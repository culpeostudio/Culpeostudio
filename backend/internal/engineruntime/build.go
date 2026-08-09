package engineruntime

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
)

// BuildVariant names the compute backend a prebuilt llama-server was compiled
// against. The engine picks one from the machine's GPU vendor rather than
// building anything locally.
type BuildVariant string

const (
	// BuildCUDA is the NVIDIA build.
	BuildCUDA BuildVariant = "cuda"
	// BuildVulkan covers AMD and anything else with a working Vulkan driver.
	// It is also the NVIDIA fallback on platforms with no published CUDA build.
	BuildVulkan BuildVariant = "vulkan"
	// BuildSYCL is the Intel Arc build.
	BuildSYCL BuildVariant = "sycl"
	// BuildMetal is the Apple Silicon build.
	BuildMetal BuildVariant = "metal"
	// BuildCPU is the fallback for machines with no usable accelerator.
	BuildCPU BuildVariant = "cpu"
)

// KnownBuildVariants lists every variant the catalogue may name. The installer
// uses it to recognise its own directories when sweeping stale ones.
func KnownBuildVariants() []BuildVariant {
	return []BuildVariant{BuildCUDA, BuildVulkan, BuildSYCL, BuildMetal, BuildCPU}
}

// LlamaBuildTag pins the upstream llama.cpp release these binaries come from.
// Bumping it means refreshing every checksum in the catalogue below; the
// digests are what make the download trustworthy.
const LlamaBuildTag = "b10327"

const llamaReleaseBaseURL = "https://github.com/ggml-org/llama.cpp/releases/download/"

var (
	safePathPart     = regexp.MustCompile(`[^a-zA-Z0-9._-]+`)
	sha256HexPattern = regexp.MustCompile(`^[a-f0-9]{64}$`)
	assetNamePattern = regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9._-]*$`)
	buildTagPattern  = regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9._-]*$`)
)

// Asset is one release archive, pinned by content digest.
type Asset struct {
	Name   string `json:"name"`
	SHA256 string `json:"sha256"`
	Bytes  int64  `json:"bytes"`
}

func (a Asset) validate() error {
	if !assetNamePattern.MatchString(a.Name) {
		return fmt.Errorf("asset name %q is not a safe file name", a.Name)
	}
	if !sha256HexPattern.MatchString(a.SHA256) {
		return fmt.Errorf("asset %s has no lowercase hex SHA-256 digest", a.Name)
	}
	if a.Bytes <= 0 {
		return fmt.Errorf("asset %s has no expected size", a.Name)
	}
	if !strings.HasSuffix(a.Name, ".zip") && !strings.HasSuffix(a.Name, ".tar.gz") {
		return fmt.Errorf("asset %s is neither a .zip nor a .tar.gz archive", a.Name)
	}
	return nil
}

// Build is the full description of one installable llama-server: the archive to
// fetch, anything that has to be unpacked next to it, and the platform it is
// for.
type Build struct {
	Variant BuildVariant `json:"variant"`
	Tag     string       `json:"tag"`
	OS      string       `json:"os"`
	Arch    string       `json:"arch"`
	Archive Asset        `json:"archive"`

	// Extras are unpacked into the same directory as Archive. The Windows CUDA
	// build ships without the CUDA runtime DLLs and will not start unless the
	// matching cudart archive lands beside it.
	Extras []Asset `json:"extras,omitempty"`

	// BaseURL overrides where assets are fetched from. Empty means the upstream
	// llama.cpp release host. It is part of the digest, so a build served from
	// somewhere else never shares an install directory with the real one.
	BaseURL string `json:"base_url,omitempty"`
}

// AssetURL is where one of this build's assets is fetched from. Assets live
// under the build's own tag, so the URL cannot drift from the pinned release.
func (b Build) AssetURL(asset Asset) string {
	base := b.BaseURL
	if base == "" {
		base = llamaReleaseBaseURL
	}
	if !strings.HasSuffix(base, "/") {
		base += "/"
	}
	return base + b.Tag + "/" + asset.Name
}

func (b Build) Validate() error {
	known := false
	for _, variant := range KnownBuildVariants() {
		if b.Variant == variant {
			known = true
			break
		}
	}
	if !known {
		return fmt.Errorf("unsupported build variant %q", b.Variant)
	}
	if !buildTagPattern.MatchString(b.Tag) {
		return errors.New("build tag must be a non-empty path-safe value")
	}
	if strings.TrimSpace(b.OS) == "" || strings.TrimSpace(b.Arch) == "" {
		return errors.New("build must name its OS and architecture")
	}
	if b.BaseURL != "" {
		parsed, err := url.Parse(b.BaseURL)
		if err != nil || (parsed.Scheme != "https" && parsed.Scheme != "http") || parsed.Host == "" {
			return fmt.Errorf("build base URL %q is not an absolute http(s) URL", b.BaseURL)
		}
	}
	if err := b.Archive.validate(); err != nil {
		return err
	}
	seen := map[string]struct{}{b.Archive.Name: {}}
	for _, extra := range b.Extras {
		if err := extra.validate(); err != nil {
			return err
		}
		if _, duplicate := seen[extra.Name]; duplicate {
			return fmt.Errorf("asset %s is listed twice", extra.Name)
		}
		seen[extra.Name] = struct{}{}
	}
	return nil
}

