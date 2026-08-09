package marketplace

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"
)

type DownloadStatus string

const (
	DownloadStatusQueued  DownloadStatus = "queued"
	DownloadStatusRunning DownloadStatus = "running"
	DownloadStatusDone    DownloadStatus = "done"
	DownloadStatusFailed  DownloadStatus = "failed"
)

type DownloadJob struct {
	ID         string         `json:"id"`
	Provider   string         `json:"provider"`
	ModelID    string         `json:"model_id"`
	AssetID    string         `json:"asset_id,omitempty"`
	AssetIDs   []string       `json:"asset_ids,omitempty"`
	Revision   string         `json:"revision,omitempty"`
	CommitSHA  string         `json:"commit_sha,omitempty"`
	TargetDir  string         `json:"target_dir"`
	Status     DownloadStatus `json:"status"`
	Progress   int            `json:"progress"`
	Error      string         `json:"error,omitempty"`
	OutputPath string         `json:"output_path,omitempty"`
	CreatedAt  time.Time      `json:"created_at"`
	UpdatedAt  time.Time      `json:"updated_at"`
	StartedAt  *time.Time     `json:"started_at,omitempty"`
	FinishedAt *time.Time     `json:"finished_at,omitempty"`

	DownloadedBytes int64 `json:"downloaded_bytes,omitempty"`

	SpeedBytesPerSec int64 `json:"speed_bytes_per_sec,omitempty"`

	TotalBytes int64 `json:"total_bytes,omitempty"`
}

type DownloadJobStore struct {
	mu              sync.RWMutex
	persistencePath string
	jobs            map[string]*DownloadJob
	ordered         []string
	cancels         map[string]context.CancelFunc
}

func NewDownloadJobStore(persistencePath ...string) *DownloadJobStore {
	path := ""
	if len(persistencePath) > 0 {
		path = persistencePath[0]
	}
	s := &DownloadJobStore{
		persistencePath: path,
		jobs:            make(map[string]*DownloadJob),
		cancels:         make(map[string]context.CancelFunc),
	}
	if path != "" {
		s.load()
	}
	return s
}

func (s *DownloadJobStore) RegisterCancel(id string, cancel context.CancelFunc) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.cancels == nil {
		s.cancels = make(map[string]context.CancelFunc)
	}
	s.cancels[id] = cancel
}

func (s *DownloadJobStore) UnregisterCancel(id string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.cancels, id)
}

type persistedData struct {
	Jobs    map[string]*DownloadJob `json:"jobs"`
	Ordered []string                `json:"ordered"`
}

func newJobID() string {
	buf := make([]byte, 6)
	if _, err := rand.Read(buf); err != nil {

		return fmt.Sprintf("dl-%d", time.Now().UnixNano())
	}
	return "dl-" + hex.EncodeToString(buf)
}

func (s *DownloadJobStore) load() {
	s.mu.Lock()
	defer s.mu.Unlock()

	data, err := os.ReadFile(s.persistencePath)
	if err != nil {

		if !os.IsNotExist(err) {
			log.Printf("[marketplace] download_jobs load: %v", err)
		}
		return
	}

	var pd persistedData
	if err := json.Unmarshal(data, &pd); err != nil {
		log.Printf("[marketplace] download_jobs unmarshal: %v", err)
		return
	}

	if pd.Jobs != nil {
		s.jobs = pd.Jobs
	}
	if pd.Ordered != nil {
		s.ordered = pd.Ordered
	}
}

