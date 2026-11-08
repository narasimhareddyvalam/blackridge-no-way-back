# Particle effects research (Assignment 6)

Written by Claude Code on 2026-11-07 at the author's request (#138). It collects what the brief
needs: what the code does today, how the real things behave, with sources, and the property
names this Godot version has.

**This is not the brief.** `CHANGE-BRIEF.md` is the author's: the assignment says "You write:
CHANGE-BRIEF.md, every prediction, every verdict and the process-shader notes". Nothing here is
an intent, a setting, a rule, a prediction or a budget for that brief. Each fact is marked:

- **Code:** from this repository, with its file and line;
- **Published:** a measured number from a named source;
- **Calculated:** Claude Code's arithmetic from those two;
- **Estimate** or **suggestion:** Claude Code's judgement, for the author to accept or reject.

## 1. The author's choices

From 2026-11-07 (`docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #131–#138, C52):

| | Effect | Job | Graded |
| --- | --- | --- | --- |
| A1 | Wiper flick: water thrown off the glass as the blades turn at the top of each stroke | One-shot | Yes |
| A2 | Roof spill: rain on the roof pours over the windshield when the van brakes hard | One-shot | Yes |
| B1 | Rain in every lamp's light | Ambience | Open |
| B2 | Exhaust vapour, following the throttle | Feedback loop | Open |

- "both the effects in A should be graded."
- "make sure everything is realisitc as if its real life world" and "make sure physics work as
  real life".
- "i want it to be visible even when theres no lamp", for the A effects.

## 2. What the brief must contain

Assignment 6, "1. Predict". Each item has a heading in `CHANGE-BRIEF.md`.

- **For each effect:**
  - the job: what it tells the player and why, and the script and signal or variable behind it;
  - the intent: timing phases with rough durations, contrast against the named background, scale
    against the character, change over life, variation, and each emitter's job;
  - the settings, with values: node type and why; emission (amount, one_shot, explosiveness,
    lifetime, emission shape); process (velocity, spread, gravity, damping, colour, alpha and
    scale curves); draw (texture, draw material, blend mode, billboard mode, mesh);
    local_coords and why; visibility_aabb, and whether it was generated or set and checked;
    preprocess;
  - the rules a test can measure;
  - the evidence split: for each rule, a headless test, a frame strip or eyes in the game;
  - the frame strip: the background, the trigger frame, the frames to read and what each shows.
- **For each B effect:** which job, and the process or draw feature it uses that the A effects
  don't.
- **For the whole brief:** the boundaries; at least three predicted failures, each with the check
  that catches it; per effect, the peak particle count, the predicted headless CPU price, the
  predicted GPU time and a budget, with the price it is compared on; short answers to the six
  questions.
- **When:** committed before the first prompt; after that, changed only by dated revisions below
  the original.

## 3. A1: the wiper flick

### Code

- **The event:** `wiper_swept` (`game/features/vehicles/freight_van/freight_van.gd:5`), emitted
  every half stroke while the wipers run (`:279-284`): once at the top of each stroke and once
  back at park. It carries no position.
- **Speeds:** `WIPER_CYCLES` is [0.0, 0.75, 1.1] strokes a second for off, slow and fast (`:14`).
  The `wipers` action cycles them (`:183-185`; `game/project.godot:72`). The ignition sets slow
  (`:258`), and switching off parks them (`:233`).
- **Motion:** `wiper_angle = WIPER_PARK + WIPER_SWEEP × (1 − cos(2π·t)) / 2`, with `WIPER_PARK`
  −1.55 rad and `WIPER_SWEEP` 1.72 rad (`:12-13`, `:285`). The blades slow to a stop at each
  end, as a crank linkage moves them.
- **Layout on the glass** (`windshield_wipe_map.gd:3-6`): the glass is 1.77 × 1.0 m; the pivots
  are at (−0.595, −0.47) and (0.06, −0.5) m from its centre; the arms are 0.42 and 0.40 m and the
  blades 0.65 and 0.53 m. A blade points along (sin a, cos a), with a = −`wiper_angle` (`:35`,
  `:54`). Parked, both lie along the bottom, pointing right.
- **The glass:** centred at (0, 1.849, −1.389) in the van's frame and tilted back 45.65° from
  upright (`WINDSHIELD_RAKE` 0.7967 rad, `van_presentation.gd:71-72`). The driver's eye is at
  (−0.45, 1.88, −0.72) (`:121`).
- **What the glass already draws** (Run 16, step 2, in `docs/PHASE_BRIEF.md`): a ridge of water
  ahead of each moving blade, left behind at the top turn as a line that breaks into beads. The
  windshield shader is outside this change.

### Calculated

- The glass runs from 1.50 m to 2.20 m above the ground.
- Top turns come every 1.33 s on slow and every 0.91 s on fast.
- The driver's blade tip is 0.745 m from its pivot. It peaks at 3.0 m/s on slow and 4.4 m/s on
  fast. Into the turn it slows at up to 14 m/s² (1.5 g) on slow and 31 m/s² (3.1 g) on fast.
- At the top turn both blades stand 9.7° past upright, leaning left. The driver's tip is then
  16 cm from the glass's left edge and 23 cm below its top; the passenger's tip is near the
  middle, 34 cm below the top.
- Parked, a drop that leaves the glass 1.8 m up reaches the ground in about 0.6 s.

### Published: how fast water drops fall

Gunn and Kinzer (1949), "The terminal velocity of fall for water droplets in stagnant air",
*Journal of Meteorology* 6, 243–248:

| Diameter (mm) | 0.1 | 0.2 | 0.3 | 0.5 | 1 | 2 | 3 | 4 | 5 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Speed (m/s) | 0.27 | 0.72 | 1.17 | 2.06 | 4.03 | 6.49 | 8.06 | 8.83 | 9.09 |

### How the real thing behaves

- A blade can push water but can't hold it back. Once it starts slowing after mid-stroke, the
  ridge runs on ahead of it. On the driver's side that water reaches the left edge by the pillar
  and leaves the glass. Slow wipers throw much less.
- The water leaves as millimetre drops and finer spray (estimate). Parked, the drops arc out past
  the pillar and fall beside the door; the fine spray, 0.1–0.3 mm, falls at 0.3–1.2 m/s, so it
  hangs for a second or more. At speed, the air carries the drops back along the side window,
  the same airflow the glass rain already uses (`rain_physics.gd`).
- On the way down, the blades push the water into the gap under the bonnet, out of view
  (estimate).
- **Seen without a lamp:** a water drop is a tiny ball lens. It shows an upside-down image of
  what is around it, so against the dark sky it carries a bright speck of the headlight-lit road,
  and against the road a dark speck of the sky. With the lights off on an unlit road it fades,
  as real water does. The drops on the glass already work this way (`sky_view()`, Run 11).

### For the rules

- On fast wipers the next top turn comes 0.91 s after the last, while the fine spray is still in
  the air, so the bursts overlap. With bursts that last under 1.82 s, at most two are alive at
  once on fast (calculated). Suggestion: the retrigger rule "overlap".
- Once in the air, the water no longer moves with the van.
- The van and its wipers are never freed on a wiper turn.

## 4. A2: the roof spill on hard braking

### Code

- **Braking:** a brake press, the handbrake or Ethan's held foot sets `braking`
  (`freight_van.gd:100`). The van then slows at 9 m/s² (`brake_deceleration`, `:22`,
  `:106-108`), or at 1.5 m/s² while its wheels are locked (`LOCKED_GRIP`, `:16`). On a keyboard
  the brake is all or nothing (`:90`), so every press at speed is a hard stop.
- **Speed:** `actual_speed` (`:123`) gives the van's real speed each physics tick, so its
  deceleration can be read from it.
- **The roof:** the Iveco is 2.08 m tall and sits 0.16 m up in the van's frame (Run 23), so its
  roof is about 2.24 m up; the glass's top edge is at 2.20 m (§3). The moon roof's opening is
  1.04 × 0.44 m (Run 23).

### Calculated

- Braking at 9 m/s², gravity and the braking push add up to 13.3 m/s², pointing forward and
  47.5° below horizontal. The windshield runs down and forward at 44.35°, only 3.1° away. So
  water on the glass presses on it at 0.72 m/s² instead of 7.0, about a tenth, and runs down it
  at 13.3 m/s² instead of 6.9, about twice as fast.
- A stop lasts 1.2 s from 40 km/h and 1.9 s from 60 km/h.
- **Thin-film flow:** a film of water of depth h, pushed by an acceleration a, flows at
  a·h²/(3ν). For a 0.5 mm film at 9 m/s², with water at 10 °C (ν = 1.31 × 10⁻⁶ m²/s), that is
  about 0.6 m/s. So only the water near the roof's front edge spills during one stop.
- **Refilling:** heavy rain of 25 mm an hour puts 6.9 mL a second on each square metre of roof.
  Refilling the front of the roof with half a litre takes tens of seconds.

### How the real thing behaves

- Rain gathers on the roof as a film, from a fraction of a millimetre to about a millimetre deep
  (estimate). At speed, the air pushes it toward the back.
- Brake hard, and the water near the front surges forward and pours over the edge onto the
  windshield, wavering and breaking into streams and drops, then races down the glass.
- With so little pressing it onto the surface, water coming over the edge leaves it easily, as a
  thin curtain in front of the glass, before landing lower down (calculated, above).
- A second hard stop soon after finds the front of the roof nearly empty. Suggestion: the
  retrigger rule "ignore" follows from this.

## 5. B1: rain in every lamp's light

### Code

- **Lamp posts** (`game/features/environments/industrial_loop/industrial_loop.gd:632-653`):
  each light is an omni light 6.7 m up, colour `ffd1a0`, energy 3.0, reach 18 m, attenuation 1.6,
  fading out from 65 m to 90 m away. Posts beyond z 100 get shadows, energy 4.0 and 16 m.
  - the depot: three posts at x −45, −30 and −15, z 109, with shadows (`:456-460`);
  - the valley road: `TOWN_LAMPS` at (−45, 64.5), (−15, 63.8) and (8, 62.5) (`:68-69`,
    `:468-469`);
  - the lumber yard: one post (`:542`).
- **The site office** (`:592-619`):
  - the door lamp (`NoticeLight`): a spot light, energy 4.0, 8 m, 55°, with shadows;
  - the floodlight (`FloodLight`): a spot light, energy 9.0, 32 m, 30°, with shadows, aimed at
    the van's parking place, 1 m up;
  - the window glow: an omni light, 0.8, 4 m.
- **Ground and shelter:** the office has a door hood and 35 cm eaves (Run 24); the lumber yard and
  the forecourt are gravel (`:505`, `:509`); the valley road is asphalt.
- **The beam rain:** drops fall at 7.5 m/s and draw as 32 cm streaks (`beam_rain.gdshader:11`,
  `:24`), slanted 0.08, or 4.6°, by `RAIN_SLANT` (`van_presentation.gd:98`). Its streak columns
  are laid out across the van (`across = VERTEX.x`, `beam_rain.gdshader:52`), so it moves with
  the van: at speed it doesn't rush toward the driver, and its slant turns with the van.
- **Pause:** the title screen pauses the game (`game/app/first_drive.gd:138-140`), and so does
  the pause menu (`:402-403`).

### Published: how many drops, and how big

Marshall and Palmer (1948), "The distribution of raindrops with size", *Journal of Meteorology*
5, 165–166: N(D) = 8,000 e^(−ΛD) drops per cubic metre per millimetre of diameter, with
Λ = 4.1 R^(−0.21) per millimetre for a rain rate R in millimetres an hour.

### Calculated

- At 25 mm an hour, each cubic metre holds about 3,800 drops: about 480 of 1 mm or more, 60 of
  2 mm or more and 7 of 3 mm or more.
- About 400 drops of 2 mm or more hit each square metre of ground every second.
- The beam rain draws a 7.5 m/s drop as a 0.32 m streak, a 1/23 s exposure. At the same exposure,
  a 1 mm drop draws 17 cm long, a 2 mm drop 28 cm and a 3 mm drop 34 cm.

### How the real thing behaves

- Rain shows only where light reaches it. Drops scatter light mostly forward, so rain is
  brightest when you look toward the lamp and faint with the lamp behind you.
- A real street lamp's head is shielded, so rain above it stays dark. These posts are omni
  lights, which also light upward.
- Splashes rise a few centimetres off concrete and asphalt, up to about 15 cm for the biggest
  drops; there are fewer on gravel, and rings on puddles (estimate).
- It stays dry under the office's door hood and eaves. Drops land and splash on the van's roof
  and bonnet.
- The drops stay where they are in the world, so they rush past as the van drives by.
- Wind slants rain the same way everywhere, whichever way the van faces.

## 6. B2: exhaust vapour

### Code

- **The engine:** `engine_on` (`freight_van.gd:27`). `start_engine()` (`:237`) sets it and emits
  `engine_started` (`:8`, `:242`); `switch_off()` (`:228`) clears it.
- **The throttle:** the strength of the `accelerate` action (`:89`), all or nothing on a
  keyboard; the mission's `scripted_throttle` while the mission drives (`:94`).
- **The lights that will show it** (`van_presentation.gd`):
  - the tail glow: two red spot lights, 5 m, 85°, pitched 20° down, energy 0.25, or 1.0 when
    braking (`TAIL_GLOW`, `TAIL_GLOW_RANGE`, `:60-61`, `:847-860`);
  - the reversing lamps: two white spot lights, energy 6, 14 m, 55°, pitched 12° down
    (`REVERSE_ENERGY`, `REVERSE_RANGE`, `:57-58`, `:833-844`). In reverse, the reverse camera
    shows them three times brighter (`REVERSE_GAIN`, `:59`);
  - all of them light render layer 1 only (`light_cull_mask = 1`, `:841`, `:857`).
- **The tailpipe:** not in the code. Its position comes from the Iveco model.
- **The story:** "a long, lonely drive through Blackridge in cold rain" (`docs/GAME_STORY.md:43`).

### How the real thing behaves

- Burning diesel makes water. Hot exhaust carries it as vapour; mixed into cold air already
  saturated by rain, it condenses into a white plume of tiny droplets, which evaporate again as
  the plume thins. In saturated air it lingers: a few metres and a few seconds at idle
  (estimate).
- It leaves the pipe at about 5–10 m/s at idle and several times that under load (estimate, from
  the air flow of the Daily's 2.3–3.0 litre engines).
- The engine and turbo take about half a second to a second to build power, so a real plume
  grows with that, not the instant the key is pressed (estimate).
- It rises as it slows, being warm, and curls as it mixes.
- Moving, a box-shaped van leaves a low-pressure wake behind its rear doors; the plume is drawn
  into it and torn up.
- Just after a cold start it is thicker, because water condensed in the cold exhaust is blown
  out; it thins over the first few minutes (suggestion).
- At switch-off the flow stops at once, and the last vapour drifts away over a few seconds.
- It shows only where light falls on it: red in the tail glow and brighter when braking; white in
  the reversing lamps and on the reverse camera; under the office floodlight and the depot lamps.

## 7. Godot 4.7.2 names

From the engine's own description of its classes (`--dump-extension-api`, Godot 4.7.2 stable,
2026-11-07). Use these names, never Godot 3's.

**`GPUParticles3D`:** emitting, amount, amount_ratio, sub_emitter, lifetime, interp_to_end,
one_shot, preprocess, speed_scale, explosiveness, randomness, use_fixed_seed, seed, fixed_fps,
interpolate, fract_delta, collision_base_size, visibility_aabb, local_coords, draw_order,
transform_align, transform_align_axis, transform_align_channel_filter, trail_enabled,
trail_lifetime, process_material, draw_passes, draw_pass_1 to draw_pass_4, draw_skin.

- `draw_order`: DRAW_ORDER_INDEX, DRAW_ORDER_LIFETIME, DRAW_ORDER_REVERSE_LIFETIME,
  DRAW_ORDER_VIEW_DEPTH.
- `transform_align`: TRANSFORM_ALIGN_DISABLED, TRANSFORM_ALIGN_Z_BILLBOARD,
  TRANSFORM_ALIGN_Y_TO_VELOCITY, TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY,
  TRANSFORM_ALIGN_LOCAL_BILLBOARD.

**`ParticleProcessMaterial`:** lifetime_randomness, particle_flag_align_y,
particle_flag_rotate_y, particle_flag_disable_z, particle_flag_damping_as_friction,
particle_flag_inherit_emitter_scale, emission_shape_offset, emission_shape_scale, emission_shape,
emission_sphere_radius, emission_box_extents, emission_point_texture, emission_normal_texture,
emission_color_texture, emission_point_count, emission_ring_axis, emission_ring_height,
emission_ring_radius, emission_ring_inner_radius, emission_ring_cone_angle, angle, angle_min,
angle_max, angle_curve, use_rotation_3d, rotation_3d_min, rotation_3d_max, inherit_velocity_ratio,
velocity_pivot, direction, spread, flatness, initial_velocity, initial_velocity_min,
initial_velocity_max, angular_velocity, angular_velocity_min, angular_velocity_max,
angular_velocity_curve, directional_velocity, directional_velocity_min, directional_velocity_max,
directional_velocity_curve, orbit_velocity, orbit_velocity_min, orbit_velocity_max,
orbit_velocity_curve, radial_velocity, radial_velocity_min, radial_velocity_max,
radial_velocity_curve, velocity_limit_curve, use_rotation_velocity_3d, rotation_velocity_3d_min,
rotation_velocity_3d_max, rotation_velocity_3d_curve, gravity, linear_accel, linear_accel_min,
linear_accel_max, linear_accel_curve, radial_accel, radial_accel_min, radial_accel_max,
radial_accel_curve, tangential_accel, tangential_accel_min, tangential_accel_max,
tangential_accel_curve, damping, damping_min, damping_max, damping_curve,
attractor_interaction_enabled, use_scale_3d, scale_3d_min, scale_3d_max, scale, scale_min,
scale_max, scale_curve, scale_over_velocity, scale_over_velocity_min, scale_over_velocity_max,
scale_over_velocity_curve, color, color_ramp, color_initial_ramp, alpha_curve, emission_curve,
hue_variation, hue_variation_min, hue_variation_max, hue_variation_curve, anim_speed,
anim_speed_min, anim_speed_max, anim_speed_curve, anim_offset, anim_offset_min, anim_offset_max,
anim_offset_curve, turbulence_enabled, turbulence_noise_strength, turbulence_noise_scale,
turbulence_noise_speed, turbulence_noise_speed_random, turbulence_influence,
turbulence_influence_min, turbulence_influence_max, turbulence_initial_displacement,
turbulence_initial_displacement_min, turbulence_initial_displacement_max,
turbulence_influence_over_life, collision_mode, collision_friction, collision_bounce,
collision_use_scale, sub_emitter_mode, sub_emitter_frequency, sub_emitter_amount_at_end,
sub_emitter_amount_at_collision, sub_emitter_amount_at_start, sub_emitter_keep_velocity.

- `emission_shape`: EMISSION_SHAPE_POINT, EMISSION_SHAPE_SPHERE, EMISSION_SHAPE_SPHERE_SURFACE,
  EMISSION_SHAPE_BOX, EMISSION_SHAPE_POINTS, EMISSION_SHAPE_DIRECTED_POINTS, EMISSION_SHAPE_RING.
- `collision_mode`: COLLISION_DISABLED, COLLISION_RIGID, COLLISION_HIDE_ON_CONTACT.
- `sub_emitter_mode`: SUB_EMITTER_DISABLED, SUB_EMITTER_CONSTANT, SUB_EMITTER_AT_END,
  SUB_EMITTER_AT_COLLISION, SUB_EMITTER_AT_START.

**`StandardMaterial3D`,** the parts a particle draw material uses (from `BaseMaterial3D`):
transparency, blend_mode, shading_mode, cull_mode, depth_draw_mode, no_depth_test,
vertex_color_use_as_albedo, vertex_color_is_srgb, albedo_color, albedo_texture, roughness,
metallic, emission_enabled, emission, emission_energy_multiplier, refraction_enabled,
refraction_scale, billboard_mode, billboard_keep_scale, particles_anim_h_frames,
particles_anim_v_frames, particles_anim_loop, use_particle_trails, proximity_fade_enabled,
proximity_fade_distance, distance_fade_mode, distance_fade_min_distance,
distance_fade_max_distance.

- `transparency`: TRANSPARENCY_DISABLED, TRANSPARENCY_ALPHA, TRANSPARENCY_ALPHA_SCISSOR,
  TRANSPARENCY_ALPHA_HASH, TRANSPARENCY_ALPHA_DEPTH_PRE_PASS.
- `blend_mode`: BLEND_MODE_MIX, BLEND_MODE_ADD, BLEND_MODE_SUB, BLEND_MODE_MUL,
  BLEND_MODE_PREMULT_ALPHA.
- `billboard_mode`: BILLBOARD_DISABLED, BILLBOARD_ENABLED, BILLBOARD_FIXED_Y,
  BILLBOARD_PARTICLES.

**Collision, attractors and trails:**

- `GPUParticlesCollisionHeightField3D`: size, resolution (RESOLUTION_256 to RESOLUTION_8192),
  update_mode (UPDATE_MODE_WHEN_MOVED, UPDATE_MODE_ALWAYS), follow_camera_enabled,
  heightfield_mask;
- `GPUParticlesCollisionBox3D`: size. `GPUParticlesCollisionSDF3D`: size, resolution, thickness,
  bake_mask, texture;
- `GPUParticlesAttractorBox3D`: size;
- `RibbonTrailMesh`: shape (SHAPE_FLAT, SHAPE_CROSS), size, sections, section_length,
  section_segments, curve. `TubeTrailMesh`: radius, radial_steps, sections, section_length,
  section_rings, cap_top, cap_bottom, curve.

**`CPUParticles3D`** has none of these: amount_ratio, collision, sub-emitters, trails,
turbulence or attractors.

**Godot 3 names, and what 4.7.2 does with them:**

- `ParticlesMaterial`: no such class.
- `scale_random`: no such property.
- `initial_velocity`, `scale`, `damping`, `angle` and `hue_variation` do exist in 4.7.2, but as
  Vector2 ranges beside the `_min` and `_max` floats. So the assignment's mutation, renaming
  `initial_velocity_min` to `initial_velocity`, may not fail the way the assignment expects. The
  assignment says to record what happens.

## 8. Facts for predicted failures

The assignment's own list (Godot 3 names; 3D draw materials; the visibility box; preprocess;
the dropped retrigger; the popping feedback loop; the freed parent), and these, from this game:

- **Render layers.** The driving camera draws `7 | MIRROR_LAYER` (`van_presentation.gd:362`), the
  mirror cameras 3 (`:496`), the reverse camera 7 (`:389`), and the on-foot camera every layer
  (`driver.gd:66` sets none). The headlights, tail glow and reversing lamps light layer 1 only
  (`:306`, `:841`, `:857`). The beam rain is on layer value 4 (`:710`).
- **The windshield.** Its drops show a copy of the screen that holds only opaque objects (Run 5),
  so see-through particles behind the glass can vanish inside them.
- **Upscaling.** MetalFX draws at 75% on macOS (`game/project.godot:137-138`), which can smear
  small, fast particles.
- **Exposure.** AgX at exposure 1.3 (`industrial_loop.gd:121-122`), and the driver's eyes adapt
  to glare (Run 19, step 4).
- **Pause.** The title screen and the pause menu pause the game (§5).
- **Mirrors.** They redraw what they see, 30 and 15 times a second (Run 33).
- **Headless runs** draw no particles.
- **The GPU timer.** "Godot's GPU timer reads 0 on Metal" (Run 17, `docs/PHASE_BRIEF.md:1151`).

## 9. Facts for prices and budgets

- The frame budget is 16.7 ms for 60 FPS (C21).
- Latest measured, on battery (`PERFORMANCE.md:199-212`): 13.25 ms (75.5 FPS) at the start with
  the new mirrors; the captures ran at 69.8–74.8 FPS; on a warm Mac the slowest 5% of frames take
  17–19 ms. Not yet measured on mains power.
- A GPU effect's headless CPU price is near zero by construction; a CPU node's isn't.
- The cost script is adapted from the chapter's Example 09, which is not in this repository.

## 10. Paths and commands in this repository

- The project is `game/`, not `godot/`: effects in `game/effects/`, previews in
  `game/previews/`, tests in `game/tests/`.
- The previews are test fixtures. The export's exclude list (`game/export_presets.cfg:11`) leaves
  out `tests/*` and `experiments/*` today, not `previews/*`.
- `game/shaders/particles_generated.gdshader` is made by the author in the editor (Step 6).
  Agents never write in `game/shaders/`.
- Frame strips come from a windowed Movie Maker run that the author starts, with the scratch
  home:

  ```sh
  HOME="$PWD/.scratch-home" /Applications/Godot.app/Contents/MacOS/Godot --path game \
    res://previews/<effect>_preview.tscn \
    --write-movie "$PWD/captures/<effect>/r0/frame.png" --fixed-fps 30 --quit-after 60
  ```

- The order: the brief; then the test runner (`realtime` mode and a timeout added, keeping the
  scratch home and the save-folder check); the baseline; then Step 1.
