#!/usr/bin/env python3
"""Build reproducible PhiloEngine update and first-install archives.

The script intentionally uses only Python's standard library so a release host
does not need project-specific Python packages.
"""

from __future__ import annotations

import argparse
import copy
import gzip
import hashlib
import json
import os
import platform
import re
import shlex
import shutil
import stat
import subprocess
import sys
import tarfile
import tempfile
import zipfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Mapping, Sequence
from urllib.parse import quote


SCHEMA_VERSION = 1
DEFAULT_HEALTH_URL = "http://127.0.0.1:8080/health"
DEFAULT_DOWNLOAD_BASE_URL = (
    "https://raw.githubusercontent.com/kuchenboss/MyPhiloEngine/"
    "main/quikinstall/releases/{version}"
)
SEMVER_PATTERN = re.compile(
    r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
    r"(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?"
    r"(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$"
)
RFC3339_PATTERN = re.compile(
    r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}"
    r"(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$"
)

QUIKINSTALL_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = QUIKINSTALL_DIR.parent


class ReleaseBuildError(RuntimeError):
    """A release cannot be built without operator action."""


@dataclass(frozen=True)
class TargetSpec:
    """Platform-specific artifact and archive conventions."""

    key: str
    goos: str
    goarch: str
    flutter_platform: str
    archive_format: str
    backend_name: str
    launcher_name: str
    frontend_entrypoint: str
    flutter_output: str

    @property
    def extension(self) -> str:
        return ".tar.gz" if self.archive_format == "tar.gz" else ".zip"


TARGETS: dict[str, TargetSpec] = {
    "linux-x64": TargetSpec(
        key="linux-x64",
        goos="linux",
        goarch="amd64",
        flutter_platform="linux",
        archive_format="tar.gz",
        backend_name="philoengine-server",
        launcher_name="myphiloengine",
        frontend_entrypoint="myphilostudio",
        flutter_output="build/linux/x64/release/bundle",
    ),
    "windows-x64": TargetSpec(
        key="windows-x64",
        goos="windows",
        goarch="amd64",
        flutter_platform="windows",
        archive_format="zip",
        backend_name="philoengine-server.exe",
        launcher_name="myphiloengine.exe",
        frontend_entrypoint="myphilostudio.exe",
        flutter_output="build/windows/x64/runner/Release",
    ),
    "macos-x64": TargetSpec(
        key="macos-x64",
        goos="darwin",
        goarch="amd64",
        flutter_platform="macos",
        archive_format="tar.gz",
        backend_name="philoengine-server",
        launcher_name="myphiloengine",
        frontend_entrypoint="myphilostudio.app/Contents/MacOS/myphilostudio",
        flutter_output="build/macos/Build/Products/Release/myphilostudio.app",
    ),
    "macos-arm64": TargetSpec(
        key="macos-arm64",
        goos="darwin",
        goarch="arm64",
        flutter_platform="macos",
        archive_format="tar.gz",
        backend_name="philoengine-server",
        launcher_name="myphiloengine",
        frontend_entrypoint="myphilostudio.app/Contents/MacOS/myphilostudio",
        flutter_output="build/macos/Build/Products/Release/myphilostudio.app",
    ),
}
# Each entry lists the accepted names of one required backend runtime file. The
# hardware probe has two: it was renamed from whichllm_ to philoengine_, and the
# launcher looks for either name, so a release can be built from a checkout on
# either side of that rename.
BACKEND_RUNTIME_FILES = (
    ("engineworker/transformers_worker.py",),
    (
        "tools/philoengine_hardware_probe.py",
        "tools/whichllm_hardware_probe.py",
    ),
    ("requirements-hardware.txt",),
)
RELEASE_LEGAL_FILES = (
    "LICENSE",
    "NOTICE",
    "THIRD_PARTY_NOTICES.md",
    "licenses/whichllm-MIT.txt",
)


