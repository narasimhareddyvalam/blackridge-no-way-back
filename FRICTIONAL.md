# FRICTIONAL — Assignment 5 honest log

The author's log of what they tried, expected, saw, checked and learned, with
human and AI work kept apart. Each entry is dated and points to a commit,
prompt, test log or capture. AI may organise these notes, but it does not
write the author's experiences. Entries marked "recorded by Claude Code"
contain facts only.

## Entry format

- **Tried / expected:**
- **What happened:**
- **Checked or changed in response:**
- **Learned / still unresolved:**
- **Human vs AI:** what I wrote; what the agent wrote; what I accepted,
  modified or rejected
- **Trace:** commit, prompt, log or capture

## 2026-10-28 — Changing games for the final

Write here, in your own words, why you switched from your Assignment 2–4 game
to *Blackridge: No Way Back*. `SUBMISSION.md` points to this entry.

## 2026-10-28 — Setup before the specification (recorded by Claude Code)

- Claude Code read the assignment brief and the project, and explained the
  requirements.
- At the author's request it initialized Git with a repo-only identity and made
  three commits:
  - `e81ec92`: the project as found;
  - `7385eb8`: the game-change note in `fractional.md`;
  - `2b6b251`: the course wrapper `scripts/run-test.sh`, adapted for `game/`,
    with the baseline logs.
- Baseline at 60 fps through the wrapper: regression 64/64, integration 29/29.
- Claude suggested candidate effects (impact flash, night illumination, brake
  lamps) and textured objects. The author's choice is recorded in
  `CHANGE-BRIEF.md`.
- Claude created empty skeletons for `CHANGE-BRIEF.md`, `LANGUAGE-NOTES.md`,
  `FRICTIONAL.md`, `TEST-REPORT.md`, `SOURCES.md` and `SUBMISSION.md`: headings
  and copied questions only.
- Correction recorded 2026-10-29: the line above said no shader content
  existed before `CHANGE-BRIEF.md`. That was true when it was written, but
  the author then drafted all three shaders from their own notes before
  writing the brief. The brief was committed (`2729c26`) before any shader
  was committed (`c055037`). No driver or test content existed before the
  brief.

## 2026-10-28 — My own notes (author to write)

Write here, in your own words:
- that you drafted the shaders before the brief while learning;
- why you moved from impact flash to night dimming, and from wet cladding to
  the foggy windshield;
- what you checked in the `CLAUDE.md` draft, and which fixes you decided on.

## 2026-10-28 – 2026-10-29 — Agent work (recorded by Claude Code, facts only)

- **CLAUDE.md, session 1** (`ea88542`, review `4bba9b2`):
  - `claude -p` with the course's tool scope: success in 34 of 40 turns;
  - 4 Bash calls denied;
  - read-only `cat`/`grep` still ran outside the allowed list, so checksums of
    `game/shaders/` were the real guarantee: unchanged.
- **Brief:** the author's `night_amount` default was 1.0 in the shader but
  0.0 in the brief. Claude flagged it. The author chose 0.0 and changed it
  themselves with a `!` command; Claude declined to edit the shader.
- **Driver and test** (`132a068`):
  - first run 29/30. The failure was a test bug: it counted one frame after
    the fade had finished. The test was fixed;
  - float rounding made the 60 fps fade land one frame late, so the driver
    now snaps within 1e-6;
  - then 30/30 at 30, 60 and 144 fps; existing suites 64/64 and 29/29.
- **Night cluster captures** (`5669a40`): the measured pixels at 0, 0.5 and
  1.0 equal the author's hand predictions exactly. At 2.0 the result differs
  from 1.0, so `hint_range` did not clamp a value set from code.
- **Hint experiment** (`5669a40`): under Compatibility both quads show
  64/128/192. Under a Forward+ comparison the data quad shows 137/188/225,
  which is the author's prediction. A diagnostic with a separate data-only
  texture gives the same split.
- **Fog** (`0b8fbb0`, `384e5b8`, `2204b55`):
  - textures written by code;
  - the first import defaulted to Detect, no mipmaps, and detect-3D on; all
    were set explicitly;
  - calibration GL 0.5792 / DX 1.4208, and `fog_normal.png` 0.0033 / 1.9967;
  - Claude made both materials from the brief's values and added the overlays.
- **Flagged:** the author's `foggy_windshield.gdshader` draft does not match
  CHANGE-BRIEF §5. It uses a screen texture, is unshaded, has `ALPHA = 1.0`
  and only one uniform group. It needs rewriting by the author.
- **Fog shader rewritten** (`3bac73e`): the author rewrote it. The audit
  (`fe625c4`) then found two differences from the brief, multiply instead of
  `mix()` and fixed ROUGHNESS and SPECULAR values. The author settled both
  with a dated brief revision (`a09eb4e`).

## 2026-10-29 — My own notes on testing (author to write)

Write here what you saw when you looked at the captures and played the game.
Include the Compatibility hint result and how you explain it.
