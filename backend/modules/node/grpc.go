package node

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"

	enginev1 "github.com/culpeohq/backend/gen/go/culpeostudio/engine/v1"
	hardwarev1 "github.com/culpeohq/backend/gen/go/culpeostudio/hardware/v1"
	nodev1 "github.com/culpeohq/backend/gen/go/culpeostudio/node/v1"
	"github.com/culpeohq/backend/internal/nodeconnection"
	"github.com/culpeohq/backend/internal/wireguard"
)

type grpcService struct {
	nodev1.UnimplementedNodeServiceServer
	module *Module
}

// RegisterGRPC serves both sides. A Studio only ever answers NodeService, and
// a node only ever answers NodeAgentService, but which of the two a backend is
// depends on an environment variable rather than on the binary - so both are
// registered and each guards itself.
func (m *Module) RegisterGRPC(server *grpc.Server) {
	nodev1.RegisterNodeServiceServer(server, &grpcService{module: m})
	nodev1.RegisterNodeAgentServiceServer(server, &agentService{module: m})
}

func (s *grpcService) ListNodes(
	ctx context.Context,
	_ *nodev1.ListNodesRequest,
) (*nodev1.ListNodesResponse, error) {
	stored := sortedByName(s.module.registry.list())
	nodes := make([]*nodev1.Node, 0, len(stored))
	for _, entry := range stored {
		nodes = append(nodes, s.module.nodeToProto(entry))
	}
	return &nodev1.ListNodesResponse{Nodes: nodes}, nil
}

func (s *grpcService) AddNode(
	ctx context.Context,
	req *nodev1.AddNodeRequest,
) (*nodev1.AddNodeResponse, error) {
	if s.module.nodeMode {
		return nil, status.Error(codes.FailedPrecondition, "ein Node kann keine weiteren Nodes verwalten")
	}
	switch source := req.GetSource().(type) {
	case *nodev1.AddNodeRequest_JoinCode:
		return s.addFromJoinCode(ctx, source.JoinCode, strings.TrimSpace(req.GetName()))
	case *nodev1.AddNodeRequest_Manual:
		return s.addManually(ctx, source.Manual, strings.TrimSpace(req.GetName()))
	default:
		return nil, status.Error(codes.InvalidArgument, "es fehlt ein Join-Code oder eine manuelle Angabe")
	}
}

func (s *grpcService) addFromJoinCode(ctx context.Context, rawCode, nameOverride string) (*nodev1.AddNodeResponse, error) {
	if isDirectConnectionLink(rawCode) {
		return s.addDirectConnection(ctx, rawCode, nameOverride)
	}

	code, err := wireguard.DecodeJoinCode(rawCode)
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	if _, exists := s.module.registry.get(code.NodeID); exists {
		return nil, status.Error(codes.AlreadyExists, "dieser Node ist bereits hinterlegt")
	}

	interfaceName := strings.TrimSpace(code.InterfaceName)
	if interfaceName == "" {
		interfaceName = wireguard.InterfaceName(code.NodeID)
	}
	// wg-quick takes the interface name from the file name, so the config has
	// to be called exactly that.
	configPath := filepath.Join(s.module.tunnelDir, interfaceName+".conf")
	if err := writeTunnelConfig(configPath, code.TunnelConfig); err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}

	name := nameOverride
	if name == "" {
		name = strings.TrimSpace(code.Name)
	}
	entry, err := s.module.registry.add(storedNode{
		ID:          code.NodeID,
		Name:        name,
		Address:     code.NodeAddress,
		GRPCPort:    code.GRPCPort,
		GatewayPort: code.GatewayPort,
		Enabled:     true,
		Token:       code.Token,
		Tunnel: storedTunnel{
			InterfaceName: interfaceName,
			ConfigPath:    configPath,
			LocalAddress:  code.LocalAddress,
			Network:       code.Network,
			Endpoint:      code.Endpoint,
			PeerPublicKey: code.PeerPublicKey,
			Managed:       true,
		},
		AddedAt: time.Now().UTC(),
		State:   stateOffline,
	})
	if err != nil {
		_ = os.Remove(configPath)
		return nil, toStatus(err)
	}

	steps := []string{}
	tunnel := wireguard.Query(interfaceName)
	if tunnel.State != wireguard.StateUp {
		steps = append(steps, fmt.Sprintf(
			"Tunnel starten: %s", wireguard.RaiseCommand(configPath),
		))
	}
	// Probe once. It usually fails at this point, because the tunnel is not up
	// yet; the state that gets recorded is what the client shows until the
	// user brings it up and refreshes.
	refreshed := s.module.refresh(ctx, entry.ID)
	if refreshed.State != stateOnline {
		steps = append(steps, "Danach im Studio auf Aktualisieren tippen.")
	}
	return &nodev1.AddNodeResponse{
		Node:      s.module.nodeToProto(refreshed),
		NextSteps: steps,
	}, nil
}

