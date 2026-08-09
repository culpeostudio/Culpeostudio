// Command culpeosearch exposes the metasearch engine on the command line.
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/culpeohq/backend/internal/metasearch"
	"github.com/culpeohq/backend/internal/metasearch/engines"
)

var (
	gProxy  string
	gTime   int
	gVerify bool
)

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(1)
	}
	cmd := os.Args[1]
	args := os.Args[2:]

	switch cmd {
	case "text", "news", "images", "videos", "books":
		runSearch(cmd, args)
	case "extract":
		runExtract(args)
	case "engines":
		runEngines(args)
	case "version", "-v", "--version", "-version":
		fmt.Printf("culpeosearch %s\n", culpeosearchVersion())
	case "help", "-h", "--help":
		usage()
	default:
		fmt.Fprintf(os.Stderr, "unbekanntes Subkommando: %s\n\n", cmd)
		usage()
		os.Exit(2)
	}
}

func parseGlobals(fs *flag.FlagSet) {
	fs.StringVar(&gProxy, "proxy", "", "Proxy-URL (http/socks5/socks5h) oder 'tb' fuer Tor")
	fs.IntVar(&gTime, "timeout", 10, "HTTP-Timeout in Sekunden")
	fs.BoolVar(&gVerify, "verify", true, "TLS-Verifikation (false = InsecureSkipVerify)")
}

func splitArgs(fs *flag.FlagSet, args []string) (positional, flags []string) {
	for i := 0; i < len(args); i++ {
		arg := args[i]
		if arg == "--" {
			positional = append(positional, args[i+1:]...)
			return positional, flags
		}
		if len(arg) < 2 || !strings.HasPrefix(arg, "-") {
			positional = append(positional, arg)
			continue
		}
		flags = append(flags, arg)
		name := strings.TrimLeft(arg, "-")
		if strings.Contains(name, "=") {

			continue
		}
		f := fs.Lookup(name)
		if f == nil {

			continue
		}
		if bf, ok := f.Value.(interface{ IsBoolFlag() bool }); ok && bf.IsBoolFlag() {
			continue
		}
		if i+1 < len(args) {
			i++
			flags = append(flags, args[i])
		}
	}
	return positional, flags
}

func buildSearch() (*metasearch.HttpClient, *metasearch.Search) {
	client, err := metasearch.NewHttpClient(metasearch.ClientOptions{
		Proxy:   metasearch.ExpandProxyTBAlias(gProxy),
		Timeout: time.Duration(gTime) * time.Second,
		Verify:  gVerify,
	})
	if err != nil {
		log.Fatalf("HttpClient: %v", err)
	}
	cats := []string{"text", "images", "videos", "news", "books"}
	enginesByCat := make(map[string][]metasearch.Engine, len(cats))
	for _, c := range cats {
		enginesByCat[c] = engines.Build(c, "auto", client)
	}
	return client, metasearch.NewSearch(client, enginesByCat, metasearch.SearchOptions{})
}

func runSearch(category string, args []string) {
	fs := flag.NewFlagSet("culpeosearch "+category, flag.ExitOnError)
	parseGlobals(fs)
	var (
		maxResults int
		region     string
		safesearch string
		timelimit  string
		page       int
		backend    string
		asJSON     bool
	)
	fs.IntVar(&maxResults, "max", 10, "Maximale Trefferzahl")
	fs.StringVar(&region, "region", "us-en", "Region (z.B. us-en, de-de)")
	fs.StringVar(&safesearch, "safesearch", "moderate", "SafeSearch: on|moderate|off")
	fs.StringVar(&timelimit, "timelimit", "", "Zeitlimit: d|w|m|y")
	fs.IntVar(&page, "page", 1, "Seite (1-basiert)")
	fs.StringVar(&backend, "backend", "auto", "Backend-Liste (auto, all, oder kommasepariert)")
	fs.BoolVar(&asJSON, "json", false, "Treffer als JSON ausgeben")

	positional, flags := splitArgs(fs, args)
	if err := fs.Parse(flags); err != nil {
		log.Fatalf("Parse-Fehler: %v", err)
	}
	positional = append(positional, fs.Args()...)

	if len(positional) < 1 {
		log.Fatalf("Nutzung: culpeosearch %s QUERY [-max N] [-region R] [-backend list] [-json]", category)
	}
	query := strings.Join(positional, " ")

	_, search := buildSearch()
	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(gTime*2)*time.Second+5*time.Second)
	defer cancel()

	results, err := search.Run(ctx, category, metasearch.SearchParams{
		Query:      query,
		Region:     region,
		Safesearch: safesearch,
		Timelimit:  timelimit,
		Page:       page,
		Max:        maxResults,
		Backend:    backend,
	})
	if err != nil {
		log.Fatalf("Suche fehlgeschlagen: %v", err)
	}

	if asJSON {
		enc := json.NewEncoder(os.Stdout)
		enc.SetEscapeHTML(false)
		enc.SetIndent("", "  ")
		if err := enc.Encode(results); err != nil {
			log.Fatalf("JSON-Encode: %v", err)
		}
		return
	}
	printHuman(category, query, results)
}

