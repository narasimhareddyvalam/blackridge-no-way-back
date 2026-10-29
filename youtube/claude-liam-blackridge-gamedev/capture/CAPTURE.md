# CAPTURE.md — engine evidence for "Blackridge, Shaded"

Claude Code recorded this evidence on 2026-10-29 from an isolated copy of the game.
Nothing in the repository's `game/` was created, edited, renamed or deleted, and no
shader was saved; the integrity checks are at the end. Every clip and still is an
offline render at a fixed 60 frames per second. They show what the engine draws,
not how fast it draws it: **nothing here is a real-time frame-rate claim.**

## Outputs

| Take | File in `capture/` | Size | What it shows |
| --- | --- | --- | --- |
| A | `take_a_headlights.mp4` | 3840×2400, 60 fps, 26.000 s, 1560 frames | L handled at 3.000 s, 8.500 s, 12.000 s and 12.117 s |
| G | `cockpit_hero_4k.png` | 3840×2400 | take A clip frame 120 (t = 2.000 s): headlights on, amber cluster |
| B | `take_b_driver_window.mp4` | 3840×2400, 60 fps, 20.000 s, 1200 frames | J handled at 2.000 s (lowers) and 11.000 s (raises) |
| C | `fog_baseline.png`, `world_fog_off.png`, `world_fog_on.png` | 3840×2400 | wipers parked, tree paused, both overlays at their `.tres` values |
| C | `material_edit.mp4` | 3840×2400, 60 fps, 7.000 s, 420 frames | `light_fog` fog_amount 0.25 → 1.0 at 2.000 s |
| C | `shader_edit.mp4` | 3840×2400, 60 fps, 7.000 s, 420 frames | shared Shader line replaced in memory at 2.000 s |
| C | `material_edit_before.png`, `material_edit_after.png`, `shader_edit_before.png`, `shader_edit_after.png` | 3840×2400 | lossless copies of clip frames 119 and 120 |
| C2 | `shader_edit_visible.mp4`, `shader_edit_visible_before.png`, `shader_edit_visible_after.png` | 3840×2400, 60 fps, 7.000 s, 420 frames | the same line replacement, with `light_fog` fog_amount set to 1.0 before recording (added on request) |
| D | `sweep_<uniform>_<min/default/max>.png` (21) | 3840×2400 | `light_fog` interface sweep |
| E | `hint_compatibility_4k.png`, `hint_forward_plus_4k.png`, `hint_samples_4k.txt` | 3840×2160 | hint experiment under both renderers |
| F | `generated_vs_fog_4k.png` | 3840×2160 | generated shader against the fog shader, test scene |

Each take also has these files:

- `<take>-inputs.jsonl`: every injected input, handled signal, scripted change and check, with process frame, physics frame, clip frame, clip time, game time and wall clock.
- `<take>-frames.csv` for A, B, C, C2 and D: per-frame state.
- `logs/<take>.log`: the full engine output and the exact command.
- `logs/<take>-result.json`: every check.

The raw takes are in `raw/<clip>_raw_mjpeg.mov`. Hashes and sizes are in `manifest.json`.

## Engine and machine

- **Godot:** 4.7.2.stable.official.ed1daf0bf, `/Applications/Godot.app/Contents/MacOS/Godot`.
- **Compatibility**, the project's renderer (`project.godot:125`): "OpenGL API 4.1 Metal - 90.5 - Compatibility - Using Device: Apple - Apple M4".
- **Forward+**, used only for the take E comparison (`--rendering-method forward_plus`, never written to any project file): "Metal 4.0 - Forward+ - Using Device #0: Apple - Apple M4 (Apple9)".
- **Machine**, as reported by `system_profiler`: Apple M4 with an 8-core GPU, 16 GB, macOS 26.6.2.
  - Displays: built-in 2560×1664 Retina (main) and an LG Ultra HD 3840×2160 at 30 Hz.
  - The repository's docs name a MacBook Air M1 as the development machine. This capture machine reports an M4; it does not matter for offline renders.
- **Tools:** ffmpeg 8.0.1 with libx264. Python 3.14.7 with Pillow 12.3.0 and NumPy 2.5.3 for the pixel analysis.

## The isolated copy

