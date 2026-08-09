package marketplace

import (
	"context"
	"errors"
	"strings"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	marketplacev1 "github.com/culpeohq/backend/gen/go/culpeostudio/marketplace/v1"
	"github.com/culpeohq/backend/internal/apimodels"
	"github.com/culpeohq/backend/internal/appsettings"
	enginehardware "github.com/culpeohq/backend/internal/hardware"
	"github.com/culpeohq/backend/modules/marketplace/featherless"
	"github.com/culpeohq/backend/modules/marketplace/huggingface"
	"github.com/culpeohq/backend/modules/marketplace/openrouter"
	"github.com/culpeohq/backend/modules/marketplace/types"
)

type grpcService struct {
	marketplacev1.UnimplementedMarketplaceServiceServer
	module *MarketplaceModule
}

func (m *MarketplaceModule) RegisterGRPC(server *grpc.Server) {
	marketplacev1.RegisterMarketplaceServiceServer(server, &grpcService{module: m})
}

func (s *grpcService) SearchModels(
	ctx context.Context,
	req *marketplacev1.SearchModelsRequest,
) (*marketplacev1.SearchModelsResponse, error) {
	p, err := searchParamsFromRequest(req)
	if err != nil {
		return nil, err
	}

	settings, err := s.module.loadSettings()
	if err != nil {
		return nil, status.Error(codes.Internal, "settings konnten nicht geladen werden")
	}

	hardwareProfile := detectHardwareProfile()
	searchLimit := computeSearchLimit(p)
	searchProvider := p.resolvedProvider()
	postFilteredSearch := p.isPostFilteredSearch()

	// One extra hit, so a full page can still tell whether another one follows.
	searchLimit++
	if searchLimit > maxSearchWindow {
		searchLimit = maxSearchWindow
	}

	targetResultCount := p.PageSize*p.Page + 1
	rawModelCount := 0
	var models []types.ModelSummary
	var providerErrors []string

	for {
		rawModels, currentProviderErrors := s.module.loadSearchModels(ctx, searchProvider, p.Query, p.Format, searchLimit, settings)
		rawModelCount = len(rawModels)
		providerErrors = currentProviderErrors
		models = prepareMarketplaceResults(rawModels, hardwareProfile, p.Query, p.Format, p.Category, p.Quantization, p.NormalizedQuantization, p.LocalOnly, p.GPUOnly, p.SortMode)

		if !postFilteredSearch || len(models) >= targetResultCount || rawModelCount < searchLimit || searchLimit >= maxSearchWindow {
			break
		}

		nextSearchLimit, ok := expandSearchLimit(searchLimit)
		if !ok {
			break
		}
		searchLimit = nextSearchLimit
	}

	pagedModels, hasMore := paginateModels(models, p.Page, p.PageSize)

	// The window was exhausted rather than the catalogue: there may well be
	// more matches behind it, so the client is allowed to ask for them.
	if !hasMore && postFilteredSearch && rawModelCount == searchLimit && searchLimit < maxSearchWindow {
		hasMore = true
	}

	response := &marketplacev1.SearchModelsResponse{
		Total:    int32(len(models)),
		Returned: int32(len(pagedModels)),
		Partial:  len(providerErrors) > 0,
		Errors:   providerErrors,
		Page:     int32(p.Page),
		PageSize: int32(p.PageSize),
		HasMore:  hasMore,
		Hardware: HardwareProfileToProto(hardwareProfile),
	}
	response.Models = make([]*marketplacev1.ModelSummary, 0, len(pagedModels))
	for _, model := range pagedModels {
		response.Models = append(response.Models, modelSummaryToProto(model))
	}
	return response, nil
}

func (s *grpcService) GetModelDetail(
	ctx context.Context,
	req *marketplacev1.GetModelDetailRequest,
) (*marketplacev1.GetModelDetailResponse, error) {
	provider, err := concreteProviderFromProto(req.GetProvider())
	if err != nil {
		return nil, err
	}

	// No unescaping: the id used to arrive as a path segment or a query
	// parameter and had to be decoded, whereas a proto field carries it as it
	// was written.
	modelID := strings.TrimSpace(req.GetId())
	if modelID == "" {
		return nil, status.Error(codes.InvalidArgument, "model id fehlt")
	}

	settings, err := s.module.loadSettings()
	if err != nil {
		return nil, status.Error(codes.Internal, "settings konnten nicht geladen werden")
	}

	var detail types.ModelDetail
	switch provider {
	case types.ProviderHuggingFace:
		detail, err = huggingface.DetailHuggingFace(ctx, s.module.metadataClient, s.module.hfAPIBase, modelID, settings.HuggingFaceToken)
	case types.ProviderOpenRouter:
		detail, err = openrouter.DetailOpenRouter(ctx, s.module.metadataClient, s.module.orAPIBase, modelID, settings.OpenRouterToken)
	case types.ProviderFeatherless:
		detail, err = featherless.DetailFeatherless(ctx, s.module.metadataClient, s.module.flAPIBase, modelID, settings.FeatherlessToken)
	default:
		return nil, status.Error(codes.InvalidArgument, "ungueltiger provider")
	}
	if err != nil {
		// The lookup itself failed upstream, which the HTTP API reported as a
		// bad gateway.
		return nil, status.Error(codes.Unavailable, err.Error())
	}

	enriched := enrichMarketplaceMetadata([]types.ModelSummary{detail.ModelSummary}, detectHardwareProfile())
	detail.ModelSummary = enriched[0]
	return &marketplacev1.GetModelDetailResponse{Detail: modelDetailToProto(detail)}, nil
}

