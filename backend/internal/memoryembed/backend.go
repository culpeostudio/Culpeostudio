// Package memoryembed provides pluggable embedding backends for the memory
// vector index. The backend is chosen via config; every deployment always has
// the deterministic hash backend available as fallback and for scoring legacy
// vectors that were written before a model switch.
package memoryembed

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"runtime"
	"strconv"
	"strings"
)

const (
	BackendHash         = "hash"
	BackendONNXLocal    = "onnx_local"
	BackendOllamaRemote = "ollama_remote"
	BackendAPIRemote    = "api_remote"
)

// Backend turns text into a vector. Model() identifies the concrete model so
// stored embeddings can be told apart after a backend switch; embeddings from
// different models are never compared against each other.
type Backend interface {
	// Name is the backend kind: hash | onnx_local | ollama_remote | api_remote.
	Name() string
	// Model is the persisted model identifier (e.g. "hash-v1", "nomic-embed-text").
	Model() string
	// Dim is the vector dimensionality; 0 until discovered for remote backends.
	Dim() int
	Embed(text string) ([]float32, error)
}

type Config struct {
	Backend        string
	HashDims       int
	SidecarURL     string
	SidecarModel   string
	OllamaURL      string
	OllamaModel    string
	APIURL         string
	APIKey         string
	APIModel       string
	MinFreeMemMB   int
	MinCores       int
	TimeoutSeconds int
}

// Select builds the active backend plus the always-available hash backend.
// Non-hash backends are health-checked once; if the check or the resource
// gate fails, the selection falls back to hash so the service stays usable.
func Select(cfg Config) (active Backend, hash Backend) {
	hash = NewHashBackend(cfg.HashDims)
	requested := strings.ToLower(strings.TrimSpace(cfg.Backend))
	switch requested {
	case "", BackendHash:
		active = hash
	case BackendONNXLocal:
		if reason := checkResources(cfg.MinFreeMemMB, cfg.MinCores); reason != "" {
			log.Printf("[memory-embed] onnx_local nicht tragbar (%s), fallback auf hash", reason)
			active = hash
			break
		}
		backend := NewSidecarBackend(cfg.SidecarURL, cfg.SidecarModel, cfg.TimeoutSeconds)
		active = probeOrFallback(backend, hash)
	case BackendOllamaRemote:
		backend := NewOllamaBackend(cfg.OllamaURL, cfg.OllamaModel, cfg.TimeoutSeconds)
		active = probeOrFallback(backend, hash)
	case BackendAPIRemote:
		backend := NewAPIBackend(cfg.APIURL, cfg.APIKey, cfg.APIModel, cfg.TimeoutSeconds)
		active = probeOrFallback(backend, hash)
	default:
		log.Printf("[memory-embed] unbekanntes Backend %q, fallback auf hash", requested)
		active = hash
	}
	log.Printf("[memory-embed] aktives Backend=%s model=%s dim=%d", active.Name(), active.Model(), active.Dim())
	return active, hash
}

func probeOrFallback(backend Backend, hash Backend) Backend {
	if _, err := backend.Embed("healthcheck"); err != nil {
		log.Printf("[memory-embed] Backend %s (%s) nicht erreichbar: %v — fallback auf hash", backend.Name(), backend.Model(), err)
		return hash
	}
	return backend
}

// checkResources gates local model loading on available RAM and CPU cores.
// Returns an empty string when the machine can carry the model.
func checkResources(minFreeMemMB, minCores int) string {
	if minFreeMemMB <= 0 {
		minFreeMemMB = 1024
	}
	if minCores <= 0 {
		minCores = 2
	}
	if cores := runtime.NumCPU(); cores < minCores {
		return fmt.Sprintf("nur %d Cores, benoetigt %d", cores, minCores)
	}
	availableMB, err := availableMemoryMB()
	if err != nil {
		// No /proc/meminfo (non-Linux): do not block, the sidecar probe still runs.
		return ""
	}
	if availableMB < minFreeMemMB {
		return fmt.Sprintf("nur %d MB frei, benoetigt %d MB", availableMB, minFreeMemMB)
	}
	return ""
}

func availableMemoryMB() (int, error) {
	file, err := os.Open("/proc/meminfo")
	if err != nil {
		return 0, err
	}
	defer file.Close()
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if !strings.HasPrefix(line, "MemAvailable:") {
			continue
		}
		fields := strings.Fields(line)
		if len(fields) < 2 {
			break
		}
		kb, err := strconv.Atoi(fields[1])
		if err != nil {
			return 0, err
		}
		return kb / 1024, nil
	}
	return 0, fmt.Errorf("MemAvailable nicht gefunden")
}
