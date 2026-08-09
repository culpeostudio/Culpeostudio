package memorystore

import (
	"database/sql"
	"errors"
	"os"

	_ "modernc.org/sqlite"
	_ "modernc.org/sqlite/vec"

	"github.com/culpeohq/backend/internal/memory"
)

func (s *SQLiteStore) loadSessionBase(q queryer, userID, id string) (*memory.Session, error) {
	row := q.QueryRow(`
		SELECT user_id, id, project, source, status, goals_json, context_usage_estimate, created_at, updated_at
		FROM memory_sessions
		WHERE user_id = ? AND id = ?
	`, userID, id)
	session, err := scanSessionBase(row)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, os.ErrNotExist
		}
		return nil, err
	}
	return session, nil
}

type scanRow interface {
	Scan(dest ...interface{}) error
}

func scanSessionBase(row scanRow) (*memory.Session, error) {
	var session memory.Session
	var status string
	var goalsJSON string
	var createdAt string
	var updatedAt string
	if err := row.Scan(&session.UserID, &session.ID, &session.Project, &session.Source, &status, &goalsJSON, &session.ContextUsageEstimate, &createdAt, &updatedAt); err != nil {
		return nil, err
	}
	session.Status = memory.SessionStatus(status)
	session.Goals = unmarshalStrings(goalsJSON)
	session.CreatedAt = parseTime(createdAt)
	session.UpdatedAt = parseTime(updatedAt)
	session.Prompts = []memory.Prompt{}
	session.ActiveObservations = []memory.Observation{}
	session.ArchivedObservations = []memory.Observation{}
	session.Memories = []memory.CompressedMemory{}
	session.Summaries = []memory.SessionSummary{}
	return &session, nil
}

func scanObservationRow(row scanRow) (*memory.Observation, error) {
	var tagsJSON string
	var changeRequestJSON string
	var keywordsJSON string
	var personsJSON string
	var entitiesJSON string
	var layer string
	var category string
	var archived int
	var deletedAt string
	var createdAt string
	observation := &memory.Observation{}
	if err := row.Scan(
		&observation.UserID,
		&observation.ID,
		&observation.SessionID,
		&observation.Project,
		&observation.Source,
		&layer,
		&category,
		&observation.Type,
		&observation.Title,
		&observation.Narrative,
		&changeRequestJSON,
		&observation.Speaker,
		&observation.DialogueID,
		&keywordsJSON,
		&personsJSON,
		&entitiesJSON,
		&observation.Topic,
		&observation.Location,
		&observation.ValidFrom,
		&observation.Importance,
		&observation.Confidence,
		&observation.SupersededBy,
		&observation.ToolName,
		&observation.SourcePath,
		&tagsJSON,
		&observation.ContentHash,
		&archived,
		&observation.MemoryID,
		&deletedAt,
		&createdAt,
	); err != nil {
		return nil, err
	}
	observation.Tags = unmarshalStrings(tagsJSON)
	observation.Layer = memory.MemoryLayer(layer)
	observation.Category = memory.MemoryCategory(category)
	observation.ChangeRequest = unmarshalChangeRequest(changeRequestJSON)
	observation.Keywords = unmarshalStrings(keywordsJSON)
	observation.Persons = unmarshalStrings(personsJSON)
	observation.Entities = unmarshalStrings(entitiesJSON)
	observation.Archived = archived == 1
	observation.DeletedAt = deletedAt
	observation.CreatedAt = parseTime(createdAt)
	return observation, nil
}

func scanCompressedMemory(row scanRow) (*memory.CompressedMemory, error) {
	var item memory.CompressedMemory
	var layer string
	var category string
	var learnedJSON string
	var openTasksJSON string
	var observationIDsJSON string
	var correctedByUser int
	var createdAt string
	if err := row.Scan(&item.UserID, &item.ID, &item.SessionID, &layer, &category, &item.Summary, &learnedJSON, &openTasksJSON, &observationIDsJSON, &correctedByUser, &createdAt); err != nil {
		return nil, err
	}
	item.Layer = memory.MemoryLayer(layer)
	item.Category = memory.MemoryCategory(category)
	item.Learned = unmarshalStrings(learnedJSON)
	item.OpenTasks = unmarshalStrings(openTasksJSON)
	item.ObservationIDs = unmarshalStrings(observationIDsJSON)
	item.CorrectedByUser = correctedByUser == 1
	item.CreatedAt = parseTime(createdAt)
	return &item, nil
}

type sessionCounts struct {
	prompts      int
	observations int
	memories     int
	summaries    int
}

func (s *SQLiteStore) loadSessionCounts(q queryer, userID, sessionID string) (sessionCounts, error) {
	counts := sessionCounts{}
	queries := []struct {
		sql  string
		dest *int
	}{
		{`SELECT COUNT(*) FROM memory_prompts WHERE user_id = ? AND session_id = ?`, &counts.prompts},
		{`SELECT COUNT(*) FROM observations WHERE user_id = ? AND session_id = ? AND deleted_at = ''`, &counts.observations},
		{`SELECT COUNT(*) FROM compressed_memories WHERE user_id = ? AND session_id = ?`, &counts.memories},
		{`SELECT COUNT(*) FROM session_summaries WHERE user_id = ? AND session_id = ?`, &counts.summaries},
	}
	for _, query := range queries {
		if err := q.QueryRow(query.sql, userID, sessionID).Scan(query.dest); err != nil {
			return counts, err
		}
	}
	return counts, nil
}
