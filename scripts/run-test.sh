#!/usr/bin/env bash
# scripts/run-test.sh <test-file.gd> <fps>  (LOG_DIR=<folder> keeps logs out of logs/)
# Godot runs with HOME=.scratch-home, so user:// is a scratch folder; the run fails if the
# player's real save folder changes.
set -o pipefail
log_dir="${LOG_DIR:-logs}"
mkdir -p "$log_dir"
log="$log_dir/$(basename "$1" .gd)_${2}fps.log"
godot_bin="${GODOT:-$(command -v godot || echo /Applications/Godot.app/Contents/MacOS/Godot)}"
if [ -f "game/tests/$1" ]; then script="res://tests/$1"; else script="../tools/tests/$1"; fi
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
timeout 120 "$godot_bin" --headless --path game --script "$script" --fixed-fps "$2" 2>&1 | tee "$log"
status=$?
if grep -qE "SHADER ERROR|SCRIPT ERROR" "$log"; then status=1; fi
if [ "$(fingerprint)" != "$before" ]; then
	echo "REAL SAVE FOLDER CHANGED: $real_saves" | tee -a "$log"
	status=1
fi
exit $status
