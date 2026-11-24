# Blackridge: No Way Back, the pitch (Assignment 8)

- **Author:** Narasimha Reddy Valam
- **Project:** Blackridge: No Way Back, a short crime thriller played from the cab of a delivery
  van on one rainy night (Godot 4.7.2, GDScript, macOS)
- **Role sought:** generalist game developer
- **Film:** "Blackridge: No Way Back, the pitch", 3 min 38 s (218.5 s), 3840×2160, 30 fps
- **Watch:** <https://northeastern-my.sharepoint.com/:v:/g/personal/valam_n_northeastern_edu/IQCRxZTe0mv4R7cb097cFjjhAUO1iZ4CPFfMp2BPDvDqt7w?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=dZz321>
  (Northeastern OneDrive; the film is not in Git: MP4s stay out of the repository)
- **File:** `blackridge-pitch.mp4` (317,949,575 bytes, H.264 and AAC), SHA-256
  `96123b97bb4b4b4cdca4bc263ca305562bae491e98a99f97d75669a4ab23c800`; built at
  `youtube/blackridge-pitch/exports/landscape/`
- **Tag:** `a8` on `develop`

## What is in this folder

| File | What it is |
| --- | --- |
| `PROJECT-BRIEF.md` | The one-page brief: the seven answers, Exists today, Will exist |
| `beat_sheet.json` | The film's plan: narration and visuals per beat, approved by the author (#457-#459); two overnight corrections (B04, B07) are marked in `revisions` for the author's review |
| `SOURCES.md` | Where everything in the film and the game came from, and who made what |
| `FRICTIONAL.md` | What went wrong while making the film, dated, and what was done about it |
| `BUILD-PROMPT.md` | One Claude Code prompt that rebuilds the film |
| `CHECKS.md` | The gates the film passed, with their real output |
| `gates/` | The toolkit's own gate reports for the submitted film (`gates/README.md`) |

## Honesty rules this film keeps

- Past tense only for what exists; everything else is said as a will.
- Every gameplay shot is labelled: real captured play, an automated player (scripted input), not
  a person, with the commit it ran at and the capture's size.
- No invented numbers: the frame times are the ones in `PERFORMANCE.md`; the test shown was run
  for the film, with its date on screen.
- No Claude response is shown. The narration is an AI voice reading the author's approved
  script, and the closing card says so.

## How to rebuild

The reel lives in `youtube/blackridge-pitch/` (its build scripts are in `build/`). Paste
`BUILD-PROMPT.md` into Claude Code from the repository root, with the Brutalist toolkit at
`~/Desktop/brutalist.art`.
