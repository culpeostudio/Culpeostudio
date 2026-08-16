package providerconn

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
)

const (
	storeSchemaVersion = 1
	maxActiveModels    = 200

	// These limits bound the durable per-user state and the amount of work a
	// periodic catalogue sync can create. They still leave room for multiple
	// accounts and large vendor catalogues without letting an account turn the
	// backend into an unbounded metadata cache.
	maxConnectionsPerUser = 16
	maxCatalogModels      = 1000
	maxActiveDisplayRunes = 256
)

var (
	ErrNotFound           = errors.New("Provider-Verbindung wurde nicht gefunden")
	ErrActiveModelMissing = errors.New("API-Modell ist nicht aktiviert")
	ErrActiveModelLimit   = errors.New("Limit für aktive API-Modelle erreicht")
	ErrModelNotDiscovered = errors.New("Modell ist nicht im aktuellen Provider-Katalog")
	ErrConnectionLimit    = errors.New("Limit für Provider-Verbindungen erreicht")
	ErrCatalogModelLimit  = errors.New("Provider-Modellkatalog ist zu groß")
	ErrSyncSuperseded     = errors.New("Provider-Verbindung wurde während der Synchronisierung geändert")
)

type userState struct {
	Connections map[string]Connection
	Active      map[string]ActiveModel
}

type persistedFile struct {
	SchemaVersion int                           `json:"schema_version"`
	Users         map[string]persistedUserState `json:"users"`
}

type persistedUserState struct {
	Connections []persistedConnection `json:"connections"`
	Active      []ActiveModel         `json:"active_models"`
}

