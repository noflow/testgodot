#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${PORT_ALDER_GODOT_BIN:-}" && -x "$PORT_ALDER_GODOT_BIN" ]]; then
  :
elif command -v godot >/dev/null 2>&1; then
  PORT_ALDER_GODOT_BIN="$(command -v godot)"
elif command -v godot4 >/dev/null 2>&1; then
  PORT_ALDER_GODOT_BIN="$(command -v godot4)"
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
  PORT_ALDER_GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
else
  echo "Godot 4.7.2 was not found. Install it or add 'godot' to PATH." >&2
  exit 127
fi

PORT_ALDER_DISABLE_AUTOSAVE=1 "$PORT_ALDER_GODOT_BIN" --headless --path . --script res://src/tests/test_runner.gd
PORT_ALDER_DISABLE_AUTOSAVE=1 "$PORT_ALDER_GODOT_BIN" --headless --path . res://scenes/tests/home_runtime_probe.tscn
PORT_ALDER_DISABLE_AUTOSAVE=1 "$PORT_ALDER_GODOT_BIN" --headless --path . res://scenes/tests/city_runtime_probe.tscn
PORT_ALDER_DISABLE_AUTOSAVE=1 "$PORT_ALDER_GODOT_BIN" --headless --path . res://scenes/tests/dialogue_accessibility_probe.tscn
PORT_ALDER_DISABLE_AUTOSAVE=1 "$PORT_ALDER_GODOT_BIN" --headless --path . res://scenes/tests/vertical_slice_runtime_probe.tscn
