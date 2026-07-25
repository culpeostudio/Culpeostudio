# PhiloEngine model workers

`transformers_worker.py` is launched only by the Go runtime supervisor from its
versioned virtual environment. It exposes loopback-only health and OpenAI-style
completion routes. The worker always uses `local_files_only=True`, defaults to
`trust_remote_code=False`, and never changes checkpoint weight quantization.
Every route, including `/health`, requires the random per-process bearer secret
provided by the Go adapter; that secret is never part of serialized configs.

KV-cache selection is independent of model weights:

- `quanto_4bit`: Transformers `QuantizedCache` with `optimum-quanto` at 4 bit
- `offloaded`: Transformers offloaded KV cache
- `native`: backend default KV cache
