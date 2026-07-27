package autoupdate

import (
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/url"
	"path"
	"runtime"
	"strings"
	"time"
)

const (
	ManifestSchemaVersion = 1
	maxManifestBytes      = 1 << 20
	defaultMaxAssetBytes  = int64(8 << 30)
)

type Manifest struct {
	SchemaVersion int              `json:"schema_version"`
	Version       string           `json:"version"`
	PublishedAt   string           `json:"published_at,omitempty"`
	Assets        map[string]Asset `json:"assets"`

	// Signature is reserved for a future signed manifest and is deliberately
	// not interpreted yet. Unknown fields are rejected, so a client that did
	// not know this name would refuse a signed manifest outright, fall back to
	// starting offline, and never receive another update. Accepting the key as
	// raw JSON keeps every released client able to read a manifest once
	// signing is introduced, whatever shape the signature ends up having.
	Signature json.RawMessage `json:"signature,omitempty"`
}

type Asset struct {
	URL       string     `json:"url"`
	SHA256    string     `json:"sha256"`
	Size      int64      `json:"size"`
	Format    string     `json:"format"`
	Launcher  Entrypoint `json:"launcher"`
	Backend   Entrypoint `json:"backend"`
	Frontend  Entrypoint `json:"frontend"`
	HealthURL string     `json:"health_url,omitempty"`
}

type Entrypoint struct {
	Path string   `json:"path"`
	Args []string `json:"args,omitempty"`
}

func DecodeManifest(reader io.Reader, manifestURL *url.URL) (Manifest, error) {
	limited := io.LimitReader(reader, maxManifestBytes+1)
	payload, err := io.ReadAll(limited)
	if err != nil {
		return Manifest{}, fmt.Errorf("read update manifest: %w", err)
	}
	if len(payload) > maxManifestBytes {
		return Manifest{}, fmt.Errorf("update manifest exceeds %d bytes", maxManifestBytes)
	}

	var manifest Manifest
	decoder := json.NewDecoder(strings.NewReader(string(payload)))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&manifest); err != nil {
		return Manifest{}, fmt.Errorf("decode update manifest: %w", err)
	}
	if err := ensureJSONEOF(decoder); err != nil {
		return Manifest{}, err
	}
	if err := manifest.validate(manifestURL); err != nil {
		return Manifest{}, err
	}
	return manifest, nil
}

func ensureJSONEOF(decoder *json.Decoder) error {
	var extra any
	if err := decoder.Decode(&extra); err != io.EOF {
		if err == nil {
			return fmt.Errorf("update manifest contains multiple JSON values")
		}
		return fmt.Errorf("decode update manifest trailer: %w", err)
	}
	return nil
}

func (manifest *Manifest) validate(manifestURL *url.URL) error {
	if manifest.SchemaVersion != ManifestSchemaVersion {
		return fmt.Errorf("unsupported update manifest schema %d", manifest.SchemaVersion)
	}
	if _, err := parseSemanticVersion(manifest.Version); err != nil {
		return fmt.Errorf("invalid manifest version %q: %w", manifest.Version, err)
	}
	manifest.Version = strings.TrimPrefix(strings.TrimSpace(manifest.Version), "v")
	if manifest.PublishedAt != "" {
		if _, err := time.Parse(time.RFC3339, manifest.PublishedAt); err != nil {
			return fmt.Errorf("invalid manifest published_at: %w", err)
		}
	}
	if manifest.Assets == nil {
		return fmt.Errorf("update manifest assets are missing")
	}
	for platform, asset := range manifest.Assets {
		if err := validatePlatformKey(platform); err != nil {
			return err
		}
		if err := asset.validate(manifestURL); err != nil {
			return fmt.Errorf("invalid asset %q: %w", platform, err)
		}
		manifest.Assets[platform] = asset
	}
	return nil
}

