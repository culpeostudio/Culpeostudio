package engine

import (
	"testing"

	"github.com/culpeohq/backend/internal/hardware"
)

func TestUnknownPressureTelemetryFailsClosed(t *testing.T) {
	tests := []struct {
		name     string
		snapshot hardware.Snapshot
		want     GuardState
	}{
		{name: "initial empty asynchronous cache", snapshot: hardware.Snapshot{}, want: GuardWarning},
		{name: "known RAM total with zero available", snapshot: hardware.Snapshot{RAMTotalBytes: 32 << 30}, want: GuardEmergency},
		{
			name: "dedicated GPU with unknown total",
			snapshot: hardware.Snapshot{
				RAMTotalBytes: 32 << 30, RAMAvailableBytes: 24 << 30,
				GPUs: []hardware.GPU{{ID: "gpu", SharedMemory: false}},
			},
			want: GuardWarning,
		},
		{
			name: "dedicated GPU with zero free memory",
			snapshot: hardware.Snapshot{
				RAMTotalBytes: 32 << 30, RAMAvailableBytes: 24 << 30,
				GPUs: []hardware.GPU{{ID: "gpu", SharedMemory: false, VRAMTotalBytes: 16 << 30}},
			},
			want: GuardEmergency,
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := guardStateForSnapshot(test.snapshot); got != test.want {
				t.Fatalf("guard state = %s, want %s", got, test.want)
			}
		})
	}
}
