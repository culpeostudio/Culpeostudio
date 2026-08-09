package autoupdate

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"net/url"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

const (
	currentStateFilename = "current.json"
	bundleStateFilename  = ".culpeostudio-bundle.json"
)

type CurrentState struct {
	SchemaVersion int    `json:"schema_version"`
	Version       string `json:"version"`
	Bundle        string `json:"bundle"`
	AssetSHA256   string `json:"asset_sha256"`
	UpdatedAt     string `json:"updated_at"`
}

type BundleMetadata struct {
	CurrentState
	Asset Asset `json:"asset"`
}

type InstalledBundle struct {
	State    CurrentState
	Root     string
	Launcher string
	Backend  string
	Frontend string
	Asset    Asset
}

func LoadCurrent(installRoot string) (CurrentState, error) {
	payload, err := os.ReadFile(filepath.Join(installRoot, currentStateFilename))
	if err != nil {
		return CurrentState{}, err
	}
	var state CurrentState
	decoder := json.NewDecoder(strings.NewReader(string(payload)))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&state); err != nil {
		return CurrentState{}, fmt.Errorf("decode installed version state: %w", err)
	}
	if err := ensureJSONEOF(decoder); err != nil {
		return CurrentState{}, err
	}
	if err := validateCurrentState(state); err != nil {
		return CurrentState{}, err
	}
	return state, nil
}

func ActivateState(installRoot string, state CurrentState) error {
	if err := validateCurrentState(state); err != nil {
		return err
	}
	if _, err := ResolveInstalledBundle(installRoot, state); err != nil {
		return fmt.Errorf("cannot activate invalid bundle: %w", err)
	}
	if err := writeJSONAtomic(filepath.Join(installRoot, currentStateFilename), state, 0o600); err != nil {
		return err
	}
	_ = syncDirectory(installRoot)
	return nil
}

func validateCurrentState(state CurrentState) error {
	if state.SchemaVersion != ManifestSchemaVersion {
		return fmt.Errorf("unsupported installed version schema %d", state.SchemaVersion)
	}
	if _, err := parseSemanticVersion(state.Version); err != nil {
		return fmt.Errorf("invalid installed version %q: %w", state.Version, err)
	}
	bundle, err := safeArchivePath(state.Bundle)
	if err != nil || !strings.HasPrefix(bundle, "versions/") {
		return fmt.Errorf("invalid installed bundle path %q", state.Bundle)
	}
	if checksum, err := hex.DecodeString(state.AssetSHA256); err != nil || len(checksum) != 32 {
		return fmt.Errorf("invalid installed asset checksum")
	}
	if _, err := time.Parse(time.RFC3339, state.UpdatedAt); err != nil {
		return fmt.Errorf("invalid installed update timestamp: %w", err)
	}
	return nil
}

func ResolveInstalledBundle(installRoot string, state CurrentState) (InstalledBundle, error) {
	if err := validateCurrentState(state); err != nil {
		return InstalledBundle{}, err
	}
	root, err := secureBundlePath(installRoot, state.Bundle)
	if err != nil {
		return InstalledBundle{}, err
	}
	metadata, err := LoadBundleMetadata(root)
	if err != nil {
		return InstalledBundle{}, fmt.Errorf("load bundle metadata: %w", err)
	}
	if metadata.CurrentState.Version != state.Version ||
		!strings.EqualFold(metadata.CurrentState.AssetSHA256, state.AssetSHA256) ||
		metadata.CurrentState.Bundle != state.Bundle ||
		!strings.EqualFold(metadata.Asset.SHA256, state.AssetSHA256) {
		return InstalledBundle{}, fmt.Errorf("installed bundle metadata does not match current.json")
	}
	asset := metadata.Asset
	if err := validateLocalAsset(asset); err != nil {
		return InstalledBundle{}, fmt.Errorf("installed asset metadata is invalid: %w", err)
	}
	launcher, err := validateInstalledEntrypoint(root, asset.Launcher.Path)
	if err != nil {
		return InstalledBundle{}, fmt.Errorf("launcher entrypoint: %w", err)
	}
	backend, err := validateInstalledEntrypoint(root, asset.Backend.Path)
	if err != nil {
		return InstalledBundle{}, fmt.Errorf("backend entrypoint: %w", err)
	}
	frontend, err := validateInstalledEntrypoint(root, asset.Frontend.Path)
	if err != nil {
		return InstalledBundle{}, fmt.Errorf("frontend entrypoint: %w", err)
	}
	return InstalledBundle{
		State:    state,
		Root:     root,
		Launcher: launcher,
		Backend:  backend,
		Frontend: frontend,
		Asset:    asset,
	}, nil
}

