package marktplatz

import (
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/modules/marktplatz/types"
)

func TestParseSearchParams_Success(t *testing.T) {
	cases := []struct {
		name  string
		query string
		want  searchParams
	}{
		{
			name:  "defaults",
			query: "",
			want: searchParams{
				Provider: types.ProviderAll,
				SortMode: "popularity",
				Page:     1,
				PageSize: 20,
			},
		},
		{
			name:  "provider openrouter",
			query: "provider=openrouter",
			want: searchParams{
				Provider: types.ProviderOpenRouter,
				SortMode: "popularity",
				Page:     1,
				PageSize: 20,
			},
		},
		{
			name:  "page+limit",
			query: "page=3&limit=50",
			want: searchParams{
				Provider: types.ProviderAll,
				SortMode: "popularity",
				Page:     3,
				PageSize: 50,
			},
		},
		{
			name:  "limit cap at 1000",
			query: "limit=5000",
			want: searchParams{
				Provider: types.ProviderAll,
				SortMode: "popularity",
				Page:     1,
				PageSize: 1000,
			},
		},
		{
			name:  "hf local filters",
			query: "provider=huggingface&local_only=true&gpu_fit=true&quantization=Q4_K_M&category=chat&sort=intelligence&q=llama&format=gguf",
			want: searchParams{
				Provider:               types.ProviderHuggingFace,
				Query:                  "llama",
				Format:                 "gguf",
				Quantization:           "Q4_K_M",
				NormalizedQuantization: "q4_k_m",
				Category:               "chat",
				SortMode:               "intelligence",
				Page:                   1,
				PageSize:               20,
				GPUOnly:                true,
				LocalOnly:              true,
			},
		},
		{
			name:  "all with local_only collapses to hf (still valid)",
			query: "provider=all&local_only=true",
			want: searchParams{
				Provider:  types.ProviderAll,
				SortMode:  "popularity",
				Page:      1,
				PageSize:  20,
				LocalOnly: true,
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			app := fiber.New()
			req := httptest.NewRequest("GET", "/search?"+tc.query, nil)

			var got searchParams
			var gotErr error
			app.Get("/search", func(c *fiber.Ctx) error {
				got, gotErr = parseSearchParams(c)
				return c.SendStatus(200)
			})
			_, _ = app.Test(req, 1000)
			if gotErr != nil {
				t.Fatalf("unexpected error: %v", gotErr)
			}
			if got.Provider != tc.want.Provider {
				t.Errorf("Provider: got %q, want %q", got.Provider, tc.want.Provider)
			}
			if got.Query != tc.want.Query {
				t.Errorf("Query: got %q, want %q", got.Query, tc.want.Query)
			}
			if got.Format != tc.want.Format {
				t.Errorf("Format: got %q, want %q", got.Format, tc.want.Format)
			}
			if got.Quantization != tc.want.Quantization {
				t.Errorf("Quantization: got %q, want %q", got.Quantization, tc.want.Quantization)
			}
			if got.NormalizedQuantization != tc.want.NormalizedQuantization {
				t.Errorf("NormalizedQuantization: got %q, want %q",
					got.NormalizedQuantization, tc.want.NormalizedQuantization)
			}
			if got.Category != tc.want.Category {
				t.Errorf("Category: got %q, want %q", got.Category, tc.want.Category)
			}
			if got.SortMode != tc.want.SortMode {
				t.Errorf("SortMode: got %q, want %q", got.SortMode, tc.want.SortMode)
			}
			if got.Page != tc.want.Page {
				t.Errorf("Page: got %d, want %d", got.Page, tc.want.Page)
			}
			if got.PageSize != tc.want.PageSize {
				t.Errorf("PageSize: got %d, want %d", got.PageSize, tc.want.PageSize)
			}
			if got.GPUOnly != tc.want.GPUOnly {
				t.Errorf("GPUOnly: got %v, want %v", got.GPUOnly, tc.want.GPUOnly)
			}
			if got.LocalOnly != tc.want.LocalOnly {
				t.Errorf("LocalOnly: got %v, want %v", got.LocalOnly, tc.want.LocalOnly)
			}
		})
	}
}

