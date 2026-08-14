package wireguard

import (
	"context"
	"errors"
	"fmt"
	"net"
	"os"
	"os/exec"
	"runtime"
	"strconv"
	"strings"
	"time"
)

// State is what can be said about an interface from an unprivileged process.
type State string

const (
	StateDown State = "down"
	StateUp   State = "up"
	// StateUnavailable means WireGuard itself is missing, so the config can be
	// written but nothing can be said about the interface.
	StateUnavailable State = "unavailable"
)

// Status is the reading Query took.
type Status struct {
	State State
	// Message explains a state that is not simply up or down.
	Message string
	// LastHandshake is only filled when wg could be read, which usually means
	// the process is root. Its absence says nothing about the tunnel.
	LastHandshake time.Time
}

// Available reports whether the WireGuard tools are installed at all.
func Available() bool {
	_, err := exec.LookPath("wg-quick")
	return err == nil
}

// Query reports what an unprivileged process can see: whether the interface
// exists, and - if wg answers - when it last handshook.
//
// Interface presence is read through the standard library rather than through
// ip or ifconfig, because it needs no privileges and behaves the same on every
// platform the Studio ships on.
func Query(interfaceName string) Status {
	interfaceName = strings.TrimSpace(interfaceName)
	if interfaceName == "" {
		return Status{State: StateUnavailable, Message: "kein Interface-Name hinterlegt"}
	}
	if !Available() {
		return Status{State: StateUnavailable, Message: "WireGuard ist auf diesem Rechner nicht installiert"}
	}
	if _, err := net.InterfaceByName(interfaceName); err != nil {
		return Status{State: StateDown}
	}
	status := Status{State: StateUp}
	if handshake, ok := lastHandshake(interfaceName); ok {
		status.LastHandshake = handshake
	}
	return status
}

// lastHandshake asks wg when the peer was last heard from. It usually needs
// root, so a failure is not an error: the interface is up either way.
func lastHandshake(interfaceName string) (time.Time, bool) {
	binary, err := exec.LookPath("wg")
	if err != nil {
		return time.Time{}, false
	}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	output, err := exec.CommandContext(ctx, binary, "show", interfaceName, "latest-handshakes").Output()
	if err != nil {
		return time.Time{}, false
	}
	newest := int64(0)
	for _, line := range strings.Split(string(output), "\n") {
		fields := strings.Fields(line)
		if len(fields) < 2 {
			continue
		}
		seconds, convErr := strconv.ParseInt(fields[len(fields)-1], 10, 64)
		if convErr == nil && seconds > newest {
			newest = seconds
		}
	}
	if newest == 0 {
		return time.Time{}, false
	}
	return time.Unix(newest, 0).UTC(), true
}

// RaiseCommand is what brings the tunnel up, as a user would type it.
func RaiseCommand(configPath string) string {
	if runtime.GOOS == "windows" {
		return `wireguard.exe /installtunnelservice "` + configPath + `"`
	}
	return "sudo wg-quick up " + shellQuote(configPath)
}

// LowerCommand is the counterpart. It takes the config path rather than the
// interface name, because the config does not live in /etc/wireguard, which is
// the only place wg-quick finds an interface by name.
func LowerCommand(configPath string, interfaceName string) string {
	if runtime.GOOS == "windows" {
		return `wireguard.exe /uninstalltunnelservice ` + interfaceName
	}
	return "sudo wg-quick down " + shellQuote(configPath)
}

// ErrNeedsPrivileges says the tunnel could not be changed because nothing on
// this machine can ask for the rights it takes. The caller shows the command
// instead.
var ErrNeedsPrivileges = errors.New("das Tunnel-Interface braucht Administratorrechte")

// Raise brings the interface up, asking for rights through a graphical helper
// when the process does not already have them.
func Raise(ctx context.Context, configPath string) (string, error) {
	return runQuick(ctx, "up", configPath)
}

// Lower brings it back down.
func Lower(ctx context.Context, configPath string) (string, error) {
	return runQuick(ctx, "down", configPath)
}

func runQuick(ctx context.Context, action, configPath string) (string, error) {
	if !Available() {
		return "", fmt.Errorf("WireGuard ist nicht installiert; bitte wireguard-tools installieren")
	}
	binary, err := exec.LookPath("wg-quick")
	if err != nil {
		return "", fmt.Errorf("wg-quick nicht gefunden: %w", err)
	}

	var command *exec.Cmd
	switch {
	case os.Geteuid() == 0:
		command = exec.CommandContext(ctx, binary, action, configPath)
	default:
		helper, helperErr := exec.LookPath("pkexec")
		if helperErr != nil {
			return "", ErrNeedsPrivileges
		}
		command = exec.CommandContext(ctx, helper, binary, action, configPath)
	}
	output, runErr := command.CombinedOutput()
	text := strings.TrimSpace(string(output))
	if runErr != nil {
		if text == "" {
			text = runErr.Error()
		}
		return text, fmt.Errorf("wg-quick %s ist fehlgeschlagen: %s", action, text)
	}
	return text, nil
}

// shellQuote wraps a path for a command line the user is meant to copy. Only
// the display path goes through it; nothing here is handed to a shell.
func shellQuote(value string) string {
	if value == "" {
		return "''"
	}
	if !strings.ContainsAny(value, " \t'\"\\$`") {
		return value
	}
	return "'" + strings.ReplaceAll(value, "'", `'\''`) + "'"
}
