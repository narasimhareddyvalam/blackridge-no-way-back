# BUILD-PROMPT: Blackridge: No Way Back, the pitch

A single paste-ready Claude Code prompt that rebuilds the pitch film end to end from this
repository at tag `a8`, with the Brutalist toolkit at `~/Desktop/brutalist.art` (commit `6a8380a`,
plus the two local changes in `pitch/SOURCES.md` §1). It never publishes, never pushes, never
calls a paid API, and never edits `game/shaders/` or `game/project.godot`.

```text
Read ~/Desktop/brutalist.art/skills/make/godot-waikthrough/SKILL.md in full (standard mode, not
walker), plus the ai-explainer and riff skills it names. Then rebuild youtube/blackridge-pitch in
this order, stopping on any failure. The plan is pitch/beat_sheet.json; never edit the reel's
beat_sheet.json by hand.

1. Gate: git status shows nothing changed under game/. game/override.cfg must not exist except
   while a recording runs.
2. Footage (only if captures/pitch/takes4k/ is missing or its hashes differ from
   youtube/blackridge-pitch/coverage.json): record each run with Movie Maker at 3840x2160, 30
   fps, a temporary game/override.cfg setting window_width_override=3840 and
   window_height_override=2160 (removed after), and an empty HOME:
     Mission 1: film_missions.gd -- 1, 10200 frames; keep 30-80, 95-120, 155-225, 235-260,
       275-312 s
     Mission 2: film_mission_two.gd -- load, 1500 frames, keep 25-50 s; -- yard, 3900 frames,
       keep 95-130 s
     Mission 3: film_missions.gd -- 3 gate, 9000 frames, keep 0-50, 80-135, 230-300 s
       (keyframe_interval 64, to fit the disk)
   Cut each window from the .ogv in one sequential decode at a constant 30 fps (never seek into
   Theora), crf 17, and a 960x540 proxy of the whole run; check frame counts; read the proxies'
   frames and set build/segments.json from what they show.
3. Audio (master clock), only if the narration changed: generate_audio_kokoro.py (am_onyx), bake
   the lead silences (B01 0.8 s, B13 0.5 s) and the outro tail (B15 1.0 s), align.py.
4. Sheet: python3 youtube/blackridge-pitch/build/build_sheet.py (it must report no missing cue or
   segment).
5. Evidence: python3 build/coverage.py, then ./art godot-waikthrough --check
   youtube/blackridge-pitch. It must PASS.
6. Visuals, one beat at a time: footage beats (B00, B03-B08, B10-B12) with
   python3 build/render_chunked.py <BID> (CHUNK=20 for B10); the others with runtime/scripts/remotion_scenes.py
   <reel> --only <BID>. Pilot one of each scene first and read its frames.
7. Docs: python3 build/docs.py (SCRIPT.md, SHOTLIST.md).
8. Final: ./art final youtube/blackridge-pitch --height 2160 --fps 30 --out
   youtube/blackridge-pitch/exports/landscape. GATE T and Gate V must pass; the film must run
   2-4 minutes.
9. Visual QC: read frames from every beat of the master, log them in _qc/VISUAL-QC.md, fix root
   causes until there is no blocker. Report the 4K path, its SHA-256 and an `open` command.
```
