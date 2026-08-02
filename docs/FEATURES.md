# PhiloEngine — Features and limitations

**English** · [Deutsch](../de/docs/FEATURES.md)

This page documents the **current development state** of PhiloEngine. It deliberately separates usable functionality from alpha modules, partially connected controls, locked previews, and planned future phases.

[← English overview](../README.md) · [Installation](INSTALLATION.md) · [Roadmap](../ROADMAP.md)

> [!NOTE]
> This page can be ahead of packaged builds. Use the matching release notes as
> the authoritative feature list for an installed package.

## Status key

| Status | Meaning |
|:---|:---|
| **Usable** | Implemented in the current development tree. Still subject to change while the project is in alpha. |
| **Alpha** | Implemented and testable, but actively evolving or not included in every published build yet. |
| **Partial** | UI or infrastructure exists, but the full end-to-end workflow is not connected. |
| **Locked** | A visible preview for a later project phase; controls are intentionally unavailable. |
| **Planned** | Roadmap direction without a usable interface or backend workflow today. |

## Feature matrix

| Area | Status | Current scope |
|:---|:---:|:---|
| Authentication and onboarding | Usable | Login, session restore, TOTP setup, language and Classic/Lite selection |
| Chat | Usable | Local and supported cloud models, streaming, Markdown, LaTeX, reasoning, code and projects |
| Engine | Usable | Configure, start, monitor and manage local model instances |
| Marketplace | Usable | Hugging Face downloads plus OpenRouter and Featherless models |
| Bot management | Usable | Custom bots, prompts, response styles, routing and model binding |
| Settings | Usable | Providers, server, language, UI mode, shortcuts, default bot and skill administration |
| News | Alpha | Aggregated AI and technology feeds, search, filters and saved articles |
| Benchmark | Alpha | LMArena Text leaderboard, model details and comparison |
| Agentic workflows | Partial | Planning, tool, permission and diff surfaces exist; direct agent modes remain disabled |
| Training | Locked | Phase 3 preview for guided full fine-tuning and fine-tuning without an active backend workflow |
| Quantization | Locked | Phase 3 preview for guided conversion and quantization without an active backend workflow |
| Gen Studio | Locked | Phase 4 image/video preview without generation services |
| Game development | Planned | Phase 4 direction without a current product module |
| Shared models and compute | Planned | Opt-in Phase 5 direction; no current resource-sharing network |

## Interface and navigation

PhiloEngine uses a permanently dark Material 3 interface with an Obsidian palette, gold accents, and responsive card grids. The dashboard adapts its sidebar, content panels and cards to narrow and wide desktop windows.

### Classic and Lite

- **Classic** exposes Chat, Engine, Marketplace, Training, Quantization, Gen Studio, News and Benchmark.
- **Lite** focuses the main navigation on Chat, Engine, Marketplace, News and Benchmark.
- Settings and Bot Management remain available in both modes.
- Switching to Lite leaves a currently open module that is hidden in Lite.

The sidebar can be collapsed, reordered and reduced during a session. Those layout changes currently live in widget state; persistent sidebar customization is not implemented.

## Authentication and onboarding

- Username and password login.
- Restore a remembered session at startup.
- Select a session duration from eight hours to permanent.
- Configure TOTP through a QR code for apps such as Google Authenticator or 2FAS.
- Registration and password reset with an authenticator code.
- Non-dismissible first-run selection of **German/English** and **Classic/Lite**.
- Preferences are saved through the backend; a failed save keeps a visible retry path.

## Chat

### Models and sessions

- Select a running local Engine instance or an activated API model.
- Change the model for an individual chat session.
- Bind a bot to a fixed local or API model.
- Follow local-model warm-up progress, cancel it, or retry.
- Create chats and organize history into projects.
- Give projects a name, color, icon and optional local directory.
- Rename, delete and move chats between projects.

### Responses and rendering

