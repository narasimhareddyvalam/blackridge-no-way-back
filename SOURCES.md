# SOURCES

Mission 2's work (the final project's Phase 2) comes first, then Assignment 6, whose graded copy
is at tag `a6`. Assignment 5's record follows with its text unchanged; its graded copy is at tag
`a5`.

# Phase 2 — Mission 2, The Wrong Cargo (2026-11-08 onward)

## Models

| Asset | Source | Authors (roles) | Licence | Date | Used in |
| --- | --- | --- | --- | --- | --- |
| `guard.glb` in `game/features/characters/guard/`, with six extracted WebP textures | Microsoft Rocketbox avatar library, https://github.com/microsoft/Microsoft-Rocketbox: the avatar `Security_Male_01` and the animation `m_sit_chair_breathe_01` (`source_assets/rocketbox/README.md`) | Microsoft (Rocketbox Studios; Microsoft Research). Converted by Claude Code with `tools/art/convert_rocketbox.py` (Blender 5.2.2) on 2026-11-11: the clip baked onto him bone by bone, his shoes at the origin, one roughness per part, the specular maps dropped, textures halved to 1024 pixels as WebP (`game/features/characters/ATTRIBUTION.md`) | MIT, copyright (c) 2020 Microsoft; the notice is in the in-game credits (C55) | 2026-11-11 | the gate guard at the transfer shed, a stand-in (D6) |
| `dock_door.glb` in `game/features/environments/industrial_loop/art/depot/` | "Industrial Overhead Door" by Maxwell autodoors, https://sketchfab.com/3d-models/industrial-overhead-door-20ced63367824ec1a2ada0fbf118b413 (`source_assets/sketchfab/01_door_maxwell/README.md`), fetched through the Blender MCP add-on on 2026-11-11 | Maxwell autodoors (Sketchfab `maihupronoob`). Converted by Claude Code with `tools/art/convert_depot_models.py` (Blender 5.2.2): its red wall, its trim and its overhead tracks and springs removed, its panel scaled to the 2.74 x 3.05 m opening, reduced to 5,341 triangles, no textures | CC BY 4.0; credited in game ("THE DEPOT") | 2026-11-11 | the transfer shed's nine dock doors |
| `dock_seal.glb` in `game/features/environments/industrial_loop/art/depot/` | "Foam Pad Dock Seal" by Maxwell autodoors, https://sketchfab.com/3d-models/foam-pad-dock-seal-e1225eb3cddf47d7b1d627c3aa0054e0 (`source_assets/sketchfab/03_seal_maxwell/README.md`) | Maxwell autodoors (Sketchfab `maihupronoob`). Converted by Claude Code with `tools/art/convert_depot_models.py`: its gap widened to 2.80 m and its side pads 3.25 m tall, 556 triangles, no textures | CC BY 4.0; credited in game ("THE DEPOT") | 2026-11-11 | the seals round the shed's nine dock doors |
| `dock_leveller.glb` in `game/features/environments/industrial_loop/art/depot/` | "DLHH Electrohydraulic Dock Leveler" by Maxwell autodoors, https://sketchfab.com/3d-models/dlhh-electrohydraulic-dock-leveler-47b0d1d2ed4e4e4a843082f63c9582d9 (`source_assets/sketchfab/02_leveller_maxwell/README.md`) | Maxwell autodoors (Sketchfab `maihupronoob`). Converted by Claude Code with `tools/art/convert_depot_models.py`: its deck 2.13 x 2.44 m, 9,187 triangles, three textures of at most 512 pixels | CC BY 4.0; credited in game ("THE DEPOT") | 2026-11-11 | the levellers inside docks 1-8 |
| `forklift.glb` in `game/features/environments/industrial_loop/art/depot/` | "Warehouse Forklift Gameready" by Kamran Mughal, https://sketchfab.com/3d-models/warehouse-forklift-gameready-94e21059f00c4e989c6403ada034516e (`source_assets/sketchfab/09_forklift/README.md`), fetched through the Blender MCP add-on on 2026-11-11 | Kamran Mughal (Sketchfab `absologixemployee`). Converted by Claude Code with `tools/art/convert_depot_models.py` (Blender 5.2.2): 7,786 triangles as made, its specular map left out, two textures halved to 1024 pixels and saved as JPEG. Its lettering, "SQUIRE" and "e-TL2", names no forklift maker a web search found (2026-11-11) | CC BY 4.0; credited in game ("THE DEPOT") | 2026-11-11 | the forklift behind dock 5 |
| `pallet_jack.glb` in `game/features/environments/industrial_loop/art/depot/` | "Pallet Jack" by FFeller, https://sketchfab.com/3d-models/pallet-jack-eccf1ee2e5d64743a7b4be69acfc734f (`source_assets/sketchfab/10_pallet_jack/README.md`), fetched through the Blender MCP add-on on 2026-11-11 | FFeller (Sketchfab `FFeller`), who adds: "If you use it in a game or in a video it is royalty free, if you make some changes and reupload it, please give me credit." Converted by Claude Code with the same script: 6,450 triangles as made, three textures halved to 1024 pixels and saved as JPEG | CC BY 4.0; credited in game ("THE DEPOT") | 2026-11-11 | the pallet jack at bay 9 |
| `pallet.glb` in `game/features/environments/industrial_loop/art/depot/` | "Euro pallet photoscanned" by widthRider, https://sketchfab.com/3d-models/euro-pallet-photoscanned-84132ceb4323477292ccf22a349b9f9d (`source_assets/sketchfab/11_pallet/README.md`), fetched through the Blender MCP add-on on 2026-11-11 | widthRider (Sketchfab `widthRider`). Converted by Claude Code with the same script: sized as the American 48 x 40 in pallet (1.219 x 1.016 x 0.15 m), reduced from 42,662 to 3,000 triangles, its wood matte (roughness 0.85), two textures halved to 1024 pixels and saved as JPEG. No EPAL or EUR stamp on its blocks | CC BY 4.0; credited in game ("THE DEPOT") | 2026-11-11 | the eleven pallets inside docks 5 and 9 |
| `carton.glb` in `game/features/environments/industrial_loop/art/depot/` | Poly Haven's "Cardboard Box 01" by Rahul Chaudhary, https://polyhaven.com/a/cardboard_box_01, from the depot yard's copy (`game/features/environments/depot_yard/polyhaven/`) | Rahul Chaudhary. Converted by Claude Code with the same script: reduced from 16,952 to 399 triangles, its three textures halved to 512 pixels | CC0; Poly Haven credited in game ("THE FOREST, THE ROAD AND THE YARD") | 2026-11-11 | the cartons on the staged pallets |
| `rollershutter_door.gltf`, reused from `game/features/environments/depot_yard/polyhaven/models/` (its `POLYHAVEN.md`) | https://polyhaven.com/a/rollershutter_door | MP | CC0 1.0 | 2026-11-11 (reused) | the transfer shed's drive-in door, scaled 1.2 |

