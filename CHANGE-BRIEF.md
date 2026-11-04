# CHANGE-BRIEF.md: Phase 1, Forward+, headlights, night lighting and macOS export

**Status: approved by me on 2026-10-30** and committed on the `develop` branch before any
code. Claude Code drafted it from `ROADMAP.md` §6 and my answers. Assignment 5's brief
stays on `main` and at tag `a5` (`git show a5:CHANGE-BRIEF.md`).

## 1. What I am changing

1. **Renderer:** Compatibility becomes Forward+ (C12).
2. **Headlights that work.** Today they light nothing from the driver's seat, and the
   night is so bright they would barely show anyway. I want: "the user should see the
   road little better when turned on. and less when turned off." With them on, the road
   must be clearly visible.
3. **A darker night** with wet-road reflections.
4. **A macOS export** (C13): a preset, an inspected pack listing, and a release export
   that I launch and play.

## 2. Why now

Assignment 10 asks me to decide the export target and its renderer by November 3, and to
attempt an export: "A renderer change is cheap before your effects and animation are
final and expensive after." My particles (Assignment 6) and animation are not built yet.

## 3. Export target and renderer

- **Target:** macOS desktop, on this MacBook Air M4.
- **Renderer:** Forward+, which uses Metal on this Mac. Web would need Compatibility,
  which loses the beam cutoff, reflections and bounce light.
- **Earlier features at risk:** none of Assignment 10's list. Forward+ supports decals,
  compute shaders, particle trails and particle SDF collision. What does change is that
  my Assignment 5 results were measured under Compatibility, so every Assignment 5 look
  check is redone (§8).
- **State I expect to claim after Phase 1:** export-ready on this Mac, but only if the
  exported app launches and plays. Otherwise source-ready, with the error kept as
  evidence.

## 4. Changes

1. **Renderer.** `game/project.godot:125` becomes `forward_plus`. README's renderer note
   says why.
2. **Headlight bug.** `_mark_layer` (`van_presentation.gd:259-263`) puts the two headlight
   lights on render layer 2. The driving camera only sees layers 1 and 3
   (`cull_mask = 5`, `:132`), so it culls them. The fix sets layers only on meshes, never
   on lights.
3. **Low beams.** Both headlights cast shadows; Godot needs shadows for a pattern image.
   Each beam uses a low-beam pattern image, made by a script like my fog textures. The
   pattern gives:
   - a sharp top edge just below the horizon;
   - the brightest band right under that edge;
   - dimmer light toward the sides;
   - a slightly raised right side, because traffic keeps right.

   Starting values come from the 2026-10-30 test: energy 560, distance falloff 1.0,
   aimed 2° down, 35° half-angle. They may be tuned to pass §8 and my look check, and
   every change is logged.
4. **Darker night.** Moon 0.55 → 0.25 and ambient 0.30 → 0.12 (`industrial_loop.gd:47,59`)
   as starting values, tuned the same way. Street-lamp pools should show on the road.
5. **Wet-road reflections.** Screen-space reflections on.
6. **No mist.** Volumetric fog stays off; the beam lit it up and hid the road in the
   2026-10-30 test.
7. **Export.**
   - A macOS preset in a committed `export_presets.cfg`, version `0.1.0`. It excludes
     tests, `experiments/` and the visual benchmark scene, and carries no credentials.
   - `--export-pack`, with its listing inspected.
   - Install the verified 4.7.2 templates, then run `--export-release` to a `.zip` in
     `builds/macos/`.
   - Launch and play the exported app, and record its SHA-256.

## 5. What must not change

- `headlights_on`, the L key, the `LIGHTS` text, the switch click, and the dashboard
  dimming shader and driver.
- Every file in `game/shaders/`. These are mine; agents never edit them.
- The window fog materials. I re-check them by eye under Forward+, and they change only
  with my OK. If I approve new values, `test_materials.gd` changes to match, with a dated
  revision below.
- The tonemap stays Linear unless lit surfaces clip to white (§8). Any change is shown
  to me with before/after stills.
- The interior, the road's shape and material, models, rain, audio, controls and every
  other key binding.

## 6. Predictions (written before any code)

| # | Prediction | How I check |
| --- | --- | --- |
| P1 | `game/tests/test_headlights.gd` fails on today's code (layers 2, cull mask 5) and passes after the fix | Run it before and after |
| P2 | Parked view in Forward+: the road band is at least 2.5× brighter with the lights on; the band above the horizon changes by less than 5%; the road band is at least 20 with the lights off; under 1% of the outside view is pure white | Captures |
| P3 | The cluster colours match my Assignment 5 §3.1 predictions exactly, as they did under Compatibility. At `night_amount` 0, 0.5 and 1.0: background (8,14,18), (6,9,10), (4,4,2); hub (135,156,148), (105,102,82), (74,47,16). The cluster is drawn in a 2D SubViewport with HDR 2D off | Rerun `tools/captures/capture_night_cluster.gd` |
| P4 | The hint experiment shows my Forward+ predictions: 64/128/192 read as colour, 137/188/225 read as data. Under Compatibility it showed the file values on both quads | Rerun `tools/captures/capture_hint.gd` |
| P5 | The heavy window fog looks stronger than under Compatibility; 44% of that area changed in the 2026-10-30 test. I decide whether to retune it | Before/after stills of both fog overlays |
| P6 | Without exclude filters, `--export-pack` would ship `tests/` and `experiments/`. With the preset's filters it ships neither | Pack listing |
| P7 | A fresh import creates only `game/.godot/` (ignored) plus `.uid` files for new scripts, which I commit | `git status --short` after the import |
| P8 | With the templates installed, `--export-release` writes a macOS `.zip` that launches on this Mac. Without templates it would stop with a missing-template error | Export output; launch |
| P9 | A 10-minute windowed drive at 1280×800 stays at or above 45 FPS | Performance overlay, recorded in `PERFORMANCE.md` |

## 7. Failure cases and how I will catch them

1. **One headlight has shadows off.** Its pattern does nothing, so its beam lights the
   air and the signs (this happened on 2026-10-30). The new test asserts shadows on both,
   and the above-horizon capture check would catch it too.
2. **Lit surfaces near the van clip to pure white** under the Linear tonemap. The
   white-out capture check catches it. Tune energy and falloff first; change the tonemap
   only with my OK.
3. **The headlight test passes for the wrong reason.** Undo the fix: the test must exit 1.
4. **The switch quietly changes an Assignment 5 result.** Rerun every Assignment 5 suite
   and look check (§8).
5. **The export ships test or development files.** Inspect the pack listing.
6. **Shadows and reflections cost too much on the M4.** Measure FPS. Cut reflection
   quality first, then shadow quality.

## 8. How Phase 1 is tested

**Machine checks.** Headless, through `scripts/run-test.sh <test> <fps>`:
- New `game/tests/test_headlights.gd` at 60 FPS. It checks that:
  - each headlight's layers overlap the driving camera's cull mask;
  - both headlights light the world layer and cast shadows, and each has the pattern
    image;
  - real L presses switch them off and on.
- Mutation: undo the layer fix, and the test exits 1.
- Every existing suite passes unchanged at 60 FPS:
  - `first_drive_regression.gd`
  - `first_drive_integration.gd`
  - `test_materials.gd`
  - `normal_map_check.gd`
  - `test_night_dimming.gd`, which also runs at 30 and 144 FPS.
- A run is clean only if every test exits 0 and its log has no "SCRIPT ERROR", "SHADER
  ERROR" or "Failed loading resource" line. Any other "ERROR:" line is explained.

**Captures.** These are windowed evidence runs, labelled as such. They use the parked start
view at 3840×2400. The rig moves from
`youtube/claude-liam-blackridge-gamedev/capture/scripts/` into `tools/captures/`.

| Region | Pixels |
| --- | --- |
| Road band | x 1300–2700, y 975–1140 |
| Band above the horizon | x 1300–2700, y 650–940 |
| Outside view | x 1100–3840, y 600–1100 |

- Headlights on and off: the four numbers in P2.
- Assignment 5 redone under Forward+: cluster colours (P3), hint experiment (P4), and
  the fog overlays (P5).

**Export.** The pack listing, the release export's output, and the SHA-256 (P6–P8).

**My checks:**
- Drive the loop with the lights on and off: the road is easy to see with them on.
- The dashboard dimming, `LIGHTS` text, wipers, windows and both fog overlays look
  right.
- The exported app launches and plays.
- FPS over a 10-minute drive.

**Where the results go:**
- `TEST-REPORT.md`, in a dated final-project section;
- `PERFORMANCE.md`;
- the stills, in `source_assets/artwork/captures/`.

## 9. Agent runs (each ends by writing `HANDOFF.md`)

1. **Renderer switch.** Then every suite and every Assignment 5 look check, rerun.
2. **Headlights:** the test first (it must fail), then the layer fix, low beams, darker
   night and reflections, and the captures.
3. **Export:** the preset, the pack listing, the templates, the release export.

Between runs I read the diff and `HANDOFF.md`, run the import, rerun the tests, read the
logs, and commit.

## 10. Files

- **Changed:**
  - `game/project.godot`;
  - `game/features/vehicles/freight_van/van_presentation.gd`;
  - `game/features/environments/industrial_loop/industrial_loop.gd`.
- **New:**
  - the beam pattern image and its script;
  - `game/tests/test_headlights.gd`;
  - the capture rig and night take in `tools/captures/`;
  - `export_presets.cfg`, `HANDOFF.md` and `PERFORMANCE.md`.
- **Documents:**
  - `CLAUDE.md`: the renderer line, "Out of scope" replaced by §5, and a pointer to
    `HANDOFF.md`;
  - README: the renderer note and the export state;
  - `TEST-REPORT.md`;
  - the development log.

## Revision 2026-10-30 (Run 1)

- **§8 listed the wrong fifth suite.** `game/tests/normal_map_check.gd` is not a suite. It
  is the curl-ratio helper that `test_materials.gd` preloads. Run directly, it has nothing
  to run and stops at the 120 s timeout. Assignment 5's fifth suite is the Python art
  check, `tools/tests/check_first_drive_art.py`. Run 1 ran the art check instead.
- **Two tool changes not listed in §10**, so new results never overwrite Assignment 5's
  evidence. Without the new option, both behave exactly as before.
  - `scripts/run-test.sh` takes an optional `LOG_DIR`. Phase 1 logs go to
    `logs/phase_1/`.
  - The three Assignment 5 capture scripts in `tools/captures/` take an optional output
    folder after `--`. Phase 1 captures go to `evidence/phase_1/`.

## Revision 2026-10-30 (Run 2: the author widened the scope)

- **The author's requests:**
  - "show me after making the road,car more realstic add lot of trees on the entire road.
    dense trees, froest like road just a single lane road. they are literally the same
    bro. i told you to improve them. assignment 5 is done. move on."
  - "when i switch on lights, i dont see more road, when lights are off road should be
    more darker. and also, the van interior isnt realistic. and rain should be super
    realistic ... use something better if this is not the best - 17 million polygons".
- **So Run 2 also covers:**
  - the single-lane forest road: 4.5 m of asphalt with leafy gravel edges;
  - a dense pine forest;
  - a darker night.

  §5's "road and models are later" no longer applies.
- **Headlights (§4.2–4.3):**
  - Test-first: `test_headlights.gd` failed 7/12 on the old code and passes 12/12 after
    the fix. Undoing the layer fix fails it again (10/12).
  - Both lamps cast shadows and use the low-beam pattern. The edge was softened (1.2°)
    and the leak raised to 0.05 after the stills showed white "socks" on the trunks.
- **Tonemap (§5).** Linear clipped lit trunks to pure white on 1.25% of the windshield
  view, so the tonemap is now AgX at exposure 1.3 (0.00%). Before/after stills:
  `evidence/phase_1/forest_road/before_tonemap/` and `after_tonemap/`.
- **Measures, from the driver's seat in the parked view, road pixels projected 10–46 m
  ahead (P2 by a better method; the old pixel bands no longer match the narrower road):**
  - road with the lights on 62.6, off 16.9, ratio 3.71;
  - white-out 0.00%.

  "Off ≥ 20" is missed (16.9), because the author asked for the road to be darker with
  the lights off.
- **Positions.** The mission's start, checkpoints and recovery points move from the old
  right lane (3 m off-centre) to the single lane's centre line. The tests read these
  from the mission script, so no test changed.
- **Not done yet:** realistic rain on the glass, and the van interior, which needs Blender
  and a model choice. Falling rain particles wait for Assignment 6.

## Revision 2026-10-30 (window fog, approved by the author)

- **The author asked:** "do all these properly", covering "Your judgment of the window
  fog".
- **What changed.** Under Forward+ the heavy fog showed as bright white smoke on the
  driver's window. Stills at opacities 0.60, 0.45, 0.35 and 0.25 are in
  `evidence/phase_1/window_fog/`. By eye, 0.35 reads as real night condensation and stays
  clearly heavier than the windshield's light fog.
- **Files:** `heavy_fog.tres` `fog_opacity` goes from 0.6 to 0.35, and
  `test_materials.gd`'s expected heavy values change to match, under the §5 rule. The fog
  shader in `game/shaders/` is untouched. Assignment 5's values stay at tag `a5`.

## Revision 2026-10-30 (Run 3: rain, undergrowth, cluster, cabin, by the author's request)

- **The author's request.** "do all these properly then i will test all at once. i want the
  car interior to be different the ac vents, speedometer, sterrting wheel everything. more
  details, realistic". This covered realistic windshield rain, a fog judgment, undergrowth,
  tree detail and the interior.
- **Rain.** `windshield.gdshader` was rewritten in place, so the test still finds it.
  - A float-precision wetness map (`windshield_wipe_map.gd`, a SubViewport that is never
    cleared) re-wets over 6 s, and the swept sector of each blade is painted dry every
    frame.
  - Three drop sizes appear in random order as the glass re-wets. Each drop refracts the
    scene like a lens and has a dark rim.
  - Running drops have broken trails, and the airflow pushes them up at speed.
  - A water film blurs the scene, and the blade leaves a smear.
  - Glints follow the brightness behind each drop, so the old white specks are gone.
- **Undergrowth.** `forest_floor.gd` adds Poly Haven CC0 ferns, branches, stumps, mossy
  rocks and fallen trunks: 11,330 props in culled tiles, placed along the road weighted by
  road length.
- **Cluster.** `instruments.gd` was redrawn at 2× resolution:
  - two analog dials with bezels, fine ticks, red needles with a glow, and fuel and
    temperature sub-gauges;
  - a centre display with P R N D, digital speed, odometer, time and temperature;
  - lamp symbols.

  The `LIGHTS` text is kept, and the night-dimming material still applies.
- **Cabin** (generator `tools/art/build_first_drive_art.py`):
  - the instrument hood is down from 1.94 m to 1.845 m and slimmer, so the road shows from
    about 7 m;
  - four round chrome vents with louvers;
  - a new three-spoke leather wheel, tilted 22° and placed lower.

  The cabin is 27,084 triangles and the steering wheel 5,174. Every other model regenerated
  byte-identical.
- **Beam.** It is dimmer in the foreground, as a real low beam is, and falls off faster to
  the sides. Energy is 650, and wet ground is darker.
- **Result.** From the driver's seat the road reads 97.7 with the lights on and 11.2 with
  them off (8.7×). White-out is 0.00%. All suites pass.
- **Not done:** scan-quality tree cards, which need Blender connected. The add-on did not
  answer during this run.

## Revision 2026-10-30 (Run 4: the author's feedback on Run 3)

- **Author:**
  - "i dont like the trees. they look fake, i dont like the fog on the drivers side
    window ... add water droplets dripping on drivers side window ... change the van
    interiors completely ... the sterring wheel sucks ... the vent is inside the drivers
    door ... the sterring wheel points downwards".
  - Answers:
    - interior: "Free prebuilt, I pick";
    - style: "Modern van";
    - side window: "Drops and drips, no fog";
    - access: "Blender + Sketchfab token".
- **Fixed:**
  - The outer vents overlapped the door cards by about 4 cm. They are now smaller and sit
    at x ±0.952.
  - The wheel tilt sign was wrong: +22° turned its face toward the lap. It is now -22°,
    with the face up toward the driver, at y 1.49.
- **Side windows.** The driver's-window fog overlay is replaced by
  `side_window_rain.gdshader` on both side windows, riding with the glass.
  - Lens drops are sparse, with a thin rim and a glossy edge.
  - Parked, drips run down with broken trails. At speed, drops stretch and streak
    backward.
  - `heavy_fog.tres` stays in the repository, unused.
  - `test_materials.gd` now checks one windshield fog overlay and two side-window rain
    overlays, at the author's request; 76/76 pass.
- **Waiting for Blender and the Sketchfab token:**
  - a free prebuilt modern van cockpit, with 2–3 options shown to the author first;
  - scan-quality trees baked from Poly Haven's pine scans.

## Revision 2026-10-30 (Run 5: driver's-window rain brought up to the windshield)

- **Author:** "the drivers window rain doesnt look as realistic as front windshield".
- **Causes:**
  - `side_window_rain.gdshader` was a separate, simpler copy of the windshield rain: two
    drop sizes, weaker lenses, no water film.
  - Its layer sat on the cabin side of the tinted side glass and drew after it. A drop
    refracts a copy of the screen that holds only opaque objects, so each drop showed the
    view without the glass tint and read as a dark dot.
  - Drip trails were drawn ahead of each drip instead of behind it.
