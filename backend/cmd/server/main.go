package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"

	"github.com/fillyengine/backend/internal/bus"
	"github.com/fillyengine/backend/internal/config"
	"github.com/fillyengine/backend/internal/grpcserver"
	"github.com/fillyengine/backend/internal/memory"
	"github.com/fillyengine/backend/internal/memoryembed"
	"github.com/fillyengine/backend/internal/middleware"

	modModule "github.com/fillyengine/backend/modules"
	modEngine "github.com/fillyengine/backend/modules/engine"
	modLogin "github.com/fillyengine/backend/modules/login"
	modMarktplatz "github.com/fillyengine/backend/modules/marktplatz"
	modMemory "github.com/fillyengine/backend/modules/memory"
	modNews "github.com/fillyengine/backend/modules/news"
	modPhilobot "github.com/fillyengine/backend/modules/philobot"
	modPhilosearch "github.com/fillyengine/backend/modules/philosearch"
	modSettings "github.com/fillyengine/backend/modules/settings"
	modSkills "github.com/fillyengine/backend/modules/skills"
)

func main() {
	cfg := config.Load()
	loginModule := modLogin.New(
		cfg.JWTSecret,
		cfg.LoginAccountsFile,
		cfg.AuthConfigFile,
		cfg.UserPreferencesFile,
	)

	// ══════════════════════════════════════════════════════
	// 1. Fiber HTTP/HTTPS Server
	// ══════════════════════════════════════════════════════
	app := fiber.New(fiber.Config{
		AppName:      "FillyEngine Backend",
		ServerHeader: "FillyEngine",
		// Engine operations keep route IDs after the request returns. Without
		// Immutable, fasthttp may reuse and overwrite their backing byte buffer.
		Immutable: true,
	})

	// Globale Middleware
	app.Use(logger.New())
	app.Use(recover.New())
	app.Use(middleware.CORSMiddleware())
	app.Use(middleware.AuthMiddleware(cfg.JWTSecret, loginModule.UserExists))

	// API-Router Gruppe
	api := app.Group("/api")

	// ══════════════════════════════════════════════════════
	// 2. Module registrieren (jedes Modul unabhängig)
	// ══════════════════════════════════════════════════════
	memoryModule := modMemory.New(
		cfg.MemorySQLitePath,
		cfg.MemoryVectorPath,
		memoryembed.Config{
			Backend:        cfg.EmbeddingBackend,
			HashDims:       cfg.EmbeddingHashDims,
			SidecarURL:     cfg.EmbeddingSidecarURL,
			SidecarModel:   cfg.EmbeddingSidecarModel,
			OllamaURL:      cfg.EmbeddingOllamaURL,
			OllamaModel:    cfg.EmbeddingOllamaModel,
			APIURL:         cfg.EmbeddingAPIURL,
			APIKey:         cfg.EmbeddingAPIKey,
			APIModel:       cfg.EmbeddingAPIModel,
			MinFreeMemMB:   cfg.EmbeddingMinFreeMemMB,
			MinCores:       cfg.EmbeddingMinCores,
			TimeoutSeconds: cfg.EmbeddingTimeoutSec,
		},
		cfg.MemoryProjectTag,
		cfg.MemoryAPIToken,
		cfg.MemoryDefaultUserID,
		cfg.MemoryContextBudget,
		memory.CompressionPolicy{
			UserDataThreshold:          cfg.UserThreshold,
			ProjectStatusThreshold:     cfg.StatusThreshold,
			ProjectBrainstormThreshold: cfg.BrainstormThreshold,
			ChangeRequestThreshold:     cfg.ChangeRequestThreshold,
		},
		cfg.CaptureRateLimit,
		cfg.ChatWindowSize,
		cfg.ChatOverlapSize,
		cfg.MemoryViewerTitle,
		modMemory.MaintenanceConfig{
			ReindexInterval:     time.Duration(cfg.MemoryReindexIntervalSeconds) * time.Second,
			ReindexBatchSize:    cfg.MemoryReindexBatchSize,
			ReindexConcurrency:  cfg.MemoryReindexConcurrency,
			SoftDeleteRetention: time.Duration(cfg.MemorySoftDeleteRetentionDays) * 24 * time.Hour,
		},
		cfg.MemoryTokenizerFamily,
		cfg.MemoryTokenizerModelPath,
	)

	philobotModule := modPhilobot.New(cfg.SettingsFile)
	// PhiloBot bekommt lesenden Zugriff aufs Projektgedaechtnis, damit dauerhafte
	// Nutzerfakten (z. B. der Name) auch in neuen Chats erinnert werden.
	philobotModule.SetMemory(memoryModule)
	philobotModule.SetExistingUsers(loginModule.ListUserIDs)
	loginModule.SetUserCreatedHook(philobotModule.EnsureUser)
	engineModule := modEngine.New(cfg.SettingsFile)
	philobotModule.SetLocalModels(engineModule)
	skillsModule := modSkills.New("data/skills")

	modules := []modModule.Module{
		memoryModule,
		loginModule,
		modMarktplatz.New(cfg.SettingsFile),
		philobotModule,
		modSettings.New(cfg.SettingsFile),
		skillsModule,
		engineModule,
		modNews.New(),
		modPhilosearch.New(),
	}

	for _, m := range modules {
		if err := m.Initialize(); err != nil {
			log.Fatalf("[%s] Initialisierung fehlgeschlagen: %v", m.Name(), err)
		}
		m.RegisterRoutes(api)
		if appModule, ok := m.(modModule.AppRouteRegistrar); ok {
			appModule.RegisterAppRoutes(app)
		}
		log.Printf("[HTTP] Modul '%s' registriert", m.Name())
	}

	// ══════════════════════════════════════════════════════
	// 3. Inter-Modul-Kommunikation (Event Bus)
	// ══════════════════════════════════════════════════════
	eventBus := bus.Get()

	// Memory hoert auf alle Bus-Events: PhiloBot-Chats werden strukturiert
	// erfasst, uebrige Modul-Events landen als Observations im Gedaechtnis.
	memoryModule.AttachBus(eventBus)

	// Beispiel: Wenn ein Modell heruntergeladen wurde, Engine benachrichtigen
	eventBus.On(bus.EventModelDownloaded, func(e bus.Event) {
		log.Printf("[Bus] Modell heruntergeladen: %v – Engine kann Modell-Liste aktualisieren", e.Data)
	})

	// Debug: Alle Events loggen
	eventBus.OnAll(func(e bus.Event) {
		log.Printf("[Bus] %s -> %s: %v", e.Source, e.Type, e.Data)
	})

	// ══════════════════════════════════════════════════════
	// 4. Health Check
	// ══════════════════════════════════════════════════════
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "ok",
			"modules": len(modules),
		})
	})

	// ══════════════════════════════════════════════════════
	// 5. gRPC Server (parallel)
	// ══════════════════════════════════════════════════════
	grpcSrv := grpcserver.New(cfg.HTTPHost, cfg.GRPCPort)

	// TODO: gRPC Service-Implementierungen registrieren:
	// pb.RegisterEngineServiceServer(grpcSrv.GetGRPC(), &engineGrpc{})
	// pb.RegisterChatServiceServer(grpcSrv.GetGRPC(), &chatGrpc{})
	// pb.RegisterTrainingServiceServer(grpcSrv.GetGRPC(), &trainingGrpc{})
	// pb.RegisterQuantizationServiceServer(grpcSrv.GetGRPC(), &quantGrpc{})
	// pb.RegisterMarktplatzServiceServer(grpcSrv.GetGRPC(), &marktplatzGrpc{})
	skillsModule.RegisterGRPC(grpcSrv.GetGRPC())

	go func() {
		if err := grpcSrv.Start(); err != nil {
			log.Printf("[gRPC] Fehler: %v", err)
		}
	}()

	// ══════════════════════════════════════════════════════
	// 6. HTTP(S) Server starten
	// ══════════════════════════════════════════════════════
	go func() {
		// Standardmaessig nur lokal erreichbar: Frontend und Backend laufen auf
		// demselben Rechner, ein Lauschen auf allen Interfaces (":8080") wuerde
		// die Instanz sonst im ganzen Netz (z. B. oeffentliches WLAN) anbieten.
		// Wer bewusst von aussen zugreifen will, setzt HTTP_HOST — etwa
		// HTTP_HOST=0.0.0.0 fuer alle Interfaces.
		addr := cfg.HTTPHost + ":" + cfg.HTTPPort
		if cfg.UseHTTPS && cfg.TLSCert != "" && cfg.TLSKey != "" {
			log.Printf("[HTTPS] Server läuft auf %s", addr)
			if err := app.ListenTLS(addr, cfg.TLSCert, cfg.TLSKey); err != nil {
				log.Fatalf("[HTTPS] Fehler: %v", err)
			}
		} else {
			log.Printf("[HTTP] Server läuft auf %s", addr)
			if err := app.Listen(addr); err != nil {
				log.Fatalf("[HTTP] Fehler: %v", err)
			}
		}
	}()

	// ══════════════════════════════════════════════════════
	// 7. Graceful Shutdown
	// ══════════════════════════════════════════════════════
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Server wird heruntergefahren...")

	// Module herunterfahren
	for _, m := range modules {
		if err := m.Shutdown(); err != nil {
			log.Printf("[%s] Shutdown-Fehler: %v", m.Name(), err)
		}
	}

	grpcSrv.Stop()

	if err := app.Shutdown(); err != nil {
		log.Fatalf("Fiber Shutdown-Fehler: %v", err)
	}

	log.Println("Server gestoppt.")
}
