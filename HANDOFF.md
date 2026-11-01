# HANDOFF.md

**Last run:** Phase 1, Run 19 (on foot, the oncoming van, the collision; C27–C29), all four
steps done, 2026-10-31, on branch `develop`. At the author's request ("commit and push to
develop", #71), Run 19 is committed in the commit after `b1e5785`, and `develop` is pushed to
`origin`. `main` is untouched. Final logs: `logs/phase_1/run19/step4/`.

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
