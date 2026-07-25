package engineruntime

import (
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestRecipeUsesContentAddressedVersionedPath(t *testing.T) {
	recipe := DefaultLlamaCPPRecipe(map[string]string{"CMAKE_ARGS": "-DGGML_VULKAN=on"})
	digest, err := recipe.Digest()
	if err != nil {
		t.Fatal(err)
	}
	path, err := recipe.EnvironmentPath("/runtime-root")
	if err != nil {
		t.Fatal(err)
	}
	wantSuffix := filepath.Join(string(RuntimeLlamaCPP), LlamaCPPVersion, digest[:16])
	if !strings.HasSuffix(path, wantSuffix) {
		t.Fatalf("environment path %q does not end in %q", path, wantSuffix)
	}

	other := DefaultLlamaCPPRecipe(map[string]string{"CMAKE_ARGS": "-DGGML_CUDA=on"})
	otherPath, err := other.EnvironmentPath("/runtime-root")
	if err != nil {
		t.Fatal(err)
	}
	if path == otherPath {
		t.Fatal("different build recipes must not share an environment")
	}
}

func TestRecipeRejectsUnpinnedPackage(t *testing.T) {
	recipe := Recipe{Runtime: RuntimeVLLM, Version: "1", Packages: []string{"vllm"}}
	if err := recipe.Validate(); err == nil {
		t.Fatal("expected an unpinned package error")
	}
}

func TestDefaultTransformersRecipePinsWorkerDependencies(t *testing.T) {
	recipe, err := DefaultTransformersRecipe("torch==2.9.1", []string{"--index-url", "https://download.pytorch.org/whl/rocm7.0"})
	if err != nil {
		t.Fatal(err)
	}
	for _, wanted := range []string{
		"transformers==" + TransformersVersion,
		"safetensors==" + SafeTensorsVersion,
		"accelerate==" + AccelerateVersion,
		"optimum-quanto==0.2.7",
		"fastapi==0.139.0",
		"uvicorn==0.51.0",
		"torch==2.9.1",
	} {
		found := false
		for _, pkg := range recipe.Packages {
			if pkg == wanted {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("recipe is missing %q: %#v", wanted, recipe.Packages)
		}
	}
	if _, err := DefaultTransformersRecipe("torch", nil); err == nil {
		t.Fatal("an unpinned accelerator-specific Torch package must be rejected")
	}
}

func TestEnvironmentPython(t *testing.T) {
	got := environmentPython("/env")
	if runtime.GOOS == "windows" {
		if !strings.HasSuffix(got, filepath.Join("Scripts", "python.exe")) {
			t.Fatalf("unexpected Windows venv Python path: %s", got)
		}
	} else if !strings.HasSuffix(got, filepath.Join("bin", "python")) {
		t.Fatalf("unexpected venv Python path: %s", got)
	}
}
