// Command node runs a standalone Culpeo Node.  It is intentionally not a
// Studio server in a different mode: only NodeAgent, Engine, and Marketplace
// are assembled here.
package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"github.com/culpeohq/backend/internal/nodeapp"
)

// version is replaced by the release build. A development build intentionally
// keeps the clear "dev" label rather than pretending to be a published one.
var version = "dev"

func main() {
	if len(os.Args) > 1 {
		switch strings.TrimSpace(os.Args[1]) {
		case "help", "--help", "-h":
			fmt.Fprintln(os.Stdout, "Culpeo Node\n\n  culpeo-node              Node starten\n  culpeo-node pairing-link Verbindungslink fuer Studio ausgeben")
			return
		case "pairing-link":
			// This command still needs the configured public endpoint below.
		default:
			log.Fatalf("[node] Unbekannter Befehl %q. Erlaubt: pairing-link", os.Args[1])
		}
	}

	config, err := nodeapp.FromEnv(func(name string) string {
		value := os.Getenv(name)
		if name == "CULPEO_NODE_VERSION" && value == "" {
			return version
		}
		return value
	})
	if err != nil {
		log.Fatalf("[node] Konfiguration: %v", err)
	}

	if len(os.Args) > 1 {
		link, linkErr := nodeapp.PairingLink(config)
		if linkErr != nil {
			log.Fatalf("[node] Verbindungslink: %v", linkErr)
		}
		// This is an explicit secret-revealing command. The running service
		// deliberately never writes the link into its logs.
		fmt.Println(link)
		return
	}

	runtime, err := nodeapp.New(config)
	if err != nil {
		log.Fatalf("[node] Start vorbereiten: %v", err)
	}
	defer func() {
		if closeErr := runtime.Close(); closeErr != nil {
			log.Printf("[node] Beenden: %v", closeErr)
		}
	}()

	log.Printf("[node] bereit: Engine und Marketplace laufen lokal auf diesem Rechner.")
	log.Printf("[node] Studio verbinden: `culpeo-node pairing-link` ausfuehren und den einen Link in Studio einfuegen.")
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	if err := runtime.Run(ctx); err != nil {
		log.Fatalf("[node] Steuerungsebene: %v", err)
	}
}
