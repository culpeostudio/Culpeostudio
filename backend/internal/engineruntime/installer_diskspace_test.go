package engineruntime

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestSweepStaleArtifactsRemovesStagingAndBackup(t *testing.T) {
	root := t.TempDir()
	environments := filepath.Join(root, "llama_cpp", "0_3_9", "abcdef0123456789")
	stale := []string{
		environments + ".staging-job1",
		environments + ".previous",
	}
	keep := []string{
		environments,
		filepath.Join(root, "llama_cpp", "0_3_9", "0123456789abcdef"),
	}
	for _, path := range append(append([]string(nil), stale...), keep...) {
		if err := os.MkdirAll(path, 0o700); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(path, "marker.txt"), []byte("x"), 0o600); err != nil {
			t.Fatal(err)
		}
	}

	installer, err := NewInstaller(root, "/usr/bin/python3", &recordingRunner{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)

	for _, path := range stale {
		if _, err := os.Stat(path); !os.IsNotExist(err) {
			t.Fatalf("stale artifact %s must be removed at startup", path)
		}
	}
	for _, path := range keep {
		if _, err := os.Stat(path); err != nil {
			t.Fatalf("valid environment %s must survive the sweep: %v", path, err)
		}
	}
}

func TestFreeDiskBytesReportsPlausibleValue(t *testing.T) {
	free, err := freeDiskBytes(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	if free <= 0 {
		t.Fatalf("free disk bytes should be positive on a writable temp dir, got %d", free)
	}
}

func TestObservePipLineAdvancesProgress(t *testing.T) {
	job := &InstallJob{status: InstallPackages, log: NewRingBuffer(4096)}
	if progress := job.Snapshot().Progress; progress != 0.15 {
		t.Fatalf("packages phase should start at 0.15, got %v", progress)
	}
	for _, line := range []string{
		"Collecting torch==2.13.0",
		"  Downloading torch-2.13.0-cp312-linux_x86_64.whl (899.1 MB)",
		"Collecting numpy",
		"Collecting safetensors",
	} {
		job.observePipLine(line)
	}
	afterCollect := job.Snapshot().Progress
	if afterCollect <= 0.15 {
		t.Fatalf("collecting packages should advance progress, got %v", afterCollect)
	}
	job.observePipLine("Installing collected packages: torch, numpy, safetensors")
	afterInstall := job.Snapshot().Progress
	if afterInstall <= afterCollect {
		t.Fatalf("install marker should advance progress, got %v <= %v", afterInstall, afterCollect)
	}
	job.observePipLine("Successfully installed torch-2.13.0 numpy-2.0.0 safetensors-0.8.0")
	if final := job.Snapshot().Progress; final != 0.85 {
		t.Fatalf("finished pip should land at 0.85 (0.15+0.7), got %v", final)
	}
}

func TestFriendlyInstallLogDetailKeepsPackageName(t *testing.T) {
	detail := friendlyInstallLogDetail("Downloading torch-2.13.0-cp312-linux_x86_64.whl (899.1 MB)")
	if !strings.Contains(detail, "torch") || !strings.Contains(detail, "899.1 MB") {
		t.Fatalf("download detail should keep package and size, got %q", detail)
	}
}

func TestLineSplittingWriterHandlesChunksAndCR(t *testing.T) {
	seen := []string{}
	buffer := &strings.Builder{}
	writer := &lineSplittingWriter{output: buffer, observe: func(line string) { seen = append(seen, line) }}
	_, _ = writer.Write([]byte("Collecting to"))
	_, _ = writer.Write([]byte("rch\r\nDownloading x (1 MB)\n"))
	if len(seen) < 2 || seen[0] != "Collecting torch" {
		t.Fatalf("line reassembly failed: %v", seen)
	}
	if buffer.String() != "Collecting torch\r\nDownloading x (1 MB)\n" {
		t.Fatalf("tee output altered: %q", buffer.String())
	}
}
