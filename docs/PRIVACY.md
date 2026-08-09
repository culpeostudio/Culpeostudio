# Culpeo Studio Privacy & Network Boundaries

Culpeo Studio is local-first: accounts, chats, Scout project files, memory indices, and local model files stay on your machine unless a feature explicitly needs an external service.

---

## Network Connection Matrix

| Feature / Action | Destination Host / Service | Data Transmitted | Trigger Condition |
|:---|:---|:---|:---|
| **Local Model Chat** | None (`127.0.0.1` loopback only) | Prompts and inference tokens stay on host | Always local unless online web tool / external API is selected |
| **API Provider Chat** | `openrouter.ai` / `api.featherless.ai` | User prompts, system instructions, message history | Explicitly selecting an OpenRouter or Featherless model |
| **CulpeoSearch** | DuckDuckGo, Brave, Google, Bing, Wikipedia | Search queries and target webpage URL requests | User explicitly invokes search or Scout tool uses search |
| **News Module** | Configured RSS/Atom feeds and news sources | HTTP GET requests for feed items and article text | Automated background refresh (every 15 min) or manual pull |
| **Benchmark Module** | LMArena public leaderboard sources | Public dataset/ranking queries | Startup refresh (if cache >24h) or manual refresh |
| **Marketplace Downloads** | `huggingface.co` or configured model host | Model download requests | User initiates GGUF model download |
| **Update Checker** | `raw.githubusercontent.com` / `github.com` | Manifest fetch and release asset download | Application startup update check |

---

## Scout tools and permissions

> [!WARNING]
> Scout tool execution includes project path validation and explicit permission prompts, but command execution is **not an operating-system sandbox**. Executable tools run with the privileges of the Culpeo Studio user process.

- **Allowed Project Roots:** Scout session paths are constrained to explicitly bound project directories.
- **Diff Preview:** Proposed file edits render readable diffs for user review before write operations are applied.
- **Provider keys:** OpenRouter and Featherless keys are stored in local settings (`data/settings.json`) and sent only to the selected provider during a request.
