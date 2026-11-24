# CHECKS: the gates the pitch film passed

Run by Claude Code on 2026-11-24 against `youtube/blackridge-pitch/`; the output below is copied
from the runs.

| Gate | Command | Result |
| --- | --- | --- |
| Walkthrough evidence | `./art godot-waikthrough --check youtube/blackridge-pitch` | PASS: 14 implemented features with gameplay evidence, 3 planned with reasons, 10 captures, each 3840×2160, 16:9, its SHA-256 matching `coverage.json` |
| GATE T (typography) | run by `./art final` (`runtime/scripts/type_check.py`) | PASS, 16 beats (`TYPECHECK.md`); advisory only: B15's narration reads its title card |
| Gate V (frames) | run by `./art final` (`runtime/qc/final_frame_check.py`) | 32 frames sampled, BLOCKER 0, MAJOR 0 (`_qc/REPORT.md`) |
| Loudness | `runtime/scripts/loudness_check.py <reel> --mp4 <master>` | PASS, -24.70 LUFS, true peak -2.94 dBTP, no silent beat |
| Sharpness | `runtime/scripts/sharpness_check.py <reel>` | PASS, 16 beats, median Laplacian variance 607.5 |
| Visual QC by eye | 48 frames of the master, three per beat | 0 BLOCKER, 0 MAJOR (`_qc/VISUAL-QC.md`) |
| The test shown in B09 | `scripts/run-test.sh test_save_rules.gd 60` (2026-11-23 20:33) | SAVE RULES RESULT: 29/29 passed; 0 failed |

Toolkit notes printed by `./art final` (style lint, not gates):
- "B00: ... the cold open is 'GodotEngineEvidence' — COLD OPEN LAW wants ClaudeComposerAsk": the
  cold open is real gameplay, the strongest thing the pitch has to show, and a composer opening
  would show a prompt that was never typed.
- "B15: ... the outro is 'FormACard' — OUTRO LAW wants ClaudeTitleOutro": `ClaudeTitleOutro`
  hard-codes the instructor's handle, which the handout forbids.

The master: `blackridge-pitch.mp4`, 3840×2160, 30 fps, H.264 and AAC 48 kHz stereo, 218.5 s
(3 min 38 s), 317,949,575 bytes, SHA-256
`96123b97bb4b4b4cdca4bc263ca305562bae491e98a99f97d75669a4ab23c800`, as the compiler's
`.verified.json` records.
