package benchmark

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/parquet-go/parquet-go"
)

const (
	maxParquetBytes = 32 << 20

	hubRevision = "main"
)

type endpoints struct {
	hub string
}

func defaultEndpoints() endpoints {
	return endpoints{hub: "https://huggingface.co"}
}

type parquetQuery struct {
	dataset string
	config  string
	split   string

	token string
}

var retryDelays = []time.Duration{2 * time.Second, 6 * time.Second}

var errNoRows = errors.New("hub lieferte keine Zeilen")

type statusError struct {
	code int
	body string
}

func (e *statusError) Error() string {
	return fmt.Sprintf("hub antwortete mit %d: %s", e.code, e.body)
}

func isTransient(err error) bool {
	if err == nil {
		return false
	}
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return false
	}
	var status *statusError
	if errors.As(err, &status) {

		return status.code == http.StatusTooManyRequests || status.code >= 500
	}

	message := err.Error()
	return strings.Contains(message, "EOF") || strings.Contains(message, "connection reset")
}

func fetchParquetRows[T any](ctx context.Context, client *http.Client, hubBase string, query parquetQuery) ([]T, error) {
	paths, err := parquetFiles(ctx, client, hubBase, query)
	if err != nil {
		return nil, err
	}

	collected := make([]T, 0, 1024)
	for _, path := range paths {
		payload, err := downloadWithRetry(ctx, client, resolveURL(hubBase, query.dataset, path), query.token)
		if err != nil {

			return nil, err
		}
		rows, err := parquet.Read[T](bytes.NewReader(payload), int64(len(payload)))
		if err != nil {
			return nil, fmt.Errorf("%s ist unlesbar: %w", path, err)
		}
		collected = append(collected, rows...)
	}

	if len(collected) == 0 {
		return nil, fmt.Errorf("%w fuer %s/%s", errNoRows, query.dataset, query.config)
	}
	return collected, nil
}

type treeEntry struct {
	Type string `json:"type"`
	Path string `json:"path"`
	Size int64  `json:"size"`
}

func parquetFiles(ctx context.Context, client *http.Client, hubBase string, query parquetQuery) ([]string, error) {
	endpoint := strings.TrimRight(hubBase, "/") + "/api/datasets/" +
		strings.Trim(query.dataset, "/") + "/tree/" + hubRevision + "/" + url.PathEscape(query.config)

	payload, err := downloadWithRetry(ctx, client, endpoint, query.token)
	if err != nil {
		return nil, err
	}

	var entries []treeEntry
	if err := json.Unmarshal(payload, &entries); err != nil {
		return nil, fmt.Errorf("verzeichnis von %s unlesbar: %w", query.dataset, err)
	}

	prefix := query.config + "/" + query.split + "-"
	paths := make([]string, 0, 2)
	for _, entry := range entries {
		if entry.Type != "file" || !strings.HasSuffix(entry.Path, ".parquet") {
			continue
		}
		if !strings.HasPrefix(entry.Path, prefix) {
			continue
		}
		if entry.Size > maxParquetBytes {
			return nil, fmt.Errorf("%s ist mit %d Byte zu gross", entry.Path, entry.Size)
		}
		paths = append(paths, entry.Path)
	}
	if len(paths) == 0 {
		return nil, fmt.Errorf("%w: %s kennt keinen Split %q", errNoRows, query.dataset, query.split)
	}
	return paths, nil
}

func resolveURL(hubBase, dataset, path string) string {
	segments := strings.Split(path, "/")
	for i, segment := range segments {
		segments[i] = url.PathEscape(segment)
	}
	return strings.TrimRight(hubBase, "/") + "/datasets/" + strings.Trim(dataset, "/") +
		"/resolve/" + hubRevision + "/" + strings.Join(segments, "/")
}

func downloadWithRetry(ctx context.Context, client *http.Client, endpoint, token string) ([]byte, error) {
	payload, err := download(ctx, client, endpoint, token)
	for attempt := 0; err != nil && attempt < len(retryDelays); attempt++ {
		if !isTransient(err) {
			return nil, err
		}
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		case <-time.After(retryDelays[attempt]):
		}
		payload, err = download(ctx, client, endpoint, token)
	}
	return payload, err
}

func download(ctx context.Context, client *http.Client, endpoint, token string) ([]byte, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, err
	}
	if token = strings.TrimSpace(token); token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	res, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(res.Body, 512))
		return nil, &statusError{code: res.StatusCode, body: strings.TrimSpace(string(body))}
	}

	payload, err := io.ReadAll(io.LimitReader(res.Body, maxParquetBytes+1))
	if err != nil {
		return nil, err
	}
	if len(payload) > maxParquetBytes {
		return nil, fmt.Errorf("%s liefert mehr als %d Byte", endpoint, maxParquetBytes)
	}
	return payload, nil
}
