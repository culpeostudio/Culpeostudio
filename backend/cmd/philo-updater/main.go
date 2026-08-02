// Command philo-updater is the launcher. It updates a source checkout by
// fast-forward, or verifies and activates a released bundle and starts it.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"github.com/fillyengine/backend/internal/autoupdate"
)

const (
	defaultManifestURL = "https://raw.githubusercontent.com/kuchenboss/MyPhiloEngine/main/quikinstall/manifest.json"
	defaultRepository  = "https://github.com/kuchenboss/MyPhiloEngine.git"
)

var launcherVersion = "dev"

func main() {
	os.Exit(run(os.Args[1:], os.Stdout, os.Stderr))
}

func run(arguments []string, stdout, stderr io.Writer) int {
	if len(arguments) == 0 {

		return runCompiled(nil, stdout, stderr)
	}
	switch arguments[0] {
	case "source":
		return runSource(arguments[1:], stdout, stderr)
	case "compiled":
		return runCompiled(arguments[1:], stdout, stderr)
	case "version":
		_, _ = fmt.Fprintln(stdout, launcherVersion)
		return 0
	case "help", "-h", "--help":
		printUsage(stdout)
		return 0
	default:
		_, _ = fmt.Fprintf(stderr, "Unbekannter Updater-Befehl %q.\n", arguments[0])
		printUsage(stderr)
		return 2
	}
}

func runSource(arguments []string, stdout, stderr io.Writer) int {
	flags := flag.NewFlagSet("source", flag.ContinueOnError)
	flags.SetOutput(stderr)
	root := flags.String("root", "", "Pfad zur Quellcode-Installation")
	repository := flags.String("repository", defaultRepository, "Git-Repository")
	branch := flags.String("branch", "main", "Update-Branch")
	strict := flags.Bool("strict", false, "Bei einer nicht aktualisierbaren Installation fehlschlagen")
	if err := flags.Parse(arguments); err != nil {
		return 2
	}
	if strings.TrimSpace(*root) == "" {
		_, _ = fmt.Fprintln(stderr, "--root ist erforderlich")
		return 2
	}
	if updateDisabled() {
		_, _ = fmt.Fprintln(stdout, "[Updater] Quellcode-Update wurde über PHILOENGINE_SKIP_UPDATE übersprungen.")
		return 0
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()
	result, err := autoupdate.UpdateSource(ctx, *root, *repository, *branch)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "[Updater] Automatisches Quellcode-Update übersprungen: %v\n", err)
		if *strict {
			return 1
		}
		return 0
	}
	if result.Updated {
		_, _ = fmt.Fprintf(stdout, "[Updater] Quellcode automatisch auf %s aktualisiert.\n", shortRevision(result.After))
	} else {
		_, _ = fmt.Fprintln(stdout, "[Updater] Quellcode ist aktuell.")
	}
	return 0
}

