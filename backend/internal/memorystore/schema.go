package memorystore

import (
	"database/sql"
	"fmt"

	_ "modernc.org/sqlite"
	_ "modernc.org/sqlite/vec"

	"github.com/fillyengine/backend/internal/memory"
)

func (s *SQLiteStore) UpdateSessionUsage(userID, sessionID string, usage float64) error {
	return s.withImmediateTx(func(tx *writeTx) error {
		return updateSessionUsage(tx, userID, sessionID, usage)
	})
}

func updateSessionUsage(q queryer, userID, sessionID string, usage float64) error {
	_, err := q.Exec(`
		UPDATE memory_sessions
		SET context_usage_estimate = ?, updated_at = ?
		WHERE user_id = ? AND id = ?
	`, usage, nowString(), userID, sessionID)
	return err
}

func (s *SQLiteStore) UpdateSessionStatus(userID, sessionID string, status memory.SessionStatus) error {
	return s.withImmediateTx(func(tx *writeTx) error {
		_, err := tx.Exec(`
			UPDATE memory_sessions
			SET status = ?, updated_at = ?
			WHERE user_id = ? AND id = ?
		`, string(status), nowString(), userID, sessionID)
		return err
	})
}

func (s *SQLiteStore) migrate() error {
	statements := []string{
		`CREATE TABLE IF NOT EXISTS memory_sessions (
			user_id TEXT NOT NULL DEFAULT 'local',
			id TEXT NOT NULL,
			project TEXT NOT NULL,
			source TEXT NOT NULL,
			status TEXT NOT NULL,
			goals_json TEXT NOT NULL,
			context_usage_estimate REAL NOT NULL DEFAULT 0,
			created_at TEXT NOT NULL,
			updated_at TEXT NOT NULL,
			PRIMARY KEY (user_id, id)
		);`,
		`CREATE TABLE IF NOT EXISTS memory_prompts (
			user_id TEXT NOT NULL DEFAULT 'local',
			id TEXT PRIMARY KEY,
			session_id TEXT NOT NULL,
			role TEXT NOT NULL,
			prompt_text TEXT NOT NULL,
			created_at TEXT NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS observations (
			user_id TEXT NOT NULL DEFAULT 'local',
			id TEXT PRIMARY KEY,
			session_id TEXT NOT NULL,
			project TEXT NOT NULL,
			source TEXT NOT NULL,
			layer TEXT NOT NULL DEFAULT 'project_data',
			category TEXT NOT NULL DEFAULT 'status',
			type TEXT NOT NULL,
			title TEXT NOT NULL,
			narrative TEXT NOT NULL,
			change_request_json TEXT NOT NULL DEFAULT '',
			speaker TEXT NOT NULL DEFAULT '',
			dialogue_id INTEGER NOT NULL DEFAULT 0,
			keywords_json TEXT NOT NULL DEFAULT '[]',
			persons_json TEXT NOT NULL DEFAULT '[]',
			entities_json TEXT NOT NULL DEFAULT '[]',
			topic TEXT NOT NULL DEFAULT '',
			location TEXT NOT NULL DEFAULT '',
			valid_from TEXT NOT NULL DEFAULT '',
			importance REAL NOT NULL DEFAULT 0.5,
			confidence REAL NOT NULL DEFAULT 0,
			superseded_by TEXT NOT NULL DEFAULT '',
			tool_name TEXT NOT NULL DEFAULT '',
			source_path TEXT NOT NULL DEFAULT '',
			tags_json TEXT NOT NULL DEFAULT '[]',
			content_hash TEXT NOT NULL,
			dedup_bucket INTEGER NOT NULL DEFAULT 0,
			archived INTEGER NOT NULL DEFAULT 0,
			memory_id TEXT NOT NULL DEFAULT '',
			deleted_at TEXT NOT NULL DEFAULT '',
			created_at TEXT NOT NULL
		);`,
		`CREATE INDEX IF NOT EXISTS idx_observations_user_session_created ON observations(user_id, session_id, created_at);`,
		`CREATE INDEX IF NOT EXISTS idx_observations_user_hash_created ON observations(user_id, session_id, content_hash, created_at);`,
		`CREATE INDEX IF NOT EXISTS idx_observations_layer_category ON observations(user_id, layer, category, created_at);`,
		`CREATE UNIQUE INDEX IF NOT EXISTS idx_observations_dedup_window ON observations(user_id, session_id, content_hash, dedup_bucket) WHERE dedup_bucket > 0;`,
		`CREATE TABLE IF NOT EXISTS compressed_memories (
			user_id TEXT NOT NULL DEFAULT 'local',
			id TEXT PRIMARY KEY,
			session_id TEXT NOT NULL,
			layer TEXT NOT NULL DEFAULT 'project_data',
			category TEXT NOT NULL DEFAULT 'status',
			summary TEXT NOT NULL,
			learned_json TEXT NOT NULL DEFAULT '[]',
			open_tasks_json TEXT NOT NULL DEFAULT '[]',
			observation_ids_json TEXT NOT NULL DEFAULT '[]',
			corrected_by_user INTEGER NOT NULL DEFAULT 0,
			created_at TEXT NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS session_summaries (
			user_id TEXT NOT NULL DEFAULT 'local',
			id TEXT PRIMARY KEY,
			session_id TEXT NOT NULL,
			learned_json TEXT NOT NULL DEFAULT '[]',
			completed_json TEXT NOT NULL DEFAULT '[]',
			next_steps_json TEXT NOT NULL DEFAULT '[]',
			created_at TEXT NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS observation_links (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT NOT NULL DEFAULT 'local',
			memory_id TEXT NOT NULL,
			observation_id TEXT NOT NULL,
			position INTEGER NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS vector_documents (
			doc_id TEXT PRIMARY KEY,
			user_id TEXT NOT NULL DEFAULT 'local',
			session_id TEXT NOT NULL,
			ref_id TEXT NOT NULL,
			kind TEXT NOT NULL,
			project TEXT NOT NULL,
			source TEXT NOT NULL,
			layer TEXT NOT NULL DEFAULT 'project_data',
			category TEXT NOT NULL DEFAULT 'status',
			observation_type TEXT NOT NULL,
			title TEXT NOT NULL,
			body TEXT NOT NULL,
			source_path TEXT NOT NULL DEFAULT '',
			tags_json TEXT NOT NULL DEFAULT '[]',
			created_at TEXT NOT NULL,
			updated_at TEXT NOT NULL,
			embedding BLOB,
			embedding_model TEXT NOT NULL DEFAULT '',
			embedding_dim INTEGER NOT NULL DEFAULT 0,
			embedded_at TEXT NOT NULL DEFAULT ''
		);`,
		`CREATE INDEX IF NOT EXISTS idx_vector_documents_model ON vector_documents(embedding_model);`,
		`DROP TABLE IF EXISTS vector_ann_buckets;`,
		`CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5(
			doc_id UNINDEXED,
			user_id UNINDEXED,
			kind,
			title,
			body,
			project,
			source,
			observation_type,
			source_path,
			tags
		);`,
	}
	for _, statement := range statements {
		if _, err := s.db.Exec(statement); err != nil {
			return fmt.Errorf("sqlite migration failed: %w", err)
		}
	}
	for _, column := range compatibilityColumns() {
		_, _ = s.db.Exec(fmt.Sprintf(`ALTER TABLE %s ADD COLUMN %s`, column.table, column.definition))
	}
	if err := s.ensureSearchIndexSchema(); err != nil {
		return err
	}
	return nil
}

