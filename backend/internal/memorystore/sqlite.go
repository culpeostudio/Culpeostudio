package memorystore

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sync"

	_ "modernc.org/sqlite"
	_ "modernc.org/sqlite/vec"
)

// SQLiteStore is the canonical store. Concurrency model:
//   - journal_mode=WAL so readers never block on the single writer
//   - busy_timeout=5000 so a waiting connection retries instead of failing
//     immediately with SQLITE_BUSY
//   - every write runs through one dedicated, permanently held connection
//     that issues an explicit BEGIN IMMEDIATE. Go SQLite drivers do not map
//     TxOptions.Isolation onto SQLite locking, so db.BeginTx would only give
//     a deferred transaction; the raw statement on a pinned *sql.Conn is the
//     only reliable way to take the write lock up front.
type SQLiteStore struct {
	path      string
	db        *sql.DB
	writeConn *sql.Conn
	writeMu   sync.Mutex
}

const observationColumns = `user_id, id, session_id, project, source, layer, category, type, title, narrative, change_request_json, speaker, dialogue_id, keywords_json, persons_json, entities_json, topic, location, valid_from, importance, confidence, superseded_by, tool_name, source_path, tags_json, content_hash, archived, memory_id, deleted_at, created_at`

const documentColumns = `doc_id, user_id, session_id, ref_id, kind, project, source, layer, category, observation_type, title, body, source_path, tags_json, created_at`

func NewSQLiteStore(path string) *SQLiteStore {
	return &SQLiteStore{path: path}
}

func (s *SQLiteStore) Initialize() error {
	if err := os.MkdirAll(filepath.Dir(s.path), 0o755); err != nil {
		return fmt.Errorf("sqlite dir create failed: %w", err)
	}
	dsn := "file:" + s.path +
		"?_pragma=busy_timeout(5000)" +
		"&_pragma=journal_mode(WAL)" +
		"&_pragma=synchronous(NORMAL)" +
		// Caps how large the -wal file is allowed to grow before a checkpoint
		// truncates it back down, so heavy write bursts cannot fill the disk.
		"&_pragma=journal_size_limit(67108864)"
	db, err := sql.Open("sqlite", dsn)
	if err != nil {
		return fmt.Errorf("sqlite open failed: %w", err)
	}
	// WAL allows many parallel readers next to the single writer connection.
	db.SetMaxOpenConns(4)
	db.SetMaxIdleConns(4)
	s.db = db
	writeConn, err := db.Conn(context.Background())
	if err != nil {
		return fmt.Errorf("sqlite write connection failed: %w", err)
	}
	s.writeConn = writeConn
	return s.migrate()
}

func (s *SQLiteStore) Close() error {
	if s.writeConn != nil {
		_ = s.writeConn.Close()
	}
	if s.db != nil {
		return s.db.Close()
	}
	return nil
}

// queryer lets read helpers run either on the pool or inside a write tx.
// It is public so other packages can use it.
type Queryer interface {
	Exec(query string, args ...interface{}) (sql.Result, error)
	Query(query string, args ...interface{}) (*sql.Rows, error)
	QueryRow(query string, args ...interface{}) *sql.Row
}

type queryer interface {
	Exec(query string, args ...interface{}) (sql.Result, error)
	Query(query string, args ...interface{}) (*sql.Rows, error)
	QueryRow(query string, args ...interface{}) *sql.Row
}

type writeTx struct {
	ctx  context.Context
	conn *sql.Conn
}

func (t *writeTx) Exec(query string, args ...interface{}) (sql.Result, error) {
	return t.conn.ExecContext(t.ctx, query, args...)
}

func (t *writeTx) Query(query string, args ...interface{}) (*sql.Rows, error) {
	return t.conn.QueryContext(t.ctx, query, args...)
}

func (t *writeTx) QueryRow(query string, args ...interface{}) *sql.Row {
	return t.conn.QueryRowContext(t.ctx, query, args...)
}

// withImmediateTx serializes all writes of this process onto the held
// connection and wraps fn in an explicit BEGIN IMMEDIATE ... COMMIT.
func (s *SQLiteStore) withImmediateTx(fn func(tx *writeTx) error) error {
	s.writeMu.Lock()
	defer s.writeMu.Unlock()
	ctx := context.Background()
	if _, err := s.writeConn.ExecContext(ctx, "BEGIN IMMEDIATE"); err != nil {
		return fmt.Errorf("begin immediate failed: %w", err)
	}
	tx := &writeTx{ctx: ctx, conn: s.writeConn}
	if err := fn(tx); err != nil {
		rollbackOnError(ctx, s.writeConn, err)
		return err
	}
	if _, err := s.writeConn.ExecContext(ctx, "COMMIT"); err != nil {
		rollbackOnError(ctx, s.writeConn, err)
		return fmt.Errorf("commit failed: %w", err)
	}
	return nil
}

// rollbackOnError setzt eine offene Transaktion zurueck und loggt einen
// fehlgeschlagenen ROLLBACK laut. Frueher wurde dieser Fehler verschluckt
// (`_, _ =`): schlaegt der ROLLBACK fehl (z. B. bei Korruption), bleibt die
// serialisierte Write-Verbindung in einer offenen Transaktion haengen und JEDE
// folgende Schreiboperation dieses Prozesses scheitert still — der Reindexer
// dreht dann endlos leer. Sichtbar geloggt kann das Problem wenigstens erkannt
// werden.
func rollbackOnError(ctx context.Context, conn *sql.Conn, cause error) {
	if _, err := conn.ExecContext(ctx, "ROLLBACK"); err != nil {
		log.Printf("[memorystore] ROLLBACK fehlgeschlagen nach Fehler %v: %v — Write-Verbindung moeglicherweise in inkonsistentem Zustand", cause, err)
	}
}
