package grpcserver_test

import (
	"context"
	"net"
	"path/filepath"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	skillsv1 "github.com/culpeohq/backend/gen/go/culpeostudio/skills/v1"
	"github.com/culpeohq/backend/internal/grpcmw"
	"github.com/culpeohq/backend/internal/grpcserver"
	"github.com/culpeohq/backend/modules/skills"
)

const testSecret = "integration-secret"

// startServer brings up a real listener with the production interceptor chain
// and the Skills service registered on it, and returns a client for it.
func startServer(t *testing.T, auth grpcmw.AuthConfig) skillsv1.SkillsServiceClient {
	t.Helper()

	port := freePort(t)
	server, err := grpcserver.New(grpcserver.Config{
		Host: "127.0.0.1",
		Port: port,
		Auth: auth,
	})
	if err != nil {
		t.Fatalf("Server anlegen fehlgeschlagen: %v", err)
	}

	module := skills.New(filepath.Join(t.TempDir(), "skills"))
	if err := module.Initialize(); err != nil {
		t.Fatalf("Skills-Modul initialisieren fehlgeschlagen: %v", err)
	}
	module.RegisterGRPC(server.GetGRPC())

	go func() {
		// Serve returns once Stop is called; a shutdown is not a failure.
		_ = server.Start()
	}()
	t.Cleanup(server.Stop)

	conn, err := grpc.NewClient(
		net.JoinHostPort("127.0.0.1", port),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		t.Fatalf("Verbindung fehlgeschlagen: %v", err)
	}
	t.Cleanup(func() { _ = conn.Close() })

	return skillsv1.NewSkillsServiceClient(conn)
}

func freePort(t *testing.T) string {
	t.Helper()
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("freien Port suchen fehlgeschlagen: %v", err)
	}
	defer listener.Close()
	_, port, err := net.SplitHostPort(listener.Addr().String())
	if err != nil {
		t.Fatalf("Adresse zerlegen fehlgeschlagen: %v", err)
	}
	return port
}

func bearerContext(t *testing.T, username string) context.Context {
	t.Helper()
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id":  "user-1",
		"username": username,
	})
	signed, err := token.SignedString([]byte(testSecret))
	if err != nil {
		t.Fatalf("Token signieren fehlgeschlagen: %v", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	t.Cleanup(cancel)
	return metadata.AppendToOutgoingContext(ctx, "authorization", "Bearer "+signed)
}

// A call carrying a valid token reaches the service.
func TestServerAcceptsAuthenticatedCall(t *testing.T) {
	client := startServer(t, grpcmw.AuthConfig{Secret: testSecret})

	response, err := client.ListSkills(bearerContext(t, "anna"), &skillsv1.ListSkillsRequest{})
	if err != nil {
		t.Fatalf("ListSkills fehlgeschlagen: %v", err)
	}
	if response.GetCount() != 0 {
		t.Fatalf("erwartete leeren Store, bekam %d Skills", response.GetCount())
	}
}

// Without metadata the interceptor rejects the call before the service runs.
func TestServerRejectsCallWithoutToken(t *testing.T) {
	client := startServer(t, grpcmw.AuthConfig{Secret: testSecret})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := client.ListSkills(ctx, &skillsv1.ListSkillsRequest{})
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("erwartete Unauthenticated, bekam: %v", err)
	}
}

// A token for a deleted account is refused even though the signature is valid.
func TestServerRejectsRemovedAccount(t *testing.T) {
	client := startServer(t, grpcmw.AuthConfig{
		Secret:       testSecret,
		IsActiveUser: func(name string) bool { return name == "anna" },
	})

	_, err := client.ListSkills(bearerContext(t, "geloescht"), &skillsv1.ListSkillsRequest{})
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("erwartete Unauthenticated, bekam: %v", err)
	}
}