# Assignment 6 — particle effects (2026-11-07)

## Tools

- Godot 4.7.2 stable, standard build, Forward+ (MetalFX upscaling at 75% on macOS).
- Claude Code (model Claude Opus 5.5), through the author's Claude account.
- Python 3 with NumPy and Pillow, used by `tools/make_particle_textures.py`.

## Textures

| Asset | Source | Authors (roles) | Licence | Date | Used in |
| --- | --- | --- | --- | --- | --- |
| `water_bead.png`, `fine_spray.png`, `roof_stream.png`, `exhaust_puff.png` | Written by code: `tools/make_particle_textures.py` (Claude Code), seed 6; every run writes the same bytes | Claude Code (script) | Original, no licence needed | 2026-11-07 | A1's beads and mist, A2's streams and beads, B1's splashes, B2's puffs |
| `rain_streak.png` | The same script; redrawn as wide as its quad in brief revision 5 | Claude Code (script) | Original, no licence needed | 2026-11-07 | B1's streaks |
| `cladding_grey_diff_2k.jpg` in `game/features/environments/industrial_loop/art/depot/` | Made by code from https://polyhaven.com/a/box_profile_metal_sheet (its 2k colour map, in the depot yard's copy): `tools/art/make_depot_textures.py` (Claude Code) turns the red sheet a light warm grey; the shed uses the sheet's own normal and ARM maps, and `concrete_wall_006` (2k), from the same folder | Amal Kumar (the sheet); Claude Code (script) | CC0 1.0 | 2026-11-11 | the transfer shed's cladding and dock face |

