package philox

import (
	"encoding/json"
	"fmt"
	"io"
	"strconv"
	"strings"
)

func normalizeToolCall(call ToolCall) (ToolCall, map[string]interface{}, error) {
	normalized, parsed, err := normalizeToolArguments(call.Function.Arguments)
	if err != nil {
		return call, nil, err
	}
	call.Function.Arguments = normalized
	return call, parsed, nil
}

func sanitizeToolCalls(toolCalls []ToolCall) []ToolCall {
	if len(toolCalls) == 0 {
		return nil
	}

	sanitized := make([]ToolCall, 0, len(toolCalls))
	for _, call := range toolCalls {
		normalizedCall, parsedArgs, err := normalizeToolCall(call)
		if err == nil && validateToolArguments(normalizedCall.Function.Name, parsedArgs) == nil {
			sanitized = append(sanitized, normalizedCall)
			continue
		}

		fallback := call
		fallback.Function.Arguments = "{}"
		sanitized = append(sanitized, fallback)
	}
	return sanitized
}

func normalizeToolArguments(raw string) (string, map[string]interface{}, error) {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return "", map[string]interface{}{}, nil
	}

	var lastErr error
	for _, candidate := range toolArgumentCandidates(trimmed) {
		normalized, parsed, err := parseToolArgumentCandidate(candidate)
		if err == nil {
			return normalized, parsed, nil
		}
		lastErr = err
	}
	if lastErr == nil {
		lastErr = fmt.Errorf("kein JSON-Objekt erkannt")
	}
	return "", nil, lastErr
}

func toolArgumentCandidates(raw string) []string {
	candidates := []string{raw}
	if unquoted, err := strconv.Unquote(raw); err == nil {
		candidates = append(candidates, strings.TrimSpace(unquoted))
	}
	if first := strings.Index(raw, "{"); first >= 0 {
		if last := strings.LastIndex(raw, "}"); last > first {
			candidates = append(candidates, strings.TrimSpace(raw[first:last+1]))
		}
	}

	seen := map[string]struct{}{}
	unique := make([]string, 0, len(candidates))
	for _, candidate := range candidates {
		candidate = strings.TrimSpace(candidate)
		if candidate == "" {
			continue
		}
		if _, ok := seen[candidate]; ok {
			continue
		}
		seen[candidate] = struct{}{}
		unique = append(unique, candidate)
	}
	return unique
}

func parseToolArgumentCandidate(candidate string) (string, map[string]interface{}, error) {
	value, rest, err := decodeJSONValue(candidate)
	if err != nil {
		repaired, repairedErr := repairToolArgumentCandidate(candidate, err)
		if repairedErr != nil {
			return "", nil, repairedErr
		}
		value, rest, err = decodeJSONValue(repaired)
		if err != nil {
			return "", nil, err
		}
	}

	if nested, ok := value.(string); ok {
		if strings.Contains(nested, "{") {
			return normalizeToolArguments(nested)
		}
		return "", nil, fmt.Errorf("Tool-Argumente muessen ein JSON-Objekt sein")
	}

	parsed, ok := value.(map[string]interface{})
	if !ok {
		return "", nil, fmt.Errorf("Tool-Argumente muessen ein JSON-Objekt sein")
	}

	for strings.TrimSpace(rest) != "" {
		extraValue, nextRest, err := decodeJSONValue(rest)
		if err != nil {
			return "", nil, err
		}
		extraParsed, ok := extraValue.(map[string]interface{})
		if !ok || !sameJSONValue(parsed, extraParsed) {
			return "", nil, fmt.Errorf("mehrere unterschiedliche JSON-Werte erkannt")
		}
		rest = nextRest
	}

	normalizedBytes, err := json.Marshal(parsed)
	if err != nil {
		return "", nil, err
	}
	return string(normalizedBytes), parsed, nil
}

func repairToolArgumentCandidate(candidate string, parseErr error) (string, error) {
	trimmed := strings.TrimSpace(stripJSONCodeFence(candidate))
	if trimmed == "" {
		return "", parseErr
	}

	repaired := escapeInvalidBackslashes(trimmed)
	repaired = closeJSONObjectFragments(repaired)

	if repaired == trimmed {
		return "", parseErr
	}
	return repaired, nil
}

func closeJSONObjectFragments(raw string) string {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return ""
	}

	inString := false
	escaped := false
	openBraces := 0
	openBrackets := 0

	for i := 0; i < len(trimmed); i++ {
		ch := trimmed[i]
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
			openBraces++
		case '}':
			if openBraces > 0 {
				openBraces--
			}
		case '[':
			openBrackets++
		case ']':
			if openBrackets > 0 {
				openBrackets--
			}
		}
	}

	var builder strings.Builder
	builder.WriteString(trimmed)
	if inString {
		builder.WriteByte('"')
	}
	for openBrackets > 0 {
		builder.WriteByte(']')
		openBrackets--
	}
	for openBraces > 0 {
		builder.WriteByte('}')
		openBraces--
	}
	return builder.String()
}

func escapeInvalidBackslashes(raw string) string {
	if !strings.Contains(raw, `\`) {
		return raw
	}

	var builder strings.Builder
	builder.Grow(len(raw) + 8)

	inString := false
	escaped := false
	for i := 0; i < len(raw); i++ {
		ch := raw[i]
		if !inString {
			builder.WriteByte(ch)
			if ch == '"' {
				inString = true
				escaped = false
			}
			continue
		}

		if escaped {
			builder.WriteByte(ch)
			escaped = false
			continue
		}

		if ch == '"' {
			builder.WriteByte(ch)
			inString = false
			continue
		}

		if ch == '\\' {
			next := byte(0)
			hasNext := i+1 < len(raw)
			if hasNext {
				next = raw[i+1]
			}
			if !hasNext || !isValidJSONEscape(next) {
				builder.WriteString(`\\`)
				continue
			}
			builder.WriteByte(ch)
			escaped = true
			continue
		}

		builder.WriteByte(ch)
	}

	return builder.String()
}

func isValidJSONEscape(ch byte) bool {
	switch ch {
	case '"', '\\', '/', 'b', 'f', 'n', 'r', 't', 'u':
		return true
	default:
		return false
	}
}

func decodeJSONValue(candidate string) (interface{}, string, error) {
	reader := strings.NewReader(candidate)
	decoder := json.NewDecoder(reader)
	decoder.UseNumber()

	var value interface{}
	if err := decoder.Decode(&value); err != nil {
		return nil, "", err
	}

	buffered, _ := io.ReadAll(decoder.Buffered())
	remaining, _ := io.ReadAll(reader)
	rest := strings.TrimSpace(string(buffered) + string(remaining))
	return value, rest, nil
}

func sameJSONValue(left, right interface{}) bool {
	leftBytes, leftErr := json.Marshal(left)
	rightBytes, rightErr := json.Marshal(right)
	if leftErr != nil || rightErr != nil {
		return false
	}
	return string(leftBytes) == string(rightBytes)
}
