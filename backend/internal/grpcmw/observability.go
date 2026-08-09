package grpcmw

import (
	"context"
	"log"
	"runtime/debug"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// UnaryLoggingInterceptor logs the method, duration and resulting status code
// of every unary call.
func UnaryLoggingInterceptor() grpc.UnaryServerInterceptor {
	return func(
		ctx context.Context,
		req any,
		info *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler,
	) (any, error) {
		started := time.Now()
		response, err := handler(ctx, req)
		log.Printf("[gRPC] %s %s %s", info.FullMethod, status.Code(err), time.Since(started).Round(time.Millisecond))
		return response, err
	}
}

// StreamLoggingInterceptor logs the method, duration and resulting status code
// of every streaming call. The duration covers the whole stream, so it is only
// written once the stream is closed.
func StreamLoggingInterceptor() grpc.StreamServerInterceptor {
	return func(
		srv any,
		stream grpc.ServerStream,
		info *grpc.StreamServerInfo,
		handler grpc.StreamHandler,
	) error {
		started := time.Now()
		err := handler(srv, stream)
		log.Printf("[gRPC] %s %s %s (stream)", info.FullMethod, status.Code(err), time.Since(started).Round(time.Millisecond))
		return err
	}
}

// UnaryRecoveryInterceptor turns a panic in a handler into an Internal error so
// one failing call cannot take the server down. The stack trace is logged
// rather than returned, to keep it out of the client's error message.
func UnaryRecoveryInterceptor() grpc.UnaryServerInterceptor {
	return func(
		ctx context.Context,
		req any,
		info *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler,
	) (response any, err error) {
		defer func() {
			if recovered := recover(); recovered != nil {
				log.Printf("[gRPC] panic in %s: %v\n%s", info.FullMethod, recovered, debug.Stack())
				err = status.Error(codes.Internal, "Interner Serverfehler")
				response = nil
			}
		}()
		return handler(ctx, req)
	}
}

// StreamRecoveryInterceptor is the streaming counterpart of
// UnaryRecoveryInterceptor.
func StreamRecoveryInterceptor() grpc.StreamServerInterceptor {
	return func(
		srv any,
		stream grpc.ServerStream,
		info *grpc.StreamServerInfo,
		handler grpc.StreamHandler,
	) (err error) {
		defer func() {
			if recovered := recover(); recovered != nil {
				log.Printf("[gRPC] panic in %s: %v\n%s", info.FullMethod, recovered, debug.Stack())
				err = status.Error(codes.Internal, "Interner Serverfehler")
			}
		}()
		return handler(srv, stream)
	}
}