func LoadBundleMetadata(bundleRoot string) (BundleMetadata, error) {
	payload, err := os.ReadFile(filepath.Join(bundleRoot, bundleStateFilename))
	if err != nil {
		return BundleMetadata{}, err
	}
	var metadata BundleMetadata
	decoder := json.NewDecoder(strings.NewReader(string(payload)))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&metadata); err != nil {
		return BundleMetadata{}, err
	}
	if err := ensureJSONEOF(decoder); err != nil {
		return BundleMetadata{}, err
	}
	if err := validateCurrentState(metadata.CurrentState); err != nil {
		return BundleMetadata{}, err
	}
	return metadata, nil
}

func validateLocalAsset(asset Asset) error {
	if checksum, err := hex.DecodeString(asset.SHA256); err != nil || len(checksum) != 32 {
		return fmt.Errorf("invalid asset checksum")
	}
	if asset.Size <= 0 || asset.Size > defaultMaxAssetBytes {
		return fmt.Errorf("invalid asset size")
	}
	if asset.Format != "zip" && asset.Format != "tar.gz" {
		return fmt.Errorf("invalid asset format")
	}
	if err := validateEntrypoint("launcher", asset.Launcher); err != nil {
		return err
	}
	if err := validateEntrypoint("backend", asset.Backend); err != nil {
		return err
	}
	if err := validateEntrypoint("frontend", asset.Frontend); err != nil {
		return err
	}
	if asset.HealthURL != "" {
		healthURL, err := url.Parse(asset.HealthURL)
		if err != nil || healthURL.Scheme != "http" || !isLoopbackHost(healthURL.Hostname()) {
			return fmt.Errorf("invalid health URL")
		}
	}
	return nil
}

func (client *Client) Install(ctx context.Context, installRoot string, manifest Manifest, asset Asset) (CurrentState, error) {
	absoluteRoot, err := filepath.Abs(installRoot)
	if err != nil {
		return CurrentState{}, fmt.Errorf("resolve install root: %w", err)
	}
	versionsRoot := filepath.Join(absoluteRoot, "versions")
	if err := os.MkdirAll(versionsRoot, 0o755); err != nil {
		return CurrentState{}, fmt.Errorf("create versions directory: %w", err)
	}
	bundleName := manifest.Version + "-" + asset.SHA256[:12]
	target := filepath.Join(versionsRoot, bundleName)
	state := CurrentState{
		SchemaVersion: ManifestSchemaVersion,
		Version:       manifest.Version,
		Bundle:        filepath.ToSlash(filepath.Join("versions", bundleName)),
		AssetSHA256:   asset.SHA256,
		UpdatedAt:     time.Now().UTC().Format(time.RFC3339),
	}

	installed, err := bundleAlreadyInstalled(target, state, asset)
	if err != nil {
		return CurrentState{}, err
	}
	if !installed {
		if err := client.stageBundle(ctx, absoluteRoot, versionsRoot, target, state, asset); err != nil {
			return CurrentState{}, err
		}
	}
	if err := writeJSONAtomic(filepath.Join(absoluteRoot, currentStateFilename), state, 0o600); err != nil {
		return CurrentState{}, fmt.Errorf("activate update: %w", err)
	}
	_ = syncDirectory(versionsRoot)
	_ = syncDirectory(absoluteRoot)
	return state, nil
}

func bundleAlreadyInstalled(target string, state CurrentState, asset Asset) (bool, error) {
	info, err := os.Stat(target)
	if errors.Is(err, os.ErrNotExist) {
		return false, nil
	}
	if err != nil {
		return false, fmt.Errorf("inspect bundle target: %w", err)
	}
	if !info.IsDir() {
		return false, fmt.Errorf("bundle target %q is not a directory", target)
	}
	metadata, err := LoadBundleMetadata(target)
	if err != nil {
		return false, fmt.Errorf("bundle target %q has unreadable metadata: %w", target, err)
	}
	if metadata.CurrentState.Version != state.Version ||
		metadata.CurrentState.Bundle != state.Bundle ||
		!strings.EqualFold(metadata.CurrentState.AssetSHA256, state.AssetSHA256) {
		return false, fmt.Errorf("bundle target %q already exists with different metadata", target)
	}
	if err := validateBundleEntrypoints(target, asset); err != nil {
		return false, fmt.Errorf("existing bundle is invalid: %w", err)
	}
	return true, nil
}

