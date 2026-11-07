# CHANGE-BRIEF.md: Particle effects (Assignment 6)

**Date:** 2026-11-07  
**Status:** Initial author design brief, prepared after Assignment 6 planning conversations and research, but before implementing the particle effects described here. This document does **not** claim that a Git commit, implementation, capture, or measurement has happened. Commit this initial prediction before effect implementation; later changes belong only in dated revisions.

**How it was made:** the author's draft. At the author's request, Claude Code corrected its Godot names, units and flags, and wrote in the decisions the author chose on 2026-11-07: both B effects graded, B1's condition and feature, rain that appears already falling, four realism fixes, A2 simulated with the van and firing at the hit. The textures are drawn by a script: the author first chose AI-generated ones, then asked for everything else to follow best practice, and Claude Code chose the script (#142). Values marked † are Claude Code's proposals from the author's descriptions and `docs/PARTICLE_RESEARCH.md`, for the author to check before committing (`docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #141).

The previous brief (Phase 1, the Phase 2 brief for Mission 2, and both versions of the save rules) moved unchanged to `docs/PHASE_BRIEF.md` on 2026-11-07. Assignment 5's brief is at tag `a5` (`git show a5:CHANGE-BRIEF.md`).

## 1. The effects

| ID | Effect | Job | Event or condition | Graded |
| --- | --- | --- | --- | --- |
| A1 | Wiper flick | One-shot | `wiper_swept` in `game/features/vehicles/freight_van/freight_van.gd:5`; emit at the **top turn** of each blade sweep, not at park | Yes |
| A2 | Roof spill on hard braking | One-shot | Rising edge of `braking` (`freight_van.gd:100`) while `actual_speed >= 8 m/s` and measured deceleration `>= 6 m/s²`, with enough time for roof water to replenish | Yes |
| B1 | Rain in every lamp's light | Ambience | The active camera within 65 m of a lamp, where the lamp's own light begins to fade (`distance_fade_begin`, `industrial_loop.gd:647`); lamps defined in `game/features/environments/industrial_loop/industrial_loop.gd` | Yes |
| B2 | Exhaust vapour | Feedback loop | `engine_on` in `freight_van.gd:27`; intensity follows the effective player or scripted throttle (`:89`, `:94`) | Yes |

**Grading decision:** all four are graded: A1 and A2 as Effect A, B1 and B2 as Effect B.

## 2. A1: Wiper flick

### The job

At the upper turning point, the wiper throws a few drops and fine mist off the glass. The player sees that the blades are physically moving water rather than merely wiping a texture. This must still be visible against an unlit road, although it should become faint when no light catches the droplets. The event is `wiper_swept` in `game/features/vehicles/freight_van/freight_van.gd:5` (emitted around lines 279–284). It has no position payload, so the effect finds the current blade-tip transform in the van presentation and emits **only at the top turn**. The park event is ignored for this effect.

### Intent

- **Timing phases:** 0.00–0.07 s: sharp bead release at the blade tip; 0.07–0.25 s: larger beads arc outward and down, with finer spray spreading; 0.25–0.65 s: big drops fall out of view; 0.65–1.20 s: only a few faint mist specks remain before fading.
- **Contrast:** Darkest: the unlit valley road beneath the night sky, where a few cool or reflected specks show without glowing unnaturally. Brightest: the depot under its amber lamps, where drops gain warm highlights but never become a solid white fan. The effect must work without a lamp.
- **Scale:** At 1280×800, the largest visible drops should be about 2–5 px, mist 1–2 px, and the whole flick roughly 0.15–0.35 m across near the blade tip. It stays small compared with the 0.65 m driver blade and 1.77 m windshield, and tiny compared with Ethan.
- **Change over life:** Beads start nearly clear with a bright edge, then become dimmer and more transparent. Mist starts faint and loses alpha steadily. Big beads keep nearly constant physical size before disappearing; mist expands about 1.4× while fading. Alpha keys (normalized life): BigDrops `0:0.75, 0.15:0.90, 0.55:0.40, 1:0`, FineSpray `0:0.35, 0.2:0.45, 0.65:0.15, 1:0`; size keys: BigDrops `0:0.75, 0.2:1.0, 1:1.0`, FineSpray `0:0.7, 0.5:1, 1:1.4`.
- **Variation:** Randomize velocity by the chosen ranges, direction within the cone, bead size ±25%, mist size ±35%, slight cool/warm tint ±5%, and billboard rotation 0–360°. Each top turn should look related but not identical.
- **Emitters:** `BigDrops` makes a short, readable arc of individual water beads. `FineSpray` creates a longer-lived, sparse mist at the same blade-tip position. Both belong to one reusable A1 effect root.

### Settings

Directions and boxes are in the van's frame (−x toward the driver's side, +y up, −z forward); each emitter is turned like the van when it fires†.

**BigDrops**