func (s *DownloadJobStore) save() {
	if s.persistencePath == "" {
		return
	}

	s.mu.Lock()
	jobsCopy := make(map[string]*DownloadJob, len(s.jobs))
	for k, v := range s.jobs {
		if v != nil {
			c := *v
			if v.StartedAt != nil {
				t := *v.StartedAt
				c.StartedAt = &t
			}
			if v.FinishedAt != nil {
				t := *v.FinishedAt
				c.FinishedAt = &t
			}
			jobsCopy[k] = &c
		}
	}
	orderedCopy := make([]string, len(s.ordered))
	copy(orderedCopy, s.ordered)
	s.mu.Unlock()

	pd := persistedData{
		Jobs:    jobsCopy,
		Ordered: orderedCopy,
	}

	data, err := json.MarshalIndent(pd, "", "  ")
	if err != nil {
		log.Printf("[marketplace] download_jobs marshal: %v", err)
		return
	}

	dir := filepath.Dir(s.persistencePath)
	if dir != "." && dir != "" {
		if err := os.MkdirAll(dir, 0o755); err != nil {
			log.Printf("[marketplace] download_jobs mkdir %s: %v", dir, err)
			return
		}
	}

	tmpPath := s.persistencePath + ".tmp"
	if err := os.WriteFile(tmpPath, data, 0o644); err != nil {
		log.Printf("[marketplace] download_jobs write tmp: %v", err)
		return
	}
	if err := os.Rename(tmpPath, s.persistencePath); err != nil {

		_ = os.Remove(tmpPath)
		log.Printf("[marketplace] download_jobs rename: %v", err)
	}
}

func (s *DownloadJobStore) Create(provider, modelID, assetID, targetDir string) DownloadJob {
	return s.CreateWithAssets(provider, modelID, assetID, nil, targetDir)
}

func (s *DownloadJobStore) CreateWithAssets(provider, modelID, assetID string, assetIDs []string, targetDir string) DownloadJob {
	return s.CreateWithAssetsAndRevision(provider, modelID, assetID, assetIDs, targetDir, "main")
}

func (s *DownloadJobStore) CreateWithAssetsAndRevision(provider, modelID, assetID string, assetIDs []string, targetDir, revision string) DownloadJob {
	now := time.Now().UTC()
	id := newJobID()
	job := &DownloadJob{
		ID:        id,
		Provider:  provider,
		ModelID:   modelID,
		AssetID:   assetID,
		AssetIDs:  append([]string(nil), assetIDs...),
		Revision:  revision,
		TargetDir: targetDir,
		Status:    DownloadStatusQueued,
		Progress:  0,
		CreatedAt: now,
		UpdatedAt: now,
	}

	s.mu.Lock()
	s.jobs[id] = job
	s.ordered = append(s.ordered, id)
	s.mu.Unlock()

	s.save()
	return copyJob(job)
}

func (s *DownloadJobStore) SetResolvedBundle(id, revision, commitSHA string, assets []string) {
	s.mutate(id, func(job *DownloadJob) {
		job.Revision = revision
		job.CommitSHA = commitSHA
		job.AssetIDs = append([]string(nil), assets...)
		job.UpdatedAt = time.Now().UTC()
	})
	s.save()
}

func (s *DownloadJobStore) Get(id string) (DownloadJob, bool) {

	s.mu.RLock()
	defer s.mu.RUnlock()
	job, ok := s.jobs[id]
	if !ok {
		return DownloadJob{}, false
	}
	return copyJob(job), true
}

func (s *DownloadJobStore) Delete(id string) bool {
	s.mu.Lock()
	if _, ok := s.jobs[id]; !ok {
		s.mu.Unlock()
		return false
	}

	cancel, ok := s.cancels[id]
	if ok {
		delete(s.cancels, id)
	}
	delete(s.jobs, id)

	for i, oID := range s.ordered {
		if oID == id {
			s.ordered = append(s.ordered[:i], s.ordered[i+1:]...)
			break
		}
	}
	s.mu.Unlock()

	if ok {
		cancel()
	}

	s.save()
	return true
}

func (s *DownloadJobStore) List() []DownloadJob {
	s.mu.RLock()
	defer s.mu.RUnlock()

	out := make([]DownloadJob, 0, len(s.ordered))
	for i := len(s.ordered) - 1; i >= 0; i-- {
		if job, ok := s.jobs[s.ordered[i]]; ok {
			out = append(out, copyJob(job))
		}
	}
	return out
}