// Assets returns the archive followed by its extras, in unpack order.
func (b Build) Assets() []Asset {
	result := make([]Asset, 0, 1+len(b.Extras))
	result = append(result, b.Archive)
	result = append(result, b.Extras...)
	return result
}

// Digest identifies the exact set of bytes this build installs. It keys the
// install directory, so changing any asset installs alongside rather than over
// the previous one.
func (b Build) Digest() (string, error) {
	if err := b.Validate(); err != nil {
		return "", err
	}
	encoded, err := json.Marshal(b)
	if err != nil {
		return "", err
	}
	sum := sha256.Sum256(encoded)
	return hex.EncodeToString(sum[:]), nil
}

// InstallPath is where this build's files live once unpacked.
func (b Build) InstallPath(root string) (string, error) {
	digest, err := b.Digest()
	if err != nil {
		return "", err
	}
	variant := safePathPart.ReplaceAllString(string(b.Variant), "_")
	tag := safePathPart.ReplaceAllString(b.Tag, "_")
	return filepath.Join(root, variant, tag, digest[:16]), nil
}

// ServerBinaryName is the executable to look for inside the unpacked archive.
func ServerBinaryName() string {
	if runtime.GOOS == "windows" {
		return "llama-server.exe"
	}
	return "llama-server"
}

// catalogue pins one build per platform and variant. Every digest here was read
// from the GitHub release for LlamaBuildTag; they are the only thing standing
// between the engine and an arbitrary binary off the network.
//
// Note the gaps: upstream publishes no Linux CUDA archive, so NVIDIA on Linux
// resolves to the Vulkan build, which drives NVIDIA hardware fine.
var catalogue = map[string]map[BuildVariant]Build{
	"linux/amd64": {
		BuildCPU: {
			Archive: Asset{Name: "llama-" + LlamaBuildTag + "-bin-ubuntu-x64.tar.gz", SHA256: "b0d1c644a73902f374ab736baff1e9333aaf60f41dab9b21dff66e402b2c668c", Bytes: 16479533},
		},
		BuildVulkan: {
			Archive: Asset{Name: "llama-" + LlamaBuildTag + "-bin-ubuntu-vulkan-x64.tar.gz", SHA256: "852fa511ab8a9b16021d1fff8fe20043cce10b16c4f220e6a5392119538c30ec", Bytes: 32494053},
		},
		BuildSYCL: {
			Archive: Asset{Name: "llama-" + LlamaBuildTag + "-bin-ubuntu-sycl-fp16-x64.tar.gz", SHA256: "d85d722ba1edde7712a05f940829e9c624164623ecbee7cf4bb24df49554ff40", Bytes: 53192528},
		},
	},
	"linux/arm64": {
		BuildCPU: {
			Archive: Asset{Name: "llama-" + LlamaBuildTag + "-bin-ubuntu-arm64.tar.gz", SHA256: "5e2e235dff2e0b5a28ac8da5c58215ab563bcd0ffa06bf9fc888ba68cf9837a4", Bytes: 13362145},
		},
		BuildVulkan: {
			Archive: Asset{Name: "llama-" + LlamaBuildTag + "-bin-ubuntu-vulkan-arm64.tar.gz", SHA256: "8867ddeeb88259c7daf79ca5c44b643e129d17bd073a3b26a4de04ec01d133bc", Bytes: 26543715},
		},
	},
	"windows/amd64": {
		BuildCPU: {
			Archive: Asset{Name: "llama-" + LlamaBuildTag + "-bin-win-cpu-x64.zip", SHA256: "c2781932f9af623c9498a12f002f667d2b668f65e0f19b4401e12b5fe9f860c3", Bytes: 18377141},
		},
		BuildCUDA: {
			Archive: Asset{Name: "llama-" + LlamaBuildTag + "-bin-win-cuda-12.4-x64.zip", SHA256: "8932f819b9ba0d7866911bac5db4a01d9ebefd0071c4293b1ef9ab5c22919637", Bytes: 250467548},
			// Without the CUDA runtime DLLs the server fails to start on any
			// machine that has no CUDA toolkit installed, which is most of them.
			Extras: []Asset{{Name: "cudart-llama-bin-win-cuda-12.4-x64.zip", SHA256: "8c79a9b226de4b3cacfd1f83d24f962d0773be79f1e7b75c6af4ded7e32ae1d6", Bytes: 391443627}},
		},
		BuildVulkan: {
			Archive: Asset{Name: "llama-" + LlamaBuildTag + "-bin-win-vulkan-x64.zip", SHA256: "d6863f1e0d6044fff8c8ff78dc898599d5061c18ddca825aa77de0bc5396b8f4", Bytes: 34126051},
		},
		BuildSYCL: {
			Archive: Asset{Name: "llama-" + LlamaBuildTag + "-bin-win-sycl-x64.zip", SHA256: "b8a90f1008d9443fe5e60fbd9f8fe82ab4607500d78b8f8c6a6c0d089fe9176e", Bytes: 119476655},
		},
	},
	"windows/arm64": {
		BuildCPU: {
			Archive: Asset{Name: "llama-" + LlamaBuildTag + "-bin-win-cpu-arm64.zip", SHA256: "0a7d04263d02dbc6792d7bbc24412ab7a3c4f50d27175ee1b3952211a6a7f16d", Bytes: 12212244},
		},
	},
	"darwin/arm64": {
		// Apple Silicon builds carry Metal, so there is no separate CPU archive.
		BuildMetal: {
			Archive: Asset{Name: "llama-" + LlamaBuildTag + "-bin-macos-arm64.tar.gz", SHA256: "a909ed6e907f9cd671ff271c68f1174320b7c59da746045092cd37e705360f1e", Bytes: 10997689},
		},
	},
	"darwin/amd64": {
		BuildCPU: {
			Archive: Asset{Name: "llama-" + LlamaBuildTag + "-bin-macos-x64.tar.gz", SHA256: "14b3e1df27f8a433230afaa1fbce1b8482e7f4122646cdbd38f91b4d9d292b7e", Bytes: 11268063},
		},
	},
}

