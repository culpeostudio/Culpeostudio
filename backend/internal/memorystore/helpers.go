// Package memorystore is the SQLite layer behind memory, including the full-text
// index and the schema migrations.
package memorystore

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	_ "modernc.org/sqlite"
	_ "modernc.org/sqlite/vec"

	"github.com/culpeohq/backend/internal/memory"
)

func mustChangeRequestJSON(value *memory.ChangeRequestState) string {
	if value == nil {
		return ""
	}
	payload, _ := json.Marshal(value)
	return string(payload)
}

func dedupBucket(createdAt time.Time) int64 {
	if createdAt.IsZero() {
		createdAt = time.Now().UTC()
	}
	return createdAt.Unix() / 30
}

func unmarshalChangeRequest(raw string) *memory.ChangeRequestState {
	if strings.TrimSpace(raw) == "" {
		return nil
	}
	var value memory.ChangeRequestState
	if err := json.Unmarshal([]byte(raw), &value); err != nil {
		return nil
	}
	return &value
}

func mustJSON(values []string) string {
	if values == nil {
		values = []string{}
	}
	payload, _ := json.Marshal(values)
	return string(payload)
}

func unmarshalStrings(raw string) []string {
	if strings.TrimSpace(raw) == "" {
		return []string{}
	}
	var values []string
	if err := json.Unmarshal([]byte(raw), &values); err != nil {
		return []string{}
	}
	return values
}

func parseTime(raw string) time.Time {
	parsed, err := time.Parse(time.RFC3339Nano, raw)
	if err != nil {
		return time.Time{}
	}
	return parsed
}

func nowString() string {
	return time.Now().UTC().Format(time.RFC3339Nano)
}

func boolToInt(value bool) int {
	if value {
		return 1
	}
	return 0
}

func buildFTSQuery(query string) string {
	tokens := strings.Fields(strings.ToLower(query))
	clean := []string{}
	for _, token := range tokens {
		filtered := strings.Map(func(r rune) rune {
			switch {
			case r >= 'a' && r <= 'z':
				return r
			case r >= '0' && r <= '9':
				return r
			case r == '_' || r == '-' || r == '/':
				return r
			default:
				return -1
			}
		}, token)
		if filtered != "" {

			clean = append(clean, `"`+filtered+`"*`)
		}
	}
	return strings.Join(clean, " OR ")
}

func appendFilterClauses(alias string, clauses *[]string, args *[]interface{}, filters memory.SearchFilters) {
	prefix := ""
	if strings.TrimSpace(alias) != "" {
		prefix = strings.TrimSpace(alias) + "."
	}
	if strings.TrimSpace(filters.UserID) != "" {
		*clauses = append(*clauses, prefix+"user_id = ?")
		*args = append(*args, strings.TrimSpace(filters.UserID))
	}
	if strings.TrimSpace(filters.Project) != "" {
		*clauses = append(*clauses, prefix+"project = ?")
		*args = append(*args, strings.TrimSpace(filters.Project))
	}
	if strings.TrimSpace(filters.Source) != "" {
		*clauses = append(*clauses, prefix+"source = ?")
		*args = append(*args, strings.TrimSpace(filters.Source))
	}
	if filters.Layer != "" {
		*clauses = append(*clauses, prefix+"layer = ?")
		*args = append(*args, string(filters.Layer))
	}
	if filters.Category != "" {
		*clauses = append(*clauses, prefix+"category = ?")
		*args = append(*args, string(filters.Category))
	}
	if strings.TrimSpace(filters.Type) != "" {
		*clauses = append(*clauses, prefix+"observation_type = ?")
		*args = append(*args, strings.TrimSpace(filters.Type))
	}
}

type compatibilityColumn struct {
	table      string
	definition string
}

func compatibilityColumns() []compatibilityColumn {
	return []compatibilityColumn{
		{"memory_sessions", "user_id TEXT NOT NULL DEFAULT 'local'"},
		{"memory_prompts", "user_id TEXT NOT NULL DEFAULT 'local'"},
		{"observations", "user_id TEXT NOT NULL DEFAULT 'local'"},
		{"observations", "layer TEXT NOT NULL DEFAULT 'project_data'"},
		{"observations", "category TEXT NOT NULL DEFAULT 'status'"},
		{"observations", "change_request_json TEXT NOT NULL DEFAULT ''"},
		{"observations", "speaker TEXT NOT NULL DEFAULT ''"},
		{"observations", "dialogue_id INTEGER NOT NULL DEFAULT 0"},
		{"observations", "keywords_json TEXT NOT NULL DEFAULT '[]'"},
		{"observations", "persons_json TEXT NOT NULL DEFAULT '[]'"},
		{"observations", "entities_json TEXT NOT NULL DEFAULT '[]'"},
		{"observations", "topic TEXT NOT NULL DEFAULT ''"},
		{"observations", "location TEXT NOT NULL DEFAULT ''"},
		{"observations", "valid_from TEXT NOT NULL DEFAULT ''"},
		{"observations", "importance REAL NOT NULL DEFAULT 0.5"},
		{"observations", "confidence REAL NOT NULL DEFAULT 0"},
		{"observations", "superseded_by TEXT NOT NULL DEFAULT ''"},
		{"observations", "dedup_bucket INTEGER NOT NULL DEFAULT 0"},
		{"observations", "deleted_at TEXT NOT NULL DEFAULT ''"},
		{"compressed_memories", "user_id TEXT NOT NULL DEFAULT 'local'"},
		{"compressed_memories", "layer TEXT NOT NULL DEFAULT 'project_data'"},
		{"compressed_memories", "category TEXT NOT NULL DEFAULT 'status'"},
		{"compressed_memories", "corrected_by_user INTEGER NOT NULL DEFAULT 0"},
		{"session_summaries", "user_id TEXT NOT NULL DEFAULT 'local'"},
		{"observation_links", "user_id TEXT NOT NULL DEFAULT 'local'"},
		{"vector_documents", "user_id TEXT NOT NULL DEFAULT 'local'"},
		{"vector_documents", "layer TEXT NOT NULL DEFAULT 'project_data'"},
		{"vector_documents", "category TEXT NOT NULL DEFAULT 'status'"},
		{"vector_documents", "embedding BLOB"},
		{"vector_documents", "embedding_model TEXT NOT NULL DEFAULT ''"},
		{"vector_documents", "embedding_dim INTEGER NOT NULL DEFAULT 0"},
		{"vector_documents", "embedded_at TEXT NOT NULL DEFAULT ''"},
	}
}

func memoryIDs(ids []string) []string {
	result := []string{}
	seen := map[string]struct{}{}
	for _, id := range ids {
		trimmed := strings.TrimSpace(id)
		if trimmed == "" {
			continue
		}
		if _, ok := seen[trimmed]; ok {
			continue
		}
		seen[trimmed] = struct{}{}
		result = append(result, trimmed)
	}
	return result
}

func buildInClause(format string, ids []string) (string, []interface{}) {
	placeholders := make([]string, 0, len(ids))
	args := make([]interface{}, 0, len(ids))
	for _, id := range ids {
		placeholders = append(placeholders, "?")
		args = append(args, id)
	}
	return fmt.Sprintf(format, strings.Join(placeholders, ",")), args
}
