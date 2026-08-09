from __future__ import annotations

import argparse
import asyncio
import os
import signal
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

_setup_go_path()

from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Button, DataTable, Footer, Header, Input, Label, RichLog, Static

BACKEND_DIR = Path(__file__).resolve().parent


@dataclass
class ManagedService:
    name: str
    cwd: Path
    command: list[str] = field(default_factory=list)
    process: asyncio.subprocess.Process | None = None
    tasks: list[asyncio.Task] = field(default_factory=list)
    exit_task: asyncio.Task | None = None
    stopping: bool = False

    @property
    def running(self) -> bool:
        return self.process is not None and self.process.returncode is None


class BackendConsoleApp(App):
    CSS = """
    Screen {
        layout: vertical;
        background: #111318;
    }

    #top {
        height: 24;
    }

    #services, #actions, #users {
        width: 1fr;
        height: 1fr;
        border: round #3f4c6b;
        background: #171a22;
        padding: 1;
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

    DataTable {
        height: 1fr;
        border: round #2c9f6d;
        background: #11161d;
    }

    Input {
        margin-bottom: 1;
    }

    Button {
        margin-bottom: 1;
    }
    """

    BINDINGS = [
        ("q", "request_exit", "Exit"),
    ]

    def __init__(self, accounts_file: str):
        super().__init__()
        self.accounts_file = accounts_file.strip() or "data/login_accounts.json"
        self.logs_dir = BACKEND_DIR / "logs"
        self.logs_dir.mkdir(parents=True, exist_ok=True)
        self.current_log_file = self.logs_dir / self._build_session_log_name()
        self.log_file_handle: TextIO | None = self.current_log_file.open("a", encoding="utf-8")

        self.backend = ManagedService(
            name="backend",
            cwd=BACKEND_DIR,
            command=["go", "run", "./cmd/server"],
        )

        self.log_buffer: deque[str] = deque(maxlen=5000)
        self.dependencies_ready = False

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Horizontal(id="top"):
            with Vertical(id="services"):
                yield Label("Service", classes="section-title")
                yield Static("Backend: stopped", id="status-backend")
                yield Static("PID: -", id="status-pid")
                yield Static(f"Backend path: {BACKEND_DIR}")
                yield Static(f"Accounts file: {self.accounts_file}", id="status-accounts")
                yield Static("Log file: -", id="status-log")
            with Vertical(id="actions"):
                yield Label("Actions", classes="section-title")
                yield Button("Start backend", id="start-backend")
                yield Button("Restart backend", id="restart-backend")
                yield Button("Stop backend", id="stop-backend")
                yield Button("Refresh status", id="refresh-status")
                yield Button("Copy logs", id="copy-logs")
                yield Button("Exit (stop backend)", variant="error", id="exit-all")
            with Vertical(id="users"):
                yield Label("User Admin", classes="section-title")
                yield Input(placeholder="Username", id="user-name")
                yield Input(placeholder="Password", password=True, id="user-password")
                yield Button("Create user", id="create-user")
                yield Input(placeholder="Delete username", id="delete-user-name")
                yield Button("Delete user", id="delete-user", variant="error")
                yield Button("List users", id="list-users")
                yield DataTable(id="users-table")
        with Vertical(id="logs"):
            yield Label("Backend Logs", classes="section-title")
            yield RichLog(id="backend-log", wrap=True, markup=False)
        yield Footer()

    async def on_mount(self) -> None:
        users_table = self.query_one("#users-table", DataTable)
        users_table.add_columns("Username")

        self._log("Dev console started.", source="console.lifecycle")
        self._log(f"Session log file: {self.current_log_file}", source="console.lifecycle")
        self._log(f"Console PID: {os.getpid()}", source="console.lifecycle")
        self._log(f"Backend directory: {BACKEND_DIR}", source="console.lifecycle")
        self._log(f"Accounts file: {self.accounts_file}", source="console.lifecycle")
        self._log(f"Backend command: {' '.join(self.backend.command)}", source="console.lifecycle")

        await self._ensure_go_dependencies()
        await self._refresh_users_table()
        self._update_status_widgets()

    def on_unmount(self) -> None:
        self._close_log_file()

    async def action_request_exit(self) -> None:
        await self._stop_backend()
        self.exit()

    async def on_button_pressed(self, event: Button.Pressed) -> None:
        button_id = event.button.id or ""

        if button_id == "start-backend":
            await self._start_backend()
        elif button_id == "restart-backend":
            await self._restart_backend()
        elif button_id == "stop-backend":
            await self._stop_backend()
        elif button_id == "create-user":
            await self._create_user_from_form()
        elif button_id == "delete-user":
            await self._delete_user_from_form()
        elif button_id == "list-users":
            await self._refresh_users_table()
        elif button_id == "refresh-status":
            self._update_status_widgets()
        elif button_id == "copy-logs":
            self._copy_logs_to_clipboard()
        elif button_id == "exit-all":
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
                asyncio.create_task(self._stream_output(process.stdout, "stdout")),
                asyncio.create_task(self._stream_output(process.stderr, "stderr")),
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
            await self._shutdown_stream_tasks()
            await self._shutdown_exit_task()
            self.backend.process = None
            await asyncio.sleep(0.8)

    async def _stop_backend(self) -> None:
        process = self.backend.process
        if process is None:
            await self._shutdown_stream_tasks()
            await self._shutdown_exit_task()
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

        await self._shutdown_stream_tasks()
        try:
            await asyncio.wait_for(process.communicate(), timeout=2)
        except Exception:
            pass

        await self._shutdown_exit_task()
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

    async def _restart_backend(self) -> None:
        await self._stop_backend()
        await self._start_backend()

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

    async def _stream_output(self, stream: asyncio.StreamReader | None, channel: str) -> None:
        if stream is None:
            return
        try:
            while True:
                line = await stream.readline()
                if not line:
                    break
                text = line.decode(errors="replace").rstrip()
                if text:
                    self._log(text, source=f"backend.{channel}")
        except asyncio.CancelledError:
            return

    async def _run_login_admin(self, *args: str) -> tuple[int, list[str]]:
        if not await self._ensure_go_dependencies():
            return 1, ["go dependencies are not ready"]

        process = await asyncio.create_subprocess_exec(
            "go",
            "run",
            "./cmd/login-admin",
            *args,
            "-accounts-file",
            self.accounts_file,
            cwd=str(BACKEND_DIR),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, stderr = await process.communicate()

        lines: list[str] = []
        out = stdout.decode(errors="replace").splitlines()
        err = stderr.decode(errors="replace").splitlines()
        lines.extend(out)
        lines.extend(err)
        if not lines:
            lines = ["(no output)"]
        return process.returncode or 0, lines

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

    async def _create_user_from_form(self) -> None:
        username_input = self.query_one("#user-name", Input)
        password_input = self.query_one("#user-password", Input)

        username = username_input.value.strip()
        password = password_input.value

        if not username or not password:
            self._log("Create user failed: username/password required.", source="users.admin", level="WARN")
            return

        code, lines = await self._run_login_admin(
            "-action",
            "create",
            "-username",
            username,
            "-password",
            password,
        )

        for line in lines:
            self._log(line, source="users.admin.command")

        if code == 0:
            self._log(f"User created: {username}", source="users.admin")
            password_input.value = ""
            await self._refresh_users_table()
        else:
            self._log("Create user failed.", source="users.admin", level="ERROR")

    async def _delete_user_from_form(self) -> None:
        delete_input = self.query_one("#delete-user-name", Input)
        username = delete_input.value.strip()

        if not username:
            self._log("Delete user failed: username required.", source="users.admin", level="WARN")
            return

        code, lines = await self._run_login_admin(
            "-action",
            "delete",
            "-username",
            username,
        )

        for line in lines:
            self._log(line, source="users.admin.command")

        if code == 0:
            self._log(f"User deleted: {username}", source="users.admin")
            delete_input.value = ""
            await self._refresh_users_table()
        else:
            self._log(f"Delete user failed for: {username}", source="users.admin", level="ERROR")

    async def _refresh_users_table(self) -> None:
        users_table = self.query_one("#users-table", DataTable)
        users_table.clear()

        code, lines = await self._run_login_admin("-action", "list")
        if code != 0:
            self._log("Load users failed.", source="users.admin", level="ERROR")
            for line in lines:
                self._log(line, source="users.admin.command", level="ERROR")
            return

        users = [line.strip() for line in lines if line.strip() and line.strip().lower() != "no users found"]
        if not users:
            self._log("No users found.", source="users.admin")
            return

        for username in users:
            users_table.add_row(username)

        self._log(f"Loaded users ({len(users)}).", source="users.admin")

    def _copy_logs_to_clipboard(self) -> None:
        text = "\n".join(self.log_buffer)
        if not text:
            self._log("No logs available to copy.", source="console.clipboard", level="WARN")
            return

        result = subprocess.run(["clip"], input=text, text=True, capture_output=True)
        if result.returncode == 0:
            self._log("Logs copied to clipboard.", source="console.clipboard")
        else:
            self._log("Clipboard write failed.", source="console.clipboard", level="ERROR")

    def _update_status_widgets(self) -> None:
        status_widget = self.query_one("#status-backend", Static)
        pid_widget = self.query_one("#status-pid", Static)
        log_widget = self.query_one("#status-log", Static)

        if self.backend.running and self.backend.process is not None:
            status_widget.update("Backend: running")
            pid_widget.update(f"PID: {self.backend.process.pid}")
        else:
            status_widget.update("Backend: stopped")
            pid_widget.update("PID: -")

        log_widget.update(f"Log file: {self.current_log_file}")

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

        self.query_one("#backend-log", RichLog).write(formatted)

    async def _shutdown_stream_tasks(self) -> None:
        if not self.backend.tasks:
            return

        for task in self.backend.tasks:
            if not task.done():
                task.cancel()
        await asyncio.gather(*self.backend.tasks, return_exceptions=True)
        self.backend.tasks.clear()

    async def _shutdown_exit_task(self) -> None:
        task = self.backend.exit_task
        if task is None:
            return

        if task is asyncio.current_task():
            self.backend.exit_task = None
            return

        if not task.done():
            task.cancel()
        await asyncio.gather(task, return_exceptions=True)
        self.backend.exit_task = None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="CulpeoStudio Dev Console")
    parser.add_argument(
        "--accounts-file",
        default=os.getenv("LOGIN_ACCOUNTS_FILE", "data/login_accounts.json"),
        help="Path to account file for login-admin.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    BackendConsoleApp(accounts_file=args.accounts_file).run()


if __name__ == "__main__":
    main()
