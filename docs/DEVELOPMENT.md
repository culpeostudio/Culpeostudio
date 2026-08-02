# Develop PhiloEngine

**English** · [Deutsch](../de/docs/DEVELOPMENT.md)

PhiloEngine combines a Flutter desktop client, a Go control plane, and Python
workers used by selected local-model and hardware features. This guide covers
the local development workflow; it does not describe the compiled end-user
installation.

[← README](../README.md) · [Installation](INSTALLATION.md) · [Contributing](../CONTRIBUTING.md)

## Development toolchain

| Tool | Current project baseline | Used for |
|---|---:|---|
| Go | 1.25+ | Backend, launcher, runtime supervision |
| Flutter | 3.44+ | Desktop frontend |
| Dart | 3.12+ | Frontend language and tooling |
| Python | 3.12 recommended | Developer console, workers, hardware probe, release scripts |
| Git | Current supported version | Source workflow and safe source updates |

Install the native Flutter desktop prerequisites for your operating system as
described in the Flutter documentation. Local llama.cpp builds can additionally
require CMake and C/C++ compilers. Accelerator-specific work requires the
matching GPU driver and SDK/toolchain.

## Repository map

```text
backend/
  cmd/server/             Go server entry point
  cmd/philo-updater/      source and compiled-bundle updater
  cmd/philosearch/        metasearch command-line client
  modules/                feature modules and HTTP routes
  internal/               shared runtime, memory, security, and update code
  engineworker/           Transformers worker and Python tests
  sidecar/                source-only ONNX memory-embedding service
  tools/                  hardware probe and data-maintenance tools
  proto/                  protocol definitions and generated Go code
frontend/
  lib/screens/            product screens grouped by feature
  lib/services/           backend client and transport handling
  lib/state/              application state
  lib/l10n/               German and English UI strings
  lib/theme/              shared visual system
  test/                   Flutter widget and unit tests
  integration_test/       desktop integration tests
quikinstall/
  build_release.py        platform release builder
  merge_manifests.py      release-manifest merger
  manifest.json           published update manifest
  tests/                  release tooling tests
docs/
  screenshots/            public product imagery
```

Runtime state, credentials, models, chats, and memory data live under
`backend/data/` in a normal source run. Quickinstall instead keeps persistent
state under `<install-root>/backend/data/`, outside its versioned application
bundles. These directories are not source material. The repository's
`backend/data/` is ignored by Git; never copy either data directory into
fixtures, commits, issue reports, or screenshots.

## Run the application

### Recommended supervised start

On Linux, prepare the development console once:

```bash
cd /path/to/philoengine
python3 -m venv backend/.venv
backend/.venv/bin/python -m pip install textual
./start.sh
```

`start.sh` opens the development console and manages backend and frontend in
the intended order. While working on a branch, use
`PHILOENGINE_SKIP_UPDATE=1 ./start.sh` to avoid an unnecessary update check.
The updater already refuses dirty worktrees and branches other than `main`.
The development console currently launches `flutter run -d linux`; use the
manual commands below for Windows, macOS, or another Flutter target.

### Manual layer-by-layer start

For focused diagnostics, start the backend from `backend/`:

```bash
cd backend
go run ./cmd/server
```

The default HTTP endpoint is `http://127.0.0.1:8080`. A parallel gRPC listener
uses the same loopback host; most application traffic uses HTTP and SSE.

Start the frontend in another terminal:

```bash
cd frontend
flutter pub get
flutter run -d linux
```

Use `windows` or `macos` instead of `linux` on those desktop hosts.

### Optional ONNX memory sidecar

The ONNX embedding sidecar is a manual, source-only component. It is not
started by `start.sh` and is not part of the Quickinstall payload. To develop it, create its own environment, install its dependencies,
and download the model from Hugging Face:

```bash
cd /path/to/philoengine/backend/sidecar
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
.venv/bin/python download_model.py
.venv/bin/python main.py
```

It binds to `127.0.0.1:8092`. Start the main application in another terminal
with `MEMORY_EMBEDDING_BACKEND=onnx_local ./start.sh`. If the sidecar is absent
or unhealthy, Memory deliberately falls back to deterministic hash embeddings.

## Verify changes

Run checks that cover the code you changed. The commands below are the local
project checks; do not assume that an unlisted hosted CI job will run them for
you.

### Go backend

```bash
cd backend
go test ./...
go build ./cmd/server
go build ./cmd/philo-updater
```

Format changed Go files with `gofmt` before testing.

### Flutter frontend

```bash
cd frontend
flutter analyze
flutter test
```

Run the desktop integration suite on a host with a working Flutter desktop
target and graphical session:

```bash
cd frontend
flutter test integration_test/ -d linux
```

Substitute the local desktop target where appropriate. Format changed Dart
files with `dart format` before analysis.

### Python workers and release tooling

```bash
python3 -m unittest discover -s backend/engineworker -p 'test_*.py' -v
python3 -m unittest discover -s quikinstall/tests -v
python3 -m py_compile \
  backend/engineworker/transformers_worker.py \
  backend/tools/philoengine_hardware_probe.py \
  quikinstall/build_release.py \
  quikinstall/merge_manifests.py
```

Run these commands from the repository root.

### Documentation-only changes

Check local links, heading order, code fences, image paths, and rendering on
both light and dark GitHub themes. Keep volatile values—such as leaderboard
counts and current release numbers—out of prose unless they are generated or
updated as part of the same release process.

## Build desktop artifacts

> [!WARNING]
> The current release workflow builds archives but does not run the Go,
> Flutter, or Python test suites and does not code-sign or notarize the produced
> binaries. Run the checks above before creating a tag. SHA-256 values in the
> update manifest are integrity metadata, not a publisher signature.

Backend binaries can be built directly:

```bash
cd backend
go build ./cmd/server
go build ./cmd/philo-updater
```

Flutter desktop bundles must be built on the target operating system:

```bash
cd frontend
flutter build linux --release
```

Use `windows` or `macos` on the matching host. The release workflow currently
builds Linux x64, Windows x64, and macOS ARM64 on native runners. For the full
archive and manifest process, see `quikinstall/README.md` in the repository.

A development checkout can be ahead of the published package. Before
documenting or capturing a release, compare the screens and routes against the
exact tag that will be published.

## Architecture and coding boundaries

- Keep feature routing and orchestration in the Go backend; Python workers are
  supervised runtime components, not a second application backend.
- Keep business logic out of large Flutter widget trees. Reuse services,
  state, shared widgets, and localized strings.
- Use the PhiloGrid conventions for card and matrix layouts: adaptive columns,
  reusable cells, 12/16 px container padding, and 8/12 px grid gaps.
- Preserve loopback defaults. A change that exposes a service beyond the local
  machine needs an explicit security review and documentation update.
- Do not log provider keys, session secrets, bearer tokens, or model-download
  credentials.
- Treat assistant file access, command execution, archive extraction, and
  updater activation as security-sensitive boundaries.

Before submitting work, review the [contribution guide](../CONTRIBUTING.md).
