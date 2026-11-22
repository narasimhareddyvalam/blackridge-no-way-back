#!/usr/bin/env bash
# The film's takes (Assignment 7), recorded by Movie Maker at 1280x800, 30 fps, one after another,
# from the repository's game/ (its revision is in capture/manifest.json). Each take's PNG or AVI
# output goes to <out>/<take>/, its Godot log beside it.
# Usage, from the repository root: bash youtube/claude-liam-blackridge-animation-gamedev/capture/scripts/run_film_captures.sh <out>
set -u
out="$1"
godot=/Applications/Godot.app/Contents/MacOS/Godot
cd game
run() {
	local take=$1 script=$2; shift 2
	mkdir -p "$out/$take"
	HOME=../.scratch-home timeout 2400 "$godot" --path . --resolution 1280x800 \
		--write-movie "$out/$take/$take.avi" --fixed-fps 30 -s "$script" "$@" \
		> "$out/$take/godot.log" 2>&1
	echo "$take exit $?" >> "$out/STATUS.txt"
}
run reload ../tools/captures/capture_reload_strip.gd
run interrupt_startup ../tools/captures/capture_enter_van_interrupt.gd -- startup
run interrupt_active ../tools/captures/capture_enter_van_interrupt.gd -- active
run interrupt_recovery ../tools/captures/capture_enter_van_interrupt.gd -- recovery
run ring_play ../tools/captures/capture_a7_clips.gd
run shock ../tools/captures/capture_shock_shot.gd
echo DONE >> "$out/STATUS.txt"
