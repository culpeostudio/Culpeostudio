package marketplace

import (
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	marketplacev1 "github.com/culpeohq/backend/gen/go/culpeostudio/marketplace/v1"
	"github.com/culpeohq/backend/internal/apimodels"
	"github.com/culpeohq/backend/modules/marketplace/types"
)

// searchProviderFromProto accepts the whole enum, including PROVIDER_ALL.
// An unset provider means "all", which is what an omitted query parameter did.
func searchProviderFromProto(provider marketplacev1.Provider) (string, error) {
	switch provider {
	case marketplacev1.Provider_PROVIDER_UNSPECIFIED, marketplacev1.Provider_PROVIDER_ALL:
		return types.ProviderAll, nil
	case marketplacev1.Provider_PROVIDER_HUGGINGFACE:
		return types.ProviderHuggingFace, nil
	case marketplacev1.Provider_PROVIDER_OPENROUTER:
		return types.ProviderOpenRouter, nil
	case marketplacev1.Provider_PROVIDER_FEATHERLESS:
		return types.ProviderFeatherless, nil
	default:
		return "", status.Error(codes.InvalidArgument, "ungueltiger provider")
	}
}

// concreteProviderFromProto insists on a single host. Looking up or starting a
// model needs to know where it lives, so "all" is as useless as no provider.
func concreteProviderFromProto(provider marketplacev1.Provider) (string, error) {
	name, err := searchProviderFromProto(provider)
	if err != nil {
		return "", err
	}
	if name == types.ProviderAll {
		return "", status.Error(codes.InvalidArgument, "provider muss gesetzt sein")
	}
	return name, nil
}

func providerToProto(provider string) marketplacev1.Provider {
	switch types.NormalizeProvider(provider) {
	case types.ProviderAll:
		return marketplacev1.Provider_PROVIDER_ALL
	case types.ProviderHuggingFace:
		return marketplacev1.Provider_PROVIDER_HUGGINGFACE
	case types.ProviderOpenRouter:
		return marketplacev1.Provider_PROVIDER_OPENROUTER
	case types.ProviderFeatherless:
		return marketplacev1.Provider_PROVIDER_FEATHERLESS
	default:
		return marketplacev1.Provider_PROVIDER_UNSPECIFIED
	}
}

func categoryFromProto(category marketplacev1.Category) string {
	switch category {
	case marketplacev1.Category_CATEGORY_CHAT:
		return categoryChat
	case marketplacev1.Category_CATEGORY_CODE:
		return categoryCode
	case marketplacev1.Category_CATEGORY_REASONING:
		return categoryReasoning
	case marketplacev1.Category_CATEGORY_VISION:
		return categoryVision
	case marketplacev1.Category_CATEGORY_EMBEDDING:
		return categoryEmbedding
	default:
		return categoryAll
	}
}

// sortModeFromProto returns the canonical spelling of each mode. The aliases
// the sorter still accepts were only there for the free-form query parameter.
func sortModeFromProto(sort marketplacev1.SortMode) string {
	switch sort {
	case marketplacev1.SortMode_SORT_MODE_INTELLIGENCE:
		return "intelligence"
	case marketplacev1.SortMode_SORT_MODE_CONTEXT:
		return "context"
	case marketplacev1.SortMode_SORT_MODE_NEWEST:
		return "newest"
	case marketplacev1.SortMode_SORT_MODE_PRICE_LOW_HIGH:
		return "price_low_high"
	case marketplacev1.SortMode_SORT_MODE_PRICE_HIGH_LOW:
		return "price_high_low"
	default:
		return "popularity"
	}
}

func downloadStatusToProto(state DownloadStatus) marketplacev1.DownloadStatus {
	switch state {
	case DownloadStatusQueued:
		return marketplacev1.DownloadStatus_DOWNLOAD_STATUS_QUEUED
	case DownloadStatusRunning:
		return marketplacev1.DownloadStatus_DOWNLOAD_STATUS_RUNNING
	case DownloadStatusDone:
		return marketplacev1.DownloadStatus_DOWNLOAD_STATUS_DONE
	case DownloadStatusFailed:
		return marketplacev1.DownloadStatus_DOWNLOAD_STATUS_FAILED
	default:
		return marketplacev1.DownloadStatus_DOWNLOAD_STATUS_UNSPECIFIED
	}
}

func downloadOptionToProto(option types.DownloadOption) *marketplacev1.DownloadOption {
	return &marketplacev1.DownloadOption{
		Label:     option.Label,
		AssetId:   option.AssetID,
		AssetIds:  append([]string{}, option.AssetIDs...),
		Format:    option.Format,
		SizeBytes: option.SizeBytes,
		Url:       option.URL,
	}
}

