from __future__ import annotations

import sys
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path
from unittest import mock


QUIKINSTALL_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(QUIKINSTALL_DIR))

import build_release  # noqa: E402


class TargetForHostTests(unittest.TestCase):
    def test_maps_every_supported_target(self) -> None:
        cases = {
            ("Linux", "x86_64"): "linux-x64",
            ("Windows", "AMD64"): "windows-x64",
            ("Darwin", "x86_64"): "macos-x64",
            ("Darwin", "arm64"): "macos-arm64",
        }
        for host, expected in cases.items():
            with self.subTest(host=host):
                self.assertEqual(build_release.target_for_host(*host), expected)

    def test_rejects_unsupported_linux_arm(self) -> None:
        with self.assertRaisesRegex(ValueError, "Unsupported release host"):
            build_release.target_for_host("Linux", "aarch64")


class VersionAndTimestampTests(unittest.TestCase):
    def test_accepts_semver_and_rejects_path_or_tag_syntax(self) -> None:
        self.assertEqual(
            build_release.validate_version("2.1.0-rc.1+build.9"),
            "2.1.0-rc.1+build.9",
        )
        for invalid in ("v1.2.3", "../1.2.3", "1.2", "01.2.3"):
            with self.subTest(version=invalid):
                with self.assertRaises(ValueError):
                    build_release.validate_version(invalid)

    def test_utc_timestamp_is_seconds_precision_rfc3339(self) -> None:
        instant = datetime(2026, 7, 26, 10, 11, 12, 987, tzinfo=timezone.utc)
        self.assertEqual(build_release.utc_timestamp(instant), "2026-07-26T10:11:12Z")

    def test_same_version_reuses_publication_time(self) -> None:
        manifest = {
            "version": "1.4.0",
            "published_at": "2026-07-25T09:00:00Z",
        }
        self.assertEqual(
            build_release.release_timestamp(
                manifest,
                "1.4.0",
                None,
                now_factory=lambda: "2026-07-26T09:00:00Z",
            ),
            "2026-07-25T09:00:00Z",
        )

    def test_timestamp_requires_rfc3339_t_separator_and_timezone(self) -> None:
        for invalid in ("2026-07-26 10:11:12Z", "2026-07-26T10:11:12"):
            with self.subTest(timestamp=invalid):
                with self.assertRaises(ValueError):
                    build_release.validate_rfc3339(invalid)


