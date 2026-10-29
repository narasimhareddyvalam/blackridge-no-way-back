# TEST-REPORT — Assignment 5

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
| Remove `source_color` from the colour sampler | `test_materials.gd` | after the audit |

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
- Author to confirm: look at each image, and compare one capture with an OS screenshot.

## In play (HUMAN CHECK)

Author to do: drive normally, press L several times, and confirm the headlights, the LIGHTS
text and the switch click still work.

## Hint experiment (HUMAN CHECK)

Captures: `evidence/captures/hint_experiment_compatibility.png` and `_forward_plus.png`.

| Band (file value) | Predicted, `source_color` | Predicted, data | Compatibility, `source_color` | Compatibility, data | Forward+ comparison, `source_color` | Forward+ comparison, data |
| --- | --- | --- | --- | --- | --- | --- |
| 64 | 64 | 137 | 64 | 64 | 64 | 137 |
| 128 | 128 | 188 | 128 | 128 | 128 | 188 |
| 192 | 192 | 225 | 192 | 192 | 192 | 225 |

- A separate data-only texture gives the same split: 64/128/192 under Compatibility and
  137/188/225 under Forward+ (`evidence/captures/hint_diagnose_results.txt`).
- Author to explain in their own words, and to confirm by eye.

## Interface sweep (HUMAN CHECK)

Scripted captures of the windshield's `light_fog.tres`, one per uniform at minimum, default
and maximum: `evidence/captures/fog/sweep_<uniform>_<min|default|max>.png` (21 images, made
by `tools/captures/capture_fog.gd`).

Author to do: look at each set, write what changed, and note any setting that breaks the
look.

## One shader, two materials (HUMAN CHECK)

- **Side by side:** `evidence/captures/fog/side_by_side_world_fog_off.png` and
  `_world_fog_on.png`, with the windshield (light fog) and the driver's window (heavy fog)
  in one view.
- **Material edit:** at runtime, `light_fog` fog_amount went 0.25 → 1.0 while `heavy_fog`
  stayed 0.75 (`material_edit_light_fog_amount_1.0.png`).
- **Author to do:**
  - confirm by eye that only the windshield changed;
  - edit one line of `foggy_windshield.gdshader` in the editor, record that both windows
    change, then restore the line.

## Material wiring

- **Fresh cache:** `game/.godot` deleted, then a full headless reimport
  (`logs/import_fresh_cache.log`: 0 errors, 0 SHADER ERROR lines).
- **Materials test after the fresh cache:** `test_materials.gd` **76/76**, exit 0
  (`logs/test_materials_fresh_cache_60fps.log`).
- **Other suites on the same cache:** night dimming 30/30, regression 64/64, integration
  0 failures.
- **Real J press:** lowers the driver's window and its fog overlay by 0.880 m. The test
  measures this in the van's frame, because the van also settles onto the ground.
- **`source_color` mutation:** author to run.

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

Author to do: run `git status` after the first editor session, and explain any `.import`
diff.

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
