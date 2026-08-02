package security

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"io"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gofiber/fiber/v2"
)

func TestBearerAuthRejectsMissingToken(t *testing.T) {
	app := fiber.New()
	app.Use(BearerAuth("secret", "local"))
	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString("ok")
	})

	response, err := app.Test(httptest.NewRequest("GET", "/", nil))
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if response.StatusCode != fiber.StatusUnauthorized {
		t.Fatalf("expected unauthorized, got %d", response.StatusCode)
	}
}

func TestBearerAuthSetsUserIDContext(t *testing.T) {
	app := fiber.New()
	app.Use(BearerAuth("secret", "local"))
	app.Get("/", func(c *fiber.Ctx) error {
		userID, _ := c.Locals(UserIDLocalKey).(string)
		return c.SendString(userID)
	})

	request := httptest.NewRequest("GET", "/", nil)
	request.Header.Set("Authorization", "Bearer secret:alice")
	response, err := app.Test(request)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	body, _ := io.ReadAll(response.Body)
	if string(body) != "alice" {
		t.Fatalf("expected alice user context, got %q", string(body))
	}
}

func TestBearerAuthUsesUserIDHeader(t *testing.T) {
	app := fiber.New()
	app.Use(BearerAuth("secret", "local"))
	app.Get("/", func(c *fiber.Ctx) error {
		userID, _ := c.Locals(UserIDLocalKey).(string)
		return c.SendString(userID)
	})

	request := httptest.NewRequest("GET", "/", nil)
	request.Header.Set("Authorization", "Bearer secret")
	request.Header.Set("X-Memory-User-ID", "alice")
	response, err := app.Test(request)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	body, _ := io.ReadAll(response.Body)
	if string(body) != "alice" {
		t.Fatalf("expected alice user context from header, got %q", string(body))
	}
}

func TestRateLimiterBlocksAfterLimit(t *testing.T) {
	app := fiber.New()
	app.Use(func(c *fiber.Ctx) error {
		c.Locals(UserIDLocalKey, "local")
		return c.Next()
	})
	app.Use(NewRateLimiter(1, time.Minute).Middleware())
	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString("ok")
	})

	first, err := app.Test(httptest.NewRequest("GET", "/", nil))
	if err != nil {
		t.Fatalf("first request failed: %v", err)
	}
	if first.StatusCode != fiber.StatusOK {
		t.Fatalf("expected first request to pass, got %d", first.StatusCode)
	}
	second, err := app.Test(httptest.NewRequest("GET", "/", nil))
	if err != nil {
		t.Fatalf("second request failed: %v", err)
	}
	if second.StatusCode != fiber.StatusTooManyRequests {
		t.Fatalf("expected rate limit, got %d", second.StatusCode)
	}
}

func TestVerifyUserTokenHMAC(t *testing.T) {
	masterShort := "secret-key"
	masterLong := "a-very-long-master-api-token-that-is-secure"
	userID := "bob"

	if !VerifyUserToken(masterShort, "secret-key", userID) {
		t.Errorf("expected short key plaintext match to succeed")
	}
	if VerifyUserToken(masterShort, "wrong-key", userID) {
		t.Errorf("expected short key wrong plaintext to fail")
	}

	if VerifyUserToken(masterLong, masterLong, userID) {
		t.Errorf("expected long key plaintext to be rejected")
	}

	mac := hmac.New(sha256.New, []byte(masterLong))
	mac.Write([]byte(userID))
	correctHMAC := hex.EncodeToString(mac.Sum(nil))

	if !VerifyUserToken(masterLong, correctHMAC, userID) {
		t.Errorf("expected correct HMAC token to succeed")
	}
	if VerifyUserToken(masterLong, "some-random-hmac-token", userID) {
		t.Errorf("expected wrong HMAC token to fail")
	}
}

func TestBearerAuthEnforcesHMAC(t *testing.T) {
	masterLong := "a-very-long-master-api-token-that-is-secure"
	app := fiber.New()
	app.Use(BearerAuth(masterLong, "local"))
	app.Get("/", func(c *fiber.Ctx) error {
		userID, _ := c.Locals(UserIDLocalKey).(string)
		return c.SendString(userID)
	})

	req1 := httptest.NewRequest("GET", "/", nil)
	req1.Header.Set("Authorization", "Bearer "+masterLong+":bob")
	resp1, err := app.Test(req1)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp1.StatusCode != fiber.StatusUnauthorized {
		t.Errorf("expected plaintext token with long key to be rejected, got %d", resp1.StatusCode)
	}

	mac := hmac.New(sha256.New, []byte(masterLong))
	mac.Write([]byte("bob"))
	correctHMAC := hex.EncodeToString(mac.Sum(nil))

	req2 := httptest.NewRequest("GET", "/", nil)
	req2.Header.Set("Authorization", "Bearer "+correctHMAC+":bob")
	resp2, err := app.Test(req2)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp2.StatusCode != fiber.StatusOK {
		t.Errorf("expected HMAC token to be accepted, got %d", resp2.StatusCode)
	}
}

func TestRateLimiterJanitorPruning(t *testing.T) {
	rl := NewRateLimiter(5, 10*time.Millisecond)
	defer rl.Close()

	app := fiber.New()
	app.Use(func(c *fiber.Ctx) error {
		c.Locals(UserIDLocalKey, "local")
		return c.Next()
	})
	app.Use(rl.Middleware())
	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString("ok")
	})

	req := httptest.NewRequest("GET", "/", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("request failed: %v", err)
	}
	if resp.StatusCode != fiber.StatusOK {
		t.Fatalf("expected status 200, got %d", resp.StatusCode)
	}

	rl.mu.Lock()
	var foundKey string
	for k := range rl.buckets {
		foundKey = k
		break
	}
	rl.mu.Unlock()

	if foundKey == "" {
		t.Fatalf("expected bucket to be populated, found none")
	}

	time.Sleep(50 * time.Millisecond)

	rl.mu.Lock()
	_, exists := rl.buckets[foundKey]
	rl.mu.Unlock()

	if exists {
		t.Errorf("expected bucket key %s to be pruned, but it still exists", foundKey)
	}
}
