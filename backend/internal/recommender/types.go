// Package recommender contains pure, dependency-free local-LLM fit logic.
// It deliberately has no HTTP, filesystem, or hardware probing concerns.
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
	// FitUnsupported means neither the GPU+RAM combination nor RAM alone is
	// enough to hold the model. Check used to leave the zero-value Fit
	// (FitCPUOnly, set before the switch below runs) in place for this case,
	// which made an unrunnable model report the exact same "cpu_only" label
	// as one that genuinely runs (slowly) on the CPU.
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
