#!/usr/bin/env python3
"""Check Screenwriter .character exports before they replace canonical game data."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CANONICAL = ROOT / "characters"
QUEST_CONTRACT_FIELDS = (
    "discovery",
    "requirements",
    "availability",
    "repeatable",
    "timing",
)


def load_sheets(path: Path) -> tuple[dict[str, dict[str, Any]], list[str]]:
    errors: list[str] = []
    files = [path] if path.is_file() else sorted(path.glob("*.character"))
    sheets: dict[str, dict[str, Any]] = {}
    if not files:
        return {}, [f"No .character files found at {path}"]
    for file_path in files:
        try:
            sheet = json.loads(file_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            errors.append(f"{file_path}: invalid JSON: {exc}")
            continue
        character_id = sheet.get("id") if isinstance(sheet, dict) else None
        if not isinstance(character_id, str) or not character_id:
            errors.append(f"{file_path}: missing character id")
            continue
        if character_id in sheets:
            errors.append(f"{file_path}: duplicate character id {character_id}")
            continue
        sheets[character_id] = sheet
    return sheets, errors


def compact(value: Any) -> str:
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(",", ":"))


def quest_index(sheet: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        quest["id"]: quest
        for quest in sheet.get("quests", [])
        if isinstance(quest, dict) and isinstance(quest.get("id"), str)
    }


def validate_contract(
    canonical: dict[str, dict[str, Any]], exported: dict[str, dict[str, Any]], exact: bool
) -> list[str]:
    errors: list[str] = []
    missing = sorted(set(canonical) - set(exported))
    unexpected = sorted(set(exported) - set(canonical))
    if missing:
        errors.append(f"Export is missing character sheets: {', '.join(missing)}")
    if unexpected:
        errors.append(f"Export contains unexpected character sheets: {', '.join(unexpected)}")

    for character_id in sorted(set(canonical) & set(exported)):
        before = canonical[character_id]
        after = exported[character_id]
        if exact:
            if before != after:
                errors.append(f"{character_id}: exact no-edit round trip changed the character sheet")
            continue

        if after.get("format_version") != 1:
            errors.append(f"{character_id}: format_version must remain 1")
        before_quests = quest_index(before)
        after_quests = quest_index(after)
        for quest_id in sorted(set(before_quests) & set(after_quests)):
            old_quest = before_quests[quest_id]
            new_quest = after_quests[quest_id]
            for field in QUEST_CONTRACT_FIELDS:
                if field in old_quest and old_quest.get(field) != new_quest.get(field):
                    errors.append(
                        f"{character_id}.{quest_id}: Screenwriter changed protected quest field "
                        f"{field} ({compact(old_quest.get(field))} -> {compact(new_quest.get(field))})"
                    )
        for quest_id, quest in after_quests.items():
            discovery = quest.get("discovery")
            if not isinstance(discovery, dict) or not discovery.get("source"):
                errors.append(f"{character_id}.{quest_id}: exported quest has no explicit discovery source")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Validate Screenwriter exports against Port Alder's canonical character sheets. "
            "The default contract mode permits authored scene changes but rejects loss of "
            "sandbox quest metadata."
        )
    )
    parser.add_argument("export", type=Path, help="Exported .character file or directory")
    parser.add_argument("--canonical", type=Path, default=DEFAULT_CANONICAL, help="Canonical sheet directory")
    parser.add_argument("--exact", action="store_true", help="Require a byte-semantic no-edit JSON round trip")
    args = parser.parse_args()

    canonical, canonical_errors = load_sheets(args.canonical.resolve())
    exported, export_errors = load_sheets(args.export.resolve())
    errors = canonical_errors + export_errors
    if not errors:
        errors.extend(validate_contract(canonical, exported, args.exact))
    if errors:
        print(f"Screenwriter export validation failed with {len(errors)} issue(s):", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    mode = "exact round trip" if args.exact else "integration contract"
    print(f"Validated {len(exported)} Screenwriter character exports against the {mode} successfully.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
