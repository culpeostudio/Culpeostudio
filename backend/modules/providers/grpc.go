package providers

import (
	"context"
	"errors"
	"strings"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	providersv1 "github.com/culpeohq/backend/gen/go/culpeostudio/providers/v1"
	"github.com/culpeohq/backend/internal/grpcmw"
	"github.com/culpeohq/backend/internal/providerconn"
)

type grpcService struct {
	providersv1.UnimplementedProviderServiceServer
	module *Module
}

func (m *Module) RegisterGRPC(server *grpc.Server) {
	providersv1.RegisterProviderServiceServer(server, &grpcService{module: m})
}

func providerUserID(ctx context.Context) string {
	if userID := strings.TrimSpace(grpcmw.UserIDFromContext(ctx)); userID != "" {
		return strings.ToLower(userID)
	}
	// Direct handler tests and a local loopback installation use the same
	// owner fallback as Scout. Network calls still pass through gRPC auth.
	return "local"
}

func (s *grpcService) managerOrError() (*providerconn.Manager, error) {
	if s == nil || s.module == nil || s.module.manager == nil {
		return nil, status.Error(codes.Unavailable, "Provider-Verwaltung ist nicht verfügbar")
	}
	return s.module.manager, nil
}

func (s *grpcService) ListPresets(ctx context.Context, req *providersv1.ListPresetsRequest) (*providersv1.ListPresetsResponse, error) {
	presets := providerconn.Presets()
	response := &providersv1.ListPresetsResponse{Presets: make([]*providersv1.ProviderPreset, 0, len(presets))}
	for _, preset := range presets {
		response.Presets = append(response.Presets, presetToProto(preset))
	}
	return response, nil
}

func (s *grpcService) ListConnections(ctx context.Context, req *providersv1.ListConnectionsRequest) (*providersv1.ListConnectionsResponse, error) {
	manager, err := s.managerOrError()
	if err != nil {
		return nil, err
	}
	connections, err := manager.ListConnections(providerUserID(ctx))
	if err != nil {
		return nil, providerStoreStatus(err)
	}
	response := &providersv1.ListConnectionsResponse{Connections: make([]*providersv1.ProviderConnection, 0, len(connections))}
	for _, connection := range connections {
		response.Connections = append(response.Connections, publicConnectionToProto(providerconn.Public(connection, time.Now().UTC())))
	}
	return response, nil
}

func (s *grpcService) SaveConnection(ctx context.Context, req *providersv1.SaveConnectionRequest) (*providersv1.SaveConnectionResponse, error) {
	manager, err := s.managerOrError()
	if err != nil {
		return nil, err
	}
	if req == nil || strings.TrimSpace(req.GetPresetId()) == "" {
		return nil, status.Error(codes.InvalidArgument, "preset_id ist erforderlich")
	}

	var apiKey *string
	if req.ApiKey != nil {
		value := req.GetApiKey()
		apiKey = &value
	}
	created := strings.TrimSpace(req.GetId()) == ""
	connection, err := manager.SaveConnection(providerUserID(ctx), providerconn.ConnectionInput{
		ID:          req.GetId(),
		PresetID:    req.GetPresetId(),
		Name:        req.GetName(),
		Protocol:    protocolFromProto(req.GetProtocol()),
		BaseURL:     req.GetBaseUrl(),
		APIKey:      apiKey,
		ClearAPIKey: req.GetClearApiKey(),
		Enabled:     req.GetEnabled(),
	})
	if err != nil {
		return nil, providerSaveStatus(err)
	}

	response := &providersv1.SaveConnectionResponse{
		Connection: publicConnectionToProto(providerconn.Public(connection, time.Now().UTC())),
	}
	// A new/key-edited enabled connection should immediately get a current
	// catalogue even if an older client omitted sync_models. An edit made while
	// offline remains durable and reports a redacted sync_error instead.
	shouldSync := connection.Enabled && (req.GetSyncModels() || created || apiKey != nil || req.GetClearApiKey())
	if shouldSync {
		syncCtx, cancel := context.WithTimeout(ctx, providerRefreshTimeout)
		updated, models, syncErr := manager.SyncConnection(syncCtx, providerUserID(ctx), connection.ID)
		cancel()
		response.Connection = publicConnectionToProto(providerconn.Public(updated, time.Now().UTC()))
		if syncErr != nil {
			response.SyncError = safeProviderError(syncErr)
			_, cached, listErr := manager.ListModels(providerUserID(ctx), connection.ID)
			if listErr == nil {
				response.Models = modelsToProto(cached)
			}
			return response, nil
		}
		response.Models = modelsToProto(models)
		return response, nil
	}

	_, models, listErr := manager.ListModels(providerUserID(ctx), connection.ID)
	if listErr == nil {
		response.Models = modelsToProto(models)
	}
	return response, nil
}