**Location:** `/private/tmp/claude-501/-Users-narasimhareddyvalam-Desktop-Blackridge-No-Way-Back/59cc27ca-ea9d-4bb1-919c-75b671e4d5dd/scratchpad/blackridge-capture/`. It holds the contents of `game/`, copied with `cp -Rp`, including `.godot/`.

**Snapshot:**

- Repository commit `25c78737db54c6e9977cddb365fb7518b48833a4`; `git status --porcelain -- game` was empty.
- All 385 files outside `.godot/` were hashed, and the copy was byte-identical. The lists are in `logs/snapshot/repo_game_before.sha256` and `logs/snapshot/copy_game_initial.sha256`; the SHA-256 of the list file is `420ca4e6610f4c39d8b54e71ba5b3953130494532bd83223743e4bd318976524`.
- A headless `--import` on the copy exited 0 (`logs/snapshot/copy_headless_import.log`).

**Changes made in the copy only** (`logs/snapshot/copy_project_godot.diff`):

- `application/config/use_custom_user_dir=true` and `application/config/custom_user_dir_name="blackridge_capture_copy"`.
  - The copy's `user://` is `~/Library/Application Support/blackridge_capture_copy/`.
  - The real game's data in `~/Library/Application Support/Godot/app_userdata/Blackridge- No Way Back/` was not modified (checked by modification time).
  - No checkpoint was saved in any take: the van never reached a checkpoint.
- `[editor] movie_writer/mjpeg_quality=0.95`. This was added for Movie Maker, but Godot 4.7.2 has no such key (the binary knows `editor/movie_writer/video_quality`), so it had no effect. Movie Maker was only used for the two resolution probes.
- `capture_drivers/`: copies of `capture/scripts/*.gd`, refreshed by `run_take.sh` before every run.

After all takes, the copy's `shaders/` and `materials/` are still byte-identical to the repository's files (`logs/snapshot/copy_game_final.sha256`).

## Resolution: the probe, then a SubViewport rig

The probe used `scripts/probe_resolution.gd`; its logs are in `logs/probe/` and its output movies in `raw/probe/`:

```sh
Godot --path <copy> --script res://capture_drivers/probe_resolution.gd \
  --write-movie probe_3840x2400.avi --fixed-fps 60 --quit-after 120 --resolution 3840x2400
Godot --path <copy> --script res://capture_drivers/probe_resolution.gd \
  --write-movie probe_3840x2160_screen1.avi --fixed-fps 60 --quit-after 120 --resolution 3840x2160 --screen 1
```

**Result:** both runs printed "Movie Maker mode enabled, recording movie in 1280×800 @ 60 FPS". ffprobe reads 1280×800 MJPEG for both (`logs/probe/movie_maker_ffprobe.txt`).

- In 4.7.2, Movie Maker records at the project's window size override (1280×800), whatever `--resolution` requests.
- macOS also clamped the window:
  - 2940×1652 on the built-in display (16:10 content 2643×1652);
  - 3840×2036 on the 4K display (content 3257×2036).

So Movie Maker could not give frames at least 2160 pixels high. Following the brief, I used a SubViewport capture instead, and **nothing was upscaled**.

### The rig (`scripts/capture_rig.gd`)

- **Size.** The cockpit takes use a 3840×2400 SubViewport, exactly 3× the game's 16:10 base of 1280×800.
  - The SubViewport has `size_2d_override = 1280×800` with `size_2d_override_stretch = true`. This is what `window/stretch/mode="canvas_items"` does to the game window: the HUD is laid out at 1280×800 and drawn at full resolution.
  - Framing and layout match the 1280×800 window captures in `evidence/captures/`.
  - Other settings: `render_target_update_mode = UPDATE_ALWAYS`; the positional shadow atlas settings are copied from the project settings the root viewport uses (4096).
  - A 3840×2160 film frame is a crop of these frames (240 rows to remove), so no scaling is needed.
  - The test scenes in takes E and F are rendered at 3840×2160 directly.
- **Scene.** The real main scene, `res://app/first_drive.tscn`, is instanced inside the SubViewport, which sits in a SubViewportContainer.
  - The scene root gets `process_mode = PAUSABLE`, the same mode it inherits from the root window in the game.
  - The rig's own nodes are `ALWAYS`, so they keep running while the game pauses itself.
