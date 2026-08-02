// Package memory recalls facts from earlier conversations into later ones. It
// ranks candidates, keeps the injected context inside a budget, and summarises
// what no longer fits.
package memory

import (
	"errors"
	"log"
	"strings"
)

func (s *Service) TriggerCompression(userID, sessionID string) error {
	return s.maybeCompress(userID, sessionID, "")
}

func (s *Service) maybeCompress(userID, sessionID, reason string) error {
	userID = normalizeUserID(userID, s.defaultUserID)
	sessionID = strings.TrimSpace(sessionID)

	session, err := s.repo.GetSession(userID, sessionID)
	if err != nil {
		return err
	}

	usage := EstimateUsage(session)
	compressible := compressibleObservations(session.ActiveObservations)
	threshold := s.compressionThreshold(compressible)
	if reason == "complete" && len(compressible) > ActiveWindow {
		threshold = ActiveWindow + 1
	}
	if usage < compressionThreshold && len(compressible) < threshold {
		return nil
	}
	if len(compressible) <= ActiveWindow {
		return nil
	}

	cutoff := len(compressible) - ActiveWindow
	toCompress := append([]Observation{}, compressible[:cutoff]...)
	obsIDs := collectObservationIDs(toCompress)

	summaryText, learned, openTasks, sumErr := s.summarizer.Summarize(toCompress)
	if sumErr != nil {
		return sumErr
	}

	memoryItem := &CompressedMemory{
		UserID:         session.UserID,
		ID:             newMemoryID(),
		SessionID:      session.ID,
		Layer:          dominantLayer(toCompress),
		Category:       dominantCategory(toCompress),
		Summary:        summaryText,
		Learned:        learned,
		OpenTasks:      openTasks,
		ObservationIDs: obsIDs,
		CreatedAt:      nowUTC(),
	}

	plan := &CompressionPlan{
		Memory:      memoryItem,
		Document:    BuildMemoryDocument(memoryItem, session.Project, session.Source),
		UsageBefore: usage,
		UsageAfter:  estimateUsageAfterCompression(session, memoryItem),
	}

	err = s.repo.WriteCompressedMemory(userID, sessionID, plan, obsIDs)
	if err != nil {
		if errors.Is(err, ErrAlreadyArchived) {
			log.Printf("[memory-service] observations already archived, backing off compression")
			return nil
		}
		return err
	}

	if s.vector != nil {
		if vectorErr := s.vector.Upsert(plan.Document); vectorErr != nil {
			s.publish("vector_upsert_failed", map[string]string{"doc_id": plan.Document.DocID, "error": vectorErr.Error()})
		}
	}

	s.publish("memory_compressed", map[string]interface{}{
		"user_id":        userID,
		"memory_id":      plan.Memory.ID,
		"session_id":     sessionID,
		"usage_before":   plan.UsageBefore,
		"usage_after":    plan.UsageAfter,
		"observations":   len(plan.Memory.ObservationIDs),
		"memory_summary": plan.Memory.Summary,
	})
	return nil
}

func (s *Service) indexObservation(observation *Observation) error {
	body := observationIndexBody(observation)
	document := SearchDocument{
		DocID:      "obs:" + observation.ID,
		UserID:     observation.UserID,
		SessionID:  observation.SessionID,
		RefID:      observation.ID,
		Kind:       "observation",
		Project:    observation.Project,
		Source:     observation.Source,
		Layer:      observation.Layer,
		Category:   observation.Category,
		Type:       observation.Type,
		Title:      fallbackTitle(observation.Title, observation.Type),
		Body:       body,
		SourcePath: observation.SourcePath,
		Tags:       observationIndexTags(observation),
		CreatedAt:  observation.CreatedAt,
	}
	if err := s.repo.UpsertSearchDocument(document); err != nil {
		return err
	}
	if s.vector != nil {
		if err := s.vector.Upsert(document); err != nil {

			s.publish("vector_upsert_failed", map[string]string{"doc_id": document.DocID, "error": err.Error()})
		}
	}
	return nil
}

func observationIndexBody(observation *Observation) string {
	parts := []string{
		observation.Title,
		observation.Narrative,
		observation.Topic,
		observation.Location,
		strings.Join(observation.Keywords, " "),
		strings.Join(observation.Persons, " "),
		strings.Join(observation.Entities, " "),
		observation.ValidFrom,
	}
	return strings.TrimSpace(strings.Join(parts, "\n"))
}

func observationIndexTags(observation *Observation) []string {
	tags := append([]string{}, observation.Tags...)
	tags = append(tags, observation.Keywords...)
	tags = append(tags, observation.Persons...)
	tags = append(tags, observation.Entities...)
	tags = append(tags, observation.Topic, observation.Location)
	return normalizeList(tags)
}

func BuildMemoryDocument(memoryItem *CompressedMemory, project, source string) SearchDocument {
	return SearchDocument{
		DocID:     "mem:" + memoryItem.ID,
		UserID:    memoryItem.UserID,
		SessionID: memoryItem.SessionID,
		RefID:     memoryItem.ID,
		Kind:      "memory",
		Project:   project,
		Source:    source,
		Layer:     memoryItem.Layer,
		Category:  memoryItem.Category,
		Type:      "memory",
		Title:     "Compressed memory",
		Body: strings.TrimSpace(
			memoryItem.Summary + "\nLearned: " + strings.Join(memoryItem.Learned, " | ") + "\nOpen tasks: " + strings.Join(memoryItem.OpenTasks, " | "),
		),
		CreatedAt: memoryItem.CreatedAt,
	}
}

func (s *Service) resolveContextQuery(session *Session, query string) string {
	if strings.TrimSpace(query) != "" {
		return strings.TrimSpace(query)
	}
	for i := len(session.Prompts) - 1; i >= 0; i-- {
		if session.Prompts[i].Role == PromptRoleUser && strings.TrimSpace(session.Prompts[i].Text) != "" {
			return session.Prompts[i].Text
		}
	}
	if len(session.Goals) > 0 {
		return strings.Join(session.Goals, " ")
	}
	return session.Project + " " + session.Source
}
