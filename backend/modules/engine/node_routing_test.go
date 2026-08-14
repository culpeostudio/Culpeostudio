package engine

import (
	"context"
	"net"
	"strings"
	"sync"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	enginev1 "github.com/culpeohq/backend/gen/go/culpeostudio/engine/v1"
	"github.com/culpeohq/backend/modules/node"
)

// stubNodeEngine is a node's engine, reduced to the calls the routing sends
// it. It records what it was asked, because the point of these tests is that
// a node is addressed with its own identifiers rather than the qualified ones
// the Studio carries around.
type stubNodeEngine struct {
	enginev1.UnimplementedEngineServiceServer

	instances     []*enginev1.EngineInstance
	models        []*enginev1.ModelRecord
	lastInstance  string
	lastModel     string
	lastAuthority string
	updateChange  string
}

func (s *stubNodeEngine) noteAuthority(ctx context.Context) {
	if md, ok := metadata.FromIncomingContext(ctx); ok {
		if values := md.Get("authorization"); len(values) > 0 {
			s.lastAuthority = values[0]
		}
	}
}

func (s *stubNodeEngine) ListInstances(ctx context.Context, _ *enginev1.ListInstancesRequest) (*enginev1.ListInstancesResponse, error) {
	s.noteAuthority(ctx)
	return &enginev1.ListInstancesResponse{Instances: s.instances}, nil
}

func (s *stubNodeEngine) ListModels(ctx context.Context, _ *enginev1.ListModelsRequest) (*enginev1.ListModelsResponse, error) {
	s.noteAuthority(ctx)
	return &enginev1.ListModelsResponse{Models: s.models, ModelDir: "/srv/models"}, nil
}

func (s *stubNodeEngine) GetInstance(ctx context.Context, req *enginev1.GetInstanceRequest) (*enginev1.GetInstanceResponse, error) {
	s.noteAuthority(ctx)
	s.lastInstance = req.GetInstanceId()
	for _, instance := range s.instances {
		if instance.GetId() == req.GetInstanceId() {
			return &enginev1.GetInstanceResponse{Instance: instance}, nil
		}
	}
	return nil, status.Error(codes.NotFound, "unbekannte Instanz")
}

func (s *stubNodeEngine) UpdateInstance(ctx context.Context, req *enginev1.UpdateInstanceRequest) (*enginev1.UpdateInstanceResponse, error) {
	s.noteAuthority(ctx)
	s.lastInstance = req.GetInstanceId()
	switch req.GetChange().(type) {
	case *enginev1.UpdateInstanceRequest_Start:
		s.updateChange = "start"
	case *enginev1.UpdateInstanceRequest_Stop:
		s.updateChange = "stop"
	default:
		s.updateChange = "other"
	}
	return &enginev1.UpdateInstanceResponse{
		Instance:    s.instances[0],
		OperationId: "op-7",
	}, nil
}

func (s *stubNodeEngine) CreateInstance(ctx context.Context, req *enginev1.CreateInstanceRequest) (*enginev1.CreateInstanceResponse, error) {
	s.noteAuthority(ctx)
	s.lastModel = req.GetModelId()
	return &enginev1.CreateInstanceResponse{
		Instance:    s.instances[0],
		OperationId: "op-9",
	}, nil
}

// stubDirectory stands in for the node registry, pointing at the stub server.
type stubDirectory struct {
	target     node.Target
	connection *grpc.ClientConn
}

func (d *stubDirectory) EnabledTargets() []node.Target { return []node.Target{d.target} }

func (d *stubDirectory) LookupTarget(nodeID string) (node.Target, bool) {
	if nodeID == d.target.ID {
		return d.target, true
	}
	return node.Target{}, false
}

func (d *stubDirectory) Dial(nodeID string) (*grpc.ClientConn, error) {
	if nodeID != d.target.ID {
		return nil, status.Error(codes.NotFound, "unbekannter Node")
	}
	return d.connection, nil
}

