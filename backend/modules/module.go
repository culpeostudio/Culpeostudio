// Package modules defines what a backend module is and how it registers its
// routes.
package modules

import "github.com/gofiber/fiber/v2"

type Module interface {
	Name() string

	RegisterRoutes(router fiber.Router)

	Initialize() error

	Shutdown() error
}

type AppRouteRegistrar interface {
	RegisterAppRoutes(router fiber.Router)
}
