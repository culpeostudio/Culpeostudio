package memorystore

import (
	"database/sql"
	"errors"
	"fmt"
	"strings"

	_ "modernc.org/sqlite"
	_ "modernc.org/sqlite/vec"
)

func (s *SQLiteStore) CreateVectorIndexTable(name string, dim int) error {
	if dim <= 0 {
		return fmt.Errorf("invalid vector dimension %d", dim)
	}
	return s.withImmediateTx(func(tx *writeTx) error {
		var schemaSQL string
		err := tx.QueryRow("SELECT sql FROM sqlite_schema WHERE name = ?", name).Scan(&schemaSQL)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				// Table does not exist, create it
				_, err = tx.Exec(fmt.Sprintf(`
					CREATE VIRTUAL TABLE %s USING vec0(
						doc_id TEXT PRIMARY KEY,
						embedding int8[%d] distance_metric=cosine
					)
				`, name, dim))
				return err
			}
			return err
		}

		// Table exists, check if dimension or element type (float -> int8
		// migration) matches; the schema text is stored verbatim so a
		// substring check is enough to detect both.
		dimToken := fmt.Sprintf("int8[%d]", dim)
		if !strings.Contains(schemaSQL, dimToken) {
			// Dimension mismatch, drop and recreate
			_, err = tx.Exec(fmt.Sprintf("DROP TABLE %s", name))
			if err != nil {
				return fmt.Errorf("failed to drop legacy vector index table %s: %w", name, err)
			}
			_, err = tx.Exec(fmt.Sprintf(`
				CREATE VIRTUAL TABLE %s USING vec0(
					doc_id TEXT PRIMARY KEY,
					embedding int8[%d] distance_metric=cosine
				)
			`, name, dim))
			return err
		}
		return nil
	})
}

func (s *SQLiteStore) SyncVectorIndex(name, model string) error {
	return s.withImmediateTx(func(tx *writeTx) error {
		rows, err := tx.Query(`
			SELECT doc_id, embedding
			FROM vector_documents
			WHERE embedding_model = ? AND embedding IS NOT NULL
		`, model)
		if err != nil {
			return err
		}
		type pendingVector struct {
			docID string
			blob  []byte
		}
		pending := []pendingVector{}
		for rows.Next() {
			var row pendingVector
			if err := rows.Scan(&row.docID, &row.blob); err != nil {
				rows.Close()
				return err
			}
			pending = append(pending, row)
		}
		if err := rows.Err(); err != nil {
			rows.Close()
			return err
		}
		rows.Close()

		// vec0 virtual tables reject INSERT OR REPLACE on their primary key,
		// so the sync mirrors upsertEmbedding: delete + insert per document.
		// vec_quantize_int8(x, 'unit') assumes a [-1,1] input range, which
		// holds because every embedding backend L2-normalizes its output.
		deleteSQL := fmt.Sprintf(`DELETE FROM %s WHERE doc_id = ?`, name)
		insertSQL := fmt.Sprintf(`INSERT INTO %s(doc_id, embedding) VALUES (?, vec_quantize_int8(?, 'unit'))`, name)
		for _, row := range pending {
			if _, err := tx.Exec(deleteSQL, row.docID); err != nil {
				return err
			}
			if _, err := tx.Exec(insertSQL, row.docID, row.blob); err != nil {
				return err
			}
		}
		return nil
	})
}
