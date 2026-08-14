package engine

import (
	"context"
	"log"
	"strings"
	"sync"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	enginev1 "github.com/culpeohq/backend/gen/go/culpeostudio/engine/v1"
	"github.com/culpeohq/backend/modules/node"
)

// nodeCallTimeout bounds a call a user made: starting a model, stopping one,
// reading one back. Every one of them schedules work and returns, so twenty
// seconds is generous rather than tight.
const nodeCallTimeout = 20 * time.Second

// nodeListTimeout bounds the calls behind a list. Those are polled while a
// screen is open, so an unreachable node has to fall out of them quickly: the
// local catalog is what the user is looking at, and it must not wait on a
// machine that is switched off.
const nodeListTimeout = 4 * time.Second

// SetNodes wires the node registry. Without one the engine is what it always
// was: the models and instances of this machine.
func (m *EngineModule) SetNodes(directory node.Directory) { m.nodes = directory }

// nodeTargets lists the nodes a merged view should include.
func (m *EngineModule) nodeTargets() []node.Target {
	if m.nodes == nil {
		return nil
	}
	return m.nodes.EnabledTargets()
}

// nodeEngine resolves a node and a client for its engine.
func (m *EngineModule) nodeEngine(nodeID string) (node.Target, enginev1.EngineServiceClient, error) {
	if m.nodes == nil {
		return node.Target{}, nil, status.Error(codes.FailedPrecondition, "Nodes sind in dieser Instanz nicht eingerichtet")
	}
	target, ok := m.nodes.LookupTarget(nodeID)
	if !ok {
		return node.Target{}, nil, status.Errorf(codes.NotFound, "Node %s ist nicht hinterlegt", nodeID)
	}
	connection, err := m.nodes.Dial(nodeID)
	if err != nil {
		return node.Target{}, nil, status.Errorf(codes.FailedPrecondition, "Node %s: %v", target.Name, err)
	}
	return target, enginev1.NewEngineServiceClient(connection), nil
}

// nodeEngineFor resolves the node an identifier belongs to. It reports false
// for a local identifier, which is the ordinary case.
func (m *EngineModule) nodeEngineFor(id string) (node.Target, enginev1.EngineServiceClient, string, bool, error) {
	nodeID, localID, remote := node.Split(id)
	if !remote {
		return node.Target{}, nil, id, false, nil
	}
	target, client, err := m.nodeEngine(nodeID)
	if err != nil {
		return node.Target{}, nil, "", true, err
	}
	return target, client, localID, true, nil
}

// nodeError names the node in whatever it answered. An engine error that talks
// about free VRAM is confusing without saying whose.
func nodeError(target node.Target, err error) error {
	if err == nil {
		return nil
	}
	name := strings.TrimSpace(target.Name)
	if name == "" {
		name = target.ID
	}
	if statusErr, ok := status.FromError(err); ok {
		return status.Errorf(statusErr.Code(), "Node %s: %s", name, statusErr.Message())
	}
	return status.Errorf(codes.Unavailable, "Node %s: %v", name, err)
}

// The conversions below rewrite what a node sent so it can live beside local
// entries. Every identifier a client may send back is qualified with the node,
// which is what lets the next call route itself.

func qualifyModelRecord(target node.Target, record *enginev1.ModelRecord) *enginev1.ModelRecord {
	if record == nil {
		return nil
	}
	record.Id = node.Qualify(target.ID, record.GetId())
	record.NodeId = target.ID
	record.NodeName = target.Name
	return record
}

func qualifyInstance(target node.Target, instance *enginev1.EngineInstance) *enginev1.EngineInstance {
	if instance == nil {
		return nil
	}
	instance.Id = node.Qualify(target.ID, instance.GetId())
	instance.ModelId = node.Qualify(target.ID, instance.GetModelId())
	instance.NodeId = target.ID
	instance.NodeName = target.Name
	return instance
}

// nodeModels collects the catalogs of every enabled node.
//
// A node that does not answer is left out with a log line rather than failing
// the call: the local catalog is still worth showing, and the node screen is
// where an unreachable node is reported.
func (m *EngineModule) nodeModels(ctx context.Context) []*enginev1.ModelRecord {
	return fanOutToNodes(ctx, m, "Modelle", func(ctx context.Context, target node.Target, client enginev1.EngineServiceClient) ([]*enginev1.ModelRecord, error) {
		response, err := client.ListModels(ctx, &enginev1.ListModelsRequest{})
		if err != nil {
			return nil, err
		}
		records := make([]*enginev1.ModelRecord, 0, len(response.GetModels()))
		for _, record := range response.GetModels() {
			records = append(records, qualifyModelRecord(target, record))
		}
		return records, nil
	})
}

