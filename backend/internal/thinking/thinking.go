package thinking

import "strings"

type Mode string

const (
	ModeNone Mode = "none"

	ModeMedium Mode = "medium"

	ModeMax Mode = "max"

	ModeDual Mode = "dual"

	ModeAgent Mode = "agent"
)

type Surface int

const (
	SurfaceChat Surface = iota

	SurfaceAgent
)

type definition struct {
	mode          Mode
	label         string
	inDevelopment bool
	chat          string
	agent         string

	reasoningEffort string
	temperature     float64
	topP            float64
}

type ReasoningConfig struct {
	Effort      string
	Temperature float64
	TopP        float64
}

var registry = map[Mode]definition{}

func register(d definition) {
	registry[d.mode] = d
}

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

func InDevelopment(m Mode) bool {
	if d, ok := registry[m]; ok {
		return d.inDevelopment
	}
	return false
}

func Label(m Mode) string {
	if d, ok := registry[m]; ok {
		return d.label
	}
	return string(m)
}

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
