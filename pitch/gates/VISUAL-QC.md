# VISUAL-QC: Blackridge: No Way Back, the pitch

Frames read by Claude Code from each rendered beat (`_qc/pilot/`), 2026-11-23/24. Severity:
BLOCKER (wrong or dishonest on screen), MAJOR (hurts reading), MINOR.

## Pilot and per-beat reads

| Beat | Read | Found | Fixed |
| --- | --- | --- | --- |
| B00 | 6 frames incl. a 90-frame join | footer named the old 1280×800 clip (MAJOR: wrong provenance) | footers now written from the 4K take and its start |
| B01 | 8 frames | the writer never corrected "a driving game" (BLOCKER: contradicts the narration); its triggers are single words | triggers "driving, game" → "crime, thriller": types "a driving", "a crime game", "a crime thriller" |
| B02 | 5 frames | cards on their cues, readable | — |
| B03 | 8 frames | first cut ended at 294.4 s, before the hit (BLOCKER: "a man in the headlights" not shown) | cut moved to 289 s: the glare, the man in the headlights and the hit (about 297.5 s), Ethan gripping the wheel; Exists card on cue |
| B04 | — | narration "Watch him back onto bay nine ... strap it by hand" not shown by the shot (MAJOR) | sentence reworded to what the shot shows; voice regenerated (a draft for the author) |
| B06 | 8 frames | call prompt on the dash; GTA V, ETS2, Blackridge cards in turn | — |
| B07 | 8 frames | opening, then the walk to the van; Reader and Will cards | — |
| B08 | 8 frames | shaders, particles, animation cards on cue; EnterVan shot | — |
| B09 | 7 frames | four cards on cue; the test's result line legible | — |
| B13 | 7 frames | all four lines in by 2.5 s on the component's own stagger, not on their spoken cues (MINOR; `ClaudeVerdictArtifact` has no timing props and is the required verdict scene) | left as designed |
| B14 | 8 frames | the lines under the composer could be read as a reply (MAJOR) | labelled "Rubric, a good answer: ..." |
| B07 (re-render) | 4 frames | the Will card came in on the first "will" (0.7 s), not "That is a will" (MINOR) | cue moved to "is a will" |
| B10 (re-render) | 4 frames | the label's "1280×800" read as the capture size (MAJOR: mislabels the 4K capture) | label: "frame times from PERFORMANCE.md (MacBook Air M4, game window 1280×800)" |
| B04, B05, B11, B12 | 8 frames each | the pallet then the dark van; Maya at the gate then Lily; Checkpoint saved with In/Out/First; HE TOLD THEM EVERYTHING, SIX MONTHS LATER, the sunny house | — |
| B15 | gate | GATE T: the meta line 55 px < 82 px floor (BLOCKER); Gate V: underfill 20% (MAJOR) | the disclosure split into two shorter lines; declared `qc.sparse_by_design` with its reason |

## The master

`exports/landscape/blackridge-pitch.mp4`: three frames from every beat (at 15%, 50% and 90% of
it), 48 in all (`_qc/master_a.jpg`, `_qc/master_b.jpg`), read by Claude Code on 2026-11-24. Every
beat shows what its narration says; every gameplay shot carries its label and its take; no
instructor name or handle appears; the closing card names the author and the AI voice.
Result: 0 BLOCKER, 0 MAJOR. Open, for the author: the B13 verdict's lines come in on the
component's own stagger (MINOR).
