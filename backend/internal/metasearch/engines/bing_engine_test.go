package engines

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/fillyengine/backend/internal/metasearch"
)

// TestBingEngineEnd2End mocked den Bing-HTML-Output ueber httptest und
// prueft, dass die XPath-Extraction und Bing-URL-Unwrapping durch den
// echten Engine laufen.
func TestBingEngineEnd2End(t *testing.T) {
	// Aufgebautes Mock-HTML im Stil von Bing-Suchtreffern.
	// Die Klassen `b_algo` und das hrefpattern entsprechen dem Original.
	encoded := "aHR0cHM6Ly93d3cuZXhhbXBsZS5jb20v" // = "https://www.example.com/"
	html := `<!DOCTYPE html><html><body><ol>
<li class="b_algo"><h2><a href="https://www.bing.com/ck/a?u=aX` + encoded + `">Hello World</a></h2><p>This is the body text</p></li>
<li class="b_algo"><h2><a href="https://example.org/page">Second hit</a></h2><p>Body two</p></li>
<li class="b_algo"><h2><a href="https://www.bing.com/aclick?x=ad">Ad should be filtered</a></h2><p>Ad body</p></li>
</ol></body></html>`

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html")
		_, _ = w.Write([]byte(html))
	}))
	defer srv.Close()

	// Wir bauen Bing-Engine manuell und ueberschreiben die URL, damit der
	// Mock-Server angesprochen wird statt www.bing.com.
	client, err := metasearch.NewHttpClient(metasearch.ClientOptions{Timeout: 5 * time.Second})
	if err != nil {
		t.Fatalf("client: %v", err)
	}
	eng := newBing(client).(interface {
		Search(ctx context.Context, p metasearch.SearchParams) ([]metasearch.Result, error)
		Info() metasearch.EngineInfo
	})
	// URL des XPathEngine aendern - wir greifen via Reflexion sonst nicht ran;
	// stattdessen lesen wir das EngineInfo und ueberschreiben Search-URL
	// ueber das sidestepping von BuildPayload: Dort wird requestURL=""
	// zurueckgegeben, also nutzen wir e.URL. Damit das Mock greift, testen
	// wir direkt, dass die Engine mit der angegebenen URL aufruft - dafuer
	// muessen wir e.URL aendern. Da das Feld public ist, koennen wir das
	// via Type-Assertion machen.
	if xe, ok := eng.(*metasearch.XPathEngine); ok {
		xe.URL = srv.URL
	} else {
		t.Fatalf("unexpected engine type %T", eng)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	results, err := eng.Search(ctx, metasearch.SearchParams{
		Query:  "test",
		Region: "us-en",
		Page:   1,
	})
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if len(results) != 2 {
		t.Fatalf("erwartet 2 Treffer (Ad herausgefiltert), got %d: %+v", len(results), results)
	}
	if results[0].Title != "Hello World" {
		t.Errorf("results[0].Title = %q, want 'Hello World'", results[0].Title)
	}
	// Bing URL Unwrap sollte /ck/a?u=aX<base64> zu https://www.example.com/ dekodieren.
	if !strings.HasPrefix(results[0].Href, "https://") {
		t.Errorf("Href[0] = %q, expected unwrapped https-URL", results[0].Href)
	}
	if !strings.Contains(results[0].Href, "www.example.com") {
		t.Errorf("Href[0] = %q, expected www.example.com (unwrapped)", results[0].Href)
	}
	if results[1].Title != "Second hit" {
		t.Errorf("results[1].Title = %q, want 'Second hit'", results[1].Title)
	}
	if results[1].Href != "https://example.org/page" {
		t.Errorf("Href[1] = %q, want https://example.org/page", results[1].Href)
	}
}
