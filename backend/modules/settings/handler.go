// Package settings serves the settings screen, system information and provider
// connection tests.
package settings

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/culpeohq/backend/internal/appsettings"
	"github.com/culpeohq/backend/internal/hardware"
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

func (m *SettingsModule) Initialize() error {
	return m.store.Load()
}

func (m *SettingsModule) Shutdown() error { return nil }

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
