#!/usr/bin/env python3
"""Merge the per-platform manifests produced by parallel release builds.

Each platform is built on its own machine, so every build writes a manifest
holding only its own asset. Publishing needs the union of those assets under one
version.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any, Mapping, Sequence

sys.path.insert(0, str(Path(__file__).resolve().parent))

from build_release import (  # noqa: E402
    SCHEMA_VERSION,
    ReleaseBuildError,
    load_manifest,
    validate_rfc3339,
    validate_version,
    write_json_atomic,
)


def merge_manifests(manifests: Sequence[Mapping[str, Any]]) -> dict[str, Any]:
    """Combine per-platform manifests of one version into a single manifest."""

    if not manifests:
        raise ReleaseBuildError("No manifests to merge")

    version: str | None = None
    published_at = ""
    assets: dict[str, Any] = {}
    for manifest in manifests:
        if manifest.get("schema_version") != SCHEMA_VERSION:
            raise ReleaseBuildError(
                f"Unsupported manifest schema {manifest.get('schema_version')!r}"
            )
        current = validate_version(str(manifest.get("version", "")))
        if version is None:
            version = current
        elif current != version:
            # Publishing a mixed-version manifest would offer users a platform
            # build that does not match the release they are being told about.
            raise ReleaseBuildError(
                f"Refusing to merge different versions: {version} and {current}"
            )
        if stamp := manifest.get("published_at", ""):
            validate_rfc3339(str(stamp))
            published_at = max(published_at, str(stamp))
        for platform, asset in (manifest.get("assets") or {}).items():
            existing = assets.get(platform)
            if existing is not None and existing != asset:
                raise ReleaseBuildError(
                    f"Conflicting assets for platform {platform!r}"
                )
            assets[platform] = asset

    if not assets:
        raise ReleaseBuildError("Merged manifest would contain no assets")
    merged: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "version": version,
        "assets": assets,
    }
    if published_at:
        merged["published_at"] = published_at
    return merged


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifests", nargs="+", type=Path, help="per-platform manifests")
    parser.add_argument("--output", required=True, type=Path, help="merged manifest")
    arguments = parser.parse_args(argv)

    try:
        merged = merge_manifests([load_manifest(path) for path in arguments.manifests])
    except ReleaseBuildError as error:
        print(f"manifest merge failed: {error}", file=sys.stderr)
        return 1
    write_json_atomic(arguments.output, merged)
    platforms = ", ".join(sorted(merged["assets"]))
    print(f"Merged {merged['version']} for: {platforms}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
