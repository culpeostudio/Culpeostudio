package memory

import (
	"errors"
	"os"
	"strings"
)

func (s *Service) EnsureSession(input CreateSessionInput) (*Session, error) {
	sessionID := strings.TrimSpace(input.SessionID)
	userID := normalizeUserID(input.UserID, s.defaultUserID)
	if sessionID != "" {
		session, err := s.repo.GetSession(userID, sessionID)
		if err == nil {
			return session, nil
		}

		if !errors.Is(err, os.ErrNotExist) {
			return nil, err
		}
	}
	return s.CreateSession(input)
}

func (s *Service) CreateSession(input CreateSessionInput) (*Session, error) {
	project := strings.TrimSpace(input.Project)
	if project == "" {
		project = s.projectTag
	}
	userID := normalizeUserID(input.UserID, s.defaultUserID)
	sessionID := strings.TrimSpace(input.SessionID)
	if sessionID == "" {
		sessionID = newSessionID()
	}
	session := &Session{
		UserID:             userID,
		ID:                 sessionID,
		Project:            project,
		Source:             strings.TrimSpace(input.Source),
		Status:             SessionActive,
		Goals:              normalizeList(input.Goals),
		Prompts:            []Prompt{},
		ActiveObservations: []Observation{},
		Memories:           []CompressedMemory{},
		Summaries:          []SessionSummary{},
		CreatedAt:          nowUTC(),
		UpdatedAt:          nowUTC(),
	}
	if err := s.repo.CreateSession(session); err != nil {
		return nil, err
	}
	s.publish("session_created", session)
	return session, nil
}

func (s *Service) GetSession(id string) (*Session, error) {
	return s.GetSessionForUser(s.defaultUserID, id)
}

func (s *Service) GetSessionForUser(userID, id string) (*Session, error) {
	return s.repo.GetSession(normalizeUserID(userID, s.defaultUserID), strings.TrimSpace(id))
}

func (s *Service) ListSessions() ([]*Session, error) {
	return s.ListSessionsForUser(s.defaultUserID)
}

func (s *Service) ListSessionsForUser(userID string) ([]*Session, error) {
	return s.repo.ListSessions(normalizeUserID(userID, s.defaultUserID))
}

func (s *Service) DeleteSession(id string) error {
	return s.DeleteSessionForUser(s.defaultUserID, id)
}

func (s *Service) DeleteSessionForUser(userID, id string) error {
	userID = normalizeUserID(userID, s.defaultUserID)
	id = strings.TrimSpace(id)
	if _, err := s.repo.GetSession(userID, id); err != nil {
		return err
	}

	if err := s.repo.DeleteSession(userID, id); err != nil {
		return err
	}
	s.publish("session_deleted", map[string]string{"user_id": userID, "session_id": id})
	if s.onSessionCleanup != nil {
		s.onSessionCleanup(id)
	}
	return nil
}

func (s *Service) AddPrompt(sessionID string, input AddPromptInput) (*Prompt, *ContextEnvelope, error) {
	userID := normalizeUserID(input.UserID, s.defaultUserID)
	session, err := s.repo.GetSession(userID, strings.TrimSpace(sessionID))
	if err != nil {
		return nil, nil, err
	}
	text := strings.TrimSpace(input.Text)
	if text == "" {
		return nil, nil, errors.New("prompt text ist erforderlich")
	}
	prompt := &Prompt{
		UserID:    userID,
		ID:        newPromptID(),
		SessionID: session.ID,
		Role:      normalizePromptRole(input.Role),
		Text:      text,
		CreatedAt: nowUTC(),
	}
	if err := s.repo.AddPrompt(prompt); err != nil {
		return nil, nil, err
	}
	if refreshed, getErr := s.repo.GetSession(userID, session.ID); getErr == nil {
		_ = s.repo.UpdateSessionUsage(userID, session.ID, EstimateUsage(refreshed))
	}
	s.publish("prompt_added", prompt)

	var context *ContextEnvelope
	if prompt.Role == PromptRoleUser {
		context, err = s.BuildContextForUser(userID, session.ID, prompt.Text, defaultContextLimit)
		if err != nil {
			return prompt, nil, err
		}
	}
	return prompt, context, nil
}

