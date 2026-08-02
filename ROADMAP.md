<h1 align="center">PhiloEngine Roadmap</h1>

<p align="center">
  <strong>Build on what already works, improve it carefully, and open the next capabilities in clear phases.</strong>
</p>

<p align="center">
  <strong>English</strong> · <a href="de/ROADMAP.md">Deutsch</a>
</p>

<p align="center">
  <img alt="Roadmap status: Phase 1" src="https://img.shields.io/badge/current-Phase%201-C9A24A?style=for-the-badge&amp;labelColor=0A0A0B">
  <img alt="Project maturity: Alpha" src="https://img.shields.io/badge/maturity-Alpha-F59E0B?style=for-the-badge&amp;labelColor=0A0A0B">
</p>

> **Last updated:** 2 August 2026  
> This is a living roadmap. It defines direction and dependency order, not
> guaranteed release dates.

[← README](README.md) · [Features](docs/FEATURES.md) · [Installation](docs/INSTALLATION.md) · [Contributing](CONTRIBUTING.md)

> [!NOTE]
> Checked items describe the current development tree, not automatically the
> latest packaged release. Check the corresponding release notes before treating
> a roadmap item as shipped.

## Roadmap at a glance

~~~mermaid
timeline
    title PhiloEngine development — five dependent phases, no fixed release dates
    NOW — Phase 1 : Consolidate the existing modules
                  : Complete the frontend overhaul
                  : Fix bugs and strengthen documentation
    NEXT — Phase 2 : Extend and improve current features
                   : Connect external servers to Chat and Engine
                   : Deepen reliability, performance, and accessibility
    LATER — Phase 3 : Make full fine-tuning and fine-tuning guided
                    : Make quantization guided and approachable
                    : Keep jobs reproducible and recoverable
    FUTURE — Phase 4 : Add image and video generation
                     : Develop a game-development workspace
                     : Reuse local and optional hosted runtimes
    LONG TERM — Phase 5 : Share self-hosted models by explicit opt-in
                         : Make compute capacity available safely
                         : Keep PhiloEngine itself free and open source
~~~

<details>
<summary><strong>Text version of the timeline</strong></summary>

1. **Phase 1 — now:** consolidate the modules that already exist, complete the
   frontend overhaul, fix bugs, improve usability, and finish the documentation.
2. **Phase 2 — next:** extend and improve the current functionality and make
   configured external servers usable from Chat and Engine.
3. **Phase 3 — later:** provide guided, easy-to-use workflows for full
   fine-tuning, other fine-tuning paths, model conversion, and quantization.
4. **Phase 4 — future:** develop image and video generation together with a
   dedicated game-development workspace.
5. **Phase 5 — long term:** allow owners to offer self-hosted AI models and
   compute capacity voluntarily while following the project's commitment to
   keep the PhiloEngine software free and open source.

</details>

| Phase | Position | Main outcome |
|:---|:---:|:---|
| **Phase 1** | Now | A coherent, dependable version of the product that already exists |
| **Phase 2** | Next | Deeper existing features and practical external-server connections |
| **Phase 3** | Later | Guided full fine-tuning, fine-tuning, and quantization |
| **Phase 4** | Future | Image, video, and game-development workflows |
| **Phase 5** | Long term | Opt-in access to self-hosted models and shared compute |

The order describes dependencies. A later phase starts only when the earlier
foundation is reliable enough to support it.

## 🟡 Phase 1 — consolidate the current product

**Goal:** improve the state that already exists instead of presenting every
new idea as immediate active development.

### Available foundation

- [x] Chat with local model instances
- [x] Chat with supported OpenRouter and Featherless models
- [x] Hardware detection, memory planning, and managed local runtimes
- [x] Marketplace for local downloads and supported API models
- [x] PhiloBots, projects, tool events, permissions, and readable diffs
- [x] Per-user and per-project memory infrastructure
- [x] Text metasearch and public-page extraction
- [x] News with feeds, filters, search, and saved articles
- [x] LMArena Text benchmark overview, ranking, details, and comparison
- [x] Authentication, settings, German/English, and Classic/Lite modes
- [x] Cross-platform release and update foundations

### Current work

- [ ] Complete the visual and interaction overhaul across the existing frontend
- [ ] Improve current functions and finish incomplete end-to-end flows
- [ ] Fix known bugs and prevent regressions with focused tests
- [ ] Harmonize navigation, responsive layouts, loading, empty, and error states
- [ ] Improve performance and accessibility where the current UI needs it
- [ ] Keep English and German documentation complete and consistent
- [ ] Verify release packages, updates, rollback, and offline restart behavior

### Active workstreams

| Workstream | Intended result |
|:---|:---|
| **Frontend overhaul** | A consistent, clearer interface across every existing module |
| **Feature refinement** | Existing controls and workflows behave completely and predictably |
| **Bug fixing** | Known defects and regressions are reproduced, fixed, and covered by tests |
| **Documentation** | README, roadmap, installation, privacy, architecture, and help stay aligned |
| **Release readiness** | Supported packages start, update, recover, and work offline as documented |

### Phase 1 exit criteria

