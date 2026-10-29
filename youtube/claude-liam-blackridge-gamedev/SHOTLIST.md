# SHOTLIST — Blackridge, Shaded

Generated from beat_sheet.json by build/shotlist.py. Media paths under `blackridge-shaded/` are hash-identical copies of the reel's `evidence/` and `capture/` files in the Remotion public folder.

## B00 · ASK · ClaudeComposerAsk · 17.43 s

- Show: at “Namaste” — Composer types the reconstructed Walker prompt
- Show: at “reconstruction” — Running line, then three result lines land

## B01 · BLUF · BrutalistHesitantWriter · 12.28 s

- Show: at “0.8” — Writer types 'Shaders are decoration.'
- Show: at “rules you can test” — Deletes 'decoration', types 'rules you can test'

## B02 · SETUP · GodotEngineEvidence · 20.01 s

- Title: What This Build Adds
- Label: Held frame · engine capture, scripted · native 3840 × 2400
- Show: at “already had” — Held 4K cockpit frame; 'Already built' card
- Show: at “four pieces” — Four component cards light in narration order
- Show: at “Compatibility” — Engine card: Godot 4.7.2 · Compatibility · project.godot:125
- Media: `blackridge-shaded/capture/cockpit_hero_4k.png` (image, sha256 8a724a5d0048cc40…)

## B03 · SPEC · GodotEngineEvidence · 22.57 s

- Title: The Specification Came First
- Label: Document excerpt · verbatim
- Show: at “colour line” — Verbatim CHANGE-BRIEF colour line and uniform table
- Show: at “quarter” — Rule cards reveal as spoken
- Show: at “Git shows” — Commit order card: 2729c26 -> c055037; CLAUDE.md:91 import

## B04 · CODE · GodotDevWorkbench · 20.31 s

- Title: The Effect Is One Line
- Code: `game/shaders/night_cluster.gdshader` from line 1 (verbatim; Godot editor reconstruction)

## B05 · RESULT · GodotEngineEvidence · 21.85 s

- Title: Predicted, Then Measured
- Label: Held frames · engine capture of the 640×256 cluster SubViewport (scripted) · shown enlarged, pixels not smoothed
- Show: at “three settings” — Captures cycle 0.0 -> 0.5 -> 1.0 with pixel markers
- Show: at “eighteen” — Predicted -> measured cards tick 18/18
- Show: at “two point zero” — 2.0 capture; 'hint_range does not clamp' card
- Media: `blackridge-shaded/night_cluster_0.0.png` (image, sha256 987bc3e1fb2363cb…)
- Media: `blackridge-shaded/night_cluster_0.5.png` (image, sha256 a831fdfe56761a40…)
- Media: `blackridge-shaded/night_cluster_1.0.png` (image, sha256 b302e213b79c938a…)
- Media: `blackridge-shaded/night_cluster_2.0.png` (image, sha256 626642515f7aff7e…)
- Paired evidence: `evidence/night_cluster_1.0.png` sha256 b302e213b79c938a3945bdc12865fd4e28cf3acaba7acb5296b088a0e6f15fdd

## B06 · MATH · TypesetMath · 19.82 s

- Title: The Hand Prediction
- Show: at “Factor” — Row 1: the factored colour line
- Show: at “135” — Row 2: the worked hub-red case

## B07 · CODE · GodotDevWorkbench · 19.20 s

- Title: The Driver Reads Game State
- Code: `game/features/vehicles/freight_van/night_dimming.gd` from line 21 (verbatim; Godot editor reconstruction)

## B08 · RESULT · GodotEngineEvidence · 17.45 s

- Title: The Effect in Play
- Label: Engine capture · scripted input (L) · real-time segments of one take, cut only between presses · fixed 60 fps offline render, not an FPS claim
- Show: at “Lights off” — Footage: L press, dashboard fades to mint-white
- Show: at “Lights on” — L press, amber returns
- Show: at “Tap L twice” — Double tap reverses mid-fade
- Show: at “The tests” — Recorded frame-count card
- Media: `blackridge-shaded/capture/take_a_headlights.mp4` (video, sha256 4fa9b4ac877c86a7…)
- Media: `blackridge-shaded/capture/take_a_headlights.mp4` (video, sha256 4fa9b4ac877c86a7…) crop {"x": 0.234, "y": 0.575, "w": 0.581, "h": 0.208}
- Media: `blackridge-shaded/capture/take_a_headlights.mp4` (video, sha256 4fa9b4ac877c86a7…)
- Media: `blackridge-shaded/capture/take_a_headlights.mp4` (video, sha256 4fa9b4ac877c86a7…) crop {"x": 0.234, "y": 0.575, "w": 0.581, "h": 0.208}
- Media: `blackridge-shaded/capture/take_a_headlights.mp4` (video, sha256 4fa9b4ac877c86a7…)
- Media: `blackridge-shaded/capture/take_a_headlights.mp4` (video, sha256 4fa9b4ac877c86a7…) crop {"x": 0.234, "y": 0.575, "w": 0.581, "h": 0.208}
- Media: `blackridge-shaded/recorded_fade_timing.png` (image, sha256 726454c0b19d2188…)
- Paired evidence: `capture/take_a_headlights_keyframes.png` sha256 a0bfa339b03a6e582d5508763b3509a7301657b2d0319887fa985c06b7467c09