func (s *Service) AddObservation(sessionID string, input AddObservationInput) (*Observation, error) {
	userID := normalizeUserID(input.UserID, s.defaultUserID)
	session, err := s.repo.GetSession(userID, strings.TrimSpace(sessionID))
	if err != nil {
		return nil, err
	}
	title := strings.TrimSpace(input.Title)
	narrative := strings.TrimSpace(input.Narrative)
	layer := normalizeLayer(input.Layer)
	category := normalizeCategory(input.Category)
	changeRequest := normalizeChangeRequest(input.ChangeRequest)
	if changeRequest == nil && category == CategoryChangeRequest && (title != "" || narrative != "") {
		changeRequest = &ChangeRequestState{
			Status:   ChangeRequestOpen,
			Proposal: firstNonEmpty(narrative, title),
		}
	}
	if title == "" && narrative == "" && changeRequest == nil {
		return nil, errors.New("title oder narrative ist erforderlich")
	}
	if changeRequest != nil {
		narrative = RenderChangeRequestNarrative(changeRequest)
	}

	hash := contentHash(session.ID, title, narrative)
	duplicate, err := s.repo.FindRecentObservationByHash(userID, session.ID, hash, nowUTC().Add(-dedupWindow))
	if err != nil {
		return nil, err
	}
	if duplicate != nil {
		return duplicate, nil
	}

	observation := &Observation{
		UserID:        userID,
		ID:            newObservationID(),
		SessionID:     session.ID,
		Project:       fallbackString(input.Project, session.Project),
		Source:        fallbackString(input.Source, session.Source),
		Layer:         layer,
		Category:      category,
		Type:          normalizeObservationType(input.Type),
		Title:         title,
		Narrative:     narrative,
		ChangeRequest: changeRequest,
		Speaker:       strings.TrimSpace(input.Speaker),
		DialogueID:    input.DialogueID,
		Keywords:      normalizeList(input.Keywords),
		Persons:       normalizeList(input.Persons),
		Entities:      normalizeList(input.Entities),
		Topic:         strings.TrimSpace(input.Topic),
		Location:      strings.TrimSpace(input.Location),
		ValidFrom:     strings.TrimSpace(input.ValidFrom),
		Importance:    normalizeWeight(input.Importance, 0.5),
		Confidence:    normalizeWeight(input.Confidence, 0.5),
		SupersededBy:  strings.TrimSpace(input.SupersededBy),
		ToolName:      strings.TrimSpace(input.ToolName),
		SourcePath:    strings.TrimSpace(input.SourcePath),
		Tags:          normalizeList(input.Tags),
		ContentHash:   hash,
		CreatedAt:     nowUTC(),
	}
	if observation.ChangeRequest != nil {
		observation.Category = CategoryChangeRequest
		observation.Type = "change_request"
	}
	if err := s.repo.AddObservation(observation); err != nil {
		return nil, err
	}
	if err := s.indexObservation(observation); err != nil {
		return nil, err
	}
	s.publish("observation_added", observation)
	if err := s.maybeCompress(userID, session.ID, ""); err != nil {
		return nil, err
	}
	return observation, nil
}

func (s *Service) DeleteObservation(observationID string) (*Observation, bool, error) {
	return s.DeleteObservationForUser(s.defaultUserID, observationID)
}

func (s *Service) DeleteObservationForUser(userID, observationID string) (*Observation, bool, error) {
	userID = normalizeUserID(userID, s.defaultUserID)
	observation, tombstoned, err := s.repo.DeleteObservation(userID, strings.TrimSpace(observationID))
	if err != nil {
		return nil, false, err
	}
	s.publish("observation_deleted", map[string]interface{}{
		"user_id":        userID,
		"observation_id": observation.ID,
		"session_id":     observation.SessionID,
		"tombstoned":     tombstoned,
	})
	return observation, tombstoned, nil
}

func (s *Service) UpdateMemoryForUser(userID, memoryID string, patch MemoryPatch) (*CompressedMemory, error) {
	userID = normalizeUserID(userID, s.defaultUserID)
	item, document, err := s.repo.UpdateCompressedMemory(userID, strings.TrimSpace(memoryID), patch, true)
	if err != nil {
		return nil, err
	}
	if s.vector != nil {
		if vectorErr := s.vector.Upsert(document); vectorErr != nil {

			s.publish("vector_upsert_failed", map[string]string{"doc_id": document.DocID, "error": vectorErr.Error()})
		}
	}
	s.publish("memory_updated", item)
	return item, nil
}

func (s *Service) CompleteSession(sessionID string, input CompleteSessionInput) (*SessionSummary, error) {
	userID := normalizeUserID(input.UserID, s.defaultUserID)
	session, err := s.repo.GetSession(userID, strings.TrimSpace(sessionID))
	if err != nil {
		return nil, err
	}
	summary := &SessionSummary{
		UserID:    userID,
		ID:        newSummaryID(),
		SessionID: session.ID,
		Learned:   normalizeList(append(input.Learned, deriveLearned(session)...)),
		Completed: normalizeList(append(input.Completed, deriveCompleted(session)...)),
		NextSteps: normalizeList(append(input.NextSteps, deriveNextSteps(session)...)),
		CreatedAt: nowUTC(),
	}
	if err := s.repo.AddSummary(summary); err != nil {
		return nil, err
	}
	if err := s.repo.UpdateSessionStatus(userID, session.ID, SessionCompleted); err != nil {
		return nil, err
	}
	_ = s.maybeCompress(userID, session.ID, "complete")
	if refreshed, getErr := s.repo.GetSession(userID, session.ID); getErr == nil {
		_ = s.repo.UpdateSessionUsage(userID, session.ID, EstimateUsage(refreshed))
	}
	s.publish("session_completed", summary)
	if s.onSessionCleanup != nil {
		s.onSessionCleanup(sessionID)
	}
	return summary, nil
}

func (s *Service) GetObservations(ids []string) ([]Observation, error) {
	return s.GetObservationsForUser(s.defaultUserID, ids)
}

func (s *Service) GetObservationsForUser(userID string, ids []string) ([]Observation, error) {
	return s.repo.GetObservationsByIDs(normalizeUserID(userID, s.defaultUserID), normalizeList(ids))
}
