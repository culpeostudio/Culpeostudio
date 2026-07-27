#!/usr/bin/env python3
"""JSON bridge for PhiloEngine Hardware Detection.

The Go API owns routing, live resource data, normalization, and caching. This
small adapter delegates the optional cross-platform base probe to the external
``whichllm`` package so its NVIDIA/AMD/Intel/Apple support can evolve without
putting platform-specific shell parsing into HTTP handlers.

The adapter is PhiloEngine code. The external dependency is MIT-licensed; see
the repository NOTICE for provenance and the complete license notice.
"""

from __future__ import annotations

import json
import sys

from whichllm.hardware.detector import detect_hardware


def main() -> int:
    try:
        hardware = detect_hardware()
        payload = {
            "os": hardware.os,
            "cpu_name": hardware.cpu_name,
            "cpu_cores": hardware.cpu_cores,
            "has_avx2": hardware.has_avx2,
            "has_avx512": hardware.has_avx512,
            "ram_bytes": hardware.ram_bytes,
            "disk_free_bytes": hardware.disk_free_bytes,
            "gpus": [
                {
                    "name": gpu.name,
                    "vendor": gpu.vendor,
                    "vram_bytes": gpu.vram_bytes,
                    "usable_vram_bytes": gpu.usable_vram_bytes,
                    "memory_bandwidth_gbps": gpu.memory_bandwidth_gbps,
                    "shared_memory": gpu.shared_memory,
                    "compute_capability": gpu.compute_capability,
                }
                for gpu in hardware.gpus
            ],
        }
    except Exception as exc:  # The Go caller falls back to its local probe.
        payload = {"error": f"{type(exc).__name__}: {exc}"}

    json.dump(payload, sys.stdout, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
