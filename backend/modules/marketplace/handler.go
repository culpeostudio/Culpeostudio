package marketplace

import (
	"context"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"golang.org/x/sync/errgroup"

	"github.com/culpeohq/backend/internal/apimodels"
	"github.com/culpeohq/backend/internal/appsettings"
	"github.com/culpeohq/backend/internal/bus"
	"github.com/culpeohq/backend/internal/modelstorage"
	"github.com/culpeohq/backend/modules/marketplace/common"
	"github.com/culpeohq/backend/modules/marketplace/featherless"
	"github.com/culpeohq/backend/modules/marketplace/huggingface"
	"github.com/culpeohq/backend/modules/marketplace/openrouter"
	"github.com/culpeohq/backend/modules/marketplace/types"
	"github.com/culpeohq/backend/modules/node"
)

// nodeCallTimeout bounds a call a user made. Starting a download schedules it
// rather than waiting for it, so none of these calls is long-running.
const nodeCallTimeout = 20 * time.Second

// nodeListTimeout bounds the call behind the downloads list, which is polled
// while the panel is open. A node that is off has to drop out of it quickly.
const nodeListTimeout = 4 * time.Second

type MarketplaceModule struct {
	metadataClient *http.Client

	downloadClient *http.Client

	settingsStore *appsettings.Store
	activeModels  *apimodels.Store
	jobs          *DownloadJobStore

	// nodes is nil until a node registry is wired in, which is what makes
	// every download local by default.
	nodes node.Directory

	hfAPIBase string
	orAPIBase string
	flAPIBase string
}

func New(settingsFile string) *MarketplaceModule {
	cleanPath := strings.TrimSpace(settingsFile)
	if cleanPath == "" {
		cleanPath = appsettings.DefaultSettingsFile
	}
	dir := filepath.Dir(cleanPath)
	jobsFile := filepath.Join(dir, "download_jobs.json")

	return &MarketplaceModule{
		metadataClient: &http.Client{Timeout: 30 * time.Second},

		downloadClient: &http.Client{
			Transport: &http.Transport{
				DialContext: (&net.Dialer{
					Timeout:   10 * time.Second,
					KeepAlive: 30 * time.Second,
				}).DialContext,
				TLSHandshakeTimeout:   10 * time.Second,
				ResponseHeaderTimeout: 60 * time.Second,
			},
		},

		settingsStore: appsettings.NewStore(settingsFile),
		activeModels:  apimodels.NewStoreForSettings(cleanPath),
		jobs:          NewDownloadJobStore(jobsFile),
		hfAPIBase:     "https://huggingface.co",
		orAPIBase:     "https://openrouter.ai",
		flAPIBase:     "https://api.featherless.ai",
	}
}

func (m *MarketplaceModule) Name() string { return "marketplace" }

func (m *MarketplaceModule) Initialize() error {
	if _, err := m.loadSettings(); err != nil {
		return err
	}
	return nil
}

func (m *MarketplaceModule) Shutdown() error { return nil }

func prepareMarketplaceResults(models []types.ModelSummary, hardwareProfile HardwareProfile, query, format, category, quantization, normalizedQuantization string, localOnly, gpuOnly bool, sortMode string) []types.ModelSummary {
	models = filterModelsByQuery(models, query)
	models = enrichMarketplaceMetadata(models, hardwareProfile)
	models = filterModelsByFormat(models, format)
	models = filterModelsByCategory(models, category)
	models = filterModelsByQuantization(models, quantization)
	models = filterModelsByLocalOnly(models, localOnly)
	models = filterModelsByGPUFit(models, gpuOnly, hardwareProfile, normalizedQuantization)
	models = sortModels(models, sortMode)
	return models
}

func sanitizeTargetDir(baseDir, targetDir string) (string, error) {
	if runtime.GOOS != "windows" && appsettings.LooksLikeWindowsPath(baseDir) {
		return "", fmt.Errorf("model_dir ist ein Windows-Pfad; bitte in den Einstellungen einen Linux-Ordner auswählen")
	}
	baseAbs, err := filepath.Abs(filepath.Clean(baseDir))
	if err != nil {
		return "", fmt.Errorf("model_dir ungueltig: %w", err)
	}
	if strings.TrimSpace(targetDir) == "" {
		return baseAbs, nil
	}

	var candidate string
	if filepath.IsAbs(targetDir) {
		candidate = filepath.Clean(targetDir)
	} else {
		candidate = filepath.Clean(filepath.Join(baseAbs, targetDir))
	}

	if !isWithinDir(candidate, baseAbs) {
		return "", fmt.Errorf("target_dir ausserhalb des ModelDir")
	}
	return candidate, nil
}

func isWithinDir(child, parent string) bool {
	if child == parent {
		return true
	}

	return strings.HasPrefix(child, parent+string(filepath.Separator))
}

