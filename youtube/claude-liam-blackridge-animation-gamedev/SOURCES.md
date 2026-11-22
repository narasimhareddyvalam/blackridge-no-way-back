# SOURCES — Blackridge, Frame by Frame

## Game source shown

- Repository: `develop`, game source `game/` at commit `1e7765e` (the captures' revision).
- Code excerpts are read verbatim from the hashed files in `gamedev-evidence.json`; the checker
  verifies each line range against the file.

## Engine footage

- `capture/manifest.json`: SHA-256, frames and duration of every take; method in
  `capture/CAPTURE.md`.
- Strip frames: `captures/enter_van/r0|r1/` in the repository (fixture captures, Movie Maker
  1280×800 at 30 fps), copied into `evidence/strips/`.

## Recorded output shown

- `CHANGE-BRIEF.md` §3, §4 (B03).
- `logs/animation/rig/fresh_cache`, `rig/mutation_loop` (B09).
- `logs/animation/step7/enter_van_r0.log` (B13).
- `logs/animation/{repin, step7_r1, reload, shock}`, `logs/animation/mutations/EXITS.txt` (B21).

## Assets in the game

- `phone_ring.png`: drawn by `tools/art/make_phone_ring_sheet.py`, original, no licence needed.
- Ethan's clips: Adobe Mixamo, under Mixamo's terms (`SOURCES.md` in the repository).
- The M16: "M16 Assault Rifle" by jeandiz on Sketchfab, CC BY 4.0.

## Production

- Narration: Kokoro `am_onyx` (local, free), Liam in for Bear.
- Brutalist toolkit at `~/Desktop/brutalist.art`: skills/make/godot-gamedev with `walker`;
  Remotion scenes `GodotDevWorkbench`, `GodotEngineEvidence`, `ClaudeComposerAsk`,
  `BrutalistHesitantWriter`, `ClaudeVerdictArtifact`, `ClaudeTitleOutro`.
