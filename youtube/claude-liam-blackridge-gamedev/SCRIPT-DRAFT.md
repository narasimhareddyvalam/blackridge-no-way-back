# SCRIPT.md — Blackridge, Shaded

Draft for the author's approval, 2026-10-29. Nothing is rendered until the
author approves this script.

| Field | Value |
| --- | --- |
| Title (outro restates it exactly) | Blackridge, Shaded |
| Slug | `claude-liam-blackridge-gamedev` |
| Builder | Brutalist `godot-gamedev`, `walker` modifier |
| Narrator | Liam, in for Bear (local Kokoro `am_onyx`, free); Teardown register |
| Footer chip | `@NikBearBrown` |
| Game source shown | Blackridge commit to be fixed at render time (now `25c7873`) |
| Output | 3840×2160 landscape, 30 fps; MP4 kept out of Git |

On-screen labels, used everywhere they apply:
- **Godot editor reconstruction · path:lines** on every code view. These are
  teaching views, not recordings of an editing session. Code is copied
  verbatim from the hashed file.
- **Engine capture · scripted input** on footage. Godot Movie Maker renders
  offline at a fixed 60 fps, so it is not a real-time frame-rate claim.
- **Held frame** on stills.
- **Recorded output · logs/...** on test results.
- **Reconstructed prompt** on the opening composer.

Each beat lists what the viewer sees first, then Liam's words. Each code beat
is followed immediately by its visible result, as godot-gamedev's
code-then-result teaching contract requires.

---

## B00 — Cold open (ClaudeComposerAsk, greeting "Namaste, Liam")

**On screen:** the composer types the prompt below, labelled "Reconstructed
prompt". The running line reads "reading the brief…". Three result lines then
land:
- "Brief committed before any shader."
- "Two shaders. Two materials. One experiment."
- "Every number predicted, then measured."

The prompt: "Please use Walker to convert my game design document about
Blackridge: No Way Back (a night-freight van driver in a rain-soaked industrial
district) into two shaders: a dashboard that dims when the headlights are on,
and fog on the van's windows driven by texture maps."

**Liam:** Namaste — this is Liam, in for Bear. This is Blackridge: No Way Back,
a night-freight driving game built in Godot. The prompt on screen is a
reconstruction; the real work started from a written brief. Let's take apart
the two shaders this build added, and how each one was checked.

## B01 — Summary (BrutalistHesitantWriter, 0.8 s lead silence, at least 9 s)

**On screen:** the writer types "Shaders are decoration." and hesitates.
It deletes "decoration" and types "rules you can test." Then it
writes: "In Blackridge, the dashboard dims when the headlights are on, / and the
van's windows fog from texture maps."

**Liam:** Shaders are rules you can test. In Blackridge, the dashboard dims when
the headlights are on, and the windows fog from texture maps. Every number was
predicted by hand first, then measured in the engine.

## B02 — The game and what this build adds (held frame with component chips)

**On screen:** a held engine frame of the night cockpit. A divider splits it:
on one side "Already built: van, district, driving (`e81ec92`)", on the other
"This build". Four chips light in order:
1. State-driven shader → `night_cluster.gdshader`
2. Textured shader with two materials → `foggy_windshield.gdshader`
3. Hint experiment → `hint_experiment.gdshader`
4. Language notes and the generated shader

Footer chip: "Godot 4.7.2 · Compatibility · project.godot:125".

**Liam:** Blackridge already had the van, the district and the driving. This
build adds four pieces: a shader whose colour comes from the van's state, a
textured shader shared by two materials, an experiment on what texture hints do
to the numbers, and a close reading of the shader Godot generates itself. The
game runs Godot 4.7.2 on the Compatibility renderer. Remember that.

## B03 — The specification came first (CHANGE-BRIEF.md excerpts)

**On screen:**
1. The colour line from CHANGE-BRIEF §2.4, verbatim. The three-row uniform
   table slides in.
2. Rule chips light one by one:
   - on 0.25 s;
   - off 0.35 s;
   - reverse from current value;
   - ±1 frame (33.3 / 16.7 / 6.9 ms);
   - time scale 0.5 → 0.50 s;
   - pause freezes;
   - R leaves it alone;
   - one material per van.
3. A git timeline: `2729c26` brief → `c055037` first shader.

