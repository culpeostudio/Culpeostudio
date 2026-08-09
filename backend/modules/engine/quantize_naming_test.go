package engine

import "testing"

func TestDefaultTargetNameReplacesTheQuantizationLabel(t *testing.T) {
	cases := []struct {
		source string
		target string
		want   string
	}{
		// The common case: the source name already carries a label, and piling
		// a second one on top produces "Model-Q8_0-Q4_K_M.gguf".
		{"MiniCPM5-1B-Thinking-Q8_0.gguf", "Q4_K_M", "MiniCPM5-1B-Thinking-Q4_K_M.gguf"},
		{"Gemma-4-E4B-IQ4_XS.gguf", "Q3_K_M", "Gemma-4-E4B-Q3_K_M.gguf"},
		{"model.f16.gguf", "Q4_K_M", "model-Q4_K_M.gguf"},
		{"Llama-3-8B-BF16.gguf", "Q6_K", "Llama-3-8B-Q6_K.gguf"},
		// No recognisable label: append rather than mangle the name.
		{"my-finetune.gguf", "Q4_K_M", "my-finetune-Q4_K_M.gguf"},
		// A version number is not a quantisation label and must survive.
		{"Qwen3-30B-A3B.gguf", "Q4_K_M", "Qwen3-30B-A3B-Q4_K_M.gguf"},
	}
	for _, test := range cases {
		if got := defaultTargetName(test.source, test.target); got != test.want {
			t.Errorf("defaultTargetName(%q, %q) = %q, want %q", test.source, test.target, got, test.want)
		}
	}
}

func TestSplitArgumentsHonoursQuoting(t *testing.T) {
	got, err := splitArguments(`--chat-template "a b" --numa isolate`)
	if err != nil {
		t.Fatal(err)
	}
	want := []string{"--chat-template", "a b", "--numa", "isolate"}
	if len(got) != len(want) {
		t.Fatalf("got %q", got)
	}
	for index := range want {
		if got[index] != want[index] {
			t.Fatalf("got %q, want %q", got, want)
		}
	}
	// An empty quoted string is a real argument and must not vanish, or the
	// flag before it silently takes the next flag as its value.
	if got, err := splitArguments(`--chat-template ""`); err != nil || len(got) != 2 || got[1] != "" {
		t.Fatalf("empty quoted argument lost: %q err=%v", got, err)
	}
	if _, err := splitArguments(`--chat-template "unterminated`); err == nil {
		t.Fatal("an unterminated quote must be reported rather than guessed at")
	}
}

func TestTailLinesKeepsTheEnd(t *testing.T) {
	if got := tailLines("a\nb\nc\nd", 2); got != "c\nd" {
		t.Fatalf("tailLines = %q", got)
	}
	if got := tailLines("a\nb", 10); got != "a\nb" {
		t.Fatalf("a shorter log must come back whole, got %q", got)
	}
	if got := tailLines("a\nb", 0); got != "a\nb" {
		t.Fatalf("zero means everything, got %q", got)
	}
}

func TestLastCompletionTokensReadsTheFinalUsageObject(t *testing.T) {
	// A stream reports usage more than once; the last one is the total.
	stream := `data: {"choices":[]}

data: {"usage":{"completion_tokens":12,"prompt_tokens":8}}

data: {"usage":{"completion_tokens":40,"prompt_tokens":8}}

data: [DONE]
`
	if value, ok := lastCompletionTokens([]byte(stream)); !ok || value != 40 {
		t.Fatalf("lastCompletionTokens = %d ok=%v", value, ok)
	}
	if _, ok := lastCompletionTokens([]byte(`{"choices":[{"text":"hi"}]}`)); ok {
		t.Fatal("a response without usage must not be counted")
	}
	// A window into a stream is usually a partial document, so a truncated key
	// must not be read as a zero.
	if _, ok := lastCompletionTokens([]byte(`{"usage":{"completion_tokens":`)); ok {
		t.Fatal("a truncated usage object must not produce a count")
	}
}
