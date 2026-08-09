package engine

import (
	"context"
	"fmt"
	"sort"
	"strings"

	"github.com/culpeohq/backend/internal/engineruntime"
)

func gatewayModelFor(instance *EngineInstance) gatewayModel {
	limit := 0
	if instance.Plan != nil {
		limit = instance.Plan.EffectiveContextTokens
	}
	return gatewayModel{
		ID: instance.ID, Alias: strings.TrimSpace(instance.ServedModelName),
		Ready:        instance.State == engineruntime.StateReady,
		Autostart:    instance.GatewayAutostart,
		BaseURL:      instance.BaseURL,
		WorkerSecret: instance.WorkerSecret, ContextLimit: limit,
		CreatedAt: instance.CreatedAt, Runtime: string(instance.Runtime),
		GenerationDefaults: cloneJSONMap(instance.EffectiveConfig.GenerationDefaults),
	}
}

// gatewayLookup resolves what an OpenAI client put in the "model" field. The
// instance ID is the canonical name, but the served model name is what a user
// actually wants to type into an SDK config, so it is accepted as an alias.
// Ambiguity resolves to the ID: an alias may repeat, an ID may not.
func (m *EngineModule) gatewayLookup(name string) (gatewayModel, bool) {
	name = strings.TrimSpace(name)
	if name == "" {
		return gatewayModel{}, false
	}
	m.mu.RLock()
	defer m.mu.RUnlock()
	if instance := m.instances[name]; instance != nil {
		return gatewayModelFor(instance), true
	}
	matches := []*EngineInstance{}
	for _, instance := range m.instances {
		if strings.EqualFold(strings.TrimSpace(instance.ServedModelName), name) {
			matches = append(matches, instance)
		}
	}
	if len(matches) == 0 {
		return gatewayModel{}, false
	}
	// More than one instance can serve the same model under the same name. A
	// ready one is the useful answer; otherwise the choice is made stable by
	// sorting rather than left to map iteration order.
	sort.Slice(matches, func(a, b int) bool {
		readyA := matches[a].State == engineruntime.StateReady
		readyB := matches[b].State == engineruntime.StateReady
		if readyA != readyB {
			return readyA
		}
		return matches[a].ID < matches[b].ID
	})
	return gatewayModelFor(matches[0]), true
}

func (m *EngineModule) gatewayList() []gatewayModel {
	m.mu.RLock()
	defer m.mu.RUnlock()
	result := make([]gatewayModel, 0, len(m.instances))
	for _, instance := range m.instances {
		result = append(result, gatewayModelFor(instance))
	}
	sort.Slice(result, func(a, b int) bool { return result[a].ID < result[b].ID })
	return result
}

// gatewayEnsureReady warms an instance up for a request that arrived for it.
// It only ever acts on an instance whose owner ticked the box: loading a model
// that may be tens of gigabytes is not something to do because a stray request
// mentioned its name.
func (m *EngineModule) gatewayEnsureReady(ctx context.Context, instanceID string) error {
	m.mu.RLock()
	instance := m.instances[instanceID]
	allowed := instance != nil && instance.GatewayAutostart
	m.mu.RUnlock()
	if instance == nil {
		return fmt.Errorf("Engine-Instanz wurde nicht gefunden")
	}
	if !allowed {
		return errGatewayAutostartDisabled
	}
	_, err := m.EnsureLocalModelReady(ctx, instanceID, nil)
	if err != nil {
		return err
	}
	return nil
}

var errGatewayAutostartDisabled = fmt.Errorf("automatischer Start ist fuer diese Instanz nicht aktiviert")

// gatewayRecordUsage feeds a request that went through the OpenAI gateway into
// the same throughput statistics the Studio chat path fills. Without it an
// instance driven purely from an external SDK reported no throughput at all.
func (m *EngineModule) gatewayRecordUsage(instanceID string, sample gatewayUsageSample) {
	if sample.OutputTokens <= 0 {
		return
	}
	m.recordInferenceSampleDirect(instanceID, inferenceSample{
		CompletedAt:     sample.CompletedAt,
		DurationSeconds: sample.GenerationSeconds,
		TTFTSeconds:     sample.TTFTSeconds,
		OutputTokens:    sample.OutputTokens,
	})
}

func (m *EngineModule) restoreAutostart() {
	instances := m.listInstances()
	// Autostart used to fire in map order, which meant the instance that got
	// the hardware first was arbitrary. Pinned and high-priority instances now
	// claim their budget before the rest.
	sort.SliceStable(instances, func(a, b int) bool {
		return autostartRank(instances[a]) < autostartRank(instances[b])
	})
	for _, instance := range instances {
		if !instance.Autostart {
			continue
		}
		_, _ = m.scheduleStart(instance.ID, instance.RequestedConfig, "autostart")
	}
}

func autostartRank(instance *EngineInstance) int {
	switch {
	case instance.Pinned:
		return 0
	case instance.Priority == "high":
		return 1
	case instance.Priority == "low":
		return 3
	default:
		return 2
	}
}
