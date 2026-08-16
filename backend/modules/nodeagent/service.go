package nodeagent

import (
	"context"
	"fmt"
	"math"
	"net/url"
	"strings"
	"sync"
	"unicode"
	"unicode/utf8"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	hardwarev1 "github.com/culpeohq/backend/gen/go/culpeostudio/hardware/v1"
	nodev1 "github.com/culpeohq/backend/gen/go/culpeostudio/node/v1"
)

const (
	defaultGatewayKeyLabel = "Culpeo Studio"
	maxModelDirRunes       = 4096
	maxGatewayURLRunes     = 2048
)

// AgentBridge supplies the values owned by other backend modules. Keeping
// these as callbacks means nodeagent has no dependency on either the Engine or
// Marketplace implementation: the same small service can accompany any
// engine that exposes the generated gRPC APIs.
//
// Every status callback is optional. A missing callback leaves its matching
// response field empty; a callback that returns an invalid value fails the
// RPC instead of reporting misleading status data.
type AgentBridge struct {
	Hardware        func() *hardwarev1.HardwareProfile
	ModelDir        func() string
	ModelCount      func() int
	InstanceCount   func() int
	GatewayBaseURL  func() string
	IssueGatewayKey func(label string) (keyID string, secret string, err error)
}

// Service is the NodeAgentService implementation attached to a node backend.
// Its identity is persisted locally, while operational details arrive through
// AgentBridge from the modules that own them.
type Service struct {
	nodev1.UnimplementedNodeAgentServiceServer

	mu           sync.RWMutex
	identity     persistedIdentity
	identityPath string
	version      string

	bridgeMu sync.RWMutex
	bridge   AgentBridge
}

// New opens or creates the persistent node identity and returns a standalone
// NodeAgentService. It performs no networking and never logs the pairing
// token.
func New(cfg Config, bridge AgentBridge) (*Service, error) {
	version, err := normalizeVersion(cfg.Version)
	if err != nil {
		return nil, err
	}
	identity, path, err := loadOrCreateIdentity(cfg)
	if err != nil {
		return nil, err
	}
	return &Service{
		identity:     identity,
		identityPath: path,
		version:      version,
		bridge:       bridge,
	}, nil
}

// RegisterGRPC adds just NodeAgentService. EngineService and
// MarketplaceService remain registered by the modules that implement them.
func (s *Service) RegisterGRPC(registrar grpc.ServiceRegistrar) {
	nodev1.RegisterNodeAgentServiceServer(registrar, s)
}

// SetAgentBridge swaps the callbacks used for status and key issuance. It is
// safe to call during setup before the gRPC listener is started.
func (s *Service) SetAgentBridge(bridge AgentBridge) {
	s.bridgeMu.Lock()
	s.bridge = bridge
	s.bridgeMu.Unlock()
}

func (s *Service) bridgeSnapshot() AgentBridge {
	s.bridgeMu.RLock()
	defer s.bridgeMu.RUnlock()
	return s.bridge
}

// Identity returns the non-secret identity that can safely be shown in Studio.
func (s *Service) Identity() Identity {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.identity.public()
}

// PairingToken returns the sensitive pairing token explicitly. It exists for
// first-start setup code that has to present the token to an operator; this
// package intentionally never logs it.
func (s *Service) PairingToken() string {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.identity.Token
}

