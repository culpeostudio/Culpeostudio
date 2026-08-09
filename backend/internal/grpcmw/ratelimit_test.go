package grpcmw

import (
	"context"
	"strings"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// countingLimiter allows a fixed number of calls, then refuses.
type countingLimiter struct {
	allowed int
	keys    []string
}

func (l *countingLimiter) Allow(key string) bool {
	l.keys = append(l.keys, key)
	if l.allowed == 0 {
		return false
	}
	l.allowed--
	return true
}

func everyMethod(string) bool { return true }

func callLimited(t *testing.T, interceptor grpc.UnaryServerInterceptor, method string) error {
	t.Helper()
	_, err := interceptor(
		context.Background(),
		nil,
		&grpc.UnaryServerInfo{FullMethod: method},
		func(context.Context, any) (any, error) { return nil, nil },
	)
	return err
}

func TestRateLimitRefusesOnceTheBudgetIsSpent(t *testing.T) {
	limiter := &countingLimiter{allowed: 1}
	interceptor := UnaryRateLimitInterceptor(RateLimit{Limiter: limiter, Applies: everyMethod})

	if err := callLimited(t, interceptor, "/svc/Method"); err != nil {
		t.Fatalf("erster Aufruf sollte durchgehen, bekam: %v", err)
	}
	err := callLimited(t, interceptor, "/svc/Method")
	if status.Code(err) != codes.ResourceExhausted {
		t.Fatalf("erwartete ResourceExhausted, bekam: %v", err)
	}
}

// Methods outside the selection must not even consult the limiter, otherwise
// they would spend a budget that is not theirs.
func TestRateLimitSkipsUnselectedMethods(t *testing.T) {
	limiter := &countingLimiter{allowed: 0}
	interceptor := UnaryRateLimitInterceptor(RateLimit{
		Limiter: limiter,
		Applies: func(method string) bool { return method == "/svc/Limited" },
	})

	if err := callLimited(t, interceptor, "/svc/Other"); err != nil {
		t.Fatalf("nicht ausgewaehlte Methode sollte durchgehen, bekam: %v", err)
	}
	if len(limiter.keys) != 0 {
		t.Fatalf("Limiter wurde fuer eine nicht ausgewaehlte Methode befragt: %v", limiter.keys)
	}
}

func TestRateLimitWithoutLimiterIsInactive(t *testing.T) {
	interceptor := UnaryRateLimitInterceptor(RateLimit{Applies: everyMethod})

	if err := callLimited(t, interceptor, "/svc/Method"); err != nil {
		t.Fatalf("ohne Limiter darf nichts blockiert werden, bekam: %v", err)
	}
}

// The key carries the authenticated user, so one account cannot spend the
// budget of another on the same address.
func TestRateLimitKeyIncludesTheAuthenticatedUser(t *testing.T) {
	limiter := &countingLimiter{allowed: 10}
	interceptor := UnaryRateLimitInterceptor(RateLimit{Limiter: limiter, Applies: everyMethod})

	ctx := ContextWithUserForTest(context.Background(), "user-1", "anna")
	if _, err := interceptor(
		ctx,
		nil,
		&grpc.UnaryServerInfo{FullMethod: "/svc/Method"},
		func(context.Context, any) (any, error) { return nil, nil },
	); err != nil {
		t.Fatalf("Aufruf fehlgeschlagen: %v", err)
	}

	if len(limiter.keys) != 1 || !strings.Contains(limiter.keys[0], "anna") {
		t.Fatalf("Schluessel enthaelt den Nutzer nicht: %v", limiter.keys)
	}
}

// Two modules, two budgets: what one spends must not be missing from the
// other, which is the point of the rules being a list.
func TestRateLimitBudgetsAreIndependentPerRule(t *testing.T) {
	spent := &countingLimiter{allowed: 0}
	untouched := &countingLimiter{allowed: 1}
	interceptor := UnaryRateLimitInterceptor(
		RateLimit{
			Limiter: spent,
			Applies: func(method string) bool { return method == "/svc/Spent" },
		},
		RateLimit{
			Limiter: untouched,
			Applies: func(method string) bool { return method == "/svc/Untouched" },
		},
	)

	if status.Code(callLimited(t, interceptor, "/svc/Spent")) != codes.ResourceExhausted {
		t.Fatal("die erschoepfte Regel sollte blockieren")
	}
	if err := callLimited(t, interceptor, "/svc/Untouched"); err != nil {
		t.Fatalf("die andere Regel hat ihr Budget verloren: %v", err)
	}
}

// A call authenticated by a module's own token has a user id but no account
// name. Keying it on the address alone would put every such caller into one
// bucket.
func TestRateLimitKeyFallsBackToTheUserID(t *testing.T) {
	limiter := &countingLimiter{allowed: 10}
	interceptor := UnaryRateLimitInterceptor(RateLimit{Limiter: limiter, Applies: everyMethod})

	ctx := ContextWithUserForTest(context.Background(), "tool-user", "")
	if _, err := interceptor(
		ctx,
		nil,
		&grpc.UnaryServerInfo{FullMethod: "/svc/Method"},
		func(context.Context, any) (any, error) { return nil, nil },
	); err != nil {
		t.Fatalf("Aufruf fehlgeschlagen: %v", err)
	}

	if len(limiter.keys) != 1 || !strings.Contains(limiter.keys[0], "tool-user") {
		t.Fatalf("Schluessel enthaelt die Nutzer-ID nicht: %v", limiter.keys)
	}
}
