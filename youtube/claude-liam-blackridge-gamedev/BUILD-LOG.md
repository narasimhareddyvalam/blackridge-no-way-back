# BUILD-LOG — Blackridge, Shaded

Built 2026-10-29 by Claude Code with the Brutalist toolkit at `~/Desktop/brutalist.art`
(commit `6a8380a`), following skills/make/godot-gamedev/SKILL.md with the `walker` modifier.

## Author decisions

- **Script approved, with one instruction:** the film must not frame the work as course
  requirements or count completed items. The skill's "lead with the actual assignment
  requirements" step is therefore replaced by a neutral "what this build adds" setup
  (B02). Coverage is unchanged.
- **Title:** "Blackridge, Shaded". **Greeting:** "Namaste, Liam".

## Toolkit gaps found and handled

1. **`./setup` stops early.** Its ElevenLabs guard fails on references inside the toolkit's
   own `youtube/` examples, so the readiness table never prints. Each check was run directly
   instead:
   - ffmpeg 8.0.1;
   - Node 24.20;
   - venv Python 3.12 with kokoro_onnx, faster_whisper, manim and Pillow;
   - the Kokoro model files;
   - the Kokoro smoke test (−21.8 dB).
2. **Fonts were not installed.** The bundled EB Garamond, Lato and Inter TTFs were copied to
   `~/Library/Fonts`, as `./setup --install` would do.
3. **`typeset_math.py` imports matplotlib, but `requirements.txt` omits it.** matplotlib 3.11
   was installed into the toolkit venv; maths uses TypesetMath, never a text fallback.
4. **No script consumes `lead_silence_s` or a tail hold.** The 0.8 s (B01) and 0.5 s (B26)
   lead silences and the 1.0 s outro tail (B28) were added to those MP3s with ffmpeg and
   re-measured. Each change is noted in that beat's `audio_notes`.
5. **No existing component shows engine evidence with provenance labels** (GATE L search:
   "image evidence with labeled callouts", "video clip with overlay labels", "table of numbers
   rows reveal"). New shared component `GodotEngineEvidence` (+916) was added in
   `runtime/remotion/src/scenes/`, registered in Root.tsx and indexed with `./art scene-index`.
   It plays OffthreadVideo inside a Sequence, so footage starts when shown and is never
   retimed.
6. **`GodotDevWorkbench` clipped a 15-line shader** (line 14 cut off at 4K). The pilot QC
   frame showed it. Added an opt-in `dense` prop (tighter page margins; default layout
   unchanged), and `//` comments now highlight as comments (shader files use `//`).

## Pilot QC (before batching)

- **B05 (new component):**
  - rows switch on the spoken cues and the cards reveal in order;
  - defect: dead space under the media, and terracotta on markers, chips and cards at once.
  - Fixed by centring the content vertically and keeping terracotta only on the latest card;
    markers and chips are now white/ink.
- **B04 (code):** line 14 clipped. Fixed with `dense` and font 23; the complete
  15-line file is now readable.

## Narration

- Kokoro `am_onyx`, free and local; 27 beats generated, then B03 regenerated after
  "Git shows" was changed to "The commit history shows" (it risked sounding like "get").
- Word clock: `runtime/scripts/align.py` (faster-whisper base); 27/27 beats aligned, 0
  fallbacks.
- A whisper transcript was checked for risky terms: GLSL, Claude dot M D, 4.7.2, the encode
  numbers.
- **B01 (hesitant writer), blocker from QC:** the frame at 11.5 s showed no correction.
  `BrutalistHesitantWriter` matches triggers per single word, so the phrase trigger
  "a coat of paint" never fired. The trigger is now the single word "decoration", replaced by
  "rules you can test"; the final sentence is unchanged. Typing was sped up (charMs 30,
  hesitateBetween 8) so the correction lands well before the cut.
- **B03, minor from QC:** the verbatim markdown table wrapped awkwardly. The document panel
  in `GodotEngineEvidence` is now 70% wide when the layout is `document`.
- **B27:** the Your Turn narration now gives the viewer a three-part rubric (asks for your
  number first, shows the measured pixel, flags a mismatch), as nopunt's scaffolded-task
  item requires.

## GATE T (type_check.py), first run: 4 FAIL

| Beat | Finding | Cause | Fix |
| --- | --- | --- | --- |
| B02 | §8.1 min-size 37 px | The game's own HUD text inside the 4K cockpit capture | `GodotEngineEvidence` added beside `GodotDesignFigure` in `HAND_DRAWN_PATTERNS`, the existing exemption for real engine captures. Its own text stays checked. |
| B05 | §8.3b local contrast 1.15:1 | The dashboard capture at night_amount 2.0 is nearly black, as the evidence requires | Added to `DARK_BACKGROUND_MARK_PATTERNS` beside `GodotDesignFigure` (same reasoning). |
| B06 | §8.5 note 13 words | Prose in a TypesetMath note | Shortened to 8 words |
| B11 | §8.5 output 14 words | GodotDevWorkbench output line | Shortened to 8 words |

The two image-content exemptions mirror the toolkit's documented treatment of
`GodotDesignFigure`. No check was loosened for designed text.
