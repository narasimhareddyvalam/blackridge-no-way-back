# Visual QC — Blackridge, Rain and Vapour

Frame-level audit under `CLAUDE-CODE-VISUAL-QC-CHECK.md`. Each beat sampled at 15%, 50% and 85%
of its span (`build/qcframes.py`), contact sheets read in `_qc/sheets/`. Severity: BLOCKER
(clipped or unreadable, or a false claim on screen) > MAJOR (overlap, outside the safe margin,
narration not matching what is shown) > MINOR (tight but legible).

`_qc/REPORT.md` is the toolkit's own Gate V summary, which `./art final` writes over on every
export; this audit is kept here so that no export can overwrite it. The final export's
Gate V: 56 frames sampled, 0 BLOCKER, 0 MAJOR.

## Defects found on the per-beat renders

| Beat | Rubric | Defect | Cause | Severity |
| --- | --- | --- | --- | --- |
| B04 | — | Render failed: `p.output.join is not a function` | `output` passed as a string; the component takes a list of recorded lines | BLOCKER |
| B04 | 3 | Third source note ("Draw") clipped by the notes panel | Note texts too long for the panel's height | BLOCKER |
| B04, all code beats | 4 | Two-line source footer overlapped the window's lower edge | Credit text too long for one line | MAJOR |
| B05 | — | Narration named the red glow and the switch-off 3 s after the 6.3 s clip had played them | A real-time clip is shorter than its narration; footage may not be retimed | MAJOR |
| B05 | 4 | "brake" and "engine off" tick labels overlapped ("brakængine off") | Ticks 0.66 s apart on a 12 s strip | MAJOR |
| B06 | 6 | The cost table's columns wrapped inside the document panel | Log lines wider than the panel | MINOR |
| B08 | — | The in-play take ran on into the pause menu and reverse gear, which B08's narration does not cover | The whole take was played from 1 s | MAJOR |
| B09 | 6 | A1's dashes too small to see in the r0/r1 crops | Crop too wide | MAJOR |
| B10, B12, B14 | 3 | Lines past the 15th hidden by the code panel; B12's "hides" (line 84) and B14's "three droplets" (line 57) highlighted invisible lines | Excerpts of 16–21 lines in a panel that shows 15 | BLOCKER |
| B17 | — | Narration said the in-play dash "shows it", but the dash crop is too small to show the plume | Claim beyond the evidence | MAJOR |
| B19 | 3 | A 20-line excerpt would clip the same way | As B10 | BLOCKER |
| B18 | — | B1's r0/r1 row never showed: both rows were timed at 0 s, so the B2 row won from the start | Row times not tied to the narration | MAJOR |
| B22 | 3, 4 | The excerpt ran past its panel and the source line overlapped the panel's edge | The line filter also caught the per-effect detail rows | MAJOR |

## Fixes applied

- B04: each code beat's `output` is its test's recorded result line; notes shortened to fit; the
  source footer shortened to one line (`<path>:<lines> · <credit> · verbatim`).
- B05, B13, B17: grid rows. The clip plays once in real time, then the panel steps to labelled
  held strip frames as the narration names each state; B05's narration reordered to follow the
  clip; ticks removed.
- B06: the excerpt is the log's own verbatim summary sentences, which wrap as prose.
- B08: an excerpt of frames 30–254 (up to the pause), then one labelled replay.
- B09: A1 cropped to the pillar region, about 2.5× larger.
- B10, B12, B14: excerpts cut to 15 lines that keep every cued line (342–356, 70–84, 43–57).
- B17: narration now says the dash shows the same camera.
- B19: lines 248–257, the scale curve (254) and the alpha curve (255): two brief settings in
  short lines that fit; B19's and B20's narration follow.
- B18: B1's row from 0 s, B2's from the narration's "the exhaust".
- B22: the excerpt is the price table's header and its five rows, verbatim.

## Second pass: every claim against the records

