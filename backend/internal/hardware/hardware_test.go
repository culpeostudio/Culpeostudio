package hardware

import (
	"context"
	"testing"
	"time"
)

func TestParseProcMeminfoUsesAvailableMemory(t *testing.T) {
	total, available := parseProcMeminfo([]byte("MemTotal:       32768000 kB\nMemAvailable:   12000000 kB\n"))
	if total != 32768000*1024 || available != 12000000*1024 {
		t.Fatalf("unexpected memory values: total=%d available=%d", total, available)
	}
}

func TestParseProcMeminfoKeepsMissingOrZeroAvailableUnknown(t *testing.T) {
	for _, input := range []string{
		"MemTotal:       32768000 kB\n",
		"MemTotal:       32768000 kB\nMemAvailable:          0 kB\n",
	} {
		total, available := parseProcMeminfo([]byte(input))
		if total != 32768000*1024 {
			t.Fatalf("total = %d", total)
		}
		if available != 0 {
			t.Fatalf("unknown available memory was fabricated as %d", available)
		}
	}
}

func TestParseDarwinMemoryPressure(t *testing.T) {
	percent, ok := parseDarwinMemoryPressure("System-wide memory free percentage: 37%\n")
	if !ok || percent != 37 {
		t.Fatalf("memory pressure = %d, ok=%v", percent, ok)
	}
	if _, ok := parseDarwinMemoryPressure("unknown output"); ok {
		t.Fatal("unexpectedly accepted invalid memory_pressure output")
	}
}

func TestParseDarwinVMStatAvailable(t *testing.T) {
	output := `Mach Virtual Memory Statistics: (page size of 16384 bytes)
Pages free:                               100.
Pages active:                             900.
Pages inactive:                           200.
Pages speculative:                         10.
Pages occupied by compressor:              50.
`
	available, ok := parseDarwinVMStatAvailable(output)
	if !ok || available != int64(310*16384) {
		t.Fatalf("vm_stat available = %d, ok=%v", available, ok)
	}
}

func TestDarwinMemoryMeasurementDistinguishesMissingFromMeasuredZero(t *testing.T) {
	total := int64(32 << 30)
	if gotTotal, gotAvailable := darwinMemoryMeasurement(total, 0, false); gotTotal != 0 || gotAvailable != 0 {
		t.Fatalf("missing measurement = (%d,%d), want unknown (0,0)", gotTotal, gotAvailable)
	}
	if gotTotal, gotAvailable := darwinMemoryMeasurement(total, 0, true); gotTotal != total || gotAvailable != 0 {
		t.Fatalf("measured zero = (%d,%d), want (%d,0)", gotTotal, gotAvailable, total)
	}
}

func TestCapturePressureSnapshotIsDeadlineBoundAndStartsProbesConcurrently(t *testing.T) {
	startedMemory := make(chan struct{})
	startedGPU := make(chan struct{})
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Millisecond)
	defer cancel()
	begin := time.Now()
	snapshot := capturePressureSnapshot(ctx,
		func(probeCtx context.Context) (int64, int64) {
			close(startedMemory)
			<-probeCtx.Done()
			return 32 << 30, 16 << 30
		},
		func(probeCtx context.Context) []GPU {
			close(startedGPU)
			<-probeCtx.Done()
			return []GPU{{ID: "gpu"}}
		},
	)
	if elapsed := time.Since(begin); elapsed > 100*time.Millisecond {
		t.Fatalf("pressure snapshot ignored its deadline: %s", elapsed)
	}
	select {
	case <-startedMemory:
	default:
		t.Fatal("memory probe was not started")
	}
	select {
	case <-startedGPU:
	default:
		t.Fatal("GPU probe was not started")
	}
	if snapshot.Source != "native-pressure" || snapshot.CapturedAt.IsZero() {
		t.Fatalf("incomplete pressure snapshot metadata: %#v", snapshot)
	}
}

func TestDefaultReservations(t *testing.T) {
	s := Snapshot{RAMTotalBytes: 32 << 30, RAMAvailableBytes: 30 << 30}
	if got, want := s.SchedulableRAM(), int64(32<<30)-(int64(32<<30)*15/100); got != want {
		t.Fatalf("schedulable RAM = %d, want %d", got, want)
	}
	g := GPU{VRAMTotalBytes: 16 << 30, VRAMFreeBytes: 15 << 30}
	if got, want := g.SchedulableVRAM(), int64(16<<30)-(int64(16<<30)/10); got != want {
		t.Fatalf("schedulable VRAM = %d, want %d", got, want)
	}
}

