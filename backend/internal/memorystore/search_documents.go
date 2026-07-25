package memorystore

import (
	"database/sql"
	"fmt"
	"math"
	"strings"
	"time"

	_ "modernc.org/sqlite"
	_ "modernc.org/sqlite/vec"

	"github.com/fillyengine/backend/internal/memory"
)

func (s *SQLiteStore) UpsertSearchDocument(document memory.SearchDocument) error {
	return s.withImmediateTx(func(tx *writeTx) error {
		return upsertSearchDocument(tx, document)
	})
}

// upsertSearchDocument writes the document metadata and the FTS row. It
// resets the embedding columns so the vector layer (or the background
// reindexer) re-embeds the changed body.
func upsertSearchDocument(q queryer, document memory.SearchDocument) error {
	tagsJSON := mustJSON(document.Tags)
	if _, err := q.Exec(`
		INSERT INTO vector_documents
			(doc_id, user_id, session_id, ref_id, kind, project, source, layer, category, observation_type, title, body, source_path, tags_json, created_at, updated_at, embedding, embedding_model, embedding_dim, embedded_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, '', 0, '')
		ON CONFLICT(doc_id) DO UPDATE SET
			user_id = excluded.user_id,
			session_id = excluded.session_id,
			ref_id = excluded.ref_id,
			kind = excluded.kind,
			project = excluded.project,
			source = excluded.source,
			layer = excluded.layer,
			category = excluded.category,
			observation_type = excluded.observation_type,
			title = excluded.title,
			body = excluded.body,
			source_path = excluded.source_path,
			tags_json = excluded.tags_json,
			created_at = excluded.created_at,
			updated_at = excluded.updated_at,
			embedding = NULL,
			embedding_model = '',
			embedding_dim = 0,
			embedded_at = ''
	`,
		document.DocID,
		document.UserID,
		document.SessionID,
		document.RefID,
		document.Kind,
		document.Project,
		document.Source,
		string(document.Layer),
		string(document.Category),
		document.Type,
		document.Title,
		document.Body,
		document.SourcePath,
		tagsJSON,
		document.CreatedAt.Format(time.RFC3339Nano),
		time.Now().UTC().Format(time.RFC3339Nano),
	); err != nil {
		return err
	}
	if _, err := q.Exec(`DELETE FROM vec_active WHERE doc_id = ?`, document.DocID); err != nil {
		return err
	}
	if _, err := q.Exec(`DELETE FROM vec_hash WHERE doc_id = ?`, document.DocID); err != nil {
		return err
	}
	if _, err := q.Exec(`DELETE FROM search_index WHERE doc_id = ?`, document.DocID); err != nil {
		return err
	}
	if _, err := q.Exec(`
		INSERT INTO search_index
			(doc_id, user_id, kind, title, body, project, source, observation_type, source_path, tags)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`,
		document.DocID,
		document.UserID,
		document.Kind,
		document.Title,
		document.Body,
		document.Project,
		document.Source,
		document.Type,
		document.SourcePath,
		strings.Join(document.Tags, " "),
	); err != nil {
		return err
	}
	return nil
}

func (s *SQLiteStore) DeleteSearchDocument(docID string) error {
	return s.withImmediateTx(func(tx *writeTx) error {
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
		return nil
	})
}

func (s *SQLiteStore) SearchDocuments(query string, filters memory.SearchFilters, limit int) ([]memory.SearchDocument, error) {
	if limit <= 0 {
		limit = 10
	}
	ftsQuery := buildFTSQuery(query)
	if ftsQuery == "" {
		return s.ListDocuments(filters, limit)
	}
	clauses := []string{`search_index MATCH ?`}
	args := []interface{}{ftsQuery}
	appendFilterClauses("d", &clauses, &args, filters)
	sqlQuery := fmt.Sprintf(`
		SELECT d.doc_id, d.user_id, d.session_id, d.ref_id, d.kind, d.project, d.source, d.layer, d.category, d.observation_type, d.title, d.body, d.source_path, d.tags_json, d.created_at, bm25(search_index) AS rank
		FROM search_index
		JOIN vector_documents d ON d.doc_id = search_index.doc_id
		WHERE %s
		ORDER BY rank
		LIMIT ?
	`, strings.Join(clauses, " AND "))
	args = append(args, limit)
	rows, err := s.db.Query(sqlQuery, args...)
	if err != nil {
		return nil, fmt.Errorf("fts search failed: %w", err)
	}
	defer rows.Close()
	result := []memory.SearchDocument{}
	for rows.Next() {
		var document memory.SearchDocument
		var layer string
		var category string
		var tagsJSON string
		var createdAt string
		var rank float64
		if err := rows.Scan(
			&document.DocID,
			&document.UserID,
			&document.SessionID,
			&document.RefID,
			&document.Kind,
			&document.Project,
			&document.Source,
			&layer,
			&category,
			&document.Type,
			&document.Title,
			&document.Body,
			&document.SourcePath,
			&tagsJSON,
			&createdAt,
			&rank,
		); err != nil {
			return nil, err
		}
		document.Layer = memory.MemoryLayer(layer)
		document.Category = memory.MemoryCategory(category)
		document.Tags = unmarshalStrings(tagsJSON)
		document.CreatedAt = parseTime(createdAt)
		document.TextScore = 1 / (1 + math.Abs(rank))
		result = append(result, document)
	}
	return result, rows.Err()
}

func (s *SQLiteStore) ListDocuments(filters memory.SearchFilters, limit int) ([]memory.SearchDocument, error) {
	if limit <= 0 {
		limit = 50
	}
	clauses := []string{"1=1"}
	args := []interface{}{}
	appendFilterClauses("", &clauses, &args, filters)
	query := fmt.Sprintf(`
		SELECT `+documentColumns+`
		FROM vector_documents
		WHERE %s
		ORDER BY created_at DESC
		LIMIT ?
	`, strings.Join(clauses, " AND "))
	args = append(args, limit)
	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, fmt.Errorf("document list failed: %w", err)
	}
	defer rows.Close()
	return scanDocuments(rows)
}

func (s *SQLiteStore) GetSearchDocumentsByIDs(userID string, docIDs []string) ([]memory.SearchDocument, error) {
	docIDs = memoryIDs(docIDs)
	if len(docIDs) == 0 {
		return []memory.SearchDocument{}, nil
	}
	query, args := buildInClause(`
		SELECT `+documentColumns+`
		FROM vector_documents
		WHERE user_id = ? AND doc_id IN (%s)
	`, docIDs)
	args = append([]interface{}{userID}, args...)
	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, fmt.Errorf("document get by ids failed: %w", err)
	}
	defer rows.Close()
	return scanDocuments(rows)
}

func scanDocuments(rows *sql.Rows) ([]memory.SearchDocument, error) {
	result := []memory.SearchDocument{}
	for rows.Next() {
		var document memory.SearchDocument
		var layer string
		var category string
		var tagsJSON string
		var createdAt string
		if err := rows.Scan(
			&document.DocID,
			&document.UserID,
			&document.SessionID,
			&document.RefID,
			&document.Kind,
			&document.Project,
			&document.Source,
			&layer,
			&category,
			&document.Type,
			&document.Title,
			&document.Body,
			&document.SourcePath,
			&tagsJSON,
			&createdAt,
		); err != nil {
			return nil, err
		}
		document.Tags = unmarshalStrings(tagsJSON)
		document.Layer = memory.MemoryLayer(layer)
		document.Category = memory.MemoryCategory(category)
		document.CreatedAt = parseTime(createdAt)
		result = append(result, document)
	}
	return result, rows.Err()
}
