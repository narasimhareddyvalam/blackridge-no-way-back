# CHECKS-REPORT — Blackridge, Rain and Vapour

PROOF GATE, written before the first slate or render, under skills/make/nopunt/SKILL.md.

26 SHOW / 0 justified-HOLD / 2 CARD / 0 PUNT-flagged.

| Classification | Beats |
| --- | --- |
| SHOW, motion enacting narration | B00 (composer types; result lines land) · B01 (hesitant writer, live correction) · B02–B03 (still, document and cards reveal on spoken cues) · B04, B07, B10, B12, B14, B16, B19 (code with line highlights on cues) · B05, B08, B13, B17 (engine footage, real time, input ticks) · B09, B11, B15, B18, B20 (strip frames reveal row by row on cues) · B06, B21, B22 (recorded output, cards on cues) · B23–B24 (cards reveal on cues) · B26 (composer types the viewer prompt) |
| CARD, legal bookend | B25 verdict · B27 locked outro |

Revised after the frame-level QC (2026-11-08, `_qc/VISUAL-QC.md`): the input ticks were dropped. B05,
B13 and B17 play their clip in real time, then step to labelled held frames on spoken cues; B08
plays an excerpt of the in-play take, then one labelled replay.

Teaching arc:

| Item | Status | Beats |
| --- | --- | --- |
| FRAMEWORK | ✓ | B03: the brief and its measurable rules before any example; B04: the three parts of a particle system |
| WORKED EXAMPLE | ✓ | B04–B05: one scene's three parts, then the engine drawing them; B09: a prediction, then the strip |
| FALSIFIABILITY | ✓ | B09 (three of Claude's predictions wrong), B21 (mutations make the tests fail), B22 (B2 over its budget) |
| SCAFFOLDED TASK | ✓ | B26: a real prompt plus a three-part rubric (asks for your prediction first, shows the strip and the price, flags a mismatch) |
| BOOKENDS | ✓ | B00, B25, B26, B27 |
| NO-SOURCE-NO-VERDICT | ✓ | Every claim beat carries an on-screen source line or artifact (file:line, log, capture path, commit) |

Code → result pairs (teaching contract `code-then-result-v1`): B04→B05, B07→B08, B10→B11,
B12→B13, B14→B15, B16→B17, B19→B20. Every result beat names its hashed media.

Labels: preview-scene captures are labelled fixtures; the in-play take is labelled scripted input
on the real main scene; held frames and crops are labelled; editor views are labelled
"Godot editor reconstruction". No reconstruction is presented as a screenshot.

Contributions are stated as the records state them (prompt log #173): the author chose the
effects, wrote the brief, directed every change, played and judged, and made every final call;
Claude Code built, tested, tuned, captured and measured; Codex saved Step 6's shader; all at the
author's direction.
