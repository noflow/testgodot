#!/usr/bin/env bash
set -euo pipefail

if command -v godot >/dev/null 2>&1; then
  godot --headless --path . --script res://src/tests/test_runner.gd
elif command -v godot4 >/dev/null 2>&1; then
  godot4 --headless --path . --script res://src/tests/test_runner.gd
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://src/tests/test_runner.gd
else
  echo "Godot 4.7.2 was not found. Install it or add 'godot' to PATH." >&2
  exit 127
fi

