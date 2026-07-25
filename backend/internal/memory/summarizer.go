package memory

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"time"
)

// Summarizer is the pluggable compression step: it turns a slice of
// observations into the compressed memory content. The rule-based engine is
// the default; an LLM-based engine can be switched on via config.
type Summarizer interface {
	Name() string
	Summarize(observations []Observation) (summary string, learned []string, openTasks []string, err error)
}

// RuleBasedSummarizer is the deterministic, dependency-free default.
type RuleBasedSummarizer struct{}

func (RuleBasedSummarizer) Name() string { return "rules" }

func (RuleBasedSummarizer) Summarize(observations []Observation) (string, []string, []string, error) {
	return summarizeObservations(observations),
		extractObservationHighlights(observations, 4),
		extractObservationTasks(observations, 4),
		nil
}

// LLMSummarizer calls an OpenAI-compatible chat endpoint. It runs outside the
// compression write transaction (preventing database lock blockages during
// network I/O), so every failure falls back to the rule-based engine — compression
// never breaks because an LLM endpoint is down.
//
// Where the surrounding system already runs LLM DAG roles, prefer feeding
// their outputs in via the capture API (extracted metadata) instead of
// paying an extra call here.
type LLMSummarizer struct {
	url      string
	model    string
	apiKey   string
	client   *http.Client
	fallback Summarizer
}

func NewLLMSummarizer(url, model, apiKey string, timeoutSeconds int) *LLMSummarizer {
	if timeoutSeconds <= 0 {
		timeoutSeconds = 8
	}
	return &LLMSummarizer{
		url:      strings.TrimRight(strings.TrimSpace(url), "/"),
		model:    strings.TrimSpace(model),
		apiKey:   strings.TrimSpace(apiKey),
		client:   &http.Client{Timeout: time.Duration(timeoutSeconds) * time.Second},
		fallback: RuleBasedSummarizer{},
	}
}

func (l *LLMSummarizer) Name() string { return "llm" }

func (l *LLMSummarizer) Summarize(observations []Observation) (string, []string, []string, error) {
	summary, learned, tasks, err := l.summarizeViaLLM(observations)
	if err != nil {
		log.Printf("[memory-compress] llm summarizer fehlgeschlagen (%v), fallback auf rules", err)
		return l.fallback.Summarize(observations)
	}
	return summary, learned, tasks, nil
}

func (l *LLMSummarizer) summarizeViaLLM(observations []Observation) (string, []string, []string, error) {
	if l.url == "" {
		return "", nil, nil, fmt.Errorf("llm url fehlt")
	}
	lines := make([]string, 0, len(observations))
	for _, observation := range observations {
		line := fallbackTitle(observation.Title, observation.Type)
		if observation.Narrative != "" {
			line += ": " + previewText(observation.Narrative, 300)
		}
		lines = append(lines, "- "+line)
	}
	prompt := "Fasse die folgenden Projekt-Beobachtungen zusammen. Antworte NUR mit JSON: " +
		`{"summary":"...","learned":["..."],"open_tasks":["..."]}` +
		"\n\nBeobachtungen:\n" + strings.Join(lines, "\n")

	requestBody, err := json.Marshal(map[string]interface{}{
		"model": l.model,
		"messages": []map[string]string{
			{"role": "user", "content": prompt},
		},
		"temperature": 0.2,
	})
	if err != nil {
		return "", nil, nil, err
	}
	request, err := http.NewRequest(http.MethodPost, l.url+"/v1/chat/completions", bytes.NewReader(requestBody))
	if err != nil {
		return "", nil, nil, err
	}
	request.Header.Set("Content-Type", "application/json")
	if l.apiKey != "" {
		request.Header.Set("Authorization", "Bearer "+l.apiKey)
	}
	response, err := l.client.Do(request)
	if err != nil {
		return "", nil, nil, err
	}
	defer response.Body.Close()
	payload, err := io.ReadAll(io.LimitReader(response.Body, 4<<20))
	if err != nil {
		return "", nil, nil, err
	}
	if response.StatusCode != http.StatusOK {
		return "", nil, nil, fmt.Errorf("llm status %d", response.StatusCode)
	}
	var parsed struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(payload, &parsed); err != nil {
		return "", nil, nil, err
	}
	if len(parsed.Choices) == 0 {
		return "", nil, nil, fmt.Errorf("llm antwort leer")
	}
	content := extractJSONObject(parsed.Choices[0].Message.Content)
	var result struct {
		Summary   string   `json:"summary"`
		Learned   []string `json:"learned"`
		OpenTasks []string `json:"open_tasks"`
	}
	if err := json.Unmarshal([]byte(content), &result); err != nil {
		return "", nil, nil, fmt.Errorf("llm antwort kein valides JSON: %w", err)
	}
	if strings.TrimSpace(result.Summary) == "" {
		return "", nil, nil, fmt.Errorf("llm antwort ohne summary")
	}
	return strings.TrimSpace(result.Summary), normalizeList(result.Learned), normalizeList(result.OpenTasks), nil
}

// extractJSONObject tolerates markdown fences and prose around the JSON.
func extractJSONObject(content string) string {
	start := strings.Index(content, "{")
	end := strings.LastIndex(content, "}")
	if start >= 0 && end > start {
		return content[start : end+1]
	}
	return content
}
