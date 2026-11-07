# CHANGE-BRIEF.md: particle effects (Assignment 6)

<!--
TEMPLATE, added by Claude Code on 2026-11-07. Everything under these headings is yours to
write: the assignment says "You write: CHANGE-BRIEF.md, every prediction, every verdict and the
process-shader notes", and this file is committed before the first prompt.

The headings follow the assignment's "1. Predict" section, with one block per effect. Facts,
file references, real-world numbers and Godot 4.7.2 property names for every part are in
docs/PARTICLE_RESEARCH.md. These guide comments don't show when the file is rendered; keep or
delete them.

Once committed, the text above "Revisions" stays as written. Changes go in dated revisions.
-->

**Status:** written by me on <date>, before any Assignment 6 prompt or code, and committed on
`develop` before the first prompt.

The previous brief (Phase 1, the Phase 2 brief for Mission 2, and both versions of the save
rules) moved unchanged to `docs/PHASE_BRIEF.md` on 2026-11-07. Assignment 5's brief is at tag
`a5` (`git show a5:CHANGE-BRIEF.md`).

## 1. The effects

| | Effect | Job | Event or condition | Graded |
| --- | --- | --- | --- | --- |
| A1 | Wiper flick | One-shot | | Yes |
| A2 | Roof spill on hard braking | One-shot | | Yes |
| B1 | Rain in every lamp's light | Ambience | | |
| B2 | Exhaust vapour | Feedback loop | | |

## 2. A1: Wiper flick

### The job

<!-- What the effect tells the player, and why the player needs it. The script and the signal
or variable that hold its event. Research §3. -->

### Intent

<!-- How it should read on screen. A list of settings is not a design. -->

- **Timing phases** (rough durations, and what happens in each: a strong first frame, a fast
  outward phase, a slower dissipation):
- **Contrast** against the real background, at its darkest and its lightest (name the places):
- **Scale** against the character (Ethan, the van, the blade), judged at 1280×800:
- **Change over life** (colour, alpha and scale curves):
- **Variation** (velocity, scale, hue, rotation), so repeats don't look stamped:
- **Emitters,** and what each one does (one root node may hold several):

### Settings

<!-- Values. The configuration test reads every one back. Godot 4.7.2 names only: research §7. -->

- **Node type** (CPU or GPU, 3D) and why:
- **Emission:** amount, one_shot, explosiveness, lifetime, emission shape:
- **Process:** velocity, spread, gravity, damping; colour, alpha and scale curves:
- **Draw:** texture, draw material, blend mode, billboard mode, mesh:
- **local_coords** (on or off) and why:
- **visibility_aabb,** and whether it was generated, or set and checked:
- **preprocess:**

### Rules a test can measure

- **Fires** on every event the retrigger rule allows, never otherwise (including on scene load),
  and at the event's position:
- **Retrigger rule** when the event repeats within one lifetime (restart; overlap, with the most
  bursts alive at once; or ignore):
- **If the node it would follow is freed** on the same event:

### Evidence

<!-- For each rule above: a headless test, a frame strip, or your eyes in the running game, and
how. -->

### Frame strip

<!-- The preview scene's background is a representative stretch of the real level. The trigger
is at frame 10, at 30 fps; read frames 10, 12, 15, 20, 30 and 50 (the trigger, then 2, 5, 10, 20
and 40 frames after it). If it lives longer than about 1.3 s, add frames. -->

- **Background:**
- **Frame 10:**
- **Frame 12:**
- **Frame 15:**
- **Frame 20:**
- **Frame 30:**
- **Frame 50:**

## 3. A2: Roof spill on hard braking

### The job

<!-- What the effect tells the player, and why the player needs it. The script and the signal
or variable that hold its event. Research §4. -->

### Intent

- **Timing phases** (rough durations, and what happens in each):
- **Contrast** against the real background, at its darkest and its lightest (name the places):
- **Scale** against the character (Ethan, the van, the windshield), judged at 1280×800:
- **Change over life** (colour, alpha and scale curves):
- **Variation** (velocity, scale, hue, rotation):
- **Emitters,** and what each one does:

### Settings

- **Node type** (CPU or GPU, 3D) and why:
- **Emission:** amount, one_shot, explosiveness, lifetime, emission shape:
- **Process:** velocity, spread, gravity, damping; colour, alpha and scale curves:
- **Draw:** texture, draw material, blend mode, billboard mode, mesh:
- **local_coords** (on or off) and why:
- **visibility_aabb,** and whether it was generated, or set and checked:
- **preprocess:**

### Rules a test can measure

- **Fires** on every event the retrigger rule allows, never otherwise (including on scene load),
  and at the event's position:
- **Retrigger rule** when the event repeats within one lifetime (restart; overlap, with the most
  bursts alive at once; or ignore):
- **If the node it would follow is freed** on the same event:

### Evidence

<!-- For each rule above: a headless test, a frame strip, or your eyes in the running game, and
how. -->

### Frame strip

<!-- Trigger at frame 10, at 30 fps; frames 10, 12, 15, 20, 30 and 50, more if it lives longer
than about 1.3 s. -->

- **Background:**
- **Frame 10:**
- **Frame 12:**
- **Frame 15:**
- **Frame 20:**
- **Frame 30:**
- **Frame 50:**

