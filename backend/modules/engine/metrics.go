package engine

import (
	"context"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/fillyengine/backend/internal/hardware"
)

// inferenceSample captures one completed streaming request. Token counts are
// approximated by emitted stream chunks, which matches OpenAI-style deltas
// closely enough for a live throughput display.
type inferenceSample struct {
	CompletedAt     time.Time `json:"completed_at"`
	DurationSeconds float64   `json:"duration_seconds"`
	TTFTSeconds     float64   `json:"time_to_first_token_seconds"`
	OutputTokens    int       `json:"output_tokens"`
}

const maxInferenceSamples = 20

type instanceInferenceStats struct {
	mu            sync.Mutex
	samples       []inferenceSample
	totalRequests int64
	totalTokens   int64
}

func (s *instanceInferenceStats) record(sample inferenceSample) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.samples = append(s.samples, sample)
	if len(s.samples) > maxInferenceSamples {
		s.samples = s.samples[len(s.samples)-maxInferenceSamples:]
	}
	s.totalRequests++
	s.totalTokens += int64(sample.OutputTokens)
}

// summary aggregates the retained samples into the JSON shape served by the
// metrics endpoint.
func (s *instanceInferenceStats) summary() map[string]interface{} {
	s.mu.Lock()
	defer s.mu.Unlock()
	result := map[string]interface{}{
		"total_requests":      s.totalRequests,
		"total_output_tokens": s.totalTokens,
		"requests_measured":   len(s.samples),
	}
	if len(s.samples) == 0 {
		return result
	}
	var tokenSeconds, tokens, ttft float64
	for _, sample := range s.samples {
		tokenSeconds += sample.DurationSeconds
		tokens += float64(sample.OutputTokens)
		ttft += sample.TTFTSeconds
	}
	if tokenSeconds > 0 {
		result["avg_tokens_per_second"] = roundTo(tokens/tokenSeconds, 1)
	}
	result["avg_time_to_first_token_ms"] = int(ttft / float64(len(s.samples)) * 1000)
	last := s.samples[len(s.samples)-1]
	if last.DurationSeconds > 0 {
		result["last_tokens_per_second"] = roundTo(float64(last.OutputTokens)/last.DurationSeconds, 1)
	}
	result["last_time_to_first_token_ms"] = int(last.TTFTSeconds * 1000)
	result["last_measured_at"] = last.CompletedAt
	return result
}

func roundTo(value float64, decimals int) float64 {
	factor := 1.0
	for i := 0; i < decimals; i++ {
		factor *= 10
	}
	return float64(int64(value*factor+0.5)) / factor
}

func (m *EngineModule) recordInferenceSample(instanceID string, start, firstToken time.Time, tokens int) {
	if tokens <= 0 {
		return
	}
	end := time.Now()
	sample := inferenceSample{
		CompletedAt:     end.UTC(),
		DurationSeconds: end.Sub(start).Seconds(),
		OutputTokens:    tokens,
	}
	if !firstToken.IsZero() {
		sample.TTFTSeconds = firstToken.Sub(start).Seconds()
		// Throughput is more meaningful over the generation window (after the
		// first token) than over the full request including prompt processing.
		if generation := end.Sub(firstToken).Seconds(); generation > 0 {
			sample.DurationSeconds = generation
		}
	}
	m.inferenceStatsMu.Lock()
	if m.inferenceStats == nil {
		m.inferenceStats = map[string]*instanceInferenceStats{}
	}
	stats := m.inferenceStats[instanceID]
	if stats == nil {
		stats = &instanceInferenceStats{}
		m.inferenceStats[instanceID] = stats
	}
	m.inferenceStatsMu.Unlock()
	stats.record(sample)
}

func (m *EngineModule) inferenceStatsFor(instanceID string) *instanceInferenceStats {
	m.inferenceStatsMu.Lock()
	defer m.inferenceStatsMu.Unlock()
	return m.inferenceStats[instanceID]
}

// instanceMetrics builds the live monitoring payload for one instance:
// throughput from recent requests, process memory, the planned budget, and
// the current host headroom.
func (m *EngineModule) instanceMetrics(ctx context.Context, instance *EngineInstance) map[string]interface{} {
	metrics := map[string]interface{}{
		"instance_id":     instance.ID,
		"state":           instance.State,
		"active_requests": instance.ActiveRequests,
	}
	if instance.LastUsedAt != nil {
		metrics["last_used_at"] = instance.LastUsedAt
	}

	if stats := m.inferenceStatsFor(instance.ID); stats != nil {
		metrics["throughput"] = stats.summary()
	} else {
		metrics["throughput"] = map[string]interface{}{
			"total_requests": 0, "total_output_tokens": 0, "requests_measured": 0,
		}
	}

	memory := map[string]interface{}{}
	if instance.Plan != nil {
		planned := map[string]interface{}{"ram_bytes": instance.Plan.Memory.Total.RAMBytes}
		gpuPlanned := map[string]int64{}
		for id, bytes := range instance.Plan.Memory.Total.GPUBytes {
			gpuPlanned[id] = bytes
		}
		if len(gpuPlanned) > 0 {
			planned["gpu_bytes"] = gpuPlanned
		}
		memory["planned"] = planned
	}
	if ram := m.instanceProcessRAM(instance.ID); ram > 0 {
		memory["process_ram_bytes"] = ram
	}
	metrics["memory"] = memory

	snapshot := hardware.DetectPressure(ctx)
	host := map[string]interface{}{
		"ram_total_bytes":     snapshot.RAMTotalBytes,
		"ram_available_bytes": snapshot.RAMAvailableBytes,
	}
	gpus := make([]map[string]interface{}, 0, len(snapshot.GPUs))
	for _, gpu := range snapshot.GPUs {
		gpus = append(gpus, map[string]interface{}{
			"id": gpu.ID, "name": gpu.Name,
			"vram_total_bytes": gpu.VRAMTotalBytes,
			"vram_free_bytes":  gpu.VRAMFreeBytes,
		})
	}
	if len(gpus) > 0 {
		host["gpus"] = gpus
	}
	metrics["host"] = host
	return metrics
}

// instanceProcessRAM reports the resident memory of one worker process
// (Linux only; other platforms return 0 and the field is omitted).
func (m *EngineModule) instanceProcessRAM(instanceID string) int64 {
	if m.supervisor == nil || runtime.GOOS != "linux" {
		return 0
	}
	for _, process := range m.supervisor.Instances() {
		if process.InstanceID != instanceID || process.PID <= 0 {
			continue
		}
		data, err := os.ReadFile(filepath.Join("/proc", strconv.Itoa(process.PID), "status"))
		if err != nil {
			return 0
		}
		for _, line := range strings.Split(string(data), "\n") {
			if strings.HasPrefix(line, "VmRSS:") {
				fields := strings.Fields(line)
				if len(fields) >= 2 {
					value, _ := strconv.ParseInt(fields[1], 10, 64)
					return value * 1024
				}
			}
		}
	}
	return 0
}
