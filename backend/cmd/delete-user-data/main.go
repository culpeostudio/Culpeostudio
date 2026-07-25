// delete-user-data permanently removes the local data owned by one login.
// Stop the backend before running it so SQLite and JSON stores are not changed
// concurrently with the server process.
package main

import (
	"compress/gzip"
	"database/sql"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/fillyengine/backend/internal/security"
	"github.com/fillyengine/backend/modules/login"
	_ "modernc.org/sqlite"
	_ "modernc.org/sqlite/vec"
)

func main() {
	username := flag.String("username", "", "Benutzername, dessen Daten geloescht werden")
	dataDir := flag.String("data-dir", "data", "Backend-Datenverzeichnis")
	confirm := flag.Bool("confirm", false, "Loeschung wirklich ausfuehren")
	purgeLegacyPhilox := flag.Bool("purge-legacy-philox", false, "auch nicht zuordenbare, alte Philox-Sitzungen loeschen (betrifft alle Benutzer)")
	flag.Parse()

	if strings.TrimSpace(*username) == "" {
		fatal("-username ist erforderlich")
	}
	if !*confirm {
		fatal("Sicherheitsbremse: erneut mit -confirm ausfuehren")
	}

	root := filepath.Clean(*dataDir)
	canonical, accountExists := resolveLogin(root, *username)
	if canonical == "" {
		canonical = strings.TrimSpace(*username)
	}
	memoryUserID := security.SanitizeUserID(canonical)
	if memoryUserID == "" {
		fatal("Benutzername enthaelt keine gueltige Kennung fuer gespeicherte Daten")
	}
	jsonUserID := strings.ToLower(strings.TrimSpace(canonical))

	deleteJSONUser(filepath.Join(root, "bots.json"), jsonUserID, "Bots")
	deleteJSONUser(filepath.Join(root, "engine_user_preferences.json"), jsonUserID, "Engine-Einstellungen")
	deleteMemory(filepath.Join(root, "memory", "memory.db"), memoryUserID)
	deletePhiloxSessions(filepath.Join(root, "philox", "sessions"), memoryUserID, *purgeLegacyPhilox)

	if accountExists {
		deleteLogin(root, canonical)
		fmt.Printf("Login-Account %q geloescht.\n", canonical)
	} else {
		fmt.Printf("Kein Login-Account fuer %q gefunden; vorhandene Nutzdaten wurden trotzdem bereinigt.\n", canonical)
	}
	fmt.Println("Fertig. Gemeinsame Einstellungen und API-Schluessel wurden bewusst nicht beruehrt.")
}

func resolveLogin(root, username string) (string, bool) {
	store := login.NewAccountStore(filepath.Join(root, "login_accounts.json"))
	if err := store.Load(); err != nil {
		fatal("Login-Accounts konnten nicht gelesen werden: %v", err)
	}
	canonical, found := store.CanonicalUsername(username)
	if !found {
		return strings.TrimSpace(username), false
	}
	return canonical, true
}

func deleteLogin(root, username string) {
	store := login.NewAccountStore(filepath.Join(root, "login_accounts.json"))
	if err := store.Load(); err != nil {
		fatal("Login-Accounts konnten nicht gelesen werden: %v", err)
	}
	deleted, err := store.DeleteUser(username)
	if err != nil {
		fatal("Login-Account konnte nicht geloescht werden: %v", err)
	}
	if !deleted {
		fatal("Login-Account %q wurde waehrend der Loeschung nicht gefunden", username)
	}
}

func deleteJSONUser(path, userID, label string) {
	payload, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return
	}
	if err != nil {
		fatal("%s konnten nicht gelesen werden: %v", label, err)
	}
	var document map[string]json.RawMessage
	if err := json.Unmarshal(payload, &document); err != nil {
		fatal("%s enthalten kein gueltiges JSON: %v", label, err)
	}
	var users map[string]json.RawMessage
	if raw, ok := document["users"]; ok {
		if err := json.Unmarshal(raw, &users); err != nil {
			fatal("%s enthalten keine gueltigen Benutzerbereiche: %v", label, err)
		}
	}
	if _, exists := users[userID]; !exists {
		return
	}
	delete(users, userID)
	encoded, err := json.MarshalIndent(users, "", "  ")
	if err != nil {
		fatal("%s konnten nicht serialisiert werden: %v", label, err)
	}
	document["users"] = encoded
	writeJSON(path, document)
	fmt.Printf("%s fuer %q geloescht.\n", label, userID)
}

