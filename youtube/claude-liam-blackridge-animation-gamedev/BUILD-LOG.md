# BUILD-LOG — Blackridge, Frame by Frame

Built 2026-11-22 by Claude Code with the Brutalist toolkit at `~/Desktop/brutalist.art`,
following skills/make/godot-gamedev/SKILL.md with the `walker` modifier, at the author's word
(#406). The author was away. Assignments 5 and 6's films (`youtube/claude-liam-blackridge-gamedev/`,
`youtube/claude-liam-blackridge-particles-gamedev/`) are untouched; this reel reuses Assignment 6's
build helpers (`build/docs.py`, `build/qcframes.py`) and the pattern of its sheet and ledger
builders.

## Author instructions and Claude Code's decisions

- **#406:** "make sure the video includes everything we did in this assignment, show the
  animations in the video as well. make sure they are wired up in the game. make sure to satisfy
  all assignment requirements … take decisions for me realistic". The film covers all four clips
  in the game, every film requirement of the handout (`CHECKS-REPORT.md`), and states
  contributions as the records state them.
- **Title and greeting (Claude Code's choice, for the author to change at review):** "Blackridge,
  Frame by Frame", after "Blackridge, Shaded" and "Blackridge, Rain and Vapour"; greeting
  "Namaste, Liam", as in both.
- **Step 7's r1 is stated as Claude Code's decision** while the author was away, not as the
  handout's observation-driven revision; the author's verdict is stated as open (B16, B22, B24).
- **Length:** 27 beats, about 1,470 words, about 440 s, decided by the required content.

## Engine footage

New takes recorded by Movie Maker from `game/` at `1e7765e` (`capture/CAPTURE.md`). Two are
scripted input on the real main scene (the ring, and boarding at the roadside). The rest are
labelled fixtures: the three interrupts, the reload and the shock.
- The first reload capture ran at about 0.3 frames a second through Mission 3's handover
  cutscene and was stopped. The take now arms Ethan through the encounter's own `arm()`.
- In the second reload capture he was aiming at Maya from arm's length, which reads badly and is
  poor muzzle discipline. He was re-placed 3 m from her, facing away.

## Narration

- Kokoro `am_onyx`, local and free; 27 beats; word clock by `runtime/scripts/align.py`, 27/27
  aligned, 0 fallbacks.
- B01's 0.8 s and B24's 0.5 s lead silences and B26's 1.0 s tail were baked with ffmpeg and
  re-measured.
- Rewritten after a check against the sources:
  - **B09:** once its result became visible media, the narration gained a sentence on the clip
    playing once.
  - **B19:** its excerpt moved to `driver.gd:1027-1041`, where the grip and the seat's reach
    actually are, and its narration followed.

## Evidence gate

- The first `./art godot-gamedev --check` failed: B09's and B13's results pointed at log files,
  and results must be visible media.
  - B09 now shows Ethan's boarding in real play, playing once, with the read-back's lines on
    cards.
  - B13 shows strip r0's frames 44-46 with the log's line.
- Then: PASS.

## Pilot QC (before batching)

- **B04 (code):** fifteen lines readable, the highlight on the keys line, the notes panel
  unclipped.
- **B05 (sheet):** the sheet's six cells large on their dark backing, then the six dash frames.

## Batch render and QC

- All 27 beats rendered one at a time with `remotion_scenes.py`.
- Frame-level QC found five beats whose engine footage was shorter than the beat or waited for
  its cue (B07, B09, B15, B18, B20). Each now plays its take in real time, then labelled
  replays; B15 shows one interrupt per row. The ring and shock takes were cut to their events.
  Details are in `_qc/VISUAL-QC.md`.
- `remotion_scenes.py` skips beats already filled; re-renders need `--force`.
- `./art final` refuses without `SHOTLIST.md` (GATE F): run `build/docs.py` first.

## Final export

- `./art final <reel> --height 2160 --fps 30 --out <reel>/exports/landscape`: GATE T PASS, Gate V
  0 BLOCKER, 0 MAJOR.
- `exports/landscape/claude-liam-blackridge-animation-gamedev.mp4`, hard-linked as
  `Blackridge-Frame-by-Frame-4K.mp4`: 3840×2160, 30 fps, H.264 and AAC 48 kHz stereo, 439.9 s
  (7 min 20 s), 81.0 MB.
- SHA-256 `f2626893f942e25f58a3282c8ec3a324fab406a83a117a2af190c799ccb51040`, as the compiler's `.verified.json` beside it also records.
- Not in Git: the author uploads it to the course's media storage.
