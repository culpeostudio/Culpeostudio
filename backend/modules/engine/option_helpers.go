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

func floatOption(values map[string]interface{}, key string) (float64, bool) {
	value, ok := values[key]
	if !ok || value == nil {
		return 0, false
	}
	switch typed := value.(type) {
	case float64:
		return typed, true
	case float32:
		return float64(typed), true
	case int:
		return float64(typed), true
	case json.Number:
		parsed, err := strconv.ParseFloat(string(typed), 64)
		return parsed, err == nil
	default:
		parsed, err := strconv.ParseFloat(strings.TrimSpace(fmt.Sprint(value)), 64)
		return parsed, err == nil
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

func cloneInt64Pointer(value *int64) *int64 {
	if value == nil {
		return nil
	}
	copy := *value
	return &copy
}
