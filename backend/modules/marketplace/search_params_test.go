package marketplace

import (
	"strings"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	marketplacev1 "github.com/culpeohq/backend/gen/go/culpeostudio/marketplace/v1"
	"github.com/culpeohq/backend/modules/marketplace/types"
)

func TestSearchParamsFromRequest_Success(t *testing.T) {
	cases := []struct {
		name    string
		request *marketplacev1.SearchModelsRequest
		want    searchParams
	}{
		{
			name:    "defaults",
			request: &marketplacev1.SearchModelsRequest{},
			want: searchParams{
				Provider: types.ProviderAll,
				SortMode: "popularity",
				Page:     1,
				PageSize: 20,
			},
		},
		{
			name: "provider openrouter",
			request: &marketplacev1.SearchModelsRequest{
				Provider: marketplacev1.Provider_PROVIDER_OPENROUTER,
			},
			want: searchParams{
				Provider: types.ProviderOpenRouter,
				SortMode: "popularity",
				Page:     1,
				PageSize: 20,
			},
		},
		{
			name:    "page+page_size",
			request: &marketplacev1.SearchModelsRequest{Page: 3, PageSize: 50},
			want: searchParams{
				Provider: types.ProviderAll,
				SortMode: "popularity",
				Page:     3,
				PageSize: 50,
			},
		},
		{
			name:    "page_size cap at 1000",
			request: &marketplacev1.SearchModelsRequest{PageSize: 5000},
			want: searchParams{
				Provider: types.ProviderAll,
				SortMode: "popularity",
				Page:     1,
				PageSize: 1000,
			},
		},
		{
			name: "hf local filters",
			request: &marketplacev1.SearchModelsRequest{
				Provider:     marketplacev1.Provider_PROVIDER_HUGGINGFACE,
				Query:        "llama",
				Format:       "gguf",
				Quantization: "Q4_K_M",
				Category:     marketplacev1.Category_CATEGORY_CHAT,
				Sort:         marketplacev1.SortMode_SORT_MODE_INTELLIGENCE,
				LocalOnly:    true,
				GpuFit:       true,
			},
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
			name: "all with local_only collapses to hf (still valid)",
			request: &marketplacev1.SearchModelsRequest{
				Provider:  marketplacev1.Provider_PROVIDER_ALL,
				LocalOnly: true,
			},
			want: searchParams{
				Provider:  types.ProviderAll,
				SortMode:  "popularity",
				Page:      1,
				PageSize:  20,
				LocalOnly: true,
			},
		},
		{
			// An unset category means no filter, the way an omitted query
			// parameter used to.
			name: "unspecified category is no filter",
			request: &marketplacev1.SearchModelsRequest{
				Category: marketplacev1.Category_CATEGORY_UNSPECIFIED,
			},
			want: searchParams{
				Provider: types.ProviderAll,
				Category: "",
				SortMode: "popularity",
				Page:     1,
				PageSize: 20,
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := searchParamsFromRequest(tc.request)
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if got != tc.want {
				t.Fatalf("searchParams:\n got %+v\nwant %+v", got, tc.want)
			}
		})
	}
}

// The schema rejects an unknown provider, a non-numeric page and "maybe" for a
// boolean before the request is ever dispatched, so only the value ranges and
// the provider/filter combination are left to check.
func TestSearchParamsFromRequest_Errors(t *testing.T) {
	cases := []struct {
		name        string
		request     *marketplacev1.SearchModelsRequest
		wantMsgPart string
	}{
		{
			"provider outside the enum",
			&marketplacev1.SearchModelsRequest{Provider: marketplacev1.Provider(99)},
			"ungueltiger provider",
		},
		{
			"negative page",
			&marketplacev1.SearchModelsRequest{Page: -1},
			"page",
		},
		{
			"negative page_size",
			&marketplacev1.SearchModelsRequest{PageSize: -1},
			"page_size",
		},
		{
			"cloud provider with local_only",
			&marketplacev1.SearchModelsRequest{
				Provider:  marketplacev1.Provider_PROVIDER_OPENROUTER,
				LocalOnly: true,
			},
			"nur fuer HuggingFace",
		},
		{
			"cloud provider with gpu_fit",
			&marketplacev1.SearchModelsRequest{
				Provider: marketplacev1.Provider_PROVIDER_FEATHERLESS,
				GpuFit:   true,
			},
			"nur fuer HuggingFace",
		},
		{
			"cloud provider with quantization",
			&marketplacev1.SearchModelsRequest{
				Provider:     marketplacev1.Provider_PROVIDER_OPENROUTER,
				Quantization: "Q4_K_M",
			},
			"nur fuer HuggingFace",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			_, err := searchParamsFromRequest(tc.request)
			if err == nil {
				t.Fatalf("expected an error for %+v, got nil", tc.request)
			}
			if got := status.Code(err); got != codes.InvalidArgument {
				t.Fatalf("status code = %s, want %s", got, codes.InvalidArgument)
			}
			message := status.Convert(err).Message()
			if !strings.Contains(strings.ToLower(message), strings.ToLower(tc.wantMsgPart)) {
				t.Fatalf("message %q does not contain %q", message, tc.wantMsgPart)
			}
		})
	}
}