func runExtract(args []string) {
	fs := flag.NewFlagSet("culpeosearch extract", flag.ExitOnError)
	parseGlobals(fs)
	var (
		format string
		asJSON bool
	)
	fs.StringVar(&format, "fmt", "text_markdown", "Format: text_markdown|text_rich|text_plain|text|content")
	fs.BoolVar(&asJSON, "json", true, "JSON-Ausgabe (immer an)")
	positional, flags := splitArgs(fs, args)
	if err := fs.Parse(flags); err != nil {
		log.Fatalf("Parse-Fehler: %v", err)
	}
	positional = append(positional, fs.Args()...)
	if len(positional) < 1 {
		log.Fatalf("Nutzung: culpeosearch extract URL [-fmt text_markdown]")
	}
	target := positional[0]
	client, _ := buildSearch()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	resp, err := client.GetGuarded(ctx, target, nil)
	if err != nil {
		log.Fatalf("fetch: %v", err)
	}
	if resp.StatusCode != 200 {
		log.Fatalf("HTTP %d fuer %s", resp.StatusCode, target)
	}
	var content any
	switch format {
	case "text":
		content = resp.Text
	case "content":
		content = resp.Content
	case "text_plain":
		content = metasearch.NormalizeText(resp.Text)
	case "text_rich", "text_markdown":
		content = metasearch.HTMLToMarkdown(resp.Text)
	default:
		log.Fatalf("nicht unterstuetztes Format: %s", format)
	}
	_ = asJSON
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	if err := enc.Encode(map[string]any{
		"url":     target,
		"content": content,
		"format":  format,
	}); err != nil {
		log.Fatalf("JSON-Encode: %v", err)
	}
}

func runEngines(args []string) {
	fs := flag.NewFlagSet("culpeosearch engines", flag.ExitOnError)
	if err := fs.Parse(args); err != nil {
		log.Fatalf("Parse-Fehler: %v", err)
	}
	cats := []string{"text", "images", "videos", "news", "books"}
	out := map[string][]string{}
	for _, c := range cats {
		out[c] = engines.Available(c, "auto")
	}
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	if err := enc.Encode(out); err != nil {
		log.Fatalf("JSON-Encode: %v", err)
	}
}

func printHuman(category, query string, results []metasearch.Result) {
	fmt.Printf("CulpeoSearch '%s' (%s) – %d Treffer\n\n", query, category, len(results))
	for i, r := range results {
		fmt.Printf("%d.\t==================================================\n", i+1)
		if r.Title != "" {
			fmt.Printf("Title: %s\n", r.Title)
		}
		if r.Href != "" {
			fmt.Printf("URL:   %s\n", r.Href)
		}
		if r.Image != "" {
			fmt.Printf("Image: %s\n", r.Image)
		}
		if r.Body != "" {
			fmt.Printf("Body:  %s\n", wrapWords(r.Body, 80))
		}
		if r.Description != "" {
			fmt.Printf("Desc:  %s\n", wrapWords(r.Description, 80))
		}
		if r.Date != "" {
			fmt.Printf("Date:  %s\n", r.Date)
		}
		fmt.Println()
	}
}

func wrapWords(s string, width int) string {
	if width <= 0 || len(s) <= width {
		return s
	}
	var b strings.Builder
	for _, line := range strings.Split(s, "\n") {
		words := strings.Fields(line)
		if len(words) == 0 {
			b.WriteString("\n")
			continue
		}
		lineLen := 0
		for i, w := range words {
			if i == 0 {
				b.WriteString(w)
				lineLen = len(w)
				continue
			}
			if lineLen+1+len(w) > width {
				b.WriteString("\n")
				b.WriteString(w)
				lineLen = len(w)
			} else {
				b.WriteString(" ")
				b.WriteString(w)
				lineLen += 1 + len(w)
			}
		}
		b.WriteString("\n")
	}
	return strings.TrimRight(b.String(), "\n")
}

func usage() {
	fmt.Fprintln(os.Stderr, `culpeosearch - Culpeo Studio Metasuch-CLI

Nutzung:
  culpeosearch [global-flags] <command> [command-flags] [args]

Commands:
  text QUERY        Web-Textsuche
  news QUERY        News-Suche
  images QUERY      Bildersuche
  videos QUERY      Videosuche
  books QUERY       Buchersuche
  extract URL       URL aufrufen und Inhalt extrahieren
  engines           Verfuegbare Backends auflisten
  version           Version ausgeben

Globale Flags (vor dem Kommando):
  -proxy URL        Proxy (http://|https://|socks5://|socks5h:// oder 'tb')
  -timeout N        HTTP-Timeout in Sekunden (Default 10)
  -verify           TLS verifizieren (default true; false = InsecureSkipVerify)

Such-Flags (nach dem Kommando):
  -max N            Maximale Treffer (default 10)
  -region R         Region wie 'us-en','de-de','uk-en'
  -safesearch S     on|moderate|off (default moderate)
  -timelimit T      d|w|m|y
  -page N           Seite (default 1)
  -backend LIST     auto|all|oder kommaseparierte Engine-Liste
  -json             Treffer als JSON ausgeben

Beispiele:
  culpeosearch text "rust async tokio" -max 5 -json
  culpeosearch news "tls fingerprint" -region uk-en
  culpeosearch extract https://example.com -fmt text_plain
  culpeosearch engines`)
}

func culpeosearchVersion() string {
	return "0.1.0-mvp"
}
