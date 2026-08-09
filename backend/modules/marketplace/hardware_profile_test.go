package marketplace

import "testing"

func TestParseDxdiagDisplayDevicePrefersDedicatedMemory(t *testing.T) {
	raw := `
Card name: AMD Radeon RX 9070 XT
Display Memory: 32444 MB
Dedicated Memory: 16188 MB
Shared Memory: 16255 MB

Card name: Microsoft Basic Display Adapter
Display Memory: 1024 MB
Dedicated Memory: 0 MB
`

	name, vramMB := parseDxdiagDisplayDevice(raw)
	if name != "AMD Radeon RX 9070 XT" {
		t.Fatalf("expected primary GPU name, got %q", name)
	}
	if vramMB != 16188 {
		t.Fatalf("expected dedicated VRAM 16188 MB, got %d", vramMB)
	}
}

func TestParseDxdiagDisplayDeviceFallsBackToDisplayMemory(t *testing.T) {
	raw := `
Card name: Example GPU
Display Memory: 8192 MB
`

	name, vramMB := parseDxdiagDisplayDevice(raw)
	if name != "Example GPU" {
		t.Fatalf("expected GPU name, got %q", name)
	}
	if vramMB != 8192 {
		t.Fatalf("expected display memory fallback, got %d", vramMB)
	}
}