def target_for_host(system_name: str, machine_name: str) -> str:
    """Map Python host identifiers to one supported release target."""

    system_key = system_name.strip().lower()
    machine_key = machine_name.strip().lower()
    x64_names = {"x86_64", "amd64", "x64"}
    arm64_names = {"arm64", "aarch64"}

    if system_key == "linux" and machine_key in x64_names:
        return "linux-x64"
    if system_key == "windows" and machine_key in x64_names:
        return "windows-x64"
    if system_key in {"darwin", "macos"} and machine_key in x64_names:
        return "macos-x64"
    if system_key in {"darwin", "macos"} and machine_key in arm64_names:
        return "macos-arm64"
    raise ValueError(
        f"Unsupported release host: system={system_name!r}, "
        f"machine={machine_name!r}"
    )


def validate_version(version: str) -> str:
    """Validate a path-safe Semantic Version without a leading ``v``."""

    if not SEMVER_PATTERN.fullmatch(version):
        raise ValueError(
            f"Invalid version {version!r}; expected SemVer such as 1.2.3 "
            "without a leading 'v'"
        )
    return version


def validate_rfc3339(timestamp: str) -> str:
    """Validate an RFC 3339 timestamp and return it unchanged."""

    if not RFC3339_PATTERN.fullmatch(timestamp):
        raise ValueError(f"Invalid RFC 3339 timestamp: {timestamp!r}")
    candidate = timestamp[:-1] + "+00:00" if timestamp.endswith("Z") else timestamp
    try:
        parsed = datetime.fromisoformat(candidate)
    except ValueError as error:
        raise ValueError(f"Invalid RFC 3339 timestamp: {timestamp!r}") from error
    if parsed.tzinfo is None:
        raise ValueError(f"RFC 3339 timestamp needs a timezone: {timestamp!r}")
    return timestamp


def utc_timestamp(now: datetime | None = None) -> str:
    """Return a seconds-precision UTC RFC 3339 timestamp."""

    current = now or datetime.now(timezone.utc)
    current = current.astimezone(timezone.utc).replace(microsecond=0)
    return current.isoformat().replace("+00:00", "Z")


def release_timestamp(
    manifest: Mapping[str, Any],
    version: str,
    explicit_timestamp: str | None,
    now_factory: Callable[[], str] = utc_timestamp,
) -> str:
    """Keep one publication timestamp while adding platforms to a release."""

    if explicit_timestamp is not None:
        return validate_rfc3339(explicit_timestamp)
    previous = manifest.get("published_at")
    if manifest.get("version") == version and isinstance(previous, str) and previous:
        return validate_rfc3339(previous)
    return now_factory()


def build_state(version: str, asset_sha256: str, updated_at: str) -> dict[str, Any]:
    """Create the on-disk state shared by current.json and bundle metadata."""

    validate_version(version)
    if not re.fullmatch(r"[0-9a-f]{64}", asset_sha256):
        raise ValueError("asset_sha256 must be a lowercase 64-character SHA-256")
    validate_rfc3339(updated_at)
    bundle = f"versions/{version}-{asset_sha256[:12]}"
    return {
        "schema_version": SCHEMA_VERSION,
        "version": version,
        "bundle": bundle,
        "asset_sha256": asset_sha256,
        "updated_at": updated_at,
    }


def bundle_metadata(
    state: Mapping[str, Any],
    asset: Mapping[str, Any],
) -> dict[str, Any]:
    """Add launch configuration to the state stored inside an installed bundle."""

    metadata = copy.deepcopy(dict(state))
    metadata["asset"] = copy.deepcopy(dict(asset))
    return metadata


def download_url(base_url: str, version: str, filename: str) -> str:
    """Render an immutable asset URL from a configurable base."""

    validate_version(version)
    try:
        rendered_base = base_url.format(
            version=version,
            tag=f"v{version}",
        ).rstrip("/")
    except (KeyError, ValueError) as error:
        raise ValueError(
            "base URL may only use the placeholders {version} and {tag}"
        ) from error
    return f"{rendered_base}/{quote(filename)}"