// SetName persists a user-visible name without changing the stable node id or
// the pairing token.
func (s *Service) SetName(name string) error {
	normalized, err := normalizeName(name)
	if err != nil {
		return err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if normalized == s.identity.Name {
		return nil
	}
	next := s.identity
	next.Name = normalized
	if err := writeIdentity(s.identityPath, next); err != nil {
		return err
	}
	s.identity = next
	return nil
}

// GetNodeStatus reports the node's stable identity plus the optional details
// its Engine and Marketplace callbacks provide.
func (s *Service) GetNodeStatus(
	_ context.Context,
	_ *nodev1.GetNodeStatusRequest,
) (*nodev1.GetNodeStatusResponse, error) {
	s.mu.RLock()
	identity := s.identity
	version := s.version
	s.mu.RUnlock()
	bridge := s.bridgeSnapshot()

	response := &nodev1.GetNodeStatusResponse{
		NodeId:           identity.NodeID,
		Name:             identity.Name,
		Version:          version,
		GatewayKeyIssued: identity.GatewayKeyID != "",
	}
	if bridge.Hardware != nil {
		profile := bridge.Hardware()
		if profile != nil {
			if profile.GetDiskFreeBytes() < 0 {
				return nil, status.Error(codes.Internal, "Hardware-Profil meldet ungueltigen freien Speicher")
			}
			response.Hardware = profile
			response.DiskFreeBytes = profile.GetDiskFreeBytes()
		}
	}
	if bridge.ModelDir != nil {
		modelDir, err := normalizeModelDir(bridge.ModelDir())
		if err != nil {
			return nil, status.Errorf(codes.Internal, "Modellordner des Nodes ist ungueltig: %v", err)
		}
		response.ModelDir = modelDir
	}
	if bridge.ModelCount != nil {
		modelCount, err := countToProto("Modellanzahl", bridge.ModelCount())
		if err != nil {
			return nil, status.Error(codes.Internal, err.Error())
		}
		response.ModelCount = modelCount
	}
	if bridge.InstanceCount != nil {
		instanceCount, err := countToProto("Instanzanzahl", bridge.InstanceCount())
		if err != nil {
			return nil, status.Error(codes.Internal, err.Error())
		}
		response.InstanceCount = instanceCount
	}
	if bridge.GatewayBaseURL != nil {
		gatewayURL, err := normalizeGatewayURL(bridge.GatewayBaseURL())
		if err != nil {
			return nil, status.Errorf(codes.Internal, "Gateway-Adresse des Nodes ist ungueltig: %v", err)
		}
		response.GatewayBaseUrl = gatewayURL
	}
	return response, nil
}

// IssueGatewayKey asks the engine owning the gateway for a key and records
// only its public id. The secret is returned to the caller once and is never
// written to the node identity file.
func (s *Service) IssueGatewayKey(
	_ context.Context,
	req *nodev1.IssueGatewayKeyRequest,
) (*nodev1.IssueGatewayKeyResponse, error) {
	label := defaultGatewayKeyLabel
	if req != nil && req.GetLabel() != "" {
		var err error
		label, err = normalizeLabel(req.GetLabel())
		if err != nil {
			return nil, status.Errorf(codes.InvalidArgument, "ungueltige Bezeichnung fuer Gateway-Schluessel: %v", err)
		}
	}

	bridge := s.bridgeSnapshot()
	if bridge.IssueGatewayKey == nil {
		return nil, status.Error(codes.Unavailable, "die Engine dieses Nodes kann keine Gateway-Schluessel ausstellen")
	}
	gatewayURL := ""
	if bridge.GatewayBaseURL != nil {
		var err error
		gatewayURL, err = normalizeGatewayURL(bridge.GatewayBaseURL())
		if err != nil {
			return nil, status.Errorf(codes.Internal, "Gateway-Adresse des Nodes ist ungueltig: %v", err)
		}
	}
	keyID, secret, err := bridge.IssueGatewayKey(label)
	if err != nil {
		return nil, status.Error(codes.Internal, "Gateway-Schluessel konnte nicht ausgestellt werden")
	}
	keyID, err = normalizeOpaqueValue(keyID, "Gateway-Schluessel-ID", 1, maxTokenLength)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "die Engine lieferte eine ungueltige Gateway-Schluessel-ID: %v", err)
	}
	secret, err = normalizeOpaqueValue(secret, "Gateway-Schluessel", minTokenLength, maxTokenLength)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "die Engine lieferte einen ungueltigen Gateway-Schluessel: %v", err)
	}

	if err := s.recordGatewayKeyID(keyID); err != nil {
		return nil, status.Error(codes.Internal, "Gateway-Schluesselstatus konnte nicht gespeichert werden")
	}
	return &nodev1.IssueGatewayKeyResponse{
		KeyId:          keyID,
		Secret:         secret,
		GatewayBaseUrl: gatewayURL,
	}, nil
}

func (s *Service) recordGatewayKeyID(keyID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	next := s.identity
	next.GatewayKeyID = keyID
	if err := writeIdentity(s.identityPath, next); err != nil {
		return err
	}
	s.identity = next
	return nil
}

func normalizeModelDir(value string) (string, error) {
	value = strings.TrimSpace(value)
	if utf8.RuneCountInString(value) > maxModelDirRunes {
		return "", fmt.Errorf("Modellordner darf hoechstens %d Zeichen lang sein", maxModelDirRunes)
	}
	for _, character := range value {
		if unicode.IsControl(character) {
			return "", fmt.Errorf("Modellordner darf keine Steuerzeichen enthalten")
		}
	}
	return value, nil
}

func countToProto(name string, value int) (int32, error) {
	if value < 0 || int64(value) > math.MaxInt32 {
		return 0, fmt.Errorf("%s des Nodes ist ungueltig", name)
	}
	return int32(value), nil
}

func normalizeLabel(value string) (string, error) {
	value = strings.TrimSpace(value)
	if value == "" {
		return defaultGatewayKeyLabel, nil
	}
	if utf8.RuneCountInString(value) > maxNameRunes {
		return "", fmt.Errorf("Bezeichnung darf hoechstens %d Zeichen lang sein", maxNameRunes)
	}
	for _, character := range value {
		if unicode.IsControl(character) {
			return "", fmt.Errorf("Bezeichnung darf keine Steuerzeichen enthalten")
		}
	}
	return value, nil
}

func normalizeGatewayURL(raw string) (string, error) {
	value := strings.TrimSpace(raw)
	if value == "" {
		return "", nil
	}
	if utf8.RuneCountInString(value) > maxGatewayURLRunes {
		return "", fmt.Errorf("Gateway-Adresse darf hoechstens %d Zeichen lang sein", maxGatewayURLRunes)
	}
	parsed, err := url.ParseRequestURI(value)
	if err != nil {
		return "", fmt.Errorf("keine URL")
	}
	if parsed.Scheme != "http" && parsed.Scheme != "https" {
		return "", fmt.Errorf("Schema muss http oder https sein")
	}
	if parsed.Hostname() == "" {
		return "", fmt.Errorf("Host fehlt")
	}
	if parsed.User != nil || parsed.RawQuery != "" || parsed.Fragment != "" {
		return "", fmt.Errorf("darf keine Zugangsdaten, Query oder Fragment enthalten")
	}
	if parsed.Path == "/" {
		parsed.Path = ""
	}
	return parsed.String(), nil
}