func runCompiled(arguments []string, stdout, stderr io.Writer) int {
	executable, err := os.Executable()
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "Installationspfad konnte nicht bestimmt werden: %v\n", err)
		return 1
	}
	flags := flag.NewFlagSet("compiled", flag.ContinueOnError)
	flags.SetOutput(stderr)
	root := flags.String("root", filepath.Dir(executable), "Installationsordner")
	manifestURL := flags.String("manifest", defaultManifestURL, "HTTPS-URL des Update-Manifests")
	checkOnly := flags.Bool("check", false, "Nur auf Updates prüfen")
	skipUpdate := flags.Bool("no-update", false, "Ohne Updateprüfung starten")
	delegated := flags.Bool("delegated", false, "Interner Aufruf des versionierten Launchers")
	if err := flags.Parse(arguments); err != nil {
		return 2
	}
	absoluteRoot, err := filepath.Abs(*root)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "Ungültiger Installationspfad: %v\n", err)
		return 1
	}

	if len(arguments) == 0 && !*delegated {
		if code, handled := delegateToInstalledLauncher(stdout, stderr); handled {
			return code
		}
	}
	lock, err := autoupdate.AcquireUpdateLock(absoluteRoot)
	if err != nil {
		_, _ = fmt.Fprintln(stderr, err)
		return 1
	}
	defer lock.Close()

	ctx, stopSignals := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stopSignals()
	platform, err := autoupdate.CurrentPlatformKey()
	if err != nil {
		_, _ = fmt.Fprintln(stderr, err)
		return 1
	}

	previousState, previousErr := autoupdate.LoadCurrent(absoluteRoot)
	var previousBundle *autoupdate.InstalledBundle
	if previousErr == nil {
		if resolved, resolveErr := autoupdate.ResolveInstalledBundle(absoluteRoot, previousState); resolveErr == nil {
			previousBundle = &resolved
		} else {
			previousErr = resolveErr
		}
	}

	if *skipUpdate || updateDisabled() {
		if *checkOnly {
			_, _ = fmt.Fprintln(stdout, `{"update_check_skipped":true}`)
			return 0
		}
		if previousBundle == nil {
			_, _ = fmt.Fprintf(stderr, "Keine startfähige Installation gefunden: %v\n", previousErr)
			return 1
		}
		return runInstalled(ctx, absoluteRoot, *previousBundle, stdout, stderr)
	}

	client, err := autoupdate.NewClient(*manifestURL, autoupdate.GitHubOriginPolicy())
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "Updater-Konfiguration ist ungültig: %v\n", err)
		return 1
	}
	manifestContext, cancelManifest := context.WithTimeout(ctx, 45*time.Second)
	manifest, manifestErr := client.FetchManifest(manifestContext)
	cancelManifest()
	if manifestErr != nil {
		if *checkOnly {
			_, _ = fmt.Fprintf(stderr, "Updateprüfung fehlgeschlagen: %v\n", manifestErr)
			return 1
		}
		if previousBundle == nil {
			_, _ = fmt.Fprintf(stderr, "Updateprüfung fehlgeschlagen und keine lokale Version ist startfähig: %v\n", manifestErr)
			return 1
		}
		_, _ = fmt.Fprintf(stderr, "[Updater] GitHub ist nicht erreichbar; Version %s wird offline gestartet: %v\n", previousState.Version, manifestErr)
		return runInstalled(ctx, absoluteRoot, *previousBundle, stdout, stderr)
	}
	asset, available := manifest.Assets[platform]
	updateAvailable := false
	if available {
		if previousBundle == nil {
			updateAvailable = true
		} else if comparison, compareErr := autoupdate.CompareVersions(previousState.Version, manifest.Version); compareErr != nil {
			_, _ = fmt.Fprintf(stderr, "Versionsvergleich fehlgeschlagen: %v\n", compareErr)
			return 1
		} else {
			updateAvailable = comparison < 0 ||
				(comparison == 0 && !strings.EqualFold(previousState.AssetSHA256, asset.SHA256))
		}
	}

	quarantine, quarantineErr := autoupdate.LoadQuarantine(absoluteRoot)
	if quarantineErr != nil {
		_, _ = fmt.Fprintf(stderr, "[Updater] Quarantäneliste wird ignoriert: %v\n", quarantineErr)
	}
	blocked := updateAvailable && previousBundle != nil &&
		quarantine.Contains(manifest.Version, asset.SHA256)
	if *checkOnly {
		status := map[string]any{
			"platform":         platform,
			"latest_version":   manifest.Version,
			"asset_available":  available,
			"update_available": updateAvailable,
			"update_blocked":   blocked,
		}
		if previousErr == nil {
			status["current_version"] = previousState.Version
		}
		encoder := json.NewEncoder(stdout)
		encoder.SetEscapeHTML(false)
		if err := encoder.Encode(status); err != nil {
			_, _ = fmt.Fprintln(stderr, err)
			return 1
		}
		return 0
	}
	if !available {
		if previousBundle == nil {
			_, _ = fmt.Fprintf(stderr, "Für %s gibt es noch kein kompiliertes Paket und keine lokale Version.\n", platform)
			return 1
		}
		_, _ = fmt.Fprintf(stderr, "[Updater] Für %s ist noch kein neuer Build verfügbar; Version %s wird gestartet.\n", platform, previousState.Version)
		return runInstalled(ctx, absoluteRoot, *previousBundle, stdout, stderr)
	}

	activeBundle := previousBundle
	updated := false
	if blocked {
		_, _ = fmt.Fprintf(
			stderr,
			"[Updater] Version %s wird übersprungen, weil sie zuvor nicht startete; Version %s bleibt aktiv.\n",
			manifest.Version,
			previousState.Version,
		)
	} else if updateAvailable {
		_, _ = fmt.Fprintf(stdout, "[Updater] Version %s wird heruntergeladen und sicher installiert …\n", manifest.Version)
		installContext, cancelInstall := context.WithTimeout(ctx, 2*time.Hour)
		state, installErr := client.Install(installContext, absoluteRoot, manifest, asset)
		cancelInstall()
		if installErr != nil {
			if previousBundle == nil {
				_, _ = fmt.Fprintf(stderr, "Update konnte nicht installiert werden: %v\n", installErr)
				return 1
			}
			_, _ = fmt.Fprintf(stderr, "[Updater] Update fehlgeschlagen; Version %s bleibt aktiv: %v\n", previousState.Version, installErr)
		} else {
			resolved, resolveErr := autoupdate.ResolveInstalledBundle(absoluteRoot, state)
			if resolveErr != nil {
				_, _ = fmt.Fprintf(stderr, "Installiertes Update ist nicht startfähig: %v\n", resolveErr)
				if previousBundle == nil {
					return 1
				}
				quarantineBundle(absoluteRoot, state, resolveErr, stderr)
				if activateErr := autoupdate.ActivateState(absoluteRoot, previousState); activateErr != nil {
					_, _ = fmt.Fprintf(stderr, "Vorherige Version konnte nicht reaktiviert werden: %v\n", activateErr)
					return 1
				}
				_, _ = fmt.Fprintf(stderr, "[Updater] Version %s bleibt aktiv.\n", previousState.Version)
			} else {
				activeBundle = &resolved
				updated = true
				_, _ = fmt.Fprintf(stdout, "[Updater] Version %s ist installiert und wird gestartet.\n", state.Version)
			}
		}
	}
	if activeBundle == nil {
		_, _ = fmt.Fprintln(stderr, "Keine startfähige MyPhiloEngine-Version gefunden.")
		return 1
	}
	pruneObsoleteVersions(absoluteRoot, activeBundle.State, previousState, previousErr, stderr)
	runErr := autoupdate.RunBundle(ctx, absoluteRoot, *activeBundle, stdout, stderr)
	if runErr == nil {
		return 0
	}
	if updated && previousBundle != nil && autoupdate.IsStartupError(runErr) {
		_, _ = fmt.Fprintf(stderr, "[Updater] Neue Version startet nicht; automatischer Rollback auf %s: %v\n", previousState.Version, runErr)
		quarantineBundle(absoluteRoot, activeBundle.State, runErr, stderr)
		if activateErr := autoupdate.ActivateState(absoluteRoot, previousState); activateErr != nil {
			_, _ = fmt.Fprintf(stderr, "Rollback konnte nicht aktiviert werden: %v\n", activateErr)
			return 1
		}
		return runInstalled(ctx, absoluteRoot, *previousBundle, stdout, stderr)
	}
	_, _ = fmt.Fprintln(stderr, runErr)
	return 1
}

