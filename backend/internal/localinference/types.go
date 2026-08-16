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
	InstanceID  string `json:"instance_id"`
	ModelID     string `json:"model_id"`
	DisplayName string `json:"display_name"`
	// ContextLimit is what this instance was actually started with, which the
	// engine's memory plan routinely sets below what the model could do.
	ContextLimit int `json:"context_limit"`
	// ModelContextLimit is what the model itself would allow. Reporting both is
	// what lets a chat explain a window that looks smaller than the model's
	// advertised one instead of looking like it miscounted.
	ModelContextLimit int `json:"model_context_limit,omitempty"`
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

type Provider interface {
	ReadyLocalModels() []Model
	ResolveLocalModel(instanceID string) (Model, error)
	StreamLocalChat(ctx context.Context, instanceID string, request ChatRequest, emit func(string) error) (string, error)
}

// FinishReasonProvider additionally reports why the model stopped, which is how
// a caller tells an answer that ended from one that ran into its output limit
// and could be continued. It is optional on purpose: a Provider that does not
// implement it simply never reports a truncated reply, which is the behaviour
// everything had before.
type FinishReasonProvider interface {
	StreamLocalChatWithReason(ctx context.Context, instanceID string, request ChatRequest, emit func(string) error) (reply string, finishReason string, err error)
}

type WarmupProvider interface {
	EnsureLocalModelReady(ctx context.Context, instanceID string, emit func(WarmupProgress) error) (Model, error)
}
