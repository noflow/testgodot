#!/usr/bin/env python3
"""Validate that every mapped Port Alder room has a production background."""

from __future__ import annotations

import json
import struct
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ART_PATH = ROOT / "content" / "presentation" / "vn_art.json"
WORLD_PATH = ROOT / "content" / "world" / "all_locations.json"
EXPECTED_SIZE = (1672, 941)


def png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError("not a valid PNG")
    return struct.unpack(">II", header[16:24])


def main() -> int:
    art = json.loads(ART_PATH.read_text(encoding="utf-8"))
    world = json.loads(WORLD_PATH.read_text(encoding="utf-8"))
    backgrounds = art.get("vn_backgrounds", [])
    expected = [
        (location["id"], room["id"])
        for location in world.get("locations", [])
        for room in location.get("rooms", [])
    ]
    actual = [(entry.get("location"), entry.get("room")) for entry in backgrounds]
    errors: list[str] = []

    expected_set = set(expected)
    actual_set = set(actual)
    for location_id, room_id in sorted(expected_set - actual_set):
        errors.append(f"missing registry entry: {location_id}.{room_id}")
    for location_id, room_id in sorted(actual_set - expected_set):
        errors.append(f"unmapped registry entry: {location_id}.{room_id}")

    ids: set[str] = set()
    for entry in backgrounds:
        asset_id = str(entry.get("id", ""))
        expected_id = f"{entry.get('location', '')}.{entry.get('room', '')}"
        if not asset_id or asset_id in ids:
            errors.append(f"missing or duplicate background id: {asset_id or '<empty>'}")
        ids.add(asset_id)
        if asset_id != expected_id:
            errors.append(f"background id mismatch: {asset_id} != {expected_id}")
        resource_path = str(entry.get("path", ""))
        if not resource_path.startswith("res://"):
            errors.append(f"invalid resource path for {asset_id}: {resource_path}")
            continue
        file_path = ROOT / resource_path.removeprefix("res://")
        if not file_path.is_file():
            errors.append(f"missing background file for {asset_id}: {file_path}")
            continue
        try:
            dimensions = png_size(file_path)
        except (OSError, ValueError) as exc:
            errors.append(f"invalid PNG for {asset_id}: {exc}")
            continue
        if dimensions != EXPECTED_SIZE:
            errors.append(f"wrong dimensions for {asset_id}: {dimensions[0]}x{dimensions[1]}")
        if entry.get("status") != "ready":
            errors.append(f"background is not ready: {asset_id}")
        if entry.get("variants", {}).get("day") != resource_path:
            errors.append(f"day variant does not match base path: {asset_id}")

    if errors:
        print("Background validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(
        f"Validated {len(backgrounds)} production backgrounds across "
        f"{len(world.get('locations', []))} mapped locations at {EXPECTED_SIZE[0]}x{EXPECTED_SIZE[1]}."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
