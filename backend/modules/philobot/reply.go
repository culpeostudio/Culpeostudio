package philobot

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"

	"github.com/fillyengine/backend/internal/apimodels"
	"github.com/fillyengine/backend/internal/bus"
	"github.com/fillyengine/backend/internal/localinference"
)

// maxModelHistoryMessages caps how much conversation history is replayed to the
// model each turn. Without it, every message resends the full transcript, so
// answers get progressively slower (and eventually blow the context window) as
// a chat grows. Older facts are not lost: they are recalled from the memory
// module and injected via appendMemoryRecall. 24 messages ≈ 12 turns of verbatim
// context, which keeps recent coherence while staying fast.
const maxModelHistoryMessages = 24

// windowMessages returns at most max most-recent messages, preserving order.
func windowMessages(messages []chatMessage, max int) []chatMessage {
	if max <= 0 || len(messages) <= max {
		return append([]chatMessage{}, messages...)
	}
	return append([]chatMessage{}, messages[len(messages)-max:]...)
}

// projectPathForSessionLocked liefert den (getrimmten) Dateisystem-Pfad des
// Projekts, dem die Session zugeordnet ist, oder "" wenn keins/ohne Pfad. Aktiv
// gesetzt schaltet er die Datei-Tools frei. Muss mit gehaltenem m.mu aufgerufen
// werden (liest m.projects).
func (m *PhiloBotModule) projectPathForSessionLocked(userID string, session *philoBotSession) string {
	if session == nil {
		return ""
	}
	projectID := strings.TrimSpace(session.ProjectID)
	if projectID == "" {
		return ""
	}
	project := m.projects[projectID]
	if project == nil || project.UserID != userID {
		return ""
	}
	return strings.TrimSpace(project.Path)
}

