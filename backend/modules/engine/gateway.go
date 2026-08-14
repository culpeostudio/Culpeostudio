package engine

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/http/httptrace"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

type gatewayModel struct {
	ID string
	// Alias is the served model name. It is what a user wants to write into an
	// SDK config, rather than the generated instance ID.
	Alias string
	Ready bool
	// Autostart is the per-instance opt-in for warming this model up when a
	// request arrives for it.
	Autostart          bool
	BaseURL            string
	WorkerSecret       string
	ContextLimit       int
	CreatedAt          time.Time
	Runtime            string
	GenerationDefaults map[string]interface{}
}

// gatewayUsageSample is what one proxied request measured. The gateway is a
// byte proxy, so these come from the OpenAI usage object the worker itself
// reports rather than from counting chunks.
type gatewayUsageSample struct {
	CompletedAt       time.Time
	GenerationSeconds float64
	TTFTSeconds       float64
	OutputTokens      int
}

type gatewayDependencies struct {
	lookup      func(string) (gatewayModel, bool)
	list        func() []gatewayModel
	acquire     func(context.Context, string) (func(), error)
	ensureReady func(context.Context, string) error
	recordUsage func(string, gatewayUsageSample)
}

type localGateway struct {
	keys   *engineKeyStore
	deps   gatewayDependencies
	client *http.Client
	// allowNetwork lets the gateway bind beyond loopback without the
	// environment variable. Node mode sets it: a node exists to serve its
	// models to one paired Studio over a tunnel, so binding to its tunnel
	// address is the configuration rather than an override of it.
	allowNetwork bool

	server   *http.Server
	listener net.Listener
}

func newLocalGateway(keys *engineKeyStore, deps gatewayDependencies) *localGateway {
	return &localGateway{keys: keys, deps: deps, client: newLoopbackHTTPClient()}
}

func (g *localGateway) lookup(name string) (gatewayModel, bool) {
	if g.deps.lookup == nil {
		return gatewayModel{}, false
	}
	return g.deps.lookup(name)
}

func (g *localGateway) list() []gatewayModel {
	if g.deps.list == nil {
		return nil
	}
	return g.deps.list()
}

func newLoopbackHTTPClient() *http.Client {
	return &http.Client{Transport: &http.Transport{

		Proxy: nil, DisableCompression: true, MaxIdleConnsPerHost: 16,
	}}
}

func (g *localGateway) start(address string) (string, error) {
	if strings.TrimSpace(address) == "" {
		address = "127.0.0.1:8091"
	}
	host, _, err := net.SplitHostPort(address)
	if err != nil {
		return "", fmt.Errorf("ungueltige Engine-Gateway-Adresse: %w", err)
	}
	ip := net.ParseIP(host)
	if host != "localhost" && (ip == nil || !ip.IsLoopback()) {
		// Serving beyond loopback exposes every model on this machine to the
		// network, so it takes a deliberate opt-in rather than just an address.
		// The keys are then the only thing between the network and the models,
		// which is why an unkeyed gateway refuses outright.
		if !g.allowNetwork && strings.TrimSpace(os.Getenv("ENGINE_GATEWAY_ALLOW_NETWORK")) != "1" {
			return "", fmt.Errorf("das Engine-Gateway ist auf Loopback beschraenkt; fuer %s muss ENGINE_GATEWAY_ALLOW_NETWORK=1 gesetzt sein", address)
		}
		if g.keys == nil || len(g.keys.list()) == 0 {
			return "", fmt.Errorf("ein Engine-Gateway im Netzwerk benoetigt mindestens einen Zugriffsschluessel; bitte zuerst einen Schluessel anlegen")
		}
		log.Printf("[engine-gateway] serving on %s, which is reachable from the network; every request needs a valid engine key", address)
	}
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return "", err
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/v1/models", g.handleModels)
	mux.HandleFunc("/v1/chat/completions", g.handleInference)
	mux.HandleFunc("/v1/completions", g.handleInference)
	mux.HandleFunc("/v1/embeddings", g.handleInference)
	mux.HandleFunc("/v1/rerank", g.handleInference)
	mux.HandleFunc("/health", g.handleHealth)
	g.listener = listener
	g.server = &http.Server{
		Handler:           mux,
		ReadHeaderTimeout: 10 * time.Second,
		IdleTimeout:       2 * time.Minute,
		MaxHeaderBytes:    1 << 20,
	}
	go func() { _ = g.server.Serve(listener) }()
	return listener.Addr().String(), nil
}

