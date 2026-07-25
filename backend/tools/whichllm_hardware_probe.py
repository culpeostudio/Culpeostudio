#!/usr/bin/env python3
"""Stable JSON bridge to whichllm's cross-platform hardware detector.

The Go API owns routing and caching.  This helper deliberately owns only
hardware probing, so whichllm's tested NVIDIA/AMD/Intel/Apple logic can evolve
without putting platform-specific shell parsing into HTTP handlers.
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