Phase 2 begins when:

- the frontend overhaul is coherent across the available modules;
- visible core controls either work end to end or are clearly unavailable;
- no known critical authentication, data-loss, update, or project-boundary
  defect remains open;
- News and Benchmark fail safely when an external source is unavailable;
- supported release packages pass their checks;
- the English and German documentation matches the released state.

There is no fixed completion date. Stability and a comprehensible user
experience take priority over an artificial deadline.

## 🔵 Phase 2 — extend the current features and connect external servers

**Goal:** deepen the existing product and make remote systems intentional,
testable parts of normal workflows.

| Planned area | Intended result |
|:---|:---|
| Existing modules | More complete Chat, Engine, Marketplace, Memory, Search, News, Benchmark, PhiloBot, and settings workflows |
| External servers | Saved and tested server profiles can become active Chat or Engine connections |
| Connection control | Clear endpoint, authentication, capability, health, latency, and failure information |
| Runtime and hardware coverage | More reliable operation across real GPUs, drivers, model formats, and CPU-only systems |
| Performance | Faster startup, lower UI overhead, and smoother large-model catalogues |
| Accessibility | Better keyboard use, focus, contrast, scaling, and screen-reader behavior |
| Reliability | Stronger recovery, migration, update verification, and integration tests |

External-server support must remain explicit. Users should be able to see which
server handles a request and whether data leaves the local machine.

## 🟣 Phase 3 — guided fine-tuning and quantization

**Goal:** make advanced model work approachable without hiding the controls
needed by experienced users.

### Full fine-tuning and fine-tuning

- Guided project setup from dataset selection to an exportable result
- Dataset import, validation, preparation, and clear error reporting
- A deliberate choice between full fine-tuning and more resource-conscious
  fine-tuning paths
- Hardware and storage checks before a job starts
- Reproducible configuration, checkpoints, pause, resume, cancel, and recovery
- Evaluation, provenance, and comparison with the source model
- Simple defaults with an optional expert configuration path

### Quantization and conversion

- Guided selection of source model, target format, and quantization level
- Understandable quality, size, memory, and compatibility trade-offs
- Hardware-aware preflight checks and storage planning
- Reproducible conversion jobs with progress, logs, cancel, and recovery
- Validation of the generated model before it is added to the Engine

The current Training and Quantization screens are locked design previews. They
do not start backend jobs today.

## ⚫ Phase 4 — image, video, and game development

**Goal:** extend PhiloEngine beyond language models while retaining visible
runtime choices, hardware planning, and local-first control.

### Image and video generation

- Local and optional provider-backed generation
- Visible models, runtimes, parameters, storage, and provenance
- Reusable workflows for generation, iteration, and export
- Hardware-aware planning and recoverable jobs

### Game-development workspace

- A dedicated module for assisted game-development workflows
- Organized generation and iteration of project assets
- Project-aware assistance for concepts, content, and implementation work
- Clear export boundaries instead of pretending to replace a complete game engine

The detailed scope will be refined after Phases 1–3 provide a stable base.

## ⚪ Phase 5 — self-hosted models and shared compute

**Goal:** let users voluntarily make their own hosted AI models and compute
capacity available to others.

Planned principles:

- sharing is disabled by default and requires explicit owner opt-in;
- owners control available models, capacity, limits, access, and revocation;
- clients see where a request is processed and what data is sent;
- authentication, isolation, abuse protection, job limits, and auditability are
  required before public sharing;
- local use remains possible without participating in shared compute;
- no private model or machine is made available automatically.

**PhiloEngine's current project commitment is to keep the software free and
open source.** This commitment describes the project's direction; it is not a
legal guarantee about the future availability or pricing of independent
services. Phase 5 is not intended to place existing local functionality behind
a paywall. Third-party API providers, hosting, electricity, or independently
operated infrastructure can still create costs outside the PhiloEngine
software.

## Recently completed foundations

- Cross-platform release bundles for Linux x64, Windows x64, and macOS ARM64
- Atomic bundle activation with rollback and quarantine of failed updates
- German/English account preferences and Classic/Lite modes
- Hardware-aware Marketplace and Engine planning
- Project-scoped PhiloBot sessions and persistent Memory infrastructure
- Native News and Benchmark modules in the current development tree

## How this roadmap stays useful

The roadmap is updated when:

1. a planned capability becomes current work;
2. a release changes the available feature set;
3. a phase exit criterion is completed or changed;
4. a planned item is removed, delayed, or replaced.

Avoid progress percentages unless they are based on measurable tasks.
Checklists, exit criteria, tests, and release notes provide a more honest view.
Security defects, data-loss risks, broken updates, and regressions can reorder
the work at any time.

## Follow progress or contribute

- Review the detailed [feature status](docs/FEATURES.md).
- Check [GitHub releases](https://github.com/kuchenboss/MyPhiloEngine/releases)
  for what is actually shipped.
- Use the [contribution guide](CONTRIBUTING.md) before proposing or implementing
  a roadmap item.
- Report security issues privately as described in the
  [security policy](https://github.com/kuchenboss/MyPhiloEngine/blob/main/SECURITY.md).