func (s *grpcService) DeleteConnection(ctx context.Context, req *providersv1.DeleteConnectionRequest) (*providersv1.DeleteConnectionResponse, error) {
	manager, err := s.managerOrError()
	if err != nil {
		return nil, err
	}
	if req == nil || strings.TrimSpace(req.GetId()) == "" {
		return nil, status.Error(codes.InvalidArgument, "id ist erforderlich")
	}
	deleted, err := manager.DeleteConnection(providerUserID(ctx), req.GetId())
	if err != nil {
		return nil, providerStoreStatus(err)
	}
	if !deleted {
		return nil, status.Error(codes.NotFound, "Provider-Verbindung wurde nicht gefunden")
	}
	return &providersv1.DeleteConnectionResponse{}, nil
}

func (s *grpcService) TestConnection(ctx context.Context, req *providersv1.TestConnectionRequest) (*providersv1.TestConnectionResponse, error) {
	manager, err := s.managerOrError()
	if err != nil {
		return nil, err
	}
	if req == nil || strings.TrimSpace(req.GetId()) == "" {
		return nil, status.Error(codes.InvalidArgument, "id ist erforderlich")
	}
	testCtx, cancel := context.WithTimeout(ctx, providerRefreshTimeout)
	count, testErr := manager.TestConnection(testCtx, providerUserID(ctx), req.GetId())
	cancel()
	if testErr != nil {
		if errors.Is(testErr, providerconn.ErrNotFound) {
			return nil, status.Error(codes.NotFound, "Provider-Verbindung wurde nicht gefunden")
		}
		return &providersv1.TestConnectionResponse{Reachable: false, Message: safeProviderError(testErr)}, nil
	}
	return &providersv1.TestConnectionResponse{
		Reachable:            true,
		Message:              "Verbindung und Modellkatalog sind erreichbar.",
		DiscoveredModelCount: int32(count),
	}, nil
}

func (s *grpcService) SyncConnectionModels(ctx context.Context, req *providersv1.SyncConnectionModelsRequest) (*providersv1.SyncConnectionModelsResponse, error) {
	manager, err := s.managerOrError()
	if err != nil {
		return nil, err
	}
	if req == nil || strings.TrimSpace(req.GetId()) == "" {
		return nil, status.Error(codes.InvalidArgument, "id ist erforderlich")
	}
	syncCtx, cancel := context.WithTimeout(ctx, providerRefreshTimeout)
	connection, models, syncErr := manager.SyncConnection(syncCtx, providerUserID(ctx), req.GetId())
	cancel()
	if syncErr != nil {
		if errors.Is(syncErr, providerconn.ErrNotFound) {
			return nil, status.Error(codes.NotFound, "Provider-Verbindung wurde nicht gefunden")
		}
		if errors.Is(syncErr, providerconn.ErrSyncSuperseded) {
			return nil, status.Error(codes.Aborted, "Provider-Verbindung wurde während der Synchronisierung geändert. Bitte erneut synchronisieren.")
		}
		if errors.Is(syncErr, providerconn.ErrCatalogModelLimit) {
			return nil, status.Error(codes.ResourceExhausted, "Der Provider-Katalog ist zu groß und wurde nicht übernommen")
		}
		return nil, status.Error(codes.Unavailable, safeProviderError(syncErr))
	}
	return &providersv1.SyncConnectionModelsResponse{
		Connection: publicConnectionToProto(providerconn.Public(connection, time.Now().UTC())),
		Models:     modelsToProto(models),
	}, nil
}

func (s *grpcService) ListConnectionModels(ctx context.Context, req *providersv1.ListConnectionModelsRequest) (*providersv1.ListConnectionModelsResponse, error) {
	manager, err := s.managerOrError()
	if err != nil {
		return nil, err
	}
	if req == nil || strings.TrimSpace(req.GetConnectionId()) == "" {
		return nil, status.Error(codes.InvalidArgument, "connection_id ist erforderlich")
	}
	connection, models, err := manager.ListModels(providerUserID(ctx), req.GetConnectionId())
	if err != nil {
		return nil, providerStoreStatus(err)
	}
	return &providersv1.ListConnectionModelsResponse{
		Connection: publicConnectionToProto(providerconn.Public(connection, time.Now().UTC())),
		Models:     modelsToProto(models),
	}, nil
}

