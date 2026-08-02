// Package security holds the HTTP hardening middleware applied to every route.
package security

import (
	"crypto/hmac"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"strings"
	"sync"
	"time"

	"github.com/gofiber/fiber/v2"
)

const UserIDLocalKey = "memory_user_id"

func VerifyUserToken(masterToken, userToken, userID string) bool {
	masterToken = strings.TrimSpace(masterToken)
	userToken = strings.TrimSpace(userToken)
	userID = SanitizeUserID(userID)
	if masterToken == "" || userToken == "" || userID == "" {
		return false
	}

	if len(masterToken) <= 18 {
		if subtle.ConstantTimeCompare([]byte(userToken), []byte(masterToken)) == 1 {
			return true
		}
	}

	mac := hmac.New(sha256.New, []byte(masterToken))
	mac.Write([]byte(userID))
	expected := hex.EncodeToString(mac.Sum(nil))

	return subtle.ConstantTimeCompare([]byte(userToken), []byte(expected)) == 1
}

func BearerAuth(token, defaultUserID string) fiber.Handler {
	token = strings.TrimSpace(token)
	defaultUserID = SanitizeUserID(defaultUserID)
	if defaultUserID == "" {
		defaultUserID = "local"
	}
	return func(c *fiber.Ctx) error {
		header := strings.TrimSpace(c.Get("Authorization"))
		const prefix = "Bearer "
		if token == "" || !strings.HasPrefix(header, prefix) {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "unauthorized"})
		}

		fullToken := strings.TrimSpace(strings.TrimPrefix(header, prefix))
		requestedUserID := SanitizeUserID(c.Get("X-Memory-User-ID"))
		if requestedUserID == "" {
			requestedUserID = defaultUserID
		}

		if strings.Contains(fullToken, ":") {
			parts := strings.SplitN(fullToken, ":", 2)
			secretPart := strings.TrimSpace(parts[0])
			userPart := SanitizeUserID(parts[1])
			if userPart == "" {
				userPart = requestedUserID
			}
			if userPart == "" {
				userPart = defaultUserID
			}
			if !VerifyUserToken(token, secretPart, userPart) {
				return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "unauthorized"})
			}
			requestedUserID = userPart
		} else if subtle.ConstantTimeCompare([]byte(fullToken), []byte(token)) != 1 {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "unauthorized"})
		}

		c.Locals(UserIDLocalKey, requestedUserID)
		return c.Next()
	}
}

type RateLimiter struct {
	mu        sync.Mutex
	limit     int
	window    time.Duration
	buckets   map[string][]time.Time
	stop      chan struct{}
	closeOnce sync.Once
}

func NewRateLimiter(limit int, window time.Duration) *RateLimiter {
	if limit <= 0 {
		limit = 120
	}
	if window <= 0 {
		window = time.Minute
	}
	rl := &RateLimiter{
		limit:   limit,
		window:  window,
		buckets: map[string][]time.Time{},
		stop:    make(chan struct{}),
	}
	go rl.janitor()
	return rl
}

func (r *RateLimiter) Close() {
	r.closeOnce.Do(func() {
		close(r.stop)
	})
}

func (r *RateLimiter) janitor() {
	ticker := time.NewTicker(r.window * 2)
	defer ticker.Stop()
	for {
		select {
		case <-r.stop:
			return
		case <-ticker.C:
			r.mu.Lock()
			cutoff := time.Now().Add(-r.window)
			for key, events := range r.buckets {
				filtered := events[:0]
				for _, eventTime := range events {
					if eventTime.After(cutoff) {
						filtered = append(filtered, eventTime)
					}
				}
				if len(filtered) == 0 {
					delete(r.buckets, key)
				} else {
					r.buckets[key] = filtered
				}
			}
			r.mu.Unlock()
		}
	}
}

func (r *RateLimiter) Middleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		userID, _ := c.Locals(UserIDLocalKey).(string)
		key := c.IP() + ":" + strings.TrimSpace(userID)
		now := time.Now()
		cutoff := now.Add(-r.window)

		r.mu.Lock()
		events := r.buckets[key]
		filtered := events[:0]
		for _, eventTime := range events {
			if eventTime.After(cutoff) {
				filtered = append(filtered, eventTime)
			}
		}
		if len(filtered) >= r.limit {
			r.buckets[key] = filtered
			r.mu.Unlock()
			return c.Status(fiber.StatusTooManyRequests).JSON(fiber.Map{"error": "rate limit exceeded"})
		}
		filtered = append(filtered, now)
		r.buckets[key] = filtered
		r.mu.Unlock()

		return c.Next()
	}
}

func SanitizeUserID(value string) string {
	value = strings.TrimSpace(value)
	if value == "" {
		return ""
	}
	var builder strings.Builder
	for _, ch := range value {
		switch {
		case ch >= 'a' && ch <= 'z':
			builder.WriteRune(ch)
		case ch >= 'A' && ch <= 'Z':
			builder.WriteRune(ch)
		case ch >= '0' && ch <= '9':
			builder.WriteRune(ch)
		case ch == '_' || ch == '-' || ch == '.':
			builder.WriteRune(ch)
		}
	}
	return builder.String()
}