// startStubNode runs the stub on loopback and wires a module to it.
func startStubNode(t *testing.T, module *EngineModule, stub *stubNodeEngine) *stubDirectory {
	t.Helper()
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	server := grpc.NewServer()
	enginev1.RegisterEngineServiceServer(server, stub)
	go func() { _ = server.Serve(listener) }()
	t.Cleanup(server.Stop)

	connection, err := grpc.NewClient(listener.Addr().String(), grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	t.Cleanup(func() { _ = connection.Close() })

	directory := &stubDirectory{
		target: node.Target{
			ID: "nodeone", Name: "Werkstatt", Address: "127.0.0.1",
			GatewayKey: "gateway-secret", GatewayBaseURL: "http://127.0.0.1:9999",
		},
		connection: connection,
	}
	module.SetNodes(directory)
	return directory
}

func nodeInstance(id, modelID string, state enginev1.InstanceState) *enginev1.EngineInstance {
	return &enginev1.EngineInstance{
		Id: id, ModelId: modelID, State: state, ServedModelName: "qwen3",
		Plan: &enginev1.ContextPlan{EffectiveContextTokens: 8192},
	}
}

func TestListInstancesMergesNodeInstances(t *testing.T) {
	module, service := newGRPCEngineModule(t)
	stub := &stubNodeEngine{instances: []*enginev1.EngineInstance{
		nodeInstance("inst-1", "org/model", enginev1.InstanceState_INSTANCE_STATE_READY),
	}}
	startStubNode(t, module, stub)

	response, err := service.ListInstances(context.Background(), &enginev1.ListInstancesRequest{})
	if err != nil {
		t.Fatalf("ListInstances: %v", err)
	}
	var found *enginev1.EngineInstance
	for _, instance := range response.GetInstances() {
		if instance.GetNodeId() != "" {
			found = instance
		}
	}
	if found == nil {
		t.Fatal("the node's instance is missing from the merged list")
	}
	// The id has to say where it lives, or the next call has nowhere to go.
	if found.GetId() != "n:nodeone:inst-1" {
		t.Errorf("instance id = %q, want n:nodeone:inst-1", found.GetId())
	}
	if found.GetModelId() != "n:nodeone:org/model" {
		t.Errorf("model id = %q, want it qualified too", found.GetModelId())
	}
	if found.GetNodeName() != "Werkstatt" {
		t.Errorf("node name = %q", found.GetNodeName())
	}
}

func TestListModelsMergesNodeCatalog(t *testing.T) {
	module, service := newGRPCEngineModule(t)
	stub := &stubNodeEngine{models: []*enginev1.ModelRecord{
		{Id: "org/remote", Name: "remote", Status: enginev1.ModelStatus_MODEL_STATUS_READY},
	}}
	startStubNode(t, module, stub)

	response, err := service.ListModels(context.Background(), &enginev1.ListModelsRequest{})
	if err != nil {
		t.Fatalf("ListModels: %v", err)
	}
	local, remote := 0, 0
	for _, record := range response.GetModels() {
		if record.GetNodeId() == "" {
			local++
			continue
		}
		remote++
		if record.GetId() != "n:nodeone:org/remote" {
			t.Errorf("node model id = %q, want it qualified", record.GetId())
		}
	}
	if local == 0 {
		t.Error("the local catalog disappeared from the merged list")
	}
	if remote != 1 {
		t.Errorf("node models in the list = %d, want 1", remote)
	}
}

func TestInstanceCallsRouteToTheNodeUnqualified(t *testing.T) {
	module, service := newGRPCEngineModule(t)
	stub := &stubNodeEngine{instances: []*enginev1.EngineInstance{
		nodeInstance("inst-1", "org/model", enginev1.InstanceState_INSTANCE_STATE_READY),
	}}
	startStubNode(t, module, stub)

	got, err := service.GetInstance(context.Background(), &enginev1.GetInstanceRequest{
		InstanceId: "n:nodeone:inst-1",
	})
	if err != nil {
		t.Fatalf("GetInstance: %v", err)
	}
	if stub.lastInstance != "inst-1" {
		t.Errorf("the node was asked for %q; it only knows its own ids", stub.lastInstance)
	}
	if got.GetInstance().GetId() != "n:nodeone:inst-1" {
		t.Errorf("the answer came back unqualified: %q", got.GetInstance().GetId())
	}

	updated, err := service.UpdateInstance(context.Background(), &enginev1.UpdateInstanceRequest{
		InstanceId: "n:nodeone:inst-1",
		Change:     &enginev1.UpdateInstanceRequest_Stop{Stop: &enginev1.StopInstance{}},
	})
	if err != nil {
		t.Fatalf("UpdateInstance: %v", err)
	}
	if stub.updateChange != "stop" {
		t.Errorf("the change did not survive the forward: %q", stub.updateChange)
	}
	// An operation id has to be routable too, or polling it lands here.
	if updated.GetOperationId() != "n:nodeone:op-7" {
		t.Errorf("operation id = %q, want n:nodeone:op-7", updated.GetOperationId())
	}
}

func TestCreateInstanceFollowsAQualifiedModel(t *testing.T) {
	module, service := newGRPCEngineModule(t)
	stub := &stubNodeEngine{instances: []*enginev1.EngineInstance{
		nodeInstance("inst-1", "org/model", enginev1.InstanceState_INSTANCE_STATE_STARTING),
	}}
	startStubNode(t, module, stub)

	response, err := service.CreateInstance(context.Background(), &enginev1.CreateInstanceRequest{
		ModelId: "n:nodeone:org/remote",
	})
	if err != nil {
		t.Fatalf("CreateInstance: %v", err)
	}
	if stub.lastModel != "org/remote" {
		t.Errorf("the node was asked to start %q, want org/remote", stub.lastModel)
	}
	if response.GetInstance().GetNodeId() != "nodeone" {
		t.Error("the new instance does not say which node it runs on")
	}

	// The node may also be named outright, for a model id that carries no node
	// of its own.
	stub.lastModel = ""
	if _, err := service.CreateInstance(context.Background(), &enginev1.CreateInstanceRequest{
		ModelId: "org/remote", NodeId: "nodeone",
	}); err != nil {
		t.Fatalf("CreateInstance with an explicit node: %v", err)
	}
	if stub.lastModel != "org/remote" {
		t.Errorf("the node was asked to start %q", stub.lastModel)
	}
}

func TestCallsForAnUnknownNodeFailWithoutTouchingTheLocalEngine(t *testing.T) {
	module, service := newGRPCEngineModule(t)
	startStubNode(t, module, &stubNodeEngine{})

	_, err := service.GetInstance(context.Background(), &enginev1.GetInstanceRequest{
		InstanceId: "n:missing:inst-1",
	})
	if err == nil {
		t.Fatal("an instance on a node that is not registered should not resolve")
	}
	if got := status.Code(err); got != codes.NotFound {
		t.Errorf("status = %s, want NotFound (%v)", got, err)
	}
}

func TestQuantizationRefusesNodeModelsClearly(t *testing.T) {
	module, service := newGRPCEngineModule(t)
	startStubNode(t, module, &stubNodeEngine{})

	_, err := service.StartQuantization(context.Background(), &enginev1.StartQuantizationRequest{
		Request: &enginev1.QuantizationRequest{SourceModelId: "n:nodeone:org/remote"},
	})
	if err == nil {
		t.Fatal("quantising a model on another machine should be refused")
	}
	if got := status.Code(err); got != codes.FailedPrecondition {
		t.Errorf("status = %s, want FailedPrecondition", got)
	}
	if !strings.Contains(err.Error(), "lokale") {
		t.Errorf("the refusal should say why, got: %v", err)
	}
}

// The feed opens with a snapshot the client replaces its whole list with, so a
// node's instances have to be in it or they are treated as gone.
func TestEventSnapshotCarriesNodeInstances(t *testing.T) {
	module, service := newGRPCEngineModule(t)
	stub := &stubNodeEngine{instances: []*enginev1.EngineInstance{
		nodeInstance("inst-1", "org/model", enginev1.InstanceState_INSTANCE_STATE_READY),
	}}
	startStubNode(t, module, stub)

	stream := &recordingEventStream{ctx: context.Background(), done: make(chan struct{})}
	go func() { _ = service.StreamEvents(&enginev1.StreamEventsRequest{}, stream) }()

	select {
	case <-stream.done:
	case <-time.After(10 * time.Second):
		t.Fatal("the feed sent no snapshot")
	}

	found := false
	for _, instance := range stream.snapshot() {
		if instance.GetId() == "n:nodeone:inst-1" {
			found = true
		}
	}
	if !found {
		t.Error("the opening snapshot left the node's instance out")
	}
}

// The watcher is what keeps a node's instances in the client's list after the
// snapshot. It has to be quiet about instances that have not changed, and it
// must not report deletions for a node that simply did not answer.
func TestNodeInstanceWatcherPublishesOnlyRealChanges(t *testing.T) {
	module, _ := newGRPCEngineModule(t)
	stub := &stubNodeEngine{instances: []*enginev1.EngineInstance{
		nodeInstance("inst-1", "org/model", enginev1.InstanceState_INSTANCE_STATE_STARTING),
	}}
	directory := startStubNode(t, module, stub)

	events, unsubscribe := module.events.subscribe()
	defer unsubscribe()
	lastSeen := map[string]*enginev1.EngineInstance{}

	module.publishNodeInstanceChanges(lastSeen)
	if got := drainEventTypes(events); len(got) != 1 || got[0] != "instance_created" {
		t.Fatalf("first round published %v, want one instance_created", got)
	}

	// Nothing moved, so nothing should be said.
	module.publishNodeInstanceChanges(lastSeen)
	if got := drainEventTypes(events); len(got) != 0 {
		t.Errorf("an unchanged instance published %v", got)
	}

	stub.instances = []*enginev1.EngineInstance{
		nodeInstance("inst-1", "org/model", enginev1.InstanceState_INSTANCE_STATE_READY),
	}
	module.publishNodeInstanceChanges(lastSeen)
	if got := drainEventTypes(events); len(got) != 1 || got[0] != "instance_changed" {
		t.Errorf("a state change published %v, want one instance_changed", got)
	}

	// A node that cannot be reached has told us nothing; its instances are not
	// gone, and announcing them as deleted would empty the list on a hiccup.
	directory.connection.Close()
	module.publishNodeInstanceChanges(lastSeen)
	if got := drainEventTypes(events); len(got) != 0 {
		t.Errorf("an unreachable node published %v, want silence", got)
	}
	if _, still := lastSeen["n:nodeone:inst-1"]; !still {
		t.Error("the instance was forgotten because its node went quiet")
	}
}

// recordingEventStream stands in for a client's feed, capturing the opening
// snapshot and then getting out of the way.
type recordingEventStream struct {
	grpc.ServerStream

	ctx      context.Context
	mu       sync.Mutex
	captured []*enginev1.EngineInstance
	done     chan struct{}
	closed   bool
}

func (s *recordingEventStream) Context() context.Context { return s.ctx }

func (s *recordingEventStream) Send(response *enginev1.StreamEventsResponse) error {
	if snapshot := response.GetSnapshot(); snapshot != nil {
		s.mu.Lock()
		s.captured = snapshot.GetInstances()
		if !s.closed {
			s.closed = true
			close(s.done)
		}
		s.mu.Unlock()
	}
	return nil
}

func (s *recordingEventStream) snapshot() []*enginev1.EngineInstance {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.captured
}

// drainEventTypes collects the instance events that arrived. The engine's own
// maintenance publishes on the same hub, so anything that is not about an
// instance is somebody else's traffic.
func drainEventTypes(events <-chan engineEvent) []string {
	var types []string
	for {
		select {
		case event := <-events:
			if strings.HasPrefix(event.Type, "instance_") {
				types = append(types, event.Type)
			}
		case <-time.After(150 * time.Millisecond):
			return types
		}
	}
}

// Without a node registry the engine has to behave exactly as it did before.
func TestEngineWithoutNodesIsUnchanged(t *testing.T) {
	_, service := newGRPCEngineModule(t)

	models, err := service.ListModels(context.Background(), &enginev1.ListModelsRequest{})
	if err != nil {
		t.Fatalf("ListModels: %v", err)
	}
	for _, record := range models.GetModels() {
		if record.GetNodeId() != "" {
			t.Errorf("a model claims to be on node %q with no registry wired", record.GetNodeId())
		}
	}
	if _, err := service.GetInstance(context.Background(), &enginev1.GetInstanceRequest{
		InstanceId: "n:nodeone:inst-1",
	}); status.Code(err) != codes.FailedPrecondition {
		t.Errorf("a node id without a registry should say so, got %v", err)
	}
}