func TestParseSearchParams_Errors(t *testing.T) {
	cases := []struct {
		name        string
		query       string
		wantStatus  int
		wantMsgPart string
	}{
		{"invalid provider", "provider=evilcorp", 400, "ungueltiger provider"},
		{"page zero", "page=0", 400, "ungueltige page"},
		{"page non-numeric", "page=abc", 400, "ungueltige page"},
		{"limit zero", "limit=0", 400, "ungueltiges limit"},
		{"limit non-numeric", "limit=foo", 400, "ungueltiges limit"},
		{"gpu_fit non-bool", "gpu_fit=maybe", 400, "gpu_fit"},
		{"local_only non-bool", "local_only=ja", 400, "local_only"},
		{
			"cloud provider with local_only",
			"provider=openrouter&local_only=true",
			400,
			"nur fuer HuggingFace",
		},
		{
			"cloud provider with gpu_fit",
			"provider=featherless&gpu_fit=true",
			400,
			"nur fuer HuggingFace",
		},
		{
			"cloud provider with quantization",
			"provider=openrouter&quantization=Q4_K_M",
			400,
			"nur fuer HuggingFace",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			app := fiber.New()
			req := httptest.NewRequest("GET", "/search?"+tc.query, nil)
			var gotErr error
			app.Get("/search", func(c *fiber.Ctx) error {
				_, gotErr = parseSearchParams(c)
				if gotErr != nil {
					return c.Status(500).SendString(gotErr.Error())
				}
				return c.SendStatus(200)
			})
			_, _ = app.Test(req, 1000)
			if gotErr == nil {
				t.Fatalf("expected error for %q, got nil", tc.query)
			}
			fe, ok := gotErr.(*fiberErr)
			if !ok {
				t.Fatalf("expected *fiberErr, got %T (%v)", gotErr, gotErr)
			}
			if fe.status != tc.wantStatus {
				t.Fatalf("status: got %d, want %d", fe.status, tc.wantStatus)
			}
			if !strings.Contains(strings.ToLower(fe.msg), strings.ToLower(tc.wantMsgPart)) {
				t.Fatalf("msg %q does not contain %q", fe.msg, tc.wantMsgPart)
			}
		})
	}
}

func TestComputeSearchLimit(t *testing.T) {
	cases := []struct {
		name string
		p    searchParams
		want int
	}{
		{"plain page1 limit20", searchParams{Page: 1, PageSize: 20}, 20},
		{"plain page5 limit24", searchParams{Page: 5, PageSize: 24}, 120},
		{"cap at maxSearchWindow", searchParams{Page: 100, PageSize: 20}, maxSearchWindow},
		{
			"local filter expands 8x",
			searchParams{Page: 1, PageSize: 24, LocalOnly: true, Provider: types.ProviderHuggingFace},
			192,
		},
		{
			"local filter min 160",
			searchParams{Page: 1, PageSize: 10, LocalOnly: true, Provider: types.ProviderHuggingFace},
			160,
		},
		{
			"local filter capped at max",
			searchParams{Page: 100, PageSize: 20, LocalOnly: true, Provider: types.ProviderHuggingFace},
			maxSearchWindow,
		},
		{
			"all+localOnly collapses to hf expansion",
			searchParams{Page: 2, PageSize: 20, LocalOnly: true, Provider: types.ProviderAll},
			320,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := computeSearchLimit(tc.p)
			if got != tc.want {
				t.Fatalf("computeSearchLimit: got %d, want %d", got, tc.want)
			}
		})
	}
}

func TestExpandSearchLimit(t *testing.T) {
	cases := []struct {
		current int
		want    int
		wantOk  bool
	}{
		{100, 200, true},
		{512, 1000, true},
		{1000, 1000, false},
		{2000, 2000, false},
	}

	for _, tc := range cases {
		got, ok := expandSearchLimit(tc.current)
		if got != tc.want || ok != tc.wantOk {
			t.Fatalf("expandSearchLimit(%d): got (%d, %v), want (%d, %v)",
				tc.current, got, ok, tc.want, tc.wantOk)
		}
	}
}

func TestSearchParamsResolvedProvider(t *testing.T) {
	cases := []struct {
		name    string
		p       searchParams
		want    string
		wantLoc bool
	}{
		{"all no filters", searchParams{Provider: types.ProviderAll}, types.ProviderAll, false},
		{"all + localOnly", searchParams{Provider: types.ProviderAll, LocalOnly: true}, types.ProviderHuggingFace, true},
		{"all + gpuOnly", searchParams{Provider: types.ProviderAll, GPUOnly: true}, types.ProviderHuggingFace, true},
		{"all + quantization", searchParams{Provider: types.ProviderAll, NormalizedQuantization: "q4_k_m"}, types.ProviderHuggingFace, true},
		{"hf explicit no filters", searchParams{Provider: types.ProviderHuggingFace}, types.ProviderHuggingFace, false},
		{"hf + localOnly", searchParams{Provider: types.ProviderHuggingFace, LocalOnly: true}, types.ProviderHuggingFace, true},
		{"openrouter no filters", searchParams{Provider: types.ProviderOpenRouter}, types.ProviderOpenRouter, false},
		{"openrouter + category", searchParams{Provider: types.ProviderOpenRouter, Category: "code"}, types.ProviderOpenRouter, true},
		{"all + format", searchParams{Provider: types.ProviderAll, Format: "gguf"}, types.ProviderAll, true},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if got := tc.p.resolvedProvider(); got != tc.want {
				t.Fatalf("resolvedProvider: got %q, want %q", got, tc.want)
			}
			if got := tc.p.isPostFilteredSearch(); got != tc.wantLoc {
				t.Fatalf("isPostFilteredSearch: got %v, want %v", got, tc.wantLoc)
			}
		})
	}
}