func (asset *Asset) validate(manifestURL *url.URL) error {
	if asset.URL == "" {
		return fmt.Errorf("url is empty")
	}
	assetURL, err := url.Parse(asset.URL)
	if err != nil {
		return fmt.Errorf("parse url: %w", err)
	}
	if !assetURL.IsAbs() {
		if manifestURL == nil || !manifestURL.IsAbs() {
			return fmt.Errorf("relative asset url requires an absolute manifest url")
		}
		assetURL = manifestURL.ResolveReference(assetURL)
	}
	if assetURL.User != nil || assetURL.Fragment != "" {
		return fmt.Errorf("url must not contain credentials or a fragment")
	}
	asset.URL = assetURL.String()

	checksum, err := hex.DecodeString(strings.TrimSpace(asset.SHA256))
	if err != nil || len(checksum) != 32 {
		return fmt.Errorf("sha256 must contain exactly 64 hexadecimal characters")
	}
	asset.SHA256 = strings.ToLower(strings.TrimSpace(asset.SHA256))
	if asset.Size <= 0 || asset.Size > defaultMaxAssetBytes {
		return fmt.Errorf("size must be between 1 and %d bytes", defaultMaxAssetBytes)
	}
	if asset.Format != "zip" && asset.Format != "tar.gz" {
		return fmt.Errorf("unsupported archive format %q", asset.Format)
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
			return fmt.Errorf("health_url must be an HTTP loopback URL")
		}
	}
	return nil
}

func validateEntrypoint(name string, entrypoint Entrypoint) error {
	if _, err := safeArchivePath(entrypoint.Path); err != nil {
		return fmt.Errorf("%s entrypoint: %w", name, err)
	}
	for _, argument := range entrypoint.Args {
		if strings.IndexByte(argument, 0) >= 0 {
			return fmt.Errorf("%s argument contains a NUL byte", name)
		}
	}
	return nil
}

func PlatformKey(goos, goarch string) (string, error) {
	var architecture string
	switch goarch {
	case "amd64":
		architecture = "x64"
	case "arm64":
		architecture = "arm64"
	default:
		return "", fmt.Errorf("unsupported architecture %q", goarch)
	}
	switch goos {
	case "linux", "windows", "darwin":
	default:
		return "", fmt.Errorf("unsupported operating system %q", goos)
	}
	if goos == "darwin" {
		goos = "macos"
	}
	return goos + "-" + architecture, nil
}

func CurrentPlatformKey() (string, error) {
	return PlatformKey(runtime.GOOS, runtime.GOARCH)
}

func validatePlatformKey(value string) error {
	parts := strings.Split(value, "-")
	if len(parts) != 2 {
		return fmt.Errorf("invalid platform key %q", value)
	}
	var goos string
	switch parts[0] {
	case "linux", "windows":
		goos = parts[0]
	case "macos":
		goos = "darwin"
	default:
		return fmt.Errorf("invalid platform key %q", value)
	}
	var goarch string
	switch parts[1] {
	case "x64":
		goarch = "amd64"
	case "arm64":
		goarch = "arm64"
	default:
		return fmt.Errorf("invalid platform key %q", value)
	}
	normalized, _ := PlatformKey(goos, goarch)
	if normalized != value {
		return fmt.Errorf("invalid platform key %q", value)
	}
	return nil
}

func safeArchivePath(raw string) (string, error) {
	if raw == "" || strings.IndexByte(raw, 0) >= 0 {
		return "", fmt.Errorf("path is empty or contains a NUL byte")
	}
	normalized := strings.ReplaceAll(raw, "\\", "/")
	if strings.HasPrefix(normalized, "/") || (len(normalized) >= 2 && normalized[1] == ':') {
		return "", fmt.Errorf("path %q is absolute", raw)
	}
	clean := path.Clean(normalized)
	if clean == "." || clean == ".." || strings.HasPrefix(clean, "../") {
		return "", fmt.Errorf("path %q escapes the bundle", raw)
	}
	return clean, nil
}

func isLoopbackHost(host string) bool {
	switch strings.ToLower(strings.TrimSpace(host)) {
	case "localhost", "127.0.0.1", "::1":
		return true
	default:
		return false
	}
}
