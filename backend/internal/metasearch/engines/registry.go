package engines

import (
	"sort"
	"strings"

	"github.com/fillyengine/backend/internal/metasearch"
)

type factory func(client *metasearch.HttpClient) metasearch.Engine

type registryEntry struct {
	name    string
	factory factory
}

var registry = []registryEntry{
	{"wikipedia", newWikipedia},
	{"bing", newBing},
	{"brave", newBrave},
	{"google", newGoogle},
	{"duckduckgo", newDuckduckgo},
}

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
