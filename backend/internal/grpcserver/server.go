// Package grpcserver runs the gRPC listener that carries the control plane
// between the client and the backend.
package grpcserver

import (
	"fmt"
	"log"
	"net"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/reflection"

	"github.com/culpeohq/backend/internal/grpcmw"
)

// Config describes the listener and the interceptors wrapped around every call.
type Config struct {
	Host string
	Port string
	Auth grpcmw.AuthConfig

	// TLSCert and TLSKey enable transport credentials. Both must be set;
	// leaving them empty serves plaintext, which is the default for the
	// loopback listener.
	TLSCert string
	TLSKey  string

	// RateLimits throttle the methods each of them selects. A method no rule
	// covers is not throttled.
	RateLimits []grpcmw.RateLimit
}

type Server struct {
	grpcServer *grpc.Server
	host       string
	port       string
	secure     bool
}

func New(cfg Config) (*Server, error) {
	// Outermost first: logging sees the status code that recovery produced for
	// a panicking handler, and recovery covers the auth interceptor too.
	options := []grpc.ServerOption{
		grpc.ChainUnaryInterceptor(
			grpcmw.UnaryLoggingInterceptor(),
			grpcmw.UnaryRecoveryInterceptor(),
			grpcmw.UnaryAuthInterceptor(cfg.Auth),
			// After auth, so the budget can be keyed on the caller.
			grpcmw.UnaryRateLimitInterceptor(cfg.RateLimits...),
		),
		grpc.ChainStreamInterceptor(
			grpcmw.StreamLoggingInterceptor(),
			grpcmw.StreamRecoveryInterceptor(),
			grpcmw.StreamAuthInterceptor(cfg.Auth),
		),
	}

	secure := cfg.TLSCert != "" && cfg.TLSKey != ""
	if secure {
		creds, err := credentials.NewServerTLSFromFile(cfg.TLSCert, cfg.TLSKey)
		if err != nil {
			return nil, fmt.Errorf("gRPC TLS-Zertifikat konnte nicht geladen werden: %w", err)
		}
		options = append(options, grpc.Creds(creds))
	}

	return &Server{
		grpcServer: grpc.NewServer(options...),
		host:       cfg.Host,
		port:       cfg.Port,
		secure:     secure,
	}, nil
}

func (s *Server) GetGRPC() *grpc.Server {
	return s.grpcServer
}

func (s *Server) Start() error {
	address := net.JoinHostPort(s.host, s.port)
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return fmt.Errorf("gRPC Listen fehlgeschlagen: %w", err)
	}

	// Reflection lets grpcurl and similar tools inspect the running services,
	// which is the replacement for poking at the old HTTP API with curl.
	reflection.Register(s.grpcServer)

	scheme := "plaintext"
	if s.secure {
		scheme = "TLS"
	}
	log.Printf("[gRPC] Server läuft auf %s (%s)", address, scheme)
	return s.grpcServer.Serve(listener)
}

func (s *Server) Stop() {
	log.Println("[gRPC] Server wird gestoppt...")
	s.grpcServer.GracefulStop()
}

// ForceStop immediately terminates open RPCs. Callers should first use Stop
// so ordinary requests can finish, then use ForceStop only after a bounded
// grace period. This matters for a Node because Engine event streams can stay
// open indefinitely while a model is generating.
func (s *Server) ForceStop() {
	log.Println("[gRPC] Server wird sofort gestoppt...")
	s.grpcServer.Stop()
}
