package engine

import (
	"github.com/fillyengine/backend/internal/engineruntime"
)

func (m *EngineModule) gatewayLookup(id string) (gatewayModel, bool) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	instance := m.instances[id]
	if instance == nil {
		return gatewayModel{}, false
	}
	limit := 0
	if instance.Plan != nil {
		limit = instance.Plan.EffectiveContextTokens
	}
	return gatewayModel{ID: instance.ID, Ready: instance.State == engineruntime.StateReady, BaseURL: instance.BaseURL, WorkerSecret: instance.WorkerSecret, ContextLimit: limit, CreatedAt: instance.CreatedAt, Runtime: string(instance.Runtime), GenerationDefaults: cloneJSONMap(instance.EffectiveConfig.GenerationDefaults)}, true
}

func (m *EngineModule) gatewayList() []gatewayModel {
	m.mu.RLock()
	defer m.mu.RUnlock()
	result := make([]gatewayModel, 0, len(m.instances))
	for _, instance := range m.instances {
		limit := 0
		if instance.Plan != nil {
			limit = instance.Plan.EffectiveContextTokens
		}
		result = append(result, gatewayModel{ID: instance.ID, Ready: instance.State == engineruntime.StateReady, BaseURL: instance.BaseURL, WorkerSecret: instance.WorkerSecret, ContextLimit: limit, CreatedAt: instance.CreatedAt, Runtime: string(instance.Runtime), GenerationDefaults: cloneJSONMap(instance.EffectiveConfig.GenerationDefaults)})
	}
	return result
}

func (m *EngineModule) restoreAutostart() {
	for _, instance := range m.listInstances() {
		if !instance.Autostart {
			continue
		}
		_, _ = m.scheduleStart(instance.ID, instance.RequestedConfig, "autostart")
	}
}
