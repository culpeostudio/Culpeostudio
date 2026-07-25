package philox

// MemoryRecorder verbindet Philox mit dem Projektgedaechtnis (modules/memory).
// Die Implementierung muss fehlertolerant sein: Philox laeuft ohne angebundenes
// Memory unveraendert weiter, alle Aufrufe sind Fire-and-Forget bis auf
// PhiloxPromptContext, das den fertig gerenderten Injektions-Prompt liefert.
type MemoryRecorder interface {
	PhiloxSessionStarted(sessionID string, goals []string)
	PhiloxPromptContext(sessionID, prompt string) string
	PhiloxToolObserved(sessionID, toolName string, arguments map[string]interface{}, resultPreview string, success bool)
	PhiloxReplyFinished(sessionID, reply string)
}

type NoopMemoryRecorder struct{}

func (NoopMemoryRecorder) PhiloxSessionStarted(sessionID string, goals []string) {}
func (NoopMemoryRecorder) PhiloxPromptContext(sessionID, prompt string) string   { return "" }
func (NoopMemoryRecorder) PhiloxToolObserved(sessionID, toolName string, arguments map[string]interface{}, resultPreview string, success bool) {
}
func (NoopMemoryRecorder) PhiloxReplyFinished(sessionID, reply string) {}

// SetMemory haengt das Projektgedaechtnis an. Wird in cmd/server verdrahtet.
func (m *PhiloxModule) SetMemory(recorder MemoryRecorder) {
	m.memory = recorder
}
