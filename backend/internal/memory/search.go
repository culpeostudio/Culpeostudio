package memory

import (
	"errors"
	"os"
	"sort"
	"strings"
)

func (s *Service) Search(query string, filters SearchFilters) ([]SearchResult, error) {
	filters.UserID = normalizeUserID(filters.UserID, s.defaultUserID)
	filters = s.routeIntent(query, filters)
	if filters.Limit <= 0 {
		filters.Limit = 10
	}
	query = strings.TrimSpace(query)
	if query == "" {
		documents, err := s.repo.ListDocuments(filters, filters.Limit)
		if err != nil {
			return nil, err
		}
		return searchResultsFromDocuments(documents), nil
	}

	textDocuments, err := s.repo.SearchDocuments(query, filters, filters.Limit*4)
	if err != nil {
		return nil, err
	}
	var vectorHits []VectorHit
	if s.vector != nil {
		vectorHits, err = s.vector.Search(query, filters, filters.Limit*4)
		if err != nil {
			return nil, err
		}
	}

	merged := map[string]*SearchResult{}
	for _, document := range textDocuments {
		merged[document.DocID] = &SearchResult{
			DocID:       document.DocID,
			UserID:      document.UserID,
			SessionID:   document.SessionID,
			RefID:       document.RefID,
			Kind:        document.Kind,
			Project:     document.Project,
			Source:      document.Source,
			Layer:       document.Layer,
			Category:    document.Category,
			Type:        document.Type,
			Title:       document.Title,
			Snippet:     previewText(document.Body, 220),
			TextScore:   document.TextScore,
			VectorScore: 0,
			CreatedAt:   document.CreatedAt,
		}
	}

	missingDocIDs := []string{}
	for _, hit := range vectorHits {
		if current, ok := merged[hit.DocID]; ok {
			current.VectorScore = hit.Score
			continue
		}
		missingDocIDs = append(missingDocIDs, hit.DocID)
	}
	if len(missingDocIDs) > 0 {
		documents, docErr := s.repo.GetSearchDocumentsByIDs(filters.UserID, missingDocIDs)
		if docErr != nil {
			return nil, docErr
		}
		documentMap := map[string]SearchDocument{}
		for _, document := range documents {
			documentMap[document.DocID] = document
		}
		for _, hit := range vectorHits {
			if _, ok := merged[hit.DocID]; ok {
				continue
			}
			document, ok := documentMap[hit.DocID]
			if !ok {
				continue
			}
			merged[hit.DocID] = &SearchResult{
				DocID:       document.DocID,
				UserID:      document.UserID,
				SessionID:   document.SessionID,
				RefID:       document.RefID,
				Kind:        document.Kind,
				Project:     document.Project,
				Source:      document.Source,
				Layer:       document.Layer,
				Category:    document.Category,
				Type:        document.Type,
				Title:       document.Title,
				Snippet:     previewText(document.Body, 220),
				VectorScore: hit.Score,
				CreatedAt:   document.CreatedAt,
			}
		}
	}

	results := make([]SearchResult, 0, len(merged))
	for _, result := range merged {
		recency := recencyBoost(result.CreatedAt)
		typeBoost := typeBoost(result.Type, result.Layer)
		sourceBoost := sourceBoost(result.Source, result.Layer)
		result.Score = result.TextScore*0.55 + result.VectorScore*0.35 + recency*0.07 + typeBoost + sourceBoost
		results = append(results, *result)
	}
	sort.Slice(results, func(i, j int) bool {
		if results[i].Score == results[j].Score {
			return results[i].CreatedAt.After(results[j].CreatedAt)
		}
		return results[i].Score > results[j].Score
	})
	if len(results) > filters.Limit {
		results = results[:filters.Limit]
	}
	return results, nil
}

func (s *Service) Timeline(sessionID string, query TimelineQuery) ([]Observation, error) {
	return s.TimelineForUser(s.defaultUserID, sessionID, query)
}

func (s *Service) TimelineForUser(userID, sessionID string, query TimelineQuery) ([]Observation, error) {
	userID = normalizeUserID(userID, s.defaultUserID)
	session, err := s.repo.GetSession(userID, strings.TrimSpace(sessionID))
	if err != nil {
		return nil, err
	}
	before := query.Before
	after := query.After
	if before <= 0 {
		before = 2
	}
	if after <= 0 {
		after = 2
	}

	targetID := strings.TrimSpace(query.ObservationID)
	if targetID == "" && strings.TrimSpace(query.Query) != "" {
		results, err := s.Search(query.Query, SearchFilters{UserID: userID, Project: session.Project, Source: session.Source, Limit: 5})
		if err != nil {
			return nil, err
		}
		for _, result := range results {
			if result.Kind == "observation" {
				targetID = result.RefID
				break
			}
		}
	}
	if targetID == "" {
		return nil, errors.New("observation_id oder query ist erforderlich")
	}

	all := append(append([]Observation{}, session.ArchivedObservations...), session.ActiveObservations...)
	sort.Slice(all, func(i, j int) bool {
		return all[i].CreatedAt.Before(all[j].CreatedAt)
	})
	index := -1
	for i, observation := range all {
		if observation.ID == targetID {
			index = i
			break
		}
	}
	if index == -1 {
		return nil, os.ErrNotExist
	}
	start := index - before
	if start < 0 {
		start = 0
	}
	end := index + after + 1
	if end > len(all) {
		end = len(all)
	}
	return all[start:end], nil
}
