package memorystore

import (
	"encoding/binary"
	"fmt"
	"math"
	"strings"

	"github.com/fillyengine/backend/internal/memory"
)

func isHashModel(model string) bool {
	return strings.HasPrefix(model, "hash-")
}

type EmbeddingRecord struct {
	DocID     string
	Embedding []float32
	Model     string
}

type EmbeddedDocument struct {
	Document  memory.SearchDocument
	Embedding []float32
	Model     string
}

func (s *SQLiteStore) UpsertEmbedding(record EmbeddingRecord) error {
	return s.withImmediateTx(func(tx *writeTx) error {
		return upsertEmbedding(tx, record)
	})
}

func (s *SQLiteStore) UpsertEmbeddingBatch(records []EmbeddingRecord) error {
	if len(records) == 0 {
		return nil
	}
	return s.withImmediateTx(func(tx *writeTx) error {
		for _, record := range records {
			if err := upsertEmbedding(tx, record); err != nil {
				return err
			}
		}
		return nil
	})
}

func upsertEmbedding(tx *writeTx, record EmbeddingRecord) error {
	result, err := tx.Exec(`
		UPDATE vector_documents
		SET embedding = ?, embedding_model = ?, embedding_dim = ?, embedded_at = ?
		WHERE doc_id = ?
	`, encodeVector(record.Embedding), record.Model, len(record.Embedding), nowString(), record.DocID)
	if err != nil {
		return fmt.Errorf("embedding update failed: %w", err)
	}
	if affected, err := result.RowsAffected(); err == nil && affected == 0 {

		return nil
	}

	if _, err := tx.Exec(`DELETE FROM vec_active WHERE doc_id = ?`, record.DocID); err != nil {
		return err
	}
	if _, err := tx.Exec(`DELETE FROM vec_hash WHERE doc_id = ?`, record.DocID); err != nil {
		return err
	}

	targetTable := "vec_active"
	if isHashModel(record.Model) {
		targetTable = "vec_hash"
	}

	_, err = tx.Exec(fmt.Sprintf(`
		INSERT INTO %s(doc_id, embedding)
		VALUES (?, vec_quantize_int8(?, 'unit'))
	`, targetTable), record.DocID, encodeVector(record.Embedding))
	return err
}

func (s *SQLiteStore) DeleteEmbedding(docID string) error {
	return s.withImmediateTx(func(tx *writeTx) error {
		if _, err := tx.Exec(`DELETE FROM vec_active WHERE doc_id = ?`, docID); err != nil {
			return err
		}
		if _, err := tx.Exec(`DELETE FROM vec_hash WHERE doc_id = ?`, docID); err != nil {
			return err
		}
		_, err := tx.Exec(`
			UPDATE vector_documents
			SET embedding = NULL, embedding_model = '', embedding_dim = 0, embedded_at = ''
			WHERE doc_id = ?
		`, docID)
		return err
	})
}

func (s *SQLiteStore) CandidateDocuments(model string, queryVector []float32, filters memory.SearchFilters, fillLimit int) ([]EmbeddedDocument, error) {
	if fillLimit <= 0 {
		fillLimit = 256
	}

	targetTable := "vec_active"
	if isHashModel(model) {
		targetTable = "vec_hash"
	}

	clauses := []string{"d.embedding_model = ?"}
	args := []interface{}{model}
	appendFilterClauses("d", &clauses, &args, filters)

	query := fmt.Sprintf(`
		SELECT d.doc_id, d.user_id, d.session_id, d.ref_id, d.kind, d.project, d.source, d.layer, d.category, d.observation_type, d.title, d.body, d.source_path, d.tags_json, d.created_at, d.embedding, d.embedding_model
		FROM (
			SELECT doc_id, distance
			FROM %s
			WHERE embedding MATCH vec_quantize_int8(?, 'unit')
			LIMIT %d
		) v
		JOIN vector_documents d ON d.doc_id = v.doc_id
		WHERE %s
		ORDER BY v.distance
	`, targetTable, fillLimit, strings.Join(clauses, " AND "))

	finalArgs := append([]interface{}{encodeVector(queryVector)}, args...)

	rows, err := s.db.Query(query, finalArgs...)
	if err != nil {
		return nil, fmt.Errorf("sqlite-vec candidate query failed: %w", err)
	}
	defer rows.Close()

	return scanEmbeddedDocuments(rows)
}

