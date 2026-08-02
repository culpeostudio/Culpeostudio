package benchmark

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/parquet-go/parquet-go"
)

func newParquetHub(t *testing.T, tree []treeEntry, handler http.HandlerFunc) *httptest.Server {
	t.Helper()

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if bytes.Contains([]byte(r.URL.Path), []byte("/tree/")) {
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(tree)
			return
		}
		handler(w, r)
	}))
	t.Cleanup(server.Close)
	return server
}

func parquetPayload(t *testing.T, rows []arenaRow) []byte {
	t.Helper()

	var buffer bytes.Buffer
	if err := parquet.Write(&buffer, rows); err != nil {
		t.Fatalf("Parquet schreiben: %v", err)
	}
	return buffer.Bytes()
}

func testQuery() parquetQuery {
	return parquetQuery{dataset: arenaDataset, config: arenaConfig, split: arenaSplit}
}

func TestFetchParquetRowsRetriesTransientFailures(t *testing.T) {
	original := retryDelays
	retryDelays = []time.Duration{time.Millisecond, time.Millisecond}
	t.Cleanup(func() { retryDelays = original })

	payload := parquetPayload(t, []arenaRow{
		arenaRowFor("claude-opus-5", "anthropic", "Proprietary", arenaPrimaryCategory, 1511.6),
	})
	attempts := 0
	server := newParquetHub(t,
		[]treeEntry{{Type: "file", Path: arenaConfig + "/" + arenaSplit + "-00000-of-00001.parquet"}},
		func(w http.ResponseWriter, _ *http.Request) {
			attempts++
			if attempts < 3 {
				w.WriteHeader(http.StatusTooManyRequests)
				return
			}
			_, _ = w.Write(payload)
		})

	rows, err := fetchParquetRows[arenaRow](context.Background(), server.Client(), server.URL, testQuery())
	if err != nil {
		t.Fatalf("fetchParquetRows() error = %v", err)
	}
	if len(rows) != 1 || attempts != 3 {
		t.Fatalf("%d Zeilen nach %d Versuchen", len(rows), attempts)
	}
}

func TestFetchParquetRowsDoesNotRetryPermanentFailures(t *testing.T) {
	original := retryDelays
	retryDelays = []time.Duration{time.Millisecond, time.Millisecond}
	t.Cleanup(func() { retryDelays = original })

	attempts := 0
	server := newParquetHub(t,
		[]treeEntry{{Type: "file", Path: arenaConfig + "/" + arenaSplit + "-00000-of-00001.parquet"}},
		func(w http.ResponseWriter, _ *http.Request) {
			attempts++
			w.WriteHeader(http.StatusNotFound)
		})

	if _, err := fetchParquetRows[arenaRow](context.Background(), server.Client(), server.URL, testQuery()); err == nil {
		t.Fatal("fetchParquetRows() lieferte keinen Fehler")
	}
	if attempts != 1 {
		t.Fatalf("%d Versuche, want 1", attempts)
	}
}

func TestParquetFilesPicksOnlyTheWantedSplit(t *testing.T) {
	t.Parallel()

	server := newParquetHub(t, []treeEntry{
		{Type: "file", Path: arenaConfig + "/full-00000-of-00001.parquet", Size: 49643581},
		{Type: "file", Path: arenaConfig + "/" + arenaSplit + "-00000-of-00002.parquet", Size: 300},
		{Type: "file", Path: arenaConfig + "/" + arenaSplit + "-00001-of-00002.parquet", Size: 300},
		{Type: "directory", Path: arenaConfig + "/altlast"},
		{Type: "file", Path: arenaConfig + "/README.md", Size: 10},
	}, func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusNotFound) })

	paths, err := parquetFiles(context.Background(), server.Client(), server.URL, testQuery())
	if err != nil {
		t.Fatalf("parquetFiles() error = %v", err)
	}
	if len(paths) != 2 {
		t.Fatalf("paths = %v, want beide Teile von %q", paths, arenaSplit)
	}
}

func TestParquetFilesRejectsOversizedFiles(t *testing.T) {
	t.Parallel()

	server := newParquetHub(t, []treeEntry{
		{Type: "file", Path: arenaConfig + "/" + arenaSplit + "-00000-of-00001.parquet", Size: maxParquetBytes + 1},
	}, func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusNotFound) })

	if _, err := parquetFiles(context.Background(), server.Client(), server.URL, testQuery()); err == nil {
		t.Fatal("parquetFiles() nahm eine zu grosse Datei an")
	}
}

func TestParquetFilesReportsAnUnknownSplit(t *testing.T) {
	t.Parallel()

	server := newParquetHub(t, []treeEntry{
		{Type: "file", Path: arenaConfig + "/full-00000-of-00001.parquet", Size: 10},
	}, func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusNotFound) })

	_, err := parquetFiles(context.Background(), server.Client(), server.URL, testQuery())
	if !errors.Is(err, errNoRows) {
		t.Fatalf("err = %v, want %v", err, errNoRows)
	}
}

func TestIsTransientSeparatesOutagesFromRefusals(t *testing.T) {
	t.Parallel()

	for _, code := range []int{http.StatusTooManyRequests, http.StatusInternalServerError, http.StatusBadGateway} {
		if !isTransient(&statusError{code: code}) {
			t.Errorf("%d sollte als voruebergehend gelten", code)
		}
	}
	for _, code := range []int{http.StatusNotFound, http.StatusUnauthorized, http.StatusBadRequest} {
		if isTransient(&statusError{code: code}) {
			t.Errorf("%d sollte nicht wiederholt werden", code)
		}
	}
	if isTransient(context.Canceled) || isTransient(nil) {
		t.Error("Abbruch ist kein voruebergehender Ausfall")
	}
}
