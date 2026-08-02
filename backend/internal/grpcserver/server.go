// Package grpcserver runs the gRPC listener. Only the Skills service is
// registered on it today.
package grpcserver

import (
	"fmt"
	"log"
	"net"

	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

type Server struct {
	grpcServer *grpc.Server
	host       string
	port       string
}

func New(host, port string) *Server {
	return &Server{
		grpcServer: grpc.NewServer(),
		host:       host,
		port:       port,
	}
}

func (s *Server) GetGRPC() *grpc.Server {
	return s.grpcServer
}

func (s *Server) Start() error {
	lis, err := net.Listen("tcp", fmt.Sprintf("%s:%s", s.host, s.port))
	if err != nil {
		return fmt.Errorf("gRPC Listen fehlgeschlagen: %w", err)
	}

	reflection.Register(s.grpcServer)

	log.Printf("[gRPC] Server läuft auf %s:%s", s.host, s.port)
	return s.grpcServer.Serve(lis)
}

func (s *Server) Stop() {
	log.Println("[gRPC] Server wird gestoppt...")
	s.grpcServer.GracefulStop()
}
