package engineruntime

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"path/filepath"
	"regexp"
	"runtime"
	"sort"
	"strings"
)

const (
	LlamaCPPVersion     = "0.3.33"
	VLLMVersion         = "0.24.0"
	TransformersVersion = "5.13.1"
	SafeTensorsVersion  = "0.8.0"
	AccelerateVersion   = "1.14.0"
)

var safePathPart = regexp.MustCompile(`[^a-zA-Z0-9._-]+`)

type Recipe struct {
	Runtime      RuntimeKind       `json:"runtime"`
	Version      string            `json:"version"`
	Packages     []string          `json:"packages"`
	PipArgs      []string          `json:"pip_args,omitempty"`
	Environment  map[string]string `json:"environment,omitempty"`
	ProbeModules []string          `json:"probe_modules,omitempty"`

	SmokeTestArgs []string `json:"smoke_test_args,omitempty"`
}

func (r Recipe) Validate() error {
	if r.Runtime != RuntimeLlamaCPP && r.Runtime != RuntimeTransformers && r.Runtime != RuntimeVLLM {
		return fmt.Errorf("unsupported runtime %q", r.Runtime)
	}
	if strings.TrimSpace(r.Version) == "" || strings.ContainsAny(r.Version, `/\\\r\n`) {
		return errors.New("recipe version must be a non-empty path-safe value")
	}
	if len(r.Packages) == 0 {
		return errors.New("recipe requires at least one package")
	}
	for _, pkg := range r.Packages {
		if strings.TrimSpace(pkg) != pkg || strings.ContainsAny(pkg, "\r\n\x00") {
			return fmt.Errorf("invalid package argument %q", pkg)
		}
		pinned := exactlyPinned(pkg)
		directHashed := strings.Contains(pkg, " @ ") && strings.Contains(pkg, "#sha256=")
		if !pinned && !directHashed {
			return fmt.Errorf("package %q is not pinned exactly", pkg)
		}
	}
	for _, arg := range append(append([]string(nil), r.PipArgs...), r.SmokeTestArgs...) {
		if strings.ContainsAny(arg, "\r\n\x00") {
			return errors.New("recipe arguments may not contain control characters")
		}
	}
	for key, value := range r.Environment {
		if key == "" || strings.ContainsAny(key, "=\r\n\x00") || strings.ContainsAny(value, "\x00") {
			return fmt.Errorf("invalid recipe environment entry %q", key)
		}
	}
	return nil
}

func exactlyPinned(pkg string) bool {
	if strings.Count(pkg, "==") != 1 || strings.ContainsAny(pkg, ";\r\n") {
		return false
	}
	parts := strings.SplitN(pkg, "==", 2)
	return strings.TrimSpace(parts[0]) != "" && strings.TrimSpace(parts[1]) != "" &&
		!strings.ContainsAny(parts[0], "<>!~") && !strings.ContainsAny(parts[1], "<>!~* ")
}

func (r Recipe) Digest() (string, error) {
	if err := r.Validate(); err != nil {
		return "", err
	}
	b, err := json.Marshal(r)
	if err != nil {
		return "", err
	}
	sum := sha256.Sum256(b)
	return hex.EncodeToString(sum[:]), nil
}

func (r Recipe) EnvironmentPath(root string) (string, error) {
	digest, err := r.Digest()
	if err != nil {
		return "", err
	}
	kind := safePathPart.ReplaceAllString(string(r.Runtime), "_")
	version := safePathPart.ReplaceAllString(r.Version, "_")
	return filepath.Join(root, kind, version, digest[:16]), nil
}

func environmentPython(environment string) string {
	if runtime.GOOS == "windows" {
		return filepath.Join(environment, "Scripts", "python.exe")
	}
	return filepath.Join(environment, "bin", "python")
}

func PythonExecutable(environment string) string { return environmentPython(environment) }

func (r Recipe) PythonPath(root string) (string, error) {
	environment, err := r.EnvironmentPath(root)
	if err != nil {
		return "", err
	}
	return environmentPython(environment), nil
}

func DefaultLlamaCPPRecipe(environment map[string]string) Recipe {
	return Recipe{
		Runtime:      RuntimeLlamaCPP,
		Version:      LlamaCPPVersion,
		Packages:     []string{"llama-cpp-python[server]==" + LlamaCPPVersion},
		Environment:  cloneStringMap(environment),
		ProbeModules: []string{"llama_cpp", "llama_cpp.server"},
	}
}

func DefaultVLLMRecipe() Recipe {
	return Recipe{
		Runtime:      RuntimeVLLM,
		Version:      VLLMVersion,
		Packages:     []string{"vllm==" + VLLMVersion},
		ProbeModules: []string{"vllm"},
	}
}

func DefaultTransformersRecipe(torchPackage string, pipArgs []string) (Recipe, error) {
	r := Recipe{
		Runtime: RuntimeTransformers,
		Version: TransformersVersion,
		Packages: []string{
			"transformers==" + TransformersVersion,
			"safetensors==" + SafeTensorsVersion,
			"accelerate==" + AccelerateVersion,
			"fastapi==0.139.0",
			"uvicorn==0.51.0",
			"optimum-quanto==0.2.7",
			torchPackage,
		},
		PipArgs:      append([]string(nil), pipArgs...),
		ProbeModules: []string{"torch", "transformers", "safetensors", "accelerate", "fastapi", "uvicorn", "optimum.quanto"},
	}
	if err := r.Validate(); err != nil {
		return Recipe{}, err
	}
	return r, nil
}

func cloneStringMap(in map[string]string) map[string]string {
	if in == nil {
		return nil
	}
	out := make(map[string]string, len(in))
	keys := make([]string, 0, len(in))
	for key := range in {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		out[key] = in[key]
	}
	return out
}