// fanOutToNodes asks every enabled node the same question at once and returns
// what answered in time.
//
// Concurrent, because the alternative is that four nodes cost four timeouts in
// a row. Failures are logged and dropped rather than returned: a merged list
// exists to show what is there, and a node that is off says so on its own
// screen.
func fanOutToNodes[T any](
	ctx context.Context,
	m *EngineModule,
	what string,
	ask func(context.Context, node.Target, enginev1.EngineServiceClient) ([]T, error),
) []T {
	targets := m.nodeTargets()
	if len(targets) == 0 {
		return nil
	}
	results := make([][]T, len(targets))
	var waiting sync.WaitGroup
	for index, target := range targets {
		_, client, err := m.nodeEngine(target.ID)
		if err != nil {
			continue
		}
		waiting.Add(1)
		go func(index int, target node.Target, client enginev1.EngineServiceClient) {
			defer waiting.Done()
			callCtx, cancel := context.WithTimeout(ctx, nodeListTimeout)
			defer cancel()
			answered, askErr := ask(callCtx, target, client)
			if askErr != nil {
				log.Printf("[engine] %s von Node %s: %v", what, target.Name, askErr)
				return
			}
			results[index] = answered
		}(index, target, client)
	}
	waiting.Wait()

	var collected []T
	for _, answered := range results {
		collected = append(collected, answered...)
	}
	return collected
}

// rescanNodeModels asks every node to look at its own model directory again.
// A download that finished there is only in its catalog after this, which is
// exactly what the user pressed the button for.
func (m *EngineModule) rescanNodeModels(ctx context.Context) []*enginev1.ModelRecord {
	return fanOutToNodes(ctx, m, "Neu-Einlesen", func(ctx context.Context, target node.Target, client enginev1.EngineServiceClient) ([]*enginev1.ModelRecord, error) {
		response, err := client.RescanModels(ctx, &enginev1.RescanModelsRequest{})
		if err != nil {
			return nil, err
		}
		records := make([]*enginev1.ModelRecord, 0, len(response.GetModels()))
		for _, record := range response.GetModels() {
			records = append(records, qualifyModelRecord(target, record))
		}
		return records, nil
	})
}

// deleteModelOnNode removes a model from the machine that holds it and hands
// back that machine's catalog, qualified.
func (m *EngineModule) deleteModelOnNode(ctx context.Context, target node.Target, client enginev1.EngineServiceClient, modelID string) (*enginev1.DeleteModelResponse, error) {
	callCtx, cancel := context.WithTimeout(ctx, nodeCallTimeout)
	defer cancel()
	response, err := client.DeleteModel(callCtx, &enginev1.DeleteModelRequest{ModelId: modelID})
	if err != nil {
		return nil, nodeError(target, err)
	}
	for _, record := range response.GetModels() {
		qualifyModelRecord(target, record)
	}
	return response, nil
}

// nodeInstances does the same for what the nodes are running.
func (m *EngineModule) nodeInstances(ctx context.Context) []*enginev1.EngineInstance {
	return fanOutToNodes(ctx, m, "Instanzen", func(ctx context.Context, target node.Target, client enginev1.EngineServiceClient) ([]*enginev1.EngineInstance, error) {
		response, err := client.ListInstances(ctx, &enginev1.ListInstancesRequest{})
		if err != nil {
			return nil, err
		}
		instances := make([]*enginev1.EngineInstance, 0, len(response.GetInstances()))
		for _, instance := range response.GetInstances() {
			instances = append(instances, qualifyInstance(target, instance))
		}
		return instances, nil
	})
}

// createInstanceOnNode starts a model on the machine that holds it.
func (m *EngineModule) createInstanceOnNode(
	ctx context.Context,
	nodeID string,
	req *enginev1.CreateInstanceRequest,
	modelID string,
) (*enginev1.CreateInstanceResponse, error) {
	target, client, err := m.nodeEngine(nodeID)
	if err != nil {
		return nil, err
	}
	callCtx, cancel := context.WithTimeout(ctx, nodeCallTimeout)
	defer cancel()
	response, err := client.CreateInstance(callCtx, &enginev1.CreateInstanceRequest{
		ModelId:         modelID,
		ServedModelName: req.GetServedModelName(),
		Config:          req.GetConfig(),
	})
	if err != nil {
		return nil, nodeError(target, err)
	}
	response.Instance = qualifyInstance(target, response.GetInstance())
	response.OperationId = node.Qualify(target.ID, response.GetOperationId())
	return response, nil
}

// The remaining forwards are one-liners around the same shape: send the local
// identifier, qualify whatever comes back.

