package marketplace

import (
	"context"
	"net"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	marketplacev1 "github.com/culpeohq/backend/gen/go/culpeostudio/marketplace/v1"
	"github.com/culpeohq/backend/modules/node"
)

// stubNodeMarketplace is a node's marketplace, reduced to the download calls.
type stubNodeMarketplace struct {
	marketplacev1.UnimplementedMarketplaceServiceServer

	jobs        []*marketplacev1.DownloadJob
	lastModelID string
	lastNodeID  string
	lastDeleted string
}

func (s *stubNodeMarketplace) StartDownload(_ context.Context, req *marketplacev1.StartDownloadRequest) (*marketplacev1.StartDownloadResponse, error) {
	s.lastModelID = req.GetModelId()
	s.lastNodeID = req.GetNodeId()
	return &marketplacev1.StartDownloadResponse{
		JobId:     "dl-remote",
		Status:    marketplacev1.DownloadStatus_DOWNLOAD_STATUS_QUEUED,
		TargetDir: "/srv/models",
	}, nil
}

func (s *stubNodeMarketplace) ListDownloadJobs(context.Context, *marketplacev1.ListDownloadJobsRequest) (*marketplacev1.ListDownloadJobsResponse, error) {
	return &marketplacev1.ListDownloadJobsResponse{Jobs: s.jobs}, nil
}

func (s *stubNodeMarketplace) DeleteDownloadJob(_ context.Context, req *marketplacev1.DeleteDownloadJobRequest) (*marketplacev1.DeleteDownloadJobResponse, error) {
	s.lastDeleted = req.GetId()
	return &marketplacev1.DeleteDownloadJobResponse{}, nil
}

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

func startStubNodeMarketplace(t *testing.T, module *MarketplaceModule, stub *stubNodeMarketplace) {
	t.Helper()
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	server := grpc.NewServer()
	marketplacev1.RegisterMarketplaceServiceServer(server, stub)
	go func() { _ = server.Serve(listener) }()
	t.Cleanup(server.Stop)

	connection, err := grpc.NewClient(listener.Addr().String(), grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	t.Cleanup(func() { _ = connection.Close() })

	module.SetNodes(&stubDirectory{
		target:     node.Target{ID: "nodeone", Name: "Werkstatt", Address: "10.77.0.1"},
		connection: connection,
	})
}

func TestStartDownloadOnANodeStaysThere(t *testing.T) {
	service := newTestService(t, `{"model_dir":"data/models"}`)
	stub := &stubNodeMarketplace{}
	startStubNodeMarketplace(t, service.module, stub)

	response, err := service.StartDownload(context.Background(), &marketplacev1.StartDownloadRequest{
		Provider: marketplacev1.Provider_PROVIDER_HUGGINGFACE,
		ModelId:  "org/model",
		AssetId:  "model.gguf",
		NodeId:   "nodeone",
	})
	if err != nil {
		t.Fatalf("StartDownload: %v", err)
	}
	if stub.lastModelID != "org/model" {
		t.Errorf("the node was asked for %q", stub.lastModelID)
	}
	// A node does not forward further; the field has to be cleared on the way.
	if stub.lastNodeID != "" {
		t.Errorf("the node was told to forward to %q", stub.lastNodeID)
	}
	if response.GetJobId() != "n:nodeone:dl-remote" {
		t.Errorf("job id = %q, want it qualified with the node", response.GetJobId())
	}
	// Nothing may have been started here.
	if jobs := service.module.jobs.List(); len(jobs) != 0 {
		t.Errorf("a local job was created as well: %+v", jobs)
	}
}

func TestListDownloadJobsMergesLocalAndNodeJobs(t *testing.T) {
	service := newTestService(t, `{"model_dir":"data/models"}`)
	stub := &stubNodeMarketplace{jobs: []*marketplacev1.DownloadJob{{
		Id:        "dl-remote",
		ModelId:   "org/remote",
		Status:    marketplacev1.DownloadStatus_DOWNLOAD_STATUS_RUNNING,
		CreatedAt: timestamppb.Now(),
	}}}
	startStubNodeMarketplace(t, service.module, stub)
	service.module.jobs.CreateWithAssets("huggingface", "org/local", "model.gguf", nil, t.TempDir())

	response, err := service.ListDownloadJobs(context.Background(), &marketplacev1.ListDownloadJobsRequest{})
	if err != nil {
		t.Fatalf("ListDownloadJobs: %v", err)
	}
	if len(response.GetJobs()) != 2 {
		t.Fatalf("jobs = %d, want the local one and the node's", len(response.GetJobs()))
	}
	var remote *marketplacev1.DownloadJob
	for _, job := range response.GetJobs() {
		if job.GetNodeId() != "" {
			remote = job
		}
	}
	if remote == nil {
		t.Fatal("the node's job is missing")
	}
	if remote.GetId() != "n:nodeone:dl-remote" {
		t.Errorf("node job id = %q, want it qualified", remote.GetId())
	}
	if remote.GetNodeName() != "Werkstatt" {
		t.Errorf("node name = %q", remote.GetNodeName())
	}
}

func TestDeleteDownloadJobRoutesToTheNode(t *testing.T) {
	service := newTestService(t, `{"model_dir":"data/models"}`)
	stub := &stubNodeMarketplace{}
	startStubNodeMarketplace(t, service.module, stub)

	if _, err := service.DeleteDownloadJob(context.Background(), &marketplacev1.DeleteDownloadJobRequest{
		Id: "n:nodeone:dl-remote",
	}); err != nil {
		t.Fatalf("DeleteDownloadJob: %v", err)
	}
	if stub.lastDeleted != "dl-remote" {
		t.Errorf("the node was asked to delete %q, want dl-remote", stub.lastDeleted)
	}
}

func TestDownloadToAnUnknownNodeIsRefused(t *testing.T) {
	service := newTestService(t, `{"model_dir":"data/models"}`)
	startStubNodeMarketplace(t, service.module, &stubNodeMarketplace{})

	_, err := service.StartDownload(context.Background(), &marketplacev1.StartDownloadRequest{
		Provider: marketplacev1.Provider_PROVIDER_HUGGINGFACE,
		ModelId:  "org/model",
		NodeId:   "missing",
	})
	if err == nil {
		t.Fatal("a download aimed at a node that is not registered should be refused")
	}
	if got := status.Code(err); got != codes.NotFound {
		t.Errorf("status = %s, want NotFound (%v)", got, err)
	}
	if jobs := service.module.jobs.List(); len(jobs) != 0 {
		t.Errorf("the download fell back to this machine: %+v", jobs)
	}
}
