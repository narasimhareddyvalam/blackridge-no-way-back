# MATERIALS — Assignment 5 audit

Audit of the materials named in `CHANGE-BRIEF.md`, written by Claude Code on 2026-10-29 with
no changes to any shader, material, scene or `.import` file. `game/tests/test_materials.gd`
pins every table below (76/76 at 60 fps, `logs/test_materials_60fps.log`). Integer enums were
checked against Godot 4.7.2's `editor/import/resource_importer_texture.cpp` and against the
engine constants printed headlessly.

## Materials

| Material | Shader | Uniform values | Textures bound |
| --- | --- | --- | --- |
| `game/materials/windshield/light_fog.tres` | `res://shaders/foggy_windshield.gdshader` | fog_amount 0.25, fog_opacity 0.45, clear_center 0.65, edge_softness 0.2, normal_strength 0.5, texture_scale 1.0, fog_tint (0.82, 0.87, 0.9, 1) | fog_color ← `fog_color.png`, fog_normal ← `fog_normal.png`, fog_data ← `fog_data.png` |
| `game/materials/windshield/heavy_fog.tres` | `res://shaders/foggy_windshield.gdshader` | fog_amount 0.75, fog_opacity 0.6, clear_center 0.35, edge_softness 0.25, normal_strength 0.5, texture_scale 1.0, fog_tint (0.82, 0.87, 0.9, 1) | the same three textures |
| `game/experiments/hint_experiment/hint_as_color.tres` | `res://shaders/hint_experiment.gdshader` | show_data false | color_read and data_read ← `greys_3x1.png` |
| `game/experiments/hint_experiment/hint_as_data.tres` | `res://shaders/hint_experiment.gdshader` | show_data true | color_read and data_read ← `greys_3x1.png` |

The night-dimming ShaderMaterial is made in code, one per van
(`game/features/vehicles/freight_van/night_dimming.gd:9,15-16`), so it has no `.tres`.

## Samplers

Import columns: `compress/mode` (0 = Lossless), `compress/normal_map` (1 = Enable,
2 = Disabled), `mipmaps/generate`.

| Shader | Sampler | Hints as written | Bound texture | `compress/mode` | `compress/normal_map` | `mipmaps/generate` |
| --- | --- | --- | --- | --- | --- | --- |
| foggy_windshield (`:26`) | fog_color | `source_color, filter_linear, repeat_enable` | `fog_color.png` (both materials) | 0 | 2 | true |
| foggy_windshield (`:27`) | fog_normal | `hint_normal, filter_linear, repeat_enable` | `fog_normal.png` (both materials) | 0 | 1 | true |
| foggy_windshield (`:28`) | fog_data | `filter_linear, repeat_enable` | `fog_data.png` (both materials) | 0 | 2 | true |
| hint_experiment (`:5`) | color_read | `source_color, filter_nearest` | `greys_3x1.png` (both materials) | 0 | 2 | false |
| hint_experiment (`:6`) | data_read | `filter_nearest` | `greys_3x1.png` (both materials) | 0 | 2 | false |

- **Detect 3D:** every texture above has `detect_3d/compress_to=0` (Disabled), so the editor
  has no reason to change the compression later.
- **Measured format:** `get_image().get_format()` gives 4 (`FORMAT_RGB8`) for all four
  textures. The fog images have mipmaps; the hint PNG has none.

## Lights and environment

**Main scene** (`res://app/first_drive.tscn`). The environment is built in code
(`game/features/environments/industrial_loop/industrial_loop.gd:33-62`):
- **Sky:** ProceduralSky background.
- **Ambient:** source COLOR (2), `#758b9c`, energy 0.30.
- **Reflections:** from the sky (2), plus the depot reflection probe (`:246-257`).
- **World fog:** on, density 0.0038, light colour `#334653`, sky affect 0.65.
- **Moon:** DirectionalLight3D `#9bb8d4`, energy 0.55, shadows to 85 m.
- **Tonemap:** not set, so it is the Godot default: `tonemap_mode` 0 (`TONE_MAPPER_LINEAR`),
  exposure 1.0. Glow and SSAO are off by default.