func platformKey(goos, goarch string) string { return goos + "/" + goarch }

// BuildFor returns the pinned build for a platform and variant.
func BuildFor(goos, goarch string, variant BuildVariant) (Build, error) {
	platform := platformKey(goos, goarch)
	variants, known := catalogue[platform]
	if !known {
		return Build{}, fmt.Errorf("no llama-server build is published for %s", platform)
	}
	build, available := variants[variant]
	if !available {
		return Build{}, fmt.Errorf("no %s llama-server build is published for %s", variant, platform)
	}
	build.Variant = variant
	build.Tag = LlamaBuildTag
	build.OS = goos
	build.Arch = goarch
	if err := build.Validate(); err != nil {
		return Build{}, err
	}
	return build, nil
}

// AvailableVariants lists the variants published for a platform, most capable
// first, with the CPU fallback last.
func AvailableVariants(goos, goarch string) []BuildVariant {
	variants, known := catalogue[platformKey(goos, goarch)]
	if !known {
		return nil
	}
	result := []BuildVariant{}
	for _, variant := range KnownBuildVariants() {
		if _, available := variants[variant]; available {
			result = append(result, variant)
		}
	}
	return result
}

// VariantForVendor maps a GPU vendor to the build that drives it. Vendor is a
// steadier signal than the reported backend string, which varies by platform
// (Windows reports "directml" for both AMD and Intel, Linux reports "xpu" for
// Intel and either "rocm" or "vulkan" for AMD).
//
// The mapping is: NVIDIA to CUDA, AMD to Vulkan, Intel to SYCL, Apple to Metal.
// A vendor whose build is not published for this platform falls back to Vulkan
// and then to CPU.
func VariantForVendor(goos, goarch, vendor, backend string) BuildVariant {
	available := map[BuildVariant]bool{}
	for _, variant := range AvailableVariants(goos, goarch) {
		available[variant] = true
	}
	preferred := []BuildVariant{}
	switch strings.ToLower(strings.TrimSpace(vendor)) {
	case "nvidia":
		preferred = []BuildVariant{BuildCUDA, BuildVulkan}
	case "amd":
		preferred = []BuildVariant{BuildVulkan}
	case "intel":
		preferred = []BuildVariant{BuildSYCL, BuildVulkan}
	case "apple":
		preferred = []BuildVariant{BuildMetal}
	default:
		// No recognised vendor: fall back to the backend the probe reported.
		switch strings.ToLower(strings.TrimSpace(backend)) {
		case "cuda":
			preferred = []BuildVariant{BuildCUDA, BuildVulkan}
		case "metal":
			preferred = []BuildVariant{BuildMetal}
		case "rocm", "vulkan":
			preferred = []BuildVariant{BuildVulkan}
		case "xpu", "sycl":
			preferred = []BuildVariant{BuildSYCL, BuildVulkan}
		}
	}
	for _, variant := range preferred {
		if available[variant] {
			return variant
		}
	}
	return BuildCPU
}