- Token streaming through Server-Sent Events.
- Live reasoning followed by a collapsible reasoning view.
- Work phase, elapsed time and progress while a response is running.
- GitHub-Flavored Markdown after a stream completes.
- Inline and block LaTeX, checkboxes and links.
- Code blocks with preview, source view and copy actions.
- Native <code>visual</code> blocks for bar, column, line, donut, pie, process, flow and KPI views.
- Copy messages, edit a user message, and resend from that point.
- Quick follow-ups such as shorter, more critical, or more structured.

### Agentic infrastructure

Planning can be sent to the API. The interface also contains plan approval, tool events, file diffs, and permission decisions such as allow once, allow for the session, or deny.

The direct **Dual** and **Agent** thinking modes are currently disabled. Existing agentic event handling should therefore not be presented as a generally unlocked agent mode.

### Visible but incomplete chat controls

| Control | Current limitation |
|:---|:---|
| Web search | The toggle changes UI state and its badge, but is not currently included in the outgoing chat request. |
| File upload / drag and drop | Selected files appear as chips but are not attached to the message payload yet. |
| Microphone | The button has no action; voice input is not functional. |
| Philox | The route currently opens the regular chat UI rather than a separate Philox screen. |

## Memory and embeddings

Memory recall uses a deterministic, local 128-dimensional hash embedding
backend by default. The optional local ONNX backend depends on a Python/ONNX
sidecar that must be started and configured separately from the source tree.
Quick Install does not bundle that sidecar. Without a working optional backend,
Memory falls back to the hash implementation.

## Engine

The Engine follows a three-stage workflow:

1. Select a model from the local catalog.
2. Configure resources or calculate a recommendation.
3. Review preflight information and start an instance.

### Models and resources

- Scan, rescan and remove local model files with confirmation.
- Recommend GPU, GPU-plus-RAM, or CPU/RAM fallback configurations.
- Calculate automatic or fixed context sizes with weight, context-memory and runtime reserves.
- Plan GPU, CPU or hybrid placement.
- Install a compatible runtime and display setup events.
- Start, stop, edit and remove instances.
- Apply context changes with restart and stability checks.
- Manage sampling defaults and inspect technical failure suggestions.

### Expert controls

Available controls include runtime, process priority, GPU layers, CPU threads, tensor parallelism, parallel sequences, GPU selection, offloading, KV-cache data type and policy, RAM offload, fallback, remote code and autostart.

### Safety and telemetry

- The built-in privileged repair for GPU build dependencies currently applies
  only to Debian-based Linux systems. After explicit consent it uses `pkexec`
  with `apt-get`; other Linux distributions, macOS, and Windows require manual
  dependency setup.
- Remote model code is not fully sandboxed. Approval is bound to the model fingerprint and Python code hash, and is requested again when either changes.
- Telemetry covers RAM and VRAM usage, startup progress, running models, active requests, runtime details and technical components.

## Marketplace

### Local models through Hugging Face

- Debounced search, pagination and incremental loading.
- Chat, Code, Reasoning, Vision and Embedding categories.
- Sorting by popularity, intelligence, context, recency and supported cloud price fields.
- Filters for local models, GPU fit, quantization and format.
- Responsive grid and list views.
- Hardware-aware fit, VRAM, runtime and context information.
- Selection of concrete quantized files or Safetensors shards.
- Size validation before download.
- Download progress, speed, target path, history and duplicate-job protection.
- Token support for gated Hugging Face models.

### Cloud models

Supported OpenRouter and Featherless models can be activated for chat after a provider token has been configured. Provider availability and prices originate outside PhiloEngine and may change independently.

## Bots

Custom bots support:

- Name and system prompt.
- Keywords for automatic routing.
- Short, explanatory, step-by-step, critical, brainstorming or balanced response styles.
- Optional agentic flag and allowed root paths.
- Optional binding to a local or API model.
- Selection of a default bot.

The built-in **Bot Builder** is a protected, read-only system bot.

## Settings

### General

- Choose the model download directory.
- Change the backend API address.
- Select German or English.
- Switch between Classic and Lite.
- Inspect detected hardware, memory and storage information.

### Providers and custom nodes

- Check the local backend connection.
- Manage Hugging Face, OpenRouter and Featherless tokens.
- Add, edit, remove and health-check custom nodes.

