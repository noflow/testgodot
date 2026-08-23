#!/usr/bin/env python3
"""Validate Port Alder JSON-based .character development packages."""

from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHARACTER_DIR = ROOT / "characters"
GLOBAL_CONTENT_DIR = ROOT / "content"
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
    "conversation_topics", "text_style", "quests", "conversations",
    "text_messages", "outcomes", "asset_refs", "entry_event"
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

    quests = data["quests"]
    quest_ids = [quest.get("id") for quest in quests]
    if len(quest_ids) != len(set(quest_ids)):
        fail(errors, path, "quest ids must be unique within a package")
    for quest in quests:
        if not quest.get("id") or not quest.get("title") or not quest.get("category"):
            fail(errors, path, "each quest needs id, title, and category")
        objectives = quest.get("objectives", [])
        objective_ids = [objective.get("id") for objective in objectives]
        if not objectives or any(not item for item in objective_ids):
            fail(errors, path, f"quest {quest.get('id')} needs identified objectives")
        if len(objective_ids) != len(set(objective_ids)):
            fail(errors, path, f"quest {quest.get('id')} has duplicate objective ids")

    conversations = data["conversations"]
    conversation_ids = [conversation.get("id") for conversation in conversations]
    if len(conversation_ids) != len(set(conversation_ids)):
        fail(errors, path, "conversation ids must be unique within a package")
    for conversation in conversations:
        conversation_id = conversation.get("id")
        nodes = conversation.get("nodes", {})
        start_node = conversation.get("start_node")
        if not conversation_id or not conversation.get("type"):
            fail(errors, path, "each conversation needs id and type")
        if not nodes or start_node not in nodes:
            fail(errors, path, f"conversation {conversation_id} has an invalid start node")
            continue
        for node_id, node in nodes.items():
            targets = []
            if node.get("next") is not None:
                targets.append(node.get("next"))
            for choice in node.get("choices", []):
                if not choice.get("id") or not choice.get("text"):
                    fail(errors, path, f"conversation {conversation_id} node {node_id} has an invalid choice")
                if choice.get("next") is not None:
                    targets.append(choice.get("next"))
            for target in targets:
                if target not in nodes:
                    fail(errors, path, f"conversation {conversation_id} links to missing node {target}")

    return errors


def validate_global_content() -> list[str]:
    errors: list[str] = []
    package_ids: set[str] = set()
    quest_ids: set[str] = set()
    conversation_ids: set[str] = set()

    for path in sorted(GLOBAL_CONTENT_DIR.rglob("*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            errors.append(f"{path.relative_to(ROOT)}: invalid JSON: {exc}")
            continue

        package_id = data.get("package_id")
        if not package_id or package_id in package_ids:
            errors.append(f"{path.relative_to(ROOT)}: missing or duplicate package_id")
        package_ids.add(package_id)
        if data.get("format_version") != 1:
            errors.append(f"{path.relative_to(ROOT)}: format_version must be 1")

        for quest in data.get("quests", []):
            quest_id = quest.get("id")
            if not quest_id or quest_id in quest_ids:
                errors.append(f"{path.relative_to(ROOT)}: missing or duplicate global quest id {quest_id}")
            quest_ids.add(quest_id)
            objectives = quest.get("objectives", [])
            objective_ids = [objective.get("id") for objective in objectives]
            if not quest.get("title") or not quest.get("category") or not objectives:
                errors.append(f"{path.relative_to(ROOT)}: quest {quest_id} is incomplete")
            if any(not item for item in objective_ids) or len(objective_ids) != len(set(objective_ids)):
                errors.append(f"{path.relative_to(ROOT)}: quest {quest_id} has invalid objective ids")

        for conversation in data.get("conversations", []):
            conversation_id = conversation.get("id")
            if not conversation_id or conversation_id in conversation_ids:
                errors.append(f"{path.relative_to(ROOT)}: missing or duplicate global conversation id {conversation_id}")
            conversation_ids.add(conversation_id)
            nodes = conversation.get("nodes", {})
            if not conversation.get("type") or conversation.get("start_node") not in nodes:
                errors.append(f"{path.relative_to(ROOT)}: conversation {conversation_id} has an invalid start node")
                continue
            for node_id, node in nodes.items():
                targets = []
                if node.get("next") is not None:
                    targets.append(node.get("next"))
                choices = node.get("choices", [])
                choice_ids = [choice.get("id") for choice in choices]
                if any(not item for item in choice_ids) or len(choice_ids) != len(set(choice_ids)):
                    errors.append(f"{path.relative_to(ROOT)}: conversation {conversation_id} node {node_id} has invalid choice ids")
                targets.extend(choice.get("next") for choice in choices if choice.get("next") is not None)
                for target in targets:
                    if target not in nodes:
                        errors.append(f"{path.relative_to(ROOT)}: conversation {conversation_id} links to missing node {target}")

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
    errors.extend(validate_global_content())

    if errors:
        print("Character validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    global_files = len(list(GLOBAL_CONTENT_DIR.rglob("*.json")))
    print(f"Validated {len(paths)} character packages and {global_files} global content packages successfully.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
