package benchmark

import (
	"context"
	"strings"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	benchmarkv1 "github.com/culpeohq/backend/gen/go/culpeostudio/benchmark/v1"
)

type grpcService struct {
	benchmarkv1.UnimplementedBenchmarkServiceServer
	module *Module
}

func (m *Module) RegisterGRPC(server *grpc.Server) {
	benchmarkv1.RegisterBenchmarkServiceServer(server, &grpcService{module: m})
}

func (s *grpcService) ListBoards(
	ctx context.Context,
	req *benchmarkv1.ListBoardsRequest,
) (*benchmarkv1.ListBoardsResponse, error) {
	return &benchmarkv1.ListBoardsResponse{
		Boards:       boardInfosToProto(s.module.allBoards()),
		DefaultBoard: DefaultBoard,
	}, nil
}

func (s *grpcService) GetStatus(
	ctx context.Context,
	req *benchmarkv1.GetStatusRequest,
) (*benchmarkv1.GetStatusResponse, error) {
	boardKey := boardKeyOrDefault(req.GetBoard())
	infos := s.module.allBoards()

	response := &benchmarkv1.GetStatusResponse{
		Boards: boardInfosToProto(infos),
		State:  benchmarkv1.BoardState_BOARD_STATE_EMPTY,
	}
	for _, info := range infos {
		if info.Key == boardKey {
			response.Source = sourceInfoToProto(info.Source)
			response.State = boardStateToProto(info.Source.State)
			response.Error = info.Source.Error
		}
	}

	s.module.mu.RLock()
	if state, ok := s.module.state[boardKey]; ok {
		response.Loaded = int32(state.loadedRows)
		response.Expected = int32(state.expected)
	}
	s.module.mu.RUnlock()

	s.module.loadMu.Lock()
	response.Refreshing = s.module.loading[boardKey]
	s.module.loadMu.Unlock()

	return response, nil
}

func (s *grpcService) GetOverview(
	ctx context.Context,
	req *benchmarkv1.GetOverviewRequest,
) (*benchmarkv1.GetOverviewResponse, error) {
	boardKey := boardKeyOrDefault(req.GetBoard())
	entries, info := s.module.snapshotState(boardKey)

	unique := keepBestPerModel(filter(entries, Query{}))
	sortEntries(unique, primaryKey, "desc")

	open := filter(unique, Query{OpenWeightsOnly: true})

	return &benchmarkv1.GetOverviewResponse{
		Board:           boardInfoToProto(info),
		Boards:          boardInfosToProto(s.module.allBoards()),
		TotalEntries:    int32(len(entries)),
		TotalModels:     int32(len(unique)),
		MetricStats:     metricStatsToProto(s.module.metricStats(boardKey)),
		TopOverall:      entriesToProto(headOf(unique, 10)),
		TopByMetric:     entryListsToProto(topByMetric(unique, info.Metrics, 5)),
		TopOpenWeights:  entriesToProto(headOf(open, 10)),
		TopOpenByMetric: entryListsToProto(topByMetric(open, info.Metrics, 5)),
		TypeShare:       facetValuesToProto(shareOf(unique, func(entry Entry) string { return entry.Type })),
		OrgShare:        facetValuesToProto(shareOf(unique, func(entry Entry) string { return entry.Org })),
	}, nil
}

func (s *grpcService) GetLeaderboard(
	ctx context.Context,
	req *benchmarkv1.GetLeaderboardRequest,
) (*benchmarkv1.GetLeaderboardResponse, error) {
	boardKey := boardKeyOrDefault(req.GetBoard())
	entries, info := s.module.snapshotState(boardKey)
	query := queryFromRequest(req, info.Metrics)

	matched := filter(entries, query)
	if query.BestPerModel {
		matched = keepBestPerModel(matched)
	}
	facets := buildFacets(matched)
	sortEntries(matched, query.Sort, query.Order)

	response := &benchmarkv1.GetLeaderboardResponse{
		Board:  boardInfoToProto(info),
		Items:  entriesToProto(paginate(matched, query.Offset, query.Limit)),
		Total:  int32(len(matched)),
		Offset: int32(query.Offset),
		Limit:  int32(query.Limit),
		Sort:   query.Sort,
		Order:  sortOrderToProto(query.Order),
		Facets: facetsToProto(facets),
	}
	// A board that is not ready still answers, so the client can tell a thin
	// list from a filtered one.
	if info.Source.State != stateReady {
		response.Warning = boardStateToProto(info.Source.State)
	}
	return response, nil
}

func (s *grpcService) GetModel(
	ctx context.Context,
	req *benchmarkv1.GetModelRequest,
) (*benchmarkv1.GetModelResponse, error) {
	modelID := strings.TrimSpace(req.GetId())
	if modelID == "" {
		return nil, status.Error(codes.InvalidArgument, "Feld 'id' ist erforderlich")
	}

	boardKey := boardKeyOrDefault(req.GetBoard())
	entries, info := s.module.snapshotState(boardKey)
	detail := buildDetail(entries, modelID, info, true)

	if req.WithHub == nil || req.GetWithHub() {
		lookup := detail.ModelID
		if lookup == "" {
			lookup = modelID
		}
		stats, cardResults := s.module.hubStats(ctx, lookup)
		detail.Hub = stats
		detail.CardResults = cardResults
	}

	if len(detail.Entries) == 0 && (detail.Hub == nil || detail.Hub.Missing) {
		return nil, status.Errorf(
			codes.NotFound,
			"Modell %q weder in dieser Rangliste noch auf dem Hub gefunden",
			modelID,
		)
	}
	return &benchmarkv1.GetModelResponse{Detail: modelDetailToProto(detail)}, nil
}

func (s *grpcService) CompareModels(
	ctx context.Context,
	req *benchmarkv1.CompareModelsRequest,
) (*benchmarkv1.CompareModelsResponse, error) {
	ids := trimmedList(req.GetIds())
	if len(ids) == 0 {
		return nil, status.Error(codes.InvalidArgument, "Feld 'ids' ist erforderlich")
	}
	if len(ids) > maxCompare {
		ids = ids[:maxCompare]
	}

	boardKey := boardKeyOrDefault(req.GetBoard())
	entries, info := s.module.snapshotState(boardKey)
	withHub := req.WithHub == nil || req.GetWithHub()

	models := make([]*benchmarkv1.ModelDetail, 0, len(ids))
	for _, id := range ids {
		detail := buildDetail(entries, id, info, false)
		if withHub && detail.ModelID != "" {
			detail.Hub, detail.CardResults = s.module.hubStats(ctx, detail.ModelID)
		}
		models = append(models, modelDetailToProto(detail))
	}

	return &benchmarkv1.CompareModelsResponse{
		Models: models,
		Board:  boardInfoToProto(info),
	}, nil
}

func (s *grpcService) RefreshBoards(
	ctx context.Context,
	req *benchmarkv1.RefreshBoardsRequest,
) (*benchmarkv1.RefreshBoardsResponse, error) {
	requested := strings.TrimSpace(req.GetBoard())
	keys := make([]string, 0, len(BoardOrder))
	if _, ok := knownBoard(requested); ok {
		keys = append(keys, requested)
	} else {
		keys = append(keys, BoardOrder...)
	}

	// The refresh outlives the call, so it runs on the module's lifecycle
	// context rather than this request's, which ends with the response.
	go s.module.refreshBoards(s.module.lifecycle, keys)
	return &benchmarkv1.RefreshBoardsResponse{Boards: keys}, nil
}
