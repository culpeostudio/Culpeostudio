package philobot

import (
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type sessionStorage struct {
	baseDir string
}

func newPhiloBotStorage(baseDir string) *sessionStorage {
	return &sessionStorage{baseDir: strings.TrimSpace(baseDir)}
}

func (s *sessionStorage) enabled() bool { return s != nil && s.baseDir != "" }

func (s *sessionStorage) Initialize() error {
	if !s.enabled() {
		return nil
	}
	return os.MkdirAll(s.baseDir, 0o755)
}

func (s *sessionStorage) sessionPath(id string) string {
	return filepath.Join(s.baseDir, id+".json")
}

func (s *sessionStorage) writeRaw(id string, payload []byte) error {
	if !s.enabled() {
		return nil
	}
	id = strings.TrimSpace(id)
	if id == "" {
		return errors.New("philobot: session id required")
	}
	if err := s.Initialize(); err != nil {
		return err
	}
	tmp := s.sessionPath(id) + ".tmp"
	if err := os.WriteFile(tmp, payload, 0o644); err != nil {
		return fmt.Errorf("write philobot session: %w", err)
	}
	if err := os.Rename(tmp, s.sessionPath(id)); err != nil {
		_ = os.Remove(tmp)
		return fmt.Errorf("replace philobot session: %w", err)
	}
	return nil
}

func (s *sessionStorage) LoadAll() ([]*philoBotSession, error) {
	if !s.enabled() {
		return nil, nil
	}
	if err := s.Initialize(); err != nil {
		return nil, err
	}
	matches, err := filepath.Glob(filepath.Join(s.baseDir, "*.json"))
	if err != nil {
		return nil, fmt.Errorf("glob philobot sessions: %w", err)
	}
	sessions := make([]*philoBotSession, 0, len(matches))
	for _, match := range matches {
		content, readErr := os.ReadFile(match)
		if readErr != nil {
			log.Printf("[philobot] Session-Datei %s nicht lesbar: %v", match, readErr)
			continue
		}
		var session philoBotSession
		if err := json.Unmarshal(content, &session); err != nil {
			log.Printf("[philobot] Session-Datei %s nicht dekodierbar: %v", match, err)
			continue
		}
		if strings.TrimSpace(session.ID) == "" {
			continue
		}
		session.MutationInFlight = false
		sessions = append(sessions, &session)
	}
	return sessions, nil
}

func (s *sessionStorage) Delete(id string) error {
	if !s.enabled() {
		return nil
	}
	if err := os.Remove(s.sessionPath(strings.TrimSpace(id))); err != nil && !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("delete philobot session: %w", err)
	}
	return nil
}

func (m *PhiloBotModule) persistSession(sessionID string) {
	if !m.storage.enabled() {
		return
	}
	m.mu.Lock()
	session := m.sessions[strings.TrimSpace(sessionID)]
	if session == nil {
		m.mu.Unlock()
		return
	}
	now := time.Now().UTC()
	if session.CreatedAt.IsZero() {
		session.CreatedAt = now
	}
	session.UpdatedAt = now
	id := session.ID
	payload, err := json.MarshalIndent(session, "", "  ")
	m.mu.Unlock()
	if err != nil {
		log.Printf("[philobot] Session %s serialisieren fehlgeschlagen: %v", sessionID, err)
		return
	}
	if err := m.storage.writeRaw(id, payload); err != nil {
		log.Printf("[philobot] Session %s speichern fehlgeschlagen: %v", sessionID, err)
	}
}

type philoBotSessionSummary struct {
	SessionID    string    `json:"session_id"`
	Title        string    `json:"title"`
	Preview      string    `json:"preview"`
	Provider     string    `json:"provider"`
	ModelID      string    `json:"model_id"`
	DisplayName  string    `json:"display_name"`
	LockedBotID  string    `json:"locked_bot_id,omitempty"`
	ProjectID    string    `json:"project_id,omitempty"`
	MessageCount int       `json:"message_count"`
	UpdatedAt    time.Time `json:"updated_at"`
}

func summarizeSession(session *philoBotSession) philoBotSessionSummary {
	title := strings.TrimSpace(session.Title)
	if title == "" {
		for _, message := range session.Messages {
			if message.Role == "user" && strings.TrimSpace(message.Content) != "" {
				title = chatSessionTitle(message.Content, 60)
				break
			}
		}
	}
	if title == "" {
		title = "Neuer Chat"
	}
	preview := ""
	if count := len(session.Messages); count > 0 {
		preview = chatSessionTitle(session.Messages[count-1].Content, 100)
	}
	return philoBotSessionSummary{
		SessionID:    session.ID,
		Title:        title,
		Preview:      preview,
		Provider:     session.Provider,
		ModelID:      session.ModelID,
		DisplayName:  session.DisplayName,
		LockedBotID:  session.LockedBotID,
		ProjectID:    session.ProjectID,
		MessageCount: len(session.Messages),
		UpdatedAt:    session.UpdatedAt,
	}
}

func chatSessionTitle(text string, max int) string {
	line := strings.TrimSpace(text)
	if idx := strings.IndexAny(line, "\r\n"); idx >= 0 {
		line = strings.TrimSpace(line[:idx])
	}
	if max <= 0 {
		return line
	}
	runes := []rune(line)
	if len(runes) <= max {
		return line
	}
	return strings.TrimSpace(string(runes[:max])) + "…"
}