- **Input.** Events go `Input.parse_input_event(InputEventAction)` → root window → `SubViewportContainer` → `SubViewport.push_input()` → the game's own `_unhandled_input()` handlers.
  - Action names from `project.godot`: `pause` (Escape), `headlights` (L), `window_left` (J) and `wipers` (V). The brief said `left_window`, but that is the variable in `freight_van.gd`; the action is `window_left`.
  - Each tap is a press event, then a release event on the next frame, as in `tools/tests/first_drive_integration.gd`.
  - Godot buffers parsed input and dispatches it at the start of the next iteration, so a press injected on frame k is handled on frame k + 1. The logs record both the injection and the handling, through the van's own `switch_operated` and `window_operated` signals.
- **Starting the drive.** `FreightVan` ignores input until `occupied` and `input_enabled` are both true (`freight_van.gd:112`), and the game starts paused at its menu with `input_enabled` false.
  - Every cockpit take begins with a real Escape press: injected on frame 2, handled on frame 3 by the HUD, the same path as "Begin / continue drive". It unpauses the tree, hides the menu and enables input.
  - No state is set directly on the van.
- **Settling.** Physics settles before anything is recorded. The van drops 0.2448 m onto the ground in its first frames, and recording or freezing starts only after its height has been stable for 60 frames.
- **Stray input.** An `InputGate` node blocks every event that is not an InputEventAction from the rig (device 4242), so a physical mouse, trackpad or key cannot reach the game.
  - Blocked events are counted in each result: C had 73 mouse motions; D had 93 mouse motions and 6 pan gestures; A, B, C2, E and F had none. The aborted first run of C2 had 2.
  - The polled driving actions (`accelerate`, `brake`, `steer_left`, `steer_right`, `handbrake`) are checked every frame. None was held, and the van moved 0.000000 m in every take.
- **Frames.** After each `RenderingServer.frame_post_draw`, the rig reads `SubViewport.get_texture().get_image()` and saves it: JPEG at quality 0.95 for clip frames, PNG for stills.
  - A still requested on frame k shows that frame's state. In the self-test, a change made on frame 236 appears in the frame 236 still (`logs/probe/rig_selftest_pixel_diffs.txt`).
- **Offline render.** Every run uses `--fixed-fps 60`: every frame advances exactly 1/60 s of game time, with one physics tick per frame at 60 ticks/s, however long saving takes. This is not a real-time measurement.
- **Audio.** `--audio-driver Dummy`: no sound was played or recorded, and the clips have no audio stream.
- **Revisions.** Each revision only adds safeguards; none changes how a drawn frame is made.
  - Takes A and B were recorded with `scripts/history/capture_rig.rev1_takes_A_B.gd` and `scripts/history/run_take.rev1_takes_A_B.sh`.
  - Take C (second run), D, E and F used `scripts/history/capture_rig.rev2_takes_C_D_E_F.gd` and the current `run_take.sh`, which adds `--always-on-top`.
  - Take C2 used the current `capture_rig.gd`.
  - The safeguards: fail fast when a recording frame is not drawn; log changes to `DisplayServer.window_can_draw()`; ignore a duplicate draw; and an opt-in forced draw for frozen takes. C2 armed the forced draw, and it was never needed (0 forced draws).

### Encoding (`scripts/pack_and_encode.sh` and `scripts/verify_clip.py`)

1. **Pack.** The JPEG frames go into `raw/<clip>_raw_mjpeg.mov` by stream copy. framemd5 confirms every packet is byte-identical to its JPEG file.
2. **Encode** the MP4:

   ```sh
   ffmpeg -i raw/<clip>_raw_mjpeg.mov -vf "scale=in_color_matrix=bt601:in_range=full:flags=accurate_rnd+full_chroma_int,format=rgb24,scale=out_color_matrix=bt709:out_range=tv:flags=accurate_rnd+full_chroma_int,format=yuv420p,setparams=color_primaries=bt709:color_trc=bt709:colorspace=bt709:range=tv" -c:v libx264 -crf 14 -preset slow -pix_fmt yuv420p -colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv -r 60 -an -movflags +faststart <clip>.mp4
   ```

   JPEG stores BT.601 full-range colour, so the chain converts to RGB and then to BT.709 limited range explicitly. Otherwise the clip would be decoded with the wrong colour matrix.
   - **Exception:** take A was encoded before `setparams` was added (`scripts/history/pack_and_encode.rev1_take_A.sh`). Its stream is tagged matrix bt709 and range tv, but primaries and transfer read "unknown"; its pixels decode correctly.
   - I did not re-encode it, because the reel build (`build/evidence.py`) was already using `take_a_headlights.mp4`.
