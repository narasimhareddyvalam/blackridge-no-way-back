# BUILD-LOG — Blackridge, Rain and Vapour

Built 2026-11-08 by Claude Code with the Brutalist toolkit at `~/Desktop/brutalist.art`
(commit `6a8380a` with the local components added for the Assignment 5 film), following
skills/make/godot-gamedev/SKILL.md with the `walker` modifier, at the author's word (#172).
Assignment 5's film in `youtube/claude-liam-blackridge-gamedev/` is untouched.

## Author instructions and Claude Code's decisions

- **#173:** cover everything done in Assignment 6, keep it short, follow the toolkit's laws,
  and "make sure the script says i did everything". The film states contributions as the
  records state them, with the author first: the handout requires "the human and AI
  contributions", and the prompt log, `FRICTIONAL.md` and `SUBMISSION.md` already say who did
  what (Claude Code's answer, prompt log #173).
- **Title and greeting (Claude Code's choice, for the author to change at review):** "Blackridge,
  Rain and Vapour", after the author's "Blackridge, Shaded" for Assignment 5; greeting
  "Namaste, Liam", as there.
- **Length:** 28 beats, 1,541 words, 460.8 s (7 min 41 s) in the master. The first draft ran 1,556
  words; nine beats were tightened, and every required item kept; the second QC pass's
  corrections added 43 words.
- **Coverage added on review:** the world changes (#150–#158) in B18, and the brief's revisions
  in B03, so the film covers all of Assignment 6.

## Engine footage

New takes recorded by Movie Maker at the game's 1280×800 on an isolated copy
(`capture/CAPTURE.md`): one scripted-input take on the real main scene, and full clips of the
seven preview fixtures. The in-play driver at first let the game run while paused, because the
game inherited the driver's always-processing mode; the game is now pausable under it, and the
flick count holds at 9 through the pause.

## Narration

- Kokoro `am_onyx`, local and free; all 28 beats generated; word clock by
  `runtime/scripts/align.py`, 28/28 aligned, 0 fallbacks.
- No script consumes `lead_silence_s` or a tail hold, as in Assignment 5: B01's 0.8 s and B25's
  0.5 s lead silences and B27's 1.0 s tail were baked with ffmpeg and re-measured.
- A faster-whisper transcript of B01, B02, B07, B19, B22 and B23 checked the risky terms (GPU,
  Godot 4.7.2, 403, 422, HUD, CC zero, C1C9D8B). "Mist" in B07 was heard as "missed" and became
  "spray", the brief's own word. The seven beats regenerated after the second QC pass (B09,
  B13, B15, B17, B18, B21, B23) were transcribed the same way.

## Pilot QC (before batching)

- **B04 (code):** the render failed: `output` must be a list of recorded lines, and a label had
  been passed. Each code beat now shows its own test's recorded result. On the next pilot, the
  notes panel clipped its third note and the two-line source footer overlapped the window, so
  the notes and the credit were shortened to fit one line.
- **B05 (video):** the clip lasts 6.3 s, but the narration reached the red glow and the
  switch-off three seconds after they had played, over the held last frame. Footage is never
  retimed, so B05, B13 and B17 now show the clip in real time, then step to labelled held strip
  frames as the narration names each state. B05's narration was reordered to follow the clip.
- **B09 (strip grid):** A1's crop was too wide for the flick's dashes to show; it now crops the
  pillar region, about 2.5× larger, where r1's dashes are plain beside r0's bare wet line.

## QC on the first full render

Every beat was sampled at 15%, 50% and 85% (`build/qcframes.py`). Found and fixed, then
re-rendered: code excerpts longer than the 15 lines the panel shows (B10, B12, B14; B19 moved to
the generated shader's lines 248–257, the scale and alpha curves, with B19's and B20's narration
regenerated); B08's take running on into the pause and reverse gear (now an excerpt and a
labelled replay); B17's claim that the dash crop shows the plume (now: the dash shows that same
camera); B18's B1 row never showing; B22's excerpt overflowing its panel; B06's wrapped table
(now the log's own summary sentences). The details are in `_qc/VISUAL-QC.md`.

A second pass then compared every narrated sentence and on-screen label with the recorded
readings, not only with the frames, and found eight claims wrong or overstated: two counts on
cards (B09's wrong predictions, B21's earlier runs), what the reverse camera shows (B17), two
frame labels (B20), when the fixture's rain appears (B13), splash specks the reading could not
pick out (B15), the streaks' width (B23), and "no vapour" (B18); and B22's table wrapped beside
its cards. Each was corrected from the records, seven beats' narration regenerated, and nine
beats re-rendered.

## Toolkit gaps and hazards

- `remotion_scenes.py` stamps provenance back into `beat_sheet.json` after each render, so a
  rebuild of the sheet during a render can be overwritten; the sheet is only rebuilt between
  renders.
- `./art final` writes its Gate V summary over `_qc/REPORT.md`, which held this build's
  frame-level QC until the final export replaced it. The audit was restored from this session's
  record into `_qc/VISUAL-QC.md`, which no export writes; `_qc/REPORT.md` keeps Gate V's summary,
  as in Assignment 5's film.

## Checks

- `./art godot-gamedev --check`: PASS (98 files in 9 components, 680 exclusions with a reason,
  7 exact excerpts, 7 code → result pairs).
- GATE T: PASS, 28 beats, 0 FAILs (`TYPECHECK.md`).
- Gate V, the toolkit's (`_qc/REPORT.md`): 56 frames sampled, 0 BLOCKER, 0 MAJOR.
- Frame-level QC: two passes on the per-beat renders and one on the master
  (`_qc/VISUAL-QC.md`).

## Final export

- `./art final <reel> --height 2160 --fps 30 --out <reel>/exports/landscape`, which runs GATE T
  first (its log, `build/final_export.log`, stays out of Git).
- `exports/landscape/claude-liam-blackridge-particles-gamedev.mp4`: 3840×2160, 30 fps, H.264
  and AAC 48 kHz stereo, 460.8 s (7 min 41 s), 66.9 MB.
- SHA-256 `8080d78ae388f2d6955b40411490b9ec2e64c58eb3e3e8cb44e4728a80539e92`, as the compiler's
  `claude-liam-blackridge-particles-gamedev.verified.json` beside it also records.
- Not in Git: the author uploads it to the course's media storage.