func TestSchedulableMemoryFailsClosedForUnknownMeasurements(t *testing.T) {
	for _, snapshot := range []Snapshot{
		{RAMTotalBytes: 32 << 30},
		{RAMAvailableBytes: 16 << 30},
	} {
		if got := snapshot.SchedulableRAM(); got != 0 {
			t.Fatalf("unknown RAM snapshot returned %d schedulable bytes", got)
		}
	}
	for _, gpu := range []GPU{
		{VRAMTotalBytes: 16 << 30},
		{VRAMFreeBytes: 8 << 30},
	} {
		if got := gpu.SchedulableVRAM(); got != 0 {
			t.Fatalf("unknown VRAM snapshot returned %d schedulable bytes", got)
		}
	}
}

func TestSharedMemoryIsNotCountedAsVRAM(t *testing.T) {
	g := GPU{VRAMTotalBytes: 8 << 30, VRAMFreeBytes: 8 << 30, SharedMemory: true}
	if got := g.SchedulableVRAM(); got != 0 {
		t.Fatalf("shared memory returned %d schedulable VRAM", got)
	}
}

func TestMergeGPUInventoriesKeepsMixedVendorsAndPrefersNvidiaSMI(t *testing.T) {
	primary := []GPU{{ID: "GPU-stable", Index: 0, Vendor: "nvidia", Backend: "cuda", VRAMFreeBytes: 12}}
	secondary := []GPU{
		{ID: "0000:01:00.0", Index: 0, Vendor: "nvidia", Backend: "cuda"},
		{ID: "0000:02:00.0", Index: 0, Vendor: "amd", Backend: "vulkan", VRAMFreeBytes: 16},
	}
	got := mergeGPUInventories(primary, secondary, true)
	if len(got) != 2 {
		t.Fatalf("mixed inventory = %#v", got)
	}
	foundCUDA, foundAMD := false, false
	for _, gpu := range got {
		foundCUDA = foundCUDA || gpu.ID == "GPU-stable"
		foundAMD = foundAMD || gpu.ID == "0000:02:00.0"
		if gpu.ID == "0000:01:00.0" {
			t.Fatalf("lower-confidence duplicate NVIDIA record survived: %#v", got)
		}
	}
	if !foundCUDA || !foundAMD {
		t.Fatalf("mixed vendors were lost: %#v", got)
	}
}

func TestWindowsCIMInventoryNeverFabricatesFreeVRAM(t *testing.T) {
	input := `[{"Name":"AMD Radeon RX 7900 XTX","PNPDeviceID":"PCI\\VEN_1002","AdapterRAM":4294967295,"DriverVersion":"1.2.3"},{"Name":"Intel Arc","PNPDeviceID":"PCI\\VEN_8086","AdapterRAM":2147483648,"DriverVersion":"4.5.6"}]`
	gpus := parseWindowsGPUInventory(input)
	if len(gpus) != 2 {
		t.Fatalf("CIM inventory = %#v", gpus)
	}
	for _, gpu := range gpus {
		if gpu.VRAMTotalBytes != 0 || gpu.VRAMUsedBytes != 0 || gpu.VRAMFreeBytes != 0 {
			t.Fatalf("CIM fabricated live VRAM counters: %#v", gpu)
		}
		if gpu.SchedulableVRAM() != 0 {
			t.Fatalf("unknown CIM VRAM became schedulable: %#v", gpu)
		}
		if gpu.Backend != "directml" {
			t.Fatalf("backend = %q for %#v", gpu.Backend, gpu)
		}
		if !gpu.VRAMTelemetryUnavailable {
			t.Fatalf("CIM-only GPU was not marked telemetry-unavailable: %#v", gpu)
		}
	}
	if gpus[0].ID != `PCI\VEN_1002` || gpus[0].DriverVersion != "1.2.3" {
		t.Fatalf("CIM identity metadata was lost: %#v", gpus[0])
	}

	single := parseWindowsGPUInventory(`{"Name":"NVIDIA GeForce","PNPDeviceID":"gpu-0","AdapterRAM":8589934592}`)
	if len(single) != 1 || single[0].Vendor != "nvidia" || single[0].VRAMTotalBytes != 0 {
		t.Fatalf("single CIM record = %#v", single)
	}
}

func TestFriendlyGPUDescriptionsPreferKnownNameAndStripPCIPrefix(t *testing.T) {
	if got := linuxGPUName("0x1002", "0x7550"); got != "AMD Radeon RX 9070 XT" {
		t.Fatalf("known GPU name = %q", got)
	}
	got := friendlyPCIDescription("VGA compatible controller: Advanced Micro Devices, Inc. [AMD/ATI] Navi")
	if got != "Advanced Micro Devices, Inc. [AMD/ATI] Navi" {
		t.Fatalf("PCI description = %q", got)
	}
}
