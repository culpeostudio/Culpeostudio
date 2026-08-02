package memoryembed

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"
)

type httpBackend struct {
	name    string
	model   string
	client  *http.Client
	request func(text string) (*http.Request, error)
	decode  func(payload []byte) ([]float32, error)

	mu  sync.Mutex
	dim int
}

func newHTTPClient(timeoutSeconds int) *http.Client {
	if timeoutSeconds <= 0 {
		timeoutSeconds = 30
	}
	return &http.Client{Timeout: time.Duration(timeoutSeconds) * time.Second}
}

func (b *httpBackend) Name() string  { return b.name }
func (b *httpBackend) Model() string { return b.model }

func (b *httpBackend) Dim() int {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.dim
}

func (b *httpBackend) Embed(text string) ([]float32, error) {
	request, err := b.request(text)
	if err != nil {
		return nil, err
	}
	response, err := b.client.Do(request)
	if err != nil {
		return nil, err
	}
	defer response.Body.Close()
	payload, err := io.ReadAll(io.LimitReader(response.Body, 8<<20))
	if err != nil {
		return nil, err
	}
	if response.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("%s: status %d: %s", b.name, response.StatusCode, previewBytes(payload, 200))
	}
	vector, err := b.decode(payload)
	if err != nil {
		return nil, err
	}
	if len(vector) == 0 {
		return nil, fmt.Errorf("%s: leeres Embedding", b.name)
	}
	b.mu.Lock()
	b.dim = len(vector)
	b.mu.Unlock()
	return normalize(vector), nil
}

func NewSidecarBackend(url, model string, timeoutSeconds int) Backend {
	url = strings.TrimRight(strings.TrimSpace(url), "/")
	if model == "" {
		model = "onnx-minilm"
	}
	return &httpBackend{
		name:   BackendONNXLocal,
		model:  model,
		client: newHTTPClient(timeoutSeconds),
		request: func(text string) (*http.Request, error) {
			body, err := json.Marshal(map[string]interface{}{"texts": []string{text}})
			if err != nil {
				return nil, err
			}
			request, err := http.NewRequest(http.MethodPost, url+"/embed", bytes.NewReader(body))
			if err != nil {
				return nil, err
			}
			request.Header.Set("Content-Type", "application/json")
			return request, nil
		},
		decode: func(payload []byte) ([]float32, error) {
			var parsed struct {
				Embeddings [][]float32 `json:"embeddings"`
			}
			if err := json.Unmarshal(payload, &parsed); err != nil {
				return nil, err
			}
			if len(parsed.Embeddings) == 0 {
				return nil, fmt.Errorf("sidecar: keine Embeddings in Antwort")
			}
			return parsed.Embeddings[0], nil
		},
	}
}

func NewOllamaBackend(url, model string, timeoutSeconds int) Backend {
	url = strings.TrimRight(strings.TrimSpace(url), "/")
	if url == "" {
		url = "http://127.0.0.1:11434"
	}
	if model == "" {
		model = "nomic-embed-text"
	}
	return &httpBackend{
		name:   BackendOllamaRemote,
		model:  model,
		client: newHTTPClient(timeoutSeconds),
		request: func(text string) (*http.Request, error) {
			body, err := json.Marshal(map[string]interface{}{"model": model, "prompt": text})
			if err != nil {
				return nil, err
			}
			request, err := http.NewRequest(http.MethodPost, url+"/api/embeddings", bytes.NewReader(body))
			if err != nil {
				return nil, err
			}
			request.Header.Set("Content-Type", "application/json")
			return request, nil
		},
		decode: func(payload []byte) ([]float32, error) {
			var parsed struct {
				Embedding []float32 `json:"embedding"`
			}
			if err := json.Unmarshal(payload, &parsed); err != nil {
				return nil, err
			}
			return parsed.Embedding, nil
		},
	}
}

func NewAPIBackend(url, apiKey, model string, timeoutSeconds int) Backend {
	url = strings.TrimRight(strings.TrimSpace(url), "/")
	if model == "" {
		model = "text-embedding-3-small"
	}
	return &httpBackend{
		name:   BackendAPIRemote,
		model:  model,
		client: newHTTPClient(timeoutSeconds),
		request: func(text string) (*http.Request, error) {
			body, err := json.Marshal(map[string]interface{}{"model": model, "input": text})
			if err != nil {
				return nil, err
			}
			request, err := http.NewRequest(http.MethodPost, url+"/v1/embeddings", bytes.NewReader(body))
			if err != nil {
				return nil, err
			}
			request.Header.Set("Content-Type", "application/json")
			if strings.TrimSpace(apiKey) != "" {
				request.Header.Set("Authorization", "Bearer "+strings.TrimSpace(apiKey))
			}
			return request, nil
		},
		decode: func(payload []byte) ([]float32, error) {
			var parsed struct {
				Data []struct {
					Embedding []float32 `json:"embedding"`
				} `json:"data"`
			}
			if err := json.Unmarshal(payload, &parsed); err != nil {
				return nil, err
			}
			if len(parsed.Data) == 0 {
				return nil, fmt.Errorf("api_remote: keine Embeddings in Antwort")
			}
			return parsed.Data[0].Embedding, nil
		},
	}
}

func previewBytes(payload []byte, max int) string {
	text := strings.TrimSpace(string(payload))
	if len(text) > max {
		return text[:max]
	}
	return text
}
