package engineruntime

import (
	"archive/tar"
	"bytes"
	"compress/gzip"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestCatalogueIsInternallyConsistent(t *testing.T) {
	for _, platform := range []struct{ goos, goarch string }{
		{"linux", "amd64"}, {"linux", "arm64"},
		{"windows", "amd64"}, {"windows", "arm64"},
		{"darwin", "arm64"}, {"darwin", "amd64"},
	} {
		variants := AvailableVariants(platform.goos, platform.goarch)
		if len(variants) == 0 {
			t.Fatalf("%s/%s has no published build", platform.goos, platform.goarch)
		}
		// Every platform needs somewhere to land when no accelerator works.
		// Apple Silicon is the exception: its build always carries Metal.
		fallback := BuildCPU
		if platform.goos == "darwin" && platform.goarch == "arm64" {
			fallback = BuildMetal
		}
		if _, err := BuildFor(platform.goos, platform.goarch, fallback); err != nil {
			t.Fatalf("%s/%s has no %s fallback: %v", platform.goos, platform.goarch, fallback, err)
		}
		for _, variant := range variants {
			build, err := BuildFor(platform.goos, platform.goarch, variant)
			if err != nil {
				t.Fatalf("%s/%s %s: %v", platform.goos, platform.goarch, variant, err)
			}
			// Validate covers the digest format and archive extension; without a
			// correct digest the download is just an arbitrary binary.
			if err := build.Validate(); err != nil {
				t.Fatalf("%s/%s %s: %v", platform.goos, platform.goarch, variant, err)
			}
			if !strings.HasPrefix(build.AssetURL(build.Archive), "https://github.com/ggml-org/llama.cpp/releases/download/"+LlamaBuildTag+"/") {
				t.Fatalf("%s/%s %s asset URL = %q", platform.goos, platform.goarch, variant, build.AssetURL(build.Archive))
			}
		}
	}

	// The Windows CUDA build does not bundle the CUDA runtime DLLs and will not
	// start without them on a machine with no CUDA toolkit installed.
	cuda, err := BuildFor("windows", "amd64", BuildCUDA)
	if err != nil {
		t.Fatal(err)
	}
	if len(cuda.Extras) != 1 || !strings.HasPrefix(cuda.Extras[0].Name, "cudart-") {
		t.Fatalf("windows CUDA build extras = %#v", cuda.Extras)
	}
}

func TestVariantForVendorMapsHardwareToBuilds(t *testing.T) {
	for _, testCase := range []struct {
		goos, goarch, vendor, backend string
		want                          BuildVariant
	}{
		{"windows", "amd64", "nvidia", "cuda", BuildCUDA},
		{"windows", "amd64", "amd", "directml", BuildVulkan},
		{"windows", "amd64", "intel", "directml", BuildSYCL},
		{"linux", "amd64", "amd", "rocm", BuildVulkan},
		{"linux", "amd64", "intel", "xpu", BuildSYCL},
		// Upstream publishes no Linux CUDA archive, so NVIDIA there resolves to
		// the Vulkan build, which drives NVIDIA hardware fine.
		{"linux", "amd64", "nvidia", "cuda", BuildVulkan},
		// The ARM Linux release has no SYCL archive either.
		{"linux", "arm64", "intel", "xpu", BuildVulkan},
		{"darwin", "arm64", "apple", "metal", BuildMetal},
		{"linux", "amd64", "", "", BuildCPU},
		{"linux", "amd64", "matrox", "", BuildCPU},
		// An unrecognised vendor still resolves through the reported backend.
		{"linux", "amd64", "some-oem", "vulkan", BuildVulkan},
	} {
		got := VariantForVendor(testCase.goos, testCase.goarch, testCase.vendor, testCase.backend)
		if got != testCase.want {
			t.Fatalf("%s/%s vendor=%q backend=%q resolved to %q, want %q",
				testCase.goos, testCase.goarch, testCase.vendor, testCase.backend, got, testCase.want)
		}
	}
}

func TestBuildDigestSeparatesDifferentSources(t *testing.T) {
	build, err := BuildFor(runtime.GOOS, runtime.GOARCH, AvailableVariants(runtime.GOOS, runtime.GOARCH)[0])
	if err != nil {
		t.Fatal(err)
	}
	original, err := build.Digest()
	if err != nil {
		t.Fatal(err)
	}
	moved := build
	moved.BaseURL = "https://mirror.example/releases/"
	movedDigest, err := moved.Digest()
	if err != nil {
		t.Fatal(err)
	}
	if movedDigest == original {
		t.Fatal("a build served from a different host shares an install directory with the pinned one")
	}

	retagged := build
	retagged.Archive.SHA256 = strings.Repeat("b", 64)
	retaggedDigest, err := retagged.Digest()
	if err != nil {
		t.Fatal(err)
	}
	if retaggedDigest == original {
		t.Fatal("changing the expected checksum did not change the install directory")
	}
}

func TestBuildRejectsUnsafeDescriptors(t *testing.T) {
	base, err := BuildFor(runtime.GOOS, runtime.GOARCH, AvailableVariants(runtime.GOOS, runtime.GOARCH)[0])
	if err != nil {
		t.Fatal(err)
	}
	for name, mutate := range map[string]func(*Build){
		"path traversal in asset name": func(b *Build) { b.Archive.Name = "../escape.tar.gz" },
		"absolute asset name":          func(b *Build) { b.Archive.Name = "/etc/passwd.tar.gz" },
		"missing digest":               func(b *Build) { b.Archive.SHA256 = "" },
		"short digest":                 func(b *Build) { b.Archive.SHA256 = "abc" },
		"uppercase digest":             func(b *Build) { b.Archive.SHA256 = strings.ToUpper(b.Archive.SHA256) },
		"unknown archive format":       func(b *Build) { b.Archive.Name = "llama.tar.xz" },
		"no expected size":             func(b *Build) { b.Archive.Bytes = 0 },
		"traversal in tag":             func(b *Build) { b.Tag = "../../etc" },
		"unknown variant":              func(b *Build) { b.Variant = BuildVariant("opencl") },
		"non-http base URL":            func(b *Build) { b.BaseURL = "file:///etc" },
	} {
		candidate := base
		mutate(&candidate)
		if err := candidate.Validate(); err == nil {
			t.Fatalf("%s was accepted", name)
		}
		if _, err := candidate.InstallPath(t.TempDir()); err == nil {
			t.Fatalf("%s produced an install path", name)
		}
	}
}

func TestExtractArchiveRefusesEscapingEntries(t *testing.T) {
	for name, entryName := range map[string]string{
		"parent traversal": "../escaped.txt",
		"deep traversal":   "llama/../../escaped.txt",
		"absolute path":    "/tmp/escaped.txt",
	} {
		archive := filepath.Join(t.TempDir(), "evil.tar.gz")
		writeTarGz(t, archive, entryName, "payload", "")
		destination := t.TempDir()
		if err := extractArchive(archive, destination); err == nil {
			t.Fatalf("%s was extracted", name)
		}
		if _, err := os.Stat(filepath.Join(filepath.Dir(destination), "escaped.txt")); !os.IsNotExist(err) {
			t.Fatalf("%s wrote outside the install directory", name)
		}
	}
}

func TestExtractArchiveRefusesEscapingSymlinks(t *testing.T) {
	for name, target := range map[string]string{
		"relative escape": "../../../etc/passwd",
		"absolute escape": "/etc/passwd",
	} {
		archive := filepath.Join(t.TempDir(), "evil.tar.gz")
		writeTarGz(t, archive, "llama/link", "", target)
		if err := extractArchive(archive, t.TempDir()); err == nil {
			t.Fatalf("%s symlink was created", name)
		}
	}
}

func TestExtractArchiveKeepsRelativeSymlinksInsideTheTree(t *testing.T) {
	archive := filepath.Join(t.TempDir(), "good.tar.gz")
	writeTarGz(t, archive, "llama/libllama.so.0", "", "libllama.so.0.0.10327")
	destination := t.TempDir()
	if err := extractArchive(archive, destination); err != nil {
		t.Fatal(err)
	}
	// The real llama.cpp tarballs depend on these for their sonames.
	target, err := os.Readlink(filepath.Join(destination, "llama", "libllama.so.0"))
	if err != nil || target != "libllama.so.0.0.10327" {
		t.Fatalf("symlink = %q, %v", target, err)
	}
}

func writeTarGz(t *testing.T, path, name, body, linkname string) {
	t.Helper()
	var buffer bytes.Buffer
	compressor := gzip.NewWriter(&buffer)
	writer := tar.NewWriter(compressor)
	header := &tar.Header{Typeflag: tar.TypeReg, Name: name, Mode: 0o644, Size: int64(len(body))}
	if linkname != "" {
		header = &tar.Header{Typeflag: tar.TypeSymlink, Name: name, Linkname: linkname, Mode: 0o777}
	}
	if err := writer.WriteHeader(header); err != nil {
		t.Fatal(err)
	}
	if linkname == "" {
		if _, err := writer.Write([]byte(body)); err != nil {
			t.Fatal(err)
		}
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	if err := compressor.Close(); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, buffer.Bytes(), 0o600); err != nil {
		t.Fatal(err)
	}
}
