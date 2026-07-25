package engine

import (
	"context"
	"sync"
	"time"

	"github.com/fillyengine/backend/internal/hardware"
)

const watchdogHardwareSampleTimeout = 400 * time.Millisecond
const watchdogHardwareSampleMaxAge = 2500 * time.Millisecond

// hardwareSampler keeps slow platform probes off the pressure-watchdog loop.
// Sample is non-blocking and coalesces any number of refresh requests into at
// most one detector goroutine. Until the first result is available callers get
// an unknown snapshot, which the guard treats fail-closed.
type hardwareSampler struct {
	detect  func(context.Context) hardware.Snapshot
	timeout time.Duration
	maxAge  time.Duration

	ctx    context.Context
	cancel context.CancelFunc

	mu          sync.RWMutex
	inFlight    bool
	closed      bool
	have        bool
	latest      hardware.Snapshot
	completedAt time.Time
	// expectedDedicatedGPUs is learned only from live, measurable dedicated
	// records. Inventory-only CIM adapters are intentionally excluded.
	expectedDedicatedGPUs map[string]bool
}

func newHardwareSampler(detect func(context.Context) hardware.Snapshot) *hardwareSampler {
	return newHardwareSamplerWithOptions(detect, 400*time.Millisecond, watchdogHardwareSampleMaxAge)
}

func newHardwareSamplerWithOptions(detect func(context.Context) hardware.Snapshot, timeout, maxAge time.Duration) *hardwareSampler {
	if detect == nil {
		detect = hardware.DetectPressure
	}
	if timeout <= 0 || timeout > watchdogHardwareSampleTimeout {
		timeout = watchdogHardwareSampleTimeout
	}
	if maxAge <= 0 {
		maxAge = watchdogHardwareSampleMaxAge
	}
	ctx, cancel := context.WithCancel(context.Background())
	return &hardwareSampler{
		detect: detect, timeout: timeout, maxAge: maxAge, ctx: ctx, cancel: cancel,
		expectedDedicatedGPUs: map[string]bool{},
	}
}

// Sample requests a refresh and immediately returns the last completed
// snapshot. The boolean is false before the first probe and once the cache is
// too old to be trusted.
func (s *hardwareSampler) Sample() (hardware.Snapshot, bool) {
	s.mu.Lock()
	latest := s.latest
	have := s.have && time.Since(s.completedAt) <= s.maxAge
	if !s.closed && !s.inFlight {
		s.inFlight = true
		go s.refresh()
	}
	s.mu.Unlock()
	if !have {
		return hardware.Snapshot{}, false
	}
	return latest, have
}

// ExpectDedicatedGPUs seeds inventory learned by the slower full detector or
// persisted engine plans. This closes the first-sample gap when a pressure
// command consistently exceeds the 400 ms watchdog budget.
func (s *hardwareSampler) ExpectDedicatedGPUs(ids []string) {
	s.mu.Lock()
	for _, id := range ids {
		if id != "" {
			s.expectedDedicatedGPUs[id] = true
		}
	}
	// A valid cached pressure sample may predate a plan which first exposed a
	// dedicated GPU. Mark that cache incomplete immediately; waiting for the
	// next asynchronous refresh would briefly reopen admission on stale
	// GPU-less telemetry.
	if s.have && missingExpectedDedicatedGPU(s.latest, s.expectedDedicatedGPUs) {
		s.latest.GPUTelemetryIncomplete = true
	}
	s.mu.Unlock()
}

// Latest reads the cache without scheduling another platform probe. It is
// mainly useful to observe an asynchronously completed sample in tests.
func (s *hardwareSampler) Latest() (hardware.Snapshot, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.latest, s.have
}

func (s *hardwareSampler) refresh() {
	ctx, cancel := context.WithTimeout(s.ctx, s.timeout)
	snapshot := s.detect(ctx)
	cancel()

	s.mu.Lock()
	if !s.closed {
		for _, gpu := range snapshot.GPUs {
			if gpu.SharedMemory || gpu.VRAMTelemetryUnavailable || gpu.VRAMTotalBytes <= 0 {
				continue
			}
			s.expectedDedicatedGPUs[gpu.ID] = true
		}
		if missingExpectedDedicatedGPU(snapshot, s.expectedDedicatedGPUs) {
			snapshot.GPUTelemetryIncomplete = true
		}
		s.latest = snapshot
		s.have = true
		s.completedAt = time.Now()
	}
	s.inFlight = false
	s.mu.Unlock()
}

func missingExpectedDedicatedGPU(snapshot hardware.Snapshot, expected map[string]bool) bool {
	if len(expected) == 0 {
		return false
	}
	observed := make(map[string]bool, len(snapshot.GPUs))
	for _, gpu := range snapshot.GPUs {
		if gpu.SharedMemory || gpu.VRAMTelemetryUnavailable || gpu.VRAMTotalBytes <= 0 {
			continue
		}
		observed[gpu.ID] = true
	}
	for id := range expected {
		if !observed[id] {
			return true
		}
	}
	return false
}

func (s *hardwareSampler) Close() {
	s.mu.Lock()
	if s.closed {
		s.mu.Unlock()
		return
	}
	s.closed = true
	s.cancel()
	s.mu.Unlock()
}
