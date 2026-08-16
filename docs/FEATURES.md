# Features and current status

This page is a practical snapshot of what works today. “Available” means the workflow is usable; “Beta” means it works but is still receiving polish and fixes; “Experimental” means it is being built right now and is not a feature you can rely on.

## What is available

| Area | Status | What it does |
|:---|:---:|:---|
| Local models | Available · Phase 1 Beta | Runs GGUF models through `llama.cpp` and can use CUDA, Vulkan, SYCL, Metal, or CPU. |
| API providers | Available · Phase 1 Beta | Connects OpenRouter and Featherless; provider keys stay in local settings. |
| Own provider connections | Available · Phase 1 Beta | Adds an OpenAI-compatible endpoint of your own; the key is stored encrypted and never shown again in clear text. |
| Guest mode | Available · Phase 1 Beta | Starts the app without an account and carries the guest chats and settings over when one is created later. |
| Hardware planning | Available · Phase 1 Beta | Checks RAM and VRAM, estimates context size, and retries with a safer setup when needed. |
| Scouts | Available · Phase 1 Beta | Provides project-aware assistants with planning, tools, permissions, and reviewable diffs. |
| Memory | Available · Phase 1 Beta | Keeps searchable context per user and project using SQLite text and vector search. |
| Marketplace | Available · Phase 1 Beta | Shows Hugging Face downloads and hosted models together, with fit information where available. |
| CulpeoSearch | Available · Phase 1 Beta | Searches public sources and extracts pages into Markdown. |
| News | Beta | Aggregates AI and technology feeds with search, filters, and saved articles. |
| Benchmark | Beta | Displays LMArena rankings, category scores, comparisons, and refreshed snapshots. |
| Culpeo Node | **Experimental** | Would run models on another machine. Unfinished and unstable; in the tree because it is under development, not because it works. See [NODE.md](NODE.md). |

![Chat, marketplace, news, and benchmark views in Culpeo Studio](../assets/screenshots/chat.png)

## Details

### Local engine

The engine scans the model directory, checks the current machine, and plans a launch before starting a worker. If GPU placement does not fit, it can reduce the context or fall back to CPU. Workers run locally on loopback with a bearer token.

### Scouts and projects

Scouts can have their own prompt, trigger words, model, and project directory. File tools are limited to approved project roots. Proposed edits are shown as diffs before they are written. A Scout that plans first proposes the plan, waits for approval, and then works it off as a checklist that survives an interrupted run.

### Chats and sessions

A chat is named by the model that answered its first exchange, so the sidebar shows the topic instead of the opening message; the name can be overwritten by hand at any time. When a conversation fills about four fifths of the model's context window, the older turns are folded into a running summary — the transcript keeps every message, only the model sees the folded history. The answer length is capped per turn against the room the prompt leaves.

### Memory and retrieval

Chats, observations, and summaries live in SQLite. Retrieval combines ordinary FTS5 text search with vector similarity. The default embedding is a local deterministic 128-dimensional hash; ONNX and other backends can be configured.

### Marketplace

Local models are searched and downloaded from Hugging Face. Hosted models are available through OpenRouter and Featherless. Cards show format, context, pricing, or hardware-fit information when the provider supplies it.

### Culpeo Node (experimental)

A separate backend meant to run models on another machine, paired over a pinned TLS link. It is unfinished: pairing, remote downloads and remote inference are being worked on right now and change without notice. It is not part of the Beta and nothing in the app should be planned around it.

## Planned work

- **Phase 2:** Remote server profiles and hybrid routing.
- **Phase 3:** Guided LoRA/QLoRA fine-tuning and quantization workflows.
- **Phase 4:** Local image/video generation and a game-development workspace.
- **Phase 5:** Optional encrypted sharing of self-hosted models and compute.
