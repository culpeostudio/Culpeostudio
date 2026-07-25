package memory

import (
	"sort"
	"strings"
	"sync"

	"github.com/fillyengine/backend/internal/memorytoken"
)

func (s *Service) BuildContext(sessionID, query string, limit int) (*ContextEnvelope, error) {
	return s.BuildContextForUser(s.defaultUserID, sessionID, query, limit)
}

func (s *Service) BuildContextForUser(userID, sessionID, query string, limit int) (*ContextEnvelope, error) {
	userID = normalizeUserID(userID, s.defaultUserID)
	session, err := s.repo.GetSession(userID, strings.TrimSpace(sessionID))
	if err != nil {
		return nil, err
	}
	if limit <= 0 {
		limit = defaultContextLimit
	}
	query = s.resolveContextQuery(session, query)
	results, err := s.Search(query, SearchFilters{
		UserID:  userID,
		Project: session.Project,
		Source:  session.Source,
		Limit:   limit,
	})
	if err != nil {
		return nil, err
	}
	observations := make([]Observation, 0, limit)
	memoryDocs := make([]CompressedMemory, 0, limit)
	observationIDs := make([]string, 0, limit)
	for _, result := range results {
		switch result.Kind {
		case "memory":
			for _, memoryItem := range session.Memories {
				if memoryItem.ID == result.RefID {
					memoryDocs = append(memoryDocs, memoryItem)
					break
				}
			}
		case "observation":
			observationIDs = append(observationIDs, result.RefID)
		}
	}
	if len(observationIDs) > 0 {
		observations, err = s.repo.GetObservationsByIDs(userID, observationIDs)
		if err != nil {
			return nil, err
		}
	}
	summary, err := s.repo.GetLatestSummary(userID, session.ID)
	if err != nil {
		return nil, err
	}
	injection := renderInjectionPrompt(query, session.Goals, summary, memoryDocs, observations, s.contextBudget)
	return &ContextEnvelope{
		SessionID:       session.ID,
		Query:           query,
		BudgetTokens:    s.contextBudget,
		UsedTokens:      memorytoken.Estimate(injection),
		InjectionPrompt: injection,
		Memories:        memoryDocs,
		Observations:    observations,
		Summary:         summary,
		ToolHints:       defaultToolDefinitions(),
	}, nil
}

// BuildUserContext assembles a cross-session memory recall for a user. Unlike
// BuildContextForUser it is not tied to a single session: it searches the
// user's entire memory (every session) for the query and renders a compact
// recall block from the matching observations. Chat surfaces such as PhiloBot
// use it to recall durable user facts (e.g. the user's name) in a brand-new
// conversation, where no session-scoped memory exists yet. The rendered block
// intentionally omits the memory-tool hints, because plain chat has no tools to
// call. An empty query yields an empty envelope rather than an error, and a
// user without any stored memory simply gets an empty InjectionPrompt.
func (s *Service) BuildUserContext(userID, query string, limit int) (*ContextEnvelope, error) {
	return s.BuildScopedContext(userID, "", query, limit)
}

