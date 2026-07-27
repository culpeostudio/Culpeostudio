<div align="center">

<img src="frontend/assets/logo.png" alt="PhiloEngine" width="120">

# PhiloEngine

**A self-hosted desktop studio for local and API-based language models.**
Your models, your keys, your data — nothing leaves your machine unless you say so.

[![Licence: AGPL v3](https://img.shields.io/badge/Licence-AGPL_v3-c9a24a.svg)](LICENSE)
[![Status: Alpha](https://img.shields.io/badge/Status-Alpha-orange.svg)](#roadmap)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-blue.svg)](#requirements)
[![Backend: Go](https://img.shields.io/badge/Backend-Go-00ADD8.svg)](https://go.dev)
[![Frontend: Flutter](https://img.shields.io/badge/Frontend-Flutter-02569B.svg)](https://flutter.dev)

</div>

---

> **Alpha (Phase 1).** Usable day to day, but expect rough edges.
> The interface is currently **German-only**; Linux desktop is the supported target.

## Why another one?

Most tools make you choose: either a polished cloud product that owns your data,
or a local setup you spend an evening assembling. PhiloEngine aims for the middle —
everything runs on your machine, but you should not have to fight it to get there.

The part that took the most work is the one you never see: figuring out **what
your hardware can actually run**. Instead of failing with an out-of-memory error,
PhiloEngine plans a context size that fits, picks a runtime, and steps down
sensibly when a configuration does not hold.

## Features

### Run models locally

- **PhiloEngine Hardware Detection** — detects GPUs, VRAM and RAM, then
  proposes a context size that will actually load
- **Three runtimes**: llama.cpp, vLLM and Transformers, selected per model
- **Graceful fallbacks** instead of hard failures: GPU → CPU, smaller context,
  alternate KV cache type — each step is shown, not hidden
- **Resource guard** prevents starting a model that would push the machine into
  swapping

### Or use API providers

OpenRouter and Featherless are supported. Keys are stored in your local settings
and used only for the requests you trigger.

### PhiloBot — assistants with tools

- Define bots with their own prompt, response style and trigger keywords
- Bind a chat to a **project folder**: the bot can then list, read, search,
  edit and create files there
- Anything **outside** that folder triggers an explicit approval prompt —
  allow once, allow for the session, or deny
- File changes are shown as expandable diffs, not silent writes
- Reasoning models: the thought process streams live, then collapses into a
  dropdown so it does not clutter the transcript

### Long-term memory

Facts from earlier conversations are recalled into later ones, so you do not
repeat yourself across sessions. Backed by SQLite with full-text and vector
search, scoped per user and per project.

### Model marketplace

Search Hugging Face, see **whether a model fits your hardware before
downloading**, then manage what you have locally.

## How it works

```
┌─────────────────────────────┐
│  Flutter desktop app        │   UI, chat, settings
└──────────────┬──────────────┘
               │ HTTP + SSE (127.0.0.1)
┌──────────────┴──────────────┐
│  Go backend                 │   modules: engine, philobot, philox,
│                             │   marktplatz, memory, skills, settings,
│                             │   login, news
└──────────────┬──────────────┘
               │ spawns & supervises
┌──────────────┴──────────────┐
│  llama.cpp · vLLM ·         │   local inference runtimes
│  Transformers               │
└─────────────────────────────┘
```

Both servers bind to `127.0.0.1` by default. The backend keeps all state under
`backend/data/` — models, chats, memory database and settings.

## Requirements

| | |
|---|---|
| OS | Linux desktop |
| [Flutter](https://flutter.dev) | 3.44+ (Dart 3.12+) |
| [Go](https://go.dev) | 1.25+ |
| GPU | optional — CPU inference works, just slower |

## Getting started

```bash
git clone <repository-url>
cd philoengine

# terminal 1 — backend
cd backend && go run ./cmd/server

# terminal 2 — frontend
cd frontend && flutter run -d linux
```

On first start a random signing secret is generated under `backend/data/` —
no setup step required.

**First run, in order:**

1. Set up the authenticator (TOTP) when prompted, then create your account
2. *Marketplace* → search a model and check the hardware verdict before downloading
3. *Engine* → start the model; the wizard proposes a context size that fits
4. *Chat* → pick the model and start talking

No GPU? Use an API provider instead: *Settings → Server / API*, add an
OpenRouter or Featherless key, then start a model from the marketplace.

## Automatic updates

Both supported installation styles update without a manual reinstall:

- **Source checkout:** start with `./start.sh`. Before opening the developer
  console, its bootstrap updater fetches `main` from
  `kuchenboss/MyPhiloEngine` and applies only a clean fast-forward. Local
  changes, another branch, a diverged history, or an offline machine are never
  overwritten; the existing checkout starts with a warning instead.
- **Compiled quick install:** download the `quickinstall` archive for your
  platform from the [latest
  release](https://github.com/kuchenboss/MyPhiloEngine/releases), extract it
  once, and always start the top-level `myphiloengine` launcher
  (`myphiloengine.exe` on Windows). Before every launch it reads
  `quikinstall/manifest.json`, selects the current OS/architecture, downloads
  and verifies the complete frontend/backend bundle, and atomically activates
  it. User data lives outside versioned bundles.

The compiled launcher verifies the trusted GitHub origin, declared size,
SHA-256 checksum, archive paths, and all three entrypoints before activation. A
failed download never replaces the working version, and an offline start uses
the last verified bundle.

A release that installs but fails to start is rolled back to the previous
version and recorded in `quarantine.json`, so the next launch skips it instead
of downloading and failing again every time. The record is keyed on version and
asset checksum, so a rebuilt archive of the same version number is offered
again. Superseded bundles are pruned; the active version and the rollback
target are kept.

Releases are built by
[`.github/workflows/release.yml`](.github/workflows/release.yml): pushing a
`v*` tag builds every platform on a native runner, uploads the archives as
release assets, and publishes the manifest only after each asset is confirmed
reachable. A single platform can also be built locally:

```bash
python3 quikinstall/build_release.py --version 1.1.0-alpha
```

The complete manifest contract and publishing order are documented in
[`quikinstall/README.md`](quikinstall/README.md). Set
`PHILOENGINE_SKIP_UPDATE=1` only when a deliberate offline/development start is
needed.

<details>
<summary>Source checkout: developer console prerequisites</summary>

A terminal UI that supervises backend and frontend together with live logs.
Needs Python and [Textual](https://textual.textualize.io/):

```bash
cd backend
python3 -m venv .venv
.venv/bin/pip install textual
cd .. && ./start.sh
```
</details>

<details>
<summary>Exposing the backend to your network</summary>

Both servers bind to localhost. Only if you deliberately want to reach the
instance from another machine:

```bash
HTTP_HOST=0.0.0.0 go run ./cmd/server
```

Be aware this makes the API reachable for everyone on that network.
</details>

## Roadmap

The interface already shows modules from later phases — they are visible but
locked, so you can see where this is going.

| Phase | Scope | Status |
|---|---|---|
| **1** | Chat, local + API models, memory, marketplace, skills | **current** |
| 2 | Stabilisation, broader hardware coverage | planned |
| 3 | Fine-tuning and quantisation | locked in UI |
| 4 | Image and video generation | locked in UI |

## Development

```bash
cd backend  && go test ./...            # backend tests
cd frontend && flutter test             # widget tests
cd frontend && flutter test integration_test/ -d linux   # drives the real app
```

Repository layout:

```
backend/
  cmd/server/      entry point
  modules/         feature modules, one per domain
  internal/        shared infrastructure (memory, runtimes, hardware, security)
frontend/
  lib/screens/     one folder per screen
  lib/services/    API client
  lib/state/       app state
```

## Contributing

Contributions are welcome — bug reports, fixes, hardware feedback from setups
we cannot test, and translations once the UI is localised.

Please read [CLA.md](CLA.md) first. It keeps the rights to the code in one
place so the project can offer a commercial service later without a
relicensing mess. Sign commits with `git commit -s`.

## Security

Found a security issue? Please report it **privately** to
<security@fillystudio.com> instead of opening a public issue — see
[SECURITY.md](SECURITY.md).

Relevant because assistants can modify files and run commands inside a project
folder, and the backend stores provider API keys.

## Licence

[GNU AGPL-3.0](LICENSE). You may use, modify and redistribute this software.
If you offer a modified version as a network service, you must publish your
changes.

Names and logos are not covered by the code licence — see
[TRADEMARK.md](TRADEMARK.md). Forks are welcome under their own name.

Runtimes and models carry their own licences; see [NOTICE](NOTICE) and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). **If you host models
commercially, check their terms first** — some prohibit it outright.

---

<div align="center">
<sub>Built by fillystudio · Powered by PhiloEngine</sub>
</div>
