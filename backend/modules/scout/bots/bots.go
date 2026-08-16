package bots

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"sync"

	"github.com/culpeohq/backend/internal/apimodels"
	"github.com/culpeohq/backend/internal/providerconn"
)

const StoreSchemaVersion = 2

var (
	ErrBotBuilderLocked    = errors.New("botbuilder ist gesperrt und kann nicht bearbeitet werden")
	ErrInvalidModelBinding = errors.New("ungueltige Modellbindung")
)

type ModelBinding struct {
	Kind         string `json:"kind"`
	ModelRef     string `json:"model_ref,omitempty"`
	Provider     string `json:"provider,omitempty"`
	ModelID      string `json:"model_id,omitempty"`
	InstanceID   string `json:"instance_id,omitempty"`
	DisplayName  string `json:"display_name,omitempty"`
	ConnectionID string `json:"connection_id,omitempty"`
}

type Config struct {
	ID             string        `json:"id"`
	Name           string        `json:"name"`
	SystemPrompt   string        `json:"system_prompt"`
	Keywords       []string      `json:"keywords"`
	ResponseStyle  string        `json:"response_style"`
	AgenticEnabled bool          `json:"agentic_enabled"`
	AllowedRoots   []string      `json:"allowed_roots"`
	IsDefault      bool          `json:"is_default"`
	ModelBinding   *ModelBinding `json:"model_binding,omitempty"`
}

type StoreUser struct {
	Bots []Config `json:"bots"`
}

type StoreMigration struct {
	PendingLegacyBots []Config `json:"pending_legacy_bots,omitempty"`
}

type StoreFile struct {
	Version   int                  `json:"version"`
	Users     map[string]StoreUser `json:"users"`
	Migration *StoreMigration      `json:"migration,omitempty"`
}

type Store struct {
	path          string
	mu            sync.RWMutex
	users         map[string][]Config
	pendingLegacy []Config
	existingUsers func() []string
	loaded        bool
}

func NewStore(path string) *Store {
	return &Store{path: strings.TrimSpace(path), users: make(map[string][]Config)}
}

func (s *Store) SetExistingUsers(provider func() []string) {
	s.mu.Lock()
	s.existingUsers = provider
	s.mu.Unlock()
}

func (s *Store) Load() error {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.users = make(map[string][]Config)
	s.pendingLegacy = nil
	data, err := os.ReadFile(s.path)
	if errors.Is(err, os.ErrNotExist) || (err == nil && len(strings.TrimSpace(string(data))) == 0) {
		if _, err := s.seedExistingUsersLocked(nil); err != nil {
			return err
		}
		s.loaded = true
		return s.saveLocked()
	}
	if err != nil {
		return err
	}

	var probe struct {
		Version int             `json:"version"`
		Users   json.RawMessage `json:"users"`
	}
	if err := json.Unmarshal(data, &probe); err == nil && probe.Version == StoreSchemaVersion && len(probe.Users) > 0 {
		var stored StoreFile
		if err := json.Unmarshal(data, &stored); err != nil {
			return err
		}
		needsSave := false
		for userID, entry := range stored.Users {
			userID = NormalizeUserID(userID)
			if userID == "" {
				continue
			}
			normalized, changed := s.normalizeBots(entry.Bots)
			needsSave = needsSave || changed
			s.users[userID] = normalized
		}
		if stored.Migration != nil && len(stored.Migration.PendingLegacyBots) > 0 {
			s.pendingLegacy, _ = s.normalizeBots(stored.Migration.PendingLegacyBots)
		}
		changed, err := s.seedExistingUsersLocked(s.pendingLegacy)
		if err != nil {
			return err
		}
		s.loaded = true
		if changed || needsSave {
			return s.saveLocked()
		}
		return nil
	}

	var legacy []Config
	if err := json.Unmarshal(data, &legacy); err != nil {
		return fmt.Errorf("bots.json ist weder Schema v2 noch ein gueltiges v1-Array: %w", err)
	}
	legacy, _ = s.normalizeBots(legacy)
	if err := backupLegacyBotFile(s.path, data); err != nil {
		return fmt.Errorf("v1-Backup konnte nicht erstellt werden: %w", err)
	}
	if _, err := s.seedExistingUsersLocked(legacy); err != nil {
		return err
	}
	if len(s.users) == 0 {
		s.pendingLegacy = CloneBots(legacy)
	}
	s.loaded = true
	return s.saveLocked()
}

