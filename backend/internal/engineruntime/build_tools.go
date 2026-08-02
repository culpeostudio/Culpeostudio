package engineruntime

import (
	"fmt"
	"os/exec"
	"runtime"
	"strings"
)

func checkNativeBuildTools() error {
	missing := []string{}
	if _, err := exec.LookPath("cmake"); err != nil {
		missing = append(missing, "CMake")
	}
	compilerFound := false
	for _, name := range compilerCandidates() {
		if _, err := exec.LookPath(name); err == nil {
			compilerFound = true
			break
		}
	}
	if !compilerFound {
		missing = append(missing, "C-Compiler")
	}
	cxxCompilerFound := false
	for _, name := range cxxCompilerCandidates() {
		if _, err := exec.LookPath(name); err == nil {
			cxxCompilerFound = true
			break
		}
	}
	if !cxxCompilerFound {
		missing = append(missing, "C++-Compiler")
	}
	if len(missing) == 0 {
		return nil
	}
	return fmt.Errorf("Fuer den nativen Runtime-Build fehlen benoetigte Werkzeuge: %s. %s",
		strings.Join(missing, " und "), buildToolInstallHint())
}

func cxxCompilerCandidates() []string {
	switch runtime.GOOS {
	case "windows":
		return []string{"cl", "clang++", "g++"}
	case "darwin":
		return []string{"c++", "clang++"}
	default:
		return []string{"c++", "g++", "clang++"}
	}
}

func compilerCandidates() []string {
	switch runtime.GOOS {
	case "windows":
		return []string{"cl", "clang", "gcc"}
	case "darwin":
		return []string{"cc", "clang"}
	default:
		return []string{"cc", "gcc", "clang"}
	}
}

func buildToolInstallHint() string {
	switch runtime.GOOS {
	case "windows":
		return "Bitte die Visual Studio Build Tools (C++-Workload) und CMake installieren und den Rechner neu starten."
	case "darwin":
		return "Bitte die Xcode Command Line Tools installieren ('xcode-select --install') und CMake, z. B. ueber Homebrew ('brew install cmake')."
	default:
		return "Bitte Compiler und CMake installieren, z. B. unter Ubuntu/Debian: 'sudo apt install build-essential cmake'."
	}
}
