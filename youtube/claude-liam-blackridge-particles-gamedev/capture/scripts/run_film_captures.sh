#!/usr/bin/env bash
# run_film_captures.sh <isolated-copy> <out-dir>: the film's engine footage, recorded by Movie Maker
# in a window at the game's own 1280x800 and 30 fps, on an isolated copy of game/ (never the
# repository's). The in-play take is scripted input on the real main scene; the others are the
# assignment's preview fixtures, the same runs as the frame strips with every frame kept. Each
# take is encoded to H.264 and hashed; frames and logs stay beside it.
set -u -o pipefail
copy="$1"
out="$2"
godot=/Applications/Godot.app/Contents/MacOS/Godot
home="$(cd "$(dirname "$0")/../../../.." && pwd)/.scratch-home"
mkdir -p "$out"
takes=(
	"in_play|res://capture_drivers/in_play_take.tscn|480|"
	"a1_repeats|res://previews/wiper_flick_preview.tscn|60|retrigger=true"
	"a1_speed|res://previews/wiper_flick_preview.tscn|60|speed_kmh=50"
	"a2_office|res://previews/roof_spill_preview.tscn|60|retrigger=true"
	"a2_valley|res://previews/roof_spill_preview.tscn|60|place=valley"
	"b1_post|res://previews/lamp_rain_preview.tscn|120|"
	"b2_rear|res://previews/exhaust_vapour_preview.tscn|190|"
	"b2_reverse|res://previews/exhaust_vapour_preview.tscn|190|view=reverse_camera"
)
for spec in "${takes[@]}"; do
	IFS='|' read -r name scene frames args <<< "$spec"
	dir="$out/$name"
	rm -rf "$dir"
	mkdir -p "$dir/frames"
	extra=()
	[ -n "$args" ] && extra=(-- "$args")
	echo "== $name: $scene, $frames frames ${args:+($args)}"
	HOME="$home" "$godot" --path "$copy" --resolution 1280x800 "$scene" \
		--write-movie "$dir/frames/frame.png" --fixed-fps 30 --quit-after "$frames" \
		${extra[@]+"${extra[@]}"} > "$dir/godot.log" 2>&1
	code=$?
	grep -E '^(TAKE )?frame [0-9-]+:' "$dir/godot.log" > "$dir/events.txt"
	if [ "$code" -ne 0 ] || grep -q 'SCRIPT ERROR\|SHADER ERROR' "$dir/godot.log"; then
		echo "   FAILED (exit $code); see $dir/godot.log"
		continue
	fi
	rm -f "$dir/frames/frame.wav"
	ffmpeg -loglevel error -y -framerate 30 -i "$dir/frames/frame%08d.png" -c:v libx264 \
		-preset slow -crf 12 -pix_fmt yuv420p "$dir/$name.mp4"
	echo "   $(ls "$dir/frames" | wc -l | tr -d ' ') frames; $(shasum -a 256 "$dir/$name.mp4")"
done