func (s *grpcService) ActivateModel(ctx context.Context, req *providersv1.ActivateModelRequest) (*providersv1.ActivateModelResponse, error) {
	manager, err := s.managerOrError()
	if err != nil {
		return nil, err
	}
	if req == nil || strings.TrimSpace(req.GetConnectionId()) == "" || strings.TrimSpace(req.GetModelId()) == "" {
		return nil, status.Error(codes.InvalidArgument, "connection_id und model_id sind erforderlich")
	}
	model, err := manager.ActivateModel(providerUserID(ctx), req.GetConnectionId(), req.GetModelId(), req.GetDisplayName())
	if err != nil {
		return nil, providerActivateStatus(err)
	}
	return &providersv1.ActivateModelResponse{Model: activeModelToProto(model)}, nil
}

func (s *grpcService) ListActiveModels(ctx context.Context, req *providersv1.ListActiveModelsRequest) (*providersv1.ListActiveModelsResponse, error) {
	manager, err := s.managerOrError()
	if err != nil {
		return nil, err
	}
	models, err := manager.ListActiveModels(providerUserID(ctx))
	if err != nil {
		return nil, providerStoreStatus(err)
	}
	response := &providersv1.ListActiveModelsResponse{Models: make([]*providersv1.ActiveProviderModel, 0, len(models))}
	for _, model := range models {
		response.Models = append(response.Models, activeModelToProto(model))
	}
	return response, nil
}

func (s *grpcService) DeleteActiveModel(ctx context.Context, req *providersv1.DeleteActiveModelRequest) (*providersv1.DeleteActiveModelResponse, error) {
	manager, err := s.managerOrError()
	if err != nil {
		return nil, err
	}
	if req == nil || strings.TrimSpace(req.GetModelRef()) == "" {
		return nil, status.Error(codes.InvalidArgument, "model_ref ist erforderlich")
	}
	deleted, err := manager.DeleteActiveModel(providerUserID(ctx), req.GetModelRef())
	if err != nil {
		return nil, providerStoreStatus(err)
	}
	if !deleted {
		return nil, status.Error(codes.NotFound, "Aktives API-Modell wurde nicht gefunden")
	}
	return &providersv1.DeleteActiveModelResponse{}, nil
}

func presetToProto(preset providerconn.Preset) *providersv1.ProviderPreset {
	return &providersv1.ProviderPreset{
		Id:                preset.ID,
		Name:              preset.Name,
		Description:       preset.Description,
		Protocol:          protocolToProto(preset.Protocol),
		DefaultBaseUrl:    preset.DefaultBaseURL,
		DocumentationUrl:  preset.DocumentationURL,
		ApiKeyRequired:    preset.APIKeyRequired,
		Available:         preset.Available,
		UnavailableReason: preset.UnavailableReason,
		LocalOnly:         preset.LocalOnly,
	}
}

func publicConnectionToProto(connection providerconn.PublicConnection) *providersv1.ProviderConnection {
	return &providersv1.ProviderConnection{
		Id:            connection.ID,
		PresetId:      connection.PresetID,
		Name:          connection.Name,
		Protocol:      protocolToProto(connection.Protocol),
		BaseUrl:       connection.BaseURL,
		ApiKeySet:     connection.APIKeySet,
		Enabled:       connection.Enabled,
		ModelCount:    int32(connection.ModelCount),
		LastSyncedAt:  timeToProto(connection.LastSyncedAt),
		LastSyncError: connection.LastSyncError,
		ChatSupported: connection.ChatSupported,
		Stale:         connection.Stale,
		ProviderLabel: connection.ProviderLabel,
	}
}

func modelsToProto(models []providerconn.Model) []*providersv1.ProviderModel {
	response := make([]*providersv1.ProviderModel, 0, len(models))
	for _, model := range models {
		response = append(response, &providersv1.ProviderModel{
			Id:               model.ID,
			DisplayName:      model.DisplayName,
			Description:      model.Description,
			ContextWindow:    int32(model.ContextWindow),
			MaxOutputTokens:  int32(model.MaxOutputTokens),
			InputModalities:  append([]string(nil), model.InputModalities...),
			OutputModalities: append([]string(nil), model.OutputModalities...),
			Capabilities:     append([]string(nil), model.Capabilities...),
			ChatSupported:    model.ChatSupported,
			Deprecated:       model.Deprecated,
			DiscoveredAt:     timeToProto(model.DiscoveredAt),
		})
	}
	return response
}

