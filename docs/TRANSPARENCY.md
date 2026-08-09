# Transparency and disclosure

This page explains who maintains Culpeo Studio, where AI tools are used during development, and why the project uses its current providers and news sources.

---

## 1. Primary Human Authorship & Software Engineering

Culpeo Studio is designed, architected, and coded **primarily by the human developer**.

The vast majority of the source code—including the Go gRPC backend services (`backend/`), the Flutter desktop user interface (`frontend/`), local inference management, hardware planner algorithms, and memory database integrations—is **manually written and maintained by the author**.

AI is used as a supporting tool alongside manual development. The developer reviews the resulting code and remains responsible for the software.

---

## 2. Role of AI as an Assistive Tool

When AI tools are used, they help with tasks such as:

- **Secondary Code & UX Auditing:** Assisting in identifying edge-case UI overflows in Flutter or inspecting code for potential race conditions.
- **Security & Penetration Testing Ideas:** Serving as a sounding board to brainstorm security test vectors, path traversal scenarios, and permission boundary checks.
- **Consultation & Brainstorming:** Acting as an advisory partner when exploring architectural trade-offs or reviewing mathematical formulations for RAM/VRAM probes.
- **Repository Administration Support:** Assisting with drafting release notes, documentation formatting, and issue template structure.
- **Marketing Media & Asset Generation:** Assisting in generating promotional background imagery, splash screen illustrations, and demo media assets.

Final code, architecture decisions, and security changes are reviewed and verified by the developer.

---

## 3. Provider & Source Selection Rationale

### Marketplace & API Providers

Culpeo Studio integrates Hugging Face, OpenRouter, and Featherless into a unified marketplace grid:

- **Hugging Face:** Selected as the primary source for local model downloads because it is the global open-source community standard for hosting open weights, GGUF quantizations, and model metadata.
- **OpenRouter:** Chosen to provide optional access to hosted open and proprietary language models through a single, standardized API key with transparent per-token pricing.
- **Featherless:** Integrated to offer serverless open-weights model inference, allowing users to test large models that exceed local hardware capabilities without subscription lock-in.

### News Sources & Feed Selection

The News module aggregates public AI and technology news sources:

- **Selection Criteria:** Sources are selected based on technical relevance to artificial intelligence, software engineering, and hardware developments.
- **Public Standards:** Feeds utilize standard RSS/Atom endpoints and compliant HTML extraction. Articles are cached locally and sanitized to protect user privacy.

---

## 4. Commitment to Open Source

Culpeo Studio is **100% free and open source** under the [GNU AGPL-3.0 License](../LICENSE). Core local features will remain independent and will never be placed behind paywalls.
