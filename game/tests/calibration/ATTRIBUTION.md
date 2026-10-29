# Calibration pair credits

These two files are used only to calibrate `game/tests/normal_map_check.gd`. The
game does not use them.

| Field | Value |
| --- | --- |
| Asset | Box Profile Metal Sheet, https://polyhaven.com/a/box_profile_metal_sheet |
| Files | `box_profile_metal_sheet_nor_gl_1k.png` (OpenGL, green up) and `box_profile_metal_sheet_nor_dx_1k.png` (DirectX, green down), 1024 × 1024 PNG |
| Download URLs | `https://dl.polyhaven.org/file/ph-assets/Textures/png/1k/box_profile_metal_sheet/` + file name |
| MD5 (matches the Poly Haven API) | gl `a9a5f7f4862bfe61b8103bbf8cebfac4`, dx `ece51096c76d38efc648db134d4fb48e` |
| Author and role | Amal Kumar. The Poly Haven API lists the role as "All" |
| Licence | CC0 1.0, https://polyhaven.com/license (no credit required; recorded for provenance) |
| Date checked | 2026-10-29, through `https://api.polyhaven.com/info/box_profile_metal_sheet` and `/files/` |

The folder has a `.gdignore` file, so Godot does not import these images as
textures. Tests decode them with `Image.load_from_file()`.
