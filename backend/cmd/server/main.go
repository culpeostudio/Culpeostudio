// Command server runs the PhiloEngine backend: the HTTP control plane, the
// module registry and the gRPC listener.
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
	modBenchmark "github.com/fillyengine/backend/modules/benchmark"
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

	app := fiber.New(fiber.Config{
		AppName:      "FillyEngine Backend",
		ServerHeader: "FillyEngine",

		Immutable: true,
	})

	app.Use(logger.New())
	app.Use(recover.New())
	app.Use(middleware.CORSMiddleware())
	app.Use(middleware.AuthMiddleware(cfg.JWTSecret, loginModule.UserExists))

	api := app.Group("/api")

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
		modNews.New(cfg.NewsSavedFile),
		modBenchmark.New(cfg.BenchmarkCacheDir, cfg.SettingsFile),
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

	eventBus := bus.Get()

	memoryModule.AttachBus(eventBus)

	eventBus.On(bus.EventModelDownloaded, func(e bus.Event) {
		log.Printf("[Bus] Modell heruntergeladen: %v – Engine kann Modell-Liste aktualisieren", e.Data)
	})

	eventBus.OnAll(func(e bus.Event) {
		log.Printf("[Bus] %s -> %s: %v", e.Source, e.Type, e.Data)
	})

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "ok",
			"modules": len(modules),
		})
	})

	grpcSrv := grpcserver.New(cfg.HTTPHost, cfg.GRPCPort)

	skillsModule.RegisterGRPC(grpcSrv.GetGRPC())

	go func() {
		if err := grpcSrv.Start(); err != nil {
			log.Printf("[gRPC] Fehler: %v", err)
		}
	}()

	go func() {

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

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Server wird heruntergefahren...")

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