def asset_entry(
    target: TargetSpec,
    url: str,
    sha256: str,
    size: int,
) -> dict[str, Any]:
    """Create the exact schema consumed by the Go updater."""

    if not re.fullmatch(r"[0-9a-f]{64}", sha256):
        raise ValueError("sha256 must be a lowercase 64-character SHA-256")
    if size <= 0:
        raise ValueError("size must be greater than zero")
    return {
        "url": url,
        "sha256": sha256,
        "size": size,
        "format": target.archive_format,
        "launcher": {
            "path": f"launcher/{target.launcher_name}",
            "args": [],
        },
        "backend": {
            "path": f"backend/{target.backend_name}",
            "args": [],
        },
        "frontend": {
            "path": f"frontend/{target.frontend_entrypoint}",
            "args": [],
        },
        "health_url": DEFAULT_HEALTH_URL,
    }


def resolve_backend_runtime_files(project_root: Path = PROJECT_ROOT) -> tuple[str, ...]:
    """Pick the name each required backend runtime file carries in this checkout."""

    resolved: list[str] = []
    for alternatives in BACKEND_RUNTIME_FILES:
        for relative_path in alternatives:
            if (project_root / "backend" / relative_path).is_file():
                resolved.append(relative_path)
                break
        else:
            expected = " or ".join(f"backend/{name}" for name in alternatives)
            raise ReleaseBuildError(
                f"Required backend runtime file is missing: {expected}"
            )
    return tuple(resolved)


def backend_payload_paths(
    target: TargetSpec, project_root: Path = PROJECT_ROOT
) -> tuple[str, ...]:
    """List backend files that must be present in every update payload."""

    return (
        f"backend/{target.backend_name}",
        *(
            f"backend/{path}"
            for path in resolve_backend_runtime_files(project_root)
        ),
    )


def legal_payload_paths() -> tuple[str, ...]:
    """List legal notices that must accompany every binary distribution."""

    return RELEASE_LEGAL_FILES


def updated_manifest(
    manifest: Mapping[str, Any],
    version: str,
    published_at: str,
    target_key: str,
    asset: Mapping[str, Any],
) -> dict[str, Any]:
    """Return a new latest-release manifest with one target updated."""

    validate_version(version)
    validate_rfc3339(published_at)
    if target_key not in TARGETS:
        raise ValueError(f"Unsupported target: {target_key}")
    schema = manifest.get("schema_version", SCHEMA_VERSION)
    if schema != SCHEMA_VERSION:
        raise ValueError(
            f"Unsupported manifest schema_version {schema!r}; "
            f"expected {SCHEMA_VERSION}"
        )

    existing_assets = manifest.get("assets", {})
    if not isinstance(existing_assets, Mapping):
        raise ValueError("manifest assets must be an object")
    assets: dict[str, Any] = {}
    if manifest.get("version") == version:
        assets = copy.deepcopy(dict(existing_assets))
    assets[target_key] = copy.deepcopy(dict(asset))
    return {
        "schema_version": SCHEMA_VERSION,
        "version": version,
        "published_at": published_at,
        "assets": assets,
    }


def sha256_and_size(path: Path) -> tuple[str, int]:
    """Stream a file once and return its SHA-256 plus byte size."""

    digest = hashlib.sha256()
    size = 0
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
            size += len(chunk)
    return digest.hexdigest(), size


def load_manifest(path: Path) -> dict[str, Any]:
    if not path.is_file():
        raise ReleaseBuildError(f"Manifest does not exist: {path}")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ReleaseBuildError(f"Cannot read manifest {path}: {error}") from error
    if not isinstance(value, dict):
        raise ReleaseBuildError(f"Manifest root must be an object: {path}")
    return value