func (m *EngineModule) getInstanceFromNode(ctx context.Context, target node.Target, client enginev1.EngineServiceClient, instanceID string) (*enginev1.GetInstanceResponse, error) {
	callCtx, cancel := context.WithTimeout(ctx, nodeCallTimeout)
	defer cancel()
	response, err := client.GetInstance(callCtx, &enginev1.GetInstanceRequest{InstanceId: instanceID})
	if err != nil {
		return nil, nodeError(target, err)
	}
	response.Instance = qualifyInstance(target, response.GetInstance())
	return response, nil
}

func (m *EngineModule) updateInstanceOnNode(ctx context.Context, target node.Target, client enginev1.EngineServiceClient, req *enginev1.UpdateInstanceRequest, instanceID string) (*enginev1.UpdateInstanceResponse, error) {
	forwarded := &enginev1.UpdateInstanceRequest{InstanceId: instanceID, Change: req.GetChange()}
	callCtx, cancel := context.WithTimeout(ctx, nodeCallTimeout)
	defer cancel()
	response, err := client.UpdateInstance(callCtx, forwarded)
	if err != nil {
		return nil, nodeError(target, err)
	}
	response.Instance = qualifyInstance(target, response.GetInstance())
	response.OperationId = node.Qualify(target.ID, response.GetOperationId())
	return response, nil
}

func (m *EngineModule) deleteInstanceOnNode(ctx context.Context, target node.Target, client enginev1.EngineServiceClient, instanceID string) (*enginev1.DeleteInstanceResponse, error) {
	callCtx, cancel := context.WithTimeout(ctx, nodeCallTimeout)
	defer cancel()
	response, err := client.DeleteInstance(callCtx, &enginev1.DeleteInstanceRequest{InstanceId: instanceID})
	if err != nil {
		return nil, nodeError(target, err)
	}
	response.Instance = qualifyInstance(target, response.GetInstance())
	response.OperationId = node.Qualify(target.ID, response.GetOperationId())
	return response, nil
}

func (m *EngineModule) ensureReadyOnNode(ctx context.Context, target node.Target, client enginev1.EngineServiceClient, instanceID string) (*enginev1.EnsureInstanceReadyResponse, error) {
	callCtx, cancel := context.WithTimeout(ctx, nodeCallTimeout)
	defer cancel()
	response, err := client.EnsureInstanceReady(callCtx, &enginev1.EnsureInstanceReadyRequest{InstanceId: instanceID})
	if err != nil {
		return nil, nodeError(target, err)
	}
	response.Instance = qualifyInstance(target, response.GetInstance())
	response.OperationId = node.Qualify(target.ID, response.GetOperationId())
	return response, nil
}

func (m *EngineModule) getOperationFromNode(ctx context.Context, target node.Target, client enginev1.EngineServiceClient, operationID string) (*enginev1.GetOperationResponse, error) {
	callCtx, cancel := context.WithTimeout(ctx, nodeCallTimeout)
	defer cancel()
	response, err := client.GetOperation(callCtx, &enginev1.GetOperationRequest{OperationId: operationID})
	if err != nil {
		return nil, nodeError(target, err)
	}
	response.Operation = qualifyOperation(target, response.GetOperation())
	return response, nil
}

func (m *EngineModule) cancelOperationOnNode(ctx context.Context, target node.Target, client enginev1.EngineServiceClient, operationID string) (*enginev1.CancelOperationResponse, error) {
	callCtx, cancel := context.WithTimeout(ctx, nodeCallTimeout)
	defer cancel()
	response, err := client.CancelOperation(callCtx, &enginev1.CancelOperationRequest{OperationId: operationID})
	if err != nil {
		return nil, nodeError(target, err)
	}
	response.Operation = qualifyOperation(target, response.GetOperation())
	return response, nil
}

func qualifyOperation(target node.Target, operation *enginev1.EngineOperation) *enginev1.EngineOperation {
	if operation == nil {
		return nil
	}
	operation.Id = node.Qualify(target.ID, operation.GetId())
	operation.InstanceId = node.Qualify(target.ID, operation.GetInstanceId())
	for index, evicted := range operation.GetEvictedInstanceIds() {
		operation.EvictedInstanceIds[index] = node.Qualify(target.ID, evicted)
	}
	return operation
}

// errNodeOnlyLocal is what the calls that cannot cross a machine boundary
// answer. Quantising rewrites a file in place and presets are this Studio's
// own; neither means anything aimed at a node.
func errNodeOnlyLocal(what string) error {
	return status.Errorf(codes.FailedPrecondition, "%s ist nur fuer lokale Modelle moeglich", what)
}
