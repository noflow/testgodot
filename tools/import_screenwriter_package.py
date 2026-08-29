#!/usr/bin/env python3
"""Preview and safely import a Screenwriter game package into Port Alder."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
PACKAGE_FORMAT = "scenewright.game_package"
PACKAGE_TARGET = "port_alder_godot"
WORLD_PATHS = {
    "content/world/all_locations.json",
    "content/world/scenewright_custom_locations.json",
}


class PackageError(ValueError):
    """A package is unsafe or incompatible with this project."""


@dataclass(frozen=True)
class PreviewRow:
    status: str
    path: str
    kind: str
    content_text: str


def _fnv1a(data: bytes) -> str:
    value = 2166136261
    for byte in data:
        value ^= byte
        value = (value * 16777619) & 0xFFFFFFFF
    return f"fnv1a-{value:08x}"


def _checksum(text: str, expected: str) -> str:
    if expected.startswith("fnv1a-"):
        return _fnv1a(text.encode("utf-8"))
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def _safe_relative_path(raw: Any) -> str:
    value = str(raw or "")
    path = PurePosixPath(value)
    if not value or path.is_absolute() or ".." in path.parts or "." in path.parts:
        raise PackageError(f"Unsafe package path: {value or '(empty)'}")
    normalized = path.as_posix()
    is_character = (
        len(path.parts) == 2
        and path.parts[0] == "characters"
        and path.suffix == ".character"
        and path.stem.replace("_", "").isalnum()
        and path.stem == path.stem.lower()
    )
    if not is_character and normalized not in WORLD_PATHS:
        raise PackageError(f"Package may not write outside supported content paths: {normalized}")
    return normalized


def _parse_content(file_entry: dict[str, Any], relative_path: str) -> tuple[str, dict[str, Any]]:
    text = file_entry.get("content_text")
    if not isinstance(text, str) or not text.strip():
        raise PackageError(f"{relative_path}: missing JSON content")
    expected = str(file_entry.get("checksum", ""))
    if not expected or _checksum(text, expected) != expected:
        raise PackageError(f"{relative_path}: checksum does not match its content")
    try:
        document = json.loads(text)
    except json.JSONDecodeError as exc:
        raise PackageError(f"{relative_path}: invalid JSON at line {exc.lineno}: {exc.msg}") from exc
    if not isinstance(document, dict):
        raise PackageError(f"{relative_path}: JSON root must be an object")
    return text, document


def _validate_document(relative_path: str, document: dict[str, Any]) -> None:
    if relative_path.startswith("characters/"):
        expected_id = PurePosixPath(relative_path).stem
        if document.get("format_version") != 1:
            raise PackageError(f"{relative_path}: character format_version must be 1")
        if document.get("id") != expected_id:
            raise PackageError(f"{relative_path}: character id must match the file name")
        if not str(document.get("display_name", "")).strip():
            raise PackageError(f"{relative_path}: character requires a display_name")
        return
    if not isinstance(document.get("locations"), list):
        raise PackageError(f"{relative_path}: location package requires a locations list")
    if relative_path.endswith("all_locations.json"):
        if document.get("package_id") != "port_alder_all_locations":
            raise PackageError(f"{relative_path}: package_id must remain port_alder_all_locations")
        if not isinstance(document.get("districts"), list):
            raise PackageError(f"{relative_path}: canonical world package requires districts")
    elif document.get("package_id") != "scenewright_custom_locations":
        raise PackageError(f"{relative_path}: custom location package has the wrong package_id")


def load_package(package_path: Path) -> dict[str, Any]:
    try:
        package = json.loads(package_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise PackageError(f"Could not read package: {exc}") from exc
    if not isinstance(package, dict) or package.get("format") != PACKAGE_FORMAT:
        raise PackageError(f"Expected {PACKAGE_FORMAT} format")
    if package.get("format_version") != 1:
        raise PackageError("Only Screenwriter game package format_version 1 is supported")
    if package.get("target") != PACKAGE_TARGET:
        raise PackageError(f"Package target must be {PACKAGE_TARGET}")
    package_id = str(package.get("package_id", ""))
    if not re.fullmatch(r"[a-z0-9]+(?:_[a-z0-9]+)*", package_id):
        raise PackageError("Package id must use lowercase words joined by underscores")
    if not isinstance(package.get("version"), int) or package["version"] < 1:
        raise PackageError("Package version must be a positive integer")
    if package.get("scope") not in {"changed", "full"}:
        raise PackageError("Package scope must be changed or full")
    validation = package.get("validation", {})
    if isinstance(validation, dict) and int(validation.get("blockers", 0)):
        raise PackageError("Package reports unresolved blocking validation issues")
    files = package.get("files")
    if not isinstance(files, list) or not files:
        raise PackageError("Package contains no deployable files")
    manifest = package.get("manifest")
    if not isinstance(manifest, dict) or not isinstance(manifest.get("files"), list):
        raise PackageError("Package has no file manifest")
    manifest_text = json.dumps(manifest["files"], ensure_ascii=False, separators=(",", ":"))
    manifest_checksum = str(manifest.get("checksum", ""))
    if not manifest_checksum or _checksum(manifest_text, manifest_checksum) != manifest_checksum:
        raise PackageError("Package manifest checksum does not match")
    if manifest.get("file_count") != len(files) or len(manifest["files"]) != len(files):
        raise PackageError("Package manifest file count does not match its payload")
    return package


def preview_package(package: dict[str, Any], project_root: Path) -> list[PreviewRow]:
    rows: list[PreviewRow] = []
    seen: set[str] = set()
    manifest_files = package["manifest"]["files"]
    for file_value in package["files"]:
        if not isinstance(file_value, dict):
            raise PackageError("Package file manifest contains a non-object entry")
        relative_path = _safe_relative_path(file_value.get("path"))
        if relative_path in seen:
            raise PackageError(f"Package contains the same path twice: {relative_path}")
        seen.add(relative_path)
        manifest_match = next((row for row in manifest_files
            if isinstance(row, dict) and row.get("path") == relative_path), None)
        if manifest_match is None or manifest_match.get("checksum") != file_value.get("checksum"):
            raise PackageError(f"{relative_path}: payload does not match its manifest entry")
        if file_value.get("operation") not in {"add", "replace"}:
            raise PackageError(f"{relative_path}: unsupported operation; imports never delete content")
        text, document = _parse_content(file_value, relative_path)
        _validate_document(relative_path, document)
        target = project_root / relative_path
        if not target.exists():
            status = "ADD"
        else:
            try:
                status = "UNCHANGED" if json.loads(target.read_text(encoding="utf-8")) == document else "UPDATE"
            except (OSError, json.JSONDecodeError):
                status = "UPDATE"
        rows.append(PreviewRow(status, relative_path, str(file_value.get("kind", "content")), text))
    return rows


def reported_removals(package: dict[str, Any]) -> list[str]:
    manifest = package.get("manifest", {})
    values = manifest.get("removed_paths", []) if isinstance(manifest, dict) else []
    if not isinstance(values, list):
        raise PackageError("manifest.removed_paths must be a list")
    return [_safe_relative_path(value) for value in values]


def _atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.screenwriter.tmp")
    with temporary.open("w", encoding="utf-8", newline="") as handle:
        handle.write(text)
    os.replace(temporary, path)


def _restore(project_root: Path, backup_root: Path, changed: list[str], added: list[str]) -> None:
    for relative_path in added:
        target = project_root / relative_path
        if target.exists():
            target.unlink()
    for relative_path in changed:
        backup = backup_root / relative_path
        if backup.exists():
            target = project_root / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(backup, target)


def apply_package(
    package: dict[str, Any], project_root: Path, rows: list[PreviewRow], *, validate: bool = True
) -> Path | None:
    writable = [row for row in rows if row.status != "UNCHANGED"]
    if not writable:
        return None
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    backup_root = project_root / ".screenwriter-backups" / f"{package['package_id']}-v{package.get('version', 1)}-{stamp}"
    changed: list[str] = []
    added: list[str] = []
    try:
        for row in writable:
            target = project_root / row.path
            if target.exists():
                backup = backup_root / row.path
                backup.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(target, backup)
                changed.append(row.path)
            else:
                added.append(row.path)
            _atomic_write(target, row.content_text)
        if validate:
            validator = project_root / "tools" / "validate_characters.py"
            if validator.is_file():
                result = subprocess.run(
                    [sys.executable, str(validator)], cwd=project_root,
                    capture_output=True, text=True, check=False
                )
                if result.returncode:
                    detail = (result.stderr or result.stdout).strip()
                    raise PackageError(f"Project validation failed after import:\n{detail}")
    except Exception:
        _restore(project_root, backup_root, changed, added)
        raise
    receipt = {
        "format": "scenewright.import_receipt",
        "package_id": package["package_id"],
        "version": package.get("version", 1),
        "imported_at": datetime.now(timezone.utc).isoformat(),
        "updated": changed,
        "added": added,
    }
    _atomic_write(backup_root / "receipt.json", json.dumps(receipt, indent=2) + "\n")
    return backup_root


def _print_preview(package: dict[str, Any], rows: list[PreviewRow], removals: list[str]) -> None:
    print(f"Screenwriter package: {package['package_id']} v{package.get('version', 1)}")
    print(f"Scope: {package.get('scope', 'changed')} · {len(rows)} deployable file(s)")
    for row in rows:
        print(f"{row.status:9} {row.path} ({row.kind})")
    for relative_path in removals:
        print(f"KEEP      {relative_path} (reported removed; deletion is disabled)")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Preview or safely import a .screenwriter-package into the Port Alder Godot project."
    )
    parser.add_argument("package", type=Path, help="Package downloaded from Screenwriter")
    parser.add_argument("--project-root", type=Path, default=ROOT, help="Port Alder project directory")
    parser.add_argument("--apply", action="store_true", help="Write the previewed changes; default is dry-run")
    parser.add_argument("--skip-project-validation", action="store_true", help="Skip the post-write character validator")
    args = parser.parse_args()
    try:
        project_root = args.project_root.resolve()
        package = load_package(args.package.resolve())
        rows = preview_package(package, project_root)
        removals = reported_removals(package)
        _print_preview(package, rows, removals)
        if not args.apply:
            print("Dry run only. Re-run with --apply to import these files.")
            return 0
        backup = apply_package(package, project_root, rows, validate=not args.skip_project_validation)
        if backup is None:
            print("Nothing changed; every packaged file already matches the project.")
        else:
            print(f"Import complete. Recoverable backups: {backup}")
        return 0
    except PackageError as exc:
        print(f"Screenwriter package import failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
