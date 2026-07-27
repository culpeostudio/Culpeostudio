package autoupdate

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const (
	quarantineFilename   = "quarantine.json"
	maxQuarantineEntries = 20
	maxQuarantineReason  = 300
)

// QuarantinedBundle records a version that was installed successfully but could
// not start, so the launcher does not download and retry it on every start.
type QuarantinedBundle struct {
	Version     string `json:"version"`
	AssetSHA256 string `json:"asset_sha256"`
	Reason      string `json:"reason,omitempty"`
	FailedAt    string `json:"failed_at"`
}

type Quarantine struct {
	SchemaVersion int                 `json:"schema_version"`
	Entries       []QuarantinedBundle `json:"entries"`
}

// LoadQuarantine reads the quarantine list. A missing list is not an error: it
// simply means no version has failed yet. A corrupt list returns an empty
// quarantine alongside the error so callers can warn and still offer updates.
func LoadQuarantine(installRoot string) (Quarantine, error) {
	empty := Quarantine{SchemaVersion: ManifestSchemaVersion}
	payload, err := os.ReadFile(filepath.Join(installRoot, quarantineFilename))
	if errors.Is(err, os.ErrNotExist) {
		return empty, nil
	}
	if err != nil {
		return empty, fmt.Errorf("read quarantine list: %w", err)
	}
	var quarantine Quarantine
	decoder := json.NewDecoder(strings.NewReader(string(payload)))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&quarantine); err != nil {
		return empty, fmt.Errorf("decode quarantine list: %w", err)
	}
	if err := ensureJSONEOF(decoder); err != nil {
		return empty, err
	}
	if quarantine.SchemaVersion != ManifestSchemaVersion {
		return empty, fmt.Errorf("unsupported quarantine schema %d", quarantine.SchemaVersion)
	}
	return quarantine, nil
}

// Contains reports whether exactly this build already failed to start. Keying
// on the asset checksum as well as the version means a republished build of the
// same version is still offered.
func (quarantine Quarantine) Contains(version, assetSHA256 string) bool {
	version = strings.TrimPrefix(strings.TrimSpace(version), "v")
	for _, entry := range quarantine.Entries {
		if entry.Version == version && strings.EqualFold(entry.AssetSHA256, assetSHA256) {
			return true
		}
	}
	return false
}

// QuarantineBundle remembers a broken version. It keeps the newest
// maxQuarantineEntries records so the list cannot grow without bound.
func QuarantineBundle(installRoot string, state CurrentState, reason string) error {
	if err := validateCurrentState(state); err != nil {
		return err
	}
	// A corrupt list must not stop us from recording the current failure,
	// otherwise the retry loop this guards against would return.
	quarantine, _ := LoadQuarantine(installRoot)
	quarantine.SchemaVersion = ManifestSchemaVersion
	if quarantine.Contains(state.Version, state.AssetSHA256) {
		return nil
	}
	quarantine.Entries = append(quarantine.Entries, QuarantinedBundle{
		Version:     state.Version,
		AssetSHA256: strings.ToLower(state.AssetSHA256),
		Reason:      summarizeReason(reason),
		FailedAt:    time.Now().UTC().Format(time.RFC3339),
	})
	if len(quarantine.Entries) > maxQuarantineEntries {
		quarantine.Entries = quarantine.Entries[len(quarantine.Entries)-maxQuarantineEntries:]
	}
	if err := writeJSONAtomic(filepath.Join(installRoot, quarantineFilename), quarantine, 0o600); err != nil {
		return fmt.Errorf("write quarantine list: %w", err)
	}
	_ = syncDirectory(installRoot)
	return nil
}

func summarizeReason(reason string) string {
	reason = strings.TrimSpace(strings.Join(strings.Fields(reason), " "))
	if len(reason) > maxQuarantineReason {
		return reason[:maxQuarantineReason]
	}
	return reason
}
