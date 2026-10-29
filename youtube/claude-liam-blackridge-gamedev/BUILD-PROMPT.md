# BUILD-PROMPT — Blackridge, Shaded

This is a single paste-ready Claude Code prompt that rebuilds the film end to end. Run it
from the Blackridge repository root, with the Brutalist toolkit at `~/Desktop/brutalist.art`.
It never publishes and never calls a paid API.

```text
Read ~/Desktop/brutalist.art/skills/make/godot-gamedev/SKILL.md in full, plus the files it
references (ai-explainer, riff, RENDER-TARGETS.md, PIPELINE-SAFETY.md, OUTRO-LOCK.md,
references/evidence.md, godot-waikthrough references/capture-and-coverage.md, nopunt, and
docs/MATH-TYPESETTING.md). Then rebuild youtube/claude-liam-blackridge-gamedev in this order,
stopping on any failure:

1. Gate check: git status shows no changes under game/. Never edit game/shaders/.
2. Captures: if capture/manifest.json hashes do not match, re-run the drivers in
   capture/scripts/ on an isolated copy of game/ exactly as capture/CAPTURE.md describes,
   then verify that each take shows its event by reading extracted frames.
3. Props: ~/Desktop/brutalist.art/.venv/bin/python3 build/evidence.py, then
   python3 build/build_sheet.py.
4. Audio (master clock): with the toolkit venv on PATH, run
   runtime/scripts/generate_audio_kokoro.py on the reel. Bake the lead and tail silences
   listed in BUILD-LOG.md, run runtime/scripts/align.py, then rebuild the props (step 3).
5. Evidence gate: python3 build/ledger.py, then
   ./art godot-gamedev --check <reel> --game game. It must PASS.
6. Visuals: render each beat with runtime/scripts/remotion_scenes.py <reel> --only <BID>,
   one at a time (never concurrently, never hand-rolled npx remotion render).
7. Review cut: ./art run <reel> --height 1080. Then the final master:
   ./art final <reel> --height 2160 --fps 30 --out <reel>/exports/landscape
8. Visual QC: sample frames at 2 fps and at 15/50/85% of every beat, Read the PNGs, and
   audit the 9-point rubric in CLAUDE-CODE-VISUAL-QC-CHECK.md (including maths frames). Log
   the results in _qc/REPORT.md. Fix root causes until there are 0 BLOCKER and 0 MAJOR
   issues.
9. Report the 4K path, its SHA-256 and an `open` command. Do not publish or push.
```
