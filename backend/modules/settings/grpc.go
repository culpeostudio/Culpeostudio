package settings

import (
	"context"
	"runtime"
	"strings"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	settingsv1 "github.com/culpeohq/backend/gen/go/culpeostudio/settings/v1"
	"github.com/culpeohq/backend/internal/appsettings"
	"github.com/culpeohq/backend/modules/marketplace"
)

type grpcService struct {
	settingsv1.UnimplementedSettingsServiceServer
	module *SettingsModule
	store  *appsettings.Store
}

func (m *SettingsModule) RegisterGRPC(server *grpc.Server) {
	settingsv1.RegisterSettingsServiceServer(server, &grpcService{
		module: m,
		store:  m.store,
	})
}

func (s *grpcService) GetSettings(ctx context.Context, req *settingsv1.GetSettingsRequest) (*settingsv1.GetSettingsResponse, error) {
	return &settingsv1.GetSettingsResponse{Settings: publicSettings(s.store.Get())}, nil
}

func (s *grpcService) UpdateSettings(ctx context.Context, req *settingsv1.UpdateSettingsRequest) (*settingsv1.UpdateSettingsResponse, error) {
	ramReserve := req.EngineRamReserveBytes
	gpuReserve := req.EngineGpuReserveBytes

	var warnings []string
	var err error
	if s.module != nil && s.module.Node != nil {
		warnings, err = s.module.Node.ValidateEngineReserves(ctx, ramReserve, gpuReserve)
		if err != nil {
			return nil, status.Error(codes.InvalidArgument, err.Error())
		}
	}

	updated, err := s.store.Update(appsettings.Update{
		ModelDir:              req.ModelDir,
		HuggingFaceToken:      req.HuggingfaceToken,
		OpenRouterToken:       req.OpenrouterToken,
		FeatherlessToken:      req.FeatherlessToken,
		Shortcuts:             req.GetShortcuts(),
		EngineRAMReserveBytes: ramReserve,
		EngineGPUReserveBytes: gpuReserve,
		ResetEngineReserves:   req.GetResetEngineReserves(),
	})
	if err != nil {
		// A rejected directory or reserve is the caller's mistake; anything
		// else means the store itself failed to persist.
		code := codes.Internal
		if req.ModelDir != nil || ramReserve != nil || gpuReserve != nil {
			code = codes.InvalidArgument
		}
		return nil, status.Error(code, err.Error())
	}

	return &settingsv1.UpdateSettingsResponse{
		Settings: publicSettings(updated),
		Message:  "Einstellungen gespeichert",
		Warnings: warnings,
	}, nil
}

func (s *grpcService) GetSystemInfo(ctx context.Context, req *settingsv1.GetSystemInfoRequest) (*settingsv1.GetSystemInfoResponse, error) {
	return &settingsv1.GetSystemInfoResponse{
		Profile: marketplace.HardwareProfileToProto(marketplace.CurrentHardwareProfile()),
	}, nil
}

func (s *grpcService) TestProvider(ctx context.Context, req *settingsv1.TestProviderRequest) (*settingsv1.TestProviderResponse, error) {
	current := s.store.Get()

	if s.module == nil || s.module.Anbieter == nil {
		return nil, status.Error(codes.Internal, "Anbieter Modul nicht initialisiert")
	}

	var token string
	var test func(string) (bool, string)
	switch req.GetProvider() {
	case settingsv1.Provider_PROVIDER_HUGGINGFACE:
		token, test = current.HuggingFaceToken, s.module.Anbieter.TestHuggingFace
	case settingsv1.Provider_PROVIDER_OPENROUTER:
		token, test = current.OpenRouterToken, s.module.Anbieter.TestOpenRouter
	case settingsv1.Provider_PROVIDER_FEATHERLESS:
		token, test = current.FeatherlessToken, s.module.Anbieter.TestFeatherless
	default:
		return nil, status.Error(codes.InvalidArgument, "Ungültiger Provider")
	}

	reachable, message := test(token)
	return &settingsv1.TestProviderResponse{
		Provider:  req.GetProvider(),
		Reachable: reachable,
		Message:   message,
	}, nil
}

// publicSettings is what the client is allowed to see: the stored tokens are
// reduced to whether one is set.
func publicSettings(s appsettings.Settings) *settingsv1.Settings {
	modelDirValid := !(runtime.GOOS != "windows" && appsettings.LooksLikeWindowsPath(s.ModelDir))
	modelDirError := ""
	if !modelDirValid {
		modelDirError = "Windows-Pfad unter Linux: bitte einen Linux-Ordner auswählen"
	}
	return &settingsv1.Settings{
		ModelDir:              strings.TrimSpace(s.ModelDir),
		ModelDirValid:         modelDirValid,
		ModelDirError:         modelDirError,
		HuggingfaceTokenSet:   strings.TrimSpace(s.HuggingFaceToken) != "",
		OpenrouterTokenSet:    strings.TrimSpace(s.OpenRouterToken) != "",
		FeatherlessTokenSet:   strings.TrimSpace(s.FeatherlessToken) != "",
		Shortcuts:             s.Shortcuts,
		EngineRamReserveBytes: s.EngineRAMReserveBytes,
		EngineGpuReserveBytes: s.EngineGPUReserveBytes,
	}
}
