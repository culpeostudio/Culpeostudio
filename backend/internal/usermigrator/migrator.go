package usermigrator

import (
	"database/sql"
	"encoding/json"
	"errors"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/culpeohq/backend/internal/security"
	_ "modernc.org/sqlite"
)

// MigrateData moves all per-user data (JSON preferences, sessions, databases) from an old user to a new user.
// This is typically used to move data from 'guest' to the first registered user.
func MigrateData(dataDir, oldUsername, newUsername string) error {
	oldMemoryID := security.SanitizeUserID(oldUsername)
	newMemoryID := security.SanitizeUserID(newUsername)

	oldJSONID := strings.ToLower(strings.TrimSpace(oldUsername))
	newJSONID := strings.ToLower(strings.TrimSpace(newUsername))

	if oldMemoryID == "" || newMemoryID == "" || oldJSONID == "" || newJSONID == "" {
		return errors.New("ungueltige Benutzernamen")
	}

	migrateJSONUser(filepath.Join(dataDir, "bots.json"), oldJSONID, newJSONID)
	migrateJSONUser(filepath.Join(dataDir, "engine_user_preferences.json"), oldJSONID, newJSONID)
	migrateJSONUser(filepath.Join(dataDir, "user_preferences.json"), oldJSONID, newJSONID)

	migrateOwnedRecords(filepath.Join(dataDir, "scout_sessions"), oldJSONID, newJSONID)
	migrateOwnedRecords(filepath.Join(dataDir, "spark_projects"), oldJSONID, newJSONID)

	migrateMemory(filepath.Join(dataDir, "memory", "memory.db"), oldMemoryID, newMemoryID)

	return nil
}

func migrateJSONUser(path, oldUserID, newUserID string) {
	payload, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return
	}
	if err != nil {
		log.Printf("Warnung: %s konnte nicht gelesen werden: %v", path, err)
		return
	}

	var document map[string]json.RawMessage
	if err := json.Unmarshal(payload, &document); err != nil {
		log.Printf("Warnung: %s ist kein gueltiges JSON: %v", path, err)
		return
	}

	var users map[string]json.RawMessage
	if raw, ok := document["users"]; ok {
		if err := json.Unmarshal(raw, &users); err != nil {
			log.Printf("Warnung: %s users-Feld ungueltig: %v", path, err)
			return
		}
	} else {
		return
	}

	userData, exists := users[oldUserID]
	if !exists {
		return
	}

	delete(users, oldUserID)
	users[newUserID] = userData

	encoded, err := json.MarshalIndent(users, "", "  ")
	if err != nil {
		log.Printf("Warnung: %s konnte nicht serialisiert werden: %v", path, err)
		return
	}

	document["users"] = encoded
	writeJSON(path, document)
}

func writeJSON(path string, value any) {
	payload, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		log.Printf("Fehler beim Serialisieren fuer %s: %v", path, err)
		return
	}
	temp := path + ".migrate.tmp"
	if err := os.WriteFile(temp, append(payload, '\n'), 0o600); err != nil {
		log.Printf("Fehler beim Schreiben der Temp-Datei %s: %v", temp, err)
		return
	}
	if err := os.Rename(temp, path); err != nil {
		log.Printf("Fehler beim Ersetzen der Datei %s: %v", path, err)
	}
}

func migrateOwnedRecords(dir, oldUserID, newUserID string) {
	entries, err := os.ReadDir(dir)
	if errors.Is(err, os.ErrNotExist) {
		return
	}
	if err != nil {
		log.Printf("Warnung: Verzeichnis %s konnte nicht gelesen werden: %v", dir, err)
		return
	}

	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".json") {
			continue
		}
		path := filepath.Join(dir, entry.Name())
		content, readErr := os.ReadFile(path)
		if readErr != nil {
			continue
		}

		var record map[string]any
		if err := json.Unmarshal(content, &record); err != nil {
			continue
		}

		recordUserID, ok := record["UserID"].(string)
		if !ok {
			// Some formats use lowercase user_id
			recordUserID, ok = record["user_id"].(string)
			if !ok {
				continue
			}
			if strings.ToLower(strings.TrimSpace(recordUserID)) == oldUserID {
				record["user_id"] = newUserID
				writeJSON(path, record)
			}
			continue
		}

		if strings.ToLower(strings.TrimSpace(recordUserID)) == oldUserID {
			record["UserID"] = newUserID
			writeJSON(path, record)
		}
	}
}

func migrateMemory(path, oldUserID, newUserID string) {
	if _, err := os.Stat(path); errors.Is(err, os.ErrNotExist) {
		return
	} else if err != nil {
		log.Printf("Memory-Datenbank Fehler: %v", err)
		return
	}

	db, err := sql.Open("sqlite", path)
	if err != nil {
		log.Printf("Memory-Datenbank konnte nicht geoeffnet werden: %v", err)
		return
	}
	defer db.Close()

	tx, err := db.Begin()
	if err != nil {
		log.Printf("Memory-Transaktion fehlerhaft: %v", err)
		return
	}
	defer tx.Rollback()

	tables := []string{
		"observation_links",
		"vector_documents",
		"memory_prompts",
		"observations",
		"compressed_memories",
		"session_summaries",
		"memory_sessions",
	}

	for _, table := range tables {
		query := "UPDATE " + table + " SET user_id = ? WHERE user_id = ?"
		if _, err := tx.Exec(query, newUserID, oldUserID); err != nil {
			log.Printf("Fehler beim Migrieren von %s: %v", table, err)
			return
		}
	}

	if err := tx.Commit(); err != nil {
		log.Printf("Fehler beim Speichern der Memory-Migration: %v", err)
	}
}