func (m *PhiloBotModule) generateReply(ctx context.Context, userID, sessionID, message string, options chatOptions, onBotSelected func(botID, botName string), emit func(string) error, emitWarmup func(localinference.WarmupProgress) error, emitEvent func(eventType string, data interface{}) error) (string, string, string, *BotConfig, error) {
	m.mu.Lock()
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		m.mu.Unlock()
		return "", "", "", nil, errPhiloBotSessionNotFound
	}
	if options.EditMessageIndex >= 0 && options.EditMessageIndex <= len(session.Messages) {
		session.Messages = append([]chatMessage{}, session.Messages[:options.EditMessageIndex]...)
	}
	if options.Thinking != "" {
		session.Thinking = options.Thinking
	}
	if options.Style != "" {
		session.Style = options.Style
	}
	var finalBot BotConfig
	var err error
	if options.PreselectedBot != nil {
		finalBot = cloneBot(*options.PreselectedBot)
		session.ActiveBotID = finalBot.ID
	} else {
		finalBot, err = m.selectBotForSessionLocked(userID, message, session)
		if err != nil {
			m.mu.Unlock()
			return "", "", "", nil, err
		}
	}
	provider := session.SelectedProvider
	modelID := session.SelectedModelID
	modelRef := session.SelectedModelRef
	displayName := session.SelectedDisplayName
	contextLimit := session.SelectedContextLimit
	if provider == "" && modelID == "" {
		provider = session.Provider
		modelID = session.ModelID
		modelRef = session.ModelRef
		displayName = session.DisplayName
		contextLimit = session.ContextLimit
	}
	thinking := session.Thinking
	style := session.Style
	// project bindet Recall und Capture an das Projekt-Grid dieser Session (leer =
	// nutzerweit). Unter dem Lock lesen, weil die Session danach freigegeben wird.
	project := session.ProjectID
	// projectPath aktiviert die Datei-Tools: ist er gesetzt, arbeitet JEDER Bot im
	// Projekt-Ordner (Tool-Loop statt Single-Shot), strikt auf diesen Pfad begrenzt.
	projectPath := m.projectPathForSessionLocked(userID, session)
	history := windowMessages(session.Messages, maxModelHistoryMessages)
	m.mu.Unlock()

	// Announce the selected bot before validating its binding. The recovery UI
	// needs this identity even when a persisted binding is invalid, otherwise it
	// cannot offer the user a direct "Bindung aendern" action.
	if onBotSelected != nil {
		onBotSelected(finalBot.ID, finalBot.Name)
	}
	boundModel := false
	if finalBot.ModelBinding != nil {
		binding, bindingErr := normalizeModelBinding(finalBot.ModelBinding)
		if bindingErr != nil {
			return "", "", "", nil, bindingErr
		}
		boundModel = true
		provider = binding.Provider
		modelRef = binding.ModelRef
		displayName = binding.DisplayName
		contextLimit = 0
		if binding.Kind == "local" {
			modelID = binding.InstanceID
		} else {
			modelID = binding.ModelID
		}
	}
	if strings.TrimSpace(finalBot.ResponseStyle) != "" {
		style = normalizeResponseStyle(finalBot.ResponseStyle)
	}

	var reply string
	var createdBot *BotConfig
	providerEmit := emit
	systemPrompt := buildBotRuntimeSystemPrompt(finalBot, thinking, style)
	var botBuilderFilter *botBuilderStreamFilter
	if finalBot.ID == "botbuilder" {
		systemPrompt = m.botBuilderSystemPrompt(userID, systemPrompt)
		if emit != nil {
			botBuilderFilter = newBotBuilderStreamFilter(emit)
			providerEmit = botBuilderFilter.Emit
		}
	}
	systemPrompt = m.appendMemoryRecall(userID, project, message, systemPrompt)
	if provider == "" || modelID == "" {
		reply = "PhiloBot Stub-Antwort auf: " + message
		if providerEmit != nil {
			if err := providerEmit(reply); err != nil {
				return "", "", "", nil, err
			}
		}
		m.updateSessionEffectiveModel(userID, sessionID, provider, modelID, modelRef, displayName, contextLimit)
	} else {
		if apimodels.NormalizeProvider(provider) == localinference.ProviderLocal {
			localModel, err := m.ensureLocalModelReady(ctx, modelID, boundModel, emitWarmup)
			if err != nil {
				return "", "", "", nil, err
			}
			modelID = localModel.InstanceID
			modelRef = localinference.ProviderLocal + ":" + localModel.InstanceID
			displayName = localModel.DisplayName
			contextLimit = localModel.ContextLimit
			m.updateSessionEffectiveModel(userID, sessionID, provider, modelID, modelRef, displayName, contextLimit)
		}
		// The original user message enters the provider history only after warmup
		// succeeds, and StreamLocalChat is invoked exactly once.
		history = append(history, chatMessage{Role: "user", Content: message})
		modelStart := time.Now()
		if projectPath != "" {
			// Projekt-Kontext: Datei-Tool-Loop statt einmaligem Chat, damit der Bot
			// im Projekt-Ordner arbeiten kann. Roots strikt auf den Projekt-Pfad.
			// Der Permission-Broker erlaubt dem Nutzer, Zugriffe ausserhalb des
			// Projektpfads im laufenden Stream freizugeben oder abzulehnen; er
			// lebt nur fuer diesen Request und wird danach aufgeloest.
			broker := newPermissionBroker()
			m.mu.Lock()
			m.permissionBrokers[sessionID] = broker
			m.mu.Unlock()
			defer func() {
				m.mu.Lock()
				delete(m.permissionBrokers, sessionID)
				m.mu.Unlock()
				broker.Close()
			}()
			reply, err = m.runProjectToolLoop(ctx, provider, modelID, history, systemPrompt, thinking, []string{projectPath}, providerEmit, emitEvent, broker, sessionID)
		} else {
			emitReasoning := func(chunk string) error {
				if emitEvent == nil {
					return nil
				}
				return emitEvent("reasoning_delta", map[string]interface{}{"chunk": chunk})
			}
			// thinkFilter loest inline <think> Bloecke (Modelle ohne natives
			// Reasoning-Feld) aus dem sichtbaren Text heraus, BEVOR er providerEmit
			// (ggf. der BotBuilder-Filter) erreicht.
			thinkFilter := newThinkTagFilter(providerEmit, emitReasoning)
			reply, err = m.streamProviderChat(ctx, provider, modelID, history, systemPrompt, thinking, thinkFilter.Emit, emitReasoning)
			if err == nil {
				err = thinkFilter.Flush()
			}
		}
		// Modellzeit getrennt loggen: so ist im Log sofort erkennbar, dass die
		// wahrgenommene Langsamkeit an der Inferenz haengt, nicht am Recall.
		log.Printf("[philobot] Modell-Antwort in %s (provider=%s, model=%s, projekt-tools=%t)", time.Since(modelStart).Round(time.Millisecond), apimodels.NormalizeProvider(provider), modelID, projectPath != "")
		if err != nil {
			if boundModel && errors.Is(err, localinference.ErrNotFound) {
				return "", "", "", nil, fmt.Errorf("%w: %v", errModelBindingMissing, err)
			}
			var providerErr *providerChatHTTPError
			if boundModel && errors.As(err, &providerErr) && providerErr.StatusCode == http.StatusNotFound {
				return "", "", "", nil, fmt.Errorf("%w: %v", errModelBindingMissing, err)
			}
			return "", "", "", nil, err
		}
		if apimodels.NormalizeProvider(provider) != localinference.ProviderLocal {
			m.updateSessionEffectiveModel(userID, sessionID, provider, modelID, modelRef, displayName, contextLimit)
		}
	}
	if botBuilderFilter != nil {
		if err := botBuilderFilter.Flush(); err != nil {
			return "", "", "", nil, err
		}
	}
	// Ein evtl. <think> Block wurde bereits live als reasoning_delta gestreamt;
	// aus der gespeicherten/finalen Antwort entfernen, damit sie nicht als
	// unformatierter Rohtext in Verlauf und UI landet.
	reply = stripThinkBlocks(reply)
	if finalBot.ID == "botbuilder" {
		reply, createdBot = m.applyBotBuilderAutomation(userID, reply)
	}

	m.mu.Lock()
	session = m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		m.mu.Unlock()
		return "", "", "", nil, errPhiloBotSessionNotFound
	}
	session.Messages = append(session.Messages,
		chatMessage{Role: "user", Content: message},
		chatMessage{Role: "assistant", Content: reply, BotID: finalBot.ID, BotName: finalBot.Name},
	)
	m.mu.Unlock()
	m.persistSession(sessionID)

	bus.Get().Emit("philobot", bus.EventPhiloBotMessageSent, map[string]interface{}{
		"session_id": sessionID,
		"user_id":    userID,
		"project":    project,
		"message":    message,
		"reply":      reply,
		"provider":   provider,
		"model_id":   modelID,
		"bot_id":     finalBot.ID,
		"bot_name":   finalBot.Name,
		"thinking":   thinking,
		"style":      style,
	})
	return reply, finalBot.ID, finalBot.Name, createdBot, nil
}

