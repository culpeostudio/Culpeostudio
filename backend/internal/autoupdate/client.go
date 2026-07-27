package autoupdate

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const (
	updaterUserAgent   = "MyPhiloEngine-Updater/1"
	downloadAttempts   = 3
	downloadRetryDelay = 2 * time.Second
)

type OriginPolicy struct {
	allowedHosts map[string]struct{}
	allowHTTP    bool
}

func NewOriginPolicy(allowedHosts []string, allowHTTP bool) OriginPolicy {
	hosts := make(map[string]struct{}, len(allowedHosts))
	for _, host := range allowedHosts {
		normalized := strings.ToLower(strings.TrimSpace(host))
		if normalized != "" {
			hosts[normalized] = struct{}{}
		}
	}
	return OriginPolicy{allowedHosts: hosts, allowHTTP: allowHTTP}
}

func GitHubOriginPolicy() OriginPolicy {
	return NewOriginPolicy([]string{
		"github.com",
		"raw.githubusercontent.com",
		"objects.githubusercontent.com",
		"release-assets.githubusercontent.com",
		"codeload.github.com",
	}, false)
}

func (policy OriginPolicy) Validate(rawURL string) (*url.URL, error) {
	parsed, err := url.Parse(rawURL)
	if err != nil {
		return nil, fmt.Errorf("parse update URL: %w", err)
	}
	if parsed.User != nil || parsed.Fragment != "" {
		return nil, fmt.Errorf("update URL must not contain credentials or a fragment")
	}
	if parsed.Scheme != "https" && !(policy.allowHTTP && parsed.Scheme == "http") {
		return nil, fmt.Errorf("update URL must use HTTPS")
	}
	host := strings.ToLower(parsed.Hostname())
	if _, allowed := policy.allowedHosts[host]; !allowed {
		return nil, fmt.Errorf("update host %q is not trusted", host)
	}
	return parsed, nil
}

type Client struct {
	manifestURL string
	policy      OriginPolicy
	httpClient  *http.Client
	maxAsset    int64
	retryDelay  time.Duration
}

func NewClient(manifestURL string, policy OriginPolicy) (*Client, error) {
	if _, err := policy.Validate(manifestURL); err != nil {
		return nil, fmt.Errorf("invalid manifest URL: %w", err)
	}
	transport := http.DefaultTransport.(*http.Transport).Clone()
	transport.DialContext = (&net.Dialer{
		Timeout:   15 * time.Second,
		KeepAlive: 30 * time.Second,
	}).DialContext
	transport.TLSHandshakeTimeout = 15 * time.Second
	transport.ResponseHeaderTimeout = 30 * time.Second
	transport.ExpectContinueTimeout = time.Second
	transport.IdleConnTimeout = 90 * time.Second

	client := &Client{
		manifestURL: manifestURL,
		policy:      policy,
		maxAsset:    defaultMaxAssetBytes,
		retryDelay:  downloadRetryDelay,
	}
	client.httpClient = &http.Client{
		Transport: transport,
		CheckRedirect: func(request *http.Request, via []*http.Request) error {
			if len(via) >= 10 {
				return fmt.Errorf("too many update redirects")
			}
			_, err := policy.Validate(request.URL.String())
			return err
		},
	}
	return client, nil
}

// NewClientForTesting provides dependency injection without weakening the
// production GitHub origin policy.
func NewClientForTesting(manifestURL string, policy OriginPolicy, httpClient *http.Client) (*Client, error) {
	client, err := NewClient(manifestURL, policy)
	if err != nil {
		return nil, err
	}
	if httpClient != nil {
		client.httpClient = httpClient
	}
	return client, nil
}

func (client *Client) FetchManifest(ctx context.Context) (Manifest, error) {
	manifestURL, err := client.policy.Validate(client.manifestURL)
	if err != nil {
		return Manifest{}, err
	}
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, manifestURL.String(), nil)
	if err != nil {
		return Manifest{}, fmt.Errorf("create manifest request: %w", err)
	}
	request.Header.Set("Accept", "application/json")
	request.Header.Set("User-Agent", updaterUserAgent)
	request.Header.Set("Cache-Control", "no-cache")
	request.Header.Set("Pragma", "no-cache")

	response, err := client.httpClient.Do(request)
	if err != nil {
		return Manifest{}, fmt.Errorf("download update manifest: %w", err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		_, _ = io.Copy(io.Discard, io.LimitReader(response.Body, 4<<10))
		return Manifest{}, fmt.Errorf("download update manifest: HTTP %d", response.StatusCode)
	}
	manifest, err := DecodeManifest(response.Body, manifestURL)
	if err != nil {
		return Manifest{}, err
	}
	for platform, asset := range manifest.Assets {
		if _, err := client.policy.Validate(asset.URL); err != nil {
			return Manifest{}, fmt.Errorf("asset %q: %w", platform, err)
		}
	}
	return manifest, nil
}

