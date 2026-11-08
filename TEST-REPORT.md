# TEST-REPORT

Assignment 6 comes first. Assignment 5's report follows with its text unchanged (its graded copy
is at tag `a5`), and then the final project's saving checks.

# Assignment 6 — particle effects (2026-11-07)

| Field | Value |
| --- | --- |
| Source revision | `42772e1`, the build before tuning, for the sections from "Baseline" on; r1 (`1c8447b`) and the world changes committed after it, for "Since tuning"; the final SHA is recorded at submission |
| Godot | 4.7.2.stable.official.ed1daf0bf |
| Renderer | Forward+, Godot's desktop default (`game/project.godot` sets only the mobile method, `:135`); MetalFX upscaling at 75% on macOS |
| Machine and GPU | MacBook Air, Apple M4 and its GPU, macOS 27.2 |

Machine results come from `scripts/run-test.sh` logs in `logs/particles/`. A HUMAN CHECK row
needs the author's own observation in the running game. A headless run draws nothing and runs
no GPU particle process.

## Since tuning: r1 and the world changes, kept (2026-11-08)

The sections from "Baseline" on are for `42772e1`, the committed build before tuning. The author
kept revision r1 (`TUNING.md`) and the changes to the world (prompt log #150–#158) after playing
(#164). r1 is committed with its strips and the verdicts in `1c8447b`, and the world changes in
the commit after it; their patches are `tools/tuning/r1/r1.patch` and
`tools/tuning/world/lamps_and_rings.patch`. The F9 debug key is committed (`c5e307d`). The final
results are recorded again at the submitted commit.

| Check | Result | Logs |
| --- | --- | --- |
| Every earlier suite | The baseline's counts, exit 0; art 0 failures; the same with r1 alone, in a temporary worktree | `logs/particles/strips_163/SUMMARY.txt`; r1 alone: `logs/particles/r1_only_164/SUMMARY.txt` |
| Configuration | A1 451/451, A2 221/221, B1 364/364 (four scenes, the street lamps' own added), B2 44/44, exit 0 | the same |
| State | A1 27/27, A2 13/13, B1 13/13 (13 volumes; 12/12 with r1 alone, since the title check comes with the world changes), B2 10/10 (`amount` stays 300), exit 0 | the same |
| Effect A mutations, on the kept state | A1 Godot 3 rename on `BigDrops` (`initial_velocity_min` → `initial_velocity`): 450/451, exit 1, the minimum reading 0.0, while the state test passes 27/27. A1 `spread` 30 → 37: 450/451, exit 1. A2 Godot 3 rename on `RoofStreams`: 220/221, exit 1, state 13/13. A2 `RoofBeads` `spread` 24 → 30: 220/221, exit 1. Each scene was restored from git and checked clean | `logs/particles/mutations_final/` |
| Previews, headless at 30 fps | Every event on the same frame as before r1, except B1's hide: frame 109, 1.30 s after the stop, for 111 and 1.35 s, from r1's shorter lives. The brief's frame 110 is empty either way | `logs/particles/previews_headless_r1/` |
| Headless CPU price | The game with every effect off 0.459 ms; A1 −0.001, A2 −0.002, B1 −0.005, B2 +0.013 ms against it, while the rounds vary by up to 0.039 ms; the controls 0.002 and 0.003 ms. A1's case leaves out its passenger water, added later (#160); headless runs no GPU particles either way | `logs/particles/mutations_final/cost/cost_effects_60fps.log` |
| F9, the vsync debug key | In a window, vsync read on, then off after one F9, then on after two | Claude Code's scratch run |

## GPU price (windowed, measured by Claude Code at the author's request, #165)

The assignment's method is the Visual Profiler's GPU time, but Godot's GPU timer reads 0 on
Metal: the measuring script read `viewport_get_measured_render_time_gpu` too, and it was 0.000 in
every case. So each frame's GPU time came from Apple's Metal Performance HUD, which logs it
(`MTL_HUD_ENABLED=1 MTL_HUD_LOG_ENABLED=1`; Apple defines it from the GPU start and end times of
the frame's command buffers).

- **Conditions:** MacBook Air, Apple M4, macOS 27.2, on battery (100%), Low Power Mode off; the
  built-in Retina display at 60 Hz; the game's 1280×800 window, which is 2560×1600 pixels at
  2×, with MetalFX at 75%; vsync on.
- **Method** (`game/tests/gpu_price.gd`, `tools/tests/gpu_price.py`): each effect at its
  heaviest, in a view where it is on screen, since Godot runs no particles whose visibility box
  is off screen. Each effect keeps running while it is shown and hidden in alternating blocks of
  1 s (B2 2 s, since showing it restarts its 0.6 s ramp), the first 0.3 s (B2 0.8 s) of each left
  out. Its price is the mean, over the cycles, of a shown block's GPU time minus the next hidden
  block's, so a drift in the GPU's time over a minute cancels. The 95% interval comes from the
  cycles' spread.
- **A first design failed:** each case held 10 s in three rounds. With every effect off, the
  GPU's time drifted between rounds by more than every budget (20.5 to 25.8 ms a frame), and the
  HUD logs only while the game's window is in front, so some cases got no frames
  (`logs/particles/gpu_price/v1_rounds/NOTE.txt`).

| Effect | Heaviest state, view | Cycles | GPU price (ms) | 95% interval | Budget | Against it | Frames/s shown, hidden |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | two bursts with their passenger water and one spill's water, 1,052 particles; the driver's seat | 40 | −0.39 | −0.46 to −0.32 | 0.25 | within | 39.1, 39.4 |
| A2 | one burst, 264 particles; the driver's seat | 49 | 0.08 | −0.03 to 0.20 | 0.20 | within | 38.8, 39.6 |
| B1 | the 8 volumes nearest the B1 strip's view of the valley lamp, 48,050 particles, 3 of them in view | 24 | 0.67 | 0.61 to 0.72 | 0.70 | at its budget | 50.1, 50.0 |
| B2 | full throttle, 300 particles; behind the van | 24 | 1.11 | 1.02 to 1.20 | 0.30 | over, 3.7 times | 44.0, 45.3 |
| All four | | | 1.47 | 1.30 to 1.64 | 1.45 | at the combined budget | |

- **A1 reads below zero.** Its cost is under what this method resolves. A GPU's time for the same
  work also falls when its clock rises with load; that is Claude Code's explanation, not
  measured.
- **A2** pools two runs. The run with 40 cycles alone gives 0.19 (0.12 to 0.25), at its budget
  (`RESULT_a.txt`).
- **B1** is priced with 3 of its 8 volumes on screen; the five off screen cost nothing, so a view
  with more lamps in it would cost more.
- **B2 is over its budget:** its 300 puffs, up to 60 cm across, are drawn with the scatter
  shader close behind the van. The author keeps it as tuned and reports it (#167).
- **The frame itself** takes about 26 ms of GPU time from the driver's seat, and 20–23 ms at the
  lamp and behind the van, before any effect: above the 16.7 ms of a 60 FPS frame. The brief's
  13.25 ms baseline was measured before the world changes (#150–#158). How much of the difference
  they cause, and how much the Retina display's pixels, is unmeasured.
- **Frames a second,** from the HUD's present intervals with vsync on: the game runs below the
  display's 60 Hz, so vsync does not cap it. No vsync-off comparison was made; GPU time is the
  primary number.
- **Logs:** `logs/particles/gpu_price/` (`RESULT.txt` pools `run_all.log` and `run_a.log`).

## Baseline (earlier suites, pinned frame rate)

Every earlier suite gives the same counts at three points:
- before any Assignment 6 code: `logs/particles/baseline/SUMMARY.txt`;
- with the effects wired in (`0a76154`): `logs/particles/wired/SUMMARY.txt`;
- before tuning (`42772e1`): `logs/particles/suites_before_tuning/SUMMARY.txt`.

| Suite | FPS | Result, all three times |
| --- | --- | --- |
| `first_drive_regression.gd` | 60 | 64/64, exit 0 |
| `first_drive_integration.gd` | 60 | 0 failures, exit 0 |
| `test_materials.gd` | 60 | 92/92, exit 0 |
| `test_headlights.gd` | 60 | 21/21, exit 0 |
| `test_rain_physics.gd` | 60 | 12/12, exit 0 |
| `test_cockpit.gd` | 60 | 25/25, exit 0 |
| `test_ghat_road.gd` | 60 | 33/33, exit 0 |
| `test_wipers.gd` | 60 | 12/12, exit 0 |
| `test_on_foot.gd` | 60 | 49/49, exit 0 |
| `test_oncoming_van.gd` | 60 | 21/21, exit 0 |
| `test_collision.gd` | 60 | 44/44, exit 0 |
| `test_crossing.gd` | 60 | 12/12, exit 0 |
| `test_maya_call.gd` | 60 | 13/13, exit 0 |
| `test_hit_speeds.gd` | 60 | 12/12, exit 0 |
| `test_dash_screen.gd` | 60 | 15/15, exit 0 |
| `test_save_rules.gd` | 60 | 29/29, exit 0 |
| `test_mirrors.gd` | 60 | 13/13, exit 0 |
| `test_menus.gd` | 60 | 20/20, exit 0 |
| `test_mission_two.gd` | 60 | 7/7, exit 0 |
| `test_night_dimming.gd` | 30, 60, 144 | 30/30 at each, exit 0 |
| `tools/tests/check_first_drive_art.py` | — | 0 failures, exit 0 |

## Configuration (headless, `--fixed-fps 60`)

Each test reads back every setting the brief names, from the effect's scene, through
`game/tests/particle_readback.gd`: node, process material, draw material, quad, texture, and the
alpha and scale curves' points. Since revision 4 each also reads `billboard_keep_scale` on every
camera-facing material.

| Test | Effect | Result | Notes |
| --- | --- | --- | --- |
| `test_wiper_flick_config.gd` | A1 | 70/70, exit 0 | `BigDrops` and `FineSpray` |
| `test_roof_spill_config.gd` | A2 | 68/68, exit 0 | `RoofStreams` (with `transform_align`) and `RoofBeads` |
| `test_lamp_rain_config.gd` | B1 | 234/234, exit 0 | All three scenes. B1's feature, collision with splashes, is read: `collision_mode`, `collision_base_size`, the sub-emitter mode, amount and path, and each heightfield collider |
| `test_exhaust_vapour_config.gd` | B2 | 42/42, exit 0 | Turbulence and the render layer. B2's feature, `amount_ratio` driven by the throttle, is runtime: see State |

## Mutations

Each mutation was undone from Git or from a copy taken before it; each folder's `MUTATION.md`
has the edit.

| Mutation | Test | Result | Folder |
| --- | --- | --- | --- |
| A1: `initial_velocity_min` renamed to the Godot 3 `initial_velocity` | A1 config | 67/68, exit 1: the minimum reads 0.0, because 4.7.2 drops the float silently | `logs/particles/mutation_a1_godot3_name/` |
| A1: `spread` 28 → 35, brief unchanged | A1 config | 67/68, exit 1 | `logs/particles/mutation_a1_value_drift/` |
| A2: the same Godot 3 rename on `RoofStreams` | A2 config | 66/67, exit 1 | `logs/particles/mutation_a2_godot3_name/` |
| A2: `RoofBeads` `spread` 24 → 30 | A2 config | 66/67, exit 1 | `logs/particles/mutation_a2_value_drift/` |
| B2: `billboard_keep_scale` removed | B2 config | 41/42, exit 1 | `logs/particles/keep_scale/mutation_keep_scale_off/` |
| B1: hidden after the rain's life only, not its splashes' | B1 state | 11/12, exit 1 | `logs/particles/b1_settle/mutation_rain_life_only/` |

Under the two renames the state tests still pass (9/9, 11/11): only a configuration test catches
a value Godot 4 drops without an error.

## State (headless, `--fixed-fps 60`)

Each test drives the condition through the real game loop and real input (actions, real Esc
presses, real E presses, the van's own wipers, throttle and brake). None calls an effect's start
or stop.

| Test | Result | What it asserts |
| --- | --- | --- |
| `test_wiper_flick_state.gd` | 9/9, exit 0 | Nothing at load or with the wipers off. One flick per top turn and none at park, on slow and fast. Each starts at the blade tip, worst 0.0 mm off. The next top turn, 0.91 s later, starts a second burst while the first is alive: two events inside one lifetime. At most two alive and none missed. Freeing the van leaves live bursts to finish, then frees them |
| `test_roof_spill_state.gd` | 11/11, exit 0 | Real throttle and brake. Nothing below 8 m/s, on gentle braking, or from a held brake. One spill on a hard brake. None during the 20 s refill; one again after it. Ethan's hard brake at the hit counts. Freeing the van takes the spill with it (revision 3) |
| `test_lamp_rain_state.gd` | 12/12, exit 0 | A volume at every lamp (9). Only those within 65 m rain, already falling. Each stops within a tick of the camera passing 65 m, and hides once its drops and splashes are gone (1.35 s). Esc freezes and resumes without a restart. Hidden stops it; shown restarts it full. None on the hill road |
| `test_exhaust_vapour_state.gd` | 10/10, exit 0 | The on-foot start, the run sheet and boarding by real E presses start the engine. The plume waits 0.4 s, then ramps over 0.6 s to `amount_ratio` 0.15 at idle and 0.80 at full throttle with the real accelerate action; `amount` stays 96. Esc freezes it. Hidden stops it; shown ramps it back. New drive stops it |

## Previews and frame strips (fixture)

- **The previews:** `game/previews/`, one per effect on the shared `preview_fixture.gd`.
  - Each runs the real game at the brief's place, with fixed seeds on its own instances, and
    ignores real keys and clicks.
  - Headless at 30 fps, every variant puts its events on the brief's frames
    (`logs/particles/previews_headless/`):
    - A1: flicks on frames 10 and 37;
    - A2: a spill on 10 and an ignored second hard brake on 25;
    - B1: on at 10, off at 70, hidden at 111;
    - B2: ignition at 10, throttle from 40 to 80, engine off at 100.
- **The strips:** captured with `scripts/capture-strips.sh` by Claude Code at the author's
  request (#163; the handout has the student run them): 22 fixture strips, r0 in `2b9e327` and
  r1 in `1c8447b`, each round with the brief's variants. The readings, the comparisons and the
  verdicts are in `TUNING.md`.
- **Claude Code's own windowed checks** (renders in its scratch folder, not strips):
  - **Every effect draws where it should.** Drawn solid red for one run, each appears at the
    blade tip, the roof lip, the lamp and the tailpipe.
  - **With their real materials the effects could hardly be seen at night.** This became the
    tuning in `TUNING.md`.
  - **Two build faults, fixed before r0:** brief revisions 4 (`billboard_keep_scale`) and 5
    (the streak's width).
  - **`restart()` re-runs `preprocess`,** a question in `CLAUDE.md`. B1's volume appears full,
    top to ground, on frame 13 when restarted on frame 10. A few drops show on frame 10, none on
    11 and 12. It is the same whether the volume was hidden or shown before, so Godot 4.7.2
    applies the restart about three frames late. In play this happens 65 m from the lamp.
  - **A window takes the keyboard when it opens.** Typing meant for another window reached
    the game during one capture: an E and four Backspaces were logged. So the previews now
    ignore real input and keep only the actions they hold.

## Headless CPU price

`scripts/run-test.sh cost_effects.gd 60 300`, exit 0 (`logs/particles/cost/`). The chapter's
Example 09 script is not in this repository, so `game/tests/cost_effects.gd` was written from the
assignment's description. Each case is the wall time between frames over 240 frames after 60 to
warm up; the game's cases ran in three alternating rounds.

| Case | Mean ms | Rounds' means | State at the end |
| --- | --- | --- | --- |
| Empty scene, first (control) | 0.002 | 0.002 | — |
| Game, every effect off | 0.484 | 0.429–0.593 | no GPU emitter emitting |
| A1, two bursts alive | 0.469 | 0.425–0.551 | two bursts alive |
| A2, one burst alive | 0.454 | 0.433–0.474 | one burst alive |
| B1, eight lamp volumes | 0.466 | 0.428–0.542 | eight volumes raining |
| B2, full throttle | 0.509 | 0.426–0.559 | `amount_ratio` 0.80, `amount` 96 |
| Empty scene, last (control) | 0.003 | 0.003 | — |

- **The script measures the game, not itself:** the controls read 0.002 and 0.003 ms against
  the game's 0.484 ms.
- **Every effect reads the same as every effect off:** −0.031 to +0.024 ms, while the rounds vary
  by up to 0.165 ms. These cases should differ and do not, because headless runs no GPU particle
  process, so a GPU effect's CPU share is below the noise. The brief's headless predictions,
  0.02–0.06 ms, are below it too.
- **Godot's process and physics monitors are not used:** under a script main loop they read
  1028 ms and 0.350 ms in every case.
- **The GPU price is under "GPU price", measured windowed with Apple's Metal HUD.**

## Exit messages explained

| Line | Where | Explanation |
| --- | --- | --- |
| `ERROR: N RID allocations of type '...DummyShader' were leaked at exit.` | Every suite that loads an effect scene | An engine exit message from the headless (dummy) renderer. A probe reproduces it with two default `GPUParticles3D`, each with a default process material and a default draw pass, loaded from one scene file. The same pair built in code, or either one alone, does not print it (`logs/particles/leak_probe/RESULTS.txt`). It is printed after each test's result, at exit. |
| `ERROR: N resources still in use at exit` | Most suites | Before Assignment 6 too (`logs/particles/baseline/`). |
| `ERROR: ConfigFile parse error ... Expected value` | `test_save_rules.gd` | Its deliberately damaged save file. |
| `WARNING: N ObjectDB instances were leaked at exit` | Several suites | Before Assignment 6 too, from the audio streams. |

## Export

`game/export_presets.cfg` leaves out `previews/*` beside `tests/*`, `experiments/*` and the visual
benchmark. An `--export-pack` listing has 715 entries and none from `previews/`, `tests/` or
`experiments/`; the effects and their scripts are in it (`logs/particles/export_previews/`).

## HUMAN CHECKS (the author)

| Check | Evidence to collect | Status |
| --- | --- | --- |
| In play | A1 triggered by normal play many times, with rapid repeats on fast wipers. A2 on hard brakes and at the hit. B1 starting and stopping at lamps, paused and hidden. B2 at ignition, on the throttle and at switch-off. The size verdict at 1280×800, and the boundaries holding | The author's play, 2026-11-08 (#164): "i played and all look good proceed". The author's answer to Claude Code's checklist of these cases, 2026-11-08 (#168): "everything i asked for is delivered as it is." It answers the list as a whole, not each case |
| Against the background | Each effect on its darkest and brightest real stretch: A1 on the valley road and at the depot; A2 on the valley road and under the office floodlight; B1 between lamps and under the depot posts and floodlight; B2 on the valley road and in the floodlight and reversing lamps | The author's answer to Claude Code's checklist of these cases, 2026-11-08 (#168): "everything i asked for is delivered as it is." It answers the list as a whole, not each case |
| Edge of screen | A large GPU effect near the screen's edge does not pop out: B2's 60 m visibility box, B1's volumes | The author's answer to Claude Code's checklist of these cases, 2026-11-08 (#168): "everything i asked for is delivered as it is." It answers the list as a whole, not each case |
| Scene load | B1 on the first frames after load, already falling; B2 not before its ignition | The author's answer to Claude Code's checklist of these cases, 2026-11-08 (#168): "everything i asked for is delivered as it is." It answers the list as a whole, not each case |
| Claude against you | Each of Claude Code's strip readings beside the author's verdict, with at least one disagreement named, or none | In `TUNING.md`: the author's verdict after play (#164) keeps the two things Claude's readings faulted, A1's passenger line in the floodlight and A2's white streams. Asked why, the author answered (#168): "everything i asked for is delivered as it is." |
| GPU price | The Visual Profiler's GPU time with each effect off and at its heaviest, on the M4, an FPS comparison with vsync off if made, and the comparison with the brief's budgets | Measured by Claude Code at the author's request (#165), with Apple's Metal Performance HUD, since Godot's GPU timer reads 0 on Metal: "GPU price" above. B2 is over its budget. The author's own Visual Profiler reading is not recorded |

## The process shader (Step 6, the author)

_The author saves Godot's generated code for one process material as
`game/shaders/particles_generated.gdshader` and gives its line references and answers here._

# Assignment 5 — shaders, materials and the Godot Shading Language

| Field | Value |
| --- | --- |
| Source revision | `5669a40` (2026-10-29); final SHA recorded at submission |
| Godot | 4.7.2.stable.official.ed1daf0bf |
| Renderer | Compatibility (`gl_compatibility`, `game/project.godot:125`) |
| Machine | MacBook Air, Apple M4, macOS 26.6.2 |

Machine results come from `./scripts/run-test.sh` logs in `logs/` and from the capture
scripts in `tools/captures/`. A HUMAN CHECK row needs the author's own observation in the
editor or in a windowed run; rows marked "author to confirm" are not done yet. A headless
run draws nothing.

## Baseline (earlier suites, pinned frame rate)

| Suite | FPS | Before Assignment 5 (`2b6b251`) | After the driver and overlays (`2204b55`) |
| --- | --- | --- | --- |
| `first_drive_regression.gd` | 60 | 64/64 passed, exit 0 | 64/64 passed, exit 0 |
| `first_drive_integration.gd` | 60 | 29/29 passed, exit 0 | 29/29 passed, exit 0 |
| `check_first_drive_art.py` (Python, outside the wrapper) | n/a | 133/133 | not affected (no art files changed) |

Both Godot logs end with an engine "resources still in use at exit" error at shutdown. It
predates Assignment 5 and is not a SHADER or SCRIPT ERROR.

## Shaders parse

| Shader | Evidence |
| --- | --- |
| `night_cluster.gdshader` | `get_shader_uniform_list()` lists `night_amount` (float), `night_color` (Color), `night_brightness` (float): checks 1–4 of `test_night_dimming.gd`. The author's reimport log `logs/import_night_cluster.log` has 0 SHADER ERROR lines. |
| `foggy_windshield.gdshader` | `test_materials.gd` lists the Fog, Shape and Detail groups, 7 uniforms and 3 samplers with the right types. The source hints and declarations match CHANGE-BRIEF §5.4–5.5. Reimport log `logs/import_foggy_windshield.log` has 0 SHADER ERROR lines. |
| `hint_experiment.gdshader` | `test_materials.gd` lists `color_read`, `data_read` and `show_data`, and its source hints match CHANGE-BRIEF §4. |

## Driver (30, 60 and 144 fps)

`game/tests/test_night_dimming.gd`, 30 checks, through real L, Escape and R input
(`Input.parse_input_event`). A `process_priority` 1000 sampler records every frame.

| Check | 30 fps | 60 fps | 144 fps |
| --- | --- | --- | --- |
| Result | 30/30, exit 0 | 30/30, exit 0 | 30/30, exit 0 |
| Start value before the first frame | 1.0 | 1.0 | 1.0 |
| Off-fade 1 → 0 (spec 0.35 s ± 1 frame) | 11 frames, 0.3667 s | 21 frames, 0.3500 s | 51 frames, 0.3542 s |
| On-fade 0 → 1 (spec 0.25 s ± 1 frame) | 8 frames, 0.2667 s | 15 frames, 0.2500 s | 36 frames, 0.2500 s |
| Retrigger (reverse from current value) | rise 0.1333 s vs 0.1190 s | rise 0.1000 s vs 0.0952 s | rise 0.0833 s vs 0.0794 s |
| On-fade at `time_scale` 0.5, real time (spec 0.50 s) | 15 frames, 0.5000 s | 30 frames, 0.5000 s | 72 frames, 0.5000 s |

Every frame-rate run also showed:
- the value holds while paused;
- L while paused changes nothing;
- R recovery changes nothing;
- a second van keeps its own material and value;
- no frame changes faster than the fade-in rate.

The measured frame counts equal the author's CHANGE-BRIEF Q5 table.

## Mutations

| Mutation | Test | Exit status |
| --- | --- | --- |
| Delete one semicolon in the effect shader (line 4) | `test_night_dimming.gd` at 60 fps | **1**: 2 `SHADER ERROR: Expected a ';'` lines, uniform list empty, 25/30 (`logs/mutation_semicolon_60fps.log`) |
| Rename the driven uniform in the shader only (`night_amount` → `night_level`) | `test_night_dimming.gd` at 60 fps | **1**: no SHADER ERROR (still valid), but `night_amount` is missing from the uniform list and the declaration and colour-line checks fail, 27/30 (`logs/mutation_rename_60fps.log`) |
| Remove `source_color` from the colour sampler (`foggy_windshield.gdshader:26`) | `test_materials.gd` at 60 fps | **1**: the `fog_color` hints check fails (found `filter_linear, repeat_enable`), 75/76 (`logs/mutation_source_color_60fps.log`) |

## Controlled values (HUMAN CHECK)

Scripted in-engine captures from a real window, using `tools/captures/capture_night_cluster.gd`.
The driver is stopped, the value is set, and the cluster's own 640×256 SubViewport is read
after `frame_post_draw`. Images are in `evidence/captures/night_cluster_*.png`.

| `night_amount` | Background (10, 10): predicted → measured | Dial hub (155, 136): predicted → measured |
| --- | --- | --- |
| 0.0 | (8, 14, 18) → (8, 14, 18) | (135, 156, 148) → (135, 156, 148) |
| 0.5 | (6, 9, 10) → (6, 9, 10) | (105, 102, 82) → (105, 102, 82) |
| 1.0 | (4, 4, 2) → (4, 4, 2) | (74, 47, 16) → (74, 47, 16) |
| 2.0 (set from code) | not predicted → (0, 0, 0) | not predicted → (13, 0, 0) |

- The 2.0 capture differs from the 1.0 capture, so `hint_range` did not clamp a value set
  from code.
- **OS screenshot comparison:** Claude Code cropped the dashboard from the author's macOS
  screenshot (headlights on) and put it beside `cockpit_night_amount_0.0.png` and `_1.0.png`
  (`evidence/playtest/cluster_compare.png`). It matches the amber 1.0 capture, not the
  mint-white 0.0 capture.
- **Author's check (2026-10-29, as reported to Claude Code):** after watching the film
  preview, which shows these captures and the dashboard dimming in play, the author confirms
  the dimming "looks right".

## In play (HUMAN CHECK)

The author's playtest on 2026-10-29, as reported to Claude Code in answer to its checklist:
- **L:** the headlights turned off and on, the dashboard changed between dim amber and its
  normal mint-white, the LIGHTS text changed, and the switch click played.
- **J:** the driver's window went down, and its fog went down with it.
- **Screenshot:** the author's macOS screenshot with the headlights on, as pasted:
  `evidence/playtest/os_screenshot_cockpit_headlights_on.png`.

## Hint experiment (HUMAN CHECK)

Captures: `evidence/captures/hint_experiment_compatibility.png` and `_forward_plus.png`.

| Band (file value) | Predicted, `source_color` | Predicted, data | Compatibility, `source_color` | Compatibility, data | Forward+ comparison, `source_color` | Forward+ comparison, data |
| --- | --- | --- | --- | --- | --- | --- |
| 64 | 64 | 137 | 64 | 64 | 64 | 137 |
| 128 | 128 | 188 | 128 | 128 | 128 | 188 |
| 192 | 192 | 225 | 192 | 192 | 192 | 225 |

- A separate data-only texture gives the same split: 64/128/192 under Compatibility and
  137/188/225 under Forward+ (`evidence/captures/hint_diagnose_results.txt`).
- **The author's explanation, in their own words:** LANGUAGE-NOTES.md Q4 and FRICTIONAL.md
  (2026-10-29 testing notes).
- **4K re-capture for the film:** the same values on both renderers
  (`youtube/claude-liam-blackridge-gamedev/capture/hint_samples_4k.txt`).

## Interface sweep (HUMAN CHECK)

Scripted captures of the windshield's `light_fog.tres`, one per uniform at minimum, default
and maximum: `evidence/captures/fog/sweep_<uniform>_<min|default|max>.png` (21 images, made
by `tools/captures/capture_fog.gd`).

**Author's check (2026-10-29, as reported to Claude Code):** the author looked at the sweep
images and reports that they "look nice and how they are supposed to look".

**Measured by Claude Code** on the 4K re-capture made for the film (time frozen, wipers
parked):
- Files: `youtube/claude-liam-blackridge-gamedev/capture/sweep_*.png`, compared with
  `build/sweep_diff.py`. The measure is the share of pixels that changed by more than 6
  levels against the default frame.
- **fog_amount at max:** 8.12%; the pane clouds over.
- **clear_center at 0:** 0.80%; fog appears in the top-left corner.
- **fog_opacity, edge_softness, normal_strength, texture_scale, fog_tint:** 0.06% or less.
  At fog_amount 0.25 the fog band sits behind the window frame, so these barely show from
  the driver's view. Judging them needs a heavier base fog.

## One shader, two materials (HUMAN CHECK)

- **Side by side:** `evidence/captures/fog/side_by_side_world_fog_off.png` and
  `_world_fog_on.png`, with the windshield (light fog) and the driver's window (heavy fog)
  in one view.
- **Material edit:** at runtime, `light_fog` fog_amount went 0.25 → 1.0 while `heavy_fog`
  stayed 0.75 (`material_edit_light_fog_amount_1.0.png`).
- **Author's check (2026-10-29, as reported to Claude Code):** the author reports doing the
  shader-edit test in the editor and restoring the line, and says the results "look nice and
  how they are supposed to look". Git shows the shader file unchanged.
- **Scripted captures for the film** (`youtube/claude-liam-blackridge-gamedev/capture/`):
  - **Material edit** (light_fog fog_amount 0.25 → 1.0): 19.7% of the windshield region
    changes, and nothing on the driver's-window overlay.
  - **In-memory shader edit at the light default:** only the driver's window visibly changed
    (windshield 0.00%).
  - **A second take with light_fog's fog_amount raised to 1.0 first** (disclosed): both
    windows change, the windshield by 31.9% and the driver's window by 40.6%.
  - Files: `material_edit.mp4`, `shader_edit_visible.mp4`, CAPTURE.md.

## Material wiring

- **Fresh cache:** `game/.godot` deleted, then a full headless reimport
  (`logs/import_fresh_cache.log`: 0 errors, 0 SHADER ERROR lines).
- **Materials test after the fresh cache:** `test_materials.gd` **76/76**, exit 0
  (`logs/test_materials_fresh_cache_60fps.log`).
- **Other suites on the same cache:** night dimming 30/30, regression 64/64, integration
  0 failures.
- **Real J press:** lowers the driver's window and its fog overlay by 0.880 m. The test
  measures this in the van's frame, because the van also settles onto the ground.
- **`source_color` mutation:** run by the author. It exited 1, and a clean rerun after the
  restore gives 76/76 (see Mutations).

## Texture data

Curl ratio (`game/tests/normal_map_check.gd`, stride 4):

| Map | Read as GL | Read as DX |
| --- | --- | --- |
| Poly Haven `box_profile_metal_sheet_nor_gl_1k.png` (calibration, known good) | 0.5792 | 1.4208 |
| Poly Haven `box_profile_metal_sheet_nor_dx_1k.png` (calibration) | 1.4208 | 0.5792 |
| `fog_normal.png` (generated) | 0.0033 | 1.9967 |

- **Sign convention:** correct. The GL file is lower when read as GL, so no flip is needed.
- **Known-good drift:** the GL file drifts toward 1 because the panel is mostly flat.
- **Pair check:** the green channel is exactly inverted; red and blue are identical.
- **Pass threshold, from the known-good pair:** read as GL ≤ 0.5792 and lower than read as DX.

## Import settings

Set explicitly, then reimported:

| File | `compress/mode` | `compress/normal_map` | `mipmaps/generate` | `detect_3d/compress_to` |
| --- | --- | --- | --- | --- |
| fog textures | 0 | 1 for `fog_normal`, 2 for the others | true | 0 |
| hint PNG | 0 | 2 | false | 0 |

The first headless import had written normal_map=0 (Detect), mipmaps=false and
detect_3d/compress_to=1.

After the author's first editor session (2026-10-29), `git status` showed four changed
`.import` files. None of them is an Assignment 5 texture:
- `game/features/vehicles/freight_van/art/body_legends.png.import`
- `game/features/vehicles/freight_van/art/cabin_legends.png.import`
- `game/features/vehicles/freight_van/art/steering_legends.png.import`
- `game/features/environments/industrial_loop/art/crate_legends.png.import`

All four diffs are the same:
- `compress/mode` went from 0 (Lossless) to 2 (VRAM Compressed);
- `detect_3d/compress_to` went from 1 to 0 (Disabled);
- the imported file changed from `.ctex` to `.s3tc.ctex`, with `"vram_texture": true`.

These textures still had Godot's default Detect 3D setting. When the editor first used them
in a 3D material, it reimported them as VRAM Compressed and then turned detection off. That
is what Detect 3D does. Headless runs never trigger it, which is why the baseline import had
not changed them.

None of the fog textures changed, and neither did the hint PNG. Their `detect_3d/compress_to`
was already 0, which is the result the explicit import settings were meant to give.

The editor's change was kept and committed, so the next editor session leaves the tree
clean. After it, all five suites still pass at 60 fps (regression 64/64, integration
0 failures, materials 76/76, night dimming 30/30, art check 0 failures). The only changes in
the logs are the engine's leak counts at exit.

VRAM compression is lossy, so the legend text needs a look. In the author's playtest
screenshot, the legend text that shows ("B R" on the wheel hub, "AC" on the console) is
readable. That is Claude Code's reading of the screenshot. To undo the change, set those
four textures to Lossless with Detect 3D disabled.

## Inspect-and-revise cycle

Candidates, all observed:
1. `test_night_dimming.gd` first failed 1 check, because it counted a frame after the fade
   had finished. Fixed in `_first_at`.
2. Float rounding made the 60 fps fade land one frame late, so the driver now snaps within
   1e-6.
3. The Compatibility hint-experiment result differed from the Forward+ prediction, which led
   to the diagnostic run.
4. The first `test_materials.gd` run failed one check. The overlay seemed to drop 1.13 m on
   J, because the whole van settles 0.25 m onto the ground. The test now measures in the
   van's frame: 0.880 m.

## What no headless run can show

- Whether the dimmed cluster is readable or looks right.
- Whether the fog looks natural, and how it layers with the rain shader.
- Real-window colour output (covered only by the captures above).
- Performance on the M4.

## Agent session record

Session 1 (CLAUDE.md draft, `sessions/session-1.jsonl`):
- result `success`, 34 of 40 turns, `end_turn`;
- 4 Bash calls denied by the tool scope (a for-loop, `command -v`, two `git -C`);
- read-only `cat` and `grep` still ran, so the checksum comparison is the real guarantee.

The shader sha256 sums were unchanged after every agent step.

# Final project: saving (Assignment 10)

## Final project, 2026-11-03: saving (Assignment 10 persistence)

| Field | Value |
| --- | --- |
| Source | `develop`, Run 27; the save rules were committed first, as `301c250` |
| Godot | 4.7.2.stable.official.ed1daf0bf |
| Renderer | Forward+ |
| Machine | MacBook Air, Apple M4, macOS 26.6.2 |

### Tests isolated from the real save, verified on macOS

1. **Godot follows `HOME`.** Run with `HOME="$PWD/.scratch-home"`, a script printing
   `OS.get_user_data_dir()` gave
   `.scratch-home/Library/Application Support/Godot/app_userdata/Blackridge- No Way Back`
   (`logs/phase_1/run27/home_check/scratch_home.log`). The first check of
   `test_save_rules.gd` repeats this on every run.
2. **Before the change,** one run of `test_wipers.gd` through the old wrapper changed the real
   folder: Godot rotated its own logs there (`logs/phase_1/run27/before_isolation/`, the
   listings before and after).
3. **Every run now** goes through `scripts/run-test.sh`:
   - it sets `HOME` to `.scratch-home/`;
   - it fingerprints the real save folder (every file's path, size and time) before and after;
   - any difference fails the run with "REAL SAVE FOLDER CHANGED".

   No run reported it: not the baseline, the final suites, the mutations or the import.
4. **Saving is off unless a path is given.** A game that a test builds has no save paths:
   `test_save_rules.gd` checks that `user://` is unchanged after a checkpoint and a volume change.
   Only the scene Godot launches uses `user://progress.cfg` and `user://settings.cfg`. A headless
   launch of the real main scene, in the scratch home, set aside a damaged `progress.cfg` there
   (`logs/phase_1/run27/real_launch/`).

### The prediction (written in the save rules, before any code)

| Prediction | Result |
| --- | --- |
| The existing tests' runs save to their own scratch checkpoint files | Confirmed: every game test sets `checkpoint_path` to a file in the system's temporary folder |
| Today's runs touch the real folder: the HUD reads the real volumes, and Godot probably writes its log to `user://logs/` | Confirmed: one run rotated Godot's logs in the real folder. With the scratch home and saving off by default, no run changes it |

### `test_save_rules.gd` (26 checks)

| Rule | What is checked |
| --- | --- |
| Round trip | Continuing from a save made after the hit restores the checkpoint, the van's place, the body and the crack. It is saved again as version 1 with the mission's name, and quitting and loading again gives the same. Volumes are saved when the menu is left, load back, and are saved on quitting too |
| Missing | A new drive at the default volumes, with no warning and no file created |
| Corrupt | Text that is not a save; no version, a version in quotes, 1.5 or 0; nine single bad values among good ones; damaged settings. Nothing from the file is used, each is kept as `.corrupt`, and the game warns. A damaged file that cannot be moved stays where it is and is never saved over |
| Newer | Progress and settings from version 2 are not loaded or moved, and are byte-for-byte unchanged after a checkpoint and after leaving the menu. A newer file that appears after loading is not written over either |
| Unwritable | In a read-only folder, the game warns, the old file is unchanged, no `.tmp` is left, and the game plays on with recovery working |
| Isolation | `user://` is in the scratch home; a game built by a test writes nothing; launched as the game, it uses `user://` there |

Before the build: 4/26 (`logs/phase_1/run27/before/`). After: 26/26 (`logs/phase_1/run27/suites/`).

### Mutations

| Mutation | Result |
| --- | --- |
| The version read after the other fields | 24/26, exit 1 |
| A file applied before it is checked | 21/26, exit 1 |
| A newer file written over | 21/26, exit 1 |
| No save at the end of the drive (`test_collision.gd`) | 43/44, exit 1 |

### Human check (Assignment 10)

Author to confirm: drive to a checkpoint, quit, relaunch, continue, and say what happened.