3. **Verify.** Checks: frame count, frame rate 60/1, size, no audio stream. Then the decoded MP4 frames are compared with their source JPEGs at the event frames: mean absolute difference 0.476–0.619 levels, 99.9th percentile ≤ 6 (`logs/verify_*.json`, `logs/encode_*.log`).
   - Only after that was the JPEG folder removed; its data is in the `.mov`.

## Takes A and B: cockpit, van stationary, real presses

### Take A: headlights and dashboard dimming

**Files:** `scripts/take_a_headlights.gd`, `take_a_headlights-inputs.jsonl`, `take_a_headlights-frames.csv`.

**Command:**

```sh
Godot --path <copy> --fixed-fps 60 --audio-driver Dummy --quit-after 2400 \
  --script res://capture_drivers/take_a_headlights.gd -- <reel>/capture
```

`--quit-after` is a safety cap; the driver quits itself. `run_take.sh` fails unless the driver wrote a passing result.

**Timeline:**

- Clip frame 0 is process frame 180, 177 frames after the drive began.
- L presses are handled on clip frames 180, 510, 720 and 727, which are process frames 360, 690, 900 and 907 (t = 3.000, 8.500, 12.000 and 12.117 s).
- 12.12 s is not on a 60 fps frame boundary, so the second tap of the double tap uses the nearest frame, 727. The taps are 7 frames (0.117 s) apart.

**Checks** (20/20 passed): measured from `NightDimming.night_amount`, which equals the cluster ShaderMaterial's `night_amount` on every frame.

- **Off-fade 1 → 0:** 21 frames = 0.3500 s, clip frames 180–200.
- **On-fade 0 → 1:** 15 frames = 0.2500 s, clip frames 510–524.
- **Double tap:** the value fades for 7 frames to 0.666667 (expected 1 − 7/21), then rises by exactly one fade-in step (+0.066667). It reaches 1.0 at frame 731, after 5 frames = 0.0833 s = (1 − 0.6667) × 0.25. It turns around from its current value, with no jump.
- **Largest per-frame change:** 0.066667, one fade-in step.
- **State:** headlights on and night_amount 1.0 before the first press and after the reversal.

**What I saw** in the decoded MP4 frames:

- At 2.833 s the cluster is amber and the road and wall are lit.
- At 3.000 s the headlights go out and the cluster starts to fade; it is mint-white by 3.333 s.
- From 8.500 s it turns amber again, fully at 8.733 s.
- At 12.0–12.183 s it lightens slightly (to 0.667) and returns to amber.
- The wipers keep sweeping, as they do by default.

### Take G: hero still

`cockpit_hero_4k.png` is the take A render of clip frame 120 (t = 2.000 s, before the first press), saved losslessly. It shows headlights on and the cluster at night_amount 1.0.

### Take B: driver's window

**Files:** `scripts/take_b_driver_window.gd`, `take_b_driver_window-inputs.jsonl`, `take_b_driver_window-frames.csv`.

**Command:** the same as take A, with `--quit-after 2000` and the take B driver.

**Timeline:**

- Clip frame 0 is process frame 180.
- J presses are handled on clip frames 120 and 660 (process frames 300 and 840; t = 2.000 and 11.000 s).

**Checks** (15/15 passed). Positions are in the van's own frame (`FreightVan.to_local`):

- The pane starts at y = 2.1200 m and starts moving on the J frame.
- It is fully open at clip frame 239 (3.983 s), at y = 1.2400 m: a drop of 0.8800 m.
- The heavy-fog overlay, a child of the pane, drops the same 0.8800 m. Its offset from the pane never changes (maximum change 0.0000000 m).
- The window stays open until the second J press, is closed again at clip frame 779 (12.983 s), and stays closed to the end.

**What I saw:**

- At 3.0 s the falling top edge of the glass and its fog crosses the middle of the window.
- At 3.98–10.0 s the opening is clear.
- At 12.0 s the glass and fog are coming back up, and from 12.98 s the window is closed again.

The view is the default forward cockpit view; I did not turn the camera. The driver's window is the left quarter of the frame.

## Takes C, C2 and D: parked, paused, frozen

