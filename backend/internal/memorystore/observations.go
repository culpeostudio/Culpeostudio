package memorystore

import (
	"database/sql"
	"errors"
	"fmt"
	"log"
	"os"
	"time"

	_ "modernc.org/sqlite"
	_ "modernc.org/sqlite/vec"

	"github.com/culpeohq/backend/internal/memory"
)

func (s *SQLiteStore) FindRecentObservationByHash(userID, sessionID, hash string, since time.Time) (*memory.Observation, error) {
	row := s.db.QueryRow(`SELECT `+observationColumns+`
		FROM observations
		WHERE user_id = ? AND session_id = ? AND content_hash = ? AND deleted_at = '' AND created_at >= ?
		ORDER BY created_at DESC
		LIMIT 1
	`, userID, sessionID, hash, since.Format(time.RFC3339Nano))
	observation, err := scanObservationRow(row)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return observation, nil
}

func (s *SQLiteStore) AddObservation(observation *memory.Observation) error {
	return s.withImmediateTx(func(tx *writeTx) error {
		_, err := tx.Exec(`
			INSERT INTO observations
				(user_id, id, session_id, project, source, layer, category, type, title, narrative, change_request_json, speaker, dialogue_id, keywords_json, persons_json, entities_json, topic, location, valid_from, importance, confidence, superseded_by, tool_name, source_path, tags_json, content_hash, dedup_bucket, archived, memory_id, deleted_at, created_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, '', ?)
		`,
			observation.UserID,
			observation.ID,
			observation.SessionID,
			observation.Project,
			observation.Source,
			string(observation.Layer),
			string(observation.Category),
			observation.Type,
			observation.Title,
			observation.Narrative,
			mustChangeRequestJSON(observation.ChangeRequest),
			observation.Speaker,
			observation.DialogueID,
			mustJSON(observation.Keywords),
			mustJSON(observation.Persons),
			mustJSON(observation.Entities),
			observation.Topic,
			observation.Location,
			observation.ValidFrom,
			observation.Importance,
			observation.Confidence,
			observation.SupersededBy,
			observation.ToolName,
			observation.SourcePath,
			mustJSON(observation.Tags),
			observation.ContentHash,
			dedupBucket(observation.CreatedAt),
			boolToInt(observation.Archived),
			observation.MemoryID,
			observation.CreatedAt.Format(time.RFC3339Nano),
		)
		if err != nil {
			return fmt.Errorf("observation insert failed: %w", err)
		}
		return touchSession(tx, observation.UserID, observation.SessionID)
	})
}

func (s *SQLiteStore) ListObservations(userID, sessionID string) ([]memory.Observation, error) {
	return s.listObservations(s.db, userID, sessionID)
}

func (s *SQLiteStore) listObservations(q queryer, userID, sessionID string) ([]memory.Observation, error) {
	rows, err := q.Query(`SELECT `+observationColumns+`
		FROM observations
		WHERE user_id = ? AND session_id = ? AND deleted_at = ''
		ORDER BY created_at ASC
	`, userID, sessionID)
	if err != nil {
		return nil, fmt.Errorf("observation list query failed: %w", err)
	}
	defer rows.Close()
	result := []memory.Observation{}
	for rows.Next() {
		observation, err := scanObservationRow(rows)
		if err != nil {
			return nil, err
		}
		result = append(result, *observation)
	}
	return result, rows.Err()
}

func (s *SQLiteStore) GetObservationsByIDs(userID string, ids []string) ([]memory.Observation, error) {
	ids = memoryIDs(ids)
	if len(ids) == 0 {
		return []memory.Observation{}, nil
	}
	query, args := buildInClause(`SELECT `+observationColumns+`
		FROM observations
		WHERE user_id = ? AND deleted_at = '' AND id IN (%s)
	`, ids)
	args = append([]interface{}{userID}, args...)
	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, fmt.Errorf("observation get by ids failed: %w", err)
	}
	defer rows.Close()
	observationMap := map[string]memory.Observation{}
	for rows.Next() {
		observation, err := scanObservationRow(rows)
		if err != nil {
			return nil, err
		}
		observationMap[observation.ID] = *observation
	}
	result := make([]memory.Observation, 0, len(ids))
	for _, id := range ids {
		if observation, ok := observationMap[id]; ok {
			result = append(result, observation)
		}
	}
	return result, rows.Err()
}