func TestSortModeFromProto(t *testing.T) {
	cases := map[marketplacev1.SortMode]string{
		marketplacev1.SortMode_SORT_MODE_UNSPECIFIED:    "popularity",
		marketplacev1.SortMode_SORT_MODE_POPULARITY:     "popularity",
		marketplacev1.SortMode_SORT_MODE_INTELLIGENCE:   "intelligence",
		marketplacev1.SortMode_SORT_MODE_CONTEXT:        "context",
		marketplacev1.SortMode_SORT_MODE_NEWEST:         "newest",
		marketplacev1.SortMode_SORT_MODE_PRICE_LOW_HIGH: "price_low_high",
		marketplacev1.SortMode_SORT_MODE_PRICE_HIGH_LOW: "price_high_low",
	}

	for sortMode, want := range cases {
		got := sortModeFromProto(sortMode)
		if got != want {
			t.Errorf("sortModeFromProto(%v) = %q, want %q", sortMode, got, want)
		}
		// Every mode the enum offers has to survive the sorter's own
		// normalisation, which is what actually decides the order.
		if normalizeSortMode(got) != got {
			t.Errorf("sortModeFromProto(%v) = %q is not a canonical sort mode", sortMode, got)
		}
	}

	if !isPriceSortMode(sortModeFromProto(marketplacev1.SortMode_SORT_MODE_PRICE_LOW_HIGH)) {
		t.Error("price low-high must be recognised as a price sort")
	}
	if !isDescendingPriceSortMode(sortModeFromProto(marketplacev1.SortMode_SORT_MODE_PRICE_HIGH_LOW)) {
		t.Error("price high-low must be recognised as descending")
	}
}

func TestCategoryFromProto(t *testing.T) {
	cases := map[marketplacev1.Category]string{
		marketplacev1.Category_CATEGORY_UNSPECIFIED: categoryAll,
		marketplacev1.Category_CATEGORY_CHAT:        categoryChat,
		marketplacev1.Category_CATEGORY_CODE:        categoryCode,
		marketplacev1.Category_CATEGORY_REASONING:   categoryReasoning,
		marketplacev1.Category_CATEGORY_VISION:      categoryVision,
		marketplacev1.Category_CATEGORY_EMBEDDING:   categoryEmbedding,
	}

	for category, want := range cases {
		if got := categoryFromProto(category); got != want {
			t.Errorf("categoryFromProto(%v) = %q, want %q", category, got, want)
		}
	}
}

// Every provider name the backend produces has to map back onto the enum, or a
// search hit would arrive without a provider and could never be downloaded.
func TestProviderRoundTrip(t *testing.T) {
	for _, provider := range []string{
		types.ProviderAll,
		types.ProviderHuggingFace,
		types.ProviderOpenRouter,
		types.ProviderFeatherless,
	} {
		encoded := providerToProto(provider)
		if encoded == marketplacev1.Provider_PROVIDER_UNSPECIFIED {
			t.Fatalf("providerToProto(%q) lost the provider", provider)
		}
		decoded, err := searchProviderFromProto(encoded)
		if err != nil {
			t.Fatalf("searchProviderFromProto(%v) failed: %v", encoded, err)
		}
		if decoded != provider {
			t.Fatalf("round trip: %q -> %v -> %q", provider, encoded, decoded)
		}
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
