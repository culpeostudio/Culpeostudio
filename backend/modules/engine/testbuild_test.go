package engine

import (
	"archive/tar"
	"bytes"
	"compress/gzip"
	"crypto/sha256"
	"encoding/hex"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"runtime"
	"testing"

	"github.com/culpeohq/backend/internal/engineruntime"
)

// newTestLlamaBuild serves a minimal but structurally real llama-server archive
// from a local host and returns the build that points at it. Tests that drive
// the installer need something it can actually download, verify and unpack; the
// probe itself is what the injected CommandRunner stands in for.
func newTestLlamaBuild(t *testing.T, variant engineruntime.BuildVariant) engineruntime.Build {
	t.Helper()
	archive := testLlamaArchive(t)
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if filepath.Base(r.URL.Path) != "llama-test-bin.tar.gz" {
			w.WriteHeader(http.StatusNotFound)
			return
		}
		_, _ = w.Write(archive)
	}))
	t.Cleanup(server.Close)

	sum := sha256.Sum256(archive)
	return engineruntime.Build{
		Variant: variant,
		Tag:     engineruntime.LlamaBuildTag,
		OS:      runtime.GOOS,
		Arch:    runtime.GOARCH,
		BaseURL: server.URL,
		Archive: engineruntime.Asset{
			Name:   "llama-test-bin.tar.gz",
			SHA256: hex.EncodeToString(sum[:]),
			Bytes:  int64(len(archive)),
		},
	}
}

func testLlamaArchive(t *testing.T) []byte {
	t.Helper()
	var buffer bytes.Buffer
	compressor := gzip.NewWriter(&buffer)
	writer := tar.NewWriter(compressor)
	body := []byte("#!/bin/sh\necho version: 10327\n")
	if err := writer.WriteHeader(&tar.Header{
		Typeflag: tar.TypeReg,
		Name:     "llama-test/" + engineruntime.ServerBinaryName(),
		Mode:     0o755,
		Size:     int64(len(body)),
	}); err != nil {
		t.Fatal(err)
	}
	if _, err := writer.Write(body); err != nil {
		t.Fatal(err)
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	if err := compressor.Close(); err != nil {
		t.Fatal(err)
	}
	return buffer.Bytes()
}