**Liam:** Before any shader code, the brief fixed the contract: the exact colour
line, three uniforms, and rules a test can fail. Fade on in a quarter of a
second, off in 0.35. A retrigger reverses from the current value. One frame of
tolerance at 30, 60 and 144 frames per second. And git shows the brief was
committed before the first shader.

## B04 — Code: `game/shaders/night_cluster.gdshader:1–15`

**On screen:** the code view, labelled "Godot editor reconstruction". Lines
highlight in order:
- line 1, `canvas_item`;
- lines 4, 7 and 10, the uniforms and their hints;
- line 14, the colour line.

The notes panel says: "The dashboard is 2D drawing in a 640×256 SubViewport"
and "Big idea 1 → line 14".

**Liam:** Here's the author's hand-written effect. It's a canvas item shader,
because the gauges are 2D drawing inside a SubViewport. Three uniforms: night
amount, driven from code; a warm amber colour; and a brightness floor. Line 14
is the whole effect. It mixes the original colour toward that colour times
amber times brightness. Multiplying keeps the gauge detail, and mix lets it
fade.

## B05 — Result: controlled values against the hand predictions

**On screen:**
1. Three held engine captures of the cluster's SubViewport, at night_amount
   0.0, 0.5 and 1.0.
2. Markers on the background pixel (10, 10) and the dial-hub pixel (155, 136).
3. Typeset maths: R = C·(1 − a + a·n·b), with the worked example
   135 × 0.775 = 104.625 ≈ 105.
4. A table of predicted against measured values. All 18 tick green.
5. The capture at 2.0: hub (13, 0, 0), background (0, 0, 0), and a chip
   reading "hint_range didn't clamp".

Source: `evidence/captures/night_cluster_*.png` and `night_cluster_samples.txt`.

**Liam:** Big idea one: a shader is a small program the GPU runs for every
pixel. Line 14 runs once per dashboard pixel, so its output can be predicted.
The brief predicted two pixels by hand, the dark background and the dial hub,
at three settings. The engine captures match all eighteen numbers exactly. At
2.0, set from code, the hub goes almost black: hint range draws a slider, but
it doesn't clamp.

## B06 — Code: `game/features/vehicles/freight_van/night_dimming.gd:21–31`

**On screen:** the code view, labelled "Godot editor reconstruction · written by
Claude Code". Lines highlight in order:
- line 24, which reads `headlights_on`;
- lines 25–26, the early return;
- line 28, `delta / seconds`;
- line 31, `set_shader_parameter`.

A trace strip builds alongside: L key → `headlights_on` → `night_amount` →
`night_cluster.gdshader:14` → pixels.

**Liam:** The driver is GDScript written by Claude Code, and it only reads the
van's headlights flag. It never sets it. Each frame, it moves night amount
toward its target by delta over the fade time, so the speed doesn't depend on
frame rate. A retrigger simply reverses from wherever the value is. Once it
arrives, lines 25 and 26 stop sending updates.

## B07 — Result: the effect in play (new engine capture)

**On screen:** 4K cockpit footage, labelled "Engine capture · scripted input ·
Godot Movie Maker 60 fps". An input-log tick marks each L press.
1. The dashboard is amber.
2. L: the headlights go off, and the gauges fade to mint-white.
3. L: amber again.
4. A double tap mid-fade: the fade reverses with no jump.

A recorded-output counter shows the measured frames:

| fps | Fade out | Fade in |
| --- | --- | --- |
| 30 | 11 | 8 |
| 60 | 21 | 15 |
| 144 | 51 | 36 |

**Liam:** Here it is in the game. Lights off, and the gauges fade back to mint
white in about a third of a second. Lights on, and the amber returns in a
quarter second. Tap L twice mid-fade, and it turns around without a jump. The
tests measured these fades at 30, 60 and 144 frames per second, each within one
frame.

## B08 — Code: `game/features/vehicles/freight_van/van_presentation.gd:226–233`