## 4. B1: Rain in every lamp's light

### The job

- **What it tells the player,** and why the player needs it:
- **Which job** (ambience, a feedback loop or a trail):
- **The script and variable** that hold its condition:
- **The process or draw feature it uses that neither A effect does:**

<!-- Candidates: a different emission shape, turbulence, damping, an attractor, collision, a
sub-emitter, a trail, a flipbook, or a value-driven amount_ratio. Research §5. -->

### Intent

- **Timing phases** (starting, steady state, after the condition ends):
- **Contrast** against the real background, at its darkest and its lightest (name the places):
- **Scale** against the character (Ethan, the van), judged at 1280×800:
- **Change over life** (colour, alpha and scale curves):
- **Variation** (velocity, scale, hue, rotation):
- **Emitters,** and what each one does:

### Settings

- **Node type** (CPU or GPU, 3D) and why:
- **Emission:** amount, one_shot, explosiveness, lifetime, emission shape:
- **Process:** velocity, spread, gravity, damping; colour, alpha and scale curves:
- **Draw:** texture, draw material, blend mode, billboard mode, mesh:
- **local_coords** (on or off) and why:
- **visibility_aabb,** and whether it was generated, or set and checked:
- **preprocess** (for anything that should already be running when its scene loads):

### Rules a test can measure

- **Starts** when its condition begins, and **stops** when it ends:
- **While the tree is paused:**
- **While it is hidden:**

### Evidence

<!-- For each rule above: a headless test, a frame strip, or your eyes in the running game, and
how. -->

### Frame strip

<!-- The condition begins at frame 10 and ends at a frame you choose. Pick frames that show it
starting, at steady state, and after the condition ends. -->

- **Background:**
- **The condition ends at frame:**
- **Frames to read, and what each shows:**

## 5. B2: Exhaust vapour

### The job

- **What it tells the player,** and why the player needs it:
- **Which job** (ambience, a feedback loop or a trail):
- **The script and variable** that hold its condition and its game value:
- **The process or draw feature it uses that neither A effect does:**

<!-- Research §6. -->

### Intent

- **Timing phases** (starting, steady state, after the condition ends):
- **Contrast** against the real background, at its darkest and its lightest (name the places):
- **Scale** against the character (Ethan, the van), judged at 1280×800:
- **Change over life** (colour, alpha and scale curves):
- **Variation** (velocity, scale, hue, rotation):
- **Emitters,** and what each one does:

### Settings

- **Node type** (CPU or GPU, 3D) and why:
- **Emission:** amount, one_shot, explosiveness, lifetime, emission shape:
- **Process:** velocity, spread, gravity, damping; colour, alpha and scale curves:
- **Draw:** texture, draw material, blend mode, billboard mode, mesh:
- **local_coords** (on or off) and why:
- **visibility_aabb,** and whether it was generated, or set and checked:
- **preprocess:**

### Rules a test can measure

- **Starts** when its condition begins, and **stops** when it ends:
- **While the tree is paused:**
- **While it is hidden:**
- **The game value's range,** and how it maps to amount_ratio (never amount):

### Evidence

<!-- For each rule above: a headless test, a frame strip, or your eyes in the running game, and
how. -->

### Frame strip

<!-- The condition begins at frame 10 and ends at a frame you choose. Pick frames that show it
starting, at steady state, and after the condition ends. -->

- **Background:**
- **The condition ends at frame:**
- **Frames to read, and what each shows:**

## 6. Boundaries

<!-- What must not change, in your own words: collision, movement, input, the state machine and
its timings, existing test expectations, the Assignment 5 shaders in game/shaders/ and every
other object. Presentation code may read game state; it never writes it. -->

## 7. Predicted failures

<!-- At least three, each with the check that would catch it. The assignment's "Failures worth
predicting" and this game's own candidates are in research §8. -->

| # | Failure | The check that would catch it |
| --- | --- | --- |
| 1 | | |
| 2 | | |
| 3 | | |

## 8. Price predictions and budgets

<!-- For each effect: the peak particle count, the predicted headless CPU price, the predicted
GPU time, and a budget with the price it is compared on. Compare GPU nodes on GPU time, because
their headless CPU price is near zero by construction; compare CPU nodes on both prices.
Research §9. -->

| Effect | Peak particles | Headless CPU (predicted) | GPU time (predicted) | Budget | Compared on |
| --- | --- | --- | --- | --- | --- |
| A1 | | | | | |
| A2 | | | | | |
| B1 | | | | | |
| B2 | | | | | |

## 9. Questions

1. Which node type does each effect use, and which features in your brief does it lack? (Check
   the class reference for 4.7.2.)
2. With local_coords as you set it, what does each A effect do if its parent moves after the
   event?
3. Under your retrigger rule, how many bursts of each A effect can be alive at once? What peak
   particle count does that give?
4. What will a headless run report as the cost of a GPU effect, and why? With vsync on, what
   would FPS read with the effect off and with it on?
5. What does each B effect show on the first frame after its scene loads, with preprocess and
   without it? While the tree is paused? While the node is hidden?
6. Which settings in your brief belong to emission, which to process, and which to draw?

## Revisions

<!-- Dated revisions go below this line. The text above stays as committed. -->
