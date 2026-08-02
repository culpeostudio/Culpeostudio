from __future__ import annotations

import asyncio
import os
import signal
import sys
import urllib.error
import urllib.request
from collections import deque
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
import shutil
import subprocess
from typing import TextIO


def _setup_go_path() -> None:
    if shutil.which("go"):
        return

    import glob
    possible_dirs = [
        os.path.expanduser("~/go-local/go/bin"),
        "/usr/local/go/bin",
        "/usr/lib/go/bin",
        os.path.expanduser("~/go/bin"),
    ]
    toolchain_dirs = glob.glob(os.path.expanduser("~/go/pkg/mod/golang.org/toolchain@*/bin"))
    if toolchain_dirs:
        toolchain_dirs.sort(reverse=True)
        possible_dirs.extend(toolchain_dirs)

    for directory in possible_dirs:
        go_path = os.path.join(directory, "go")
        if os.path.isfile(go_path) and os.access(go_path, os.X_OK):
            current_path = os.environ.get("PATH", "")
            if current_path:
                os.environ["PATH"] = f"{directory}:{current_path}"
            else:
                os.environ["PATH"] = directory
            break



def _setup_flutter_path() -> None:
    if shutil.which("flutter"):
        return

    possible_dirs = [
        os.path.expanduser("~/development/flutter/bin"),
        os.path.expanduser("~/flutter/bin"),
        "/opt/flutter/bin",
        "/snap/bin",
    ]

    for directory in possible_dirs:
        flutter_path = os.path.join(directory, "flutter")
        if os.path.isfile(flutter_path) and os.access(flutter_path, os.X_OK):
            current_path = os.environ.get("PATH", "")
            if current_path:
                os.environ["PATH"] = f"{directory}:{current_path}"
            else:
                os.environ["PATH"] = directory
            break

_setup_go_path()
_setup_flutter_path()

from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Button, Footer, Header, Label, RichLog, Static

BACKEND_DIR = Path(__file__).resolve().parent
FRONTEND_DIR = BACKEND_DIR.parent / "frontend"



@dataclass
class ManagedService:
    """Ein von der Backend-Console verwalteter Subprozess (z.B. der Go-Server).

    Die Property ``running`` ist der zentrale Zustandsindikator fuer die
    UI (grauer/roter Status pro Service). Sie wird bewusst nicht als
    separates Feld gepeichert, sondern jedes Mal live aus ``process`` /
    ``returncode`` abgeleitet – so kann sie nie durch ein vergessenes
    Update ins Inkonsistente laufen.
    """

    name: str
    cwd: Path
    command: list[str] = field(default_factory=list)
    process: asyncio.subprocess.Process | None = None
    tasks: list[asyncio.Task] = field(default_factory=list)
    exit_task: asyncio.Task | None = None
    stopping: bool = False

    @property
    def running(self) -> bool:
        """True, solange der Subprozess existiert und noch nicht beendet ist.
        ``process is None`` (vor Start) und ``returncode is None`` (zwischen
        Start und Exit) werden unterschieden, so dass "wird gerade gestartet"
        und "laeuft" denselben Status liefern – der User sieht in beiden
        Faellen einen nicht-gruenen Startbutton, solange der Prozess noch
        kein returncode hat. Das spiegelt exakt ``asyncio``'s own model
        wider und vermeidet Race-Conditions beim schnellen Start/Stop."""
        return self.process is not None and self.process.returncode is None