func (g *localGateway) shutdown(ctx context.Context) error {
	if g.server == nil {
		return nil
	}
	return g.server.Shutdown(ctx)
}

func (g *localGateway) handleModels(w http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodGet {
		writeOpenAIError(w, http.StatusMethodNotAllowed, "method_not_allowed", "Nur GET wird unter diesem Endpoint unterstuetzt.", "")
		return
	}
	plaintext := bearerToken(request.Header.Get("Authorization"))
	scope, ok := g.keys.authorizedScope(plaintext)
	if !ok {
		writeOpenAIError(w, http.StatusUnauthorized, "invalid_api_key", "Ungueltiger oder widerrufener Engine-Schluessel.", "")
		return
	}
	type modelObject struct {
		ID      string `json:"id"`
		Object  string `json:"object"`
		Created int64  `json:"created"`
		OwnedBy string `json:"owned_by"`
	}
	data := []modelObject{}
	for _, model := range g.list() {
		if len(scope) > 0 && !containsString(scope, model.ID) {
			continue
		}
		// An instance that is not loaded but may be started on demand is still
		// something a client can ask for, so it belongs in the list. One that
		// is neither ready nor startable does not.
		if !model.Ready && !model.Autostart {
			continue
		}
		data = append(data, modelObject{ID: model.ID, Object: "model", Created: model.CreatedAt.Unix(), OwnedBy: "culpeostudio/" + model.Runtime})
		// The alias is listed as its own entry rather than replacing the ID:
		// clients that stored the ID keep working, and a human writing a config
		// by hand gets a name they can recognise.
		if model.Alias != "" && !strings.EqualFold(model.Alias, model.ID) {
			data = append(data, modelObject{ID: model.Alias, Object: "model", Created: model.CreatedAt.Unix(), OwnedBy: "culpeostudio/" + model.Runtime})
		}
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{"object": "list", "data": data})
}

// handleHealth answers the probe most OpenAI-compatible tooling makes before it
// sends anything. It deliberately needs no key: it reports that the gateway is
// up, not what it serves.
func (g *localGateway) handleHealth(w http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodGet && request.Method != http.MethodHead {
		writeOpenAIError(w, http.StatusMethodNotAllowed, "method_not_allowed", "Nur GET wird unter diesem Endpoint unterstuetzt.", "")
		return
	}
	ready := 0
	for _, model := range g.list() {
		if model.Ready {
			ready++
		}
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{"status": "ok", "ready_models": ready})
}

