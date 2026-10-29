# SOURCES — Blackridge, Shaded

- Game source shown: game/ at df5a1fd · captured from 25c7873. Nothing under `game/` was edited for the film; the engine captures ran on an isolated copy with its own user-data folder (`capture/CAPTURE.md`).
- Toolkit: Brutalist `brutalist.art` at `6a8380a` plus this build's local additions (`GodotEngineEvidence`, GodotDevWorkbench `dense` and `//` comments — see BUILD-LOG.md).
- Engine: Godot 4.7.2.stable (MIT), Compatibility renderer `gl_compatibility` (opengl3, Apple M4); one Forward+ comparison run (`--rendering-method forward_plus`, Metal) for the hint experiment only.

## Evidence shown (hash at build time)

| File | Beats | SHA-256 | Made by |
| --- | --- | --- | --- |
| `capture/cockpit_hero_4k.png` | B02 | `8a724a5d0048cc40779c6f514212992b700f6cbc0950141817293d0049b6bb23` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/fog_baseline.png` | B16 | `31d437f167631b3d25068450f0b6e9986511ad1b6fd8781eeaa398b88500e5bc` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/generated_vs_fog_4k.png` | B21, B21 (paired evidence) | `9092c7adde70851fb207a742d3f870a32300de7d8cc5013d625993edecea2cf8` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/hint_compatibility_4k.png` | B18, B18 (paired evidence) | `ccaa5dcd5d831cf4d504d7fed8d00b09626619ccc7628e438b982e73aa4c8f76` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/hint_forward_plus_4k.png` | B18 | `8da1f100f67a9a6da82c87cc54b7849a4ee6f69cdf94a942e6ce62ee04b70763` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/material_edit.mp4` | B16 | `17b27598ed0f9df3d6451bc352f7be7cc2a2d0a7ff68c3107771b6bfd2458876` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/material_edit_after.png` | B16 | `f4fb349bf34915f87216049d110e99969fb185c1ba0b7230cafbcc35c456dedf` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/shader_edit_visible.mp4` | B16 | `fca0c0672ae2b2473a8d84c8a7703667f8c5e8c63bbd4c765027bace025d93d4` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/shader_edit_visible_after.png` | B16, B16 (paired evidence) | `778f28055188716584a78cbed24b50f62e3875162ea26da6b4f0c1431c242f04` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_clear_center_default.png` | B12 | `31d437f167631b3d25068450f0b6e9986511ad1b6fd8781eeaa398b88500e5bc` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_clear_center_max.png` | B12 | `ea6eb29f8ef17d13bf6731413f031c41c06b351d2425de31b92ba26187c4c204` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_clear_center_min.png` | B12 | `0b7a18802084879f62f12f442d3f19919bfd90cfc5d2ede36e8481aca8433cd8` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_edge_softness_default.png` | B12 | `31d437f167631b3d25068450f0b6e9986511ad1b6fd8781eeaa398b88500e5bc` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_edge_softness_max.png` | B12 | `de307df57aa5ce4aba0b24089ffc9c5c3f07a933cc716a8b8027910810a674ea` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_edge_softness_min.png` | B12 | `a8ddc2d2a950d72a47edfb598c29432a72614efe1ddf42f64767ea2b2280204a` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_fog_amount_default.png` | B12 | `31d437f167631b3d25068450f0b6e9986511ad1b6fd8781eeaa398b88500e5bc` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_fog_amount_max.png` | B12, B12 (paired evidence) | `f4fb349bf34915f87216049d110e99969fb185c1ba0b7230cafbcc35c456dedf` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_fog_amount_min.png` | B12 | `1b85ed70d3c369c54415e557d6206ce608cd36cbcda16d07a52f2970c80fef8a` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_fog_opacity_default.png` | B12 | `31d437f167631b3d25068450f0b6e9986511ad1b6fd8781eeaa398b88500e5bc` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_fog_opacity_max.png` | B12 | `91ccf8f34e696c9b2cf966b4021c7a5172e6d3ed53f38325ce26973d6b6207fa` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_fog_opacity_min.png` | B12 | `1b85ed70d3c369c54415e557d6206ce608cd36cbcda16d07a52f2970c80fef8a` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_fog_tint_default.png` | B12 | `31d437f167631b3d25068450f0b6e9986511ad1b6fd8781eeaa398b88500e5bc` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_fog_tint_max.png` | B12 | `a3bef95c2657eb9cd28a01969616e36479cad518c1579cc95b7271ae37105694` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_fog_tint_min.png` | B12 | `93659ffe52c208ffc43677f7502fa9cbd6edc8fa74bc2f6d597e56b67376bfc9` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_normal_strength_default.png` | B12 | `31d437f167631b3d25068450f0b6e9986511ad1b6fd8781eeaa398b88500e5bc` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_normal_strength_max.png` | B12 | `b188284a19d71bfabcab0b061cb6ea34d3a6a143bc97c886a5fb2b00f1092467` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_normal_strength_min.png` | B12 | `e419bd9d1aa7b8ca2a8f8cf6fc1525cde531392f40729f2b7a559c7220714f4e` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_texture_scale_default.png` | B12 | `31d437f167631b3d25068450f0b6e9986511ad1b6fd8781eeaa398b88500e5bc` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_texture_scale_max.png` | B12 | `c4611f4474764df50d1dfb9972bbfc894913baeba99273cddab943628dea326b` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/sweep_texture_scale_min.png` | B12 | `6a408e2acf89a1c0c35d696527b86dac9d52c9d621dc243e9b0d903a2ac0595c` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/take_a_headlights.mp4` | B08 | `4fa9b4ac877c86a70527a081bcdee727a0a3cea67f75468026486811c7e4914e` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/take_a_headlights_keyframes.png` | B08 (paired evidence) | `a0bfa339b03a6e582d5508763b3509a7301657b2d0319887fa985c06b7467c09` | four frames extracted with ffmpeg from the take of the same name (the MP4 itself stays out of Git) |
| `capture/take_b_driver_window.mp4` | B10 | `233f6db53896430cbc1192faa12249ee1dd81747df445ebb0ad779293677c750` | scripted engine capture (`capture/scripts/`, `capture/CAPTURE.md`) |
| `capture/take_b_driver_window_keyframes.png` | B10 (paired evidence) | `abceb3e058406d0c982c425892feda4e8a0ad67486ae7370ab7ba38caaf920f4` | four frames extracted with ffmpeg from the take of the same name (the MP4 itself stays out of Git) |
| `evidence/fog_data.png` | B14 (paired evidence) | `6c311ac7304e3bb6fd002834aa85778767678aea4e889c4cfba4457b9a2532bd` | copy of `game/assets/textures/windshield/` (generated by `tools/make_fog_textures.py`, seed 20261029) |
| `evidence/night_cluster_1.0.png` | B05 (paired evidence) | `b302e213b79c938a3945bdc12865fd4e28cf3acaba7acb5296b088a0e6f15fdd` | copy of `evidence/captures/` (scripted SubViewport capture, `tools/captures/capture_night_cluster.gd`) |
| `evidence/recorded_test_output.png` | B23 (paired evidence) | `9cea8357f44ace463b4e8b4b9b70b83c68df33ebddb4f727dcc23c7112366b67` | typeset by build/evidence.py from verbatim log/report lines |
| `fog_color.png` | B14 | `missing` | copy of the repository file of the same name |
| `fog_data.png` | B14 | `missing` | copy of the repository file of the same name |
| `fog_normal.png` | B14 | `missing` | copy of the repository file of the same name |
| `night_cluster_0.0.png` | B05 | `missing` | copy of the repository file of the same name |
| `night_cluster_0.5.png` | B05 | `missing` | copy of the repository file of the same name |
| `night_cluster_1.0.png` | B05 | `missing` | copy of the repository file of the same name |
| `night_cluster_2.0.png` | B05 | `missing` | copy of the repository file of the same name |
| `recorded_fade_timing.png` | B08 | `missing` | copy of the repository file of the same name |
| `recorded_test_output.png` | B23 | `missing` | copy of the repository file of the same name |
| `window_checks.png` | B10 | `missing` | copy of the repository file of the same name |

MP4 clips are kept out of Git, per the course's media rule. Their hashes are in `capture/manifest.json` and above.

## Generated or third-party material

- **Textures:** fog_color, fog_normal and fog_data were written by code (`tools/make_fog_textures.py`, by Claude Code) and are original. `greys_3x1.png` was written by `tools/make_hint_png.gd`.
- **Calibration only:** Poly Haven `box_profile_metal_sheet` nor_gl / nor_dx, CC0 1.0. They are used only by the curl test (`game/tests/calibration/ATTRIBUTION.md`).
- **Narration:** Kokoro-82M (Apache-2.0) via kokoro-onnx (MIT), voice `am_onyx`, local and free; voiced as Liam, in for Bear. No voice cloning, no paid TTS.
- **Word timing:** faster-whisper (MIT) with the Whisper `base` model, via the toolkit's `align.py`.
- **Rendering:** Remotion 4.0.486 under the Remotion Free License (individual use); ffmpeg 8.0.1.
- **Maths:** matplotlib 3.11 mathtext through the toolkit's `typeset_math.py`.
- **Fonts:** EB Garamond, Lato, Inter and PT Mono (SIL Open Font License, bundled with the toolkit).
- **No image, video or music generator was used.** No paid media.

## Who did what

- **Author:** the brief and the hand predictions; the three shaders; the generated-shader annotations; LANGUAGE-NOTES; the playtest; the decisions; script approval; the instruction that the narration never frames the work as course requirements.
- **Claude Code:**
  - the CLAUDE.md draft, driver, tests, texture script, materials and overlays, captures, audit and reports;
  - this film's script draft, beat sheet, narration text, evidence ledger and new component;
  - the capture drivers, through a subagent.

