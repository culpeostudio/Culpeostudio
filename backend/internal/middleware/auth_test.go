package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

func TestHealthRouteIsPublicButEngineManagementRemainsProtected(t *testing.T) {
	app := fiber.New()
	app.Use(AuthMiddleware("test-secret"))
	app.Get("/health", func(c *fiber.Ctx) error { return c.SendStatus(http.StatusOK) })
	app.Get("/api/engine/models", func(c *fiber.Ctx) error { return c.SendStatus(http.StatusOK) })

	response, err := app.Test(httptest.NewRequest(http.MethodGet, "/health", nil))
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusOK {
		t.Fatalf("health status = %d, want %d", response.StatusCode, http.StatusOK)
	}

	response, err = app.Test(httptest.NewRequest(http.MethodGet, "/api/engine/models", nil))
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusUnauthorized {
		t.Fatalf("engine management status = %d, want %d", response.StatusCode, http.StatusUnauthorized)
	}
}

func TestRemovedAccountTokenIsRejected(t *testing.T) {
	app := fiber.New()
	app.Use(AuthMiddleware("test-secret", func(username string) bool {
		return username == "active-user"
	}))
	app.Get("/api/engine/models", func(c *fiber.Ctx) error { return c.SendStatus(http.StatusOK) })

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id":  "removed-user",
		"username": "removed-user",
	})
	tokenText, err := token.SignedString([]byte("test-secret"))
	if err != nil {
		t.Fatal(err)
	}
	request := httptest.NewRequest(http.MethodGet, "/api/engine/models", nil)
	request.Header.Set("Authorization", "Bearer "+tokenText)
	response, err := app.Test(request)
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusUnauthorized {
		t.Fatalf("removed-account token status = %d, want %d", response.StatusCode, http.StatusUnauthorized)
	}
}
