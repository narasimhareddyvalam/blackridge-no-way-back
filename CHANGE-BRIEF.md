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
