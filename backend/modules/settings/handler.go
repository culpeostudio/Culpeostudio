// Package settings serves the settings screen, system information and provider
// connection tests.
package settings

import (
	"context"
	"fmt"
	"net/http"
	"runtime"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/internal/appsettings"
	"github.com/fillyengine/backend/internal/hardware"
	"github.com/fillyengine/backend/modules/marktplatz"
)

type SettingsModule struct {
	store *appsettings.Store
}

func New(settingsFile string) *SettingsModule {
	return &SettingsModule{
		store: appsettings.NewStore(settingsFile),
	}
}

func (m *SettingsModule) Name() string { return "settings" }

func (m *SettingsModule) RegisterRoutes(r fiber.Router) {
	g := r.Group("/settings")
	g.Get("", m.handleGet)
	g.Get("/", m.handleGet)
	g.Put("", m.handleUpdate)
	g.Put("/", m.handleUpdate)
	g.Get("/system", m.handleSystemInfo)
	g.Get("/test-provider/:provider", m.handleTestProvider)
}

func (m *SettingsModule) Initialize() error {
	return m.store.Load()
}

func (m *SettingsModule) Shutdown() error { return nil }

func (m *SettingsModule) handleGet(c *fiber.Ctx) error {
	s := m.store.Get()
	return c.JSON(buildPublicSettingsResponse(s))
}

