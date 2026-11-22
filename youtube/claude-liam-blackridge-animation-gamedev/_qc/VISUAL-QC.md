# VISUAL-QC — Blackridge, Frame by Frame

Frame-level QC under `CLAUDE-CODE-VISUAL-QC-CHECK.md`: every beat sampled at 15%, 50% and 85%
(`build/qcframes.py`), the sheets in `_qc/sheets/` read by Claude Code.

## Pass 1: the per-beat renders

| Beat | Severity | Finding | Fix |
| --- | --- | --- | --- |
| B07 | MAJOR | The ring take ran past the dash zoom and was shorter than the beat: from about 40% the beat held an unzoomed dash where the ring cannot be seen | The take cut to the zoom only (movie frames 62-212); played in real time, then twice as a labelled replay |
| B09 | MAJOR | The boarding video waited for its cue at about 12 s: a black box for two thirds of the beat | The narration reordered so "in play" comes first; the video from 0 s, then a labelled replay |
| B15 | MAJOR | The three interrupt takes played at once, small and cropped; the cab views showed before the narration reached them | One take per row, full frame, each starting when the narration names its phase |
| B18 | MINOR | The 4.6 s reload held its last frame for about 10 s | Real time, then two labelled replays |
| B19 | MAJOR (found before batching) | The excerpt (1014-1028) did not contain the grip its narration described | The excerpt moved to 1027-1041, the narration rewritten and regenerated |
| B20 | MAJOR | The take ran on past the shot into the cab view, which held for most of the beat | The take cut to the shot only (movie frames 20-124); real time, then two labelled replays |
| B03 | NOTE | The brief's table rows wrap in the document panel; still readable | kept |
| B11 | NOTE | Clip 70's frame (seated, fading up) is nearly black, as the game shows it | kept; labelled |
| B00-B02, B04-B06, B08, B10, B12-B14, B16-B17, B21-B26 | — | Code at reading size, highlights on cue, cards in order, sources on screen, bookends as locked | — |

## Pass 2: the re-rendered beats

B07, B09, B15, B18 and B20 re-rendered (`--force`); every beat's render matches its audio
(0 mismatches, 439.7 s). Sampled again at 15/50/85% (`_qc/pass2.png`):
- **B07:** the zoomed dash in every row; the ring readable.
- **B09:** the boarding from 0 s, then the replay, ending in the cab; the read-back lines on cards.
- **B15:** one take per row; startup ends seated after 2.7 s and holds the cab until the active
  row; the pause menu over the frozen door in the active row; "Van recovered…" in recovery.
- **B18, B20:** real time, then the labelled replays; the shot alone, the struck man not in frame
  (labelled fixture).

0 BLOCKER, 0 MAJOR remaining in the per-beat renders. The master is checked below.

## Pass 3: the master

- `./art final`: GATE T PASS (27 beats); the toolkit's Gate V 54 frames, 0 BLOCKER, 0 MAJOR
  (`_qc/GATE-V.md`, a copy of the `REPORT.md` the export writes).
- The master sampled at 15%, 50% and 85% of every beat (`_qc/sheets/`) and read: the same frames
  as the per-beat renders; the outro as locked.
- Narration checked by a faster-whisper transcript of B04, B13 and B22. B22's "a second writer"
  came through as "rider", and the revision lost its first "E". It now says "a second script
  playing Ethan's clips" and "one, E, seven, seven, six, five, E", heard as "1 E7765E". B22 was
  regenerated and re-rendered, and the master re-exported.
- The master's audio: −24.6 LUFS integrated, true peak −3.1 dBFS, no silence over 2.5 s.
- Final master: 3840×2160, 30 fps, H.264 and AAC 48 kHz stereo, 439.9 s, 80,969,525 bytes,
  SHA-256 `f2626893f942e25f58a3282c8ec3a324fab406a83a117a2af190c799ccb51040`.

## Pass 4: the re-exported master (#421)

B16, B22 and B24 re-voiced (transcribed: correct) and re-rendered; the master sampled again at
15/50/85% of every beat; the three beats show the new lines. Final master SHA-256
`9dbfd495e2411014449f8642ac4cce2134889a2a9aea42b0ecb168d4fa3d4ed4`, 442.8 s, Gate V 0 BLOCKER, 0 MAJOR.