- **Node type:** `GPUParticles3D`; GPU rendering supports the planned particle material and allows future collision if needed. No CPU-only behavior is required.
- **Emission:** `amount = 22`; `one_shot = true`; `explosiveness = 1.0`; `lifetime = 0.65 s`; `emission_shape = EMISSION_SHAPE_SPHERE`, `emission_sphere_radius = 0.025 m`.
- **Process:** `ParticleProcessMaterial`; `initial_velocity_min = 1.2 m/s`, `initial_velocity_max = 2.8 m/s`; `direction = (-0.94, 0.09, -0.32)`†: toward the driver's side, a little up and forward, as the water leaves the glass's left edge; `spread = 28°`; `gravity = (0, -9.8, 0) m/s²`; `damping_min = 0.3`, `damping_max = 0.7`; `color = (0.78, 0.86, 0.91, 1)` with `alpha_curve` `0:0.75, 0.15:0.90, 0.55:0.40, 1:0`; `scale_min = 0.3`, `scale_max = 0.7` (multipliers of the 0.01 m quad: 3–7 mm drops), `scale_curve = 0:0.75, 0.2:1, 1:1.0`.
- **Draw:** Tiny soft water-bead RGBA texture, created for this effect in `game/effects/textures/water_bead.png`; `StandardMaterial3D`, `TRANSPARENCY_ALPHA`, `BLEND_MODE_MIX`, `shading_mode = SHADING_MODE_PER_PIXEL` so scene lighting affects it, `BILLBOARD_PARTICLES`, `vertex_color_use_as_albedo = true`; `QuadMesh` of size `(0.01, 0.01)` m. Avoid additive glowing drops.
- **`local_coords = false`:** After emission, droplets stay in world space rather than following the van. `inherit_velocity_ratio = 0`†: each burst root stays where it fired, so at speed the drops start at rest in the world and rush back faster than real drops for the first few tenths of a second (research §3); a strip at speed checks the look.
- **`visibility_aabb`:** `AABB(position (-2.0, -2.0, -1.5), size (3, 3, 3))`† in the burst root's frame: a 3 m box around the launch point, shifted toward the driver's side and down, where the drops go. Set by hand, then checked in the editor with the wipers running and the van moving.
- **`preprocess = 0 s`:** Nothing should be visible before the first sweep.

**FineSpray**

- **Node type:** `GPUParticles3D`.
- **Emission:** `amount = 36`; `one_shot = true`; `explosiveness = 0.9`; `lifetime = 1.20 s`; `emission_shape = EMISSION_SHAPE_SPHERE`, radius `0.035 m`.
- **Process:** `initial_velocity_min = 0.35 m/s`, `initial_velocity_max = 1.1 m/s`; `direction = (-0.94, 0.09, -0.32)`† (as BigDrops); `spread = 48°`; `gravity = (0, -1.0, 0) m/s²` (stylized effective settling for tiny droplets); `damping_min = 0.8`, `damping_max = 1.6`; `color = (0.82, 0.87, 0.91, 1)`† (pale grey-blue) with `alpha_curve` `0:0.35, 0.2:0.45, 0.65:0.15, 1:0`; `scale_min = 0.15`, `scale_max = 0.3` (multipliers of the 0.01 m quad: 1.5–3 mm); `scale_curve` `0:0.7, 0.5:1, 1:1.4`.
- **Draw:** Soft circular mist texture `game/effects/textures/fine_spray.png`; `StandardMaterial3D`, `TRANSPARENCY_ALPHA`, `BLEND_MODE_MIX`, `BILLBOARD_PARTICLES`, `vertex_color_use_as_albedo = true`, `shading_mode = SHADING_MODE_PER_PIXEL` (scene-lit); `QuadMesh` of size `(0.01, 0.01)` m.
- **`local_coords = false`**, `inherit_velocity_ratio = 0`† (as BigDrops); **`visibility_aabb`** `AABB(position (-2.0, -2.0, -1.5), size (3, 3, 3))`†, checked the same way; **`preprocess = 0 s`**.

### Rules a test can measure

- **Fires:** A burst starts at the current upper blade-tip position when `wiper_swept` reports a top turn and the wipers are running. It does not fire on scene load, when wipers are off, or at the parked end of the stroke. If the event lacks an explicit phase, the presentation checks the current wiper angle to distinguish top from park.
- **Retrigger rule:** **Overlap**, using a pool of two burst instances. The next top turn arrives about every 0.91 s on fast mode; the 1.20 s spray can still be alive. At most **two** A1 bursts coexist. If a third request ever arrives while both are active, reuse only a completed instance; otherwise log a missed burst instead of silently cutting off a live one.
- **If the followed node is freed:** Disconnect the signal and stop accepting events. Already emitted world-space particles can finish in a short-lived independent effect root; free that root after the longest lifetime. Never dereference a freed blade or van.

### Evidence

- **Headless test:** With the wipers switched on by the real `wipers` key, never a direct call to the trigger†, count top-turn events, accepted burst spawns, pool size and initial spawn transforms; assert zero spawns at load/off/park and no more than two active bursts. Simulate a freed parent and check for no errors or further spawns.
- **Frame strip:** Check whether the visible beads start at the blade tip, separate from the glass, and fade in the predicted order.
- **Eyes in the game:** Compare unlit valley road with the bright depot; check that the flick is visible but not glowing, including through the windshield and while the van moves.

### Frame strip

- **Background:** Actual valley-road stretch of the industrial loop, with a second visual check near the depot lamps; 1280×800, 30 fps. Trigger at frame 10.
- **Frame 10 (0.00 s):** A compact bead cluster just leaves the blade tip; no earlier spray.
- **Frame 12 (0.07 s):** Several clear beads move sideways; a small spray halo appears.
- **Frame 15 (0.17 s):** The arc is widest and easy to read; mist follows behind.
- **Frame 20 (0.33 s):** Larger beads are falling; the fine spray is thinning.
- **Frame 30 (0.67 s):** Most large drops are gone; only faint mist remains.
- **Frame 50 (1.33 s):** Original burst is completely gone. A new burst may be visible if fast wipers have produced another top turn; for this isolated preview, disable the automatic retrigger to inspect only the first burst.
- **Retrigger (preview's retrigger on):** a second top turn fires at **frame 37** (0.91 s, fast wipers)†. Frames 37–50 show two bursts at once, the new arc beside the fading mist of the first, and neither is cut short (overlap).

## 3. A2: Roof spill on hard braking

### The job

When Ethan brakes sharply, accumulated rainwater surges off the front roof edge and briefly crosses the windshield. This makes the van's mass, rain and braking feel connected, while momentarily affecting visibility without obscuring the whole view. The source is `braking` (`game/features/vehicles/freight_van/freight_van.gd:100`) and the change in `actual_speed` (`:123`). **Hard braking** means a new brake event while speed is at least `8 m/s` (28.8 km/h) and measured deceleration is at least `6 m/s²` for two physics ticks; ignore wheel-locked slowdowns around `1.5 m/s²`. This is a new presentation-only detection rule, not a change to the van's brake physics. Ethan's scripted hard brake straight after the hit counts too, so the spill pours over the glass as the man lands on the bonnet (the author's choice, 2026-11-07).

