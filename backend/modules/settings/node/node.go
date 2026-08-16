// Package node manages server node settings, hardware reserves, and system pressure validation.
package node

import (
	"context"
	"fmt"

	"github.com/culpeohq/backend/internal/hardware"
)

// NodeHandler manages server node settings and hardware reserves (RAM/GPU).
type NodeHandler struct{}

// New returns a new NodeHandler instance.
func New() *NodeHandler {
	return &NodeHandler{}
}

// ValidateEngineReserves validates RAM and GPU reserve settings against system hardware specs.
func (n *NodeHandler) ValidateEngineReserves(ctx context.Context, ramReserve, gpuReserve *int64) ([]string, error) {
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
