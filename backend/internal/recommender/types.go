// Portions adapted from whichllm v0.5.15.
// Copyright (c) 2026 Andyyyy64; original portions are MIT-licensed.
// Culpeo Studio modifications are AGPL-3.0-only. See NOTICE.

package recommender

const GiB int64 = 1024 * 1024 * 1024

type Model struct {
	ID                       string
	ParameterCount           int64
	ActiveParameterCount     int64
	IsMoE                    bool
	ContextLength            int
	SlidingWindow            int
	SlidingWindowGlobalRatio float64
	Quantization             string
	QualityScore             float64
}

type Variant struct {
	Quantization  string
	FileSizeBytes int64
}

type GPU struct {
	Name                string
	Vendor              string
	VRAMBytes           int64
	UsableVRAMBytes     int64
	MemoryBandwidthGBPS float64
	SharedMemory        bool
}

type Hardware struct {
	RAMBytes       int64
	RAMBudgetBytes int64
	DiskFreeBytes  int64
	GPUs           []GPU
}

type FitType string

const (
	FitFullGPU        FitType = "full_gpu"
	FitPartialOffload FitType = "partial_offload"
	FitCPUOnly        FitType = "cpu_only"

	FitUnsupported FitType = "unsupported"
)

type Result struct {
	CanRun             bool
	Fit                FitType
	VRAMRequiredBytes  int64
	VRAMAvailableBytes int64
	OffloadRatio       float64
	EstimatedTokPerSec float64
	Score              float64
	Warnings           []string
}
