package engineruntime

import (
	"archive/tar"
	"archive/zip"
	"bytes"
	"compress/gzip"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"reflect"
	"runtime"
	"strings"
	"sync"
	"testing"
	"time"
)

// probeRunner stands in for actually executing the unpacked binary. It records
// what it was asked to run so the test can assert the probe hit the real path.
type probeRunner struct {
	mu     sync.Mutex
	calls  [][]string
	fail   error
	output string
}

func (r *probeRunner) Run(ctx context.Context, argv []string, _ []string, output io.Writer) error {
	r.mu.Lock()
	r.calls = append(r.calls, append([]string(nil), argv...))
	r.mu.Unlock()
	text := r.output
	if text == "" {
		text = "version: 10327 (69bf64379)\n"
	}
	_, _ = io.WriteString(output, text)
	if r.fail != nil {
		return r.fail
	}
	return ctx.Err()
}

func (r *probeRunner) Calls() [][]string {
	r.mu.Lock()
	defer r.mu.Unlock()
	result := make([][]string, len(r.calls))
	for index := range r.calls {
		result[index] = append([]string(nil), r.calls[index]...)
	}
	return result
}

type archiveEntry struct {
	name     string
	body     string
	mode     int64
	linkname string
}

func tarGzArchive(t *testing.T, entries []archiveEntry) []byte {
	t.Helper()
	var buffer bytes.Buffer
	compressor := gzip.NewWriter(&buffer)
	writer := tar.NewWriter(compressor)
	for _, entry := range entries {
		if entry.linkname != "" {
			if err := writer.WriteHeader(&tar.Header{
				Typeflag: tar.TypeSymlink, Name: entry.name, Linkname: entry.linkname, Mode: 0o777,
			}); err != nil {
				t.Fatal(err)
			}
			continue
		}
		if strings.HasSuffix(entry.name, "/") {
			if err := writer.WriteHeader(&tar.Header{
				Typeflag: tar.TypeDir, Name: entry.name, Mode: 0o755,
			}); err != nil {
				t.Fatal(err)
			}
			continue
		}
		mode := entry.mode
		if mode == 0 {
			mode = 0o644
		}
		if err := writer.WriteHeader(&tar.Header{
			Typeflag: tar.TypeReg, Name: entry.name, Mode: mode, Size: int64(len(entry.body)),
		}); err != nil {
			t.Fatal(err)
		}
		if _, err := writer.Write([]byte(entry.body)); err != nil {
			t.Fatal(err)
		}
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	if err := compressor.Close(); err != nil {
		t.Fatal(err)
	}
	return buffer.Bytes()
}

func zipArchive(t *testing.T, entries []archiveEntry) []byte {
	t.Helper()
	var buffer bytes.Buffer
	writer := zip.NewWriter(&buffer)
	for _, entry := range entries {
		mode := os.FileMode(entry.mode)
		if mode == 0 {
			mode = 0o644
		}
		header := &zip.FileHeader{Name: entry.name, Method: zip.Deflate}
		header.SetMode(mode)
		file, err := writer.CreateHeader(header)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := file.Write([]byte(entry.body)); err != nil {
			t.Fatal(err)
		}
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	return buffer.Bytes()
}

func digestOf(payload []byte) string {
	sum := sha256.Sum256(payload)
	return hex.EncodeToString(sum[:])
}

// serveArchives starts a release host for the given assets, keyed by file name.
func serveArchives(t *testing.T, payloads map[string][]byte) *httptest.Server {
	t.Helper()
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		name := filepath.Base(r.URL.Path)
		payload, known := payloads[name]
		if !known {
			w.WriteHeader(http.StatusNotFound)
			return
		}
		w.Header().Set("Content-Type", "application/octet-stream")
		_, _ = w.Write(payload)
	}))
	t.Cleanup(server.Close)
	return server
}

// testBuild wires a build to the local release host. The server binary name
// follows the host platform so the installer's own lookup applies.
func testBuild(t *testing.T, server *httptest.Server, archive []byte, extras map[string][]byte) Build {
	t.Helper()
	build := Build{
		Variant: BuildCPU,
		Tag:     "b10327",
		OS:      runtime.GOOS,
		Arch:    runtime.GOARCH,
		BaseURL: server.URL,
		Archive: Asset{Name: "llama-b10327-bin-test.tar.gz", SHA256: digestOf(archive), Bytes: int64(len(archive))},
	}
	for name, payload := range extras {
		build.Extras = append(build.Extras, Asset{Name: name, SHA256: digestOf(payload), Bytes: int64(len(payload))})
	}
	return build
}

