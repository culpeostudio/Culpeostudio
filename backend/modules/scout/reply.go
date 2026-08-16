package scout

import (
	"context"
	"errors"
	"fmt"
	"github.com/culpeohq/backend/modules/scout/bots"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/culpeohq/backend/internal/apimodels"
	"github.com/culpeohq/backend/internal/bus"
	"github.com/culpeohq/backend/internal/localinference"
	"github.com/culpeohq/backend/internal/providerconn"
	"github.com/culpeohq/backend/modules/spark"
)

const maxModelHistoryMessages = 24

func windowMessages(messages []chatMessage, max int) []chatMessage {
	if max <= 0 || len(messages) <= max {
		return append([]chatMessage{}, messages...)
	}
	return append([]chatMessage{}, messages[len(messages)-max:]...)
}

func (m *ScoutModule) generateReply(ctx context.Context, userID, sessionID, message string, options chatOptions, onBotSelected func(botID, botName string), emit func(string) error, emitWarmup func(localinference.WarmupProgress) error, emitEvent func(eventType string, data interface{}) error) (string, string, string, *bots.Config, error) {
	m.mu.Lock()
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		m.mu.Unlock()
		return "", "", "", nil, errScoutSessionNotFound
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
	var finalBot bots.Config
	var err error
	if options.PreselectedBot != nil {
		finalBot = bots.CloneBot(*options.PreselectedBot)
		session.ActiveBotID = finalBot.ID
	} else {
		finalBot, err = m.selectBotForSessionLocked(userID, message, session)
		if err != nil {
			m.mu.Unlock()
			return "", "", "", nil, err
		}
	}
	provider := session.SelectedProvider
	connectionID := session.SelectedConnectionID
	modelID := session.SelectedModelID
	modelRef := session.SelectedModelRef
	displayName := session.SelectedDisplayName
	contextLimit := session.SelectedContextLimit
	modelContextLimit := session.ModelContextLimit
	if provider == "" && modelID == "" {
		provider = session.Provider
		connectionID = session.ConnectionID
		modelID = session.ModelID
		modelRef = session.ModelRef
		displayName = session.DisplayName
		contextLimit = session.ContextLimit
	}
	thinking := session.Thinking
	style := session.Style

	project := session.ProjectID

	projectPath := m.projectPathForSessionLocked(userID, session)
	m.mu.Unlock()

	if onBotSelected != nil {
		onBotSelected(finalBot.ID, finalBot.Name)
	}
	boundModel := false
	if finalBot.ModelBinding != nil {
		binding, bindingErr := bots.NormalizeModelBinding(finalBot.ModelBinding)
		if bindingErr != nil {
			return "", "", "", nil, bindingErr
		}
		boundModel = true
		provider = binding.Provider
		connectionID = binding.ConnectionID
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
		style = bots.NormalizeResponseStyle(finalBot.ResponseStyle)
	}

	var reply string
	var createdBot *bots.Config
	var budget contextBudget
	// Set by the turn closure below when the model was still cut off after its
	// last continuation, so the finished reply can say so.
	truncatedTurn := false
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
	if connectionID != "" && modelID != "" {
		connection, active, connectionErr := m.configuredConnectionForChat(userID, connectionID, modelID)
		if connectionErr != nil {
			if boundModel && (errors.Is(connectionErr, providerconn.ErrNotFound) || errors.Is(connectionErr, providerconn.ErrActiveModelMissing)) {
				return "", "", "", nil, fmt.Errorf("%w: %v", errModelBindingMissing, connectionErr)
			}
			return "", "", "", nil, connectionErr
		}
		provider = configuredProviderDisplayName(connection)
		modelRef = active.ModelRef
		displayName = active.DisplayName
	}
	if (provider == "" && connectionID == "") || modelID == "" {
		reply = "Scout Stub-Antwort auf: " + message
		if providerEmit != nil {
			if err := providerEmit(reply); err != nil {
				return "", "", "", nil, err
			}
		}
		m.updateSessionEffectiveModel(userID, sessionID, provider, connectionID, modelID, modelRef, displayName, contextLimit, modelContextLimit)
	} else {
		if apimodels.NormalizeProvider(provider) == localinference.ProviderLocal {
			connectionID = ""
			localModel, err := m.ensureLocalModelReady(ctx, modelID, boundModel, emitWarmup)
			if err != nil {
				return "", "", "", nil, err
			}
			modelID = localModel.InstanceID
			modelRef = localinference.ProviderLocal + ":" + localModel.InstanceID
			displayName = localModel.DisplayName
			contextLimit = localModel.ContextLimit
			modelContextLimit = localModel.ModelContextLimit
			m.updateSessionEffectiveModel(userID, sessionID, provider, connectionID, modelID, modelRef, displayName, contextLimit, modelContextLimit)
		}

		// Everything the model is asked with has to fit its window, so the
		// window is resolved first and the older turns are folded into a
		// summary when they no longer do.
		budget = m.resolveContextBudget(userID, provider, connectionID, modelID, contextLimit)
		compacted := m.compactSessionIfNeeded(ctx, userID, sessionID, budget, provider, connectionID, modelID)
		summary, history := m.modelHistory(userID, sessionID)
		systemPrompt = appendConversationSummary(systemPrompt, summary)
		emitContextUsage(emitEvent, m.contextUsageForSession(userID, sessionID, budget, compacted))

		history = append(history, chatMessage{Role: "user", Content: message})
		modelStart := time.Now()
		if m.agent == nil {
			return "", "", "", nil, errAgentUnavailable
		}

		emitReasoning := func(chunk string) error {
			if emitEvent == nil {
				return nil
			}
			return emitEvent("reasoning_delta", map[string]interface{}{"chunk": chunk})
		}
		// How long the answer may get is decided per turn, because it depends on
		// how much of the window the prompt already occupies. Each agent step
		// re-resolves it against its own conversation for the same reason.
		turn := func(convo []spark.Message, prompt string, filterEmit func(string) error) (string, error) {
			convoMessages := fromAgentMessages(convo)
			promptTokens := estimateTokens(prompt) + estimateMessageTokens(convoMessages)
			output := m.resolveOutputBudget(userID, provider, connectionID, modelID,
				options.OutputLevel, budget, promptTokens)

			thinkFilter := newThinkTagFilter(filterEmit, emitReasoning)
			out, cutOff, streamErr := m.streamTurnWithContinuation(ctx, providerTurn{
				UserID:          userID,
				Provider:        provider,
				ConnectionID:    connectionID,
				ModelID:         modelID,
				Messages:        convoMessages,
				SystemPrompt:    prompt,
				ThinkingLevel:   thinking,
				ReasoningEffort: options.ReasoningEffort,
				MaxOutputTokens: output.MaxTokens,
				Emit:            thinkFilter.Emit,
				EmitReasoning:   emitReasoning,
			})
			if streamErr == nil {
				streamErr = thinkFilter.Flush()
			}
			// Assigned rather than latched: an agent run takes several turns and
			// only the last one produces the answer the user reads, so an early
			// step that had to be continued must not put a truncation notice on
			// a reply that finished cleanly.
			truncatedTurn = cutOff
			return out, streamErr
		}

		reply, err = m.agent.Run(ctx, spark.Request{
			UserID:       userID,
			SessionID:    sessionID,
			Message:      message,
			History:      toAgentMessages(history),
			SystemPrompt: systemPrompt,
			ProjectPath:  projectPath,
			Planning:     options.Planning,
			ApprovePlan:  options.ApprovePlan,
			EmitText:     providerEmit,
			EmitEvent:    emitEvent,
			// Without this the agent loop cannot know how much room it has, and
			// its tool results grow until the provider refuses the request.
			Budget: spark.ContextBudget{
				LimitTokens: budget.LimitTokens,
				Source:      budget.Source,
				Compactions: m.sessionCompactions(userID, sessionID),
			},
		}, turn)

		log.Printf("[scout] Modell-Antwort in %s (provider=%s, model=%s, projekt-tools=%t)", time.Since(modelStart).Round(time.Millisecond), apimodels.NormalizeProvider(provider), modelID, projectPath != "")
		if err != nil {
			if boundModel && errors.Is(err, localinference.ErrNotFound) {
				return "", "", "", nil, fmt.Errorf("%w: %v", errModelBindingMissing, err)
			}
			if boundModel && (errors.Is(err, providerconn.ErrNotFound) || errors.Is(err, providerconn.ErrActiveModelMissing)) {
				return "", "", "", nil, fmt.Errorf("%w: %v", errModelBindingMissing, err)
			}
			var providerErr *providerChatHTTPError
			if boundModel && errors.As(err, &providerErr) && providerErr.StatusCode == http.StatusNotFound {
				return "", "", "", nil, fmt.Errorf("%w: %v", errModelBindingMissing, err)
			}
			return "", "", "", nil, err
		}
		if apimodels.NormalizeProvider(provider) != localinference.ProviderLocal {
			m.updateSessionEffectiveModel(userID, sessionID, provider, connectionID, modelID, modelRef, displayName, contextLimit, modelContextLimit)
		}
	}
	if botBuilderFilter != nil {
		if err := botBuilderFilter.Flush(); err != nil {
			return "", "", "", nil, err
		}
	}

	reply = stripThinkBlocks(reply)
	if finalBot.ID == "botbuilder" {
		reply, createdBot = m.applyBotBuilderAutomation(userID, reply)
	}
	if truncatedTurn {
		reply = truncationNotice(reply)
	}

	m.mu.Lock()
	session = m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		m.mu.Unlock()
		return "", "", "", nil, errScoutSessionNotFound
	}
	session.Messages = append(session.Messages,
		chatMessage{Role: "user", Content: message},
		chatMessage{Role: "assistant", Content: reply, BotID: finalBot.ID, BotName: finalBot.Name},
	)
	m.mu.Unlock()
	m.persistSession(sessionID)

	// The answer counts against the window too, so the meter is corrected once
	// the turn is stored rather than left showing the pre-reply reading.
	if budget.LimitTokens > 0 {
		emitContextUsage(emitEvent, m.contextUsageForSession(userID, sessionID, budget, false))
	}

	bus.Get().Emit("scout", bus.EventScoutMessageSent, map[string]interface{}{
		"session_id":    sessionID,
		"user_id":       userID,
		"project":       project,
		"message":       message,
		"reply":         reply,
		"provider":      provider,
		"connection_id": connectionID,
		"model_id":      modelID,
		"bot_id":        finalBot.ID,
		"bot_name":      finalBot.Name,
		"thinking":      thinking,
		"style":         style,
	})
	return reply, finalBot.ID, finalBot.Name, createdBot, nil
}

