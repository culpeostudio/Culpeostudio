# PhiloEngine Privacy & Security

**English** · [Deutsch](../de/docs/PRIVACY.md)

> [!IMPORTANT]
> **PhiloEngine is local-first, not network-isolated.** Models, chats, memory, and credentials are stored locally by default, but updates, News, Benchmark, search, downloads, runtime installation, and configured API providers can contact external services.

[← README](../README.md) · [Architecture](ARCHITECTURE.md) · [Transparency](TRANSPARENCY.md) · [Troubleshooting](TROUBLESHOOTING.md)

## The short version

- Local models execute through loopback-only workers by default.
- PhiloBot chat sessions are stored as local JSON files; Memory records and indexes use a local SQLite database.
- Secrets rely primarily on owner-only file permissions; the inspected storage is not application-encrypted at rest.
- Most HTTP API routes require a signed session token.
- PhiloBot path checks and command rules are guardrails, **not an OS sandbox**.
- Several features make automatic or user-triggered outbound requests.
- Update payloads use HTTPS, size checks, and SHA-256 checksums, but the manifest signature field is **not currently verified**.

## Scope: technical documentation, not a legal privacy notice

This page records observable storage, network, and security behaviour in the
software. It is not legal advice and is **not** a complete privacy notice under
[GDPR Article 13](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32016R0679)
or equivalent national law.

Before operating a public website, hosted PhiloEngine instance or API, support
intake, analytics/telemetry service, or account service that processes personal
data, the operator must assess the applicable duties and provide a separate,
service-specific notice before processing begins. As applicable, that notice
needs the operator/controller's real legal identity, a serviceable postal
address and contact details; representative and data-protection-officer details;
purposes and legal bases; legitimate interests; recipients and international
transfers; retention periods or criteria; data-subject rights, withdrawal and
complaint routes; whether providing data is required; and information about
automated decision-making. A separate legal notice or imprint may also be
required. The exact content depends on the operator, jurisdiction, and actual
service. This project page intentionally does not invent missing operator
details or replace that assessment.

## What is stored locally

Most mutable state defaults to the backend's `data/` directory. The exact location depends on the backend working directory and configuration; model and project paths can point elsewhere.

| Data | Storage and scope | Important note |
|---|---|---|
| Accounts | Private local files with bcrypt password hashes | App accounts are not separate operating-system users |
| JWT signing secret | Install-specific private file | Rotating or deleting it invalidates existing sessions |
| TOTP setup secret | Private local file | TOTP protects setup/account administration and password reset; it is not required on every normal login |
| Memory API token | Separate private local file | Used for the Memory surface where supported |
| Provider credentials | Local settings file | Stored locally but not application-encrypted |
| PhiloBot chat sessions | One local JSON file per chat session | Prompts, responses, tool activity, and metadata can contain sensitive information |
| Memory | Per-user records and indexes in SQLite, including observations and derived summaries | Derived summaries and indexes can still contain sensitive information after the originating chat changes or is deleted |
| Saved News items | Per-user private JSON snapshots | The current News implementation is experimental Phase 1 work |
| Benchmark snapshots | Private local snapshot files | Public benchmark data, refreshed when stale |
| Engine runtimes | Content-addressed local Python environments | Packages are downloaded during first installation |
| Models and projects | Configured filesystem directories | They may live outside the default data directory |

Secret-bearing files are intended to use owner-only permissions where supported.
Other records, including chat JSON files, can rely on restrictive parent-directory
permissions instead of an owner-only mode on every individual file. Effective
permissions can also vary by platform and pre-existing directories. Anyone who
can read files as the same OS user—or a more privileged user—can still access
unencrypted application data and provider credentials. Use full-disk encryption
and a protected OS account when the machine or data is sensitive.

## External connections

Outbound behavior is feature-specific. Public services still receive ordinary connection metadata such as the machine's public IP address and request timing, even when no chat content is sent.

| Trigger | External destination | Data that can leave the machine |
|---|---|---|
| Source/release update at startup | Configured Git repository or trusted release host | Repository/version information and normal HTTP/Git metadata |
| News startup and 15-minute refresh | Public RSS/Atom feeds and selected news pages | Feed requests and normal HTTP metadata; not project or chat content by design |
| News image rendering in the Flutter client | The image host selected by the publisher, often the publisher itself or a CDN | The image URL is requested directly from the client; the host receives normal request and connection metadata such as the public IP address and request timing |
| Benchmark startup when its snapshot is stale | LMArena repository on the Hugging Face Hub | Repository and Parquet-file requests plus normal HTTP metadata |
| Text search | Selected public search engines | The search query, locale/category options, and connection metadata |
| Page extraction | The URL supplied by the user or agent | Requested URL and connection metadata |
| Marketplace/model download | Model host or configured provider | Search terms, artifact identifiers, account token where configured |
| Runtime installation | Python/package distribution hosts | Runtime recipe and package requests |
| Cloud LLM provider | The configured provider | Prompt, selected recall/context, tool results, generation settings, and provider credentials as required by that API |
| Remote embedding backend | Configured Ollama/API endpoint | Text submitted for embedding |
| Optional model-detail lookup | Hugging Face Hub | Model identifier and request metadata |
| UI font loading | Google Fonts infrastructure when a requested font is not bundled or cached | Font request and normal connection metadata; no chat content by design |