func (g *localGateway) handleInference(w http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodPost {
		writeOpenAIError(w, http.StatusMethodNotAllowed, "method_not_allowed", "Nur POST wird unter diesem Endpoint unterstuetzt.", "")
		return
	}
	bodyBytes, err := io.ReadAll(io.LimitReader(request.Body, 16<<20+1))
	if err != nil || len(bodyBytes) > 16<<20 {
		writeOpenAIError(w, http.StatusRequestEntityTooLarge, "request_too_large", "Anfrage ist groesser als 16 MiB.", "")
		return
	}
	var body map[string]interface{}
	if err := json.Unmarshal(bodyBytes, &body); err != nil {
		writeOpenAIError(w, http.StatusBadRequest, "invalid_json", "Ungueltiger JSON-Body.", "")
		return
	}
	requestedModel, _ := body["model"].(string)
	requestedModel = strings.TrimSpace(requestedModel)
	if requestedModel == "" {
		writeOpenAIError(w, http.StatusUnprocessableEntity, "model_required", "Das OpenAI-Feld model muss eine Instanz-ID oder einen Modellnamen enthalten.", "model")
		return
	}
	// The alias has to be resolved before the key check, because a key scoped by
	// instance ID must still authorise a request that used the friendly name.
	// The order matters the other way too: a caller whose key does not cover
	// what they asked for gets 401 whether or not it exists, so this never
	// answers the question "is there an instance by this name" for someone who
	// is not allowed to know.
	token := bearerToken(request.Header.Get("Authorization"))
	model, ok := g.lookup(requestedModel)
	if !ok {
		if !g.keys.authorize(token, requestedModel) {
			writeOpenAIError(w, http.StatusUnauthorized, "invalid_api_key", "Engine-Schluessel ist ungueltig, widerrufen oder nicht fuer diese Instanz freigegeben.", "")
			return
		}
		writeOpenAIError(w, http.StatusNotFound, "model_not_found", "Engine-Instanz wurde nicht gefunden.", "model")
		return
	}
	instanceID := model.ID
	// Both spellings are accepted, so a key scoped to either one works.
	if !g.keys.authorize(token, instanceID) && !g.keys.authorize(token, requestedModel) {
		writeOpenAIError(w, http.StatusUnauthorized, "invalid_api_key", "Engine-Schluessel ist ungueltig, widerrufen oder nicht fuer diese Instanz freigegeben.", "")
		return
	}
	if !model.Ready || model.BaseURL == "" {
		// Warming up on demand is per-instance opt-in. Without it the answer
		// stays what it was, because silently loading a model of tens of
		// gigabytes because a request named it is not the gateway's call.
		if !model.Autostart || g.deps.ensureReady == nil {
			writeOpenAIError(w, http.StatusServiceUnavailable, "model_not_ready",
				"Engine-Instanz ist noch nicht bereit. Fuer automatisches Laden bei Anfragen muss der automatische Start dieser Instanz aktiviert sein.", "model")
			return
		}
		if err := g.deps.ensureReady(request.Context(), instanceID); err != nil {
			if errors.Is(err, context.Canceled) {
				return
			}
			w.Header().Set("Retry-After", "30")
			writeOpenAIError(w, http.StatusServiceUnavailable, "model_start_failed",
				"Die Engine-Instanz konnte nicht automatisch geladen werden: "+err.Error(), "model")
			return
		}
		if model, ok = g.lookup(instanceID); !ok || !model.Ready || model.BaseURL == "" {
			writeOpenAIError(w, http.StatusServiceUnavailable, "model_not_ready", "Engine-Instanz ist nach dem automatischen Start noch nicht bereit.", "model")
			return
		}
	}
	// The worker only answers to its own instance ID, whatever name the client
	// used to get here.
	body["model"] = instanceID
	if g.deps.acquire != nil {
		release, admissionErr := g.deps.acquire(request.Context(), instanceID)
		if admissionErr != nil {
			if errors.Is(admissionErr, context.Canceled) {
				return
			}
			w.Header().Set("Retry-After", "120")
			code := "inference_queue_timeout"
			var detailed *inferenceAdmissionError
			if errors.As(admissionErr, &detailed) && detailed.code != "" {
				code = detailed.code
			}
			writeOpenAIError(w, http.StatusTooManyRequests, code, "Die Inferenz-Warteschlange dieser Instanz ist ausgelastet. Bitte kurz erneut versuchen.", "model")
			return
		}
		defer release()
	}
	for key, value := range model.GenerationDefaults {
		if _, explicitlySet := body[key]; !explicitlySet {
			body[key] = value
		}
	}
	bodyBytes, err = json.Marshal(body)
	if err != nil {
		writeOpenAIError(w, http.StatusBadRequest, "invalid_json", "Anfrage konnte nicht normalisiert werden.", "")
		return
	}
	if exceedsApproximateContext(body, model.ContextLimit) {
		writeContextLimitError(w, model.ContextLimit)
		return
	}
	requestStart := time.Now()
	baseProxyContext, cancelProxy := context.WithCancel(request.Context())
	defer cancelProxy()

	if notifier, ok := w.(http.CloseNotifier); ok { //nolint:staticcheck // needed for HTTP/1 disconnect detection
		closed := notifier.CloseNotify()
		proxyDone := baseProxyContext.Done()
		go func() {
			select {
			case <-closed:
				cancelProxy()
			case <-proxyDone:
			}
		}()
	}
	var upstreamConnection net.Conn
	var upstreamConnectionMu sync.Mutex
	proxyContext := httptrace.WithClientTrace(baseProxyContext, &httptrace.ClientTrace{
		GotConn: func(info httptrace.GotConnInfo) {
			upstreamConnectionMu.Lock()
			defer upstreamConnectionMu.Unlock()
			if baseProxyContext.Err() != nil {
				_ = info.Conn.Close()
				return
			}
			upstreamConnection = info.Conn
		},
	})
	upstreamURL := strings.TrimRight(model.BaseURL, "/") + request.URL.Path
	upstream, err := http.NewRequestWithContext(proxyContext, http.MethodPost, upstreamURL, bytes.NewReader(bodyBytes))
	if err != nil {
		writeOpenAIError(w, http.StatusBadGateway, "worker_error", err.Error(), "")
		return
	}
	upstream.Header.Set("Content-Type", "application/json")
	upstream.Header.Set("Accept", request.Header.Get("Accept"))
	if model.WorkerSecret != "" {
		upstream.Header.Set("Authorization", "Bearer "+model.WorkerSecret)
	}

	stopCancellation := func() bool { return true }
	if transport, ok := g.client.Transport.(interface{ CancelRequest(*http.Request) }); ok {
		stopCancellation = context.AfterFunc(proxyContext, func() {
			transport.CancelRequest(upstream)
		})
	}
	defer stopCancellation()
	stopConnectionCancellation := context.AfterFunc(proxyContext, func() {
		upstreamConnectionMu.Lock()
		defer upstreamConnectionMu.Unlock()
		if upstreamConnection != nil {
			_ = upstreamConnection.Close()
		}
	})
	defer stopConnectionCancellation()
	response, err := g.client.Do(upstream)
	if err != nil {
		writeOpenAIError(w, http.StatusBadGateway, "worker_unavailable", "Lokaler Model-Worker ist nicht erreichbar.", "model")
		return
	}
	defer response.Body.Close()
	for _, header := range []string{"Content-Type", "Cache-Control", "X-Accel-Buffering"} {
		if value := response.Header.Get(header); value != "" {
			w.Header().Set(header, value)
		}
	}
	if strings.Contains(strings.ToLower(response.Header.Get("Content-Type")), "text/event-stream") {
		w.Header().Set("Content-Type", "text/event-stream; charset=utf-8")
		w.Header().Set("Cache-Control", "no-cache")
		w.Header().Set("X-Accel-Buffering", "no")
	}
	w.WriteHeader(response.StatusCode)
	buffer := make([]byte, 32*1024)
	flusher, _ := w.(http.Flusher)
	// Measure what passes through. The gateway is a byte proxy, so the numbers
	// come from the worker's own usage object rather than from counting chunks:
	// a stream chunk is not a token, and treating it as one is how the Studio
	// chat path used to overstate throughput.
	usage := usageProbe{start: requestStart}
	defer func() {
		if g.deps.recordUsage != nil {
			if sample, ok := usage.sample(); ok {
				g.deps.recordUsage(instanceID, sample)
			}
		}
	}()
	for {
		read, readErr := response.Body.Read(buffer)
		if read > 0 {
			usage.observe(buffer[:read])
			if _, writeErr := w.Write(buffer[:read]); writeErr != nil {
				return
			}
			if flusher != nil {
				flusher.Flush()
			}
		}
		if readErr != nil {
			return
		}
	}
}

