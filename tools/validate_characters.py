#!/usr/bin/env python3
"""Validate Port Alder JSON-based .character development packages."""

from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHARACTER_DIR = ROOT / "characters"
VALID_GENDERS = {"male", "female", "trans_male", "trans_female"}
VALID_ORIENTATIONS = {"straight", "bisexual", "lesbian", "gay", "asexual"}
PRIMARY_METERS = {"friendship", "love", "attraction", "lust"}
SUPPORT_METERS = {
    "trust", "respect", "resentment", "jealousy", "comfort", "commitment",
    "compatibility", "satisfaction"
}
REQUIRED_TOP_LEVEL = {
    "format_version", "id", "display_name", "profile", "home", "personality",
    "schedule", "skills", "goals", "connections", "relationship_defaults",
    "boundaries", "private_profile", "relationship_chapters", "quest_hooks",
    "conversation_topics", "text_style", "entry_event"
}


def fail(errors: list[str], path: Path, message: str) -> None:
    errors.append(f"{path.name}: {message}")


def validate_file(path: Path, known_ids: set[str]) -> list[str]:
    errors: list[str] = []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return [f"{path.name}: invalid JSON: {exc}"]

    missing = sorted(REQUIRED_TOP_LEVEL - data.keys())
    if missing:
        fail(errors, path, f"missing fields: {', '.join(missing)}")
        return errors

    if data["format_version"] != 1:
        fail(errors, path, "format_version must be 1")
    if path.stem != data["id"]:
        fail(errors, path, "file name must match id")

    profile = data["profile"]
    if not isinstance(profile.get("age"), int) or profile["age"] < 18:
        fail(errors, path, "opening major characters must be at least 18")
    if profile.get("gender_identity") not in VALID_GENDERS:
        fail(errors, path, "unsupported gender_identity")
    if profile.get("orientation") not in VALID_ORIENTATIONS:
        fail(errors, path, "unsupported orientation")

    meters = data["relationship_defaults"]
    missing_meters = sorted((PRIMARY_METERS | SUPPORT_METERS) - meters.keys())
    if missing_meters:
        fail(errors, path, f"missing relationship meters: {', '.join(missing_meters)}")
    for meter, value in meters.items():
        if not isinstance(value, int) or not 0 <= value <= 100:
            fail(errors, path, f"meter {meter} must be an integer from 0 to 100")

    chapters = data["relationship_chapters"]
    if len(chapters) != 5 or [chapter.get("level") for chapter in chapters] != [1, 2, 3, 4, 5]:
        fail(errors, path, "relationship_chapters must contain levels 1 through 5")
    chapter_ids = [chapter.get("id") for chapter in chapters]
    if len(chapter_ids) != len(set(chapter_ids)):
        fail(errors, path, "relationship chapter ids must be unique")

    for skill, level in data["skills"].items():
        if not isinstance(level, int) or not 0 <= level <= 250:
            fail(errors, path, f"skill {skill} must be an integer from 0 to 250")

    for connection in data["connections"]:
        target = connection.get("character")
        if target not in known_ids and target != "player":
            # Placeholder households are allowed until minor/background NPC packages exist.
            if not any(token in target for token in ("parent", "parents", "roommate", "mother")):
                fail(errors, path, f"unknown connection target: {target}")

    schedule = data["schedule"]
    if not schedule.get("fixed_commitments"):
        fail(errors, path, "schedule requires at least one fixed commitment")
    for commitment in schedule.get("fixed_commitments", []):
        if not commitment.get("blocks") or "unavailable" not in commitment:
            fail(errors, path, "each commitment needs blocks and unavailable")

    if profile.get("romance_eligible") is False:
        hard_limits = set(data["boundaries"].get("hard_limits", []))
        if profile.get("role") in {"mother", "father", "older_sister"} and "romance_with_player" not in hard_limits:
            fail(errors, path, "family character must explicitly block player romance")

    return errors


def main() -> int:
    paths = sorted(CHARACTER_DIR.glob("*.character"))
    if not paths:
        print("No character packages found.", file=sys.stderr)
        return 1

    ids: list[str] = []
    parse_errors: list[str] = []
    for path in paths:
        try:
            ids.append(json.loads(path.read_text(encoding="utf-8"))["id"])
        except (OSError, json.JSONDecodeError, KeyError) as exc:
            parse_errors.append(f"{path.name}: cannot read id: {exc}")

    duplicate_ids = sorted({item for item in ids if ids.count(item) > 1})
    errors = parse_errors[:]
    if duplicate_ids:
        errors.append(f"duplicate character ids: {', '.join(duplicate_ids)}")

    known_ids = set(ids)
    for path in paths:
        errors.extend(validate_file(path, known_ids))

    if errors:
        print("Character validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"Validated {len(paths)} character packages successfully.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

