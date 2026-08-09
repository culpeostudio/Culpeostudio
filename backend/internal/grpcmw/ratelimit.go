package grpcmw

import (
	"context"
	"strings"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/peer"
	"google.golang.org/grpc/status"
)

// Limiter is the part of security.RateLimiter this package needs, kept as an
// interface so the middleware does not have to import the module it guards.
type Limiter interface {
	Allow(key string) bool
}

// RateLimit pairs a budget with the methods it covers. Each module that
// throttles brings its own, so one module spending its budget does not slow
// another down.
type RateLimit struct {
	Limiter Limiter
	Applies func(fullMethod string) bool
}

func (r RateLimit) covers(fullMethod string) bool {
	return r.Limiter != nil && r.Applies != nil && r.Applies(fullMethod)
}

// UnaryRateLimitInterceptor throttles a call against every budget that covers
// its method. The key pairs the caller's address with the authenticated user,
// the same pairing the HTTP middleware used, so one noisy account cannot spend
// everyone's budget.
//
// It belongs inside the auth interceptor in the chain: the caller is only on
// the context once authentication has run.
func UnaryRateLimitInterceptor(limits ...RateLimit) grpc.UnaryServerInterceptor {
	return func(
		ctx context.Context,
		req any,
		info *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler,
	) (any, error) {
		for _, limit := range limits {
			if !limit.covers(info.FullMethod) {
				continue
			}
			if !limit.Limiter.Allow(rateLimitKey(ctx)) {
				return nil, status.Error(codes.ResourceExhausted, "rate limit exceeded")
			}
		}
		return handler(ctx, req)
	}
}

func rateLimitKey(ctx context.Context) string {
	address := "unknown"
	if caller, ok := peer.FromContext(ctx); ok && caller.Addr != nil {
		address = caller.Addr.String()
	}
	// A call authenticated by a module's own token has no account name, only
	// the user it acts for, so that is what its budget is keyed on.
	caller := strings.TrimSpace(UsernameFromContext(ctx))
	if caller == "" {
		caller = strings.TrimSpace(UserIDFromContext(ctx))
	}
	return address + ":" + caller
}
