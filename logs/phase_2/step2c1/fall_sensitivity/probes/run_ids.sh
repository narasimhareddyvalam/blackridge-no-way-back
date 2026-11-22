#!/usr/bin/env bash
# Runs fall_ids.gd with 1..9 extra boxes, three at a time, into $1.
out="$1"
cd "$(dirname "$0")/../../../../.." || exit 2
mkdir -p "$out"
S="$PWD/logs/phase_2/step2c1/fall_sensitivity/probes"
for batch in "1 2 3" "4 5 6" "7 8 9"; do
	for k in $batch; do
		HOME=$PWD/.scratch-home timeout 300 /Applications/Godot.app/Contents/MacOS/Godot --headless \
			--path game --fixed-fps 60 --script "$S/fall_ids.gd" -- "$k" > "$out/ids_$k.log" 2>&1 &
	done
	wait
done
echo DONE
