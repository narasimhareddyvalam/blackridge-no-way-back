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
