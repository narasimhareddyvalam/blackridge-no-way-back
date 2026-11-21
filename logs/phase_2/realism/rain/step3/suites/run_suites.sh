#!/usr/bin/env bash
# Every suite for the rain's step 3 (#354), as scripts/run-test.sh runs each one, in three
# workers at once: each worker is an APFS clone of game/, tools/ and scripts/ in its own folder,
# so each has its own .scratch-home; run-test.sh still checks the player's real save folder.
# Usage, from the repository root: bash logs/phase_2/realism/rain/step3/suites/run_suites.sh <scratch>
set -u
repo="$PWD"
out="$repo/logs/phase_2/realism/rain/step3/suites"
scratch="$1"
tests=(first_drive_regression.gd:60 first_drive_integration.gd:60 test_materials.gd:60
	test_headlights.gd:60 test_rain_physics.gd:60 test_cockpit.gd:60 test_ghat_road.gd:60
	test_wipers.gd:60 test_on_foot.gd:60 test_oncoming_van.gd:60 test_collision.gd:60
	test_crossing.gd:60 test_maya_call.gd:60 test_hit_speeds.gd:60 test_dash_screen.gd:60
	test_save_rules.gd:60 test_mirrors.gd:60 test_menus.gd:60 test_mission_two.gd:60
	test_bay_nine.gd:60 test_loading.gd:60 test_sealing.gd:60 test_stair.gd:60 test_rear_doors.gd:60
	test_dock_worker.gd:60 test_racking.gd:60 test_wet_ground.gd:60 test_roadside.gd:60 test_roadside_trees.gd:60 test_town.gd:60 test_rear_camera.gd:60 test_docking.gd:60 test_shed_floor.gd:60 test_shed_fitout.gd:60 test_shed_kit.gd:60 test_shed_work.gd:60 test_yard.gd:60 test_container_yard.gd:60 test_compound.gd:60 test_warehouses.gd:60 test_loading_bay.gd:60 test_free_exit.gd:60 test_forklift.gd:60 test_pallet_jack.gd:60 test_tail_lamps.gd:60 test_moon_roof_rain.gd:60 test_windshield_water.gd:60 test_booths.gd:60 test_gates.gd:60 test_yard_realism.gd:60 test_docks.gd:60 test_gate_light.gd:60
	test_wiper_flick_config.gd:60 test_roof_spill_config.gd:60 test_lamp_rain_config.gd:60
	test_exhaust_vapour_config.gd:60 test_wiper_flick_state.gd:60 test_roof_spill_state.gd:60
	test_lamp_rain_state.gd:60 test_exhaust_vapour_state.gd:60 test_night_dimming.gd:30
	test_night_dimming.gd:60 test_night_dimming.gd:144)
for w in 0 1 2; do
	rm -rf "$scratch/suite_w$w"
	mkdir -p "$scratch/suite_w$w"
	cp -cR "$repo/game" "$repo/tools" "$repo/scripts" "$scratch/suite_w$w/"
done
run_worker() {
	local w=$1
	local i=0
	for entry in "${tests[@]}"; do
		if [ $((i % 3)) -eq "$w" ]; then
			local name="${entry%%:*}" fps="${entry##*:}"
			(cd "$scratch/suite_w$w" && LOG_DIR="$out" scripts/run-test.sh "$name" "$fps" 1200 \
				> "$out/${name%.gd}_${fps}.out" 2>&1)
			echo "$name:$fps:$?" >> "$out/status_w$w.txt"
		fi
		i=$((i + 1))
	done
}
rm -f "$out"/status_w*.txt
run_worker 0 & run_worker 1 & run_worker 2 &
wait
summary="$out/SUMMARY.txt"
: > "$summary"
for entry in "${tests[@]}"; do
	name="${entry%%:*}"; fps="${entry##*:}"
	log="$out/${name%.gd}_${fps}fps.log"
	status=$(grep -h "^$name:$fps:" "$out"/status_w*.txt | head -1 | cut -d: -f3)
	result=$(grep -E "RESULT" "$log" 2>/dev/null | tail -1)
	bad=$(grep -cE "SCRIPT ERROR|SHADER ERROR" "$log" 2>/dev/null)
	errors=$(grep -c "^ERROR:" "$log" 2>/dev/null)
	printf "%-34s %-4s exit %s   %s | bad lines %s, ERROR: lines %s\n" "$name" "$fps" \
		"$status" "$result" "$bad" "$errors" >> "$summary"
done
python3 -I tools/tests/check_first_drive_art.py > "$out/check_first_drive_art.log" 2>&1
echo "check_first_drive_art.py exit $? $(grep -E "RESULT" "$out/check_first_drive_art.log" | tail -1)" \
	>> "$summary"
echo DONE >> "$summary"