func (s *SQLiteStore) CountDocsNotEmbeddedWith(model string) (int, error) {
	var count int
	err := s.db.QueryRow(`
		SELECT COUNT(*) FROM vector_documents WHERE embedding_model != ?
	`, model).Scan(&count)
	return count, err
}

func (s *SQLiteStore) ListDocsForReindex(model string, limit int) ([]memory.SearchDocument, error) {
	if limit <= 0 {
		limit = 64
	}
	rows, err := s.db.Query(`
		SELECT `+documentColumns+`
		FROM vector_documents
		WHERE embedding_model != ?
		ORDER BY created_at DESC
		LIMIT ?
	`, model, limit)
	if err != nil {
		return nil, fmt.Errorf("reindex list query failed: %w", err)
	}
	defer rows.Close()
	return scanDocuments(rows)
}

func (s *SQLiteStore) ImportLegacyVectors(vectors map[string][]float32, model string) (int, error) {
	imported := 0
	err := s.withImmediateTx(func(tx *writeTx) error {
		for docID, vector := range vectors {
			if len(vector) == 0 {
				continue
			}
			result, err := tx.Exec(`
				UPDATE vector_documents
				SET embedding = ?, embedding_model = ?, embedding_dim = ?, embedded_at = ?
				WHERE doc_id = ? AND embedding_model = ''
			`, encodeVector(vector), model, len(vector), nowString(), docID)
			if err != nil {
				return err
			}
			affected, err := result.RowsAffected()
			if err != nil || affected == 0 {
				continue
			}

			if _, err := tx.Exec(`DELETE FROM vec_active WHERE doc_id = ?`, docID); err != nil {
				return err
			}
			if _, err := tx.Exec(`DELETE FROM vec_hash WHERE doc_id = ?`, docID); err != nil {
				return err
			}

			targetTable := "vec_active"
			if isHashModel(model) {
				targetTable = "vec_hash"
			}

			_, err = tx.Exec(fmt.Sprintf(`
				INSERT INTO %s(doc_id, embedding)
				VALUES (?, vec_quantize_int8(?, 'unit'))
			`, targetTable), docID, encodeVector(vector))
			if err != nil {
				return err
			}

			imported++
		}
		return nil
	})
	if err != nil {
		return 0, err
	}
	return imported, nil
}

func (s *SQLiteStore) CountEmbeddingsByModel() (map[string]int, error) {
	rows, err := s.db.Query(`
		SELECT embedding_model, COUNT(*) FROM vector_documents GROUP BY embedding_model
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	result := map[string]int{}
	for rows.Next() {
		var model string
		var count int
		if err := rows.Scan(&model, &count); err != nil {
			return nil, err
		}
		if model == "" {
			model = "(none)"
		}
		result[model] = count
	}
	return result, rows.Err()
}

func scanEmbeddedDocuments(rows interface {
	Next() bool
	Scan(dest ...interface{}) error
	Err() error
	Close() error
}) ([]EmbeddedDocument, error) {
	defer rows.Close()
	result := []EmbeddedDocument{}
	for rows.Next() {
		var document memory.SearchDocument
		var layer string
		var category string
		var tagsJSON string
		var createdAt string
		var blob []byte
		var model string
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
			&blob,
			&model,
		); err != nil {
			return nil, err
		}
		document.Layer = memory.MemoryLayer(layer)
		document.Category = memory.MemoryCategory(category)
		document.Tags = unmarshalStrings(tagsJSON)
		document.CreatedAt = parseTime(createdAt)
		embedding := decodeVector(blob)
		if len(embedding) == 0 {
			continue
		}
		result = append(result, EmbeddedDocument{Document: document, Embedding: embedding, Model: model})
	}
	return result, rows.Err()
}

func encodeVector(vector []float32) []byte {
	buffer := make([]byte, 4*len(vector))
	for i, value := range vector {
		binary.LittleEndian.PutUint32(buffer[i*4:], math.Float32bits(value))
	}
	return buffer
}

func decodeVector(blob []byte) []float32 {
	if len(blob) == 0 || len(blob)%4 != 0 {
		return nil
	}
	vector := make([]float32, len(blob)/4)
	for i := range vector {
		vector[i] = math.Float32frombits(binary.LittleEndian.Uint32(blob[i*4:]))
	}
	return vector
}