class BackendConsoleApp(App):
    CSS = """
    Screen {
        layout: vertical;
        background: #111318;
    }

    #top {
        height: 16;
    }

    #services, #actions {
        width: 1fr;
        height: 1fr;
        border: round #3f4c6b;
        background: #171a22;
        padding: 1;
        overflow-y: auto;
    }

    .section-title {
        text-style: bold;
        color: #9fd3ff;
        margin-bottom: 1;
    }

    #logs {
        height: 1fr;
        border: round #3f4c6b;
        background: #151820;
        padding: 1;
    }

    #backend-log {
        height: 1fr;
        border: round #2c9f6d;
        background: #101419;
    }

    Button {
        margin-bottom: 1;
    }
    """

    BINDINGS = [
        ("q", "request_exit", "Exit"),
    ]

    def __init__(self):
        super().__init__()
        self.logs_dir = BACKEND_DIR / "logs"
        self.logs_dir.mkdir(parents=True, exist_ok=True)
        self.current_log_file = self.logs_dir / self._build_session_log_name()
        self.log_file_handle: TextIO | None = self.current_log_file.open("a", encoding="utf-8")

        self.backend = ManagedService(
            name="backend",
            cwd=BACKEND_DIR,
            command=["go", "run", "./cmd/server"],
        )
        self.frontend = ManagedService(
            name="frontend",
            cwd=FRONTEND_DIR,
            command=["flutter", "run", "-d", "linux"],
        )

        self.log_buffer: deque[str] = deque(maxlen=5000)
        self.dependencies_ready = False
        self.frontend_dependencies_ready = False

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Horizontal(id="top"):
            with Vertical(id="services"):
                yield Label("Service", classes="section-title")
                yield Static("Backend: stopped", id="status-backend")
                yield Static("Backend PID: -", id="status-pid")
                yield Static(f"Backend path: {BACKEND_DIR}")
                yield Static("Session log file: -", id="status-log")
                yield Static("Frontend: stopped", id="status-frontend")
                yield Static("Frontend PID: -", id="status-frontend-pid")
                yield Static(f"Frontend path: {FRONTEND_DIR}")
            with Vertical(id="actions"):
                yield Label("Actions", classes="section-title")
                yield Button("Start all (Backend -> Frontend)", variant="success", id="start-all")
                yield Button("Stop all", id="stop-all")
                yield Button("Restart all", id="restart-all")
                yield Button("Refresh status", id="refresh-status")
                yield Button("Copy logs", id="copy-logs")
                yield Button("Exit (stop all)", variant="error", id="exit-all")
        with Vertical(id="logs"):
            yield Label("Logs (Backend + Frontend)", classes="section-title")
            yield RichLog(id="backend-log", wrap=True, markup=False)
        yield Footer()

    async def on_mount(self) -> None:
        self._log("Dev console started.", source="console.lifecycle")
        self._log(f"Session log file: {self.current_log_file}", source="console.lifecycle")
        self._log(f"Console PID: {os.getpid()}", source="console.lifecycle")
        self._log(f"Backend directory: {BACKEND_DIR}", source="console.lifecycle")
        self._log(f"Frontend directory: {FRONTEND_DIR}", source="console.lifecycle")
        self._log(f"Backend command: {' '.join(self.backend.command)}", source="console.lifecycle")
        self._log(f"Frontend command: {' '.join(self.frontend.command)}", source="console.lifecycle")



        await asyncio.gather(
            self._ensure_go_dependencies(),
            self._ensure_philoengine_hardware_dependency(),
            self._ensure_flutter_dependencies(),
        )
        self._update_status_widgets()

    def on_unmount(self) -> None:
        self._close_log_file()

    async def action_request_exit(self) -> None:
        await self._stop_frontend()
        await self._stop_backend()
        self.exit()

    async def on_button_pressed(self, event: Button.Pressed) -> None:
        button_id = event.button.id or ""

        if button_id == "start-all":
            await self._start_all()
        elif button_id == "stop-all":
            await self._stop_all()
        elif button_id == "restart-all":
            await self._restart_all()
        elif button_id == "refresh-status":
            self._update_status_widgets()
        elif button_id == "copy-logs":
            self._copy_logs_to_clipboard()
        elif button_id == "exit-all":
            await self._stop_frontend()
            await self._stop_backend()
            self.exit()

    async def _start_backend(self) -> None:
        if self.backend.running:
            self._log("Backend start requested, but service is already running.", source="backend.lifecycle", level="WARN")
            return

        if not await self._ensure_go_dependencies():
            return

        max_attempts = 3
        for attempt in range(1, max_attempts + 1):
            self._log(
                f"Backend start requested (attempt {attempt}/{max_attempts}).",
                source="backend.lifecycle",
            )
            if not await self._ensure_backend_ports_free():
                self._log(
                    "Backend start aborted because required ports are still busy.",
                    source="backend.lifecycle",
                    level="ERROR",
                )
                return

            self._log(
                f"Launching command in {self.backend.cwd}: {' '.join(self.backend.command)}",
                source="backend.lifecycle",
            )

            try:
                process_options: dict[str, object] = {}
                if os.name == "posix":



                    process_options["start_new_session"] = True
                elif os.name == "nt":
                    process_options["creationflags"] = subprocess.CREATE_NEW_PROCESS_GROUP
                process = await asyncio.create_subprocess_exec(
                    *self.backend.command,
                    cwd=str(self.backend.cwd),
                    stdin=asyncio.subprocess.DEVNULL,
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.PIPE,
                    **process_options,
                )
            except FileNotFoundError as exc:
                self._log(f"Backend start failed: {exc}", source="backend.lifecycle", level="ERROR")
                return

            self.backend.process = process
            self.backend.stopping = False
            self.backend.tasks = [
                asyncio.create_task(self._stream_output(process.stdout, "stdout", self.backend)),
                asyncio.create_task(self._stream_output(process.stderr, "stderr", self.backend)),
            ]
            self.backend.exit_task = asyncio.create_task(self._watch_backend(process))

            self._log(
                f"Backend started with PID {process.pid} (attempt {attempt}/{max_attempts}).",
                source="backend.lifecycle",
            )
            self._update_status_widgets()

            await asyncio.sleep(1.2)
            if process.returncode is None:
                return

            if attempt >= max_attempts or not self._recent_bind_conflict_detected():
                return

            self._log(
                "Detected bind conflict during backend startup, retrying.",
                source="backend.lifecycle",
                level="WARN",
            )
            await self._shutdown_stream_tasks(self.backend)
            await self._shutdown_exit_task(self.backend)
            self.backend.process = None
            await asyncio.sleep(0.8)

    async def _stop_backend(self) -> None:
        process = self.backend.process
        if process is None:
            await self._shutdown_stream_tasks(self.backend)
            await self._shutdown_exit_task(self.backend)
            self._log("Backend stop requested, but service is not running.", source="backend.lifecycle", level="WARN")
            self._update_status_widgets()
            return

        if self.backend.running:
            self.backend.stopping = True
            self._log(
                "Backend wird beendet; lokale Modelle werden sicher gestoppt.",
                source="backend.lifecycle",
            )
            process_group = None
            if os.name == "posix":
                try:
                    process_group = os.getpgid(process.pid)
                    os.killpg(process_group, signal.SIGTERM)
                except ProcessLookupError:
                    process_group = None
            else:
                process.terminate()

            deadline = asyncio.get_running_loop().time() + 40
            while self._backend_process_tree_alive(process, process_group):
                if asyncio.get_running_loop().time() >= deadline:
                    self._log(
                        "Backend-Prozessgruppe reagiert nach 40 Sekunden nicht; sie wird jetzt sicher beendet.",
                        source="backend.lifecycle",
                        level="WARN",
                    )
                    if process_group is not None:
                        try:
                            os.killpg(process_group, signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                    elif process.returncode is None:
                        process.kill()
                    break
                await asyncio.sleep(0.2)
            if process.returncode is None:
                try:
                    await asyncio.wait_for(process.wait(), timeout=2)
                except asyncio.TimeoutError:
                    process.kill()
                    await process.wait()

        await self._shutdown_stream_tasks(self.backend)
        try:
            await asyncio.wait_for(process.communicate(), timeout=2)
        except Exception:
            pass

        await self._shutdown_exit_task(self.backend)
        self.backend.process = None
        self.backend.stopping = False
        self._log("Backend stopped.", source="backend.lifecycle")
        self._update_status_widgets()

    @staticmethod
    def _backend_process_tree_alive(
        process: asyncio.subprocess.Process,
        process_group: int | None,
    ) -> bool:
        if process_group is not None and os.name == "posix":
            try:
                os.killpg(process_group, 0)
                return True
            except ProcessLookupError:
                return False
            except PermissionError:
                return True
        return process.returncode is None

    async def _watch_backend(self, process: asyncio.subprocess.Process) -> None:
        try:
            return_code = await process.wait()
        except asyncio.CancelledError:
            return

        self.backend.process = None
        if self.backend.exit_task is asyncio.current_task():
            self.backend.exit_task = None

        level = "INFO" if return_code == 0 or self.backend.stopping else "ERROR"
        self._log(f"Backend exited with code {return_code}.", source="backend.lifecycle", level=level)
        self._update_status_widgets()

    async def _ensure_flutter_available(self) -> bool:
        if not shutil.which("flutter"):
            self._log(
                "Dependency check failed: flutter is not installed or not in PATH.",
                source="frontend.lifecycle",
                level="ERROR",
            )
            return False
        return True

    async def _ensure_flutter_dependencies(self) -> bool:
        if self.frontend_dependencies_ready:
            return True
        if not await self._ensure_flutter_available():
            return False
        self._log(
            "Preparing Flutter dependencies with `flutter pub get`.",
            source="frontend.dependencies",
        )
        process = await asyncio.create_subprocess_exec(
            "flutter",
            "pub",
            "get",
            cwd=str(FRONTEND_DIR),
            stdin=asyncio.subprocess.DEVNULL,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, stderr = await process.communicate()
        if process.returncode != 0:
            self._log(
                "Flutter dependency setup failed (`flutter pub get`).",
                source="frontend.dependencies",
                level="ERROR",
            )
            for line in stderr.decode(errors="replace").splitlines()[-12:]:
                if line.strip():
                    self._log(line, source="frontend.dependencies.stderr", level="ERROR")
            return False
        for line in stdout.decode(errors="replace").splitlines():
            if line.strip() and not line.startswith("  "):
                self._log(line, source="frontend.dependencies.stdout")
        self.frontend_dependencies_ready = True
        self._log("Flutter dependencies are ready.", source="frontend.dependencies")
        return True

    async def _start_frontend(self) -> None:
        if self.frontend.running:
            self._log("Frontend start requested, but service is already running.", source="frontend.lifecycle", level="WARN")
            return

        if not await self._ensure_flutter_dependencies():
            return

        self._log("Frontend start requested.", source="frontend.lifecycle")
        self._log(
            f"Launching command in {self.frontend.cwd}: {' '.join(self.frontend.command)}",
            source="frontend.lifecycle",
        )

        try:
            process = await asyncio.create_subprocess_exec(
                *self.frontend.command,
                cwd=str(self.frontend.cwd),
                stdin=asyncio.subprocess.DEVNULL,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
        except FileNotFoundError as exc:
            self._log(f"Frontend start failed: {exc}", source="frontend.lifecycle", level="ERROR")
            return

        self.frontend.process = process
        self.frontend.tasks = [
            asyncio.create_task(self._stream_output(process.stdout, "stdout", self.frontend)),
            asyncio.create_task(self._stream_output(process.stderr, "stderr", self.frontend)),
        ]
        self.frontend.exit_task = asyncio.create_task(self._watch_frontend(process))

        self._log(f"Frontend started with PID {process.pid}.", source="frontend.lifecycle")
        self._update_status_widgets()

    async def _stop_frontend(self) -> None:
        process = self.frontend.process
        if process is None:
            await self._shutdown_stream_tasks(self.frontend)
            await self._shutdown_exit_task(self.frontend)
            self._log("Frontend stop requested, but service is not running.", source="frontend.lifecycle", level="WARN")
            self._update_status_widgets()
            return

        if self.frontend.running:
            self._log(f"Stopping frontend PID {process.pid} with SIGTERM.", source="frontend.lifecycle")
            process.terminate()
            try:
                await asyncio.wait_for(process.wait(), timeout=8)
            except asyncio.TimeoutError:
                self._log(
                    f"Frontend PID {process.pid} did not exit after SIGTERM; sending SIGKILL.",
                    source="frontend.lifecycle",
                    level="WARN",
                )
                process.kill()
                await process.wait()

        await self._shutdown_stream_tasks(self.frontend)
        try:
            await asyncio.wait_for(process.communicate(), timeout=2)
        except Exception:
            pass

        await self._shutdown_exit_task(self.frontend)
        self.frontend.process = None
        self._log("Frontend stopped.", source="frontend.lifecycle")
        self._update_status_widgets()

    async def _watch_frontend(self, process: asyncio.subprocess.Process) -> None:
        try:
            return_code = await process.wait()
        except asyncio.CancelledError:
            return

        self.frontend.process = None
        if self.frontend.exit_task is asyncio.current_task():
            self.frontend.exit_task = None

        level = "INFO" if return_code == 0 else "ERROR"
        self._log(f"Frontend exited with code {return_code}.", source="frontend.lifecycle", level=level)
        self._update_status_widgets()

    async def _wait_for_backend_health(self, timeout: float = 20.0) -> bool:
        port = os.getenv("HTTP_PORT", "8080").strip() or "8080"
        url = f"http://127.0.0.1:{port}/health"
        deadline = asyncio.get_event_loop().time() + timeout
        self._log(f"Waiting for backend health at {url} for up to {timeout:.1f}s.", source="backend.health")

        while asyncio.get_event_loop().time() < deadline:
            if not self.backend.running:
                self._log("Backend stopped before health check completed.", source="backend.health", level="WARN")
                return False
            try:
                await asyncio.to_thread(urllib.request.urlopen, url, None, 1.5)
                self._log(f"Backend health check succeeded at {url}.", source="backend.health")
                return True
            except urllib.error.HTTPError as exc:
                self._log(
                    f"Backend health endpoint returned HTTP {exc.code}; waiting for a healthy response.",
                    source="backend.health",
                    level="WARN",
                )
                await asyncio.sleep(0.5)
            except (urllib.error.URLError, OSError, ValueError):
                await asyncio.sleep(0.5)
        self._log(f"Backend health check timed out after {timeout:.1f}s at {url}.", source="backend.health", level="WARN")
        return False

    async def _start_all(self) -> None:
        self._log("Start-all sequence requested.", source="console.lifecycle")
        await self._start_backend()
        if not self.backend.running:
            self._log("Start-all aborted because backend did not start.", source="console.lifecycle", level="ERROR")
            return

        self._log("Waiting for backend health check before starting frontend.", source="console.lifecycle")
        if not await self._wait_for_backend_health():
            self._log(
                "Backend did not report healthy in time; starting frontend anyway.",
                source="console.lifecycle",
                level="WARN",
            )
        await self._start_frontend()

    async def _stop_all(self) -> None:
        self._log("Stop-all sequence requested.", source="console.lifecycle")
        await self._stop_frontend()
        await self._stop_backend()

    async def _restart_all(self) -> None:
        self._log("Restart-all sequence requested.", source="console.lifecycle")
        await self._stop_all()
        await self._start_all()

    async def _stream_output(
        self,
        stream: asyncio.StreamReader | None,
        channel: str,
        service: ManagedService,
    ) -> None:
        if stream is None:
            return
        try:
            while True:
                line = await stream.readline()
                if not line:
                    break
                text = line.decode(errors="replace").rstrip()
                if text:
                    self._log(text, source=f"{service.name}.{channel}")
        except asyncio.CancelledError:
            return

    async def _ensure_go_dependencies(self) -> bool:
        if self.dependencies_ready:
            return True

        if not shutil.which("go"):
            self._log("Dependency check failed: go is not installed or not in PATH.", source="go.dependencies", level="ERROR")
            return False

        self._log("Checking Go dependencies with `go mod tidy`.", source="go.dependencies")
        process = await asyncio.create_subprocess_exec(
            "go",
            "mod",
            "tidy",
            cwd=str(BACKEND_DIR),
            stdin=asyncio.subprocess.DEVNULL,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, stderr = await process.communicate()
        if process.returncode != 0:
            self._log("Dependency setup failed (`go mod tidy`).", source="go.dependencies", level="ERROR")
            for line in stdout.decode(errors="replace").splitlines():
                if line.strip():
                    self._log(line, source="go.dependencies.stdout", level="ERROR")
            for line in stderr.decode(errors="replace").splitlines():
                if line.strip():
                    self._log(line, source="go.dependencies.stderr", level="ERROR")
            return False
        for line in stdout.decode(errors="replace").splitlines():
            if line.strip():
                self._log(line, source="go.dependencies.stdout")
        for line in stderr.decode(errors="replace").splitlines():
            if line.strip():
                self._log(line, source="go.dependencies.stderr", level="WARN")
        self._log("Go dependencies are ready.", source="go.dependencies")

        self.dependencies_ready = True
        return True

    async def _ensure_philoengine_hardware_dependency(self) -> bool:
        """Install the optional upstream detector for PhiloEngine.

        The probe itself has a Go fallback, so a failed optional installation
        never prevents the application from starting.  The console reports the
        fallback clearly instead of hiding a missing dependency.
        """
        check = await asyncio.create_subprocess_exec(
            sys.executable,
            "-c",
            "import whichllm.hardware.detector",
            cwd=str(BACKEND_DIR),
            stdin=asyncio.subprocess.DEVNULL,
            stdout=asyncio.subprocess.DEVNULL,
            stderr=asyncio.subprocess.DEVNULL,
        )
        if await check.wait() == 0:
            self._log(
                "PhiloEngine hardware detection is ready.",
                source="hardware.dependencies",
            )
            return True

        requirements = BACKEND_DIR / "requirements-hardware.txt"
        self._log(
            "Installing PhiloEngine hardware detection dependency.",
            source="hardware.dependencies",
        )
        install = await asyncio.create_subprocess_exec(
            sys.executable,
            "-m",
            "pip",
            "install",
            "-r",
            str(requirements),
            cwd=str(BACKEND_DIR),
            stdin=asyncio.subprocess.DEVNULL,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, stderr = await install.communicate()
        if install.returncode != 0:
            self._log(
                "PhiloEngine hardware detection dependency could not be installed; "
                "the Go fallback remains active.",
                source="hardware.dependencies",
                level="WARN",
            )
            for line in stderr.decode(errors="replace").splitlines()[-8:]:
                if line.strip():
                    self._log(line, source="hardware.dependencies.stderr", level="WARN")
            return False
        self._log(
            "PhiloEngine hardware detection is ready.",
            source="hardware.dependencies",
        )
        return True

    def _configured_backend_ports(self) -> list[int]:
        ports: list[int] = []
        for env_name, fallback in (("HTTP_PORT", "8080"), ("GRPC_PORT", "50051")):
            raw = os.getenv(env_name, fallback).strip()
            try:
                port = int(raw)
            except ValueError:
                self._log(
                    f"Invalid {env_name}={raw!r}; skipping port check for this value.",
                    source="backend.ports",
                    level="WARN",
                )
                continue
            if port > 0:
                ports.append(port)

        deduped: list[int] = []
        seen: set[int] = set()
        for port in ports:
            if port in seen:
                continue
            seen.add(port)
            deduped.append(port)
        return deduped

    async def _ensure_backend_ports_free(self) -> bool:
        ports = self._configured_backend_ports()
        if not ports:
            return True

        self._log(f"Checking backend ports: {', '.join(str(p) for p in ports)}", source="backend.ports")
        for port in ports:
            pids = self._listener_pids_for_port(port)
            pids = [pid for pid in pids if not self._is_current_backend_pid(pid)]
            if not pids:
                continue

            self._log(
                f"Port {port} is in use by PID(s): {', '.join(str(pid) for pid in pids)}",
                source="backend.ports",
                level="WARN",
            )
            for pid in pids:
                if self._terminate_pid(pid):
                    self._log(f"Stop signal sent to PID {pid} for port {port}.", source="backend.ports")
                else:
                    self._log(
                        f"Failed to terminate PID {pid} for port {port}.",
                        source="backend.ports",
                        level="ERROR",
                    )

            self._log(
                "Warte, bis lokale Modelle sicher beendet und die Backend-Ports frei sind.",
                source="backend.ports",
            )
            deadline = asyncio.get_running_loop().time() + 40
            remaining = pids
            while remaining and asyncio.get_running_loop().time() < deadline:
                await asyncio.sleep(0.25)
                remaining = [pid for pid in self._listener_pids_for_port(port) if not self._is_current_backend_pid(pid)]
            if remaining:
                for pid in remaining:
                    self._kill_pid(pid)
                await asyncio.sleep(0.5)
                remaining = [pid for pid in self._listener_pids_for_port(port) if not self._is_current_backend_pid(pid)]
            if remaining:
                self._log(
                    f"Port {port} is still in use by PID(s): {', '.join(str(pid) for pid in remaining)}",
                    source="backend.ports",
                    level="ERROR",
                )
                return False

        return True

    def _is_current_backend_pid(self, pid: int) -> bool:
        if pid <= 0:
            return True
        if pid == os.getpid():
            return True
        if self.backend.process is not None and self.backend.process.pid == pid:
            return True
        return False

    def _recent_bind_conflict_detected(self) -> bool:
        recent = "\n".join(list(self.log_buffer)[-80:]).lower()
        if "bind:" not in recent:
            return False
        tokens = (
            "failed to listen",
            "address already in use",
            "normalerweise darf jede socketadresse",
        )
        return any(token in recent for token in tokens)

    def _listener_pids_for_port(self, port: int) -> list[int]:
        if port <= 0:
            return []

        pids: set[int] = set()
        if os.name == "nt":
            ps_pids = self._listener_pids_windows_powershell(port)
            if ps_pids:
                return ps_pids

            result = subprocess.run(
                ["netstat", "-ano", "-p", "TCP"],
                capture_output=True,
                text=True,
            )
            if result.returncode != 0:
                return []

            for raw_line in result.stdout.splitlines():
                line = raw_line.strip()
                if not line:
                    continue
                parts = line.split()
                if len(parts) < 5:
                    continue
                state = parts[3].upper()
                local_address = parts[1]
                if state not in {"LISTENING", "LISTEN", "ABHÖREN", "ABHOEREN"}:
                    continue
                if not local_address.endswith(f":{port}"):
                    continue
                try:
                    pids.add(int(parts[4]))
                except ValueError:
                    continue
            return sorted(pids)

        result = subprocess.run(
            ["lsof", "-nP", f"-iTCP:{port}", "-sTCP:LISTEN", "-t"],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0 and not result.stdout.strip():
            return []
        for raw_line in result.stdout.splitlines():
            line = raw_line.strip()
            if not line:
                continue
            try:
                pids.add(int(line))
            except ValueError:
                continue
        return sorted(pids)

    def _listener_pids_windows_powershell(self, port: int) -> list[int]:
        command = (
            "$ErrorActionPreference='SilentlyContinue'; "
            f"Get-NetTCPConnection -State Listen -LocalPort {port} | "
            "Select-Object -ExpandProperty OwningProcess"
        )
        result = subprocess.run(
            ["powershell", "-NoProfile", "-Command", command],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0 and not result.stdout.strip():
            return []

        pids: set[int] = set()
        for raw_line in result.stdout.splitlines():
            line = raw_line.strip()
            if not line:
                continue
            try:
                pids.add(int(line))
            except ValueError:
                continue
        return sorted(pids)

    def _terminate_pid(self, pid: int) -> bool:
        if self._is_current_backend_pid(pid):
            return False

        if os.name == "nt":
            result = subprocess.run(
                ["taskkill", "/PID", str(pid), "/T", "/F"],
                capture_output=True,
                text=True,
            )
            return result.returncode == 0

        try:
            os.kill(pid, signal.SIGTERM)
            return True
        except Exception:
            return False

    def _kill_pid(self, pid: int) -> bool:
        if self._is_current_backend_pid(pid):
            return False
        if os.name == "nt":
            result = subprocess.run(
                ["taskkill", "/PID", str(pid), "/T", "/F"],
                capture_output=True,
                text=True,
            )
            return result.returncode == 0
        try:
            os.kill(pid, signal.SIGKILL)
            return True
        except Exception:
            return False

    def _copy_logs_to_clipboard(self) -> None:
        text = "\n".join(self.log_buffer)
        if not text:
            self._log("No logs available to copy.", source="console.clipboard", level="WARN")
            return

        self.copy_to_clipboard(text)
        self._log("Logs copied to clipboard.", source="console.clipboard")

    def _update_status_widgets(self) -> None:
        try:
            self._update_status_widgets_unsafe()
        except Exception:
            pass

    def _update_status_widgets_unsafe(self) -> None:
        status_widget = self.query_one("#status-backend", Static)
        pid_widget = self.query_one("#status-pid", Static)
        log_widget = self.query_one("#status-log", Static)

        if self.backend.running and self.backend.process is not None:
            status_widget.update("Backend: running")
            pid_widget.update(f"Backend PID: {self.backend.process.pid}")
        else:
            status_widget.update("Backend: stopped")
            pid_widget.update("Backend PID: -")

        log_widget.update(f"Session log file: {self.current_log_file}")

        frontend_status_widget = self.query_one("#status-frontend", Static)
        frontend_pid_widget = self.query_one("#status-frontend-pid", Static)

        if self.frontend.running and self.frontend.process is not None:
            frontend_status_widget.update("Frontend: running")
            frontend_pid_widget.update(f"Frontend PID: {self.frontend.process.pid}")
        else:
            frontend_status_widget.update("Frontend: stopped")
            frontend_pid_widget.update("Frontend PID: -")

    def _build_session_log_name(self) -> str:
        timestamp = datetime.now().astimezone().strftime("%Y%m%d-%H%M%S")
        return f"dev-console-{timestamp}.log"

    def _close_log_file(self) -> None:
        if self.log_file_handle is not None:
            try:
                self.log_file_handle.flush()
                self.log_file_handle.close()
            except Exception:
                pass
            self.log_file_handle = None

    def _log(self, message: str, source: str = "console", level: str = "INFO") -> None:
        timestamp = datetime.now().astimezone().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
        formatted = f"{timestamp} | {level.upper():<5} | {source} | {message}"
        self.log_buffer.append(formatted)
        if self.log_file_handle is not None:
            try:
                self.log_file_handle.write(formatted + "\n")
                self.log_file_handle.flush()
            except Exception:
                pass

        try:
            self.query_one("#backend-log", RichLog).write(formatted)
        except Exception:
            pass

    async def _shutdown_stream_tasks(self, service: ManagedService) -> None:
        if not service.tasks:
            return

        for task in service.tasks:
            if not task.done():
                task.cancel()
        await asyncio.gather(*service.tasks, return_exceptions=True)
        service.tasks.clear()

    async def _shutdown_exit_task(self, service: ManagedService) -> None:
        task = service.exit_task
        if task is None:
            return

        if task is asyncio.current_task():
            service.exit_task = None
            return

        if not task.done():
            task.cancel()
        await asyncio.gather(task, return_exceptions=True)
        service.exit_task = None


def main() -> None:




    mouse_enabled = os.getenv("TUI_MOUSE", "1").strip().lower() not in ("0", "false", "no")
    BackendConsoleApp().run(mouse=mouse_enabled)


if __name__ == "__main__":
    main()
