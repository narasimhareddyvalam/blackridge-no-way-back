#!/usr/bin/env bash
# run_take.sh <driver.gd> <take_name> [extra Godot args...]
#
# Copies the driver scripts into the isolated project copy, runs one take there with
# --fixed-fps 60 (offline render), the Dummy audio driver and an always-on-top window
# (added after take C's first run lost draws while the machine was in use), and fails unless:
#   - Godot exits 0,
#   - the driver wrote capture/logs/<take_name>-result.json with "passed": true,
#   - the log contains no "SHADER ERROR" or "SCRIPT ERROR".
# Reaching --quit-after (a safety cap) without the driver's own finish() is a failure.
set -u -o pipefail

REEL=/Users/narasimhareddyvalam/Desktop/Blackridge_No_Way_Back/youtube/claude-liam-blackridge-gamedev
CAP="$REEL/capture"
COPY=/private/tmp/claude-501/-Users-narasimhareddyvalam-Desktop-Blackridge-No-Way-Back/59cc27ca-ea9d-4bb1-919c-75b671e4d5dd/scratchpad/blackridge-capture
GODOT=/Applications/Godot.app/Contents/MacOS/Godot

driver=$1
take=$2
shift 2
mkdir -p "$COPY/capture_drivers" "$CAP/logs" "$CAP/raw"
cp "$CAP"/scripts/*.gd "$COPY/capture_drivers/"
log="$CAP/logs/$take.log"
result="$CAP/logs/$take-result.json"
rm -f "$result"
cmd=("$GODOT" --path "$COPY" --fixed-fps 60 --audio-driver Dummy --always-on-top "$@"
	--script "res://capture_drivers/$driver" -- "$CAP")
{
	echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
	echo "command: ${cmd[*]}"
} > "$log"
start=$(date +%s)
timeout 3600 "${cmd[@]}" 2>&1 | tee -a "$log"
status=$?
echo "runner: godot exit status $status, wall time $(( $(date +%s) - start )) s" | tee -a "$log"
if grep -qE "SHADER ERROR|SCRIPT ERROR" "$log"; then
	echo "runner: FAIL (engine error in log)" | tee -a "$log"
	status=1
fi
if [ ! -f "$result" ] || ! grep -q '"passed": true' "$result"; then
	echo "runner: FAIL (no passing result file: $result)" | tee -a "$log"
	status=1
fi
[ "$status" -eq 0 ] && echo "runner: PASS $take" | tee -a "$log"
exit "$status"