func (s *Store) seedExistingUsersLocked(legacySeed []Config) (bool, error) {
	if s.existingUsers == nil {
		return false, nil
	}
	changed := false
	for _, rawUserID := range s.existingUsers() {
		userID := NormalizeUserID(rawUserID)
		if userID == "" {
			continue
		}
		if _, exists := s.users[userID]; exists {
			continue
		}
		if len(legacySeed) > 0 {
			s.users[userID] = CloneBots(legacySeed)
		} else {
			s.users[userID] = s.defaultBots()
		}
		changed = true
	}
	if changed && len(legacySeed) > 0 {
		s.pendingLegacy = nil
	}
	return changed, nil
}

func (s *Store) defaultBots() []Config {
	return []Config{
		{
			ID:             "scout",
			Name:           "Scout",
			SystemPrompt:   "Du bist Scout in culpeostudio. Antworte direkt, hilfreich und auf Deutsch, sofern der Nutzer nichts anderes wuenscht. Gib keine Safety- oder Policy-Metadaten aus.",
			Keywords:       []string{"scout", "culpeo", "culpeosophie", "culpeosoph"},
			ResponseStyle:  "balanced",
			AgenticEnabled: false,

			AllowedRoots: nil,
			IsDefault:    true,
		},
		{
			ID:             "botbuilder",
			Name:           "Bot-Builder",
			SystemPrompt:   "Du bist der Bot-Builder-Assistent in culpeostudio. Erstelle und ueberarbeite Bots so, dass der Nutzer nur deine gezielten Fragen beantworten muss. Frage nur nach fehlenden Pflichtdetails: Rolle, Ziel, Stil, Grenzen, Antwortstil und Trigger-Keywords. Antwortstil muss einer dieser Werte sein: balanced, short, explain, steps, critical, brainstorm. Wenn genug Informationen vorhanden sind oder der Nutzer eine Ueberarbeitung eines bestehenden Bots verlangt, liefere eine kurze Zusammenfassung und fuege ganz am Ende eine unsichtbare Maschinenzeile ein: [SAVE_BOT: {\"id\":\"optional-vorhandene-id\",\"name\":\"Botname\",\"system_prompt\":\"vollstaendige System-Anweisung\",\"keywords\":[\"keyword1\",\"keyword2\"],\"response_style\":\"balanced\",\"is_default\":false}]. Die Maschinenzeile muss gueltiges JSON enthalten und darf sonst nicht erklaert werden. Der Bot-Builder selbst ist gesperrt und darf nicht bearbeitet werden; wenn der Nutzer das anspricht, erklaere kurz, dass nur andere Bots gespeichert werden koennen, und gib keine SAVE_BOT-Zeile aus. Wenn noch wichtige Informationen fehlen, stelle maximal vier konkrete Fragen und gib keine SAVE_BOT-Zeile aus.",
			Keywords:       []string{"botbuilder", "bot erstellen", "bot bauen", "bot entwerfen", "assistenten erstellen", "neuer bot"},
			ResponseStyle:  "steps",
			AgenticEnabled: false,

			AllowedRoots: nil,
			IsDefault:    false,
		},
	}
}

func (s *Store) normalizeBots(input []Config) ([]Config, bool) {
	defaults := s.defaultBots()
	out := make([]Config, 0, len(input)+2)
	changed := false
	hasScout := false
	hasBotBuilder := false
	hasDefault := false
	for _, original := range input {
		bot := CloneBot(original)
		bot.ID = strings.TrimSpace(bot.ID)
		if bot.ID == "" {
			changed = true
			continue
		}
		bot.Name = strings.TrimSpace(bot.Name)
		bot.SystemPrompt = strings.TrimSpace(bot.SystemPrompt)
		bot.Keywords = CleanKeywords(bot.Keywords)
		bot.AllowedRoots = NormalizeAllowedRoots(bot.AllowedRoots)
		bot.ResponseStyle = NormalizeResponseStyle(bot.ResponseStyle)
		if bot.ModelBinding != nil {
			binding, err := NormalizeModelBinding(bot.ModelBinding)
			if err == nil {
				bot.ModelBinding = binding
			}

		}
		if bot.ID == "scout" {
			hasScout = true
		}
		if bot.ID == "botbuilder" {
			hasBotBuilder = true
			if !reflect.DeepEqual(bot, defaults[1]) {
				changed = true
			}
			bot = CloneBot(defaults[1])
		}
		if bot.IsDefault {
			hasDefault = true
		}
		if !reflect.DeepEqual(bot, original) {
			changed = true
		}
		out = append(out, bot)
	}
	if !hasScout {
		out = append([]Config{CloneBot(defaults[0])}, out...)
		hasDefault = true
		changed = true
	}
	if !hasBotBuilder {
		out = append(out, CloneBot(defaults[1]))
		changed = true
	}
	if !hasDefault {
		for i := range out {
			if out[i].ID == "scout" {
				out[i].IsDefault = true
				hasDefault = true
				changed = true
				break
			}
		}
	}
	return out, changed
}