def write_json_atomic(path: Path, value: Mapping[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.tmp")
    temporary.write_text(
        json.dumps(value, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    os.replace(temporary, path)


def _archive_paths(source_root: Path) -> list[Path]:
    return sorted(
        source_root.rglob("*"),
        key=lambda path: path.relative_to(source_root).as_posix(),
    )


def _canonical_tar_info(info: tarfile.TarInfo) -> tarfile.TarInfo:
    info.uid = 0
    info.gid = 0
    info.uname = ""
    info.gname = ""
    info.mtime = 0
    return info


def _create_tar_gz(source_root: Path, destination: Path) -> None:
    with destination.open("wb") as raw_output:
        with gzip.GzipFile(
            filename="",
            mode="wb",
            fileobj=raw_output,
            compresslevel=9,
            mtime=0,
        ) as compressed:
            with tarfile.open(fileobj=compressed, mode="w") as archive:
                for path in _archive_paths(source_root):
                    relative = path.relative_to(source_root).as_posix()
                    info = _canonical_tar_info(
                        archive.gettarinfo(str(path), arcname=relative)
                    )
                    if info.isreg():
                        with path.open("rb") as source:
                            archive.addfile(info, source)
                    else:
                        archive.addfile(info)


def _create_zip(source_root: Path, destination: Path) -> None:
    with zipfile.ZipFile(
        destination,
        mode="w",
        compression=zipfile.ZIP_DEFLATED,
        compresslevel=9,
    ) as archive:
        for path in _archive_paths(source_root):
            if path.is_symlink():
                raise ReleaseBuildError(
                    f"Windows ZIP payload cannot contain a symlink: {path}"
                )
            relative = path.relative_to(source_root).as_posix()
            archive_name = f"{relative}/" if path.is_dir() else relative
            info = zipfile.ZipInfo(archive_name, date_time=(1980, 1, 1, 0, 0, 0))
            info.create_system = 3
            mode = path.stat().st_mode
            info.external_attr = (mode & 0xFFFF) << 16
            if path.is_dir():
                info.external_attr |= 0x10
                archive.writestr(info, b"")
            else:
                info.compress_type = zipfile.ZIP_DEFLATED
                with path.open("rb") as source:
                    with archive.open(info, mode="w") as archived_file:
                        shutil.copyfileobj(
                            source,
                            archived_file,
                            length=1024 * 1024,
                        )


def create_archive(
    source_root: Path,
    destination: Path,
    archive_format: str,
) -> None:
    """Archive the contents of source_root without an extra top directory."""

    if archive_format not in {"tar.gz", "zip"}:
        raise ReleaseBuildError(f"Unsupported archive format: {archive_format}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_name(f".{destination.name}.tmp")
    if temporary.exists():
        temporary.unlink()
    try:
        if archive_format == "tar.gz":
            _create_tar_gz(source_root, temporary)
        else:
            _create_zip(source_root, temporary)
        os.replace(temporary, destination)
    finally:
        if temporary.exists():
            temporary.unlink()


def _run(command: Sequence[str], cwd: Path, env: Mapping[str, str] | None = None) -> None:
    print(f"+ {shlex.join(command)}", file=sys.stderr)
    # Windows ships flutter as flutter.bat, and the bare name never resolves
    # because CreateProcess does not search PATHEXT. shutil.which does, and
    # CreateProcess runs a .bat once it is given the full name.
    executable = shutil.which(
        command[0], path=None if env is None else env.get("PATH")
    )
    if executable is None:
        raise ReleaseBuildError(f"Required build tool not found: {command[0]}")
    try:
        subprocess.run(
            [executable, *command[1:]],
            cwd=cwd,
            env=dict(env) if env is not None else None,
            check=True,
        )
    except FileNotFoundError as error:
        raise ReleaseBuildError(f"Required build tool not found: {command[0]}") from error
    except subprocess.CalledProcessError as error:
        raise ReleaseBuildError(
            f"Build command failed with exit code {error.returncode}: "
            f"{shlex.join(command)}"
        ) from error


def _go_environment(target: TargetSpec) -> dict[str, str]:
    environment = os.environ.copy()
    environment["GOOS"] = target.goos
    environment["GOARCH"] = target.goarch
    return environment


def _build_backend(destination: Path, target: TargetSpec) -> None:
    _run(
        [
            "go",
            "build",
            "-trimpath",
            "-ldflags",
            "-s -w",
            "-o",
            str(destination),
            "./cmd/server",
        ],
        cwd=PROJECT_ROOT / "backend",
        env=_go_environment(target),
    )


def _build_launcher(destination: Path, target: TargetSpec, version: str) -> None:
    source = PROJECT_ROOT / "backend" / "cmd" / "philo-updater"
    if not source.is_dir():
        raise ReleaseBuildError(
            "Launcher source is missing at backend/cmd/philo-updater. "
            "Provide --launcher-artifact or add the updater source."
        )
    _run(
        [
            "go",
            "build",
            "-trimpath",
            "-ldflags",
            f"-s -w -X main.launcherVersion={version}",
            "-o",
            str(destination),
            "./cmd/philo-updater",
        ],
        cwd=PROJECT_ROOT / "backend",
        env=_go_environment(target),
    )


def _host_matches(target: TargetSpec) -> bool:
    try:
        return target_for_host(platform.system(), platform.machine()) == target.key
    except ValueError:
        return False


def _build_frontend(target: TargetSpec, version: str) -> Path:
    if not _host_matches(target):
        raise ReleaseBuildError(
            f"Flutter desktop builds are host-specific. Build {target.key} on "
            "that platform and pass its bundle with --frontend-artifact."
        )
    _run(
        [
            "flutter",
            "build",
            target.flutter_platform,
            "--release",
            "--build-name",
            version,
        ],
        cwd=PROJECT_ROOT / "frontend",
    )
    result = PROJECT_ROOT / "frontend" / target.flutter_output
    if not result.exists():
        raise ReleaseBuildError(f"Flutter reported success but output is missing: {result}")
    return result


def _first_existing(candidates: Sequence[Path]) -> Path | None:
    return next((candidate for candidate in candidates if candidate.exists()), None)


def _backend_candidates(target: TargetSpec) -> list[Path]:
    candidates = [
        QUIKINSTALL_DIR / "artifacts" / target.key / "backend" / target.backend_name,
        PROJECT_ROOT / "backend" / "build" / target.key / target.backend_name,
    ]
    if _host_matches(target):
        candidates.extend(
            [
                PROJECT_ROOT / "backend" / target.backend_name,
                PROJECT_ROOT
                / "backend"
                / ("server.exe" if target.goos == "windows" else "server"),
            ]
        )
    return candidates


def _launcher_candidates(target: TargetSpec) -> list[Path]:
    candidates = [
        QUIKINSTALL_DIR / "artifacts" / target.key / target.launcher_name,
        PROJECT_ROOT / "backend" / "build" / target.key / target.launcher_name,
    ]
    if _host_matches(target):
        candidates.append(PROJECT_ROOT / "backend" / target.launcher_name)
    return candidates


def _frontend_candidates(target: TargetSpec) -> list[Path]:
    return [
        QUIKINSTALL_DIR / "artifacts" / target.key / "frontend",
        PROJECT_ROOT / "frontend" / target.flutter_output,
    ]


def _copy_file(source: Path, destination: Path, executable: bool = False) -> None:
    if not source.is_file():
        raise ReleaseBuildError(f"Expected a file artifact: {source}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    if executable and os.name != "nt":
        destination.chmod(destination.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP)


def _copy_frontend(source: Path, destination: Path, target: TargetSpec) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    if source.is_file():
        _copy_file(source, destination / Path(target.frontend_entrypoint).name, True)
    elif source.is_dir() and source.suffix == ".app":
        shutil.copytree(
            source,
            destination / "myphilostudio.app",
            symlinks=True,
        )
    elif source.is_dir():
        shutil.copytree(
            source,
            destination,
            dirs_exist_ok=True,
            symlinks=True,
        )
    else:
        raise ReleaseBuildError(f"Frontend artifact does not exist: {source}")

    entrypoint = destination / target.frontend_entrypoint
    if not entrypoint.is_file():
        raise ReleaseBuildError(
            f"Frontend bundle is missing required entrypoint "
            f"{target.frontend_entrypoint}: {source}"
        )
    if os.name != "nt":
        entrypoint.chmod(entrypoint.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP)


def _resolve_backend(
    explicit: Path | None,
    destination: Path,
    target: TargetSpec,
    build_missing: bool,
) -> None:
    if explicit is not None:
        _copy_file(explicit, destination, executable=True)
    elif build_missing:
        destination.parent.mkdir(parents=True, exist_ok=True)
        _build_backend(destination, target)
    else:
        source = _first_existing(_backend_candidates(target))
        if source is None:
            raise ReleaseBuildError(
                f"No backend artifact found for {target.key}; "
                "pass --backend-artifact"
            )
        _copy_file(source, destination, executable=True)


def _copy_backend_runtime_files(backend_destination: Path) -> None:
    for relative_path in resolve_backend_runtime_files():
        _copy_file(
            PROJECT_ROOT / "backend" / relative_path,
            backend_destination / relative_path,
        )


def _copy_legal_files(destination: Path) -> None:
    for relative_path in RELEASE_LEGAL_FILES:
        source = PROJECT_ROOT / relative_path
        if not source.is_file():
            raise ReleaseBuildError(f"Required legal file is missing: {source}")
        _copy_file(source, destination / relative_path)


def _resolve_launcher(
    explicit: Path | None,
    destination: Path,
    target: TargetSpec,
    version: str,
    build_missing: bool,
) -> None:
    if explicit is not None:
        _copy_file(explicit, destination, executable=True)
    elif build_missing:
        destination.parent.mkdir(parents=True, exist_ok=True)
        _build_launcher(destination, target, version)
    else:
        source = _first_existing(_launcher_candidates(target))
        if source is None:
            raise ReleaseBuildError(
                f"No launcher artifact found for {target.key}; "
                "pass --launcher-artifact"
            )
        _copy_file(source, destination, executable=True)


def _resolve_frontend(
    explicit: Path | None,
    destination: Path,
    target: TargetSpec,
    version: str,
    build_missing: bool,
) -> None:
    source = explicit
    if source is None and build_missing:
        source = _build_frontend(target, version)
    elif source is None:
        source = _first_existing(_frontend_candidates(target))
    if source is None:
        raise ReleaseBuildError(
            f"No frontend artifact found for {target.key}; pass --frontend-artifact"
        )
    _copy_frontend(source, destination, target)


def _ensure_available(paths: Sequence[Path], force: bool) -> None:
    existing = [str(path) for path in paths if path.exists()]
    if existing and not force:
        joined = "\n  ".join(existing)
        raise ReleaseBuildError(
            "Refusing to overwrite release output. Use --force only before "
            f"publishing:\n  {joined}"
        )


@dataclass(frozen=True)
class BuildArguments:
    version: str
    target: TargetSpec
    manifest_path: Path
    output_dir: Path
    base_url: str
    published_at: str | None
    backend_artifact: Path | None
    frontend_artifact: Path | None
    launcher_artifact: Path | None
    build_missing: bool
    force: bool


def build_release(arguments: BuildArguments) -> dict[str, Any]:
    """Build both archives, then atomically publish state and manifest JSON."""

    version = validate_version(arguments.version)
    target = arguments.target
    manifest = load_manifest(arguments.manifest_path)
    published_at = release_timestamp(manifest, version, arguments.published_at)

    update_name = f"myphiloengine-{version}-{target.key}{target.extension}"
    installer_name = (
        f"myphiloengine-{version}-{target.key}-quickinstall{target.extension}"
    )
    update_path = arguments.output_dir / update_name
    installer_path = arguments.output_dir / installer_name
    state_path = arguments.output_dir / f"current-{target.key}.json"
    _ensure_available([update_path, installer_path, state_path], arguments.force)

    arguments.output_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(
        prefix=".philoengine-release-",
        dir=arguments.output_dir,
    ) as temporary_name:
        temporary = Path(temporary_name)
        payload = temporary / "payload"
        staged_update = temporary / update_name
        staged_installer = temporary / installer_name
        backend_destination = payload / "backend" / target.backend_name
        frontend_destination = payload / "frontend"
        launcher_destination = payload / "launcher" / target.launcher_name

        _resolve_backend(
            arguments.backend_artifact,
            backend_destination,
            target,
            arguments.build_missing,
        )
        _copy_backend_runtime_files(payload / "backend")
        _resolve_launcher(
            arguments.launcher_artifact,
            launcher_destination,
            target,
            version,
            arguments.build_missing,
        )
        _resolve_frontend(
            arguments.frontend_artifact,
            frontend_destination,
            target,
            version,
            arguments.build_missing,
        )
        _copy_legal_files(payload)
        create_archive(payload, staged_update, target.archive_format)
        update_sha256, update_size = sha256_and_size(staged_update)

        state = build_state(version, update_sha256, published_at)
        url = download_url(arguments.base_url, version, update_name)
        asset = asset_entry(target, url, update_sha256, update_size)
        installer_root = temporary / "installer"
        bundle_path = installer_root / state["bundle"]
        shutil.copytree(payload, bundle_path, symlinks=True)
        write_json_atomic(
            bundle_path / ".philoengine-bundle.json",
            bundle_metadata(state, asset),
        )
        write_json_atomic(installer_root / "current.json", state)
        _copy_file(
            launcher_destination,
            installer_root / target.launcher_name,
            executable=True,
        )
        _copy_legal_files(installer_root)
        create_archive(installer_root, staged_installer, target.archive_format)
        installer_sha256, installer_size = sha256_and_size(staged_installer)
        os.replace(staged_update, update_path)
        os.replace(staged_installer, installer_path)

    next_manifest = updated_manifest(
        manifest,
        version,
        published_at,
        target.key,
        asset,
    )
    write_json_atomic(state_path, state)
    write_json_atomic(arguments.manifest_path, next_manifest)
    return {
        "target": target.key,
        "version": version,
        "update_archive": str(update_path),
        "update_sha256": update_sha256,
        "update_size": update_size,
        "quickinstall_archive": str(installer_path),
        "quickinstall_sha256": installer_sha256,
        "quickinstall_size": installer_size,
        "state": str(state_path),
        "manifest": str(arguments.manifest_path),
    }


def _path_or_none(value: str | None) -> Path | None:
    return Path(value).expanduser().resolve() if value else None


def parse_arguments(argv: Sequence[str] | None = None) -> BuildArguments:
    try:
        host_target = target_for_host(platform.system(), platform.machine())
    except ValueError:
        host_target = "linux-x64"

    parser = argparse.ArgumentParser(
        description=(
            "Build a PhiloEngine update archive and a self-updating first-install "
            "archive for one platform."
        )
    )
    parser.add_argument("--version", required=True, help="Semantic version, e.g. 1.2.3")
    parser.add_argument(
        "--target",
        choices=sorted(TARGETS),
        default=host_target,
        help=f"release target (host default: {host_target})",
    )
    parser.add_argument(
        "--manifest",
        default=str(QUIKINSTALL_DIR / "manifest.json"),
        help="latest-release manifest to update",
    )
    parser.add_argument(
        "--output-dir",
        help="archive directory (default: quikinstall/releases/<version>)",
    )
    parser.add_argument(
        "--base-url",
        default=DEFAULT_DOWNLOAD_BASE_URL,
        help="asset URL prefix; supports {version} and {tag}",
    )
    parser.add_argument(
        "--published-at",
        help="RFC 3339 release time (default: now, or existing time for same version)",
    )
    parser.add_argument("--backend-artifact", help="existing Go server binary")
    parser.add_argument("--frontend-artifact", help="existing Flutter release bundle")
    parser.add_argument("--launcher-artifact", help="existing updater launcher binary")
    parser.add_argument(
        "--no-build-missing",
        action="store_true",
        help="fail instead of building missing artifacts",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="overwrite local archives; never overwrite already published assets",
    )
    namespace = parser.parse_args(argv)

    try:
        version = validate_version(namespace.version)
        if namespace.published_at:
            validate_rfc3339(namespace.published_at)
    except ValueError as error:
        parser.error(str(error))
    output_dir = (
        Path(namespace.output_dir).expanduser().resolve()
        if namespace.output_dir
        else QUIKINSTALL_DIR / "releases" / version
    )
    return BuildArguments(
        version=version,
        target=TARGETS[namespace.target],
        manifest_path=Path(namespace.manifest).expanduser().resolve(),
        output_dir=output_dir,
        base_url=namespace.base_url,
        published_at=namespace.published_at,
        backend_artifact=_path_or_none(namespace.backend_artifact),
        frontend_artifact=_path_or_none(namespace.frontend_artifact),
        launcher_artifact=_path_or_none(namespace.launcher_artifact),
        build_missing=not namespace.no_build_missing,
        force=namespace.force,
    )


def main(argv: Sequence[str] | None = None) -> int:
    try:
        result = build_release(parse_arguments(argv))
    except (OSError, ReleaseBuildError, ValueError) as error:
        print(f"release build failed: {error}", file=sys.stderr)
        return 1
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
