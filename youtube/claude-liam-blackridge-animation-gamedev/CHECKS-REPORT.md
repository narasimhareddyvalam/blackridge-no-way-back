# CHECKS-REPORT — Blackridge, Frame by Frame

PROOF GATE, written before the batch render, under skills/make/nopunt/SKILL.md.

25 SHOW / 0 justified-HOLD / 2 CARD / 0 PUNT-flagged.

| Classification | Beats |
| --- | --- |
| SHOW, motion enacting narration | B00 (composer types; result lines land) · B01 (hesitant writer, live correction) · B02 (stills by row on cues) · B03 (document and cards on cues) · B04, B06, B08, B10, B12, B14, B17, B19 (code with line highlights on cues) · B05, B11, B13, B16 (sheet, strip and log frames reveal on cues) · B07, B09, B15, B18, B20 (engine footage, real time) · B21 (recorded output, cards on cues) · B22-B23 (cards on cues) · B25 (composer types the viewer prompt) |
| CARD, legal bookend | B24 verdict · B26 locked outro |

Teaching arc:

| Item | Status | Beats |
| --- | --- | --- |
| FRAMEWORK | ✓ | B03: the cycle spec and the phase table before any clip; B04: what a clip is |
| WORKED EXAMPLE | ✓ | B04-B05: the clip, then the sheet it reads; B10-B11: the table in frames, then the strip at each boundary |
| FALSIFIABILITY | ✓ | B09 (the importer mutation fails the read-back), B13 (the clocks disagree with the brief's prediction), B16 (one prediction not seen), B21 (mutations fail) |
| SCAFFOLDED TASK | ✓ | B25: a real prompt plus a three-part rubric (asks for your prediction first, changes only the table, flags every mismatch) |
| BOOKENDS | ✓ | B00, B01, B24, B25, B26 |
| NO-SOURCE-NO-VERDICT | ✓ | Every claim beat carries an on-screen source line or artifact (file:line, log, capture path, commit) |

Assignment 7's film requirements:

| Requirement | Beats |
| --- | --- |
| The game, both clips, their routes, which loops and which commits | B02 (and B04, B08) |
| What a clip is | B04 (`phone_ring.tres:4-18`) |
| One authority | B06 (`navigation_display.gd:167-175`), B14 (`driver.gd:554-568`) |
| The two clocks | B12 (`first_drive.gd:914-920`), B13 (the r0 log) |
| Designing feel in frames | B10 (`first_drive.gd:30-38`), B11, B16 |
| The sheet, its slicing, the frame track that reads it | B04, B05 |
| The phase table beside the key times; the strip at each boundary | B03, B10, B11 |
| The state machine playing each clip in real play, an interrupt in each phase | B07, B09, B15, B18, B20 |
| What the read-backs proved, the mutations, what no headless run shows | B09, B21 |
| Mistakes caught, readings overruled, uncertainty, next step, contributions, the sheet's source and licence, the revision shown | B16, B22, B23 |

Code → result pairs (teaching contract `code-then-result-v1`): B04→B05, B06→B07, B08→B09,
B10→B11, B12→B13, B14→B15, B17→B18, B19→B20. Every result beat names its hashed media.

Labels: fixture captures are labelled fixtures (the interrupts, the reload, the shock, the
strips); the ring and boarding takes are labelled scripted input on the real main scene; held
frames, crops and the sheet's dark backing are labelled; editor views are labelled "Godot editor
reconstruction". No reconstruction is presented as a screenshot.

Contributions are stated as the records state them (prompt log #362-#417). Step 7's r1 is stated
as Claude Code's decision while the author was away, with the author's verdict after play (#417).
