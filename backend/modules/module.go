package modules

import "github.com/gofiber/fiber/v2"

// Module ist das Interface das jedes Backend-Modul implementiert.
// Jedes Modul registriert seine eigenen Routen unabhängig.
type Module interface {
	// Name gibt den Modul-Namen zurück
	Name() string

	// RegisterRoutes registriert alle HTTP-Routen des Moduls
	RegisterRoutes(router fiber.Router)

	// Initialize wird beim Server-Start aufgerufen
	Initialize() error

	// Shutdown wird beim Server-Stopp aufgerufen
	Shutdown() error
}

// AppRouteRegistrar registriert Routen direkt auf der App-Ebene
// (ausserhalb der /api-Gruppe), z.B. HTML-Seiten oder SSE-Endpunkte.
type AppRouteRegistrar interface {
	RegisterAppRoutes(router fiber.Router)
}
