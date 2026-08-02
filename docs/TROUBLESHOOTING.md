# Troubleshooting PhiloEngine

**English** · [Deutsch](../de/docs/TROUBLESHOOTING.md)

> [!NOTE]
> PhiloEngine is alpha software. Diagnose the failing layer first—client, HTTP API, runtime installer, model worker, external source, or updater—because a healthy UI does not prove that every optional service is available.

[← README](../README.md) · [Architecture](ARCHITECTURE.md) · [Privacy](PRIVACY.md)

## Two-minute triage

Run these from the PhiloEngine repository unless a command says otherwise:

```bash
cd /path/to/philoengine
git status --short
go version
flutter --version
python3 --version
curl -fsS http://127.0.0.1:8080/health
```

Then check the local listeners:

```bash
ss -ltnp | rg ':8080|:50051|:8091|:8092'
```

On systems without `ss`, use the platform's socket viewer, such as `lsof -nP -iTCP -sTCP:LISTEN` on macOS. A failed `/health` request means the HTTP backend is not ready; debug that before the Flutter client.

| Default listener | Purpose | Expected exposure |
|---|---|---|
| `127.0.0.1:8080` | HTTP API, PhiloBot POST/SSE, and ticketed Engine/Memory events | Loopback only |
| `127.0.0.1:50051` | Skills gRPC | Loopback only |
| `127.0.0.1:8091` | OpenAI-compatible local model gateway | Loopback only; absent only when explicitly disabled |
| `127.0.0.1:8092` | Optional ONNX memory-embedding sidecar | Source-only, separately started, loopback only |

Model workers use dynamically allocated loopback ports and therefore do not
have another fixed entry in this table.

## Source requirements

The current source and release workflow target:

- Go 1.25 for the backend;
- Flutter 3.44.4 with Dart compatible with the frontend constraint (`^3.12.2`);
- Python 3 for engine runtime installation and a Textual environment for the supervised source launcher;
- CMake plus C and C++ build tools for native llama.cpp package builds;
- matching GPU drivers/toolchains when using CUDA, ROCm, Vulkan, or Metal acceleration.

The Go backend can start without Python, but automatic local-runtime installation and local model inference will be unavailable.

## Starting from source

### Recommended launcher

After preparing `backend/.venv` with Textual as described below, start from the
repository root:

```bash
cd /path/to/philoengine
./start.sh
```

Use `PHILOENGINE_SKIP_UPDATE=1 ./start.sh` when a development checkout should
not perform its normal source-update check.

### Manual backend

```bash
cd backend
go run ./cmd/server
```

Wait for the HTTP and gRPC startup messages, then verify `http://127.0.0.1:8080/health` in another terminal.

### Manual Flutter client

```bash
cd frontend
flutter devices
flutter run -d linux
```

Replace `linux` with an available Flutter target. The development console used by `start.sh` currently launches the Linux Flutter device and should not be treated as a cross-platform launcher.

### Development console

`start.sh` expects a backend virtual environment containing Textual:

```bash
cd /path/to/philoengine
python3 -m venv backend/.venv
backend/.venv/bin/pip install textual
./start.sh
```

The console can run `go mod tidy` and may attempt to install its hardware-probe helper. Review a dirty Git tree before using it when you need a perfectly unchanged checkout.

## Backend does not start

