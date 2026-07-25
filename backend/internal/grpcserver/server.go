package grpcserver

import (
	"fmt"
	"log"
	"net"

	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

// Server verwaltet den gRPC-Server.
type Server struct {
	grpcServer *grpc.Server
	host       string
	port       string
}

// New erstellt einen neuen gRPC-Server. host ist die Bind-Adresse; leer
// bedeutet alle Interfaces. Aufrufer sollten dieselbe Adresse wie der
// HTTP-Server verwenden (Standard 127.0.0.1), damit die Instanz nicht
// unbeabsichtigt im ganzen Netz erreichbar ist — hier besonders relevant,
// weil unten Reflection aktiv ist und damit alle Services auflistbar waeren.
func New(host, port string) *Server {
	return &Server{
		grpcServer: grpc.NewServer(),
		host:       host,
		port:       port,
	}
}

// GetGRPC gibt den rohen grpc.Server zurück damit Module
// ihre Services registrieren können.
func (s *Server) GetGRPC() *grpc.Server {
	return s.grpcServer
}

// Start startet den gRPC-Server (blockierend, in Goroutine aufrufen).
func (s *Server) Start() error {
	lis, err := net.Listen("tcp", fmt.Sprintf("%s:%s", s.host, s.port))
	if err != nil {
		return fmt.Errorf("gRPC Listen fehlgeschlagen: %w", err)
	}

	// Reflection für grpcurl / Debugging
	reflection.Register(s.grpcServer)

	log.Printf("[gRPC] Server läuft auf %s:%s", s.host, s.port)
	return s.grpcServer.Serve(lis)
}

// Stop stoppt den gRPC-Server graceful.
func (s *Server) Stop() {
	log.Println("[gRPC] Server wird gestoppt...")
	s.grpcServer.GracefulStop()
}