- **Street lamps:** OmniLight3D `#ffd1a0`, energy 3.0, range 18. Near the depot (z > 100)
  they have shadows, energy 4.0 and range 16 (`:222-243`).
- **Cabin light:** OmniLight3D `#b7c2c9`, energy 0.45, range 2.5, cull mask 4 (cabin layer
  only), at `game/features/vehicles/freight_van/van_presentation.gd:114-119`. It lights the
  fog overlays.
- **Headlights:** SpotLight3D, energy 5.0, cull mask 1 (`van_presentation.gd:73-86`). They do
  not light the cabin layer.

**Hint scene** (`game/experiments/hint_experiment/hint_experiment.tscn`):
- **Background:** `background_mode` 1 (`BG_COLOR`), black.
- **Tonemap:** `tonemap_mode` 0 (Linear), exposure 1.0.
- **Effects:** glow, fog, adjustments and SSAO all off.
- **Lights:** none; both quads are unshaded.
- **Camera:** orthographic (`projection` 1).

## Findings

1. **Inconsistent with the brief.** `foggy_windshield.gdshader:59` multiplies the colour map
   by `fog_tint`. CHANGE-BRIEF §5.7 says "`mix()` blends the texture colour with the fog tint".
2. **Not in the brief.** `foggy_windshield.gdshader:69-70` sets `ROUGHNESS = 0.95` and
   `SPECULAR = 0.1`. These are fixed values that the §5.5 uniform plan does not list.
3. **Possibly wasteful.** Each fog texture is lossless RGB8 1024 × 1024 with mipmaps:
   4,194,303 bytes of image data, measured with `get_image().get_data_size()`, so 12.6 MB for
   the three. For a thin overlay, a smaller size or VRAM compression would cut this.
4. **Unused channels.** `fog_data.png` stores thickness as grey (R = G = B), but the shader
   reads only `.r` (`foggy_windshield.gdshader:35`).
5. **Meets the requirement.** The two fog materials share the shader and all three textures.
   They differ in four values (fog_amount, fog_opacity, clear_center, edge_softness) and
   share normal_strength, texture_scale and fog_tint.
6. **Hint experiment result.** Under Compatibility, both hint quads show the file's values
   (captures in `evidence/captures/`). The wiring matches the brief; the difference from the
   Forward+ prediction is a rendering result, recorded in `TEST-REPORT.md`.
7. **Test-only loading.** The calibration pair sits in `game/tests/calibration/` with
   `.gdignore`, so it is not imported. `Image.load_from_file()` then warns that this "will
   not work on export", which is acceptable for tests only.
8. **Needs a visual check.** The windshield overlay is 1.2 cm inside the transparent rain
   pane (`van_presentation.gd`, `_fog_overlay`). No headless evidence shows how the two
   layer; that needs the author's eyes.

## Attribution (facts exactly as in CHANGE-BRIEF.md)

- The three fog textures are "generated using `tools/make_fog_textures.py`, written by
  Claude Code" (CHANGE-BRIEF §5.6).
- The calibration pair is "a known normal-map pair from Poly Haven", "the same texture's
  OpenGL (`_nor_gl`) and DirectX (`_nor_dx`) normal maps" (CHANGE-BRIEF §5.10 item 7).
- Fuller credits: `game/assets/textures/windshield/ATTRIBUTION.md` and
  `game/tests/calibration/ATTRIBUTION.md`.

## What the headless test cannot establish

- Whether the fog looks natural.
- Whether the two transparent layers sort correctly.
- Whether the road stays readable.
- Whether sRGB decoding is visible on screen, which the captures show differs between
  renderers.
- Anything about performance.
