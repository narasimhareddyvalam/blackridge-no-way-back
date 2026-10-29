#!/usr/bin/env bash
# scripts/run-test.sh <test-file.gd> <fps>
set -o pipefail
mkdir -p logs
log="logs/$(basename "$1" .gd)_${2}fps.log"
godot_bin="${GODOT:-$(command -v godot || echo /Applications/Godot.app/Contents/MacOS/Godot)}"
if [ -f "game/tests/$1" ]; then script="res://tests/$1"; else script="../tools/tests/$1"; fi
timeout 120 "$godot_bin" --headless --path game --script "$script" --fixed-fps "$2" 2>&1 | tee "$log"
status=$?
if grep -qE "SHADER ERROR|SCRIPT ERROR" "$log"; then status=1; fi
exit $status
