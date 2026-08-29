#!/usr/bin/env python3
"""Regression tests for the safe Screenwriter package importer."""

from __future__ import annotations

import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from import_screenwriter_package import PackageError, apply_package, preview_package, reported_removals


def entry(path: str, document: dict, *, operation: str = "replace") -> dict:
    text = json.dumps(document, indent=2) + "\n"
    return {
        "path": path,
        "kind": "character" if path.endswith(".character") else "world",
        "id": document.get("id", document.get("package_id", "")),
        "operation": operation,
        "checksum": hashlib.sha256(text.encode()).hexdigest(),
        "content_text": text,
    }


class ScreenwriterPackageImportTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "characters").mkdir()
        self.alexa = {"format_version": 1, "id": "alexa", "display_name": "Alexa"}
        (self.root / "characters" / "alexa.character").write_text(
            json.dumps(self.alexa) + "\n", encoding="utf-8"
        )

    def tearDown(self) -> None:
        self.temp.cleanup()

    def package(self, files: list[dict]) -> dict:
        manifest_files = [
            {key: value for key, value in file.items() if key != "content_text"}
            for file in files
        ]
        manifest_checksum = hashlib.sha256(json.dumps(
            manifest_files, ensure_ascii=False, separators=(",", ":")
        ).encode()).hexdigest()
        return {
            "format": "scenewright.game_package",
            "format_version": 1,
            "target": "port_alder_godot",
            "package_id": "test_package",
            "version": 2,
            "scope": "full",
            "validation": {"blockers": 0, "warnings": 0},
            "manifest": {"file_count": len(files), "files": manifest_files,
                "checksum": manifest_checksum,
                "removed_paths": ["characters/retired.character"]},
            "files": files,
        }

    def test_preview_reports_unchanged_updated_and_added(self) -> None:
        beth = {"format_version": 1, "id": "beth", "display_name": "Beth"}
        updated = {**self.alexa, "display_name": "Alexa Updated"}
        rows = preview_package(
            self.package([
                entry("characters/alexa.character", self.alexa),
                entry("characters/beth.character", beth, operation="add"),
                entry("content/world/scenewright_custom_locations.json", {
                    "format_version": 1,
                    "package_id": "scenewright_custom_locations",
                    "locations": [],
                }, operation="add"),
            ]),
            self.root,
        )
        self.assertEqual([row.status for row in rows], ["UNCHANGED", "ADD", "ADD"])
        updated_rows = preview_package(self.package([entry("characters/alexa.character", updated)]), self.root)
        self.assertEqual(updated_rows[0].status, "UPDATE")

    def test_apply_writes_and_creates_recoverable_backup(self) -> None:
        updated = {**self.alexa, "display_name": "Alexa Updated"}
        beth = {"format_version": 1, "id": "beth", "display_name": "Beth"}
        package = self.package([
            entry("characters/alexa.character", updated),
            entry("characters/beth.character", beth, operation="add"),
        ])
        rows = preview_package(package, self.root)
        backup = apply_package(package, self.root, rows, validate=False)
        self.assertIsNotNone(backup)
        self.assertEqual(json.loads((self.root / "characters/alexa.character").read_text()), updated)
        self.assertEqual(json.loads((self.root / "characters/beth.character").read_text()), beth)
        self.assertEqual(json.loads((backup / "characters/alexa.character").read_text()), self.alexa)
        self.assertTrue((backup / "receipt.json").is_file())
        self.assertEqual(reported_removals(package), ["characters/retired.character"])

    def test_rejects_traversal_checksum_mismatch_and_id_mismatch(self) -> None:
        bad = entry("characters/alexa.character", self.alexa)
        bad["checksum"] = "0" * 64
        with self.assertRaisesRegex(PackageError, "checksum"):
            preview_package(self.package([bad]), self.root)
        with self.assertRaisesRegex(PackageError, "outside supported|Unsafe"):
            preview_package(self.package([{**entry("characters/alexa.character", self.alexa),
                "path": "../project.godot"}]), self.root)
        with self.assertRaisesRegex(PackageError, "id must match"):
            preview_package(self.package([entry("characters/wrong.character", self.alexa)]), self.root)


if __name__ == "__main__":
    unittest.main()