func (m *MarketplaceModule) searchProviders(ctx context.Context, provider, query, format string, limit int, settings appsettings.Settings) ([]types.ModelSummary, []string) {
	type providerSearch struct {
		name string
		fn   func() ([]types.ModelSummary, error)
	}

	searches := make([]providerSearch, 0, 4)
	switch provider {
	case types.ProviderAll:
		searches = append(searches,
			providerSearch{name: types.ProviderHuggingFace, fn: func() ([]types.ModelSummary, error) {
				return huggingface.SearchHuggingFace(ctx, m.metadataClient, m.hfAPIBase, query, format, limit, settings.HuggingFaceToken)
			}},
			providerSearch{name: types.ProviderOpenRouter, fn: func() ([]types.ModelSummary, error) {
				return openrouter.SearchOpenRouter(ctx, m.metadataClient, m.orAPIBase, query, format, limit, settings.OpenRouterToken)
			}},
			providerSearch{name: types.ProviderFeatherless, fn: func() ([]types.ModelSummary, error) {
				return featherless.SearchFeatherless(ctx, m.metadataClient, m.flAPIBase, query, format, limit, settings.FeatherlessToken)
			}},
		)
	case types.ProviderHuggingFace:
		searches = append(searches, providerSearch{name: types.ProviderHuggingFace, fn: func() ([]types.ModelSummary, error) {
			return huggingface.SearchHuggingFace(ctx, m.metadataClient, m.hfAPIBase, query, format, limit, settings.HuggingFaceToken)
		}})
	case types.ProviderOpenRouter:
		searches = append(searches, providerSearch{name: types.ProviderOpenRouter, fn: func() ([]types.ModelSummary, error) {
			return openrouter.SearchOpenRouter(ctx, m.metadataClient, m.orAPIBase, query, format, limit, settings.OpenRouterToken)
		}})
	case types.ProviderFeatherless:
		searches = append(searches, providerSearch{name: types.ProviderFeatherless, fn: func() ([]types.ModelSummary, error) {
			return featherless.SearchFeatherless(ctx, m.metadataClient, m.flAPIBase, query, format, limit, settings.FeatherlessToken)
		}})
	}

	if len(searches) == 1 {

		result, err := searches[0].fn()
		if err != nil {
			return nil, []string{searches[0].name + ": " + err.Error()}
		}
		return result, nil
	}

	g, gctx := errgroup.WithContext(ctx)
	results := make([][]types.ModelSummary, len(searches))
	errs := make([]error, len(searches))

	for i := range searches {
		i := i
		s := searches[i]
		g.Go(func() error {

			if gctx.Err() != nil {
				return gctx.Err()
			}
			r, err := s.fn()
			results[i] = r
			errs[i] = err
			return nil
		})
	}
	_ = g.Wait()

	models := make([]types.ModelSummary, 0)
	errorsOut := make([]string, 0)
	for i, s := range searches {
		if errs[i] != nil {
			errorsOut = append(errorsOut, s.name+": "+errs[i].Error())
			continue
		}
		models = append(models, results[i]...)
	}
	return models, errorsOut
}

func (m *MarketplaceModule) loadSearchModels(ctx context.Context, provider, query, format string, limit int, settings appsettings.Settings) ([]types.ModelSummary, []string) {
	models, providerErrors := m.searchProviders(ctx, provider, query, format, limit, settings)
	if provider == types.ProviderAll {
		suggestions := m.defaultSuggestions(provider, limit)
		if strings.TrimSpace(query) == "" {
			merged := make([]types.ModelSummary, 0, len(suggestions)+len(models))
			merged = append(merged, models...)
			merged = append(merged, suggestions...)
			models = deduplicateModels(merged)
		} else if len(models) == 0 {
			models = mergeModelLists(models, suggestions, limit)
		}
	} else if len(models) == 0 {
		models = mergeModelLists(models, m.defaultSuggestions(provider, limit), limit)
	}
	return models, providerErrors
}

func paginateModels(models []types.ModelSummary, page int, pageSize int) ([]types.ModelSummary, bool) {
	if pageSize <= 0 {
		pageSize = 20
	}
	if page <= 0 {
		page = 1
	}
	start := (page - 1) * pageSize
	if start >= len(models) {
		return []types.ModelSummary{}, false
	}
	end := start + pageSize
	if end > len(models) {
		end = len(models)
	}
	hasMore := end < len(models)
	return models[start:end], hasMore
}

