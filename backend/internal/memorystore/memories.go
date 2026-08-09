package memorystore

import (
	"database/sql"
	"errors"
	"fmt"
	"os"
	"strings"
	"time"

	_ "modernc.org/sqlite"
	_ "modernc.org/sqlite/vec"

	"github.com/culpeohq/backend/internal/memory"
)

func (s *SQLiteStore) ListMemories(userID, sessionID string) ([]memory.CompressedMemory, error) {
	return s.listMemories(s.db, userID, sessionID)
}

func (s *SQLiteStore) listMemories(q queryer, userID, sessionID string) ([]memory.CompressedMemory, error) {
	rows, err := q.Query(`
		SELECT user_id, id, session_id, layer, category, summary, learned_json, open_tasks_json, observation_ids_json, corrected_by_user, created_at
		FROM compressed_memories
		WHERE user_id = ? AND session_id = ?
		ORDER BY created_at DESC
	`, userID, sessionID)
	if err != nil {
		return nil, fmt.Errorf("memory list query failed: %w", err)
	}
	defer rows.Close()
	result := []memory.CompressedMemory{}
	for rows.Next() {
		item, err := scanCompressedMemory(rows)
		if err != nil {
			return nil, err
		}
		result = append(result, *item)
	}
	return result, rows.Err()
}

func (s *SQLiteStore) UpdateCompressedMemory(userID, memoryID string, patch memory.MemoryPatch, manual bool) (*memory.CompressedMemory, memory.SearchDocument, error) {
	var updated *memory.CompressedMemory
	var document memory.SearchDocument
	err := s.withImmediateTx(func(tx *writeTx) error {
		row := tx.QueryRow(`
			SELECT user_id, id, session_id, layer, category, summary, learned_json, open_tasks_json, observation_ids_json, corrected_by_user, created_at
			FROM compressed_memories
			WHERE user_id = ? AND id = ?
		`, userID, memoryID)
		item, err := scanCompressedMemory(row)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				return os.ErrNotExist
			}
			return err
		}
		if !manual && item.CorrectedByUser {
			return memory.ErrCorrectedByUser
		}
		if patch.Summary != nil {
			item.Summary = strings.TrimSpace(*patch.Summary)
		}
		if patch.Learned != nil {
			item.Learned = *patch.Learned
		}
		if patch.OpenTasks != nil {
			item.OpenTasks = *patch.OpenTasks
		}
		if manual {
			item.CorrectedByUser = true
		}
		if _, err := tx.Exec(`
			UPDATE compressed_memories
			SET summary = ?, learned_json = ?, open_tasks_json = ?, corrected_by_user = ?
			WHERE user_id = ? AND id = ?
		`, item.Summary, mustJSON(item.Learned), mustJSON(item.OpenTasks), boolToInt(item.CorrectedByUser), userID, memoryID); err != nil {
			return err
		}
		session, err := s.loadSessionBase(tx, userID, item.SessionID)
		if err != nil {
			return err
		}
		document = memory.BuildMemoryDocument(item, session.Project, session.Source)
		if err := upsertSearchDocument(tx, document); err != nil {
			return err
		}
		updated = item
		return touchSession(tx, userID, item.SessionID)
	})
	if err != nil {
		return nil, memory.SearchDocument{}, err
	}
	return updated, document, nil
}

func (s *SQLiteStore) WriteCompressedMemory(userID, sessionID string, plan *memory.CompressionPlan, obsIDs []string) error {
	if len(obsIDs) == 0 {
		return nil
	}
	return s.withImmediateTx(func(tx *writeTx) error {

		inSQL, inArgs := buildInClause("SELECT COUNT(*) FROM observations WHERE user_id = ? AND session_id = ? AND archived = 0 AND id IN (%s)", obsIDs)
		args := append([]interface{}{userID, sessionID}, inArgs...)

		var count int
		err := tx.QueryRow(inSQL, args...).Scan(&count)
		if err != nil {
			return err
		}

		if count != len(obsIDs) {

			return memory.ErrAlreadyArchived
		}

		item := plan.Memory
		if _, err := tx.Exec(`
			INSERT INTO compressed_memories
				(user_id, id, session_id, layer, category, summary, learned_json, open_tasks_json, observation_ids_json, corrected_by_user, created_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?)
		`,
			item.UserID,
			item.ID,
			item.SessionID,
			string(item.Layer),
			string(item.Category),
			item.Summary,
			mustJSON(item.Learned),
			mustJSON(item.OpenTasks),
			mustJSON(item.ObservationIDs),
			item.CreatedAt.Format(time.RFC3339Nano),
		); err != nil {
			return fmt.Errorf("compressed memory insert failed: %w", err)
		}

		for position, observationID := range item.ObservationIDs {
			if _, err := tx.Exec(`
				INSERT INTO observation_links (user_id, memory_id, observation_id, position)
				VALUES (?, ?, ?, ?)
			`, userID, item.ID, observationID, position); err != nil {
				return fmt.Errorf("observation link insert failed: %w", err)
			}
		}

		query, args := buildInClause(`
			UPDATE observations
			SET archived = 1, memory_id = ?
			WHERE user_id = ? AND session_id = ? AND id IN (%s)
		`, item.ObservationIDs)
		args = append([]interface{}{item.ID, userID, sessionID}, args...)
		if _, err := tx.Exec(query, args...); err != nil {
			return fmt.Errorf("observation archive failed: %w", err)
		}

		if err := upsertSearchDocument(tx, plan.Document); err != nil {
			return err
		}

		if err := updateSessionUsage(tx, userID, sessionID, plan.UsageAfter); err != nil {
			return err
		}

		return touchSession(tx, userID, sessionID)
	})
}

