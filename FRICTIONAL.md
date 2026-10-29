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
- No specification, shader, driver or test content existed before
  `CHANGE-BRIEF.md`.
