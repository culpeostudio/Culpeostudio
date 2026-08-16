// Package agentplan holds the data model and prompts for two-stage task
// handling: a model first splits a task into readable steps, then one subagent
// works each step with a fresh context.
package agentplan

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
)

const (
	StatusPending = "pending"
	StatusRunning = "running"
	StatusDone    = "done"
	StatusFailed  = "failed"
)

const (
	MinSteps = 1
	MaxSteps = 12

	maxResultChars = 800
)

var ErrNoPlan = errors.New("agentplan: kein Plan in der Antwort gefunden")

// MaxQuestions caps how much the planner may ask back before it plans. Two,
// because the user starts a task with a concrete idea in mind: a round of
// questions is a last resort, not the way in.
const MaxQuestions = 2

type Step struct {
	Number int `json:"number"`

	Title string `json:"title"`

	Detail string `json:"detail,omitempty"`

	Status string `json:"status"`

	Result string `json:"result,omitempty"`
}

type Plan struct {
	Goal string `json:"goal"`

	Summary string `json:"summary"`

	Steps []Step `json:"steps"`
}

func (p Plan) StepTitles() []string {
	titles := make([]string, 0, len(p.Steps))
	for _, step := range p.Steps {
		titles = append(titles, fmt.Sprintf("%d. %s", step.Number, step.Title))
	}
	return titles
}

func (p Plan) IsEmpty() bool { return len(p.Steps) == 0 }

// Unfinished counts every step that is not done, failed ones included: a plan
// counts as worked off when all of its points are green, and a step that broke
// is a step to come back to, not one to write off.
func (p Plan) Unfinished() int {
	open := 0
	for _, step := range p.Steps {
		if step.Status != StatusDone {
			open++
		}
	}
	return open
}

func (p Plan) Pending() (Step, bool) {
	for _, step := range p.Steps {
		if step.Status == StatusPending || step.Status == StatusRunning {
			return step, true
		}
	}
	return Step{}, false
}

type Questions struct {
	Reason string `json:"reason"`

	Items []string `json:"items"`
}

type ParseResult struct {
	Plan      Plan
	Questions Questions
}

func (r ParseResult) NeedsAnswers() bool { return len(r.Questions.Items) > 0 }

func ParsePlan(goal, reply string) (Plan, error) {
	result, err := Parse(goal, reply)
	if err != nil {
		return Plan{}, err
	}
	if result.NeedsAnswers() {
		return Plan{}, ErrNoPlan
	}
	return result.Plan, nil
}

func Parse(goal, reply string) (ParseResult, error) {
	raw, ok := extractJSONObject(reply)
	if !ok {
		return ParseResult{}, ErrNoPlan
	}

	var parsed struct {
		Summary string `json:"summary"`
		Steps   []struct {
			Title  string `json:"title"`
			Detail string `json:"detail"`
		} `json:"steps"`
		Reason    string   `json:"reason"`
		Questions []string `json:"questions"`
	}
	if err := json.Unmarshal([]byte(raw), &parsed); err != nil {
		return ParseResult{}, fmt.Errorf("%w: %v", ErrNoPlan, err)
	}

	if questions := cleanQuestions(parsed.Questions); len(questions) > 0 {
		reason := strings.TrimSpace(parsed.Reason)
		if reason == "" {
			reason = "Zur Aufgabe fehlen mir noch Angaben."
		}
		return ParseResult{Questions: Questions{Reason: reason, Items: questions}}, nil
	}

	plan := Plan{
		Goal:    strings.TrimSpace(goal),
		Summary: strings.TrimSpace(parsed.Summary),
	}
	for _, item := range parsed.Steps {
		title := strings.TrimSpace(item.Title)
		if title == "" {
			continue
		}
		if len(plan.Steps) >= MaxSteps {
			break
		}
		plan.Steps = append(plan.Steps, Step{
			Number: len(plan.Steps) + 1,
			Title:  title,
			Detail: strings.TrimSpace(item.Detail),
			Status: StatusPending,
		})
	}
	if len(plan.Steps) < MinSteps {
		return ParseResult{}, ErrNoPlan
	}
	if plan.Summary == "" {
		plan.Summary = fmt.Sprintf("Plan mit %d Schritten", len(plan.Steps))
	}
	return ParseResult{Plan: plan}, nil
}

func cleanQuestions(raw []string) []string {
	out := make([]string, 0, len(raw))
	for _, question := range raw {
		trimmed := strings.TrimSpace(question)
		if trimmed == "" {
			continue
		}
		out = append(out, trimmed)
		if len(out) >= MaxQuestions {
			break
		}
	}
	return out
}

func extractJSONObject(text string) (string, bool) {
	start := strings.Index(text, "{")
	if start < 0 {
		return "", false
	}
	depth := 0
	inString := false
	escaped := false
	for i := start; i < len(text); i++ {
		c := text[i]
		if inString {
			switch {
			case escaped:
				escaped = false
			case c == '\\':
				escaped = true
			case c == '"':
				inString = false
			}
			continue
		}
		switch c {
		case '"':
			inString = true
		case '{':
			depth++
		case '}':
			depth--
			if depth == 0 {
				return text[start : i+1], true
			}
		}
	}
	return "", false
}

func shorten(s string, limit int) string {
	s = strings.TrimSpace(s)
	runes := []rune(s)
	if limit <= 0 || len(runes) <= limit {
		return s
	}
	return strings.TrimSpace(string(runes[:limit])) + " […]"
}
