// Package nodegateway exposes a Node's local OpenAI-compatible Engine gateway
// through the Node's pinned TLS certificate. It is deliberately narrow: the
// public listener can proxy only /v1/ requests to a loopback-only upstream.
package nodegateway

import (
	"crypto/tls"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"path"
	"strconv"
	"strings"
	"sync"
	"time"
)

// Config describes the public TLS listener and the Engine gateway it protects.
// TLSCertFile and TLSKeyFile may be the paths returned by nodecert.Ensure.
// UpstreamURL must use a literal loopback IP address such as
// http://127.0.0.1:8091; this keeps the reverse proxy from becoming a generic
// network pivot.
type Config struct {
	ListenAddress string
	UpstreamURL   string
	TLSCertFile   string
	TLSKeyFile    string
}

// Gateway is a running TLS reverse proxy. Close is safe to call repeatedly.
type Gateway struct {
	address string
	server  *http.Server
	done    chan struct{}

	mu       sync.RWMutex
	serveErr error

	closeOnce sync.Once
	closeErr  error
}

// Start validates config, opens a TLS-only public listener, and starts
// forwarding /v1/ requests to the local Engine gateway. It returns once the
// listener is ready; serving happens in a background goroutine.
func Start(config Config) (*Gateway, error) {
	listenAddress, err := validateListenAddress(config.ListenAddress)
	if err != nil {
		return nil, fmt.Errorf("Node-Gateway-Adresse: %w", err)
	}
	upstream, err := parseLoopbackUpstream(config.UpstreamURL)
	if err != nil {
		return nil, fmt.Errorf("Node-Gateway-Upstream: %w", err)
	}
	certificate, err := tls.LoadX509KeyPair(strings.TrimSpace(config.TLSCertFile), strings.TrimSpace(config.TLSKeyFile))
	if err != nil {
		return nil, fmt.Errorf("Node-Gateway-TLS-Zertifikat laden: %w", err)
	}

	listener, err := net.Listen("tcp", listenAddress)
	if err != nil {
		return nil, fmt.Errorf("Node-Gateway starten: %w", err)
	}

	proxy := newReverseProxy(upstream)
	server := &http.Server{
		Handler:           v1OnlyHandler(proxy),
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       60 * time.Second,
		IdleTimeout:       120 * time.Second,
		MaxHeaderBytes:    16 << 10,
		// Neither the HTTP server nor the proxy gets a logger that might
		// accidentally render request headers, including Authorization.
		ErrorLog: log.New(io.Discard, "", 0),
	}
	gateway := &Gateway{
		address: listener.Addr().String(),
		server:  server,
		done:    make(chan struct{}),
	}
	tlsListener := tls.NewListener(listener, &tls.Config{
		MinVersion:   tls.VersionTLS12,
		Certificates: []tls.Certificate{certificate},
	})

	go gateway.serve(tlsListener)
	return gateway, nil
}

func (g *Gateway) serve(listener net.Listener) {
	err := g.server.Serve(listener)
	if err != nil && !errors.Is(err, http.ErrServerClosed) {
		g.mu.Lock()
		g.serveErr = err
		g.mu.Unlock()
	}
	close(g.done)
}

// Address returns the resolved listener address. In particular, a :0 listen
// address is replaced with the actual port after Start succeeds.
func (g *Gateway) Address() string {
	if g == nil {
		return ""
	}
	return g.address
}

// Close immediately stops the listener and active proxy connections. It is
// intended for process shutdown, where the local Engine is stopped too.
func (g *Gateway) Close() error {
	if g == nil {
		return nil
	}
	g.closeOnce.Do(func() {
		if err := g.server.Close(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			g.closeErr = err
		}
		<-g.done
		if g.closeErr != nil {
			return
		}
		g.mu.RLock()
		g.closeErr = g.serveErr
		g.mu.RUnlock()
	})
	return g.closeErr
}

func newReverseProxy(upstream *url.URL) *httputil.ReverseProxy {
	proxy := httputil.NewSingleHostReverseProxy(upstream)
	// Negative means flush after every write. This retains streaming responses
	// such as OpenAI-compatible server-sent events instead of buffering them.
	proxy.FlushInterval = -1
	proxy.ErrorHandler = func(writer http.ResponseWriter, _ *http.Request, _ error) {
		// Do not log proxy errors here: request headers can contain credentials.
		http.Error(writer, http.StatusText(http.StatusBadGateway), http.StatusBadGateway)
	}
	return proxy
}

func v1OnlyHandler(proxy http.Handler) http.Handler {
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		// Check both the original prefix and its clean form. Without the latter
		// /v1/../private could make a standard upstream server normalize the
		// request into a non-/v1 endpoint after it passed this boundary.
		cleanPath := path.Clean(request.URL.Path)
		if !strings.HasPrefix(request.URL.Path, "/v1/") || (cleanPath != "/v1" && !strings.HasPrefix(cleanPath, "/v1/")) {
			http.NotFound(writer, request)
			return
		}
		proxy.ServeHTTP(writer, request)
	})
}

func validateListenAddress(raw string) (string, error) {
	address := strings.TrimSpace(raw)
	if address == "" {
		return "", fmt.Errorf("fehlt")
	}
	_, port, err := net.SplitHostPort(address)
	if err != nil {
		return "", fmt.Errorf("muss Host:Port sein")
	}
	if _, err := validPort(port); err != nil {
		return "", err
	}
	return address, nil
}

func parseLoopbackUpstream(raw string) (*url.URL, error) {
	value := strings.TrimSpace(raw)
	if value == "" {
		return nil, fmt.Errorf("fehlt")
	}
	upstream, err := url.Parse(value)
	if err != nil {
		return nil, fmt.Errorf("ungueltige URL: %w", err)
	}
	if upstream.Scheme != "http" && upstream.Scheme != "https" {
		return nil, fmt.Errorf("muss http oder https verwenden")
	}
	if upstream.Host == "" {
		return nil, fmt.Errorf("muss einen Host enthalten")
	}
	if upstream.User != nil {
		return nil, fmt.Errorf("darf keine Zugangsdaten enthalten")
	}
	if upstream.RawQuery != "" || upstream.Fragment != "" {
		return nil, fmt.Errorf("darf keinen Query-String oder Fragment enthalten")
	}
	if upstream.Path != "" && upstream.Path != "/" {
		return nil, fmt.Errorf("muss auf den Root des lokalen Gateways zeigen")
	}

	host := upstream.Hostname()
	ip := net.ParseIP(host)
	if ip == nil || !ip.IsLoopback() {
		return nil, fmt.Errorf("muss eine literale Loopback-IP verwenden")
	}
	if port := upstream.Port(); port != "" {
		if _, err := validPort(port); err != nil {
			return nil, fmt.Errorf("Upstream-Port: %w", err)
		}
	}
	return upstream, nil
}

func validPort(raw string) (int, error) {
	port, err := strconv.Atoi(raw)
	if err != nil || port < 0 || port > 65535 {
		return 0, fmt.Errorf("enthaelt keinen gueltigen Port")
	}
	return port, nil
}