**On screen:** the code view (Claude Code's code). Line 230 highlights:
`LIGHT_FOG` on the windshield pane. Then line 232: `HEAVY_FOG` added as a child
of `_windows[0]`.

**Liam:** The textured shader goes on two new overlays, built beside the
existing glass, never in place of it. The windshield gets the light fog
material. The driver's window gets the heavy fog material, and because that
overlay is a child of the window pane, it inherits every move the pane makes.

## B09 — Result: J lowers the window and its fog (new engine capture)

**On screen:** footage with scripted input: J lowers the driver's window, and
the heavy fog moves down with it. A chip reads "0.880 m in the van's frame
(`test_materials.gd`)".

**Liam:** Press J, and the driver's window drops 0.88 metres in the van's own
frame, and the fog rides down with it. The first version of this test measured
in world space and got 1.13 metres, because the whole van also settles onto the
ground. Measuring in the van's frame fixed it. The author confirmed it by hand,
too.

## B10 — Code: `game/shaders/foggy_windshield.gdshader:1–23`

**On screen:** the code view. Lines highlight in order:
- line 1, `spatial`;
- line 2, `render_mode`;
- lines 5, 12 and 18, the groups;
- the ranges and defaults;
- line 9, `source_color`.

The notes panel says "Big idea 4 → lines 2, 5, 9: Godot additions to GLSL".

**Liam:** The fog shader is spatial, because the glass is in 3D. Its render mode
blends it over the scene, skips depth writes, and draws both faces. Seven
uniforms sit in three Inspector groups, each with a type, a range and a
default. Big idea four: group uniforms, hint range and source colour aren't
plain GLSL. They're Godot's shading language talking to the editor.

## B11 — Result: the interface sweep (new 4K capture, wipers parked)

**On screen:** a 7 × 3 grid of held engine frames, one row per uniform, at its
minimum, default and maximum. Each row lights in turn.

**Liam (final wording after I inspect the 4K sweep):** The sweep runs every
control at its minimum, default and maximum. Fog amount pushes the fog inward
from the edges. Clear centre protects the middle. Edge softness turns a hard
border into a gradient. Opacity, tint and texture scale change strength, colour
and pattern size. At the defaults, the windshield fog is deliberately light;
whether the road stays readable is a human check.

## B12 — Code: `game/shaders/foggy_windshield.gdshader:26–35`

**On screen:** the code view. Lines highlight in order:
- line 26, `source_color`;
- line 27, `hint_normal`;
- line 28, no hint;
- line 35, `.r` read as thickness.

The notes panel says "Big idea 3 → line 35".

**Liam:** Three textures, three jobs. Fog colour has source colour, so Godot
decodes it as colour. Fog normal has hint normal: these are directions, not
colours. Fog data has no hint at all, and line 35 reads only its red channel,
as a thickness from zero to one. Big idea three: a texture is information, not
just a picture.

## B13 — Result: the textures, their imports, the normal-map check

**On screen:**
1. The actual `fog_color.png`, `fog_normal.png` and `fog_data.png`.
2. The import settings as recorded: lossless, normal-map mode 2 / 1 / 2,
   mipmaps on, detect 3D off.
3. Curl-ratio bars:
   - the Poly Haven calibration pair: GL 0.5792 against DX 1.4208;
   - `fog_normal.png`: GL 0.0033 against DX 1.9967.
4. A check mark: "green up: OpenGL convention".

**Liam:** Here are the three files. A seeded script written by Claude Code
generated them, so they're original and reproducible. Their import settings are
written down explicitly: lossless, mipmaps on, normal-map mode set by hand.
That's why opening the editor later didn't change them. And a curl check
against a known Poly Haven pair confirms the normal map's green channel points
up, the convention Godot expects.

## B14 — Code: `game/materials/windshield/light_fog.tres:8–19`

**On screen:** the code view. Lines highlight in order:
- line 9, the shader;
- lines 10–12, the textures;
- lines 13–16, the values.

A notes panel, labelled as a source inspection, lists the four values
`heavy_fog.tres` changes: 0.75 / 0.6 / 0.35 / 0.25. A Big idea 2 pointer goes
to `foggy_windshield.gdshader:7`.

**Liam:** A material holds settings, not the program. Light fog points at the
same shader and the same three textures, then sets its own values. Heavy fog
differs in exactly four of them. Big idea two: the shader declares fog amount
once, on line 7, and each material gives it its own value: a quarter here,
three quarters on the side window.

## B15 — Result: one shader, two materials (engine captures)

**On screen:**
1. The windshield (light fog) and the driver's window (heavy fog) side by side,
   with world fog off and then on.
2. Material edit: light fog's `fog_amount` goes from 0.25 to 1.0, and only the
   windshield changes.
3. Shader edit: one shader line is changed in memory on an isolated copy, with
   the file untouched. Both windows change.

**Liam:** Side by side: light fog on the windshield, heavy fog on the driver's
window. Change one value in the light fog material, and only the windshield
thickens, because materials don't share values. Change one line of the shader,
and both windows change, because they share the program. Two edits, and the
difference between a material and a shader is on screen.

## B16 — Code: `game/shaders/hint_experiment.gdshader:1–15`

**On screen:** the code view. Line 5 (`source_color, filter_nearest`)
highlights against line 6 (`filter_nearest` only). Then line 9 (`show_data`),
then line 15 (`ALBEDO`). The notes panel says "`greys_3x1.png`: 64 · 128 · 192".

**Liam:** The hint experiment isolates a single word. A tiny image holds three
grey bands: 64, 128 and 192. The author's shader reads it through two samplers,
one with source colour and one without, and a show data switch picks which one
an unshaded quad displays. Same file, same pixels, one hint different.

## B17 — Result: predicted against measured

**On screen:**
1. Typeset maths: the sRGB encode, with the worked example
   64/255 = 0.251 → 0.537 → 137.
2. A table with three columns of values:
   - predicted: 64/128/192 read as colour, 137/188/225 read as data;
   - Compatibility capture: 64/128/192 on both quads;
   - Forward+ comparison: 137/188/225 on the data quad.
3. Labels: "Held frames · engine captures" and "Forward+ is a comparison run;
   the game ships Compatibility".

**Liam:** The prediction: read as colour, each band is decoded to linear light
and encoded back on the way out, so it stays 64, 128 and 192. Read as data, the
raw value is only encoded: 137, 188 and 225. A Forward+ comparison matched that
exactly. But in Compatibility, the game's renderer, both quads showed the
file's values. Same shader, different renderer, different numbers.

## B18 — Code: `game/shaders/standard_generated.gdshader:6–7`

**On screen:** the code view, labelled "generated by Godot, comments by the
author". The notes panel shows "Mine:" and two lines:
- `foggy_windshield.gdshader:9`, `fog_tint : source_color`;
- `foggy_windshield.gdshader:26`, `fog_color : source_color, filter_linear,
  repeat_enable`.

**Liam:** To learn the language, the author converted a standard material into a
shader and annotated what Godot generated. Lines 6 and 7: an albedo colour and
an albedo texture, both marked source colour. The author's equivalents are fog
tint, on line 9, and fog colour, on line 26. They make the same promise: these
values are colours, so decode them.

## B19 — Result: the same textures through both shaders (new engine capture)

**On screen:** two quads, captured in a test scene on an isolated copy:
- left: the generated shader, with `fog_color` as albedo and `fog_normal` as
  the normal map;
- right: the author's fog shader with `light_fog`.

**Liam:** Here are the same textures through both shaders. Godot's generated
shader paints them onto an opaque, lit surface. The author's shader uses the
data texture and an edge mask to decide where the glass stays clear, and writes
alpha so the road shows through. The generated code teaches the vocabulary; the
hand-written shader decides what the textures mean.

## B20 — Code: `game/tests/test_night_dimming.gd:70–75`

**On screen:** the code view (Claude Code's test). Line 73
(`get_shader_uniform_list()`) highlights, then line 75 ("Shader parses").

**Liam:** Tests get their own look. This is Claude Code's driver test asking
Godot for the shader's uniform list. If the shader fails to parse, that list
comes back empty, so one check catches a broken shader. Other checks press the
real L key through Godot's input system and sample night amount on every frame.

## B21 — Result: recorded test output and the three mutations

**On screen:**
1. Recorded-output panels:
   - night dimming: 30/30 at 30, 60 and 144 fps;
   - materials: 76/76;
   - regression: 64/64;
   - behaviour: 0 failures.
2. Three mutation cards turn red:
   - semicolon removed → `SHADER ERROR: Expected a ';'` → exit 1 (25/30);
   - uniform renamed → exit 1 (27/30);
   - `source_color` removed → exit 1 (75/76).
3. A strip: "What no headless run can show: readability · natural fog ·
   transparent layering · real-window colour · performance".

**Liam:** Every suite passes through the course wrapper at fixed frame rates.
Then come three deliberate breaks: a missing semicolon, a renamed uniform, a
deleted source colour. Each one made a test exit with status one, which proves
the tests can fail. What they can't show is whether any of this looks right. A
headless run draws nothing. That part takes eyes.

## B22 — Caught along the way

**On screen:** four rows, each tagged with who or what caught it:
1. "The CLAUDE.md draft said 'each frame'; it's each physics tick." Caught in
   review; the author approved the fix.
2. "The driver test counted a frame after the fade ended." Caught by a failing
   test (29/30).
3. "The window test measured in world space: 1.13 m." Caught by a failing test;
   now 0.88 m in the van's frame.
4. "The agent searched outside the project folder." Stopped by the author.

**Liam:** Not everything was right the first time. Claude's CLAUDE.md draft said
the van updates every frame; it's every physics tick, fixed in review with the
author's approval. Two agent-written tests were wrong until they failed. And
the author stopped Claude from searching outside the project folder. Every
correction is logged, with its commit, in the frictional log.

## B23 — Who did what, sources, revision

**On screen:** two columns, plus a sources row and a revision chip.
- **Author:** the brief and the hand predictions; the three shaders; the
  annotations; the language notes; the playtest and human checks; every
  decision.
- **Claude Code:** the CLAUDE.md draft; the driver; the tests and wrapper; the
  texture script; the materials and overlays; the captures; the audit and
  reports; this film.
- **Sources:** the fog textures from `tools/make_fog_textures.py` (seed
  20261029, original); the hint image from `tools/make_hint_png.gd`; the Poly
  Haven calibration pair (CC0, used in a test only).
- **Revision chip:** "Game source shown: <commit>".

**Liam:** Who did what. The author wrote the brief and its predictions, all
three shaders, the annotations and the language notes, and played the build.
Claude Code wrote the driver, the tests, the texture script, the materials and
overlays, the captures, the audit and this film. The fog textures are original,
generated by code; the Poly Haven pair is only used in a test.

## B24 — Verdict (ClaudeVerdictArtifact, 0.5 s lead)

**On screen:** four lines.
1. Implemented: a state-driven dashboard shader and a textured fog shader with
   two materials.
2. Verified: the hand predictions matched the captures; the tests and mutations
   behaved as specified.
3. Open: the Compatibility hint result; fog layering with rain; performance on
   the M1.
4. Human judgement: whether it reads well at night.

**Liam:** Let's recap with Claude. Implemented: a dashboard shader driven by the
headlights, and a textured fog shader shared by two materials. Verified: hand
predictions matched the captures, and the tests failed when they should. Still
open: why Compatibility showed no colour-space split, and how the fog layers
with rain. Human judgement: whether it reads well at night. Next step: profile
the fog on the MacBook Air M1 this game targets.

## B25 — Your Turn (ClaudeComposerAsk, greeting "Your turn.")

**On screen:** the composer types the prompt. The running line reads "paste
this into Claude…".

**Liam:** Your turn. Paste this into Claude: Please use Walker to help me test
one change to my night dashboard shader. I will add a clamp to night amount
myself. Before I run anything, check my prediction for the dial hub pixel at
night amount 2.0 after the clamp, then run the capture script and show me
predicted versus measured. That's one small change, a prediction you commit to
first, and a capture that can prove you wrong. Liam, in for Bear.

## B26 — Outro (ClaudeTitleOutro, locked)

**On screen:** "Blackridge, Shaded." with `@NikBearBrown` and one slug-seeded
mascot. No subline, no music.

**Liam:** Blackridge, Shaded. At Nik Bear Brown. (Then a 1 s silent hold.)

---

## New captures this script needs (scripted, on an isolated copy)

- **B07 and B09:** Movie Maker footage at native 3840×2160 of L presses
  (including a mid-fade double tap) and of a J press, each with an input log.
- **B11:** the interface sweep re-captured at 4K with the wipers parked and
  time frozen. The earlier sweep was taken while the wipers and rain were
  moving.
- **B15:** shader-edit capture, with one line changed in memory only. No file
  in `game/shaders/` is touched.
- **B19:** the generated shader and the fog shader on two quads with the same
  textures.

Existing evidence reused, with hashes: the night-cluster captures, the hint
captures, the fog side-by-side and material-edit captures, and the test and
mutation logs.

## Still the author's (not replaced by this film)

The TEST-REPORT human checks: the sweep notes, the shader-edit test in the
editor, and confirming the captures by eye.