func activeModelToProto(model providerconn.ActiveModel) *providersv1.ActiveProviderModel {
	return &providersv1.ActiveProviderModel{
		ModelRef:      model.ModelRef,
		ConnectionId:  model.ConnectionID,
		ProviderLabel: model.ProviderLabel,
		ProviderId:    model.ProviderID,
		ModelId:       model.ModelID,
		DisplayName:   model.DisplayName,
		Protocol:      protocolToProto(model.Protocol),
		ActivatedAt:   timeToProto(model.ActivatedAt),
		LastUsedAt:    timeToProto(model.LastUsedAt),
	}
}

func protocolToProto(protocol string) providersv1.ConnectionProtocol {
	switch providerconn.NormalizeProtocol(protocol) {
	case providerconn.ProtocolOpenAICompatible:
		return providersv1.ConnectionProtocol_CONNECTION_PROTOCOL_OPENAI_COMPATIBLE
	case providerconn.ProtocolAnthropic:
		return providersv1.ConnectionProtocol_CONNECTION_PROTOCOL_ANTHROPIC_MESSAGES
	case providerconn.ProtocolGoogleGenAI:
		return providersv1.ConnectionProtocol_CONNECTION_PROTOCOL_GOOGLE_GENAI
	default:
		return providersv1.ConnectionProtocol_CONNECTION_PROTOCOL_UNSPECIFIED
	}
}

func protocolFromProto(protocol providersv1.ConnectionProtocol) string {
	switch protocol {
	case providersv1.ConnectionProtocol_CONNECTION_PROTOCOL_OPENAI_COMPATIBLE:
		return providerconn.ProtocolOpenAICompatible
	case providersv1.ConnectionProtocol_CONNECTION_PROTOCOL_ANTHROPIC_MESSAGES:
		return providerconn.ProtocolAnthropic
	case providersv1.ConnectionProtocol_CONNECTION_PROTOCOL_GOOGLE_GENAI:
		return providerconn.ProtocolGoogleGenAI
	default:
		return ""
	}
}

func timeToProto(value time.Time) *timestamppb.Timestamp {
	if value.IsZero() {
		return nil
	}
	return timestamppb.New(value)
}

func providerStoreStatus(err error) error {
	switch {
	case errors.Is(err, providerconn.ErrNotFound):
		return status.Error(codes.NotFound, "Provider-Verbindung wurde nicht gefunden")
	default:
		return status.Error(codes.Internal, "Provider-Verbindungen konnten nicht gelesen werden")
	}
}

func providerSaveStatus(err error) error {
	if errors.Is(err, providerconn.ErrNotFound) {
		return status.Error(codes.NotFound, "Provider-Verbindung wurde nicht gefunden")
	}
	if errors.Is(err, providerconn.ErrConnectionLimit) {
		return status.Error(codes.ResourceExhausted, "Limit für Provider-Verbindungen erreicht")
	}
	return status.Error(codes.InvalidArgument, safeProviderError(err))
}

func providerActivateStatus(err error) error {
	switch {
	case errors.Is(err, providerconn.ErrNotFound):
		return status.Error(codes.NotFound, "Provider-Verbindung wurde nicht gefunden")
	case errors.Is(err, providerconn.ErrModelNotDiscovered):
		return status.Error(codes.FailedPrecondition, "Modell ist nicht im aktuellen Provider-Katalog")
	case errors.Is(err, providerconn.ErrActiveModelLimit):
		return status.Error(codes.ResourceExhausted, "Limit für aktive API-Modelle erreicht")
	default:
		return status.Error(codes.FailedPrecondition, safeProviderError(err))
	}
}

func safeProviderError(err error) string {
	if err == nil {
		return ""
	}
	// providerconn deliberately emits redacted errors. Keep an upper bound here
	// as a second line of defence before a message reaches the client.
	message := strings.TrimSpace(err.Error())
	if len([]rune(message)) > 300 {
		message = string([]rune(message)[:300]) + "…"
	}
	return message
}
