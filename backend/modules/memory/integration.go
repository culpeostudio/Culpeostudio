package memorymodule

import (
	"log"
	"strings"

	"github.com/culpeohq/backend/internal/bus"
	"github.com/culpeohq/backend/internal/memory"
	"github.com/culpeohq/backend/internal/memorycapture"
	"github.com/culpeohq/backend/internal/security"
)

// projectMemorySource marks everything a project remembers, so a scope can be
// told apart from the user's general memory.
const projectMemorySource = "spark"

// ProjectMemoryContext returns the recall block for one scope. An empty project
// falls back to the user's general memory.
func (m *MemoryModule) ProjectMemoryContext(userID, project, query string) string {
	userID = m.resolveUserID(userID)
	envelope, err := m.service.BuildScopedContext(userID, project, query, 0)
	if err != nil {
		log.Printf("[memory] Projekt-Kontext fehlgeschlagen: %v", err)
		return ""
	}
	if envelope == nil {
		return ""
	}
	return envelope.InjectionPrompt
}

// EnsureProjectScope opens the memory a project keeps for itself. It is called
// when a project is created and is safe to call again.
func (m *MemoryModule) EnsureProjectScope(userID, project string) error {
	project = strings.TrimSpace(project)
	if project == "" {
		return nil
	}
	_, err := m.service.EnsureSession(memory.CreateSessionInput{
		UserID:    m.resolveUserID(userID),
		SessionID: projectScopeSessionID(project),
		Project:   project,
		Source:    projectMemorySource,
	})
	return err
}

// PurgeProjectScope drops everything the project remembered. It is called when
// a project is deleted.
func (m *MemoryModule) PurgeProjectScope(userID, project string) error {
	project = strings.TrimSpace(project)
	if project == "" {
		return nil
	}
	userID = m.resolveUserID(userID)
	sessions, err := m.service.ListSessionsForUser(userID)
	if err != nil {
		return err
	}
	for _, session := range sessions {
		if session == nil || strings.TrimSpace(session.Project) != project {
			continue
		}
		if err := m.service.DeleteSessionForUser(userID, session.ID); err != nil {
			return err
		}
	}
	return nil
}

// projectScopeSessionID keeps one stable session per project, so repeated calls
// do not pile up empty scopes.
func projectScopeSessionID(project string) string {
	return "spark-project-" + project
}

func (m *MemoryModule) resolveUserID(userID string) string {
	userID = security.SanitizeUserID(userID)
	if userID == "" {
		return m.defaultUserID
	}
	return userID
}

func (m *MemoryModule) AttachBus(b *bus.EventBus) {
	b.OnAll(func(e bus.Event) {
		if err := m.captureBusEvent(e); err != nil {
			log.Printf("[memory] Bus-Capture fehlgeschlagen (%s/%s): %v", e.Source, e.Type, err)
		}
	})
}

func (m *MemoryModule) captureBusEvent(e bus.Event) error {
	userID := security.SanitizeUserID(stringField(e.Data, "user_id"))
	if userID == "" {
		userID = m.defaultUserID
	}
	sessionID := strings.TrimSpace(stringField(e.Data, "session_id"))

	switch e.Type {
	case bus.EventScoutMessageSent:
		if sessionID == "" {
			return nil
		}

		project := strings.TrimSpace(stringField(e.Data, "project"))
		_, err := m.capture.CaptureChatMessage(userID, sessionID, project, stringField(e.Data, "message"), stringField(e.Data, "reply"))
		return err
	default:
		if sessionID == "" {
			sessionID = "system-events"
		}
		_, err := m.capture.CaptureEventBus(memorycapture.EventBusInput{
			UserID:    userID,
			SessionID: sessionID,
			Source:    e.Source,
			Type:      e.Type,
			Data:      e.Data,
		})
		return err
	}
}

func stringField(data map[string]interface{}, key string) string {
	if data == nil {
		return ""
	}
	value, _ := data[key].(string)
	return value
}
