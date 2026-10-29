# SCRIPT.md — Blackridge, Shaded

Voiced script, generated from `beat_sheet.json`. Narrator: Liam (in for Bear) (Kokoro `am_onyx`); register Teardown; godot-gamedev with the `walker` modifier.
The author-approved draft is `SCRIPT-DRAFT.md`; changes since then are listed in `BUILD-LOG.md`.

## B00 — Ask (ClaudeComposerAsk, 17.4 s)

**On screen:** Composer types the reconstructed Walker prompt · Running line, then three result lines land.

**Liam:** Namaste. This is Liam, in for Bear. This is Blackridge: No Way Back, a narrative crime game where you drive freight through a rainy industrial town at night, built in Godot. The prompt on screen is a reconstruction; the real work started from a written brief. Let's take apart the two shaders this build added, and how each one was checked.

## B01 — Bluf (BrutalistHesitantWriter, 12.3 s)

**On screen:** Writer types 'Shaders are decoration.' · Deletes 'decoration', types 'rules you can test'.

**Liam:** Shaders are rules you can test. In Blackridge, the dashboard dims when the headlights are on, and the windows fog from texture maps. Every number was predicted by hand first, then measured in the engine.

## B02 — Setup (GodotEngineEvidence, 20.0 s)

**On screen:** Held 4K cockpit frame; 'Already built' card · Four component cards light in narration order · Engine card: Godot 4.7.2 · Compatibility · project.godot:125.

**Liam:** Blackridge already had the van, the district and the driving. This build adds four pieces: a shader whose colour comes from the van's state, a textured shader shared by two materials, an experiment on what texture hints do to the numbers, and a close reading of the shader Godot generates itself. The game runs Godot four point seven point two, on the Compatibility renderer. Remember that.

## B03 — Spec (GodotEngineEvidence, 22.6 s)

**On screen:** Verbatim CHANGE-BRIEF colour line and uniform table · Rule cards reveal as spoken · Commit order card: 2729c26 -> c055037; CLAUDE.md:91 import.

**Liam:** Before any shader code, a written brief fixed the contract: the exact colour line, three uniforms, and rules a test can fail. Fade on in a quarter of a second, and off in zero point three five. A retrigger reverses from the current value. One frame of tolerance at 30, 60 and 144 frames per second. The commit history shows the brief landed before the first shader, and the project's Claude dot M D imports it.

## B04 — Code (GodotDevWorkbench, 20.3 s)

**Liam:** Here's the author's hand-written effect. It's a canvas item shader, because the gauges are 2D drawing inside a sub-viewport. Three uniforms: night amount, driven from code; a warm amber colour; and a brightness floor. Line 14 is the whole effect. It mixes the original colour toward that colour times amber times brightness. Multiplying keeps the gauge detail, and mix lets it fade.

## B05 — Result (GodotEngineEvidence, 21.9 s)

**On screen:** Captures cycle 0.0 -> 0.5 -> 1.0 with pixel markers · Predicted -> measured cards tick 18/18 · 2.0 capture; 'hint_range does not clamp' card.

**Liam:** Big idea one: a shader is a small program the GPU runs for every pixel. Line 14 runs once per dashboard pixel, so its output can be predicted. The brief predicted two pixels by hand, the dark background and the dial hub, at three settings. The engine captures match all eighteen numbers exactly. At two point zero, set from code, the hub goes almost black: hint range draws a slider, but it doesn't clamp.

## B06 — Math (TypesetMath, 19.8 s)

**On screen:** Row 1: the factored colour line · Row 2: the worked hub-red case.

**Liam:** Here's the hand calculation. Factor the mix, and each channel is the original value times one minus the amount, plus the amount times amber times brightness. For the hub's red channel at one half, that's 135 times zero point seven seven five: one hundred and four point six two five, which rounds to 105. The capture reads 105.

## B07 — Code (GodotDevWorkbench, 19.2 s)

**Liam:** The driver is GDScript written by Claude Code, and it only reads the van's headlights flag. It never sets it. Each frame, it moves night amount toward its target by delta over the fade time, so the speed doesn't depend on frame rate. A retrigger simply reverses from wherever the value is. Once it arrives, lines 25 and 26 stop sending updates.

## B08 — Result (GodotEngineEvidence, 17.4 s)

