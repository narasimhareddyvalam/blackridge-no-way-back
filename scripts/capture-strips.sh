#!/usr/bin/env bash
# Captures Assignment 6's frame strips: each effect's preview scene rendered in a window by Godot's
# Movie Maker at 1280x800 and 30 fps. The frames the brief reads are kept in
# captures/<effect>/r<round>/, with the preview's own event log; the rest of the sequence is
# deleted. A window opens for each strip; keys typed meanwhile are ignored by the preview.
#
# Usage, from the repository root:
#   scripts/capture-strips.sh <round> [effect[:name=value[,name=value]] ...]
# With no effect named, all four are captured. A variant's settings go after a colon and name
# its folder, for example:
#   scripts/capture-strips.sh 0
#   scripts/capture-strips.sh 0 wiper_flick:retrigger=true lamp_rain:place=door
set -u

if [ "$#" -lt 1 ] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
	echo "usage: scripts/capture-strips.sh <round> [effect[:name=value[,name=value]] ...]" >&2
	exit 2
fi
round="$1"
shift
specs=("$@")
if [ "${#specs[@]}" -eq 0 ]; then
	specs=(wiper_flick roof_spill lamp_rain exhaust_vapour)
fi

root="$(cd "$(dirname "$0")/.." && pwd)"
godot="${GODOT:-$(command -v godot || echo /Applications/Godot.app/Contents/MacOS/Godot)}"
captures="${CAPTURES:-$root/captures}"
status=0

for spec in "${specs[@]}"; do
	effect="${spec%%:*}"
	settings=()
	suffix=""
	if [ "$spec" != "$effect" ]; then
		IFS=',' read -r -a settings <<< "${spec#*:}"
		suffix="-$(IFS=_; echo "${settings[*]}" | tr '=' '-')"
	fi
	case "$effect" in
		wiper_flick) quit_after=60; frames="10 12 15 20 30 50" ;;
		roof_spill) quit_after=60; frames="10 12 15 20 30 50" ;;
		lamp_rain) quit_after=120; frames="10 12 20 30 50 70 85 110" ;;
		exhaust_vapour) quit_after=190; frames="10 20 30 40 55 80 100 130 180" ;;
		*) echo "unknown effect: $effect" >&2; status=2; continue ;;
	esac
	case "$effect$suffix" in
		wiper_flick*retrigger-true*) frames="$frames 37 40 45" ;;
		roof_spill*retrigger-true*) frames="$frames 25" ;;
	esac
	out="$captures/$effect/r$round$suffix"
	if [ -e "$out" ] && [ -n "$(ls -A "$out")" ]; then
		echo "$out already holds a strip; pick a new round" >&2
		status=1
		continue
	fi
	mkdir -p "$out"
	echo "== $effect$suffix: rendering $quit_after frames into $out (a window opens)"
	extra=()
	if [ "${#settings[@]}" -gt 0 ]; then
		extra=(-- "${settings[@]}")
	fi
	HOME="$root/.scratch-home" "$godot" --path "$root/game" --resolution 1280x800 \
		"res://previews/${effect}_preview.tscn" --write-movie "$out/frame.png" \
		--fixed-fps 30 --quit-after "$quit_after" ${extra[@]+"${extra[@]}"} > "$out/godot.log" 2>&1
	code=$?
	grep '^frame [0-9]*:' "$out/godot.log" > "$out/events.txt"
	if [ "$code" -ne 0 ] || grep -q 'SCRIPT ERROR\|SHADER ERROR' "$out/godot.log"; then
		echo "   failed (exit $code); see $out/godot.log" >&2
		status=1
		continue
	fi
	keep=()
	for frame in $frames; do
		keep+=("$(printf 'frame%08d.png' "$frame")")
	done
	for file in "$out"/frame*.png; do
		name="$(basename "$file")"
		if [[ " ${keep[*]} " != *" $name "* ]]; then
			rm -f -- "$file"
		fi
	done
	rm -f -- "$out/frame.wav"
	echo "   kept frames $frames; events in $out/events.txt"
done
exit "$status"