func (s *grpcService) GetHardwareProfile(
	ctx context.Context,
	req *marketplacev1.GetHardwareProfileRequest,
) (*marketplacev1.GetHardwareProfileResponse, error) {
	return &marketplacev1.GetHardwareProfileResponse{
		Profile: HardwareProfileToProto(detectHardwareProfile()),
	}, nil
}

func (s *grpcService) StartDownload(
	ctx context.Context,
	req *marketplacev1.StartDownloadRequest,
) (*marketplacev1.StartDownloadResponse, error) {
	provider, err := concreteProviderFromProto(req.GetProvider())
	if err != nil {
		return nil, err
	}

	modelID := strings.TrimSpace(req.GetModelId())
	if modelID == "" {
		return nil, status.Error(codes.InvalidArgument, "model_id ist erforderlich")
	}

	if existing, ok := s.module.jobs.ActiveJobForModel(provider, modelID); ok {
		return &marketplacev1.StartDownloadResponse{
			JobId:     existing.ID,
			Status:    downloadStatusToProto(existing.Status),
			Existing:  true,
			TargetDir: existing.TargetDir,
		}, nil
	}

	settings, err := s.module.loadSettings()
	if err != nil {
		return nil, status.Error(codes.Internal, "settings konnten nicht geladen werden")
	}

	baseDir := strings.TrimSpace(settings.ModelDir)
	if baseDir == "" {
		baseDir = appsettings.DefaultModelDir
	}
	targetDir, dirErr := sanitizeTargetDir(baseDir, strings.TrimSpace(req.GetTargetDir()))
	if dirErr != nil {
		return nil, status.Error(codes.InvalidArgument, dirErr.Error())
	}

	if err := s.ensureDiskSpace(ctx, targetDir, req.GetSizeBytes()); err != nil {
		return nil, err
	}

	revision := strings.TrimSpace(req.GetRevision())
	if revision == "" {
		revision = "main"
	}
	job := s.module.jobs.CreateWithAssetsAndRevision(
		provider,
		modelID,
		strings.TrimSpace(req.GetAssetId()),
		types.UniqueNonEmpty(req.GetAssetIds()),
		targetDir,
		revision,
	)
	s.module.jobs.SetExpectedBytes(job.ID, req.GetSizeBytes())
	go s.module.runDownloadJob(job.ID)

	return &marketplacev1.StartDownloadResponse{
		JobId:     job.ID,
		Status:    downloadStatusToProto(job.Status),
		TargetDir: targetDir,
	}, nil
}

// ensureDiskSpace refuses a download the target volume cannot hold, including a
// ten percent margin. A size the client did not state cannot be checked.
func (s *grpcService) ensureDiskSpace(ctx context.Context, targetDir string, sizeBytes int64) error {
	if sizeBytes <= 0 {
		return nil
	}

	profile := detectHardwareProfile()
	// The cached profile measured whichever volume the backend started on, so
	// the target directory is measured again when it reports less.
	if live := enginehardware.Detect(ctx, targetDir); live.DiskFreeBytes > 0 &&
		(profile.DiskFreeBytes == 0 || live.DiskFreeBytes < profile.DiskFreeBytes) {
		profile.DiskFreeBytes = live.DiskFreeBytes
		profile.DiskFree = formatBytesAsGB(live.DiskFreeBytes)
	}

	puffer := sizeBytes / 10
	if puffer < 1<<30 {
		puffer = 1 << 30
	}
	needed := sizeBytes + puffer
	if profile.DiskFreeBytes > 0 && needed > profile.DiskFreeBytes {
		return status.Errorf(
			codes.FailedPrecondition,
			"nicht genug Speicherplatz: brauche ~%.1f GB, frei %.1f GB",
			float64(needed)/float64(1<<30),
			float64(profile.DiskFreeBytes)/float64(1<<30),
		)
	}
	return nil
}