### Setup (`scripts/fog_take.gd`)

1. **Start and settle.** The drive begins with the real Escape press, and the van settles.
2. **Park the wipers.** `wiper_setting` starts at 1 (low; `freight_van.gd:24`). Two real V presses, handled on frames 151 and 161, cycle it from 1 to 2 to 0.
3. **Wait for parking.** The driver waits until `wiper_angle` is exactly the parked value −0.9 for 10 frames and the van has settled.
4. **Pause and freeze on frame 187.** At that moment the windshield wetness is 0.234; it rises while the wipers are off and is held from then on.
   - The driver sets `get_tree().paused = true`.
   - In the same frame it also sets `Engine.time_scale = 0.0`, at runtime only. Pausing the tree stops physics and `_process`, but not shader `TIME`, and `windshield.gdshader` (drop wobble) and `wet_asphalt.gdshader` (ripples) keep animating.
   - The self-test measured this at 3840×2400: paused at time_scale 1.0, 57,594 pixels changed in 1 s; at time_scale 0.0, none did.
5. **Masks.** Both overlay quads are projected to screen polygons (`logs/<take>-overlay-masks.json`). The polygons have no occlusion removed, so they are supersets.

### Take C: one shader, two materials

**Files:** `scripts/take_c_one_shader_two_materials.gd`, `take_c_one_shader_two_materials-inputs.jsonl` and `-frames.csv`.

**Checks:** 36/36 passed, plus `scripts/analyze_fog.py` → `logs/analysis_take_c.json`.

**Objects:**

| Object | Instance id |
| --- | --- |
| `light_fog.tres` (on the windshield overlay) | −9223371997461871011 |
| `heavy_fog.tres` (on the driver-window overlay) | −9223371997226989990 |
| The one Shader both materials use, `res://shaders/foggy_windshield.gdshader` | −9223371998619498935 (`light.shader == heavy.shader`) |

**Stills:**

- `fog_baseline.png`, process frame 189.
- `world_fog_off.png`, frame 191: `WorldEnvironment.environment.fog_enabled = false` at runtime only, never saved. 7,339,347 pixels differ from the baseline.
- `world_fog_on.png`, frame 193, with world fog back on. It is pixel-identical to `fog_baseline.png` (0 pixels differ): the same state, and nothing moved.

**`material_edit.mp4`** (process frames 197–616):

- At clip frame 120, `light_fog.set_shader_parameter("fog_amount", 1.0)`, runtime only.
- 1,737,239 pixels changed: 1,729,708 inside the windshield mask only, 7,531 where the two masks overlap, **0 inside the driver-window mask only, 0 outside both**.
- `heavy_fog` keeps fog_amount 0.75 on every frame.
- Afterwards `light_fog` is restored to its `.tres` values.

**`shader_edit.mp4`** (process frames 627–1046):

- At clip frame 120 the loaded Shader resource's `code` is changed in memory. Exactly one occurrence is replaced:
  - original line: `ALBEDO = color_sample * fog_tint.rgb;` (line 59 of the file, indented with one tab);
  - replacement: `ALBEDO = vec3(1.0, 0.35, 0.2);`.
- The shader still compiles (10 uniforms listed). The code is restored after the clip.
- The file on disk is unchanged, checked against its own contents before and after; there was no `ResourceSaver` call.

**Result of the shader edit:** the driver's window turns clearly warm red: 1,225,727 pixels inside its mask, 54.90% of the rectangle x 0–1250, y 350–1500. On the windshield the change is tiny: 0.03% of the rectangle x 1300–3840, y 0–1377 changed at all, 0.00% by more than 6 levels.

The reason is that ALBEDO only shows where ALPHA > 0. At fog_amount 0.25 the windshield's fog lies in its outer edge band, which is mostly off-screen or behind the A-pillar and dashboard. Take C2 was added for that reason.

**Static check:** inside each clip, all frames before the edit are byte-identical JPEGs, and so are all frames after it.

### Take C2: shader edit with the windshield fog visible

This take was requested by the coordinator.

**Files:** `scripts/take_c2_shader_edit_visible.gd`, `take_c2_shader_edit_visible-inputs.jsonl` and `-frames.csv`.

**Checks:** 25/25 passed, plus `scripts/measure_regions.py` → `logs/region_change_shares.json`.

**Steps:**

