package engine

import (
	"crypto/sha256"
	"fmt"
	"sort"
	"strings"

	"github.com/culpeohq/backend/internal/hardware"
	"github.com/culpeohq/backend/internal/modelcatalog"
)

func preflightReport(record modelcatalog.ModelRecord, plan ContextPlanView, snapshot hardware.Snapshot) PreflightReport {
	confidence := "verified"
	for _, warning := range plan.Warnings {
		lower := strings.ToLower(warning)
		if strings.Contains(lower, "geschaetzt") || strings.Contains(lower, "kein verifiziertes") {
			confidence = "estimated"
			break
		}
	}

	checks := []PreflightCheck{
		{
			ID: "catalog", State: "pending", Label: "Modelldateien vor Start prüfen",
			Detail: "Vor jedem Start wird der Modell-Fingerabdruck erneut mit den Dateien auf der Festplatte abgeglichen.",
		},
		{
			ID: "memory", State: "passed", Label: "Speicherplan berechnet",
			Detail: fmt.Sprintf("GPU und System-RAM wurden mit Sicherheitsreserven für bis zu %d Token berechnet.", plan.EffectiveContextTokens),
		},
		{
			ID: "launch_revalidation", State: "pending", Label: "Vor dem Start erneut prüfen",
			Detail: "Nach dem Runtime-Bau werden Hardware, Modell-Fingerabdruck und Speicherplan direkt vor dem Workerstart erneut geprüft.",
		},
		{
			ID: "worker_probe", State: "pending", Label: "Modellantwort verifizieren",
			Detail: "Erst eine lokale Mini-Inferenz bestätigt, dass das Modell tatsächlich bereit ist.",
		},
	}
	if plan.HybridMaxContextTokens > plan.GPUOnlyMaxContextTokens {
		checks = append(checks, PreflightCheck{
			ID: "ram_context", State: "passed", Label: "RAM-Erweiterung berechnet",
			Detail: fmt.Sprintf("Mit freigegebenem System-RAM wären bis zu %d Token möglich.", plan.HybridMaxContextTokens),
		})
	} else if plan.GPUOnlyMaxContextTokens >= plan.ModelContextLimitTokens {
		checks = append(checks, PreflightCheck{
			ID: "ram_context", State: "passed", Label: "RAM-Vorteil eingeordnet",
			Detail: "System-RAM erhöht den Kontext hier nicht, weil das Modelllimit bereits erreicht ist.",
		})
	} else {
		checks = append(checks, PreflightCheck{
			ID: "ram_context", State: "pending", Label: "System-RAM ist noch nicht freigegeben",
			Detail: "Der aktuelle Plan nutzt nur Grafikspeicher. Für eine größere oder peak-sichere Aufteilung muss System-RAM ausdrücklich freigegeben werden.",
		})
	}
	return PreflightReport{
		HardwareSnapshotID: hardwareSnapshotID(snapshot),
		ModelFingerprint:   record.Fingerprint,
		MetadataConfidence: confidence,
		Checks:             checks,
	}
}

func hardwareSnapshotID(snapshot hardware.Snapshot) string {
	parts := []string{fmt.Sprintf("ram:%d:%d", snapshot.RAMTotalBytes, snapshot.RAMAvailableBytes)}
	gpus := append([]hardware.GPU(nil), snapshot.GPUs...)
	sort.Slice(gpus, func(i, j int) bool { return gpus[i].ID < gpus[j].ID })
	for _, gpu := range gpus {
		parts = append(parts, fmt.Sprintf("gpu:%s:%s:%d:%d:%t", gpu.ID, gpu.Backend, gpu.VRAMTotalBytes, gpu.VRAMFreeBytes, gpu.SharedMemory))
	}
	digest := sha256.Sum256([]byte(strings.Join(parts, "|")))
	return fmt.Sprintf("hw-%x", digest[:6])
}
