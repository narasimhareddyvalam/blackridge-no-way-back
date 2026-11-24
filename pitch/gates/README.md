# The toolkit's gate reports for the submitted film

Copied from `youtube/blackridge-pitch/` at `1600fbc`, as the gates wrote them on 2026-11-24 for
`blackridge-pitch.mp4` (SHA-256 `96123b97bb4b4b4cdca4bc263ca305562bae491e98a99f97d75669a4ab23c800`).

| Report | Gate | Result |
| --- | --- | --- |
| `TYPECHECK.md` | GATE T (typography), run by `./art final` | PASS, 16 beats, 0 FAILs |
| `GATE-V-REPORT.md`, `gate-v-contact-sheet.png` | Gate V (frames of the final master) | 32 frames, BLOCKER 0, MAJOR 0 |
| `LOUDNESS.md` | loudness | PASS, -24.70 LUFS, true peak -2.94 dBTP |
| `SHARPNESS.md` | sharpness | PASS, 16 beats |
| `VISUAL-QC.md` | Claude Code's read of the master's frames | 0 BLOCKER, 0 MAJOR |

`./art godot-waikthrough --check` prints its result and writes no file: PASS (14 implemented
features with gameplay evidence, 3 planned with reasons, 10 captures at 3840×2160), as
`pitch/CHECKS.md` records it.