func touchSession(q queryer, userID, sessionID string) error {
	_, err := q.Exec(`
		UPDATE memory_sessions
		SET updated_at = ?
		WHERE user_id = ? AND id = ?
	`, nowString(), userID, sessionID)
	return err
}

func (s *SQLiteStore) ensureSearchIndexSchema() error {
	rows, err := s.db.Query(`PRAGMA table_info(search_index)`)
	if err != nil {
		return err
	}
	defer rows.Close()

	hasUserID := false
	for rows.Next() {
		var cid int
		var name string
		var columnType string
		var notNull int
		var defaultValue sql.NullString
		var pk int
		if err := rows.Scan(&cid, &name, &columnType, &notNull, &defaultValue, &pk); err != nil {
			return err
		}
		if name == "user_id" {
			hasUserID = true
		}
	}
	if err := rows.Err(); err != nil {
		return err
	}
	if hasUserID {
		return nil
	}

	if _, err := s.db.Exec(`DROP TABLE IF EXISTS search_index`); err != nil {
		return err
	}
	if _, err := s.db.Exec(`CREATE VIRTUAL TABLE search_index USING fts5(
		doc_id UNINDEXED,
		user_id UNINDEXED,
		kind,
		title,
		body,
		project,
		source,
		observation_type,
		source_path,
		tags
	);`); err != nil {
		return err
	}
	return s.rebuildSearchIndex()
}

func (s *SQLiteStore) rebuildSearchIndex() error {
	_, err := s.db.Exec(`
		INSERT INTO search_index
			(doc_id, user_id, kind, title, body, project, source, observation_type, source_path, tags)
		SELECT doc_id, user_id, kind, title, body, project, source, observation_type, source_path, tags_json
		FROM vector_documents
	`)
	return err
}
