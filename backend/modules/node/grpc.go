package node

import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"

	hardwarev1 "github.com/culpeohq/backend/gen/go/culpeostudio/hardware/v1"
	nodev1 "github.com/culpeohq/backend/gen/go/culpeostudio/node/v1"
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
			Endpoint:      code.Endpoint,
			PeerPublicKey: code.PeerPublicKey,
			Managed:       true,
		},
		AddedAt: time.Now().UTC(),
		State:   stateOffline,
	})
	if err != nil {
		_ = os.Remove(configPath)
		return nil, status.Error(codes.Internal, err.Error())
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
		return nil, status.Error(codes.Internal, err.Error())
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
	entry, err := s.module.registry.update(req.GetNodeId(), func(value *storedNode) {
		if req.Name != nil && strings.TrimSpace(req.GetName()) != "" {
			value.Name = strings.TrimSpace(req.GetName())
		}
		if req.Enabled != nil {
			value.Enabled = req.GetEnabled()
		}
	})
	if err != nil {
		return nil, toStatus(err)
	}
	if !entry.Enabled {
		// Nothing should keep talking to a node that was switched off.
		s.module.dropConnection(entry.ID)
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
	// own. Fetching it here means a node becomes usable for chat as soon as it
	// is reachable, rather than at the first message.
	if strings.TrimSpace(updated.GatewayKey) == "" && strings.TrimSpace(updated.GatewayBaseURL) != "" {
		if issued := m.issueGatewayKey(ctx, nodeID); issued.ID != "" {
			updated = issued
		}
	}
	return updated
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
	issued, err := client.IssueGatewayKey(callCtx, &nodev1.IssueGatewayKeyRequest{Label: "Culpeo Studio"})
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
		// Nothing to report and nothing to run: the tunnel is somebody else's.
		message.State = nodev1.TunnelState_TUNNEL_STATE_UNSPECIFIED
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
	default:
		return status.Error(codes.Internal, err.Error())
	}
}