// isDirectConnectionLink keeps the new one-link pairing format separate from
// the legacy WireGuard join code. Decode itself accepts whitespace around a
// link, so detection intentionally does as well.
func isDirectConnectionLink(raw string) bool {
	return strings.HasPrefix(strings.Join(strings.Fields(raw), ""), nodeconnection.Prefix)
}

// addDirectConnection registers a standalone Node from its single connection
// link. The link is already a complete and pinned TLS description, so this
// path deliberately never writes, starts, or checks a WireGuard interface.
//
// The status request is part of pairing rather than deferred to Refresh: a
// copied-but-wrong token or certificate pin must not leave a broken Node in
// the Studio registry.
func (s *grpcService) addDirectConnection(ctx context.Context, rawLink, nameOverride string) (*nodev1.AddNodeResponse, error) {
	connection, err := nodeconnection.Decode(rawLink)
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	host, rawPort, err := net.SplitHostPort(connection.Endpoint)
	if err != nil {
		// Decode validates this before it reaches us. Keep the guard so a
		// future connection format cannot accidentally create an unusable
		// registry record.
		return nil, status.Error(codes.InvalidArgument, "Node-Endpunkt muss Host:Port sein")
	}
	grpcPort, err := strconv.Atoi(rawPort)
	if err != nil || grpcPort < 1 || grpcPort > 65535 {
		return nil, status.Error(codes.InvalidArgument, "Node-Endpunkt hat keinen gueltigen Port")
	}

	name := nameOverride
	if name == "" {
		name = connection.Name
	}

	// New links carry the Node's persistent identity. That lets an operator
	// paste an updated link after a DNS, IP, or port change without registering
	// a second view of the same models and instances.
	previous := storedNode{}
	hadPrevious := false
	var entry storedNode
	if connection.NodeID != "" {
		if existing, found := s.module.registry.get(connection.NodeID); found {
			if existing.TLSFingerprint != connection.Fingerprint {
				return nil, status.Error(codes.AlreadyExists,
					"diese stabile Node-ID ist bereits mit einem anderen TLS-Zertifikat hinterlegt; bitte den alten Node bewusst entfernen und dann neu verbinden")
			}
			if existing.Address == host && existing.GRPCPort == grpcPort {
				return nil, status.Error(codes.AlreadyExists, "dieser Node ist bereits hinterlegt")
			}
			previous = existing
			hadPrevious = true
			entry, err = s.module.registry.update(existing.ID, func(value *storedNode) {
				value.Address = host
				value.GRPCPort = grpcPort
				value.Token = connection.Token
				value.TLSFingerprint = connection.Fingerprint
				value.Enabled = true
				value.State = stateOffline
				value.StatusMessage = ""
				if name != "" {
					value.Name = name
				}
			})
			if err != nil {
				return nil, toStatus(err)
			}
		}
	}
	if !hadPrevious {
		for _, existing := range s.module.registry.list() {
			if existing.TLSFingerprint == connection.Fingerprint &&
				existing.Address == host && existing.GRPCPort == grpcPort {
				return nil, status.Error(codes.AlreadyExists, "dieser Node ist bereits hinterlegt")
			}
		}
		nodeID := connection.NodeID
		if nodeID == "" {
			nodeID = newID() // compatibility for early direct connection links
		}
		entry, err = s.module.registry.add(storedNode{
			ID:              nodeID,
			Name:            name,
			Address:         host,
			GRPCPort:        grpcPort,
			Enabled:         true,
			Token:           connection.Token,
			TLSFingerprint:  connection.Fingerprint,
			GatewayKeyLabel: newGatewayKeyLabel(),
			// Direct nodes do not have a WireGuard route or a locally managed
			// tunnel. The TLS pin is what makes a public endpoint safe.
			Tunnel:  storedTunnel{Managed: false},
			AddedAt: time.Now().UTC(),
			State:   stateOffline,
		})
		if err != nil {
			return nil, toStatus(err)
		}
	}

	refreshed := s.module.refresh(ctx, entry.ID)
	if refreshed.State == stateOnline {
		if err := s.module.probeDirectGateway(ctx, refreshed); err == nil {
			return &nodev1.AddNodeResponse{Node: s.module.nodeToProto(refreshed)}, nil
		} else {
			refreshed.StatusMessage = "Das HTTPS-Inferenzgateway des Nodes konnte nicht mit dem gepinnten Zertifikat und dem ausgestellten Zugang geprueft werden: " + err.Error()
		}
	}

	// Do not retain a new entry that was never successfully authenticated. For
	// an endpoint migration restore the previously verified record instead.
	// This also closes a pooled connection that a failed TLS handshake may have
	// created before the server rejected it.
	s.module.dropConnection(entry.ID)
	var rollbackErr error
	if hadPrevious {
		restored := previous
		// refresh has already rotated this Studio's key on the Node. Do not
		// resurrect the revoked old secret when a new endpoint's HTTPS probe
		// fails; retain the fresh key but route it through the last verified
		// gateway address from the previous record.
		if refreshed.GatewayKeyID != "" && refreshed.GatewayKey != "" {
			restored.GatewayKeyID = refreshed.GatewayKeyID
			restored.GatewayKey = refreshed.GatewayKey
		}
		_, rollbackErr = s.module.registry.update(entry.ID, func(value *storedNode) { *value = restored })
	} else {
		_, rollbackErr = s.module.registry.remove(entry.ID)
	}
	if rollbackErr != nil {
		return nil, status.Errorf(codes.Internal,
			"Node-Verbindung konnte nicht geprueft werden und der vorherige Registry-Stand konnte nicht wiederhergestellt werden: %v",
			rollbackErr,
		)
	}

	message := strings.TrimSpace(refreshed.StatusMessage)
	if refreshed.State == stateUnauthorized {
		if message == "" {
			message = "Der Node hat den Pairing-Token abgelehnt. Bitte einen neuen Verbindungslink kopieren."
		}
		return nil, status.Error(codes.Unauthenticated, message)
	}
	if message == "" {
		message = "Der Node antwortet nicht. Bitte Adresse, Erreichbarkeit und den laufenden Node-Dienst pruefen."
	}
	return nil, status.Error(codes.Unavailable, message)
}

