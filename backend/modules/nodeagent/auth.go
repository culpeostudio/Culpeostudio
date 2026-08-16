package nodeagent

import (
	"context"
	"crypto/subtle"
	"strings"
)

const (
	nodeAgentServicePrefix   = "/culpeostudio.node.v1.NodeAgentService/"
	engineServicePrefix      = "/culpeostudio.engine.v1.EngineService/"
	marketplaceServicePrefix = "/culpeostudio.marketplace.v1.MarketplaceService/"
)

// AllowedMethod reports whether a pairing token may authenticate a gRPC
// method. A node pairing is deliberately not a general backend login: it can
// inspect node status, download models through MarketplaceService and run them
// through EngineService, but it cannot access accounts, chat, settings or a
// node registry.
func AllowedMethod(fullMethod string) bool {
	if sensitiveEngineMethods[fullMethod] {
		return false
	}
	return strings.HasPrefix(fullMethod, nodeAgentServicePrefix) ||
		strings.HasPrefix(fullMethod, engineServicePrefix) ||
		strings.HasPrefix(fullMethod, marketplaceServicePrefix)
}

// Some EngineService methods manage credentials or import/export files from
// the node owner. They are not required for downloading or running a model,
// so a paired Studio must use NodeAgentService.IssueGatewayKey instead. The
// sole exception is RevokeKey: Studio uses the exact key id it previously
// received when a direct Node is disabled or removed.
var sensitiveEngineMethods = map[string]bool{
	"/culpeostudio.engine.v1.EngineService/ListKeys":      true,
	"/culpeostudio.engine.v1.EngineService/CreateKey":     true,
	"/culpeostudio.engine.v1.EngineService/RotateKey":     true,
	"/culpeostudio.engine.v1.EngineService/ExportPresets": true,
	"/culpeostudio.engine.v1.EngineService/ImportPresets": true,
}

// AlternateAuth is designed for grpcmw.AuthConfig.AlternateAuth. It accepts a
// pairing token only for the narrow NodeAgent, Engine and Marketplace surfaces
// a Studio needs to operate this node.
func (s *Service) AlternateAuth(_ context.Context, fullMethod, token string) (string, bool) {
	if !AllowedMethod(fullMethod) {
		return "", false
	}
	s.mu.RLock()
	identity := s.identity
	s.mu.RUnlock()
	if subtle.ConstantTimeCompare([]byte(identity.Token), []byte(token)) != 1 {
		return "", false
	}
	return "node:" + identity.NodeID, true
}

// AuthenticateGRPCToken is an explicit name for the same grpcmw hook. It
// keeps node setup readable at call sites without widening its permissions.
func (s *Service) AuthenticateGRPCToken(ctx context.Context, fullMethod, token string) (string, bool) {
	return s.AlternateAuth(ctx, fullMethod, token)
}
