package engine

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptrace"
	"strconv"
	"strings"
	"sync"
	"time"
)

type gatewayModel struct {
	ID                 string
	Ready              bool
	BaseURL            string
	WorkerSecret       string
	ContextLimit       int
	CreatedAt          time.Time
	Runtime            string
	GenerationDefaults map[string]interface{}
}

type localGateway struct {
	keys    *engineKeyStore
	lookup  func(string) (gatewayModel, bool)
	list    func() []gatewayModel
	client  *http.Client
	acquire func(context.Context, string) (func(), error)

	server   *http.Server
	listener net.Listener
}

func newLocalGateway(keys *engineKeyStore, lookup func(string) (gatewayModel, bool), list func() []gatewayModel, admission ...func(context.Context, string) (func(), error)) *localGateway {
	gateway := &localGateway{
		keys: keys, lookup: lookup, list: list,
		client: newLoopbackHTTPClient(),
	}
	if len(admission) > 0 {
		gateway.acquire = admission[0]
	}
	return gateway
}

func newLoopbackHTTPClient() *http.Client {
	return &http.Client{Transport: &http.Transport{
		// Worker traffic is always loopback-only and must never inherit a cloud
		// proxy or provider credentials from the management environment.
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
		return "", fmt.Errorf("Engine-Gateway darf nur an Loopback gebunden werden")
	}
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return "", err
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/v1/models", g.handleModels)
	mux.HandleFunc("/v1/chat/completions", g.handleInference)
	mux.HandleFunc("/v1/completions", g.handleInference)
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
		if !model.Ready || (len(scope) > 0 && !containsString(scope, model.ID)) {
			continue
		}
		data = append(data, modelObject{ID: model.ID, Object: "model", Created: model.CreatedAt.Unix(), OwnedBy: "philoengine/" + model.Runtime})
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{"object": "list", "data": data})
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
	instanceID, _ := body["model"].(string)
	instanceID = strings.TrimSpace(instanceID)
	if instanceID == "" {
		writeOpenAIError(w, http.StatusUnprocessableEntity, "model_required", "Das OpenAI-Feld model muss eine Instanz-ID enthalten.", "model")
		return
	}
	if !g.keys.authorize(bearerToken(request.Header.Get("Authorization")), instanceID) {
		writeOpenAIError(w, http.StatusUnauthorized, "invalid_api_key", "Engine-Schluessel ist ungueltig, widerrufen oder nicht fuer diese Instanz freigegeben.", "")
		return
	}
	model, ok := g.lookup(instanceID)
	if !ok {
		writeOpenAIError(w, http.StatusNotFound, "model_not_found", "Engine-Instanz wurde nicht gefunden.", "model")
		return
	}
	if !model.Ready || model.BaseURL == "" {
		writeOpenAIError(w, http.StatusServiceUnavailable, "model_not_ready", "Engine-Instanz ist noch nicht bereit.", "model")
		return
	}
	if g.acquire != nil {
		release, admissionErr := g.acquire(request.Context(), instanceID)
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
	baseProxyContext, cancelProxy := context.WithCancel(request.Context())
	defer cancelProxy()
	// For an HTTP/1 client that disconnects after its complete request body was
	// read, Request.Context can remain alive until the handler next writes. Ask
	// the response writer for its close signal as well so a worker blocked before
	// response headers is still cancelled promptly.
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
	// Request contexts normally cancel Transport round trips on their own. The
	// explicit transport cancellation also tears down a connection whose worker
	// has not sent response headers yet; otherwise some Go/platform combinations
	// can return from Do while leaving that decoder request alive upstream.
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
	for {
		read, readErr := response.Body.Read(buffer)
		if read > 0 {
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
	// This preflight only rejects requests that are certainly excessive under
	// a generous one-token-per-Unicode-scalar upper bound. The worker tokenizer
	// performs the exact check and also returns OpenAI-compatible 422.
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
