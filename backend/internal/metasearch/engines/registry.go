// Package engines enthaelt die einzelnen Such-Backends, die von
// PhiloSearch verwendet werden. Jeder Engine implementiert das
// metasearch.Engine-Interface; XPath-basierte Backends nutzen
// metasearch.XPathEngine als gemeinsame Implementierung.
//
// Die Registry ersetzt das automatische Discovery aus dem
// Python-Projekt (engines/__init__.py) durch eine explizite Liste.
// Das vermeidet Reflection-Magic und macht die Engine-Menge beim
// Lesen des Codes sofort sichtbar.
package engines

import (
	"sort"
	"strings"

	"github.com/fillyengine/backend/internal/metasearch"
)

// factory ist eine Konstruktor-Funktion, die einen Engine mit dem
// gegebenen HttpClient erzeugt.
type factory func(client *metasearch.HttpClient) metasearch.Engine

// registryEntry verknuepft Engine-Namen mit ihrer Konstruktor-Funktion.
type registryEntry struct {
	name    string
	factory factory
}

// registry enthaelt alle verfuegbaren Engines. Die Reihenfolge spielt
// fuer die Auto-Auswahl keine Rolle (wird gemischt).
var registry = []registryEntry{
	{"wikipedia", newWikipedia},
	{"bing", newBing},
	{"brave", newBrave},
	{"google", newGoogle},
	{"duckduckgo", newDuckduckgo},
	// Neue Engines einfach hier anhaengen.
}

// Available liefert die Namen aller verfuegbaren Engines in der
// Kategorie, optional gefiltert nach dem Backend-Parameter.
//
// backend ist ein Komma-string. Werte:
//
//	"auto" oder "all"  -> alle Engines der Kategorie
//	eine Liste         -> nur die genannten Engines (Reihenfolge egal)
func Available(category, backend string) []string {
	all := listByCategory(category)
	if backend == "" || backend == "auto" || backend == "all" {
		return all
	}
	wanted := strings.Split(backend, ",")
	wantedSet := make(map[string]struct{}, len(wanted))
	for i := range wanted {
		wantedSet[strings.TrimSpace(wanted[i])] = struct{}{}
	}
	var out []string
	for _, n := range all {
		if _, ok := wantedSet[n]; ok {
			out = append(out, n)
		}
	}
	return out
}

// listByCategory liefert die Namen aller Engines in der Kategorie
// (ohne deaktivierte).
func listByCategory(category string) []string {
	client, _ := metasearch.NewHttpClient(metasearch.ClientOptions{})
	var out []string
	for _, entry := range registry {
		eng := entry.factory(client)
		info := eng.Info()
		if info.Disabled {
			continue
		}
		if !strings.EqualFold(info.Category, category) {
			continue
		}
		out = append(out, info.Name)
	}
	sort.Strings(out)
	return out
}

// Build erzeugt eine Liste von Engine-Instanzen fuer die angegebene
// Kategorie, gefiltert nach backend. Engines, die nicht verfuegbar sind,
// werden still verworfen; die caller kann invalid engines nicht
// unterscheiden.
func Build(category, backend string, client *metasearch.HttpClient) []metasearch.Engine {
	wanted := Available(category, backend)
	factories := make(map[string]factory, len(registry))
	for _, entry := range registry {
		factories[entry.name] = entry.factory
	}
	out := make([]metasearch.Engine, 0, len(wanted))
	for _, name := range wanted {
		f, ok := factories[name]
		if !ok {
			continue
		}
		eng := f(client)
		if eng.Info().Disabled {
			continue
		}
		out = append(out, eng)
	}
	return out
}
