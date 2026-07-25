// Package thinking defines the shared "Thinking" mode taxonomy used by the
// PhiloBot chat surface and the Philox agent surface. Each mode lives in its
// own file (none.go, medium.go, max.go, dual.go, agent.go) and registers a
// definition here. This file holds the type, the registry, and the
// normalization/lookup helpers.
//
// Thinking is prompt-driven: a mode simply selects which system-prompt fragment
// is injected. That single mechanism works for models with native reasoning as
// well as models without it — for the latter, the medium/max instruction is what
// makes them reason step by step in plain text.
package thinking

import "strings"

// Mode is a canonical thinking level selected in the UI.
type Mode string

const (
	// ModeNone — "Fast": no deliberate thinking, answer directly.
	ModeNone Mode = "none"
	// ModeMedium — "Fast Thinking": balanced, everyday reasoning.
	ModeMedium Mode = "medium"
	// ModeMax — "Extra": maximum, multi-step reasoning.
	ModeMax Mode = "max"
	// ModeDual — "Dual": in development.
	ModeDual Mode = "dual"
	// ModeAgent — "Agent": in development.
	ModeAgent Mode = "agent"
)

// Surface distinguishes the two prompt styles a mode can render.
type Surface int

const (
	// SurfaceChat renders the short "- Thinking: …" one-liner used by PhiloBot.
	SurfaceChat Surface = iota
	// SurfaceAgent renders the "## Arbeitsmodus: …" block used by Philox.
	SurfaceAgent
)

// definition is the full description of one thinking mode. Each mode file
// registers exactly one of these from its init().
type definition struct {
	mode          Mode
	label         string
	inDevelopment bool
	chat          string // SurfaceChat instruction
	agent         string // SurfaceAgent instruction

	// Native reasoning + sampling knobs. reasoningEffort maps to OpenRouter's
	// unified `reasoning: {effort}` control ("" = don't request native reasoning,
	// rely on the prompt fallback). temperature/topP are per-level sampling.
	reasoningEffort string
	temperature     float64
	topP            float64
}

// ReasoningConfig is the model-native reasoning + sampling configuration for a
// thinking mode. Effort is empty when the mode should not request native
// reasoning (the prompt instruction is then the only steering).
type ReasoningConfig struct {
	Effort      string // "", "low", "medium", "high"
	Temperature float64
	TopP        float64
}

var registry = map[Mode]definition{}

func register(d definition) {
	registry[d.mode] = d
}

// Normalize maps any raw UI value or legacy alias onto a canonical Mode.
// Unknown values fall back to ModeMedium.
func Normalize(raw string) Mode {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "none", "off", "aus":
		return ModeNone
	case "max", "extra":
		return ModeMax
	case "dual", "deep":
		return ModeDual
	case "agent", "agents", "agentic":
		return ModeAgent
	case "medium", "fast", "balanced":
		return ModeMedium
	default:
		return ModeMedium
	}
}

// InDevelopment reports whether a mode is gated (not yet built).
func InDevelopment(m Mode) bool {
	if d, ok := registry[m]; ok {
		return d.inDevelopment
	}
	return false
}

// Label returns the human-facing label for a mode.
func Label(m Mode) string {
	if d, ok := registry[m]; ok {
		return d.label
	}
	return string(m)
}

// Instruction returns the system-prompt fragment for the given mode and surface.
// Unknown modes fall back to ModeMedium so callers always get usable text.
func Instruction(m Mode, surface Surface) string {
	d, ok := registry[m]
	if !ok {
		d = registry[ModeMedium]
	}
	if surface == SurfaceAgent {
		return d.agent
	}
	return d.chat
}

// ReasoningFor returns the native reasoning + sampling configuration for a mode.
// Unknown modes fall back to ModeMedium.
func ReasoningFor(m Mode) ReasoningConfig {
	d, ok := registry[m]
	if !ok {
		d = registry[ModeMedium]
	}
	return ReasoningConfig{
		Effort:      d.reasoningEffort,
		Temperature: d.temperature,
		TopP:        d.topP,
	}
}