**On screen:** Footage: L press, dashboard fades to mint-white · L press, amber returns · Double tap reverses mid-fade · Recorded frame-count card.

**Liam:** Here it is in the game. Lights off, and the gauges fade back to mint white in about a third of a second. Lights on, and the amber returns in a quarter of a second. Tap L twice mid-fade, and it turns around without a jump. The tests measured these fades at 30, 60 and 144 frames per second, each within one frame.

## B09 — Code (GodotDevWorkbench, 15.7 s)

**Liam:** The textured shader goes on two new overlays, built beside the existing glass, never in place of it. The windshield gets the light fog material. The driver's window gets the heavy fog material, and because that overlay is a child of the window pane, it inherits every move the pane makes.

## B10 — Result (GodotEngineEvidence, 17.9 s)

**On screen:** Footage: J press, window and fog lower together · Card: 1.13 m world-space bug -> 0.880 m in van frame.

**Liam:** Press J, and the driver's window drops zero point eight eight metres in the van's own frame, and the fog rides down with it. The first version of this test measured in world space and got one point one three metres, because the whole van also settles onto the ground. Measuring in the van's frame fixed it. The author confirmed it by hand, too.

## B11 — Code (GodotDevWorkbench, 19.8 s)

**Liam:** The fog shader is spatial, because the glass is in 3D. Its render mode blends it over the scene, skips depth writes, and draws both faces. Seven uniforms sit in three Inspector groups, each with a type, a range and a default. Big idea four: group uniforms, hint range and source colour aren't plain G L S L. They're Godot's shading language talking to the editor.

## B12 — Result (GodotEngineEvidence, 21.8 s)

**Liam:** The sweep runs every control at its minimum, default and maximum on the windshield, then measures what changed. Fog amount is the big one: at its maximum, eight percent of the frame changes and the pane clouds over. Clear centre at zero lets fog creep in from the corner. The other five barely move a pixel, because at the light default the fog band sits behind the frame. To judge them, the next sweep needs a heavier base fog.

## B13 — Code (GodotDevWorkbench, 18.4 s)

**Liam:** Three textures, three jobs. Fog colour has source colour, so Godot decodes it as colour. Fog normal has hint normal: these are directions, not colours. Fog data has no hint at all, and line 35 reads only its red channel, as a thickness from zero to one. Big idea three: a texture is information, not just a picture.

## B14 — Result (GodotEngineEvidence, 21.6 s)

**On screen:** The three actual texture files · Import-settings cards · Curl-ratio card: calibration vs fog_normal.

**Liam:** Here are the three files. A seeded script written by Claude Code generated them, so they're original and reproducible. Their import settings are written down explicitly: lossless, mipmaps on, normal-map mode set by hand. That's why opening the editor later didn't change them. And a curl check against a known Poly Haven pair confirms the normal map's green channel points up, the convention Godot expects.

## B15 — Code (GodotDevWorkbench, 18.3 s)

**Liam:** A material holds settings, not the program. Light fog points at the same shader and the same three textures, then sets its own values. Heavy fog differs in exactly four of them. Big idea two: the shader declares fog amount once, on line 7, and each material gives it its own value: a quarter here, three quarters on the side window.

## B16 — Result (GodotEngineEvidence, 20.1 s)

**On screen:** Baseline: both overlays · Material edit clip: only the windshield thickens · Shader edit clip: both windows change.

**Liam:** Side by side: light fog on the windshield, heavy fog on the driver's window. Change one value in the light fog material, and only the windshield clouds over, because materials don't share values. Now turn that fog up so it shows, and change one line of the shader: both windows turn red, because they share the program. Two edits, and the difference between a material and a shader is on screen.

## B17 — Code (GodotDevWorkbench, 18.0 s)

**Liam:** The hint experiment isolates a single word. A tiny image holds three grey bands: 64, 128 and 192. The author's shader reads it through two samplers, one with source colour and one without, and a show data switch picks which one an unshaded quad displays. Same file, same pixels, one hint different.

## B18 — Result (GodotEngineEvidence, 25.8 s)

**On screen:** Predicted values card · Forward+ capture with measured bands · Compatibility capture: file values on both quads.