func (s *Store) saveLocked() error {
	stored := StoreFile{Version: StoreSchemaVersion, Users: make(map[string]StoreUser, len(s.users))}
	for userID, bots := range s.users {
		stored.Users[userID] = StoreUser{Bots: CloneBots(bots)}
	}
	if len(s.pendingLegacy) > 0 {
		stored.Migration = &StoreMigration{PendingLegacyBots: CloneBots(s.pendingLegacy)}
	}
	data, err := json.MarshalIndent(stored, "", "  ")
	if err != nil {
		return err
	}
	data = append(data, '\n')
	return writeBotFileAtomic(s.path, data)
}

func (s *Store) EnsureUser(rawUserID string) error {
	userID := NormalizeUserID(rawUserID)
	if userID == "" {
		return errors.New("user_id ist erforderlich")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, exists := s.users[userID]; exists {
		return nil
	}
	if len(s.pendingLegacy) > 0 && len(s.users) == 0 {
		s.users[userID] = CloneBots(s.pendingLegacy)
		s.pendingLegacy = nil
	} else {
		s.users[userID] = s.defaultBots()
	}
	if !s.loaded {
		return nil
	}
	return s.saveLocked()
}

func (s *Store) GetBotsForUser(rawUserID string) []Config {
	userID := NormalizeUserID(rawUserID)
	s.mu.RLock()
	bots := CloneBots(s.users[userID])
	s.mu.RUnlock()
	if len(bots) == 0 {
		return s.defaultBots()
	}
	return bots
}

func (s *Store) GetBotForUser(rawUserID, id string) (Config, bool) {
	id = strings.TrimSpace(id)
	for _, bot := range s.GetBotsForUser(rawUserID) {
		if bot.ID == id {
			return bot, true
		}
	}
	return Config{}, false
}

func (s *Store) SaveBotForUser(rawUserID string, bot Config) error {
	userID := NormalizeUserID(rawUserID)
	if userID == "" {
		return errors.New("user_id ist erforderlich")
	}
	bot.ID = strings.TrimSpace(bot.ID)
	if bot.ID == "botbuilder" {
		return ErrBotBuilderLocked
	}
	if bot.ID == "" {
		return errors.New("bot id ist erforderlich")
	}
	bot.Name = strings.TrimSpace(bot.Name)
	bot.SystemPrompt = strings.TrimSpace(bot.SystemPrompt)
	bot.Keywords = CleanKeywords(bot.Keywords)
	bot.AllowedRoots = NormalizeAllowedRoots(bot.AllowedRoots)
	bot.ResponseStyle = NormalizeResponseStyle(bot.ResponseStyle)
	if bot.ModelBinding != nil {
		binding, err := NormalizeModelBinding(bot.ModelBinding)
		if err != nil {
			return err
		}
		bot.ModelBinding = binding
	}

	s.mu.Lock()
	defer s.mu.Unlock()
	bots, exists := s.users[userID]
	if !exists {
		bots = s.defaultBots()
	}
	if bot.IsDefault {
		for i := range bots {
			bots[i].IsDefault = false
		}
	}
	found := false
	for i, current := range bots {
		if current.ID != bot.ID {
			continue
		}
		if current.IsDefault && !bot.IsDefault {
			anotherDefault := false
			for j, other := range bots {
				if i != j && other.IsDefault {
					anotherDefault = true
					break
				}
			}
			if !anotherDefault {
				bot.IsDefault = true
			}
		}
		bots[i] = CloneBot(bot)
		found = true
		break
	}
	if !found {
		bots = append(bots, CloneBot(bot))
	}
	if !hasDefaultBot(bots) {
		setPreferredDefault(bots)
	}
	s.users[userID] = bots
	return s.saveLocked()
}

func (s *Store) DeleteBotForUser(rawUserID, id string) error {
	userID := NormalizeUserID(rawUserID)
	id = strings.TrimSpace(id)
	if userID == "" {
		return errors.New("user_id ist erforderlich")
	}
	if id == "scout" || id == "botbuilder" {
		return nil
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	bots, exists := s.users[userID]
	if !exists {
		return nil
	}
	deleted := -1
	for i, bot := range bots {
		if bot.ID == id {
			deleted = i
			break
		}
	}
	if deleted < 0 {
		return nil
	}
	wasDefault := bots[deleted].IsDefault
	bots = append(bots[:deleted], bots[deleted+1:]...)
	if wasDefault {
		setPreferredDefault(bots)
	}
	s.users[userID] = bots
	return s.saveLocked()
}

func (s *Store) MatchBotByKeywordForUser(rawUserID, message string) (Config, bool) {
	bots := s.GetBotsForUser(rawUserID)
	msgLower := strings.ToLower(message)
	for _, bot := range bots {
		if bot.IsDefault || bot.ID == "scout" {
			continue
		}
		if botKeywordMatches(bot, msgLower) {
			return bot, true
		}
	}
	var fallback Config
	for _, bot := range bots {
		if bot.IsDefault || bot.ID == "scout" {
			fallback = bot
			if botKeywordMatches(bot, msgLower) {
				return bot, true
			}
		}
	}
	if fallback.ID != "" {
		return fallback, false
	}
	return s.defaultBots()[0], false
}

func (s *Store) GetBots() []Config         { return s.GetBotsForUser("local") }
func (s *Store) SaveBot(bot Config) error  { return s.SaveBotForUser("local", bot) }
func (s *Store) DeleteBot(id string) error { return s.DeleteBotForUser("local", id) }
func (s *Store) MatchBotByKeyword(message string) (Config, bool) {
	return s.MatchBotByKeywordForUser("local", message)
}
func (s *Store) MatchBot(message string) Config {
	bot, _ := s.MatchBotByKeyword(message)
	return bot
}

func NormalizeModelBinding(input *ModelBinding) (*ModelBinding, error) {
	if input == nil {
		return nil, nil
	}
	binding := *input
	binding.Kind = strings.ToLower(strings.TrimSpace(binding.Kind))
	binding.ModelRef = strings.TrimSpace(binding.ModelRef)
	binding.Provider = apimodels.NormalizeProvider(binding.Provider)
	binding.ModelID = strings.TrimSpace(binding.ModelID)
	binding.InstanceID = strings.TrimSpace(binding.InstanceID)
	binding.DisplayName = strings.TrimSpace(binding.DisplayName)
	binding.ConnectionID = strings.TrimSpace(binding.ConnectionID)
	if binding.Kind == "" {
		if binding.Provider == "local" || binding.InstanceID != "" || strings.HasPrefix(strings.ToLower(binding.ModelRef), "local:") {
			binding.Kind = "local"
		} else {
			binding.Kind = "api"
		}
	}
	switch binding.Kind {
	case "local":
		if binding.InstanceID == "" && strings.HasPrefix(strings.ToLower(binding.ModelRef), "local:") {
			binding.InstanceID = strings.TrimSpace(binding.ModelRef[len("local:"):])
		}
		if binding.InstanceID == "" {
			binding.InstanceID = binding.ModelID
		}
		if binding.InstanceID == "" {
			return nil, fmt.Errorf("%w: instance_id ist fuer lokale Modelle erforderlich", ErrInvalidModelBinding)
		}
		binding.Provider = "local"
		binding.ConnectionID = ""
		binding.ModelRef = "local:" + binding.InstanceID
		if binding.ModelID == "" {
			binding.ModelID = binding.InstanceID
		}
	case "api":
		if binding.ConnectionID != "" {
			if binding.ModelID == "" {
				return nil, fmt.Errorf("%w: model_id ist fuer verbundene API-Modelle erforderlich", ErrInvalidModelBinding)
			}
			binding.InstanceID = ""
			binding.ModelRef = providerconn.ModelRef(binding.ConnectionID, binding.ModelID)
			break
		}
		if (binding.Provider == "" || binding.ModelID == "") && binding.ModelRef != "" {
			provider, modelID := decodeAPIModelRef(binding.ModelRef)
			if binding.Provider == "" {
				binding.Provider = provider
			}
			if binding.ModelID == "" {
				binding.ModelID = modelID
			}
		}
		if !apimodels.IsSupportedProvider(binding.Provider) {
			return nil, fmt.Errorf("%w: provider wird fuer API-Chat nicht unterstuetzt", ErrInvalidModelBinding)
		}
		if binding.ModelID == "" {
			return nil, fmt.Errorf("%w: model_id ist fuer API-Modelle erforderlich", ErrInvalidModelBinding)
		}
		binding.InstanceID = ""
		binding.ModelRef = apimodels.ModelRef(binding.Provider, binding.ModelID)
	default:
		return nil, fmt.Errorf("%w: kind muss local oder api sein", ErrInvalidModelBinding)
	}
	if binding.DisplayName == "" {
		binding.DisplayName = binding.ModelID
	}
	return &binding, nil
}

func decodeAPIModelRef(modelRef string) (string, string) {
	parts := strings.SplitN(strings.TrimSpace(modelRef), ":", 2)
	if len(parts) != 2 {
		return "", ""
	}
	decoded, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return "", ""
	}
	return apimodels.NormalizeProvider(parts[0]), strings.TrimSpace(string(decoded))
}

func NormalizeUserID(value string) string {

	return strings.ToLower(strings.TrimSpace(value))
}

func CloneBots(input []Config) []Config {
	out := make([]Config, len(input))
	for i := range input {
		out[i] = CloneBot(input[i])
	}
	return out
}

func CloneBot(input Config) Config {
	input.Keywords = append([]string(nil), input.Keywords...)
	input.AllowedRoots = append([]string(nil), input.AllowedRoots...)
	if input.ModelBinding != nil {
		binding := *input.ModelBinding
		input.ModelBinding = &binding
	}
	return input
}

func hasDefaultBot(bots []Config) bool {
	for _, bot := range bots {
		if bot.IsDefault {
			return true
		}
	}
	return false
}

func setPreferredDefault(bots []Config) {
	if len(bots) == 0 {
		return
	}
	index := 0
	for i := range bots {
		bots[i].IsDefault = false
		if bots[i].ID == "scout" {
			index = i
		}
	}
	bots[index].IsDefault = true
}

func botKeywordMatches(bot Config, lowerMessage string) bool {
	for _, keyword := range bot.Keywords {
		clean := strings.ToLower(strings.TrimSpace(keyword))
		if clean != "" && strings.Contains(lowerMessage, clean) {
			return true
		}
	}
	return false
}

func backupLegacyBotFile(path string, data []byte) error {
	base := path + ".v1.bak"
	for index := 0; ; index++ {
		candidate := base
		if index > 0 {
			candidate = fmt.Sprintf("%s.%d", base, index)
		}
		existing, err := os.ReadFile(candidate)
		if err == nil {
			if bytes.Equal(existing, data) {
				return nil
			}
			continue
		}
		if !errors.Is(err, os.ErrNotExist) {
			return err
		}
		if err := os.MkdirAll(filepath.Dir(candidate), 0o755); err != nil {
			return err
		}
		file, err := os.OpenFile(candidate, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o600)
		if errors.Is(err, os.ErrExist) {
			continue
		}
		if err != nil {
			return err
		}
		_, writeErr := file.Write(data)
		if writeErr == nil {
			writeErr = file.Sync()
		}
		closeErr := file.Close()
		if writeErr != nil {
			_ = os.Remove(candidate)
			return writeErr
		}
		return closeErr
	}
}

func writeBotFileAtomic(path string, data []byte) error {
	if strings.TrimSpace(path) == "" {
		return errors.New("bot store path ist leer")
	}
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	temp, err := os.CreateTemp(dir, ".bots-*.tmp")
	if err != nil {
		return err
	}
	tempPath := temp.Name()
	defer os.Remove(tempPath)
	if err := temp.Chmod(0o600); err != nil {
		_ = temp.Close()
		return err
	}
	if _, err := temp.Write(data); err != nil {
		_ = temp.Close()
		return err
	}
	if err := temp.Sync(); err != nil {
		_ = temp.Close()
		return err
	}
	if err := temp.Close(); err != nil {
		return err
	}
	return os.Rename(tempPath, path)
}

func CleanKeywords(keywords []string) []string {
	cleaned := make([]string, 0, len(keywords))
	seen := make(map[string]struct{}, len(keywords))
	for _, keyword := range keywords {
		kw := strings.TrimSpace(keyword)
		if kw == "" {
			continue
		}
		key := strings.ToLower(kw)
		if _, exists := seen[key]; exists {
			continue
		}
		seen[key] = struct{}{}
		cleaned = append(cleaned, kw)
	}
	return cleaned
}

func NormalizeAllowedRoots(values []string) []string {
	roots := make([]string, 0, len(values))
	seen := map[string]struct{}{}
	for _, value := range values {
		trimmed := strings.TrimSpace(value)
		if trimmed == "" {
			continue
		}
		key := strings.ToLower(trimmed)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		roots = append(roots, trimmed)
	}
	return roots
}

func NormalizeResponseStyle(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "balanced", "short", "explain", "steps", "critical", "brainstorm":
		return strings.ToLower(strings.TrimSpace(value))
	default:
		return "balanced"
	}
}