// usageProbe watches a response go past and pulls the completion token count
// out of it. Both the streaming and the non-streaming shape end in a JSON
// object carrying "completion_tokens", so the last value seen is the answer.
//
// It keeps only a small rolling window, because a long completion must not be
// buffered in full just to read a number off its end.
type usageProbe struct {
	start      time.Time
	firstByte  time.Time
	tail       []byte
	tokens     int
	sawPayload bool
}

const usageProbeTailBytes = 8 << 10

func (p *usageProbe) observe(chunk []byte) {
	if len(chunk) == 0 {
		return
	}
	if !p.sawPayload {
		p.sawPayload = true
		p.firstByte = time.Now()
	}
	p.tail = append(p.tail, chunk...)
	if len(p.tail) > usageProbeTailBytes {
		p.tail = p.tail[len(p.tail)-usageProbeTailBytes:]
	}
	if tokens, ok := lastCompletionTokens(p.tail); ok {
		p.tokens = tokens
	}
}

func (p *usageProbe) sample() (gatewayUsageSample, bool) {
	if p.tokens <= 0 || !p.sawPayload {
		return gatewayUsageSample{}, false
	}
	end := time.Now()
	sample := gatewayUsageSample{
		CompletedAt:       end.UTC(),
		GenerationSeconds: end.Sub(p.start).Seconds(),
		OutputTokens:      p.tokens,
	}
	if !p.firstByte.IsZero() {
		sample.TTFTSeconds = p.firstByte.Sub(p.start).Seconds()
		// Throughput is about generation, not about how long the prompt took.
		if generation := end.Sub(p.firstByte).Seconds(); generation > 0 {
			sample.GenerationSeconds = generation
		}
	}
	return sample, true
}