### Intent

- **Timing phases:** 0.00–0.12 s: water gathers at the roof lip; 0.12–0.35 s: short broken sheet spills forward; 0.35–0.80 s: the sheet separates into narrow streams and beads; 0.80–1.30 s: remaining drops fall and fade.
- **Contrast:** Darkest: unlit valley road, where water is translucent with occasional dim edges. Brightest: office floodlight/depot lamps, where streams pick up highlights but the windshield and road remain visible.
- **Scale:** The main spill spans about 0.7–1.0 m across the roof's front edge, less than the 1.77 m windshield width. Individual drops are about 2–6 px at 1280×800. It should feel broad compared with the wiper flick, but not like a waterfall covering Ethan's entire view.
- **Change over life:** Start as a narrow, mostly transparent sheet; separate into smaller drops, becoming less opaque and slightly thinner. Alpha keys `0:0.1, 0.12:0.6, 0.5:0.4, 1:0`; scale keys `0:1, 0.5:0.8, 1:0.4`.
- **Variation:** Randomize width/position along the roof lip, launch velocity ±20%, droplet size ±30%, angle ±12°, and small hue/alpha variation. Do not randomize the spill into an implausible sideways jet.
- **Emitters:** `RoofStreams` produces sparse elongated streaks at the roof lip. `RoofBeads` produces separated droplets that fall ahead of the glass. Both are attached to the front roof-edge spawn transform only at trigger time.

### Settings

**RoofStreams**