func (s *DownloadJobStore) ActiveJobForModel(provider, modelID string) (DownloadJob, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	for i := len(s.ordered) - 1; i >= 0; i-- {
		job, ok := s.jobs[s.ordered[i]]
		if !ok {
			continue
		}
		if job.Provider != provider || job.ModelID != modelID {
			continue
		}
		if job.Status == DownloadStatusQueued || job.Status == DownloadStatusRunning {
			return copyJob(job), true
		}
	}
	return DownloadJob{}, false
}

func (s *DownloadJobStore) SetRunning(id string) {
	s.mutate(id, func(job *DownloadJob) {
		now := time.Now().UTC()
		job.Status = DownloadStatusRunning
		job.Progress = maxInt(job.Progress, 1)
		job.StartedAt = &now
		job.UpdatedAt = now
	})
	s.save()
}

func (s *DownloadJobStore) SetProgress(id string, progress int) {
	if progress < 0 {
		progress = 0
	}
	if progress > 99 {
		progress = 99
	}
	var changed bool
	s.mutate(id, func(job *DownloadJob) {
		if job.Status != DownloadStatusRunning {
			return
		}
		if progress > job.Progress {

			if progress-job.Progress >= 10 || progress == 99 || job.Progress == 1 {
				changed = true
			}
			job.Progress = progress
			job.UpdatedAt = time.Now().UTC()
		}
	})
	if changed {
		s.save()
	}
}

func (s *DownloadJobStore) SetExpectedBytes(id string, totalBytes int64) {
	if totalBytes <= 0 {
		return
	}
	s.mutate(id, func(job *DownloadJob) {
		job.TotalBytes = totalBytes
		job.UpdatedAt = time.Now().UTC()
	})
	s.save()
}

func (s *DownloadJobStore) SetStats(id string, downloadedBytes int64, totalBytes int64, speedBytesPerSec int64) {
	var changed bool
	s.mutate(id, func(job *DownloadJob) {
		if job.Status != DownloadStatusRunning {
			return
		}
		if downloadedBytes > 0 {
			job.DownloadedBytes = downloadedBytes
			changed = true
		}
		if totalBytes > job.TotalBytes {
			job.TotalBytes = totalBytes
		}
		if job.TotalBytes > 0 && job.DownloadedBytes > job.TotalBytes {
			job.DownloadedBytes = job.TotalBytes
		}
		job.SpeedBytesPerSec = speedBytesPerSec
		job.UpdatedAt = time.Now().UTC()
	})
	if changed {

		s.save()
	}
}

func (s *DownloadJobStore) SetDone(id, outputPath string) {
	s.mutate(id, func(job *DownloadJob) {
		now := time.Now().UTC()
		job.Status = DownloadStatusDone
		job.Progress = 100
		job.Error = ""
		job.OutputPath = outputPath
		job.UpdatedAt = now
		job.FinishedAt = &now
	})
	s.save()
}

func (s *DownloadJobStore) SetFailed(id string, err error) {
	s.mutate(id, func(job *DownloadJob) {
		now := time.Now().UTC()
		job.Status = DownloadStatusFailed
		job.UpdatedAt = now
		job.FinishedAt = &now
		if err != nil {
			job.Error = err.Error()
		}
	})
	s.save()
}

func (s *DownloadJobStore) mutate(id string, fn func(*DownloadJob)) {
	s.mu.Lock()
	defer s.mu.Unlock()
	job, ok := s.jobs[id]
	if !ok {
		return
	}
	fn(job)
}

func copyJob(job *DownloadJob) DownloadJob {
	if job == nil {
		return DownloadJob{}
	}
	out := *job
	out.AssetIDs = append([]string(nil), job.AssetIDs...)
	if job.StartedAt != nil {
		started := *job.StartedAt
		out.StartedAt = &started
	}
	if job.FinishedAt != nil {
		finished := *job.FinishedAt
		out.FinishedAt = &finished
	}
	return out
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}