1. Check whether ports `8080`, `50051`, or `8091` are already occupied.
2. Read the first backend error rather than the Flutter connection error that follows it.
3. Confirm the current user can create and update the backend `data/` directory.
4. Check that the configured host is a valid local address. Binding to `0.0.0.0` is exposure, not a connection fix.
5. Run the focused backend tests shown under [Verification](#verification).

The HTTP and gRPC servers share one backend process but start independently. A
gRPC bind failure is logged while the HTTP API can remain healthy; an HTTP bind
failure is fatal. The Engine gateway starts during module initialization, so an
`8091` bind failure also prevents the backend from becoming ready unless the
gateway was explicitly disabled.

## `401 Unauthorized` or login loops

- Obtain a new token through the login flow; do not reuse an expired session.
- Confirm the account still exists. Tokens for deleted accounts are rejected.
- A regenerated or replaced JWT secret invalidates every previous token.
- TOTP is required for initial authenticator setup, account administration, and password reset—not for every normal username/password login.
- Permanent sessions intentionally have no expiry. Client logout can discard its copy, while account deletion or server-wide signing-secret rotation invalidates the token; treat a leaked permanent token as sensitive.

Do not work around authentication by exposing a public route or disabling the middleware.

## Streaming connects and immediately closes

PhiloBot chat streams use an authenticated `POST /api/philobot/stream` request
whose response is `text/event-stream`; send the normal session token in the
authorization header and do not place it in the URL. Engine and Memory event
feeds use a different flow: request a fresh SSE ticket immediately before
opening their `GET` stream. Those tickets are short-lived and single-use, so
reconnect logic must obtain a new one.

Also verify that a reverse proxy, if present, does not buffer `text/event-stream` responses and permits long-lived connections.

## A gRPC client cannot find Engine or Chat

This is expected in the current alpha. Only **Skills** is registered on gRPC. Engine, Chat, Training, Quantization, and Marketplace proto definitions are not active server services. Use the HTTP/SSE API for current integration work.

The Skills gRPC listener also does not inherit HTTP JWT middleware. Keep it on loopback unless an independent authenticated boundary is added.

## A model is missing from the catalog

- Confirm the configured model directory, not just the default directory.
- Rescan the catalog after copying files.
- Use a supported GGUF or SafeTensors layout and include the metadata/configuration files required by the selected runtime.
- Check file permissions and available disk space.
- Treat an incomplete or partially downloaded artifact as invalid; do not rename it to bypass validation.

`trust_remote_code` is off by default. Enable it only when the model genuinely requires repository-supplied code and that code has been reviewed.

## Runtime installation fails

Check the host tools first:

```bash
python3 --version
cmake --version
cc --version
c++ --version
```

Then distinguish these cases:

- **Package host unavailable:** first-time runtime creation needs network access. A fully installed worker can operate with local model files and offline flags afterward.
- **Native build failure:** llama.cpp installation can compile native code and needs a functioning compiler toolchain.
- **GPU build failure:** verify the driver and SDK/toolkit agree with the selected backend.
- **Smoke test failure:** PhiloEngine does not activate the new environment; inspect the installer output instead of manually marking it healthy.
- **Low disk space:** runtime environments are isolated and content-addressed, so multiple recipes can coexist.

Do not copy a half-created environment over an active one. Installation and activation are designed to be staged atomically.

The in-app privileged repair path for missing Vulkan build packages currently
supports Debian/Ubuntu only and invokes `pkexec` with `apt-get` after explicit,
single-use consent. On other systems, install the required toolchain through
the operating system's normal package-management process.

## An unexpected runtime was selected

The current selection rules are intentional:

| Situation | Expected result |
|---|---|
| GGUF | llama.cpp |
| SafeTensors on Linux with supported discrete CUDA/ROCm | vLLM, with Transformers fallback |
| SafeTensors elsewhere | Transformers |

vLLM is not the default for CPU, Metal, or unsupported hosts. A failed preferred runtime can fall back to another runtime, device, KV-cache mode, or smaller context. Weight quantization is not performed automatically.

## Out of memory, pressure, or slow loading

- Inspect the engine capability/plan output and live metrics.
- Close or unload idle instances before increasing context.
- Reduce requested context or parallel instance count.
- Confirm the OS and driver report realistic free memory; planning uses current snapshots, not only nominal capacity.
- Leave the default RAM/GPU reserve enabled unless you understand the host workload.

The planner and resource guard reduce oversubscription risk, but they cannot guarantee that the operating system never swaps or that every driver reports usable memory perfectly.

## Memory recall looks weak or unexpected

The default embedding backend is a deterministic 128-dimensional hash backend. It is reliable and local, but it is not equivalent to a neural semantic embedding model.

- Check Memory health to see which embedding backend is active.
- Verify user and project scoping before concluding that data is missing.
- Remember that hybrid ranking also uses FTS, recency, source, and type signals.
- An unavailable optional ONNX, Ollama, or remote API backend falls back to hash embeddings.
- Default compression is deterministic and rule-based; summaries can omit detail by design.

The repository's ONNX sidecar under `backend/sidecar/` is not started by
`start.sh` and is not bundled in Quickinstall. It must run
separately on `127.0.0.1:8092`; otherwise selecting `onnx_local` falls back to
the hash backend.

Never edit the SQLite database directly while the backend is running. Back up
targeted state before maintenance, and do not delete the entire data directory
as a generic reset. That directory is `backend/data/` for a source run and
`<install-root>/backend/data/` for Quickinstall.

## Search categories return `no engines available`

Only **text search** currently has registered engines: Wikipedia, Bing, Brave, Google, and DuckDuckGo. News, image, video, and book route shapes exist but do not have engines today.

For text-search failures:

- try another registered engine;
- expect upstream HTML changes or rate limits to break scraping providers temporarily;
- verify the query is not blocked by a network policy;
- remember that web extraction rejects localhost, private, link-local, and other protected address ranges.

The SSRF guard is a mitigation, not a reason to expose the fetch service to hostile multi-tenant traffic.

## News or Benchmark is empty/stale

> [!WARNING]
> News and Benchmark are alpha modules and differ between releases. Diagnose
> against the exact installed build and its release notes.

- News refreshes at startup and every 15 minutes. If every source fails, it keeps its current cache; a fresh workspace can therefore show bundled fallback items.
- Some News sources are HTML scrapers and can break when a publisher changes markup. One failing source should not invalidate successful feeds.
- In the newer local development state, Benchmark registers only the LMArena text board. At backend startup it refreshes a missing snapshot or one older than 24 hours; it does not run a separate daily timer.
- A Benchmark source failure keeps the last usable snapshot. A current local snapshot count is not a permanent model-count guarantee.
- Optional Hugging Face model details need a resolvable repository ID; imported Arena rows do not always provide one.

Inspect the authenticated status endpoints and backend refresh logs before clearing any cache.

## Updates are skipped or roll back

For source updates, check:

```bash
git branch --show-current
git status --short
```

Automatic source updates require the exact configured branch (normally `main`), a clean tree including no untracked files, and a fast-forward relationship with the remote. The updater intentionally does not switch branches, rebase, reset, or overwrite local work.

For release updates:

- an offline or unavailable manifest should fall back to the previously verified bundle;
- asset size and SHA-256 must match the manifest;
- unsafe archive paths and symlinks are rejected;
- an immediate startup failure can quarantine the new bundle and reactivate the prior version;
- a later runtime crash does not automatically trigger downgrade.

The manifest signature field is reserved but **not verified** in the current
updater. A checksum match proves consistency with that manifest, not an
independent publisher signature. The current release workflow also does not
code-sign or notarize its binaries, so operating-system trust warnings can
appear.

Set `PHILOENGINE_SKIP_UPDATE=1` to skip the development launcher's update check. Current release automation targets Linux x64, Windows x64, and macOS ARM64; do not expect a current macOS x64 artifact.

## Verification

Run checks for the layer you changed. Network access may be needed the first time dependencies are resolved.

```bash
cd backend
go test ./...
```

```bash
cd frontend
flutter analyze
flutter test
```

```bash
cd frontend
flutter test integration_test/ -d linux
```

```bash
cd backend
python3 -m unittest engineworker/test_transformers_worker.py
```

```bash
python3 -m unittest discover -s quikinstall/tests -v
python3 -m py_compile quikinstall/build_release.py
```

Run commands from the directory shown; several paths and data defaults are working-directory-sensitive.

## Reporting an issue safely

Include:

- OS, architecture, and PhiloEngine commit;
- Go, Flutter/Dart, and Python versions;
- model format and runtime selected, without uploading private model files;
- GPU/driver/runtime type when relevant;
- the first causal backend/installer error and the action that triggered it;
- whether the checkout is dirty and whether the problem reproduces with loopback defaults.

Remove API keys, JWTs, TOTP secrets, memory tokens, private prompts, project paths, usernames, and provider request payloads before sharing logs. See [Privacy](PRIVACY.md) for the full trust model.
