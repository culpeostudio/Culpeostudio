package engine

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
)

func stringOption(values map[string]interface{}, key string) (string, bool) {
	value, ok := values[key]
	if !ok || value == nil {
		return "", false
	}
	return strings.TrimSpace(fmt.Sprint(value)), true
}

func intOption(values map[string]interface{}, key string) (*int, bool) {
	value, ok := values[key]
	if !ok || value == nil {
		return nil, false
	}
	var parsed int
	switch typed := value.(type) {
	case float64:
		parsed = int(typed)
	case int:
		parsed = typed
	case json.Number:
		parsed, _ = strconv.Atoi(string(typed))
	default:
		var err error
		parsed, err = strconv.Atoi(strings.TrimSpace(fmt.Sprint(value)))
		if err != nil {
			return nil, false
		}
	}
	return &parsed, true
}

func boolOption(values map[string]interface{}, key string) (bool, bool) {
	value, ok := values[key]
	if !ok || value == nil {
		return false, false
	}
	switch typed := value.(type) {
	case bool:
		return typed, true
	case string:
		parsed, err := strconv.ParseBool(typed)
		return parsed, err == nil
	default:
		return false, false
	}
}

func stringSliceOption(values map[string]interface{}, key string) []string {
	raw := values[key]
	result := []string{}
	switch typed := raw.(type) {
	case []interface{}:
		for _, item := range typed {
			result = append(result, fmt.Sprint(item))
		}
	case []string:
		result = append(result, typed...)
	}
	return uniqueStrings(result)
}

func floatOption(values map[string]interface{}, key string) (*float64, bool) {
	value, ok := values[key]
	if !ok || value == nil {
		return nil, false
	}
	var parsed float64
	switch typed := value.(type) {
	case float64:
		parsed = typed
	case int:
		parsed = float64(typed)
	case json.Number:
		parsed, _ = typed.Float64()
	default:
		var err error
		parsed, err = strconv.ParseFloat(strings.TrimSpace(fmt.Sprint(value)), 64)
		if err != nil {
			return nil, false
		}
	}
	return &parsed, true
}

// floatSliceOption reads a proportion list. It accepts both a JSON array and
// the comma-separated string a text field produces, because the value reaches
// the engine as free-form JSON either way.
func floatSliceOption(values map[string]interface{}, key string) ([]float64, error) {
	raw, ok := values[key]
	if !ok || raw == nil {
		return nil, nil
	}
	parse := func(text string) (float64, error) {
		value, err := strconv.ParseFloat(strings.TrimSpace(text), 64)
		if err != nil {
			return 0, fmt.Errorf("%q ist in %s keine Zahl", text, key)
		}
		return value, nil
	}
	result := []float64{}
	switch typed := raw.(type) {
	case []interface{}:
		for _, item := range typed {
			value, err := parse(fmt.Sprint(item))
			if err != nil {
				return nil, err
			}
			result = append(result, value)
		}
	case []float64:
		return append([]float64(nil), typed...), nil
	case string:
		for _, part := range strings.Split(typed, ",") {
			if strings.TrimSpace(part) == "" {
				continue
			}
			value, err := parse(part)
			if err != nil {
				return nil, err
			}
			result = append(result, value)
		}
	default:
		return nil, fmt.Errorf("%s erwartet eine Liste von Zahlen", key)
	}
	return result, nil
}

// argumentSliceOption reads the extra-args escape hatch. A single string is
// split the way a shell would, so a user can paste a flag line verbatim.
func argumentSliceOption(values map[string]interface{}, key string) ([]string, error) {
	raw, ok := values[key]
	if !ok || raw == nil {
		return nil, nil
	}
	switch typed := raw.(type) {
	case []interface{}:
		result := make([]string, 0, len(typed))
		for _, item := range typed {
			if text := strings.TrimSpace(fmt.Sprint(item)); text != "" {
				result = append(result, text)
			}
		}
		return result, nil
	case []string:
		return append([]string(nil), typed...), nil
	case string:
		return splitArguments(typed)
	default:
		return nil, fmt.Errorf("%s erwartet eine Argumentliste", key)
	}
}

// splitArguments splits on whitespace while honouring single and double quotes,
// so a value containing a space survives being typed into one text field.
func splitArguments(line string) ([]string, error) {
	result := []string{}
	current := strings.Builder{}
	quote := rune(0)
	started := false
	for _, char := range line {
		switch {
		case quote != 0:
			if char == quote {
				quote = 0
				continue
			}
			current.WriteRune(char)
		case char == '\'' || char == '"':
			quote = char
			started = true
		case char == ' ' || char == '\t' || char == '\n' || char == '\r':
			if started || current.Len() > 0 {
				result = append(result, current.String())
				current.Reset()
				started = false
			}
		default:
			current.WriteRune(char)
		}
	}
	if quote != 0 {
		return nil, fmt.Errorf("die zusaetzlichen Startargumente enthalten ein nicht geschlossenes Anfuehrungszeichen")
	}
	if started || current.Len() > 0 {
		result = append(result, current.String())
	}
	return result, nil
}

func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}
