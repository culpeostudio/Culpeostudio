package philobot

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"
)

func (m *PhiloBotModule) applyBotBuilderAutomation(userID, reply string) (string, *BotConfig) {
	clean := reply
	var savedBot *BotConfig
	for _, prefix := range []string{"[SAVE_BOT:", "[CREATE_BOT:"} {
		for {
			startIdx := strings.Index(clean, prefix)
			if startIdx == -1 {
				break
			}
			jsonStartRel := strings.Index(clean[startIdx+len(prefix):], "{")
			if jsonStartRel == -1 {
				break
			}
			jsonStart := startIdx + len(prefix) + jsonStartRel
			jsonEnd, ok := findJSONObjectEnd(clean, jsonStart)
			if !ok {
				break
			}
			markerEnd := jsonEnd
			for markerEnd < len(clean) && isInlineSpace(clean[markerEnd]) {
				markerEnd++
			}
			if markerEnd < len(clean) && clean[markerEnd] == ']' {
				markerEnd++
			}
			if bot, err := m.saveBotBuilderPayload(userID, clean[jsonStart:jsonEnd]); err == nil {
				savedBot = bot
			}
			clean = strings.TrimSpace(clean[:startIdx] + clean[markerEnd:])
		}
	}
	return clean, savedBot
}

type botBuilderStreamFilter struct {
	pending string
	emit    func(string) error
}

func newBotBuilderStreamFilter(emit func(string) error) *botBuilderStreamFilter {
	return &botBuilderStreamFilter{emit: emit}
}

func (f *botBuilderStreamFilter) Emit(chunk string) error {
	f.pending += chunk
	return f.drain(false)
}

func (f *botBuilderStreamFilter) Flush() error {
	return f.drain(true)
}

func (f *botBuilderStreamFilter) drain(final bool) error {
	for {
		startIdx, prefix := firstBotBuilderMarker(f.pending)
		if startIdx == -1 {
			if final {
				return f.emitPending()
			}
			visible, rest := splitKeepingLastRunes(f.pending, len("[CREATE_BOT:")-1)
			f.pending = rest
			if visible == "" {
				return nil
			}
			return f.emit(visible)
		}

		if startIdx > 0 {
			if err := f.emit(f.pending[:startIdx]); err != nil {
				return err
			}
			f.pending = f.pending[startIdx:]
		}

		jsonStartRel := strings.Index(f.pending[len(prefix):], "{")
		if jsonStartRel == -1 {
			return nil
		}
		jsonStart := len(prefix) + jsonStartRel
		jsonEnd, ok := findJSONObjectEnd(f.pending, jsonStart)
		if !ok {
			return nil
		}
		markerEnd := jsonEnd
		for markerEnd < len(f.pending) && isInlineSpace(f.pending[markerEnd]) {
			markerEnd++
		}
		if markerEnd < len(f.pending) && f.pending[markerEnd] == ']' {
			markerEnd++
		}
		f.pending = f.pending[markerEnd:]
	}
}

func (f *botBuilderStreamFilter) emitPending() error {
	if f.pending == "" {
		return nil
	}
	pending := f.pending
	f.pending = ""
	return f.emit(pending)
}

func firstBotBuilderMarker(text string) (int, string) {
	bestIdx := -1
	bestPrefix := ""
	for _, prefix := range []string{"[SAVE_BOT:", "[CREATE_BOT:"} {
		idx := strings.Index(text, prefix)
		if idx == -1 {
			continue
		}
		if bestIdx == -1 || idx < bestIdx {
			bestIdx = idx
			bestPrefix = prefix
		}
	}
	return bestIdx, bestPrefix
}

func splitKeepingLastRunes(text string, keep int) (string, string) {
	if keep <= 0 {
		return text, ""
	}
	runes := []rune(text)
	if len(runes) <= keep {
		return "", text
	}
	return string(runes[:len(runes)-keep]), string(runes[len(runes)-keep:])
}

func (m *PhiloBotModule) saveBotBuilderPayload(userID, raw string) (*BotConfig, error) {
	var payload BotConfig
	if err := json.Unmarshal([]byte(raw), &payload); err != nil {
		return nil, err
	}
	payload.ID = strings.TrimSpace(payload.ID)
	if payload.ID == "" || payload.ID == "optional-vorhandene-id" {
		payload.ID = fmt.Sprintf("bot-%d", time.Now().UnixNano())
	}
	payload.Name = strings.TrimSpace(payload.Name)
	payload.SystemPrompt = strings.TrimSpace(payload.SystemPrompt)
	payload.Keywords = cleanKeywords(payload.Keywords)
	payload.ResponseStyle = normalizeResponseStyle(payload.ResponseStyle)
	if payload.Name == "" || payload.SystemPrompt == "" {
		return nil, fmt.Errorf("Botbuilder-Payload braucht name und system_prompt")
	}
	if err := m.botStore.SaveBotForUser(userID, payload); err != nil {
		return nil, err
	}
	return &payload, nil
}

func findJSONObjectEnd(text string, start int) (int, bool) {
	depth := 0
	inString := false
	escaped := false
	for i := start; i < len(text); i++ {
		ch := text[i]
		if inString {
			if escaped {
				escaped = false
				continue
			}
			if ch == '\\' {
				escaped = true
				continue
			}
			if ch == '"' {
				inString = false
			}
			continue
		}
		switch ch {
		case '"':
			inString = true
		case '{':
			depth++
		case '}':
			depth--
			if depth == 0 {
				return i + 1, true
			}
		}
	}
	return 0, false
}

func cleanKeywords(keywords []string) []string {
	cleaned := make([]string, 0, len(keywords))
	seen := make(map[string]struct{}, len(keywords))
	for _, keyword := range keywords {
		kw := strings.TrimSpace(keyword)
		if kw == "" {
			continue
		}
		key := strings.ToLower(kw)
		if _, exists := seen[key]; exists {
			continue
		}
		seen[key] = struct{}{}
		cleaned = append(cleaned, kw)
	}
	return cleaned
}

func isInlineSpace(ch byte) bool {
	return ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t'
}