func serverArchive(t *testing.T) []byte {
	t.Helper()
	return tarGzArchive(t, []archiveEntry{
		{name: "llama-b10327/"},
		{name: "llama-b10327/libllama.so.0.0.10327", body: "shared library"},
		// The real tarballs use relative symlinks for their sonames, and the
		// binary will not resolve its libraries without them.
		{name: "llama-b10327/libllama.so.0", linkname: "libllama.so.0.0.10327"},
		{name: "llama-b10327/" + ServerBinaryName(), body: "#!/bin/sh\necho version: 10327\n", mode: 0o755},
	})
}

func TestInstallerDownloadsVerifiesAndActivatesBuild(t *testing.T) {
	archive := serverArchive(t)
	server := serveArchives(t, map[string][]byte{"llama-b10327-bin-test.tar.gz": archive})
	build := testBuild(t, server, archive, nil)

	runner := &probeRunner{}
	installer, err := NewInstaller(t.TempDir(), server.Client(), runner)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)

	job, err := installer.Start(build)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	snapshot, err := job.Wait(ctx)
	if err != nil {
		t.Fatalf("install failed: %v (log: %s)", err, snapshot.Log)
	}
	if snapshot.Status != InstallReady || snapshot.Progress != 1 {
		t.Fatalf("snapshot = %#v", snapshot)
	}

	serverPath, err := installer.ServerPath(build)
	if err != nil {
		t.Fatal(err)
	}
	if filepath.Base(serverPath) != ServerBinaryName() {
		t.Fatalf("server path = %q", serverPath)
	}
	info, err := os.Stat(serverPath)
	if err != nil {
		t.Fatal(err)
	}
	if runtime.GOOS != "windows" && info.Mode().Perm()&0o111 == 0 {
		t.Fatalf("installed binary is not executable: %v", info.Mode())
	}

	// The probe must have run the binary that was actually installed, and then
	// asked it which cache types it implements.
	calls := runner.Calls()
	if len(calls) != 2 || calls[0][1] != "--version" || calls[1][1] != "--help" {
		t.Fatalf("probe calls = %#v", calls)
	}
	for _, call := range calls {
		if !strings.HasSuffix(call[0], ServerBinaryName()) {
			t.Fatalf("probe ran %q", call[0])
		}
	}

	// The relative symlink has to survive extraction.
	linkTarget, err := os.Readlink(filepath.Join(filepath.Dir(serverPath), "libllama.so.0"))
	if err != nil || linkTarget != "libllama.so.0.0.10327" {
		t.Fatalf("symlink = %q, %v", linkTarget, err)
	}

	// The downloaded archives are not left behind in the activated install.
	if _, err := os.Stat(filepath.Join(filepath.Dir(filepath.Dir(serverPath)), ".downloads")); !os.IsNotExist(err) {
		t.Fatal("download scratch directory was activated along with the build")
	}

	capability := installer.Capability(build, DefaultCapability(build.Variant))
	if !capability.Installed || !capability.Healthy || capability.ServerPath != serverPath {
		t.Fatalf("capability = %#v", capability)
	}
	if capability.BuildVersion == "" {
		t.Fatal("capability did not record what the binary reported for --version")
	}
}

// helpOutput mirrors the shape of real `llama-server --help` output, including
// the draft-model flag that prints a second allowed-values list.
const helpOutput = `----- common params -----

-c,    --ctx-size N                     size of the prompt context (default: 0)
-ctk,  --cache-type-k TYPE              KV cache data type for K
                                        allowed values: f32, f16, bf16, q8_0, q4_0, q3_k, q2_k
                                        (default: f16)
                                        (env: LLAMA_ARG_CACHE_TYPE_K)
-ctv,  --cache-type-v TYPE              KV cache data type for V
--spec-draft-type-k, -ctkd, --cache-type-k-draft TYPE
                                        KV cache data type for K for the draft model
                                        allowed values: f32, f16
`

func TestParseSupportedCacheTypesReadsTheBinarysOwnList(t *testing.T) {
	got := ParseSupportedCacheTypes(helpOutput)
	want := []string{"f32", "f16", "bf16", "q8_0", "q4_0", "q3_k", "q2_k"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("cache types = %#v, want %#v", got, want)
	}
	// The draft flag has its own, shorter list; picking it up would make the
	// planner think the build supports far less than it does.
	if len(got) == 2 {
		t.Fatal("parser matched the draft-model flag instead of the main one")
	}
	for _, unusable := range []string{"", "no flags here", "-ctk, --cache-type-k TYPE\n  (default: f16)\n"} {
		if types := ParseSupportedCacheTypes(unusable); types != nil {
			t.Fatalf("unparsable help produced %#v; the caller must fall back instead", types)
		}
	}
}