Custom nodes **cannot yet become active Chat or Engine connections**. The interface identifies that integration as Phase 2.

### Shortcuts, default bot and Agent Skills

Keyboard shortcuts can be adjusted for module navigation, sidebar actions, chat focus, new sessions, search and Engine actions. New chats can use automatic routing or a preferred default bot; existing chats keep their current binding.

Skill folders can be imported, validated, copied into <code>data/skills</code>, enabled, disabled, deleted and rescanned. In this version, Agent Skills are **not yet loaded into chats**.

## News · Alpha

News belongs to the current alpha development tree and may be ahead of published packages.

<img src="../assets/screenshots/news.png" alt="News feed with provider and category filters" width="100%">

- Responsive cards with image, source, time, headline, excerpt and category.
- Search across titles, content and tags.
- Category, source and saved-only filters.
- Per-user saved articles with optimistic updates and rollback on failure.
- Links to the original source.
- Periodic feed refresh and deduplication.

Current sources include OpenAI, Hugging Face, Google DeepMind, Mistral AI, Golem, heise, Hacker News and Anthropic, among others. VideoCardz is disabled because its endpoint returns HTTP 403. External feeds can change or disappear independently of PhiloEngine.

## Benchmark · Alpha

Benchmark is an alpha module. The internal structure can support multiple
boards, but only **LMArena · Text** is currently registered.

<img src="../assets/screenshots/benchmark.gif" alt="Benchmark overview, leaderboard and side-by-side comparison" width="100%">

- Overview, Leaderboard and Compare tabs.
- Overall Elo plus categories such as Coding, Math, Creative Writing, Instruction Following, Multi-Turn, Longer Query and Non-English.
- Search, organization/open-weight filters, sorting and incremental loading.
- Details including rank, percentile, vote count, confidence interval, license, organization and evaluation date.
- Hugging Face Hub metadata such as downloads, likes, modification time, gating, parameter counts and inference providers when available.
- Side-by-side comparison of up to four models.

Leaderboard data comes from the Parquet files in
<code>lmarena-ai/leaderboard-dataset</code> on the Hugging Face Hub, not from the
Hugging Face datasets server. Snapshots are cached locally and normally
refreshed daily; Hub details use a shorter cache. “Live” does not mean that
every field is fetched again whenever the screen opens.

## Later phases

### Training · Phase 3

Training is a locked design preview. Its controls are disabled, with no active training API, running job or progress polling. Phase 3 is intended to make full fine-tuning and more resource-conscious fine-tuning paths guided, reproducible, and approachable while retaining expert controls.

### Quantization · Phase 3

Quantization is a locked design preview. Displayed configuration values do not start a quantization process. Phase 3 is intended to guide users through format, quality, size, memory, and compatibility decisions as well as conversion, progress, validation, and recovery.

### Gen Studio · Phase 4

Gen Studio is a locked preview for image and video generation and is not connected to a generation service.

### Game development · Phase 4

The roadmap includes a dedicated game-development workspace for organized asset workflows and project-aware assistance. No Game Development module or backend workflow exists in the current interface.

### Shared models and compute · Phase 5

The long-term roadmap allows owners to offer self-hosted models and compute by explicit opt-in. Nothing is shared automatically today, and there is no current public compute network. PhiloEngine itself is intended to remain free and open source.

## Localization

PhiloEngine-authored UI is available in German and English. Technical diagnostics and data received directly from the backend or external sources may intentionally remain untranslated to preserve precision.

## Platforms

Current desktop packages:

- Linux x64
- Windows x64
- macOS ARM64

Flutter scaffolding for Android, iOS, Web or other desktop architectures does not imply an officially packaged and tested release. macOS x64 can be built locally but is not produced automatically as a release artifact.

## Tests and maturity

The repository includes widget and unit tests for Engine, Chat, Marketplace, News, Benchmark, Settings, Onboarding, localization, authentication, bots and the dark theme, plus an integration smoke test. Their presence does not mean every platform or external provider has been verified in every release.

PhiloEngine remains alpha software. For a specific build, also review the [Roadmap](../ROADMAP.md), [Installation guide](INSTALLATION.md), and the corresponding release notes.
