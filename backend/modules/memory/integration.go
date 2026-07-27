package memorymodule

import (
	"log"
	"strings"

	"github.com/fillyengine/backend/internal/bus"
	"github.com/fillyengine/backend/internal/memorycapture"
	"github.com/fillyengine/backend/internal/security"
)

// ── PhiloBot-Direktanbindung (nur lesend) ──────────────────────────
// PhiloBotMemoryContext liefert einen kompakten Recall-Block fuer den
// PhiloBot-Chat: relevante Fakten aus frueheren Unterhaltungen desselben
// Nutzers, unabhaengig von der aktuellen Session. Ist project gesetzt, zieht der
// Recall aus genau diesem Projekt-Grid (plus globaler Nutzer-Fakten); ein leeres
// project sucht nutzerweit ueber alle Projekte. Diese Methode erfasst NICHTS —
// PhiloBot-Nachrichten werden bereits ueber den Event-Bus (CaptureChatMessage)
// gespeichert, ein zweiter Capture wuerde doppeln.
// Fehler blockieren den Chat nie, sie liefern nur einen leeren Kontext.
func (m *MemoryModule) PhiloBotMemoryContext(userID, project, query string) string {
	userID = security.SanitizeUserID(userID)
	if userID == "" {
		userID = m.defaultUserID
	}
	envelope, err := m.service.BuildScopedContext(userID, project, query, 0)
	if err != nil {
		log.Printf("[memory] PhiloBot-Kontext fehlgeschlagen: %v", err)
		return ""
	}
	if envelope == nil {
		return ""
	}
	return envelope.InjectionPrompt
}

// ── Event-Bus-Anbindung ────────────────────────────────────────────

// AttachBus abonniert den Event-Bus der Engine. PhiloBot-Konversationen werden
// als strukturierte Chat-Memories erfasst, alle uebrigen Events als generische
// Observations.
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
	case bus.EventPhiloBotMessageSent:
		if sessionID == "" {
			return nil
		}
		// project taggt die Chat-Memory mit dem PhiloBot-Projekt-Grid (leer =
		// nutzerweit); PhiloBot liefert es im Event mit, sofern die Session einem
		// Projekt zugeordnet ist.
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