type persistedConnection struct {
	ID               string    `json:"id"`
	PresetID         string    `json:"preset_id"`
	Name             string    `json:"name"`
	Protocol         string    `json:"protocol"`
	BaseURL          string    `json:"base_url"`
	SecretCiphertext string    `json:"secret_ciphertext,omitempty"`
	Enabled          bool      `json:"enabled"`
	Models           []Model   `json:"models"`
	LastSyncedAt     time.Time `json:"last_synced_at"`
	LastSyncError    string    `json:"last_sync_error,omitempty"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

// Manager owns user-scoped connections and active model choices.  The API key
// stays only in memory while in use and is AES-GCM encrypted in the private
// state file; no caller gets a raw key from a public query method.
type Manager struct {
	path string
	key  [32]byte

	mu     sync.RWMutex
	loaded bool
	users  map[string]userState
}

func NewManager(path, encryptionSecret string) (*Manager, error) {
	path = strings.TrimSpace(path)
	if path == "" {
		return nil, errors.New("Provider-Verbindungsdatei fehlt")
	}
	encryptionSecret = strings.TrimSpace(encryptionSecret)
	if encryptionSecret == "" {
		return nil, errors.New("Provider-Geheimnis fehlt; API-Schlüssel werden nicht unverschlüsselt gespeichert")
	}
	// Domain-separate the key from the JWT signing material passed by the
	// server.  A future secret-store backend can preserve this file contract.
	key := sha256.Sum256([]byte("culpeostudio/provider-connections/v1\x00" + encryptionSecret))
	return &Manager{path: path, key: key, users: make(map[string]userState)}, nil
}

func (m *Manager) Path() string { return m.path }

func normalizeUserID(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	if value == "" {
		return "local"
	}
	return value
}

func (m *Manager) Load() error {
	if m == nil {
		return errors.New("Provider-Verwaltung ist nicht initialisiert")
	}

	m.mu.Lock()
	defer m.mu.Unlock()
	if m.loaded {
		return nil
	}

	payload, err := os.ReadFile(m.path)
	if errors.Is(err, os.ErrNotExist) {
		m.users = make(map[string]userState)
		m.loaded = true
		return nil
	}
	if err != nil {
		return fmt.Errorf("Provider-Verbindungen lesen: %w", err)
	}
	if len(strings.TrimSpace(string(payload))) == 0 {
		m.users = make(map[string]userState)
		m.loaded = true
		return nil
	}

	var persisted persistedFile
	if err := json.Unmarshal(payload, &persisted); err != nil {
		return fmt.Errorf("Provider-Verbindungen enthalten ungültiges JSON: %w", err)
	}
	if persisted.SchemaVersion != storeSchemaVersion {
		return fmt.Errorf("Provider-Verbindungs-Schema %d wird nicht unterstützt", persisted.SchemaVersion)
	}

	loaded := make(map[string]userState, len(persisted.Users))
	for rawUserID, data := range persisted.Users {
		userID := normalizeUserID(rawUserID)
		state := userState{Connections: make(map[string]Connection), Active: make(map[string]ActiveModel)}
		for _, raw := range data.Connections {
			connection, decodeErr := m.fromPersisted(userID, raw)
			if decodeErr != nil {
				return fmt.Errorf("Provider-Verbindung %q entschlüsseln: %w", raw.ID, decodeErr)
			}
			if connection.ID == "" {
				continue
			}
			// A vendor that moved to the Marketplace keeps no connection here.
			// Dropping it also drops its active models below, which is the
			// point: those models are picked in the Marketplace now.
			if _, retired := RetiredPresetIDs[connection.PresetID]; retired {
				continue
			}
			state.Connections[connection.ID] = connection
		}
		for _, active := range data.Active {
			if active.ModelRef == "" || active.ConnectionID == "" || active.ModelID == "" {
				continue
			}
			if _, exists := state.Connections[active.ConnectionID]; !exists {
				continue
			}
			state.Active[active.ModelRef] = active
		}
		loaded[userID] = state
	}
	m.users = loaded
	m.loaded = true
	if err := os.Chmod(m.path, 0o600); err != nil {
		return fmt.Errorf("Provider-Verbindungs-Berechtigungen setzen: %w", err)
	}
	return nil
}

func (m *Manager) ListConnections(userID string) ([]Connection, error) {
	if err := m.ensureLoaded(); err != nil {
		return nil, err
	}
	m.mu.RLock()
	defer m.mu.RUnlock()
	state := m.users[normalizeUserID(userID)]
	connections := make([]Connection, 0, len(state.Connections))
	for _, connection := range state.Connections {
		connections = append(connections, sanitizeConnection(connection))
	}
	sort.SliceStable(connections, func(i, j int) bool {
		return strings.ToLower(connections[i].Name) < strings.ToLower(connections[j].Name)
	})
	return connections, nil
}

// GetConnection is for trusted backend consumers (the sync and chat adapters).
// It returns the decrypted key only in process memory.
func (m *Manager) GetConnection(userID, id string) (Connection, error) {
	if err := m.ensureLoaded(); err != nil {
		return Connection{}, err
	}
	m.mu.RLock()
	defer m.mu.RUnlock()
	connection, ok := m.users[normalizeUserID(userID)].Connections[strings.TrimSpace(id)]
	if !ok {
		return Connection{}, ErrNotFound
	}
	return cloneConnection(connection), nil
}

func (m *Manager) SaveConnection(userID string, input ConnectionInput) (Connection, error) {
	if err := m.ensureLoaded(); err != nil {
		return Connection{}, err
	}
	userID = normalizeUserID(userID)
	prepared, err := normalizeConnectionInput(input)
	if err != nil {
		return Connection{}, err
	}

	m.mu.Lock()
	defer m.mu.Unlock()
	state := m.stateLocked(userID)
	now := time.Now().UTC()
	id := strings.TrimSpace(prepared.ID)
	var current Connection
	if id != "" {
		var exists bool
		current, exists = state.Connections[id]
		if !exists {
			return Connection{}, ErrNotFound
		}
	} else {
		if len(state.Connections) >= maxConnectionsPerUser {
			return Connection{}, ErrConnectionLimit
		}
		id = "pc_" + strings.ReplaceAll(uuid.NewString(), "-", "")
		current = Connection{ID: id, UserID: userID, CreatedAt: now}
	}

	updated := current
	updated.PresetID = prepared.PresetID
	updated.Name = prepared.Name
	updated.Protocol = prepared.Protocol
	updated.BaseURL = prepared.BaseURL
	updated.Enabled = prepared.Enabled
	updated.UpdatedAt = now
	targetChanged := current.PresetID != "" &&
		(current.PresetID != updated.PresetID || current.BaseURL != updated.BaseURL || current.Protocol != updated.Protocol)
	if prepared.ClearAPIKey {
		updated.APIKey = ""
		updated.APIKeySet = false
	} else if prepared.APIKey != nil {
		updated.APIKey = strings.TrimSpace(*prepared.APIKey)
		updated.APIKeySet = updated.APIKey != ""
	} else if targetChanged {
		// Never silently send a credential entered for one provider to a new
		// endpoint or protocol. The user must explicitly re-enter it.
		updated.APIKey = ""
		updated.APIKeySet = false
	}

	// Changing a provider target invalidates catalogue metadata from the old
	// host and prevents stale models from being activated.
	if targetChanged {
		updated.Models = nil
		updated.LastSyncedAt = time.Time{}
		updated.LastSyncError = ""
		removeActiveModelsForConnection(&state, id)
	} else if !updated.Enabled || (presetRequiresKey(updated.PresetID) && !updated.APIKeySet) {
		// A disabled or de-keyed connection must not leave a still-selectable
		// model in the chat picker. Re-enabling/re-keying requires an explicit
		// model activation, which makes any billable use intentional again.
		removeActiveModelsForConnection(&state, id)
	}

	state.Connections[id] = updated
	m.users[userID] = state
	if err := m.writeLocked(); err != nil {
		return Connection{}, err
	}
	return sanitizeConnection(updated), nil
}

func (m *Manager) DeleteConnection(userID, id string) (bool, error) {
	if err := m.ensureLoaded(); err != nil {
		return false, err
	}
	userID = normalizeUserID(userID)
	id = strings.TrimSpace(id)
	if id == "" {
		return false, nil
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	state := m.stateLocked(userID)
	if _, ok := state.Connections[id]; !ok {
		return false, nil
	}
	delete(state.Connections, id)
	for ref, active := range state.Active {
		if active.ConnectionID == id {
			delete(state.Active, ref)
		}
	}
	m.users[userID] = state
	return true, m.writeLocked()
}

func (m *Manager) SetSyncResult(userID, id string, models []Model, syncErr error) (Connection, error) {
	return m.setSyncResult(userID, id, nil, models, syncErr)
}

// SetSyncResultIfCurrent prevents an in-flight metadata request from
// overwriting a connection that was edited, disabled, re-keyed, or retargeted
// after discovery began. The snapshot must be the trusted Connection returned
// by GetConnection immediately before the request.
func (m *Manager) SetSyncResultIfCurrent(userID, id string, expected Connection, models []Model, syncErr error) (Connection, error) {
	return m.setSyncResult(userID, id, &expected, models, syncErr)
}

func (m *Manager) setSyncResult(userID, id string, expected *Connection, models []Model, syncErr error) (Connection, error) {
	if err := m.ensureLoaded(); err != nil {
		return Connection{}, err
	}
	userID = normalizeUserID(userID)
	id = strings.TrimSpace(id)
	m.mu.Lock()
	defer m.mu.Unlock()
	state := m.stateLocked(userID)
	connection, ok := state.Connections[id]
	if !ok {
		return Connection{}, ErrNotFound
	}
	if expected != nil && !sameSyncTarget(connection, *expected) {
		return sanitizeConnection(connection), ErrSyncSuperseded
	}
	if syncErr != nil {
		connection.LastSyncError = limitError(syncErr.Error(), 300)
	} else {
		if len(models) > maxCatalogModels {
			return sanitizeConnection(connection), ErrCatalogModelLimit
		}
		connection.Models = cloneModels(models)
		connection.LastSyncedAt = time.Now().UTC()
		connection.LastSyncError = ""
		pruneInactiveCatalogueModels(&state, id, connection.Models)
	}
	connection.UpdatedAt = time.Now().UTC()
	state.Connections[id] = connection
	m.users[userID] = state
	if err := m.writeLocked(); err != nil {
		return Connection{}, err
	}
	return sanitizeConnection(connection), nil
}

func (m *Manager) ListModels(userID, connectionID string) (Connection, []Model, error) {
	connection, err := m.GetConnection(userID, connectionID)
	if err != nil {
		return Connection{}, nil, err
	}
	return sanitizeConnection(connection), cloneModels(connection.Models), nil
}

func (m *Manager) ActivateModel(userID, connectionID, modelID, displayName string) (ActiveModel, error) {
	if err := m.ensureLoaded(); err != nil {
		return ActiveModel{}, err
	}
	userID = normalizeUserID(userID)
	connectionID = strings.TrimSpace(connectionID)
	modelID = strings.TrimSpace(modelID)
	if connectionID == "" || modelID == "" {
		return ActiveModel{}, errors.New("connection_id und model_id sind erforderlich")
	}

	m.mu.Lock()
	defer m.mu.Unlock()
	state := m.stateLocked(userID)
	connection, ok := state.Connections[connectionID]
	if !ok {
		return ActiveModel{}, ErrNotFound
	}
	if !connection.Enabled {
		return ActiveModel{}, errors.New("Provider-Verbindung ist deaktiviert")
	}
	if connection.APIKey == "" && presetRequiresKey(connection.PresetID) {
		return ActiveModel{}, errors.New("API-Key fehlt für diese Provider-Verbindung")
	}

	model, found := findModel(connection.Models, modelID)
	if !found {
		return ActiveModel{}, ErrModelNotDiscovered
	}
	if !model.ChatSupported {
		return ActiveModel{}, errors.New("dieses Modell unterstützt keinen Text-Chat über die konfigurierte API")
	}

	displayName = strings.TrimSpace(displayName)
	if len([]rune(displayName)) > maxActiveDisplayRunes {
		return ActiveModel{}, errors.New("Modell-Anzeigename ist zu lang")
	}

	ref := ModelRef(connectionID, modelID)
	now := time.Now().UTC()
	active, exists := state.Active[ref]
	if !exists && len(state.Active) >= maxActiveModels {
		return ActiveModel{}, ErrActiveModelLimit
	}
	if !exists {
		active = ActiveModel{ModelRef: ref, ConnectionID: connectionID, ActivatedAt: now}
	}
	active.ProviderLabel = connection.Name
	active.ProviderID = connection.PresetID
	active.ModelID = modelID
	active.DisplayName = displayName
	if active.DisplayName == "" {
		active.DisplayName = model.DisplayName
	}
	if active.DisplayName == "" {
		active.DisplayName = modelID
	}
	active.Protocol = connection.Protocol
	active.LastUsedAt = now
	state.Active[ref] = active
	m.users[userID] = state
	if err := m.writeLocked(); err != nil {
		return ActiveModel{}, err
	}
	return active, nil
}

func (m *Manager) ListActiveModels(userID string) ([]ActiveModel, error) {
	if err := m.ensureLoaded(); err != nil {
		return nil, err
	}
	m.mu.RLock()
	defer m.mu.RUnlock()
	state := m.users[normalizeUserID(userID)]
	active := make([]ActiveModel, 0, len(state.Active))
	for _, item := range state.Active {
		active = append(active, item)
	}
	sort.SliceStable(active, func(i, j int) bool { return active[i].LastUsedAt.After(active[j].LastUsedAt) })
	return active, nil
}

func (m *Manager) TouchActiveModel(userID, modelRef string) (ActiveModel, bool, error) {
	if err := m.ensureLoaded(); err != nil {
		return ActiveModel{}, false, err
	}
	userID = normalizeUserID(userID)
	modelRef = strings.TrimSpace(modelRef)
	m.mu.Lock()
	defer m.mu.Unlock()
	state := m.stateLocked(userID)
	active, ok := state.Active[modelRef]
	if !ok {
		return ActiveModel{}, false, nil
	}
	if _, connected := state.Connections[active.ConnectionID]; !connected {
		delete(state.Active, modelRef)
		_ = m.writeLocked()
		return ActiveModel{}, false, nil
	}
	active.LastUsedAt = time.Now().UTC()
	state.Active[modelRef] = active
	m.users[userID] = state
	if err := m.writeLocked(); err != nil {
		return ActiveModel{}, false, err
	}
	return active, true, nil
}

func (m *Manager) DeleteActiveModel(userID, modelRef string) (bool, error) {
	if err := m.ensureLoaded(); err != nil {
		return false, err
	}
	userID = normalizeUserID(userID)
	modelRef = strings.TrimSpace(modelRef)
	m.mu.Lock()
	defer m.mu.Unlock()
	state := m.stateLocked(userID)
	if _, ok := state.Active[modelRef]; !ok {
		return false, nil
	}
	delete(state.Active, modelRef)
	m.users[userID] = state
	return true, m.writeLocked()
}

// SyncTargets is safe for the background synchronizer: it contains no key.
type SyncTarget struct {
	UserID       string
	ConnectionID string
}

func (m *Manager) SyncTargets() ([]SyncTarget, error) {
	if err := m.ensureLoaded(); err != nil {
		return nil, err
	}
	m.mu.RLock()
	defer m.mu.RUnlock()
	targets := []SyncTarget{}
	for userID, state := range m.users {
		for id, connection := range state.Connections {
			if connection.Enabled {
				targets = append(targets, SyncTarget{UserID: userID, ConnectionID: id})
			}
		}
	}
	return targets, nil
}

func (m *Manager) stateLocked(userID string) userState {
	state, ok := m.users[userID]
	if !ok {
		state = userState{Connections: make(map[string]Connection), Active: make(map[string]ActiveModel)}
	}
	if state.Connections == nil {
		state.Connections = make(map[string]Connection)
	}
	if state.Active == nil {
		state.Active = make(map[string]ActiveModel)
	}
	return state
}

func removeActiveModelsForConnection(state *userState, connectionID string) {
	if state == nil {
		return
	}
	for ref, active := range state.Active {
		if active.ConnectionID == connectionID {
			delete(state.Active, ref)
		}
	}
}

// pruneInactiveCatalogueModels leaves an explicit activation intact only if
// the freshly synchronised catalogue still advertises that exact model ID.
// Discovery itself never creates a new activation.
func pruneInactiveCatalogueModels(state *userState, connectionID string, models []Model) {
	if state == nil {
		return
	}
	available := make(map[string]struct{}, len(models))
	for _, model := range models {
		if id := strings.TrimSpace(model.ID); id != "" {
			available[id] = struct{}{}
		}
	}
	for ref, active := range state.Active {
		if active.ConnectionID != connectionID {
			continue
		}
		if _, exists := available[active.ModelID]; !exists {
			delete(state.Active, ref)
		}
	}
}

func sameSyncTarget(current, expected Connection) bool {
	return current.ID == expected.ID &&
		current.PresetID == expected.PresetID &&
		current.Protocol == expected.Protocol &&
		current.BaseURL == expected.BaseURL &&
		current.APIKey == expected.APIKey &&
		current.Enabled == expected.Enabled
}

func (m *Manager) ensureLoaded() error {
	if m == nil {
		return errors.New("Provider-Verwaltung ist nicht initialisiert")
	}
	m.mu.RLock()
	loaded := m.loaded
	m.mu.RUnlock()
	if loaded {
		return nil
	}
	return m.Load()
}

func (m *Manager) fromPersisted(userID string, raw persistedConnection) (Connection, error) {
	key := ""
	var err error
	if strings.TrimSpace(raw.SecretCiphertext) != "" {
		key, err = m.decrypt(raw.SecretCiphertext)
		if err != nil {
			return Connection{}, err
		}
	}
	connection := Connection{
		ID:            strings.TrimSpace(raw.ID),
		UserID:        userID,
		PresetID:      strings.TrimSpace(raw.PresetID),
		Name:          strings.TrimSpace(raw.Name),
		Protocol:      NormalizeProtocol(raw.Protocol),
		BaseURL:       strings.TrimSpace(raw.BaseURL),
		APIKey:        key,
		APIKeySet:     key != "",
		Enabled:       raw.Enabled,
		Models:        cloneModels(raw.Models),
		LastSyncedAt:  raw.LastSyncedAt,
		LastSyncError: limitError(raw.LastSyncError, 300),
		CreatedAt:     raw.CreatedAt,
		UpdatedAt:     raw.UpdatedAt,
	}
	if connection.Protocol == "" || connection.ID == "" {
		return Connection{}, errors.New("ungültige gespeicherte Provider-Verbindung")
	}
	return connection, nil
}

func (m *Manager) toPersisted(connection Connection) (persistedConnection, error) {
	ciphertext := ""
	var err error
	if strings.TrimSpace(connection.APIKey) != "" {
		ciphertext, err = m.encrypt(connection.APIKey)
		if err != nil {
			return persistedConnection{}, err
		}
	}
	return persistedConnection{
		ID:               connection.ID,
		PresetID:         connection.PresetID,
		Name:             connection.Name,
		Protocol:         connection.Protocol,
		BaseURL:          connection.BaseURL,
		SecretCiphertext: ciphertext,
		Enabled:          connection.Enabled,
		Models:           cloneModels(connection.Models),
		LastSyncedAt:     connection.LastSyncedAt,
		LastSyncError:    connection.LastSyncError,
		CreatedAt:        connection.CreatedAt,
		UpdatedAt:        connection.UpdatedAt,
	}, nil
}

func (m *Manager) writeLocked() error {
	persisted := persistedFile{SchemaVersion: storeSchemaVersion, Users: make(map[string]persistedUserState, len(m.users))}
	for userID, state := range m.users {
		data := persistedUserState{
			Connections: make([]persistedConnection, 0, len(state.Connections)),
			Active:      make([]ActiveModel, 0, len(state.Active)),
		}
		for _, connection := range state.Connections {
			raw, err := m.toPersisted(connection)
			if err != nil {
				return fmt.Errorf("Provider-Verbindung verschlüsseln: %w", err)
			}
			data.Connections = append(data.Connections, raw)
		}
		sort.SliceStable(data.Connections, func(i, j int) bool { return data.Connections[i].ID < data.Connections[j].ID })
		for _, active := range state.Active {
			data.Active = append(data.Active, active)
		}
		sort.SliceStable(data.Active, func(i, j int) bool { return data.Active[i].ModelRef < data.Active[j].ModelRef })
		persisted.Users[userID] = data
	}
	payload, err := json.MarshalIndent(persisted, "", "  ")
	if err != nil {
		return err
	}
	return atomicPrivateWrite(m.path, append(payload, '\n'))
}

func (m *Manager) encrypt(value string) (string, error) {
	block, err := aes.NewCipher(m.key[:])
	if err != nil {
		return "", err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}
	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}
	sealed := gcm.Seal(nil, nonce, []byte(value), nil)
	return base64.RawURLEncoding.EncodeToString(append(nonce, sealed...)), nil
}

func (m *Manager) decrypt(value string) (string, error) {
	raw, err := base64.RawURLEncoding.DecodeString(strings.TrimSpace(value))
	if err != nil {
		return "", err
	}
	block, err := aes.NewCipher(m.key[:])
	if err != nil {
		return "", err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}
	if len(raw) < gcm.NonceSize() {
		return "", errors.New("verschlüsselter API-Key ist unvollständig")
	}
	plain, err := gcm.Open(nil, raw[:gcm.NonceSize()], raw[gcm.NonceSize():], nil)
	if err != nil {
		return "", errors.New("verschlüsselter API-Key kann nicht entschlüsselt werden")
	}
	return strings.TrimSpace(string(plain)), nil
}

func atomicPrivateWrite(path string, payload []byte) (err error) {
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}
	temporary, err := os.CreateTemp(dir, filepath.Base(path)+".tmp-*")
	if err != nil {
		return err
	}
	temporaryPath := temporary.Name()
	defer func() {
		if err != nil {
			_ = temporary.Close()
			_ = os.Remove(temporaryPath)
		}
	}()
	if err := temporary.Chmod(0o600); err != nil {
		return err
	}
	if _, err := temporary.Write(payload); err != nil {
		return err
	}
	if err := temporary.Sync(); err != nil {
		return err
	}
	if err := temporary.Close(); err != nil {
		return err
	}
	return os.Rename(temporaryPath, path)
}

func sanitizeConnection(connection Connection) Connection {
	copy := cloneConnection(connection)
	copy.APIKey = ""
	return copy
}

func cloneConnection(connection Connection) Connection {
	connection.Models = cloneModels(connection.Models)
	return connection
}

func cloneModels(models []Model) []Model {
	out := make([]Model, len(models))
	for i, model := range models {
		out[i] = model
		out[i].InputModalities = append([]string(nil), model.InputModalities...)
		out[i].OutputModalities = append([]string(nil), model.OutputModalities...)
		out[i].Capabilities = append([]string(nil), model.Capabilities...)
	}
	return out
}

func findModel(models []Model, id string) (Model, bool) {
	for _, model := range models {
		if model.ID == id {
			return model, true
		}
	}
	return Model{}, false
}

func presetRequiresKey(presetID string) bool {
	preset, ok := FindPreset(presetID)
	return ok && preset.APIKeyRequired
}

func limitError(value string, max int) string {
	value = strings.TrimSpace(value)
	if len([]rune(value)) <= max {
		return value
	}
	return string([]rune(value)[:max]) + "…"
}
