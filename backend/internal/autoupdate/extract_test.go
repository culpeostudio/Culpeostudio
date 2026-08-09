package autoupdate

import (
	"archive/tar"
	"archive/zip"
	"compress/gzip"
	"os"
	"path/filepath"
	"testing"
)

func TestExtractArchiveRejectsZipTraversal(t *testing.T) {
	t.Parallel()
	archivePath := filepath.Join(t.TempDir(), "bad.zip")
	file, err := os.Create(archivePath)
	if err != nil {
		t.Fatal(err)
	}
	writer := zip.NewWriter(file)
	entry, err := writer.Create("../../outside")
	if err != nil {
		t.Fatal(err)
	}
	_, _ = entry.Write([]byte("no"))
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	if err := file.Close(); err != nil {
		t.Fatal(err)
	}
	destination := t.TempDir()
	if err := ExtractArchive(archivePath, "zip", destination); err == nil {
		t.Fatal("ExtractArchive() unexpectedly accepted path traversal")
	}
}

func TestExtractArchiveTarGzip(t *testing.T) {
	t.Parallel()
	archivePath := filepath.Join(t.TempDir(), "update.tar.gz")
	file, err := os.Create(archivePath)
	if err != nil {
		t.Fatal(err)
	}
	gzipWriter := gzip.NewWriter(file)
	tarWriter := tar.NewWriter(gzipWriter)
	payload := []byte("#!/bin/sh\nexit 0\n")
	if err := tarWriter.WriteHeader(&tar.Header{
		Name: "backend/server",
		Mode: 0o755,
		Size: int64(len(payload)),
	}); err != nil {
		t.Fatal(err)
	}
	if _, err := tarWriter.Write(payload); err != nil {
		t.Fatal(err)
	}
	if err := tarWriter.Close(); err != nil {
		t.Fatal(err)
	}
	if err := gzipWriter.Close(); err != nil {
		t.Fatal(err)
	}
	if err := file.Close(); err != nil {
		t.Fatal(err)
	}

	destination := t.TempDir()
	if err := ExtractArchive(archivePath, "tar.gz", destination); err != nil {
		t.Fatalf("ExtractArchive() error = %v", err)
	}
	info, err := os.Stat(filepath.Join(destination, "backend", "server"))
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm()&0o100 == 0 {
		t.Fatalf("executable bit was not preserved: %s", info.Mode())
	}
}

func TestExtractArchiveRejectsEscapingSymlink(t *testing.T) {
	t.Parallel()
	archivePath := filepath.Join(t.TempDir(), "bad.tar.gz")
	file, err := os.Create(archivePath)
	if err != nil {
		t.Fatal(err)
	}
	gzipWriter := gzip.NewWriter(file)
	tarWriter := tar.NewWriter(gzipWriter)
	if err := tarWriter.WriteHeader(&tar.Header{
		Name:     "frontend/link",
		Mode:     0o777,
		Typeflag: tar.TypeSymlink,
		Linkname: "../../outside",
	}); err != nil {
		t.Fatal(err)
	}
	_ = tarWriter.Close()
	_ = gzipWriter.Close()
	_ = file.Close()
	if err := ExtractArchive(archivePath, "tar.gz", t.TempDir()); err == nil {
		t.Fatal("ExtractArchive() unexpectedly accepted an escaping symlink")
	}
}
