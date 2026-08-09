package memorymodule

import (
	"reflect"

	"github.com/culpeohq/backend/internal/memory"
	"github.com/culpeohq/backend/internal/memoryviewer"
	"github.com/culpeohq/backend/internal/security"
)

// eventUserID reports whose memory an event describes, so a feed only carries
// what its subscriber is allowed to see. The hub broadcasts to everyone
// listening, so both the SSE writer and the gRPC stream filter on this.
//
// The payload types are what the store publishes; the reflection fallback
// covers a publisher that starts sending a type not listed here, which would
// otherwise leak to every subscriber.
func eventUserID(event memoryviewer.Event) string {
	if event.Data == nil {
		return ""
	}
	switch d := event.Data.(type) {
	case *memory.Session:
		if d != nil {
			return security.SanitizeUserID(d.UserID)
		}
	case memory.Session:
		return security.SanitizeUserID(d.UserID)
	case *memory.Prompt:
		if d != nil {
			return security.SanitizeUserID(d.UserID)
		}
	case memory.Prompt:
		return security.SanitizeUserID(d.UserID)
	case *memory.Observation:
		if d != nil {
			return security.SanitizeUserID(d.UserID)
		}
	case memory.Observation:
		return security.SanitizeUserID(d.UserID)
	case *memory.CompressedMemory:
		if d != nil {
			return security.SanitizeUserID(d.UserID)
		}
	case memory.CompressedMemory:
		return security.SanitizeUserID(d.UserID)
	case *memory.SessionSummary:
		if d != nil {
			return security.SanitizeUserID(d.UserID)
		}
	case memory.SessionSummary:
		return security.SanitizeUserID(d.UserID)
	case map[string]string:
		if val, ok := d["user_id"]; ok {
			return security.SanitizeUserID(val)
		}
	case map[string]interface{}:
		if val, ok := d["user_id"]; ok {
			if str, ok := val.(string); ok {
				return security.SanitizeUserID(str)
			}
		}
	default:
		val := reflect.ValueOf(event.Data)
		if val.Kind() == reflect.Ptr {
			val = val.Elem()
		}
		if val.Kind() == reflect.Struct {
			field := val.FieldByName("UserID")
			if field.IsValid() && field.Kind() == reflect.String {
				return security.SanitizeUserID(field.String())
			}
		}
	}
	return ""
}