1. The same setup as take C, frozen on frame 187.
2. **Before recording**, on frame 189, a disclosed visibility change: `light_fog` fog_amount 0.25 → 1.0, at runtime only. `heavy_fog` is untouched.
3. The clip runs on process frames 191–610: 2 s baseline, the same in-memory line replacement at clip frame 120, then 5 s hold.
4. After the clip, the code is restored and `light_fog` goes back to its `.tres` values (fog_amount 0.25).

The checks confirm the following:

- There is still one shared Shader object and two different materials (same ids as take C).
- `heavy_fog` was unchanged on every recorded frame.
- The file on disk is unchanged.
- Both the code and the values were restored.

**Measured change**, between `shader_edit_visible_before.png` and `_after.png` (clip frames 119 and 120):

| Pair | Windshield, x 1300–3840, y 0–1377: >0 / >6 levels | Driver window, x 0–1250, y 350–1500: >0 / >6 levels |
| --- | --- | --- |
| C2 shader edit (light_fog 1.0) | 46.25% / 31.87% (max 37 levels) | 56.06% / 40.58% (max 43) |
| C shader edit (`.tres` values) | 0.03% / 0.00% (max 1) | 54.90% / 37.66% (max 43) |
| C material edit | 45.74% / 19.66% (max 34) | 3.34% / 1.04% (max 27) |

- The rectangles are numpy slices `[0:1377, 1300:3840]` and `[350:1500, 0:1250]`. A pixel counts as changed when its largest per-channel difference exceeds the threshold.
- The driver-window rectangle is not purely the driver's window: 13% of it lies inside the windshield overlay's mask, near the A-pillar.
- All 48,048 pixels the material edit changed inside that rectangle are windshield pixels: 0 lie in the driver-window overlay's own mask.
- Across C2's whole frame, 1,748,387 changed pixels lie in the windshield mask only, 1,225,727 in the driver-window mask only, 16,003 in the overlap, and 0 outside both.

**What I saw:** from frame 120 the windshield shows warm red-brown cloud patches, and the driver's window turns warm red. Before that, the windshield shows the thicker light fog that fog_amount 1.0 gives.

### Take D: interface sweep

**Files:** `scripts/take_d_interface_sweep.gd`, `take_d_interface_sweep-inputs.jsonl` and `-frames.csv`.

**Checks:** 54/54 passed, plus `logs/analysis_take_d.json`.

**Method:**

- The setup is the same as take C, with world fog on, the game's own state. The earlier 1280×800 sweep in `evidence/captures/fog/` used world fog off.
- One `light_fog` uniform changes at a time; the others stay at their `.tres` values. Each value is set on frame k, captured on frame k + 1, and restored on frame k + 2.

**Ranges.** The six float ranges are the shader's own `hint_range` bounds in `game/shaders/foggy_windshield.gdshader`. `fog_tint` has no `hint_range`, so its extremes are a choice.

| Uniform (line) | min | default (`light_fog.tres`) | max | Where the range comes from |
| --- | --- | --- | --- | --- |
| fog_amount (7) | 0.0 | 0.25 | 1.0 | `hint_range(0.0, 1.0)` |
| fog_opacity (8) | 0.0 | 0.45 | 1.0 | `hint_range(0.0, 1.0)` |
| fog_tint (9) | Color(0, 0, 0, 1) | Color(0.82, 0.87, 0.9, 1) | Color(1, 1, 1, 1) | no `hint_range`; it is `source_color`; black and white are the chosen extremes |
| clear_center (14) | 0.0 | 0.65 | 0.9 | `hint_range(0.0, 0.9)` |
| edge_softness (15) | 0.01 | 0.2 | 0.5 | `hint_range(0.01, 0.5)` |
| normal_strength (20) | 0.0 | 0.5 | 2.0 | `hint_range(0.0, 2.0)` |
| texture_scale (21) | 0.5 | 1.0 | 4.0 | `hint_range(0.5, 4.0)` |

**Results:**

- The seven "default" stills are pixel-identical to each other and to take C's `fog_baseline.png`, which was rendered in a separate run. They are in fact byte-identical PNG files.
- Likewise, `material_edit_after.png` (C), `shader_edit_visible_before.png` (C2) and `sweep_fog_amount_max.png` (D) are byte-identical: all three show `light_fog` at fog_amount 1.0. The hashes are in `manifest.json`.
- Every min and max still differs from the default only inside the windshield mask: 0 pixels change in the driver-window mask or outside both masks.

