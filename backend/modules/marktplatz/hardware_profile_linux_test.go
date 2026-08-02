package marktplatz

import (
	"os"
	"path/filepath"
	"testing"
)

func TestDetectLinuxGPUFromSysfsReadsAMDNameAndVRAM(t *testing.T) {
	drm := t.TempDir()
	device := filepath.Join(drm, "card1", "device")
	if err := os.MkdirAll(device, 0o755); err != nil {
		t.Fatal(err)
	}
	for path, value := range map[string]string{
		"vendor":              "0x1002\n",
		"device":              "0x7550\n",
		"mem_info_vram_total": "17095983104\n",
	} {
		if err := os.WriteFile(filepath.Join(device, path), []byte(value), 0o644); err != nil {
			t.Fatal(err)
		}
	}

	if err := os.MkdirAll(filepath.Join(drm, "card1-DP-1"), 0o755); err != nil {
		t.Fatal(err)
	}

	name, vramMB := detectLinuxGPUFromSysfs(drm)
	if name != "AMD Radeon RX 9070 XT" {
		t.Fatalf("unexpected GPU name: %q", name)
	}
	if vramMB != 16304 {
		t.Fatalf("unexpected VRAM: %d MB", vramMB)
	}
}

func TestNormalizePhiloEngineGPUNameEnrichesNewAMDDeviceID(t *testing.T) {
	if got := normalizePhiloEngineGPUName("amd", "Device 7550"); got != "AMD Radeon RX 9070 XT" {
		t.Fatalf("unexpected enriched name: %q", got)
	}
	if got := normalizePhiloEngineGPUName("amd", "AMD Radeon RX 7900 XTX"); got != "AMD Radeon RX 7900 XTX" {
		t.Fatalf("driver name must be retained, got %q", got)
	}
}
