# SOURCES — Blackridge, Rain and Vapour

## Game source shown

- Repository: `develop`, game source `game/` at commit `c1c9d8b` (unchanged through `72ac99c`,
  the commit the captures copied).
- Code excerpts are read verbatim from the hashed files listed in `gamedev-evidence.json`; the
  checker verifies each line range against the file.

## Engine footage

- `capture/manifest.json`: SHA-256, frames and size of every take; method in
  `capture/CAPTURE.md`.
- Strip frames: `captures/<effect>/r0|r1/` in the repository (fixture captures, Movie Maker
  1280×800 at 30 fps, #163), three copied into `evidence/strips/`.

## Recorded output shown

- `CHANGE-BRIEF.md` §2, §7, §8 and revisions 1–11 (B03).
- `logs/particles/mutations_final/cost/cost_effects_60fps.log` (B06).
- `logs/particles/strips_163/SUMMARY.txt`, `logs/particles/mutations_final/SUMMARY.txt` (B21).
- `logs/particles/gpu_price/RESULT.txt`, from `game/tests/gpu_price.gd` and
  `tools/tests/gpu_price.py` (B22).
- `captures/roof_spill/r1-retrigger-true/events.txt` (B11).
- `TUNING.md`, `TEST-REPORT.md`, `SUBMISSION.md`, `FRICTIONAL.md`, and
  `docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #131–#173 (B09, B18, B23, B24).

## Assets and licences

- The five particle textures (`water_bead`, `fine_spray`, `roof_stream`, `rain_streak`,
  `exhaust_puff`) are drawn by `tools/make_particle_textures.py`: original, no licence needed.
- Poly Haven's `security_light`, `green_metal_rust` and `leafy_grass`: CC0 1.0. The streetlight
  is built by `tools/art/build_streetlight.py`. Every source is listed in the repository's
  `SOURCES.md`.

## Upstream documentation consulted

- Apple, "Monitoring your Metal app's graphics performance" and "Customizing the Metal
  Performance HUD": the `MTL_HUD_ENABLED` and `MTL_HUD_LOG_ENABLED` variables and the per-frame
  log format behind the GPU price (B22).

## Film toolkit and voice

- Brutalist toolkit at `~/Desktop/brutalist.art`, commit `6a8380a`, with the local components
  added for the Assignment 5 film (`GodotEngineEvidence`, `GodotDevWorkbench` dense mode).
- Narration: Liam, Kokoro `am_onyx`, local and free.
