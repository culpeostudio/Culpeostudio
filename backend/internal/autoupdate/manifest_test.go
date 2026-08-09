package autoupdate

import (
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestPublishedManifestIsDecodable(t *testing.T) {
	t.Parallel()
	path := filepath.Join("..", "..", "..", "quikinstall", "manifest.json")
	payload, err := os.Open(path)
	if err != nil {
		t.Skipf("published manifest is not available: %v", err)
	}
	defer payload.Close()
	base, err := url.Parse("https://raw.githubusercontent.com/culpeohq/CulpeoStudio/main/quikinstall/manifest.json")
	if err != nil {
		t.Fatal(err)
	}
	manifest, err := DecodeManifest(payload, base)
	if err != nil {
		t.Fatalf("DecodeManifest(%s) error = %v", path, err)
	}
	if _, err := parseSemanticVersion(manifest.Version); err != nil {
		t.Fatalf("published version %q is invalid: %v", manifest.Version, err)
	}
	for platform := range manifest.Assets {
		if err := validatePlatformKey(platform); err != nil {
			t.Errorf("published asset %q: %v", platform, err)
		}
	}
}

func TestDecodeManifestAcceptsAReservedSignature(t *testing.T) {
	t.Parallel()
	base, err := url.Parse("https://raw.githubusercontent.com/example/project/main/quikinstall/manifest.json")
	if err != nil {
		t.Fatal(err)
	}
	for name, signature := range map[string]string{
		"string": `"ed25519:3045022100"`,
		"object": `{"algorithm": "ed25519", "key_id": "2026-07", "value": "abc"}`,
	} {
		t.Run(name, func(t *testing.T) {
			manifest, err := DecodeManifest(strings.NewReader(`{
				"schema_version": 1,
				"version": "1.2.3",
				"signature": `+signature+`,
				"assets": {}
			}`), base)
			if err != nil {
				t.Fatalf("DecodeManifest() rejected a signed manifest: %v", err)
			}
			if len(manifest.Signature) == 0 {
				t.Fatal("signature was not preserved for a future verifier")
			}
		})
	}
}

func TestDecodeManifestResolvesRelativeAssetURL(t *testing.T) {
	t.Parallel()
	base, err := url.Parse("https://raw.githubusercontent.com/example/project/main/quikinstall/manifest.json")
	if err != nil {
		t.Fatal(err)
	}
	manifest, err := DecodeManifest(strings.NewReader(`{
		"schema_version": 1,
		"version": "1.2.3",
		"published_at": "2026-07-26T12:00:00Z",
		"assets": {
			"linux-x64": {
				"url": "dist/culpeostudio-linux-x64.tar.gz",
				"sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
				"size": 1234,
				"format": "tar.gz",
				"launcher": {"path": "launcher/culpeostudio"},
				"backend": {"path": "backend/culpeostudio-server"},
				"frontend": {"path": "frontend/culpeostudio"},
				"health_url": "http://127.0.0.1:8080/health"
			}
		}
	}`), base)
	if err != nil {
		t.Fatalf("DecodeManifest() error = %v", err)
	}
	got := manifest.Assets["linux-x64"].URL
	want := "https://raw.githubusercontent.com/example/project/main/quikinstall/dist/culpeostudio-linux-x64.tar.gz"
	if got != want {
		t.Fatalf("resolved URL = %q, want %q", got, want)
	}
}

func TestDecodeManifestRejectsUnsafeEntrypoint(t *testing.T) {
	t.Parallel()
	base, _ := url.Parse("https://example.com/manifest.json")
	_, err := DecodeManifest(strings.NewReader(`{
		"schema_version": 1,
		"version": "1.0.0",
		"assets": {
			"linux-x64": {
				"url": "https://example.com/update.tar.gz",
				"sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
				"size": 10,
				"format": "tar.gz",
				"launcher": {"path": "launcher/culpeostudio"},
				"backend": {"path": "../../outside"},
				"frontend": {"path": "frontend/app"}
			}
		}
	}`), base)
	if err == nil {
		t.Fatal("DecodeManifest() unexpectedly accepted a traversal path")
	}
}

func TestPlatformKey(t *testing.T) {
	t.Parallel()
	tests := map[string]string{
		"linux/amd64":   "linux-x64",
		"windows/arm64": "windows-arm64",
		"darwin/arm64":  "macos-arm64",
	}
	for input, want := range tests {
		parts := strings.Split(input, "/")
		got, err := PlatformKey(parts[0], parts[1])
		if err != nil {
			t.Fatalf("PlatformKey(%q) error = %v", input, err)
		}
		if got != want {
			t.Fatalf("PlatformKey(%q) = %q, want %q", input, got, want)
		}
	}
}