## B09 · CODE · GodotDevWorkbench · 15.72 s

- Title: Two Overlays, One Shader
- Code: `game/features/vehicles/freight_van/van_presentation.gd` from line 226 (verbatim; Godot editor reconstruction)

## B10 · RESULT · GodotEngineEvidence · 17.92 s

- Title: The Fog Rides With the Glass
- Label: Engine capture · scripted input (J) · one real-time take · fixed 60 fps offline render, not an FPS claim
- Show: at “Press J” — Footage: J press, window and fog lower together
- Show: at “first version” — Card: 1.13 m world-space bug -> 0.880 m in van frame
- Media: `blackridge-shaded/capture/take_b_driver_window.mp4` (video, sha256 233f6db53896430c…)
- Media: `blackridge-shaded/capture/take_b_driver_window.mp4` (video, sha256 233f6db53896430c…) crop {"x": 0.0, "y": 0.146, "w": 0.391, "h": 0.479}
- Media: `blackridge-shaded/window_checks.png` (image, sha256 bc3fde97ccfc5398…)
- Paired evidence: `capture/take_b_driver_window_keyframes.png` sha256 abceb3e058406d0c982c425892feda4e8a0ad67486ae7370ab7ba38caaf920f4

## B11 · CODE · GodotDevWorkbench · 19.75 s

- Title: A Parameter Interface
- Code: `game/shaders/foggy_windshield.gdshader` from line 1 (verbatim; Godot editor reconstruction)

## B12 · RESULT · GodotEngineEvidence · 21.78 s