func (m *ScoutModule) generateAgenticReply(ctx context.Context, userID, sessionID, message string, options chatOptions, onBotSelected func(botID, botName string), emit func(string, interface{}) error) (string, string, string, error) {
	m.mu.Lock()
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		m.mu.Unlock()
		return "", "", "", errScoutSessionNotFound
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
	if len(session.AllowedRoots) == 0 {
		session.AllowedRoots = append([]string{}, finalBot.AllowedRoots...)
	}
	m.mu.Unlock()

	return m.generateBoundAgenticReply(ctx, userID, sessionID, message, options, finalBot, onBotSelected, emit)
}

func (m *ScoutModule) generateBoundAgenticReply(ctx context.Context, userID, sessionID, message string, options chatOptions, finalBot bots.Config, onBotSelected func(botID, botName string), emit func(string, interface{}) error) (string, string, string, error) {
	delegated := options
	delegated.EditMessageIndex = -1
	selected := bots.CloneBot(finalBot)
	delegated.PreselectedBot = &selected

	var textEmitter *streamingTextEmitter
	var emitText func(string) error
	var emitWarmup func(localinference.WarmupProgress) error
	var emitEvent func(eventType string, data interface{}) error
	if emit != nil {
		textEmitter = newStreamingTextEmitter(func(character string) error {
			return emit("text_delta", map[string]interface{}{"chunk": character})
		})
		emitText = textEmitter.Emit
		emitWarmup = func(progress localinference.WarmupProgress) error {
			return emit("model_warmup", progress)
		}

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
		err = emit("done", map[string]interface{}{
			"session_id":     sessionID,
			"thinking_level": "agentic",
			"response_style": m.responseStyleForBot(userID, botID, options.Style),
		})
	}
	return reply, botID, botName, err
}

func (m *ScoutModule) selectBotForSessionLocked(userID, message string, session *scoutSession) (bots.Config, error) {
	if session.LockedBotID != "" {
		bot, ok := m.botStore.GetBotForUser(userID, session.LockedBotID)
		if !ok {
			return bots.Config{}, errScoutBotNotFound
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

func (m *ScoutModule) ensureLocalModelReady(ctx context.Context, instanceID string, binding bool, emit func(localinference.WarmupProgress) error) (localinference.Model, error) {
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

func (m *ScoutModule) updateSessionEffectiveModel(userID, sessionID, provider, connectionID, modelID, modelRef, displayName string, contextLimit, modelContextLimit int) {
	m.mu.Lock()
	defer m.mu.Unlock()
	session := m.sessions[sessionID]
	if session == nil || session.UserID != userID {
		return
	}
	session.Provider = provider
	session.ConnectionID = connectionID
	session.ModelID = modelID
	session.ModelRef = modelRef
	session.DisplayName = displayName
	session.ContextLimit = contextLimit
	session.ModelContextLimit = modelContextLimit
}
