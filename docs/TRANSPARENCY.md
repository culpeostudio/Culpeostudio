# PhiloEngine Transparency

**English** · [Deutsch](../de/docs/TRANSPARENCY.md)

> [!NOTE]
> PhiloEngine combines local execution with optional online services. This page
> explains why those paths exist and how AI-assisted tools are used during
> development. It is a description of design choices—not an endorsement of
> every model, dataset, or result available through an integrated service.

[← README](../README.md) · [Privacy & network boundaries](PRIVACY.md) · [Contributing](../CONTRIBUTING.md)

## The short version

- Local runtimes are the preferred path when privacy, control, or offline use
  matters.
- Hosted providers remain optional for models or workloads that do not fit the
  user's hardware.
- Multiple paths preserve user choice and reduce dependence on one runtime,
  catalogue, or provider.
- Public search, News, and Benchmark sources add current external information;
  they are not treated as unquestionable truth.
- AI assists parts of project development, but people remain responsible for
  decisions, review, testing, security, licensing, and releases.

## Why PhiloEngine supports several paths

No single inference path is best for every machine or task. A compact
quantized model on a laptop, a throughput-oriented deployment on a GPU server,
and an occasional request to a hosted model have different requirements.
PhiloEngine therefore aims to make the route visible and selectable instead
of silently deciding that all work must go through one company or runtime.

The main selection criteria are:

| Criterion | What it means in PhiloEngine |
|---|---|
| **User choice** | Users can choose local inference, a configured hosted provider, and the model appropriate to the task. An integration being present does not make it the default recommendation. |
| **Local control** | Local execution keeps model files and inference on hardware controlled by the user, subject to separately enabled online tools and remote embedding services. |
| **Hardware fit** | Different runtimes cover different model formats, accelerators, memory limits, and performance profiles. The engine can plan around available RAM and VRAM. |
| **Reach** | Hosted catalogues and providers make additional models available when a local download or execution is impractical. |
| **Resilience** | More than one route reduces reliance on a single runtime or service. It does not guarantee that an external service will always be available or interchangeable. |
| **Visible boundaries** | Network-backed actions should be identifiable so users can decide whether their data and environment are suitable for them. |

## Why these runtimes and services are included

### Local runtimes

| Runtime | Why it is useful |
|---|---|
| **llama.cpp** | A practical local path for quantized models and a wide range of consumer hardware, including configurations where memory efficiency matters. |
| **vLLM** | A path for accelerator-oriented serving and workloads where efficient request scheduling and throughput matter. |
| **Transformers** | A flexible path for model architectures and workflows represented in the broader Transformers ecosystem. |

These runtimes are complementary. Their presence is not a promise that every
model works with every runtime, operating system, or accelerator. Compatibility
still depends on the model, format, runtime version, and local hardware.

### Model discovery, downloads, and public data

**Hugging Face** gives the marketplace access to a broad model ecosystem,
artifact metadata, model files, and selected public datasets used by supported
features. It helps users discover and obtain models without PhiloEngine
maintaining a separate copy of every artifact. A listing is not a security,
quality, or licence approval: users should review the model card, licence,
publisher, files, and any remote-code requirement before use.

### Optional hosted inference

**OpenRouter** provides an optional route to a broad hosted-model catalogue
through one integration. **Featherless** provides another optional hosted
inference route. These paths are useful when a model does not fit locally, when
users need access to a different model family, or when they intentionally
prefer hosted execution for a task.

Hosted providers receive the information required to process a request, which
can include prompts, selected context or memory, tool results, generation
settings, and credentials required by their APIs. They also apply their own
terms, availability, pricing, retention, and privacy policies. Neither provider
is required for local inference. See the [privacy and network matrix](PRIVACY.md)
before sending confidential material.

### Search, News, and Benchmark sources

PhiloEngine can connect to public search engines, RSS/Atom feeds, web pages,
and public benchmark datasets. Depending on the selected feature, sources can
include search services such as DuckDuckGo, Brave, Google, Bing, or Wikipedia,
public News publishers, and public leaderboard data hosted through Hugging
Face.

They serve different purposes:

- **Search** retrieves information in response to a query.
- **News** brings time-sensitive public reporting into a native view.
- **Benchmarks** provide one external comparison signal for models.

External material can be incomplete, outdated, biased, incorrectly labelled,
or unavailable. Benchmark ranks do not establish that one model is best for
every user, and a search rank or News listing is not an editorial endorsement
by PhiloEngine. Important claims should be checked against suitable primary
sources.

