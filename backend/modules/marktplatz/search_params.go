package marktplatz

import (
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/modules/marktplatz/types"
)

// maxSearchWindow begrenzt, wie viele Modelle pro Suche maximal beim Provider
// angefordert werden – verhindert, dass eine kombinierte Filter+Paging-
// Anfrage den Katalog komplett laedt. Wurde frueher inline in handleSearch
// gefuehrt; ist jetzt zur Kapselung der Such-Helper hier.
const maxSearchWindow = 1000

// searchParams fasst alle pro Suchanfrage gueltigen Filter und
// paging-Parameter zusammen. parseSearchParams erzeugt sie aus einem
// fiber.Ctx; danach sind sie reine Daten, die in computeSearchLimit / den
// Provider-Suchen / prepareMarketplaceResults verwendet werden. So laesst
// sich die Logik ohne fiber.Ctx unit-testen.
type searchParams struct {
	Provider               string
	Query                  string
	Format                 string
	Quantization           string
	NormalizedQuantization string
	Category               string
	SortMode               string
	Page                   int
	PageSize               int
	GPUOnly                bool
	LocalOnly              bool
}

// fiberErr traegt HTTP-Status + Klartext-Nachricht. So kann parseSearchParams
// Validierungsfehler als error an den Handler zurueckgeben, der sie direkt
// via c.Status(...) weiterreichen kann – ohne dass der Handler
// string-Matches machen muss.
type fiberErr struct {
	status int
	msg    string
}

func (e *fiberErr) Error() string { return e.msg }

// parseSearchParams liest und validiert alle Query-Parameter einer /search-
// Anfrage. Bei jedem Validierungsfehler kehrt sie sofort mit einem *fiberErr
// zurueck – die Statuscodes sind stabil fuer Test-Cases und Clients.
func parseSearchParams(c *fiber.Ctx) (searchParams, error) {
	provider := types.NormalizeProvider(c.Query("provider", types.ProviderAll))
	if !types.IsSupportedProvider(provider) {
		return searchParams{}, &fiberErr{status: 400, msg: "ungueltiger provider"}
	}

	page := 1
	if raw := strings.TrimSpace(c.Query("page", "")); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil || parsed <= 0 {
			return searchParams{}, &fiberErr{status: 400, msg: "ungueltige page"}
		}
		page = parsed
	}

	pageSize := 20
	if raw := strings.TrimSpace(c.Query("limit", "")); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil || parsed <= 0 {
			return searchParams{}, &fiberErr{status: 400, msg: "ungueltiges limit"}
		}
		if parsed > 1000 {
			parsed = 1000
		}
		pageSize = parsed
	}

	query := strings.TrimSpace(c.Query("q", ""))
	format := strings.TrimSpace(c.Query("format", ""))
	quantization := strings.TrimSpace(c.Query("quantization", ""))
	normalizedQuantization := normalizeQuantization(quantization)
	category := normalizeCategory(c.Query("category", ""))
	sortMode := strings.TrimSpace(c.Query("sort", "popularity"))

	gpuOnly := false
	if raw := strings.TrimSpace(c.Query("gpu_fit", "")); raw != "" {
		parsed, err := strconv.ParseBool(raw)
		if err != nil {
			return searchParams{}, &fiberErr{status: 400, msg: "ungueltiger gpu_fit wert"}
		}
		gpuOnly = parsed
	}

	localOnly := false
	if raw := strings.TrimSpace(c.Query("local_only", "")); raw != "" {
		parsed, err := strconv.ParseBool(raw)
		if err != nil {
			return searchParams{}, &fiberErr{status: 400, msg: "ungueltiger local_only wert"}
		}
		localOnly = parsed
	}

	// local_only/gpu_fit/quantization sind HF-spezifische Filter (lokale
	// gguf-Downloads, VRAM-Check). Cloud-Provider liefern garantiert leere
	// Ergebnisse, weil der Backend alle nicht-HF-Modelle herausfiltert.
	// Stille leere Listen sind fuer Clients unauffaellig – wir lehnen hier
	// frueh mit 400 ab, damit der Aufrufer den Missbrauch bemerkt. ProviderAll
	// bleibt erlaubt (Backend schaltet verdeckt auf HF um).
	if (localOnly || gpuOnly || normalizedQuantization != "") &&
		provider != types.ProviderAll && provider != types.ProviderHuggingFace {
		return searchParams{}, &fiberErr{
			status: 400,
			msg:    "local_only, gpu_fit und quantization sind nur fuer HuggingFace-Modelle verfuegbar",
		}
	}

	return searchParams{
		Provider:               provider,
		Query:                  query,
		Format:                 format,
		Quantization:           quantization,
		NormalizedQuantization: normalizedQuantization,
		Category:               category,
		SortMode:               sortMode,
		Page:                   page,
		PageSize:               pageSize,
		GPUOnly:                gpuOnly,
		LocalOnly:              localOnly,
	}, nil
}

// resolvedProvider liefert den tatsaechlich abzufragenden Provider. Bei
// "all" kollabiert die Suche auf HuggingFace, sobald lokale Filter aktiv
// sind – der Vertrag der /search-API ist: "all + lokaler Filter == nur
// HF-Treffer, da nur HF lokal ladbar ist".
func (p searchParams) resolvedProvider() string {
	if p.Provider == types.ProviderAll && (p.LocalOnly || p.GPUOnly || p.NormalizedQuantization != "") {
		return types.ProviderHuggingFace
	}
	return p.Provider
}

// isPostFilteredSearch gibt an, ob Filter erst nach dem Providerabruf auf
// angereicherte Metadaten angewandt werden. Dann reichen die ersten N
// Rohmodelle nicht: Kategorie-Treffer können erst viel später vorkommen.
func (p searchParams) isPostFilteredSearch() bool {
	if p.Category != "" || p.Format != "" {
		return true
	}
	return p.resolvedProvider() == types.ProviderHuggingFace &&
		(p.LocalOnly || p.GPUOnly || p.NormalizedQuantization != "")
}

// computeSearchLimit bestimmt das initiale Suchfenster (Limit), das beim
// Provider angefragt wird. Fuer lokale Filter wird das Fenster bis zu 8x
// vergroessert, damit nach Enrichment+Filter genug Treffer fuer die
// angefragte Seite uebrig bleiben.
func computeSearchLimit(p searchParams) int {
	searchLimit := p.PageSize * p.Page
	if searchLimit > maxSearchWindow {
		searchLimit = maxSearchWindow
	}
	if p.isPostFilteredSearch() {
		expandedSearchLimit := p.PageSize * p.Page * 8
		if expandedSearchLimit < 160 {
			expandedSearchLimit = 160
		}
		if expandedSearchLimit > maxSearchWindow {
			expandedSearchLimit = maxSearchWindow
		}
		if searchLimit < expandedSearchLimit {
			searchLimit = expandedSearchLimit
		}
	}
	return searchLimit
}

// expandSearchLimit verdoppelt das Suchfenster, wenn die bisherige
// Provider-Antwort nicht genug gefilterte Treffer geliefert hat. Gibt
// (neuerLimit, ok) zurueck; ok=false bedeutet, dass kein weiteres Wachstum
// moeglich ist (maxSearchWindow erreicht oder Verdopplung wuerde nichts
// bringen). So bleibt die Expansionslogik in handleSearch als einfaches
// `for { ... if !ok { break } ... }`.
func expandSearchLimit(current int) (int, bool) {
	if current >= maxSearchWindow {
		return current, false
	}
	next := current * 2
	if next > maxSearchWindow {
		next = maxSearchWindow
	}
	if next <= current {
		return current, false
	}
	return next, true
}