func writeJSON(path string, value any) {
	payload, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		fatal("JSON konnte nicht serialisiert werden: %v", err)
	}
	temp := path + ".delete-user-data.tmp"
	if err := os.WriteFile(temp, append(payload, '\n'), 0o600); err != nil {
		fatal("Temporäre Datei konnte nicht geschrieben werden: %v", err)
	}
	if err := os.Rename(temp, path); err != nil {
		fatal("Datei konnte nicht ersetzen werden: %v", err)
	}
}

func deleteMemory(path, userID string) {
	if _, err := os.Stat(path); errors.Is(err, os.ErrNotExist) {
		return
	} else if err != nil {
		fatal("Memory-Datenbank konnte nicht geprueft werden: %v", err)
	}
	db, err := sql.Open("sqlite", path)
	if err != nil {
		fatal("Memory-Datenbank konnte nicht geoeffnet werden: %v", err)
	}
	defer db.Close()
	tx, err := db.Begin()
	if err != nil {
		fatal("Memory-Transaktion konnte nicht gestartet werden: %v", err)
	}
	defer tx.Rollback()
	for _, statement := range []string{
		`DELETE FROM observation_links WHERE user_id = ?`,
		`DELETE FROM search_index WHERE doc_id IN (SELECT doc_id FROM vector_documents WHERE user_id = ?)`,
		`DELETE FROM vec_active WHERE doc_id IN (SELECT doc_id FROM vector_documents WHERE user_id = ?)`,
		`DELETE FROM vec_hash WHERE doc_id IN (SELECT doc_id FROM vector_documents WHERE user_id = ?)`,
		`DELETE FROM vector_documents WHERE user_id = ?`,
		`DELETE FROM memory_prompts WHERE user_id = ?`,
		`DELETE FROM observations WHERE user_id = ?`,
		`DELETE FROM compressed_memories WHERE user_id = ?`,
		`DELETE FROM session_summaries WHERE user_id = ?`,
		`DELETE FROM memory_sessions WHERE user_id = ?`,
	} {
		if _, err := tx.Exec(statement, userID); err != nil {
			fatal("Memory-Daten konnten nicht geloescht werden: %v", err)
		}
	}
	if err := tx.Commit(); err != nil {
		fatal("Memory-Loeschung konnte nicht gespeichert werden: %v", err)
	}
	fmt.Printf("Memory, Vektorindex und Chat-Kontext fuer %q geloescht.\n", userID)
}

func deletePhiloxSessions(dir, userID string, purgeLegacy bool) {
	entries, err := os.ReadDir(dir)
	if errors.Is(err, os.ErrNotExist) {
		return
	}
	if err != nil {
		fatal("Philox-Sitzungen konnten nicht gelesen werden: %v", err)
	}
	deleted := 0
	legacy := 0
	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".json.gz") {
			continue
		}
		path := filepath.Join(dir, entry.Name())
		storedUserID, err := philoxUserID(path)
		if err != nil {
			fatal("Philox-Sitzung %s konnte nicht gelesen werden: %v", entry.Name(), err)
		}
		if storedUserID == "" {
			legacy++
			if !purgeLegacy {
				continue
			}
		}
		if storedUserID != "" && storedUserID != userID {
			continue
		}
		if err := os.Remove(path); err != nil {
			fatal("Philox-Sitzung konnte nicht geloescht werden: %v", err)
		}
		_ = os.Remove(strings.TrimSuffix(path, ".json.gz") + ".meta.json")
		deleted++
	}
	if deleted > 0 {
		fmt.Printf("%d Philox-Sitzung(en) geloescht.\n", deleted)
	}
	if legacy > 0 && !purgeLegacy {
		fmt.Printf("%d alte, nicht zuordenbare Philox-Sitzung(en) wurden nicht geloescht. Fuer deren globale Loeschung -purge-legacy-philox verwenden.\n", legacy)
	}
}

func philoxUserID(path string) (string, error) {
	file, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer file.Close()
	reader, err := gzip.NewReader(file)
	if err != nil {
		return "", err
	}
	defer reader.Close()
	var session struct {
		UserID string `json:"user_id"`
	}
	if err := json.NewDecoder(reader).Decode(&session); err != nil {
		return "", err
	}
	return security.SanitizeUserID(session.UserID), nil
}

func fatal(format string, args ...any) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(1)
}
