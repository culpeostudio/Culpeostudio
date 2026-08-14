package marketplace

import (
	"context"
	"log"
	"sort"
	"strings"
	"sync"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	marketplacev1 "github.com/culpeohq/backend/gen/go/culpeostudio/marketplace/v1"
	"github.com/culpeohq/backend/modules/node"
)

// SetNodes wires the node registry. Without one the marketplace behaves as it
// always has: every download happens on this machine.
func (m *MarketplaceModule) SetNodes(directory node.Directory) { m.nodes = directory }

// startDownloadOnNode hands the job to the machine that will keep the model.
//
// Only the request travels. The node fetches from the model host itself, which
// is the whole reason for aiming a download at one: pulling tens of gigabytes
// to this machine and pushing them on would take twice as long and need the
// disk space twice over.
func (s *grpcService) startDownloadOnNode(
	ctx context.Context,
	nodeID string,
	req *marketplacev1.StartDownloadRequest,
) (*marketplacev1.StartDownloadResponse, error) {
	target, client, err := s.module.nodeClientWithTarget(nodeID)
	if err != nil {
		return nil, err
	}

	forwarded := &marketplacev1.StartDownloadRequest{
		Provider:  req.GetProvider(),
		ModelId:   req.GetModelId(),
		AssetId:   req.GetAssetId(),
		AssetIds:  req.GetAssetIds(),
		Revision:  req.GetRevision(),
		TargetDir: req.GetTargetDir(),
		SizeBytes: req.GetSizeBytes(),
		// Cleared on purpose: to the node this is a local download, and a node
		// does not forward to further nodes.
	}
	callCtx, cancel := context.WithTimeout(ctx, nodeCallTimeout)
	defer cancel()
	response, err := client.StartDownload(callCtx, forwarded)
	if err != nil {
		return nil, nodeCallError(target, err)
	}
	return &marketplacev1.StartDownloadResponse{
		JobId:     node.Qualify(nodeID, response.GetJobId()),
		Status:    response.GetStatus(),
		Existing:  response.GetExisting(),
		TargetDir: response.GetTargetDir(),
	}, nil
}

// nodeDownloadJobs collects what every enabled node is downloading, so the
// downloads list is one list rather than one per machine.
//
// A node that does not answer is skipped rather than failing the call: the
// local jobs are still worth showing, and the node's own state is reported by
// the node screen.
func (m *MarketplaceModule) nodeDownloadJobs(ctx context.Context) []*marketplacev1.DownloadJob {
	if m.nodes == nil {
		return nil
	}
	targets := m.nodes.EnabledTargets()
	if len(targets) == 0 {
		return nil
	}
	// Asked at once rather than one after another: this list is polled while
	// the downloads panel is open, and four unreachable nodes must not cost
	// four timeouts in a row.
	results := make([][]*marketplacev1.DownloadJob, len(targets))
	var waiting sync.WaitGroup
	for index, target := range targets {
		client, err := m.marketplaceClient(target.ID)
		if err != nil {
			continue
		}
		waiting.Add(1)
		go func(index int, target node.Target, client marketplacev1.MarketplaceServiceClient) {
			defer waiting.Done()
			callCtx, cancel := context.WithTimeout(ctx, nodeListTimeout)
			defer cancel()
			response, err := client.ListDownloadJobs(callCtx, &marketplacev1.ListDownloadJobsRequest{})
			if err != nil {
				log.Printf("[marketplace] Downloads von Node %s: %v", target.Name, err)
				return
			}
			jobs := make([]*marketplacev1.DownloadJob, 0, len(response.GetJobs()))
			for _, job := range response.GetJobs() {
				if job == nil {
					continue
				}
				job.Id = node.Qualify(target.ID, job.GetId())
				job.NodeId = target.ID
				job.NodeName = target.Name
				jobs = append(jobs, job)
			}
			results[index] = jobs
		}(index, target, client)
	}
	waiting.Wait()

	var collected []*marketplacev1.DownloadJob
	for _, jobs := range results {
		collected = append(collected, jobs...)
	}
	return collected
}

// sortJobsNewestFirst restores the order the local store hands its jobs back
// in, after local and node jobs have been merged.
func sortJobsNewestFirst(jobs []*marketplacev1.DownloadJob) {
	sort.SliceStable(jobs, func(first, second int) bool {
		left, right := jobs[first].GetCreatedAt(), jobs[second].GetCreatedAt()
		if left == nil || right == nil {
			return left != nil
		}
		return left.AsTime().After(right.AsTime())
	})
}

// getDownloadJobFromNode reads one job back off the node that owns it.
func (m *MarketplaceModule) getDownloadJobFromNode(ctx context.Context, nodeID, jobID string) (*marketplacev1.DownloadJob, error) {
	target, client, err := m.nodeClientWithTarget(nodeID)
	if err != nil {
		return nil, err
	}
	callCtx, cancel := context.WithTimeout(ctx, nodeCallTimeout)
	defer cancel()
	response, err := client.GetDownloadJob(callCtx, &marketplacev1.GetDownloadJobRequest{Id: jobID})
	if err != nil {
		return nil, nodeCallError(target, err)
	}
	job := response.GetJob()
	if job == nil {
		return nil, status.Error(codes.NotFound, "job nicht gefunden")
	}
	job.Id = node.Qualify(nodeID, job.GetId())
	job.NodeId = target.ID
	job.NodeName = target.Name
	return job, nil
}

// deleteDownloadJobOnNode cancels or forgets a job where it runs.
func (m *MarketplaceModule) deleteDownloadJobOnNode(ctx context.Context, nodeID, jobID string) error {
	target, client, err := m.nodeClientWithTarget(nodeID)
	if err != nil {
		return err
	}
	callCtx, cancel := context.WithTimeout(ctx, nodeCallTimeout)
	defer cancel()
	if _, err := client.DeleteDownloadJob(callCtx, &marketplacev1.DeleteDownloadJobRequest{Id: jobID}); err != nil {
		return nodeCallError(target, err)
	}
	return nil
}

func (m *MarketplaceModule) marketplaceClient(nodeID string) (marketplacev1.MarketplaceServiceClient, error) {
	_, client, err := m.nodeClientWithTarget(nodeID)
	return client, err
}

func (m *MarketplaceModule) nodeClientWithTarget(nodeID string) (node.Target, marketplacev1.MarketplaceServiceClient, error) {
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
	return target, marketplacev1.NewMarketplaceServiceClient(connection), nil
}

// nodeCallError names the node in whatever it answered, because an error that
// says only "not enough disk space" is confusing when the disk in question is
// on another machine.
func nodeCallError(target node.Target, err error) error {
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
