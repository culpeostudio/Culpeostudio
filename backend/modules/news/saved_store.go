package news

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"
)

const (
	savedArticlesSchema = 1

	maxSavedArticlesPerUser = 500

	maxSavedTitleLength   = 300
	maxSavedContentLength = 1200
	maxSavedURLLength     = 2000
	maxSavedTagCount      = 12
)

var errSavedArticleIncomplete = errors.New("Beitrag braucht id und title")

type SavedArticle struct {
	NewsItem
	SavedAt time.Time `json:"saved_at"`
}

type persistedSavedArticles struct {
	SchemaVersion int                       `json:"schema_version"`
	Users         map[string][]SavedArticle `json:"users"`
}

type SavedStore struct {
	path  string
	mu    sync.RWMutex
	users map[string][]SavedArticle
}

func NewSavedStore(path string) *SavedStore {
	return &SavedStore{
		path:  strings.TrimSpace(path),
		users: make(map[string][]SavedArticle),
	}
}

func (s *SavedStore) Load() error {
	if s == nil {
		return errors.New("Merkliste ist nicht initialisiert")
	}
	if s.path == "" {
		return errors.New("Merklisten-Dateipfad ist leer")
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	payload, err := os.ReadFile(s.path)
	if errors.Is(err, os.ErrNotExist) {
		s.users = make(map[string][]SavedArticle)
		return nil
	}
	if err != nil {
		return fmt.Errorf("Merkliste lesen: %w", err)
	}
	if len(strings.TrimSpace(string(payload))) == 0 {
		s.users = make(map[string][]SavedArticle)
		return nil
	}

	var persisted persistedSavedArticles
	if err := json.Unmarshal(payload, &persisted); err != nil {
		return fmt.Errorf("Merkliste enthaelt ungueltiges JSON: %w", err)
	}
	if persisted.SchemaVersion != savedArticlesSchema {
		return fmt.Errorf("Merklisten-Schema %d wird nicht unterstuetzt", persisted.SchemaVersion)
	}

	loaded := make(map[string][]SavedArticle, len(persisted.Users))
	for userID, articles := range persisted.Users {
		userID = normalizeSavedUserID(userID)
		if userID == "" {
			continue
		}
		cleaned := make([]SavedArticle, 0, len(articles))
		for _, article := range articles {
			normalized, err := normalizeSavedArticle(article)
			if err != nil {

				continue
			}
			cleaned = append(cleaned, normalized)
		}
		loaded[userID] = sortedSavedArticles(cleaned)
	}

	s.users = loaded
	if err := os.Chmod(s.path, 0o600); err != nil {
		return fmt.Errorf("Merklisten-Berechtigungen setzen: %w", err)
	}
	return nil
}

func (s *SavedStore) List(userID string) []SavedArticle {
	if s == nil {
		return nil
	}
	key := normalizeSavedUserID(userID)
	if key == "" {
		return nil
	}

	s.mu.RLock()
	defer s.mu.RUnlock()
	articles := s.users[key]
	copied := make([]SavedArticle, len(articles))
	copy(copied, articles)
	return copied
}

func (s *SavedStore) Save(userID string, item NewsItem, savedAt time.Time) (SavedArticle, error) {
	if s == nil {
		return SavedArticle{}, errors.New("Merkliste ist nicht initialisiert")
	}
	key := normalizeSavedUserID(userID)
	if key == "" {
		return SavedArticle{}, errors.New("Benutzerkennung ist erforderlich")
	}

	article, err := normalizeSavedArticle(SavedArticle{NewsItem: item, SavedAt: savedAt})
	if err != nil {
		return SavedArticle{}, err
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	next := cloneSavedArticles(s.users)
	articles := next[key]
	replaced := false
	for index, existing := range articles {
		if existing.ID == article.ID {
			articles[index] = article
			replaced = true
			break
		}
	}
	if !replaced {
		articles = append(articles, article)
	}
	articles = sortedSavedArticles(articles)
	if len(articles) > maxSavedArticlesPerUser {
		articles = articles[:maxSavedArticlesPerUser]
	}
	next[key] = articles

	if err := s.writeLocked(next); err != nil {
		return SavedArticle{}, err
	}
	s.users = next
	return article, nil
}

func (s *SavedStore) Delete(userID string, articleID string) (bool, error) {
	if s == nil {
		return false, errors.New("Merkliste ist nicht initialisiert")
	}
	key := normalizeSavedUserID(userID)
	if key == "" {
		return false, errors.New("Benutzerkennung ist erforderlich")
	}
	articleID = strings.TrimSpace(articleID)
	if articleID == "" {
		return false, nil
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	articles, ok := s.users[key]
	if !ok {
		return false, nil
	}
	remaining := make([]SavedArticle, 0, len(articles))
	for _, article := range articles {
		if article.ID == articleID {
			continue
		}
		remaining = append(remaining, article)
	}
	if len(remaining) == len(articles) {
		return false, nil
	}

	next := cloneSavedArticles(s.users)
	next[key] = remaining
	if err := s.writeLocked(next); err != nil {
		return false, err
	}
	s.users = next
	return true, nil
}

func (s *SavedStore) writeLocked(users map[string][]SavedArticle) error {
	if s.path == "" {
		return errors.New("Merklisten-Dateipfad ist leer")
	}
	persisted := persistedSavedArticles{
		SchemaVersion: savedArticlesSchema,
		Users:         users,
	}
	payload, err := json.MarshalIndent(persisted, "", "  ")
	if err != nil {
		return fmt.Errorf("Merkliste serialisieren: %w", err)
	}
	return atomicPrivateWrite(s.path, append(payload, '\n'))
}

func normalizeSavedUserID(userID string) string {
	return strings.Clone(strings.ToLower(strings.TrimSpace(userID)))
}

func normalizeSavedArticle(article SavedArticle) (SavedArticle, error) {
	article.ID = strings.TrimSpace(article.ID)
	article.Title = truncateRunes(strings.TrimSpace(stripHTML(article.Title)), maxSavedTitleLength)
	article.Content = truncateRunes(strings.TrimSpace(stripHTML(article.Content)), maxSavedContentLength)
	article.Author = truncateRunes(strings.TrimSpace(stripHTML(article.Author)), maxSavedTitleLength)
	article.Category = truncateRunes(strings.TrimSpace(stripHTML(article.Category)), maxSavedTitleLength)
	article.URL = truncateRunes(strings.TrimSpace(article.URL), maxSavedURLLength)
	article.ImageURL = normalizeImageURL(article.ImageURL)

	if article.ID == "" || article.Title == "" {
		return SavedArticle{}, errSavedArticleIncomplete
	}

	tags := make([]string, 0, len(article.Tags))
	for _, tag := range article.Tags {
		tag = truncateRunes(strings.TrimSpace(stripHTML(tag)), 40)
		if tag == "" {
			continue
		}
		tags = append(tags, tag)
		if len(tags) == maxSavedTagCount {
			break
		}
	}
	article.Tags = tags

	if article.SavedAt.IsZero() {
		article.SavedAt = time.Now().UTC()
	}
	article.SavedAt = article.SavedAt.UTC()
	return article, nil
}

func truncateRunes(value string, limit int) string {
	runes := []rune(value)
	if len(runes) <= limit {
		return value
	}
	return string(runes[:limit])
}

func sortedSavedArticles(articles []SavedArticle) []SavedArticle {
	sort.SliceStable(articles, func(i, j int) bool {
		if articles[i].SavedAt.Equal(articles[j].SavedAt) {
			return articles[i].ID < articles[j].ID
		}
		return articles[i].SavedAt.After(articles[j].SavedAt)
	})
	return articles
}

func cloneSavedArticles(users map[string][]SavedArticle) map[string][]SavedArticle {
	cloned := make(map[string][]SavedArticle, len(users)+1)
	for userID, articles := range users {
		copied := make([]SavedArticle, len(articles))
		copy(copied, articles)
		cloned[userID] = copied
	}
	return cloned
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