func quarantineBundle(installRoot string, state autoupdate.CurrentState, cause error, stderr io.Writer) {
	if err := autoupdate.QuarantineBundle(installRoot, state, cause.Error()); err != nil {
		_, _ = fmt.Fprintf(stderr, "[Updater] Defekte Version %s konnte nicht vorgemerkt werden: %v\n", state.Version, err)
	}
}

func pruneObsoleteVersions(
	installRoot string,
	active autoupdate.CurrentState,
	previous autoupdate.CurrentState,
	previousErr error,
	stderr io.Writer,
) {
	keep := []autoupdate.CurrentState{active}
	if previousErr == nil {
		keep = append(keep, previous)
	}
	if err := autoupdate.PruneVersions(installRoot, keep...); err != nil {
		_, _ = fmt.Fprintf(stderr, "[Updater] Alte Versionen konnten nicht aufgeräumt werden: %v\n", err)
	}
}

func delegateToInstalledLauncher(stdout, stderr io.Writer) (int, bool) {
	executable, err := os.Executable()
	if err != nil {
		return 0, false
	}
	installRoot := filepath.Dir(executable)
	state, err := autoupdate.LoadCurrent(installRoot)
	if err != nil {
		return 0, false
	}
	bundle, err := autoupdate.ResolveInstalledBundle(installRoot, state)
	if err != nil || sameExecutable(executable, bundle.Launcher) {
		return 0, false
	}
	command := exec.Command(
		bundle.Launcher,
		"compiled",
		"--root",
		installRoot,
		"--delegated",
	)
	command.Stdin = os.Stdin
	command.Stdout = stdout
	command.Stderr = stderr
	if err := command.Run(); err != nil {
		var exitError *exec.ExitError
		if errors.As(err, &exitError) {
			return exitError.ExitCode(), true
		}
		_, _ = fmt.Fprintf(stderr, "[Updater] Versionierter Launcher konnte nicht gestartet werden; Bootstrap wird verwendet: %v\n", err)
		return 0, false
	}
	return 0, true
}

func sameExecutable(left, right string) bool {
	leftResolved, leftErr := filepath.EvalSymlinks(left)
	rightResolved, rightErr := filepath.EvalSymlinks(right)
	if leftErr == nil {
		left = leftResolved
	}
	if rightErr == nil {
		right = rightResolved
	}
	leftAbsolute, leftErr := filepath.Abs(left)
	rightAbsolute, rightErr := filepath.Abs(right)
	return leftErr == nil && rightErr == nil &&
		filepath.Clean(leftAbsolute) == filepath.Clean(rightAbsolute)
}

func runInstalled(
	ctx context.Context,
	root string,
	bundle autoupdate.InstalledBundle,
	stdout io.Writer,
	stderr io.Writer,
) int {
	if err := autoupdate.RunBundle(ctx, root, bundle, stdout, stderr); err != nil {
		if !errors.Is(err, context.Canceled) {
			_, _ = fmt.Fprintln(stderr, err)
			return 1
		}
	}
	return 0
}

func updateDisabled() bool {
	switch strings.ToLower(strings.TrimSpace(os.Getenv("PHILOENGINE_SKIP_UPDATE"))) {
	case "1", "true", "yes", "on":
		return true
	default:
		return false
	}
}

func shortRevision(revision string) string {
	revision = strings.TrimSpace(revision)
	if len(revision) > 12 {
		return revision[:12]
	}
	return revision
}

func printUsage(writer io.Writer) {
	_, _ = fmt.Fprintln(writer, `MyPhiloEngine Updater

Verwendung:
  philo-updater source --root <Projektordner>
  philo-updater compiled [--root <Installationsordner>] [--check]
  philo-updater version

PHILOENGINE_SKIP_UPDATE=1 überspringt die Netzprüfung, startet aber eine
bereits installierte kompilierte Version weiterhin.`)
}
