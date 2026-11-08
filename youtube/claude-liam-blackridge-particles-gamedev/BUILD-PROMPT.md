# BUILD-PROMPT — Blackridge, Rain and Vapour

A single paste-ready Claude Code prompt that rebuilds the film end to end. Run it from the
Blackridge repository root, with the Brutalist toolkit at `~/Desktop/brutalist.art`. It never
publishes, never pushes and never calls a paid API.

```text
Read ~/Desktop/brutalist.art/skills/make/godot-gamedev/SKILL.md in full, plus the files it
references (ai-explainer, riff, RENDER-TARGETS.md, PIPELINE-SAFETY.md, OUTRO-LOCK.md,
references/evidence.md, nopunt). Then rebuild
youtube/claude-liam-blackridge-particles-gamedev in this order, stopping on any failure:

1. Gate check: git status shows no changes under game/. Never edit game/shaders/.
2. Captures: if capture/manifest.json hashes do not match, copy game/ to a scratch folder,
   add capture/scripts/in_play_take.* under capture_drivers/, and run
   capture/scripts/run_film_captures.sh <copy> <out>, then copy each take's MP4, events.txt
   and godot.log into capture/takes/<take>/ as capture/CAPTURE.md describes. Read extracted
   frames to confirm each take shows its event.
3. Sheet: python3 build/build_sheet.py
4. Audio (master clock): ~/Desktop/brutalist.art/.venv/bin/python3
   runtime/scripts/generate_audio_kokoro.py <reel>. Bake the lead silences (B01 0.8 s, B25
   0.5 s) and the outro tail (B27 1.0 s) with ffmpeg and re-measure, run
   runtime/scripts/align.py <reel>, then python3 build/build_sheet.py again.
5. Evidence gate: python3 build/ledger.py, then
   ./art godot-gamedev --check <reel> --game game. It must PASS.
6. Visuals: render each beat with runtime/scripts/remotion_scenes.py <reel> --only <BID>,
   one at a time, never concurrently.
7. Final master: ./art final <reel> --height 2160 --fps 30 --out <reel>/exports/landscape
8. Visual QC: sample frames at 15/50/85% of every beat, read the PNGs, audit the rubric in
   CLAUDE-CODE-VISUAL-QC-CHECK.md, log the results in _qc/REPORT.md, and fix root causes until
   there are 0 BLOCKER and 0 MAJOR issues. Run python3 build/docs.py.
9. Report the 4K path, its SHA-256 and an `open` command. Do not publish or push.
```
