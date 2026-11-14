#!/bin/zsh
# Every suite of step 2e's last run, one after another, into $1; then the art check.
cd /Users/narasimhareddyvalam/Desktop/Blackridge_No_Way_Back || exit 2
OUT=$1
mkdir -p "$OUT"
SUMMARY="$OUT/SUMMARY.txt"
: > "$SUMMARY"
runs=(first_drive_regression.gd:60 first_drive_integration.gd:60 test_materials.gd:60 test_headlights.gd:60
  test_rain_physics.gd:60 test_cockpit.gd:60 test_ghat_road.gd:60 test_wipers.gd:60 test_on_foot.gd:60
  test_oncoming_van.gd:60 test_collision.gd:60 test_crossing.gd:60 test_maya_call.gd:60 test_hit_speeds.gd:60
  test_dash_screen.gd:60 test_save_rules.gd:60 test_mirrors.gd:60 test_menus.gd:60 test_mission_two.gd:60
  test_bay_nine.gd:60 test_loading.gd:60 test_sealing.gd:60 test_wiper_flick_config.gd:60
  test_roof_spill_config.gd:60 test_lamp_rain_config.gd:60 test_exhaust_vapour_config.gd:60
  test_wiper_flick_state.gd:60 test_roof_spill_state.gd:60 test_lamp_rain_state.gd:60
  test_exhaust_vapour_state.gd:60 test_night_dimming.gd:30 test_night_dimming.gd:60 test_night_dimming.gd:144)
for run in $runs; do
  test=${run%%:*}; fps=${run##*:}
  LOG_DIR="$OUT" scripts/run-test.sh "$test" "$fps" 450 > "$OUT/${test%.gd}_${fps}.out" 2>&1
  code=$?
  log="$OUT/${test%.gd}_${fps}fps.log"
  result=$(grep -E "RESULT" "$log" 2>/dev/null | tail -1)
  bad=$(grep -cE "SCRIPT ERROR|SHADER ERROR" "$log" 2>/dev/null)
  errors=$(grep -c "ERROR:" "$log" 2>/dev/null)
  printf "%-34s %-4s exit %s   %s | bad lines %s, ERROR: lines %s\n" "$test" "$fps" "$code" "$result" "$bad" "$errors" >> "$SUMMARY"
done
python3 tools/tests/check_first_drive_art.py > "$OUT/check_first_drive_art.log" 2>&1
echo "check_first_drive_art.py exit $? $(grep 'ART RESULT' "$OUT/check_first_drive_art.log")" >> "$SUMMARY"
echo DONE >> "$SUMMARY"