func (m *PhiloBotModule) generateAgenticReply(ctx context.Context, userID, sessionID, message string, options chatOptions, onBotSelected func(botID, botName string), emit func(string, interface{}) error) (string, string, string, error) {
	m.mu.Lock()
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		m.mu.Unlock()
		return "", "", "", errPhiloBotSessionNotFound
	}
	if options.EditMessageIndex >= 0 && options.EditMessageIndex <= len(session.Messages) {
		session.Messages = append([]chatMessage{}, session.Messages[:options.EditMessageIndex]...)
	}
	session.Thinking = "agentic"
	session.AgenticMode = options.AgenticMode
	if len(options.AllowedRoots) > 0 {
		session.AllowedRoots = append([]string{}, options.AllowedRoots...)
	}

	finalBot, err := m.selectBotForSessionLocked(userID, message, session)
	if err != nil {
		m.mu.Unlock()
		return "", "", "", err
	}
	if finalBot.ModelBinding != nil {
		m.mu.Unlock()
		return m.generateBoundAgenticReply(ctx, userID, sessionID, message, options, finalBot, onBotSelected, emit)
	}
	// Gehoert die Session zu einem Projekt mit Pfad, laeuft die Arbeit ueber den
	// Datei-Tool-Loop (via generateReply) statt ueber den abgeschalteten Philox-
	// Pfad — so kann JEDER Bot im Projekt-Ordner arbeiten, egal welches
	// Thinking-Level gewaehlt ist.
	if m.projectPathForSessionLocked(userID, session) != "" {
		m.mu.Unlock()
		return m.generateBoundAgenticReply(ctx, userID, sessionID, message, options, finalBot, onBotSelected, emit)
	}
	if len(session.AllowedRoots) == 0 {
		session.AllowedRoots = append([]string{}, finalBot.AllowedRoots...)
	}
	roots := append([]string{}, session.AllowedRoots...)
	mode := session.AgenticMode
	if mode == "" {
		mode = "execute"
	}
	m.mu.Unlock()
	if m.philoxClient == nil {
		return "", "", "", fmt.Errorf("Philox gRPC Client ist nicht konfiguriert")
	}

	if onBotSelected != nil {
		onBotSelected(finalBot.ID, finalBot.Name)
	}

	reply, err := m.philoxClient.StreamAgentic(ctx, agenticStreamRequest{
		SessionID:    sessionID,
		Message:      message,
		Mode:         mode,
		AllowedRoots: roots,
		Context:      agenticContext(finalBot, options.ApprovePlan),
	}, emit)
	if err != nil {
		return reply, finalBot.ID, finalBot.Name, err
	}

	m.mu.Lock()
	session = m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		m.mu.Unlock()
		return "", "", "", errPhiloBotSessionNotFound
	}
	session.Messages = append(session.Messages,
		chatMessage{Role: "user", Content: message},
		chatMessage{Role: "assistant", Content: reply, BotID: finalBot.ID, BotName: finalBot.Name},
	)
	// project unter dem Lock lesen, damit die Chat-Memory im Projekt-Grid landet.
	project := session.ProjectID
	m.mu.Unlock()
	m.persistSession(sessionID)

	bus.Get().Emit("philobot", bus.EventPhiloBotMessageSent, map[string]interface{}{
		"session_id": sessionID,
		"user_id":    userID,
		"project":    project,
		"message":    message,
		"reply":      reply,
		"bot_id":     finalBot.ID,
		"bot_name":   finalBot.Name,
		"thinking":   "agentic",
		"mode":       mode,
	})
	return reply, finalBot.ID, finalBot.Name, nil
}

