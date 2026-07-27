from __future__ import annotations

import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import build_release  # noqa: E402
import merge_manifests  # noqa: E402


def platform_manifest(
    platform: str, version: str = "1.1.0-alpha", published_at: str = ""
) -> dict:
    manifest = {
        "schema_version": 1,
        "version": version,
        "assets": {
            platform: {
                "url": f"https://example.invalid/{platform}.tar.gz",
                "sha256": "a" * 64,
                "size": 1234,
                "format": "tar.gz",
                "launcher": {"path": "launcher/myphiloengine", "args": []},
                "backend": {"path": "backend/philoengine-server", "args": []},
                "frontend": {"path": "frontend/myphilostudio", "args": []},
                "health_url": "http://127.0.0.1:8080/health",
            }
        },
    }
    if published_at:
        manifest["published_at"] = published_at
    return manifest


class MergeManifestsTest(unittest.TestCase):
    def test_merges_every_platform_of_one_version(self) -> None:
        merged = merge_manifests.merge_manifests(
            [
                platform_manifest("linux-x64", published_at="2026-07-27T10:00:00Z"),
                platform_manifest("macos-arm64", published_at="2026-07-27T11:00:00Z"),
                platform_manifest("windows-x64"),
            ]
        )
        self.assertEqual(merged["version"], "1.1.0-alpha")
        self.assertEqual(
            sorted(merged["assets"]), ["linux-x64", "macos-arm64", "windows-x64"]
        )
        # The newest build stamps the release, so the manifest never claims to
        # predate an asset it points at.
        self.assertEqual(merged["published_at"], "2026-07-27T11:00:00Z")

    def test_refuses_to_mix_versions(self) -> None:
        with self.assertRaises(build_release.ReleaseBuildError) as caught:
            merge_manifests.merge_manifests(
                [
                    platform_manifest("linux-x64", version="1.1.0-alpha"),
                    platform_manifest("windows-x64", version="1.1.0"),
                ]
            )
        self.assertIn("different versions", str(caught.exception))

    def test_refuses_conflicting_assets_for_one_platform(self) -> None:
        other = platform_manifest("linux-x64")
        other["assets"]["linux-x64"]["sha256"] = "b" * 64
        with self.assertRaises(build_release.ReleaseBuildError):
            merge_manifests.merge_manifests([platform_manifest("linux-x64"), other])

    def test_refuses_an_empty_merge(self) -> None:
        with self.assertRaises(build_release.ReleaseBuildError):
            merge_manifests.merge_manifests([])

    def test_cli_writes_the_merged_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            inputs = []
            for platform in ("linux-x64", "windows-x64"):
                path = root / f"{platform}.json"
                build_release.write_json_atomic(path, platform_manifest(platform))
                inputs.append(str(path))
            output = root / "manifest.json"
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(
                    merge_manifests.main([*inputs, "--output", str(output)]), 0
                )
            merged = build_release.load_manifest(output)
            self.assertEqual(sorted(merged["assets"]), ["linux-x64", "windows-x64"])


if __name__ == "__main__":
    unittest.main()