### Benchmark data attribution

The Benchmark module uses the
[LMArena Leaderboard Dataset](https://huggingface.co/datasets/lmarena-ai/leaderboard-dataset)
by `lmarena-ai`, licensed under
[Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/).
PhiloEngine downloads selected Parquet shards from the dataset's Hugging Face
Hub repository and processes them into local snapshots for filtering, mapping,
sorting, caching, and display. Those processing steps are modifications made by
PhiloEngine; the resulting presentation is not an endorsement by LMArena.

> [!WARNING]
> News and Benchmark are **alpha modules** and can be ahead of the latest
> published release. Both can initiate background requests without a
> per-refresh click. Do not describe PhiloEngine as “nothing leaves the machine
> unless the user asks.”

Phase 5 describes a future, opt-in way to offer self-hosted models and compute.
It is not current behavior: PhiloEngine does not automatically share a model,
machine, or compute capacity.

### Working in a strict-offline environment

1. Set `PHILOENGINE_SKIP_UPDATE=1` before using the development launcher.
2. Do not configure cloud providers or remote embedding endpoints.
3. Avoid search, page extraction, News views with remote images, marketplace downloads, and first-time runtime installation.
4. Pre-stage models and all required runtime packages while connected.
5. Bundle or pre-cache the configured UI fonts if consistent typography is required offline.
6. Block outbound traffic at the OS/container boundary if strict enforcement is required. The current News and Benchmark work has background refresh behavior and should not be controlled by a documentation promise alone.

An offline firewall can make network-backed features fail; it should not corrupt the last usable local News or Benchmark cache.

## Authentication boundaries

The primary HTTP API uses JWT HS256 sessions with an install-specific secret. Deleted accounts invalidate their tokens because account existence is checked during authentication. Session lifetimes include expiring and explicitly permanent options.

- Initial setup, login, and account-recovery entry points are necessarily available before normal API authentication.
- Most `/api` routes require a valid account token.
- Chat and engine SSE connections use short-lived, single-use tickets instead of placing a long-lived bearer token in an event-stream URL.
- Model workers bind to loopback and use independent random bearer secrets.
- The Memory API can use its own generated token on supported paths.

The server currently permits CORS from `*`. JWT authentication still protects authenticated HTTP routes, but permissive CORS is another reason not to expose the backend directly to an untrusted network.

### gRPC limitation

Only the Skills gRPC service is currently registered. It does not inherit Fiber's HTTP JWT middleware. Keep the gRPC listener on loopback or place it behind an independently authenticated boundary. Do not expose port `50051` based on assumptions made for the HTTP API.

## Security boundaries

### Localhost is a default, not a firewall

HTTP (`127.0.0.1:8080`), Skills gRPC (`127.0.0.1:50051`), and the local model gateway (`127.0.0.1:8091`) bind to loopback by default. Changing the configured HTTP host can also affect the gRPC listener. If remote access is required, add a firewall, TLS termination, strong authentication, and an explicit proxy policy instead of binding directly to every interface.

### PhiloBot is not an OS sandbox

File tools resolve symlinks and check paths against allowed project roots. Access outside those roots can require an explicit session permission, and privileged launchers such as `sudo`, `su`, and `doas` are blocked.

Those controls do not confine a process at the operating-system level. Allowed executables—including Python, Go, Node, Dart, and Flutter tooling—run with the same OS permissions as PhiloEngine and can interpret paths in their own arguments or code. Use a container, VM, restricted OS account, or another real sandbox for untrusted repositories and commands.

### Web fetch protection has limits

The URL guard accepts HTTP(S) and rejects loopback, private, link-local, and carrier-grade NAT targets. This reduces SSRF risk, but DNS can change between validation and connection. Do not treat the fetcher as a hardened boundary for hostile multi-tenant use.

### Model code is a trust decision

Transformers workers request local files and set common offline flags. Repository-supplied remote code is disabled by default, but users can explicitly trust it per model. Enabling that option allows model code to execute with the worker process's OS permissions.

## Update integrity

The release updater uses trusted HTTPS hosts, validates the declared download size and SHA-256 checksum, rejects unsafe archive paths/symlinks, stages installation atomically, and can roll back after an immediate startup failure.

However, checksum authenticity ultimately depends on the downloaded manifest. The manifest contains a reserved `signature` field, but the inspected updater does not verify it. Therefore:

- describe releases as **checksum-verified**, not cryptographically signed;
- independently verify artifacts when the distribution channel is part of your threat model;
- do not treat automatic rollback as protection from a malicious but correctly checksummed bundle.

## Practical privacy checklist

- Keep all listeners on loopback unless remote exposure is intentionally secured.
- Use a dedicated OS account and full-disk encryption for sensitive local data.
- Review the provider and embedding backend before sending confidential prompts.
- Treat remembered summaries as sensitive even when the original chat is deleted.
- Leave `trust_remote_code` disabled for models you have not audited.
- Run untrusted project commands in a real sandbox.
- Review outbound behavior before claiming an offline deployment.
- Never include JWTs, API keys, TOTP secrets, memory tokens, or full private prompts in bug reports.

See [Architecture](ARCHITECTURE.md) for component boundaries and [Troubleshooting](TROUBLESHOOTING.md) for safe diagnostic commands.