**What I saw:** at this view, most uniforms change very little. The changed pixels per still, out of 9,216,000:

| Uniform | min | max |
| --- | --- | --- |
| fog_amount | 43,922 | 1,737,239 |
| fog_opacity | 43,922 | 50,659 |
| clear_center | 420,779 | 43,178 |
| edge_softness | 42,048 | 107,360 |
| normal_strength | 2,832 | 6,340 |
| texture_scale | 44,042 | 40,913 |
| fog_tint | 61,127 | 34,968 |

- Only fog_amount max, clear_center min and, less clearly, edge_softness max are obvious at full-frame size.
- The rest show only in a thin strip by the left A-pillar. At the defaults, the windshield fog sits in the glass's outer edge band.

## Take E: hint experiment, two renderers

**Files:** `scripts/take_e_hint.gd`, `take_e_hint_<renderer>-inputs.jsonl`, `logs/hint_samples_<renderer>.txt`, combined in `hint_samples_4k.txt`.

**Scene:** `res://experiments/hint_experiment/hint_experiment.tscn`, unchanged, at a native 3840×2160 in the rig.

**Commands:** the project's own renderer, then the same command with `--rendering-method forward_plus`.

**Sampling:** the centre pixel of each band, at quad-local x = −0.5, 0 and 0.5, projected with the scene's camera. Each 9×9 neighbourhood was uniform.

| Renderer | with `source_color` (AsColor) | without, read as data (AsData) |
| --- | --- | --- |
| Compatibility (gl_compatibility, OpenGL 4.1 Metal) | 64 / 128 / 192 | 64 / 128 / 192 |
| Forward+ (Metal) | 64 / 128 / 192 | 137 / 188 / 225 |

These match the earlier 1280×800 measurements exactly. Forward+ is a comparison run only; the game ships Compatibility.

## Take F: generated shader against the fog shader

**Files:** `scripts/take_f_generated_vs_fog.gd`; the full parameter record is in `logs/generated_vs_fog_parameters.json`.

The test scene is built in code by the driver. It is not saved and is not part of the game.

**Scene:**

- **Environment:** BG_COLOR Color(0.03, 0.03, 0.035); ambient AMBIENT_SOURCE_COLOR Color(1, 1, 1) at energy 0.25; tonemap Linear at exposure 1.0; glow and fog off.
- **Light:** one DirectionalLight3D, rotation_degrees (−35, −30, 0), Color(1, 1, 1), energy 1.0, no shadows.
- **Camera:** perspective, fov 40° (vertical), at (0, 0, 3.2), looking down −Z.
- **Backdrop:** a QuadMesh 8 × 4.5 at z = −1.5. Its material is an unshaded StandardMaterial3D with nearest filtering and a generated 1600×900 diagonal-stripe image (48 px black / 48 px white). It is unshaded so its contrast does not depend on the light.
- **Quads:** two upright QuadMeshes, 1.2 × 1.5, at x = −0.75 and x = +0.75, facing the camera.

**Left quad:** a ShaderMaterial with `res://shaders/standard_generated.gdshader`, the file unchanged.

- Set explicitly:
  - albedo Color(1, 1, 1, 1);
  - texture_albedo `res://assets/textures/windshield/fog_color.png`;
  - texture_normal `res://assets/textures/windshield/fog_normal.png`;
  - roughness 1.0, metallic 0.0, specular 0.5, normal_scale 1.0;
  - uv1_scale Vector3(1, 1, 1), uv1_offset Vector3(0, 0, 0);
  - metallic_texture_channel Vector4(1, 0, 0, 0).
- Left unset, as asked:
  - texture_metallic (its `hint_default_white` gives white);
  - texture_roughness (`hint_roughness_r`);
  - albedo_texture_size, point_size, uv2_scale and uv2_offset, which the fragment does not use.

**Right quad:** `res://materials/windshield/light_fog.tres` with fog_amount 0.25 → 1.0, set at runtime on the loaded resource and never saved. All other values are the `.tres` values.

**What I saw:** on the left, an opaque, lit, light-grey surface with fine bumpy moisture detail from the normal map. On the right, a mostly transparent quad: foggy grey-white edges and a clear centre where the stripes show through.

