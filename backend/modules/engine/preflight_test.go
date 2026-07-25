package engine

import (
	"strings"
	"testing"

	"github.com/fillyengine/backend/internal/hardware"
	"github.com/fillyengine/backend/internal/modelcatalog"
)

func TestPreflightExplainsHardModelLimitAndBindsLiveHardware(t *testing.T) {
	snapshot := hardware.Snapshot{
		RAMTotalBytes: 64 << 30, RAMAvailableBytes: 40 << 30,
		GPUs: []hardware.GPU{{ID: "gpu-0", Backend: "vulkan", VRAMTotalBytes: 16 << 30, VRAMFreeBytes: 12 << 30}},
	}
	plan := ContextPlanView{
		ModelContextLimitTokens: 131072,
		GPUOnlyMaxContextTokens: 131072,
		HybridMaxContextTokens:  131072,
		EffectiveContextTokens:  131072,
		Warnings:                []string{"Layerzahl fehlt und wurde fuer die Speicherplanung geschaetzt."},
	}
	report := preflightReport(modelcatalog.ModelRecord{Fingerprint: "sha256:model"}, plan, snapshot)
	if report.MetadataConfidence != "estimated" {
		t.Fatalf("metadata confidence = %q, want estimated", report.MetadataConfidence)
	}
	if report.HardwareSnapshotID == "" || report.ModelFingerprint != "sha256:model" {
		t.Fatalf("incomplete report: %#v", report)
	}
	if !hasPreflightCheck(report.Checks, "ram_context", "System-RAM erhöht den Kontext hier nicht") {
		t.Fatalf("hard context limit was not explained: %#v", report.Checks)
	}
	if !hasPreflightCheck(report.Checks, "launch_revalidation", "direkt vor dem Workerstart") {
		t.Fatalf("launch revalidation missing: %#v", report.Checks)
	}

	changed := snapshot
	changed.GPUs[0].VRAMFreeBytes--
	if hardwareSnapshotID(changed) == report.HardwareSnapshotID {
		t.Fatal("snapshot ID did not change after free VRAM changed")
	}
}

func TestPreflightDoesNotCallDisabledRAMAReachedModelLimit(t *testing.T) {
	plan := ContextPlanView{
		ModelContextLimitTokens: 262144,
		GPUOnlyMaxContextTokens: 4096,
		HybridMaxContextTokens:  4096,
		EffectiveContextTokens:  4096,
	}
	report := preflightReport(modelcatalog.ModelRecord{}, plan, hardware.Snapshot{})
	if !hasPreflightCheck(report.Checks, "ram_context", "ausdrücklich freigegeben") {
		t.Fatalf("missing RAM consent explanation: %#v", report.Checks)
	}
	if hasPreflightCheck(report.Checks, "ram_context", "Modelllimit bereits erreicht") {
		t.Fatalf("disabled RAM was misreported as a hard model limit: %#v", report.Checks)
	}
}

func hasPreflightCheck(checks []PreflightCheck, id, contains string) bool {
	for _, check := range checks {
		if check.ID == id && strings.Contains(check.Detail, contains) {
			return true
		}
	}
	return false
}