class ContractTests(unittest.TestCase):
    def test_state_uses_update_hash_for_version_directory(self) -> None:
        digest = "a" * 64
        state = build_release.build_state(
            "1.2.3",
            digest,
            "2026-07-26T10:11:12Z",
        )
        self.assertEqual(
            state,
            {
                "schema_version": 1,
                "version": "1.2.3",
                "bundle": "versions/1.2.3-aaaaaaaaaaaa",
                "asset_sha256": digest,
                "updated_at": "2026-07-26T10:11:12Z",
            },
        )

    def test_linux_asset_matches_updater_schema(self) -> None:
        digest = "b" * 64
        asset = build_release.asset_entry(
            build_release.TARGETS["linux-x64"],
            "https://example.invalid/update.tar.gz",
            digest,
            123,
        )
        self.assertEqual(
            asset,
            {
                "url": "https://example.invalid/update.tar.gz",
                "sha256": digest,
                "size": 123,
                "format": "tar.gz",
                "launcher": {
                    "path": "launcher/myphiloengine",
                    "args": [],
                },
                "backend": {
                    "path": "backend/philoengine-server",
                    "args": [],
                },
                "frontend": {
                    "path": "frontend/myphilostudio",
                    "args": [],
                },
                "health_url": "http://127.0.0.1:8080/health",
            },
        )

    def test_asset_rejects_an_empty_archive(self) -> None:
        with self.assertRaisesRegex(ValueError, "greater than zero"):
            build_release.asset_entry(
                build_release.TARGETS["linux-x64"],
                "https://example.invalid/update.tar.gz",
                "b" * 64,
                0,
            )

    def test_all_platforms_have_expected_archive_and_entrypoint_layout(self) -> None:
        expected = {
            "linux-x64": (
                "tar.gz",
                "myphiloengine",
                "philoengine-server",
                "myphilostudio",
            ),
            "windows-x64": (
                "zip",
                "myphiloengine.exe",
                "philoengine-server.exe",
                "myphilostudio.exe",
            ),
            "macos-x64": (
                "tar.gz",
                "myphiloengine",
                "philoengine-server",
                "myphilostudio.app/Contents/MacOS/myphilostudio",
            ),
            "macos-arm64": (
                "tar.gz",
                "myphiloengine",
                "philoengine-server",
                "myphilostudio.app/Contents/MacOS/myphilostudio",
            ),
        }
        for target_key, values in expected.items():
            with self.subTest(target=target_key):
                target = build_release.TARGETS[target_key]
                self.assertEqual(
                    (
                        target.archive_format,
                        target.launcher_name,
                        target.backend_name,
                        target.frontend_entrypoint,
                    ),
                    values,
                )

    def _checkout_with_probe(self, probe_name: str) -> Path:
        """Build a checkout holding every required runtime file."""

        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        for relative_path in (
            "engineworker/transformers_worker.py",
            f"tools/{probe_name}",
            "requirements-hardware.txt",
        ):
            source = root / "backend" / relative_path
            source.parent.mkdir(parents=True, exist_ok=True)
            source.write_text("", encoding="utf-8")
        return root

    def test_run_resolves_the_tool_through_path_lookup(self) -> None:



        resolved = "C:\\hostedtoolcache\\flutter\\bin\\flutter.bat"
        with mock.patch.object(build_release.shutil, "which", return_value=resolved):
            with mock.patch.object(build_release.subprocess, "run") as run:
                build_release._run(["flutter", "build", "windows"], Path("."))
        self.assertEqual(run.call_args.args[0][0], resolved)

    def test_run_reports_a_tool_that_is_not_on_path(self) -> None:
        with mock.patch.object(build_release.shutil, "which", return_value=None):
            with self.assertRaises(build_release.ReleaseBuildError) as caught:
                build_release._run(["flutter", "build", "windows"], Path("."))
        self.assertIn("flutter", str(caught.exception))

    def test_backend_payload_includes_only_required_worker_source(self) -> None:
        paths = build_release.backend_payload_paths(
            build_release.TARGETS["linux-x64"],
            self._checkout_with_probe("philoengine_hardware_probe.py"),
        )
        self.assertEqual(
            paths,
            (
                "backend/philoengine-server",
                "backend/engineworker/transformers_worker.py",
                "backend/tools/philoengine_hardware_probe.py",
                "backend/requirements-hardware.txt",
            ),
        )
        self.assertNotIn("backend/engineworker/test_transformers_worker.py", paths)
        self.assertNotIn("backend/engineworker/README.md", paths)

    def test_backend_payload_accepts_the_former_hardware_probe_name(self) -> None:


        paths = build_release.backend_payload_paths(
            build_release.TARGETS["linux-x64"],
            self._checkout_with_probe("whichllm_hardware_probe.py"),
        )
        self.assertIn("backend/tools/whichllm_hardware_probe.py", paths)
        self.assertNotIn("backend/tools/philoengine_hardware_probe.py", paths)

    def test_backend_payload_reports_a_missing_hardware_probe(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        for relative_path in (
            "engineworker/transformers_worker.py",
            "requirements-hardware.txt",
        ):
            source = root / "backend" / relative_path
            source.parent.mkdir(parents=True, exist_ok=True)
            source.write_text("", encoding="utf-8")
        with self.assertRaises(build_release.ReleaseBuildError) as caught:
            build_release.resolve_backend_runtime_files(root)
        self.assertIn("hardware_probe", str(caught.exception))

    def test_binary_payload_includes_project_and_upstream_licenses(self) -> None:
        self.assertEqual(
            build_release.legal_payload_paths(),
            (
                "LICENSE",
                "NOTICE",
                "THIRD_PARTY_NOTICES.md",
                "licenses/whichllm-MIT.txt",
            ),
        )

    def test_legal_payload_files_are_copied_with_their_contents(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary)
            build_release._copy_legal_files(destination)

            for relative_path in build_release.legal_payload_paths():
                copied = destination / relative_path
                source = build_release.PROJECT_ROOT / relative_path
                self.assertTrue(copied.is_file(), relative_path)
                self.assertEqual(copied.read_bytes(), source.read_bytes())

    def test_bundle_metadata_adds_asset_without_changing_current_state(self) -> None:
        state = {
            "schema_version": 1,
            "version": "1.2.3",
            "bundle": "versions/1.2.3-aaaaaaaaaaaa",
            "asset_sha256": "a" * 64,
            "updated_at": "2026-07-26T10:11:12Z",
        }
        asset = {"format": "tar.gz", "backend": {"path": "backend/server"}}
        metadata = build_release.bundle_metadata(state, asset)

        self.assertEqual(metadata["asset"], asset)
        self.assertNotIn("asset", state)
        self.assertIsNot(metadata["asset"], asset)

    def test_same_version_preserves_other_platform_assets(self) -> None:
        old_asset = {"sha256": "old"}
        manifest = {
            "schema_version": 1,
            "version": "1.2.3",
            "published_at": "2026-07-26T10:00:00Z",
            "assets": {"linux-x64": old_asset},
        }
        result = build_release.updated_manifest(
            manifest,
            "1.2.3",
            "2026-07-26T10:00:00Z",
            "windows-x64",
            {"sha256": "new"},
        )
        self.assertEqual(result["assets"]["linux-x64"], old_asset)
        self.assertEqual(result["assets"]["windows-x64"], {"sha256": "new"})
        self.assertIsNot(result["assets"], manifest["assets"])

    def test_new_version_drops_stale_platform_assets(self) -> None:
        manifest = {
            "schema_version": 1,
            "version": "1.2.3",
            "published_at": "2026-07-26T10:00:00Z",
            "assets": {"linux-x64": {"sha256": "old"}},
        }
        result = build_release.updated_manifest(
            manifest,
            "2.0.0",
            "2026-07-26T11:00:00Z",
            "windows-x64",
            {"sha256": "new"},
        )
        self.assertEqual(result["assets"], {"windows-x64": {"sha256": "new"}})

    def test_download_url_supports_release_and_repository_layouts(self) -> None:
        self.assertEqual(
            build_release.download_url(
                "https://example.invalid/{tag}",
                "1.2.3",
                "bundle file.tar.gz",
            ),
            "https://example.invalid/v1.2.3/bundle%20file.tar.gz",
        )


class ArtifactResolutionTests(unittest.TestCase):
    def test_normal_release_builds_backend_fresh(self) -> None:
        target = build_release.TARGETS["linux-x64"]
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / target.backend_name
            with (
                mock.patch.object(build_release, "_build_backend") as build,
                mock.patch.object(build_release, "_first_existing") as existing,
            ):
                build_release._resolve_backend(
                    None,
                    destination,
                    target,
                    build_missing=True,
                )
        build.assert_called_once_with(destination, target)
        existing.assert_not_called()

    def test_normal_release_builds_launcher_fresh(self) -> None:
        target = build_release.TARGETS["linux-x64"]
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / target.launcher_name
            with (
                mock.patch.object(build_release, "_build_launcher") as build,
                mock.patch.object(build_release, "_first_existing") as existing,
            ):
                build_release._resolve_launcher(
                    None,
                    destination,
                    target,
                    "1.2.3",
                    build_missing=True,
                )
        build.assert_called_once_with(destination, target, "1.2.3")
        existing.assert_not_called()

    def test_normal_release_builds_frontend_fresh(self) -> None:
        target = build_release.TARGETS["linux-x64"]
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / "frontend"
            built = Path(temporary) / "fresh-frontend"
            built.mkdir()
            (built / target.frontend_entrypoint).write_text(
                "frontend",
                encoding="utf-8",
            )
            with (
                mock.patch.object(
                    build_release,
                    "_build_frontend",
                    return_value=built,
                ) as build,
                mock.patch.object(build_release, "_first_existing") as existing,
            ):
                build_release._resolve_frontend(
                    None,
                    destination,
                    target,
                    "1.2.3",
                    build_missing=True,
                )
        build.assert_called_once_with(target, "1.2.3")
        existing.assert_not_called()


if __name__ == "__main__":
    unittest.main()
