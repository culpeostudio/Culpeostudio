package philobot

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

	"github.com/fillyengine/backend/internal/apimodels"
)

const botStoreSchemaVersion = 2

var (
	errBotBuilderLocked    = errors.New("botbuilder ist gesperrt und kann nicht bearbeitet werden")
	errInvalidModelBinding = errors.New("ungueltige Modellbindung")
)

// ModelBinding pins a bot either to one local Engine instance or to an API
// provider model. A binding is authoritative when the bot is selected.
type ModelBinding struct {
	Kind        string `json:"kind"`
	ModelRef    string `json:"model_ref,omitempty"`
	Provider    string `json:"provider,omitempty"`
	ModelID     string `json:"model_id,omitempty"`
	InstanceID  string `json:"instance_id,omitempty"`
	DisplayName string `json:"display_name,omitempty"`
}

// BotConfig defines the configuration for a philobot personality.
type BotConfig struct {
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

type botStoreUser struct {
	Bots []BotConfig `json:"bots"`
}

type botStoreMigration struct {
	// PendingLegacyBots is only present when a v1 array was migrated before
	// any login account existed. The first real user receives this seed once.
	PendingLegacyBots []BotConfig `json:"pending_legacy_bots,omitempty"`
}

type botStoreFile struct {
	Version   int                     `json:"version"`
	Users     map[string]botStoreUser `json:"users"`
	Migration *botStoreMigration      `json:"migration,omitempty"`
}

// BotStore manages per-login bot persistence and lookup.
type BotStore struct {
	path          string
	mu            sync.RWMutex
	users         map[string][]BotConfig
	pendingLegacy []BotConfig
	existingUsers func() []string
	loaded        bool
}

// NewBotStore creates a new BotStore.
func NewBotStore(path string) *BotStore {
	return &BotStore{path: strings.TrimSpace(path), users: make(map[string][]BotConfig)}
}

// SetExistingUsers supplies login accounts for one-time v1 migration. It must
// normally be configured before Load; setting it later is still safe and will
// be applied on the next Load.
func (s *BotStore) SetExistingUsers(provider func() []string) {
	s.mu.Lock()
	s.existingUsers = provider
	s.mu.Unlock()
}

// Load reads schema v2 or migrates the legacy top-level bot array. The exact
// v1 bytes are backed up before the v2 file is written.
func (s *BotStore) Load() error {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.users = make(map[string][]BotConfig)
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
	if err := json.Unmarshal(data, &probe); err == nil && probe.Version == botStoreSchemaVersion && len(probe.Users) > 0 {
		var stored botStoreFile
		if err := json.Unmarshal(data, &stored); err != nil {
			return err
		}
		needsSave := false
		for userID, entry := range stored.Users {
			userID = normalizeBotUserID(userID)
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

	var legacy []BotConfig
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
		s.pendingLegacy = cloneBots(legacy)
	}
	s.loaded = true
	return s.saveLocked()
}

// seedExistingUsersLocked ensures every currently known account has a bot
// namespace. legacySeed is copied only during migration, never to later users.
func (s *BotStore) seedExistingUsersLocked(legacySeed []BotConfig) (bool, error) {
	if s.existingUsers == nil {
		return false, nil
	}
	changed := false
	for _, rawUserID := range s.existingUsers() {
		userID := normalizeBotUserID(rawUserID)
		if userID == "" {
			continue
		}
		if _, exists := s.users[userID]; exists {
			continue
		}
		if len(legacySeed) > 0 {
			s.users[userID] = cloneBots(legacySeed)
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

func (s *BotStore) defaultBots() []BotConfig {
	return []BotConfig{
		{
			ID:             "philobot",
			Name:           "PhiloBot",
			SystemPrompt:   "Du bist PhiloBot in myphilostudio. Antworte direkt, hilfreich und auf Deutsch, sofern der Nutzer nichts anderes wuenscht. Gib keine Safety- oder Policy-Metadaten aus.",
			Keywords:       []string{"philobot", "philo", "philosophie", "philosoph"},
			ResponseStyle:  "balanced",
			AgenticEnabled: false,
			// Keine Vorgabe-Wurzeln: welche Ordner ein Bot lesen darf, ergibt
			// sich aus dem Projekt, dem die Sitzung zugeordnet ist. Feste Pfade
			// waeren auf einem fremden Rechner ohnehin ungueltig.
			AllowedRoots: nil,
			IsDefault: true,
		},
		{
			ID:             "botbuilder",
			Name:           "Bot-Builder",
			SystemPrompt:   "Du bist der Bot-Builder-Assistent in myphilostudio. Erstelle und ueberarbeite Bots so, dass der Nutzer nur deine gezielten Fragen beantworten muss. Frage nur nach fehlenden Pflichtdetails: Rolle, Ziel, Stil, Grenzen, Antwortstil und Trigger-Keywords. Antwortstil muss einer dieser Werte sein: balanced, short, explain, steps, critical, brainstorm. Wenn genug Informationen vorhanden sind oder der Nutzer eine Ueberarbeitung eines bestehenden Bots verlangt, liefere eine kurze Zusammenfassung und fuege ganz am Ende eine unsichtbare Maschinenzeile ein: [SAVE_BOT: {\"id\":\"optional-vorhandene-id\",\"name\":\"Botname\",\"system_prompt\":\"vollstaendige System-Anweisung\",\"keywords\":[\"keyword1\",\"keyword2\"],\"response_style\":\"balanced\",\"is_default\":false}]. Die Maschinenzeile muss gueltiges JSON enthalten und darf sonst nicht erklaert werden. Der Bot-Builder selbst ist gesperrt und darf nicht bearbeitet werden; wenn der Nutzer das anspricht, erklaere kurz, dass nur andere Bots gespeichert werden koennen, und gib keine SAVE_BOT-Zeile aus. Wenn noch wichtige Informationen fehlen, stelle maximal vier konkrete Fragen und gib keine SAVE_BOT-Zeile aus.",
			Keywords:       []string{"botbuilder", "bot erstellen", "bot bauen", "bot entwerfen", "assistenten erstellen", "neuer bot"},
			ResponseStyle:  "steps",
			AgenticEnabled: false,
			// Keine Vorgabe-Wurzeln: welche Ordner ein Bot lesen darf, ergibt
			// sich aus dem Projekt, dem die Sitzung zugeordnet ist. Feste Pfade
			// waeren auf einem fremden Rechner ohnehin ungueltig.
			AllowedRoots: nil,
			IsDefault: false,
		},
	}
}

func (s *BotStore) normalizeBots(input []BotConfig) ([]BotConfig, bool) {
	defaults := s.defaultBots()
	out := make([]BotConfig, 0, len(input)+2)
	changed := false
	hasPhiloBot := false
	hasBotBuilder := false
	hasDefault := false
	for _, original := range input {
		bot := cloneBot(original)
		bot.ID = strings.TrimSpace(bot.ID)
		if bot.ID == "" {
			changed = true
			continue
		}
		bot.Name = strings.TrimSpace(bot.Name)
		bot.SystemPrompt = strings.TrimSpace(bot.SystemPrompt)
		bot.Keywords = cleanKeywords(bot.Keywords)
		bot.AllowedRoots = normalizeAllowedRoots(bot.AllowedRoots)
		bot.ResponseStyle = normalizeResponseStyle(bot.ResponseStyle)
		if bot.ModelBinding != nil {
			binding, err := normalizeModelBinding(bot.ModelBinding)
			if err == nil {
				bot.ModelBinding = binding
			}
			// Invalid persisted bindings stay intact. Erasing them here would turn
			// a pinned bot into an unbound bot and silently route it through the
			// session's normal model. The request path validates the preserved
			// binding and returns model_binding_invalid instead.
		}
		if bot.ID == "philobot" {
			hasPhiloBot = true
		}
		if bot.ID == "botbuilder" {
			hasBotBuilder = true
			if !reflect.DeepEqual(bot, defaults[1]) {
				changed = true
			}
			bot = cloneBot(defaults[1])
		}
		if bot.IsDefault {
			hasDefault = true
		}
		if !reflect.DeepEqual(bot, original) {
			changed = true
		}
		out = append(out, bot)
	}
	if !hasPhiloBot {
		out = append([]BotConfig{cloneBot(defaults[0])}, out...)
		hasDefault = true
		changed = true
	}
	if !hasBotBuilder {
		out = append(out, cloneBot(defaults[1]))
		changed = true
	}
	if !hasDefault {
		for i := range out {
			if out[i].ID == "philobot" {
				out[i].IsDefault = true
				hasDefault = true
				changed = true
				break
			}
		}
	}
	return out, changed
}

func (s *BotStore) saveLocked() error {
	stored := botStoreFile{Version: botStoreSchemaVersion, Users: make(map[string]botStoreUser, len(s.users))}
	for userID, bots := range s.users {
		stored.Users[userID] = botStoreUser{Bots: cloneBots(bots)}
	}
	if len(s.pendingLegacy) > 0 {
		stored.Migration = &botStoreMigration{PendingLegacyBots: cloneBots(s.pendingLegacy)}
	}
	data, err := json.MarshalIndent(stored, "", "  ")
	if err != nil {
		return err
	}
	data = append(data, '\n')
	return writeBotFileAtomic(s.path, data)
}

// EnsureUser creates a namespace for a new login. Only the first user after a
// no-account v1 migration receives the legacy seed; all later users get the two
// system bots.
func (s *BotStore) EnsureUser(rawUserID string) error {
	userID := normalizeBotUserID(rawUserID)
	if userID == "" {
		return errors.New("user_id ist erforderlich")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, exists := s.users[userID]; exists {
		return nil
	}
	if len(s.pendingLegacy) > 0 && len(s.users) == 0 {
		s.users[userID] = cloneBots(s.pendingLegacy)
		s.pendingLegacy = nil
	} else {
		s.users[userID] = s.defaultBots()
	}
	if !s.loaded {
		return nil
	}
	return s.saveLocked()
}

// GetBotsForUser returns a deep copy of one login's bots.
func (s *BotStore) GetBotsForUser(rawUserID string) []BotConfig {
	userID := normalizeBotUserID(rawUserID)
	s.mu.RLock()
	bots := cloneBots(s.users[userID])
	s.mu.RUnlock()
	if len(bots) == 0 {
		return s.defaultBots()
	}
	return bots
}

func (s *BotStore) GetBotForUser(rawUserID, id string) (BotConfig, bool) {
	id = strings.TrimSpace(id)
	for _, bot := range s.GetBotsForUser(rawUserID) {
		if bot.ID == id {
			return bot, true
		}
	}
	return BotConfig{}, false
}

// SaveBotForUser inserts or updates only the caller's bot namespace.
func (s *BotStore) SaveBotForUser(rawUserID string, bot BotConfig) error {
	userID := normalizeBotUserID(rawUserID)
	if userID == "" {
		return errors.New("user_id ist erforderlich")
	}
	bot.ID = strings.TrimSpace(bot.ID)
	if bot.ID == "botbuilder" {
		return errBotBuilderLocked
	}
	if bot.ID == "" {
		return errors.New("bot id ist erforderlich")
	}
	bot.Name = strings.TrimSpace(bot.Name)
	bot.SystemPrompt = strings.TrimSpace(bot.SystemPrompt)
	bot.Keywords = cleanKeywords(bot.Keywords)
	bot.AllowedRoots = normalizeAllowedRoots(bot.AllowedRoots)
	bot.ResponseStyle = normalizeResponseStyle(bot.ResponseStyle)
	if bot.ModelBinding != nil {
		binding, err := normalizeModelBinding(bot.ModelBinding)
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
		bots[i] = cloneBot(bot)
		found = true
		break
	}
	if !found {
		bots = append(bots, cloneBot(bot))
	}
	if !hasDefaultBot(bots) {
		setPreferredDefault(bots)
	}
	s.users[userID] = bots
	return s.saveLocked()
}

// DeleteBotForUser deletes a custom bot only for the caller.
func (s *BotStore) DeleteBotForUser(rawUserID, id string) error {
	userID := normalizeBotUserID(rawUserID)
	id = strings.TrimSpace(id)
	if userID == "" {
		return errors.New("user_id ist erforderlich")
	}
	if id == "philobot" || id == "botbuilder" {
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

// MatchBotByKeywordForUser prefers custom/non-default bots and otherwise
// returns the user's default bot.
func (s *BotStore) MatchBotByKeywordForUser(rawUserID, message string) (BotConfig, bool) {
	bots := s.GetBotsForUser(rawUserID)
	msgLower := strings.ToLower(message)
	for _, bot := range bots {
		if bot.IsDefault || bot.ID == "philobot" {
			continue
		}
		if botKeywordMatches(bot, msgLower) {
			return bot, true
		}
	}
	var fallback BotConfig
	for _, bot := range bots {
		if bot.IsDefault || bot.ID == "philobot" {
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

// Backward-compatible helpers use the local test/standalone namespace.
func (s *BotStore) GetBots() []BotConfig        { return s.GetBotsForUser("local") }
func (s *BotStore) SaveBot(bot BotConfig) error { return s.SaveBotForUser("local", bot) }
func (s *BotStore) DeleteBot(id string) error   { return s.DeleteBotForUser("local", id) }
func (s *BotStore) MatchBotByKeyword(message string) (BotConfig, bool) {
	return s.MatchBotByKeywordForUser("local", message)
}
func (s *BotStore) MatchBot(message string) BotConfig {
	bot, _ := s.MatchBotByKeyword(message)
	return bot
}

func normalizeModelBinding(input *ModelBinding) (*ModelBinding, error) {
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
			return nil, fmt.Errorf("%w: instance_id ist fuer lokale Modelle erforderlich", errInvalidModelBinding)
		}
		binding.Provider = "local"
		binding.ModelRef = "local:" + binding.InstanceID
		if binding.ModelID == "" {
			binding.ModelID = binding.InstanceID
		}
	case "api":
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
			return nil, fmt.Errorf("%w: provider wird fuer API-Chat nicht unterstuetzt", errInvalidModelBinding)
		}
		if binding.ModelID == "" {
			return nil, fmt.Errorf("%w: model_id ist fuer API-Modelle erforderlich", errInvalidModelBinding)
		}
		binding.InstanceID = ""
		binding.ModelRef = apimodels.ModelRef(binding.Provider, binding.ModelID)
	default:
		return nil, fmt.Errorf("%w: kind muss local oder api sein", errInvalidModelBinding)
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

func normalizeBotUserID(value string) string {
	// Bot namespaces are JSON object keys, not filesystem paths. Keep the full
	// login identity and use the exact same case-insensitive normalization as
	// AccountStore. Sanitizing characters here would merge distinct accounts
	// such as "alice" and "alice!", and could collapse Unicode-only names to an
	// empty/shared namespace.
	return strings.ToLower(strings.TrimSpace(value))
}

func cloneBots(input []BotConfig) []BotConfig {
	out := make([]BotConfig, len(input))
	for i := range input {
		out[i] = cloneBot(input[i])
	}
	return out
}

func cloneBot(input BotConfig) BotConfig {
	input.Keywords = append([]string(nil), input.Keywords...)
	input.AllowedRoots = append([]string(nil), input.AllowedRoots...)
	if input.ModelBinding != nil {
		binding := *input.ModelBinding
		input.ModelBinding = &binding
	}
	return input
}

func hasDefaultBot(bots []BotConfig) bool {
	for _, bot := range bots {
		if bot.IsDefault {
			return true
		}
	}
	return false
}

func setPreferredDefault(bots []BotConfig) {
	if len(bots) == 0 {
		return
	}
	index := 0
	for i := range bots {
		bots[i].IsDefault = false
		if bots[i].ID == "philobot" {
			index = i
		}
	}
	bots[index].IsDefault = true
}

func botKeywordMatches(bot BotConfig, lowerMessage string) bool {
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