func (client *Client) stageBundle(
	ctx context.Context,
	absoluteRoot string,
	versionsRoot string,
	target string,
	state CurrentState,
	asset Asset,
) error {
	workRoot, err := os.MkdirTemp(absoluteRoot, updateWorkPrefix)
	if err != nil {
		return fmt.Errorf("create update work directory: %w", err)
	}
	defer os.RemoveAll(workRoot)
	archivePath := filepath.Join(workRoot, "bundle."+strings.ReplaceAll(asset.Format, ".", "-"))
	if err := client.DownloadAsset(ctx, asset, archivePath); err != nil {
		return err
	}

	staging, err := os.MkdirTemp(versionsRoot, stagingPrefix)
	if err != nil {
		return fmt.Errorf("create bundle staging directory: %w", err)
	}
	keepStaging := false
	defer func() {
		if !keepStaging {
			_ = os.RemoveAll(staging)
		}
	}()
	if err := ExtractArchive(archivePath, asset.Format, staging); err != nil {
		return fmt.Errorf("extract update asset: %w", err)
	}
	if err := validateBundleEntrypoints(staging, asset); err != nil {
		return fmt.Errorf("validate staged bundle: %w", err)
	}
	metadata := BundleMetadata{CurrentState: state, Asset: asset}
	if err := writeJSONAtomic(filepath.Join(staging, bundleStateFilename), metadata, 0o600); err != nil {
		return fmt.Errorf("write staged bundle metadata: %w", err)
	}
	if err := os.Rename(staging, target); err != nil {
		return fmt.Errorf("activate staged bundle directory: %w", err)
	}
	keepStaging = true
	return nil
}

func validateBundleEntrypoints(bundleRoot string, asset Asset) error {
	for _, entrypoint := range []struct {
		name string
		path string
	}{
		{"launcher", asset.Launcher.Path},
		{"backend", asset.Backend.Path},
		{"frontend", asset.Frontend.Path},
	} {
		if _, err := validateInstalledEntrypoint(bundleRoot, entrypoint.path); err != nil {
			return fmt.Errorf("%s entrypoint: %w", entrypoint.name, err)
		}
	}
	return nil
}

func secureBundlePath(installRoot, relative string) (string, error) {
	clean, err := safeArchivePath(relative)
	if err != nil {
		return "", err
	}
	absoluteRoot, err := filepath.Abs(installRoot)
	if err != nil {
		return "", err
	}
	resolved := filepath.Join(absoluteRoot, filepath.FromSlash(clean))
	relation, err := filepath.Rel(absoluteRoot, resolved)
	if err != nil || relation == ".." || strings.HasPrefix(relation, ".."+string(filepath.Separator)) {
		return "", fmt.Errorf("bundle path escapes install root")
	}
	info, err := os.Stat(resolved)
	if err != nil {
		return "", err
	}
	if !info.IsDir() {
		return "", fmt.Errorf("bundle path is not a directory")
	}
	return resolved, nil
}

func validateInstalledEntrypoint(bundleRoot, relative string) (string, error) {
	clean, err := safeArchivePath(relative)
	if err != nil {
		return "", err
	}
	absoluteRoot, err := filepath.Abs(bundleRoot)
	if err != nil {
		return "", err
	}
	candidate := filepath.Join(absoluteRoot, filepath.FromSlash(clean))
	resolved, err := filepath.EvalSymlinks(candidate)
	if err != nil {
		return "", err
	}
	relation, err := filepath.Rel(absoluteRoot, resolved)
	if err != nil || relation == ".." || strings.HasPrefix(relation, ".."+string(filepath.Separator)) {
		return "", fmt.Errorf("entrypoint escapes bundle")
	}
	info, err := os.Stat(resolved)
	if err != nil {
		return "", err
	}
	if !info.Mode().IsRegular() {
		return "", fmt.Errorf("entrypoint is not a regular file")
	}
	if runtime.GOOS != "windows" && info.Mode().Perm()&0o111 == 0 {
		return "", fmt.Errorf("entrypoint is not executable")
	}
	return resolved, nil
}

func writeJSONAtomic(destination string, value any, permissions fs.FileMode) (err error) {
	payload, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		return err
	}
	payload = append(payload, '\n')
	directory := filepath.Dir(destination)
	if err := os.MkdirAll(directory, 0o755); err != nil {
		return err
	}
	temporary, err := os.CreateTemp(directory, "."+filepath.Base(destination)+".tmp-")
	if err != nil {
		return err
	}
	temporaryPath := temporary.Name()
	keep := false
	defer func() {
		_ = temporary.Close()
		if !keep {
			_ = os.Remove(temporaryPath)
		}
	}()
	if err := temporary.Chmod(permissions); err != nil {
		return err
	}
	if _, err := temporary.Write(payload); err != nil {
		return err
	}
	if err := temporary.Sync(); err != nil {
		return err
	}
	if err := temporary.Close(); err != nil {
		return err
	}
	if err := replaceFile(temporaryPath, destination); err != nil {
		return err
	}
	keep = true
	return nil
}

func syncDirectory(directory string) error {
	handle, err := os.Open(directory)
	if err != nil {
		return err
	}
	defer handle.Close()
	if err := handle.Sync(); err != nil && !errors.Is(err, os.ErrInvalid) {
		return err
	}
	return nil
}
