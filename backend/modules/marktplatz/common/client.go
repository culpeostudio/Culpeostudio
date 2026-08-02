// Package common holds the HTTP client shared by the marketplace providers.
package common

import (
	"context"
	"encoding/json"
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

func friendlyDownloadStatusError(status int, body string) error {
	detail := strings.TrimSpace(body)
	if len(detail) > 160 {
		detail = detail[:160] + "..."
	}
	switch {
	case status == http.StatusUnauthorized:
		return fmt.Errorf("Zugriff verweigert (401): Der Zugriffstoken fehlt oder ist ungueltig. Bitte den Anbieter-Token in den Einstellungen pruefen")
	case status == http.StatusForbidden:
		return fmt.Errorf("Zugriff verweigert (403): Dieses Modell erfordert eine Freigabe beim Anbieter (gated model) oder der Token hat keine Berechtigung")
	case status == http.StatusNotFound:
		return fmt.Errorf("Nicht gefunden (404): Das Modell oder die Datei existiert beim Anbieter nicht mehr. Bitte die Modellliste aktualisieren")
	case status == http.StatusRequestTimeout || status == http.StatusGatewayTimeout:
		return fmt.Errorf("Zeitueberschreitung (%d): Die Verbindung zum Anbieter ist zu langsam oder instabil. Bitte spaeter erneut versuchen", status)
	case status == http.StatusTooManyRequests:
		return fmt.Errorf("Zu viele Anfragen (429): Der Anbieter drosselt Downloads gerade. Bitte einige Minuten warten und erneut versuchen")
	case status >= 500:
		return fmt.Errorf("Serverfehler (%d) beim Anbieter. Das liegt nicht an deinem System; bitte spaeter erneut versuchen", status)
	default:
		if detail == "" {
			return fmt.Errorf("Download fehlgeschlagen (%d)", status)
		}
		return fmt.Errorf("Download fehlgeschlagen (%d): %s", status, detail)
	}
}

func friendlyTransportError(err error) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, context.Canceled) {
		return err
	}
	var dnsError *net.DNSError
	if errors.As(err, &dnsError) {
		return fmt.Errorf("Der Anbieter ist nicht erreichbar (DNS-Aufloesung fehlgeschlagen). Bitte die Internetverbindung pruefen")
	}
	var netError net.Error
	if errors.As(err, &netError) && netError.Timeout() {
		return fmt.Errorf("Zeitueberschreitung beim Download: Die Verbindung ist zu langsam oder wurde unterbrochen. Bitte erneut versuchen")
	}
	if errors.Is(err, context.DeadlineExceeded) {
		return fmt.Errorf("Zeitueberschreitung beim Download: Die Verbindung ist zu langsam oder wurde unterbrochen. Bitte erneut versuchen")
	}
	lower := strings.ToLower(err.Error())
	if strings.Contains(lower, "connection refused") || strings.Contains(lower, "connection reset") || strings.Contains(lower, "broken pipe") || strings.Contains(lower, "unexpected eof") {
		return fmt.Errorf("Die Verbindung zum Anbieter wurde unterbrochen. Der Download kann erneut gestartet werden und setzt vorhandene Dateien fort")
	}
	return err
}

func RequestJSON(ctx context.Context, httpClient *http.Client, method, rawURL string, headers map[string]string, out interface{}) error {
	reqCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(reqCtx, method, rawURL, nil)
	if err != nil {
		return err
	}
	for key, value := range headers {
		if strings.TrimSpace(value) != "" {
			req.Header.Set(key, value)
		}
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", "myphiloengine-marktplatz/1.0")

	resp, err := httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 2048))
		return fmt.Errorf("request failed (%d): %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	const maxResponseBytes = 64 * 1024 * 1024
	limited := io.LimitReader(resp.Body, maxResponseBytes)
	return json.NewDecoder(limited).Decode(out)
}

func DownloadFile(ctx context.Context, httpClient *http.Client, sourceURL string, headers map[string]string, targetDir string, fileName string, onProgress func(int)) (string, error) {
	return DownloadFileWithStats(ctx, httpClient, sourceURL, headers, targetDir, fileName, onProgress, nil)
}

