package thinking

import "testing"

func TestNormalize(t *testing.T) {
	cases := map[string]Mode{
		"none":     ModeNone,
		"off":      ModeNone,
		"AUS":      ModeNone,
		"medium":   ModeMedium,
		"fast":     ModeMedium,
		"balanced": ModeMedium,
		"max":      ModeMax,
		"extra":    ModeMax,
		"dual":     ModeDual,
		"deep":     ModeDual,
		"agent":    ModeAgent,
		"agents":   ModeAgent,
		"agentic":  ModeAgent,
		"  Max  ":  ModeMax,
		"unknown":  ModeMedium,
		"":         ModeMedium,
	}
	for raw, want := range cases {
		if got := Normalize(raw); got != want {
			t.Errorf("Normalize(%q) = %q, want %q", raw, got, want)
		}
	}
}

func TestInDevelopment(t *testing.T) {
	built := []Mode{ModeNone, ModeMedium, ModeMax}
	for _, m := range built {
		if InDevelopment(m) {
			t.Errorf("mode %q should be built, got in-development", m)
		}
	}
	for _, m := range []Mode{ModeDual, ModeAgent} {
		if !InDevelopment(m) {
			t.Errorf("mode %q should be in-development", m)
		}
	}
}

func TestInstruction(t *testing.T) {
	for _, m := range []Mode{ModeNone, ModeMedium, ModeMax, ModeDual, ModeAgent} {
		if Instruction(m, SurfaceChat) == "" {
			t.Errorf("chat instruction for %q is empty", m)
		}
		if Instruction(m, SurfaceAgent) == "" {
			t.Errorf("agent instruction for %q is empty", m)
		}
	}

	if Instruction(ModeMax, SurfaceChat) == Instruction(ModeMax, SurfaceAgent) {
		t.Error("expected chat and agent surfaces to differ for ModeMax")
	}

	if Instruction("bogus", SurfaceChat) != Instruction(ModeMedium, SurfaceChat) {
		t.Error("unknown mode should fall back to ModeMedium")
	}
}

func TestReasoningFor(t *testing.T) {

	if got := ReasoningFor(ModeNone).Effort; got != "" {
		t.Errorf("ModeNone effort = %q, want empty", got)
	}
	if got := ReasoningFor(ModeMedium).Effort; got != "medium" {
		t.Errorf("ModeMedium effort = %q, want medium", got)
	}
	if got := ReasoningFor(ModeMax).Effort; got != "high" {
		t.Errorf("ModeMax effort = %q, want high", got)
	}

	none, medium, mx := ReasoningFor(ModeNone), ReasoningFor(ModeMedium), ReasoningFor(ModeMax)
	if !(none.Temperature < medium.Temperature && medium.Temperature < mx.Temperature) {
		t.Errorf("expected temperature none<medium<max, got %.2f/%.2f/%.2f",
			none.Temperature, medium.Temperature, mx.Temperature)
	}
	for _, c := range []ReasoningConfig{none, medium, mx} {
		if c.Temperature <= 0 || c.Temperature > 1 || c.TopP <= 0 || c.TopP > 1 {
			t.Errorf("sampling out of range: %+v", c)
		}
	}

	if ReasoningFor("bogus").Effort != ReasoningFor(ModeMedium).Effort {
		t.Error("unknown mode should fall back to ModeMedium reasoning config")
	}
}

func TestLabel(t *testing.T) {
	want := map[Mode]string{
		ModeNone:   "Fast",
		ModeMedium: "Fast Thinking",
		ModeMax:    "Extra",
		ModeDual:   "Dual",
		ModeAgent:  "Agent",
	}
	for m, label := range want {
		if got := Label(m); got != label {
			t.Errorf("Label(%q) = %q, want %q", m, got, label)
		}
	}
}