// lastCompletionTokens finds the final "completion_tokens": N in a buffer. It
// scans the bytes rather than decoding, because the buffer is a window into a
// stream and is almost never a complete JSON document.
func lastCompletionTokens(buffer []byte) (int, bool) {
	const key = `"completion_tokens"`
	text := string(buffer)
	index := strings.LastIndex(text, key)
	if index < 0 {
		return 0, false
	}
	rest := text[index+len(key):]
	rest = strings.TrimLeft(rest, " \t\r\n")
	if !strings.HasPrefix(rest, ":") {
		return 0, false
	}
	rest = strings.TrimLeft(rest[1:], " \t\r\n")
	end := 0
	for end < len(rest) && rest[end] >= '0' && rest[end] <= '9' {
		end++
	}
	if end == 0 {
		return 0, false
	}
	value, err := strconv.Atoi(rest[:end])
	if err != nil || value <= 0 {
		return 0, false
	}
	return value, true
}

func bearerToken(header string) string {
	scheme, value, ok := strings.Cut(strings.TrimSpace(header), " ")
	if !ok || !strings.EqualFold(scheme, "Bearer") {
		return ""
	}
	return strings.TrimSpace(value)
}

func exceedsApproximateContext(body map[string]interface{}, limit int) bool {
	if limit <= 0 {
		return false
	}
	maxTokens := 0
	maxTokenValue := body["max_tokens"]
	if maxTokenValue == nil {
		maxTokenValue = body["max_completion_tokens"]
	}
	switch value := maxTokenValue.(type) {
	case float64:
		maxTokens = int(value)
	case int:
		maxTokens = value
	case json.Number:
		maxTokens, _ = strconv.Atoi(string(value))
	}

	textScalars := 0
	if prompt, ok := body["prompt"].(string); ok {
		textScalars += len([]rune(prompt))
	}
	if messages, ok := body["messages"].([]interface{}); ok {
		for _, raw := range messages {
			message, _ := raw.(map[string]interface{})
			if content, ok := message["content"].(string); ok {
				textScalars += len([]rune(content))
			}
		}
	}
	return maxTokens > limit || textScalars+maxTokens > limit*4
}

func writeContextLimitError(w http.ResponseWriter, limit int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusUnprocessableEntity)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{"error": map[string]interface{}{
		"message": "Prompt plus Ausgabe ueberschreitet das effektive Kontextlimit.",
		"type":    "context_length_exceeded", "param": "max_tokens", "code": "context_length_exceeded", "context_limit": limit,
	}})
}

func writeOpenAIError(w http.ResponseWriter, status int, code, message, param string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{"error": map[string]interface{}{
		"message": message, "type": code, "param": param, "code": code,
	}})
}
