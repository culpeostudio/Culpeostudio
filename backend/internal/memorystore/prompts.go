package memorystore

import (
	"fmt"
	"time"

	_ "modernc.org/sqlite"
	_ "modernc.org/sqlite/vec"

	"github.com/culpeohq/backend/internal/memory"
)

func (s *SQLiteStore) AddPrompt(prompt *memory.Prompt) error {
	return s.withImmediateTx(func(tx *writeTx) error {
		_, err := tx.Exec(`
			INSERT INTO memory_prompts (user_id, id, session_id, role, prompt_text, created_at)
			VALUES (?, ?, ?, ?, ?, ?)
		`, prompt.UserID, prompt.ID, prompt.SessionID, string(prompt.Role), prompt.Text, prompt.CreatedAt.Format(time.RFC3339Nano))
		if err != nil {
			return fmt.Errorf("prompt insert failed: %w", err)
		}
		return touchSession(tx, prompt.UserID, prompt.SessionID)
	})
}

func (s *SQLiteStore) ListPrompts(userID, sessionID string, limit int) ([]memory.Prompt, error) {
	return s.listPrompts(s.db, userID, sessionID, limit)
}

func (s *SQLiteStore) listPrompts(q queryer, userID, sessionID string, limit int) ([]memory.Prompt, error) {
	query := `
		SELECT user_id, id, session_id, role, prompt_text, created_at
		FROM memory_prompts
		WHERE user_id = ? AND session_id = ?
		ORDER BY created_at ASC
	`
	args := []interface{}{userID, sessionID}
	if limit > 0 {
		query += " LIMIT ?"
		args = append(args, limit)
	}
	rows, err := q.Query(query, args...)
	if err != nil {
		return nil, fmt.Errorf("prompt list query failed: %w", err)
	}
	defer rows.Close()
	result := []memory.Prompt{}
	for rows.Next() {
		var prompt memory.Prompt
		var role string
		var createdAt string
		if err := rows.Scan(&prompt.UserID, &prompt.ID, &prompt.SessionID, &role, &prompt.Text, &createdAt); err != nil {
			return nil, err
		}
		prompt.Role = memory.PromptRole(role)
		prompt.CreatedAt = parseTime(createdAt)
		result = append(result, prompt)
	}
	return result, rows.Err()
}
