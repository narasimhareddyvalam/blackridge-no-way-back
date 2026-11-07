#!/usr/bin/env bash
# scripts/run-test.sh <test-file.gd> <fps|realtime> [timeout-seconds]  (LOG_DIR=<folder> keeps
# logs out of logs/). Godot runs with HOME=.scratch-home, so user:// is a scratch folder; the run
# fails if the player's real save folder changes, or if the test file does not exist.
set -o pipefail
if [ $# -lt 2 ]; then
	echo "usage: scripts/run-test.sh <test-file.gd> <fps|realtime> [timeout-seconds]" >&2
	exit 2
fi
log_dir="${LOG_DIR:-logs}"
mkdir -p "$log_dir"
if [ "$2" = "realtime" ]; then
	fps_args=(); tag="realtime"
else
	fps_args=(--fixed-fps "$2"); tag="${2}fps"
fi
log="$log_dir/$(basename "$1" .gd)_${tag}.log"
godot_bin="${GODOT:-$(command -v godot || echo /Applications/Godot.app/Contents/MacOS/Godot)}"
if [ -f "game/tests/$1" ]; then
	script="res://tests/$1"
elif [ -f "tools/tests/$1" ]; then
	script="../tools/tests/$1"
else
	echo "TEST FILE NOT FOUND: $1 (looked in game/tests/ and tools/tests/)" | tee "$log"
	exit 1
fi
name=$(sed -n 's/^config\/name="\(.*\)"$/\1/p' game/project.godot | tr ':*?"<>|' '-------')
real_saves="$HOME/Library/Application Support/Godot/app_userdata/$name"
fingerprint() {
	if [ -d "$real_saves" ]; then
		find "$real_saves" -type f -exec stat -f '%N %z %Fm' {} + | sort | shasum -a 256
	else
		echo "absent"
	fi
}
before=$(fingerprint)
export HOME="$PWD/.scratch-home"
mkdir -p "$HOME"
timeout "${3:-120}" "$godot_bin" --headless --path game --script "$script" "${fps_args[@]}" 2>&1 \
	| tee "$log"
status=$?
if grep -qE "SHADER ERROR|SCRIPT ERROR" "$log"; then status=1; fi
if [ "$(fingerprint)" != "$before" ]; then
	echo "REAL SAVE FOLDER CHANGED: $real_saves" | tee -a "$log"
	status=1
fi
exit $status
