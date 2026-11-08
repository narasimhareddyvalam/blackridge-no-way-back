# HANDOFF.md

**Last run:** the brief's step 5, the rendering (#158), 2026-11-08, on branch `develop`, after
the roadside (#157), the depot lit from its wall (#151), the street lamps and the road's puddles
(#150), and Assignment 6's r1 (#145–#149). All stay uncommitted in the working tree; their
records, a patch copy of each, and this handoff are committed, not pushed. Their sections are
below, newest first. **Next:** the author's brief for a photorealistic rainy road is done, one
approved step at a time (C53): the wet road's reflections (#153), the streetlight (#154), the
rain and its splashes (#156), the roadside (#157) and the rendering (#158). What is left of
Assignment 6 is listed in the prompt log's #158 answer and the "Waiting for the author" list;
it starts with the author's look in the game and the strips.

Before it, the build after the brief (#142–#144), committed in 18 commits from `7f1f7bb` (the
test runner) to `4f73f98`, not pushed. Before that:
- `7bbf0a4`: the old brief moved, and the brief template (#138);
- `5d5ca7e`: Phase 2, step 1b, missions in a row and the progress file's version 2 (#129–#130);
- `b4650fd`: the version 2 save rules, before any code (#127–#128);
- `2ebd682`: the Phase 2 brief, Mission 2, before any code (#126);
- `31840c9`: Phase 1, Run 34, the front door in design A (#122–#124, C50).

Before those, Run 33: real door mirrors and the yard gravel at real size (#119, C48), then the
passenger mirror turned toward the driver (#120, C49).
Runs 27 to 33 are committed together on `develop` and pushed (#121): saving (C43), Ethan's step,
the beam shape and wet bark (C44), the beam reach (C45), the forecourt start (C46), the reversing
lamps (C47) and Run 33. Committed before them, in order:
- `3d257a2`: Run 19;
- `301c250`: the save rules, on their own (#107);
- `573862b`: Runs 20–26, after the author had told Max about the van on 2026-11-03 (#109).

`develop` is pushed up to `c1ee48f`; every commit after it is local, not pushed; `main` is
untouched.

**Assignment 6 (particles) began on 2026-11-07 (#131–#138, C52):** four effects, the author's
brief first, then the test runner, the baseline and the assignment's Step 1. See the section
below.

**The author's agreed order (#108–#109), each step approved on its own:**

1. ~~Runs 20–26 committed and pushed~~ (done);
2. ~~saving, built to the committed save rules, test first~~ (done, Run 27); the author's check
   (quit at a checkpoint, relaunch, continue) is still to come;
3. ~~the keyboard-only menu, Assignment 10's front door~~ (done, Run 34); the author's keyboard
   check is still to come;
4. Mission 2, The Wrong Cargo: planned on a map (#124–#125, C51), and its brief written as the
   Phase 2 revision at the end of the old brief, now `docs/PHASE_BRIEF.md` (#126). It is built
   one approved step at a time:
   - step 1a, the version 2 save rules, is committed (#128);
   - step 1b, missions in a row and the version 2 code, is committed (`5d5ca7e`, #130);
   - step 2, the transfer shed, waits until Assignment 6 is tagged (Claude Code's
     recommendation; the author has not confirmed it);
5. Mission 3, Last Run, with the combat encounter and the story scenes;
6. the author's own full playtest, then the story changes, the "gamify" pass and the polish.

**The bar for every step (#109):** realistic down to the minor details, built to best practice.

**Set aside until the author returns to them (#103–#104):** the opening cutscene, the live title
screen with the game logo (C42), the film look in cutscenes, the filmed ending and the studio
intro.

No slow motion. No title card before the end shows the game's title (C04).

## The brief, step 5: the rendering (#158)

**The instruction (#158):** "proceed with step 5. what else is left in the assignment do?"

**Found:** every rendering setting is Godot's default except MetalFX temporal upscaling at 75% on
macOS. The moon's mirror glint made wet surfaces shine silver-blue and the needles look frosted;
under full cloud the moon gives only diffuse light. Four candidates changed almost nothing
visible, so none was made: shadows to 65 m, soft contact shadows, a reflection probe at the west
bend, and anisotropic filtering on the road (renders and pixel counts in the prompt log).

**In the working tree, uncommitted,** in `tools/tuning/world/lamps_and_rings.patch`:
`industrial_loop.gd`'s moon has `light_specular = 0.0`.

**Tests:** `LOG_DIR=logs/particles/brief_step5`, every suite and `test_night_dimming.gd` at 30, 60
and 144 exit 0 with step 4's counts; art 0 failures; `cost_effects.gd 60 300` exit 0 (0.467 ms).

**Unverified:** the darker night in play, on foot and in the van; the author's view of losing the
frosted look of the trees.

## The brief, step 4: the roadside (#157)

**The instruction (#157):** "alright proceed with step 4" (guardrails, grass, lamps in the
distance and thin mist, the mist without volumetric fog).

**Found:**
- The straight past the lamps is flat, so a real road would have no guardrail there. The bends
  east and west of the depot (radius 42 m and 48 m) have trees within the widened clear zone on
  their outside, so each gets a guardrail there.
- Poly Haven's grass models are too heavy (0.2–1.6 million polygons each).
- `_outer_side()` in `ghat_dressing.gd` returns a curve's inside. Only the lay-by walls use it;
  it is left as it is, as a question for the author.

**In the working tree, uncommitted,** in `tools/tuning/world/lamps_and_rings.patch`:
- `ghat_dressing.gd`:
  - a real W-beam profile (311 × 83 mm, its top at 787 mm);
  - posts every 1.905 m by arc length, with timber spacer blocks;
  - a white reflector on every 16th post;
  - a terminal head and striped marker at each end of every rail run;
  - wet galvanized steel, its roughness patched by noise;
  - `build()` takes `outside_rails`, pairs of points along which the outside of the curve gets a
    rail, its side found once from the whole bend's turn.
- `retroreflector.gdshader`, new: matt sheeting plus a return toward each light,
  `return_peak / (1 + (angle / return_spread)²)` in the observation angle.
- `industrial_loop.gd`:
  - `CURVE_RAILS` (two bends);
  - `_bend_lamps()`, four lamps on the west bend's outside, 38 m apart and 1.3 m beyond the
    verge;
  - `_mist()` under every street lamp, depot wall light, the floodlight and the door lamp;
  - the ground's turf textures, and `OFFICE_PLOT` (the office's clearing, unchanged);
  - the grass built after the forest, from the built plots, the forecourt and the office.
- `roadside_grass.gd`, new:
  - about 45,000 tufts in the valley road's verge (2.5 m mowed, thinning to 4 m), in 16 m
    tiles, drawn up to 45 m with a lighter tuft beyond 18 m, and without shadows;
  - a 1 m map of distance beyond the verge, which `paint()` hands to the ground shader.
- `verge_grass.gdshader`, new: wet blades that sway with the +x wind and twitch in the rain.
- `hill_ground.gdshader`: `leafy_grass` turf blended in by the verge map, with a ragged edge,
  kept matt (roughness 0.85).
- `forest_floor.gd`: no prop inside the mowed strip of a valley section. The random sequence
  is kept, so the rest of the forest floor is unchanged.
- `lamp_mist.gdshader`, new: equi-angular sampling (10 samples) of a spot light's in-scattering
  along the view through a box around its cone:
  - Godot's own cone and range falloff;
  - two Henyey–Greenstein lobes;
  - scattering 0.004 and extinction 0.0045 per metre;
  - clipped by the scene's depth;
  - faded with the lamp's distance fade.
- `polyhaven/textures/leafy_grass/` (CC0) and `tools/assets/verge_assets.json`, new;
  `SOURCES.md` and `POLYHAVEN.md` record it.
- `test_lamp_rain_state.gd`: 13 rain volumes (9).

**Tests:** `LOG_DIR=logs/particles/brief_step4`, every suite and `test_night_dimming.gd` at 30,
60 and 144 exit 0 with the same counts as step 3 (regression 64/64, lamp rain 360/360 and
12/12); art 0 failures; `cost_effects.gd 60 300` exit 0 (the game reads 0.469 ms headless).

**Unverified:**
- The GPU price of the grass, the mist and the four lamps. Godot's GPU timer reads 0 on Metal,
  and frame times on battery were noisy.
- The look in motion, and in the van's headlights.
- Whether the author wants the mist stronger or fainter (`scattering`).
- Whether the lay-by walls should move.

## The brief, step 3: the rain and its splashes (#156)

**The instruction (#156):** "alright proceed with step 3".

**Found:** B1's splashes never fired. In Godot 4.7.2 `COLLISION_HIDE_ON_CONTACT` sets off no
`SUB_EMITTER_AT_COLLISION`; `COLLISION_RIGID` does (a scratch scene, then large markers in the
game). The configuration test read only the settings.

**In the working tree, uncommitted** (the r1 patch, and in the world patch only
`_lamp_post()`'s `LampRain.STREET`):
- `game/effects/lamp_rain_street.tscn`, new: the street lamps' rain, 10 × 10 m, 5,000 drops,
  2,750 splash droplets, a 12 × 12 m collider; `lamp_rain.gd` gains `STREET`; the preview's valley
  lamp uses it.
- All four rain scenes: rigid collisions (friction 1, bounce 0), `fixed_fps` 60, splashes 3 cm up,
  and `still_fade` 1 on the drops; the street and post splashes 0.5–1.5 mm, `scatter` 30,
  `diffuse` 1.
- `scatter_particle.gdshader`: `still_fade` fades a particle whose streak has lost its speed
  stretch (`shape_ratio`, its length over its width before any widening).
- `test_lamp_rain_config.gd`: four scenes, 360 checks.

**Tests:** `LOG_DIR=logs/particles/brief_step3`, every suite exits 0 (lamp rain 360/360 and
12/12), art 0 failures.

**Unverified:** the splash droplets are real size and faint from a few metres; whether the author
wants them more visible. The particle count per street lamp is 7,750 (3,100 before); the GPU
price is unmeasured.

## The street lamps: a pool under each (#155)

**The instruction (#155):** "the street light lits entire road. make sure it light only road under
it radius. check how it is is real life and do it please."

**In the working tree, uncommitted,** in the world patch: `POST_SPREAD` 72 → 55, `POST_REACH`
30 → 15 m, and the street lamps' `spot_angle_attenuation` 0.5 → 1.5, so each lights a pool about
8 m in radius. **Tests:** `LOG_DIR=logs/particles/lamp_pool_155`, every suite exits 0, art 0
failures. **Unverified:** the pool in motion; the lamp's reflection now shows only within about
12 m of it.

## The brief, step 2: the streetlight (#154)

**The instruction (#154):** "alright proceed", then "Amber like your reference (Recommended)" for
the street lamps' light (C54).

**In the working tree, uncommitted,** in `tools/tuning/world/lamps_and_rings.patch` (which now
carries new files as well):
- `tools/art/build_streetlight.py`, new: run with
  `/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1
  --python tools/art/build_streetlight.py`; it writes
  `game/features/environments/industrial_loop/art/streetlight/streetlight.glb` (1,626
  triangles; slots "pole", "housing", "lens", "footing", "steel"; an empty "Lens").
- `tools/assets/streetlight_assets.json`, new: Poly Haven's `green_metal_rust` (1k), fetched
  with `python3 -I tools/assets/fetch_polyhaven.py tools/assets/streetlight_assets.json`, its
  imports set by `configure_imports.py` (the six other import files it touched were put back).
- `industrial_loop.gd`: `_lamp_post()` places the model and replaces its materials
  (`_streetlight_material()`); the light, amber `STREET_LIGHT_COLOR`, energy 90, sits at the
  "Lens" empty; `_halo(size, color)` now takes a colour; the depot keeps `WALL_LIGHT_COLOR`.
- `SOURCES.md`: rows for the texture and the model.

**An r1 change with it,** in `tools/tuning/r1/r1.patch`: B1's post scene scatters 5 (60), as the
brighter lamps had blown its amber to white; `test_lamp_rain_config.gd` reads each scene's own
strength. It assumes the world patch's lamps.

**Tests:** `LOG_DIR=logs/particles/brief_step2`, the same commands as #150: every suite exits 0
with the same counts, art 0 failures, and the cost script reads every effect the same as every
effect off.

**Unverified:** the model in the running game up close; the GPU price is unchanged in kind
(four shadowed spot lights, as before). Found, not changed: `rock_wall_02` and
`rustic_stone_wall` import without mipmaps or VRAM compression.

## The brief, step 1: the wet road's reflections (#153)

**The instruction (#153):** "Yes, start step 1", after the author kept the effects as they are
("Keep the game as it is (Recommended)") over their old picks from the options page.

**In the working tree, uncommitted,** in `tools/tuning/world/lamps_and_rings.patch` with #150
to #152 (`wet_asphalt.gdshader`):
- an uneven water film (`film`, slow noise, wetter round the puddles): the asphalt under it a
  quarter darker, roughness `FILM_ROUGHNESS` 0.16, its normal map flattened, and the stone tops
  (the brightest quarter of the aggregate, `stone_top`) kept bumpy at `WET_STONE_ROUGHNESS` 0.22;
- the rain rings in the film too (`FILM_RINGS` 0.45 of their strength), and where they are finer
  than the pixels, a smooth random tilt per patch of about two pixels (`dance_at()`, slope 0.05,
  changing five times a second, blended between two sizes so no seam shows).

**Tests:** `LOG_DIR=logs/particles/brief_step1`, the same commands as #150: every suite exits 0
with the same counts, art 0 failures, and the cost script reads every effect the same as every
effect off.

**Unverified:** the shimmer in motion in the running game and under MetalFX's temporal upscaling;
the GPU price of the rings, now on the film as well as the puddles.

## The depot lit from its wall (#151), each light a small pool (#152)

**#152:** "those lights shouldnt light up entire depot, it should lightup only things below those
lights in small radius". Each wall light's beam now points nearly straight down (10° out from
the wall), 40° each side with a soft edge (`spot_angle_attenuation` 1.5), reaching 9 m at energy
60, with a 1.2 m glow (`_halo(size)` now takes the size): a pool about 4 m across in front of each
door, the rest of the depot dark. Every suite passes (`logs/particles/depot_152/SUMMARY.txt`).
The values below are #151's first ones.

**The instruction (#151):** "those lights at shed looks so bad i mean, real physics and in real
life thats not how they are added near sheds, look for already available assets maybe", then "i
want them to be stuck onto the wall directly, i dont want any streetlight style lamps at depot".
With it, a pasted brief for a photorealistic rainy road, to be taken one part at a time ("Shed
lights, then brief step by step"), with volumetric fog off and the exposure fixed ("Keep them
fixed"). The street lamps' colour is open until the brief's streetlight step (C53).

**In the working tree, uncommitted until the author has looked,** in the same patch as #150
(`tools/tuning/world/lamps_and_rings.patch`, which now holds both, applying to HEAD):
- `industrial_loop.gd`: `_wall_light()` in place of the depot's three `_lamp_post()` calls:
  Poly Haven's Security Light (already in `depot_yard/polyhaven/models/`) on the wall above
  each roller door, 5.45 m up, its glass drawn with the street lamps' lens, casting no shadow
  itself; a spot light at its glass, aimed 35° from straight down and out over the apron, 60°
  each side, energy 140, reach 20 m, `spot_attenuation` 2, shadows to 45 m; the street lamps'
  glow; a B1 rain volume (the post scene) 4 m out from the wall and 0.45 m below the light,
  clear of the roof's 1 m overhang.
- `front_menu.gd`: the credits read "Textures, trees, plants, rocks and props from Poly Haven".
- `SOURCES.md`: a row for the Security Light.
- `test_lamp_rain_state.gd`: its message names the lamps as they are (4 posts, the depot's 3
  wall lights, the floodlight, the door lamp); the expected count, 9, is unchanged.

**Tests:** `LOG_DIR=logs/particles/depot_151` with the same commands as #150: every suite exits 0
with the same counts, art 0 failures, and the cost script reads every effect the same as every
effect off (`logs/particles/depot_151/SUMMARY.txt`).

**Unverified:** the wall lights in the running game and their GPU price (three shadowed spot
lights, as the three posts had); the bus stop's Poly Haven trash can, which ships, has no row in
`SOURCES.md` (found, not changed).

## The street lamps and the road's puddles (#150)

**The instruction (#150):** "can we add ripple effect when rain is falling under light on the
floor?? do research how it looks in real life and do it and can we make the lamp light more
realistic as in real life?" The research, with links to its sources, is in the prompt log (#150).
It lifts `CHANGE-BRIEF.md` §6's "do not change lamp behaviour" for the lamps themselves.

**In the working tree, uncommitted until the author has looked,** like r1.
`tools/tuning/world/lamps_and_rings.patch` is a committed copy: `git apply` restores it on HEAD
(checked with `git apply --cached --check`). r1's patch leaves these two files out and is
unchanged.
- `game/features/environments/industrial_loop/industrial_loop.gd`, `_lamp_post()` and the new
  `_halo()`, for all seven posts:
  - a `SpotLight3D` at the lens under the head, pointing down: 72° from straight down, energy
    60, reach 30 m, `spot_attenuation` 2 (falling off with the square of distance), the same
    colour and the same distance fade from 65 m, which B1's condition reads; shadows on every
    post, to 45 m (before: an omni light 0.4 m under the head, energy 3, attenuation 1.6, which
    also lit upward; shadows only on the depot's three);
  - the head: a dark metal housing and a bright lens beneath it (`_lens`, an HDR colour), in
    place of a head that glowed all over;
  - a halo: a 2.4 m additive billboard around the lens, fading where it meets geometry.
- `game/features/environments/industrial_loop/wet_asphalt.gdshader` (the valley road, the
  crossing and the depot yard):
  - puddles with defined edges and the stones at their rims, from the same noise, fewer of them
    (`PUDDLE_LEVEL` 0.62); their water flat (no road texture under it) and smooth;
  - raindrop rings in the water (`ring_slope()`, four layers, `rain_rings` to turn them off), in
    place of a fixed grid of waves that moved together; where the rings are finer than the
    pixels they widen and fade, and the water's roughness rises from 0.075 to 0.175.

**Tests, with the exact commands** (from the repository root):

```sh
LOG_DIR=logs/particles/lamps_150 scripts/run-test.sh <test>.gd 60   # every suite
LOG_DIR=logs/particles/lamps_150 scripts/run-test.sh test_night_dimming.gd 30  # and 60, 144
LOG_DIR=logs/particles/lamps_150 scripts/run-test.sh cost_effects.gd 60 300
python3 tools/tests/check_first_drive_art.py
```

- **Every suite** (`logs/particles/lamps_150/SUMMARY.txt`), all exit 0, no script or shader
  errors, with the same counts as `realistic_r1d`, and art 0 failures.
- **The cost script:** controls 0.002 and 0.003 ms against the game's 0.475 ms; every effect reads
  the same as every effect off.
- **Claude Code's renders** (scratch, not committed): the valley lamp before and after from four
  views; the puddles mapped with a copy of the shader that paints them red; rings seen in the
  lamp's reflection in a puddle from 2–4 m; every preview, with no script or shader errors.

**What the next run may rely on:**
- No test reads the post lamps' light or the road's puddles; `test_crossing.gd` reads only the
  crossing's paint.
- Findings:
  - `Build.luminous` makes an unshaded material, and Godot ignores an unshaded material's
    emission: only its albedo colour shows, so an HDR colour is what makes it bright;
  - rings show only in flat, smooth water: the old soft-edged puddles, half water and half
    textured road, hid them;
  - a puddle mirrors the lamp about a fifth of the way from the eye to the lamp (the eye 1.7 m
    up, the lamp 7 m).

**Unverified:**
- How it looks in the running game and in motion; MetalFX's temporal upscaling may soften rings.
- The GPU price: seven shadowed spot lights (three omni lights with cube shadows before) and the
  rings, four layers on each puddle pixel.
- Whether the author wants the road's new puddles: the road's look changes everywhere it uses
  this shader.
- B1's rain volume, 6 × 6 m under the head, is now smaller than the lamp's pool of light.

## Assignment 6, r1 applied at the author's direction: the realistic look (#145–#149)

**The instructions:**
- #146: "make them more realistic. i want the bigger droplets effect even under no lights in
  normal when driving. make everything realistic as fuck as if its a real world game", after the
  options page the author asked for in #145: https://claude.ai/artifact/3e4vVuGdFm9fBS5TndPFRZ;
- #147: "make wiper flick and roof spill more realistic. like give me ideas to choose from
  first", then the author's choices: every A1 idea, three of the four A2 ideas, and B1's
  splashes as its feature that the A effects don't use;
- #148: "make wiper flicker more visible and realistic and real physics as if in real life. go
  do research how it looks in real life first". The research and its sources are in the
  prompt log (#148) and `TUNING.md`;
- #149: "do the same thing do research of how the other three effects look in real life and
  redo them to match real life and realisitic." The research, with links to its sources, is in
  the prompt log (#149); the changes and predictions are in `TUNING.md`.

**In the working tree, uncommitted until the author's verdicts** (the handout: "Do not commit"
until the verdict). `tools/tuning/r1/r1.patch` is a committed copy: `git apply
tools/tuning/r1/r1.patch` on `4f73f98` restores it (checked with `git apply --cached --check`).
- `game/effects/scatter_particle.gdshader` and its `.uid`, new: the particle shader for all four
  effects (`TUNING.md` lists its parts). It is an effect resource, not in `game/shaders/`. The
  water is drawn like the windshield's own drops (`rain_drops.gdshaderinc`), and a drop turned
  along its motion draws as a comet.
- The six effect scenes: every draw material is a `ShaderMaterial` running that shader. A1 has
  six emitters (`WaterSheet`, `HeavyDrops`, `SpillWater` and `PillarRunoff` are new) and A2 four
  (`Rivulets` and, from #149, `WaterWash`, a clear sheet of water drawn first, are new); their
  values are in `TUNING.md`. #149 also changed B1 (real drop sizes and speeds, streaks
  stretched by speed, 2,000 drops a post lamp) and B2 (a short jet, gone in 1.6 s), and gave
  the shader a `ripple` setting for A2's sheet.
- The shader's water also shows, in each drop's upper part, an average of the headlit scene
  below it (`ground_reach`), and reflects at least 35% of the night sky's glow over all of it.
- `van_particles.gd`:
  - each van gets its own copy of the flick's and spill's process materials, since their gravity
    changes at runtime;
  - the flick is turned to the windshield's frame and placed at the blade tip, its bow-wave
    sheet laid along the blade (`_lay_along_blade`); each tick its
    gravity is the still air's plus the air's push up the glass, or back along the side for the
    run-off (`_blow_flicks`), none parked or reversing;
  - the run-off is thrown only above 5 m/s; a spill's water is thrown by the first top turn
    within 3 s of it;
  - the spill is turned to the windshield's frame at the roof lip (#149), and each tick its
    gravity is the still air's plus its water's surge as the van's speed changes
    (`_pour_spill`);
  - three thin colliders follow the curved windshield, each a plane fitted to a third of the
    glass model (`_fit_glass`);
  - `setup()` takes the windshield's `MeshInstance3D`, and `van_presentation.gd`'s one call
    passes it.
- The previews fix the new emitters' seeds (`WaterWash` last, so the others keep theirs);
  `cost_effects.gd` restarts them.
- `particle_readback.gd` reads a `ShaderMaterial` and per-axis curves, and checks that an emitter
  uses no sub-emitter, turbulence or driven `amount_ratio`.
- The four configuration tests take the new values, B1's with each lamp's own counts and its
  per-axis stretch; the A1 state test adds the colliders, the air's push, the run-off at speed,
  the spill's water and freeing the van; the A2 state test adds the water's surge;
  `test_exhaust_vapour_state.gd` expects an amount of 300.

**Committed:**
- this handoff;
- `TUNING.md`: r1 for each effect, with the predictions;
- the prompt log (#145–#149);
- `scripts/capture-strips.sh`: `FROM=<commit>` renders that commit's game from a temporary
  checkout;
- `tools/tuning/r1/r1.patch`, in place of the first proposal, which stays at `bf962da`;
- `logs/particles/realistic/` (r1 as of #146), `logs/particles/realistic_r1b/` (as of #147),
  `logs/particles/realistic_r1c/` (as of #148) and `logs/particles/realistic_r1d/` (as of
  #149).

**Tests, with the exact commands** (from the repository root):

```sh
HOME=$PWD/.scratch-home /Applications/Godot.app/Contents/MacOS/Godot --headless --editor \
  --path game --import
LOG_DIR=logs/particles/realistic_r1d scripts/run-test.sh <test>.gd 60   # every suite
LOG_DIR=logs/particles/realistic_r1d scripts/run-test.sh test_night_dimming.gd 30  # and 60, 144
LOG_DIR=logs/particles/realistic_r1d scripts/run-test.sh cost_effects.gd 60 300
python3 tools/tests/check_first_drive_art.py
```

- **The import:** exit 0 with no errors.
- **Every suite** (`logs/particles/realistic_r1d/SUMMARY.txt`), all exit 0, no script or shader
  errors:
  - the earlier suites with their baseline counts: 64/64, 0 failures, 92/92, 21/21, 12/12, 25/25,
    33/33, 12/12, 49/49, 21/21, 44/44, 12/12, 13/13, 12/12, 15/15, 29/29, 13/13, 20/20, 7/7, 30/30
    ×3, and art 0 failures;
  - configuration 339/339, 217/217, 255/255 and 44/44;
  - state 22/22, 13/13, 12/12 and 10/10.
- **The cost script** (run alone, the log kept): controls 0.002 and 0.003 ms against the game's
  0.456 ms. A1 reads +0.071 ms while its rounds vary by 0.164 ms (one slow round, up to
  3.4 ms), A2 +0.018, B1 +0.005 and B2 +0.005 ms, within 0.049 ms: all read the same as every
  effect off, so still no GPU particle process headless. A first run, made while Claude Code's
  renders ran, read +0.001 to +0.006 ms within 0.009.
- **The only ERROR lines:** the same engine messages as before tuning. A verbose run names the
  resources still in use at exit as `wiper.wav` and `collision.wav`, sounds still playing, not
  the effects.

**What the next run may rely on:**

- r1 renders in the game as the page shows: Claude Code rendered every preview from the working
  tree into its scratch folder, with A1 also at 50 km/h and in the depot (the previews use fixed
  seeds).
- `FROM=4f73f98 scripts/capture-strips.sh 0 …` renders r0. It was tested for A1 at 50 km/h, into
  the scratch folder, and its temporary checkout was removed.
- Findings from this run:
  - The windshield model is curved, 3.4 cm proud of its plane at the middle and 7–12 cm behind it
    at the sides; the wipers sweep the plane.
  - GPU trails redraw every draw pass once per trail section, so a bead cannot head a trail, and
    a trail misbehaves once its particle rests; rigid collision works for local-coordinate
    particles against colliders that move with them.
  - Turned along their motion, particles face the driver's camera correctly even with the
    mirrors' cameras drawing them too.
  - At night only a particle's emission shows; a lens that shows only the dark scene behind it
    disappears, so the water copies the windshield drops' sky-filled lower half.
  - A test that times a deceleration counts ticks with the van's clock, not a fixed duration.
  - Measured in renders of the parked flick: drops showing only the dark scene lifted their
    pixels by 1–3 levels of 255; with the bow-wave sheet, the average view below and the sky's
    reflection, the sheet's frames lift them by a median of 18–23 and up to 47.
  - The previews repeat in their effects, but the game's own background rain is not seeded.
  - #149: a transparent particle that shows the screen copy hides any transparent particle drawn
    before it, since the copy holds only opaque objects; A2's clear sheet hid its own streams
    until `sorting_offset` −0.25 m drew it first.
  - #149: turning the spill to the glass's frame kept its water's angles in the world (10.4°
    off the glass, the rivulets 5° into it), measured in the van.
  - #149: with every seed fixed, two renders that differ in one emitter differ only where it
    draws, so its effect can be measured (A2's sheet: 2.9% of the frame at 0.47 s).

**Waiting on the author (`TUNING.md`):**

1. If the Godot editor is open and says files changed on disk, choose Reload, not Ignore: Ignore
   and a later save would write r0's scenes back over r1.
2. Look at the four effects in the game at 1280×800:
   - the wiper flick, parked and driving on the dark valley road, and in the depot;
   - a hard brake at the office, with the wipers running;
   - a lamp on the valley road;
   - the exhaust at the office.
3. Capture `FROM=4f73f98 scripts/capture-strips.sh 0`, then `scripts/capture-strips.sh 1`, and
   the A1 variants named in `TUNING.md`.
4. Give a verdict per effect.
   - **For each effect kept,** Claude Code commits its part of r1 and writes the brief's
     revisions (listed under each effect in `TUNING.md`), including revision 6: B1's feature
     that the A effects don't use is its splash sub-emitter (#147).
   - **For each effect reverted,** Claude Code restores its part from `4f73f98`.

**Unverified:**

- How r1 looks in the author's strips and in the running game, which decide.
- r1's GPU price:
  - more particles (A1 804 at its peak, A2 264, B1 3,100 a post lamp and up to 24,800 at eight
    post volumes, B2 300);
  - a shader that reads the screen for A1's and A2's water, up to four times a pixel for the
    flick's drops;
  - three more particle colliders;
  - the windowed frame-time check is the author's (§8).
- Whether the parked flick on the unlit road reads as real: the sheet shows; the drops after
  it stay small and faint, as real ones are there.
- The wind speed at which drops of each size start to climb: no measured value was found, so
  the air's push stays an estimate.
- The side-window run-off is beyond the pillar, out of the driver's view in these strips; it is
  seen through the side window and from outside.
- The tailpipe's position (revision 2).
- #149: whether the author wants A2's clear sheet, which is close to the "Clear sheet" idea not
  chosen in #147 (the streams stay on top of it here); B1's slowest drops fade out 2–4 m above
  the ground instead of landing (`TUNING.md`, "A known gap"); B2's jet speed and how fast it
  stops are Claude Code's estimates, and no source gave how long exhaust vapour stays visible.

## Assignment 6, the build: effects, wiring, previews, fixes, price and documents (#142–#144)

**The instruction (#142):** finish every agent part following best practice, and leave the
author's own tasks for the end. Then #144: make all four effects clearly visible, as in the real
world.

**Files changed (committed):**

- **The effects:** `game/effects/` holds four scenes, three B1 variants and five textures, with
  `tools/make_particle_textures.py`.
- **The controllers:**
  - `game/features/vehicles/freight_van/van_particles.gd`, new, for A1, A2 and B2;
  - `game/features/environments/industrial_loop/lamp_rain.gd`, new, for B1; its hide time comes
    from the scene's lifetimes (1.35 s);
  - the hooks: `van_presentation.gd`, `industrial_loop.gd`, and `throttle` as a member in
    `freight_van.gd`.
- **The previews:** `game/previews/` (the shared `preview_fixture.gd` and one per effect), left
  out of the export (`game/export_presets.cfg`).
- **The tools:** `scripts/capture-strips.sh`, new; `scripts/run-test.sh` (`7f1f7bb`).
- **The tests:**
  - `game/tests/`: four configuration tests, four state tests, `particle_readback.gd` and
    `cost_effects.gd`;
  - `logs/particles/` holds every run, each mutation with its `MUTATION.md`, and the leak
    probe.
- **Documents:**
  - `CHANGE-BRIEF.md`, revisions 1–5;
  - `CLAUDE.md` (`05eefd3`);
  - `TEST-REPORT.md`, `SOURCES.md` and `README.md`, each with an Assignment 6 section first;
  - `TUNING.md`, new;
  - `FRICTIONAL.md`, the prompt log (#143–#144) and this file.

**Tests, with the exact commands** (from the repository root; logs under `logs/particles/`):

```sh
LOG_DIR=logs/particles/<step> scripts/run-test.sh <test>.gd 60
LOG_DIR=logs/particles/<step> scripts/run-test.sh test_night_dimming.gd 30  # and 60, 144
LOG_DIR=logs/particles/cost scripts/run-test.sh cost_effects.gd 60 300
python3 tools/tests/check_first_drive_art.py
```

- **Every suite before tuning** (`logs/particles/suites_before_tuning/SUMMARY.txt`), all exit 0:
  - the earlier suites with their baseline counts: 64/64, 0 failures, 92/92, 21/21, 12/12, 25/25,
    33/33, 12/12, 49/49, 21/21, 44/44, 12/12, 13/13, 12/12, 15/15, 29/29, 13/13, 20/20, 7/7, 30/30
    ×3, and art 0 failures;
  - configuration 70/70, 68/68, 234/234 and 42/42;
  - state 9/9, 11/11, 12/12 and 10/10.
- **The cost script:** controls 0.002 and 0.003 ms against the game's 0.484 ms. Every effect is
  within −0.031 to +0.024 ms of it while the rounds vary by up to 0.165 ms: no GPU particle
  process runs headless.
- **The mutations:** all six exit 1, as in `TEST-REPORT.md`.
- **The only ERROR lines:** the engine's DummyShader leak, "resources still in use", and the save
  test's damaged file, explained in `TEST-REPORT.md`.

**What the next run may rely on:**

- Every effect fires on the right game state and on the preview's frames, headless and in a
  window. Drawn solid red for one check, each draws where it should.
- The build matches the brief: revisions 4 (`billboard_keep_scale`) and 5 (the streak's width).
- Godot 4.7.2 runs `restart()` with `preprocess` about three frames late, and it does re-run the
  preprocess.
- A capture window takes the keyboard; the previews ignore real input.

**Waiting on the author (the tuning loop, `TUNING.md`):**

1. Capture the before strips: `scripts/capture-strips.sh 0`.
2. Approve revision r1, the scattering draw material for each effect, or change it. Its patch
   and shader wait in `tools/tuning/r1/`, outside `game/`, so nothing imports or exports them,
   and they change nothing until applied with
   `python3 -I tools/tuning/r1/apply_r1.py tools/tuning/r1/scatter_particle.gdshader`:
   - it adds `game/effects/scatter_particle.gdshader`;
   - it swaps each effect's draw material;
   - it teaches `particle_readback.gd` to check a shader material;
   - it updates the four configuration tests.
3. After r1: capture `scripts/capture-strips.sh 1`; Claude Code compares; the author judges in
   the game.
4. r2 is proposed after r1's strips, for the sizes and counts the brief's own scale asks for: A1's
   drops at 2–5 px and B2's plume to 0.5–0.8 m.

**Unverified:**

- How the effects look in the record: no strip has been captured by the author yet.
- The GPU price: Godot's GPU timer read 0 on Metal in Run 17.
- The tailpipe's position (revision 2).

## Assignment 6, step 1: the old brief moved, and the brief template (approved: #138)

**The effects (C52):** A1 the wiper flick and A2 the roof spill on hard braking, both graded as
Effect A; B1 rain in every lamp's light and B2 exhaust vapour as Effect B. Real-life physics
throughout. Whether the B effects are graded is open.

**Files:**

- **Moved, unchanged:** `CHANGE-BRIEF.md` to `docs/PHASE_BRIEF.md` (SHA-256 `6ed86df9…`, the same
  as at `5d5ca7e`), committed as a rename on its own (`7bbf0a4`).
- **New:**
  - `CHANGE-BRIEF.md`: the Assignment 6 template, headings only, for the author's text;
  - `docs/PARTICLE_RESEARCH.md`: facts from the code, published numbers and Godot 4.7.2's
    property names, for the author's brief. It is not the brief.
- **Changed:** `docs/AUTHOR_PROMPTS_AND_DECISIONS.md` (#131–#138), `docs/DESIGN_DECISIONS.md`
  (C52) and this file.

**Tests:** none run. Only documents changed. Nothing in the game, tests or tools reads the
brief's contents; three checks name it in their labels only (`test_materials.gd:111`,
`test_night_dimming.gd:85`, `check_first_drive_art.py:136,247`). The Assignment 6 baseline is
run with the test runner change, after the brief.

**What the next run may rely on:**

- `CLAUDE.md` still imports `@CHANGE-BRIEF.md`, which is now the Assignment 6 template. Its other
  mentions of the old brief's sections now mean `docs/PHASE_BRIEF.md`. The assignment's Step 1
  rewrites `CLAUDE.md`.
- The property names in `docs/PARTICLE_RESEARCH.md` §7 come from Godot 4.7.2's own API dump
  (`--dump-extension-api`, run with a scratch home in Claude Code's scratch folder).

**Unverified:**

- Everything marked "estimate" or "suggestion" in `docs/PARTICLE_RESEARCH.md`.
- Whether the Visual Profiler shows GPU time on Metal (Run 17 found Godot's GPU timer at 0).

**Next, each step approved on its own:**

1. The author writes the brief and commits it as the author's own commit, before any agent
   prompt.
2. The test runner: `realtime` mode and a timeout argument added, keeping the scratch home and
   the save-folder check, and failing when the test file does not exist. Then the baseline.
3. The assignment's Step 1: `CLAUDE.md`, from the author's `claude -p` run.

**No tag yet (#139):** `a6` goes on the final submission commit only, after the film records
and a fresh clone of that commit passes every test.

## Phase 2, step 1b: missions in a row, and the progress file's version 2 (approved: #129)

**Files:**

- **New:**
  - `game/features/missions/the_wrong_cargo/the_wrong_cargo.gd` and its `.uid`: Mission 2's name,
    places, checkpoint check, start save and title scene. Nothing in it is playable yet;
  - `game/tests/test_mission_two.gd` and its `.uid`: 7 checks.
- **Changed:**
  - `game/shared/save/save_file.gd`: `read(valid, upgrade)`, the upgrade step;
  - the Night Freight mission script: version 2, `_upgrade()`, `handed_on`, Mission 2's check by
    name, and finishing into Mission 2's start;
  - `game/app/first_drive.gd`: `cargo`, `_mission`, `_pick_mission()` and `_has_progress()`. The
    title, Continue, pause, Recover van and the start follow the current mission;
  - `driving_hud.gd`: `_eyebrow` and `set_mission()`;
  - `test_save_rules.gd` (29 checks) and `test_collision.gd` (44), with the reasons in
    `CHANGE-BRIEF.md`.
- **Docs:** `CHANGE-BRIEF.md`, this file and #129.

**What the next run can rely on:**

- **Versions:** progress is version 2 (`PROGRESS_VERSION` in Mission 1); settings stay version 1.
- **Reading:** `SaveFile.read(valid, upgrade)` upgrades an older file in memory, one version at a
  time, then reads the version again. The file on disk is rewritten only at the next checkpoint.
- **Which mission runs:**
  - Mission 1 (`$DrivingTrial`) still reads the progress file;
  - a Mission 2 save leaves Mission 1 `complete`, with the file in `handed_on`;
  - the app then runs Mission 2 (`cargo`, the `TheWrongCargo` node), and `_mission` is whichever
    is current.
- **Mission 2's interface,** as the app uses it:
  - `MISSION`, `NAME`, `START`, `TITLE_EYE`, `TITLE_LOOK` and `TITLE_FOV`;
  - `stage`, `recovery_pose` and `fleeing`;
  - `configure(van, config)`, `recover()`, `place_reached()` and `place_next()`;
  - the `objective_changed` signal;
  - the static `valid_progress()` and `start_progress()`, which Mission 1 calls. Mission 2 must
    not preload Mission 1, which preloads it.
- **For now,** every Mission 2 checkpoint starts the van in the depot bay.

**Commands and real results:**

| Command | Result |
| --- | --- |
| every suite before the build (`logs/phase_2/step1b/baseline/`) | all pass |
| the new and changed tests on the old code (`before/`) | `test_mission_two` 0/1, `test_save_rules` 26/29, `test_collision` 42/44; each exit 1 |
| the same three on the new code (in the agent's scratch folder) | 7/7 and 44/44; `test_save_rules` 28/29, because its launch check still expected version 1 |
| `test_save_rules.gd` once that check expected version 2 (scratch folder) | 29/29, exit 0 |
| `mutation_no_upgrade/`: Mission 1 reads without its upgrade step | 24/29, exit 1 |
| `mutation_name_unchecked/`: any `[cargo]` section taken as Mission 2 | 28/29, exit 1: "harbour_run" loads as Mission 2 |
| every suite (`suites/`) | all pass: 64/64, 0 failures, 92/92, 21/21, 12/12, 30/30 ×3, 25/25, 33/33, 12/12, 49/49, 21/21, 44/44, 12/12, 13/13, 12/12, 15/15, 29/29, 13/13, 20/20, 7/7; art 0 failures; the real save folder never changed |
| `HOME="$PWD/.scratch-home" Godot --headless --editor --path game --import` (`import/`) | exit 0, no errors or warnings; the two new `.uid` files; the real folder unchanged |

**Found, not changed:** `scripts/run-test.sh` exits 0 when the test file does not exist. The first
suite loop here ran under zsh, which gave every test a wrong name, and every run exited 0 with no
result line. Those logs were deleted and the suites run again with bash. A fix to the wrapper is
its own step.

**Not verified:**

- **Mission 2's title shot** was checked headless only, by the camera's place. It has not been
  seen in a window.
- **The author's checks** of saving and the keyboard (Assignment 10) are still to come.

## Run 34: the front door, design A (approved: #123; C50)

**Files:**

- **New:**
  - `game/features/ui/menus/front_menu.gd`: the title, pause, settings, credits and "ask first"
    screens;
  - `game/features/ui/menus/menu_blur.gdshader`: the blur behind every screen but the title;
  - `game/tests/test_menus.gd`: 20 checks;
  - `tools/captures/capture_menus.gd`.
- **Changed:**
  - `driving_hud.gd`: the old panel is gone. It builds the front menu and keeps the settings
    logic, and gains `show_title()`, `show_pause()` and `reveal()`;
  - `game/app/first_drive.gd`: the title camera and scene, the title's choices, back to the title
    in place, and the pause facts;
  - the mission script: `NAME`, `TITLE_EYE`, `TITLE_LOOK` and `TITLE_FOV`, `reload()`, and the new
    objective line;
  - `van_presentation.gd`: `settle()`;
  - `driving_audio.gd`: `title_ambience()`;
  - `test_collision.gd`: three checks, with the reasons in `CHANGE-BRIEF.md`.
- **Docs:** `CHANGE-BRIEF.md`, this file, C50, #122–#123 and `docs/AUDIO.md`.
- **Evidence:** `evidence/phase_1/menu/run34/` (`menu_sheet.png`). The mockups are on the private
  canvas https://claude.ai/artifact/KMksj4rmd9VUdFjXt7koKN.

**What the next run can rely on:**

- **Launch:** the app opens on the title, paused. `_resume()` and `resume_requested` still start the
  drive the old way, so the tests that skip the menu are unaffected.
- **The menu's API:**
  - `hud.menu` is the front menu. `screen()` names the open screen: "title", "pause", "settings",
    "credits", "confirm", or "" when it is closed.
  - Its signals are `continue_chosen`, `new_game_chosen`, `resume_chosen`, `recover_chosen`,
    `main_menu_chosen`, `quit_chosen` and `settings_left`.
- **Each mission's title scene** is `TITLE_EYE`, `TITLE_LOOK` and `TITLE_FOV`, around its
  `START`. Mission 2 needs the same three.
- **Back to the title:** `_back_to_title()` resets the session and calls the mission's `reload()`.
  The ending uses it too.
- **The volumes** move 5% per ← or →, through the menu's own handler. Godot 4.7's HSlider has no
  keyboard-step setting.
- **Windowed captures** of the menus draw each still themselves (`RenderingServer.force_draw`),
  because macOS stops drawing a covered Godot window.

**Commands and real results:**

| Command | Result |
| --- | --- |
| every suite before the build (`logs/phase_1/run34/baseline/`) | all pass |
| `LOG_DIR=logs/phase_1/run34/before scripts/run-test.sh test_menus.gd 60` | 0/1, exit 1: the HUD had no front menu |
| `LOG_DIR=logs/phase_1/run34/suites scripts/run-test.sh test_menus.gd 60` | 20/20, exit 0 |
| `mutate_run34.py` (in the agent's scratch folder; logs in `logs/phase_1/run34/mutation_*`) | no focus 4/20; unnamed slider 19/20; Esc on the title starting the game 12/20; title camera not current 17/20; each exit 1 |
| every suite (`logs/phase_1/run34/suites/`) | all pass: 64/64, 0 failures, 92/92, 21/21, 12/12, 30/30 ×3, 25/25, 33/33, 12/12, 49/49, 21/21, 44/44, 12/12, 13/13, 12/12, 15/15, 26/26, 13/13, 20/20; art 0 failures |
| `HOME="$PWD/.scratch-home" Godot --headless --editor --path game --import` (`import/`) | exit 0, no errors or warnings; three new `.uid` files; the real folder unchanged |
| `HOME="$PWD/.scratch-home" Godot --path game --script ../tools/captures/capture_menus.gd -- ../evidence/phase_1/menu/run34` (windowed) | ten stills and `menu_sheet.png`; two earlier tries stalled while the window was covered |

**Not verified:**

- **The author's checks** (Assignment 10): start, play, pause and quit by keyboard alone, and what a
  screen reader announces, if tried. The save check (#110) is also still to come.
- **Frame rate:** not measured on the title or pause screens.
- **Fonts:** DIN Condensed and SF Pro are system fonts. They were seen in the windowed stills, but
  not on another Mac.

## Run 33, step 2: the passenger mirror turned toward the driver (approved: #120; C49)

**Files:**

- `van_presentation.gd`:
  - `MIRROR_HEAD`, `MIRROR_ARM`, `MIRROR_TURN` and `_turn_passenger_mirror()`;
  - the passenger holder's transform;
  - the mirror camera's pose turned into its holder's frame.
- `game/tests/test_mirrors.gd` (13 checks).
- `tools/captures/capture_mirrors.gd`, now with passenger views.
- Docs: `CHANGE-BRIEF.md`, this file, C49 and #120.
- Evidence: `evidence/phase_1/mirror/run33_step2_proposal/` and `run33_step2/`.

**What the next run can rely on:**

- **The door mesh:** `PassengerDoor`'s mesh is rebuilt when the van is built, without the mirror
  head. The head is `PassengerMirrorHead`, a sibling under the `Iveco` node, turned 25° about the
  arm's root (`_passenger_turn`).
- **Triangle counts** under the `Iveco` node are unchanged.
- **The passenger reflection's holder** (`PassengerMirror`) carries that turn. Mirror camera poses
  are built in their holder's frame, so any future turned holder works too.

**Commands and real results:**

| Command | Result |
| --- | --- |
| `LOG_DIR=logs/phase_1/run33/step2_before scripts/run-test.sh test_mirrors.gd 60` | 11/12, exit 1: 48 of 101 in sight, 65° off its face |
| after the turn, aim check extended (`step2_aim_before/`) | 12/13, exit 1: the passenger mirror looked 29.7° into the van's side |
| after turning the view into the holder's frame (`step2_first/`) | 13/13: 62 of 101, 42°; passenger aim 4.7° inside to 10.6° outside |
| `mutation_passenger_not_turned`, `mutation_view_not_turned` | each 12/13, exit 1 |
| every suite (`step2_suites/`) | all pass, the same counts as step 1 with mirrors 13/13; art 0 failures |
| `capture_mirrors.gd -- ../evidence/phase_1/mirror/run33_step2` (windowed, on battery) | `passenger_mirror_sheet.png`; 70.2 FPS at the start, 75.3 FPS with a van behind |

**Not verified:** the author's look in play. At night the passenger mirror mostly reflects dark
forest; the van's lit right side, along its inner edge, is mostly behind the door frame.

## Run 33: real door mirrors and the yard gravel at real size (approved: #119; C48)

**Files:**

- `game/features/vehicles/freight_van/van_presentation.gd`:
  - `_mirrors()`, `_mirror()`, `_glass_piece()`, `_field()`, `_reflection()`,
    `_reflected_light()`: the reflections, their cameras and their lighting;
  - `_tail_glow_lights()`: the tail lamps' glow;
  - the mirror schedule in `update_vehicle()` (`MIRROR_RATES`, `REVERSE_RATE`,
    `mirror_updates`);
  - the reverse camera's cull mask (7);
  - removed: `MIRROR_CAMERA`, `MIRROR_GLASS` (the old position), `MIRROR_GLASS_SIZE`,
    `WIDE_GLASS`, `WIDE_GLASS_SIZE`, `MIRROR_UPDATES_PER_SECOND`, `_mirror_glass()`,
    `_mirror_timer` and `_mirror_turn`.
- New in the van's folder:
  - `mirror_glass.gdshader`, the glass;
  - `mirror_glass.gd`, the rule that finds the mirror glass in the model;
  - `art/iveco/mirror_glass_left.tres` and `mirror_glass_right.tres`, the glass it found.
- `game/features/environments/industrial_loop/industrial_loop.gd`: `MOON_LAYER`; the probe's cull
  mask; the yard and forecourt gravel projected in metres.
- New tools:
  - `tools/art/extract_mirror_glass.gd` makes the two `.tres` files;
  - `tools/captures/capture_mirrors.gd` takes the evidence.
- Tests:
  - new `game/tests/test_mirrors.gd` (11 checks);
  - `game/tests/test_cockpit.gd` (25) and `game/tests/test_dash_screen.gd` (15), with the reasons
    in `CHANGE-BRIEF.md`.
- Docs: `CHANGE-BRIEF.md`, this file, `PERFORMANCE.md`, C48 and #119.
- Evidence: `evidence/phase_1/mirror/run33_options/`, `run33_fix/` and `run33/`.

**What the next run can rely on:**

- **Viewports and cameras:** `mirrors` holds the two door-mirror viewports, driver's first. Each has
  one HDR camera with its own linear-tonemapped copy of the world's lighting. `mirror_cameras`
  holds the reverse camera first, then the two mirror cameras; each camera's pose follows its
  frame in `_mirror_frames`.
- **Glass and layers:** the reflections are `MainGlass` and `WideGlass` under `DriverDoorGlass`
  and `PassengerMirror`, on render layer 8 (`MIRROR_LAYER`). They are hidden while the van is not
  occupied. The driving camera's cull mask is 15.
- **The moon** is on render layer 4. A camera that should see moonlight must draw layer 4; the
  door-mirror cameras do not.
- **Rebuilding the glass:** if the Iveco model is converted again, rerun
  `Godot --headless --path game --script ../tools/art/extract_mirror_glass.gd` (with the scratch
  home). `test_mirrors.gd` fails if the saved glass no longer matches the model.
- **Spotlights on the van:** besides the headlights (forward), the reversing lamps (white, back)
  and the tail glow (red, back, `TailGlowLeft` and `TailGlowRight`).

**Commands and real results:**

| Command | Result |
| --- | --- |
| `HOME="$PWD/.scratch-home" Godot --headless --path game --script ../tools/art/extract_mirror_glass.gd` | 55 main and 46 wide-angle triangles per door, both saved |
| `LOG_DIR=logs/phase_1/run33/before scripts/run-test.sh test_mirrors.gd 60` | 0/11, exit 1 |
| the same after (`first/`, `check/`) | 11/11 |
| five mutations (`mutation_ldr_screen`, `mutation_straight_back`, `mutation_moon_in_mirrors`, `mutation_stretched_gravel`, `mutation_shown_from_outside`) | each 10/11, exit 1, failing only its own check |
| every suite (`suites/`) | 64/64, 0 failures, 92/92, 21/21, 12/12, 30/30 ×3, 25/25, 33/33, 12/12, 49/49, 21/21, 44/44, 12/12, 13/13, 12/12, 15/15, 26/26, 11/11; art 0 failures; the real save folder unchanged |
| `HOME="$PWD/.scratch-home" Godot --headless --editor --path game --import` (`import/`) | exit 0, no errors or warnings; only three new `.uid` files; the real folder unchanged |
| `HOME="$PWD/.scratch-home" Godot --path game --script ../tools/captures/capture_mirrors.gd -- ../evidence/phase_1/mirror/run33` (windowed, on battery) | 11 stills and `mirrors_sheet.png`; 69.8 FPS at the start, 74.8 FPS with a van behind |
| the prototypes' frame times, in one session on battery | today's mirrors 12.40 ms, the new ones 13.25 ms (+0.85); the driver's mirror every frame +3.7 ms |

**Not verified:**

- the author's look at the mirrors in play;
- the frame rate on mains power;
- the passenger mirror from the seat, which is mostly hidden: it sits just past the front edge of
  the passenger window (#120).

## Run 32: reversing lamps and a working reverse camera (approved: #118; C47)

**Files:**

- `van_presentation.gd`: `REVERSE_LENS`, `REVERSE_LAMP`, `REVERSE_ENERGY`, `REVERSE_RANGE`,
  `REVERSE_GAIN`, `_reversing_lamps()`, and the reverse camera's `CameraAttributesPractical`.
- `game/tests/test_dash_screen.gd` (15 checks) and `game/tests/test_headlights.gd`, which counts
  only forward-pointing lights as headlights.
- Evidence: `evidence/phase_1/dash/run32/`.

**What the next run can rely on:**

- In reverse with the engine running, `ReversingLenses` (on the van's body) glows, and two backward
  `SpotLight3D`s are visible. In drive both are hidden.
- The reverse camera's exposure is 3x.
- Tests that look for spotlights on the van must now tell headlights (pointing forward) from
  reversing lamps (pointing back).

**Commands and real results:**

| Command | Result |
| --- | --- |
| `LOG_DIR=logs/phase_1/run32/before scripts/run-test.sh test_dash_screen.gd 60` | 14/15, exit 1: 0 lamps, 1.0x |
| the same after (`first/`) | 15/15 |
| lamps kept off (`mutation_lamps_off/`) | 14/15, exit 1 |
| the first full run | `test_headlights.gd` 21/29 (it took all four spotlights for headlights); `test_cockpit.gd` 24/25 (the lens copy sat inside the converted model) |
| after moving the lens copy to the body and selecting forward lights; every suite (`suites/`) | 64/64, 0 failures, 92/92, 21/21, 12/12, 30/30 ×3, 25/25, 33/33, 12/12, 49/49, 21/21, 44/44, 12/12, 13/13, 12/12, 15/15, 26/26; art 0 failures |
| `capture_dash_screen.gd -- evidence/phase_1/dash/run32` | the reverse picture's mean brightness 26.6 before, 45.0 after |

**Unverified:** the rear of the van in reverse seen from outside, in a window.

## Run 31: back onto the road, the van on the forecourt, bay 2, kerbs (approved: #117; C46)

**Files:**

- **`industrial_loop.gd`:**
  - `SHOULDER` and `_shoulder()`: the verge's sloping outer edge;
  - `FORECOURT`, `VAN_PARKING`, the forecourt's gravel and clearing;
  - the floodlight aimed at the van.
- **Mission `first_drive.gd`:** `START` on the forecourt (568, -0.02, 123.5), facing west; the run
  sheet says bay 2.
- **`navigation_display.gd`:** bay 2.
- **`driver.gd`:** `STEP_REACH`, `STEP_HOLD`, `_step_top` and `_hold_step()`.
- **Tests:** `test_ghat_road.gd` (33 checks) and `test_on_foot.gd` (49 checks).
- **Evidence:** `evidence/phase_1/start/run31/`.

**What the next run can rely on:**

- **The road's edge:** the shoulder slopes into the ground, so nothing gets stuck coming back onto
  the road on flat stretches.
- **The start:** the van starts on the forecourt, out of the lane. Every suite, both Assignment 5
  suites included, passes with it.
- **Ethan's step:** he climbs steps up to 30 cm in one rise; 50 cm stops him.
- **Next, waiting for the author's OK:**
  - **reverse camera:** white reversing lamps and a low-light camera;
  - **mirrors:** real reflections instead of self-lit screens.

**Commands and real results:**

| Command | Result |
| --- | --- |
| off-road probe at samples 40, 120, 330, 640 and 760, both sides (before) | stuck at 40 and 120, blocked by the verge strip with a level normal |
| `LOG_DIR=logs/phase_1/run31/before scripts/run-test.sh test_ghat_road.gd 60` | 31/32, exit 1: the van stays off the asphalt on both sides |
| the same after the shoulder (`first/`), and the probe | 32/32; back on the asphalt in 3.5–6 s at 40 and 120 |
| step probe at 10–30 cm, before and after `_hold_step()` | before: 20–30 cm bobbed; after: one rise each |
| `test_on_foot.gd`, with the step removed (`mutation_no_step/`) | 48/49, exit 1 |
| every suite, with `LOG_DIR=logs/phase_1/run31/suites` | 64/64, 0 failures, 92/92, 21/21, 12/12, 30/30 ×3, 25/25, 33/33, 12/12, 49/49, 21/21, 44/44, 12/12, 13/13, 12/12, 14/14, 26/26; art 0 failures |

**Unverified:** pulling out of the forecourt by hand in a window, and puddles under the street lamps
near the depot.

## Run 30: low beams reach about 40 m, high beams further (approved: #115; C45)

**Files:**

- **Changed:**
  - `tools/make_low_beam_pattern.py`: `CUTOFF_ABOVE_AXIS` 0.6, `STRAY` 0.02;
  - both beam images, regenerated;
  - `van_presentation.gd`:
    - `LOW_BEAM_RANGE` 70 and `HIGH_BEAM_RANGE` 260;
    - `LOW_BEAM_ENERGY` 650 and `HIGH_BEAM_ENERGY` 850, set by `_aim_beam()`;
  - `game/tests/test_headlights.gd`: `_check_reach()` and the high-beam check (21 checks).
- **Evidence:** `evidence/phase_1/beams/run30_options/` and `evidence/phase_1/beams/run30/`.

**What the next run can rely on:**

- **Low beams:** they light the road to about 37 m, measured where the light falls to a tenth, and
  fade out by 70 m.
- **High beams:** 850 against 650, with a reach of 260 m.
- **The road beyond 50 m** at the start straight reads 29.1 on low beams and 106.1 on high beams;
  lights off, it reads 24.6.

**Commands and real results:**

| Command | Result |
| --- | --- |
| `LOG_DIR=logs/phase_1/run30/before scripts/run-test.sh test_headlights.gd 60` | 19/21, exit 1: 63 m and 120 m; 220 m with 650 against 650 |
| the same after (`logs/phase_1/run30/first/`) | 21/21: 37 m, fading out by 70 m; 260 m with 850 against 650 |
| the committed images and the 120 m reach put back (`mutation_old_reach/`) | 19/21, exit 1 |
| every suite, with `LOG_DIR=logs/phase_1/run30/suites` | 64/64, 0 failures, 92/92, 21/21, 12/12, 30/30 ×3, 25/25, 31/31, 12/12, 48/48, 21/21, 44/44, 12/12, 13/13, 12/12, 14/14, 26/26; art 0 failures |
| `capture_beams.gd -- evidence/phase_1/beams/run30` | low 80.8/29.1, high 144.1/106.1, off 18.3/24.6; white-out 0.00% |

**Unverified:** the author's look in motion, and the frame rate on mains power.

## Run 29: low beams shaped like real ones, and wet bark (approved: #113–#114; C44)

**Files:**

- **Changed:**
  - `tools/make_low_beam_pattern.py`: the new horizontal and vertical fades, and `STRAY` 0.03;
  - `game/features/vehicles/freight_van/art/low_beam_pattern.png` and `high_beam_pattern.png`,
    regenerated in that order;
  - `roadside_forest.gd`: `WET_BARK` 0.6 for the mature trunks;
  - `game/tests/test_headlights.gd`: `_check_low_beam_shape()` and `_check_wet_bark()` (19 checks).
- **Evidence:**
  - `evidence/phase_1/beams/run29_options/` (the options shown to the author);
  - `evidence/phase_1/beams/run29/` (the standard beam measurements);
  - `evidence/phase_1/collision/run29/` (the crossing, and the man in the road before and after).
- **Docs:** `CHANGE-BRIEF.md` (Run 29), `docs/DESIGN_DECISIONS.md` (C44) and the prompt log
  (#113–#114).

**What the next run can rely on:**

- **The low beam:**
  - at 20° to the side it gives 21% of its centre, and 6% on the ground just ahead;
  - the road on straights is as bright as before; on bends it is about a fifth dimmer;
  - after any change to the generator, regenerate the low pattern, then the high one, then run
    the headless import with `HOME="$PWD/.scratch-home"`.
- **The bark:** mature trunks are drawn at 60% for the rain.

**Commands and real results:**

| Command | Result |
| --- | --- |
| `LOG_DIR=logs/phase_1/run29/before scripts/run-test.sh test_headlights.gd 60` | 17/19, exit 1: 50% at the side, 16% on the ground, bark 100% |
| `python3 -I tools/make_low_beam_pattern.py`, then `make_high_beam_pattern.py` | both images written; high beams 20.6x brighter at the horizon (it was 12.6x) |
| `HOME="$PWD/.scratch-home" Godot --headless --editor --path game --import` | exit 0, no errors; the real save folder unchanged |
| the same test after (`logs/phase_1/run29/first/`) | 19/19, exit 0 |
| the old beam images put back (`logs/phase_1/run29/mutation_old_beam/`) | 18/19, exit 1 |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run29/suites` | 64/64, 0 failures, 92/92, 19/19, 12/12, 30/30 ×3, 25/25, 31/31, 12/12, 48/48, 21/21, 44/44, 12/12, 13/13, 12/12, 14/14, 26/26; art 0 failures |
| `capture_beams.gd -- evidence/phase_1/beams/run29` | low 88.4/42.8, high 133.0/102.3, off 18.1/25.4; white-out 0.00% |
| `capture_collision.gd -- evidence/phase_1/collision/run29` | the man in the road keeps his dark clothes |

**Unverified:**

- **The author's look in motion,** in a window.
- **The frame rate on mains power.**

## Run 28: Ethan steps up road edges and kerbs (approved: #112)

**Files:**

- **Changed:**
  - `driver.gd`: `STEP_HEIGHT` 0.3 m, `STEP_PROBE` 0.1 m, `_step_up()` before each
    `move_and_slide()`, and `floor_snap_length` 0.3 m;
  - `game/tests/test_on_foot.gd`: `ROUND_THE_FRONT` and `_check_walk_to_van()` (48 checks).
- **Docs:** `CHANGE-BRIEF.md` (Run 28, with the play-test's eight gaps) and the prompt log
  (#111–#112).

**What the next run can rely on:**

- **On foot:** Ethan walks from the office to the driver's door by keyboard, up the road's 11 cm
  gravel edge, and E from 4 m away walks him round with no teleport. The scripted walk's
  stuck-then-arrive fallback (`_route_direction()`) is still there as a safety net.
- **What still stops him:** walls, barriers, the van and anything steeper than 45°.
- **The play-test gaps,** listed in `CHANGE-BRIEF.md` Run 28, are waiting for the author's
  approval, one step at a time. The suggested order is lighting (white trunks), then the start
  (the van in the yard, the bay number, the puddles), then gears and the hillside texture. The
  prototype wording goes with the keyboard-only menu.
- **The scratch probes** (`probe_van_approach.gd`, `probe_playthrough.gd`,
  `capture_playthrough.gd`, `probe_boarding.gd`) are in the agent's scratch folder, not the
  repository.

**Commands and real results:**

| Command | Result |
| --- | --- |
| the approach probe from 17 directions, before | stopped 2.6 m short from 15 directions; blocked by the verge strip's collision (contact normal y 0.64) |
| a headless play-through by key presses | the whole drive completes; Ethan stuck 5.85 m from the door; E from 4.15 m, then a teleport |
| the same drive in a window (21 screenshots) | the eight gaps in `CHANGE-BRIEF.md` Run 28 |
| `LOG_DIR=logs/phase_1/run28/before scripts/run-test.sh test_on_foot.gd 60` | 47/48, exit 1: 5.85 m from the door |
| the same after the fix (`logs/phase_1/run28/first/`) | 48/48, exit 0: 0.30 m from the door after 9.1 s, up 0.11 m |
| with `_step_up()` removed (`logs/phase_1/run28/mutation_no_step/`) | 47/48, exit 1 |
| the approach probe after the fix; the boarding probe | the van's body reached from every direction; boarding from 4 m in 7.9 s, largest step 3.8 cm |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run28/suites` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31, 12/12, 48/48, 21/21, 44/44, 12/12, 13/13, 12/12, 14/14, 26/26; art 0 failures |

**Unverified:**

- **The author's checks:** walking to the van in a window, then the save check (quit at a
  checkpoint, relaunch, continue).
- **Other low edges** (the bus stop pad, plot edges) are covered by the same step height, but only
  the road's edge and the office were walked.

## Run 27: saving, built to the save rules (approved: #110; C43)

**Files:**

- **New:**
  - `game/shared/save/save_file.gd` (the rules: version first, whole-file check through the
    caller's `valid` callable, `.corrupt`, newer files locked, `.tmp` then rename) and its `.uid`;
  - `game/tests/test_save_rules.gd` (26 checks) and its `.uid`.
- **Changed:**
  - mission `first_drive.gd`: `checkpoint_path` empty by default, `playable_area`,
    `progress_read`, `MISSION`, `PROGRESS_VERSION`, `_valid_progress()`, `_save_finished()`;
    `SAVE_PATH` is gone;
  - `driving_hud.gd`: `settings_path`, `load_settings()`, `save_settings()` on leaving the menu
    and on quitting, `warn()` and `warning()`, `_sliders` and `_defaults`; `SETTINGS_PATH` is
    gone;
  - `game/app/first_drive.gd`: `PROGRESS_PATH` and `SETTINGS_PATH`, given only when
    `get_tree().current_scene == self`; `_warn_about_progress()`;
  - `van_presentation.gd`: `NO_CRACK`, the crack point and seed set when the glass is made;
  - `game/tests/test_collision.gd`: 44 checks (the continue check uses the save kept after the
    hit; a new check for the end-of-drive save);
  - `scripts/run-test.sh`: `HOME=.scratch-home` and the real-folder fingerprint;
  - `.gitignore`: `/.scratch-home/`.
- **Docs:**
  - `CHANGE-BRIEF.md` (Run 27);
  - `TEST-REPORT.md` (a dated final-project section);
  - `CLAUDE.md`: the runner, the `HOME` fact and the T key (#101);
  - `docs/DESIGN_DECISIONS.md` (C43);
  - the prompt log (#110).

**What the next run can rely on:**

- **The save files:**
  - the real files are `user://progress.cfg` and `user://settings.cfg`, used only when the app is
    the scene Godot launched. A game built by a test saves nothing unless the test sets
    `checkpoint_path` or the HUD's `settings_path`;
  - the old `driving_prototype.cfg` and `driving_audio.cfg` are never read or deleted.
- **The runner:** `scripts/run-test.sh` keeps every run out of the real save folder. Captures run
  by hand should use `HOME="$PWD/.scratch-home"` too.
- **Adding to a save file:** add the new values to the save's validator and raise its version
  (`PROGRESS_VERSION` or `SETTINGS_VERSION`). A file of the old version then needs an upgrade
  step in `save_file.gd`'s `read()`; today a version below the current one counts as damaged.
- **Mission 2:** today the mission's validator accepts only `night_freight`. The app must read
  `[save] mission` before choosing a mission, or an M2 save would be set aside as damaged.

**Commands and real results:**

| Command | Result |
| --- | --- |
| a script printing `OS.get_user_data_dir()`, with `HOME="$PWD/.scratch-home"` (`logs/phase_1/run27/home_check/`) | `user://` is `.scratch-home/Library/Application Support/Godot/app_userdata/Blackridge- No Way Back` |
| `test_wipers.gd` through the old runner, the real folder listed before and after (`logs/phase_1/run27/before_isolation/`) | Godot's logs in the real folder rotated; `driving_prototype.cfg` unchanged |
| every suite through the new runner on the unchanged game (`logs/phase_1/run27/baseline/`) | all pass, as in Run 26; no "REAL SAVE FOLDER CHANGED" |
| `LOG_DIR=logs/phase_1/run27/before scripts/run-test.sh test_save_rules.gd 60` | 4/26, exit 1 |
| the same after the build (`logs/phase_1/run27/first/`), with the regression suite | 26/26 and 64/64, exit 0 |
| three mutations of the save code (`logs/phase_1/run27/mutation_*`) | all exit 1: 24/26, 21/26, 21/26 |
| the first full run | `test_collision.gd` 41/42: its continue check read the save after the depot, which now holds the start |
| `test_collision.gd` after its change (`logs/phase_1/run27/collision_fix/`); with no end-of-drive save (`mutation_no_end_save/`) | 44/44, exit 0; 43/44, exit 1 |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run27/suites` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31, 12/12, 46/46, 21/21, 44/44, 12/12, 13/13, 12/12, 14/14, 26/26; art 0 failures; the only "ERROR:" lines are "resources still in use at exit" and the expected parse error |
| `HOME="$PWD/.scratch-home" Godot --headless --editor --path game --import` (`logs/phase_1/run27/import/`) | exit 0, no errors or warnings; only the two new `.uid` files; the real folder unchanged |
| the main scene launched headless with `--quit-after 30`, a damaged `progress.cfg` in the scratch home (`logs/phase_1/run27/real_launch/`) | set aside as `progress.cfg.corrupt`, with the warning |

**Unverified:**

- **The author's check:** drive to a checkpoint, quit, relaunch, continue.
- **The menu with a warning on it,** in a window: the panel grows downward, which may crowd a
  1280×800 window when both warnings show. The keyboard-only menu step will lay it out.
- **Settings on Cmd+Q:** saving on quit relies on Godot sending the close request, which the
  test sends directly.

## Run 26, step 2: the pedestrian scene waits for Maya's call (approved: #102; C41)

**Files:**

- **Changed:**
  - mission `first_drive.gd`: the encounter starts only when `not phone_call.active`;
  - mission `phone_call.gd`: `RINGS` 4 (was 6), `CALL_BACK` 2.0 (was 8.0);
  - `game/tests/test_maya_call.gd`: `_check_fits()`, `_check_scene_waits()` and `_coast()`
    (13 checks).
- **Docs:**
  - `CHANGE-BRIEF.md` (Run 26 step 2);
  - `docs/DESIGN_DECISIONS.md` (C41);
  - the prompt log (#102).
  - The Run 26 notes now give the old worst case as 80.3 s. The talk is 33.5 s, not 34 s.

**What the next run can rely on:**

- **The call's worst case:** a call ignored twice ends 59.5 s after its first ring. Flat out, the
  van cannot reach the encounter's first sample (680) in less than 62.0 s. `test_maya_call.gd`
  recomputes both numbers from the code, so any change to the call, the lines, the road or the
  van's top speed is checked.
- **The scene waits:** while any call is active, the encounter does not start.

**Commands and real results:**

| Command | Result |
| --- | --- |
| scratch probe, flat out from the lumber yard, never answering (`logs/phase_1/run26/step2/flat_out/before.log`) | call rang 18.0 s, picked up 64.8 s; encounter started 88.8 s with the call active |
| the same probe after the fix (`flat_out/after.log`) | call ended 77.6 s; encounter started 88.8 s with no call |
| `LOG_DIR=logs/phase_1/run26/step2/first scripts/run-test.sh test_maya_call.gd 60` | 13/13, exit 0 |
| two mutations (`logs/phase_1/run26/step2/mutation_*`) | both exit 1: the scene not waiting 12/13; the old pacing 12/13 (80.3 s against 62.0 s) |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run26/step2/suites` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31, 12/12, 46/46, 21/21, 43/43, 12/12, 13/13, 12/12, 14/14; art 0 failures; only "resources still in use at exit" ERROR lines |

**Unverified:**

- **The new ring pacing in play:** whether four rings and a 2 s call-back feel right.

## Run 26: the dash screen, built into the van (approved: #99–#101; C40)

**Files:**

- **New:**
  - `game/features/vehicles/freight_van/parking_guides.gd`, the reverse camera's guide lines;
  - `game/tests/test_dash_screen.gd` (14 checks);
  - `tools/captures/capture_dash_screen.gd`;
  - `parking_guides.gd.uid` and `test_dash_screen.gd.uid`, which the import created.
- **Rewritten:**
  - `navigation_display.gd`, the final design at 768 × 400;
  - mission `phone_call.gd`: rings until answered, missed calls, the call-back and the third call
    answering itself.
- **Changed:**
  - `van_presentation.gd`:
    - the map's place and size, measured from the cab model (`MAP_SCREEN`, `MAP_SIZE`, `MAP_TURN`);
    - `MAP_PIXELS` and `REVERSE_PIXELS`;
    - `_cover_screen()` (the black cover) and `_screen_glass()` (the glass and the glow);
    - `_lcd()`, and the start-up fade (`_screen_power`, `BOOT_SECONDS`);
  - `cockpit_screen.gdshader` (in the van's folder): `power`, `border`, `black_level` and
    `view_falloff`, neutral by default, so the gauges and mirrors are unchanged;
  - `freight_van.gd`: `clock`, `clock_text()` and `reset_clock()`;
  - `instruments.gd`: the gauges show `clock_text()`;
  - mission `first_drive.gd`: no `destination` or `instruction` for the map; "New drive" resets
    the clock;
  - `game/app/first_drive.gd`: the map follows the road to the depot; the call's `missed` and
    `connected` signals; T answers; the hint "T  Answer the call";
  - `driving_audio.gd`: `stop_ringing()`;
  - `driving_hud.gd`: the pause menu lists "T   Answer a call";
  - `game/project.godot`: the `answer_call` action on T (#101);
  - tests: `test_maya_call.gd` (11 checks, 180 s limit) and `test_ghat_road.gd` (the map check).
- **Docs:**
  - `CHANGE-BRIEF.md` (Run 26);
  - `docs/DESIGN_DECISIONS.md` (C40);
  - the prompt log (#98–#101).

**What the next run can rely on:**

- **The map:**
  - `navigation.follow(road, depot, start)` once per world;
  - after that it reads only `vehicle` and the road.
  - **Its state is public:** `route_index`, `to_turn` (metres along the road),
    `seconds_left`, `next_hairpin` (−1 when none within 150 m), `wrong_way`, `arrived`,
    `progress`, `map_yaw`, `map_scale` and `drawn_road`.
- **The call** (`phone_call.gd`):
  - `answer()` works only while `can_answer()`;
  - `answers_itself()` is true on the third attempt;
  - signals: `ringing`, `missed`, `connected`, `line_started` and `ended`.
  - The map shows it through `ring()`, `talk()`, `miss()` and `end_call()`.
- **The screen:**
  - the presentation's `_map_screen` and `reverse_screen` share `MAP_SCREEN`;
  - `_screen_power` runs from 0 to 1 over 1.2 s after the ignition.
- **The clock:** `FreightVan.clock` is in seconds and starts at 23:42; `reset_clock()` sets it
  back.

**Commands and real results:**

| Command | Result |
| --- | --- |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run26/suites` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31, 12/12, 46/46, 21/21, 43/43, 12/12, 11/11, 12/12, 14/14; art 0 failures; only "resources still in use at exit" ERROR lines |
| five mutations (`logs/phase_1/run26/mutation_*`) | all exit 1: old screen place 12/14 (26.9 mm overhang); straight-line distance 13/14; north-up map 13/14 (80.4° behind); first call answers itself 9/11; no call-back 10/11 |
| `capture_dash_screen.gd` (windowed, on battery) | exit 0, no ERROR lines; 10 stills, `dash_captures.txt` and `dash_sheet.png` in `evidence/phase_1/dash/run26/` |
| `Godot --headless --editor --path game --import` (`logs/phase_1/run26/import/`) | exit 0, no ERROR or WARNING lines; it created only the two `.uid` files, and `project.godot` is unchanged |

**Unverified:**

- **The author's own look and drive:** the screen from the seat, answering with T, and letting
  the call ring out.
- **A late call at speed:** with both calls missed, the conversation ended 80.3 s after the first
  ring, and a driver averaging over 52.8 km/h could still be on the call when the encounter
  started. Fixed in step 2.
- **The glass:** it catches a small bright reflection of the cab's fill light in close-ups.
- **The frame rate on power.**

## Run 25: the hit holds up at any speed (approved: #97; C39)

**Files:**

- **New:** `game/tests/test_hit_speeds.gd` (12 checks).
- **Changed:**
  - mission `first_drive.gd`: `LOCK_LOOK`, `_lock_lane`; `_watch_lock()` steers the locked van
    along its lane; `_watch_crossing()` aims at the van's lane offset;
  - `freight_van.gd`: `lock_curvature`, which sets the locked van's yaw, and `recover()` clears it;
  - `game/tests/test_collision.gd`: the skid's wheel check measures the lane (`LANE_HOLD`,
    `_lane()`) instead of the heading;
  - `tools/captures/capture_collision.gd`: an optional run speed after the folder, and a side
    camera that follows the van.
- **Unchanged:** `pedestrian.gd`. Two changes to the hit itself were tried and dropped
  (`logs/phase_1/run25/hit_sweep/`).
- **Docs:**
  - `CHANGE-BRIEF.md` (Run 25);
  - `docs/DESIGN_DECISIONS.md` (C39);
  - the prompt log (#97).

**What the next run can rely on:**

- **The lock:**
  - while `FreightVan.locked` is set, its yaw is `speed * lock_curvature`. The mission sets
    `lock_curvature` each tick, and the player's steering is ignored;
  - the lock runs from his first step to the impact, about one second.
- **The aim:** the impact point is the van's lane offset at the step-out, plus `IMPACT_RIGHT`.
- **Tests:** `test_hit_speeds.gd` places the van 60 m short of the crossing and holds its
  speed. The full encounter is covered by `test_collision.gd` and `test_crossing.gd`.

**Commands and real results:**

| Command | Result |
| --- | --- |
| `LOG_DIR=logs/phase_1/run25/before scripts/run-test.sh test_hit_speeds.gd 60`, on Run 24 step 3's code | exit 1, 7/12: at 45 km/h he ends 0.3 m behind the bumper; at 60 km/h no crack, 18.1 m behind |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run25/suites` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31, 12/12, 46/46, 21/21, 43/43, 12/12, 9/9, 12/12; art 0 failures; only "resources still in use at exit" ERROR lines |
| four mutations (`logs/phase_1/run25/mutation_*`) | all exit 1: straight lock 5/9; old aim 10/12; steering in the skid 18/40 (collision test); reversed limb limits 9/12 |
| hit sweep at 30–65 km/h, a scratch copy of the new test (`logs/phase_1/run25/hit_sweep/`) | before 18/32; push changes only 21/32 and 20/32; lane fix 28/32 with or without them (limb check only); final check 32/32 |
| encounter sweep, a scratch probe, approaches 5–18 m/s (`logs/phase_1/run25/encounter_sweep/`) | hits at 32–63 km/h, crack 1.00 every time, 0.93–1.07 s from step-out to hit, ahead of the van every time |
| `capture_collision.gd -- evidence/phase_1/collision/run25 15.3` (windowed, on battery) | exit 0, no ERROR lines; step-out 16.9 m ahead at 55 km/h, hit at 53 km/h, carried on the bonnet, lies 4.8 m ahead |

**Unverified:**

- **Limb spikes:** a knee or an elbow can still spike past its range for a single tick (up to
  −110° once). None lasts, and every resting pose is in range.
- **The author's own drive** at speed.
- **The frame rate on power.**

## Run 24, step 3: the crossing up the hill, the wheel given back, a checkpoint after the hit (approved: #96; C38)

**Files:**

- **New:** `game/features/audio/first_drive/skid.wav` and its `.import`.
- **Changed:**
  - `industrial_loop.gd`: `CROSSING_AT` is (64, -79), road sample 785;
  - mission `first_drive.gd`:
    - the encounter: `ENCOUNTER_STAGE` 3, `ENCOUNTER_SPAN`, `SPAWN_AT` 815, `MEETING_BEFORE`,
      `ETA_FLOOR`, `_entering_encounter()` (with the arrival check), `_time_the_meeting()`;
    - the step-out: `MIN_STEP_SPEED`, `STEP_HORIZON`, `IMPACT_RIGHT` and `_watch_crossing()`,
      which sets `vehicle.locked`;
    - the lock: `LOCK_PAST`, `_watch_lock()`, `_release_van()`;
    - after the hit: the post-hit checkpoint in `_save_checkpoint()` and `_load_checkpoint()`,
      and `vehicle.foot_on_brake` after the hold, a recovery and a load;
    - removed: C33's takeover (`_carry_on()`, `_stop_carrying()`, `CARRY_*`, `_stuck_for`);
  - `freight_van.gd`: `locked` with `LOCKED_GRIP`, and `foot_on_brake`, which `recover()` clears;
  - `pedestrian.gd`: `MIN_IMPACT`, `IN_PATH`, `_stop_at`, `lying_pose()`, `lie_as()`;
  - `van_presentation.gd`: `crack_state()`, `restore_crack()`;
  - `driving_audio.gd`: the skid (`skidding()`);
  - `game/app/first_drive.gd`: `_begin()` and `_continue_in_van()`;
  - `source_assets/audio/first_drive/synthesize.py`: `skid()`;
  - tests: `test_collision.gd`, `test_crossing.gd`, `test_oncoming_van.gd`,
    `game/tests/lane_keeper.gd`;
  - captures: `capture_collision.gd`, `capture_oncoming.gd`.
- **Docs:**
  - `CHANGE-BRIEF.md` (Run 24 step 3);
  - `docs/DESIGN_DECISIONS.md` (C38);
  - the prompt log (#96's outcome);
  - `docs/AUDIO.md` (19 sounds);
  - `CLAUDE.md` (the I key in the `project.godot` rule, #96).

**What the next run can rely on:**

- **The encounter:**
  - it runs in stage 3, from the second hairpin down;
  - the oncoming van starts at sample 815 and meets the player at sample 770;
  - he steps out at the crossing, sample 785, and the depot is 511 m on by road.
- **The lock:** `FreightVan.locked` is true from his first step until the impact, the stop, or
  10 m past the crossing.
- **Fleeing:** while `route.fleeing`, `FreightVan.foot_on_brake` keeps the van braked until a
  pedal, the handbrake or the wheel is touched.
- **The post-hit checkpoint:** it has the keys `recovery`, `body` and `crack` in section
  `drive`. The loader checks for them before reading.
- **Tests that drive to the crossing:**
  - set the stage to `Mission.ENCOUNTER_STAGE`;
  - start at sample 672 with `lane_keeper.gd`;
  - stay at about 8 m/s, where the hit holds up.

**Commands and real results:**

| Command | Result |
| --- | --- |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run24/step3/suites` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31, 12/12, 46/46, 21/21, 43/43, 12/12, 9/9; art 0 failures; only "resources still in use at exit" ERROR lines |
| seven mutations (`logs/phase_1/run24/step3/mutation_*`) | all exit 1: no lock 21/40; takeover back 1/5; steering in the skid 18/40; no post-hit checkpoint 40/42; continue on foot 42/43; spawn in view 7/8; no brake hold 40/43 |
| `capture_collision.gd -- evidence/phase_1/collision/run24_step3` (windowed, on battery) | exit 0, no ERROR lines; step-out at 36 km/h 21 m ahead, hit at 32 km/h, van held 4.7 m short of him after "DRIVE." |
| `capture_oncoming.gd -- evidence/phase_1/oncoming/run24_step3` (windowed, on battery) | exit 0, no ERROR lines; glare per lamp 0.38 at 110 m to 2.9 at 10 m; windshield brightness 98 to 157, then 44 |
| speed sweep (a scratch probe, `--fixed-fps 60`; `logs/phase_1/run24/step3/speed_sweep/`) | hits at 30–62 km/h; the crack at 30, 32, 37 and 46 km/h, none at 40, 54 and 62; under the van at 54 and 62 km/h; elbows past 30° the wrong way from 37 km/h |

**Superseded logs, kept:**

- `logs/phase_1/run24/step3/suites_before_loader_fix/`: the regression log shows the two
  checkpoint ERROR lines;
- `suites_before_brake_hold/`: the suites before the brake hold;
- `first/` and `first_hold/`: single-suite runs during the step.

**Unverified:**

- **Above about 36 km/h** the hit does not hold up:
  - an elbow flips from 37 km/h;
  - there is no crack at 40, 54 and 62 km/h;
  - from about 54 km/h he goes under the van.

  The tests run at 32 and 18 km/h.
- **The author's own drive** down the hill: how the lock and the skid feel, and whether 511 m is
  enough of a run.
- **The frame rate on power.**

## Run 24: fixes from the author's play test (approved: #95; C37)

**Files:**

- **New:**
  - `game/features/vehicles/freight_van/side_glass.gdshader` and `window_slide.gdshaderinc`;
  - `game/features/ui/driving_hud/van_guide.gd`;
  - `tools/captures/capture_play_fixes.gd`.
- **Changed:**
  - `van_presentation.gd`:
    - `_slide_into_door()`, the window drop and its uniforms;
    - the dome lamp: `_dome_lamp()`, `_light_the_cab()`, `cabin_lamp`;
    - `door_handle()`, `door_opening_toward()`;
    - `WINDOW_DROP` and `_window_rest` are gone;
  - `side_window_rain.gdshader`: the slide and the cut at the sill;
  - `freight_van.gd`: `cabin_light`, the I key, `door_handle()`, `door_opening_toward()`;
    `switch_off()` turns the lamp off;
  - `driver.gd`: `grip()`, `grip_point()` and the left-arm `TwoBoneIK3D`;
  - `game/app/first_drive.gd`:
    - the grip while getting in;
    - `_step_out()`, `_door_under_hand()`, `_clear()`;
    - `_guide_to_van()`;
  - `driving_hud.gd`: `van_guide`, and the controls list gains I;
  - `industrial_loop.gd`: `office_transform`;
  - `game/project.godot`: the `cabin_light` action on I, with the author's OK (#95);
  - tests:
    - `test_materials.gd`;
    - `tools/tests/first_drive_regression.gd`;
    - `tools/tests/first_drive_integration.gd`;
    - `test_on_foot.gd`.
- **Docs:** `CHANGE-BRIEF.md` (Run 24, the play-test fixes), `docs/DESIGN_DECISIONS.md` (C37),
  the prompt log (#95).

**What the next run can rely on:**

- **Lowering a window** sets `lowered` on the pane's `side_glass` material and its rain;
  the nodes stay where they are.
- **The exit:** E at a stop takes about 3.5 s through `_step_out()`. `_boarding` is true
  meanwhile, and tests wait for it to clear.
- **The cabin lamp:** it follows `vehicle.cabin_light` and the driver's door; `cabin_lamp` is
  the light.
- **The guide:** `hud.van_guide.shown()`, `distance()` and `label()` say what it shows.

**Commands and real results:**

| Command | Result |
| --- | --- |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run24/fixes/suites` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31, 12/12, 46/46, 21/21, 38/38, 12/12, 9/9; art 0 failures; only "resources still in use at exit" ERROR lines |
| five mutations (`logs/phase_1/run24/fixes/mutation_*`) | all exit 1: half drop 91/92; no grip 45/46; instant exit 42/46; lamp ignores door 44/46; no guide 45/46 |
| `capture_play_fixes.gd` (windowed) | exit 0; 14 stills in `evidence/phase_1/fixes/run24/` |

**Unverified:**

- How the exit and the hand on the handle look in the author's own play, from the third-person
  camera.
- `CLAUDE.md`'s `project.godot` rule does not yet name the I key. The wording is drafted for the
  author's OK.

## Run 24: the timber site office from Blender, and the yard floodlight (approved: #94; C36)

**Files:**

- **New:**
  - `tools/art/build_site_office.py` (Blender script);
  - `game/features/environments/industrial_loop/art/office/site_office.glb` and its `.import`;
  - five Poly Haven texture folders in `industrial_loop/polyhaven/textures/` (`weathered_plank_siding`
    2k; `corrugated_iron`, `rough_pine_door`, `stair_planks`, `brushed_concrete_03` 1k), with
    `.import` files set by `configure_imports.py`;
  - `tools/assets/site_office_assets.json`;
  - `tools/captures/capture_site_office.gd`.
- **Changed:**
  - `industrial_loop.gd`: `SiteOffice`, `OFFICE_TEXTURES`, `OFFICE_PAINT`, `LAMP_COLOR`,
    `FLOODLIGHT_COLOR`; `_site_office()`, `_office_material()`, `_office_lights()`; `_surface()`
    and `_texture()` take a resolution. `OFFICE_SIZE`, `OFFICE_RAISE` and `CLIPBOARD` are gone;
  - `tools/assets/fetch_polyhaven.py`: keeps the manifest's earlier rows;
  - `industrial_loop/polyhaven/POLYHAVEN.md`: five rows;
  - tests: `test_on_foot.gd` (5 checks), `tools/tests/check_first_drive_art.py` (office section).
- **Docs:** `CHANGE-BRIEF.md` (Run 24, the site office), `docs/DESIGN_DECISIONS.md` (C36), the
  prompt log (#94's outcome), `SOURCES.md` (five textures and the model).

**What the next run can rely on:**

- **Rebuilding the office:** `Blender -b --factory-startup --python-exit-code 1 --python
  tools/art/build_site_office.py` rebuilds the model to the same bytes.
- **Its parts:** the model's materials are named, and Godot replaces each one by name. Its
  markers are `RunSheet`, `NoticeLamp`, `Floodlight` and `WindowLight`. A light marker's local +Y
  in Blender is the light's -Z in Godot.
- **Placement:** the office stands at `SITE_OFFICE`, facing +Z (the road). In the game, the
  lights are its children `NoticeLight`, `FloodLight` and `WindowGlow`, and its collision is the
  bodies `Building` and `Landing`.
- **The run sheet:** `run_sheet_at` and `run_sheet_spot` keep their meaning: the clipboard, and
  where Ethan stands, on the ground.

**Commands and real results:**

| Command | Result |
| --- | --- |
| `Blender -b --factory-startup --python-exit-code 1 --python tools/art/build_site_office.py` ×3 | 3,448 triangles; the same SHA-256 each time (`4a056a5232ed...`) |
| `Godot --headless --editor --path game --import` | exit 0, no errors |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run24/office/suites` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31, 12/12, 36/36, 21/21, 38/38, 12/12, 9/9; art 0 failures; only "resources still in use at exit" ERROR lines |
| `test_on_foot.gd` with the office's collision removed | 35/36, exit 1 (`mutation_no_office_collision/`) |
| `test_on_foot.gd` with the floodlight turned away | 35/36, exit 1 (`mutation_floodlight_away/`) |
| `capture_site_office.gd` and `capture_on_foot.gd` (windowed) | both exit 0; `evidence/phase_1/start/run24_office/`; the van's brightness goes from 13.0 to 52.8 with the floodlight; no pure-white pixel |

**Unverified:**

- How the office and the floodlight look in the author's own play, on power.
- The driver's door is in the van's own shadow until the ignition. Whether that is too dark is
  the author's call.

## Run 24, step 2: the end-of-shift start and controls taught when needed (approved: #93; C35)

**Files:**

- **New:** `game/features/ui/driving_hud/drive_lessons.gd`.
- **Changed:**
  - `industrial_loop.gd`: `_site_office()`, `SITE_OFFICE`, `run_sheet_at`, `run_sheet_spot`;
  - the mission's `first_drive.gd`: `RUN_SHEET`, `RUN_SHEET_SIGNATURE`;
  - `driving_hud.gd`: `show_document()`, `sign_document()`, `hide_document()`,
    `document_visible()`, `document_text()`;
  - `game/app/first_drive.gd`: the start at the office, `_sign_run_sheet()`, `_needs_sheet()`,
    `_hint()`, `_teach_driving()`; `START_SPOT` and `START_FACING` are gone;
  - tests: `test_on_foot.gd`, `test_maya_call.gd`; capture: `capture_on_foot.gd`.
- **Docs:** `CHANGE-BRIEF.md` (Run 24, step 2), `docs/DESIGN_DECISIONS.md` (C35), the prompt log
  (#93 with the answers, the approved run sheet and the agreed list).

**What the next run can rely on:**

- **The start:** `_begin_on_foot()` puts Ethan at `world.run_sheet_spot`. `_needs_sheet()` is
  true only before the first boarding of a drive. Tests that start with `_resume()` skip it.
- **Hints:** `_hint()` decides each 0.2 s; lessons live in `DriveLessons` (`offer`, `learn`,
  `again`, `tick`). Hints are empty during boarding, the run sheet, the encounter, the hold,
  "DRIVE." and the ending.

**Commands and real results:**

| Command | Result |
| --- | --- |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run24/step2/suites` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31, 12/12, 31/31, 21/21, 38/38, 12/12, 9/9; art 0 failures; only "resources still in use at exit" ERROR lines |
| `test_on_foot.gd` with no run-sheet check at the van | exit 1 (`mutation_no_sheet_gate/`) |
| `test_on_foot.gd` with "14 pallets" changed to "12" | 29/31, exit 1 (`mutation_changed_sheet/`) |
| `capture_on_foot.gd` (windowed) | exit 0; `evidence/phase_1/start/run24_step2/start_sheet.png` |

**Unverified:**

- How dark the walk to the van feels in play (mean brightness 9 of 255 by the van).
- Whether the lessons appear at the right moments in a real drive (high beams, wipers, viewpoint).

## Run 24, step 1: Maya's call and the quiet ending (approved: #92 and its answers; C34)

**Files:**

- **New:**
  - `game/features/missions/night_freight/phone_call.gd`;
  - `game/tests/test_maya_call.gd`;
  - `tools/captures/capture_call.gd`;
  - `phone_ring`, `call_connect`, `call_end`, `breathing` and `engine_tick` WAVs with their
    `.import` files.
- **Changed:**
  - the mission's `first_drive.gd`: `MAYA_CALL` (the approved lines), `CALL_AT` 91,
    `CALL_SEARCH`, `phone_call`; the completion objective is empty; `_nearest_index()` takes a
    span;
  - `game/app/first_drive.gd`: the call wiring, the quiet ending (`ENDING_HOLD` 9 s,
    `ENDING_FADE` 3 s, `ENDING_BLACK` 2 s, a token against a new drive mid-ending), "Drive
    again"; `_exit_at_depot()` is gone;
  - `driving_hud.gd`: `show_subtitle()`, `clear_subtitle()`, `subtitle()`, `set_cinematic()`,
    `set_ended()`;
  - `navigation_display.gd`: `caller`, `call_seconds`, the call card;
  - `driving_audio.gd`: `ring()`, `answer()`, `hang_up()`, `breathe()`, `cool_down()`,
    `fade_out()`, `restore()`, the engine run-down;
  - `source_assets/audio/first_drive/synthesize.py`: the five sounds; the 13 older WAVs are
    byte-identical;
  - `test_collision.gd` (the depot part), `capture_collision.gd` (the ending stills).
- **Docs:** `CHANGE-BRIEF.md` (Run 24, step 1), `docs/DESIGN_DECISIONS.md` (C34), the prompt log
  (#91–#92 with the answers and Draft A verbatim), `docs/AUDIO.md` (18 sounds).

**What the next run can rely on:**

- **The call:** `route.phone_call` emits `ringing(caller)`, `connected`, `line_started(speaker,
  words)` and `ended`. `active` and `talking` say where it is; `elapsed` counts from the
  connection. The mission starts it once per drive in stage 0, at road sample 91.
- **The ending:** `drive_completed` now runs the quiet ending. While it plays, `_ending` is true;
  afterwards `_ended` is true, the tree is paused, and `_begin()` starts a new drive. Pause,
  recovery and E do nothing during or after it.
- **Pausing:** pause on a physics-frame boundary when code pauses from a timer, or a later
  resume during a physics step prints `Condition "p_elem->_root" is true`.

**Commands and real results:**

| Command | Result |
| --- | --- |
| `python3 -I source_assets/audio/first_drive/synthesize.py` | 18 sounds; the 13 older WAVs byte-identical (SHA-256 compared) |
| the headless import | exit 0; 18 sound sidecars |
| every suite under "Test suite to rerun" plus `test_maya_call.gd`, with `LOG_DIR=logs/phase_1/run24/step1/suites` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31, 12/12, 25/25, 21/21, 38/38, 12/12, 8/8; art 0 failures; only "resources still in use at exit" ERROR lines |
| `test_maya_call.gd` with "Lock it anyway." changed | 7/8, exit 1 (`mutation_changed_line/`) |
| `test_collision.gd` with "DRIVE COMPLETE" back | 37/38, exit 1 (`mutation_old_banner/`) |
| `capture_call.gd`, `capture_collision.gd` (windowed, default folders) | both exit 0; the call at 3.2 s shows "MAYA 00:03"; the ending stills at the depot |

**Unverified:**

- How the call and the ending sound: the ring, beeps and breathing are synthesized placeholders,
  and the levels (ring −14 dB, breathing −11 dB) are untested by ear.
- Whether 9 s in the cab before the fade feels right in play.

## Run 23, step 4: blinded, carried on, and the fall onto the windshield (approved: #89, #90; C33)

**Files:**

- **Changed:**
  - `game/features/vehicles/oncoming_van/oncoming_van.gd`: rebuilt from `iveco_exterior.glb`,
    dark paint, own plates, high beams always on, `meet()` timing, Iveco-size box;
  - `game/features/missions/night_freight/first_drive.gd`: the encounter span and trigger
    (`ENCOUNTER_SPAN`, `ENCOUNTER_SPEED`), the takeover (`_carry_on()`, `CARRY_*`), the stuck
    abort, the half-second coast (`REACTION`), the step-out with the freeze counted; the 3 m/s²
    skid braking is gone;
  - `game/features/vehicles/freight_van/freight_van.gd`: `scripted`, `scripted_throttle`,
    `scripted_brake`, `scripted_steer`, `steering_for()`, `_steering_limit()`;
  - `game/features/vehicles/freight_van/van_presentation.gd`: the front shell (`FRONT_LAYER` 16,
    `FRONT_PROFILE`, `GLASS_PROFILE`), `watch_head()` (`HEAD_REACH`, `COWL`, `HEAD_WATCH`);
  - `game/features/characters/pedestrian/pedestrian.gd`: `SWEEP`, `SCOOP`, `VAN_FRONT_LAYER`,
    damping (`LINEAR_DAMP` 0.3, `ANGULAR_DAMP` 4, `LIMB_DAMP` 25), hinge limits from a straight
    limb (`_pose_bend()`), `head_body()`;
  - `game/app/first_drive.gd`: `_struck()` calls `watch_head()` instead of `crack_at()`;
  - `tools/make_number_plate.py`: `--registration`, `--width`, `--out` (default output
    unchanged, byte-identical);
  - tests: `test_collision.gd`, `test_crossing.gd`, `test_oncoming_van.gd`;
  - captures: `capture_collision.gd`, `capture_oncoming.gd`.
- **New:** `game/features/vehicles/oncoming_van/art/number_plate.png` and its `.import`
  (VRAM-compressed, mipmaps, both texture formats).
- **Docs:** `CHANGE-BRIEF.md` (Run 23, step 4), `docs/DESIGN_DECISIONS.md` (C33), the prompt log
  (#89 outcome), `SOURCES.md` (Iveco use, the new plate) and the Iveco `ATTRIBUTION.md` (second
  use).
- **Evidence:** `evidence/phase_1/collision/run23_step4/` and `evidence/phase_1/oncoming/run23_step4/`.
- **Unused now, kept in the repository:** `body.glb`, `door.glb` and `tire.glb` (the oncoming
  van no longer uses them), `cabin.glb`, `steering.glb` and the Honda cockpit files.

**What the next run can rely on:**

- **Encounter:** it starts only when the van drives forward through road samples 927–960, on the
  road, at 3 m/s or more, in stage 4. Tests and captures must give the van speed
  (`_van.set("speed", ...)`) or drive it there; placing it parked starts nothing.
- **Takeover:** while `vehicle.scripted` is true, the van ignores the player's brake, throttle
  and wheel. It ends at the impact (plus a 0.5 s coast), past the crossing (+5 samples), when
  the van leaves the driver's seat, on a stall (below 2 m/s for 1.5 s), on recovery or on a new
  drive. `_stop_carrying()` hands control back.
- **Speeds:** `CARRY_SPEED` 11.8–12.5 m/s (42–45 km/h). The hit is tuned for this range; the
  head reached the glass in all 12 probe hits at 42–45 km/h.
- **The van's front for the ragdoll:** `_front` in `van_presentation.gd`, layer 16, only in the
  ragdoll's mask. Nothing else should use layer 16.
- **The crack:** placed by `watch_head()` where his head meets the glass base, not at the moment
  of contact.
- **The oncoming van:** `high_beams` is always true; `meet(at_distance, in_seconds)` steers its
  speed; `meet(-INF, 0)` releases it. `BUMPERS` 5.04, `LENGTH` 5.53, `KEEP_RIGHT` 0.85,
  `CLEARANCE` 2.15.

**Commands and real results:**

| Command | Result |
| --- | --- |
| `python3 -I tools/make_number_plate.py` | the player's plate unchanged (SHA-256 `5bf7ebdb…27c2` before and after) |
| `python3 -I tools/make_number_plate.py --registration "BR 731" --width 768 --out game/features/vehicles/oncoming_van/art/number_plate.png` | 768×160 |
| the headless import, `configure_imports.py` on `oncoming_van/art`, the import again | exit 0, no errors |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run23/step4/suites` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31, 12/12, 25/25, 21/21, 35/35, 12/12; art 0 failures; the only ERROR lines are "resources still in use at exit" |
| `test_collision.gd` with the takeover removed | 0/1, exit 1 (`mutation_no_takeover/`) |
| `test_collision.gd` with the brake working during the takeover | 2/5, exit 1 (`mutation_brake_works/`) |
| `test_collision.gd` with Run 20's bent-pose hinge limits | 33/35, exit 1, knees 177° (`mutation_bent_limits/`) |
| `test_collision.gd` with the old uniform push | head never at the glass, exit 1 (`mutation_old_push/`) |
| `test_oncoming_van.gd` with the oncoming van on low beams | 19/21, exit 1 (`mutation_low_beams/`) |
| `capture_collision.gd`, `capture_oncoming.gd` (windowed, default folders) | both exit 0; glare per lamp 0.27 at 84 m, 2.4 at 20 m; windshield 131 at 70 m, 33 as the vans pass; hit at 43 km/h |

**Unverified:**

- How the takeover feels in the author's own drive (about 12 s with no control).
- The frame rate on power.
- Rare ragdoll outliers: in 24 probe hits one elbow bent 51° the wrong way while tumbling.
- Driving on: the van does not collide with his body, so it can pass through it.

## Run 23, step 3: the Iveco in the game (approved: "proceed with step 3"; C32 from #88)

**Files:**

- **Changed:**
  - `game/features/vehicles/freight_van/van_presentation.gd`: rebuilt around
    `art/iveco/iveco_exterior.glb` and `iveco_cab.glb`;
  - `freight_van.tscn`: the Iveco-size collision box;
  - `windshield_wipe_map.gd`: the Iveco glass (1.77 × 1.0 m), pivots, arms and blades;
  - `game/app/first_drive.gd`: boarding and exit spots;
  - the mission's `first_drive.gd` (`BUMPER_AHEAD`), `pedestrian.gd` (`BUMPER_REACH`,
    `VAN_HALF_WIDTH`) and `oncoming_van.gd` (`BUMPERS`);
  - `tools/art/convert_iveco.py`: lamp lenses split, and the moon roof cut; the two `.glb` files
    and their textures re-exported and re-imported;
  - `tools/tests/check_first_drive_art.py`: the Iveco parts list;
  - tests: `test_cockpit.gd` (rewritten), `first_drive_regression.gd`,
    `first_drive_integration.gd`, `test_on_foot.gd`;
  - `tools/captures/capture_cockpit.gd`: Iveco view angles and a look up.
- **Docs:** `CHANGE-BRIEF.md` (Run 23, step 3), `docs/DESIGN_DECISIONS.md` (C32), the prompt log
  (#86–#88), `SOURCES.md` and the van's `ATTRIBUTION.md`.
- **Evidence:** `evidence/phase_1/cockpit/run23/`, `characters/run23/`, `beams/run23/`,
  `collision/run23_step3/` and `moon_roof/run23/`.
- **Unused now, kept in the repository:** `body.glb`, `door.glb`, `tire.glb`, `cabin.glb`,
  `steering.glb` and the Honda cockpit files. The oncoming van still uses `body.glb`,
  `door.glb` and `tire.glb`.

**What the next run can rely on** (the van's frame: front -Z, driver's side -X):

- **Placement:** the Iveco is placed at `IVECO_PLACE` (0, 0.16, 0.5); the road is at y 0.15–0.16.
  Its front bumper is 2.52 m ahead of the van's origin and its rear 3.01 m behind.
- **Eye:** `EYE` (-0.45, 1.88, -0.72). `LEAN` is (0, 0.05, -0.42).
- **Glass frame** (`WINDSHIELD_CENTRE`, `WINDSHIELD_RAKE`): (0, 1.8493, -1.3888), 0.7967 rad.
  `_windshield` is a mesh in that frame with UVs over `WipeMap.GLASS_SIZE`. `CRACK_AREA` is
  Rect2(-0.7, -0.42, 1.2, 0.82).
- **Nodes:**
  - `_door` is the Iveco `DriverDoor`, whose origin is its hinge;
  - `_door_glass` (cabin layer) holds the driver's window and mirror glass, and turns with it;
  - `_wheel` is the Iveco `SteeringWheel`, and `rotation.z` steers it;
  - `_tires` are the four Iveco wheel nodes: `rotation.y` steers and `rotation.x` rolls;
  - `_front_lenses`, `_rear_lamps` and `_indicators` are the Iveco lens meshes. Their
    `material_override` is set when lit and is null when off.
- **Screens:** `_powered_screens` are the cluster and the map, `_dark_screens` the matching dark
  faces, and `mirrors` the two door mirror viewports. There is no inside mirror.
- **Moon roof:** `MOON_ROOF` is Rect2(-0.52, -0.8, 1.04, 0.44) at `MOON_ROOF_HEIGHT` 2.226. The
  opening is cut in the `.glb` files themselves.

**Commands and real results:**

| Command | Result |
| --- | --- |
| `Blender -b --factory-startup --python-exit-code 1 --python tools/art/convert_iveco.py` | exit 0; moon roof cut 158 roof and 60 headliner faces; 88,428 triangles |
| the headless import, then `configure_imports.py` on `art/iveco`, then the import again | exit 0, no errors; 35 textures VRAM-compressed |
| `python3 tools/tests/check_first_drive_art.py` | 0 failures |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run23/step3/suites` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31, 12/12, 25/25, 21/21, 30/30, 11/11; art 0 failures |
| `test_cockpit.gd` with the steering reversed | 23/25, exit 1 (`mutation_steering_sign/`) |
| `test_cockpit.gd` with the gauges sunk 3 cm | 24/25, exit 1 (`mutation_cluster_sunk/`) |
| `capture_cockpit.gd`, `capture_on_foot.gd`, `capture_beams.gd`, `capture_collision.gd`, `capture_moon_roof.gd` (windowed, `-- <run folder>`) | all exit 0, no "unpair" errors; beams low 88.7/44.7, high 134.9/103.9, off 18.6/24.8, white-out 0.00% |

**Unverified:**

- The frame rate on power (the captures ran on battery at 72.8–80.9 FPS).
- How the van feels in the author's own drive: the narrower body, the lower eye, the mirrors.
- Ethan's hand on the Iveco's handle, checked only in dark stills.
- The oncoming van is still the old code-built van.

## Run 23, step 2: the Iveco made ours (approved: "Yes, start step 2 (Recommended)")

**Files:**

- **New:**
  - `tools/art/convert_iveco.py`, the Blender converter;
  - `tools/make_number_plate.py` and `source_assets/artwork/number_plate.png`;
  - `game/features/vehicles/freight_van/art/iveco/`: `iveco_exterior.glb`, `iveco_cab.glb`,
    the 35 WebP textures Godot extracted, every `.import` sidecar, and `ATTRIBUTION.md`;
  - `game/tests/lane_keeper.gd.uid` and `game/tests/test_crossing.gd.uid`, which the import
    created for Run 22's scripts.
- **Changed:**
  - `tools/tests/check_first_drive_art.py`: the Iveco section (15 checks);
  - `tools/assets/configure_imports.py`: also treats `*_normal.webp` as normal maps;
  - `SOURCES.md` (two rows), `source_assets/sketchfab/iveco_daily_2014/README.md`,
    `CHANGE-BRIEF.md` (Run 23, step 2) and the prompt log #85.
- **Evidence:** `evidence/phase_1/van/run23_step2/`: `before_after_sheet.png`,
  `van_sheet.png` and the ten renders in them.
- **Blender:** the author's open Blender gained an `IvecoGame` scene with the exported files,
  a `Shot` camera, `Sun`, `CabLight` and `Ground`. The `IvecoInspection` scene is as it was:
  its root was turned for the "before" renders and turned back. Nothing was saved.
- **Nothing in the game uses the van yet.**

**What the next run can rely on** (Godot space: front -Z, driver's side -X, metres):

- **`iveco_exterior.glb`:**
  - `Body` and `Windshield` sit at the origin. The body spans x ±1.002, y 0.235–2.081 and
    z -3.021–2.512; the windshield glass spans y 1.345–1.987 and z -2.254 to -1.48;
  - `DriverDoor` has its hinge at (-0.962, 1.102, -1.909) and `PassengerDoor` at (0.978, 1.102,
    -1.910), each with its window as a child. The driver's door opens with a negative turn
    about its local Y;
  - the wheels are at (∓0.872, 0.359, -2.007) at the front and (∓0.872, 0.359, 1.497) at the
    rear. They have a radius of 0.359 and turn about local X.
- **`iveco_cab.glb`:** `Cab` sits at the origin. `SteeringWheel`'s hub is at (-0.476, 1.313,
  -1.642), and its local Z (0, 0.703, 0.711) points up the column at the driver. A right turn
  is a negative turn about local Z.
- **Rebuilding the van:**
  1. `/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup
     --python-exit-code 1 --python tools/art/convert_iveco.py`;
  2. the headless import;
  3. `python3 -I tools/assets/configure_imports.py game/features/vehicles/freight_van/art/iveco`;
  4. the import again.

  The converter gives the same bytes on every run.

**Commands and real results:**

| Command | Result |
| --- | --- |
| `python3 -I tools/make_number_plate.py` | 1536×320 plate |
| the converter, above | exit 0; removed 318 grille-letter, 319 rear-door letter and 1,530 wiper faces; `iveco_exterior.glb` 5.5 MB, 56,107 triangles; `iveco_cab.glb` 1.9 MB, 31,630 triangles |
| `Godot --headless --editor --path game --import`, `configure_imports.py` on `art/iveco`, the import again | exit 0, no errors; 35 textures VRAM-compressed with mipmaps, 11 as normal maps |
| `Godot --headless --path game -s <scratch>/probe_iveco.gd` | both files load; positions as above (`logs/phase_1/run23/step2/probe_iveco_in_godot.log`) |
| `python3 tools/tests/check_first_drive_art.py` | 0 failures, Iveco 87,737 triangles |
| the art check with the van exported facing +Z | 3 failures, exit 1 (`mutation_faces_plus_z/`) |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run23/step2/suites` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31, 12/12, 25/25, 21/21, 30/30, 11/11; art 0 failures |

**Unverified:**

- How the van looks in the game's night, rain and headlights, and its frame rate (step 3).
- **Two-sided materials:** every material is two-sided, as in the source. What that costs is
  unmeasured.
- **The plate:** "BLACKRIDGE" along its top is Claude Code's reading of "a Blackridge plate".
- **Max:** whether he replies.

## Run 23, step 1: the Iveco Daily inspected (approved: "I'll open Blender's add-on")

- **Nothing in the game changed.**
- **Raw model:** `source_assets/sketchfab/iveco_daily_2014/` holds Blender's glTF export of the
  imported model (37 files, 260 MB), kept out of Git; its README is tracked.
- **Measurements** are in that README and in `CHANGE-BRIEF.md`. Renders are in
  `evidence/phase_1/van/run23_step1/`.
- **Blender:** the author's open Blender, an unsaved default file, now has an `IvecoInspection`
  scene with the Iveco, today's van (`TodaysVan`) and a `DriverEye` camera. The original
  "Scene" is untouched, and nothing was saved.
- **Sketchfab:** the add-on's switch and key are stored per scene. The key was copied inside
  Blender and never printed. Sketchfab's own download API refused that key (401), so the raw
  copy is a Blender export.
- **Unverified:** whether Max replies; how the Iveco's textures look once shrunk for the game.

## Run 22, step 1: the bus stop and zebra crossing (approved: "Yes, start step 1 (Recommended)")

**Files:**

- **New:**
  - `game/features/environments/industrial_loop/bus_stop.gd` (with its `.uid`);
  - `game/tests/lane_keeper.gd` and `game/tests/test_crossing.gd` (with their `.uid` files).
- **Changed:**
  - `industrial_loop.gd`: `CROSSING_AT`, `crossing`, the stop built and painted, and its
    clearings;
  - `ghat_dressing.gd`: `_crossing_signs()`, the five-row atlas, the "flag" shape;
  - `wet_asphalt.gdshader`: `crossing_*` uniforms and `crossing_paint()`;
  - `tools/make_road_signs.py` and `art/road_signs.png` (fifth row);
  - `tools/art/convert_mixamo.py` and `pedestrian.glb` (Idle);
  - `pedestrian.gd`: `waiting`, `wait_at()`, the near-miss `_resume()`, `MAX_WALK`;
  - the mission's `first_drive.gd`: `crossing`, `ENCOUNTER_INDEX` 934, `MEETING_BEFORE` 8,
    `_watch_crossing()`, `_spawn_pedestrian()`;
  - `game/app/first_drive.gd`: `route.crossing`;
  - `test_collision.gd`, `test_oncoming_van.gd`, `capture_oncoming.gd`, `capture_collision.gd`.
- **Docs:** `CHANGE-BRIEF.md` (Run 22, step 1), `docs/DESIGN_DECISIONS.md` (C30),
  `game/features/characters/ATTRIBUTION.md` and the prompt log #80.

**What the next run can rely on:**

- **`world.crossing` (the bus stop node):** `index` (1002), `centre`, `forward`, `right`,
  `half_width`, `kerb` (where he waits) and `clearings`.
- **The pedestrian** exists from the encounter's start, `waiting` at the kerb until
  `_watch_crossing()` sends him.
- **Tests** that drive toward the crossing must steer: `LaneKeeper.new(road, start_index)`,
  then `steer(van, lateral)` every physics frame and `release()` at the end.

**Commands and real results:**

| Command | Result |
| --- | --- |
| `Blender -b --factory-startup --python tools/art/convert_mixamo.py` | exit 0; `pedestrian.glb` has HitByVan, Walk and Idle; `ethan.glb` byte-identical |
| `python3 -I tools/make_road_signs.py` | 20 cells; the 15 older faces pixel-identical |
| `Godot --headless --editor --path game --import` | exit 0; no errors |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run22/step1` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31, 12/12, 25/25, 21/21, 30/30, 11/11; art 0 failures |
| `test_crossing.gd` with no crossing paint | 10/11, exit 1 (`mutation_no_paint/`) |
| `test_collision.gd` with the step-out 2 s early | fails, exit 1 (`mutation_early_step/`) |
| `capture_collision.gd -- evidence/phase_1/collision/run22` (windowed) | 19 stills, including both overviews, the approach at 44 m and 20 m, and the step-out at 57 km/h |

**Unverified:**

- How the crossing reads in play, and the pedestrian's waiting pose up close.
- **Below about 15 km/h,** an instantly braking driver can stop short; a human reaction time
  still hits at 10 km/h. Whether that edge case is acceptable is the author's call.
- Frame rate with the shelter and path (a few hundred triangles; no new lights).

## Run 21, step 2: the release export (approved: "Yes, start step 2 (Recommended)"; then "Switch to universal (Recommended)")

**Files:**

- **Changed:**
  - `game/export_presets.cfg`: `binary_format/architecture="universal"`;
  - `README.md`: the macOS export note and command;
  - `CLAUDE.md`: the `project.godot` rule includes the texture setting.
- **Outside the repository:** the macOS template in
  `~/Library/Application Support/Godot/export_templates/4.7.2.stable/` (`macos.zip` and
  `version.txt`).
- **Generated, ignored by Git:** `builds/macos/Blackridge.zip` and the unzipped
  `Blackridge- No Way Back.app`.
- **Evidence:** `evidence/phase_1/export/run21/release_export.txt` and both release logs.
- **Docs:** `CHANGE-BRIEF.md` (Run 21, step 2) and the prompt log #78.

**What the next run can rely on:**

- **Export command:** `Godot --headless --path game --export-release "macOS"
  ../builds/macos/Blackridge.zip`, exit 0 in about 20 s.
- **Official templates** ship universal macOS binaries only; an arm64-only preset fails.
- **The app's data folder** is `~/Library/Application Support/Godot/app_userdata/Blackridge-
  No Way Back/`, the same one the editor and tests use. Its log is written when the app
  quits.
- **An open Godot editor can undo outside edits.** On "Ignore external changes" it rewrote
  `project.godot` and re-imported the textures (#81). Check
  `grep -c import_etc2_astc=true game/project.godot` and the 160 `path.etc2` sidecars before
  an export.

**Commands and real results:**

| Command | Result |
| --- | --- |
| `shasum -a 512` of the templates file against the official `SHA512-SUMS.txt` | match |
| `--export-release "macOS"` with the arm64 preset | exit 1: "Requested template binary "godot_macos_release.arm64" not found" |
| the same after switching to universal | exit 0, 20 s; 350,894,372 bytes; SHA-256 `a547b5ea…90ae7` |
| `open "builds/macos/Blackridge- No Way Back.app"` | the app starts and keeps running (process found) |

**Unverified:**

- How the exported game plays, and its frame rate (the author's check).
- The app's log, until the app quits.

## Run 21, step 1: the macOS export preset and pack listing (approved: "Yes, start step 1 (Recommended)")

**Files:**

- **New:** `game/export_presets.cfg` (one preset, "macOS").
- **Changed:**
  - `game/project.godot`: `rendering/textures/vram_compression/import_etc2_astc=true`, with
    the author's OK (#77);
  - 160 texture `.import` sidecars, rewritten by the import to list the ETC2/ASTC copy.
- **Evidence:** `evidence/phase_1/export/run21/` (listings, the difference, export logs).
- **Docs:** `CHANGE-BRIEF.md` (Run 21, step 1) and the prompt log #76–#77.

**What the next run can rely on:**

- **Preset:** "macOS": arm64, "Testing" distribution, built-in ad-hoc signing, no notarization,
  version 0.1.0, `../builds/macos/Blackridge.zip`, excluding `tests/*`, `experiments/*` and
  `app/visual_benchmark.*`.
- **Textures:** every compressed texture exists in both formats in `game/.godot/imported/`.
- **Templates:** the 4.7.2 templates file is in the agent's scratch folder,
  `godot-templates/Godot_v4.7.2-stable_export_templates.tpz` (1,281,349,702 bytes), with
  `SHA512-SUMS.txt`. They are not installed yet.
- **`CLAUDE.md`** still says `project.godot` changes only its renderer and MetalFX lines. The
  wording for the new texture line is for the author to approve.

**Commands and real results:**

| Command | Result |
| --- | --- |
| `Godot --headless --editor --path game --import` | exit 0; 160 textures re-imported with an `.etc2.ctex` copy |
| `Godot --headless --path game --export-pack "macOS" <scratch>/pack_filtered.zip` | exit 0, 20 s; 703 entries, 482.7 MB; no tests, experiments or benchmark |
| the same with a temporary "macOS (no filters)" preset | exit 0; 737 entries; the 34 extra are tests, the hint experiment and the benchmark; the temporary preset was removed (`cmp` identical) |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run21/step1` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31, 12/12, 25/25, 21/21, 29/29; art 0 failures |

**Unverified:**

- Whether the release export succeeds and the app launches (step 2).
- How the app's file name treats the colon in "Blackridge: No Way Back".
- Whether the arm64 app uses the ASTC or the desktop copies of the textures.

## Run 20, step 3: the hood in the cab view (approved: "Yes, start step 3 (Recommended)")

**Files:**

- **Changed:**
  - `van_presentation.gd`: `_hood_from_cab()`, `_hood_faces()`, `HOOD`, `HOOD_LIFT`,
    `HOOD_LAYER`; the driving camera's cull mask is `5 | HOOD_LAYER` (13);
  - `test_collision.gd`: 29 checks; the sight lines use the driving camera's cull mask.
- **Docs:** `CHANGE-BRIEF.md` (Run 20, step 3) and the prompt log #75.

**What the next run can rely on:**

- **`HoodFromCab`:** a child of the presentation on render layer value 8, holding the body's
  hood triangles 3 mm outside the real hood. No other camera or light uses layer value 8.
- **The driving camera** draws layers 1 and 3 plus the hood copy, never the whole body.

**Commands and real results:**

| Command | Result |
| --- | --- |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run20/step3` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31, 12/12, 25/25, 21/21, 29/29; art 0 failures; no script, shader or load errors |
| `test_collision.gd` with the hood left out of the cab view | 28/29, exit 1 (`mutation_no_hood/`) |
| `test_collision.gd` with `LEAN` zero | 27/29, exit 1 (`mutation_no_lean/`) |
| `capture_collision.gd -- evidence/phase_1/collision/run20_step3` (windowed) | 15 stills at 1280×800; leaning, the hood covers the ground and only a sliver of him shows 2.25 m past the bumper; seated views unchanged |

**Unverified:**

- How the hood looks in motion, and in the on-foot view (it sits 3 mm outside the real hood).
- Frame rate on power (the copy is 1,002 triangles with no shadow).

## Run 20, step 2: the van takes the hit (approved: "Yes, all of it (Recommended)"; crack: "Put it in anyway")

**Files:**

- **New:** `game/features/audio/first_drive/impact_body.wav` (with its `.import`).
- **Changed:**
  - `source_assets/audio/first_drive/synthesize.py`: `body_impact()`; the other 12 WAVs are
    byte-identical;
  - `driving_audio.gd`: `body_impact()`;
  - the mission's `struck(speed)` signal carries the impact speed, and the hit no longer
    emits the van's `collided`;
  - `game/app/first_drive.gd`: `_struck(speed)` plays the sound, jolts the cab and cracks the
    glass by impact speed (`IMPACT_SPEED`), and gives the presentation the body to look at;
    `_restart()` clears both;
  - `van_presentation.gd`: the rock spring (`ROCK_*`), `look_target_node`, `_lean_to_look()`
    (`LEAN`, `LEAN_RATE`, `LOOK_DOWN`, `CAMERA_TILT`), `crack_at()`, `clear_crack()`
    (`CRACK_AREA`, `CRACK_GROWTH`);
  - `windshield.gdshader` (the van's folder, not `game/shaders/`): `crack_point`,
    `crack_amount`, `crack_seed`, `crack_ray()` and `crack_lines()`;
  - `pedestrian.gd`: `hips_body()`, `head_position()`;
  - `test_collision.gd`: 28 checks;
  - `tools/captures/capture_collision.gd`: `leaning_over_the_wheel`, `drive_objective`,
    `sitting_back` and `driving_on_with_the_crack` stills, the eye's lean in each report line,
    and a 1280×800 window.
- **Docs:** `CHANGE-BRIEF.md` (Run 20, step 2), `docs/AUDIO.md` (13 WAVs) and the prompt log
  #73–#74.

**What the next run can rely on:**

- **Lean:** `look_target_node` is the pedestrian's hips body after a hit, and `null` after
  "New drive". The lean happens only while `vehicle.held` and nearly stopped.
- **Rock:** `_rock` is the cab's extra pitch in radians. Only `jolt()` kicks it, and only the
  hit calls `jolt()`.
- **Crack:** `crack_amount` on the windshield material is 0 until a hit, then the impact
  strength (0.3–1.0), and it stays until `clear_crack()`.
- **Hood:** the driving camera does not draw the van's body (layer 2), so the hood is
  invisible from the cab. Counting the hood, leaning shows 0 of 11 body parts when he lies
  1.6 m ahead, and 10 of 11 at 2.8 m. Drawing the whole body from the cab would put the body's
  solid roof over the moon roof.

**Commands and real results:**

| Command | Result |
| --- | --- |
| `Godot --headless --editor --path game --import` | `impact_body.wav.import` created; exit 0 |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run20/step2` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31, 12/12, 25/25, 21/21, 28/28; art 0 failures; no script, shader or load errors; only "resources still in use at exit" errors |
| `test_collision.gd` with `LEAN` zero | 27/28, exit 1 (`mutation_no_lean/`) |
| `test_collision.gd` with the crack at the glass's bottom edge | 27/28, exit 1 (`mutation_hidden_crack/`) |
| `python3 source_assets/audio/first_drive/synthesize.py` | 13 WAVs; all byte-identical to the run before the code tidy |
| `capture_collision.gd -- evidence/phase_1/collision/run20_step2` (windowed) | 15 stills at 1280×800; unbraked impact at 8.3 m/s; leaning shows him on the verge; the crack shows low on the right from the seat |

**Unverified:**

- How the shudder, the lean and the crack feel in motion.
- Frame rate on power, and the crack's cost (one more loop of 14 radial lines, only inside its
  circle).

## Run 20, step 1: the hit by physics (approved: "Yes, start step 1 (Recommended)")

**Files:**

- **Changed:**
  - `game/features/characters/pedestrian/pedestrian.gd`: the ragdoll (`BONES`,
    `_build_ragdoll()`, `_joint()`, `_shape()`), the freeze (`_freeze()`), the hit
    (`_go_limp()`) and the settling (`_settle()`); `frozen`, `settled`, `bones`,
    `simulating()`, `hips_position()`;
  - `tools/art/convert_mixamo.py` (`REAL_SIZE`, `real_size()`) and the re-exported
    `pedestrian.glb`, now at real size;
  - `game/tests/test_collision.gd`: the ragdoll checks, 22 in all;
  - `tools/captures/capture_collision.gd`: a side-on sequence, cameras aimed at his hips,
    output `evidence/phase_1/collision/run20`.
- **Docs:** `CHANGE-BRIEF.md` (Run 20), `game/features/characters/ATTRIBUTION.md` and the
  prompt log #72–#73.

**What the next run can rely on:**

- **Bodies:** `pedestrian.bones` maps "Hips", "Spine", "Head", "LeftArm", "LeftForeArm",
  "RightArm", "RightForeArm", "LeftUpLeg", "LeftLeg", "RightUpLeg" and "RightLeg" to
  `PhysicalBone3D`s.
- **Layers:** the bones are on layer 8 and collide with layer 1 only. The van ignores them.
- **Joint types:** knees and elbows are hinges with their limits as (−bend, +2°), because
  Godot measures the hinge angle with the opposite sign to the walk-clip axis. Other joints are
  6DOF. Cone joints and limits near 90° made the ragdoll blow up.
- **Build pose and push:** the ragdoll is built in the standing pose (Hit By Car at 1.6 s).
  Every body gets the same push; giving joined bodies different velocities blew it up.
- **Settling:** after settling the bodies are static (`settled`).

**Commands and real results:**

| Command | Result |
| --- | --- |
| `Blender -b --factory-startup --python tools/art/convert_mixamo.py` | only `pedestrian.glb` changed; `ethan.glb` byte-identical |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run20` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31, 12/12, 25/25, 21/21, 22/22; art 0 failures; only "resources still in use at exit" errors |
| `test_collision.gd` with no push | 20/22, exit 1 (`mutation_no_push/`) |
| `test_collision.gd` with the knee limits reversed | 21/22, exit 1 (`mutation_knees_backward/`) |
| `capture_collision.gd -- evidence/phase_1/collision/run20` (windowed) | 13 stills: impact at 8.1 m/s; he lands about 5.6 m down the road and rests about 2 m ahead of the stopped bumper, on the verge to the right |

**Unverified:**

- How it feels in play.
- Whether the author wants the body visible from the driver's seat. It lies in the cab-over
  blind spot.
- Frame rate with the ragdoll; it runs only after the hit.

## Run 19, step 4: the collision, the flight and the depot (approved: "Yes, unavoidable (Recommended)")

**Files:**

- **New:**
  - `game/features/characters/pedestrian/pedestrian.gd` (with its `.uid`);
  - `game/tests/test_collision.gd` (with its `.uid`);
  - `tools/captures/capture_collision.gd`.
- **Changed:**
  - mission `first_drive.gd`: `struck`, `pedestrian`, `fleeing`, `_physics_process()`,
    `_send_pedestrian()`, `_on_struck()`, `_restore_braking()`; "DRIVE." in
    `_update_objective()`; recovery keeps him after a hit;
  - `game/app/first_drive.gd`: `_struck()`, `_drive_completed()`, `_exit_at_depot()`, E blocked
    while fleeing, music back on "New drive";
  - `freight_van.gd`: `held`;
  - `van_presentation.gd`: `jolt()`; eye adaptation through the driving camera's
    `CameraAttributesPractical`;
  - `driving_audio.gd`: `silence_music()`, `play_music()`;
  - `driver.gd`: `play_clip(clip, facing, from, shift)`, `clip_finished()`, `finish_clip()`;
  - `test_oncoming_van.gd`: two adaptation checks.
- **Docs:** `CHANGE-BRIEF.md`, `docs/DESIGN_DECISIONS.md` (C29) and the prompt log #70.

**What the next run can rely on:**

- **Mission state:** `route.pedestrian.hit` says whether he was struck. `route.fleeing` is
  true from "DRIVE." until "New drive". `route.complete` after a hit triggers the depot exit.
- **The pedestrian:** his `struck(speed)` signal fires once.
- **Throw:** `THROW_BASE` 0.8 + `THROW_PER_SPEED_SQUARED` 0.16 × speed², at most 12 m.
- **The driving camera** now has a `CameraAttributesPractical`. Its `exposure_multiplier` is 1.0
  except while the glare adapts the eye.

**Commands and real results:**

| Command | Result |
| --- | --- |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run19/step4` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31, 12/12, 25/25, 21/21, 18/18; art 0 failures |
| the same, as the final run before the commit (the logs in that folder) | the same results. No "SCRIPT ERROR", "SHADER ERROR" or "Failed loading resource" line; the only "ERROR:" lines are the engine's "resources still in use at exit". The run before it showed one freed-object error from `_clear_oncoming()`, fixed before the commit |
| `test_collision.gd` with dry brakes (`SKID_BRAKING` 9.0) | 8/18, exit 1 (`mutation_dry_brakes/`) |
| `capture_collision.gd -- evidence/phase_1/collision/step4` (windowed, on battery) | 11 stills: step-out at 7.0 m/s, too late at 4 m, impact at 8.3 m/s, skid, he lies 8 m ahead of the bumper in the low beams, "DRIVE.", side views, getting out and shutting the door at the depot |

**Unverified:**

- How it plays and feels in motion. It was seen only in tests and stills, never driven by a
  person.
- Whether the darkened view after the glare makes him hard enough to see in normal play. In the
  capture the player stopped and was teleported, so the eyes had recovered.
- Frame rate on power.

## Run 19, step 3: the oncoming van and its glare (approved: "Yes, start step 3 (Recommended)")

**Files:**

- **New:**
  - `game/features/vehicles/oncoming_van/oncoming_van.gd` (with its `.uid`);
  - `game/tests/test_oncoming_van.gd` (with its `.uid`);
  - `tools/captures/capture_oncoming.gd`.
- **Changed:**
  - `game/features/missions/night_freight/first_drive.gd`: `road`, `oncoming`,
    `_send_oncoming()`, `_nearest_index()` and `_clear_oncoming()`;
  - `game/app/first_drive.gd`: `route.road = world.road`;
  - `van_presentation.gd`: `oncoming`, `_update_glare()`, `_on_windshield()`, `_hidden()`,
    `_oncoming_rain()`; `_light_the_rain()` also lights the rain with the oncoming lamps;
  - `windshield.gdshader`: `glare_points`, `glare_power`, `glare_colour`, `glare_veil()`,
    `arc_streak()`;
  - `beam_rain.gdshader`: the `oncoming_*` uniforms; `lamp_light()` takes a pattern and a
    range.
- **Docs:** `CHANGE-BRIEF.md` and the prompt log #69.

**What the next run can rely on:**

- **The trigger:** `ENCOUNTER` (98.7, 25.5), within 14 m, in stage 4, once per drive.
- **The van:** it starts between samples 1040 and 1090, meets the player near 1012, and is
  removed at 900. It emits `passed` once the player is behind it, which step 4 can use to send
  the pedestrian.
- **Numbers:** `OncomingVan.KEEP_RIGHT` 0.95, `BUMPERS` 4.7, `STOP_GAP` 2.5, `CRUISE`
  11.1 m/s.
- **Its body:** with `sync_to_physics` off, its transform is exact on the first frame.

**Commands and real results:**

| Command | Result |
| --- | --- |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run19/step3` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31, 12/12, 25/25, 19/19; art 0 failures |
| `test_oncoming_van.gd`, never blocked | 18/19, exit 1 (`mutation_no_blocking/`) |
| `test_oncoming_van.gd`, no glare | 18/19, exit 1 (`mutation_no_glare/`) |
| `capture_oncoming.gd -- evidence/phase_1/oncoming/step3` (windowed, on battery) | 10 stills; glare 0.10 at 120 m to 0.89 at 10 m; windshield brightness 53 → 88 at 20 m |

**Unverified:**

- How the glare feels while driving; it was seen only in stills, parked.
- Frame rate with the second van on power. The stills ran at 46–61 FPS on battery.
- Whether two vans meeting in the hairpins themselves would fit. The van is removed before
  them.

## Run 19, step 2: start on foot and get into the van (approved: "Yes, lights on at ignition (Recommended)")

**Files:**

- **Changed:**
  - `game/app/first_drive.gd`: `_begin()`, `_new_drive()`, `_begin_on_foot()`,
    `_board_van()`, `_cancel_boarding()`, `_path_to()`, `_on_ground()` and the hints;
  - `game/features/characters/driver/driver.gd`: Ethan's model and clips, `walk_to()`,
    `play_clip()`;
  - `game/features/vehicles/freight_van/freight_van.gd`: `engine_on`, `driver_door`,
    `switch_off()`, `start_engine()`, `ignition_sweep()`, `engine_started`;
  - `van_presentation.gd`: `DOOR_ART`, `DOOR_HINGE`, `DOOR_SWING`, `_door`, `_door_glass`,
    `_power_screens()`, `_tail_off`;
  - `instruments.gd`: the sweep;
  - `driving_audio.gd`: the engine is silent while off;
  - `driving_hud.gd`: `fade()`, the controls line;
  - `tools/art/build_first_drive_art.py` and the regenerated `body.glb`.
- **New:** `art/door.glb`, `game/tests/test_on_foot.gd` (with its `.uid`) and
  `tools/captures/capture_on_foot.gd`.
- **Tests changed (recorded in `CHANGE-BRIEF.md`):** `first_drive_integration.gd` waits for
  boarding; `check_first_drive_art.py` expects five van models.
- **Docs:** `CHANGE-BRIEF.md`, `CLAUDE.md` (the ignition line), `SOURCES.md` and the prompt
  log #68.

**What the next run can rely on:**

- **Tests start in the van.** Suites that call `_resume()` start in the van with the engine
  running, as before. Only the HUD's "Begin / continue drive" (`_begin()`) and "New drive"
  (`_new_drive()`) start on foot.
- **The boarding spot** is van-local (-2.25, 0, -0.35), facing the van's +X. At clip time
  1.05 s his hand meets the handle at (-1.20, 1.05, -0.22).
- **The door** swings to 31° (`driver_door` 1.0) by 1.6 s, and the cut starts at 1.75 s.
- **Ignition:** 0.6 s after the cut, then a 1.4 s sweep, then the low beams and wipers.

**Commands and real results:**

| Command | Result |
| --- | --- |
| `python3 tools/art/build_first_drive_art.py` | only `body.glb` changed (9,838 → 9,278 triangles); new `door.glb` 1,172 |
| every suite before the two test changes (`logs/phase_1/run19/step2_before_test_changes/`) | all pass except "Nearby driver can reenter" (integration) and the art check's model count |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run19/step2` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31, 12/12, 25/25; art 0 failures |
| `test_on_foot.gd` with the ignition call removed | 20/25, exit 1 (`logs/phase_1/run19/step2/mutation_no_ignition/`) |
| `capture_on_foot.gd -- evidence/phase_1/characters/step2` (windowed) | 8 stills: start (mean brightness 9.6/255), walking, reach, door open (third-person and side), in the cab with the engine off, gauge sweep, low beams and wipers on |

**Unverified:**

- How it looks and feels in motion: the walk, the reach and the cut were checked only in
  stills.
- Walking around the van from the far side (`_path_to()`), which no test covers.
- Whether the start is too dark to find the door. The objective and hint name it.

## Run 19, step 1: Mixamo characters imported (approved: "Go ahead, dark shirt (Recommended)")

**Files:**

- **New:**
  - `tools/art/convert_mixamo.py`;
  - `game/features/characters/ethan/ethan.glb` (6.5 MB), `pedestrian/pedestrian.glb`
    (3.2 MB), their `.import` files and six extracted WebP textures;
  - `game/features/characters/ATTRIBUTION.md`;
  - `tools/captures/capture_characters.gd`;
  - stills in `evidence/phase_1/characters/step1/`.
- **Changed:**
  - `tools/assets/configure_imports.py` also sets `*.webp` textures, and treats
    `*_Normal.webp` as normal maps;
  - `.gitignore` ignores `/source_assets/mixamo/*.fbx` (about 55 MB each);
  - `source_assets/mixamo/README.md`;
  - `SOURCES.md`.

**What the game can rely on:**

- **Ethan:** 54,938 triangles, 65 bones and 1.78 m tall. His clips are `Idle`, `Walk`,
  `WalkBack` and `Run`, which loop, plus `EnterVan` and `ExitVan`.
- **The pedestrian:** 42,818 triangles and 1.75 m tall. His clips are `HitByVan` and `Walk`
  (looping). His polo is charcoal, about sRGB (56, 58, 62).
- **Bones:** `mixamorig_*` in Godot, so either character can play the other's clips.
- **Walk and run play in place.** Ground speeds: `Walk` 1.705 m/s (a 1.033 s cycle),
  `WalkBack` 0.529 m/s, `Run` 4.535 m/s. The car and hit clips keep their own motion.
- **Looping** comes from Godot's "-loop" track-name hint, so the `.import` files stay at
  their defaults.
- **EnterVan does not fit the cab.** Seated, his hips are 0.83 m above his feet. The cab
  floor is 1.17 m above the van's base and the driver's eye 2.03 m, so seated hips would be
  about 0.6 m higher. The clip also ducks him into a low car door
  (`enter_van_2.5s_debug_light.png`).

**Commands and real results:**

| Command | Result |
| --- | --- |
| `Blender -b --factory-startup --python tools/art/convert_mixamo.py` | the two `.glb` files above, both under 25 MB |
| `Godot --headless --editor --path game --import`, then `configure_imports.py game/features/characters`, then the import again | VRAM-compressed textures with mipmaps; normal maps marked |
| `Godot --path game --resolution 1280x800 --script ../tools/captures/capture_characters.gd -- evidence/phase_1/characters/step1` (windowed) | 11 stills; pedestrian at 14 m against the road behind him: low beam 156.0 / 149.4, high 187.9 / 153.1, off 12.1 / 15.2 |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run19/step1` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31, 12/12; art 0 failures |

No log has a "SCRIPT ERROR", "SHADER ERROR" or "Failed loading resource" line. The only
other "ERROR:" lines are the engine's "resources still in use at exit".

**Unverified:**

- Mixamo's normal-map convention.
- How the characters look in motion; only stills exist.
- Whether the art check should also cover `game/features/characters/`. Today it reads only
  the van and world art folders.

## Run 18 (committed)

The author tested Runs 15–18 ("everything is perfect"). Runs 1–16 are in `ef011b8`, and
Runs 17–18 are in the commit after it; `develop` is pushed to `origin`, and `main` is not.
Final logs: `logs/phase_1/run18/`.

## Files changed in Run 18

- `game/features/vehicles/freight_van/van_presentation.gd`: `LOW_BEAM_RAIN` and
  `HIGH_BEAM_RAIN`; `_light_the_rain()` sets the rain's glow and density by beam.
- `game/tests/test_headlights.gd`: the 3× check (17 in total).
- **Docs:** `CHANGE-BRIEF.md`, the prompt log (#56–#57), the development log and the
  captures README.

## Run 18 commands and real results

| Command | Result |
| --- | --- |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run18` | 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31, 12/12; art 0 failures |
| `test_headlights.gd` with equal rain for both beams | 16/17, exit 1 (`logs/phase_1/run18/mutation_same_rain/`) |
| `capture_beams.gd -- evidence/phase_1/beams/run18` (windowed) | near/far: low 91.4/41.2, high 133.8/98.6, off 18.8/27.2; white-out 0.00%; 24–28 FPS while charging from 8% |

No log has a "SCRIPT ERROR", "SHADER ERROR" or "Failed loading resource" line. The only
other "ERROR:" lines are the engine's "resources still in use at exit".

## Unverified

- The frame rate with the beam rain, on power with a charged battery.
- The author's test of Runs 15–18.

## Files changed in Run 17

- `game/features/vehicles/freight_van/beam_rain.gdshader` (new, with its `.uid`).
- `van_presentation.gd`:
  - `BEAM_RAIN`, `RAIN_LAYERS`, `LAMP_FRONT`, `RAIN_SLANT` and `BODY_ROOF`;
  - `_rain_layers` and `_beam_rain_material`;
  - `_beam_rain()` and `_light_the_rain()`;
  - `MoonRoofOutside` in `_exterior()`.
- `game/features/environments/industrial_loop/industrial_loop.gd`: `GUIDE_GREEN`.
- `CLAUDE.md`: "cycled (low beam, high beam, off)".
- **Tests:**
  - `test_headlights.gd` (16), with `_check_beam_rain()`;
  - `test_cockpit.gd` (29);
  - `test_ghat_road.gd` (31).
- **Docs:**
  - `CHANGE-BRIEF.md` and `docs/DESIGN_DECISIONS.md` (C26);
  - the prompt log (#55), the development log and the captures README.

## Run 17 commands and real results

| Command | Result |
| --- | --- |
| `Godot --headless --editor --path game --import` | exit 0 (`logs/phase_1/run17_import.log`) |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run17` | 64/64, 0 failures, 92/92, 16/16, 12/12, 30/30 ×3, 29/29, 31/31, 12/12; art 0 failures |
| headlight and ghat tests with the rain always shown and teal signs | 15/16 and 30/31, exit 1 each |
| `capture_beams.gd -- evidence/phase_1/beams/run17` (windowed) | near/far: low 97.3/48.1, high 120.7/82.3, off 18.2/28.6; white-out 0.00% |
| a scratch still script for the outside roof (windowed) | `evidence/phase_1/moon_roof/run17/` |
| `measure_performance.gd` and a GPU-time script (windowed) | not comparable: the Mac was on battery at 10% (about 60 FPS, 18 ms frames); the GPU timer reads 0 on Metal |

No log has a "SCRIPT ERROR", "SHADER ERROR" or "Failed loading resource" line. The only
other "ERROR:" lines are the engine's "resources still in use at exit".

## Unverified

- The beam rain's frame-time cost; re-measure on power with `measure_performance.gd`.
- How the beam rain looks while driving fast. The layers ride with the van, so the drops
  fall but do not rush toward the driver.
- The author's verdicts on everything since Run 15, including the lumber-yard start and the
  landslide.

## Files changed in Run 16, step 5

- `game/features/vehicles/freight_van/van_presentation.gd`: `CENTRE_MIRROR`,
  `CENTRE_MIRROR_SIZE` and `CENTRE_MIRROR_TURN`; the inside view goes through
  `_dash_screen()` on the Honda mirror instead of `_screen()` beyond the windshield.
- `game/tests/test_cockpit.gd`: `_check_centre_mirror()`, two checks (28 in total).
- **Docs:** `CHANGE-BRIEF.md`, the prompt log (#54) and the development log.

## Run 16 step 5 commands and real results

| Command | Result |
| --- | --- |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run16/mirror` | 64/64, 0 failures, 92/92, 14/14, 12/12, 30/30 ×3, 28/28, 30/30, 12/12; art 0 failures |
| `test_cockpit.gd` with the old mirror put back | 26/28, exit 1 (`logs/phase_1/run16/mirror/mutation_old_mirror/`) |
| a scratch still script (windowed): forward, looking at the mirror, zoomed | `evidence/phase_1/mirror/run16/`; the first try timed out without a frame, the retry worked |

No log has a "SCRIPT ERROR", "SHADER ERROR" or "Failed loading resource" line. The only
other "ERROR:" lines are the engine's "resources still in use at exit".

## Waiting on the author

- Their own drive with the wipers, beams, moon roof and mirror.
- Whether the `CLAUDE.md` project-context line "toggled by the `headlights` action" should
  say "cycled".
- Rain in the beams waits for Assignment 6's particles.

## Files changed in Run 16, step 4

- `game/features/vehicles/freight_van/art/cockpit/cockpit_roof.gltf`, `.bin` and
  `cockpit_shadow.glb`, re-exported from Blender with the plate inside the Honda's sunroof
  frame cut away; `ATTRIBUTION.md` lists the change. The 11 roof textures are unchanged.
- `van_presentation.gd`:
  - `MOON_ROOF`, `MOON_ROOF_HEIGHT`, `ROOF_SLOPE`, `ROOF_AIR` and `LOOK_UP`;
  - `roof_rain` and `_roof_water`;
  - `_moon_roof()` builds `MoonRoofGlass` and `MoonRoofRain`;
  - the mouse look limit uses `LOOK_UP`.
- **Tests:** `game/tests/test_cockpit.gd` (26 checks; triangle count 847,408).
- `tools/captures/capture_moon_roof.gd` (new).
- **Docs:**
  - `CHANGE-BRIEF.md`, `CLAUDE.md` (the approved L wording), `SOURCES.md`;
  - the prompt log (#53), the development log and the captures README.

## Run 16 step 4 commands and real results

| Command | Result |
| --- | --- |
| Blender (MCP): cut the plate inside the frame in three meshes; export roof (GLTF_SEPARATE) and static shadow (GLB) to `cockpit_fit/hookup/export_run16/` | roof 89,186 triangles, shadow 29,973 |
| `python3 -I postprocess.py export_run16 final_run16` (in `cockpit_fit/hookup/`) | 11 images; every texture byte-identical to the game's |
| `Godot --headless --editor --path game --import` | exit 0 (`logs/phase_1/run16/import_step4.log`); texture import settings unchanged |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run16/step4` | 64/64, 0 failures, 92/92, 14/14, 12/12, 30/30 ×3, 26/26, 30/30, 12/12; art 0 failures |
| `test_cockpit.gd` with the closed roof files put back | 23/26, exit 1 (`logs/phase_1/run16/step4/mutation_closed_roof/`) |
| `capture_moon_roof.gd -- evidence/phase_1/moon_roof/run16` (windowed) | three stills; the roof water flows backward |

No log has a "SCRIPT ERROR", "SHADER ERROR" or "Failed loading resource" line. The only
other "ERROR:" lines are the engine's "resources still in use at exit".

## What the next run may rely on

- The Blender session holds the cut; a copy is `cockpit_fit/cockpit_fit_step4_moonroof.blend`
  in the agent's scratch folder (374 MB, not in Git). A future roof change re-exports with
  the same settings, runs `postprocess.py`, and copies only the changed `.gltf`, `.bin` and
  `.glb` files.
- `test_cockpit.gd` checks the moon roof by sight lines against the imported meshes, so a
  re-export that closes the roof fails it.

## Waiting on the author

- Their own drive: the wipers (step 2), the beams (step 3) and the moon roof (step 4).
- Commit approval for Runs 1–16.
- The rest of the backlog: the double rear-view mirror, rain in the beams (Assignment 6),
  and a played lap of the ghat road.

## Files changed in Run 16, step 3

- `game/features/vehicles/freight_van/freight_van.gd`: `high_beams`, and
  `_cycle_headlights()` behind the `headlights` action (low, high, off).
- `van_presentation.gd`: `HIGH_BEAM`, `LOW_BEAM_RANGE`, `HIGH_BEAM_RANGE`,
  `_high_beams_shown` and `_aim_beam()`.
- `art/high_beam_pattern.png` (new, with its `.import`), made by
  `tools/make_high_beam_pattern.py` (new).
- `instruments.gd`: `LAMP_BLUE` and `_high_beam_symbol()`.
- **Tests:**
  - `game/tests/test_headlights.gd`: 14 checks, the L cycle and the patterns;
  - `game/tests/test_night_dimming.gd`: `_switch_headlights()`;
  - `tools/tests/first_drive_integration.gd`: the L cycle.
- **Tools:**
  - `tools/captures/capture_beams.gd` (new);
  - `capture_forest_road.gd` (L twice for off; `WIPER_PARK`);
  - `capture_cockpit.gd` (L twice for off).
- **Docs:** `CHANGE-BRIEF.md`, `docs/DESIGN_DECISIONS.md` (C25), `SOURCES.md`,
  `PERFORMANCE.md`, the prompt log (#52), the development log and the captures README.

## Run 16 step 3 commands and real results

| Command | Result |
| --- | --- |
| `python3 -I tools/make_high_beam_pattern.py` | `art/high_beam_pattern.png` written |
| `Godot --headless --editor --path game --import` | exit 0 (`logs/phase_1/run16/import_step3.log`) |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run16/step3` | 64/64, 0 failures, 92/92, 14/14, 12/12, 30/30 ×3, 22/22, 30/30, 12/12; art 0 failures |
| `test_headlights.gd` with L toggling again / with no high pattern | 11/14 and 13/14, exit 1 each (`logs/phase_1/run16/step3/mutation_*`) |
| `capture_beams.gd -- evidence/phase_1/beams/run16` (windowed) | road near/far: low 87.7/40.3, high 103.2/61.6, off 18.2/28.7; white-out 0.00%; about 60 FPS in each |

No log has a "SCRIPT ERROR", "SHADER ERROR" or "Failed loading resource" line. The only
other "ERROR:" lines are the engine's "resources still in use at exit".

## What the next run may rely on

- `vehicle.headlights_on` is true while either beam is on, and `vehicle.high_beams` says
  which. Code that only cares whether the lights are on keeps reading `headlights_on`.
- To reach "off" from low beams, press L twice; tests use `_switch_headlights()`.

## Waiting on the author (as it stood after step 3)

- The `CLAUDE.md` wording for the L key: approved and applied in step 4 (#53).
- Step 4, the moon roof: done in step 4.

## Files changed in Run 16, step 2

- `game/features/vehicles/freight_van/wiper.gd` (new): builds one wiper from code-made
  parts (`PivotCap`, `SpringCover`, `Arm`, `Hook`, and `Blade` with `Spoiler`, `Rubber`,
  `EndCapInner`, `EndCapOuter`, `Adapter`); exposes `blade`.
- `windshield_wipe_map.gd`: `ARMS`, `BLADES` and `span()` replace `BLADE_INNER` and
  `BLADE_OUTER`; `REWET_SECONDS` 2.0 and `SPEED_REWET` 10.
- `windshield.gdshader` (feature folder): uniforms `blade_speed`, `stroke_progress`, `dump`,
  `wiper_cycles`, `wiper_park`, `wiper_sweep`, `wiper_pivots`, `wiper_spans`; functions
  `stroke_index()`, `wipe_seed()`, `blade_water()` and `blade_blur()`; the film floor 0.08.
- `van_presentation.gd`: `WIPER_PIVOTS` removed; `WINDSHIELD_CENTRE`, `DUMP_SECONDS`,
  `Wiper`; `_on_glass()`, `_wiper_uniforms()` and `_blade_water()`; `_last_wiper` starts
  from the van's wiper angle.
- `freight_van.gd`: `wiper_cycles()`.
- **Tests:** `game/tests/test_wipers.gd` (new, 12 checks); `test_ghat_road.gd` (the pivot
  check measures the built wipers).
- `tools/captures/capture_wipers.gd` (new).
- **Docs:** `CHANGE-BRIEF.md`, `PERFORMANCE.md`, the prompt log (#51), the development log
  and the captures README.

## Run 16 step 2 commands and real results

| Command | Result |
| --- | --- |
| `Godot --path game --resolution 1280x800 --script ../tools/captures/capture_wipers.gd -- <scratch>` (windowed, before the change) | the old wipers: plain sticks; the wiped glass indistinguishable (`evidence/phase_1/wipers/run16_before/`) |
| `Godot --headless --editor --path game --import` | exit 0 (`logs/phase_1/run16/import_step2.log`) |
| every suite under "Test suite to rerun", plus `test_wipers.gd 60`, with `LOG_DIR=logs/phase_1/run16/step2` | 64/64, 0 failures, 92/92, 12/12, 12/12, 30/30 ×3, 22/22, 30/30, 12/12; art 0 failures |
| `test_wipers.gd` with `_blade_water()` not called / with the end caps removed | 10/12 and 8/9, exit 1 each (`logs/phase_1/run16/step2/mutation_*`) |
| `measure_performance.gd -- evidence/phase_1/performance/run16_wipers` (windowed) | 76.0 FPS parked, 74.3 FPS driving |
| `capture_wipers.gd -- evidence/phase_1/wipers/run16` (windowed) | 16 frames and two stroke sheets |

No log has a "SCRIPT ERROR", "SHADER ERROR" or "Failed loading resource" line. The only
other "ERROR:" lines are the engine's "resources still in use at exit".

## What the next run may rely on

- The wiper layout lives in `windshield_wipe_map.gd` (`PIVOTS`, `ARMS`, `BLADES`,
  `span()`); the presentation builds the wipers and feeds the shader from it.
- `test_wipers.gd` joins the suite to rerun.

## Remaining approved order (each step needs its own approval)

1. **Low and high beams on L.** The author: "when L is pressed once low beam should turn
   on, when pressed twice high beam, when thrice lights off." `headlights_on` keeps its
   meaning (any beam on), so the dimming, `LIGHTS` text and lamps still read it. The
   `CLAUDE.md` protection wording and the tests that press L change with this step, and
   are shown to the author first.
2. **Moon roof:** glass over the front seats, with the mouse look-up limit raised from 29°
   to about 60°. Needs Blender to open the roof.

## Unverified for step 2

- The author's own look in motion, on their display: the blur trail, the ridge, the dump
  and the refill are clearest moving, and the captures are 1280×800.
- The wipers on the fast setting, and turned off mid-stroke.

## Files changed in Run 16, step 1

- `game/features/environments/industrial_loop/industrial_loop.gd`:
  - new constants `DEPOT_YARD`, `DRIVEWAY`, `YARD_HEIGHT`, `YARD_GAP` and `DRIVEWAY_RAMP`;
  - new `_depot_ground()`, `_road_edge()` and `_edge_at()`; the two yard boxes are gone.
- `game/tests/test_ghat_road.gd`: the check "The depot yard stops at the road's edge" and
  its helper `_beyond_asphalt()`.
- **Docs:** `CHANGE-BRIEF.md`, the prompt log (#50) and the development log.

## Run 16 step 1 commands and real results

| Command | Result |
| --- | --- |
| `Godot --headless --editor --path game --import` | exit 0 (`logs/phase_1/run16/import.log`) |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run16` | 64/64, 0 failures, 92/92, 12/12, 12/12, 30/30 ×3, 22/22, 30/30; art 0 failures (`logs/phase_1/run16/summary.txt`) |
| `test_ghat_road.gd` with the driveway pushed 3 m onto the road | 29/30, exit 1 (`logs/phase_1/run16/mutation_depot_yard/`) |
| a scratch still script at the author's spot (windowed, about 20 s) | `evidence/phase_1/depot/run16/depot_road_after.png`; the road is continuous |

No log has a "SCRIPT ERROR", "SHADER ERROR" or "Failed loading resource" line. The only
other "ERROR:" lines are the engine's "resources still in use at exit".

## What the next run may rely on

- `IndustrialLoop/DepotYard` is the depot's ground: one indexed mesh, visual only. The van
  drives on the levelled terrain and the road's own collision, as before.
- `_road_edge(extra)` gives the road's south edge at any offset beyond the asphalt, built
  the same way as `_road_strip()`.

## Approved order for the rest of Run 16, as it stood after step 1

1. **Wipers.** The author: "They look like sticks", "Water doesn't react". (Done in step 2.)
2. **Low and high beams on L.** The author: "when L is pressed once low beam should turn
   on, when pressed twice high beam, when thrice lights off." `headlights_on` keeps its
   meaning (any beam on), so the dimming, `LIGHTS` text and lamps still read it. The
   `CLAUDE.md` protection wording and the tests that press L change with this step, and
   are shown to the author first.
3. **Moon roof:** glass over the front seats, with the mouse look-up limit raised from 29°
   to about 60°. Needs Blender to open the roof.

## Unverified

- The depot driveway in a played drive: turning in, and the look at speed.

## Files changed in Run 15

- `game/features/environments/industrial_loop/ghat_road.gd` (rewritten):
  - `WAYPOINTS` (38), `_curve()`, `_resample()`, `_elevate()` and `_widen()`;
  - new `laybys` and `is_layby()`;
  - the interface is unchanged: `points`, `half_widths`, `sections`, `length`,
    `heading_at()`, `grade_at()` and `is_hairpin()`.
- `ghat_dressing.gd` (new, with its `.uid`):
  - `build()`;
  - the counts `guardrail_segments`, `wall_segments`, `delineator_count` and
    `mirror_count`, and `signs` (kind, position, road index);
  - the drop rule `DROP`, `DEEP_DROP`, `DROP_PROBE` and `RAIL_INSET`.
- `hill_ground.gdshader` (new, with its `.uid`), in the feature folder.
- `hill_terrain.gd`: the shape constants (`VALLEY_EDGE`, `PLATEAU_EDGE`, `PLATEAU`,
  `PASS_X`, `PEAKS`, `PEAK_WIDTH`), and the `lowest` road surface under the asphalt.
- `industrial_loop.gd`:
  - the constants `TERRAIN_AREA`, `PLAYABLE_AREA`, `LUMBER_YARD`, `VIEW_CLEARINGS`,
    `SKYLINE_*`, `GLOW_*`, `LANDSLIDE_AT`, `SIGN_SETBACK` and `TOWN_LAMPS`;
  - `dressing`, `_hill_material()`, `_direction_sign()`, `_lumber_yard()`,
    `_town_windows()` and `_town_glows()`;
  - Run 14's `_barriers()` and its constants are removed.
- `art/road_signs.png` (new, with its `.import`), made by `tools/make_road_signs.py` (new).
- `polyhaven/textures/rock_wall_02/` (2k) and `rustic_stone_wall/` (1k), new, with their
  `.import` files. `POLYHAVEN.md` and `tools/assets/forest_road_assets.json` list them.
- `game/features/missions/night_freight/first_drive.gd`: `TARGETS`, `HEADINGS`,
  `DIRECTIONS` and `START`.
- `game/app/first_drive.tscn`: the van starts at (560, 0.1, 130), facing west.
- `game/features/vehicles/freight_van/freight_van.gd`: `WIPER_PARK`, `WIPER_SWEEP` and
  `WIPER_CYCLES`.
- `van_presentation.gd`: `WIPER_PIVOTS` and `BLADE_FLIP`; the new wiper parts in
  `_windows_and_wipers()`, and the blade rock in `update_vehicle()`.
- `windshield_wipe_map.gd`: `PIVOTS`, `BLADE_INNER` and `BLADE_OUTER`.
- **Tests:**
  - `game/tests/test_ghat_road.gd`: 29 checks (was 22);
  - `tools/tests/first_drive_integration.gd`: the park check reads `WIPER_PARK`.
- `tools/captures/capture_ghat.gd`: the Run 15 shot list.
- **Docs:**
  - `CHANGE-BRIEF.md`, `docs/DESIGN_DECISIONS.md` (C24), `PERFORMANCE.md` and `SOURCES.md`;
  - the prompt log (#49), the development log and the captures README.

## Run 15 commands and real results

| Command | Result |
| --- | --- |
| `python3 -I tools/make_road_signs.py` | 16 cells written to `art/road_signs.png` |
| `python3 -I tools/assets/fetch_polyhaven.py tools/assets/forest_road_assets.json` | the two new texture sets fetched and MD5-checked; existing files skipped |
| `Godot --headless --editor --path game --import` | exit 0, no error lines (`logs/phase_1/run15/import.log`) |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run15` | 64/64, 0 failures, 92/92, 12/12, 12/12, 30/30 ×3, 22/22, 29/29; art 0 failures (`logs/phase_1/run15/summary.txt`) |
| `test_ghat_road.gd` with `WIPER_PARK` set back to −0.9 | 28/29, exit 1 (`logs/phase_1/run15/mutation_wiper_park/`) |
| `Godot --path game --resolution 1280x800 --script ../tools/captures/capture_ghat.gd -- evidence/phase_1/ghat/run15` (windowed) | 14 stills and one overview; 68–119 FPS; at most 0.05% pure white outside |
| `… measure_performance.gd -- evidence/phase_1/performance/run15_ghat` (windowed) | 74.9 FPS parked, 76.0 FPS driving |

No log has a "SCRIPT ERROR", "SHADER ERROR" or "Failed loading resource" line. The only
other "ERROR:" lines are the engine's "resources still in use at exit" (1–3 per log).

The climb sign's text was corrected ("3 MI" to "3/4 MI") after the capture. The import and
every suite were rerun after it; the results above are from that rerun.

## What the next run may rely on

- `IndustrialLoop.road` is still the one source for the road. `road.is_layby()` marks the
  viewpoint.
- `IndustrialLoop.dressing` exposes its counts and `signs` for tests.
- The drop rule lives in `ghat_dressing.gd`. `test_ghat_road.gd` reads the same constants,
  so a change to the rule changes both.
- `WIPER_PIVOTS` (presentation) and `WipeMap.PIVOTS` must match; a test checks it.
- The mission's `START` is the one start, recovery and restart pose.

## Backlog from the author (#48: "remember to implement all these")

- **A moon roof that shows the sky:** today the sunroof is a shut panel from step 2.
- **Low and high beams:** a new control, which the author asked for.
- **Windshield rain as convincing with the lights on as with them off.** Falling rain in
  the beams is a particle effect, which the plan keeps for Assignment 6, so ask first.
- **Everything realistic.** Known gaps:
  - two rear-view mirrors: the Honda's own, and the old code-built one just beyond the
    windshield, in the rain;
  - the bottoms of lit tree trunks near the van look pale in the low beams.
- **Run 16:** headlight and rain checks on the hill, and a full played lap. The view over
  the valley is measured: 118.8 FPS.

## Waiting on the author

- Commit approval for Runs 1–15.
- Verdicts on Run 15's own calls: the lumber-yard start and the landslide (C24).

## Unverified

- A full lap driven by a person: hairpin speeds, the barriers' feel, and whether the
  20 MPH plates suit the van.
- The wipers moving at both speeds in a played drive (the stills show mid-sweep and park).
- The blinking flashers and the town glows in motion.
- What the convex mirrors show at night.
- The far slopes beyond the trees' 280 m drawing range, seen from the summit.

## Files changed in Run 14

- `game/features/environments/industrial_loop/ghat_road.gd` (new): the road's 31 pieces,
  `points` (every 2 m), `half_widths`, `sections`, `heading_at()`, `grade_at()` and
  `is_hairpin()`.
- `hill_terrain.gd` (new):
  - `build()`, `height_at()` and `road_clearance()`, the distance beyond the verge;
  - the hillside follows the road within 20 m;
  - shoulders, cuts and fills, levelled plots, tiles and a scaled `HeightMapShape3D`.
- `industrial_loop.gd`:
  - `road`, `terrain` and `playable_area`;
  - `_road_strip()` with real normals, `_barriers()` and `_flat_plots()`;
  - moved buildings and signs, and invisible boundary walls.
- `roadside_forest.gd` and `forest_floor.gd`: they take the terrain; heights, clearance,
  density and counts.
- `game/features/missions/night_freight/first_drive.gd`: `TARGETS`, `HEADINGS` and
  `DIRECTIONS`.
- `game/app/first_drive.gd`: `world`; it gives the map the road; `playable_area` bounds.
- `freight_van.gd`: `slope_pull()`.
- `van_presentation.gd`: `_follow_ground()`, and the mirror cameras follow the tilted body.
- `navigation_display.gd`: draws the real road.
- **Tests:**
  - `game/tests/test_ghat_road.gd` (new);
  - `test_materials.gd`: the window measured in the cab's frame.
- `tools/captures/capture_ghat.gd` (new).
- **Docs:**
  - `docs/DESIGN_DECISIONS.md` (C23) and `CHANGE-BRIEF.md`;
  - `PERFORMANCE.md`, the prompt log (#46–#48) and the development log.

## Run 14 commands and real results

| Command | Result |
| --- | --- |
| `Godot --headless --editor --path game --import` | exit 0 |
| every suite under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run14` | 64/64, 0 failures, 92/92, 12/12, 12/12, 30/30 ×3, 22/22, 22/22; art 0 failures |
| `test_ghat_road.gd` with slope gravity removed, or with no barriers | 21/22, exit 1 each (`logs/phase_1/run14/mutation_*`) |
| `capture_ghat.gd -- evidence/phase_1/ghat/run14` (windowed) | stills and the frame rate on the hill: 69–84 FPS |
| `measure_performance.gd -- evidence/phase_1/performance/run14_ghat` (windowed) | 79.4 FPS parked, 78.2 FPS driving |

## What the next run may rely on

- `IndustrialLoop.road` is the one source for the road. Every system reads it: the hill,
  the forest, the barriers, the map and the test.
- `IndustrialLoop.terrain.height_at(x, z)` gives the ground height anywhere, and
  `road_clearance(x, z)` the distance beyond the road's verge, capped at 20 m.
- The checkpoints are constants in the mission script. `test_ghat_road.gd` checks that
  they sit on the road.

## Unverified

- A full lap driven by a person: hairpins at real speeds, and the barriers' feel.
- The far slopes beyond the trees' 280 m drawing range, seen from the summit at night.

## Files changed in Run 13

- `game/features/vehicles/freight_van/art/cockpit/cockpit_front.gltf` and `.bin`,
  re-exported. Only two parts moved: `Cockpit_SteeringColumn_FrontL` (−5 cm in x) and
  `Cockpit_Screen_Cluster` (−3.5 cm). The textures are unchanged.
- `van_presentation.gd`: `WHEEL_HUB` x −0.57 and `CLUSTER_SCREEN` x −0.5563.
- `game/tests/test_cockpit.gd`: the expected hub position.
- `CHANGE-BRIEF.md` and `docs/AUTHOR_PROMPTS_AND_DECISIONS.md` (#46, #47).

## Run 13 commands and real results

| Command | Result |
| --- | --- |
| `Godot --headless --editor --path game --import` | exit 0; `cockpit_front.gltf` reimported |
| every suite listed under "Test suite to rerun", with `LOG_DIR=logs/phase_1/run13` | 64/64, 0 failures, 92/92, 12/12, 12/12, 30/30 ×3, 22/22; art 0 failures |
| `capture_cockpit.gd -- evidence/phase_1/cockpit/run13` (windowed) | 13 stills |

The re-export pipeline: Blender export (GLTF_SEPARATE, `textures/`, no tangents), then
`python3 -I postprocess.py <export> <final>` from the agent's scratch folder
(`cockpit_fit/hookup/`). Then copy only the changed `.gltf` and `.bin`.

## Next

The ghat road (#47: "real ghats i want"). It waits for the author's approval of the design.

## Files changed in Run 12

- **New art,** `game/features/vehicles/freight_van/art/cockpit/`:
  - `cockpit_front.gltf`, `cockpit_back.gltf`, `cockpit_roof.gltf` and `cockpit_wheel.gltf`,
    each with its `.bin`;
  - `textures/` (27 files, `configure_imports.py` settings);
  - `cockpit_shadow.glb` and `cockpit_wheel_shadow.glb`;
  - `ATTRIBUTION.md`;
  - the `.import` files.

  The wheel file is in its hub's frame, so it spins about its local Z axis.
- `game/features/vehicles/freight_van/van_presentation.gd`:
  - `COCKPIT_*`, `WHEEL_*`, `SCREEN_GAP`, `CLUSTER_*`, `MAP_*` and `MIRROR_SCREEN*`
    constants;
  - `_cockpit_part()`, `_shadow_stand_in()` and `_dash_screen()`;
  - the wheel's steering sign is fixed, and the door-mirror arms are shorter;
  - `CABIN_ART` and `STEERING_ART` are removed (the files stay).
- `game/features/vehicles/freight_van/cockpit_screen.gdshader` (new, with its `.uid`): a
  box-filtered, unshaded screen.
- **Tests:**
  - `game/tests/test_cockpit.gd` (new, with its `.uid`, 22 checks);
  - `tools/tests/check_first_drive_art.py`: a new cockpit section, the written exception.
- `tools/captures/capture_cockpit.gd` (new).
- **Docs:**
  - `SOURCES.md` (Alex Murias, CC BY 4.0), `CHANGE-BRIEF.md` and `PERFORMANCE.md`;
  - `docs/AUTHOR_PROMPTS_AND_DECISIONS.md` (#45).

## Run 12 commands and real results

| Command | Result |
| --- | --- |
| `Godot --headless --editor --path game --import` (then `python3 -I tools/assets/configure_imports.py game/features/vehicles/freight_van/art/cockpit`, then the import again) | exit 0; 27 textures VRAM-compressed with mipmaps, 9 as normal maps |
| `LOG_DIR=logs/phase_1/run12 scripts/run-test.sh first_drive_regression.gd 60` | 64/64, exit 0 |
| `… first_drive_integration.gd 60` | 0 failures, exit 0 |
| `… test_materials.gd 60` | 92/92, exit 0 |
| `… test_headlights.gd 60` | 12/12, exit 0 |
| `… test_rain_physics.gd 60` | 12/12, exit 0 |
| `… test_night_dimming.gd` 30 / 60 / 144 | 30/30 each, exit 0 |
| `… test_cockpit.gd 60` | 22/22, exit 0; with the old steering sign it fails 20/22, exit 1 (`logs/phase_1/run12/mutation/`) |
| `python3 tools/tests/check_first_drive_art.py` | 0 failures; cockpit 847,364 triangles, stand-ins 31,533 |
| `Godot --path game --script ../tools/captures/capture_cockpit.gd -- evidence/phase_1/cockpit/run12` (windowed) | 13 stills; wheel ±2.20 rad; reverse and lights-off shots |
| `measure_performance.gd`, A/B/A/B against a throwaway Run 11 copy (windowed) | parked 71.1 / 69.0 / 71.0 / 68.9 FPS, driving 68.1 / 65.2 / 68.0 / 65.0 FPS |

No log has a "SCRIPT ERROR", "SHADER ERROR" or "Failed loading resource" line. The engine's
"resources still in use at exit" lines are the same counts as at the start of the run.

## What the next run may rely on

- The cockpit is rebuilt in Blender by the scripts in the agent's scratch folder
  (`cockpit_fit/`), with the `.blend` copies (365 MB, so not in Git). The repository holds
  only the exported files. Re-exporting needs the same glTF settings (separate files,
  `textures/` folder, no tangents) and then the texture rename (`cockpit_<material>_<map>`).
- `test_cockpit.gd` locates screens by the viewport texture they show, so moving a screen
  keeps the test valid as long as it stays on its Honda screen.
- The cluster's own image and its night dimming are untouched, so the Assignment 5 cluster
  checks still read the same viewport.

## Unverified

- The author's own drive with the new cockpit (look, wheel feel, readability of the small
  cluster).
- From the driver's seat, about half of the right mirror screen is hidden behind the
  centre-screen housing.
- `CLAUDE.md` still says the cluster shows on "a QuadMesh with an unshaded
  StandardMaterial3D". It is now `cockpit_screen.gdshader` on the Honda driver display;
  the line waits for the author's OK to change.
- P9 (the 10-minute drive on a warm Mac).

## Files changed in Run 11

- `game/features/vehicles/freight_van/rain_drops.gdshaderinc`: `slip()` and `sky_view()`;
  `by_bin()` weights 45/30/17/8; `physical_layer()` with per-column pace and stick-slip.
- `windshield.gdshader`:
  - `runner()` events in 6 cm lanes, two phases, both directions;
  - the swept `track` that clears resting drops;
  - a `settled` layer, larger small drops, and the `sky_glow` uniform;
  - `runner_down` and `runner_up` replace `runner_travel`.
- `side_window_rain.gdshader`: uses `sky_view()`; `drop_radii` defaults are 1.6–3.8 mm.
- `rain_physics.gd`: `RADII` (1.6, 2.2, 3.0, 3.8) mm; `runner_down` and `runner_up`.
- `van_presentation.gd`: sends `drop_radii` (from `RainPhysics.RADII`), `runner_down` and
  `runner_up`.
- **Tests:** `test_materials.gd` (rain uniforms, runner counters);
  `test_rain_physics.gd` (12 checks).
- **Tools:** `tools/captures/capture_windshield_sequence.gd` (new): wipers off, then six
  frames 0.45 s apart.

## Run 11 results

- **Performance:** parked 71.1 FPS, driving 68.0 FPS.
- **Tests:** 64/64, 0 failures, 92/92, 12/12, 12/12, 30/30 ×3, art 0 failures.
- **Evidence:** `evidence/phase_1/rain/run11_runners/` (six frames and two debug frames).

## Files changed in Run 10

- `game/features/environments/industrial_loop/conifer_builder.gd`:
  - `MATURE_CROWN`, and a `crown` argument on `build()`;
  - a young-tree branch (under 6 m) in `trunk_radius()`, the stem length, whorl spacing,
    branch count, branch angle and top card.
  - Mature trees are unchanged.
- `roadside_forest.gd`: `SAPLINGS`, `SAPLING_*`, `EDGE_DEPTH`, `EDGE_BOOST`,
  `YOUNG_BARK_SHADE`, `_build_saplings()`, `_mark_edge()` and `_is_edge()`, and
  `sapling_count`. The blocked bitmap now uses value 2 for the road-edge band.
- `forest_floor.gd`: two clumped deep props and `PATCH_SEED`.
- `tools/captures/capture_forest_road.gd`: reports `saplings=`.
- `PERFORMANCE.md`: the Run 10 table.

## Run 10 results

- **Performance:** parked 71.7 FPS, driving 68.6 FPS (`PERFORMANCE.md`).
- **Forest:** 6,549 trees, 1,369 young firs and 14,430 ground props. The road reads 98.4
  with the lights on and 12.0 with them off.
- **Tests:** all suites pass (64/64, 0 failures, 92/92, 12/12, 11/11, 30/30 ×3, art 0
  failures).

## Next

The cockpit rebuild in Blender (C20). The author needs to commit the Sketchfab key in the
Blender panel by pressing Enter.

## Files changed in Run 9

- `game/features/environments/industrial_loop/roadside_forest.gd`: `NEAR_RANGE` 60;
  `SHADOW_RANGE` 50; `_multimesh()` and `_add_instance()`, with an explicit shadow
  setting.
- `forest_floor.gd`: `SHADOW_RANGE` 30, 24 m chunks, and `_instance()`.
- `industrial_loop.gd`: the moon's shadow reaches 40 m, orthogonal (one cascade).
- `game/features/vehicles/freight_van/van_presentation.gd`: `MIRROR_UPDATES_PER_SECOND`,
  `MIRROR_DISTANCE` and `MIRROR_LOD_THRESHOLD`; mirrors take turns.
- `game/project.godot`: `scaling_3d/mode.macos=4` and `scaling_3d/scale.macos=0.75`.
- `tools/captures/measure_performance.gd` (new); `PERFORMANCE.md` (new).
- `CLAUDE.md`: the `project.godot` rule notes the author's MetalFX approval.

## Run 9 results

- **Performance:** parked 73.4 FPS, driving 70.8 FPS (median 12.2 ms, slowest 5% 18.8 ms).
  The full table is in `PERFORMANCE.md`.
- **Tests:** suites as in Run 8; all pass (64/64, 0 failures, 92/92, 12/12, 11/11,
  30/30 ×3, art 0 failures).
- **Captures:** `evidence/phase_1/forest_road/perf_pass/`. The road reads 98.5 with the
  lights on and 12.1 with them off; white-out 0.00%.

## Next

The cockpit rebuild in Blender (C20). The Sketchfab Staria is imported as a local
reference only, and never committed.

## Files changed in Run 8

- `game/features/vehicles/freight_van/rain_physics.gd` (new, with its `.uid`):
  `drop_velocity()`, `film_velocity()` and `step()`.
- `rain_drops.gdshaderinc`: `physical_layer()`, `by_bin()`, and a `shape` argument on
  `drop_layer()`; `moving_layer()` removed.
- `windshield.gdshader`: uniforms `drop_radii`, `drop_travel`, `drop_speed`,
  `runner_radius`, `runner_travel`, `runner_speed` and `film_travel`; `water_flow` removed.
- `side_window_rain.gdshader`: uniforms `flow_dir`, `drop_radii`, `travel_x`, `travel_y`,
  `runner_radius`, `runner_travel` and `runner_speed`; `water_flow` removed.
- `van_presentation.gd`: `RainPhysics`, with two states (windshield and side windows)
  stepped each tick, and the constants `WINDSHIELD_RAKE`, `WINDSHIELD_AIR`, `SIDE_AIR` and
  `SIDE_AIR_DIRECTION`.
- **Tests:**
  - `game/tests/test_rain_physics.gd` (new, with its `.uid`).
  - `test_materials.gd`: rain uniforms `drop_radii` and `runner_travel`; the climb/slide
    check reads `runner_travel`.
- **Docs:**
  - `docs/AUTHOR_PROMPTS_AND_DECISIONS.md` (new);
  - `docs/DESIGN_DECISIONS.md` (C16–C19);
  - a link in `SOURCES.md`;
  - `CHANGE-BRIEF.md` and the development log.

## Test suite to rerun

```sh
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh first_drive_regression.gd 60
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh first_drive_integration.gd 60
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh test_materials.gd 60
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh test_headlights.gd 60
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh test_rain_physics.gd 60
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh test_night_dimming.gd 30   # also 60 and 144
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh test_cockpit.gd 60
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh test_ghat_road.gd 60
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh test_wipers.gd 60
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh test_on_foot.gd 60
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh test_oncoming_van.gd 60
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh test_collision.gd 60
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh test_crossing.gd 60
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh test_maya_call.gd 60
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh test_hit_speeds.gd 60
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh test_dash_screen.gd 60
LOG_DIR=logs/phase_1/<run> scripts/run-test.sh test_save_rules.gd 60
python3 tools/tests/check_first_drive_art.py
```

Run 8 results: 64/64, 0 failures, 92/92, 12/12, 11/11, 30/30 ×3, and art 0 failures. No
log has a "SCRIPT ERROR", "SHADER ERROR" or "Failed loading resource" line. Read each
RESULT line: the wrapper exits 0 even when a test file is missing.

## Waiting on the author

- **Blender:** quit fully (Cmd+Q) and reopen, so the protocol 15 add-on loads. Then Start
  MCP Server, and switch on Sketchfab with the token. After that, Claude Code imports
  cockpit A (Sketchfab `d499b10731194ae0b122a76e099eb2b5`) and renders its interior.
- **Visual verdict:** on the physically sized drops (`evidence/phase_1/rain/run8_*`).

## Files changed in Run 7

- `game/features/vehicles/freight_van/rain_drops.gdshaderinc`: `moving_layer()`.
- `windshield.gdshader`: rewritten around `water_flow`, with diverging flow, sliding and
  streaming drop layers, runners that turn upward, and the sheet moving with the flow.
- `side_window_rain.gdshader`: `water_flow`, sliding drops, and a flow that goes backward
  and slightly up at speed.
- `van_presentation.gd`: `WINDSHIELD_LIFT` (8–17 m/s) and `SIDE_WIND` (3–15 m/s). It adds up
  `_windshield_flow` (−0.1 to +0.45 m/s) and `_side_flow` (0.1 to 0.9 m/s) each tick.
- `game/tests/test_materials.gd`: `water_flow` in `RAIN_UNIFORMS`, plus the up-at-speed
  check (90 checks in total).
- `tools/captures/capture_rain_speed.gd` (new).

## Run 7 commands and real results

| Command | Result |
| --- | --- |
| `LOG_DIR=logs/phase_1/run7 scripts/run-test.sh first_drive_regression.gd 60` | 64/64, exit 0 |
| `… first_drive_integration.gd 60` | 0 failures, exit 0 |
| `… test_materials.gd 60` | 90/90, exit 0; water +0.225 m at 65 km/h, −0.050 m parked (0.5 s each) |
| `… test_headlights.gd 60` | 12/12, exit 0 |
| `… test_night_dimming.gd` 30 / 60 / 144 | 30/30 each, exit 0 |
| `python3 tools/tests/check_first_drive_art.py` | 0 failures |
| `Godot --path game --script ../tools/captures/capture_rain_speed.gd -- evidence/phase_1/rain/run7_speed` (windowed) | shots at 30.2, 45.4, 60.1 and 62.4 km/h; side window at 66.3 km/h; no "SHADER ERROR" |

The first `test_materials.gd` attempt hit a SCRIPT ERROR: it read `water_flow` before any
tick had set it. The test now runs one zero-length update first.

## Waiting on the author

- **Cockpit A (Hyundai Staria):** the licence risk was reported (see the development log),
  so the author must confirm before anything is downloaded.
- **Downloading needs one of two routes:**
  - the Blender add-on updated (`uvx mcp-for-blender install-addon`), with Sketchfab
    switched on and the token entered;
  - or a manual download from the model page into a folder the author names.

## Files changed in Run 6

- **Rain:**
  - `game/features/vehicles/freight_van/windshield_wipe_map.gd`: `REWET_SECONDS` 1.0, and
    faster with speed.
  - `windshield.gdshader`: a `fine` drop layer, denser medium and large drops, `rain` 1.0,
    and the water sheet.
  - `rain_drops.gdshaderinc`: `noise()`, and `wet_glass()` takes a `sheet` offset.
  - `side_window_rain.gdshader`: passes no sheet.
  - `van_presentation.gd`: `_water` starts at and settles to 0.6 with the wipers on.
- **Trees:**
  - `tools/make_conifer_cards.py`: rewritten to build both cards from the fir scan.
  - `art/conifer/conifer_branch_*` regenerated; `conifer_deadwood_diff.png` and
    `conifer_deadwood_nor_gl.png` are new, with `.import` files set by
    `tools/assets/configure_imports.py`.
  - `conifer_builder.gd`: `_crown_start()`, `build_deadwood()` and `_add_deadwood()`. Live
    crowns are unchanged.
  - `roadside_forest.gd`: a deadwood material and a 40 m deadwood layer without shadows.
- **Assets:**
  - `tools/assets/fetch_polyhaven.py`: a "maps" kind.
  - `tools/assets/conifer_scan_assets.json` (new).
  - `source_assets/polyhaven/` (new): three 2k JPEG maps, 3.6 MB, with `POLYHAVEN.md`.
- **Docs:** `SOURCES.md`, `CHANGE-BRIEF.md`, the development log and the captures README.

## Run 6 commands and real results

| Command | Result |
| --- | --- |
| `python3 -I tools/assets/fetch_polyhaven.py tools/assets/conifer_scan_assets.json` | 3.55 MB, MD5-checked |
| `python3 -I tools/make_conifer_cards.py` | branch: 7 sprays, coverage 0.244, mean colour (38, 49, 24); deadwood: coverage 0.068 |
| `Godot --headless --editor --path game --import` | exit 0 |
| `LOG_DIR=logs/phase_1/run6 scripts/run-test.sh first_drive_regression.gd 60` | 64/64, exit 0 |
| `… first_drive_integration.gd 60` | 0 failures, exit 0 |
| `… test_materials.gd 60` | 87/87, exit 0 |
| `… test_headlights.gd 60` | 12/12, exit 0 |
| `… test_night_dimming.gd` 30 / 60 / 144 | 30/30 each, exit 0 |
| `python3 tools/tests/check_first_drive_art.py` | 0 failures |
| `capture_forest_road.gd -- evidence/phase_1/forest_road/run6_final` (windowed) | road on 97.6, off 11.3 (8.67×); white-out 0.01%; 6,549 trees |
| `capture_rain.gd -- evidence/phase_1/rain/run6_final` (windowed) | no "SHADER ERROR" |

Frame rate, measured with a scratch script at 1280×800 (vsync off, parked, driver's view,
6 s after a 4 s warm-up):

| Hidden | FPS | Frame time |
| --- | --- | --- |
| nothing | 20.7 | 48.4 ms |
| `RoadsideForest` | 116.6 | 8.6 ms |
| `ForestFloor` | 30.0 | 33.4 ms |
| both | 203.6 | 4.9 ms |

## What the next run may rely on

- `Conifer.build()` produces the same live crowns as before.
  `Conifer.build_deadwood(height, seed, material)` builds only the dead branches.
- Card textures can be regenerated at any time with the two commands above.
- The author has not picked a cockpit yet. The options are in the final message of Run 6:
  Sketchfab `d499b10731194ae0b122a76e099eb2b5` (Staria),
  `52f919aedaa1497a9c0395ec0ac63af1` (Transit) and `814cf3f8cfd64594b1c4f96e873c3cef`
  (Honda e).

## Run 6 is unverified for

- the rain in a long windowed drive, and how the ripple feels in motion;
- the dead branches' visibility-range fade at 40 m while driving;
- the forest frame rate in motion (the parked view already misses P9 by a wide margin).

## Files changed in Run 5

- `game/features/vehicles/freight_van/rain_drops.gdshaderinc` (new, with its `.uid`): the
  drop layers (`drop_layer`, `strongest`) and the wet-glass shading (`wet_glass`), moved
  out of `windshield.gdshader` unchanged. A shader that includes it must declare `rain`
  and `scene_color` first.
- `windshield.gdshader`: includes the shared file. Same maths, same look.
- `side_window_rain.gdshader`: rewritten on the shared file. It is lit, with new uniforms
  `wetness` (0.75), `water_roughness` (0.22) and `sky_glow`; `rain` is 0.8.
- `van_presentation.gd`: the side-window rain layers sit 12 mm outside their glass, with
  `sorting_offset` -0.05.
- `game/tests/test_materials.gd`: 11 new checks (87 in total).

## Run 5 commands and real results

| Command | Result |
| --- | --- |
| `Godot --headless --editor --path game --import` | exit 0; created `rain_drops.gdshaderinc.uid` |
| `LOG_DIR=logs/phase_1/run5 scripts/run-test.sh first_drive_regression.gd 60` | 64/64, exit 0 |
| `… first_drive_integration.gd 60` | 0 failures, exit 0 |
| `… test_materials.gd 60` | 87/87, exit 0. With the rain moved back inside the glass: 86/87, exit 1 (`logs/phase_1/run5/mutation/`) |
| `… test_headlights.gd 60` | 12/12, exit 0 |
| `… test_night_dimming.gd` 30 / 60 / 144 | 30/30 each, exit 0 |
| `python3 tools/tests/check_first_drive_art.py` | 0 failures |
| `Godot --path game --script ../tools/captures/capture_side_window_rain.gd -- <folder>` (windowed) | `evidence/phase_1/side_window_rain/pass3` to `pass6`; no "SHADER ERROR" |
| `Godot --path game --script ../tools/captures/capture_rain.gd -- evidence/phase_1/rain/run5` (windowed) | windshield drops render as before; no "SHADER ERROR" |

`scripts/run-test.sh` exits 0 when the test file is not found, so read the RESULT line,
not only the exit code.

Run 5 is unverified for: the passenger window (same shader, not captured); drops
sparkling as the van passes lamps; and the frame-time cost of the lit side-window drops.

## Files changed in Run 2

- **Headlights:**
  - `game/features/vehicles/freight_van/van_presentation.gd`: `_mark_layer` now marks only
    meshes, so the lights stay visible to the driving camera. Low beams use energy 560,
    falloff 1.0, aim 2° down, a 35° half-angle, shadows on both lamps, and the pattern.
  - `art/low_beam_pattern.png`, made by `tools/make_low_beam_pattern.py`.
- **World:** `game/features/environments/industrial_loop/industrial_loop.gd`:
  - the road is 4.5 m wide (half-width 2.25) with gravel edges (3.4);
  - the centre dashes, roadside lamps and cone trees are gone;
  - building and prop footprints become clearings that the forest avoids;
  - moon 0.2, ambient 0.08, SSR on, AgX at exposure 1.3, fog `1f2b34` at 0.0045;
  - the sign reads "ONE LANE ROAD".
- **Road shader:** `wet_asphalt.gdshader` gains optional inputs (`aggregate_arm`,
  `arm_roughness`, `damp_gloss`, `texture_scale`, `crack_amount`). Their defaults keep
  the depot yard unchanged.
- **Forest:**
  - `roadside_forest.gd`: jittered placement, 48 m tiles with a near version (up to 90 m)
    and a far version (90–280 m), and trunk colliders inside the barriers;
  - `conifer_builder.gd`: trunk plus crossed branch cards;
  - `conifer_needles.gdshader`: alpha cut-out, wind sway, light through needles;
  - `art/conifer/`, made by `tools/make_conifer_cards.py`.
- **Textures:** `polyhaven/`, four CC0 sets fetched with
  `tools/assets/forest_road_assets.json`; `POLYHAVEN.md` lists checksums and authors.
- **Mission:** `game/features/missions/night_freight/first_drive.gd` and
  `game/app/first_drive.tscn`: start, checkpoints and recovery moved to the lane's centre
  line, and "Keep right." dropped.
- **Tools:**
  - `tools/assets/configure_imports.py` also handles `.png` files;
  - `tools/captures/capture_forest_road.gd` blocks real mouse and keys and measures
    projected road pixels.
- **Tests:** new `game/tests/test_headlights.gd`.
- **Documents:**
  - `CLAUDE.md`: scope;
  - `CHANGE-BRIEF.md`: revision;
  - `SOURCES.md`: credits;
  - the captures README and the development log.

## Commands and real results

Godot 4.7.2, macOS, Forward+. Logs are in `logs/phase_1/run2_final/`.

| Command | Result |
| --- | --- |
| `LOG_DIR=… scripts/run-test.sh first_drive_regression.gd 60` | 64/64, exit 0 |
| `… first_drive_integration.gd 60` | 0 failures, exit 0 |
| `… test_materials.gd 60` | 76/76, exit 0 |
| `… test_headlights.gd 60` | 12/12, exit 0. It was 7/12 before the fix, and 10/12 with the fix undone |
| `… test_night_dimming.gd` 30 / 60 / 144 | 30/30 each, exit 0 |
| `python3 tools/tests/check_first_drive_art.py` | 0 failures |
| `Godot --path game --script ../tools/captures/capture_forest_road.gd -- <folder>` (windowed) | 6,549 trees and 3,422 colliders. The road reads 62.6 with the lights on and 16.9 with them off (3.71×); white-out 0.00% |

No log has a "SCRIPT ERROR", "SHADER ERROR" or "Failed loading resource" line. Each still
has the engine's "resources still in use at exit" line, as at the Assignment 5 baseline.

## What the next run may rely on

- The forest is generated at start-up from a fixed seed. `IndustrialLoop.forest` exposes
  `tree_count` and `collider_count`.
- The branch cards can be swapped for baked ones by replacing the two files in
  `art/conifer/`. The tree builder does not change.

## Unverified

- Scan-quality tree cards: Blender was not connected ("Could not connect to Blender").
- The rain in motion at different speeds, which needs a windowed drive.

- Frame rate in a played, windowed drive on the M4 (P9). The forest adds about 6,500
  instanced trees.
- The look when driving: wind sway, LOD switching at 90 m, and collisions with trunks.
- The author's verdict on the forest road stills, and on the window fog under Forward+.