- Title: Every Control, Swept
- Label: Held frames · engine captures, time frozen, wipers parked · windshield crop of 3840 × 2400 · % = largest share of pixels changed >6 levels vs default
- Media: `blackridge-shaded/capture/sweep_fog_amount_min.png` (image, sha256 1b85ed70d3c369c5…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_fog_amount_default.png` (image, sha256 31d437f167631b3d…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_fog_amount_max.png` (image, sha256 f4fb349bf34915f8…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_clear_center_min.png` (image, sha256 0b7a18802084879f…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_clear_center_default.png` (image, sha256 31d437f167631b3d…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_clear_center_max.png` (image, sha256 ea6eb29f8ef17d13…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_fog_opacity_min.png` (image, sha256 1b85ed70d3c369c5…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_fog_opacity_default.png` (image, sha256 31d437f167631b3d…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_fog_opacity_max.png` (image, sha256 91ccf8f34e696c9b…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_edge_softness_min.png` (image, sha256 a8ddc2d2a950d72a…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_edge_softness_default.png` (image, sha256 31d437f167631b3d…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_edge_softness_max.png` (image, sha256 de307df57aa5ce4a…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_normal_strength_min.png` (image, sha256 e419bd9d1aa7b8ca…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_normal_strength_default.png` (image, sha256 31d437f167631b3d…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_normal_strength_max.png` (image, sha256 b188284a19d71bfa…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_texture_scale_min.png` (image, sha256 6a408e2acf89a1c0…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_texture_scale_default.png` (image, sha256 31d437f167631b3d…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_texture_scale_max.png` (image, sha256 c4611f4474764df5…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_fog_tint_min.png` (image, sha256 93659ffe52c208ff…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_fog_tint_default.png` (image, sha256 31d437f167631b3d…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Media: `blackridge-shaded/capture/sweep_fog_tint_max.png` (image, sha256 a3bef95c2657eb9c…) crop {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
- Paired evidence: `capture/sweep_fog_amount_max.png` sha256 f4fb349bf34915f87216049d110e99969fb185c1ba0b7230cafbcc35c456dedf

## B13 · CODE · GodotDevWorkbench · 18.37 s

- Title: Three Textures, Three Jobs
- Code: `game/shaders/foggy_windshield.gdshader` from line 26 (verbatim; Godot editor reconstruction)

## B14 · RESULT · GodotEngineEvidence · 21.61 s

- Title: Three Files, Three Meanings
- Label: Source textures · the actual 1024 × 1024 PNG files
- Show: at “three files” — The three actual texture files
- Show: at “import settings” — Import-settings cards
- Show: at “curl check” — Curl-ratio card: calibration vs fog_normal
- Media: `blackridge-shaded/fog_color.png` (image, sha256 d075d863d6a2efb3…)
- Media: `blackridge-shaded/fog_normal.png` (image, sha256 c7b33bf7b2207aad…)
- Media: `blackridge-shaded/fog_data.png` (image, sha256 6c311ac7304e3bb6…)
- Paired evidence: `evidence/fog_data.png` sha256 6c311ac7304e3bb6fd002834aa85778767678aea4e889c4cfba4457b9a2532bd

## B15 · CODE · GodotDevWorkbench · 18.33 s

- Title: A Material Is Settings
- Code: `game/materials/windshield/light_fog.tres` from line 8 (verbatim; Godot editor reconstruction)

## B16 · RESULT · GodotEngineEvidence · 20.14 s

- Title: One Shader, Two Materials
- Label: Engine capture · scripted, cockpit paused, wipers parked · real-time clips · fixed 60 fps offline render
- Show: at “Side by side” — Baseline: both overlays
- Show: at “Change one value” — Material edit clip: only the windshield thickens
- Show: at “Change one line” — Shader edit clip: both windows change
- Media: `blackridge-shaded/capture/fog_baseline.png` (image, sha256 31d437f167631b3d…)
- Media: `blackridge-shaded/capture/material_edit.mp4` (video, sha256 17b27598ed0f9df3…)
- Media: `blackridge-shaded/capture/shader_edit_visible.mp4` (video, sha256 fca0c0672ae2b247…)
- Media: `blackridge-shaded/capture/material_edit_after.png` (image, sha256 f4fb349bf34915f8…)
- Media: `blackridge-shaded/capture/shader_edit_visible_after.png` (image, sha256 778f280551887165…)
- Paired evidence: `capture/shader_edit_visible_after.png` sha256 778f28055188716584a78cbed24b50f62e3875162ea26da6b4f0c1431c242f04

## B17 · CODE · GodotDevWorkbench · 18.01 s

- Title: One Hint, Isolated
- Code: `game/shaders/hint_experiment.gdshader` from line 1 (verbatim; Godot editor reconstruction)

## B18 · RESULT · GodotEngineEvidence · 25.76 s

- Title: Same Shader, Two Renderers
- Label: Held frames · engine captures at 3840 × 2160, scripted · markers show the sampled data-quad values
- Show: at “read as colour” — Predicted values card
- Show: at “Forward Plus” — Forward+ capture with measured bands
- Show: at “Compatibility” — Compatibility capture: file values on both quads
- Media: `blackridge-shaded/capture/hint_forward_plus_4k.png` (image, sha256 8da1f100f67a9a6d…)
- Media: `blackridge-shaded/capture/hint_compatibility_4k.png` (image, sha256 ccaa5dcd5d831cf4…)
- Paired evidence: `capture/hint_compatibility_4k.png` sha256 ccaa5dcd5d831cf4d504d7fed8d00b09626619ccc7628e438b982e73aa4c8f76

## B19 · MATH · TypesetMath · 19.86 s

- Title: The Encode Behind 137
- Show: at “encode” — Row 1: sRGB encode
- Show: at “Feed in” — Row 2: 64 -> 137

## B20 · CODE · GodotDevWorkbench · 19.01 s

- Title: What Godot Generates
- Code: `game/shaders/standard_generated.gdshader` from line 6 (verbatim; Godot editor reconstruction)

## B21 · RESULT · GodotEngineEvidence · 20.69 s

- Title: Same Files, Two Shaders
- Label: Engine capture · scripted test scene on an isolated copy (not the game) · 3840 × 2160
- Media: `blackridge-shaded/capture/generated_vs_fog_4k.png` (image, sha256 9092c7adde70851f…)
- Paired evidence: `capture/generated_vs_fog_4k.png` sha256 9092c7adde70851fb207a742d3f870a32300de7d8cc5013d625993edecea2cf8

## B22 · CODE · GodotDevWorkbench · 16.81 s

- Title: A Test That Can Fail
- Code: `game/tests/test_night_dimming.gd` from line 70 (verbatim; Godot editor reconstruction)

## B23 · RESULT · GodotEngineEvidence · 18.11 s

- Title: What the Tests Prove
- Label: Recorded output · logs/ (typeset verbatim)
- Show: at “Every suite” — Recorded output lines
- Show: at “three deliberate breaks” — Three mutation cards turn red: exit 1
- Show: at “can't show” — What no headless run can show
- Media: `blackridge-shaded/recorded_test_output.png` (image, sha256 9cea8357f44ace46…)
- Paired evidence: `evidence/recorded_test_output.png` sha256 9cea8357f44ace463b4e8b4b9b70b83c68df33ebddb4f727dcc23c7112366b67

## B24 · CAUGHT · GodotEngineEvidence · 20.01 s

- Title: Caught Along the Way
- Label: From FRICTIONAL.md and TEST-REPORT.md
- Show: at “every frame” — Card 1
- Show: at “Two agent-written” — Card 2
- Show: at “An audit” — Card 3
- Show: at “stopped Claude” — Card 4

## B25 · CONTRIBUTIONS · GodotEngineEvidence · 20.03 s

- Title: Who Did What
- Label: From SOURCES.md and FRICTIONAL.md
- Show: at “The author” — Author column
- Show: at “Claude Code wrote” — Claude Code column
- Show: at “fog textures” — Sources card
- Show: at “revision” — Revision card

## B26 · VERDICT · ClaudeVerdictArtifact · 22.54 s


## B27 · HANDOFF · ClaudeComposerAsk · 32.25 s


## B28 · OUTRO · ClaudeTitleOutro · 3.92 s

- Title: Blackridge, Shaded

Total narration clock: 561.54 s (9.4 min).
