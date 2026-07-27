# Third-party notices

PhiloEngine includes or integrates software from other projects. Their names
identify the upstream components and do not name PhiloEngine features.

## whichllm 0.5.15

- Upstream: <https://github.com/Andyyyy64/whichllm/tree/v0.5.15>
- License: MIT
- Copyright: Copyright (c) 2026 Andyyyy64
- License text: [`licenses/whichllm-MIT.txt`](licenses/whichllm-MIT.txt)

The PhiloEngine Hardware Detection bridge optionally imports the upstream
Python package. Portions of `backend/internal/recommender/` are adapted from
the upstream compatibility, performance, quantization, and VRAM logic.
PhiloEngine's product branding does not replace this attribution.

## Externally managed runtimes

PhiloEngine can start or manage these separately installed runtimes:

- llama.cpp — MIT — <https://github.com/ggml-org/llama.cpp>
- vLLM — Apache-2.0 — <https://github.com/vllm-project/vllm>
- Transformers — Apache-2.0 — <https://github.com/huggingface/transformers>

Models retain the licenses and usage terms published by their providers.