// BuildScopedContext ist BuildUserContext mit optionalem Projekt-Grid. Ist
// project gesetzt, werden die generelle und die project_data-Suche auf genau
// dieses Projekt eingeschraenkt ("Grid") — Wissen aus anderen Projekten bleibt
// aussen vor. Die user_data-Suche bleibt bewusst ungescoped, damit dauerhafte
// Nutzer-Fakten (Name, Vorlieben) in jedem Projekt-Chat erinnert werden. Ein
// leeres project reproduziert exakt das nutzerweite Verhalten (alle Projekte).
func (s *Service) BuildScopedContext(userID, project, query string, limit int) (*ContextEnvelope, error) {
	userID = normalizeUserID(userID, s.defaultUserID)
	project = strings.TrimSpace(project)
	query = strings.TrimSpace(query)
	if limit <= 0 {
		limit = defaultContextLimit
	}
	envelope := &ContextEnvelope{
		Query:        query,
		BudgetTokens: s.contextBudget,
		Observations: []Observation{},
	}
	if query == "" {
		return envelope, nil
	}
	// Recall darf nicht daran scheitern, dass die Query in einen anderen Layer
	// routet als der gespeicherte Fakt (routeIntent schiebt "ich/mein"-Fragen
	// nach user_data). Wir suchen daher die natuerliche (geroutete) Query plus
	// beide Layer explizit. Ein groesserer Kandidaten-Pool als die Zahl der final
	// gerenderten Zeilen gibt Reserve, weil renderUserRecall Anti-Fakten und
	// Duplikate herausfiltert.
	pool := limit
	if pool < recallCandidatePool {
		pool = recallCandidatePool
	}
	// Die drei Layer-Suchen sind unabhaengig und laufen parallel (SQLite-Reads
	// sind nebenlaeufig sicher). Projekt-Scope greift nur auf die generelle und
	// die project_data-Suche; user_data bleibt ungescoped (globale Nutzer-Fakten).
	jobs := []SearchFilters{
		{UserID: userID, Project: project, Limit: pool},
		{UserID: userID, Layer: LayerUserData, Limit: pool},
		{UserID: userID, Project: project, Layer: LayerProjectData, Limit: pool},
	}
	resultsByJob := make([][]SearchResult, len(jobs))
	errsByJob := make([]error, len(jobs))
	var wg sync.WaitGroup
	for i, filters := range jobs {
		wg.Add(1)
		go func(i int, filters SearchFilters) {
			defer wg.Done()
			resultsByJob[i], errsByJob[i] = s.Search(query, filters)
		}(i, filters)
	}
	wg.Wait()
	for _, err := range errsByJob {
		if err != nil {
			return nil, err
		}
	}
	// Global nach dem (schon recency-/typ-gewichteten) Search-Score ranken statt
	// die Layer-Ergebnisse bloss aneinanderzuhaengen. So gewinnt der beste
	// Treffer ueber alle Layer hinweg – der Score ist zwischen den Suchen
	// vergleichbar, weil dieselbe Formel greift.
	bestByRef := make(map[string]SearchResult)
	for _, results := range resultsByJob {
		for _, result := range results {
			if result.Kind != "observation" {
				continue
			}
			if existing, ok := bestByRef[result.RefID]; !ok || result.Score > existing.Score {
				bestByRef[result.RefID] = result
			}
		}
	}
	ranked := make([]SearchResult, 0, len(bestByRef))
	for _, result := range bestByRef {
		ranked = append(ranked, result)
	}
	sort.Slice(ranked, func(i, j int) bool { return ranked[i].Score > ranked[j].Score })
	observationIDs := make([]string, 0, pool)
	for _, result := range ranked {
		observationIDs = append(observationIDs, result.RefID)
		if len(observationIDs) >= pool {
			break
		}
	}
	if len(observationIDs) > 0 {
		observations, err := s.repo.GetObservationsByIDs(userID, observationIDs)
		if err != nil {
			return nil, err
		}
		// GetObservationsByIDs erhaelt die Rang-Reihenfolge nicht zwingend –
		// wieder in Score-Reihenfolge bringen, damit der Render die besten
		// Fakten zuerst sieht.
		byID := make(map[string]Observation, len(observations))
		for _, obs := range observations {
			byID[obs.ID] = obs
		}
		ordered := make([]Observation, 0, len(observationIDs))
		for _, id := range observationIDs {
			if obs, ok := byID[id]; ok {
				ordered = append(ordered, obs)
			}
		}
		envelope.Observations = ordered
	}
	injection := renderUserRecall(envelope.Observations, s.contextBudget)
	envelope.InjectionPrompt = injection
	envelope.UsedTokens = memorytoken.Estimate(injection)
	return envelope, nil
}

// renderUserRecall renders at most userRecallMaxLines observations as compact
// bullet points within an approximate token budget. It shares the soft-budget
// idea of renderInjectionPrompt but drops the tool hints and session sections:
// the output is meant to be appended to a plain-chat system prompt as recalled
// facts, not fed to a tool-using agent.
func renderUserRecall(observations []Observation, budgetTokens int) string {
	if len(observations) == 0 {
		return ""
	}
	remaining := budgetTokens
	seen := make(map[string]struct{})
	lines := make([]string, 0, userRecallMaxLines)
	for _, observation := range observations {
		if len(lines) >= userRecallMaxLines {
			break
		}
		line := strings.TrimSpace(observation.Narrative)
		if line == "" {
			line = strings.TrimSpace(fallbackTitle(observation.Title, observation.Type))
		}
		if line == "" || isIgnoranceRecall(line) {
			continue
		}
		key := recallDedupKey(line)
		if _, ok := seen[key]; ok {
			continue
		}
		preview := previewText(line, 200)
		cost := memorytoken.Estimate(preview)
		if cost > remaining {
			break
		}
		seen[key] = struct{}{}
		remaining -= cost
		lines = append(lines, "- "+preview)
	}
	return strings.Join(lines, "\n")
}

// isIgnoranceRecall filtert Q&A-Paare heraus, in denen der Assistent selbst
// angibt, etwas NICHT zu wissen ("Ich weiß deinen Namen leider nicht"). Solche
// Anti-Fakten stammen typischerweise aus Unterhaltungen, in denen der Recall
// noch gar nicht aktiv war; im Kontext wuerden sie das Modell aktiv zur
// falschen Antwort verleiten. Die Liste ist bewusst eng gehalten, um echte
// Inhalte nicht faelschlich zu unterdruecken.
func isIgnoranceRecall(narrative string) bool {
	lower := strings.ToLower(narrative)
	for _, phrase := range []string{
		"weiß leider nicht",
		"weiss leider nicht",
		"leider nicht, wie",
		"kenne deinen namen",
		"ich weiß nicht, wie",
		"ich weiss nicht, wie",
		"keine information",
		"don't know",
		"do not know",
		"i have no information",
	} {
		if strings.Contains(lower, phrase) {
			return true
		}
	}
	return false
}

// recallDedupKey normalisiert eine Beobachtung auf ihren Anfang, damit mehrfach
// gespeicherte (nahezu) identische Paare den Recall nicht mit Wiederholungen
// fluten.
func recallDedupKey(narrative string) string {
	return strings.Join(strings.Fields(strings.ToLower(previewText(narrative, 160))), " ")
}
