package memorystore

import (
	"fmt"
	"time"

	_ "modernc.org/sqlite"
	_ "modernc.org/sqlite/vec"

	"github.com/culpeohq/backend/internal/memory"
)

func (s *SQLiteStore) CreateSession(session *memory.Session) error {
	return s.withImmediateTx(func(tx *writeTx) error {
		_, err := tx.Exec(`
			INSERT INTO memory_sessions
				(user_id, id, project, source, status, goals_json, context_usage_estimate, created_at, updated_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
		`,
			session.UserID,
			session.ID,
			session.Project,
			session.Source,
			string(session.Status),
			mustJSON(session.Goals),
			session.ContextUsageEstimate,
			session.CreatedAt.Format(time.RFC3339Nano),
			session.UpdatedAt.Format(time.RFC3339Nano),
		)
		if err != nil {
			return fmt.Errorf("session insert failed: %w", err)
		}
		return nil
	})
}

func (s *SQLiteStore) GetSession(userID, id string) (*memory.Session, error) {
	return s.getSession(s.db, userID, id)
}

func (s *SQLiteStore) getSession(q queryer, userID, id string) (*memory.Session, error) {
	session, err := s.loadSessionBase(q, userID, id)
	if err != nil {
		return nil, err
	}
	prompts, err := s.listPrompts(q, userID, id, 0)
	if err != nil {
		return nil, err
	}
	observations, err := s.listObservations(q, userID, id)
	if err != nil {
		return nil, err
	}
	memories, err := s.listMemories(q, userID, id)
	if err != nil {
		return nil, err
	}
	summaries, err := s.listSummaries(q, userID, id)
	if err != nil {
		return nil, err
	}
	session.Prompts = prompts
	session.Memories = memories
	session.Summaries = summaries
	session.PromptCount = len(prompts)
	session.ObservationCount = len(observations)
	session.CompressedMemoryCount = len(memories)
	session.SummaryCount = len(summaries)
	session.ActiveObservations = make([]memory.Observation, 0, len(observations))
	session.ArchivedObservations = make([]memory.Observation, 0, len(observations))
	for _, observation := range observations {
		if observation.Archived {
			session.ArchivedObservations = append(session.ArchivedObservations, observation)
		} else {
			session.ActiveObservations = append(session.ActiveObservations, observation)
		}
	}
	return session, nil
}

func (s *SQLiteStore) ListSessions(userID string) ([]*memory.Session, error) {
	rows, err := s.db.Query(`
		SELECT user_id, id, project, source, status, goals_json, context_usage_estimate, created_at, updated_at
		FROM memory_sessions
		WHERE user_id = ?
		ORDER BY updated_at DESC
	`, userID)
	if err != nil {
		return nil, fmt.Errorf("session list query failed: %w", err)
	}
	defer rows.Close()

	result := []*memory.Session{}
	for rows.Next() {
		session, err := scanSessionBase(rows)
		if err != nil {
			return nil, err
		}
		result = append(result, session)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	for _, session := range result {
		counts, countErr := s.loadSessionCounts(s.db, userID, session.ID)
		if countErr != nil {
			return nil, countErr
		}
		session.PromptCount = counts.prompts
		session.ObservationCount = counts.observations
		session.CompressedMemoryCount = counts.memories
		session.SummaryCount = counts.summaries
	}
	return result, nil
}

func (s *SQLiteStore) DeleteSession(userID, id string) error {
	return s.withImmediateTx(func(tx *writeTx) error {
		for _, statement := range []string{
			`DELETE FROM observation_links WHERE observation_id IN (SELECT id FROM observations WHERE user_id = ? AND session_id = ?)`,
			`DELETE FROM search_index WHERE doc_id IN (SELECT doc_id FROM vector_documents WHERE user_id = ? AND session_id = ?)`,
			`DELETE FROM vec_active WHERE doc_id IN (SELECT doc_id FROM vector_documents WHERE user_id = ? AND session_id = ?)`,
			`DELETE FROM vec_hash WHERE doc_id IN (SELECT doc_id FROM vector_documents WHERE user_id = ? AND session_id = ?)`,
			`DELETE FROM vector_documents WHERE user_id = ? AND session_id = ?`,
			`DELETE FROM memory_prompts WHERE user_id = ? AND session_id = ?`,
			`DELETE FROM observations WHERE user_id = ? AND session_id = ?`,
			`DELETE FROM compressed_memories WHERE user_id = ? AND session_id = ?`,
			`DELETE FROM session_summaries WHERE user_id = ? AND session_id = ?`,
			`DELETE FROM memory_sessions WHERE user_id = ? AND id = ?`,
		} {
			if _, err := tx.Exec(statement, userID, id); err != nil {
				return err
			}
		}
		return nil
	})
}