func TestInstallerAdoptsTheCacheTypesTheBuildReports(t *testing.T) {
	archive := serverArchive(t)
	server := serveArchives(t, map[string][]byte{"llama-b10327-bin-test.tar.gz": archive})
	build := testBuild(t, server, archive, nil)

	installer, err := NewInstaller(t.TempDir(), server.Client(), &probeRunner{output: helpOutput})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)

	job, err := installer.Start(build)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if _, err := job.Wait(ctx); err != nil {
		t.Fatal(err)
	}
	capability := installer.Capability(build, DefaultCapability(build.Variant))
	// A build advertising sub-4-bit caches becomes usable without a code change.
	if !containsExact(capability.KVCaches, "q2_k") || !containsExact(capability.KVCaches, "q3_k") {
		t.Fatalf("capability cache types = %#v", capability.KVCaches)
	}
}

func TestInstallerKeepsUpstreamCacheTypesWhenTheBuildStaysSilent(t *testing.T) {
	archive := serverArchive(t)
	server := serveArchives(t, map[string][]byte{"llama-b10327-bin-test.tar.gz": archive})
	build := testBuild(t, server, archive, nil)

	// The default probeRunner prints only a version line, so the help parse fails.
	installer, err := NewInstaller(t.TempDir(), server.Client(), &probeRunner{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)

	job, err := installer.Start(build)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if _, err := job.Wait(ctx); err != nil {
		t.Fatal(err)
	}
	capability := installer.Capability(build, DefaultCapability(build.Variant))
	if !reflect.DeepEqual(capability.KVCaches, SupportedCacheTypes()) {
		t.Fatalf("cache types = %#v, want the upstream fallback", capability.KVCaches)
	}
}

func TestInstallerRejectsChecksumMismatch(t *testing.T) {
	archive := serverArchive(t)
	server := serveArchives(t, map[string][]byte{"llama-b10327-bin-test.tar.gz": archive})
	build := testBuild(t, server, archive, nil)
	// Claim a digest the served bytes do not have.
	build.Archive.SHA256 = strings.Repeat("a", 64)

	installer, err := NewInstaller(t.TempDir(), server.Client(), &probeRunner{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)

	job, err := installer.Start(build)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	snapshot, err := job.Wait(ctx)
	if err == nil {
		t.Fatal("an archive that failed its checksum was installed")
	}
	if snapshot.ErrorCode != "checksum_mismatch" {
		t.Fatalf("error code = %q, want checksum_mismatch (%s)", snapshot.ErrorCode, snapshot.ErrorSummary)
	}
	if _, err := installer.ServerPath(build); err == nil {
		t.Fatal("a build that failed verification reports an installed server")
	}
	if _, err := os.Stat(snapshot.InstallPath); !os.IsNotExist(err) {
		t.Fatal("a failed install left its directory activated")
	}
}

func TestInstallerRejectsTruncatedDownload(t *testing.T) {
	archive := serverArchive(t)
	server := serveArchives(t, map[string][]byte{"llama-b10327-bin-test.tar.gz": archive[:len(archive)/2]})
	build := testBuild(t, server, archive, nil)

	installer, err := NewInstaller(t.TempDir(), server.Client(), &probeRunner{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)

	job, err := installer.Start(build)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if _, err := job.Wait(ctx); err == nil {
		t.Fatal("a short download was accepted")
	}
}

func TestInstallerUnpacksExtrasBesideTheBinary(t *testing.T) {
	archive := serverArchive(t)
	// Stands in for the CUDA runtime archive, which the Windows CUDA build needs
	// alongside it to start at all.
	extra := zipArchive(t, []archiveEntry{{name: "llama-b10327/cudart64_12.dll", body: "runtime library"}})
	server := serveArchives(t, map[string][]byte{
		"llama-b10327-bin-test.tar.gz": archive,
		"cudart-test.zip":              extra,
	})
	build := testBuild(t, server, archive, map[string][]byte{"cudart-test.zip": extra})

	installer, err := NewInstaller(t.TempDir(), server.Client(), &probeRunner{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)

	job, err := installer.Start(build)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if _, err := job.Wait(ctx); err != nil {
		t.Fatal(err)
	}
	serverPath, err := installer.ServerPath(build)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(filepath.Dir(serverPath), "cudart64_12.dll")); err != nil {
		t.Fatalf("extra archive was not unpacked beside the binary: %v", err)
	}
}

func TestInstallerFailsWhenTheBinaryDoesNotRun(t *testing.T) {
	archive := serverArchive(t)
	server := serveArchives(t, map[string][]byte{"llama-b10327-bin-test.tar.gz": archive})
	build := testBuild(t, server, archive, nil)

	installer, err := NewInstaller(t.TempDir(), server.Client(), &probeRunner{fail: errors.New("exit status 127")})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)

	job, err := installer.Start(build)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	snapshot, err := job.Wait(ctx)
	if err == nil {
		t.Fatal("a build whose binary will not start was activated")
	}
	if snapshot.ErrorCode != "runtime_probe_failed" {
		t.Fatalf("error code = %q, want runtime_probe_failed", snapshot.ErrorCode)
	}
}

func TestInstallerFailsWhenArchiveHasNoServerBinary(t *testing.T) {
	archive := tarGzArchive(t, []archiveEntry{{name: "llama-b10327/llama-cli", body: "wrong tool", mode: 0o755}})
	server := serveArchives(t, map[string][]byte{"llama-b10327-bin-test.tar.gz": archive})
	build := testBuild(t, server, archive, nil)

	installer, err := NewInstaller(t.TempDir(), server.Client(), &probeRunner{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)

	job, err := installer.Start(build)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if _, err := job.Wait(ctx); err == nil {
		t.Fatal("an archive without llama-server was accepted")
	}
}

func TestInstallerDeduplicatesConcurrentInstalls(t *testing.T) {
	archive := serverArchive(t)
	server := serveArchives(t, map[string][]byte{"llama-b10327-bin-test.tar.gz": archive})
	build := testBuild(t, server, archive, nil)

	installer, err := NewInstaller(t.TempDir(), server.Client(), &probeRunner{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)

	first, err := installer.Start(build)
	if err != nil {
		t.Fatal(err)
	}
	second, err := installer.Start(build)
	if err != nil {
		t.Fatal(err)
	}
	if first != second {
		t.Fatal("the same build started two install jobs")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if _, err := first.Wait(ctx); err != nil {
		t.Fatal(err)
	}
	// A second Start after completion recognises the existing install instead of
	// downloading again.
	third, err := installer.Start(build)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := third.Wait(ctx); err != nil {
		t.Fatal(err)
	}
	if len(installer.Jobs()) != 1 {
		t.Fatalf("jobs = %d, want the deduplicated one", len(installer.Jobs()))
	}
}

func TestCapabilityReportsMissingWhenBinaryDisappears(t *testing.T) {
	archive := serverArchive(t)
	server := serveArchives(t, map[string][]byte{"llama-b10327-bin-test.tar.gz": archive})
	build := testBuild(t, server, archive, nil)

	installer, err := NewInstaller(t.TempDir(), server.Client(), &probeRunner{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)

	job, err := installer.Start(build)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if _, err := job.Wait(ctx); err != nil {
		t.Fatal(err)
	}
	serverPath, err := installer.ServerPath(build)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.Remove(serverPath); err != nil {
		t.Fatal(err)
	}
	// A manifest is only worth trusting while the binary it names is present;
	// otherwise the next start would fail at spawn time instead of reinstalling.
	if capability := installer.Capability(build, DefaultCapability(build.Variant)); capability.Installed {
		t.Fatal("capability still reports installed after the binary was deleted")
	}
}

func TestSweepStaleArtifactsRemovesLegacyAndPartialInstalls(t *testing.T) {
	root := t.TempDir()
	// A Python virtual environment from before the switch to prebuilt binaries.
	legacy := filepath.Join(root, "llama_cpp", "0.3.33", "abcdef")
	if err := os.MkdirAll(legacy, 0o755); err != nil {
		t.Fatal(err)
	}
	staging := filepath.Join(root, "vulkan", "b10327", "abc.staging-runtime-1")
	previous := filepath.Join(root, "vulkan", "b10327", "abc.previous")
	keep := filepath.Join(root, "vulkan", "b10327", "abcdef0123456789")
	for _, dir := range []string{staging, previous, keep} {
		if err := os.MkdirAll(dir, 0o755); err != nil {
			t.Fatal(err)
		}
	}

	installer, err := NewInstaller(root, nil, &probeRunner{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(installer.Close)

	for _, dir := range []string{filepath.Join(root, "llama_cpp"), staging, previous} {
		if _, err := os.Stat(dir); !os.IsNotExist(err) {
			t.Fatalf("%s survived the sweep", dir)
		}
	}
	if _, err := os.Stat(keep); err != nil {
		t.Fatalf("a completed install was swept: %v", err)
	}
}