func DownloadFileWithStats(ctx context.Context, httpClient *http.Client, sourceURL string, headers map[string]string, targetDir string, fileName string, onProgress func(int), onStats func(downloadedBytes int64, totalBytes int64, speedBytesPerSec int64)) (string, error) {
	const (
		requestStartedProgress = 2
		responseReadyProgress  = 3
		copyCompleteProgress   = 90
	)

	if strings.TrimSpace(targetDir) == "" {
		return "", fmt.Errorf("target_dir is empty")
	}
	if err := os.MkdirAll(targetDir, 0o755); err != nil {
		return "", err
	}

	if onProgress != nil {
		onProgress(requestStartedProgress)
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, sourceURL, nil)
	if err != nil {
		return "", err
	}
	for key, value := range headers {
		if strings.TrimSpace(value) != "" {
			req.Header.Set(key, value)
		}
	}

	resp, err := httpClient.Do(req)
	if err != nil {
		return "", friendlyTransportError(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 2048))
		return "", friendlyDownloadStatusError(resp.StatusCode, string(body))
	}

	if onProgress != nil {
		onProgress(responseReadyProgress)
	}

	if onStats != nil && resp.ContentLength > 0 {
		onStats(0, resp.ContentLength, 0)
	}

	name := ""
	if relative, ok := SafeRelativePath(fileName); ok {
		name = relative
	} else {
		name = SafeFileName(fileName)
	}
	if name == "" {
		parsed, parseErr := url.Parse(sourceURL)
		if parseErr == nil {
			name = SafeFileName(filepath.Base(parsed.Path))
		}
	}
	if name == "" {
		name = "model.bin"
	}

	finalPath := filepath.Join(targetDir, name)
	if err := os.MkdirAll(filepath.Dir(finalPath), 0o755); err != nil {
		return "", err
	}
	partPath := finalPath + ".part"
	if info, statErr := os.Stat(finalPath); statErr == nil && resp.ContentLength > 0 && info.Size() == resp.ContentLength {
		if onProgress != nil {
			onProgress(copyCompleteProgress)
		}
		return finalPath, nil
	}

	dst, err := os.Create(partPath)
	if err != nil {
		return "", err
	}

	buffer := make([]byte, 256*1024)
	var written int64
	lastProgress := responseReadyProgress
	var nextUnknownProgressStep int64 = 25 * 1024 * 1024
	total := resp.ContentLength

	speedCheckpoint := time.Now()
	speedCheckpointBytes := int64(0)
	lastStatsEmit := time.Now()

	for {
		n, readErr := resp.Body.Read(buffer)
		if n > 0 {
			writtenNow, writeErr := dst.Write(buffer[:n])
			if writeErr != nil {
				_ = dst.Close()
				_ = os.Remove(partPath)
				return "", writeErr
			}
			written += int64(writtenNow)

			if onStats != nil && time.Since(lastStatsEmit) >= time.Second {
				now := time.Now()
				windowDelta := now.Sub(speedCheckpoint).Seconds()
				deltaBytes := written - speedCheckpointBytes
				var speed int64
				if windowDelta > 0 {
					speed = int64(float64(deltaBytes) / windowDelta)
				}

				speedCheckpoint = now
				speedCheckpointBytes = written
				lastStatsEmit = now
				onStats(written, total, speed)
			}

			if onProgress != nil {
				progress := lastProgress
				if total > 0 {
					calc := responseReadyProgress + int((written*int64(copyCompleteProgress-responseReadyProgress))/total)
					if calc > copyCompleteProgress {
						calc = copyCompleteProgress
					}
					progress = calc
				} else if written >= nextUnknownProgressStep {
					progress = lastProgress + 5
					if progress > 85 {
						progress = 85
					}
					nextUnknownProgressStep += 25 * 1024 * 1024
				}
				if progress > lastProgress {
					lastProgress = progress
					onProgress(progress)
				}
			}
		}

		if readErr == io.EOF {
			break
		}
		if readErr != nil {
			_ = dst.Close()
			_ = os.Remove(partPath)
			return "", friendlyTransportError(readErr)
		}
	}

	if closeErr := dst.Close(); closeErr != nil {
		_ = os.Remove(partPath)
		return "", closeErr
	}

	if onProgress != nil {
		onProgress(copyCompleteProgress)
	}

	if err := os.Rename(partPath, finalPath); err != nil {
		_ = os.Remove(partPath)
		return "", err
	}
	return finalPath, nil
}

func SafeRelativePath(name string) (string, bool) {
	raw := strings.TrimSpace(strings.ReplaceAll(name, "\\", "/"))
	if raw == "" || strings.HasPrefix(raw, "/") || filepath.IsAbs(raw) {
		return "", false
	}
	if len(raw) >= 2 && raw[1] == ':' {
		return "", false
	}
	clean := filepath.Clean(filepath.FromSlash(raw))
	if clean == "." || clean == ".." || strings.HasPrefix(clean, ".."+string(filepath.Separator)) {
		return "", false
	}
	return clean, true
}

func SafeFileName(name string) string {
	clean := strings.TrimSpace(name)
	if clean == "" {
		return ""
	}
	invalid := []string{"\\", "/", ":", "*", "?", "\"", "<", ">", "|"}
	for _, token := range invalid {
		clean = strings.ReplaceAll(clean, token, "_")
	}
	return clean
}
