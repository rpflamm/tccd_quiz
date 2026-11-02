#!/usr/bin/env bash
# Run all GUT tests headless. Set GODOT to your Godot 4.7 binary if it is not on PATH.
set -e
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json
python3 tools/validate_questions.py
