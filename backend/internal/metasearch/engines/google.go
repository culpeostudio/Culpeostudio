package engines

import (
	"math/rand"
	"strconv"
	"strings"
	"time"

	"github.com/fillyengine/backend/internal/metasearch"
)

var googleUserAgentDevices = []struct {
	androidVer string
	device     string
	chromeMin  int
	chromeMax  int
}{
	{"5.0", "SM-G900P Build/LRX21T", 39, 60},
	{"6.0", "Nexus 5 Build/MRA58N", 39, 60},
	{"8.0", "Pixel 2 Build/OPD3.170816.012", 39, 60},
}

const googleUATail = "NSTNWV"

func getGoogleUA() string {
	dev := googleUserAgentDevices[rand.Intn(len(googleUserAgentDevices))]
	chromeMajor := dev.chromeMin + rand.Intn(dev.chromeMax-dev.chromeMin+1)
	chromeBuild := 1000 + rand.Intn(9000)
	chromePatch := 1000 + rand.Intn(1000)
	ua := "Mozilla/5.0 (Linux; Android " + dev.androidVer + "; " + dev.device + ") " +
		"AppleWebKit/537.36 (KHTML, like Gecko) " +
		"Chrome/" + strconv.Itoa(chromeMajor) + ".0." + strconv.Itoa(chromeBuild) + "." + strconv.Itoa(chromePatch) + " Mobile Safari/537.36"
	return ua + googleUATail
}

func newGoogle(client *metasearch.HttpClient) metasearch.Engine {
	ua := getGoogleUA()
	return &metasearch.XPathEngine{
		Meta: metasearch.EngineInfo{
			Name:     "google",
			Category: "text",
			Provider: "google",
			Priority: 1.0,
		},
		Client: client,
		URL:    "https://www.google.com/search",
		Method: "GET",
		Headers: map[string]string{
			"User-Agent": ua,
		},
		ItemsXPath: "//div[@data-hveid][.//h3]",
		ElementsXPath: map[string]string{
			"title": ".//h3//text()",
			"href":  ".//a[.//h3]/@href",
			"body":  "./div/div[last()]//text()",
		},
		BuildPayload: func(p metasearch.SearchParams) (map[string]string, map[string]map[string]string, string) {
			safesearchBase := map[string]string{"on": "2", "moderate": "1", "off": "0"}
			ss := safesearchBase[strings.ToLower(p.Safesearch)]
			if ss == "" {
				ss = "1"
			}
			start := (p.Page - 1) * 10
			country, lang := splitRegion(p.Region)
			payload := map[string]string{
				"q":      p.Query,
				"filter": ss,
				"start":  strconv.Itoa(start),
				"hl":     lang + "-" + strings.ToUpper(country),
				"lr":     "lang_" + lang,
				"cr":     "country" + strings.ToUpper(country),
			}
			if p.Timelimit != "" {
				payload["tbs"] = "qdr:" + p.Timelimit
			}
			cookies := map[string]map[string]string{
				"https://google.com": {
					"CONSENT": "YES+",
				},
			}
			return payload, cookies, ""
		},
		PostProcessResults: func(results []metasearch.Result) []metasearch.Result {
			out := make([]metasearch.Result, 0, len(results))
			for _, r := range results {
				if strings.HasPrefix(r.Href, "/url?q=") {
					tail := strings.TrimPrefix(r.Href, "/url?q=")
					if i := strings.Index(tail, "&"); i >= 0 {
						tail = tail[:i]
					}
					r.Href = tail
				}
				if r.Title != "" && strings.HasPrefix(r.Href, "http") {
					out = append(out, r)
				}
			}
			return out
		},
	}
}

var _ = time.Now