func (s *SQLiteStore) AddSummary(summary *memory.SessionSummary) error {
	return s.withImmediateTx(func(tx *writeTx) error {
		_, err := tx.Exec(`
			INSERT INTO session_summaries
				(user_id, id, session_id, learned_json, completed_json, next_steps_json, created_at)
			VALUES (?, ?, ?, ?, ?, ?, ?)
		`,
			summary.UserID,
			summary.ID,
			summary.SessionID,
			mustJSON(summary.Learned),
			mustJSON(summary.Completed),
			mustJSON(summary.NextSteps),
			summary.CreatedAt.Format(time.RFC3339Nano),
		)
		if err != nil {
			return fmt.Errorf("summary insert failed: %w", err)
		}
		return touchSession(tx, summary.UserID, summary.SessionID)
	})
}

func (s *SQLiteStore) ListSummaries(userID, sessionID string) ([]memory.SessionSummary, error) {
	return s.listSummaries(s.db, userID, sessionID)
}

func (s *SQLiteStore) listSummaries(q queryer, userID, sessionID string) ([]memory.SessionSummary, error) {
	rows, err := q.Query(`
		SELECT user_id, id, session_id, learned_json, completed_json, next_steps_json, created_at
		FROM session_summaries
		WHERE user_id = ? AND session_id = ?
		ORDER BY created_at DESC
	`, userID, sessionID)
	if err != nil {
		return nil, fmt.Errorf("summary list query failed: %w", err)
	}
	defer rows.Close()
	result := []memory.SessionSummary{}
	for rows.Next() {
		var summary memory.SessionSummary
		var learnedJSON string
		var completedJSON string
		var nextStepsJSON string
		var createdAt string
		if err := rows.Scan(&summary.UserID, &summary.ID, &summary.SessionID, &learnedJSON, &completedJSON, &nextStepsJSON, &createdAt); err != nil {
			return nil, err
		}
		summary.Learned = unmarshalStrings(learnedJSON)
		summary.Completed = unmarshalStrings(completedJSON)
		summary.NextSteps = unmarshalStrings(nextStepsJSON)
		summary.CreatedAt = parseTime(createdAt)
		result = append(result, summary)
	}
	return result, rows.Err()
}

func (s *SQLiteStore) GetLatestSummary(userID, sessionID string) (*memory.SessionSummary, error) {
	row := s.db.QueryRow(`
		SELECT user_id, id, session_id, learned_json, completed_json, next_steps_json, created_at
		FROM session_summaries
		WHERE user_id = ? AND session_id = ?
		ORDER BY created_at DESC
		LIMIT 1
	`, userID, sessionID)
	var summary memory.SessionSummary
	var learnedJSON string
	var completedJSON string
	var nextStepsJSON string
	var createdAt string
	if err := row.Scan(&summary.UserID, &summary.ID, &summary.SessionID, &learnedJSON, &completedJSON, &nextStepsJSON, &createdAt); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	summary.Learned = unmarshalStrings(learnedJSON)
	summary.Completed = unmarshalStrings(completedJSON)
	summary.NextSteps = unmarshalStrings(nextStepsJSON)
	summary.CreatedAt = parseTime(createdAt)
	return &summary, nil
}

func (s *SQLiteStore) UpdateChangeRequestStatus(userID, observationID string, state memory.ChangeRequestState) (*memory.Observation, error) {
	var updated *memory.Observation
	err := s.withImmediateTx(func(tx *writeTx) error {
		currentRow := tx.QueryRow(`SELECT `+observationColumns+`
			FROM observations
			WHERE user_id = ? AND id = ? AND deleted_at = ''
		`, userID, observationID)
		observation, err := scanObservationRow(currentRow)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				return os.ErrNotExist
			}
			return err
		}
		if observation.ChangeRequest == nil {
			observation.ChangeRequest = &memory.ChangeRequestState{}
		}
		observation.ChangeRequest.Status = memory.ChangeRequestStatus(strings.TrimSpace(string(state.Status)))
		if strings.TrimSpace(state.ReasonShort) != "" {
			observation.ChangeRequest.ReasonShort = strings.TrimSpace(state.ReasonShort)
		}
		if strings.TrimSpace(state.DecidedAt) != "" {
			observation.ChangeRequest.DecidedAt = strings.TrimSpace(state.DecidedAt)
		}
		observation.Narrative = memory.RenderChangeRequestNarrative(observation.ChangeRequest)

		if _, err := tx.Exec(`
			UPDATE observations
			SET change_request_json = ?, narrative = ?, archived = 0, memory_id = ''
			WHERE user_id = ? AND id = ?
		`, mustChangeRequestJSON(observation.ChangeRequest), observation.Narrative, userID, observationID); err != nil {
			return err
		}
		updated = observation
		return touchSession(tx, userID, observation.SessionID)
	})
	if err != nil {
		return nil, err
	}
	return updated, nil
}