**Liam:** The prediction: read as colour, each band is decoded to linear light and encoded back on the way out, so it stays 64, 128 and 192. Read as data, the raw value is only encoded: 137, 188 and 225. A Forward Plus comparison matched that exactly. But in Compatibility, the game's renderer, both quads showed the file's values. Same shader, different renderer, different numbers.

## B19 — Math (TypesetMath, 19.9 s)

**On screen:** Row 1: sRGB encode · Row 2: 64 -> 137.

**Liam:** Here's the encode the prediction used. Above a tiny threshold, the stored value is one point zero five five times the linear value to the power one over two point four, minus zero point zero five five. Feed in 64 over 255, about zero point two five one, and you get about zero point five three eight: 137.

## B20 — Code (GodotDevWorkbench, 19.0 s)

**Liam:** To learn the language, the author converted a standard material into a shader and annotated what Godot generated. Lines 6 and 7: an albedo colour and an albedo texture, both marked source colour. The author's equivalents are fog tint, on line 9, and fog colour, on line 26. They make the same promise: these values are colours, so decode them.

## B21 — Result (GodotEngineEvidence, 20.7 s)

**Liam:** Here are the same texture files through both shaders. Godot's generated shader paints the colour texture onto an opaque, lit surface, and the normal map raises tiny bumps. The author's shader turns them into fog: the data texture makes it patchy, and alpha lets the stripes behind it show through. The generated code teaches the vocabulary; the hand-written shader decides what the textures mean.

## B22 — Code (GodotDevWorkbench, 16.8 s)

**Liam:** Tests get their own look. This is Claude Code's driver test asking Godot for the shader's uniform list. If the shader fails to parse, that list comes back empty, so one check catches a broken shader. Other checks press the real L key through Godot's input system and sample night amount on every frame.

## B23 — Result (GodotEngineEvidence, 18.1 s)

**On screen:** Recorded output lines · Three mutation cards turn red: exit 1 · What no headless run can show.

**Liam:** Every suite passes through the test wrapper at fixed frame rates. Then come three deliberate breaks: a missing semicolon, a renamed uniform, a deleted source colour. Each one made a test exit with status one, which proves the tests can fail. What they can't show is whether any of this looks right. A headless run draws nothing. That part takes eyes.

## B24 — Caught (GodotEngineEvidence, 20.0 s)

**On screen:** Card 1 · Card 2 · Card 3 · Card 4.

**Liam:** Not everything was right the first time. The Claude dot M D draft said the van updates every frame; it's every physics tick, fixed in review with the author's approval. Two agent-written tests were wrong until they failed. An audit caught the fog shader drifting from its brief, which the author settled with a dated revision. And the author stopped Claude from searching outside the project folder.

## B25 — Contributions (GodotEngineEvidence, 20.0 s)

**On screen:** Author column · Claude Code column · Sources card · Revision card.

**Liam:** Who did what. The author wrote the brief and its predictions, all three shaders, the annotations and the language notes, and played the build. Claude Code wrote the driver, the tests, the texture script, the materials and overlays, the captures, the audit and this film. The fog textures are original, generated by code; the Poly Haven pair is only used in a test. The revision shown is on screen.

## B26 — Verdict (ClaudeVerdictArtifact, 22.5 s)

**Liam:** Let's recap with Claude. Implemented: a dashboard shader driven by the headlights, and a textured fog shader shared by two materials. Verified: hand predictions matched the captures, and the tests failed when they should. Still open: why Compatibility showed no colour-space split, and how the fog layers with rain. Human judgement: whether it reads well at night. Next step: profile the fog on the MacBook Air M one this game targets.

## B27 — Handoff (ClaudeComposerAsk, 32.2 s)

**Liam:** Your turn. Paste this into Claude. Please use Walker to help me test one change to my night dashboard shader. I will add a clamp to night amount myself. Before I run anything, check my prediction for the dial hub pixel at night amount two point zero after the clamp, then run the capture script and show me predicted versus measured. One small change, a prediction you commit to first, and a capture that can prove you wrong. Judge Claude's answer on three things: it asks for your number before running anything, it shows the measured pixel, and it flags a mismatch instead of explaining it away. Liam, in for Bear.

## B28 — Outro (ClaudeTitleOutro, 3.9 s)

**Liam:** Blackridge, Shaded. At Nik Bear Brown.

Total narration clock: 9.4 minutes.
