package config

import (
	"crypto/rand"
	"encoding/hex"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

type Config struct {
	// HTTPHost: Bind-Adresse. Standard 127.0.0.1 (nur lokal erreichbar);
	// HTTP_HOST=0.0.0.0 oeffnet den Server bewusst fuer das Netzwerk.
	HTTPHost          string
	HTTPPort          string
	GRPCPort          string
	JWTSecret         string
	LoginAccountsFile string
	AuthConfigFile    string
	SettingsFile      string
	TLSCert           string
	TLSKey            string
	UseHTTPS          bool
	AgenticTimeoutSec int

	// Memory-Modul
	MemoryDataDir          string
	MemoryProjectTag       string
	MemoryAPIToken         string
	MemoryDefaultUserID    string
	MemorySQLitePath       string
	MemoryVectorPath       string
	MemoryVectorDims       int
	MemoryContextBudget    int
	UserThreshold          int
	StatusThreshold        int
	BrainstormThreshold    int
	ChangeRequestThreshold int
	CaptureRateLimit       int
	ChatWindowSize         int
	ChatOverlapSize        int
	MemoryViewerTitle      string

	// Reindexer- und Wartungs-Tuning
	MemoryReindexIntervalSeconds  int
	MemoryReindexBatchSize        int
	MemoryReindexConcurrency      int
	MemorySoftDeleteRetentionDays int

	// Modellspezifische Token-Zaehlung (siehe internal/memorytoken)
	MemoryTokenizerFamily    string
	MemoryTokenizerModelPath string

	// Pluggable Embedding-Backends fuer das Memory-Modul
	EmbeddingBackend      string
	EmbeddingHashDims     int
	EmbeddingSidecarURL   string
	EmbeddingSidecarModel string
	EmbeddingOllamaURL    string
	EmbeddingOllamaModel  string
	EmbeddingAPIURL       string
	EmbeddingAPIKey       string
	EmbeddingAPIModel     string
	EmbeddingMinFreeMemMB int
	EmbeddingMinCores     int
	EmbeddingTimeoutSec   int
}

func Load() *Config {
	memoryDataDir := getEnv("MEMORY_DATA_DIR", "data")
	vectorDims := getEnvInt("MEMORY_VECTOR_DIMS", 128)
	return &Config{
		HTTPHost:          getEnv("HTTP_HOST", "127.0.0.1"),
		HTTPPort:          getEnv("HTTP_PORT", "8080"),
		GRPCPort:          getEnv("GRPC_PORT", "50051"),
		JWTSecret:         getOrCreateSecret("JWT_SECRET", filepath.Join(memoryDataDir, "jwt_secret")),
		LoginAccountsFile: getEnv("LOGIN_ACCOUNTS_FILE", "data/login_accounts.json"),
		AuthConfigFile:    getEnv("AUTH_CONFIG_FILE", "data/login_authenticator.json"),
		SettingsFile:      getEnv("SETTINGS_FILE", "data/settings.json"),
		TLSCert:           getEnv("TLS_CERT", ""),
		TLSKey:            getEnv("TLS_KEY", ""),
		UseHTTPS:          getEnv("USE_HTTPS", "false") == "true",
		AgenticTimeoutSec: getEnvInt("AGENTIC_TIMEOUT_SEC", 300),

		MemoryDataDir:          memoryDataDir,
		MemoryProjectTag:       getEnv("MEMORY_PROJECT_TAG", "myphiloengine"),
		MemoryAPIToken:         getOrCreateSecret("MEMORY_API_TOKEN", filepath.Join(memoryDataDir, "memory_api_token")),
		MemoryDefaultUserID:    getEnv("MEMORY_DEFAULT_USER_ID", "local"),
		MemorySQLitePath:       getEnv("MEMORY_SQLITE_PATH", memoryDataDir+"/memory/memory.db"),
		MemoryVectorPath:       getEnv("MEMORY_VECTOR_PATH", memoryDataDir+"/memory/vector-index.json"),
		MemoryVectorDims:       vectorDims,
		MemoryContextBudget:    getEnvInt("MEMORY_CONTEXT_BUDGET", 2200),
		UserThreshold:          getEnvInt("MEMORY_COMPRESS_USER_THRESHOLD", 1000000),
		StatusThreshold:        getEnvInt("MEMORY_COMPRESS_STATUS_THRESHOLD", 24),
		BrainstormThreshold:    getEnvInt("MEMORY_COMPRESS_BRAINSTORMING_THRESHOLD", 8),
		ChangeRequestThreshold: getEnvInt("MEMORY_COMPRESS_CHANGE_REQUEST_THRESHOLD", 1000000),
		CaptureRateLimit:       getEnvInt("MEMORY_CAPTURE_RATE_LIMIT", 120),
		ChatWindowSize:         getEnvInt("MEMORY_CHAT_WINDOW_SIZE", 6),
		ChatOverlapSize:        getEnvInt("MEMORY_CHAT_OVERLAP_SIZE", 2),
		MemoryViewerTitle:      getEnv("MEMORY_VIEWER_TITLE", "MyPhiloEngine Memory"),

		MemoryReindexIntervalSeconds:  getEnvInt("MEMORY_REINDEX_INTERVAL_SECONDS", 2),
		MemoryReindexBatchSize:        getEnvInt("MEMORY_REINDEX_BATCH_SIZE", 64),
		MemoryReindexConcurrency:      getEnvInt("MEMORY_REINDEX_CONCURRENCY", 4),
		MemorySoftDeleteRetentionDays: getEnvInt("MEMORY_SOFT_DELETE_RETENTION_DAYS", 90),

		MemoryTokenizerFamily:    getEnv("MEMORY_TOKENIZER_FAMILY", "openai"),
		MemoryTokenizerModelPath: getEnv("MEMORY_TOKENIZER_MODEL_PATH", ""),

		EmbeddingBackend:      getEnv("MEMORY_EMBEDDING_BACKEND", "hash"),
		EmbeddingHashDims:     getEnvInt("MEMORY_EMBEDDING_HASH_DIMS", vectorDims),
		EmbeddingSidecarURL:   getEnv("MEMORY_EMBEDDING_SIDECAR_URL", "http://127.0.0.1:8092"),
		EmbeddingSidecarModel: getEnv("MEMORY_EMBEDDING_SIDECAR_MODEL", "all-MiniLM-L6-v2"),
		EmbeddingOllamaURL:    getEnv("MEMORY_EMBEDDING_OLLAMA_URL", "http://127.0.0.1:11434"),
		EmbeddingOllamaModel:  getEnv("MEMORY_EMBEDDING_OLLAMA_MODEL", "nomic-embed-text"),
		EmbeddingAPIURL:       getEnv("MEMORY_EMBEDDING_API_URL", ""),
		EmbeddingAPIKey:       getEnv("MEMORY_EMBEDDING_API_KEY", ""),
		EmbeddingAPIModel:     getEnv("MEMORY_EMBEDDING_API_MODEL", "text-embedding-3-small"),
		EmbeddingMinFreeMemMB: getEnvInt("MEMORY_EMBEDDING_MIN_FREE_MEM_MB", 1024),
		EmbeddingMinCores:     getEnvInt("MEMORY_EMBEDDING_MIN_CORES", 2),
		EmbeddingTimeoutSec:   getEnvInt("MEMORY_EMBEDDING_TIMEOUT_SECONDS", 10),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

// getOrCreateSecret liefert ein Geheimnis (JWT-Signatur, Memory-Token) in
// dieser Reihenfolge: Umgebungsvariable, zuvor erzeugte Datei, sonst frisch
// gewuerfelt und gespeichert.
//
// Frueher stand hier ein fester Vorgabewert im Quelltext. Da der Server auf
// allen Netzwerk-Interfaces lauscht (":8080"), konnte damit jeder im selben
// Netz, der den Quelltext kennt, gueltige Tokens signieren. Ein pro
// Installation gewuerfeltes Geheimnis behebt das, ohne dass beim Start etwas
// eingerichtet werden muss; es ueberlebt Neustarts, damit Anmeldungen nicht
// jedes Mal ungueltig werden.
//
// Schlaegt Erzeugen oder Speichern fehl, laeuft der Server mit einem nur im
// Speicher gehaltenen Geheimnis weiter — dann sind Sitzungen nach einem
// Neustart ungueltig, aber nie unsicher.
func getOrCreateSecret(envKey, path string) string {
	if v := strings.TrimSpace(os.Getenv(envKey)); v != "" {
		return v
	}
	if stored, err := os.ReadFile(path); err == nil {
		if secret := strings.TrimSpace(string(stored)); secret != "" {
			return secret
		}
	}

	raw := make([]byte, 32)
	if _, err := rand.Read(raw); err != nil {
		log.Printf("[config] %s konnte nicht erzeugt werden: %v", envKey, err)
		return ""
	}
	secret := hex.EncodeToString(raw)

	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		log.Printf("[config] Ablage fuer %s nicht anlegbar (%s): %v — Geheimnis gilt nur bis zum Neustart", envKey, path, err)
		return secret
	}
	if err := os.WriteFile(path, []byte(secret), 0o600); err != nil {
		log.Printf("[config] %s nicht speicherbar (%s): %v — Geheimnis gilt nur bis zum Neustart", envKey, path, err)
		return secret
	}
	log.Printf("[config] Neues %s erzeugt und unter %s gespeichert", envKey, path)
	return secret
}

func getEnvInt(key string, fallback int) int {
	if v := os.Getenv(key); v != "" {
		if parsed, err := strconv.Atoi(v); err == nil {
			return parsed
		}
	}
	return fallback
}