## Failed attempts (kept, not hidden)

**Take A, first attempt: script error.** The driver read the scene in `SceneTree._initialize()`, before the root enters the tree, so the game's `_ready()` had not run: "Cannot get path of node as it is not in a scene tree". Scene-dependent setup now runs on the first engine frame. The log of that attempt was overwritten by the successful run.

**Take C, first run: draws stopped.** The engine stopped drawing at process frame 464, after the user started using the machine; the first stray mouse event came at frame 419. Only 268 of 840 clip frames were saved, the driver's own count check failed, and the runner reported FAIL.

- Its log, input record and CSV are in `logs/failed_runs/run1_take_c_*`.
- Its partial frames and stills were deleted.
- After this run I added the fail-fast check, `window_can_draw` logging and an always-on-top window. The rerun passed.

**Take C2, first run: aborted.** It stopped at process frame 203, when `DisplayServer.window_can_draw()` turned false. The screen was not locked, display sleep was blocked by `caffeinate`, and the user had been active 24 s earlier, so the window probably left the visible Space.

- Its records are in `logs/failed_runs/run1_take_c2_*`.
- The rerun armed the forced-draw fallback for this frozen take and passed. The fallback was never used.

## Deviations from the request

- **Capture method.** SubViewport rig instead of Movie Maker (the probe above).
  - The cockpit frames are 3840×2400 (16:10, exactly 3× the game's base). A 3840×2160 film frame is a crop of them.
  - E and F are 3840×2160.
- **Freezing.** `Engine.time_scale = 0` was added to the tree pause in C, C2 and D, so that rain shaders driven by `TIME` hold still.
- **Action name.** J is the `window_left` action; `left_window` is the variable.
- **Double-tap timing.** The second tap of the double tap is at 12.117 s (frame 727), the nearest frame to 12.12 s.
- **Duplicate still.** `fog_baseline.png` and `world_fog_on.png` show the same state and are identical; both are kept as requested.
- **Extra stills.** Take C has lossless before and after stills of each edit, for the pixel analysis.
- **Window and input.** I added `--always-on-top` (C, C2, D, E, F) and the stray-input gate. Both are described above.
- **Take A tags.** Take A's MP4 colour tags differ (see Encoding).
- **Camera.** Every cockpit shot uses the default forward cockpit view. The driver's window appears at the left edge of the frame.

## Limitations

- **Offline render.** All frames are offline renders at a fixed 60 fps. They say nothing about real-time performance on the M4 or on the M1 the game targets.
- **SubViewport.** Frames come from a SubViewport, not the window itself. It uses the same renderer, project settings and 3× canvas scale.
  - The HUD and framing match the earlier window captures.
  - Take E's numbers match the earlier window measurements exactly.
- **Masks.** Mask polygons are projections without occlusion (supersets). The rectangle regions of C2 come from the coordinator and mix the two windows near the A-pillar, as noted.
- **Compression.** Clips go through JPEG at quality 0.95 and then H.264 at CRF 14. Stills are lossless PNG.
- **Visual judgement.** The "What I saw" notes are my descriptions of frames I opened. Whether the fog looks right, and whether the gauges read well, remain the author's human checks.
- **Unrelated files.** Three files in this folder were not made by these drivers. Another process (the reel build) wrote them while the capture ran: `take_a_headlights_keyframes.png` (16:18), `sweep_diff.txt` (16:25) and `take_b_driver_window_keyframes.png` (16:29). `manifest.json` lists them under `not_from_this_capture`, without hashes, and I did not modify them.

## Integrity checks (after all takes)

```text
$ git -C /Users/narasimhareddyvalam/Desktop/Blackridge_No_Way_Back status --short
?? youtube/
$ git -C /Users/narasimhareddyvalam/Desktop/Blackridge_No_Way_Back status --short -- game
(no output)
```

- **The repository's files.** All 385 files in `game/` outside `.godot/` are byte-identical before and after (`logs/snapshot/repo_game_after.sha256`). No file under `game/`, including `game/.godot/`, has a modification time later than the snapshot.
- **The copy's files.** The copy's `shaders/` and `materials/` are identical to the repository's. The `game/shaders/` files were never opened for writing; they were only read.
- **Untouched paths.** Nothing was committed, pushed or published, and `~/Desktop/brutalist.art` was not touched.
