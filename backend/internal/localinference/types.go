// Package localinference defines the narrow contract used by application
// modules to talk to a ready local Engine instance. The worker secret and its
// loopback address deliberately stay inside the Engine implementation.
package localinference

import (
	"context"
	"errors"
)

const ProviderLocal = "local"

var (
	ErrNotFound          = errors.New("lokale Engine-Instanz wurde nicht gefunden")
	ErrNotReady          = errors.New("lokale Engine-Instanz ist noch nicht bereit")
	ErrContextLimit      = errors.New("Kontextlimit des lokalen Modells ueberschritten")
	ErrInvalidRequest    = errors.New("ungueltige lokale Modellanfrage")
	ErrWorkerUnavailable = errors.New("lokales Modell ist nicht erreichbar")
	ErrGuardRejected     = errors.New("Ressourcenwaechter hat den Modellstart abgelehnt")
	ErrQueueTimeout      = errors.New("Modellstart hat zu lange in der Warteschlange gewartet")
	ErrWarmupCanceled    = errors.New("Modell-Warmup wurde abgebrochen")
	ErrInferenceBusy     = errors.New("lokale Inferenz-Warteschlange ist ausgelastet")
)

type Model struct {
	InstanceID   string `json:"instance_id"`
	ModelID      string `json:"model_id"`
	DisplayName  string `json:"display_name"`
	ContextLimit int    `json:"context_limit"`
}

type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type ChatRequest struct {
	Messages    []Message
	Temperature *float64
	MaxTokens   *int
}

// WarmupProgress carries only presentation-safe engine state. In particular,
// worker addresses and credentials never cross the module boundary. Progress
// is an observed phase boundary; clients may interpolate it for display but
// must not treat it as a byte-accurate download percentage.
type WarmupProgress struct {
	OperationID   string  `json:"operation_id,omitempty"`
	InstanceID    string  `json:"instance_id"`
	Status        string  `json:"status"`
	Phase         string  `json:"phase"`
	Progress      float64 `json:"progress"`
	QueuePosition int     `json:"queue_position,omitempty"`
	Placement     string  `json:"placement,omitempty"`
	Message       string  `json:"message,omitempty"`
}

// Provider is implemented by EngineModule. Application modules never receive
// worker credentials and therefore cannot accidentally expose them to clients.
type Provider interface {
	ReadyLocalModels() []Model
	ResolveLocalModel(instanceID string) (Model, error)
	StreamLocalChat(ctx context.Context, instanceID string, request ChatRequest, emit func(string) error) (string, error)
}

// WarmupProvider is optional so existing Provider implementations and tests
// remain source compatible. Callers type-assert it when a stopped local model
// should be started and observed in the same request.
type WarmupProvider interface {
	EnsureLocalModelReady(ctx context.Context, instanceID string, emit func(WarmupProgress) error) (Model, error)
}