All five are in `game/effects/textures/`, imported with mipmaps. The script is their provenance
record: it draws each shape from formulas and fixed-seed noise, and fetches nothing.

## Generative models

None. The author first chose AI-generated textures for the effects, then asked for everything
else to follow best practice, and Claude Code drew them with a script instead (#142).

## Human and AI contributions

### Written or decided by the author

- The choice of the four effects, which are graded, and the realism bar (#131–#141).
- The draft of `CHANGE-BRIEF.md`, with its intent, timings, contrast, scale and predictions,
  and the decisions written into it on 2026-11-07: both B effects graded; B1's condition, its
  collision with splashes and its rain already falling; A2 moving with the van and firing at
  the hit.
- The request that all four effects be clearly visible, as in the real world (#144).
- To come: the frame strips, the verdicts in `TUNING.md`, the checks in the running game, the GPU
  price, Step 6's process shader and its answers, and the film.

### Written by Claude Code

- Corrections to the brief's Godot names, units and flags, and the values marked †, all
  disclosed in the brief's "How it was made" line; the brief's dated revisions 1–5.
- `docs/PARTICLE_RESEARCH.md`.
- The effect scenes in `game/effects/` and the five textures with their script.
- The controllers `van_particles.gd` and `lamp_rain.gd`, and the throttle member in
  `freight_van.gd`.
- The configuration, state and cost tests, `particle_readback.gd`, and the mutations.
- The preview scenes in `game/previews/`, `scripts/capture-strips.sh`, the runner changes in
  `scripts/run-test.sh`, and the leak probe in `logs/particles/leak_probe/`.
- The Assignment 6 sections of `TEST-REPORT.md`, `TUNING.md` (its predictions and comparisons),
  this file, `README.md` and `HANDOFF.md`.

# Assignment 5 — shaders, materials and the Godot Shading Language

## Starting point

*Blackridge: No Way Back*, as found on 2026-10-28 (commit `e81ec92`). It is
the author's own game. Its earlier code, tools and docs were made with Codex
and Claude at the author's direction; `fractional.md` records that history.
Assignments 2–4 used a different game; see `FRICTIONAL.md`.

## Tools

- Godot 4.7.2 stable, standard build, Compatibility renderer. One Forward+
  comparison capture was made for the hint experiment only.
- Claude Code 2.1.299 (model Claude Opus 5.5), through the author's Claude
  account.
- Python 3 with NumPy 2.5.3 and Pillow 12.3.0, used by `tools/make_fog_textures.py`.

## Textures

| Asset | Source | Authors (roles) | Licence | Date checked | Normal-map convention | Used in |
| --- | --- | --- | --- | --- | --- | --- |
| `fog_color.png`, `fog_data.png`, `fog_normal.png` | Written by code: `tools/make_fog_textures.py` (Claude Code), seed 20261029 | Claude Code (script); no other contributors | Original, no licence needed | 2026-10-29 | OpenGL (green up) | fog overlays (`light_fog.tres`, `heavy_fog.tres`) |
| `greys_3x1.png` | Written by code: `tools/make_hint_png.gd` (Claude Code) | Claude Code (script) | Original, no licence needed | 2026-10-29 | n/a | hint experiment |
| `box_profile_metal_sheet_nor_gl_1k.png`, `_nor_dx_1k.png` | https://polyhaven.com/a/box_profile_metal_sheet | Amal Kumar ("All", per the Poly Haven API) | CC0 1.0 | 2026-10-29 | GL and DX pair | curl-check calibration only |
| `tarred_gravel` (diff, nor_gl, arm, 2k) | https://polyhaven.com/a/tarred_gravel | Dimitrios Savva | CC0 1.0 | 2026-10-30 | OpenGL | forest road surface |
| `leaf_scattered_gravel` (diff, nor_gl, arm, 2k) | https://polyhaven.com/a/leaf_scattered_gravel | Dimitrios Savva | CC0 1.0 | 2026-10-30 | OpenGL | road edges |
| `forest_leaves_04` (diff, nor_gl, arm, 2k) | https://polyhaven.com/a/forest_leaves_04 | Rob Tuytel | CC0 1.0 | 2026-10-30 | OpenGL | forest floor |
| `pine_bark` (diff, nor_gl, arm, 2k) | https://polyhaven.com/a/pine_bark | Dimitrios Savva | CC0 1.0 | 2026-10-30 | OpenGL | pine trunks; lumber-yard logs |
| `conifer_branch_diff.png`, `conifer_branch_nor_gl.png`, `conifer_deadwood_diff.png`, `conifer_deadwood_nor_gl.png` | Built by code from the twig atlas of https://polyhaven.com/a/fir_tree_01 (`twig_diff`, `twig_alpha`, `twig_nor_gl`, 2k): `tools/make_conifer_cards.py` (Claude Code), seed 20261030 | Rob Tuytel, Rico Cilliers (scan); Claude Code (script) | CC0 1.0 | 2026-10-31 | OpenGL (green up) | live branch cards; dead lower branches |
| `low_beam_pattern.png` | Written by code: `tools/make_low_beam_pattern.py` (Claude Code) | Claude Code (script) | Original, no licence needed | 2026-10-30 | n/a | headlight low-beam pattern |
| `high_beam_pattern.png` | Written by code: `tools/make_high_beam_pattern.py` (Claude Code), from the low-beam pattern plus a hot spot on the horizon | Claude Code (script) | Original, no licence needed | 2026-10-31 | n/a | headlight high-beam pattern |
| `rock_wall_02` (diff, nor_gl, arm, 2k) | https://polyhaven.com/a/rock_wall_02 | Rob Tuytel | CC0 1.0 | 2026-10-31 | OpenGL | rock faces on the hill's steep cuts (`hill_ground.gdshader`) |
| `rustic_stone_wall` (diff, nor_gl, arm, 1k) | https://polyhaven.com/a/rustic_stone_wall | Dimitrios Savva | CC0 1.0 | 2026-10-31 | OpenGL | dry-stone walls at the hairpins and the viewpoint |
| `weathered_plank_siding` (diff, nor_gl, arm, 2k) | https://polyhaven.com/a/weathered_plank_siding | Dimitrios Savva | CC0 1.0 | 2026-11-01 | OpenGL | the site office's walls and its landing's sides (C36) |
| `corrugated_iron` (diff, nor_gl, arm, 1k) | https://polyhaven.com/a/corrugated_iron | Jenelle van Heerden, Dimitrios Savva | CC0 1.0 | 2026-11-01 | OpenGL | the site office's roof and door hood |
| `rough_pine_door` (diff, nor_gl, arm, 1k) | https://polyhaven.com/a/rough_pine_door | Dimitrios Savva | CC0 1.0 | 2026-11-01 | OpenGL | the site office's door |
| `stair_planks` (diff, nor_gl, arm, 1k) | https://polyhaven.com/a/stair_planks | Rob Tuytel | CC0 1.0 | 2026-11-01 | OpenGL | the site office's landing and step |
| `brushed_concrete_03` (diff, nor_gl, arm, 1k) | https://polyhaven.com/a/brushed_concrete_03 | Amal Kumar | CC0 1.0 | 2026-11-01 | OpenGL | the site office's plinth and splash block |
| `road_signs.png` | Written by code: `tools/make_road_signs.py` (Claude Code). The lettering is drawn with the macOS system font Arial Bold, which is not copied into the repository | Claude Code (script) | Original, no licence needed | 2026-10-31 | n/a | warning signs, chevrons, plates and boards on the ghat road |
| `fern_02` model (1k) | https://polyhaven.com/a/fern_02 | Rob Tuytel, Rico Cilliers | CC0 1.0 | 2026-10-30 | OpenGL | roadside ferns |
| `dry_branches_medium_01` model (1k) | https://polyhaven.com/a/dry_branches_medium_01 | Rico Cilliers | CC0 1.0 | 2026-10-30 | OpenGL | fallen branches |
| `tree_stump_01` model (1k) | https://polyhaven.com/a/tree_stump_01 | Rob Tuytel | CC0 1.0 | 2026-10-30 | OpenGL | stumps |
| `rock_moss_set_02` model (1k) | https://polyhaven.com/a/rock_moss_set_02 | Kless Gyzen | CC0 1.0 | 2026-10-30 | OpenGL | mossy rocks; the landslide |
| `dead_tree_trunk` model (1k) | https://polyhaven.com/a/dead_tree_trunk | Rob Tuytel | CC0 1.0 | 2026-10-30 | OpenGL | fallen trunks |
| `security_light` model (1k), in `game/features/environments/depot_yard/polyhaven/models/` (recorded in its `POLYHAVEN.md`) | https://polyhaven.com/a/security_light | Maximilian Schuster | CC0 1.0 | 2026-11-08 | OpenGL (glTF) | the freight depot's wall lights, one above each roller door, its glass drawn as a lit lens (#151) |
| `green_metal_rust` (diff, nor_gl, arm, 1k; the diffuse is not used) | https://polyhaven.com/a/green_metal_rust | Rob Tuytel | CC0 1.0 | 2026-11-08 | OpenGL | the street lamps' pole and head: its relief and roughness under a grey paint (#154) |
| `streetlight.glb` in `game/features/environments/industrial_loop/art/streetlight/` | Written by code: `tools/art/build_streetlight.py` (Claude Code), run in Blender 5.2.2 | Claude Code (script) | Original, no licence needed | 2026-11-08 | n/a (no images embedded) | the roadside street lamps: pole, davit arm, cobra head, refractor, footing (#154) |
| `leafy_grass` (diff, nor_gl, arm, 1k) | https://polyhaven.com/a/leafy_grass | Charlotte Baglioni | CC0 1.0 | 2026-11-08 | OpenGL | the mowed grass strip along the valley road, blended into the ground beyond the gravel verge (#157) |
| `cabin.glb`, `steering.glb` (rebuilt) | Written by code: `tools/art/build_first_drive_art.py` (Codex; cabin and wheel parts changed by Claude Code on 2026-10-30) | Codex, Claude Code (script) | Original, no licence needed | 2026-10-30 | OpenGL | van interior |
| `body.glb` and `door.glb` (the driver's door split out) | Written by code: `tools/art/build_first_drive_art.py` (Codex; the driver's door, its lowered handle and its share of the trim moved into `door.glb` by Claude Code on 2026-10-31, Run 19) | Codex, Claude Code (script) | Original, no licence needed | 2026-10-31 | OpenGL | van body; the driver's door that swings open when Ethan gets in |
| `cockpit/` in `game/features/vehicles/freight_van/art/`: `cockpit_front`, `cockpit_back`, `cockpit_roof` and `cockpit_wheel` (glTF), 27 textures, two shadow stand-ins | "FREE // Honda E (Detailed Interior) 2021", https://sketchfab.com/3d-models/free-honda-e-detailed-interior-2021-814cf3f8cfd64594b1c4f96e873c3cef | Alex Murias (Sketchfab: Xlay3D), model and textures. Changed by Claude Code in Blender on 2026-10-31: fitted to the van's cab (dash widened to the windshield, doors and seats moved, roof stretched, cab closed behind the seats), Honda badges and screen pictures removed, slimmed with no visible change, textures resized to 1k and 2k, split into four files; its own sunroof frame reopened as a moon roof on 2026-10-31 (Run 16) | CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/) | 2026-10-31 | OpenGL (glTF) | van cockpit (C22); `cabin.glb` and `steering.glb` stay in the repository, unused |
| `ethan.glb` and `pedestrian.glb` in `game/features/characters/`, with six extracted WebP textures | Adobe Mixamo, https://www.mixamo.com: characters "Ch33" (Ethan, C28) and "Ch01" (the pedestrian); animations Breathing Idle, Walking, Walking Backwards, Running, Entering Car, Exiting Car and Hit By Car, downloaded by the author on 2026-10-31 (`source_assets/mixamo/README.md`) | Adobe Mixamo (characters, rigs and motion). Converted by Claude Code with `tools/art/convert_mixamo.py` on 2026-10-31: one material per part with its own roughness, no metal, Mixamo's gloss and specular maps dropped, hair clipped, the pedestrian's polo tinted charcoal, textures halved to 2048 pixels as WebP, one bone prefix, walk and run in place | Adobe Mixamo terms: free in games, including sold games; not to be shared on their own. Committed as an exception to C10 (C27) | 2026-10-31 | glTF; Mixamo's convention not checked | Ethan on foot at the start of Mission 1; the pedestrian in the collision |
| `iveco/` in `game/features/vehicles/freight_van/art/`: `iveco_exterior.glb` and `iveco_cab.glb`, with 35 extracted WebP textures | "Iveco Daily Van 2014", https://sketchfab.com/3d-models/iveco-daily-van-2014-30003fba5b074d6eb7bc74fd5e1e7d19, imported through the Blender MCP add-on on 2026-11-01; the raw copy is in `source_assets/sketchfab/iveco_daily_2014/`, not in Git | Max (Sketchfab: Max-7215), model and textures. Converted by Claude Code with `tools/art/convert_iveco.py` on 2026-11-01: real size, turned to face -Z, the raised IVECO letters (grille, rear door) and the wipers removed, the name painted out of the textures (grille, rear door, steering-wheel badge), the French plate replaced by "BR 048" and a rear plate added, the doors, wheels, steering wheel, windshield and lamp lenses split out, a moon roof opening cut over the front seats (C32), textures 2048 (outside) and 1024 (cab) as WebP | CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/), plus the author's note "You must inform me of your usage"; the Blackridge author informs Max before the van ships | 2026-11-01 | glTF (OpenGL) | the player's van and its cab (C31), since Run 23 step 3; also, painted dark grey with its own plate, the oncoming van (C33), since Run 23 step 4 |
| `number_plate.png` in `source_assets/artwork/` | Written by code: `tools/make_number_plate.py` (Claude Code). The lettering uses the macOS system font DIN Condensed Bold, which is not copied into the repository | Claude Code (script) | Original, no licence needed | 2026-11-01 | n/a | the Iveco van's front and rear plates |
| `number_plate.png` in `game/features/vehicles/oncoming_van/art/` | Written by code: `tools/make_number_plate.py --registration "BR 731" --width 768` (Claude Code), with the same font | Claude Code (script) | Original, no licence needed | 2026-11-01 | n/a | the oncoming van's front and rear plates (C33) |
| `office/site_office.glb` in `game/features/environments/industrial_loop/art/` | Written by code: `tools/art/build_site_office.py` (Claude Code), run in Blender 5.2.2. The "OFFICE" letters are geometry from Blender's built-in text font; no font file is copied into the repository | Claude Code (script) | Original, no licence needed | 2026-11-01 | n/a (the Poly Haven textures above are applied in Godot) | the lumber yard's site office (C36) |

Credits files: `game/assets/textures/windshield/ATTRIBUTION.md`,
`game/tests/calibration/ATTRIBUTION.md` and
`game/features/environments/industrial_loop/polyhaven/POLYHAVEN.md`,
`source_assets/polyhaven/POLYHAVEN.md` (checksums and authors) and
`game/features/vehicles/freight_van/art/cockpit/ATTRIBUTION.md`,
`game/features/characters/ATTRIBUTION.md`, `source_assets/mixamo/README.md`,
`game/features/vehicles/freight_van/art/iveco/ATTRIBUTION.md` and
`source_assets/sketchfab/iveco_daily_2014/README.md`.

## Generative models

- **Game assets:** none. No image, sound or text generator made any Assignment 5 game asset.
- **Film narration:** Kokoro-82M (Apache-2.0), run locally through kokoro-onnx (MIT), voice
  `am_onyx`. It is free, uses no voice cloning, and has no paid TTS.
- **Film word timing:** faster-whisper (MIT), Whisper `base`.
- **Film visuals:** no image, video or music generator. Every visual is real engine output,
  an actual source file, or a Remotion teaching view. Details are in
  `youtube/claude-liam-blackridge-gamedev/SOURCES.md`.

## Human and AI contributions

### Written by the author, by hand

- `CHANGE-BRIEF.md` (commit `2729c26`): the spec, colour line, rules, hand
  predictions, material plan and answers. Claude Code put the author's text into
  the file and drafted the parts listed in that commit message.
- `game/shaders/night_cluster.gdshader` (`c055037`), and the reimport.
- `game/shaders/foggy_windshield.gdshader` (`3bac73e`) and
  `hint_experiment.gdshader` (`1bc3d34`).
- `LANGUAGE-NOTES.md` (`c23d4cd`, revised `e72e9d9`; Claude Code checked and
  entered the Part A line numbers) and the annotations in
  `standard_generated.gdshader` (`4d8e568`; the shader itself was generated by
  Godot).
- The `CLAUDE.md` review decisions (`4bba9b2`), every HUMAN CHECK, and the
  `FRICTIONAL.md` experience entries.

### Written by Claude Code

- The `CLAUDE.md` draft, made in scoped session 1 (`ea88542`).
- `scripts/run-test.sh`, adapted from the course wrapper.
- Driver and test:
  - `night_dimming.gd` and the `van_presentation.gd` hookup;
  - `game/tests/test_night_dimming.gd`.
- Fog:
  - `tools/make_fog_textures.py` and the three fog textures with their import
    settings;
  - `light_fog.tres` and `heavy_fog.tres`, with the author's values from
    CHANGE-BRIEF §5.8;
  - the overlay hookup.
- Hint experiment and captures:
  - `tools/make_hint_png.gd`, the hint-experiment scene and its materials;
  - the capture scripts in `tools/captures/`.
- Curl check: `normal_map_check.gd`, the course's code with tab indentation, and the
  calibration download.
- Docs: the doc skeletons and the measured parts of `TEST-REPORT.md`.
- The film "Blackridge, Shaded" (`youtube/claude-liam-blackridge-gamedev/`). Claude wrote:
  - the script draft, the beat sheet and the narration text;
  - the evidence ledger and the shared `GodotEngineEvidence` component;
  - the 4K capture drivers and takes, through a subagent on an isolated copy of `game/`;
  - the build and QC.
  The author approved the script and set the rule that the narration never frames the work
  as course requirements.

### Suggestions adopted, modified or rejected

From the final-project work on, every author prompt, approval and decline is recorded verbatim in [`docs/AUTHOR_PROMPTS_AND_DECISIONS.md`](docs/AUTHOR_PROMPTS_AND_DECISIONS.md).

- Night dimming was one of Claude's suggested effects. The author picked it.
- The author first chose rain-wet metal cladding, then a foggy windshield. The
  foggy-windshield idea was the author's own. Claude suggested overlays rather
  than replacing the glass.
- The author rejected the impact flash, which Claude had recommended.
- The author accepted Claude's review findings. On the brief, the author wrote the dated
  revision in their own words (`a09eb4e`). On `CLAUDE.md`, the author approved the fixes and
  Claude applied them (`4bba9b2`).