func (m *SettingsModule) handleUpdate(c *fiber.Ctx) error {
	var body struct {
		ModelDir              *string           `json:"model_dir"`
		HuggingFaceToken      *string           `json:"huggingface_token"`
		OpenRouterToken       *string           `json:"openrouter_token"`
		FeatherlessToken      *string           `json:"featherless_token"`
		Shortcuts             map[string]string `json:"shortcuts"`
		EngineRAMReserveBytes *int64            `json:"engine_ram_reserve_bytes"`
		EngineGPUReserveBytes *int64            `json:"engine_gpu_reserve_bytes"`
		ResetEngineReserves   bool              `json:"reset_engine_reserves"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Ungueltige Anfrage"})
	}

	reserveWarnings, err := validateEngineReserves(c.UserContext(), body.EngineRAMReserveBytes, body.EngineGPUReserveBytes)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	updated, err := m.store.Update(appsettings.Update{
		ModelDir:              body.ModelDir,
		HuggingFaceToken:      body.HuggingFaceToken,
		OpenRouterToken:       body.OpenRouterToken,
		FeatherlessToken:      body.FeatherlessToken,
		Shortcuts:             body.Shortcuts,
		EngineRAMReserveBytes: body.EngineRAMReserveBytes,
		EngineGPUReserveBytes: body.EngineGPUReserveBytes,
		ResetEngineReserves:   body.ResetEngineReserves,
	})
	if err != nil {
		status := fiber.StatusInternalServerError
		if body.ModelDir != nil || body.EngineRAMReserveBytes != nil || body.EngineGPUReserveBytes != nil {
			status = fiber.StatusBadRequest
		}
		return c.Status(status).JSON(fiber.Map{"error": err.Error()})
	}

	resp := buildPublicSettingsResponse(updated)
	resp["message"] = "Einstellungen gespeichert"
	if len(reserveWarnings) > 0 {
		resp["warnings"] = reserveWarnings
	}
	return c.JSON(resp)
}

func validateEngineReserves(ctx context.Context, ramReserve, gpuReserve *int64) ([]string, error) {
	if ramReserve == nil && gpuReserve == nil {
		return nil, nil
	}
	snapshot := hardware.DetectPressure(ctx)
	warnings := []string{}
	formatGB := func(bytes int64) string {
		return fmt.Sprintf("%.1f GB", float64(bytes)/float64(1<<30))
	}
	if ramReserve != nil && snapshot.RAMTotalBytes > 0 {
		if *ramReserve >= snapshot.RAMTotalBytes {
			return nil, fmt.Errorf(
				"die Engine-RAM-Reserve (%s) ist groesser oder gleich dem physischen Arbeitsspeicher (%s); damit koennte nie wieder ein Modell starten",
				formatGB(*ramReserve), formatGB(snapshot.RAMTotalBytes))
		}
		if *ramReserve > snapshot.RAMTotalBytes*8/10 {
			warnings = append(warnings, fmt.Sprintf(
				"Die Engine-RAM-Reserve (%s) belegt mehr als 80%% des Arbeitsspeichers (%s); fuer Modelle bleibt kaum Budget uebrig.",
				formatGB(*ramReserve), formatGB(snapshot.RAMTotalBytes)))
		}
	}
	if gpuReserve != nil {
		var largestGPU int64
		for _, gpu := range snapshot.GPUs {
			if !gpu.SharedMemory && gpu.VRAMTotalBytes > largestGPU {
				largestGPU = gpu.VRAMTotalBytes
			}
		}
		if largestGPU > 0 {
			if *gpuReserve >= largestGPU {
				return nil, fmt.Errorf(
					"die Engine-GPU-Reserve (%s) ist groesser oder gleich dem groessten Grafikspeicher (%s); damit koennte kein Modell mehr auf die GPU",
					formatGB(*gpuReserve), formatGB(largestGPU))
			}
			if *gpuReserve > largestGPU*8/10 {
				warnings = append(warnings, fmt.Sprintf(
					"Die Engine-GPU-Reserve (%s) belegt mehr als 80%% des Grafikspeichers (%s).",
					formatGB(*gpuReserve), formatGB(largestGPU)))
			}
		}
	}
	return warnings, nil
}

func buildPublicSettingsResponse(s appsettings.Settings) fiber.Map {
	modelDirValid := !(runtime.GOOS != "windows" && appsettings.LooksLikeWindowsPath(s.ModelDir))
	modelDirError := ""
	if !modelDirValid {
		modelDirError = "Windows-Pfad unter Linux: bitte einen Linux-Ordner auswählen"
	}
	return fiber.Map{
		"model_dir":                strings.TrimSpace(s.ModelDir),
		"model_dir_valid":          modelDirValid,
		"model_dir_error":          modelDirError,
		"huggingface_token_set":    strings.TrimSpace(s.HuggingFaceToken) != "",
		"openrouter_token_set":     strings.TrimSpace(s.OpenRouterToken) != "",
		"featherless_token_set":    strings.TrimSpace(s.FeatherlessToken) != "",
		"shortcuts":                s.Shortcuts,
		"engine_ram_reserve_bytes": s.EngineRAMReserveBytes,
		"engine_gpu_reserve_bytes": s.EngineGPUReserveBytes,
	}
}

func (m *SettingsModule) handleSystemInfo(c *fiber.Ctx) error {
	return c.JSON(marktplatz.CurrentHardwareProfile())
}

func (m *SettingsModule) handleTestProvider(c *fiber.Ctx) error {
	provider := c.Params("provider")
	s := m.store.Get()
	var token string
	switch provider {
	case "huggingface":
		token = s.HuggingFaceToken
	case "openrouter":
		token = s.OpenRouterToken
	case "featherless":
		token = s.FeatherlessToken
	default:
		return c.Status(400).JSON(fiber.Map{"error": "Ungültiger Provider"})
	}

	var reachable bool
	var msg string
	switch provider {
	case "huggingface":
		reachable, msg = testHuggingFace(token)
	case "openrouter":
		reachable, msg = testOpenRouter(token)
	case "featherless":
		reachable, msg = testFeatherless(token)
	}

	return c.JSON(fiber.Map{
		"provider":  provider,
		"reachable": reachable,
		"message":   msg,
	})
}

func testHuggingFace(token string) (bool, string) {
	client := &http.Client{Timeout: 10 * time.Second}
	if token != "" {
		req, err := http.NewRequest("GET", "https://huggingface.co/api/whoami", nil)
		if err != nil {
			return false, err.Error()
		}
		req.Header.Set("Authorization", "Bearer "+token)
		resp, err := client.Do(req)
		if err != nil {
			return false, "Verbindungsfehler: " + err.Error()
		}
		defer resp.Body.Close()

		if resp.StatusCode == 200 {
			return true, "Berechtigt und erreichbar"
		}
		if resp.StatusCode == 401 {
			return false, "Ungültiger Token (401)"
		}
		return false, fmt.Sprintf("Unerwarteter Status: %d", resp.StatusCode)
	} else {
		req, err := http.NewRequest("GET", "https://huggingface.co/api/models?limit=1", nil)
		if err != nil {
			return false, err.Error()
		}
		resp, err := client.Do(req)
		if err != nil {
			return false, "Dienst nicht erreichbar"
		}
		defer resp.Body.Close()
		if resp.StatusCode == 200 {
			return true, "Erreichbar (kein Token)"
		}
		return false, fmt.Sprintf("Dienst nicht erreichbar: %d", resp.StatusCode)
	}
}

func testOpenRouter(token string) (bool, string) {
	client := &http.Client{Timeout: 10 * time.Second}
	if token != "" {
		req, err := http.NewRequest("GET", "https://openrouter.ai/api/v1/auth/key", nil)
		if err != nil {
			return false, err.Error()
		}
		req.Header.Set("Authorization", "Bearer "+token)
		resp, err := client.Do(req)
		if err != nil {
			return false, "Verbindungsfehler: " + err.Error()
		}
		defer resp.Body.Close()

		if resp.StatusCode == 200 {
			return true, "Berechtigt und erreichbar"
		}
		if resp.StatusCode == 401 {
			return false, "Ungültiger Token (401)"
		}
		return false, fmt.Sprintf("Unerwarteter Status: %d", resp.StatusCode)
	} else {
		req, err := http.NewRequest("GET", "https://openrouter.ai/api/v1/models", nil)
		if err != nil {
			return false, err.Error()
		}
		resp, err := client.Do(req)
		if err != nil {
			return false, "Dienst nicht erreichbar"
		}
		defer resp.Body.Close()
		if resp.StatusCode == 200 {
			return true, "Erreichbar (kein Token)"
		}
		return false, fmt.Sprintf("Dienst nicht erreichbar: %d", resp.StatusCode)
	}
}

func testFeatherless(token string) (bool, string) {
	client := &http.Client{Timeout: 10 * time.Second}
	req, err := http.NewRequest("GET", "https://api.featherless.ai/v1/models", nil)
	if err != nil {
		return false, err.Error()
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	resp, err := client.Do(req)
	if err != nil {
		return false, "Verbindungsfehler: " + err.Error()
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 {
		if token != "" {
			return true, "Berechtigt und erreichbar"
		}
		return true, "Erreichbar (öffentlich)"
	}
	if resp.StatusCode == 401 {
		if token != "" {
			return false, "Ungültiger Token (401)"
		}
		return true, "Erreichbar (erfordert Token)"
	}
	return false, fmt.Sprintf("Unerwarteter Status: %d", resp.StatusCode)
}