func (s *grpcService) ListDownloadJobs(
	ctx context.Context,
	req *marketplacev1.ListDownloadJobsRequest,
) (*marketplacev1.ListDownloadJobsResponse, error) {
	stored := s.module.jobs.List()
	jobs := make([]*marketplacev1.DownloadJob, 0, len(stored))
	for _, job := range stored {
		jobs = append(jobs, downloadJobToProto(job))
	}
	return &marketplacev1.ListDownloadJobsResponse{Jobs: jobs}, nil
}

func (s *grpcService) GetDownloadJob(
	ctx context.Context,
	req *marketplacev1.GetDownloadJobRequest,
) (*marketplacev1.GetDownloadJobResponse, error) {
	job, ok := s.module.jobs.Get(strings.TrimSpace(req.GetId()))
	if !ok {
		return nil, status.Error(codes.NotFound, "job nicht gefunden")
	}
	return &marketplacev1.GetDownloadJobResponse{Job: downloadJobToProto(job)}, nil
}

func (s *grpcService) DeleteDownloadJob(
	ctx context.Context,
	req *marketplacev1.DeleteDownloadJobRequest,
) (*marketplacev1.DeleteDownloadJobResponse, error) {
	if !s.module.jobs.Delete(strings.TrimSpace(req.GetId())) {
		return nil, status.Error(codes.NotFound, "job nicht gefunden")
	}
	return &marketplacev1.DeleteDownloadJobResponse{}, nil
}

func (s *grpcService) StartApiModel(
	ctx context.Context,
	req *marketplacev1.StartApiModelRequest,
) (*marketplacev1.StartApiModelResponse, error) {
	provider, err := concreteProviderFromProto(req.GetProvider())
	if err != nil {
		return nil, err
	}
	if !apimodels.IsSupportedProvider(provider) {
		return nil, status.Error(
			codes.InvalidArgument,
			"nur OpenRouter und Featherless API-Modelle koennen im Chat gestartet werden",
		)
	}

	modelID := strings.TrimSpace(req.GetModelId())
	if modelID == "" {
		return nil, status.Error(codes.InvalidArgument, "model_id ist erforderlich")
	}

	settings, err := s.module.loadSettings()
	if err != nil {
		return nil, status.Error(codes.Internal, "settings konnten nicht geladen werden")
	}
	switch provider {
	case apimodels.ProviderOpenRouter:
		if strings.TrimSpace(settings.OpenRouterToken) == "" {
			return nil, status.Error(codes.FailedPrecondition, "OpenRouter API-Key fehlt in den Einstellungen")
		}
	case apimodels.ProviderFeatherless:
		if strings.TrimSpace(settings.FeatherlessToken) == "" {
			return nil, status.Error(codes.FailedPrecondition, "Featherless API-Key fehlt in den Einstellungen")
		}
	}

	model, err := s.module.activeModels.Start(provider, modelID, req.GetDisplayName())
	if err != nil {
		if errors.Is(err, apimodels.ErrActiveModelsLimitReached) {
			return nil, status.Errorf(
				codes.ResourceExhausted,
				"%s (Limit: %d); bitte zuerst ein aktives Modell entfernen",
				err.Error(), apimodels.MaxActiveModels,
			)
		}
		return nil, status.Error(codes.Internal, err.Error())
	}
	return &marketplacev1.StartApiModelResponse{Model: activeAPIModelToProto(model)}, nil
}

func (s *grpcService) ListActiveApiModels(
	ctx context.Context,
	req *marketplacev1.ListActiveApiModelsRequest,
) (*marketplacev1.ListActiveApiModelsResponse, error) {
	stored, err := s.module.activeModels.List()
	if err != nil {
		return nil, status.Error(codes.Internal, "aktive API-Modelle konnten nicht geladen werden")
	}
	models := make([]*marketplacev1.ActiveApiModel, 0, len(stored))
	for _, model := range stored {
		models = append(models, activeAPIModelToProto(model))
	}
	return &marketplacev1.ListActiveApiModelsResponse{Models: models}, nil
}

func (s *grpcService) DeleteActiveApiModel(
	ctx context.Context,
	req *marketplacev1.DeleteActiveApiModelRequest,
) (*marketplacev1.DeleteActiveApiModelResponse, error) {
	modelRef := strings.TrimSpace(req.GetModelRef())
	if modelRef == "" {
		return nil, status.Error(codes.InvalidArgument, "model_ref ist erforderlich")
	}
	deleted, err := s.module.activeModels.Delete(modelRef)
	if err != nil {
		return nil, status.Error(codes.Internal, "API-Modell konnte nicht geloescht werden")
	}
	if !deleted {
		return nil, status.Error(codes.NotFound, "API-Modell nicht gefunden")
	}
	return &marketplacev1.DeleteActiveApiModelResponse{}, nil
}