func (s *SQLiteStore) DeleteObservation(userID, observationID string) (*memory.Observation, bool, error) {
	var deleted *memory.Observation
	tombstoned := false
	err := s.withImmediateTx(func(tx *writeTx) error {
		row := tx.QueryRow(`SELECT `+observationColumns+`
			FROM observations
			WHERE user_id = ? AND id = ? AND deleted_at = ''
		`, userID, observationID)
		observation, err := scanObservationRow(row)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				return os.ErrNotExist
			}
			return err
		}
		docID := "obs:" + observation.ID
		for _, statement := range []string{
			`DELETE FROM search_index WHERE doc_id = ?`,
			`DELETE FROM vec_active WHERE doc_id = ?`,
			`DELETE FROM vec_hash WHERE doc_id = ?`,
			`DELETE FROM vector_documents WHERE doc_id = ?`,
		} {
			if _, err := tx.Exec(statement, docID); err != nil {
				return err
			}
		}
		if observation.Category == memory.CategoryChangeRequest {
			tombstoned = true
			if _, err := tx.Exec(`
				UPDATE observations
				SET deleted_at = ?, dedup_bucket = 0
				WHERE user_id = ? AND id = ?
			`, nowString(), userID, observation.ID); err != nil {
				return err
			}
		} else {
			if _, err := tx.Exec(`DELETE FROM observation_links WHERE user_id = ? AND observation_id = ?`, userID, observation.ID); err != nil {
				return err
			}
			if _, err := tx.Exec(`DELETE FROM observations WHERE user_id = ? AND id = ?`, userID, observation.ID); err != nil {
				return err
			}
		}
		deleted = observation
		return touchSession(tx, userID, observation.SessionID)
	})
	if err != nil {
		return nil, false, err
	}
	return deleted, tombstoned, nil
}

func (s *SQLiteStore) PurgeSoftDeleted(before time.Time) (int, error) {
	cutoff := before.UTC().Format(time.RFC3339Nano)
	var purged int64
	err := s.withImmediateTx(func(tx *writeTx) error {
		if _, err := tx.Exec(`
			DELETE FROM observation_links WHERE observation_id IN (
				SELECT id FROM observations WHERE deleted_at != '' AND deleted_at < ?
			)
		`, cutoff); err != nil {
			return err
		}
		result, err := tx.Exec(`DELETE FROM observations WHERE deleted_at != '' AND deleted_at < ?`, cutoff)
		if err != nil {
			return err
		}
		purged, err = result.RowsAffected()
		return err
	})
	if err != nil {
		return 0, err
	}
	return int(purged), nil
}

type MaintenanceConfig struct {
	SoftDeleteRetention time.Duration
}

const (
	maintenanceVacuumInterval  = 30 * 24 * time.Hour
	maintenanceFTSInterval     = 7 * 24 * time.Hour
	maintenancePurgeInterval   = 24 * time.Hour
	defaultSoftDeleteRetention = 90 * 24 * time.Hour
)

func (s *SQLiteStore) RunMaintenance(stop <-chan struct{}, cfg MaintenanceConfig) {
	retention := cfg.SoftDeleteRetention
	if retention <= 0 {
		retention = defaultSoftDeleteRetention
	}

	vacuumTicker := time.NewTicker(maintenanceVacuumInterval)
	ftsTicker := time.NewTicker(maintenanceFTSInterval)
	purgeTicker := time.NewTicker(maintenancePurgeInterval)
	defer vacuumTicker.Stop()
	defer ftsTicker.Stop()
	defer purgeTicker.Stop()

	for {
		select {
		case <-stop:
			return
		case <-vacuumTicker.C:

			if _, err := s.db.Exec(`VACUUM`); err != nil {
				log.Printf("[memory-maintenance] VACUUM fehlgeschlagen: %v", err)
			}
		case <-ftsTicker.C:
			if _, err := s.db.Exec(`INSERT INTO search_index(search_index) VALUES('optimize')`); err != nil {
				log.Printf("[memory-maintenance] FTS5-Optimize fehlgeschlagen: %v", err)
			}
		case <-purgeTicker.C:
			purged, err := s.PurgeSoftDeleted(time.Now().Add(-retention))
			if err != nil {
				log.Printf("[memory-maintenance] Purge fehlgeschlagen: %v", err)
			} else if purged > 0 {
				log.Printf("[memory-maintenance] %d archivierte Eintraege endgueltig geloescht", purged)
			}
		}
	}
}