// probeDirectGateway proves the second half of a direct Node connection
// before Studio persists it. A successful gRPC status call alone is not
// enough: downloads and starts would work, while every later inference could
// still fail because the separately exposed HTTPS gateway was misconfigured.
//
// The gateway uses the exact same leaf pin as gRPC. Proxy use and redirects
// are disabled, so a gateway response cannot turn first contact into a request
// to an unrelated machine.
func (m *Module) probeDirectGateway(ctx context.Context, entry storedNode) error {
	if strings.TrimSpace(entry.TLSFingerprint) == "" {
		return fmt.Errorf("dem direkten Node fehlt der TLS-Fingerprint")
	}
	if strings.TrimSpace(entry.GatewayKey) == "" {
		return fmt.Errorf("der Node hat keinen Gateway-Zugang ausgestellt")
	}
	baseURL, err := directGatewayBaseURL(entry.GatewayBaseURL)
	if err != nil {
		return err
	}
	tlsConfig, err := nodeconnection.PinnedTLSConfig(entry.TLSFingerprint)
	if err != nil {
		return fmt.Errorf("TLS-Fingerprint: %w", err)
	}
	transport := &http.Transport{
		Proxy: nil,
		DialContext: (&net.Dialer{
			Timeout:   10 * time.Second,
			KeepAlive: 30 * time.Second,
		}).DialContext,
		TLSClientConfig:       tlsConfig,
		TLSHandshakeTimeout:   10 * time.Second,
		ResponseHeaderTimeout: 10 * time.Second,
		DisableCompression:    true,
		MaxIdleConnsPerHost:   1,
	}
	client := &http.Client{
		Transport: transport,
		CheckRedirect: func(*http.Request, []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}
	defer transport.CloseIdleConnections()

	callCtx, cancel := remoteContext(ctx)
	defer cancel()
	request, err := http.NewRequestWithContext(callCtx, http.MethodGet, baseURL+"/v1/models", nil)
	if err != nil {
		return fmt.Errorf("Gateway-Anfrage: %w", err)
	}
	request.Header.Set("Authorization", "Bearer "+entry.GatewayKey)
	response, err := client.Do(request)
	if err != nil {
		return fmt.Errorf("Gateway antwortet nicht: %w", err)
	}
	defer response.Body.Close()
	_, _ = io.Copy(io.Discard, io.LimitReader(response.Body, 4096))
	if response.StatusCode < http.StatusOK || response.StatusCode >= http.StatusMultipleChoices {
		return fmt.Errorf("Gateway meldet HTTP %d", response.StatusCode)
	}
	return nil
}

func directGatewayBaseURL(raw string) (string, error) {
	parsed, err := url.Parse(strings.TrimSpace(raw))
	if err != nil || parsed == nil {
		return "", fmt.Errorf("der Node hat keine gueltige Gateway-Adresse gemeldet")
	}
	if parsed.Scheme != "https" || parsed.Hostname() == "" {
		return "", fmt.Errorf("die Gateway-Adresse muss HTTPS mit Host verwenden")
	}
	if parsed.User != nil || parsed.RawQuery != "" || parsed.Fragment != "" || (parsed.Path != "" && parsed.Path != "/") {
		return "", fmt.Errorf("die Gateway-Adresse enthaelt unzulaessige Bestandteile")
	}
	return strings.TrimRight(parsed.String(), "/"), nil
}

func (s *grpcService) addManually(ctx context.Context, details *nodev1.ManualNodeDetails, nameOverride string) (*nodev1.AddNodeResponse, error) {
	address := strings.TrimSpace(details.GetAddress())
	if address == "" {
		return nil, status.Error(codes.InvalidArgument, "die Adresse des Nodes fehlt")
	}
	if err := checkTunnelAddress(address); err != nil {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	token := strings.TrimSpace(details.GetToken())
	if token == "" {
		return nil, status.Error(codes.InvalidArgument, "der Pairing-Token des Nodes fehlt")
	}
	name := nameOverride
	if name == "" {
		name = strings.TrimSpace(details.GetName())
	}
	entry, err := s.module.registry.add(storedNode{
		ID:          newID(),
		Name:        name,
		Address:     address,
		GRPCPort:    int(details.GetGrpcPort()),
		GatewayPort: int(details.GetGatewayPort()),
		Enabled:     true,
		Token:       token,
		// Nothing is managed here: the tunnel belongs to whoever set it up.
		Tunnel:  storedTunnel{Managed: false},
		AddedAt: time.Now().UTC(),
		State:   stateOffline,
	})
	if err != nil {
		return nil, toStatus(err)
	}
	refreshed := s.module.refresh(ctx, entry.ID)
	steps := []string{}
	if refreshed.State != stateOnline {
		steps = append(steps, "Der Node hat noch nicht geantwortet. Laeuft dort das Backend im Node-Modus, und steht der Tunnel?")
	}
	return &nodev1.AddNodeResponse{Node: s.module.nodeToProto(refreshed), NextSteps: steps}, nil
}

func (s *grpcService) UpdateNode(
	ctx context.Context,
	req *nodev1.UpdateNodeRequest,
) (*nodev1.UpdateNodeResponse, error) {
	previous, found := s.module.registry.get(req.GetNodeId())
	if !found {
		return nil, status.Error(codes.NotFound, errNodeUnknown.Error())
	}
	disabling := req.Enabled != nil && !req.GetEnabled()
	revocationWarning := ""
	revokedGatewayKey := false
	if disabling && strings.TrimSpace(previous.TLSFingerprint) != "" {
		if err := s.module.revokeDirectGatewayKey(ctx, previous); err != nil {
			log.Printf("[node] Gateway-Schluessel von %s konnte beim Deaktivieren nicht widerrufen werden: %v", previous.Name, err)
			revocationWarning = "Der Node war nicht erreichbar; sein bestehender HTTPS-Gateway-Zugang konnte nicht widerrufen werden. Beim erneuten Aktivieren wird ein neuer Zugang ausgestellt."
		} else {
			revokedGatewayKey = true
		}
	}
	entry, err := s.module.registry.update(req.GetNodeId(), func(value *storedNode) {
		if req.Name != nil && strings.TrimSpace(req.GetName()) != "" {
			value.Name = strings.TrimSpace(req.GetName())
		}
		if req.Enabled != nil {
			value.Enabled = req.GetEnabled()
		}
		if disabling && revokedGatewayKey {
			value.GatewayKeyID = ""
			value.GatewayKey = ""
		}
		if revocationWarning != "" {
			value.StatusMessage = revocationWarning
		}
	})
	if err != nil {
		return nil, toStatus(err)
	}
	if !entry.Enabled {
		// Nothing should keep talking to a node that was switched off.
		s.module.dropConnection(entry.ID)
		return &nodev1.UpdateNodeResponse{Node: s.module.nodeToProto(entry)}, nil
	}
	if req.Enabled != nil && req.GetEnabled() && !previous.Enabled {
		// A disabled direct Node deliberately had its Gateway key revoked. Bring
		// it back to a usable state in this same action rather than requiring a
		// surprising second click on Refresh before chat can work again.
		entry = s.module.refresh(ctx, entry.ID)
		if strings.TrimSpace(entry.TLSFingerprint) != "" && entry.State == stateOnline {
			if probeErr := s.module.probeDirectGateway(ctx, entry); probeErr != nil {
				s.module.markUnreachable(entry.ID, stateOffline,
					"Das HTTPS-Inferenzgateway konnte nach dem Aktivieren nicht geprueft werden: "+probeErr.Error())
				entry, _ = s.module.registry.get(entry.ID)
			}
		}
	}
	return &nodev1.UpdateNodeResponse{Node: s.module.nodeToProto(entry)}, nil
}

func (s *grpcService) RemoveNode(
	ctx context.Context,
	req *nodev1.RemoveNodeRequest,
) (*nodev1.RemoveNodeResponse, error) {
	entry, ok := s.module.registry.get(req.GetNodeId())
	if !ok {
		return nil, status.Error(codes.NotFound, errNodeUnknown.Error())
	}
	if strings.TrimSpace(entry.TLSFingerprint) != "" {
		if err := s.module.revokeDirectGatewayKey(ctx, entry); err != nil {
			// Removing an unreachable node must still be possible. The warning is
			// kept out of the gRPC response because it has no message field, but
			// it remains visible to the Studio backend operator in the log.
			log.Printf("[node] Gateway-Schluessel von %s konnte beim Entfernen nicht widerrufen werden: %v", entry.Name, err)
		}
	}
	if req.GetDeleteTunnelConfig() && entry.Tunnel.Managed && entry.Tunnel.ConfigPath != "" {
		if wireguard.Query(entry.Tunnel.InterfaceName).State == wireguard.StateUp {
			lowerCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
			output, err := wireguard.Lower(lowerCtx, entry.Tunnel.ConfigPath)
			cancel()
			if err != nil {
				log.Printf("[node] Tunnel von %s konnte nicht gestoppt werden: %v %s", entry.Name, err, output)
			}
		}
		if err := os.Remove(entry.Tunnel.ConfigPath); err != nil && !os.IsNotExist(err) {
			log.Printf("[node] Tunnel-Konfiguration %s nicht geloescht: %v", entry.Tunnel.ConfigPath, err)
		}
	}
	if _, err := s.module.registry.remove(entry.ID); err != nil {
		return nil, toStatus(err)
	}
	s.module.dropConnection(entry.ID)
	return &nodev1.RemoveNodeResponse{}, nil
}

func (s *grpcService) RefreshNode(
	ctx context.Context,
	req *nodev1.RefreshNodeRequest,
) (*nodev1.RefreshNodeResponse, error) {
	requested := strings.TrimSpace(req.GetNodeId())
	if requested != "" {
		if _, ok := s.module.registry.get(requested); !ok {
			return nil, status.Error(codes.NotFound, errNodeUnknown.Error())
		}
		entry := s.module.refresh(ctx, requested)
		return &nodev1.RefreshNodeResponse{Nodes: []*nodev1.Node{s.module.nodeToProto(entry)}}, nil
	}
	stored := sortedByName(s.module.registry.list())
	// Probed at once: a Studio with several nodes, half of them switched off,
	// would otherwise wait out one timeout after another for a button press.
	refreshed := make([]storedNode, len(stored))
	var waiting sync.WaitGroup
	for index, entry := range stored {
		if !entry.Enabled {
			refreshed[index] = entry
			continue
		}
		waiting.Add(1)
		go func(index int, id string) {
			defer waiting.Done()
			refreshed[index] = s.module.refresh(ctx, id)
		}(index, entry.ID)
	}
	waiting.Wait()

	nodes := make([]*nodev1.Node, 0, len(refreshed))
	for _, entry := range refreshed {
		nodes = append(nodes, s.module.nodeToProto(entry))
	}
	return &nodev1.RefreshNodeResponse{Nodes: nodes}, nil
}

func (s *grpcService) GetNodeTunnel(
	ctx context.Context,
	req *nodev1.GetNodeTunnelRequest,
) (*nodev1.GetNodeTunnelResponse, error) {
	entry, ok := s.module.registry.get(req.GetNodeId())
	if !ok {
		return nil, status.Error(codes.NotFound, errNodeUnknown.Error())
	}
	response := &nodev1.GetNodeTunnelResponse{Tunnel: tunnelToProto(entry)}
	if entry.Tunnel.Managed && entry.Tunnel.ConfigPath != "" {
		if contents, err := os.ReadFile(entry.Tunnel.ConfigPath); err == nil {
			response.ConfigText = string(contents)
		}
	}
	return response, nil
}

func (s *grpcService) SetNodeTunnel(
	ctx context.Context,
	req *nodev1.SetNodeTunnelRequest,
) (*nodev1.SetNodeTunnelResponse, error) {
	entry, ok := s.module.registry.get(req.GetNodeId())
	if !ok {
		return nil, status.Error(codes.NotFound, errNodeUnknown.Error())
	}
	if !entry.Tunnel.Managed || entry.Tunnel.ConfigPath == "" {
		return nil, status.Error(codes.FailedPrecondition,
			"der Tunnel dieses Nodes wurde nicht vom Studio angelegt und wird auch nicht von ihm gesteuert")
	}

	// Bringing an interface up or down takes longer than a control call and is
	// worth waiting for, so it gets its own budget.
	runCtx, cancel := context.WithTimeout(ctx, 60*time.Second)
	defer cancel()

	var output string
	var err error
	if req.GetUp() {
		output, err = wireguard.Raise(runCtx, entry.Tunnel.ConfigPath)
	} else {
		output, err = wireguard.Lower(runCtx, entry.Tunnel.ConfigPath)
	}
	if err != nil {
		if errors.Is(err, wireguard.ErrNeedsPrivileges) {
			command := wireguard.RaiseCommand(entry.Tunnel.ConfigPath)
			if !req.GetUp() {
				command = wireguard.LowerCommand(entry.Tunnel.ConfigPath, entry.Tunnel.InterfaceName)
			}
			return nil, status.Errorf(codes.PermissionDenied,
				"das Tunnel-Interface braucht Administratorrechte, und auf diesem System gibt es keine grafische Rechteabfrage. Bitte einmal im Terminal ausfuehren: %s",
				command)
		}
		return &nodev1.SetNodeTunnelResponse{Tunnel: tunnelToProto(entry), Output: output},
			status.Error(codes.Internal, err.Error())
	}
	// The interface changed, so anything held open against the old one is
	// stale.
	s.module.dropConnection(entry.ID)
	refreshed := entry
	if req.GetUp() {
		refreshed = s.module.refresh(ctx, entry.ID)
	}
	return &nodev1.SetNodeTunnelResponse{Tunnel: tunnelToProto(refreshed), Output: output}, nil
}

// refresh probes one node and writes back what it reported. It returns the
// entry as it now stands, so a caller does not have to read it again.
func (m *Module) refresh(ctx context.Context, nodeID string) storedNode {
	entry, ok := m.registry.get(nodeID)
	if !ok {
		return storedNode{}
	}
	if !entry.Enabled {
		return entry
	}
	client, err := m.agentClient(nodeID)
	if err != nil {
		state, message := stateOffline, err.Error()
		m.markUnreachable(nodeID, state, message)
		updated, _ := m.registry.get(nodeID)
		return updated
	}
	callCtx, cancel := remoteContext(ctx)
	defer cancel()
	report, err := client.GetNodeStatus(callCtx, &nodev1.GetNodeStatusRequest{})
	if err != nil {
		state, message := classifyRemoteError(err)
		m.markUnreachable(nodeID, state, message)
		updated, _ := m.registry.get(nodeID)
		return updated
	}

	var hardwareBytes []byte
	if report.GetHardware() != nil {
		if encoded, marshalErr := proto.Marshal(report.GetHardware()); marshalErr == nil {
			hardwareBytes = encoded
		}
	}
	updated, err := m.registry.update(nodeID, func(value *storedNode) {
		value.State = stateOnline
		value.StatusMessage = ""
		value.LastSeenAt = time.Now().UTC()
		value.Version = report.GetVersion()
		value.ModelDir = report.GetModelDir()
		value.ModelCount = int(report.GetModelCount())
		value.InstanceCount = int(report.GetInstanceCount())
		value.DiskFreeBytes = report.GetDiskFreeBytes()
		value.GatewayBaseURL = report.GetGatewayBaseUrl()
		if port := gatewayPortFromBaseURL(report.GetGatewayBaseUrl()); port > 0 {
			value.GatewayPort = port
		}
		if hardwareBytes != nil {
			value.HardwareProto = hardwareBytes
		}
		if strings.TrimSpace(report.GetName()) != "" && strings.TrimSpace(value.Name) == "" {
			value.Name = report.GetName()
		}
	})
	if err != nil {
		updated, _ = m.registry.get(nodeID)
	}

	// Inference is streamed from the node's gateway, which needs a key of its
	// own. Refreshing deliberately gets a fresh, Studio-specific key. That
	// recovers from a restarted or revoked gateway without breaking a second
	// Studio: each registry entry has its own stable label on the Node.
	if strings.TrimSpace(updated.GatewayBaseURL) != "" {
		if issued := m.issueGatewayKey(ctx, nodeID); issued.ID != "" {
			updated = issued
		}
	}
	return updated
}

// gatewayPortFromBaseURL preserves the public inference port in the regular
// Node response too. Direct Nodes report an HTTPS gateway URL rather than a
// tunnel port in their connection link, but the Flutter node card still shows
// the familiar port field.
func gatewayPortFromBaseURL(raw string) int {
	parsed, err := url.Parse(strings.TrimSpace(raw))
	if err != nil || parsed == nil {
		return 0
	}
	if rawPort := parsed.Port(); rawPort != "" {
		port, parseErr := strconv.Atoi(rawPort)
		if parseErr == nil && port > 0 && port <= 65535 {
			return port
		}
		return 0
	}
	switch strings.ToLower(parsed.Scheme) {
	case "https":
		return 443
	case "http":
		return 80
	default:
		return 0
	}
}

// issueGatewayKey asks a node for the key its gateway will accept, and stores
// it. A failure is not fatal: the node still takes downloads and model starts,
// only chat has to wait.
func (m *Module) issueGatewayKey(ctx context.Context, nodeID string) storedNode {
	client, err := m.agentClient(nodeID)
	if err != nil {
		return storedNode{}
	}
	callCtx, cancel := remoteContext(ctx)
	defer cancel()
	label, err := m.gatewayKeyLabel(nodeID)
	if err != nil {
		log.Printf("[node] Gateway-Schluesselbezeichnung von %s: %v", nodeID, err)
		return storedNode{}
	}
	issued, err := client.IssueGatewayKey(callCtx, &nodev1.IssueGatewayKeyRequest{Label: label})
	if err != nil {
		log.Printf("[node] Gateway-Schluessel von %s: %v", nodeID, err)
		return storedNode{}
	}
	updated, err := m.registry.update(nodeID, func(value *storedNode) {
		value.GatewayKeyID = issued.GetKeyId()
		value.GatewayKey = issued.GetSecret()
		if base := strings.TrimSpace(issued.GetGatewayBaseUrl()); base != "" {
			value.GatewayBaseURL = base
		}
	})
	if err != nil {
		return storedNode{}
	}
	return updated
}

// gatewayKeyLabel returns a stable, locally generated label for a registry
// entry. The remote Node ID is intentionally not used: it is identical in
// every Studio that paired the Node, whereas this random label belongs to one
// Studio only.
func (m *Module) gatewayKeyLabel(nodeID string) (string, error) {
	entry, ok := m.registry.get(nodeID)
	if !ok {
		return "", errNodeUnknown
	}
	if label := strings.TrimSpace(entry.GatewayKeyLabel); label != "" {
		return label, nil
	}
	updated, err := m.registry.update(nodeID, func(value *storedNode) {
		if strings.TrimSpace(value.GatewayKeyLabel) == "" {
			value.GatewayKeyLabel = newGatewayKeyLabel()
		}
	})
	if err != nil {
		return "", err
	}
	return updated.GatewayKeyLabel, nil
}

func newGatewayKeyLabel() string {
	return "Culpeo Studio " + newID()
}

// revokeDirectGatewayKey removes precisely the key this Studio received for a
// direct Node. Pairing tokens are otherwise allowed to operate models, but
// revocation is used only during disable/remove so an old registry backup
// cannot retain an HTTPS inference credential indefinitely.
func (m *Module) revokeDirectGatewayKey(ctx context.Context, entry storedNode) error {
	if strings.TrimSpace(entry.GatewayKeyID) == "" {
		return nil
	}
	connection, err := m.Dial(entry.ID)
	if err != nil {
		return err
	}
	callCtx, cancel := remoteContext(ctx)
	defer cancel()
	response, err := enginev1.NewEngineServiceClient(connection).RevokeKey(callCtx, &enginev1.RevokeKeyRequest{KeyId: entry.GatewayKeyID})
	if err != nil {
		if status.Code(err) == codes.NotFound {
			return nil // already rotated or revoked is the intended end state
		}
		return err
	}
	if !response.GetRevoked() {
		return fmt.Errorf("Node bestaetigte keinen Widerruf")
	}
	return nil
}

func (m *Module) nodeToProto(entry storedNode) *nodev1.Node {
	if strings.TrimSpace(entry.ID) == "" {
		return nil
	}
	message := &nodev1.Node{
		Id:            entry.ID,
		Name:          entry.Name,
		Address:       entry.Address,
		GrpcPort:      int32(entry.GRPCPort),
		GatewayPort:   int32(entry.GatewayPort),
		Enabled:       entry.Enabled,
		State:         nodeStateToProto(entry),
		StatusMessage: entry.StatusMessage,
		Version:       entry.Version,
		ModelDir:      entry.ModelDir,
		ModelCount:    int32(entry.ModelCount),
		InstanceCount: int32(entry.InstanceCount),
		DiskFreeBytes: entry.DiskFreeBytes,
		Tunnel:        tunnelToProto(entry),
	}
	if !entry.AddedAt.IsZero() {
		message.AddedAt = timestamppb.New(entry.AddedAt)
	}
	if !entry.LastSeenAt.IsZero() {
		message.LastSeenAt = timestamppb.New(entry.LastSeenAt)
	}
	if len(entry.HardwareProto) > 0 {
		profile := &hardwarev1.HardwareProfile{}
		if err := proto.Unmarshal(entry.HardwareProto, profile); err == nil {
			message.Hardware = profile
		}
	}
	return message
}

func nodeStateToProto(entry storedNode) nodev1.NodeState {
	if !entry.Enabled {
		return nodev1.NodeState_NODE_STATE_DISABLED
	}
	switch entry.State {
	case stateOnline:
		return nodev1.NodeState_NODE_STATE_ONLINE
	case stateUnauthorized:
		return nodev1.NodeState_NODE_STATE_UNAUTHORIZED
	case stateOffline:
		return nodev1.NodeState_NODE_STATE_OFFLINE
	default:
		return nodev1.NodeState_NODE_STATE_UNSPECIFIED
	}
}

func tunnelToProto(entry storedNode) *nodev1.NodeTunnel {
	message := &nodev1.NodeTunnel{
		InterfaceName: entry.Tunnel.InterfaceName,
		ConfigPath:    entry.Tunnel.ConfigPath,
		LocalAddress:  entry.Tunnel.LocalAddress,
		Endpoint:      entry.Tunnel.Endpoint,
		PeerPublicKey: entry.Tunnel.PeerPublicKey,
	}
	if !entry.Tunnel.Managed {
		// A direct link does not use a tunnel at all. Keep the legacy message
		// for manually managed WireGuard entries so existing installations are
		// not misrepresented.
		message.State = nodev1.TunnelState_TUNNEL_STATE_UNSPECIFIED
		if strings.TrimSpace(entry.TLSFingerprint) != "" {
			message.StatusMessage = "Direkte TLS-Verbindung; kein Tunnel erforderlich."
			return message
		}
		// Nothing to report and nothing to run: the tunnel is somebody else's.
		message.StatusMessage = "Der Tunnel wird ausserhalb des Studios verwaltet."
		return message
	}
	message.BringUpCommand = wireguard.RaiseCommand(entry.Tunnel.ConfigPath)
	message.BringDownCommand = wireguard.LowerCommand(entry.Tunnel.ConfigPath, entry.Tunnel.InterfaceName)

	reading := wireguard.Query(entry.Tunnel.InterfaceName)
	switch reading.State {
	case wireguard.StateUp:
		message.State = nodev1.TunnelState_TUNNEL_STATE_UP
	case wireguard.StateDown:
		message.State = nodev1.TunnelState_TUNNEL_STATE_DOWN
	default:
		message.State = nodev1.TunnelState_TUNNEL_STATE_UNAVAILABLE
	}
	message.StatusMessage = reading.Message
	if !reading.LastHandshake.IsZero() {
		message.LastHandshakeAt = timestamppb.New(reading.LastHandshake)
	}
	return message
}

// toStatus maps the module's sentinels onto gRPC codes.
func toStatus(err error) error {
	switch {
	case err == nil:
		return nil
	case errors.Is(err, errNodeUnknown):
		return status.Error(codes.NotFound, err.Error())
	case errors.Is(err, errNodeDisabled):
		return status.Error(codes.FailedPrecondition, err.Error())
	case errors.Is(err, errTunnelNetworkConflict), errors.Is(err, errTunnelNetworkUnknown):
		return status.Error(codes.FailedPrecondition, err.Error())
	default:
		return status.Error(codes.Internal, err.Error())
	}
}