The re-renders were checked again, and this time every narrated sentence and on-screen label of a
result, tuning, test or limits beat was compared with the recorded readings (`TUNING.md`, the test
logs and summaries, the brief's revisions), not only with the frames.

| Beat | Rubric | Defect | Cause | Severity |
| --- | --- | --- | --- | --- |
| B09 | — | Card "Wrong twice" and "two predictions were wrong": `TUNING.md` records three wrong (A1's heavy drop on frames 20–30, the passenger line on frame 10, A2's streams on frame 15) and two off in brightness | `FRICTIONAL.md`'s "two of its #160 predictions" lost its qualifier | BLOCKER |
| B21 | — | Card "30 earlier runs pass" and "thirty earlier test runs": the summary's 30 runs are 22 earlier and 8 of Assignment 6 | The whole summary counted as earlier | BLOCKER |
| B17 | — | Narration said the reverse camera shows an idle wisp and a denser plume on the throttle; its recorded reading has only the red column on frame 80 and a faint wisp on 100, "the other frames none" | Narration written from the rear view's states | MAJOR |
| B20 | — | Labels "small and dense at the pipe" (frame 55) and "grown and fading" (frame 80) set two frames up as young and old puffs; frame 80 is the brighter one | Labels written from the narration, not the frames | MAJOR |
| B13 | — | "Rain … from the first frames": the strip has none on frames 10 and 12 | Narration from the design, not the reading | MAJOR |
| B23 | — | "Streaks a quarter too thin": they were a quarter as wide as their quads (brief revision 5), as its own card says | Wording | MAJOR |
| B15 | — | "A few splash specks": the reading says no splash specks can be picked out, "at most a few dots on the road" | Interpretation stated as observation | MAJOR |
| B18 | — | "No vapour" in the first B strips: the reverse camera showed a dozen red dots on frame 80 | Over-generalised | MINOR |
| B22 | 6 | Each table row wrapped its last column onto a second line beside the cards | Rows of 87–99 characters in a panel that fits 73 | MINOR |

Fixes:

- B09: "three were wrong, and two were off in brightness"; the card names the three.
- B21: "the twenty-two earlier test runs still pass"; the card "22 runs pass".
- B17: the narration follows the recorded reading; the held frames are labelled with what each
  shows ("throttle, none shows", "engine off, a faint wisp", "gone"); the clip plays on through the
  red column before them; the state test's readings (0.15, 0.80, 0, frozen) on a card.
- B20: each frame labelled with what it shows ("a small plume, pulling away"; "dense at the pipe,
  fainter out").
- B13: "a few frames after the start"; the pause and title cards cite the state test
  (`test_lamp_rain_state.gd:50, 130, 136`).
- B23: "rain streaks a quarter as wide as they should be".
- B15: "at most a few specks where they land"; splashes "too faint to pick out"; the title
  "drops land; splashes faint".
- B18: "almost no vapour".
- B22: the cards removed, so the table has the full width; their facts stay in the narration and
  the source line.
- B09, B13, B15, B17, B18, B21 and B23 narration regenerated and aligned (0 fallbacks), and checked
  with a faster-whisper transcript; `FACTCHECK.md`, `RIFF.md` and the ledger's observations
  corrected to match.

## Re-check

- **Per-beat re-renders:** every changed beat (B06, B08, B09, B10, B12, B13, B14, B15, B17, B18,
  B19, B20, B21, B22, B23) was sampled again at the times its rows and cues change and read at
  1280 wide; B17's held frames and B20's frames were also read at full size. No clipped line, no
  overlap, and no sentence or label beyond its record. One fault found here was fixed: after
  B13's narration grew, its 4 s clip ended 2 s before "after the stop" and held an empty frame
  under "steady"; a held row of frames 20 and 50 now follows the clip at "to the ground".
- **GATE T** (`TYPECHECK.md`): PASS, 28 beats, 0 FAILs (minimum size, overflow, contrast, local
  contrast, overlap and card clip on all 28; no wordy card on 23).
- **Gate V** (`_qc/REPORT.md`, the toolkit's): 56 frames sampled, 0 BLOCKER, 0 MAJOR.
- **The master** (`exports/landscape/claude-liam-blackridge-particles-gamedev.mp4`): 3840×2160,
  30 fps, H.264 with AAC 48 kHz stereo, 460.8 s. Every beat sampled at 15%, 50% and 85%
  (`_qc/sheets/`, seven sheets, all read), and the compiler's `_qc/contact_sheet.png`: each beat
  in its place, its text inside the frame, picture and narration in step. Integrated loudness
  −24.6 LUFS, true peak −3.2 dBFS; no silence longer than 2.5 s.
- **Accepted as MINOR:** B21's long log lines wrap inside their panel, each test's line starting
  at the margin; B11's three strip frames are small; B00's and B26's composer shows the toolkit's
  default model chip ("Fable 5 · High"), as Assignment 5's film did. It belongs to the
  reconstructed prompt's mock, not to a record of the model used.