func (m *MarketplaceModule) runDownloadJob(jobID string) {
	job, ok := m.jobs.Get(jobID)
	if !ok {
		return
	}

	settings, err := m.loadSettings()
	if err != nil {
		m.jobs.SetFailed(jobID, err)
		return
	}

	m.jobs.SetRunning(jobID)
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Hour)
	defer cancel()

	m.jobs.RegisterCancel(jobID, cancel)
	defer m.jobs.UnregisterCancel(jobID)

	progressFn := func(progress int) {
		m.jobs.SetProgress(jobID, progress)
	}

	statsFn := func(downloadedBytes int64, totalBytes int64, speedBytesPerSec int64) {
		m.jobs.SetStats(jobID, downloadedBytes, totalBytes, speedBytesPerSec)
	}

	assets := types.UniqueNonEmpty(job.AssetIDs)
	if len(assets) == 0 {
		assets = []string{job.AssetID}
	}
	var outputPath string
	switch job.Provider {
	case types.ProviderHuggingFace:
		descriptor, resolveErr := huggingface.ResolveBundleAssets(ctx, m.metadataClient, m.hfAPIBase, job.ModelID, job.Revision, settings.HuggingFaceToken, assets)
		if resolveErr != nil {
			err = fmt.Errorf("Repository-Bundle konnte nicht aufgeloest werden: %w", resolveErr)
			break
		}
		assets = descriptor.Assets
		m.jobs.SetResolvedBundle(jobID, descriptor.Revision, descriptor.CommitSHA, assets)
		pinnedRevision := descriptor.CommitSHA
		if pinnedRevision == "" {
			pinnedRevision = descriptor.Revision
		}
		stagingDir, finalDir, prepareErr := prepareBundlePaths(job.TargetDir, job.Provider, job.ModelID, pinnedRevision, job.ID)
		if prepareErr != nil {
			err = prepareErr
			break
		}
		published := false
		defer func() {
			if !published {
				_ = os.RemoveAll(stagingDir)
			}
		}()
		var completedBytes int64
		expectedTotal := job.TotalBytes
		for index, assetID := range assets {
			completed := index
			shardProgress := func(progress int) {
				progressFn((completed*100 + progress) / len(assets))
			}
			shardStats := func(downloadedBytes int64, totalBytes int64, speedBytesPerSec int64) {
				combinedTotal := expectedTotal
				if combinedTotal <= 0 && totalBytes > 0 {
					combinedTotal = completedBytes + totalBytes
				}
				statsFn(completedBytes+downloadedBytes, combinedTotal, speedBytesPerSec)
			}
			outputPath, err = huggingface.DownloadHuggingFaceRevisionWithStats(ctx, m.downloadClient, m.hfAPIBase, job.ModelID, pinnedRevision, assetID, stagingDir, settings.HuggingFaceToken, shardProgress, shardStats)
			if err != nil {
				break
			}
			if info, statErr := os.Stat(outputPath); statErr == nil {
				completedBytes += info.Size()
				statsFn(completedBytes, expectedTotal, 0)
			}
		}
		if err == nil {
			releaseModelDirectory := modelstorage.Acquire(job.TargetDir)
			_, err = validateAndPublishBundle(stagingDir, finalDir, bundleManifest{
				Provider: job.Provider, Repository: job.ModelID, Revision: descriptor.Revision,
				CommitSHA: descriptor.CommitSHA, Format: descriptor.Format,
			}, assets)
			releaseModelDirectory()
			if err == nil {
				published = true
				outputPath = finalDir
			}
		}
	case types.ProviderOpenRouter, types.ProviderFeatherless:
		progressFn(25)

		modelSlug := job.ModelID
		if idx := strings.LastIndex(modelSlug, "/"); idx >= 0 && idx < len(modelSlug)-1 {
			modelSlug = modelSlug[idx+1:]
		}
		fileName := common.SafeFileName(modelSlug) + ".json"
		if mkErr := os.MkdirAll(job.TargetDir, 0o755); mkErr != nil {
			m.jobs.SetFailed(jobID, fmt.Errorf("zielverzeichnis nicht anlegbar: %w", mkErr))
			return
		}
		descPath := filepath.Join(job.TargetDir, fileName)
		content := fmt.Sprintf(`{"provider": %q, "model_id": %q}`+"\n", job.Provider, job.ModelID)
		if writeErr := os.WriteFile(descPath, []byte(content), 0o644); writeErr != nil {
			log.Printf("[marketplace] descriptor write %s: %v", descPath, writeErr)
			m.jobs.SetFailed(jobID, fmt.Errorf("deskriptor nicht schreibbar: %w", writeErr))
			return
		}
		progressFn(75)
		outputPath = job.Provider + "://" + job.ModelID
	default:
		err = fmt.Errorf("unsupported provider: %s", job.Provider)
	}

	if err != nil {
		m.jobs.SetFailed(jobID, err)
		return
	}
	m.jobs.SetDone(jobID, outputPath)
	completedJob, _ := m.jobs.Get(jobID)
	bus.Get().Emit("marketplace", bus.EventModelDownloaded, map[string]interface{}{
		"job_id": jobID, "provider": job.Provider, "model_id": job.ModelID,
		"revision": completedJob.Revision, "commit_sha": completedJob.CommitSHA, "path": outputPath,
	})
}

func (m *MarketplaceModule) loadSettings() (appsettings.Settings, error) {
	if err := m.settingsStore.Load(); err != nil {
		return appsettings.Settings{}, err
	}
	return m.settingsStore.Get(), nil
}
