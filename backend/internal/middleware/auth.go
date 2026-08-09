// Package middleware provides the HTTP authentication filter shared by the API
// modules.
package middleware

import (
	"log"
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

func AuthMiddleware(secret string, activeUser ...func(string) bool) fiber.Handler {
	var isActiveUser func(string) bool
	if len(activeUser) > 0 {
		isActiveUser = activeUser[0]
	}
	return func(c *fiber.Ctx) error {
		if isPublicAuthRoute(c.Method(), c.Path()) {
			return c.Next()
		}

		memoryRoute := isMemoryRoute(c.Path())

		auth := c.Get("Authorization")
		if auth == "" || !strings.HasPrefix(auth, "Bearer ") {
			if memoryRoute {
				return c.Next()
			}
			log.Printf("[AUTH] 401 %s %s (missing bearer token)", c.Method(), c.Path())
			return c.Status(401).JSON(fiber.Map{"error": "Nicht autorisiert"})
		}

		tokenStr := strings.TrimPrefix(auth, "Bearer ")
		token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
			return []byte(secret), nil
		})

		if err != nil || !token.Valid {
			if memoryRoute {
				return c.Next()
			}
			log.Printf("[AUTH] 401 %s %s (invalid token)", c.Method(), c.Path())
			return c.Status(401).JSON(fiber.Map{"error": "Ungueltiger Token"})
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			if memoryRoute {
				return c.Next()
			}
			log.Printf("[AUTH] 401 %s %s (invalid claims)", c.Method(), c.Path())
			return c.Status(401).JSON(fiber.Map{"error": "Ungueltige Claims"})
		}
		if isActiveUser != nil {
			username, ok := claims["username"].(string)
			if !ok || !isActiveUser(username) {
				if memoryRoute {
					return c.Next()
				}
				log.Printf("[AUTH] 401 %s %s (account no longer exists)", c.Method(), c.Path())
				return c.Status(401).JSON(fiber.Map{"error": "Account existiert nicht mehr"})
			}
		}

		c.Locals("user_id", claims["user_id"])
		c.Locals("username", claims["username"])
		return c.Next()
	}
}

func isMemoryRoute(path string) bool {
	return path == "/api/memory" || strings.HasPrefix(path, "/api/memory/")
}

// isPublicAuthRoute lists the remaining HTTP routes that carry no session
// token. The login routes that used to be here are gone: sign-in, first-run
// setup, account creation and password reset moved to LoginService, and their
// gRPC counterparts are listed in cmd/server/public_methods.go instead.
func isPublicAuthRoute(method, path string) bool {
	switch method + " " + path {
	case "GET /health",

		// The memory viewer is an HTML page a browser renders, and its event
		// stream is read by an EventSource that cannot set a header.
		"GET /memory/view",
		"GET /memory/events":
		return true
	default:
		return false
	}
}
