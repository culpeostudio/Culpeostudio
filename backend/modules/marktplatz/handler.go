package marktplatz

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"golang.org/x/sync/errgroup"

	"github.com/fillyengine/backend/internal/apimodels"
	"github.com/fillyengine/backend/internal/appsettings"
	"github.com/fillyengine/backend/internal/bus"
	enginehardware "github.com/fillyengine/backend/internal/hardware"
	"github.com/fillyengine/backend/internal/modelstorage"
	"github.com/fillyengine/backend/modules/marktplatz/common"
	"github.com/fillyengine/backend/modules/marktplatz/featherless"
	"github.com/fillyengine/backend/modules/marktplatz/huggingface"
	"github.com/fillyengine/backend/modules/marktplatz/openrouter"
	"github.com/fillyengine/backend/modules/marktplatz/types"
)

const catalogCacheTTL = 15 * time.Minute

type MarktplatzModule struct {
	metadataClient *http.Client

	downloadClient *http.Client

	settingsStore *appsettings.Store
	activeModels  *apimodels.Store
	jobs          *DownloadJobStore

	hfAPIBase string
	orAPIBase string
	flAPIBase string
}

func New(settingsFile string) *MarktplatzModule {
	cleanPath := strings.TrimSpace(settingsFile)
	if cleanPath == "" {
		cleanPath = appsettings.DefaultSettingsFile
	}
	dir := filepath.Dir(cleanPath)
	jobsFile := filepath.Join(dir, "download_jobs.json")

	return &MarktplatzModule{
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

func (m *MarktplatzModule) Name() string { return "marktplatz" }

func (m *MarktplatzModule) RegisterRoutes(r fiber.Router) {

	g := r.Group("/marktplatz")
	g.Get("/search", m.handleSearch)

	g.Get("/model", m.handleDetail)
	g.Get("/model/:id", m.handleDetail)
	g.Get("/hardware/profile", m.handleHardwareProfile)
	g.Post("/api-models/start", m.handleStartAPIModel)
	g.Get("/api-models/active", m.handleActiveAPIModels)
	g.Delete("/api-models/:model_ref", m.handleDeleteAPIModel)
	g.Post("/download", m.handleDownload)
	g.Get("/jobs", m.handleListJobs)
	g.Get("/job/:id", m.handleJobStatus)
	g.Delete("/job/:id", m.handleDeleteJob)
}

func (m *MarktplatzModule) handleDeleteJob(c *fiber.Ctx) error {
	jobID := strings.TrimSpace(c.Params("id"))
	if !m.jobs.Delete(jobID) {
		return c.Status(404).JSON(fiber.Map{"error": "job nicht gefunden"})
	}
	return c.JSON(fiber.Map{"success": true})
}

func (m *MarktplatzModule) handleStartAPIModel(c *fiber.Ctx) error {
	var body struct {
		Provider    string `json:"provider"`
		ModelID     string `json:"model_id"`
		DisplayName string `json:"display_name"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ungueltige Anfrage"})
	}

	provider := apimodels.NormalizeProvider(body.Provider)
	modelID := strings.TrimSpace(body.ModelID)
	if !apimodels.IsSupportedProvider(provider) {
		return c.Status(400).JSON(fiber.Map{"error": "nur OpenRouter und Featherless API-Modelle koennen im Chat gestartet werden"})
	}
	if modelID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "model_id ist erforderlich"})
	}

	settings, err := m.loadSettings()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "settings konnten nicht geladen werden"})
	}
	switch provider {
	case apimodels.ProviderOpenRouter:
		if strings.TrimSpace(settings.OpenRouterToken) == "" {
			return c.Status(400).JSON(fiber.Map{"error": "OpenRouter API-Key fehlt in den Einstellungen"})
		}
	case apimodels.ProviderFeatherless:
		if strings.TrimSpace(settings.FeatherlessToken) == "" {
			return c.Status(400).JSON(fiber.Map{"error": "Featherless API-Key fehlt in den Einstellungen"})
		}
	}

	model, err := m.activeModels.Start(provider, modelID, body.DisplayName)
	if err != nil {

		if errors.Is(err, apimodels.ErrActiveModelsLimitReached) {
			return c.Status(400).JSON(fiber.Map{
				"error":       err.Error(),
				"limit":       apimodels.MaxActiveModels,
				"retry_after": "delete_altes_modell",
			})
		}
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{
		"status": "started",
		"model":  model,
	})
}

func (m *MarktplatzModule) handleActiveAPIModels(c *fiber.Ctx) error {
	models, err := m.activeModels.List()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "aktive API-Modelle konnten nicht geladen werden"})
	}
	return c.JSON(fiber.Map{"models": models})
}

func (m *MarktplatzModule) handleDeleteAPIModel(c *fiber.Ctx) error {
	modelRef := strings.TrimSpace(c.Params("model_ref"))
	if modelRef == "" {
		return c.Status(400).JSON(fiber.Map{"error": "model_ref ist erforderlich"})
	}
	deleted, err := m.activeModels.Delete(modelRef)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "API-Modell konnte nicht geloescht werden"})
	}
	if !deleted {
		return c.Status(404).JSON(fiber.Map{"error": "API-Modell nicht gefunden"})
	}
	return c.JSON(fiber.Map{"success": true})
}

func (m *MarktplatzModule) Initialize() error {
	if _, err := m.loadSettings(); err != nil {
		return err
	}
	return nil
}

func (m *MarktplatzModule) Shutdown() error { return nil }

func (m *MarktplatzModule) handleSearch(c *fiber.Ctx) error {
	p, err := parseSearchParams(c)
	if err != nil {
		if fe, ok := err.(*fiberErr); ok {
			return c.Status(fe.status).JSON(fiber.Map{"error": fe.msg})
		}
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	settings, err := m.loadSettings()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "settings konnten nicht geladen werden"})
	}

	hardwareProfile := detectHardwareProfile()
	searchLimit := computeSearchLimit(p)
	searchProvider := p.resolvedProvider()
	postFilteredSearch := p.isPostFilteredSearch()

	searchLimit++
	if searchLimit > maxSearchWindow {
		searchLimit = maxSearchWindow
	}

	ctx := c.UserContext()
	targetResultCount := p.PageSize*p.Page + 1
	rawModelCount := 0
	var models []types.ModelSummary
	var providerErrors []string

	for {
		rawModels, currentProviderErrors := m.loadSearchModels(ctx, searchProvider, p.Query, p.Format, searchLimit, settings)
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

	if !hasMore && postFilteredSearch && rawModelCount == searchLimit && searchLimit < maxSearchWindow {
		hasMore = true
	}

	return c.JSON(fiber.Map{
		"models":          pagedModels,
		"total":           len(models),
		"returned":        len(pagedModels),
		"partial":         len(providerErrors) > 0,
		"errors":          providerErrors,
		"provider":        p.Provider,
		"page":            p.Page,
		"page_size":       p.PageSize,
		"has_more":        hasMore,
		"category":        p.Category,
		"sort":            p.SortMode,
		"gpu_fit":         p.GPUOnly,
		"local_only":      p.LocalOnly,
		"hardware":        hardwareProfile,
		"quantization":    normalizeQuantization(p.Quantization),
		"quantizationRaw": p.Quantization,
	})
}

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

func (m *MarktplatzModule) handleDetail(c *fiber.Ctx) error {
	provider := types.NormalizeProvider(c.Query("provider", ""))
	if provider == types.ProviderAll || provider == "" {
		return c.Status(400).JSON(fiber.Map{"error": "provider muss gesetzt sein"})
	}
	if !types.IsSupportedProvider(provider) {
		return c.Status(400).JSON(fiber.Map{"error": "ungueltiger provider"})
	}

	modelID := strings.TrimSpace(c.Query("id"))
	if modelID == "" {
		modelID = strings.TrimSpace(c.Params("id"))
	}
	if modelID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "model id fehlt"})
	}
	if decoded, err := url.QueryUnescape(modelID); err == nil && strings.TrimSpace(decoded) != "" {
		modelID = strings.TrimSpace(decoded)
	}

	settings, err := m.loadSettings()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "settings konnten nicht geladen werden"})
	}

	var detail types.ModelDetail
	switch provider {
	case types.ProviderHuggingFace:
		detail, err = huggingface.DetailHuggingFace(c.UserContext(), m.metadataClient, m.hfAPIBase, modelID, settings.HuggingFaceToken)
	case types.ProviderOpenRouter:
		detail, err = openrouter.DetailOpenRouter(c.UserContext(), m.metadataClient, m.orAPIBase, modelID, settings.OpenRouterToken)
	case types.ProviderFeatherless:
		detail, err = featherless.DetailFeatherless(c.UserContext(), m.metadataClient, m.flAPIBase, modelID, settings.FeatherlessToken)
	default:
		err = fmt.Errorf("provider unsupported")
	}
	if err != nil {
		return c.Status(502).JSON(fiber.Map{"error": err.Error()})
	}

	enriched := enrichMarketplaceMetadata([]types.ModelSummary{detail.ModelSummary}, detectHardwareProfile())
	detail.ModelSummary = enriched[0]
	return c.JSON(detail)
}

func (m *MarktplatzModule) handleDownload(c *fiber.Ctx) error {
	var body struct {
		Provider  string   `json:"provider"`
		ModelID   string   `json:"model_id"`
		AssetID   string   `json:"asset_id"`
		AssetIDs  []string `json:"asset_ids"`
		Revision  string   `json:"revision"`
		TargetDir string   `json:"target_dir"`

		SizeBytes int64 `json:"size_bytes"`
	}
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "ungueltige Anfrage"})
	}

	provider := types.NormalizeProvider(body.Provider)
	if provider == types.ProviderAll || provider == "" {
		return c.Status(400).JSON(fiber.Map{"error": "provider muss gesetzt sein"})
	}
	if !types.IsSupportedProvider(provider) {
		return c.Status(400).JSON(fiber.Map{"error": "ungueltiger provider"})
	}

	modelID := strings.TrimSpace(body.ModelID)
	if modelID == "" {
		return c.Status(400).JSON(fiber.Map{"error": "model_id ist erforderlich"})
	}

	if existing, ok := m.jobs.ActiveJobForModel(provider, modelID); ok {
		return c.JSON(fiber.Map{
			"job_id":   existing.ID,
			"status":   existing.Status,
			"existing": true,
			"message":  "Modell wird bereits heruntergeladen",
		})
	}

	settings, err := m.loadSettings()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "settings konnten nicht geladen werden"})
	}

	baseDir := strings.TrimSpace(settings.ModelDir)
	if baseDir == "" {
		baseDir = appsettings.DefaultModelDir
	}
	targetDir, dirErr := sanitizeTargetDir(baseDir, strings.TrimSpace(body.TargetDir))
	if dirErr != nil {
		return c.Status(400).JSON(fiber.Map{"error": dirErr.Error()})
	}

	if body.SizeBytes > 0 {
		profile := detectHardwareProfile()
		if live := enginehardware.Detect(c.UserContext(), targetDir); live.DiskFreeBytes > 0 && (profile.DiskFreeBytes == 0 || live.DiskFreeBytes < profile.DiskFreeBytes) {
			profile.DiskFreeBytes = live.DiskFreeBytes
			profile.DiskFree = formatBytesAsGB(live.DiskFreeBytes)
		}

		puffer := body.SizeBytes / 10
		if puffer < 1<<30 {
			puffer = 1 << 30
		}
		needed := body.SizeBytes + puffer
		if profile.DiskFreeBytes > 0 && needed > profile.DiskFreeBytes {
			return c.Status(400).JSON(fiber.Map{
				"error": fmt.Sprintf(
					"nicht genug Speicherplatz: brauche ~%.1f GB, frei %.1f GB",
					float64(needed)/float64(1<<30),
					float64(profile.DiskFreeBytes)/float64(1<<30),
				),
				"disk_free_bytes":     profile.DiskFreeBytes,
				"required_bytes":      needed,
				"required_puffer_pct": 10,
			})
		}
	}

	revision := strings.TrimSpace(body.Revision)
	if revision == "" {
		revision = "main"
	}
	job := m.jobs.CreateWithAssetsAndRevision(
		provider,
		modelID,
		strings.TrimSpace(body.AssetID),
		types.UniqueNonEmpty(body.AssetIDs),
		targetDir,
		revision,
	)
	m.jobs.SetExpectedBytes(job.ID, body.SizeBytes)
	go m.runDownloadJob(job.ID)

	return c.JSON(fiber.Map{
		"job_id":     job.ID,
		"status":     job.Status,
		"target_dir": targetDir,
	})
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

func (m *MarktplatzModule) handleListJobs(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"jobs": m.jobs.List(),
	})
}

func (m *MarktplatzModule) handleHardwareProfile(c *fiber.Ctx) error {
	return c.JSON(detectHardwareProfile())
}

func (m *MarktplatzModule) handleJobStatus(c *fiber.Ctx) error {
	jobID := strings.TrimSpace(c.Params("id"))
	job, ok := m.jobs.Get(jobID)
	if !ok {
		return c.Status(404).JSON(fiber.Map{"error": "job nicht gefunden"})
	}
	return c.JSON(job)
}

func (m *MarktplatzModule) searchProviders(ctx context.Context, provider, query, format string, limit int, settings appsettings.Settings) ([]types.ModelSummary, []string) {
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

func (m *MarktplatzModule) loadSearchModels(ctx context.Context, provider, query, format string, limit int, settings appsettings.Settings) ([]types.ModelSummary, []string) {
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

func (m *MarktplatzModule) runDownloadJob(jobID string) {
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
			log.Printf("[marktplatz] descriptor write %s: %v", descPath, writeErr)
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
	bus.Get().Emit("marktplatz", bus.EventModelDownloaded, map[string]interface{}{
		"job_id": jobID, "provider": job.Provider, "model_id": job.ModelID,
		"revision": completedJob.Revision, "commit_sha": completedJob.CommitSHA, "path": outputPath,
	})
}

func (m *MarktplatzModule) loadSettings() (appsettings.Settings, error) {
	if err := m.settingsStore.Load(); err != nil {
		return appsettings.Settings{}, err
	}
	return m.settingsStore.Get(), nil
}

var _ = errors.Is
