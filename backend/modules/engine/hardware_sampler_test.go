package engine

import (
	"context"
	"sync/atomic"
	"testing"
	"time"

	"github.com/fillyengine/backend/internal/engineruntime"
	"github.com/fillyengine/backend/internal/hardware"
)

func TestHardwareSamplerIsNonBlockingAndCoalescesRefreshes(t *testing.T) {
	release := make(chan struct{})
	started := make(chan struct{}, 2)
	var calls atomic.Int32
	var concurrent atomic.Int32
	var maximum atomic.Int32
	detect := func(context.Context) hardware.Snapshot {
		calls.Add(1)
		active := concurrent.Add(1)
		defer concurrent.Add(-1)
		for {
			seen := maximum.Load()
			if active <= seen || maximum.CompareAndSwap(seen, active) {
				break
			}
		}
		started <- struct{}{}
		<-release
		return hardware.Snapshot{RAMTotalBytes: 32 << 30, RAMAvailableBytes: 16 << 30}
	}
	sampler := newHardwareSampler(detect)
	defer sampler.Close()

	begin := time.Now()
	for index := 0; index < 100; index++ {
		if _, have := sampler.Sample(); have {
			t.Fatal("unexpected cached result while detector is blocked")
		}
	}
	if elapsed := time.Since(begin); elapsed > 100*time.Millisecond {
		t.Fatalf("Sample blocked for %s", elapsed)
	}
	select {
	case <-started:
	case <-time.After(time.Second):
		t.Fatal("detector was not started")
	}
	if got := calls.Load(); got != 1 {
		t.Fatalf("detector calls while in flight = %d, want 1", got)
	}
	if got := maximum.Load(); got != 1 {
		t.Fatalf("concurrent detector calls = %d, want 1", got)
	}

	close(release)
	deadline := time.Now().Add(time.Second)
	for {
		snapshot, have := sampler.Latest()
		if have {
			if snapshot.RAMAvailableBytes != 16<<30 {
				t.Fatalf("cached snapshot = %#v", snapshot)
			}
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("completed sample was not cached")
		}
		time.Sleep(time.Millisecond)
	}
}

func TestHardwareSamplerCloseCancelsProbeAndPreventsNewOnes(t *testing.T) {
	started := make(chan struct{})
	cancelled := make(chan struct{})
	var calls atomic.Int32
	detect := func(ctx context.Context) hardware.Snapshot {
		calls.Add(1)
		close(started)
		<-ctx.Done()
		close(cancelled)
		return hardware.Snapshot{}
	}
	sampler := newHardwareSampler(detect)
	if _, have := sampler.Sample(); have {
		t.Fatal("unexpected initial sample")
	}
	<-started
	sampler.Close()
	select {
	case <-cancelled:
	case <-time.After(time.Second):
		t.Fatal("Close did not cancel detector")
	}
	for index := 0; index < 10; index++ {
		_, _ = sampler.Sample()
	}
	if got := calls.Load(); got != 1 {
		t.Fatalf("detector calls after Close = %d, want 1", got)
	}
}

func TestHardwareSamplerRejectsStaleCacheAndRefreshes(t *testing.T) {
	var calls atomic.Int32
	detect := func(context.Context) hardware.Snapshot {
		calls.Add(1)
		return hardware.Snapshot{RAMTotalBytes: 32 << 30, RAMAvailableBytes: 16 << 30}
	}
	sampler := newHardwareSamplerWithOptions(detect, 50*time.Millisecond, 20*time.Millisecond)
	defer sampler.Close()
	_, _ = sampler.Sample()
	waitForHardwareSamples(t, sampler, 1)
	time.Sleep(30 * time.Millisecond)
	if snapshot, have := sampler.Sample(); have || snapshot.RAMTotalBytes != 0 {
		t.Fatalf("stale cache remained usable: have=%v snapshot=%#v", have, snapshot)
	}
	deadline := time.Now().Add(time.Second)
	for calls.Load() < 2 && time.Now().Before(deadline) {
		time.Sleep(time.Millisecond)
	}
	if got := calls.Load(); got != 2 {
		t.Fatalf("stale cache did not schedule exactly one refresh: calls=%d", got)
	}
}