// DownloadAsset fetches asset into destination and verifies its size and
// checksum. Transport failures are retried because an update archive is large
// enough that a single dropped connection would otherwise abandon the update.
func (client *Client) DownloadAsset(ctx context.Context, asset Asset, destination string) error {
	assetURL, err := client.policy.Validate(asset.URL)
	if err != nil {
		return err
	}
	if asset.Size <= 0 || asset.Size > client.maxAsset {
		return fmt.Errorf("asset size %d is outside the allowed range", asset.Size)
	}
	if err := os.MkdirAll(filepath.Dir(destination), 0o700); err != nil {
		return fmt.Errorf("create update download directory: %w", err)
	}

	var lastErr error
	for attempt := 1; attempt <= downloadAttempts; attempt++ {
		if attempt > 1 {
			timer := time.NewTimer(time.Duration(attempt-1) * client.retryDelay)
			select {
			case <-ctx.Done():
				timer.Stop()
				return ctx.Err()
			case <-timer.C:
			}
		}
		lastErr = client.downloadOnce(ctx, assetURL, asset, destination)
		if lastErr == nil {
			return nil
		}
		if ctx.Err() != nil || !isRetryable(lastErr) {
			return lastErr
		}
	}
	return fmt.Errorf("download update asset after %d attempts: %w", downloadAttempts, lastErr)
}

// retryableError marks failures that are worth another attempt: dropped
// connections, server-side errors, and truncated bodies. A checksum mismatch is
// deliberately not retryable, because it means the server served content that
// does not match the manifest.
type retryableError struct{ cause error }

func (err retryableError) Error() string { return err.cause.Error() }

func (err retryableError) Unwrap() error { return err.cause }

func retryable(format string, arguments ...any) error {
	return retryableError{cause: fmt.Errorf(format, arguments...)}
}

func isRetryable(err error) bool {
	var retry retryableError
	return errors.As(err, &retry)
}

func retryableStatus(status int) bool {
	return status >= 500 || status == http.StatusRequestTimeout || status == http.StatusTooManyRequests
}

func (client *Client) downloadOnce(
	ctx context.Context,
	assetURL *url.URL,
	asset Asset,
	destination string,
) (err error) {
	// A previous attempt removes its partial file, but an interrupted process
	// may have left one behind and the exclusive create below would fail on it.
	if err := os.Remove(destination); err != nil && !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("remove partial update download: %w", err)
	}
	output, err := os.OpenFile(destination, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o600)
	if err != nil {
		return fmt.Errorf("create update download: %w", err)
	}
	keep := false
	defer func() {
		_ = output.Close()
		if !keep {
			_ = os.Remove(destination)
		}
	}()

	request, err := http.NewRequestWithContext(ctx, http.MethodGet, assetURL.String(), nil)
	if err != nil {
		return fmt.Errorf("create asset request: %w", err)
	}
	request.Header.Set("Accept", "application/octet-stream")
	request.Header.Set("User-Agent", updaterUserAgent)
	response, err := client.httpClient.Do(request)
	if err != nil {
		return retryable("download update asset: %w", err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		_, _ = io.Copy(io.Discard, io.LimitReader(response.Body, 4<<10))
		if retryableStatus(response.StatusCode) {
			return retryable("download update asset: HTTP %d", response.StatusCode)
		}
		return fmt.Errorf("download update asset: HTTP %d", response.StatusCode)
	}
	if response.ContentLength > asset.Size || response.ContentLength > client.maxAsset {
		return fmt.Errorf("update asset is larger than declared")
	}

	hasher := sha256.New()
	limited := io.LimitReader(response.Body, asset.Size+1)
	written, err := io.Copy(io.MultiWriter(output, hasher), limited)
	if err != nil {
		return retryable("write update asset: %w", err)
	}
	if written != asset.Size {
		return retryable("update asset size is %d bytes, expected %d", written, asset.Size)
	}
	actualChecksum := hex.EncodeToString(hasher.Sum(nil))
	if !strings.EqualFold(actualChecksum, asset.SHA256) {
		return fmt.Errorf("update asset checksum mismatch: got %s", actualChecksum)
	}
	if err := output.Sync(); err != nil {
		return fmt.Errorf("sync update asset: %w", err)
	}
	if err := output.Close(); err != nil {
		return fmt.Errorf("close update asset: %w", err)
	}
	keep = true
	return nil
}