- **Node type:** `GPUParticles3D`; suitable for transparent 3D streaks, with independent world-space motion.
- **Emission:** `amount = 32`; `one_shot = true`; `explosiveness = 0.8`; `lifetime = 0.85 s`; `emission_shape = EMISSION_SHAPE_BOX`; `emission_box_extents = (0.48, 0.015, 0.025) m` along the roof lip.
- **Process:** `initial_velocity_min = 0.5 m/s`, `initial_velocity_max = 1.4 m/s`; `direction = (0, -0.70, -0.71)`†, down and forward along the windshield; `spread = 12°`; `gravity = (0, -9.30, -9.51) m/s²`† in the van's frame: the 13.3 m/s² of gravity plus the 9 m/s² braking push, laid along the glass so the water slides down it instead of sinking through it (the true sum points 3° into the glass; research §4). Off the bottom of the glass the water passes under the bonnet and is hidden. Step 6's generated shader shows how Godot applies gravity with local coordinates; `damping_min = 0.1`, `damping_max = 0.4`; `color = (0.82, 0.86, 0.88, 1)`† (pale neutral water) with `alpha_curve` `0:0.1, 0.12:0.6, 0.5:0.4, 1:0`; `scale_min = 1.2`, `scale_max = 2.8` (multipliers of the 0.01 m quad: 12–28 mm), `scale_curve` `0:1, 0.5:0.8, 1:0.4`.
- **Draw:** Elongated semi-transparent streak texture `game/effects/textures/roof_stream.png`; `StandardMaterial3D`, `TRANSPARENCY_ALPHA`, `BLEND_MODE_MIX`, `billboard_mode = BILLBOARD_DISABLED`, because the node's `transform_align = TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY`† faces each streak to the camera with its long side along its motion (the build confirms this in 4.7.2), `vertex_color_use_as_albedo = true`, `shading_mode = SHADING_MODE_PER_PIXEL` (scene-lit); `QuadMesh` of size `(0.01, 0.01)` m; no additive blending.
- **`local_coords = true`** (the author's choice, 2026-11-07): water on the roof and glass moves with the van, so the spill is simulated in the van's frame, with the braking push in its gravity. In world space it would not keep the van's speed and would be left behind at 30–60 km/h.
- **`visibility_aabb`:** `AABB(position (-2, -3, -3), size (4, 4, 4))`† in the van's frame around the roof lip, reaching down the windshield and over the bonnet; set by hand, then checked against the real trajectory in the editor.
- **`preprocess = 0 s`.**

**RoofBeads**

- **Node type:** `GPUParticles3D`.
- **Emission:** `amount = 48`; `one_shot = true`; `explosiveness = 0.65`; `lifetime = 1.30 s`; `emission_shape = EMISSION_SHAPE_BOX`, extents `(0.48, 0.02, 0.03) m`.
- **Process:** `initial_velocity_min = 0.4 m/s`, `initial_velocity_max = 1.6 m/s`; `direction = (0, -0.70, -0.71)`†; `spread = 24°`; `gravity = (0, -9.30, -9.51) m/s²`† (as RoofStreams); `damping_min = 0.1`, `damping_max = 0.6`; `color = (0.78, 0.86, 0.91, 1)`† (the same water as A1's beads); `alpha_curve` `0:0.5, 0.2:0.8, 0.7:0.3, 1:0`; `scale_min = 0.3`, `scale_max = 0.9` (multipliers of the 0.01 m quad: 3–9 mm); `scale_curve` `0:1, 0.6:0.85, 1:0.5`.
- **Draw:** Water-bead texture `game/effects/textures/water_bead.png`; `StandardMaterial3D`, `TRANSPARENCY_ALPHA`, `BLEND_MODE_MIX`, `BILLBOARD_PARTICLES`, `vertex_color_use_as_albedo = true`, `shading_mode = SHADING_MODE_PER_PIXEL` (scene-lit); `QuadMesh` of size `(0.01, 0.01)` m.
- **`local_coords = true`** (as RoofStreams); **`visibility_aabb`** `AABB(position (-2, -3, -3), size (4, 4, 4))`†, checked the same way; **`preprocess = 0 s`**.

### Rules a test can measure

- **Fires:** One burst on a qualifying **new** hard-brake event, from the front roof lip. Never on load, at rest, on gentle deceleration, or while the brake remains held. Require `roof_water_ready = true` and a 20 s recharge after a spill, approximating the time needed for more rain to accumulate. This flag belongs only to the visual effect.
- **Retrigger rule:** **Ignore** a second hard-brake event while a burst is alive or while the 20 s recharge is running. At most **one** A2 burst is alive.
- **If the followed node is freed:** No new spawn. The detached, world-space spill completes its lifetime and is then freed safely; clear references to the van.

### Evidence

- **Headless test:** Drive the real van with real throttle and brake input, never faked speeds or a direct call to the trigger†; assert no burst below either threshold, exactly one qualifying burst, none from a held brake, and no second burst during the recharge. Free the van and verify no errors.
- **Frame strip:** Confirm that the roof lip is the origin, streams lead the beads, and the whole spill disappears within 1.30 s.
- **Eyes in the game:** Check under the office floodlight and on the unlit valley road; verify the spill does not turn into a solid opaque curtain or clip implausibly through the windshield.

### Frame strip

- **Background:** Actual approach to the site-office parking area, with the floodlight and wet windshield visible; also compare the valley road at night. Trigger at frame 10.
- **Frame 10 (0.00 s):** First thin water ridge begins at the front roof lip.
- **Frame 12 (0.07 s):** Short translucent streams begin to tip over the edge.
- **Frame 15 (0.17 s):** The broken sheet is most visible, still showing the road through it.
- **Frame 20 (0.33 s):** Streams separate into droplets and run down/forward.
- **Frame 30 (0.67 s):** Sheet is gone; scattered falling beads remain.
- **Frame 50 (1.33 s):** No A2 particles remain; recharge is still active.
- **Retrigger (preview's retrigger on):** a second hard brake comes at **frame 25** (0.5 s)†, inside the first burst's life: nothing new appears (ignore), and the first spill plays on unchanged.

## 4. B1: Rain in every lamp's light

### The job

- **What it tells the player:** Rain is physically present in the world, not just painted onto the van's windshield. Seeing droplets enter and leave warm pools of light helps the player read distance, weather and road surfaces.
- **Which job:** **Ambience**, continuously active in lit outdoor areas during rain.
- **The script and variable:** the lamps are defined in `game/features/environments/industrial_loop/industrial_loop.gd` (posts `:632–653`, site-office lights `:592–619`). The condition is the distance from the active camera to each lamp: its rain runs while that distance is under 65 m, where the lamp's own light begins to fade (`distance_fade_begin = 65.0`, `:647`). It always rains in this game, so there is no weather switch: driving or walking toward a lamp starts its rain, and leaving stops it (the author's choice, 2026-11-07).
- **Feature neither A effect uses:** **collision with splashes** (the author's choice, 2026-11-07). Drops collide with a `GPUParticlesCollisionHeightField3D` over each lamp's volume, so they stop at the ground and on roofs, and none fall under the office's door hood or eaves; each landing spawns a small splash through a sub-emitter (`sub_emitter_mode = SUB_EMITTER_AT_COLLISION`). Neither A effect uses a collider or a sub-emitter.

### Intent

- **Timing phases:** On condition start the rain is already falling at full density (preprocess; the author's choice, 2026-11-07), so it is steady from the first frame; when the condition ends, emission stops immediately and the last drops land within 1.1 s†.
- **Contrast:** Darkest: between valley road lamps, where most rain disappears into darkness. Brightest: directly below the depot posts and the office floodlight, where warm backlit streaks are readable without becoming dense white lines. Rain under the office hood/eaves must be absent.
- **Scale:** At 1280×800, most streaks appear 1–2 px wide and about 10–30 px long depending on distance. Each volume is several metres wide, much larger than Ethan or the van, but individual drops stay small.
- **Change over life:** Streaks begin faint at the top, brighten when within the light volume, then fade toward the bottom. Alpha keys `0:0.1, 0.15:0.45, 0.75:0.45, 1:0`; size keys `0:0.9, 0.5:1, 1:0.9`. Lighting, rather than a fake glow, determines most visible brightness.
- **Variation:** Drop speed 6.5–8.5 m/s, width ±25%, streak length ±30%, slight direction variation ±4°, and randomized starting positions in the volume.
- **Emitters:** One `LampRain` emitter per active post or floodlight volume, sharing a common scene/resource. The post version covers a vertical lit cylinder approximated by a box; the floodlight version uses a narrower box. `LampSplash`† is its sub-emitter: a small crown of droplets where each drop lands. Drops stop on the office's door hood and eaves through the collider instead of falling under them.

### Settings

- **Node type:** `GPUParticles3D`; it supports the GPU collision and sub-emitter this effect uses†, and efficiently draws repeated lit volumes. A single shared material is reused.
- **Emission:** `amount = 160` **per active lamp volume**; `one_shot = false`; `explosiveness = 0`; `lifetime = 1.1 s`† (long enough to fall from just below a post's lamp head, 6.4 m up, to the ground at 6.5 m/s; collision ends each drop there); `emission_shape = EMISSION_SHAPE_BOX`; post volumes `emission_box_extents = (3.0, 0.2, 3.0) m`, centred 6.4 m up† under the lamp head, which is shielded, so no rain is lit above it. The site-office volumes are fitted to their lights†: the floodlight's box `(3.5, 0.1, 6.5) m` along its beam, 4 m up, turned to the beam's heading with its slant turned back to match; the door lamp's box `(1.0, 0.1, 0.8) m`, 0.8 m in front of the wall, 3 m up.
- **Process:** `initial_velocity_min = 6.5 m/s`, `initial_velocity_max = 8.5 m/s`; `direction = (0.08, -0.997, 0)`†, the beam rain's 4.6° wind slant (`RAIN_SLANT`), fixed in the world toward +x whichever way the van faces (each emitter is world-aligned, not turned with its post); `spread = 4°`; `gravity = (0, -0.5, 0) m/s²` (terminal-speed approximation); `damping_min = 0`, `damping_max = 0.15`; `color = (0.88, 0.89, 0.90, 1)`† (neutral grey-white), `alpha_curve` `0:0.1, 0.15:0.45, 0.75:0.45, 1:0`; `scale_min = 0.7`, `scale_max = 1.35`† (multipliers of the 0.01 × 0.25 m quad: streaks 17–34 cm long and 7–14 mm wide, as long as the beam rain's, to reach the intended 10–30 px); `scale_curve` `0:0.9, 0.5:1, 1:0.9`; `collision_mode = COLLISION_HIDE_ON_CONTACT`†, with the node's `collision_base_size = 0.01`†; `sub_emitter_mode = SUB_EMITTER_AT_COLLISION`†, `sub_emitter_amount_at_collision = 4`†. The initial downward speed, not gravity, does most of the motion.
- **Draw:** Thin streak RGBA texture `game/effects/textures/rain_streak.png`; `StandardMaterial3D`, `TRANSPARENCY_ALPHA`, `BLEND_MODE_MIX`, `vertex_color_use_as_albedo = true`, `shading_mode = SHADING_MODE_PER_PIXEL` (scene-lit), `backlight_enabled = true` and `backlight = (0.8, 0.8, 0.8)`† so a drop is brightest with the lamp behind it, as real rain is; `QuadMesh` of size `(0.01, 0.25)` m†. Streaks turn along their motion†: the node's `transform_align = TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY` faces each quad to the camera with its long side along the motion, so the material's `billboard_mode = BILLBOARD_DISABLED` (the build confirms this in 4.7.2 and records any change as a dated revision). Do not use an additive beam that looks luminous without a lamp.
- **`local_coords = false`:** Drops remain at world positions and do not turn or slide with the moving van.
- **`visibility_aabb`:** posts `AABB(position (-4, -8.5, -4), size (8, 10, 8))`† from the emitter 6.4 m up, covering the whole fall path to the ground; the floodlight `AABB(position (-4.5, -5, -7.5), size (9, 6, 15))`† and the door lamp `AABB(position (-1.5, -3.5, -1.5), size (3, 4, 3))`†, each set by hand and checked in the editor.
- **`preprocess = 1.1 s`**†, one full lifetime, so the whole fall path is already filled when a lamp's rain starts, at scene load or on activation.

**LampSplash** (sub-emitter of `LampRain`)†

- **Node type:** `GPUParticles3D`, set as `LampRain`'s `sub_emitter`; `emitting = false`, because `LampRain`'s collisions drive it.
- **Emission:** `amount = 160` (about 145 landings a second per lamp × 4 droplets × 0.25 s); `one_shot = false`; `explosiveness = 0`; `lifetime = 0.25 s`; `emission_shape = EMISSION_SHAPE_POINT`.
- **Process:** `initial_velocity_min = 0.6 m/s`, `initial_velocity_max = 1.6 m/s` (droplets rise 2–13 cm); `direction = (0, 1, 0)`; `spread = 60°`; `gravity = (0, -9.8, 0) m/s²`; `color = (0.88, 0.89, 0.90, 1)`; `alpha_curve` `0:0.6, 1:0`; `scale_min = 0.1`, `scale_max = 0.3` (1–3 mm on the 0.01 m quad).
- **Draw:** `water_bead.png`, in the same material as `LampRain` but with `billboard_mode = BILLBOARD_PARTICLES`; `QuadMesh` of size `(0.01, 0.01)` m.
- **`local_coords = false`**; **`visibility_aabb`** as `LampRain`'s; **`preprocess = 0 s`**.

**The collider**†

- One `GPUParticlesCollisionHeightField3D` per active lamp volume, sized like its `visibility_aabb` (posts `size = (8, 10, 8)` m); `resolution = RESOLUTION_256`; `update_mode = UPDATE_MODE_ALWAYS`, because the van drives under the lamps; `follow_camera_enabled = false`.

### Rules a test can measure

- **Starts/stops:** A lamp's rain starts when the active camera comes within 65 m of the lamp, and stops when it goes beyond; the last drops land within 1.1 s†. Every lamp in the scene is covered: the depot and valley-road posts, the lumber-yard post, and the office floodlight and door lamp.
- **While the tree is paused:** Use inherited pausable processing. Title screen and pause menu freeze the simulation in place; unpause resumes it without a sudden restart.
- **While hidden:** Set `emitting = false` and hide the emitter when its lamp volume is culled or the effect is explicitly disabled. Clear stale particles before reactivation, and restart the emitter so its 1.1 s preprocess† fills the volume before it is seen (the build checks how Godot re-runs preprocess). Hiding is an optimization, not a weather-state change.

### Evidence

- **Headless test:** Drive or walk toward a lamp with real input and assert that its rain starts within 65 m and stops beyond†; assert emitter creation for each expected lamp, pause behaviour and the hidden-state policy. The configuration test reads the collision and splash settings†.
- **Frame strip:** Confirm the volume fills promptly, holds steady, and empties after stop; compare actual post and office floodlight views.
- **Eyes in the game:** Check darkness between lamps, amber backlighting, consistent world-space slant while the van turns, and no visible drops under the office hood/eaves.

### Frame strip

- **Background:** Valley-road lamp at the actual `(−15, 63.8)` lamp location, with a second check at the site-office door hood. Condition starts at frame 10 and ends at **frame 70** (2.0 s later).
- **Frame 10:** The camera comes within range; the lamp's rain is already falling at full density, top to ground†.
- **Frame 12 (0.07 s):** The same density, with splashes on the lit ground†.
- **Frame 20 (0.33 s):** Steady backlit streaks along their motion, splashes below†.
- **Frame 30 (0.67 s):** Stable rain density under the lamp.
- **Frame 50 (1.33 s):** Steady backlit streaks with no repeating pattern.
- **Frame 70 (2.00 s):** Condition ends; no new drops spawn.
- **Frame 85 (2.50 s):** Only the last falling streaks remain.
- **Frame 110 (3.33 s):** Volume is empty and stays empty†.

## 5. B2: Exhaust vapour

### The job

- **What it tells the player:** The diesel engine is running and responding to throttle in cold rain. At idle the vapour is gentle; when the player accelerates, the plume grows and is carried into the van's wake. It is visible in tail glow, reversing lights and depot/office lighting.
- **Which job:** **Feedback loop** linked to engine state and throttle.
- **The script and variable:** `engine_on` in `game/features/vehicles/freight_van/freight_van.gd:27`, `engine_started` at `:8`, and the effective strength of `accelerate` (`:89`) or `scripted_throttle` (`:94`). The presentation reads the effective throttle without changing the engine model.
- **Feature neither A effect uses:** **Value-driven `amount_ratio`**, with optional `ParticleProcessMaterial.turbulence_enabled` to curl the plume. `CPUParticles3D` does not have `amount_ratio`, so this is a GPU effect.

### Intent

- **Timing phases:** After ignition, wait 0.4 s and ramp the plume up over 0.6 s; steady idle produces a small translucent trail. On throttle increase, density responds smoothly over 0.5–0.8 s. After engine off, emission stops immediately; existing vapour drifts and fades within 2.5 s.
- **Contrast:** Darkest: rear of the van on the unlit valley road, where only a faint silhouette is visible. Brightest: site-office floodlight and white reverse lamps, where the plume is pale but translucent; in red tail glow it should look subtly warm/red rather than self-illuminated.
- **Scale:** From the rear tailpipe, the plume starts about 0.10–0.20 m wide and expands to roughly 0.5–0.8 m over 1–2 m behind the van. At 1280×800 it should not conceal the rear doors or Ethan when on foot.
- **Change over life:** Begin as a narrow, faint whitish puff, grow about 2.5×, curl, and fade. Alpha keys `0:0.1, 0.15:0.28, 0.5:0.18, 1:0`; size keys `0:0.4, 0.5:1.4, 1:2.5`.
- **Variation:** Randomize speed ±25%, direction ±10°, puff scale ±30%, rotation 0–360°, and turbulence phase/strength. No black smoke or thick opaque clouds.
- **Emitters:** One `ExhaustPlume` emitter at the **actual tailpipe location found on the Iveco model during setup**. The research does not provide its coordinates; do not invent them. Use one emitter for the actual outlet unless the model proves it has two.

### Settings

- **Node type:** `GPUParticles3D`, because the throttle maps to `amount_ratio` and turbulence is available.
- **Emission:** `amount = 96`; `one_shot = false`; `explosiveness = 0`; `lifetime = 2.5 s`; `emission_shape = EMISSION_SHAPE_SPHERE`; `emission_sphere_radius = 0.06 m`.
- **Process:** `initial_velocity_min = 1.0 m/s`, `initial_velocity_max = 2.2 m/s` as a visually stable effective puff velocity after leaving the pipe; `direction = (0, -0.26, 0.97)`† in the van's frame: backward and 15° down, as a tailpipe points; `spread = 18°`; `gravity = (0, 0.5, 0) m/s²` for warm rise; `damping_min = 0.8`, `damping_max = 1.4`; `turbulence_enabled = true`, `turbulence_noise_strength = 0.15`, `turbulence_noise_scale = 1.2`, `turbulence_noise_speed = (0.2, 0.1, 0.2)` (initial estimates); `color = (0.90, 0.91, 0.92, 1)`† (pale grey-white), `alpha_curve` `0:0.1, 0.15:0.28, 0.5:0.18, 1:0`; `scale_min = 1.2`, `scale_max = 2.2` (multipliers of the 0.1 m quad: 12–22 cm), `scale_curve` `0:0.4, 0.5:1.4, 1:2.5`. These velocities represent the visible condensed plume, not raw exhaust-gas speed at the pipe.
- **Draw:** Soft cloud RGBA texture `game/effects/textures/exhaust_puff.png`; `StandardMaterial3D`, `TRANSPARENCY_ALPHA`, `BLEND_MODE_MIX`, `BILLBOARD_PARTICLES`, `vertex_color_use_as_albedo = true`, `shading_mode = SHADING_MODE_PER_PIXEL` (scene-lit), low opacity, depth testing on; `QuadMesh` of size `(0.1, 0.1)` m. Put the emitter on render layer 1 (`layers = 1`), the only layer the tail glow and reversing lamps light.
- **`local_coords = false`:** Old vapour remains in the world as the van moves away; the new particles start at the moving tailpipe.
- **`visibility_aabb`:** `AABB(position (-3, -1, -11), size (6, 5, 60))`† in the van's frame from the tailpipe: 49 m behind and 11 m ahead, because the emitter rides with the van while its vapour stays in the world (19 m/s top speed × 2.5 s ≈ 48 m; less when reversing); checked in the editor while driving and reversing.
- **`preprocess = 0 s`:** The plume should not appear fully formed on scene load before the engine starts. For a scene that explicitly loads with the engine already running, build it naturally using the startup ramp instead of pre-filling.

### Rules a test can measure

- **Starts/stops:** Starts after `engine_on` becomes true, with a 0.4 s delay and 0.6 s ramp. Stops emission immediately when `engine_on` becomes false; existing particles finish their lifetime. No exhaust with the engine off.
- **While the tree is paused:** Freeze particles and the throttle-smoothing timer during title-screen or pause-menu pause. Resume from the same state, not from a new ignition.
- **While hidden:** Set `emitting = false` and hide when culled/disabled; when visible again with the engine running, restart the smooth ramp. Do not alter throttle or engine state.
- **Throttle range and mapping:** Effective throttle `t` is clamped to **0.0–1.0**. Target `amount_ratio = 0.15 + 0.65 × t` when the engine is running, giving **0.15 at idle** and **0.80 at full throttle**; smooth toward target over approximately 0.6 s. During startup, multiply by a ramp from 0 to 1; with the engine off, set `amount_ratio = 0` and `emitting = false`. Keep `amount = 96` fixed at all times. This is a visibility-oriented response curve, not a measured engine-flow equation.

### Evidence

- **Headless test:** Assert engine-off emits none, idle target is 0.15, full throttle target is 0.80, values stay in [0,1], and `amount` never changes. Check pause and hidden rules and safe parent deletion.
- **Frame strip:** Confirm gradual startup, visible idle plume, higher density with throttle, and a natural fade after switch-off.
- **Eyes in the game:** Check actual tailpipe placement, rear view/reverse camera, red tail glow, white reverse lamps and office floodlight; verify vapour is not thick smoke and does not move rigidly with the van.

### Frame strip

- **Background:** Actual van rear at the site-office parking place, with the office floodlight; also inspect the reverse camera. Engine condition starts at frame 10 and ends at **frame 100** (3.0 s later). Throttle is 0 until frame 40, then 1.0 from frames 40–80, then 0.
- **Frame 10:** Engine starts; no instant full plume.
- **Frame 20 (0.33 s):** Startup delay still suppresses emission.
- **Frame 30 (0.67 s):** Thin idle vapour begins to appear.
- **Frame 40 (1.00 s):** Idle plume established; full-throttle command begins.
- **Frame 55 (1.50 s):** Denser plume trails behind as throttle response rises.
- **Frame 80 (2.33 s):** Throttle returns to zero; density begins falling toward idle.
- **Frame 100 (3.00 s):** Engine switches off; new emission stops.
- **Frame 130 (4.00 s):** Residual vapour has expanded and become faint.
- **Frame 180 (5.67 s):** All residual vapour has expired.

## 6. Boundaries

- Do **not** change van collision shapes, rigid-body/vehicle movement, acceleration, braking strength, grip, or any other driving physics.
- Do **not** change input mappings or the meaning of the brake, wiper, ignition, accelerate or handbrake actions.
- Do **not** change mission state-machine transitions, timers, scripted driving, save rules, or existing test expectations.
- Do **not** edit the Assignment 5 shaders in `game/shaders/` (`night_cluster`, `foggy_windshield`, `hint_experiment`). The particle effect may read current transforms and state but must not write gameplay state.
- Do **not** modify other environment objects, lamp behavior, camera logic or weather mechanics just to make particles visible. A presentation-only controller may create particle nodes beside existing objects and read their state.
- Put new effect resources under `game/effects/`, preview scenes under `game/previews/`, and tests under `game/tests/`. Keep preview fixtures out of shipping exports by updating export exclusions when necessary. The author, not an agent, creates `game/shaders/particles_generated.gdshader` in the editor.
- **Textures:** the five textures (`water_bead`, `fine_spray`, `roof_stream`, `rain_streak`, `exhaust_puff`) are drawn by a script committed beside them (`tools/make_particle_textures.py`), so they are exact, rebuild identically and need no licence; the script is their provenance record, and `SOURCES.md` points to it (#142).
- No effect may obscure the road for long, change gameplay difficulty, or reveal BLACKRIDGE story information.

## 7. Predicted failures

| # | Failure | The check that would catch it |
| --- | --- | --- |
| 1 | Old Godot 3 property names or incorrect 3D material settings cause errors or invisible particles | Headless configuration/property readback test in Godot 4.7.2, followed by a windowed preview |
| 2 | Wiper top-turn event gets confused with the park event; flick fires twice per cycle or on load | Headless event-count test across off, slow and fast modes |
| 3 | A second A1 burst interrupts the first, or pool grows without limit | Headless rapid-trigger test; verify at most two live bursts and frame-strip overlap |
| 4 | Roof spill fires on every held-brake tick or before roof water has refilled | Headless threshold, rising-edge and 20 s recharge tests |
| 5 | Small transparent particles disappear behind the windshield or are blurred by MetalFX at 75% | Windowed 1280×800 frame strips from driver view; compare depot and valley road |
| 6 | `visibility_aabb` is too small, making particles pop off as the van moves | Windowed preview with camera/van movement and editor AABB inspection |
| 7 | Rain appears under the site-office hood or rotates with the van | Windowed frame strip at the office and while turning the van |
| 8 | Lamp rain or exhaust continues moving while paused, or pops when hidden and shown | Headless pause/visibility state tests plus windowed pause-menu check |
| 9 | Exhaust is unlit because its render layer does not match tail/reverse lamps | Windowed reverse-camera, brake-light and floodlight comparisons |
| 10 | GPU effects appear cheap in headless tests while real rendering exceeds the frame budget | Windowed warm-Mac frame-time capture and visual comparison; do not trust headless GPU timing |

## 8. Price predictions and budgets

These are **predictions, not measurements**. The latest research baseline is **13.25 ms/frame** on battery (roughly 75.5 FPS) at the start with mirrors; 60 FPS allows **16.7 ms/frame**, leaving about **3.45 ms** before the 60 FPS limit in an average starting frame. Warm-Mac slow frames already reach 17–19 ms, so effects should be much cheaper than that remaining average margin. All four designs use `GPUParticles3D`. GPU-time values below are target estimates to validate with a windowed run; Godot's GPU timer may report zero on Metal.

| Effect | Peak particles | Headless CPU (predicted) | GPU time (predicted) | Budget | Compared on |
| --- | ---: | ---: | ---: | --- | --- |
| A1 | **116** = (22 + 36) × 2 overlapping bursts | 0.03 ms | 0.12 ms | GPU ≤ 0.25 ms | GPU time |
| A2 | **80** = (32 + 48) × 1 burst | 0.02 ms | 0.10 ms | GPU ≤ 0.20 ms | GPU time |
| B1 | **320 per lamp** (160 drops + 160 splash droplets)†; plan for **2,560** at 8 simultaneously active lamp volumes | 0.06 ms | 0.40 ms | GPU ≤ 0.70 ms for 8 volumes | GPU time |
| B2 | **96** = 96 × 1 continuous emitter | 0.02 ms | 0.18 ms | GPU ≤ 0.30 ms | GPU time |
| **Total predicted maximum** | **2,852**† | **0.13 ms** | **0.80 ms** | **Combined GPU ≤ 1.45 ms** | Windowed GPU/render impact |

The B1 **eight-lamp simultaneous limit is a planned visibility/culling cap**, not a count of all lamps in the level. Each B effect's peak is its full `amount`, not `amount_ratio × amount`; `amount_ratio` controls active emission density but does not change the allocated maximum. A1 peak assumes two pooled copies of each of its two emitters; A2 peak assumes one copy of each emitter. GPU work also has CPU submission overhead, so the headless figures are only rough scripting overhead estimates and do not measure actual rendered particle cost. A windowed performance run must confirm or reject these budgets.

## 9. Questions

**1. Which node type does each effect use, and which features in your brief does it lack?**  
All four use `GPUParticles3D`. None of the planned GPU features is missing from that node type in the research's Godot 4.7.2 list. `CPUParticles3D` would not support `amount_ratio`, GPU collision, sub-emitters, trails, turbulence or attractors; B2 specifically needs `amount_ratio` and turbulence, so CPU particles would not meet its design.

**2. With `local_coords` as you set it, what does each A effect do if its parent moves after the event?**  
A1 uses `local_coords = false`: once emitted, its water stays in world space and follows its own velocity and gravity rather than being dragged along when the van or wiper moves; only new particles use the latest spawn position. A2 uses `local_coords = true`: its water is simulated in the van's frame, so it moves with the van while it pours over the glass, with the braking push in its gravity†.

**3. Under your retrigger rule, how many bursts of each A effect can be alive at once? What peak particle count does that give?**  
A1 overlaps, with a two-burst pool: the 1.20 s fine spray outlives the 0.91 s fast-wiper top-turn interval, but not two such intervals. Its peak is `2 × (22 + 36) = 116` particles. A2 ignores retriggers until its burst finishes and roof water recharges, so only one burst exists: `32 + 48 = 80` particles.

**4. What will a headless run report as the cost of a GPU effect, and why? With vsync on, what would FPS read with the effect off and with it on?**  
A headless run draws no particles, so it measures only small CPU-side setup/control work and cannot establish GPU rendering cost. With vsync on a 60 Hz display, both off and on can show about **60 FPS** while both fit within 16.7 ms; only a missed frame or frame-time measurement exposes the slowdown. On this Mac, the GPU timer may show zero under Metal, so use windowed frame-time captures as well.

**5. What does each B effect show on the first frame after its scene loads, with preprocess and without it? While the tree is paused? While the node is hidden?**  
B1 uses `preprocess = 1.1 s`†, one full lifetime, so when its condition is already true it looks fully populated on the first visible frame; without preprocess it would fill gradually from an initially empty volume. B2 uses `preprocess = 0 s`, so it begins empty and builds after the engine-start delay; adding preprocess would incorrectly create an instant plume. Both freeze while the scene tree is paused. When explicitly hidden or culled, both stop emission; when shown again, B1 repopulates and B2 ramps back in, rather than showing stale particles.

**6. Which settings in your brief belong to emission, which to process, and which to draw?**  
**Emission** decides when and where particles are born: `amount`, `amount_ratio`, `one_shot`, `emitting`, `explosiveness`, `lifetime`, emission shape/size, spawn transform and preprocess. **Process** controls how particles travel and change: direction, speed ranges, spread, gravity, damping, turbulence, color/alpha curves and size curves. **Draw** controls appearance: mesh, texture, `StandardMaterial3D`, transparency, blend mode, billboard mode, shading and lighting layers. `local_coords` and `visibility_aabb` are node-level simulation/culling settings rather than draw-material settings.

## Revisions

_Add future adjustments below this line with a date, reason, changed setting, and evidence. Do not rewrite the original predictions above after the initial commit._

### 2026-11-07, revision 1 (build): B1's splash emitter keeps emitting (Claude Code)

- **Changed:** `LampSplash` `emitting = false`† becomes `emitting = true`, in all three B1 scenes.
- **Why:** a particle node that is not emitting can fall idle and drop the splashes its parent
  sends it, while Godot documents that a node used as another emitter's `sub_emitter` no longer
  emits on its own. So `true` is the safe value; the † value was Claude Code's mistake.
- **To confirm in B1's first windowed strip:** splashes appear where drops land, and none rise
  from the emitter itself.
- **Evidence:** `game/effects/lamp_rain_*.tscn`, `game/tests/test_lamp_rain_config.gd`.

### 2026-11-07, revision 2 (build): where the exhaust leaves the van (Claude Code)

- **Found:** the Iveco model has no tailpipe. Its rear underside is symmetrical, with no pipe on
  either side, and a parts-catalogue search did not settle where the 2014 Daily's exits.
- **Until the author confirms it from a photo of a real Daily:** the plume starts under the rear
  bumper on the driver's side, at (−0.6, 0.46, 2.85) in the van's frame, and leaves in the
  brief's direction, backward and 15° down. This is an assumption, not the model's tailpipe.
- **Evidence:** `TAILPIPE` in `game/features/vehicles/freight_van/van_particles.gd`.

### 2026-11-07, revision 3 (build): what freeing the van does to A2 (Claude Code)

- **Changed:** A2's rule "If the followed node is freed: No new spawn. The detached, world-space
  spill completes its lifetime and is then freed safely" becomes: the spill moves with the van
  (`local_coords = true`, the author's choice), so when the van is freed the spill goes with it,
  and nothing is spawned or dereferenced afterwards.
- **Why:** the rule was written for the draft's world-space spill. Since A2 moved into the van's
  frame, there is no detached spill left to finish.
- **Evidence:** `game/tests/test_roof_spill_state.gd`.

