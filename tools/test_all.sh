#!/usr/bin/env bash
set -euo pipefail

python3 tools/validate_characters.py
python3 tools/validate_backgrounds.py
tools/test_godot.sh