func TestHardwareSamplerDeadlineAllowsNextCadenceWithoutOverlap(t *testing.T) {
	var calls atomic.Int32
	var active atomic.Int32
	var maximum atomic.Int32
	detect := func(ctx context.Context) hardware.Snapshot {
		calls.Add(1)
		current := active.Add(1)
		defer active.Add(-1)
		for {
			seen := maximum.Load()
			if current <= seen || maximum.CompareAndSwap(seen, current) {
				break
			}
		}
		<-ctx.Done()
		return hardware.Snapshot{}
	}
	sampler := newHardwareSamplerWithOptions(detect, 20*time.Millisecond, time.Second)
	defer sampler.Close()
	_, _ = sampler.Sample()
	waitForHardwareSamples(t, sampler, 1)
	_, _ = sampler.Sample()
	waitForHardwareSamples(t, sampler, 2)
	if got := maximum.Load(); got != 1 {
		t.Fatalf("overlapping timed-out probes = %d, want 1", got)
	}
}

func TestHardwareSamplerUsesPlannedGPUInventoryBeforeFirstFastSample(t *testing.T) {
	var calls atomic.Int32
	detect := func(context.Context) hardware.Snapshot {
		calls.Add(1)

		return hardware.Snapshot{RAMTotalBytes: 16 << 30, RAMAvailableBytes: 8 << 30, GPUs: nil}
	}
	sampler := newHardwareSamplerWithOptions(detect, 20*time.Millisecond, time.Second)
	defer sampler.Close()
	sampler.ExpectDedicatedGPUs([]string{"gpu-from-full-plan"})
	_, _ = sampler.Sample()
	deadline := time.Now().Add(time.Second)
	for time.Now().Before(deadline) {
		snapshot, have := sampler.Latest()
		if have {
			if !snapshot.GPUTelemetryIncomplete {
				t.Fatalf("missing planned GPU telemetry was accepted: %#v", snapshot)
			}
			if state := guardStateForSnapshot(snapshot); state != GuardWarning {
				t.Fatalf("missing planned GPU guard = %s, want warning", state)
			}
			return
		}
		time.Sleep(time.Millisecond)
	}
	t.Fatal("seeded pressure sample did not complete")
}

func TestHardwareSamplerInvalidatesCachedSampleWhenPlanAddsGPU(t *testing.T) {
	detect := func(context.Context) hardware.Snapshot {
		return hardware.Snapshot{RAMTotalBytes: 16 << 30, RAMAvailableBytes: 8 << 30}
	}
	sampler := newHardwareSamplerWithOptions(detect, 20*time.Millisecond, time.Second)
	defer sampler.Close()
	_, _ = sampler.Sample()
	waitForHardwareSamples(t, sampler, 1)

	sampler.ExpectDedicatedGPUs([]string{"newly-planned-gpu"})
	snapshot, have := sampler.Sample()
	if !have || !snapshot.GPUTelemetryIncomplete {
		t.Fatalf("cached GPU-less sample remained admissible: have=%v snapshot=%#v", have, snapshot)
	}
	if state := guardStateForSnapshot(snapshot); state != GuardWarning {
		t.Fatalf("invalidated cached sample guard = %s, want warning", state)
	}
}

func TestPlannedGPUInventoryIgnoresStoppedPlacementMetadata(t *testing.T) {
	module := New(t.TempDir() + "/settings.json")
	gpuPlan := &ContextPlanView{}
	gpuPlan.Memory.Total.GPUBytes = map[string]int64{"old-gpu": 4 << 30}
	module.instances["stopped"] = &EngineInstance{ID: "stopped", State: engineruntime.StateStopped, Plan: gpuPlan}

	if ids := module.plannedDedicatedGPUIds(); len(ids) != 0 {
		t.Fatalf("stopped placement metadata became watchdog inventory: %#v", ids)
	}
	module.instances["stopped"].State = engineruntime.StateQueued
	ids := module.plannedDedicatedGPUIds()
	if len(ids) != 1 || ids[0] != "old-gpu" {
		t.Fatalf("queued GPU plan was not monitored: %#v", ids)
	}
}

func waitForHardwareSamples(t *testing.T, sampler *hardwareSampler, want int32) {
	t.Helper()
	deadline := time.Now().Add(time.Second)
	for time.Now().Before(deadline) {
		_, have := sampler.Latest()
		if have {

			sampler.mu.RLock()
			inFlight := sampler.inFlight
			sampler.mu.RUnlock()
			if !inFlight {
				return
			}
		}
		time.Sleep(time.Millisecond)
	}
	t.Fatalf("sample %d did not complete", want)
}
