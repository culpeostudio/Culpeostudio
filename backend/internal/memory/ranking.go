package memory

import (
	"strings"
	"time"
)

func (s *Service) routeIntent(query string, filters SearchFilters) SearchFilters {
	if filters.Layer != "" || strings.TrimSpace(query) == "" {
		return filters
	}

	lower := strings.ToLower(query)
	userHints := []string{"ich ", "mein ", "meine ", "meinen ", "user data", "praeferenz", "präferenz", "vorliebe", "persoenlich", "persönlich"}
	changeHints := []string{"aenderungsantrag", "änderungsantrag", "change request", "vorschlag", "angenommen", "verworfen"}
	brainstormHints := []string{"brainstorm", "idee", "ideen", "skizze", "denken wir", "moeglichkeit", "möglichkeit"}
	for _, hint := range userHints {
		if strings.Contains(lower, hint) {
			filters.Layer = LayerUserData
			return filters
		}
	}
	for _, hint := range changeHints {
		if strings.Contains(lower, hint) {
			filters.Layer = LayerProjectData
			filters.Category = CategoryChangeRequest
			return filters
		}
	}
	for _, hint := range brainstormHints {
		if strings.Contains(lower, hint) {
			filters.Layer = LayerProjectData
			filters.Category = CategoryBrainstorming
			return filters
		}
	}
	return filters
}

func (s *Service) compressionThreshold(observations []Observation) int {
	if len(observations) == 0 {
		return s.policy.ProjectStatusThreshold
	}
	layer := dominantLayer(observations)
	category := dominantCategory(observations)
	switch {
	case layer == LayerUserData:
		return s.policy.UserDataThreshold
	case category == CategoryBrainstorming:
		return s.policy.ProjectBrainstormThreshold
	case category == CategoryChangeRequest:
		return s.policy.ChangeRequestThreshold
	default:
		return s.policy.ProjectStatusThreshold
	}
}

func compressibleObservations(observations []Observation) []Observation {
	result := make([]Observation, 0, len(observations))
	for _, observation := range observations {
		if observation.ChangeRequest != nil && normalizeChangeRequestStatus(observation.ChangeRequest.Status) == ChangeRequestOpen {
			continue
		}
		result = append(result, observation)
	}
	return result
}

func dominantLayer(observations []Observation) MemoryLayer {
	counts := map[MemoryLayer]int{}
	for _, observation := range observations {
		counts[normalizeLayer(observation.Layer)]++
	}
	if counts[LayerUserData] > counts[LayerProjectData] {
		return LayerUserData
	}
	return LayerProjectData
}

func dominantCategory(observations []Observation) MemoryCategory {
	counts := map[MemoryCategory]int{}
	for _, observation := range observations {
		counts[normalizeCategory(observation.Category)]++
	}
	best := CategoryStatus
	bestCount := 0
	for category, count := range counts {
		if count > bestCount {
			best = category
			bestCount = count
		}
	}
	return best
}

func normalizeChangeRequest(input *ChangeRequestState) *ChangeRequestState {
	if input == nil {
		return nil
	}
	state := &ChangeRequestState{
		Status:      normalizeChangeRequestStatus(input.Status),
		Proposal:    strings.TrimSpace(input.Proposal),
		ReasonShort: strings.TrimSpace(input.ReasonShort),
		DecidedAt:   strings.TrimSpace(input.DecidedAt),
	}
	if state.Proposal == "" && state.ReasonShort == "" {
		return nil
	}
	if state.Status != ChangeRequestOpen && state.DecidedAt == "" {
		state.DecidedAt = nowUTC().Format(time.RFC3339)
	}
	return state
}

func (s *Service) UpdateChangeRequestStatus(userID, observationID string, input UpdateChangeRequestInput) (*Observation, error) {
	userID = normalizeUserID(firstNonEmpty(input.UserID, userID), s.defaultUserID)
	state := ChangeRequestState{
		Status:      normalizeChangeRequestStatus(input.Status),
		ReasonShort: strings.TrimSpace(input.ReasonShort),
	}
	if state.Status != ChangeRequestOpen {
		state.DecidedAt = nowUTC().Format(time.RFC3339)
	}
	observation, err := s.repo.UpdateChangeRequestStatus(userID, strings.TrimSpace(observationID), state)
	if err != nil {
		return nil, err
	}
	if err := s.indexObservation(observation); err != nil {
		return nil, err
	}
	if observation.ChangeRequest != nil && observation.ChangeRequest.Status != ChangeRequestOpen {
		_ = s.maybeCompress(userID, observation.SessionID, "change_request_decided")
	}
	s.publish("change_request_updated", observation)
	return observation, nil
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return strings.TrimSpace(value)
		}
	}
	return ""
}
