# PROMPTS — Blackridge, Shaded

## Prompts shown on screen

**B00, cold open (ClaudeComposerAsk; eyebrow "RECONSTRUCTED PROMPT").** This is a
reconstruction for the walker bookend, and the narration says so. The real work started from
CHANGE-BRIEF.md.

> Please use Walker to convert my game design document about Blackridge: No Way Back, a
> narrative crime game where you drive freight through a rainy industrial town at night, into
> two shaders: a dashboard that dims when the headlights are on, and fog on the van's windows
> driven by texture maps.

**B01, summary (BrutalistHesitantWriter).** The writer types the text below, then replaces
the trigger "decoration" with "rules you can test".

```text
Shaders are decoration.
In Blackridge, the dashboard dims
when the headlights are on,
and the windows fog from texture maps.
```

The seed is `claude-liam-blackridge-gamedev`.

**B27, Your Turn (ClaudeComposerAsk).** Liam reads this prompt aloud, then discusses it.

> Please use Walker to help me test one change to my night dashboard shader. I will add a
> clamp to night_amount myself. Before I run anything, check my prediction for the dial-hub
> pixel at night_amount 2.0 after the clamp, then run the capture script and show me
> predicted versus measured.

## Prompts used to make the film

- **The build:** the author asked Claude Code (in this repository, 2026-10-29) to make the
  film with the Brutalist godot-gamedev skill and the walker modifier, following every
  toolkit rule. The author approved the script with one instruction: never frame the work as
  course requirements, and never count completed items in the film.
- **The engine captures:** a Claude Code subagent recorded them from a written specification
  on an isolated copy of `game/`. The specification and its results are in
  `capture/CAPTURE.md`.
- **Generation:** no paid media generation and no image or video generator. Every visual is
  real engine output, an actual source file, or a Remotion teaching view.