func modelSummaryToProto(model types.ModelSummary) *marketplacev1.ModelSummary {
	message := &marketplacev1.ModelSummary{
		Id:                  model.ID,
		Provider:            providerToProto(model.Provider),
		ModelId:             model.ModelID,
		DisplayName:         model.DisplayName,
		Name:                model.Name,
		Description:         model.Description,
		Format:              model.Format,
		Formats:             append([]string{}, model.Formats...),
		Quantizations:       append([]string{}, model.Quantizations...),
		Author:              model.Author,
		Downloads:           model.Downloads,
		SizeBytes:           model.SizeBytes,
		ParameterBadge:      model.ParameterBadge,
		ParameterCountB:     model.ParameterCountB,
		ProviderBadge:       model.ProviderBadge,
		Category:            model.Category,
		CapabilityTags:      append([]string{}, model.CapabilityTags...),
		PricePer_1M:         model.PricePer1M,
		PricePer_1MInput:    model.PricePer1MInput,
		PricePer_1MOutput:   model.PricePer1MOutput,
		ContextLength:       int32(model.ContextLength),
		IntelligenceScore:   int32(model.IntelligenceScore),
		EstimatedVramGb:     model.EstimatedVRAMGB,
		VramEstimated:       model.VRAMEstimated,
		FitsDetectedGpu:     model.FitsDetectedGPU,
		RuntimeFit:          model.RuntimeFit,
		RuntimeWarnings:     append([]string{}, model.RuntimeWarnings...),
		RuntimeRamOffloadGb: model.RuntimeRAMOffloadGB,
		RecommendationScore: model.RecommendationScore,
		LocalModel:          model.LocalModel,
		NewScore:            model.NewScore,
	}

	message.DownloadOptions = make([]*marketplacev1.DownloadOption, 0, len(model.DownloadOptions))
	for _, option := range model.DownloadOptions {
		message.DownloadOptions = append(message.DownloadOptions, downloadOptionToProto(option))
	}
	return message
}

func modelDetailToProto(detail types.ModelDetail) *marketplacev1.ModelDetail {
	message := &marketplacev1.ModelDetail{
		Summary: modelSummaryToProto(detail.ModelSummary),
		Tags:    append([]string{}, detail.Tags...),
	}
	if len(detail.Metadata) > 0 {
		message.Metadata = make(map[string]string, len(detail.Metadata))
		for key, value := range detail.Metadata {
			if text, ok := value.(string); ok {
				message.Metadata[key] = text
			}
		}
	}
	return message
}

func downloadJobToProto(job DownloadJob) *marketplacev1.DownloadJob {
	message := &marketplacev1.DownloadJob{
		Id:               job.ID,
		Provider:         providerToProto(job.Provider),
		ModelId:          job.ModelID,
		AssetId:          job.AssetID,
		AssetIds:         append([]string{}, job.AssetIDs...),
		Revision:         job.Revision,
		CommitSha:        job.CommitSHA,
		TargetDir:        job.TargetDir,
		Status:           downloadStatusToProto(job.Status),
		Progress:         int32(job.Progress),
		Error:            job.Error,
		OutputPath:       job.OutputPath,
		CreatedAt:        timestampToProto(job.CreatedAt),
		UpdatedAt:        timestampToProto(job.UpdatedAt),
		DownloadedBytes:  job.DownloadedBytes,
		SpeedBytesPerSec: job.SpeedBytesPerSec,
		TotalBytes:       job.TotalBytes,
	}
	if job.StartedAt != nil {
		message.StartedAt = timestampToProto(*job.StartedAt)
	}
	if job.FinishedAt != nil {
		message.FinishedAt = timestampToProto(*job.FinishedAt)
	}
	return message
}

func activeAPIModelToProto(model apimodels.ActiveModel) *marketplacev1.ActiveApiModel {
	return &marketplacev1.ActiveApiModel{
		Provider:    providerToProto(model.Provider),
		ModelId:     model.ModelID,
		DisplayName: model.DisplayName,
		ModelRef:    model.ModelRef,
		StartedAt:   timestampToProto(model.StartedAt),
		LastUsedAt:  timestampToProto(model.LastUsedAt),
	}
}

// timestampToProto leaves a never-set time unset rather than reporting the
// epoch, the way the hardware profile handles its capture time.
func timestampToProto(value time.Time) *timestamppb.Timestamp {
	if value.IsZero() {
		return nil
	}
	return timestamppb.New(value)
}
