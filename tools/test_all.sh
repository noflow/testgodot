#!/usr/bin/env bash
set -euo pipefail

python3 tools/validate_characters.py
tools/test_godot.sh