// A fixed model binding is authoritative even when the UI requests agentic
// thinking. Philox has its own model selection and therefore cannot preserve
// that guarantee; bound bots use the normal provider pipeline instead, while
// keeping agentic prompt/style settings and the same SSE event contract.
func (m *PhiloBotModule) generateBoundAgenticReply(ctx context.Context, userID, sessionID, message string, options chatOptions, finalBot BotConfig, onBotSelected func(botID, botName string), emit func(string, interface{}) error) (string, string, string, error) {
	delegated := options
	delegated.EditMessageIndex = -1 // generateAgenticReply already applied the edit atomically.
	selected := cloneBot(finalBot)
	delegated.PreselectedBot = &selected

	var textEmitter *streamingTextEmitter
	var emitText func(string) error
	var emitWarmup func(localinference.WarmupProgress) error
	var emitEvent func(eventType string, data interface{}) error
	if emit != nil {
		textEmitter = newStreamingTextEmitter(func(character string) error {
			return emit("text_delta", fiber.Map{"chunk": character})
		})
		emitText = textEmitter.Emit
		emitWarmup = func(progress localinference.WarmupProgress) error {
			return emit("model_warmup", progress)
		}
		// Datei-Tool-Events (im Projekt-Kontext) an denselben SSE-Kanal; vorher
		// gepufferten Text flushen, damit die Reihenfolge stimmt.
		emitEvent = func(eventType string, data interface{}) error {
			if textEmitter != nil {
				if err := textEmitter.Flush(); err != nil {
					return err
				}
			}
			return emit(eventType, data)
		}
	}

	reply, botID, botName, _, err := m.generateReply(ctx, userID, sessionID, message, delegated, onBotSelected, emitText, emitWarmup, emitEvent)
	if err == nil && textEmitter != nil {
		err = textEmitter.Flush()
	}
	if err == nil && emit != nil {
		err = emit("done", fiber.Map{
			"session_id":     sessionID,
			"thinking_level": "agentic",
			"response_style": m.responseStyleForBot(userID, botID, options.Style),
		})
	}
	return reply, botID, botName, err
}

func (m *PhiloBotModule) selectBotForSessionLocked(userID, message string, session *philoBotSession) (BotConfig, error) {
	if session.LockedBotID != "" {
		bot, ok := m.botStore.GetBotForUser(userID, session.LockedBotID)
		if !ok {
			return BotConfig{}, errPhiloBotBotNotFound
		}
		session.ActiveBotID = bot.ID
		return bot, nil
	}
	matchedBot, matchedByKeyword := m.botStore.MatchBotByKeywordForUser(userID, message)
	if matchedByKeyword {
		session.ActiveBotID = matchedBot.ID
		return matchedBot, nil
	}
	if session.ActiveBotID != "" {
		if active, ok := m.botStore.GetBotForUser(userID, session.ActiveBotID); ok {
			return active, nil
		}
	}
	session.ActiveBotID = matchedBot.ID
	return matchedBot, nil
}

func (m *PhiloBotModule) ensureLocalModelReady(ctx context.Context, instanceID string, binding bool, emit func(localinference.WarmupProgress) error) (localinference.Model, error) {
	if m.localModels == nil {
		return localinference.Model{}, localinference.ErrWorkerUnavailable
	}
	model, err := m.localModels.ResolveLocalModel(instanceID)
	if err == nil {
		return model, nil
	}
	if errors.Is(err, localinference.ErrNotFound) && binding {
		return localinference.Model{}, fmt.Errorf("%w: %v", errModelBindingMissing, err)
	}
	if !errors.Is(err, localinference.ErrNotReady) {
		return localinference.Model{}, err
	}
	warmer, ok := m.localModels.(localinference.WarmupProvider)
	if !ok {
		return localinference.Model{}, err
	}
	model, err = warmer.EnsureLocalModelReady(ctx, instanceID, emit)
	if err != nil && binding && errors.Is(err, localinference.ErrNotFound) {
		return localinference.Model{}, fmt.Errorf("%w: %v", errModelBindingMissing, err)
	}
	return model, err
}

func (m *PhiloBotModule) updateSessionEffectiveModel(userID, sessionID, provider, modelID, modelRef, displayName string, contextLimit int) {
	m.mu.Lock()
	defer m.mu.Unlock()
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		return
	}
	session.Provider = provider
	session.ModelID = modelID
	session.ModelRef = modelRef
	session.DisplayName = displayName
	session.ContextLimit = contextLimit
}
