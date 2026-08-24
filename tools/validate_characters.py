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


def validate_global_content(known_character_ids: set[str], character_quest_ids: set[str]) -> list[str]:
    errors: list[str] = []
    package_ids: set[str] = set()
    quest_ids: set[str] = set()
    conversation_ids: set[str] = set()
    packages: list[tuple[Path, dict]] = []
    valid_blocks = {"early_morning", "morning", "lunch", "afternoon", "evening", "late_evening", "night"}

    for path in sorted(GLOBAL_CONTENT_DIR.rglob("*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            errors.append(f"{path.relative_to(ROOT)}: invalid JSON: {exc}")
            continue
        packages.append((path, data))

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

    location_ids: set[str] = set()
    room_ids: set[str] = set()
    for path, data in packages:
        for location in data.get("locations", []):
            location_id = location.get("id")
            if not location_id or location_id in location_ids:
                errors.append(f"{path.relative_to(ROOT)}: missing or duplicate location id {location_id}")
                continue
            location_ids.add(location_id)
            for room in location.get("rooms", []):
                room_id = room.get("id")
                full_room_id = f"{location_id}.{room_id}"
                if not room_id or full_room_id in room_ids:
                    errors.append(f"{path.relative_to(ROOT)}: missing or duplicate room id {full_room_id}")
                room_ids.add(full_room_id)
            access = location.get("access", {})
            for block in access.get("open_blocks", []) + access.get("closed_blocks", []):
                if block not in valid_blocks:
                    errors.append(f"{path.relative_to(ROOT)}: location {location_id} uses invalid block {block}")

    account_ids: set[str] = set()
    budget_ids: set[str] = set()
    item_ids: set[str] = set()
    store_ids: set[str] = set()
    valid_clothing_slots = {"underwear", "bra", "shirt", "pants", "socks", "shoes", "hat", "jacket", "gloves", "scarf"}
    for path, data in packages:
        for account in data.get("accounts", []):
            account_id = account.get("id")
            if not account_id or account_id in account_ids:
                errors.append(f"{path.relative_to(ROOT)}: missing or duplicate account id {account_id}")
            account_ids.add(account_id)
        for budget in data.get("starting_budgets", []):
            budget_id = budget.get("id")
            if not budget_id or budget_id in budget_ids:
                errors.append(f"{path.relative_to(ROOT)}: missing or duplicate starting budget id {budget_id}")
            budget_ids.add(budget_id)
            for account_id, amount in budget.get("accounts", {}).items():
                if account_id not in account_ids or not isinstance(amount, (int, float)) or amount < 0:
                    errors.append(f"{path.relative_to(ROOT)}: budget {budget_id} has invalid account balance {account_id}")
        for item in data.get("items", []):
            item_id = item.get("id")
            if not item_id or item_id in item_ids:
                errors.append(f"{path.relative_to(ROOT)}: missing or duplicate item id {item_id}")
            item_ids.add(item_id)
            if not item.get("name") or not item.get("category"):
                errors.append(f"{path.relative_to(ROOT)}: item {item_id} has incomplete core data")
            if item.get("base_price", -1) < 0 or item.get("weight", -1) < 0 or item.get("stack_limit", 0) < 1:
                errors.append(f"{path.relative_to(ROOT)}: item {item_id} has invalid price, weight, or stack limit")
            if item.get("category") == "clothing":
                if item.get("slot") not in valid_clothing_slots:
                    errors.append(f"{path.relative_to(ROOT)}: clothing item {item_id} has an invalid slot")
                for rating in ("warmth", "rain_protection", "wind_protection", "comfort", "formality", "style"):
                    if not 0 <= item.get(rating, -1) <= 100:
                        errors.append(f"{path.relative_to(ROOT)}: clothing item {item_id} has invalid {rating}")
            if item.get("minimum_age") is not None and item["minimum_age"] < 18:
                errors.append(f"{path.relative_to(ROOT)}: restricted item {item_id} has an invalid minimum age")
        for store in data.get("stores", []):
            store_id = store.get("id")
            if not store_id or store_id in store_ids:
                errors.append(f"{path.relative_to(ROOT)}: missing or duplicate store id {store_id}")
            store_ids.add(store_id)

    for path, data in packages:
        for loadout in data.get("starting_loadouts", []):
            if loadout.get("budget") not in budget_ids:
                errors.append(f"{path.relative_to(ROOT)}: loadout references unknown budget {loadout.get('budget')}")
            for entry in loadout.get("items", []):
                if entry.get("item") not in item_ids or not isinstance(entry.get("quantity"), int) or entry["quantity"] < 1:
                    errors.append(f"{path.relative_to(ROOT)}: loadout has invalid item entry {entry}")
        for store in data.get("stores", []):
            for item_id in store.get("stock", []):
                if item_id not in item_ids:
                    errors.append(f"{path.relative_to(ROOT)}: store {store.get('id')} references unknown item {item_id}")
            for block in store.get("open_blocks", []):
                if block not in valid_blocks:
                    errors.append(f"{path.relative_to(ROOT)}: store {store.get('id')} uses invalid block {block}")

    def location_is_valid(value: str) -> bool:
        return (
            value in location_ids
            or value in room_ids
            or value in {"phone", "variable"}
            or value.startswith(("variable_", "any_", "legal_"))
            or value.endswith("_placeholder")
            or value.endswith("_offscreen")
        )

    def check_location_references(path: Path, value: object) -> None:
        if isinstance(value, dict):
            for key, child in value.items():
                if key in {"location", "alternate_location"} and isinstance(child, str):
                    if not location_is_valid(child):
                        errors.append(f"{path.relative_to(ROOT)}: unknown location reference {child}")
                elif key in {"locations", "alternate_locations"} and isinstance(child, list):
                    for item in child:
                        if isinstance(item, str) and not location_is_valid(item):
                            errors.append(f"{path.relative_to(ROOT)}: unknown location reference {item}")
                check_location_references(path, child)
        elif isinstance(value, list):
            for child in value:
                check_location_references(path, child)

    for path, data in packages:
        check_location_references(path, data)

        modes = {mode.get("id") for mode in data.get("modes", [])}
        for link in data.get("local_links", []):
            if link.get("from") not in location_ids or link.get("to") not in location_ids:
                errors.append(f"{path.relative_to(ROOT)}: local link has an unknown endpoint")
            if link.get("mode") not in modes or link.get("minutes", 0) <= 0 or link.get("cost", -1) < 0:
                errors.append(f"{path.relative_to(ROOT)}: local link has invalid travel data")
        route_ids: set[str] = set()
        for route in data.get("routes", []):
            route_id = route.get("id")
            if not route_id or route_id in route_ids:
                errors.append(f"{path.relative_to(ROOT)}: missing or duplicate route id {route_id}")
            route_ids.add(route_id)
            if route.get("from") not in location_ids or route.get("to") not in location_ids:
                errors.append(f"{path.relative_to(ROOT)}: route {route_id} has an unknown endpoint")
            for option in route.get("options", []):
                if option.get("mode") not in modes or option.get("minutes", 0) <= 0 or option.get("cost", -1) < 0:
                    errors.append(f"{path.relative_to(ROOT)}: route {route_id} has invalid travel data")

        if "calendar" in data:
            calendar_blocks = data["calendar"].get("blocks", [])
            if set(calendar_blocks) != valid_blocks or len(calendar_blocks) != 7:
                errors.append(f"{path.relative_to(ROOT)}: calendar must define all seven unique activity blocks")
            events = data.get("event_catalog", [])
            event_ids = [event.get("id") for event in events]
            if any(not item for item in event_ids) or len(event_ids) != len(set(event_ids)):
                errors.append(f"{path.relative_to(ROOT)}: event catalog contains missing or duplicate ids")
            all_quest_ids = quest_ids | character_quest_ids
            for event in events:
                if event.get("duration_blocks", 0) <= 0:
                    errors.append(f"{path.relative_to(ROOT)}: event {event.get('id')} has invalid duration")
                if event.get("quest") and event["quest"] not in all_quest_ids:
                    errors.append(f"{path.relative_to(ROOT)}: event {event.get('id')} references unknown quest {event['quest']}")
                if event.get("npc") and event["npc"] not in known_character_ids:
                    errors.append(f"{path.relative_to(ROOT)}: event {event.get('id')} references unknown character {event['npc']}")
            days = data.get("days", [])
            expected_weekdays = ["tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
            if [day.get("weekday") for day in days] != expected_weekdays:
                errors.append(f"{path.relative_to(ROOT)}: opening week must run Tuesday through Sunday")
            for day in days:
                day_blocks = day.get("blocks", {})
                if set(day_blocks) != valid_blocks:
                    errors.append(f"{path.relative_to(ROOT)}: {day.get('date')} does not define all seven blocks")
                for block, offered_events in day_blocks.items():
                    if block not in valid_blocks:
                        errors.append(f"{path.relative_to(ROOT)}: {day.get('date')} uses invalid block {block}")
                    for event_id in offered_events:
                        if event_id not in event_ids:
                            errors.append(f"{path.relative_to(ROOT)}: {day.get('date')} references unknown event {event_id}")
            scheduled_characters = [item.get("character") for item in data.get("named_npc_windows", [])]
            if set(scheduled_characters) != known_character_ids:
                missing = sorted(known_character_ids - set(scheduled_characters))
                extra = sorted(set(scheduled_characters) - known_character_ids)
                errors.append(f"{path.relative_to(ROOT)}: NPC schedule mismatch; missing={missing}, extra={extra}")
            for item in data.get("named_npc_windows", []):
                for window in item.get("windows", []):
                    for block in window.get("blocks", []):
                        if block not in valid_blocks:
                            errors.append(f"{path.relative_to(ROOT)}: NPC {item.get('character')} uses invalid block {block}")

        courses = data.get("courses", [])
        course_ids = [course.get("id") for course in courses]
        if any(not item for item in course_ids) or len(course_ids) != len(set(course_ids)):
            errors.append(f"{path.relative_to(ROOT)}: courses contain missing or duplicate ids")
        teaching_blocks = set(data.get("institution", {}).get("teaching_blocks", []))
        for course in courses:
            if not course.get("name") or not 0 <= course.get("difficulty", -1) <= 100:
                errors.append(f"{path.relative_to(ROOT)}: course {course.get('id')} has invalid core data")
            for section in course.get("sections", []):
                if section.get("block") not in teaching_blocks:
                    errors.append(f"{path.relative_to(ROOT)}: course {course.get('id')} uses a block outside teaching hours")
        program_ids: set[str] = set()
        for program in data.get("programs", []):
            program_id = program.get("id")
            if not program_id or program_id in program_ids:
                errors.append(f"{path.relative_to(ROOT)}: missing or duplicate program id {program_id}")
            program_ids.add(program_id)
            for course_id in program.get("first_semester_courses", []):
                if course_id not in course_ids:
                    errors.append(f"{path.relative_to(ROOT)}: program {program_id} references unknown course {course_id}")

        jobs = data.get("jobs", [])
        job_ids = [job.get("id") for job in jobs]
        minimum_wage = data.get("economy", {}).get("minimum_wage", 0)
        if any(not item for item in job_ids) or len(job_ids) != len(set(job_ids)):
            errors.append(f"{path.relative_to(ROOT)}: jobs contain missing or duplicate ids")
        for job in jobs:
            job_id = job.get("id")
            if not job.get("title") or not job.get("employer") or not job.get("employment_types"):
                errors.append(f"{path.relative_to(ROOT)}: job {job_id} has incomplete core data")
            if "hourly_pay" in job and job["hourly_pay"] < minimum_wage:
                errors.append(f"{path.relative_to(ROOT)}: job {job_id} pays below the configured minimum wage")
            if "booking_pay_range" in job and (len(job["booking_pay_range"]) != 2 or min(job["booking_pay_range"]) <= 0):
                errors.append(f"{path.relative_to(ROOT)}: job {job_id} has an invalid booking range")
            requirements = job.get("requirements", {})
            skill_requirements = list(requirements.get("skills", {}).items())
            skill_requirements.extend(requirements.get("skills_any", []))
            for skill, level in skill_requirements:
                if not isinstance(level, int) or not 0 <= level <= 250:
                    errors.append(f"{path.relative_to(ROOT)}: job {job_id} has invalid skill requirement {skill}")
            for schedule in job.get("schedule_options", []):
                for block in schedule.get("blocks", []):
                    if block not in valid_blocks:
                        errors.append(f"{path.relative_to(ROOT)}: job {job_id} uses invalid block {block}")
                weekly_hours = schedule.get("weekly_hours")
                if weekly_hours != "variable" and (not isinstance(weekly_hours, (int, float)) or not 0 < weekly_hours <= 60):
                    errors.append(f"{path.relative_to(ROOT)}: job {job_id} has invalid weekly hours")

        activities = data.get("activities", [])
        activity_ids = [activity.get("id") for activity in activities]
        if any(not item for item in activity_ids) or len(activity_ids) != len(set(activity_ids)):
            errors.append(f"{path.relative_to(ROOT)}: activities contain missing or duplicate ids")
        for activity in activities:
            if not activity.get("name") or not activity.get("category"):
                errors.append(f"{path.relative_to(ROOT)}: activity {activity.get('id')} has incomplete core data")
            if not 0 < activity.get("duration_blocks", 0) <= 3:
                errors.append(f"{path.relative_to(ROOT)}: activity {activity.get('id')} has invalid duration")
            if activity.get("cost", 0) < 0:
                errors.append(f"{path.relative_to(ROOT)}: activity {activity.get('id')} has invalid cost")

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
    character_quest_ids: set[str] = set()
    for path in paths:
        errors.extend(validate_file(path, known_ids))
        try:
            character_data = json.loads(path.read_text(encoding="utf-8"))
            character_quest_ids.update(quest.get("id") for quest in character_data.get("quests", []) if quest.get("id"))
        except (OSError, json.JSONDecodeError):
            pass
    errors.extend(validate_global_content(known_ids, character_quest_ids))

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
