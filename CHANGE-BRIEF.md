# CHANGE-BRIEF — Assignment 5

Specification for Assignment 5, "Shaders, Materials, and the Godot Shading
Language". The author writes everything below. Claude Code set up only the
empty headings and tables from the assignment brief. Once the content is
committed, the original stays unchanged and revisions go at the end with a date.

## 1. The state

What the effect communicates, why the player needs it, and the script and
variable that hold it (`file:line`).

## 2. Effect specification

### 2.1 Shader

Path in `game/shaders/`, `shader_type`, and any `render_mode`.

### 2.2 Uniforms

| Name | Type | Hint | Default | What sets it |
| --- | --- | --- | --- | --- |
| | | | | |
| | | | | |

### 2.3 Colour line

The one line inside `fragment()` that changes the colour.

```glsl
```

### 2.4 Observable rules

| Rule | Specified behaviour |
| --- | --- |
| Uniform value when the state begins | |
| Uniform value when the state ends | |
| Duration of each change in seconds (±1 frame period), equal at 30, 60 and 144 fps | |
| The state begins again mid-transition: restart, extend or ignore | |
| Scaled or unscaled time under `Engine.time_scale` | |
| Behaviour while the tree is paused | |
| Uniform value if the state ends before a transition finishes | |
| Several instances: how each gets its own value | |

### 2.5 Boundaries

What stays unchanged: collision, movement, input, the state machine and its
timings, existing test expectations, and every other object. Presentation code
may read game state; it never writes it.

### 2.6 Evidence split

| Rule | Headless test or my eyes | How |
| --- | --- | --- |
| | | |

## 3. Controlled inputs and predicted values

Three uniform values and at least two named pixels of the shaded object, on its
real background, worked out by hand from the colour line. Say why the output
can be modelled: unshaded, or how the lighting is fixed. If the effect changes
contrast against a background, compute the ratio.

| Pixel | Original RGB | Value 1: | Value 2: | Value 3: |
| --- | --- | --- | --- | --- |
| | | | | |
| | | | | |

Working:

## 4. Hint experiment predictions

A 3×1 PNG with greys 64, 128 and 192 on two unshaded quads, under a Linear
tonemap at exposure 1.0. One sampler uses `source_color` and the other does not.
Predict each band's displayed 8-bit value, and say which quad shows the file's
values unchanged and why. State the renderer, because the brief's predictions
assume Forward+ or Mobile.

| File value | Quad with `source_color` | Quad without |
| --- | --- | --- |
| 64 | | |
| 128 | | |
| 192 | | |

Working:

## 5. Material plan

### 5.1 Object and lighting

### 5.2 Textures

| Texture | Role and source | What its numbers mean | Colour or data | `compress/mode` | `compress/normal_map` | `mipmaps/generate` |
| --- | --- | --- | --- | --- | --- | --- |
| | | | | | | |

### 5.3 Uniforms

| Name | Type | Hint | Range | Default | Group | Expected change across the range |
| --- | --- | --- | --- | --- | --- | --- |
| | | | | | | |

### 5.4 What differs between the two materials, and why

## 6. Predicted failure cases

| Failure | Check that would catch it |
| --- | --- |
| | |
| | |
| | |

## 7. Short answers

1. Which renderer does `project.godot` name, and what does it rule out?
2. What colour arrives in your fragment function before you change it, and what
   would the tempting alternative give you?
3. For `canvas_item`: what would `texture(TEXTURE, UV)` give you instead of
   `COLOR`?
4. For `spatial`: what does `ALBEDO` hold if you never write it, and what does
   `COLOR` hold?
5. How long would a frame-counting version of your effect last at 30, 60 and
   144 frames per second?
6. Which resource holds your uniform's default, which holds its current value,
   and what happens if two objects share the material?
7. Does `hint_range` clamp a value your driver sets from code? Predict now; it
   is checked in Use It.

## Revisions

Dated revisions go here. The original above stays unchanged.