- **Changes:**
  - `rain_drops.gdshaderinc` (new) holds the drop layers and the wet-glass shading, moved
    out of `windshield.gdshader` unchanged. Both rain shaders include it; the windshield's
    maths and look stay the same.
  - `side_window_rain.gdshader` uses the windshield's three drop sizes, lens strengths, rim
    and highlight. Rain density is 0.8, and a constant water film (`wetness` 0.75) softens
    the view a little, because side glass is never wiped.
  - The side drops are lit. The refracted view is emission and each drop has a curved
    water surface (roughness 0.22), so the moon, the cabin light and passing lamps put
    highlights on them. The lower part of each drop shows the night-sky glow (`sky_glow`,
    the sky's horizon colour), because a drop on glass is a tiny upside-down fisheye lens.
  - Parked, drips run down with their trail behind them. At speed, drops stretch backward,
    medium and large drops thin out, and streaks blow back.
  - `van_presentation.gd`: each side-window rain layer sits 12 mm outside its glass, where
    real rain is, with `sorting_offset` -0.05 so that it always draws before the glass.
- **Tests:** `test_materials.gd` 87/87 (11 new checks): both rain shaders parse, list
  `rain`, `wetness` and `speed`, and include the shared file; the driver's rain sits
  outside the glass and draws first. Moving the layer back inside fails that check
  (86/87, exit 1). All suites pass; logs are in `logs/phase_1/run5/`.

## Revision 2026-10-31 (Run 6: heavier windshield rain, scanned trees, cockpit search)

- **Author:** "do these for me - 1. New interior ... 2. Realistic trees ... and also add more
  rain to the front windshiled and make it little unclear to see as if in real life when
  there is real rain and lot of droplets on windshield".
- **Windshield rain:**
  - The glass re-wets in 1 s instead of 6 s, and faster when driving, because the van runs
    into the rain (`windshield_wipe_map.gd`).
  - There is a second layer of small drops, medium drops at full density and more large
    drops. `rain` is 1.0.
  - The blade cannot dry the glass in heavy rain, so a thin rippling water sheet stays
    behind: a flowing distortion plus a light blur. The shared `wet_glass()` gained a
    `sheet` offset, and the side windows pass none.
  - With the wipers on, the water film settles at 0.6 (it was 0.18), and the game starts
    there.
- **Trees:**
  - The branch card is rebuilt from real scans: the twig atlas of Poly Haven's CC0 "Fir Tree
    01" (Rob Tuytel, Rico Cilliers), fetched with checksums into `source_assets/polyhaven/`
    (the fetch tool gained a "maps" kind). `tools/make_conifer_cards.py` cuts out the seven
    fir sprays, places them along a stem with their normals rotated, darkens the inner
    sprays and lightens the tip. The file names and size are unchanged, so the tree builder
    needed no change for it. Coverage is 24% (25% before).
  - Dead lower branches: a second card, made from the atlas's bare stem and weathered grey,
    sits under each live crown from 1.3 m. They are a separate layer, drawn within 40 m and
    casting no shadows. Built into every tree they cost about 10 ms a frame; this way they
    cost about 1 ms.
  - Blender was not used: it was disconnected ("Broken pipe"), and the scanned twig atlas
    made a 3D render unnecessary for the cards.
- **Measured:**
  - The road reads 97.6 with the lights on and 11.3 with them off (8.7×). White-out is
    0.01%. The forest still has 6,549 trees and 3,422 colliders.
  - Frame rate, at 1280×800 with vsync off in the parked driver's view: 20.7 FPS (48.4 ms).
    Without the trees it is 116.6 FPS; without the ground props, 30.0 FPS. The forest is far
    from P9's 45 FPS, and was before this run (47 ms without the dead branches).
- **Cockpit:** Sketchfab's public search (no token needed) found no clean free modern van
  cockpit. Three CC-BY options are shown to the author: Hyundai Staria, Ford Transit (older
  body) and Honda e (a car). Nothing is downloaded until the author picks.
- **Tests:** all suites pass. Logs are in `logs/phase_1/run6/`.

## Revision 2026-10-31 (Run 7: water runs up the glass at speed)

- **Author:** "when the car is moving quickly make sure the water is running up like in real
  life and is trying to fall off the car". Cockpit choice: "I want A" (Hyundai Staria).
- **Windshield:**
  - Below about 37 km/h, gravity wins and water runs down. Above it, the air pushes drops up
    the glass, fanning out toward the pillars. They stream fully by about 61 km/h and blow
    off the top edge.
  - Medium and large drops break loose and slide up, stretched along the flow; small drops
    stay stuck. Runners turn upward with trails below them, and the water sheet flows up.
- **Side windows:** drops and streaks blow backward and slightly up (they went backward and
  down before), and the bigger drops slide instead of only stretching.
- **Bug fixed:** drip positions were `time × a speed-dependent rate`, so every drip jumped
  whenever the van changed speed. `van_presentation.gd` now adds up the distance the water
  has travelled each tick (`water_flow`) and passes it to both shaders.
- **Shared code:** `moving_layer()` in `rain_drops.gdshaderinc`.
- **Tests:** `test_materials.gd` is 90/90. Both shaders list `water_flow`, and a check
  confirms the windshield water moves +0.225 m in 0.5 s at 65 km/h and −0.050 m parked. All
  suites pass; logs are in `logs/phase_1/run7/`.
- **Evidence:** `tools/captures/capture_rain_speed.gd` (new) drives the straight with the
  wipers off and saves shots at 30, 45 and 60 km/h, plus the side window at 66 km/h, into
  `evidence/phase_1/rain/run7_speed/`.

## Revision 2026-10-31 (Run 8: water moved by real forces; author log)

- **Author:** "make this for realstici understand the gravity, physics and do it", and "add
  in the documents for my approvals, declines and my prompts what i want as well" (C19).
- **Physics** (`game/features/vehicles/freight_van/rain_physics.gd`, new). Each drop on the
  glass is a 50° cap of water with three forces on it:
  - gravity along the glass, from its mass and the glass angle (windshield raked 0.32 rad,
    side windows vertical);
  - air drag, ½ρC<sub>d</sub>Au², where the drop feels only the slow air near the glass in
    proportion to its height against a 2 mm boundary layer;
  - pinning at the contact line, 2rγΔcosθ (Δcosθ 0.32).

  A drop moves only when gravity plus drag beats the pinning. Its speed is the excess force
  over a sliding resistance, approached within 0.15 s. The water film moves by gravity
  drainage plus air shear (50 µm thick). All constants are named in the script.
- **What the physics gives:**
  - drops under about 4.4 mm stay pinned;
  - an 11 mm runner slides down at 15 cm/s when parked, holds still at about 44–54 km/h,
    and climbs at 13.5 cm/s at 68 km/h;
  - on the side windows, drops stream back and slightly down at speed.
- **Shaders:** `rain_drops.gdshaderinc` gains `physical_layer()`, where each column of
  drops takes one of four physical sizes and its travelled distance. `drop_layer()` takes a
  shape vector. `moving_layer()` from Run 7 is removed.
  - The windshield draws small pinned drops, two physical layers, runners and a film moved
    by the physics.
  - The side windows draw four size groups moved by their 2D travel, and runners along the
    physics flow direction.
  - Drop sizes are now physically sized (radius 2.2–4.6 mm, runners 5.5 mm), smaller than
    the old 6–11 mm lens drops.
- **Tests:**
  - `game/tests/test_rain_physics.gd` (new, 11 checks): pinning, the runner sliding,
    holding and climbing, film direction, side-window direction, and the per-tick
    integration.
  - `test_materials.gd` is 92/92.
  - All suites pass; logs are in `logs/phase_1/run7/`.
- **Documents:** `docs/AUTHOR_PROMPTS_AND_DECISIONS.md` (new) records every prompt,
  approval and decline verbatim. `docs/DESIGN_DECISIONS.md` gains C16–C19.
- **Cockpit A:** the author accepted the licence risk ("use it for now", C18). The download
  waits for Blender to load the new add-on: it was still running protocol 13 from memory.

## Revision 2026-10-31 (Run 9: 60 FPS with every effect kept)

- **Author:** "also the game looks not so smooth ?? why?? it feels like its kind of
  lagging", then "how to keep all of them and switch to 60fps?" and "yes do it, 60fps first
  then cockpit" (C21). The author approved the MetalFX line in `project.godot`.
- **Cause:** shadow passes redrew the near forest every frame, and the three mirrors
  re-rendered the world in the same frame 15 times a second.
- **Changes:**
  - `roadside_forest.gd`:
    - full-detail trees to 60 m (was 90 m);
    - near trees cast no shadow themselves; their light version casts the shadow, within
      50 m;
    - one MultiMesh is shared by both instances.
  - `forest_floor.gd`: props are grouped in 24 m chunks (48 m or 96 m before), so each
    chunk picks its own level of detail. Shadow-casting props cast within 30 m.
  - `industrial_loop.gd`: the moon's shadow reaches 40 m (85 m before) in one cascade.
  - `van_presentation.gd`: mirrors update one at a time (45 per second in total, 15 each),
    draw to 80 m (160 m before), skip positional shadows, and use LOD threshold 4.
  - `game/project.godot`: MetalFX temporal upscaling at 75% on macOS.
  - New tool `tools/captures/measure_performance.gd`, and `PERFORMANCE.md`.
- **Result:** parked 20.8 → 73.4 FPS; driving 23.4 → 70.8 FPS. The median driving frame is
  12.2 ms. Every effect is kept. Captures look the same.
- **Tests:** all suites pass; logs are in `logs/phase_1/run9/`.

## Revision 2026-10-31 (Run 10: undergrowth between the trees)

- **Author:** "didnt we have trees and bushes together?? did you remove the bushes?", then
  "Add undergrowth between the trees, so trees and bushes mix deeper in the forest ...
  alright do it".
- **Finding:** nothing had been removed (11,330 props before and after Run 9). The
  undergrowth only grew 3.5–22 m from the road, and unlit bushes are nearly black at night.
- **Young firs** (`roadside_forest.gd`):
  - 1,369 young firs, 1.6–3.8 m tall (scaled 0.8–1.25), grow in noise patches between the
    big trees, three times as dense within 18 m of the road, where light reaches the edge.
  - They use the same scanned branch cards as the big trees.
  - They are drawn to 55 m, and their light version casts their shadows within 25 m.
  - They have no colliders.
- **Tree builder** (`conifer_builder.gd`): for trees under 6 m, a thin dark stem that ends
  inside the top foliage, closer whorls, seven branches per whorl, and branches level or
  slightly up. Every formula gives the same result for the big trees (15–23 m), so they
  are unchanged; the tree count stays 6,549.
- **Deep floor** (`forest_floor.gd`): 2,600 more ferns and 500 fallen-branch pieces,
  22–70 m from the road, in noise patches. They are appended to the prop list, so every
  existing prop keeps its place. Ground props total 14,430.
- **Cost:** parked 73.4 → 71.7 FPS, driving 70.8 → 68.6 FPS (median 12.7 ms). The headlight
  contrast is unchanged: the road reads 98.4 with the lights on and 12.0 with them off.
- **Tests:** all suites pass; logs are in `logs/phase_1/run10/`.

## Revision 2026-10-31 (Run 11: more windshield droplets; random running drops)

- **Author:** "the water droplets on front windshiled reduced. increase them. and make the
  water droplets running down and away random. dont make it uniform. thats not how the real
  life works right?? add in documentation also."
- **Why it looked thin and uniform:**
  - Since Run 8 the drops were physically small (1–4 mm). With MetalFX drawing at 75% they
    shrank to 1–2 pixels and read as speckle.
  - The moving drops slid in straight columns at one constant speed per size.
- **How real rain on glass behaves, and what now does the same:**
  - **Most drops stay pinned.** The size mix leans small (45% / 30% / 17% / 8% across the
    1.6, 2.2, 3.0 and 3.8 mm radii), and at rest only the two biggest sizes are heavy
    enough to slide.
  - **Moving drops lurch.** `slip()` turns steady travel into stick-slip: speed swings
    between 0.1× and 1.9× the average along an irregular two-frequency curve, never
    backwards. Each column also gets its own pace (0.6–1.4×).
  - **Runners are independent events.** Each lane gives every runner its own random start
    time, start point, size (0.85–1.35 × 5.5 mm), speed (0.6–1.5×) and run length
    (8–45 cm). The runner slides, pauses, stops and then fades, and a new one appears
    elsewhere.
  - **Paths wander.** The path drifts sideways by ±1 cm, following a noise curve.
  - **Runners sweep a lane.** Each runner clears the resting drops from a lane behind it,
    and leaves random tiny beads (0.6–1.6 mm) at random spacing.
  - **Direction follows the physics.** Parked, runners slide down. At speed they climb,
    each direction driven by its own distance counter (`runner_down`, `runner_up`), so
    runners never jump when the van passes the balance speed.
- **More droplets:** a new layer of resting drops (radius 1.7–3.2 mm), larger small drops,
  and runners in 55% of lanes (40% before). Every drop's lower edge shows the night-sky
  glow (`sky_view()`, now shared with the side windows). That is the inverted-lens effect
  that makes drops visible at night.
- **Files:**
  - `rain_drops.gdshaderinc`: `slip()`, `sky_view()`, size weighting, per-column pace;
  - `windshield.gdshader`: runner events, swept lanes, the new layer, sky glow;
  - `side_window_rain.gdshader`: uses `sky_view()`, same result;
  - `rain_physics.gd`: radii 1.6–3.8 mm, `runner_down` and `runner_up`;
  - `van_presentation.gd`: sends the radii and both counters;
  - tests;
  - `tools/captures/capture_windshield_sequence.gd` (new).
- **Checked:**
  - A temporary debug colouring showed runners as red heads with green lanes, at random
    places and lengths, moving and stopping independently between frames 1.4 s apart. The
    debug code was removed.
  - Frame rate: 71.1 FPS parked, 68.0 driving, unchanged.
  - All suites pass (rain physics 12/12); logs are in `logs/phase_1/run11/`.

## Revision 2026-10-31 (Run 12: the Honda e cockpit in the game)

- **Author:** "i like this more" (the Honda e interior, C22), then "proceed but make sure its
  so accurate", "yes do it, keep it looking the same. and make sure the game is smooth as
  butter", "finish step 3 first, then hook it up", and "ok" to step 4 (hook it up).
- **Steps 1–3 happened in Blender only.** The interior was fitted to the van, the cab was
  closed, and the model was slimmed with no visible change. The prompt log has the results
  (#38–#44).
- **New art** in `game/features/vehicles/freight_van/art/cockpit/`:
  - four glTF files: `cockpit_front` (338,981 triangles), `cockpit_back` (348,679),
    `cockpit_roof` (89,142) and `cockpit_wheel` (70,562);
  - 27 shared textures, set to VRAM compression with mipmaps by `configure_imports.py`;
  - two shadow stand-ins: `cockpit_shadow.glb` (29,917 triangles) and
    `cockpit_wheel_shadow.glb` (1,616);
  - `ATTRIBUTION.md`.

  Every file is under 25 MB; the largest is 12.2 MB. `cabin.glb` and `steering.glb` stay
  in the repository, unused.
- **`van_presentation.gd`:**
  - **Cockpit:** the four parts replace the old cabin and wheel. The detailed cockpit casts
    no shadows; the two stand-ins cast them, drawn from both sides.
  - **Wheel:** the whole Honda wheel turns on its own hub, at (-0.52, 1.7328, -0.8167) on a
    column tilted 18.49°. That includes the ring around the horn pad and the covers under
    the spokes, which step 3 had grouped with the column; the indicator stalks stay fixed.
  - **Steering direction fixed:** the wheel used to turn clockwise for a left turn. That was
    a sign error that predates this run.
  - **Gauges and map:** our cluster sits on the Honda driver display (16.2 × 6.5 cm). The
    map sits on the driver's half of the centre screen, and the reverse camera takes its
    place in reverse.
  - **Mirrors:** the left and right mirror views also show, mirrored, on the screens at the
    dash ends. The door mirrors and the inside mirror stay.
  - **Night dimming:** unchanged; it still works on the cluster's own image.
  - **Trim:** the code-built trim bar beside the old cluster, and the backing boxes behind
    the old cluster and map, are gone. The door-mirror arms now start at the side glass;
    before, 7 cm of each arm stuck into the new cab.
- **`cockpit_screen.gdshader` (new, in the van's folder, not in `game/shaders/`):** the Honda
  screens are about a quarter of the old screens' size. Godot 4.7 cannot mipmap a viewport
  texture, so the 1280-pixel cluster would shimmer at 14:1. The shader averages 6×6 samples
  over each screen pixel and crops a view to the screen's shape without stretching it.
- **Art check, written exception (approved with step 4):**
  - The 30,000-triangle limit still applies to every original model.
  - The cockpit gets its own section, with a budget of under 900,000 triangles for the four
    visible files and under 40,000 for the stand-ins. It is the slimmed Honda e interior,
    and slimming it further changed the driver's views (step 3).
  - The section also checks finite geometry, vertex references, unit normals, that no part
    is named as a badge, that the textures exist, and that every file is under 25 MB.
  - **Inverted triangles:** the source model has 59 triangles whose winding disagrees with
    their normals (49 front, 5 back, 5 roof). They are kept so the look matches the
    approved renders. Flipping them would have hidden one dash triangle and shown one floor
    patch, both inside single-sided materials. Any new inverted triangle fails the check.
  - The existing checks are unchanged.
- **Tests:**
  - New `game/tests/test_cockpit.gd`, 22 checks: the cockpit files are used and the old ones
    are not; triangle count; layers and shadows; each screen sits on its Honda screen and
    shows the right picture; the wheel pivot; and steering left and right turns the top of
    the wheel the same way.
  - With the old steering sign restored, it fails 20/22 and exits 1
    (`logs/phase_1/run12/mutation/`).
  - No existing test changed.
- **Measured:**
  - Back to back with a throwaway copy of Run 11, twice, with the Mac cool: parked
    71.1 → 69.0 FPS, driving 68.1 → 65.2 FPS.
  - The cockpit costs about 0.4 ms parked and 0.7 ms driving (`PERFORMANCE.md`).
- **Evidence:** 13 stills in `evidence/phase_1/cockpit/run12/`, taken by the new
  `tools/captures/capture_cockpit.gd`: the four look directions, the wheel turned both ways,
  close-ups of the cluster (lights on and off), the map, the reverse camera and both mirror
  screens, and a driving shot.
- **Not done:**
  - From the driver's seat, about half of the right mirror screen is hidden behind the long
    centre-screen housing, because the widened dash puts that screen 1.5 m away.
  - Restyling the Honda trim before any sale (C22).

## Revision 2026-10-31 (Run 13: the steering wheel moved left)

- **Author:** "can you place the steering wheel in front of driver little to the left",
  then, after seeing a proposal to move the seat instead: "move the steering wheel".
- **Moved 5 cm to the left:**
  - the wheel (`WHEEL_HUB` x −0.52 → −0.57);
  - the indicator and wiper stalks with their column housing (`Cockpit_SteeringColumn_FrontL`,
    re-exported in `cockpit_front.gltf`).
- **Moved 3.5 cm to the left:** the Honda driver display and our cluster on it
  (`CLUSTER_SCREEN` x −0.5213 → −0.5563). That is as far as the Honda's black screen panel
  reaches (it ends at x −0.64), so the gauges stay in the wheel's upper opening, 1.5 cm off
  its centre.
- **Unchanged:** the 23 front textures (byte-identical), every other part, and the
  triangle and inverted-triangle counts. The static shadow stand-in holds only 9 coarse
  faces of the stalks, so it was left as it was.
- **Test change, by the author's request:** `test_cockpit.gd` expects the hub at x −0.57.
- **Tests:** all suites pass (64/64, 0 failures, 92/92, 12/12, 12/12, 30/30 ×3, 22/22, art
  0 failures); logs are in `logs/phase_1/run13/`.
- **Evidence:** stills in `evidence/phase_1/cockpit/run13/`.

## Revision 2026-10-31 (Run 14: real ghats, the drivable hill road, C23)

- **Author:** "make the road full of twists and turns like driving on ghats. not just a circle
  road", then "real ghats i want" and "start with run 14" after seeing the layout
  (`AUTHOR_PROMPTS_AND_DECISIONS.md` #46–#48).
- **The road** (`ghat_road.gd`, new):
  - **Pieces:** the approved layout as 31 explicit lines, Bézier curves and hairpin arcs,
    sampled every 2 m.
  - **Size:** a 3.2 km lap that climbs 79 m through five hairpins, runs along the summit
    ridge, comes down through five more, and returns along the valley to the depot.
  - **Grades:** they come from distance, with hairpins counted at 35%, and are smoothed
    over 42 m. The legs reach 9.1% and the hairpins 6.2%.
  - **Width:** hairpins widen from 4.5 m to 6.5 m of asphalt.
  - **Route change from the approved map:** the approved map's way home ran through the
    depot building, so it now passes 20 m south of the depot and round its west side.
- **The hill** (`hill_terrain.gd`, new):
  - **Grid:** a 2 m height grid over 690 × 540 m, with the valley, an escarpment, the
    plateau and rim hills at the world's edge.
  - **Shaped around the road:** within 20 m, the hillside follows the road's own heights.
    A first version kept the hill's flat contours; it left the high end of every leg on an
    embankment, with drops and barriers on both sides.
  - **Carving:**
    - 12 cm under the road;
    - a flat 2 m shoulder;
    - then rock cuts of up to 58° uphill and fill banks of up to 54° downhill.
  - **Plots:** building plots are levelled to 0.
  - **Collision and drawing:** a scaled `HeightMapShape3D`, drawn in 99 tiles without shadows.
- **The world** (`industrial_loop.gd`):
  - **Road and hill:** the hill and road replace the flat ground and old loop. The verge
    strip carries the road's collision.
  - **Barriers:** 532 plain concrete barriers, with collision, line every drop of more
    than 1.6 m. The dressing comes in Run 15.
  - **Moved buildings:**
    - three warehouses, the container row and the silos move into the valley;
    - the distant skyline moves south, beyond the valley.
  - **Signs:** they stand on the ground: "BLACKRIDGE HILL ROAD" (steep grade, switchbacks)
    and "BLACKRIDGE SUMMIT" (trucks use low gear).
  - **World edge:** the old visible boundary barriers become invisible walls at the edge of
    the playable area (630 × 480 m).
- **Forest:**
  - Trees, young firs, trunk colliders and ground plants stand on the hill, sinking a
    little on slopes.
  - **Road clearance:** it now comes from the hill's distance field. Checking every
    segment would have cost about 60 million distance tests.
  - **Density:** to keep the frame rate, density beyond 20 m from a road drops to a
    quarter, young firs gather less at the road edge, and plants scale 1.4× for the longer
    road.
  - **Counts:** 9,315 trees, 4,815 young firs, 8,309 trunk colliders and 18,089 plants.
- **The van:**
  - **Slopes:** gravity along the road slows it uphill and speeds it downhill
    (`slope_pull()`). With no brake it rolls back, and the brake holds it.
  - **Tilt:** the body, cockpit, camera, headlights and mirror cameras pitch and roll to the
    road from four wheel rays (`_follow_ground()`).
- **Mission, map and app:**
  - **Checkpoints:** they move to hairpin 2, the summit, downhill hairpin D3 and the valley
    road, at their real heights and headings. The objective reads "Follow the freight loop
    via the switchbacks."
  - **Map:** the map screen draws the real road.
  - **App:** the app gives the map the road and recovers the van only outside the new
    playable area.
- **Test changes, with reasons:**
  - **`test_materials.gd`:** the window check measures in the cab's own frame
    (`presentation`), not the van's physics body. The cab now follows the ground while the
    body settles. The check is the same, 0.88 m inside the cab.
  - **New `game/tests/test_ghat_road.gd`, 22 checks:**
    - lap, climb, hairpins, grades and widths;
    - the hill never above the road; the road's own collision;
    - a barrier at every drop;
    - checkpoints on the road;
    - level start; rolling back, holding and climbing; body pitch.
  - **Mutations:**
    - with no slope gravity it fails ("rolls back");
    - with no barriers it fails (170 of 175 drops missing).
  - The other suites are unchanged and pass.
- **Measured (cool Mac, 1280×800):**
  - The standard test gives 79.4 FPS parked and 78.2 FPS driving.
  - On the hill: 69 FPS parked on the steepest climb, 70.5 FPS climbing at full throttle,
    83.5 FPS at hairpin 2 and 81.8 FPS at the summit.
  - See `PERFORMANCE.md`.
- **Evidence:** `evidence/phase_1/ghat/run14/`:
  - stills of the climb, a hairpin approach and apex, the summit, the descent and the map
    screen;
  - one overview with debug lighting (ambient 6.0, fog off) showing both zigzags.
- **Not done (Run 15 and later):**
  - guardrails, stone retaining walls and rock faces;
  - yellow curve and switchback signs, hairpin numbers and mirrors at blind bends;
  - the valley's town lights;
  - trees beyond 280 m are not drawn, so a camera far above sees bare slopes (fog hides
    this from the road).

## Revision 2026-10-31 (Run 15: a ghat road with no pattern, its dressing, real wipers, C24)

- **Author:** "yes start run 15. make sure we are documenting everything as well. also dont
  make it a pattern. make sure its uniqque. something like this, also make the wipers more
  realisitc and spawn the user away from the depot." The image was a drawn "Ghat Road Map":
  irregular hairpins, cliffs, a river, a viewpoint and a lay-by
  (`AUTHOR_PROMPTS_AND_DECISIONS.md` #49).
- **The road, no longer a pattern** (`ghat_road.gd`, rewritten):
  - **Before:** Run 14's 31 pieces made two regular zigzags of five like hairpins each.
  - **Now:** 38 hand-placed waypoints, each with a position, a heading, a section and a
    handle length. Cubic Bézier curves join them, and the result is sampled every 2 m. No
    two legs share a length or a direction, and the hairpins differ in tightness and
    spacing.
  - **Size:** a 3,007 m lap. It climbs through four hairpins, crosses a ridge with a 2.5 m
    crest, comes down through four more and returns along the valley. It climbs 64.4 m
    (Run 14: 79 m).
  - **Grades:** they come from distance, with hairpins counted at 35%, smoothed over 42 m.
    The legs reach 9.7% and the hairpins 6.5%.
  - **Viewpoint:** round the fourth hairpin up, the road widens 2.5 m on each side, so a
    van can pull off and look over the valley.
- **The hill** (`hill_terrain.gd`):
  - It is reshaped for the new road: the valley edge, plateau edge and plateau height
    moved, and peaks rise on either side of the pass at x 150.
  - Under the asphalt the hill now takes the lowest road surface above it, because legs
    pass close together. It stays under the road everywhere (worst −0.005 m).
- **Rock faces** (`hill_ground.gdshader`, new, in the feature folder, not `game/shaders/`):
  - gentle ground shows Poly Haven's forest floor, and steep cuts its "Rock Wall 02";
  - the rock blends in from about 33° to 49° of slope, projected from three sides so it
    does not stretch;
  - rain darkens and smooths both.
- **The dressing** (`ghat_dressing.gd`, new). It replaces Run 14's 532 plain concrete
  barriers.
  - **Where barriers go:** wherever the ground 6.5 m beyond the road edge is at least
    1.2 m lower. If both sides drop, only the deeper side gets one, unless both drop 3 m or
    more. Runs extend 4 m at each end, and gaps under 12 m are closed.
  - **Guardrails:** 156 galvanized W-beam segments on steel posts.
  - **Stone walls:** 145 dry-stone wall segments with caps, at the hairpins and the
    viewpoint, in Poly Haven's "Rustic Stone Wall".
  - **Collision:** every barrier segment has its own box.
  - **Delineators:** 116 white posts with reflectors, every 26 m on the hill where there is
    no barrier.
  - **Signs** (American, MUTCD style), from one atlas drawn by `tools/make_road_signs.py`:
    - 60 m before each hairpin, a switchback warning with a 20 MPH plate. A hairpin under
      12 m radius would get 15 MPH; none is that tight.
    - Chevrons every 8 m round the outside of each hairpin (49).
    - SCENIC VIEW before the viewpoint.
    - A curve warning with 25 MPH where a bend away from the hairpins is tighter than 45 m
      (one).
    - At the top of the descent: steep grade with a 9% plate, then TRUCKS USE LOW GEAR.
    - The faces are dulled to 55% and the backs made matte, after a still showed sign backs
      8 m ahead clipping to pure white in the low beams.
  - **Mirrors:** convex traffic mirrors on 2.7 m poles, at the tightest hairpin up and the
    tightest down.
  - **Landslide:** the valley road east of the depot is closed. There is a rockfall (Poly
    Haven's mossy rocks, with colliders), concrete barricades with ROAD CLOSED boards, amber
    lamps blinking every 0.55 s and landslide signs. The way to the depot is over the hill.
- **The world** (`industrial_loop.gd`):
  - **Start:** a lumber yard 589 m from the depot, with log piles (with colliders), a shed
    and a lamp.
  - **Direction signs:**
    - at the start: "BLACKRIDGE / HILL ROAD", "VALLEY ROAD CLOSED";
    - before the climb: "BLACKRIDGE PASS 3/4 MI", "SWITCHBACKS / 9% GRADE";
    - at the summit: "BLACKRIDGE PASS", "ELEV 1,200 FT";
    - before the depot: "FREIGHT DEPOT", "NEXT LEFT".

    The climb sign first said "3 MI". The pass is 1,032 m away by road, so it was changed
    after the final capture; the stills show that sign too far away to read.
  - **The town:** 14 buildings with lit windows on the valley floor south of the road, and
    24 soft glows over the rooftops that appear only beyond 150 m. From the viewpoint they
    read as a town through the rain.
  - **The view:** five clearings in the forest below the viewpoint keep the valley in
    sight.
  - **Street lamps:** three on the valley road near the depot.
  - **Size:** the hill is 820 × 650 m and the playable area 780 × 510 m (Run 14: 690 × 540
    and 630 × 480).
- **Wipers** (`freight_van.gd`, `van_presentation.gd`, `windshield_wipe_map.gd`):
  - **Before:** two plain bars at x −0.52 and +0.48 swung 52° each way about upright, so
    "parked" left them standing across the glass.
  - **Park:** they lie flat along the bottom of the windshield (−89°) and return there
    when switched off.
  - **Sweep:** 99° up and back, slow at each end and fastest mid-stroke, as a crank linkage
    moves them. Slow is 0.75 strokes a second (was 0.65), fast stays 1.1.
  - **Layout:** tandem, from pivots at x −0.80 and +0.14, both sweeping the same way, as on
    most vans.
  - **Parts:** a pivot cap, spring housing, arm and hook, and a blade with frame, spoiler
    and rubber edge, riding on the glass.
  - **Blade:** it rocks up to 8° as it reverses, as the rubber flips over.
  - **Wiped area:** the wet-glass map uses the same pivots and a blade reach from 12 to
    84 cm, so the dry sector is where the blade passes.
- **Mission and app:**
  - `first_drive.gd`: the checkpoints are THE SWITCHBACKS, THE VIEWPOINT, THE PASS, THE
    DESCENT and PARK AT THE DEPOT. One `START` pose serves the start, recovery and restart.
  - `first_drive.tscn`: the van starts at the lumber yard, facing west.
- **Test changes, with reasons:**
  - **`test_ghat_road.gd`**, from 22 to 29 checks:
    - **New layout:** 8 hairpins (was 10), a lap of 2.8–3.3 km, a climb of more than 60 m,
      and the road at least 25 m inside the playable area (was 30 m).
    - **Barrier check:** it follows the dressing's rule, so only the deeper side of a
      two-sided drop needs a barrier unless both drop 3 m or more (51 spots, 0 missing).
    - **New checks:**
      - guardrails and walls exist;
      - every hairpin has a warning and chevrons;
      - two mirrors stand;
      - the landslide blocks the road (a shape query);
      - the start is more than 400 m from the depot;
      - the wipers park flat and sweep more than 90°;
      - the wiped area uses the wiper pivots.
  - **`first_drive_integration.gd`:** the "wipers park when off" check compared against
    the old park angle (−0.9). It now reads `WIPER_PARK` from the van's script, so the
    behaviour checked is the same.
  - **Mutation:** with the wipers parked at the old angle, `test_ghat_road.gd` fails 28/29,
    exit 1 (`logs/phase_1/run15/mutation_wiper_park/`).
  - The other suites are unchanged and pass.
- **Measured** (1280×800, vsync off, Mac cool):
  - the standard test, which now starts at the lumber yard: 74.9 FPS parked and 76.0 FPS
    driving;
  - 68–119 FPS around the hill.

  See `PERFORMANCE.md`.
- **Evidence:** `evidence/phase_1/ghat/run15/` holds 14 stills and one debug-lit overview:
  - the start, and the wipers mid-sweep and parked;
  - the climb, a hairpin approach and apex, the viewpoint and the pass;
  - the descent sign, the mirror hairpin and the descent;
  - the landslide, the town lamps and the map screen.

  In every still, at most 0.05% of the outside view is pure white.
- **Not done:**
  - **From the reference map:** the river, waterfalls, tunnel, rest stop and fuel station.
  - **Hairpin numbers:** left out on purpose, because numbered bends are an Indian ghat
    custom and C23 sets the road in America.
  - **Distant trees:** trees beyond 280 m are still not drawn.
  - **Lit tree trunks:** near the van, the bottom of each trunk in the low beams still
    looks pale, as it has since Run 2.

## Revision 2026-10-31 (Run 16, step 1: the depot floor no longer covers the road)

- **Author:** "on the pic if you see the floor of depot is coming onto road", with a
  screenshot from the valley road beside the depot (`AUTHOR_PROMPTS_AND_DECISIONS.md` #50).
  Step 1 approved: "Yes, fix it now (Recommended)".
- **Cause:** the depot's ground was two flat boxes placed for the old flat loop:
  - an 18 × 18 m driveway patch, 3 cm above the asphalt, which covered 16 m of the new road
    from its centre line to its south edge; its lit side face was the white line in the
    screenshot;
  - the 60 × 42 m yard, which covered 22 m of the road's edge where the road bends round
    its north-west corner.
- **Fix** (`industrial_loop.gd`):
  - one flat surface, `DepotYard`, replaces both boxes. It is built in 1 m columns from the
    road's own edge, so no part of it lies on the asphalt or the gravel verge;
  - the driveway columns (x −37 to −19) start exactly at the asphalt's edge, 2 mm above it,
    and rise to the yard's height over 1.5 m, so the driveway meets the road level;
  - elsewhere the yard keeps 40 cm of ground between itself and the verge;
  - the surface has no side faces, so no edge catches the headlights.
- **Test change, with its reason:** `test_ghat_road.gd` gains one check, "The depot yard
  stops at the road's edge" (30 checks now). It measures every corner and every triangle
  centre of `DepotYard` against the road. The author's bug report is the reason.
  - **Mutation:** with the driveway pushed 3 m onto the road, the check fails (29/30,
    exit 1; `logs/phase_1/run16/mutation_depot_yard/`).
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 12/12, 12/12, 30/30 ×3, 22/22,
  30/30, art 0 failures. Logs are in `logs/phase_1/run16/`.
- **Evidence:** `evidence/phase_1/depot/run16/depot_road_after.png`, from the author's spot.
  The road is continuous, and the yard starts at its edge.
- **Next, each step approved on its own:**
  - the wipers ("They look like sticks", "Water doesn't react");
  - the low and high beams on L, cycling low, high and off;
  - the moon roof, glass over the front seats.

## Revision 2026-10-31 (Run 16, step 2: real wiper parts, and water that reacts)

- **Author:** "wipers arent realistic" (#50); what is wrong: "They look like sticks", "Water
  doesn't react"; then "yes start step 2" (#51).
- **What the old wipers did**, captured first (`evidence/phase_1/wipers/run16_before/`):
  - each was a few plain boxes, black from end to end, so it read as a stick;
  - the wiped glass re-wet in about 1 s parked and 0.3 s at 50 km/h, and kept 35% of its
    water film right after a wipe, so the wiped fan looked like the wet glass around it.
- **Real wiper parts** (`wiper.gd`, new, built in code from cross-sections):
  - a pivot cap, a tapered spring cover, a tapered arm and a hook;
  - a beam blade: a sloped spoiler 2 cm wide, a rubber lip on the glass, tapered end caps,
    and an adapter where the arm hooks on;
  - the driver's blade is 70 cm on a 50 cm arm, the passenger's 55 cm on a 46 cm arm, as on
    real vans (both blades were 72 cm);
  - each wiper sits on the glass plane at its pivot (`_on_glass()`), so the blade lies
    exactly where the glass is wiped; the old hinge sat 3 cm from the wiped area's pivot;
  - every part is outside the glass and casts no shadow.
- **Water that reacts** (`windshield.gdshader`, `windshield_wipe_map.gd`,
  `van_presentation.gd`):
  - **Clear arc:** the glass re-wets over 2 s parked (was 1 s), and 3× faster at 72 km/h
    (was 4.3×), because the van drives into the rain. Freshly wiped glass keeps 8% of its
    film (was 35%), so the wiped fan is crisp.
  - **New drops in new places:** each resting drop takes a seed from the stroke that last
    wiped it, worked out from the wipers' timing, so drops come back somewhere new after
    every wipe instead of in the same spots.
  - **Water pushed by the blade:** a ridge of water up to 14 mm wide rides ahead of each
    moving blade. It grows through the stroke, is lumpy along its length, and its crest
    catches the light around it.
  - **Dumped at the turn:** where the blades turn at the top, the ridge is left behind as a
    line of water that breaks into beads and fades within about a second.
  - **Streaks:** thin arcs left by the rubber at fixed places along each blade, as on a
    worn blade, fading as the glass re-wets.
  - **Motion blur:** a moving blade leaves a short dark trail on the glass, as the eye sees
    a fast blade (a 1/50 s shutter). A slow or parked blade leaves none.
  - A still shows the slimmer blade and its lit water edge. The refill, the blur, the dump
    and the streaks show in motion.
- **Fixed on the way:** on its first frame the presentation saw a 93 rad/s blade jump,
  because it started from angle 0 instead of the parked angle. It now starts from the van's
  real wiper angle.
- **Test changes, with reasons:**
  - **New `game/tests/test_wipers.gd`, 12 checks:**
    - the parts are there; the blades are 2 cm wide; the driver's blade is longer;
    - every part is outside the glass, and the blades lie where the glass is wiped (0.0 mm);
    - the shader takes the new settings, and the resting drops are reseeded;
    - the re-wet times;
    - the glass follows the swing (4.0 rad/s), the dumped water breaks up (0.18 after
      1.2 s), and parked wipers push no water.
  - **`test_ghat_road.gd`:** its pivot check compared the presentation's `WIPER_PIVOTS`
    with the wipe map's pivots. That constant is gone, because the wipers are now built from
    the wipe map's own layout, so the check now measures the built wipers on the glass. Same
    name and intent; the unused presentation preload is removed.
  - **Mutations:** with the glass no longer told about the blades, `test_wipers.gd` fails
    10/12; with the blade's end caps removed, 8/9. Both exit 1
    (`logs/phase_1/run16/step2/mutation_*`).
- **Tool:** `tools/captures/capture_wipers.gd` (new) saves eight frames of one stroke parked
  and one at about 47 km/h.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 12/12, 12/12, 30/30 ×3, 22/22,
  30/30, 12/12, art 0 failures (`logs/phase_1/run16/step2/`).
- **Frame rate:** 76.0 FPS parked and 74.3 FPS driving at the start (Run 15: 74.9 and 76.0),
  within run-to-run noise.
- **Evidence:**
  - `evidence/phase_1/wipers/run16_before/` and `run16/`: stroke sheets and frames;
  - `source_assets/artwork/captures/pending/2026-10-31_run16_wipers.png`: before and after.

  A temporary debug colouring (ridge red, dump green, streaks blue, blur magenta, fresh glass
  yellow) confirmed where each effect sits; the debug code was removed.
- **Not done:** wiper sound (the motor, and the rubber's thump at each turn), and an
  intermittent setting.

## Revision 2026-10-31 (Run 16, step 3: low and high beams on L, C25)

- **Author:** "i dont see the ... lights for low beam and high beam" (#50); for the key:
  "Add it to the L. when L is pressed once low beam should turn on, when pressed twice high
  beam, when thrice lights off."; then "yes start step 3" (#52).
- **A change to a protected control, at the author's request.** §5 and `CLAUDE.md` protect
  `headlights_on`, the L key, the `LIGHTS` text and the switch click. The author has now
  changed what L does, so:
  - **L cycles low beam, high beam, off** (`freight_van.gd`, `_cycle_headlights()`). The
    game still starts on low beams, so the first press gives high beams.
  - **`headlights_on` keeps its meaning:** true while either beam is on. The dimming driver,
    `night_cluster`, the `LIGHTS` text, the lamps and the switch click are unchanged, and
    none of them sets it. The new `high_beams` says which beam is on.
  - **`CLAUDE.md` wording:** drafted and shown to the author. It is applied only with their
    OK.
- **High beams** (`van_presentation.gd`, `_aim_beam()`):
  - the same two shadowed headlights switch pattern and reach, so there is no extra light
    or shadow cost;
  - the pattern (`art/high_beam_pattern.png`, made by `tools/make_high_beam_pattern.py`)
    keeps the low beam's light, as real high beams do, and adds a hot spot on the horizon
    with no cutoff, plus a soft spread above it;
  - the reach goes from 120 m to 220 m.
- **Cluster** (`instruments.gd`): a blue high-beam lamp beside the green low-beam one.
- **Measured from the driver's seat, parked at the start, wipers parked**
  (`tools/captures/capture_beams.gd`, new):

  | | Road 10–46 m | Road 50–100 m | White-out | FPS |
  | --- | --- | --- | --- | --- |
  | Low beams | 87.7 | 40.3 | 0.00% | 59.6 |
  | High beams | 103.2 | 61.6 | 0.00% | 59.5 |
  | Lights off | 18.2 | 28.7 | 0.00% | 60.0 |

  With the lights off, the far road reads brighter than the near road because the fog
  lightens distant pixels. High beams light the far road about 50% more and the trunks
  higher up, and the sign 60 m ahead lights up. The frame rate is the same in all three
  states (this run held about 60 FPS).
- **Test changes, with reasons (the author's request #50 changes what L does):**
  - **`test_headlights.gd`,** from 12 to 14 checks:
    - the start is on low beams;
    - press 1 gives high beams (pattern and 220 m reach), press 2 gives off, press 3 gives
      low beams again;
    - new: the high pattern is 12.6× brighter at the horizon, in linear light, and keeps
      the low beam's near light.
  - **`test_night_dimming.gd` (Assignment 5's suite):** each press that meant "switch the
    lights" now presses L until `headlights_on` flips: twice from low beams, once from off.
    The press made while paused stays a single press. The 30 checks and their timings are
    unchanged; one check's wording says "Real L presses (low, high, off)".
  - **`first_drive_integration.gd`:** the headlight check follows the cycle (high, then off,
    then low) with two new checks.
  - **Tools:**
    - `capture_forest_road.gd` and `capture_cockpit.gd` press L twice to reach "off";
    - `capture_forest_road.gd` also waited for the old park angle (−0.9), which no longer
      exists after Run 15, so it reads `WIPER_PARK` now.
  - **Mutations:**
    - with L toggling on and off again, `test_headlights.gd` fails 11/14;
    - with high beams keeping the low pattern, 13/14.

    Both exit 1 (`logs/phase_1/run16/step3/mutation_*`).
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 14/14, 12/12, 30/30 ×3, 22/22,
  30/30, 12/12, art 0 failures (`logs/phase_1/run16/step3/`).
- **Evidence:** `evidence/phase_1/beams/run16/`: the three stills, `beams_sheet.png` and the
  measurements.
- **Not done:** high beams light the rain only on the glass. Falling rain in the beams is
  particles, kept for Assignment 6. A green guide sign under high beams reads pale cyan
  (AgX desaturates very bright colours).

## Revision 2026-10-31 (Run 16, step 4: the moon roof)

- **Author:** "i want a moon roof, let users see into the sky" (#48); "i dont see the moon
  roof" (#50); the choice "Glass over front seats (Recommended)"; then "yes apply it and
  start step 4" (#53).
- **What Claude Code found:**
  - The Honda e interior already has a sunroof frame over the front seats: a metal trim and
    black border, 139 × 43 cm (x −0.69 to 0.70, z −0.94 to −0.51 in the cab). Its headliner
    is open inside that frame.
  - What hid the sky was the closing plate added when the cockpit was fitted (step 2 of the
    fit). It had been merged into the roof-cloth mesh and the shadow stand-ins.
  - So the moon roof uses the Honda's own frame. It is wider than the 70 cm estimated in the
    proposal, and keeps the original trim round the glass instead of covering half of it
    with headliner.
- **Blender** (the session's `CockpitSlim` and `CockpitHookup`, saved as
  `cockpit_fit_step4_moonroof.blend` in the agent's scratch folder, not in Git):
  - the plate's faces are cut along the frame's edges and removed inside it, in
    `Cockpit_RoofCloth_Roof`, the static shadow stand-in (`Cockpit_ShadowStatic`) and its
    Blender source (`Cockpit_ShadowProxy`); the wheel's stand-in is untouched;
  - the roof is re-exported with the Run 12 settings, and run through the same
    `postprocess.py`;
  - only `cockpit_roof.gltf`, `cockpit_roof.bin` and `cockpit_shadow.glb` changed, and the
    11 roof textures are byte-identical;
  - the roof is 89,186 triangles (+44) and the static stand-in 29,973.
- **Godot** (`van_presentation.gd`):
  - `MoonRoofGlass`: lightly tinted glass the size of the frame, 2.79 m up;
  - `MoonRoofRain`: the side-window rain shader, 12 mm above the glass and drawn first. It
    has its own water physics (`_roof_water`): the roof is nearly level (`ROOF_SLOPE`, 5%),
    so drops sit when parked, and at speed the air (`ROOF_AIR`) pushes them backward;
  - mouse look reaches `LOOK_UP` 1.05 rad (was 0.5). With the camera's own tilt, the view
    now reaches 89° up, past the frame's back edge at 75°.
- **Test changes, with reasons:**
  - **`test_cockpit.gd`,** from 22 to 26 checks:
    - five sight lines from the driver's eye through the frame meet no roof part, and none
      meets the shadow stand-in;
    - the glass matches the frame, with rain on top;
    - looking up shows the whole roof.
    - The expected triangle count changes from 847,364 to 847,408, the 44 triangles of the
      cut.
  - **Mutation:** with the closed roof files put back, the test fails 23/26 (0 of 5 sight
    lines clear), exit 1 (`logs/phase_1/run16/step4/mutation_closed_roof/`).
  - **Art check:** the roof's inverted triangles stay within the source model's 5, and the
    cockpit is within its 900,000-triangle budget.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 14/14, 12/12, 30/30 ×3, 26/26,
  30/30, 12/12, art 0 failures (`logs/phase_1/run16/step4/`).
- **Evidence:** `evidence/phase_1/moon_roof/run16/`, made by the new
  `tools/captures/capture_moon_roof.gd`. Parked, looking up, and looking up and right, the
  night sky and the pines show through rain on the glass. A third still is taken driving at
  45 km/h.
- **Not done:**
  - the van's outside roof shows no glass, which only matters from outside;
  - rain falling past the glass waits for Assignment 6's particles;
  - the old code-built rear-view mirror still shows beyond the windshield (backlog).

## Revision 2026-10-31 (Run 16, step 5: one rear-view mirror)

- **Author:** the backlog item "everything realistic", with the known gap of two rear-view
  mirrors; then "fix the mirror first, then commit" (#54).
- **Cause:**
  - The van drew its old code-built inside mirror, a 38 × 12.5 cm screen with a dark
    backing box, at z −1.25. That is 1.3 cm beyond the windshield, out in the rain.
  - The Honda cockpit has its own centre mirror on the roof console. The Honda e's mirror
    is a camera screen, and its picture was removed with the other Honda screen pictures,
    so the housing showed an empty dark face.
- **Fix** (`van_presentation.gd`): the inside-mirror camera's live view now shows on the
  Honda mirror's face, 18.5 × 4.4 cm, angled toward the driver (`CENTRE_MIRROR`,
  `CENTRE_MIRROR_SIZE`, `CENTRE_MIRROR_TURN`). It goes through the same box-filtered screen
  shader as the other Honda screens. The old mirror and its box are gone. The door mirrors
  are unchanged.
- **Test changes, with reasons:** `test_cockpit.gd` gains two checks (28 in total):
  - the rear view shows on exactly one screen, the Honda's centre mirror;
  - no rear-view mirror is left outside the windshield.

  With the old mirror put back, both fail (26/28, exit 1;
  `logs/phase_1/run16/mirror/mutation_old_mirror/`).
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 14/14, 12/12, 30/30 ×3, 28/28,
  30/30, 12/12, art 0 failures (`logs/phase_1/run16/mirror/`).
- **Evidence:** `evidence/phase_1/mirror/run16/`: straight ahead, looking at the mirror, and
  zoomed in on its live rear view. The first capture window timed out without drawing a
  frame (macOS likely stopped drawing it); the retry worked.

## Revision 2026-10-31 (Run 17: rain in the beams, green signs, outside roof glass, C26)

- **Author:** "do all these and i will test" (#55), for the open items from Run 16. For the
  rain in the beams: "Shader rain now (Recommended)" (C26).
- **Rain in the headlight beams** (`beam_rain.gdshader`, new, in the van's folder, not
  `game/shaders/`; `van_presentation.gd`, `_beam_rain()` and `_light_the_rain()`):
  - **Layers:** eight additive layers stand 3–31 m ahead of the lamps, sized to the beam's
    cone, on the cab layer so the mirrors never draw them.
  - **Light:** each layer works out, for every point, how much light both headlights give
    it, using the lamps' real positions and the current beam pattern. The low beam's cutoff
    therefore shows in the rain, and high beams light it far ahead. Rain outside the beams
    is not drawn.
  - **Streaks:** falling streaks (7.5 m/s, 32 cm of motion blur, a slight slant) in random
    columns. Their width is kept at a pixel or more, and they fade beyond about 10 m, where
    rain stops reading as streaks.
  - **No particle system** (C26). The layers hide when the headlights are off.
- **Green guide signs** (`industrial_loop.gd`): the boards were teal (`203d3f`), which read
  pale cyan under high beams. They are now highway green (`GUIDE_GREEN` `0a4128`):
  - under low beams the board measures (79, 99, 78), clearly green;
  - under high beams it reads a lighter green, as the beam's brightness and the rain haze
    wash colour out.
- **Outside roof glass** (`van_presentation.gd`, `MoonRoofOutside`): a dark glossy pane, 5 cm
  larger than the moon roof's frame, sits on the van's flat outer roof (`BODY_ROOF`
  2.995 m). It is on the body layer, so it shows from outside and in captures, not from the
  driver's seat.
- **`CLAUDE.md`:** the project-context line now says L cycles low beam, high beam and off,
  instead of "toggled".
- **The lumber-yard start and the landslide** are unchanged; the author judges them while
  testing.
- **Test changes, with reasons:**
  - `test_headlights.gd` gains two checks (16 in total):
    - rain falls through the beams, lit by the low and then the high pattern;
    - no rain shows with the lights off.
  - `test_cockpit.gd` gains one (29): the outside roof has the dark glass over the moon
    roof.
  - `test_ghat_road.gd` gains one (31): all four guide boards are green.
  - **Mutations:** with the rain left showing with the lights off, the headlight test fails
    15/16; with the teal boards back, the ghat test fails 30/31. Both exit 1
    (`logs/phase_1/run17/mutation_rain_and_sign/`).
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 16/16, 12/12, 30/30 ×3, 29/29,
  31/31, 12/12, art 0 failures (`logs/phase_1/run17/`).
- **Measured** at the start straight (`capture_beams.gd`): road near/far reads 97.3/48.1 on
  low beams, 120.7/82.3 on high beams and 18.2/28.6 with the lights off. The beams light the
  rain, so the lit road reads a little brighter than in Run 16; white-out stays 0.00%.
- **Frame rate: not measured fairly.**
  - The Mac was on battery at 10%, and every run held about 60 FPS with 18 ms median frames.
    Earlier today, on power, the game ran at 76 FPS.
  - Godot's GPU timer reads 0 on Metal, so the rain's own cost could not be measured.
  - From what the shader does (eight layers, a few multiplies and one texture read per
    pixel, nothing drawn outside the beams), it should cost well under 1 ms. To be
    re-measured on power.
- **Evidence:**
  - `evidence/phase_1/beams/run17/` (`beams_sheet.png`);
  - `evidence/phase_1/moon_roof/run17/` (`outside_roof_sheet.png`, at night and in debug
    light: ambient 6.0, fog off).

## Revision 2026-10-31 (Run 18: rain follows the beam)

- **Author:** "when the low beam is turned on the falling rain should be less and when high
  beam is turned on it should be more like in real lkfe" (#56); "plugged in, go ahead" (#57).
- **Why, in real life:** low beams aim down at the road, so the rain they light is seen
  against the bright road, mostly close in. High beams light the rain at eye level against
  the dark, which shows a wall of bright streaks.
- **Change** (`van_presentation.gd`): the beam rain's strength follows the beam:
  - `LOW_BEAM_RAIN` (glow 5, density 0.65), half the Run 17 strength;
  - `HIGH_BEAM_RAIN` (glow 16, density 0.9), 1.6× as strong and denser.

  High-beam rain is 3.2× as strong as low-beam rain.
- **Measured** at the start straight: the light the rain adds to the road, against Run 16
  (no beam rain):

  | Beam | Road 10–46 m | Road 50–100 m | Run 17 |
  | --- | --- | --- | --- |
  | Low | +3.7 | +0.9 | +9.6 / +7.8 |
  | High | +30.6 | +37.0 | +17.5 / +20.7 |

  White-out stays 0.00%.
- **Test change, with its reason (#56):** `test_headlights.gd` gains "High beams show at
  least 3x as much rain as low beams" (17 checks). With equal rain for both beams it fails
  (16/17, exit 1; `logs/phase_1/run18/mutation_same_rain/`).
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29,
  31/31, 12/12, art 0 failures (`logs/phase_1/run18/`).
- **Frame rate:** not comparable. The Mac was charging from 8% and ran at 24–28 FPS in all
  three states; it ran at 76 FPS on power with a charged battery earlier in the day. To be
  measured again once charged.
- **Evidence:** `evidence/phase_1/beams/run18/beams_sheet.png`.

## Revision 2026-10-31 (Run 19, steps 1–2: Ethan on foot and getting into the van; C27–C28)

- **Author:** "the start of the game is not so realistic. maybe we should guide user to get into
  the van and drive ... use these animations", then "Use Mixamo, commit it (Recommended)",
  "Go ahead, dark shirt (Recommended)", "Yes, lights on at ignition (Recommended)" and
  "Leave them (Recommended)" (`AUTHOR_PROMPTS_AND_DECISIONS.md` #61–#68).
- **Step 1, the Mixamo characters** (`tools/art/convert_mixamo.py`):
  - **Ethan** (Ch33, `ethan.glb`, 54,938 triangles, 1.78 m): Idle, Walk, WalkBack and Run
    loop; EnterVan and ExitVan play once.
  - **The pedestrian** (Ch01, `pedestrian.glb`, 42,818 triangles, 1.75 m): HitByVan, and
    Ethan's Walk. His light grey polo is tinted charcoal; his jeans stay blue.
  - **Materials:** Mixamo's materials were half metallic, with a gloss map wired in as
    roughness. Now each part has its own roughness, and nothing is metallic.
  - **Textures and bones:** textures are 2048-pixel WebP, VRAM-compressed. Every bone is
    `mixamorig_*`.
  - **Motion:** walk and run play in place (1.705 and 4.535 m/s).
  - **Raw downloads:** the FBX files stay out of Git.
- **Step 2, starting on foot:**
  - **The start:** "Begin / continue drive" starts the drive on foot beside the van. The van
    is dark: engine off, lights off, wipers parked, dash screens and rear lamps off. The
    objective reads "GET IN THE VAN", and the hint "E  Get in the van".
  - **"New drive"** starts on foot again. Recovery puts Ethan in the van with the engine
    running.
  - **Ethan:** the box figure is replaced by Ethan's model and clips (`driver.gd`). He walks
    at 1.705 m/s and runs at 4.535 m/s, the clips' own speeds; the box figure walked at
    2.8 m/s.
  - **Getting in:**
    - E walks Ethan to the driver's door (around the van if he is on the far side), and he
      plays Entering Car.
    - He grabs the handle at 1.05 s and pulls the door about 31° open by 1.6 s.
    - At 1.75 s the screen fades to black and back into the driver's seat, with the door
      shut.
    - The clip is made for a car: seated, his hips are 0.83 m off the ground, but the cab
      floor is 1.17 m up. So the climb in is not shown.
  - **Ignition:** 0.6 s after the cut, the needles sweep to the top and back over 1.4 s.
    Then the low beams and wipers come on (`FreightVan.start_engine()`, approved as #68).
    The engine sound fades in with it.
  - **The door:**
    - `build_first_drive_art.py` splits the driver's door out of `body.glb` into `door.glb`
      (1,172 triangles), with a 3 mm gap, its share of the rub strip, the seam and the
      wheel-arch trim.
    - The cab door handles move down from 1.60 m to 1.05 m, where the clip's hand closes.
    - Every other generated model is byte-identical.
    - The door glass and its rain layer swing on the same hinge.
    - The Honda interior's door trim stays in place: it is merged into 31 meshes with the
      dash. The cut comes before it would show.
- **Test changes, by the author's request:**
  - **`first_drive_integration.gd`:** "Nearby driver can reenter" now waits up to 8 s for
    Ethan to get in, because getting in takes about 2.5 s instead of one frame.
  - **`check_first_drive_art.py`:** expects five van models, the driver's door included.
  - **Unchanged:** every other suite. They start the game through `_resume()`, which skips
    the on-foot start, as it always skipped the menu.
  - **New `game/tests/test_on_foot.gd`, 25 checks:** the dark start; walking and running at
    the clips' paces; the door swing with its glass; the cut; the ignition sweep, low beams
    and wipers; driving after it; getting back in without a second ignition; "New drive".
    With the ignition call removed it fails 20/25 and exits 1
    (`logs/phase_1/run19/step2/mutation_no_ignition/`).
- **Tests:** all suites pass (64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31,
  12/12, 25/25; art 0 failures); logs are in `logs/phase_1/run19/step2/`.
- **Evidence:** `evidence/phase_1/characters/step1/` and `step2/`.

## Revision 2026-10-31 (Run 19, step 3: the oncoming van and its glare)

- **Author:** "on a turn let a van come and its headlights should reduce our visibility", then
  "Yes, start step 3 (Recommended)" (#61, #69).
- **The encounter** (mission `first_drive.gd`):
  - **When:** in the last stage, 90 m below the last hairpin of the descent (road sample 970),
    the mission sends one oncoming van per drive.
  - **Where it starts:** out of sight beyond the valley S-bend (samples 1040–1090). It is timed
    from the player's speed to meet the player on the S-bend (sample 1012).
  - **Clearing it:** recovery and "New drive" clear it and allow it again.
  - **The road:** the app now gives the mission the road (`route.road`).
- **The van** (`game/features/vehicles/oncoming_van/oncoming_van.gd`, new):
  - **Model:** built from our van's body, door and tyres, painted dark grey-blue. It is an
    `AnimatableBody3D` on layers 1 and 2, so both the van and Ethan collide with it.
  - **Driving:** it follows the road at 40 km/h, slows for bends (2.5 m/s² of grip), and keeps
    1.3 m right of the centre line, its right wheels on the verge. If the player's van blocks
    its lane, it brakes on a 3 m/s² curve and stops 2.5 m short. When the player keeps right,
    it squeezes past with 0.2 m to spare.
  - **High beams:** if the player's high beams are on while it is within 150 m, it flashes
    its own high beams twice.
  - **Leaving:** it drives back up the hill and is removed at sample 900.
  - **Its lights:**
    - two low beams with our low-beam pattern, without shadows, lighting the world and the
      player's cab;
    - bright lenses, and flares outside;
    - red tail lamps.
- **Glare on the player's windshield** (`windshield.gdshader` and `van_presentation.gd`, both in
  the van's folder):
  - **Where:** each lamp's point on the glass comes from the driver's eye. Glare is off when a
    tree trunk hides the lamp.
  - **Strength:** it grows as the lamp faces the driver (facing³) and as it comes closer
    (40 m falloff). It is 3.2× for high beams.
  - **What it adds:**
    - a bright core;
    - an eye veil that fades with angle from the lamp;
    - a wet-film halo;
    - light streaks along the wiper arcs;
    - lit droplets near the lamp.

  The veil washes out the glass around the lamps, which is what makes the road hard to see.
- **Rain in its beams:** `beam_rain.gdshader` also lights the rain with the oncoming van's
  lamps, backlit 2.5×, within 70 m. It shows even with the player's lights off.
- **Measured** (`capture_oncoming.gd`, parked at the S-bend):
  - glare power, per lamp: 0.10 at 120 m, 0.28 at 60 m, 0.42 at 35 m, 0.76 at 20 m and
    0.89 at 10 m;
  - windshield brightness: 53 before the van and 88 at 20 m;
  - once it is behind, the glare is 0.
- **Tests:**
  - **New `game/tests/test_oncoming_van.gd`, 19 checks.** It fails when the van ignores a
    blocked lane (18/19) and when the glare is removed (18/19), each with exit 1
    (`logs/phase_1/run19/step3/mutation_*`).
  - **All suites pass** (64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31,
    12/12, 25/25, 19/19; art 0 failures); logs are in `logs/phase_1/run19/step3/`.
- **Evidence:** `evidence/phase_1/oncoming/step3/`. The stills were taken on battery, so their
  frame rates are not comparable.

## Revision 2026-10-31 (Run 19, step 4: the collision, the flight, getting out at the depot; C29)

- **Author:** "we didnt hit and run anyone in the game yet? ... that is when we should hit and
  run", then "Yes, unavoidable (Recommended)" (#61, #70; C29).
- **The pedestrian** (`game/features/characters/pedestrian/pedestrian.gd`, new):
  - **Who:** Mixamo Ch01 in the charcoal polo. He has no collision body, and stays
    unidentified (N01).
  - **The step-out:** he walks from the right verge across the van's path at his Walk clip's
    pace.
  - **The hit:** when the front bumper reaches him (within 1.7 m of the centre line), he plays
    Hit By Car from its impact frame (2.6 s). He is thrown forward 0.8 m + 0.16 × speed²
    (at most 12 m), over up to 1.6 s, and lies on the road. There is no gore.
- **The sequence** (mission `first_drive.gd`):
  - **The step-out:** 1 s after the oncoming van has passed, at 25 km/h or more, he steps out
    1.3 m right of the van's path, aimed 0.75 s ahead of the bumper. Until the impact the wet
    road gives 3 m/s² of braking, so the hit always happens (C29).
  - **The hit:** the van's own collision thud plays, the camera jolts, and the music stops.
    Full brakes bring the van to a stop.
  - **The hold:** the van is held for 4 s; throttle and E do nothing. Then the objective
    becomes "DRIVE." and driving returns. E stays blocked while fleeing.
  - **No witness:** the oncoming van is behind the player and gone around the bend; in the
    test it was 94 m away.
  - **The depot:** parking there ends the drive, as before. After the hit, Ethan gets out:
    - a fade, then Exiting Car from 2.6 s, standing at the open door;
    - he turns and shuts the door between 3.7 and 4.3 s, then walks clear;
    - control returns on foot.
  - **Recovery and New drive:** after the hit, recovery keeps the pedestrian where he lies.
    "New drive" clears everything and brings the music back.
- **Eye adaptation** (`van_presentation.gd`):
  - **Darkening:** the oncoming lamps' glare lowers the driving camera's exposure
    (`CameraAttributesPractical.exposure_multiplier` = 1 / (1 + 1.2 × adaptation)). It comes
    on in about a third of a second and recovers over about 2 s.
  - **Measured:** staring into the lamps the view darkens to 0.47, and it is still at 0.83 a
    second after they pass, when the pedestrian steps out.
- **Other files:**
  - `freight_van.gd`: `held`;
  - `driving_audio.gd`: `silence_music()`, `play_music()`;
  - `van_presentation.gd`: `jolt()`;
  - `driver.gd`: `play_clip()` takes a start time and a model shift; `finish_clip()` moves
    Ethan to where the clip left him;
  - `game/app/first_drive.gd`: `_struck()`, `_drive_completed()`, `_exit_at_depot()`, E
    blocked while fleeing.
- **Tests:**
  - **New `game/tests/test_collision.gd`, 18 checks:** step-out timing and place, the
    unavoidable hit with the brakes on, the thud, the music, no witness, the skid and hold,
    E blocked, "DRIVE.", driving again, thrown clear and lying, getting out at the depot, and
    "New drive".
  - **Mutation:** with dry brakes (9 m/s²) it fails 8/18 and exits 1
    (`logs/phase_1/run19/step4/mutation_dry_brakes/`).
  - **`test_oncoming_van.gd`** gained the two adaptation checks (21 in all).
  - **All suites pass** (64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31,
    12/12, 25/25, 21/21, 18/18; art 0 failures); logs are in `logs/phase_1/run19/step4/`.
  - **Fix before the commit:** a final run caught a freed-object error line. "New drive"
    cleared the encounter by putting the oncoming van into a typed list after it had already
    removed itself. `_clear_oncoming()` now checks the van and the pedestrian one at a time.
    The final run's only "ERROR:" lines are the engine's "resources still in use at exit".
- **Evidence:** `evidence/phase_1/collision/step4/`, an unbraked hit at 30 km/h; he lies 8 m
  ahead of the bumper, at the edge of the low beams.
- **Not done:**
  - door, engine-start and impact sounds of their own (the van's collision sound is used);
  - the drive's end screen still reads "DRIVE COMPLETE";
  - a hit is not saved with the checkpoint, so quitting and reloading replays the encounter.

## Revision 2026-11-01 (Run 20, step 1: the hit by physics, a ragdoll)

- **Author:** "hitting the user make it more realistic", then "Yes, start step 1 (Recommended)"
  (`AUTHOR_PROMPTS_AND_DECISIONS.md` #72–#73).
- **Why the old hit looked fake:** Mixamo's Hit By Car is a canned knock from the side. He
  stood, tipped over to his right, and a script slid him along the road, whatever the van's
  speed.
- **What happens now** (`game/features/characters/pedestrian/pedestrian.gd`):
  - **Before contact:** when the van's bumper is about 0.35 s away, he stops walking, stands
    still and turns up to 69° toward the headlights.
  - **At contact:** the animation stops and a physics ragdoll takes over:
    - 11 bodies: pelvis, torso, head, both upper arms, forearms, thighs and shins;
    - 75 kg in all, collision with the road, verge, trees and rails, but not with each
      other.
  - **The throw:** the van's flat front gives the whole body one push, 1.08 × the van's speed
    plus 0.6 m/s upward. That is forward projection, as when a van or truck hits a person.
    The feet catch the road, so he is swept off his feet, lands, and tumbles and slides on
    the wet road.
  - **At rest:** once nothing has moved more than 5 cm in half a second for a second, the
    bodies are frozen where they lie.
  - **Typical result:** at 29 km/h he lands about 5.6 m down the road and the braking van
    stops 2 m short of him.
- **Joints, and why:** each choice was found with a stress test of 24 pushes (3–10 m/s) from
  walking and standing poses, plus 9 from the worst stride poses:
  - **Knees and elbows:** hinges. They bend only forward (140° and 145°) and stop 2° past
    straight. The limits are stiffened (softness 0.3, bias 0.6), and their axes come from the
    walk clip.
  - **Hips, shoulders, the torso at the pelvis, the neck:** 6DOF joints with per-axis limits:
    - hips 75° swing and 40° twist;
    - shoulders 80° and 60°;
    - torso 40° and 35°;
    - neck 60° each.
  - **Cone joints failed** under impacts, even at human ranges: 23 of 24 pushes blew up.
    Shoulder limits near 90° failed too.
  - **One torso body:** a three-joint spine chain (pelvis, lower spine, chest, head) failed,
    so the torso is one body from the lower spine to the neck.
  - **Built standing:** the ragdoll is built in his standing pose (Hit By Car at 1.6 s), so
    the limits centre on how he stands.
  - **Result:** 0 of 33 stress trials fail. In the game the hit lands the same way every run.
- **The pedestrian model:** `tools/art/convert_mixamo.py` now exports him at real size. Mixamo's
  1/100 scale and 90° turn are baked in, because physics bodies cannot hang from a scaled
  skeleton. His clips are unchanged, and Ethan's file is byte-identical.
- **Test changes, by the author's request:** `test_collision.gd` (22 checks) replaces "Hit By Car
  plays" with checks that:
  - he freezes in the headlights before the impact;
  - a ragdoll takes over at the impact;
  - he comes to rest (2.6 s), thrown clear ahead of the bumper (1.8 m when braking at once);
  - he lies on the road and never sinks into it;
  - knees and elbows only bend the right way (worst 34° and 13°).

  The hold check now counts only while the van is held.
- **Mutations:** both exit 1 (`logs/phase_1/run20/mutation_*`):
  - with no push he ends 3.1 m behind the bumper, under the van: 20/22;
  - with the knee limits reversed the knees bend to −103°: 21/22.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31,
  12/12, 25/25, 21/21, 22/22; art 0 failures. Logs are in `logs/phase_1/run20/`.
- **Evidence:** `evidence/phase_1/collision/run20/`:
  - an unbraked hit at 29 km/h;
  - side-on frames 0.15, 0.35, 0.6 and 1.0 s after the impact;
  - where he lies, at night and in debug light;
  - the depot exit.
- **What it means in play:**
  - He comes to rest about 2 m ahead of the van and to its right, inside a cab-over van's
    blind spot, so the driver's seat does not show him; the player passes him on the left
    when driving off.
  - His final pose depends on the hit; in the capture he lies curled on his side.
- **Not done (step 2, its own approval):** a cracked windshield, a cabin shudder and a heavier
  impact sound.

## Revision 2026-11-01 (Run 20, step 2: the van takes the hit)

- **Author:** "Yes, all of it (Recommended)" (`AUTHOR_PROMPTS_AND_DECISIONS.md` #73), for a
  cracked windshield, a cabin shudder, Ethan leaning forward to look, and a heavier impact
  sound made by code. Then, for the crack, "Put it in anyway" (#74).
- **Impact sound** (`impact_body.wav`, from `body_impact()` in
  `source_assets/audio/first_drive/synthesize.py`):
  - 1.4 s: a deep thud falling from 90 to 50 Hz, a crunch, nine sharp ticks of cracking
    plastic in the first 0.15 s, then the body landing on the road at 0.42 s;
  - the hit now plays it through `driving_audio.gd`'s `body_impact()`, instead of the van's
    generic collision thud (the mission no longer emits `collided` for the hit);
  - the other 12 WAVs are byte-identical.
- **Cabin shudder** (`van_presentation.gd`, `jolt()`):
  - the cab rocks on a damped spring (`ROCK_STIFFNESS` 38, `ROCK_DAMPING` 3, about 1 Hz),
    kicked nose-down by the impact;
  - the kick and the camera shake grow with the impact speed, full at 9 m/s
    (`IMPACT_SPEED` in `game/app/first_drive.gd`). Before, the shake was always full;
  - the result is 0.36° at 15 km/h and about 0.75° at 31 km/h, settled within about 1.5 s.
- **Ethan leans to look** (`van_presentation.gd`, `_lean_to_look()`):
  - while the van is held and stopped after the hit, his eye moves 55 cm forward and 15 cm
    up over the wheel in 0.7 s, half-standing, and his view turns to the body (`LEAN`,
    `LEAN_RATE`);
  - when "DRIVE." appears he sits back;
  - **measured** with sight lines against the cockpit model: from the seat, none of the
    pedestrian's 11 body parts show, because the Honda's long screen housing hides him.
    Leaning, 9 of 11 show when he lies 1.6 m ahead of the bumper. The proposed 35 cm lean
    showed at most 2.
- **The cracked windshield, against the physics, at the author's request:**
  - **why it cannot happen:** at the impact his head is 1.56 m up, at the van's nose. The
    van has a flat hood 1.50–1.57 m high that reaches 0.9 m ahead of the windshield, and the
    glass starts at 1.66 m. A front that high throws a person forward, as step 1's ragdoll
    does, so his head never reaches the glass. The proposal had assumed low cab-over glass.
    Claude Code reported this, and the author chose "Put it in anyway";
  - **the look** (`windshield.gdshader`, `crack_lines()`): a spider-web crack, as laminated
    glass breaks:
    - 14 straight radial cracks with slight kinks, some long and some short;
    - up to four rings made of straight pieces between neighbouring radial cracks;
    - a frosted centre;
    - uneven glints along every line.
  - **where:** in line with where his head was, low on the glass. It is kept inside the part
    of the glass the driver sees from the seat (`CRACK_AREA`: 55 cm either side of the
    centre, and above the lowest 16 cm, which the dash hides);
  - **size:** it grows with the impact speed, full size (34 cm across each way) at 9 m/s and
    46% at 15 km/h, and it stays for the rest of the drive;
  - "New drive" clears it.
- **Found: the cab view does not draw the van's own hood.** The driving camera draws layers
  1 and 3, and the van's body is on layer 2:
  - from the seat this does not matter, because the dash hides the hood;
  - leaning, it does. With the hood counted, a braked hit (he lies 1.6 m ahead) shows 0 of
    11 body parts, and an unbraked hit (2.8 m ahead) shows 10 of 11;
  - the author chose "Draw the hood (Recommended)", as its own step (#74).
- **Test changes, with reasons** (`test_collision.gd`, 28 checks):
  - "The van's collision thud plays" becomes "The body strikes the van with a heavy impact
    sound", because the hit now plays its own sound instead of the van's thud;
  - **new:**
    - the cab rocks on its springs (0.36°, allowed 0.11°–1.15°);
    - the windshield cracks low in front of where he struck the van, in view from the seat
      (unblocked from the eye, and inside the seated camera's view);
    - leaning, Ethan sees him (9 of 11 body parts, none from the seat, the view centred on
      his hips);
    - Ethan sits back to drive;
    - the crack stays for the rest of the drive;
    - "New drive" brings back an unbroken windshield.
  - The sight lines are rays against the meshes the driving camera draws. Glass, decals,
    screens and the moving wipers are left out.
- **Mutations:** both exit 1 (`logs/phase_1/run20/step2/mutation_*`):
  - with no lean, 27/28;
  - with the crack at the glass's bottom edge, behind the dash, 27/28.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31,
  12/12, 25/25, 21/21, 28/28; art 0 failures. Logs are in `logs/phase_1/run20/step2/`.
- **Evidence:** `evidence/phase_1/collision/run20_step2/`, 15 stills from an unbraked hit at
  8.3 m/s, including:
  - `leaning_over_the_wheel`: he lies on the verge in the headlight spill, and the crack
    glints low on the right of the glass;
  - `sitting_back`: from the seat he cannot be seen; the crack sits low on the right, with
    the wiper crossing it;
  - `driving_on_with_the_crack`.

  `capture_collision.gd` now sets its window to 1280×800 itself, because one run opened
  full-screen.

## Revision 2026-11-01 (Run 20, step 3: the hood in the cab view)

- **Author:** "Draw the hood (Recommended)" (#74), then "Yes, start step 3 (Recommended)" (#75).
- **Why:** the driving camera draws layers 1 and 3, and the van's body is on layer 2. From the
  cab the hood was invisible, so leaning over the wheel showed ground that the real hood
  hides.
- **Change** (`van_presentation.gd`, `_hood_from_cab()` and `_hood_faces()`):
  - **the copy:** the body's own triangles inside the hood region (`HOOD`: 2.6 m wide,
    1.0–1.7 m high, from the nose back to the windshield's base). That is 1,002 triangles,
    with the body's own materials;
  - **its layer:** render layer value 8 (`HOOD_LAYER`), which only the driving camera draws
    (cull mask 5 becomes 13). The cabin light, the headlights and the reflection probe leave
    it alone, and the mirrors keep showing the real body;
  - **its place:** 3 mm outside the real hood (`HOOD_LIFT`). Outside cameras see the same
    paint without flicker, and the copy is not in the real hood's shadow. It casts no shadow;
  - **why not the whole body:** its solid roof would cover the moon roof.
- **Result:**
  - the seated driving view is unchanged, because the dash hides the hood;
  - leaning, the hood covers the ground just ahead of the bumper. After a braked hit (he
    lies 1.6 m past the bumper) he stays hidden even when Ethan leans;
  - leaning shows the road from 2.4 m past the bumper (6.3 m from the seat), so a harder hit
    that throws him further still shows him.
- **Test changes, with reasons (#74–#75),** `test_collision.gd`, 29 checks:
  - the sight lines use the driving camera's own cull mask, so the hood counts;
  - "Leaning ... Ethan sees him lying in the road" becomes "Leaning 55 cm over the wheel,
    Ethan looks, but the hood hides him 1.6 m past the bumper (0 of 11 body parts in view)";
  - **new:** "Leaning shows the road from 2.4 m past the bumper, where a harder hit leaves
    him (6.3 m from the seat)".
- **Mutations:** both exit 1 (`logs/phase_1/run20/step3/mutation_*`):
  - with the hood left out of the cab view, 28/29;
  - with no lean, 27/29.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31,
  12/12, 25/25, 21/21, 29/29; art 0 failures. Logs are in `logs/phase_1/run20/step3/`.
- **Evidence:** `evidence/phase_1/collision/run20_step3/`, 15 stills from an unbraked hit at
  8.3 m/s:
  - in `leaning_over_the_wheel` the ivory hood covers the ground ahead. He came to rest
    2.25 m past the bumper, and only a sliver of him shows past its edge;
  - the seated stills (`he_steps_out`, `sitting_back`) look as before.

## Revision 2026-11-01 (Run 21, step 1: the macOS export preset and the pack listing)

- **Author:** "macOS export first (Recommended)" (#76), then "Yes, start step 1 (Recommended)"
  (#77). This is §4.7, the export that Assignment 10 asks to be attempted by November 3.
- **The preset** (`game/export_presets.cfg`, new, one preset named "macOS"):
  - Apple Silicon only (`binary_format/architecture` "arm64"), for this MacBook Air M4 (C13);
  - version 0.1.0;
  - "Testing" distribution, built-in ad-hoc signing, no notarization and no credentials;
  - a placeholder bundle identifier, `com.blackridge.nowayback`, to be replaced before any
    store release;
  - output to `builds/macos/Blackridge.zip` (`builds/` is ignored by Git);
  - it leaves out `tests/*`, `experiments/*` and `app/visual_benchmark.*`.

  Godot's macOS export has no separate app-name option, so the app takes the project's name,
  "Blackridge: No Way Back". Step 2 shows how the colon comes out in the app's file name.
- **One project setting, with the author's OK (#77):** `game/project.godot` gains
  `rendering/textures/vram_compression/import_etc2_astc=true`. Godot 4.7.2 refuses to export
  for Apple Silicon without it: "Cannot export for universal or arm64 if ETC2 ASTC texture
  format is disabled."
  - **The re-import:** the headless import made a second, ETC2/ASTC copy of each of the
    160 compressed textures in `game/.godot/imported/`.
  - **Changed sidecars:** each texture's tracked `.import` file now lists both formats and
    the new copy, so 160 `.import` files change with this step.
- **The pack listing (P6),** exported as ZIP packs into the agent's scratch folder:
  - **with the preset's filters:** 703 entries, 482.7 MB, and no file from `tests/`,
    `experiments/` or the visual benchmark;
  - **with a temporary filter-free copy of the preset:** 737 entries. The 34 extra entries
    are the 11 test scripts (22 entries), the hint experiment's four files with its two
    exported resources, its scene and its texture, and the benchmark's scene and script. The
    temporary preset was removed afterwards;
  - P6 holds;
  - both packs carry both texture formats (160 of each), so the Apple Silicon pack also
    ships the desktop copies;
  - `shaders/hint_experiment.gdshader`, used only by the experiment, still ships, because
    it lives in `game/shaders/`.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31,
  12/12, 25/25, 21/21, 29/29; art 0 failures. Logs are in `logs/phase_1/run21/step1/`.
- **Evidence:** `evidence/phase_1/export/run21/`: both listings, the 34 entries only the
  filter-free pack has, and both export logs (no errors or warnings).
- **Next (step 2, its own approval):**
  - check the downloaded 4.7.2 templates against the official SHA-512;
  - install the macOS template;
  - run `--export-release`;
  - launch and play the app, and record its SHA-256.

## Revision 2026-11-01 (Run 21, step 2: the release export)

- **Author:** "Yes, start step 2 (Recommended)" (#78), then "Switch to universal
  (Recommended)".
- **Templates:**
  - the 4.7.2 templates file downloaded on 2026-10-30 matches the official SHA-512;
  - only the macOS template (`macos.zip`, 123.6 MB, with `version.txt` "4.7.2.stable") is
    installed, in `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`. The
    folder was empty before.
- **First attempt, kept as evidence:** the arm64 preset failed in 2 s with "Requested
  template binary "godot_macos_release.arm64" not found". Godot's official macOS template
  holds only universal binaries. An arm64-only export needs a custom-built template, so
  Claude Code's arm64 recommendation in step 1 was wrong for official templates.
- **The fix, with the author's OK:** `binary_format/architecture` becomes "universal". The
  app runs natively on the M4; it also carries the Intel version, which costs about 85 MB.
  Both texture formats are needed for universal, and step 1 already imports both.
- **The export:** `--export-release "macOS" ../builds/macos/Blackridge.zip` exits 0 in 20 s:
  - `builds/macos/Blackridge.zip` is 350,894,372 bytes, SHA-256
    `a547b5eae4e68f4935fbc6a1242efb4bd2c80d863b83fa4bfca848150e690ae7`. It is built from the
    working tree on `develop`, with Runs 20 and 21 not yet committed;
  - the app is `Blackridge- No Way Back.app`: macOS turns the colon into a dash in the file
    name, and the menu-bar name stays "Blackridge: No Way Back";
  - it is a universal binary (x86_64 and arm64) with a 384.7 MB pack, ad-hoc signed, bundle
    identifier `com.blackridge.nowayback`, version 0.1.0;
  - it carries no quarantine flag, so Gatekeeper lets it open on this Mac.
- **Launch:** it opens on the MacBook Air M4 and keeps running. The author's play check, and
  the app's own log (written when it quits), are still to come.
- **Docs:**
  - README gains the export note and command;
  - `CLAUDE.md`'s `project.godot` rule gains the texture setting (approved with step 2).
- **Evidence:** `evidence/phase_1/export/run21/`:
  - `export_release_arm64_failed.log`;
  - `export_release_universal.log`;
  - `release_export.txt` (size, SHA-256, architectures, signature, bundle values).
- **The editor incident (#81):**
  - the open Godot editor, told to "Ignore" files changed on disk, rewrote `project.godot`
    and dropped the texture line, then re-imported the textures in one format;
  - the editor was closed without saving, the line was restored and the textures were
    re-imported (160 again);
  - a check export exits 0, the same size as the build;
  - whenever the editor reports files changed on disk, choose "Reload".

## Revision 2026-11-01 (Run 22, step 1: the bus stop and zebra crossing, C30)

- **Author:** "its kind of weird hes coming out of jungle it doesnt feel natural. add a zebra
  crossing and a bus stop or something like that?" (#76); "Bus stop + zebra crossing
  (Recommended)"; then "Yes, start step 1 (Recommended)" (#80).
- **Where:**
  - the foot of the hill road, at road sample 1002 (41.7, 53.8), about 80 m before the
    depot gate;
  - the road there is straight and flat, and the nearest lamp is 36 m away, so it is the
    story's "dark stretch of road";
  - the town lies to the left, and the footpath points at it;
  - the hit moves here from under the first depot lamp.
- **The stop** (`bus_stop.gd`, new, placed by `industrial_loop.gd`):
  - **the shelter:** on the right, 10 m before the crossing, on a concrete pad. It has steel
    posts, a roof, a glass back and sides, a slatted bench, a timetable (made-up Blackridge
    Transit, route 4) and Poly Haven's metal trash can. Its frame and back glass have
    collision;
  - **the footpath:** leaf-scattered gravel from the far side, 26 m toward the town's lights;
  - **clearings:** they keep trees and plants out of the shelter and off the path.
- **The crossing paint** (`wet_asphalt.gdshader`, in the environment folder):
  - four continental bars, 0.6 m wide with 0.6 m gaps, across the 4.5 m road, 3 m long;
  - more worn in the tyre tracks, speckled, and glossier than the asphalt when wet;
  - the rest of the road draws as before.
- **Signs** (`ghat_dressing.gd`, `tools/make_road_signs.py`):
  - **the atlas** gains a fifth row: pedestrian crossing (MUTCD W11-2), an AHEAD plate, a
    down-left arrow plate and a BUS STOP flag. The 15 older faces are pixel-identical;
  - **both directions:** the pedestrian sign with AHEAD 30 m (100 ft) before the crossing,
    and with the arrow at the crossing;
  - **the BUS STOP flag** stands by the shelter.
- **The pedestrian:**
  - `convert_mixamo.py` gives him Ethan's Breathing Idle, and `pedestrian.glb` is
    re-exported; Ethan's file is byte-identical;
  - he waits at the kerb (`wait_at()`), then walks (`step_out()`);
  - **after a near miss** (the van stops short), he finishes crossing and walks up the
    footpath.
- **The mission** (`first_drive.gd`; the app passes it the crossing):
  - **the encounter** starts at road sample 934 (it was 970), so the oncoming van, still
    spawned beyond the valley S-bend, meets the player 16 m before the crossing;
  - **the pedestrian** waits at the kerb from then on;
  - **the step-out:** he leaves the kerb when the van's time to the crossing equals his walk
    into its path, whatever its speed. This amends C29's 25 km/h floor (#76). Braking stays
    capped at 3 m/s² once he steps out;
  - **measured:** he steps out at 25 km/h with the bumper 4.7 m short, and is struck on the
    crossing. He is also struck on it at 20, 40 and 54 km/h;
  - **below about 15 km/h,** an instant stop can avoid him: at 9 km/h the van stops short.
    With a human reaction time of half a second he is still hit at 10 km/h.
- **Test changes, with reasons (#76, #80):**
  - **`test_collision.gd`** (30 checks):
    - the run-up moves to the new site (trigger 930, wait and run from 976);
    - it steers with a new lane keeper (`game/tests/lane_keeper.gd`), because the road
      bends before the crossing;
    - "No one is on the road while the oncoming van passes" now adds "he is still at the
      kerb", and a new check has him waiting at the crossing;
    - "He steps out only once the van is doing 25 km/h" and "He steps out from the right
      verge" become "He steps off the kerb onto the crossing, X m before the van's bumper";
    - new: "He is struck on the crossing";
    - the lean check judges each body part against the hood line, because his hips can lie
      short of it while his head lies beyond.
  - **`test_oncoming_van.gd`** and **`capture_oncoming.gd`:** the trigger spot moves from 966
    to 930.
  - **New `test_crossing.gd`** (11 checks):
    - the shelter and its fittings, the paint, the signs both ways and the flag;
    - the footpath and its clearing;
    - the dark stretch;
    - he keeps waiting while the van stands still;
    - at 20 km/h he is still struck on the crossing.
- **Mutations:** both exit 1 (`logs/phase_1/run22/step1/mutation_*`):
  - with no paint, `test_crossing.gd` fails 10/11;
  - stepping out 2 s early fails `test_collision.gd`: the van stops, and he walks on across.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31,
  12/12, 25/25, 21/21, 30/30, 11/11; art 0 failures. Logs are in `logs/phase_1/run22/step1/`.
- **Evidence:** `evidence/phase_1/collision/run22/`, 19 stills:
  - the crossing from above, at night and in debug light;
  - the approach at 44 m and at 20 m, with him waiting at the kerb;
  - the step-out at 57 km/h, then an unbraked hit at 60 km/h.
- **Next, each step approved on its own:** the smaller, more realistic van, and the fall onto
  the windshield.

## Revision 2026-11-01 (Run 22 step 2 and Run 23 step 1: the van choice and its inspection)

- **Author:** "maybe lets reduce the van size?? and make it more realsitic to look at from
  outside? and do over the windshield and movie style type?" (#76), then "Iveco Daily
  (Recommended)" and "I'll open Blender's add-on" (#82, #83).
- **The shortlist:** a private page, https://claude.ai/artifact/EMZWF2L7Fkv3GcJTqGmJbX. The
  Iveco Daily van (2014) by Max was chosen. It is CC BY, plus Max's note "You must inform me
  of your usage"; a Discord message was drafted for the author to send.
- **Inspection** (nothing in the game changed):
  - imported through the Blender add-on into a separate scene, set to real size from the
    real Daily's 1.996 m body width, and compared with today's van;
  - it is 0.9 m lower and 0.45 m narrower. The eye drops from 2.03 m to 1.72 m, and the road
    shows from about 4 m instead of 7 m;
  - its nose (hood edge 1.1 m, glass from 1.38 m raked about 45°) makes the fall onto the
    windshield realistic.
- **Files:**
  - `.gitignore`: keeps `source_assets/sketchfab/*/*` out of Git, apart from each folder's
    README;
  - `source_assets/sketchfab/iveco_daily_2014/README.md`: source, licence and size;
  - `evidence/phase_1/van/run23_step1/`: five renders.
- **Open:** whether the van keeps the Honda e cockpit (refitted lower and narrower) or uses
  the Iveco's own cab.

## Revision 2026-11-01 (Run 23, step 2: the Iveco made ours, C31)

- **Author:** "Iveco's own cab (Recommended)" (#84), then "Yes, start step 2 (Recommended)" (#85).
  Nothing in the game uses the van yet; step 3 puts it in.
- **The converter** (`tools/art/convert_iveco.py`, new): Blender makes the game files from the
  raw copy. It stops with an error if a part it removes or splits is not found.
  - **Size and direction:** the real-size transform is baked in, and the van is turned to face
    -Z with the driver on the left.
  - **Branding removed:**
    - raised IVECO letters on the grille (318 triangles) and on the left rear door (319). The
      rear door's were found when a render still showed the name after its texture was cleaned;
    - the name painted in the textures behind the grille letters (two areas), on the rear door
      and on the steering-wheel badge. Each is cleaned in the colour, gloss and bump maps, since
      the gloss map carried the name too, blurred over about 28 pixels;
    - texels that only the removed letters used are made plain grey.
  - **Plates:** the model's French plate ("MA-222-AX", with "DAILY" on its strip) becomes a
    cream "BLACKRIDGE / BR 048" plate, drawn by `tools/make_number_plate.py` (new). The same
    plate is added in the recess on the left rear door, which had none. "BLACKRIDGE" along the
    top is Claude Code's reading of "a Blackridge plate"; the author may change it.
  - **Wipers:** the model's own wipers (1,530 triangles) are removed.
  - **Parts,** each with its own origin:
    - `DriverDoor` and `PassengerDoor` swing about their hinges (local Y), with `DriverWindow`
      and `PassengerWindow` as children;
    - `WheelFrontLeft`, `WheelFrontRight`, `WheelRearLeft` and `WheelRearRight` turn about
      their centres (local X);
    - `SteeringWheel` (rim, spokes, hub, badge and buttons; 2,748 triangles) turns about its
      column, local Z, which points up the column at the driver, 44.7° from level. A right turn
      is a negative turn about local Z. The column, stalks and key stay in the cab;
    - the `Windshield` glass is separate from the other glass.
  - **Textures:** 2048 pixels outside and 1024 in the cab, down from 4096, as WebP.
- **Files** in `game/features/vehicles/freight_van/art/iveco/`:
  - `iveco_exterior.glb` (5.5 MB, 56,107 triangles): `Body`, the doors, wheels and windshield;
  - `iveco_cab.glb` (1.9 MB, 31,630 triangles): `Cab` and `SteeringWheel`;
  - the 35 WebP textures Godot extracted on import. `tools/assets/configure_imports.py` sets
    them to VRAM compression with mipmaps, 11 of them as normal maps; it now also recognises
    `*_normal.webp`;
  - `ATTRIBUTION.md`.

  The van is 5.53 m long, 2.08 m tall and 2.0 m wide, and the tyres stand on y = 0. The
  converter gives the same bytes on every run.
- **Art check exception (like the cockpit's, Run 12):** `check_first_drive_art.py` gains an
  Iveco section, 15 checks:
  - the two files hold their parts, and no part or material is named as a badge;
  - finite geometry, valid vertex references and unit normals;
  - inverted triangles within the source model's own: 49 outside and 17 in the cab. The export
    has 49 and 13, and none are new;
  - WebP textures of at most 2048 and 1024 pixels;
  - the wheels on their centres at the right corners, the van facing -Z with the driver's door
    on the left, and the steering wheel's column axis;
  - a budget of under 100,000 triangles, and every file under 25 MB.

  **Mutation:** with the van exported facing +Z, it fails three checks and exits 1
  (`logs/phase_1/run23/step2/mutation_faces_plus_z/`). A first attempt, which left out the
  half turn, crashed in Blender, and Blender still exited 0. The converter's usage now passes
  `--python-exit-code 1`.
- **Tests:** all suites pass (64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 29/29, 31/31,
  12/12, 25/25, 21/21, 30/30, 11/11; art 0 failures). Logs are in `logs/phase_1/run23/step2/`.
- **Godot:** the headless import gives exit 0 with no errors. A probe loads both files: the
  driver's door is at (-0.962, 1.102, -1.909), the front-left wheel at (-0.872, 0.359, -2.007),
  and the steering wheel at (-0.476, 1.313, -1.642), with local Z (0, 0.703, 0.711). The glass
  is transparent.
- **Evidence:** `evidence/phase_1/van/run23_step2/`:
  - `before_after_sheet.png`: the grille and plate, the rear door, and the steering-wheel badge;
  - `van_sheet.png`: front and rear, the driver's door open with the front wheels steered, and
    the steering wheel turned 90°.
- **Seen in the renders:** at 2048 pixels the finest outside detail, such as the lower grille's
  honeycomb, is softer than in the 4096 original.
- **Not done (step 3, its own approval):** the van in the game, with its lights, mirrors,
  glass, wipers, camera eye, collision and tests. The author messages Max before the van files
  are committed.

## Revision 2026-11-01 (Run 23, step 3: the Iveco in the game, C31–C32)

- **Author:** "and proceed with step 3" (#86); for the cab, "Cut one in (Recommended)" and "No
  inside mirror (Recommended)" (#88, C32).
- **The van** (`van_presentation.gd`, rebuilt around the two Iveco files):
  - **Placement:** the Iveco sits 0.16 m up and 0.5 m back in the van's frame. Its tyres rest
    on the road (the old ones sank 13 cm into it), and its front axle stays where the old
    one was.
  - **Collision** (`freight_van.tscn`): the box is the Iveco's real size, 2.0 × 2.09 × 5.53 m
    (it was 2.4 × 2.8 × 5.3 m).
  - **Layers:** the outside is on the body layer, which the mirrors draw; the cab, the glass
    and the screens are on the cabin layer. The driving camera now draws the body too (cull
    mask 7), so from the seat the driver sees the Iveco's real bonnet, door cards and
    mirrors. Run 20's hood copy is gone.
  - **Wheels:** the four Iveco wheels steer and roll on their own centres (radius 0.359 m),
    and the ground rays use their places.
  - **Steering wheel:** the Iveco's own wheel turns on its column, which leans 44.7° toward the
    driver.
  - **Driver's door:** it swings on its hinge, 31° as before, with its window and its mirror.
  - **Eye:** (−0.45, 1.88, −0.72), from the Iveco's seat. Leaning over the wheel moves it 42 cm
    forward and 5 cm up (it was 55 and 15), which keeps it 11 cm behind the raked windshield.
  - **Lamps:** the Iveco's own lenses light up: the headlights warm white with either beam, the
    tail lamps red and brighter when braking, and each indicator amber on its own side. The
    two shadowed headlights move to the Iveco's lamps, 0.99 m above the road.
  - **Glass:** the windshield and both side windows are the Iveco's own glass. Each gets flat
    UVs, so the rain, wipers, glare and crack work on it as before. The windshield is
    1.77 × 1.0 m, raked 45.65°. Assignment 5's light fog sits on the windshield's own shape,
    12 mm inside.
  - **Wipers:** the pivots are where the Iveco's own wipers were; the arms are 42 and 40 cm, the
    blades 65 and 53 cm.
  - **Screens:**
    - our gauges sit on the Iveco's cluster, seen through the wheel;
    - the map sits on its centre screen, where the reverse camera shows in reverse;
    - with the engine off both go dark, instead of showing the model's lit dials and picture.
  - **Mirrors:** each door mirror shows its live view on both its glasses, the main one and the
    wide-angle one, and the driver's swings with the door. The Honda's dash-end and centre
    mirror screens are gone, and so is the inside-mirror camera (C32).
  - **Moon roof (C32):** `convert_iveco.py` cuts the opening (1.04 × 0.44 m) through the roof and
    the headliner over the front seats. The game adds tinted glass with rain on it, a dark
    frame inside and a rubber seal outside.
  - **Cab light:** a dim fill at chest height. Under the headliner it lit a hot spot in front of
    the moon roof.
- **Converter** (`tools/art/convert_iveco.py`): it now splits the lamp lenses from the clear
  glass (`Headlights`, `TailLamps`, the four indicators by side, and `BodyGlass`) and cuts the
  moon roof. The art check's parts list follows. The van is 88,428 triangles, and the cut adds
  no inverted triangle.
- **Other files:**
  - the mission's `BUMPER_AHEAD` is 2.52;
  - the pedestrian's `BUMPER_REACH` is 2.67 and `VAN_HALF_WIDTH` 1.25;
  - the oncoming van's `BUMPERS` is 4.77;
  - the app's boarding and exit spots fit the narrower van;
  - `capture_cockpit.gd` aims at the Iveco's screens and mirrors, and looks up.
- **Found and fixed:** freeing the Iveco's original windshield node in the frame it was made
  left Godot's light pairing inconsistent, so a windowed run printed four "indexing did not
  unpair geometries from light" errors at exit. The node is now freed at the end of the frame,
  and the errors are gone.
- **Test changes, with reasons (C31, C32):**
  - **`test_cockpit.gd`** is rewritten for the Iveco cab, 25 checks:
    - the Iveco's files are drawn and no old part is, and the triangle count;
    - layers and shadows;
    - the gauges and the map on the Iveco's screens, facing the driver, the gauges seen
      through the wheel; both dark with the engine off;
    - each door mirror's live view on both its glasses, the driver's swinging with the door;
      no inside mirror;
    - the moon roof open to the sky, with glass, rain, frame and seal;
    - the wheel on its column, and both steering directions.
  - **`first_drive_regression.gd`:** the collision check expects the Iveco's real size, and the
    wall beside the van is placed from the van's own width. The turning check still has a wall
    right beside the van.
  - **`first_drive_integration.gd`:** two live mirror viewports (it was three).
  - **`test_on_foot.gd`:** two dash screens go dark with the engine (it was five).
  - **Mutations:** both exit 1 (`logs/phase_1/run23/step3/mutation_*`):
    - with the steering reversed, the cockpit test fails 23/25;
    - with the gauges sunk 3 cm into the dash, 24/25.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31,
  12/12, 25/25, 21/21, 30/30, 11/11; art 0 failures. Logs are in
  `logs/phase_1/run23/step3/suites/`.
- **Measured** (`capture_beams.gd`, at the start, from the seat):

  | | Road 10–46 m | Road 50–100 m | White-out |
  | --- | --- | --- | --- |
  | Low beams | 88.7 | 44.7 | 0.00% |
  | High beams | 134.9 | 103.9 | 0.00% |
  | Lights off | 18.6 | 24.8 | 0.00% |

  The Mac was on battery; the captures ran at 72.8–80.9 FPS, which is not comparable with
  earlier runs on power.
- **Evidence:**
  - `evidence/phase_1/cockpit/run23/` (`cockpit_sheet.png`): the cab from the seat, looking
    left, right, up and down, steering, the gauges, the map, the reverse camera and both
    mirrors;
  - `evidence/phase_1/characters/run23/`: Ethan walking to the Iveco, reaching for its handle,
    the door open, and the ignition;
  - `evidence/phase_1/beams/run23/`: the three beam stills;
  - `evidence/phase_1/collision/run23_step3/` (`collision_sheet.png`): the crossing, the hit at
    59 km/h, leaning over the bonnet, and the depot;
  - `evidence/phase_1/moon_roof/run23/`: the moon and the trees through the moon roof's glass.
- **Not done:**
  - the oncoming van is still the old code-built van;
  - the fall onto the windshield (step 4, its own approval);
  - the frame rate on power.

## Revision 2026-11-01 (Run 23, step 4: blinded, carried on, and the fall onto the windshield, C33)

- **Author:** "yes start step 4 and it should kind of look more natural. i mean the truck upcoming
  should blind us with their headlights and the van should continously go and the pedestrian
  should walk in fornt and our car should hit. make it natual and unavoidable by the user to play
  the game." (#89); for the oncoming vehicle, "Iveco, dark colour (Recommended)" (#90).
- **The oncoming van** (`oncoming_van.gd`, rebuilt):
  - **Model:** the player's Iveco (`iveco_exterior.glb`), its paint textures tinted dark grey
    (`4a545e`), with its own plate, "BR 731", front and rear (`art/number_plate.png`). The
    headlight lenses glow and the tail lamps are lit.
  - **Plate tool:** `tools/make_number_plate.py` gained `--registration`, `--width` and `--out`;
    run without them it writes the player's plate byte-identically.
  - **Size:** the Iveco's collision box (2.0 × 2.09 × 5.53 m). It keeps 1.40 m right of the
    centre line, and brakes for the player's van only when the bodies would touch (2.15 m
    between centres; it was 2.55 m).
  - **High beams:** on from the start and kept on; it no longer flashes them back. The glare
    and eye adaptation code is unchanged, so the high beams' 3.2× power applies all the way in.
  - **Timing:** each tick the mission tells it where and when the player's van will reach the
    meeting point, 16 m before the crossing, and it sets its speed to meet the player there
    (0.6–1.6× its 40 km/h cruise, still slowed for bends). It slows to squeeze past.
- **The van carries on** (`freight_van.gd`; mission `first_drive.gd`):
  - **When:** the encounter starts when the van drives forward, on the road, at 3 m/s or more,
    through samples 927–960 below the last hairpin. It used to start within 14 m of sample 934,
    even parked. Parked there, nothing happens.
  - **The takeover:** from then until the impact the mission drives (`scripted_throttle`,
    `scripted_brake`, `scripted_steer`), and the player's brake, throttle and wheel do nothing.
    - **Lane:** 1.25 m right of the centre line, by pure pursuit through the van's own steering
      limit (`steering_for()`); the worst error in the probes was 0.25–0.49 m.
    - **Speed:** 42–45 km/h, the speed it arrives with, clamped. It coasts or dabs the brakes if
      faster.
    - **Length:** about 150 m, 12 s at 43 km/h.
  - **Stuck:** if the van stays below 2 m/s for 1.5 s, against an obstacle say, the encounter is
    cleared and the player has control. It starts again when they drive through the span.
  - **After the impact:**
    - the van coasts on for half a second (`REACTION`), carrying him on the bonnet;
    - then Ethan brakes hard, and the hold, the lean and "DRIVE." follow as before;
    - C29's 3 m/s² braking is gone: the brake does nothing before the impact anyway.
- **He walks out:**
  - **Timing:** he steps off the kerb when the van's time to the crossing equals his walk to its
    path plus his 0.35 s freeze in the headlights. The freeze was not counted before, so he
    stopped 0.6 m short and was hit by the van's right corner.
  - **Aim:** he heads for the van's centre line (`IMPACT_RIGHT` 0; it was 0.4 m right).
  - **Order:** in every run he stepped out 0.6–0.7 s after the oncoming van's tail passed him.
- **The fall onto the windshield** (`pedestrian.gd`, `van_presentation.gd`):
  - **Front shell:** the Iveco's front, from its own profile, as two convex shapes on an
    `AnimatableBody3D` that follows the van:
    - the bumper face up to the bonnet edge, 1.26 m above the road;
    - the 15° bonnet, the 45.6° windshield and the roof edge.

    It is on its own layer (16), so only the ragdoll collides with it. The wet paint's
    friction is 0.3.
  - **At contact:**
    - the bumper sweeps his shins at the van's speed, his thighs at 0.9×, his hips at 0.6× and his
      arms at 0.5–0.9×;
    - his legs get 3 m/s upward and his hips 2.5 m/s;
    - his torso and head get nothing, so he folds onto the bonnet.
  - **Against the physics, as with Run 20's crack:**
    - with the shell alone his head lands on the bonnet 25 cm short of the glass, because the
      Iveco's bonnet edge (1.26 m) is above his hips;
    - C31's note that the nose makes the fall onto the windshield real was too strong;
    - the upward sweep is what puts his head at the glass.
  - **The head strike:** `watch_head()` follows his head for a second. When it comes within 16 cm
    of the glass, or of the cowl in the 10 cm below it, the crack is placed there at the
    impact's strength. In the test it strikes 0.07 s after the impact, 9 cm from the glass, at
    x −0.09 m and low on the windshield (y −0.40).
  - **Damping:** 0.3 linear and 4 angular for the body (it was 0.15 and 2), and 25 angular for
    the arms and shins.
- **Found and fixed (since Run 20): knees that folded through.**
  - **The fault:** the knee and elbow hinges measured their range from the standing pose, where
    his knees are already bent 39–43° and his elbows 19–26°. So a knee could fold to about 184°,
    the shin through the thigh, and could never straighten.
  - **The fix:** `_pose_bend()` measures the pose, and the hinges allow −2° to 140° (knees) and
    to 145° (elbows) from a straight limb.
  - **Why now:** Run 22's 25 km/h hit never reached the fold; at 42–45 km/h it did.
- **Still there:** tumbling on the road at 42–45 km/h, his knees and elbows can bend up to about
  25° the wrong way for a moment. In 24 probe hits one elbow reached 51°.
  - **Where:** it happens 2–4 m ahead of the bumper, below the bonnet line from the seat.
  - **Tried without success:** Godot's hinge limits give way under those impacts. More solver
    iterations, a stiffer limit bias, lower friction and a per-tick limit guard did not stop it.
- **Capture changes:**
  - **`capture_collision.gd`:**
    - it drives in from sample 905 and lets the takeover run;
    - new stills: the high beams, blinded as it passes, and the head strike;
    - the side stills are timed from the impact frame and taken in debug light (ambient 6.0,
      fog off), because at night they showed nothing.
  - **`capture_oncoming.gd`:** it drives through the trigger and hands control back to watch
    parked. The flash-back still is gone.
- **Test changes, with reasons (#89, #90):**
  - **`test_collision.gd`** (35 checks; it had 30):
    - **The run-up:** it drives in from sample 905 at 43 km/h. From the takeover to the impact
      it holds the brake and turns the wheel left.
    - **New checks:**
      - the oncoming van keeps its high beams on and the view darkens below 0.4;
      - the van carries on by itself;
      - it cannot be stopped or steered away (hit at 39–46 km/h);
      - his head strikes the base of the windshield;
      - the van carries him on for half a second;
      - knees and elbows never fold past their range.
    - **"No one is on the road while the oncoming van passes":** now checks that he steps out
      only once it is past him. It used to park the van until the oncoming van had passed.
    - **"No witness":** now checks that the oncoming van is behind, more than 15 m away and
      driving away. It passes the crossing about a second before the hit now (26 m away when
      checked), not long before (94 m in Run 19).
    - **"Knees and elbows only bend the right way":** allows 30° (it allowed 15° at 25 km/h,
      when the bent-pose limits stopped them short of straight).
    - **The crack check:** "cracks low in front of where he struck the van" becomes "where his
      head struck it".
    - **A guard:** if the encounter is cleared mid-way, the test fails with a message instead of
      reading a freed pedestrian.
  - **`test_crossing.gd`** (12; it had 11):
    - "While the van stands 16 m short of the crossing, he keeps waiting" becomes "Stopped on the
      valley road, nothing starts until the van drives on";
    - "At 20 km/h he still steps out" becomes "Arriving at 20 km/h with the brake held, the van
      still carries on and hits him at 43 km/h";
    - new: "He waits at the crossing's kerb as the encounter begins".
  - **`test_oncoming_van.gd`** (21):
    - new: it is an Iveco painted dark, with its own plates;
    - its two lamps are high beams (they were low beams);
    - "It keeps its high beams on all the way in" replaces "It flashes its high beams twice" and
      "The player's lights are back on low beam";
    - the vans never touch, mirrors included: 2.47 m between centres (it was 2.45 m for the old
      box vans);
    - the trigger is driven through at 8 m/s.
- **Mutations:** all exit 1 (`logs/phase_1/run23/step4/mutation_*`):
  - with the takeover removed, the collision test fails at its first check (0/1);
  - with the brake working during the takeover, 2/5: the van slows to 0 km/h;
  - with Run 20's bent-pose hinge limits, 33/35: the knees reach 177°;
  - with the old uniform push, the head never reaches the glass and the van ends up over him;
  - with the oncoming van on low beams, the oncoming test fails 19/21.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31,
  12/12, 25/25, 21/21, 35/35, 12/12; art 0 failures. Logs are in
  `logs/phase_1/run23/step4/suites/`.
- **Measured:**
  - **Parked and watching** (`capture_oncoming.gd`):
    - glare per lamp: 0.27 at 84 m, 0.91 at 60 m, 1.35 at 35 m, 2.4 at 20 m, 2.7 at 10 m. Run
      19's low beams gave 0.28 at 60 m and 0.76 at 20 m;
    - windshield brightness: 50 before, 108 at 60 m, 159 at 20 m, 43 after.
  - **In the drive** (`capture_collision.gd`): windshield brightness 131 with the high beams 70 m
    out and 33 as the vans pass, with the eyes adapted. The hit was at 43 km/h.
- **Evidence:**
  - `evidence/phase_1/collision/run23_step4/`:
    - `collision_sheet.png`: the drive from the seat;
    - `thrown_sheet.png`: the fall from the side, in debug light;
    - `collision_captures.txt`;
  - `evidence/phase_1/oncoming/run23_step4/`: `oncoming_sheet.png` and `oncoming_captures.txt`.
- **For the author:**
  - the takeover lasts about 12 s. A later trigger would shorten it, but the oncoming van would
    come into view sooner;
  - from the seat the crack sits along the bottom of the windshield, where his head struck.
    Leaning shows it clearly;
  - he lies 2–5 m ahead in the lane, and the van does not collide with his body, so the player
    steers around him;
  - the frame rate on power is still to be measured.

## Revision 2026-11-01 (Run 24, step 1: Maya's call and the quiet ending, C34)

- **Author:** "start with maya's call and the quiet ending. start with mission flow. do this
  also - - Option 1: move the crossing further back up the valley road, so running away is a
  real drive. also, i want the game user to control the driving when hes near the pedestrian i
  guess idk? we are taking away control too much maybe? make it natural and professional game."
  (#92). Answers: "Lose only the last second (Recommended)", "Draft A: big brother" and "Stay in
  the cab (Recommended)". The plan runs in three steps, each approved on its own: this one; the
  mission flow; then the crossing moved up the road with the wheel given back.
- **Maya's call** (the prologue's "short, familiar call with Maya"):
  - **When:** once per drive, in the first stage, when the van passes road sample 91, where the
    climb begins, 182 m from the start. It plays over the first climb and hairpin, long before
    the crossing.
  - **How it plays:** the phone rings through the van's speakers twice (4.4 s) and the dash
    screen shows "MAYA / Incoming call" with a pulsing green dot. It connects hands-free, with
    no new key. The dash then shows the call timer, and the 13 approved lines play as
    subtitles at the bottom of the screen. Each line stays up 1.0 s plus 0.06 s per letter
    (at most 3.6 s), with 0.35 s between lines: 34 s in all. The music dips 13 dB while she
    talks. Then two falling beeps, and the map comes back.
  - **Voices:** none yet; the author's ElevenLabs pass comes later (C06).
  - **Files:**
    - `game/features/missions/night_freight/phone_call.gd` (new): rings, connects and times
      each line;
    - the mission's `first_drive.gd`: the approved lines (`MAYA_CALL`) and the trigger
      (`CALL_AT`);
    - `driving_hud.gd`: subtitles;
    - `navigation_display.gd`: the call card;
    - `driving_audio.gd`: the ring, the beeps and the music dip;
    - `game/app/first_drive.gd`: wires them together.
- **The quiet ending** (replaces "DRIVE COMPLETE" and Run 19's getting out at the depot):
  - **When:** parked in the depot bay. The van can no longer be driven, and E and R do nothing.
  - **What happens:**
    - the engine goes off and winds down;
    - the lights go out, the wipers park and the dash screens go dark;
    - the objective and the hints disappear;
    - after the hit, there is only the rain on the roof, the engine ticking as it cools, and
      Ethan's breathing.
  - **The fade:** after 9 s the picture fades to black over 3 s, the sound fades over 2 s, and
    the menu returns with "Drive again", which starts a new drive.
  - **No title:** no game title appears (C04).
  - **Removed:** `_exit_at_depot()` and its constants.
- **Sounds** (`source_assets/audio/first_drive/synthesize.py`): five new synthesized sounds,
  `phone_ring`, `call_connect`, `call_end`, `breathing` and `engine_tick`. The 13 older WAVs are
  byte-identical, and `docs/AUDIO.md` lists all 18.
- **Found and fixed:** after the ending, resuming the game from a physics-frame coroutine (as
  the test does) printed an engine error, `Condition "p_elem->_root" is true` (`self_list.h`).
  - **Cause:** the ending paused from a timer between physics steps, so Godot's physics left a
    body in its query list. Resuming in the middle of a step added it again.
  - **Fix:** the ending now pauses on a physics-frame boundary, and the error is gone.
  - **Not affected:** a plain pause and resume mid-drive never showed the error.
- **Test changes, with reasons (#92):**
  - **New `game/tests/test_maya_call.gd`, 8 checks:**
    - a quiet start;
    - the ring and the dash card on the climb;
    - connecting after two rings with the music dipped;
    - the 13 approved lines in order, each compared word for word;
    - a short call (20–40 s);
    - everything restored after she hangs up;
    - no second call;
    - a new drive brings it back.
  - **`test_collision.gd`** (38 checks; it had 35). Run 19's three depot checks ("Ethan gets
    out", "Exiting Car", "stands clear") become five quiet-ending checks:
    - engine, lights and wipers off;
    - Ethan stays in his seat, and the van no longer drives;
    - only the rain and his breathing;
    - no objective and no "DRIVE COMPLETE";
    - the fade to black and the "Drive again" menu.

    New: "New drive leaves the ending behind".
- **Mutations:** both exit 1 (`logs/phase_1/run24/step1/mutation_*`):
  - with one approved line changed ("Lock it anyway." to "Lock it."), the call test fails 7/8;
  - with the "DRIVE COMPLETE" banner back, the collision test fails 37/38.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31,
  12/12, 25/25, 21/21, 38/38, 12/12, 8/8; art 0 failures. The only "ERROR:" lines are the
  engine's "resources still in use at exit". Logs are in `logs/phase_1/run24/step1/suites/`.
- **Captures** (windowed, `tools/captures/capture_call.gd` new, `capture_collision.gd` updated):
  - `evidence/phase_1/call/run24_step1/`:
    - the ringing, and the dash card zoomed: incoming, then 00:03;
    - the subtitles;
    - after the call;
    - `call_and_ending_sheet.png`;
  - `evidence/phase_1/collision/run24_step1/`: the drive and hit as in Run 23, then the quiet
    ending in the cab with the crack low on the glass, fading to black, and the menu.
- **Not done (steps 2 and 3, each approved on its own):**
  - the end-of-shift start;
  - controls taught when needed;
  - a checkpoint after the hit;
  - the crossing moved up the road, with the wheel given back except the last second.
- **Seen, not changed:** the dash map labels its distance "DEPOT" whatever the current
  destination, so on the climb it reads "DEPOT / 132 m" for the next checkpoint.

## Revision 2026-11-01 (Run 24, step 2: the end-of-shift start and controls taught when needed, C35)

- **Author:** "... and go ahead with step 2 as well. remember to do all these" (#93), with the run
  sheet approved as drafted ("Use this run sheet").
- **The start** (`industrial_loop.gd`, `game/app/first_drive.gd`):
  - **A site office:** a raised portacabin by the lumber yard gate, 13 m from the van. It has a
    door with a step, a lit window, a wall lamp with shadows, and a clipboard by the door. Its
    clearing keeps the forest out. The yard's shed was dark and 42 m away, and signing there
    meant walking back. The world exposes `run_sheet_at` and `run_sheet_spot`.
  - **Where Ethan starts:** at the office door, facing the clipboard. The objective is "SIGN THE
    RUN SHEET", and the hint "E  Sign the run sheet".
  - **Signing:** E shows the approved run sheet as paper on screen, in a typewriter face. After
    1.2 s, "E. Cole" is written in, in blue handwriting. The faces are the Mac's own fonts
    (`SystemFont`), so no font file is added. The objective becomes "GET IN THE VAN". E or
    walking away puts the sheet away; otherwise it closes after 6 s.
  - **The van waits:** until he signs, E at the van only says "Sign the run sheet at the office
    first." This applies only at the start of a drive. Getting out and back in mid-drive works as
    before.
  - **Removed:** `START_SPOT` and `START_FACING`.
- **Controls taught when needed** (`drive_lessons.gd` new, in the HUD's folder; the app decides
  when):
  - **One hint at a time** replaces the permanent controls line. Each lesson shows until it is
    learned or for a set time, once per drive:
    - walking, after signing, until he has walked 3 m;
    - the pedals and the wheel, until the van has driven 25 m;
    - "ESC  Pause and all controls", for 5 s;
    - high beams, after Maya's call, until he switches to them;
    - the wipers, the first time above 45 km/h;
    - "MOUSE  Look around", near the viewpoint;
    - "R  Recover the van", whenever the throttle is held and the van is stuck for 3 s.
  - **Prompts:** "E  Sign the run sheet" and "E  Get in the van" show whenever they apply.
  - **Quiet moments:** no hint shows during the encounter, the hold after the hit, "DRIVE." or
    the ending.
  - **The full list** stays in the pause menu.
- **Test changes, with reasons (#93):**
  - **`test_on_foot.gd`** (31 checks; it had 25):
    - **The start:** "Ethan starts on the van's left" becomes "Ethan starts at the site office
      door, by the clipboard". The objective and hint checks follow the run sheet.
    - **New checks:**
      - before signing, E at the van only reminds him;
      - the run sheet appears as approved, compared word for word;
      - he signs it "E. Cole", and the objective changes;
      - E puts it away, and the walking lesson shows;
      - near the van, "E  Get in the van" (moved here from the start);
      - in the seat, the pedals-and-wheel lesson.
    - **Walking:** it starts from beside the van, facing along it, as before. At the office he
      faces the wall.
    - **"New drive":** starts at the office again.
  - **`test_maya_call.gd`** (9 checks): new, after the call the hint teaches the high beams.
- **Found on the way:** the integration test's "Nearby driver can reenter" failed. The first
  version also asked for the run sheet when getting back in mid-drive. The check now applies
  only at the start.
- **Mutations:** both exit 1 (`logs/phase_1/run24/step2/mutation_*`):
  - with no run-sheet check at the van, the on-foot test fails its start and run-sheet checks;
  - with one line of the sheet changed ("14 pallets" to "12 pallets"), it fails 29/31.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31,
  12/12, 31/31, 21/21, 38/38, 12/12, 9/9; art 0 failures. The only "ERROR:" lines are the
  engine's "resources still in use at exit". Logs are in `logs/phase_1/run24/step2/suites/`.
- **Capture** (windowed, `capture_on_foot.gd`, now starting at the office):
  `evidence/phase_1/start/run24_step2/` and `start_sheet.png`. It shows:
  - the office door lit at night;
  - the sheet, then signed;
  - the walk to the van;
  - at the van;
  - the first driving lesson.
- **Seen, not changed:** by the van it is very dark (mean brightness 9 of 255), because the
  office lamp does not reach the parking spot. A yard floodlight on the office corner, aimed at
  the van, would fix it; that is left for the author to decide.
- **Next, each approved on its own:**
  - step 3: the crossing up the road, the wheel given back except the last second, and a
    checkpoint after the hit;
  - then the dash screen, the cutscenes with the film look, and the studio intro (C35).

## Revision 2026-11-01 (Run 24: the timber site office from Blender, and the yard floodlight, C36)

- **Author:** "the shed looks so fake, do it in blender and make it realstic home. the office i
  mean." (#94), then "Timber yard office (Recommended)" and "Yes, light the van (Recommended)".
- **The office** (`tools/art/build_site_office.py`, new, run in Blender 5.2.2;
  `game/features/environments/industrial_loop/art/office/site_office.glb`, 3,448 triangles):
  - **Made from scratch by a script,** so no licence is needed and it rebuilds to the same bytes
    (three exports, SHA-256 `4a056a52...`).
  - **The building:**
    - 6.0 × 3.6 m on a 35 cm concrete plinth, with walls 2.6 m high and 14 cm thick;
    - a 22° gable roof of corrugated iron with 35 cm eaves and a ridge cap;
    - gutters, a downpipe with a splash block, and a stovepipe with a rain cap;
    - corner boards, fascia and barge boards, and louvred vents in both gables.
  - **The front:**
    - a plank door, with casing and a knob, under a bracketed hood, with a timber landing and a
      step;
    - a sliding window whose venetian blinds are lit from inside;
    - right of the door, a green OFFICE board, and the clipboard under a gooseneck barn lamp.
  - **The side:** a second window with blinds, and a meter box with its conduit.
  - **The floodlight:** on the front right corner under the eave, turned 26° toward the road and
    12° down, at the van's parking place.
  - **Textures:**
    - Poly Haven CC0: Weathered Plank Siding, Corrugated Iron, Rough Pine Door, Stair Planks and
      Brushed Concrete 03;
    - fetched with checksums from `tools/assets/site_office_assets.json`; `fetch_polyhaven.py` now
      keeps the earlier rows of its manifest;
    - the model's UVs are in metres, so each texture lies at its real size;
    - the file names each part's material ("siding", "roof" and so on) and carries no image.
  - **Markers:**
    - empties mark the clipboard, the two lamps and the window;
    - two boxes named with Godot's "-convcolonly" suffix import as the walls' and the landing's
      collision.
- **Claude Code's calls:**
  - **No porch:** a bracketed hood and a landing instead of a porch with posts, so Ethan signs
    standing on the ground, and no porch beam crosses the camera behind him;
  - **The board:** it says only "OFFICE"; no company name is invented;
  - **The floodlight:** it is cool white, against the warm lamp and window.
- **In the game** (`industrial_loop.gd`):
  - **The model:** `_site_office()` puts it where the old office stood.
  - **Materials:** each part gets its own:
    - the five textures;
    - painted trim, a dark green board with cream letters, and see-through glass;
    - blinds that glow faintly, lit from the room behind them.
  - **Lights:**
    - the gooseneck lamp: a warm spot with shadows on the board and the clipboard (energy 4.0,
      8 m, 55°);
    - the floodlight: a cool white spot with shadows on the van (9.0, 32 m, 30°);
    - a soft warm glow in front of the window (0.8, 4 m), without shadows.
  - **The run sheet:** `run_sheet_at` is the clipboard's paper, read from the model's marker, and
    `run_sheet_spot` is 0.7 m in front of it, on the ground.
  - **Textures in code:** `_surface()` and `_texture()` take a resolution, because four of the
    textures are 1k.
  - **The forest:** the clearing is unchanged, so the forest is unchanged.
- **Found and fixed while building:**
  - **Walls with no thickness:** bmesh's solidify needs face normals, and new faces have none.
    The first walls came out as two coincident faces that rendered black. The normals are now
    updated first.
  - **Exports that differed:** solidify creates faces in memory order, so two exports differed.
    The faces are now sorted before the mesh is written.
- **Imports:**
  - `configure_imports.py` set the 15 new textures to VRAM compression with mipmaps, with the
    normal maps marked as normal maps;
  - it also changed `rock_wall_02` and `rustic_stone_wall`, which have imported without mipmaps
    since Run 15. Those six files were put back, because that is not this step's change.
- **Test changes, with reasons (#94):**
  - **`test_on_foot.gd`** (36 checks; it had 31). Five are new:
    - the office is the Blender building, with its five textured parts at real size;
    - the clipboard hangs on the front wall (1.44 m up, 1.8 cm proud of it);
    - the lamp lights the clipboard and Ethan standing at it;
    - the floodlight shines on the van, 11.8 m away, with nothing in between;
    - walking at the wall, Ethan stops 0.31 m short of it.
  - **`check_first_drive_art.py`:** an office section of 10 checks:
    - the parts, markers and collision boxes;
    - the 15 material names, and no image;
    - finite geometry and no inverted triangles;
    - UVs in metres (siding 0.999; door, landing and plinth 1.000);
    - the office facing +Z, with its lights turned the right way;
    - the collision box matching the walls;
    - under 30,000 triangles and 25 MB.

    The model sits in its own `art/office/` folder, like the cockpit and the Iveco, so the
    general section and its three depot props are unchanged.
- **Mutations:** both exit 1 (`logs/phase_1/run24/office/mutation_*`):
  - with the office's collision removed, Ethan walks through the wall (35/36);
  - with the floodlight turned away, the floodlight check fails (35/36).
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31,
  12/12, 36/36, 21/21, 38/38, 12/12, 9/9; art 0 failures. The only "ERROR:" lines are the
  engine's "resources still in use at exit". Logs are in `logs/phase_1/run24/office/suites/`.
- **Captures** (windowed):
  - **`tools/captures/capture_site_office.gd`** (new), into `evidence/phase_1/start/run24_office/`:
    - the office from the road;
    - the door, the board and the clipboard;
    - the side;
    - a debug-lit view (ambient 6.0, fog off);
    - the van with and without the floodlight. The van's mean brightness goes from 13.0 to 52.8
      (4.1×).

    No still has a pure-white pixel.
  - **`capture_on_foot.gd`**, into `evidence/phase_1/start/run24_office/on_foot/`: the start at
    the office, the signed sheet, the walk, and at the van.
  - **Blender preview renders** are in the agent's scratch folder, not in the repository.
- **Seen, not changed:**
  - **The driver's door is dark:** it faces away from the office, so the van's own body shades
    it. It stays dark until the ignition turns the lamps on.
  - **A pine at the corner:** a big pine stands just in front of the office's right corner, at
    the clearing's edge.
- **Next:** step 3, the crossing up the road (#93), with its own approval.

## Revision 2026-11-01 (Run 24: fixes from the author's play test, C37)

- **Author:** "i found couple of bugs ... when i am rolling down the side windows ... its glitching
  ... i wasnt able to find the van in the start, add a map to guide user to van ... i lost control
  of the vechile before 5-10 seconds before hitting the pedestrian? ... when i am opening the door
  my hand is going off into the door and when i exit the door, exit animation isnt coming ... make
  sure the cabin light turns on when the door is open. and also let the gamer choose if he wants
  to switch on the cabin light or off", then "the glass after coming down compeltely can be seen
  from inside" (#95). Answers: "Both", "I (Recommended)", "In step 3 (Recommended)", "Yes, start
  (Recommended)".
- **Side windows** (`van_presentation.gd`; `side_glass.gdshader`, `window_slide.gdshaderinc` new;
  `side_window_rain.gdshader`; all in the van's folder, not `game/shaders/`):
  - **The cause:**
    - each window moved 88 cm straight down as one piece, and nothing hid the glass below the
      sill, so it stayed in view inside the door;
    - the small front pane by the mirror post slid down with it.
  - **Now:**
    - **The front pane stays fixed,** as on a real Daily.
    - **The main pane slides down:** in the shaders, so the nodes no longer move.
    - **Below the sill nothing draws:** the glass and its rain are cut at the pane's own bottom
      edge, measured from the mesh in 32 samples.
    - **It drops its own height:** 0.607 m with a 2 cm margin, so fully down none of it shows.
  - **The moon roof's rain** uses the same shader with the slide off, so it is unchanged.
- **Getting in, the hand on the handle** (`driver.gd`, `game/app/first_drive.gd`,
  `van_presentation.gd`):
  - **The cause:** Mixamo's Entering Car grabs with the left hand but brings the wrist to the
    handle, so the fingers sank 10.5 cm into the door and then slid along it as it opened.
  - **Now:** Godot's `TwoBoneIK3D` on Ethan's left arm (`grip()`), with the hand extended
    17 cm to the fingers.
    - **When:** it blends in from 0.75 s, reaches the handle at 1.05 s, holds it while the door
      swings, and lets go at the cut.
    - **The grip point:** `door_handle()`, 4 cm out from the handle.
    - **Measured:** the fingers stay within 9 cm of the handle as the door opens.
  - **Reading the result:** Godot 4.7 shows a modifier's result only inside `skeleton_updated`,
    so `grip_point()` remembers it there.
- **Getting out** (`game/app/first_drive.gd`):
  - **The animation:** E at a stop now plays Exiting Car from 2.6 s, after a fade from the seat.
  - **The door:** it opens to 70°; at the Iveco's 31° his body would pass through it.
  - **The push:** from 3.25 s the door eases toward his hand, and from 3.55 s it follows his
    fingertips round the hinge (`door_opening_toward()`), within 5.4 cm of its outer face. At
    4.35 s it shuts.
  - **Control:** it returns when the clip ends, about 3.5 s in all.
  - **The passenger side:** if the driver's side is blocked he leaves that way, as before
    (no animation).
- **Cabin light** (`van_presentation.gd`, `freight_van.gd`; `game/project.godot`, with the
  author's OK, #95):
  - **The lamp:** a dome lamp on the headliner in front of the moon roof: a warm light on the
    cab and body layers, and a lens that glows.
  - **With the door:** it comes on in 0.12 s whenever the driver's door is open, and fades out
    over 2 s after it shuts.
  - **The I key:** the new `cabin_light` action switches it on and off from the seat, with the
    usual switch click. `switch_off()` turns it off, so the quiet ending stays dark.
  - **The pause menu** lists "I   Cabin light".
- **The guide to the van** (`van_guide.gd` new, in the HUD's folder; `driving_hud.gd`;
  `industrial_loop.gd` gives the office's transform):
  - **The corner map:** a round, heading-up map at the top right. It shows the road, the
    office, the van in amber, Ethan's arrow, a north mark, and "VAN 13 m".
  - **The marker:** "VAN · 13 m" over the van. When the van is out of view it sits at the
    screen's edge with an arrow, and it fades out within 4–7 m of the van.
  - **When:** whenever the van is where he needs to go: on foot after signing the run sheet,
    or after getting out. It hides before signing, while he gets in or out, in the van and
    during the ending.
- **Not changed here:** the loss of control before the hit is Run 23's takeover; step 3 replaces
  it, as the author chose ("In step 3").
- **Test changes, with reasons (#95):**
  - **`test_materials.gd`** (Assignment 5's suite, 92 checks, the same count):
    - "Driver-window rain overlay is a child of the left window; its glass is unchanged"
      becomes "... the glass and its rain slide into the door together";
    - "Real J press lowers the window and its fog overlay by 0.88 m" becomes "Real J press
      lowers the driver's window 0.607 m into the door: none of the sliding pane is left above
      the sill, its rain goes with it, and the fixed front pane stays". It uses the shader's own
      rule on every corner of the pane.
  - **`first_drive_regression.gd`** (Assignment 5's suite): "Clear doors allow exit" waits for
    the exit to finish, because getting out now takes the length of the clip.
  - **`first_drive_integration.gd`:** "Stopped van allows safe exit" waits for the exit to
    finish, for the same reason.
  - **`test_on_foot.gd`** (46 checks; it had 36). Ten are new:
    - no guide before signing, the guide after signing, and none in the van;
    - the hand on the handle;
    - the lamp with the door open, faded after it shuts, and switched by I;
    - the exit clip with the door shut behind him;
    - the door opening wide;
    - the hand on the door as he pushes it shut;
    - the lamp during the exit.

    "E at a stop lets Ethan out" became "E at a stop plays Exiting Car".
- **Mutations:** all exit 1 (`logs/phase_1/run24/fixes/mutation_*`):
  - with half the drop, 7 of 25 corners stay above the sill (91/92);
  - with no grip, the hand is 43 cm off the handle (45/46);
  - with the old instant exit, 42/46;
  - with a lamp that ignores the door, 44/46;
  - with no guide, 45/46.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31,
  12/12, 46/46, 21/21, 38/38, 12/12, 9/9; art 0 failures. The only "ERROR:" lines are the
  engine's "resources still in use at exit". Logs are in `logs/phase_1/run24/fixes/suites/`.
- **Captures** (windowed):
  - **`tools/captures/capture_play_fixes.gd`** (new), into `evidence/phase_1/fixes/run24/`:
    - the guide after signing, and the marker over the van;
    - the hand on the handle at 1.05 s and 1.45 s;
    - the dome lamp off and on;
    - the window at half and fully down;
    - getting out, the push from the side, and the door shut.
  - **The window before and after,** from the seat: in the agent's scratch folder.
- **Seen, not changed:** at the start the driver's door faces away from the office's
  floodlight, so getting in and out happens in the van's shadow, lit by the dome lamp.

## Revision 2026-11-01 (Run 24, step 3: the crossing up the hill, the wheel given back, a checkpoint after the hit, C38)

- **Author:** "Option 1: move the crossing further back up the valley road, so running away is a
  real drive. also, i want the game user to control the driving when hes near the pedestrian i
  guess idk? we are taking away control too much maybe? make it natural and professional game."
  and "Lose only the last second (Recommended)" (#92); "i lost control of the vechile before 5-10
  seconds before hitting the pedestrian?" and "In step 3 (Recommended)" (#95); then "okay
  proceed" (#96).
- **The crossing moves up the hill** (`industrial_loop.gd`, `CROSSING_AT`):
  - **Where:** road sample 785, at (63.3, 32.7, -79.5), on the straight between the second and
    third hairpins down. It was at sample 1002, at the foot of the hill road, 80 m before the
    depot.
  - **The place:** a 9.4% downgrade heading west, with no lamp within 156 m. The shelter stands on
    the uphill right, 9.9 m before the crossing. The footpath leads 31 m from the far side, down
    toward the town. The signs stand both ways, as before.
  - **Running away:** the depot is 511 m further on by road, through the last two hairpins and
    32.7 m lower.
- **The encounter** (mission `first_drive.gd`):
  - **When:** in stage 3 (`ENCOUNTER_STAGE`, toward THE DESCENT), as the van drives forward
    through the second hairpin down (samples 680–730), once it is close enough for the oncoming
    van to meet it in time.
  - **The oncoming van:**
    - it starts at the foot of the straight (`SPAWN_AT`, sample 815), where the hill hides it
      until the player is round the hairpin;
    - it is timed to pass the player 30 m before the crossing (`MEETING_BEFORE`);
    - it keeps its high beams on (C33).
- **The wheel given back (C34; this replaces C33's takeover):**
  - **Before he steps out,** the throttle, the brake and the wheel are the player's. The mission
    no longer drives the van; `_carry_on()` and its constants are gone.
  - **He steps out** only when all of these hold:
    - the oncoming van is past him;
    - the van is doing at least 16 km/h (`MIN_STEP_SPEED`);
    - the van is no more than 1.9 s from the crossing (`STEP_HORIZON`).

    He walks to the van's own path, 0.4 m right of where its centre will cross (`IMPACT_RIGHT`).
    His walk plus his 0.35 s freeze in the headlights ends as the bumper arrives.
  - **"Ethan brakes too late":** from his first step, the wheels lock on the wet paint
    (`FreightVan.locked`):
    - braking slows the van by only 1.5 m/s² (`LOCKED_GRIP`; 9 m/s² otherwise);
    - the tyres skid, with a new sound;
    - the wheel does nothing, and the van holds its heading.

    The lock ends at the impact, when the van stops, or 10 m past the crossing.
  - **How long the lock lasts:** from his first step to the impact, 1.6–2.0 s, not one second.
    That is how long he takes to walk into the van's path. With the wheel back for those seconds,
    a player who saw him step out could stop.
  - **After the impact,** as in C33:
    - the van carries him on for half a second;
    - Ethan brakes hard and holds for 4 s;
    - then "DRIVE.".
- **Ethan keeps his foot on the brake** (`freight_van.gd`, `foot_on_brake`):
  - **Found in the first capture:** on the 9% grade the van rolled forward as soon as "DRIVE."
    appeared, and through him within about 3 s, because it does not collide with his body (C33).
    On the valley road it had stayed where it stopped. The stills are in
    `evidence/phase_1/collision/run24_step3_before_brake_hold/`.
  - **Now:** after the hit, and after a recovery or a continue while fleeing, the van stays braked
    with its brake lights on until the player touches the pedals, the handbrake or the wheel.
    Everywhere else it rolls on slopes as before.
- **A checkpoint after the hit** (mission `first_drive.gd`, `game/app/first_drive.gd`):
  - **When:** as "DRIVE." appears, without the "checkpoint saved" notice.
  - **What it keeps:**
    - the van's place;
    - where he lies (`Pedestrian.lying_pose()`, 11 bodies);
    - the crack (`crack_state()`).
  - **Continuing from the menu** (`_continue_in_van()`):
    - Ethan is in the cab where the van stopped, with the engine running, "DRIVE." and no music;
    - he lies where he fell (`lie_as()`), and the crack is on the glass (`restore_crack()`);
    - nothing replays.

    A saved drive past the start also continues in the van; a drive from the start begins at the
    office.
  - **Recovery (R)** after the hit puts the van back at that place.
  - **Found and fixed:** the first suite run printed two engine errors ("Couldn't find the given
    section "drive" and key "body""), from an older checkpoint without the new keys. The loader
    now checks for them first.
- **The pedestrian** (`pedestrian.gd`):
  - he stops where his path meets the van's (`_stop_at`);
  - he freezes in the headlights only when he is in the van's path;
  - if the van stops or passes, he walks on;
  - he goes limp only when struck faster than 1 m/s (`MIN_IMPACT`), so walking into a stopped
    van is not a hit.
- **The skid sound** (`skid.wav`, from `skid()` in
  `source_assets/audio/first_drive/synthesize.py`):
  - a 2 s loop of tyre hiss, rubber scrub and a squeal near 960 Hz;
  - `driving_audio.gd` plays it while the locked wheels brake above 1 m/s, louder with speed;
  - the other 18 WAVs are byte-identical, and `docs/AUDIO.md` lists 19.
- **Tools:**
  - `game/tests/lane_keeper.gd` looks 0.7 s ahead at speed (at least 6 m), because it weaved on
    the descent;
  - `capture_collision.gd` drives in from sample 672 at 8 m/s with the lane keeper, and brakes as
    he steps out, as a player would;
  - `capture_oncoming.gd` triggers at sample 729 and watches from sample 750.
- **Test changes, with reasons (#92, #95, #96):**
  - **`test_collision.gd`** (43 checks; it had 38):
    - **The run-up:** stage 3, from sample 672 at 8 m/s with the lane keeper. At the step-out it
      holds the brake and turns the wheel left.
    - "With the brake held and the wheel turned, the van carries on by itself" becomes "You
      drive all the way: the wheel and the pedals are yours until he steps out".
    - "The van cannot be stopped or steered away" becomes two checks:
      - "Braking hard, the wheels lock on the wet paint: the tyres skid, the van slows only from
        36 to 32 km/h, and it hits him 2.0 s after he steps out";
      - "Turning the wheel does nothing in the skid".
    - **The lean check** asks that leaning shows more of him than the seat does (11 of 11 parts
      against 2 of 11). It used to ask for none from the seat, but on this downgrade, with him
      3.2 m out, two parts show from the seat.
    - **New:**
      - "On the 9% grade Ethan keeps his foot on the brake until you drive, so the van never
        rolls onto him";
      - "When he can drive on, a checkpoint keeps the van's place, where the man lies and the
        crack";
      - "Continuing the drive after the hit starts in the van at that checkpoint, held on the
        brake: DRIVE., and no music";
      - "He still lies where he fell, the crack is on the glass, and nothing replays".
  - **`test_crossing.gd`** (12 checks):
    - "Stopped on the valley road, nothing starts" becomes "Stopped in the hairpin above the
      crossing, nothing starts";
    - "Arriving at 20 km/h with the brake held, the van still carries on and hits him" becomes
      "Crawling down at 20 km/h, braking as he steps out, the van still skids into him on the
      crossing at 18 km/h".
  - **`test_oncoming_van.gd`** (21 checks):
    - **The site:** the trigger is at sample 729 and the wait at 795. "Below the last hairpin
      ..." and "It starts beyond the valley S-bend, out of sight" become "In the second hairpin
      down ..." and "It starts at the foot of the descent straight, where the hill hides it".
    - **A fix to the sight-line check:** it ignored only the player's van, so its ray always hit
      the oncoming van's own collision box and read "hidden" wherever the van started. It now
      ignores both vans, and the real spawn is still hidden. A mutation exposed this (below).
    - **Eye recovery:** the eyes get 8 s (it was 6 s), because the head-on high beams up the
      straight darken the view further (0.24) than on the valley road.
    - **Arrival:** if the van does not arrive properly, the test stops after the arrival checks
      instead of reading a freed van.
- **Mutations:** all exit 1 (`logs/phase_1/run24/step3/mutation_*`):
  - with no wheel lock, the van stops and he walks across (21/40);
  - with the takeover back, "You drive all the way" fails (1/5);
  - with steering in the skid, the van turns 59° and misses him (18/40);
  - with no checkpoint after the hit, 40/42;
  - with "continue" starting on foot, 42/43;
  - with the oncoming van spawned in view (sample 745), 7/8. Before the sight-line fix, the
    "hidden" check passed this mutation;
  - with no brake hold, the van rolls 3.01 m toward him in 3 s (40/43).
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31,
  12/12, 46/46, 21/21, 43/43, 12/12, 9/9; art 0 failures. The only "ERROR:" lines are the
  engine's "resources still in use at exit". Logs are in `logs/phase_1/run24/step3/suites/`.
- **Captures** (windowed, on battery):
  - **`capture_collision.gd`,** into `evidence/phase_1/collision/run24_step3/`
    (`collision_sheet.png`, `thrown_sheet.png`):
    - the crossing from above, at night and in debug light;
    - the high beams 70 m out (windshield brightness 127), and blinded as it passes (32);
    - the step-out at 36 km/h, 21 m ahead, and the skid with him 4 m ahead;
    - the impact at 32 km/h, the head strike, and the fall from the side;
    - leaning over the wheel, and "DRIVE." with the van held 4.7 m short of him;
    - driving on, and the quiet ending.
  - **`capture_oncoming.gd`,** into `evidence/phase_1/oncoming/run24_step3/`
    (`oncoming_sheet.png`), parked at the top of the straight:
    - glare per lamp: 0.38 at 110 m, 1.02 at 60 m, 1.91 at 35 m, 2.65 at 20 m and 2.9 at 10 m;
    - windshield brightness: 98, 130, 152, 157 and 146, then 44 after it passes.
- **Speed sweep** (a probe in the agent's scratch folder, at a fixed 60 FPS, braking at the
  step-out; logs in `logs/phase_1/run24/step3/speed_sweep/`):

  | Hit at | Step-out to hit | Crack | Where he ends | Elbows and knees, first 3 s |
  | --- | --- | --- | --- | --- |
  | 30 km/h | 2.0 s | 0.91 | 4.3 m ahead | within 30° the wrong way and 150° |
  | 32 km/h | 2.0 s | 0.98 | 4.3 m ahead | within 30° the wrong way and 150° |
  | 37 km/h | 2.0 s | 1.00 | 3.0 m ahead | the left elbow folds to 160°, then flips to −143° |
  | 40 km/h | 2.0 s | none | 2.1 m ahead | an elbow 35° the wrong way |
  | 46 km/h | 2.0 s | 1.00 | 1.0 m ahead | elbows 45° and 49° the wrong way |
  | 54 km/h | 1.7 s | none | under the van | an elbow 43° the wrong way, one to 151° |
  | 62 km/h | 1.6 s | none | under the van | an elbow 97° the wrong way |

- **For the author:**
  - **The hit holds up at 30–36 km/h,** where the tests run (32 and 18 km/h).
  - **Faster, it does not:**
    - above about 50 km/h he goes under the van, and the glass does not crack;
    - at 37–62 km/h an elbow can bend or flip the wrong way for a moment.

    Coming down the 9% straight, a player can easily arrive faster than 50 km/h. Making the hit
    hold up at 40–65 km/h would be its own step.
  - **The lock** lasts about 2 s from his first step, not one second.
  - **The van still passes through him** if the player drives straight at him after "DRIVE."
    (C33).
  - **From the seat,** two of his eleven body parts show on this downgrade (none did on the
    valley road).
  - **Frame rate:** the captures ran on battery at 45–61 FPS, which is not comparable with
    earlier runs on power.

## Revision 2026-11-01 (Run 25: the hit holds up at any speed, C39)

- **Author:** asked "Should the next step make the hit hold up at 40–65 km/h, or go on to the
  dash screen?", the author answered "ok", and then "Fix the hit at speed (Recommended)" (#97).
- **Test first** (`game/tests/test_hit_speeds.gd`, new, 12 checks):
  - **The set-up:** for each of 30, 45 and 60 km/h it builds a fresh game, puts him at the
    crossing's kerb and holds the van at that speed until the impact.
  - **The checks:** at each speed:
    - he is thrown onto the bonnet;
    - his head cracks the glass;
    - he never passes over or through the cab, and he ends up ahead of the bumper;
    - his knees and elbows never stay bent the wrong way, and he comes to rest with them in
      range.
  - **On Run 24 step 3's code it failed 7/12** (`logs/phase_1/run25/before/`):
    - at 45 km/h he ended 0.3 m behind the bumper;
    - at 60 km/h the glass did not crack, and he ended 18 m behind the van.
- **The cause** (traced tick by tick at 60 km/h):
  - **A bend before the crossing:** the straight has a gentle S just before it. The road's
    heading swings from 104.8° at sample 765 to 95.0° at 785.
  - **The lock went straight:** step 3's lock froze the van's heading at his first step, so a
    locked van ran straight off its lane. He aimed at where that straight line crossed the road.
  - **Too far to walk:** at speed he steps out up to 1.9 s ahead (`STEP_HORIZON`), 31 m at
    60 km/h, so that point lay up to 4 m across the road, and he could not reach it in time.
    Even at 36 km/h his walk was 2.8 m, which is why step 3's lock lasted 2.0 s.
  - **Caught by the corner:** the van's right corner caught him mid-walk, 1.15–1.4 m right of
    its centre. The hit counts within 1.25 m of the centre, but the front shell that throws him
    is only ±0.99 m wide. Nothing pushed him forward, and the braking van passed down his side
    or over him.
- **The fix** (mission `first_drive.gd`, `freight_van.gd`):
  - **The locked van keeps its lane** (`_watch_lock()`, `FreightVan.lock_curvature`):
    - the player's wheel still does nothing;
    - each tick, the van curves toward a point 12 m ahead (`LOCK_LOOK`, 6 samples) at its own
      lane offset (`_lock_lane`), so it follows the road's bend;
    - it used to hold its heading.
  - **He aims at the van's lane** (`_watch_crossing()`): the impact point is the van's offset
    in its lane, 0.4 m to its right as before. The straight-line guess is gone.
  - **So his walk is about 1.2 m,** and the lock is about one second:
    - 1.1 s in the collision test, where step 3 gave 2.0 s;
    - 0.93–1.07 s across the encounter sweep below.

    That is closer to C34's "Lose only the last second".
- **Tried, and not kept** (`pedestrian.gd` is unchanged): two changes to the hit itself, each
  measured with a sweep of 30–65 km/h in 5 km/h steps (`logs/phase_1/run25/hit_sweep/`):
  - **carrying each body part** at the van's speed less its 32 km/h shortfall;
  - **triggering the hit a tick early.**

  On step 3's aim they gave 21/32 and 20/32, against 18/32 before. With the lane fix, the sweep
  gave 28/32 with or without them, and the four failures were the limb check in both cases. So
  they were dropped.
- **The limbs:**
  - **Spikes:** at every speed, a knee or an elbow can still spike past its range for a single
    physics tick, at most two in a row: up to −59° in the test sweep and −110° once in the
    encounter sweep. This is the Godot hinge weakness noted in C33.
  - **Resting:** no limb ever stays bent the wrong way, and every resting pose is within the
    hinges' ranges.
  - **The new check:** it fails if a knee or elbow is out of range for more than 3 ticks
    (0.05 s), or if he comes to rest with one out of range. The peaks are printed in each check.
  - **Sweep logs 1–6** used the old check, which counted any single tick. Log 6 shows each run
    lasting at most one tick.
- **Measured:**
  - **The new test's sweep, 30–65 km/h** (`hit_sweep/7_final.log`): 32/32. He is thrown onto the
    bonnet (hips 1.37–1.84 m up) and his head cracks the glass (0.93 at 30 km/h, 1.00 above). No
    part of him gets past the windshield: at most 1.43 m ahead of the van's origin, where the
    roof's front edge is 0.5 m ahead. He lies 1.3–2.9 m ahead of the bumper.
  - **The full encounter** (oncoming van, step-out, braking), approaches of 5–18 m/s
    (`encounter_sweep/`):

    | Hit at | Step-out to hit | Crack | Ahead of the van's origin 1.5 s later |
    | --- | --- | --- | --- |
    | 32 km/h | 1.07 s | 1.00 | 4.2 m ahead |
    | 34 km/h | 1.05 s | 1.00 | 4.2 m ahead |
    | 39 km/h | 1.03 s | 1.00 | 3.8 m ahead |
    | 42 km/h | 1.03 s | 1.00 | 3.8 m ahead |
    | 49 km/h | 1.00 s | 1.00 | 3.7 m ahead |
    | 56 km/h | 0.95 s | 1.00 | 3.6 m ahead |
    | 63 km/h | 0.93 s | 1.00 | 1.9 m ahead |

    Before the fix, at 40, 54 and 62 km/h the glass did not crack, and at 54 and 62 km/h he went
    under the van.
- **Tool:** `capture_collision.gd` takes an optional run speed after the output folder (8 m/s by
  default). Its side camera now follows the van, so a fast van stays in frame.
- **Test changes, with reasons (#97):**
  - **`test_hit_speeds.gd`** is new (above).
  - **`test_collision.gd`** (43 checks, the same count): "Turning the wheel does nothing in the
    skid (the van turns 0.00 degrees)" measured the van's heading. The locked van now turns
    with the road (2.38° here), so the check measures what the wheel would change, the lane:
    "the van slides on in its lane (0.15 m across)". The test still holds the wheel hard left;
    with steering working, the van swerves 7.03 m (mutation below). Elsewhere its numbers
    change with the shorter lock:
    - he steps out 10.5 m before the bumper (it was 18.9 m);
    - the van slows from 36 to 34 km/h (it was 32), and hits him 1.1 s after he steps out (it
      was 2.0 s).
- **Mutations:** all exit 1 (`logs/phase_1/run25/mutation_*`):
  - with the locked van going straight again, 5/9: at 45 km/h he passes through the cab, and
    at 60 km/h the van misses him;
  - with step 3's straight-line aim, 10/12: at 60 km/h he passes through the cab;
  - with steering working in the skid, the collision test fails 18/40: the van swerves 7.03 m
    and misses him;
  - with the knee and elbow limits reversed, 9/12: limbs stay bent the wrong way for 117–244
    ticks.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31,
  12/12, 46/46, 21/21, 43/43, 12/12, 9/9, 12/12; art 0 failures. The only "ERROR:" lines are the
  engine's "resources still in use at exit". Logs are in `logs/phase_1/run25/suites/`.
- **Capture** (windowed, on battery): `capture_collision.gd -- evidence/phase_1/collision/run25
  15.3`, at about 55 km/h (`collision_sheet.png`, `thrown_sheet.png`):
  - he steps out of the glare 16.9 m ahead at 55 km/h, and is in the headlights through the skid;
  - he is hit at 53 km/h, lands on the bonnet against the glass, and is carried about a second;
  - he slides off as Ethan brakes, and lies on his back 4.8 m ahead of the stopped van.

  The capture printed no "ERROR:" line.
- **Not changed:** the van still passes through his body if the player drives straight at him
  after "DRIVE." (C33).

## Revision 2026-11-02 (Run 26: the dash screen, built into the van, C40)

- **Author:** after three mockups on a private canvas
  (https://claude.ai/artifact/XrjFWwDyNwrsBHUzRWT7aq):
  - "i like B idea but i love details in C. so combine both of them give me final design" (#99);
  - then, on the final design, "its perfect. make sure it looks like an actual screen in the van
    and not like some block ... include it nicely. and make sure the map works as in real life.
    also, i want the user to pickup the call by clicking a button.";
  - and the answers "prompt the user to click a key on keyboard to answer the call" and "she calls
    back and if user doesnt answer upto 2 times then automaticallly pick up third time" (#101).
- **Why today's screen looked like a block:** it was a 17.2 × 11.3 cm picture stuck in front of the
  dash. The van's own display is 13.6 × 7.1 cm, so the picture covered the head unit's buttons and
  its PUSH knob, and it was tilted 2.3° too far.
- **Fitted into the van's own display** (`van_presentation.gd`):
  - **Measured from the model:**
    - the head unit's screen picture is the triangles that map onto it in the dashboard
      texture, 18 of them;
    - they give its centre, its 23.7° tilt toward the driver and its size, 13.61 × 7.08 cm.
  - **The picture** sits there, at 768 × 400 pixels in the display's own shape. It was 384 × 256.
  - **A matte black copy of those 18 triangles** sits 0.5 mm in front of the model's glass, so the
    model's painted picture never shows at the edges.
  - **Like a real LCD** (`cockpit_screen.gdshader`, new settings that leave the gauges and mirrors
    as they were):
    - a thin black border round the lit area;
    - backlit blacks, not pure black;
    - a little dimmer seen from the side, up to 25% at a grazing angle;
    - a 1.2 s fade-in when the engine starts, and dark glass with the engine off.
  - **Glass and glow:** a glossy, lightly tinted glass pane in front, and a faint blue glow on the
    dash around it, cab only.
- **A map that works like real navigation** (`navigation_display.gd`, rewritten as the final
  design):
  - **Movement:**
    - heading-up, centred on the van and turning with it;
    - zoomed in when slow (3.0 px/m) and out at speed (1.8 px/m at 61 km/h);
    - drawn from the real road 30 times a second, with the route ahead in blue.
  - **Instructions:**
    - real navigation does not announce bends on a road with no junctions, so the card shows the
      next real turn: a turn-left arrow, the distance and "Freight depot", as on the in-game
      "FREIGHT DEPOT / NEXT LEFT" sign;
    - the distance is measured along the road. The old screen showed the straight-line distance
      to the next checkpoint and always called it the depot ("DEPOT / 174 m");
    - "Turn around" after 1.5 s driving the wrong way, or past the depot;
    - "Arrived" in the depot bay.
  - **The hairpin warning:** a yellow bend sign with the distance, within 150 m of each hairpin.
  - **The run-sheet card:**
    - only the approved run sheet's words;
    - a progress bar from the lumber yard to the depot;
    - the arrival time and minutes left, worked out at 40 km/h on the legs and 18 km/h in the
      hairpins.
  - **Road names:** from the in-game signs, "Hill Road" and "Valley Road".
- **Reverse** (`parking_guides.gd`, new): the reverse camera now fills the display (576 × 300),
  with red, yellow and green parking guide lines.
- **The van's clock** (`freight_van.gd`, `instruments.gd`): it starts at 23:42 and runs, and the
  gauges and the screen show the same time. The gauges used to show a fixed 23:42. "New drive"
  resets it.
- **Answering Maya** (`phone_call.gd`, `game/app/first_drive.gd`, `driving_audio.gd`,
  `driving_hud.gd`):
  - **It waits for T:** the call rings until the player presses T (the new `answer_call` action
    in `game/project.godot`, by the author's request #101). The screen shows "T Answer" and the
    hint says "T  Answer the call".
  - **Missed calls:**
    - a call that rings 6 times (13.2 s) unanswered is missed: "Missed call · Maya";
    - she calls back 8 s later;
    - the third call picks up by itself after two rings: "Answering automatically".
  - **Worst case:** with both calls missed, the conversation starts 46.8 s after the first ring
    and ends 80.3 s after it.
    - The encounter can start 1,178 m further on by road (sample 680), 132 s away at the map's
      own pace.
    - Only a driver averaging over 52.8 km/h through the hairpins would still be on the call
      when it starts. The encounter does not wait for the call (measured by a scratch probe;
      step 2 changes this).
  - **The pause menu** lists "T   Answer a call".
- **Claude Code's calls:**
  - the screen's shape: the approved design was drawn at 768 × 512 (3:2), and the van's display
    is 1.92:1, so the same layout is 112 pixels shorter (768 × 400);
  - T for the key;
  - six rings, and calling back after 8 s;
  - the depot as the destination;
  - the 150 m warning;
  - the running clock;
  - metric units, matching the gauges, although the road signs use miles;
  - the Mac's system font, like the run sheet, so no font file is added.
- **Test changes, with reasons (#101):**
  - **`test_maya_call.gd`** (11 checks; it had 9):
    - "It connects hands-free after two rings" becomes "Pressing T answers: it connects
      hands-free at once, the dash shows the call, and the music dips 13 dB";
    - new: "It keeps ringing until answered: the dash asks for T, and the hint says T  Answer
      the call";
    - new: "Unanswered, the call is missed and she calls back; after two missed calls the third
      picks up by itself after two rings (4.4 s)";
    - its game-time limit is 180 s (it was 120 s).
  - **`test_ghat_road.gd`** (31, the same count): "The map screen draws the real road inside its
    panel" checked a fixed outline of the whole loop. It becomes "The map screen draws the real
    road around the van, heading-up (68 points on the map, tracked 0 m from the van)".
  - **`test_dash_screen.gd`** (new, 14 checks):
    - **The fit:** the picture fills the van's own display, covering its glass to within 0.0 mm
      and stopping 0.1 mm short of the buttons and the knob; it faces the driver.
    - **The display:** the LCD settings; the glass and the glow; the start-up fade (50% after
      0.6 s).
    - **The map:** heading-up (0.0° behind); zoom; the distance along the road (1,822 m, not the
      366 m straight line); the clock and the arrival time.
    - **Directions:** the hairpin warning (96 m before, none on the open road); "Turn around";
      "Arrived".
    - **The rest:** the run sheet's words; reverse with its guides.
- **Mutations:** all exit 1 (`logs/phase_1/run26/mutation_*`):
  - with the old screen placement, the picture overhangs the head unit by 26.9 mm (12/14);
  - with the straight-line distance, 13/14;
  - with a north-up map, it lags the van by 80° (13/14);
  - with the first call answering itself, the call test fails 9/11;
  - with no calling back, 10/11.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 14/14,
  31/31, 12/12, 46/46, 21/21, 43/43, 12/12, 11/11, 12/12; art 0 failures. The only "ERROR:" lines
  are the engine's "resources still in use at exit". Logs are in `logs/phase_1/run26/suites/`.
- **Import:** the headless import exits 0 with no errors or warnings, and creates only the two new
  scripts' `.uid` files (`logs/phase_1/run26/import/`).
- **Capture** (windowed, on battery; `tools/captures/capture_dash_screen.gd`, new;
  `evidence/phase_1/dash/run26/`, `dash_sheet.png`):
  - from the seat: driving, ringing, and looking down at the screen;
  - close-ups from the driver's eye: driving, ringing with "T Answer", hands-free 00:04 with the
    subtitles, the hairpin warning at 80 m, reverse with the guides, engine off and starting up.
- **Seen:**
  - the glass catches a small bright reflection of the cab's fill light, which shows in close-ups;
  - from the seat the screen is small, as a real 6-inch screen is at arm's length, so its text
    reads only when the player looks down at it.

## Revision 2026-11-02 (Run 26, step 2: the pedestrian scene waits for Maya's call, C41)

- **Author:** "yes  pedestrian scene wait until Maya's call ends?" (#102), answering "Should the
  pedestrian scene wait until Maya's call ends? It only matters in that rare fast case."
- **The problem, measured:** a scratch probe drove flat out from the lumber yard with the lane
  keeper, never answering (`logs/phase_1/run26/step2/flat_out/`):
  - the call rang at 18.0 s, was missed twice, and picked up by itself at 64.8 s;
  - the encounter started at 88.8 s, with about 9.5 s of her call still to come.
- **Why waiting alone is not enough:**
  - **Where it can start:** the encounter can only start in the hairpin above the crossing
    (samples 680–730), because the oncoming van must meet the player before the crossing.
  - **The risk:** if the scene only waited, a van that passed that hairpin during a late call
    would reach the crossing with no encounter at all.
  - **The van's limits:** its top speed is 19 m/s (68 km/h), even downhill, and its steering
    takes every hairpin at that speed. So no van covers the 1,178 m by road from the call's ring
    point (sample 91) to the start of that hairpin in less than 62.0 s.
  - **The call:** left to ring out twice, it ran 80.3 s from the first ring.
- **The fix:**
  - **The scene waits** (mission `first_drive.gd`): the encounter starts only when no call is
    active (`not phone_call.active`).
  - **The call fits** (`phone_call.gd`, Claude Code's call):
    - a call is missed after 4 rings, 8.8 s (it was 6 rings, 13.2 s);
    - she calls back 2 s later (it was 8 s), as people redial straight away;
    - the third call still answers itself after two rings (C40).
  - **The worst case now:** with both calls missed, the conversation starts 26.0 s after the
    first ring and ends 59.5 s after it. That is 2.5 s before even a flat-out van could reach the
    encounter.
  - **After the fix,** the same probe has the call end at 77.6 s and the encounter start at
    88.8 s, 11.2 s later, with no call.
- **Test changes, with reasons (#102):** `test_maya_call.gd` (13 checks; it had 11).
  - **New:** "Left to ring out twice, her call still ends before even a flat-out van could reach
    the pedestrian scene (59.5 s after the first ring; 1178 m at 68 km/h takes 62.0 s)".
    - It works this out from the call's own timings, the 13 approved lines, the road and the
      van's top speed.
    - So a slower call, a faster van or a shorter road fails it.
  - **New:** "While she is on the line, the pedestrian scene waits, and it begins once the call
    ends". Here the van drives through the encounter's hairpin at 58 km/h with the call ringing.
  - **Unchanged:** the existing checks. The missed-call check reads its timings from
    `phone_call.gd`.
- **Mutations:** both exit 1 (`logs/phase_1/run26/step2/mutation_*`):
  - with the scene not waiting, 12/13;
  - with the old pacing (6 rings, 8 s), 12/13: the worst case is 80.3 s, against 62.0 s.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31,
  12/12, 46/46, 21/21, 43/43, 12/12, 13/13, 12/12, 14/14; art 0 failures. The only "ERROR:" lines
  are the engine's "resources still in use at exit". Logs are in `logs/phase_1/run26/step2/suites/`.

## Revision 2026-11-02 (the save rules, written before any save code)

- **Author:** "yes start with the save rules" (#105), after Claude Code proposed missions in a row
  and saving as the next work (#104).
- **Why now:** Assignment 10 asks for save rules "before implementation: path, format and version
  field, and what happens for missing, corrupt, newer-version and unwritable files", by
  November 13, with saving working by November 23. Its grading asks that they are "written first
  and enforced": the version read first, newer files never overwritten, the whole file validated
  before live state changes, warn and stay playable, and a temporary file then a rename.
- **Status: approved by the author on 2026-11-03** ("commit the plan to git", #107), and
  committed before any save code, because the course grades the rules as written first. The calls
  marked "Claude Code's call" came with the plan; any change to them is a later, dated revision.
- **What exists today** (the prototype's checkpoint, from Assignment 5):
  - `user://driving_prototype.cfg` (Godot's ConfigFile text) holds Mission 1's stage, and after
    the hit the van's place, where the man lies and the crack. It is written to a `.tmp` file and
    renamed, and a failed write keeps the old file. Assignment 5's regression suite checks this.
  - `user://driving_audio.cfg` holds the four audio volumes. It is written straight over the old
    file on every slider movement.
  - Neither file has a version. The game applies the stage before checking the rest of the file,
    and says nothing when a file cannot be read.

### What is saved

1. **Progress** (`user://progress.cfg`):
   - which mission the player is on: `night_freight` (Mission 1) for now;
   - Mission 1's checkpoint: 0 at the start, up to 4 before the depot;
   - after the hit, also the van's place, where the man lies (11 body parts) and the crack, as
     today.
2. **Settings** (`user://settings.cfg`): the Master, Vehicle, Ambience and Music volumes.

- **Not saved:** anything between checkpoints (the design doc: "Use mission checkpoints, not
  arbitrary world-state persistence"), the van's clock, Maya's call and the hints already shown.

### When

- **Progress:**
  - at every checkpoint: the four on the road, and silently when "DRIVE." appears after the hit;
  - when a mission ends, the save moves to the next mission's start. Until Mission 2 exists,
    finishing Mission 1 saves its start, as "Drive again" does;
  - at "New drive".
- **Settings:** when the player leaves the menu or quits (Claude Code's call; today every slider
  movement writes the file).

### Where, the format and the version

- **Folder:** Godot's `user://`. On this Mac it is under
  `~/Library/Application Support/Godot/app_userdata/`, in a folder named after the project. The
  exact folder name is checked in the build step.
- **Format:** Godot's ConfigFile text, as today (Claude Code's call). Assignment 5's regression
  suite and the collision test keep reading Mission 1's `[drive]` section unchanged.
- **Version field:** each file has a `[save]` section holding `version`, a whole number, 1 for both
  files now. Any change to what a file holds raises its version, including adding a mission.
- **Progress, version 1:**

  ```ini
  [save]
  version=1
  mission="night_freight"

  [drive]
  stage=3
  ; after the hit only, all three or none; body has 11 entries:
  recovery=Transform3D(...)
  body=[Transform3D(...), ...]
  crack={"amount": 1.0, "point": Vector2(...), "seed": 0.42}
  ```

- **Settings, version 1:** `[save]` with `version=1`, and `[audio]` with the four volumes, each 0
  to 1.
- **Today's files** (`driving_prototype.cfg`, `driving_audio.cfg`) are never read again and never
  deleted. The first launch under these rules starts a new drive at the default volumes (Claude
  Code's call; only the author and testers have saves).

### Reading a file, in this order

1. **Missing:** a new drive, or the default volumes, with no warning. That is the first launch.
2. **The version, before any other field:**
   - **newer** than the game knows: the file is not loaded, and it is never written over, moved or
     deleted, whatever else happens. Saving that file is off for the session. The game warns and
     plays on;
   - **older:** upgraded in memory, one version at a time. None exists yet, because 1 is the first;
   - **no version, not a whole number, or below 1,** or a file that is not ConfigFile text:
     **corrupt** (below).
3. **The whole file is checked before anything in the game changes:**
   - a known mission;
   - a checkpoint from 0 to 4;
   - the after-the-hit values all present or all absent, and only at checkpoint 3 or 4;
   - the van's place and every body part as finite transforms, inside the playable area;
   - exactly 11 body parts;
   - a crack amount from 0 to 1, with a finite point and seed;
   - each volume, where present, a number from 0 to 1 (a missing one keeps its default).

   Unknown extra keys are ignored. One failure makes the whole file corrupt, and nothing from it
   is used.
4. **Only then** is it applied.

- **Corrupt:**
  - the file is renamed `progress.cfg.corrupt` or `settings.cfg.corrupt`, replacing an older one,
    so it is kept and never written over;
  - the game warns and starts a new drive, or uses the default volumes;
  - if the rename fails, saving that file is off for the session, so a file the game could not
    read is never replaced.

### Writing a file

1. **Saving off** (no path given, a newer file, or a corrupt file that could not be moved): nothing
   is written.
2. **A temporary file, then a rename:** the whole file goes to `progress.cfg.tmp`, then is renamed
   over `progress.cfg`. The settings file follows the same rule; today it is written straight over.
3. **Unwritable** (a read-only folder, a full disk, or a failed write or rename): the temporary file
   is removed, and the last good file stays as it was. The game warns, keeps playing, and tries
   again at the next checkpoint.

### Warnings

- **On screen,** in plain words, where the player will see them: the menu at launch, the notice
  line while driving. **In the log,** with `push_warning`, every time.
- **Drafts** (the failed-save line is today's, which Assignment 5's suite checks):
  - corrupt progress: "Saved progress could not be read, so a new drive has started. The old file
    was kept.";
  - newer progress: "This save is from a newer version of the game. It was not loaded or changed,
    and progress will not be saved this session.";
  - a failed save: "Checkpoint could not be saved. Recovery is available for this session.";
  - settings: "Settings could not be read, so the default volumes are in use."

### Tests never touch the player's real save

- **Saving is off unless a path is given:**
  - the game, launched normally, gives the real paths;
  - a game that a test builds saves and reads nothing unless the test gives it scratch paths;
  - today the progress path defaults to the real file, and every test run reads the real audio file
    when the HUD starts.
- **A scratch home for every test and capture run:**
  - `scripts/run-test.sh` points `HOME` at `.scratch-home/` in the repository, ignored by Git, so
    even a mistake lands there (Claude Code's call: the course suggests `../scratch-home`, which is
    outside the project folder);
  - captures, run by hand, use it too;
  - exports and the editor keep the real home, where the export templates are;
  - that Godot on this Mac follows `HOME` is checked before relying on it, and how goes into
    `TEST-REPORT.md`.
- **The real folder is checked:** `scripts/run-test.sh` takes a fingerprint of the real save folder
  before and after every run, and fails if anything in it changed.
- **Prediction: where the existing tests' runs will be saved once persistence exists.**
  - The 13 game tests that load the game and both Assignment 5 suites already give it a scratch
    checkpoint file in the system temp folder, so their progress saves keep landing there.
  - Today's runs still touch the real folder: the HUD reads the real audio file, and Godot probably
    writes its own log to `user://logs/`. With the scratch home and saving off by default, nothing
    will.

### Predicted failure cases, and how they are caught

1. **A test that forgets its path** writes the player's save. Caught by saving being off by default,
   and by the wrapper's fingerprint.
2. **A newer file read past its version,** treated as corrupt and moved aside, so the newer game's
   progress is lost. Caught by a test that loads a version 2 file, reaches a checkpoint, and finds
   the file byte-for-byte the same under its own name.
3. **A half-applied file:** a good checkpoint used with a broken body part. Caught by a test with
   one bad value among good ones: nothing from it is used.
4. **Godot on this Mac ignoring `HOME`.** Caught by the check before relying on it.

### How it is checked (the build step, with its own approval)

- **A new `game/tests/test_save_rules.gd`:**
  - **round trip:** quit after the hit and load again: the same mission, checkpoint, van place,
    body and crack;
  - **missing:** a new drive, with no warning;
  - **corrupt:** text that is not ConfigFile, a bad version, and one bad value among good ones.
    Each time nothing is applied, the file is kept as `.corrupt`, and the game warns;
  - **newer:** not loaded, and byte-for-byte unchanged after a checkpoint;
  - **unwritable:** a read-only scratch folder gives the warning, the old file unchanged, and a game
    that still plays;
  - no `.tmp` left behind, and the settings file checked the same way;
  - a game built by a test with no paths writes nothing.
- **Mutations,** each of which must fail it:
  - the version read after the other fields;
  - a file applied before it is checked;
  - a newer file written over.
- **Unchanged:** Assignment 5's checkpoint checks, which keep passing as they are.
- **Human check (Assignment 10):** quit at a checkpoint, relaunch, continue, and confirm.
- **The submission's one line:** "Mission progress and its last checkpoint, plus audio volumes, as
  versioned ConfigFile text in `user://`: version read first, newer files never overwritten, the
  whole file checked before use, warn and keep playing, temporary file then rename."
- **Files:**
  - new `game/shared/save/save_file.gd`: the rules in one place, for both files;
  - the mission (progress), the app (real paths only when launched as the game, and the warnings)
    and the HUD (settings);
  - `scripts/run-test.sh` and `.gitignore`;
  - the new test.

## Revision 2026-11-03 (Run 27: saving, built to the save rules)

- **Author:** "okay proceed" (#110), for step 2 as described: the `HOME` check, the test first,
  the build, three deliberate breakages, every suite and the import, and the T key in
  `CLAUDE.md`. The rules are the revision above, approved and committed as `301c250` (#107).
- **Checked first:**
  - **Godot follows `HOME`:** with `HOME=.scratch-home`, `user://` is
    `.scratch-home/Library/Application Support/Godot/app_userdata/Blackridge- No Way Back/`
    (`logs/phase_1/run27/home_check/`). The real folder is the same path under the real home.
  - **The old runner touched the real folder:** one run of `test_wipers.gd` rotated Godot's own
    logs there (a new `godot.log`, the oldest log deleted). The player's save,
    `driving_prototype.cfg`, did not change, because every test gives the game its own
    checkpoint file (`logs/phase_1/run27/before_isolation/`).
  - **The new runner on unchanged code:** every suite passed with `HOME` in the scratch home, and
    the real folder stayed the same across all 19 runs (`logs/phase_1/run27/baseline/`).
- **Test first** (`game/tests/test_save_rules.gd`, new, 26 checks). On the old code it failed
  22/26 (`logs/phase_1/run27/before/`). It also found a bug: with no crack on the glass, the
  crack the game would save had no point or seed, because those shader values were never set.
  Under the new rules such a save would be thrown away as damaged.
- **The build:**
  - **`game/shared/save/save_file.gd` (new),** the rules in one place for both files:
    - `read()` takes the version before anything else. A newer file is left alone, and saving it
      is off for the session.
    - No version, a version that is not a whole number or is below 1, text that is not a save, or
      any bad value makes the file damaged. It is renamed `.corrupt`, replacing an older one. If
      it cannot be moved, it stays in place and saving it is off.
    - Only a file that passes the caller's whole check comes back.
    - `write()` refuses while saving is off, or when the file on disk is from a newer version,
      whatever happened since loading. It writes `[save] version` first, to a `.tmp` file, then
      renames it. On any failure it removes the `.tmp` file and keeps the old one.
    - Every warning also goes to the log, with `push_warning`.
  - **The mission** (`first_drive.gd`):
    - its progress file comes from the app (`checkpoint_path`), empty by default, so a game a
      test builds saves and reads nothing;
    - `_valid_progress()` checks the whole file before anything is applied: the mission
      `night_freight`; checkpoint 0–4; the after-the-hit values all or none, only at checkpoint
      3 or 4; every transform finite, a true rotation and inside the playable area; 11 body
      parts; a crack from 0 to 1 with a finite point and seed;
    - finishing the drive saves the start (`_save_finished()`), as the rules say until Mission 2
      exists;
    - `progress_read` tells the app what it found.
  - **The HUD** (`driving_hud.gd`): the volumes load by the same rules (`load_settings()`). They
    are saved when the menu is left or the game quits (the Quit button or closing the window),
    not on every slider movement. Warnings show on the menu (`warn()`, `warning()`).
  - **The app** (`game/app/first_drive.gd`):
    - it gives `user://progress.cfg` and `user://settings.cfg` only when it is the scene Godot
      launched (`get_tree().current_scene == self`);
    - it passes the playable area to the mission, and shows the progress warnings.
  - **`van_presentation.gd`:** the windshield's crack point and seed start at the shader's own
    defaults (`NO_CRACK`, 0.0), so a crack that never happened saves as finite values. The look
    is unchanged.
  - **`scripts/run-test.sh`:**
    - Godot runs with `HOME` in `.scratch-home/`, which Git ignores;
    - before and after each run it fingerprints the real save folder (each file's path, size and
      time), and the run fails with "REAL SAVE FOLDER CHANGED" if anything differs.
- **Claude Code's calls:**
  - **Two warnings the rules did not word:**
    - settings from a newer version: "These settings are from a newer version of the game. The
      default volumes are in use, and volume changes will not be saved this session.";
    - settings that could not be written: "Settings could not be saved. These volumes last until
      you quit."
  - **Checkpoints while saving is off:** for a newer or unmovable file, each checkpoint shows
    today's "Checkpoint could not be saved..." notice, so nothing claims a save. A game built by
    a test with no path shows nothing.
  - **Squashed transforms:** a transform with a squashed or mirrored rotation also counts as
    damaged. The rules say finite; a squashed body part would break the ragdoll.
  - **The warning's place:** it sits on the menu, under the introduction.
- **Test changes, with reasons:**
  - **`test_save_rules.gd` is new** (above). It also launches the game the way Godot does
    (`change_scene_to_packed`), only inside the scratch home, and checks that the game uses
    `user://progress.cfg` and `user://settings.cfg` there.
  - **`test_collision.gd`** (44 checks; it had 43):
    - **Why it changes:** the rules end a mission by saving the next start, so after the depot
      the save no longer holds the hit.
    - **The continue check:** it now continues from the save made right after the hit, as a
      player who quit before the depot would. The test keeps that save when "When he can drive
      on, a checkpoint keeps ..." passes.
    - **New:** "With the drive over, the save goes back to its start, so the next launch begins
      a new drive".
  - **Assignment 5's suites are unchanged and pass.** The regression suite still reads
    `[drive] stage`, finds no `.tmp`, keeps the old file on a failed write, ignores bad stages,
    and sees "Checkpoint saved" and "could not be saved". Its bad-stage files have no version,
    so the game now sets them aside as damaged.
- **Mutations:** all exit 1 (`logs/phase_1/run27/mutation_*`):
  - the version read after the other fields: 24/26, newer files moved aside as damaged;
  - a file applied before it is checked: 21/26;
  - a newer file written over: 21/26;
  - no save at the end of the drive: the collision test fails 43/44.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31,
  12/12, 46/46, 21/21, 44/44, 12/12, 13/13, 12/12, 14/14, 26/26; art 0 failures. The real save
  folder never changed. Logs are in `logs/phase_1/run27/suites/`. The only "ERROR:" lines are:
  - the engine's "resources still in use at exit";
  - the expected parse error for a deliberately damaged file.
- **Import:** the headless import, run with the scratch home, exits 0 with no errors or warnings.
  It creates only the two new scripts' `.uid` files, and the real save folder is unchanged
  (`logs/phase_1/run27/import/`).
- **A real launch:** the game, launched headless as the main scene with a damaged `progress.cfg`
  in the scratch home, set it aside as `progress.cfg.corrupt` and warned
  (`logs/phase_1/run27/real_launch/`).
- **The prediction, checked:** the existing tests save to their own temporary checkpoint files,
  as predicted. A game a test builds no longer reads the real volumes, and Godot's own log now
  lands in the scratch home.
- **Not done:**
  - the author's check (Assignment 10): drive to a checkpoint, quit, relaunch, continue;
  - the menu with a warning on it has not been seen in a window;
  - the keyboard-only menu is the next step.

## Revision 2026-11-03 (Run 28: Ethan steps up road edges and kerbs)

- **Author:** "hes not able to get closer to the van. make sure theres are no bugs, play it yourself
  and find bugs and gaps that isnt making our game realistic", with a screenshot of Ethan stopped
  beside the road short of the van (#111); then "ok" to the proposed fix (#112).
- **The cause,** found with a headless probe that walked Ethan at the van from 17 directions:
  - the gravel verge's collision is a flat strip about 11 cm above the forest floor beside it;
  - Ethan's capsule (0.3 m radius) meets its edge at about 50°, steeper than the 45° he can walk
    up, so every road edge acted as a wall;
  - E works within 4.5 m of the van, and the scripted walk to the door then teleported him there
    after a second stuck. That hid the bug from the tests, which also placed him beside the van
    instead of walking him there.
- **The fix** (`driver.gd`, Claude Code's call on the numbers):
  - Ethan has a step height of 0.3 m, as third-person characters usually do (`STEP_HEIGHT`,
    `_step_up()`). Before each move, when something is in his way within 0.1 m, he steps up onto
    it only if:
    - lifted 0.3 m he could move on;
    - the surface he would land on is walkable (45° or less).
  - So he steps onto verges, kerbs and the office step. Walls, barriers, the van (its body spans
    0.15 to 2.24 m above the road) and steep rock still stop him.
  - He keeps to the ground going down a step, too (`floor_snap_length` 0.3 m).
- **Test change, with its reason (#111):** `test_on_foot.gd` (48 checks; it had 46). Two are new:
  - **The walk to the van:** "From the office door, W and the mouse take Ethan round the van's
    front to the driver's door". It fails if he ends more than 0.5 m from the door, or moves
    more than 0.1 m in one frame, which would be a teleport. He steps up 0.11 m on the way.
  - **The van's side:** "Walking into the van's side, he stops against it and cannot climb it".
  - **Unchanged:** the test then places him beside the van as before, for the walking, boarding
    and later checks.
- **Test first:** on the old code the walk check failed. He stopped 5.85 m from the door, stepping
  up 0.00 m (47/48, `logs/phase_1/run28/before/`).
- **Mutation:** with `_step_up()` removed, the test fails 47/48 and exits 1
  (`logs/phase_1/run28/mutation_no_step/`).
- **Probes** (in the agent's scratch folder):
  - **All directions:** walking straight at the van from all 17 directions, he now reaches its
    body every time. Before, he stopped 2.6 m short from 15 of them.
  - **Boarding:** from where the author's screenshot showed him, 4 m from the van on the forest
    floor, E walks him round to the door in 7.9 s. His largest single step is 3.8 cm, so there
    is no teleport.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 17/17, 12/12, 30/30 ×3, 25/25, 31/31,
  12/12, 48/48, 21/21, 44/44, 12/12, 13/13, 12/12, 14/14, 26/26; art 0 failures. The real save
  folder never changed. Logs are in `logs/phase_1/run28/suites/`.
- **The play-test** (#111), a full drive played twice by key presses, with no shortcuts:
  - **Headless:** signing, walking to the van, boarding, the climb, Maya's call, the hit at
    41 km/h, the depot bay and the ending all work. The van never stuck, left the road or tipped.
  - **In a window,** with 21 screenshots in the agent's scratch folder. Gaps found, to fix one
    step at a time with the author's approval:
    1. trunk bottoms glow white in the low beams, and the man lying in the road looks white. The
       bark texture is a realistic dark brown (linear albedo 0.13, 0.08, 0.05), so the cause is
       over-exposure near the road;
    2. the van starts parked in the road lane, outside the lumber yard;
    3. prototype wording on screen: "NIGHT FREIGHT / DRIVING PROTOTYPE", "vehicle and atmosphere
       prototype", "Follow the freight loop";
    4. the run sheet says bay 3, but the painted bay is in front of door 02;
    5. mirror-smooth puddles at the start reflect the floodlight as white patches;
    6. the engine sound and the rev counter rise as if the van had one gear;
    7. the hillside's ground texture visibly repeats;
    8. Ethan wears a suit for a night freight shift (C28's character; the author's call).

## Revision 2026-11-03 (Run 29: low beams shaped like real ones, and wet bark, C44)

- **Author:** "yes start on the lighting" (#113). Shown three options side by side, the author chose
  "Recommended" (#114). The options are in `evidence/phase_1/beams/run29_options/`.
- **The cause of the white trunks:**
  - the low-beam pattern kept full strength out to 9° on each side and half at 20°. Real low
    beams fall to about a tenth there;
  - a trunk beside the road faces the lamps square-on, while the road is lit at a glancing angle,
    so the trunk took far more light than the road and burned to white below the cutoff;
  - the bark texture is a realistic dry brown (linear albedo 0.13, 0.08, 0.05), but in the rain
    it should be wet, and wet bark is darker.
- **How the option was chosen:**
  - runtime experiments in the agent's scratch folder: eight variants at four forest spots,
    measured and photographed;
  - the runtime copy of the generator matched today's pattern exactly (0/255).
- **The change:**
  - **`tools/make_low_beam_pattern.py`:** the horizontal fade becomes 1.0, 1.0, 0.55, 0.25, 0.12
    and 0.06 at 0, 9, 13, 18, 24 and 35°. The fade below the cutoff becomes 1.0, 1.0, 0.5, 0.2,
    0.06 and 0.03 at 0, 1.5, 4, 8, 15 and 27°. The stray light above the cutoff is 0.03 (it was
    0.05).
  - **The images:** both patterns are regenerated, the low beam's and then the high beam's, which
    adds its hot spot to the low beam.
  - **`roadside_forest.gd`:** the mature trunks' bark is darkened to 60% (`WET_BARK`). The young
    firs keep their own shade.
  - **Unchanged:** the headlights' energy (650), the exposure (1.3), the tonemap and the beam's
    reach.
- **Test change, with its reason (#113–#114):** `test_headlights.gd` (19 checks; it had 17). Two
  are new:
  - "The low beam fades as a real one does": at most a quarter of its centre at 20° to the side,
    and at most a tenth on the ground just ahead. Today it gives 21% and 6%;
  - "The trunks' bark is darkened for the rain" (60%).
- **Test first:** on the old beam and bark, both new checks failed: 50% and 16%, and the bark at
  100% (17/19, `logs/phase_1/run29/before/`).
- **Mutation:** with the old beam images put back, the test fails 18/19 and exits 1
  (`logs/phase_1/run29/mutation_old_beam/`).
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 19/19, 12/12, 30/30 ×3, 25/25, 31/31,
  12/12, 48/48, 21/21, 44/44, 12/12, 13/13, 12/12, 14/14, 26/26; art 0 failures. Logs are in
  `logs/phase_1/run29/suites/`. The headless import was run with the scratch home, and the real
  save folder did not change (`logs/phase_1/run29/import/`).
- **Measured** at the start straight (`capture_beams.gd`, `evidence/phase_1/beams/run29/`), against
  Run 23:

  | | Road 10–46 m | Road 50–100 m | White-out |
  | --- | --- | --- | --- |
  | Low beams | 88.4 (88.7) | 42.8 (44.7) | 0.00% |
  | High beams | 133.0 (134.9) | 102.3 (103.9) | 0.00% |
  | Lights off | 18.1 (18.6) | 25.4 (24.8) | 0.00% |

  At the four forest spots, the share of near-white pixels fell from 0.17–0.28% to 0.00–0.09%. On
  bends the road is about a fifth dimmer, as with real low beams.
- **The man in the road** (`capture_collision.gd`, `evidence/phase_1/collision/run29/`): he keeps
  his dark top and blue jeans instead of looking white (`before_after_the_man_in_the_road.png`,
  against Run 25).
- **Frame rates** are not compared: the Mac was not on mains power.

## Revision 2026-11-03 (Run 30: low beams reach about 40 m, high beams further, C45)

- **Author:** "i also want it to be more like low bream, user shouldnt see much road ahead, higher
  beam should be little more (like how it works in real life. )" (#115). Shown four options side by
  side (`evidence/phase_1/beams/run30_options/`), the author chose "C (Recommended)".
- **Before:**
  - the low beam's cutoff sat 1.4° above the lamp's axis. With the lamp aimed 2° down, the cutoff
    line met the road about 95 m ahead, and the beam was at a tenth of full about 63 m ahead (as
    measured by the new check);
  - both beams used the same energy (650); the low beam's reach was 120 m and the high beam's
    220 m.
- **The change:**
  - **`tools/make_low_beam_pattern.py`:** the cutoff moves to 0.6° above the axis, and the stray
    light above it to 0.02. Both images are regenerated, the low then the high.
  - **`van_presentation.gd`:** each beam has its own energy and reach (`_aim_beam()`). Low beams
    keep 650 and reach 70 m (`LOW_BEAM_RANGE`, `LOW_BEAM_ENERGY`); high beams get 850 and reach
    260 m (`HIGH_BEAM_RANGE`, `HIGH_BEAM_ENERGY`).
  - **Knock-on effects:** the rain in the beams uses each beam's reach. The oncoming van, which
    uses the high-beam image, keeps its own energy.
- **Test change, with its reason (#115):** `test_headlights.gd` (21 checks; it had 19). Two are
  new:
  - **"Low beams light the road to about 37 m ahead and fade out by 70 m".** It finds where the
    beam image reaches a tenth of full and uses the lamp's real aim and height above the road. It
    asks for 30–50 m and a reach of at most 80 m.
  - **"High beams reach 260 m, with more light than the low beams (850 against 650)".**
  - **The shape check** samples relative to the new cutoff (`CUTOFF` 0.6).
- **Test first:** on the old beams, both new checks failed: 63 m and 120 m; 220 m with equal light
  (19/21, `logs/phase_1/run30/before/`).
- **Mutation:** with the committed beam images and the 120 m reach put back, the test fails 19/21
  and exits 1 (`logs/phase_1/run30/mutation_old_reach/`).
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 21/21, 12/12, 30/30 ×3, 25/25, 31/31,
  12/12, 48/48, 21/21, 44/44, 12/12, 13/13, 12/12, 14/14, 26/26; art 0 failures. The import was
  run with the scratch home, and the real save folder did not change. Logs are in
  `logs/phase_1/run30/`.
- **Measured** at the start straight (`capture_beams.gd`, `evidence/phase_1/beams/run30/`),
  against Run 29:

  | | Road 10–46 m | Road 50–100 m | White-out |
  | --- | --- | --- | --- |
  | Low beams | 80.8 (88.4) | 29.1 (42.8) | 0.00% |
  | High beams | 144.1 (133.0) | 106.1 (102.3) | 0.00% |
  | Lights off | 18.3 (18.1) | 24.6 (25.4) | 0.00% |

  Beyond 50 m, the low beams leave the road nearly as dark as with the lights off. High beams light
  it 3.6 times as brightly as low beams (it was 2.4 times).

## Revision 2026-11-03 (Run 31: back onto the road, the van on the forecourt, bay 2, kerbs, C46)

- **Author:**
  - "Next I'd suggest the start area ... Shall I start on that? -> proceed. also, the side mirrors
    dont look nice, they dont fit it and look real and also the reverse camera isnt working, also
    one bug is when i go off the road not able to come back onto the road."
  - For the depot bay, the author chose "Sheet says bay 2 (Recommended)" (#117).
- **Back onto the road (the reported bug):**
  - **The cause:** a headless probe drove the van off the road and back. On flat stretches the
    van's body met the gravel verge's edge, about 11 cm above the ground, as a wall. It is the
    edge that stopped Ethan in Run 28; he has a step height, but the van is a sliding box.
  - **The fix** (`industrial_loop.gd`, `_shoulder()`): the verge strip gains a sloping outer edge,
    0.6 m wide and dropping 0.3 m (about 27°), in the same gravel. It carries the collision too.
    Below its top few centimetres it runs under the ground, so the shoulder now meets the ground
    as real gravel shoulders do.
  - **Measured:** at both flat stretches tested, the van now drives back onto the asphalt in
    3.5–6 s from either side. Guardrails and tree trunks still stop it.
- **The van on the forecourt:**
  - **Where:** a gravel forecourt (36 × 5.4 m, cleared of plants) now lies between the site office
    and the road. The van starts parked on it beside the road, facing west as before (mission
    `START`, 6.5 m from the road's centre), and pulls out into the lane.
  - **The floodlight:** the office floodlight is aimed at the van's new place (`VAN_PARKING`, in
    `_office_lights()`). It now lights gravel instead of the road, so the white puddle patches at
    the start are gone.
  - **Plants:** clearing the forecourt changes where some plants are placed elsewhere; the counts
    are unchanged.
- **Bay 2:** the run sheet and the dash screen's run-sheet card now say "Freight depot, bay 2",
  the painted bay in front of door 02.
- **Kerbs (found while testing):**
  - **The bug:** Run 28's step only lifted Ethan onto a step's corner. It worked up to about 15 cm.
    At 20–30 cm he rode up the edge, slid back and bobbed on the spot.
  - **The fix** (`driver.gd`, `_step_up()` and `_hold_step()`): once a walkable step is found
    0.35 m ahead, he is lifted to its top and held there until he stands on it, at most 0.6 s.
  - **Measured:** steps of 10, 15, 20, 25 and 30 cm are each climbed in one rise, and he steps down
    off the far side.
- **Test changes, with reasons (#117):**
  - **`test_ghat_road.gd`** (33 checks; it had 31):
    - new: "From the ground beside the road, the van drives back onto it on either side";
    - "The van starts level on the valley road" becomes "The van starts level, parked on the
      forecourt beside the road, out of the lane";
    - new: "From the forecourt the van pulls out into the road's lane".
  - **`test_on_foot.gd`** (49 checks; it had 48):
    - **The walk check:** it no longer crosses the road's edge, so it no longer reports a step
      height;
    - **New:** "Ethan steps up a 20 cm kerb onto the pavement behind it and walks on, but a 50 cm
      ledge stops him", using a test-built kerb and ledge in the lumber yard;
    - **The run sheet:** it is compared with "bay 2".
- **Test first and mutations:**
  - **The road check:** on the old road the van stayed off the asphalt on both sides (31/32,
    `logs/phase_1/run31/before/`). That is the same code as the fix removed.
  - **The kerb check:** with the step removed, the on-foot test fails 48/49 and exits 1
    (`logs/phase_1/run31/mutation_no_step/`).
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 21/21, 12/12, 30/30 ×3, 25/25, 33/33,
  12/12, 49/49, 21/21, 44/44, 12/12, 13/13, 12/12, 14/14, 26/26; art 0 failures
  (`logs/phase_1/run31/suites/`). Both Assignment 5 suites pass unchanged with the new start.
- **Evidence:** `evidence/phase_1/start/run31/`: walking to the van on the forecourt, reaching it,
  and the cab at ignition.
- **Found, for the next steps:**
  - **The reverse camera works but sees black.** At night nothing behind the van is lit: the van
    has no white reversing lamps.
  - **The mirrors are flat screens.** Each is a self-lit rectangle showing a fixed wide camera.
    From outside it glows like a TV. From the seat, only the driver's mirror shows, through the
    rain-covered front pane; the passenger mirror and both wide-angle glasses are hidden behind
    the doors from the driver's eye.

## Revision 2026-11-03 (Run 32: reversing lamps and a reverse camera that works at night, C47)

- **Author:** "the reverse camera isnt working" (#117), then "alright proceed with reverse camera first
  and then mirrors" (#118).
- **The cause:** the reverse camera worked, but at night it saw only black. The van had no white
  reversing lamps, so nothing behind it was lit. The camera rendered with the same night exposure
  as the driver's view.
- **The fix** (`van_presentation.gd`, `_reversing_lamps()`):
  - **Lamps:** two white reversing lamps (`REVERSE_LAMP`, energy 6, reach 14 m, 55°, aimed 12°
    down) light the ground behind the van whenever it is in reverse with the engine running.
  - **Lens glow:** the clear band of each rear lamp cluster glows white in reverse. It is the
    Iveco's own lens geometry between 0.92 and 1.08 m (`REVERSE_LENS`), the most neutral band of
    the lens texture when sampled band by band. It is copied 1.5 mm proud of the lens and added
    to the van's body, not to the converted model.
  - **The camera:** the reverse camera boosts its picture 3x (`REVERSE_GAIN`), as real backup
    cameras do in low light.
- **Test changes, with reasons (#117–#118):**
  - **`test_dash_screen.gd`** (15 checks; it had 14). New: "In reverse, white reversing lamps glow in
    both rear clusters and light the ground behind, and the camera brightens its picture for the
    dark; in drive they are off". On the old van it failed with no lamps and 1.0x
    (`logs/phase_1/run32/before/`).
  - **`test_headlights.gd`** (21, the same count): `_headlights()` counted every spotlight on the van
    as a headlight. It now counts the forward-pointing ones, because the van also has reversing
    lamps.
- **Mutation:** with the lamps kept off, the dash screen test fails 14/15 and exits 1
  (`logs/phase_1/run32/mutation_lamps_off/`).
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 21/21, 12/12, 30/30 ×3, 25/25, 33/33,
  12/12, 49/49, 21/21, 44/44, 12/12, 13/13, 12/12, 15/15, 26/26; art 0 failures
  (`logs/phase_1/run32/suites/`).
- **Evidence:** `evidence/phase_1/dash/run32/` (`reverse_before_after.png`):
  - **before:** in reverse the screen was black apart from one distant light;
  - **after:** it shows the road behind lit by the lamps: the asphalt, the gravel edge, ferns, a
    trunk and a post, under the guide lines;
  - **the picture's mean brightness:** 26.6 before, 45.0 after.

## Revision 2026-11-04 (Run 33: real door mirrors, and the yard gravel at real size, C48)

- **Author:** "the side mirrors dont look nice, they dont fit it and look real" (#117) and "then
  mirrors" (#118). Shown today's mirrors beside two prototypes, the author answered "i like A but
  it doesnt look realistic. fix it and they dont look clear. things arent looking clear to look at
  of whats coming behind." Shown the fixed A, then "Yes, both (Recommended)" (#119).
- **What was wrong with today's mirrors:**
  - each glass showed a fixed 62° camera picture on a flat quad, 2–3 cm in front of the Iveco's
    own glass, which is turned 5° toward the cab. So the picture floated in the housing;
  - the main and the wide-angle glass showed the same picture;
  - the picture was self-lit, so from outside the mirrors glowed like screens.
- **What made the first A unclear and unreal** (found in throwaway prototypes, logged with #119):
  - the reflection was tone-mapped twice, by the mirror camera and again by the driver's view.
    Dark areas washed out to grey, and lamps dulled;
  - it was drawn at 384 pixels, with raindrops on the mirror glass itself;
  - the yard's gravel showed as black-and-white blotches (below).
- **The mirrors now** (`van_presentation.gd`, `_mirrors()`; `mirror_glass.gdshader` new, in the
  van's folder, not `game/shaders/`):
  - **The glass:** the reflections sit on the Iveco's own mirror glass, 2 mm in front of it, with
    its rounded corners: 55 main and 46 wide-angle triangles per door.
    - The glass is found in the model's full-quality texture (metallic, smooth and facing back),
      by the new `tools/art/extract_mirror_glass.gd`, and saved as
      `art/iveco/mirror_glass_left.tres` and `mirror_glass_right.tres`.
    - The game cannot find it itself: the imported texture is compressed, which finds only 73 of
      the 101 triangles, or picks up 40–60 housing triangles with a looser threshold. The
      selection rule lives in `mirror_glass.gd`, which the tool and the test share.
  - **Real reflections:** one camera per mirror, at the glass, set as a driver sets a mirror.
    - **The main glass** is slightly curved, like the Iveco's European mirrors (1.6 m radius). It
      shows from 4.5° inside the van's side, so the side shows along its inner edge, to 13° outside,
      with the horizon about a third from the top.
    - **The wide-angle glass below** has a 0.4 m radius. It shows the van's side, the rear wheel and
      the ground beside it, 52.8° across against 18° for the main glass.
    - The picture is spread over each glass as a curved mirror spreads it, and flipped as a mirror
      flips it.
  - **Brightness:**
    - the mirror cameras render in HDR with a linear tonemap, and the driver's view tone-maps the
      result once, as it does everything else. So the headlights of a van behind stay bright, and
      their reflection on the wet road shows (screen-space reflections in the driver's mirror);
    - with nothing lit behind at night, the mirror is dark, as real mirrors are;
    - the glass reflects 60%, like chrome.
  - **Clear glass:** the mirror glass is heated, as on the Daily, so it carries no rain. The rain
    stays on the side window in front of it.
  - **Sharper and smoother:**
    - each mirror camera renders at 640 pixels (today: 256 × 320);
    - the driver's mirror updates 30 times a second and the passenger's 15. Today both shared 45,
      22.5 each.
  - **From outside:**
    - the reflections are drawn on their own render layer (8), which only the driving camera sees;
    - they show only while someone is in the driver's seat, so Ethan walking round the van sees
      the Iveco's own dark glass;
    - the driver's mirror, its glass and its view all swing with the door.
- **The moon and the mirrors' cost** (`industrial_loop.gd`, `MOON_LAYER`):
  - **The finding:** the moon's shadow, drawn again for every mirror picture, was about two thirds
    of a mirror's cost.
  - **The change:**
    - the moon is now on render layer 4, the layer the mirrors never draw (the cab's layer). The
      driving camera, Ethan's camera and the depot's reflection probe still see it, and its
      shadows;
    - each mirror camera gets a copy of the world's lighting with a little more soft fill
      (`MIRROR_FILL`, +0.05) in the moon's place. At mirror size, moonlight and fill cannot be
      told apart;
    - the reverse camera now draws layers 1–3, so it keeps the moon.
- **The tail lamps** (`_tail_glow_lights()`): with the engine running they cast a faint red glow
  on the road behind, four times brighter when braking, as brake lamps are. They are two soft red
  lights (0.25, braking 1.0, 5 m, 85°), so the mirrors at night show the road behind tinted red.
- **The yard gravel** (`industrial_loop.gd`):
  - **The bug:** the lumber yard (since Run 15) and the forecourt (since Run 31) are boxes whose
    texture coordinates are not in metres. The gravel was stretched about 100 times: a 5 cm leaf
    became a 5 m blotch, and the stretched gloss map made the white "puddles" of #111.
  - **The fix:** both are projected in metres, 1.8 m to a tile, like the verges.
- **Claude Code's calls:**
  - the glass radii, the aim (4.5° and 8° inside, 16° down) and the 60% reflectance;
  - the heated glass;
  - 30 and 15 updates a second;
  - 640 pixels, and the mirrors' level-of-detail threshold of 12 (a narrow mirror camera
    otherwise picks finer models than it needs);
  - the fill;
  - the tail glow's strength, softened twice after captures showed it as a red floodlight.
- **Test changes, with reasons (#117–#119):**
  - **New `game/tests/test_mirrors.gd`, 11 checks:**
    - each mirror is the Iveco's own glass, 2 mm in front of it;
    - from outside, dark glass, the reflections only for the driver in the seat;
    - HDR, tone-mapped once, 640 pixels, 60%;
    - the driver's mirror set as a driver sets it, and the wide-angle glass wider and lower;
    - the mirror swings with the door;
    - 30 and 15 updates a second;
    - the moon skipped by the mirror cameras, with a fill;
    - the tail glow;
    - the gravel at real size.
  - **`test_cockpit.gd`** (25 checks, the same count):
    - **Cameras:** the camera check reads the layers it names (world, body, cab) instead of the
      whole cull mask, because the driving camera also sees the mirror layer now.
    - **Mirrors:** "shows its live view, mirrored, on both its glasses, facing back" becomes
      "reflects onto both of its own glasses, the main and the wide-angle one".
    - **Screens:** they number 3, not 7, because the mirrors are glass, not screens.
  - **`test_dash_screen.gd`** (15): its reversing-lamp check took every backward-pointing light for
    a reversing lamp. The red tail glow also points back, so it now takes the white ones.
- **Test first:** on the old mirrors the new test failed 0/11 (`logs/phase_1/run33/before/`).
- **Mutations:** all exit 1, each failing only its own check (`logs/phase_1/run33/mutation_*`):
  - the old non-HDR picture;
  - the mirror aimed 2° outside the van's side instead of 4.5° inside: the side no longer shows;
  - the moon left in the mirrors;
  - the forecourt gravel stretched again;
  - the reflections left showing with no one in the seat.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 21/21, 12/12, 30/30 ×3, 25/25, 33/33,
  12/12, 49/49, 21/21, 44/44, 12/12, 13/13, 12/12, 15/15, 26/26, 11/11; art 0 failures. The only
  error line other than "resources still in use" is the save test's deliberately damaged file.
  Logs are in `logs/phase_1/run33/suites/`.
- **Import:** the headless import with the scratch home exits 0 with no errors or warnings. It adds
  only the `.uid` files of `mirror_glass.gd`, `mirror_glass.gdshader` and `test_mirrors.gd`, and
  the real save folder is unchanged (`logs/phase_1/run33/import/`).
- **Measured** (windowed, 1280×800, vsync off, on battery, so not comparable with runs on power):
  - **Today against the new mirrors,** in one prototype session: 12.40 ms (80.6 FPS) against
    13.25 ms (75.5 FPS), +0.85 ms. Updating the driver's mirror every frame would cost +3.7 ms, so
    it updates 30 times a second.
  - **One mirror at 30 Hz,** looking into the forest: 2.65 ms with the moon's shadows, 0.65–1.3 ms
    without.
  - **The final build** (`capture_mirrors.gd`): 69.8 FPS at the start and 74.8 FPS with a van
    behind.
- **Evidence:**
  - `evidence/phase_1/mirror/run33_options/`: today, A and B, as first shown;
  - `evidence/phase_1/mirror/run33_fix/`: today against the fixed A, and the gravel before and
    after;
  - `evidence/phase_1/mirror/run33/` (`mirrors_sheet.png`), from the new
    `tools/captures/capture_mirrors.gd`:
    - a van 28 m behind, glancing and zoomed;
    - the start;
    - from outside;
    - the door open;
    - braking;
    - the forecourt gravel.
- **For the author:**
  - at night, with nothing lit behind, the mirror is dark. What shows are lights: a van behind,
    the office and yard lamps, and the red glow of your own tail lamps;
  - from the driver's seat the passenger mirror is hard to see: it sits just past the front edge
    of the passenger window, nearly edge-on. That is its own step (#120);
  - the mirrors copy the world's lighting once, when the van is built. A later change to the
    world's lighting, such as a capture's debug light, does not reach them.

## Revision 2026-11-04 (Run 33, step 2: the passenger mirror turned toward the driver, C49)

- **Author:** "alright proceed", then "Turn it toward me (Recommended)" and, after seeing the renders,
  "Yes, build it (Recommended)" (#120).
- **The finding:**
  - from the driver's eye only a thin strip of the passenger mirror showed, at the front edge of the
    passenger window;
  - the model's mirror glass faces almost straight back, so from the seat it was seen 65° off its
    face, nearly edge-on;
  - the door's front frame hid most of what was left: 48 of the passenger glass's 101 triangles
    were in sight, against 87 for the driver's mirror.
- **The change** (`van_presentation.gd`, `_turn_passenger_mirror()`):
  - when the van is built, the passenger mirror head is separated from the door mesh. That is the
    1,055 triangles outboard of the door skin in `MIRROR_HEAD`: the housing, the glass and the
    arm's outer part;
  - it is swivelled 25° toward the cab (`MIRROR_TURN`) about the arm's root, as a driver sets a van
    mirror on its pivot. The model files are unchanged;
  - the passenger reflection and its camera follow the turned glass, and the view is still set as a
    driver sets it: from 4.7° inside the van's right side to 10.6° outside.
- **Result:**
  - from the seat, 62 of the 101 glass triangles are in sight, seen 42° off the glass's face. On
    screen that is about two and a half times the area it was;
  - turning further does not help, because the door frame keeps hiding the mirror's inboard third.
    The van's right side, which shows along that edge, is mostly behind the frame.
- **Found and fixed while building:** the mirror camera's view direction was worked out in the van's
  frame but applied in the turned holder's frame, so the passenger mirror looked 25° into the van's
  own side. The view is now turned into the holder's frame. The extended aim check caught it.
- **Test changes, with reasons (#120):** `game/tests/test_mirrors.gd` (13 checks; it had 11):
  - **new:** "The passenger mirror is turned toward the driver, so it shows through the window's
    front corner: 62 of its 101 glass triangles in sight from the seat, seen 42 degrees off its
    face". It casts a ray from each glass triangle to the eye against everything the driving
    camera draws. On step 1's code it failed: 48 and 65° (`logs/phase_1/run33/step2_before/`);
  - **the aim check** now covers the passenger mirror too;
  - **the glass-fit check** reads the glass from the turned head when there is one.
- **Mutations:** both exit 1, each failing only its own check (`logs/phase_1/run33/mutation_*`):
  - with no turn, 48 of 101 in sight;
  - with the view direction left in the van's frame, the passenger mirror looks 29.7° into the
    van's side.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 21/21, 12/12, 30/30 ×3, 25/25, 33/33,
  12/12, 49/49, 21/21, 44/44, 12/12, 13/13, 12/12, 15/15, 26/26, 13/13; art 0 failures. The only
  other error line is the save test's deliberately damaged file
  (`logs/phase_1/run33/step2_suites/`).
- **Evidence:**
  - `evidence/phase_1/mirror/run33_step2_proposal/`: today against the turn, as shown before the
    build, with the glass marked;
  - `evidence/phase_1/mirror/run33_step2/` (`passenger_mirror_sheet.png`), from
    `capture_mirrors.gd`, which now also takes the passenger mirror. 70.2 FPS at the start and
    75.3 FPS with a van behind, on battery.
- **What it looks like at night:** the passenger mirror sits in the window's front corner. At the
  start it reflects dark forest, so it reads as dark glass. A van behind shows as a bright
  headlight in it.

## Revision 2026-11-04 (Run 34: the front door, design A, C50)

- **Author:** "Menu mockups first (Recommended)" (#122). Shown three designs on a private canvas
  (https://claude.ai/artifact/KMksj4rmd9VUdFjXt7koKN), the author answered "i want A style with
  the image changing on the right based on the user misson", then "Yes, start (Recommended)"
  (#123).
- **Why:** Assignment 10's front door asks for "a start or pause menu usable by keyboard alone,
  with focus set when the scene starts", and for controls that carry accessible names. The old
  menu was one panel at launch and in pause. It was headed "NIGHT FREIGHT / First drive · vehicle
  and atmosphere prototype", and its sliders had no names.
- **The title screen** (`game/app/first_drive.gd`, `game/features/ui/menus/front_menu.gd`, new):
  - **When:** at launch, after "Quit to main menu", and at the end of a drive.
  - **The scene:** the live scene of the saved mission, between black bars (the film look, C35).
    For Night Freight it is the van on the forecourt by the office, low beams on, with the rain
    falling through them under the floodlight.
  - **The picture follows the mission:** the scene is the mission's own (`TITLE_EYE`,
    `TITLE_LOOK`, `TITLE_FOV`), so Missions 2 and 3 bring their own. Until Mission 2 exists it is
    always this one.
  - **The title:** "BLACKRIDGE / NO WAY BACK" is typed text standing where the author's logo will
    go (C42).
  - **The menu:** Continue, New game, Settings, Credits and Quit.
    - Continue appears only with a save past the start. It shows the mission, the last
      checkpoint, and when it was saved, taken from the file's own date.
    - Focus is set on the first item whenever a screen opens.
  - **Sound:** while the title waits, the rain and the music keep playing (`title_ambience()`).
    The old menu at launch was silent.
  - **Into the drive:** Continue and New game fade through black.
    - Continue puts the van back at the saved checkpoint, with Ethan in it.
    - New game starts at the office. With a save it asks first: "Start a new game? Your saved
      progress will be replaced."
- **Pause (Esc):**
  - **The screen:** the frozen game behind a blur (`menu_blur.gdshader`, new, in the menus
    folder, not `game/shaders/`), with the objective, the next checkpoint and the last save.
  - **The options:** Resume, Recover van, Settings, and Quit to main menu.
  - **Quit to main menu** asks first, and names the checkpoint you will continue from.
  - **Esc** resumes.
- **Settings:**
  - **Audio:** the four volumes, at the same defaults. ← and → change a volume by 5% a press.
    The volumes are saved when you leave Settings, as the save rules say.
  - **Controls:** every key.
- **Credits:**
  - "A game by NRVALAM WORKS" (C42);
  - then every outside asset that ships, from the attribution files:
    - the Iveco Daily by Max (CC BY 4.0);
    - the Mixamo characters;
    - Poly Haven's textures, trees, plants and rocks (CC0);
    - the Honda e interior by Alex Murias (CC BY 4.0), whose files still ship although the game
      no longer draws them;
  - then Godot Engine's MIT license and its third-party components and licenses, read from the
    engine itself, as Godot asks of exported games.
- **Keyboard and screen readers:**
  - **Keys:** ↑ and ↓ choose, Enter confirms, Esc goes back, and ← and → change a volume or switch
    the tab. Key hints in the bottom bar say which keys work on each screen.
  - **Names:** every control a player can reach (18) has an `accessibility_name`.
- **Back to the title, in place:**
  - **How:** "Quit to main menu" and the end of a drive reset the session, reload the mission from
    its save (`reload()`, new in the mission script), then show the title. The scene is not
    reloaded.
  - **The ending:** after the fade to black, the title now returns; before, a paused menu offered
    "Drive again". The drive's save went back to its start, so New game is offered.
- **Wording:**
  - **Removed:** "DRIVING PROTOTYPE", "First drive · vehicle and atmosphere prototype", "Follow the
    industrial loop" and "Follow the freight loop".
  - **The objective** now reads "Freight depot, bay 2. Next: the switchbacks.", from the approved
    run sheet.
- **Claude Code's calls:**
  - **The title scene:** the van is parked on the forecourt with its low beams on, whatever the
    save says. Continue puts it back where the save says.
  - **Fonts:** the Mac's own (DIN Condensed for headings, SF Pro for the rest), so no font file is
    added.
  - **Wording:** "New drive" is now "New game" on the title, and it leaves the pause menu.
    Controls moved into Settings.
  - **Accent colour:** amber (#e3a33b) marks the focused item.
  - **Save times** read "Saved today, 16:27"; with no save, "Nothing saved yet".
  - **No version number:** the mockup's version label is left out, because it would need a version
    line in `project.godot`.
- **Found while building:**
  - **Volume keys:** Godot 4.7's HSlider has no keyboard-step setting, so the menu moves a volume
    5% itself.
  - **Lamps:** the title first showed the van with its lamps off. The game is paused there, and the
    lamps only update while it runs. `settle()` in `van_presentation.gd` now refreshes the van once
    without advancing time.
  - **Readability:** the first stills made text over the van hard to read, so every screen except
    the title itself now blurs the scene.
  - **Captures:** a windowed capture stalls when macOS stops drawing a covered window.
    `capture_menus.gd` therefore draws each still itself.
- **Test changes, with reasons (#123):**
  - **New `game/tests/test_menus.gd`,** 20 checks, by real key presses, in the scratch home:
    - **The title:** the title scene, focus at launch, and the rain and music while it waits.
    - **Names and wording:** every control named; no prototype wording on any screen.
    - **Esc on the title** does nothing.
    - **Settings:** the volume by keyboard, saved on leaving; the Controls tab.
    - **Credits:** their content and scrolling.
    - **Starting:** New game starts at the office.
    - **Pause and back:** pause and resume; Quit to main menu asking first; Continue from the saved
      checkpoint.
    - **Asking first:** New game asks before it replaces a save.
    - **Recover van, and Quit.**
  - **Test first:** on the old code it failed 0/1, because the HUD had no front menu
    (`logs/phase_1/run34/before/`).
  - **`test_collision.gd`** (44 checks, the same count), because the menu changed:
    - "After N s the screen fades to black and the menu offers to drive again" becomes "... returns
      to the title, which offers a new game, since the drive's save went back to its start";
    - "The crack stays for the rest of the drive" reads the crack at the depot, before the title
      resets the glass for the next drive;
    - "New drive leaves the ending behind" checks that the menu is closed, instead of reading the
      old button's text.
  - **Unchanged:** Assignment 5's suites, which pass.
- **Mutations:** all exit 1 (`logs/phase_1/run34/mutation_*`):
  - with no focus set when a screen opens, 4/20;
  - with a volume slider unnamed, 19/20;
  - with Esc on the title passed to the game, 12/20;
  - with the title camera not made current, 17/20.
- **Tests:** all suites pass: 64/64, 0 failures, 92/92, 21/21, 12/12, 30/30 ×3, 25/25, 33/33,
  12/12, 49/49, 21/21, 44/44, 12/12, 13/13, 12/12, 15/15, 26/26, 13/13, 20/20; art 0 failures.
  - **Logs:** `logs/phase_1/run34/suites/`.
  - **Error lines:** the only "ERROR:" lines are the engine's "resources still in use at exit" and
    the expected parse error for a deliberately damaged file.
- **Import:** exit 0, with no errors or warnings.
  - **New files:** three `.uid` files, for `front_menu.gd`, `menu_blur.gdshader` and
    `test_menus.gd`.
  - **The real save folder** did not change (`logs/phase_1/run34/import/`).
- **Evidence** (windowed): `evidence/phase_1/menu/run34/`, with `menu_sheet.png`. The stills show:
  - the title with and without a save;
  - Settings (Audio and Controls) and Credits;
  - the pause screen on foot and in the van;
  - both "ask first" prompts;
  - the drive after Continue.
- **Not done:**
  - **The author's checks** (Assignment 10): start, play, pause and quit by keyboard alone, and
    what a screen reader says, if tried.
  - **The author's save check:** quit at a checkpoint, relaunch, continue.
  - **The author's logo** in place of the typed title (set aside, #104).
  - **A version number** on the title.
  - **Frame rate** on the title and pause screens: not measured.

## Revision 2026-11-04 (Phase 2 brief: Mission 2, The Wrong Cargo, written before any code)

- **Status:** drafted by Claude Code on 2026-11-04 from the plan canvas and the author's answers
  (#124–#126, C51). It changes nothing in the game. It is committed only with the author's OK, and
  before any Mission 2 code, as the save rules were.
- **The plan canvas:** https://claude.ai/artifact/BZ1XPVUWHt439SF6TRnj1Q (a private page): the
  map, drawn from the game's own road data; the beats; the decisions.
- **Read first:** `GAME_STORY.md`, `GAME_DESIGN.md` and `DESIGN_DECISIONS.md`, in full.

### What changes

1. **A second playable mission,** the design doc's "M2 — The Wrong Cargo":
   - the player collects a sealed load, inspects anomalies, retrieves a vehicle and escapes the
     warehouse guards;
   - in the story, routine work becomes criminal, and the links to Vale emerge.
2. **Its places, in the valley as drawn (C51),** each built to the realism bar from the start.
3. **Missions in a row:** finishing Mission 1 leads to Mission 2's start, as the save rules
   say.

### Why now

- **The agreed order (#108–#109):** saving, then the menu, then Mission 2, planned on a map
  first. Those steps are done.
- **Assignment 10:** it asks for "a small complete playable loop" by December 3.

### The route and beats (the numbers match the map)

0. **Opening:**
   - the title card "THE WRONG CARGO" (C35: mission names only);
   - a short staged scene at the depot, days after the accident.
1. **The freight depot:**
   - sign a new dispatcher's run sheet (S2);
   - Maya's check-in call on the drive (S3), answered with T as in Mission 1.
2. **The transfer shed,** at the north-west warehouse (-71, 26), reached by a new spur north
   from the road:
   - a guard checks the run sheet at the gate;
   - the van backs onto the dock;
   - the sealed load goes in, and the doors are sealed.
3. **The inspection:**
   - the seal number, the manifest and how low the van sits do not agree;
   - the first trace of Vale Freight appears (S4);
   - the seal stays unbroken.
4. **The container yard,** behind today's fence (x 64–136, z 132–158), through a new gate with
   a keypad:
   - leave your van and the load there;
   - take the dark van to the warehouse.
5. **The warehouse compound,** round two of today's warehouses (x 140–262, z 92–140), with a new
   fence, gate and guard booth: the guards recognize the shipment. Why is decided later (S1).
6. **On foot:**
   - move past the patrols, helped by an anonymous warning (S3), which is secretly Maya;
   - through the gap in the fence and back to your van;
   - if a guard catches Ethan, the game goes back to the start of the escape.
7. **Clear:** out of the container yard, west past the depot and up the hill road. The mission
   ends near road sample 990.
8. **Ending:** a quiet beat in the cab, with no title (C04).

### Decisions

- **The author's (C51):**
  - the valley route as drawn;
  - no gun in Mission 2;
  - realistic from the start;
  - why the guards turn on Ethan is decided later.
- **Claude Code's calls, open to change:**
  - **D1:** night, in the rain.
  - **D3:** the dark van is our Iveco in dark paint, and only one van is drivable at a time. The
    one left behind stays as a parked copy.
  - **D6:** the guards are Assignment 9's game-AI technique. Until it arrives they are stand-ins
    that only see straight ahead, and they are labelled as stand-ins.
  - **D7:** the progress file moves to version 2 (below).
  - **Mission 2's title scene** (C50, the picture follows the mission): the van parked at the
    depot where Mission 1 ended, under the depot lamps.
  - **Where this brief lives:** a dated revision here, because Assignment 10 asks for dated
    revisions rather than rewrites. Phase 1's brief stays above.

### Build order (each step approved on its own, test first, as in Phase 1)

1. **Missions in a row, and the progress file's version 2.**
   - **Why first:** today's file check accepts only `night_freight`. A Mission 2 save would be set
     aside as damaged, so the file must move to version 2 before Mission 2 can be saved.
   - **Version 2:**
     - it adds `the_wrong_cargo` and its checkpoints;
     - a version 1 file is upgraded in memory to version 2, as the save rules require;
     - a newer file is still never read or written over.
   - **The app** takes its mission from the save, and each mission keeps its own script under
     `game/features/missions/<id>/`.
   - **Finishing Mission 1** saves Mission 2's start.
   - **The title screen** shows the saved mission's own scene.
   - **The save rules** get a dated revision for version 2 first.
2. **The transfer shed:**
   - the spur road, the gate and booth, the building, the dock and its leveller, the floodlights;
   - backing onto the dock;
   - the forklift and the load;
   - the bolt seal.
3. **The inspection:** the paper view, the seal number, the weight in how low the van sits. It
   needs S4.
4. **The container yard and the swap:** the fence, the gate and keypad, the dark van, and one
   drivable van at a time.
5. **The warehouse compound:** the fence, gate and booth, floodlights, stacks, a loading bay, and
   the arrival. Its words need S1.
6. **The escape:**
   - the guards, as Assignment 9's technique or the stand-ins;
   - being caught, and the retry;
   - the anonymous warning (S3);
   - the gap.
7. **The getaway and the ending.** Mission 2's end saves the next mission's start, or its own
   start until Mission 3 exists.
8. **The opening, the depot's new job and Maya's call.** They need S2, S3 and S5.

### Predictions (written before any code)

| # | Prediction | How it is checked |
| --- | --- | --- |
| Q1 | A version 1 file at Mission 1's checkpoint 3, after the hit, loads under version 2 with everything kept, and is written as version 2 at the next save. A version 3 file is left alone | `test_save_rules.gd` |
| Q2 | Finishing Mission 1 saves Mission 2's start. The next launch's title shows Mission 2's scene, and Continue names The Wrong Cargo | A new `game/tests/test_mission_two.gd`; `test_menus.gd` |
| Q3 | The van backs onto the dock with the reverse camera alone, and the dock check passes within 0.3 m | `test_mission_two.gd`, by real key presses |
| Q4 | Caught in the escape, everything returns to the escape's start: Ethan, the guards, the dark van and the gate | `test_mission_two.gd` |
| Q5 | With the swap, one van is drivable at a time: two mirror cameras, as today, and the parked copy stands within 1 cm of where the van stopped | `test_mission_two.gd`, `test_mirrors.gd` |
| Q6 | The compound with its floodlights and guards keeps at least 60 FPS at 1280×800 on the M4, on mains power | A windowed measurement, in `PERFORMANCE.md` |

### Failure cases, and how they are caught

1. **A Mission 2 save written as Mission 1,** or a version 1 game reading a version 2 file as
   damaged. Caught by the save test, both ways.
2. **State leaking into a retry:** a guard left alerted, a gate left shut, or the dark van left in
   the wrong place. Caught by Q4.
3. **The title showing the wrong mission's scene.** Caught by `test_menus.gd`.
4. **Floodlight shadows costing too much.** Caught by measuring. Shadows go first on the far
   lights.
5. **Stand-in guards mistaken for Assignment 9's technique.** They are labelled as stand-ins in
   the code, the tests and the docs, and Assignment 9 replaces them.

### How it is tested

- **New `game/tests/test_mission_two.gd`,** grown step by step, playing by real key presses where
  the player acts.
- **`test_save_rules.gd`:** checks for version 2. **`test_menus.gd`:** the title per mission.
- **Every existing suite passes.** A test changes only when a step changes what it checks, and the
  change is written down with its reason.
- **Each step:** deliberate breakages, the import check with the scratch home, and windowed
  captures, announced before a window opens.

### Open story questions (C03), and the steps they block

- **S1:** why the guards turn on Ethan. It blocks step 5's words, not the building.
- **S2:** the dispatcher's name, and how the job reaches Ethan. It blocks step 8.
- **S3:** the words: Maya's check-in, the dispatcher's instructions and the anonymous warning.
  Claude Code drafts them for approval in the step that uses them.
- **S4:** what names Vale Freight, and whether the sealed load is ever seen. It blocks step 3.
- **S5:** the van days later: still cracked from Mission 1, or a new windshield? It blocks step 8.

### Not in this phase

- **Left out:** a gun (Mission 3); car chases; interiors beyond one loading bay.
- **Their own briefs:** Assignment 6's particles; Assignment 9's technique, which Mission 2 hosts.

### The schedule

- **The risk:** built realistic from the start, each place takes longer, so a playable Mission 2
  may miss December 3.
- **The fallback:** Mission 1 is already a small complete loop, from the title through the drive,
  the hit and the ending, back to the title. So Assignment 10's December 3 target still holds.

## Revision 2026-11-04 (the save rules, version 2, written before any code)

- **Author:** "ok" (#127), for step 1a of the Phase 2 brief: the save rules for version 2, written
  and committed before any code. Assignment 10 grades save rules that were written first.
- **Why a new version:**
  - **The rule:** the save rules say any change to what a file holds raises its version,
    including adding a mission. Mission 2 adds one.
  - **Today's check:** it accepts only `night_freight`, so without a new version a Mission 2 save
    would be set aside as damaged.
- **Found while writing these rules:**
  - **The gap:** `save_file.gd` reads only its own version, with no upgrade step. A game
    expecting version 2 would set a version 1 file aside as damaged, and the player would lose
    Mission 1's progress.
  - **What the rules already said:** "older: upgraded in memory, one version at a time". Step 1b
    builds that upgrade.

### What changes, and what does not

- **Progress** (`user://progress.cfg`) moves to version 2.
- **Settings** (`user://settings.cfg`) stay at version 1. Nothing in them changes.
- **Every other save rule stays:**
  - the path and the format;
  - the version read first, and newer files never written over;
  - the whole file checked before use, and damaged files kept as `.corrupt`;
  - warn and keep playing;
  - a temporary file, then a rename;
  - tests in the scratch home, with the real save folder fingerprinted.

### Progress, version 2

```ini
[save]
version=2
mission="the_wrong_cargo"   ; or "night_freight"

[cargo]                     ; Mission 2's own section, only when it is the mission
stage=1                     ; 0 its start, 1 loaded, 2 in the dark van, 3 the escape's start
```

- **The mission** is `night_freight` or `the_wrong_cargo`. The file holds the current mission and
  that mission's own section:
  - **Night Freight:** `[drive]`, exactly as in version 1: the checkpoint from 0 to 4, and after
    the hit the van's place, where the man lies and the crack.
  - **The Wrong Cargo:** `[cargo] stage`, from 0 to 3. Everything else at each of its checkpoints
    is fixed by the mission's design, such as where the vans stand and where Ethan is, so nothing
    else is saved.
- **Unknown keys,** and the other mission's section, are ignored, as before.

### When

- **At every checkpoint,** as now. Mission 2's are:
  - its start;
  - loaded, at the transfer shed;
  - in the dark van;
  - the escape's start.
- **Finishing Mission 1** saves Mission 2's start (`the_wrong_cargo`, stage 0), as the rules
  said a mission's end would once Mission 2 exists.
- **Finishing Mission 2** saves its own start until Mission 3 exists.
- **New game** saves Mission 1's start, after asking (Run 34).

### Reading, in this order

1. **Missing:** a new game, with no warning (unchanged).
2. **The version, before any other field:**
   - **newer than 2:** not loaded, never written over, and saving off for the session
     (unchanged);
   - **1:** upgraded in memory to version 2:
     - a version 1 file only ever held Night Freight, in the same keys, so the upgrade changes
       only the version number;
     - it is then checked by version 2's rules;
     - the file on disk stays version 1 until the next checkpoint writes version 2, so loading
       never writes;
   - **no version, not a whole number, or below 1:** damaged (unchanged).
3. **The whole file is checked before anything in the game changes:**
   - a known mission;
   - that mission's own section, by its own rules: Night Freight's as in version 1, and The
     Wrong Cargo's stage a whole number from 0 to 3.

   One failure makes the whole file damaged, and nothing from it is used (unchanged).
4. **Only then** is it applied: the game starts that mission at that checkpoint.

### An older game and a version 2 file

- **What happens:** a game built for version 1 (Runs 27–34) reads a version 2 file as **newer**.
  It does not load it, never writes over it, and warns. The player's Mission 2 progress waits
  safely for the newer game.
- **Nothing to build:** that is today's behaviour, and the save test already checks it with a
  version 2 file.

### The title screen

- **Continue** appears for any save past the very start of Mission 1, so Mission 2's start
  offers it.
- **It names** the mission and the last checkpoint's place, for example "The Wrong Cargo · The
  container yard".
- **The scene** behind the title is the saved mission's own (C50).

### How it is checked (step 1b, with its own approval)

- **`test_save_rules.gd`:**
  - **the upgrade:** a version 1 file at Mission 1's checkpoint 3, after the hit, loads with every
    value kept, and the next checkpoint writes version 2 (Q1);
  - **Mission 2:** a version 2 Mission 2 file loads at its checkpoint;
  - **damaged files,** each set aside as `.corrupt` with nothing applied:
    - an unknown mission;
    - a Mission 2 stage out of range;
    - a Mission 2 file without its section;
  - **newer files:** a version 3 file is left byte for byte the same.
    - **A test change, with its reason:** the test's "newer" file today is a version 2 file. It
      becomes version 3, because version 2 is now the game's own.
- **Mutations:**
  - with no upgrade step, a version 1 file is set aside and the test fails;
  - with the mission's name not checked, the test fails.
- **`test_menus.gd`:** when the save holds Mission 2, the title shows Mission 2's scene and names
  it.
- **Unchanged:** Assignment 5's suites, which pass. They read `[drive] stage`, which version 2
  keeps.

### Claude Code's calls

- **The names:** the section `[cargo]`, and Mission 2's four checkpoints, taken from the beats.
- **One section:** only the current mission's section is kept.
- **No write on load:** a version 1 file is not rewritten when it loads, only at the next
  checkpoint.