The current Benchmark module uses the
[LMArena Leaderboard Dataset](https://huggingface.co/datasets/lmarena-ai/leaderboard-dataset)
by `lmarena-ai`, made available under
[Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/).
PhiloEngine downloads selected Parquet shards from the dataset's Hugging Face
Hub repository and filters, maps, sorts, caches, and displays the data in its
own interface. These processing and presentation steps are modifications by
PhiloEngine and can differ from the source presentation. Attribution does not
imply that LMArena sponsors, approves, or endorses PhiloEngine.

## Independence and commercial relationships

Integrations are selected for technical coverage, user choice, hardware fit,
reach, and resilience. Their inclusion should not be read as a paid ranking or
as proof that a provider sponsored or approved PhiloEngine. No paid
recommendation or exclusive provider relationship is claimed on this page.
If a sponsorship, affiliate relationship, or other material commercial
relationship affects a future recommendation, it should be disclosed clearly
where that recommendation appears.

Service names belong to their respective owners. Integrations and source
availability may change as APIs, terms, technical compatibility, or project
needs evolve.

PhiloEngine itself is intended to remain free and open source. The planned
Phase 5 option to share self-hosted models and compute does not put existing
local functionality behind a paywall. Third-party providers, hosting,
electricity, or independently operated infrastructure can still create costs
outside the PhiloEngine software, and no private resource is shared
automatically.

## AI-assisted project development

As the project developer, I personally use AI-assisted tools while working on
PhiloEngine. I disclose this because the development process matters and
because responsibility cannot be delegated to a model. My current uses
include:

| Area | How AI assists my work |
|---|---|
| **Frontend development** | Drafting and revising Flutter/UI code, layouts, components, interactions, wording, and accessibility improvements |
| **Debugging and fault finding** | Analysing errors, logs, stack traces, failing flows, and possible root causes; proposing focused checks and fixes |
| **Security and penetration testing** | Assisting with threat modelling and controlled attack scenarios against PhiloEngine and explicitly authorized environments to identify potential vulnerabilities, unsafe inputs, permission failures, and exposed trust boundaries; suspected findings must be reproduced, assessed, and handled by a person |
| **Uploads and releases** | Preparing upload steps, release notes, checklists, and verification work; the actual upload or publication remains a deliberate human action |
| **Documentation and translation** | Drafting, editing, restructuring, and translating user-facing and developer documentation |
| **Project restructuring** | Planning clearer modules, directories, responsibilities, and migration steps before changing the project structure |
| **Code cleanup and refactoring** | Breaking down tangled, historically grown, or “spaghetti” code into smaller and more understandable units while checking that intended behaviour is preserved |

This is internal, AI-assisted development and security testing. Unless a
separate, verifiable report explicitly says otherwise, it is **not** an
independent security audit, certification, or external professional penetration
test. It cannot demonstrate that PhiloEngine is free of vulnerabilities.

AI does not independently decide what is uploaded, published, merged, or
released. It supplies proposals, drafts, explanations, and possible solutions
that I review and revise. This disclosure also does not mean that AI created
every part of PhiloEngine. The exact development tools, providers, and models
can change and are therefore not presented as a fixed inventory.

## The human review gate

People remain accountable for what enters the project. AI-generated or
AI-modified work is treated as a proposal, not as evidence that a change is
correct.

Before a change is accepted or released, a human is expected to:

1. decide whether the change belongs in the project;
2. inspect the actual diff and its effect on surrounding code or content;
3. run and evaluate the relevant tests and build checks;
4. review security, privacy, failure modes, and data boundaries;
5. check licences, attribution, and provenance where external material is
   involved; and
6. make the final merge and release decision.

PhiloEngine does not use an AI response as an unchecked automatic publication
or release decision. Passing tests also does not replace human judgement: test
coverage can be incomplete, and generated code can be plausible while still
being unsafe or wrong.

Contributors may use AI-assisted tools, but the same review, verification,
security, licence, and sign-off requirements still apply. See the
[contribution guide](../CONTRIBUTING.md) for the project-wide expectations.

## Questions and corrections

Transparency documentation should change when implementation or project
practice changes. If this page is incomplete or no longer matches observable
behaviour, please report the specific mismatch without including secrets,
private prompts, credentials, or personal data.
