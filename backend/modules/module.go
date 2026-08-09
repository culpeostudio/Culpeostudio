// Package modules defines what a backend module is and how it exposes itself.
package modules

import "google.golang.org/grpc"

// Module is the part every module shares: a name and a lifecycle.
type Module interface {
	Name() string

	Initialize() error

	Shutdown() error
}

// GRPCRegistrar is implemented by modules served over gRPC, which is all of
// them. The memory module additionally serves its viewer page over HTTP, and
// cmd/server wires that by name.
type GRPCRegistrar interface {
	RegisterGRPC(server *grpc.Server)
}
