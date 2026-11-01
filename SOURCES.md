# SOURCES — Assignment 5

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
| `road_signs.png` | Written by code: `tools/make_road_signs.py` (Claude Code). The lettering is drawn with the macOS system font Arial Bold, which is not copied into the repository | Claude Code (script) | Original, no licence needed | 2026-10-31 | n/a | warning signs, chevrons, plates and boards on the ghat road |
| `fern_02` model (1k) | https://polyhaven.com/a/fern_02 | Rob Tuytel, Rico Cilliers | CC0 1.0 | 2026-10-30 | OpenGL | roadside ferns |
| `dry_branches_medium_01` model (1k) | https://polyhaven.com/a/dry_branches_medium_01 | Rico Cilliers | CC0 1.0 | 2026-10-30 | OpenGL | fallen branches |
| `tree_stump_01` model (1k) | https://polyhaven.com/a/tree_stump_01 | Rob Tuytel | CC0 1.0 | 2026-10-30 | OpenGL | stumps |
| `rock_moss_set_02` model (1k) | https://polyhaven.com/a/rock_moss_set_02 | Kless Gyzen | CC0 1.0 | 2026-10-30 | OpenGL | mossy rocks; the landslide |
| `dead_tree_trunk` model (1k) | https://polyhaven.com/a/dead_tree_trunk | Rob Tuytel | CC0 1.0 | 2026-10-30 | OpenGL | fallen trunks |
| `cabin.glb`, `steering.glb` (rebuilt) | Written by code: `tools/art/build_first_drive_art.py` (Codex; cabin and wheel parts changed by Claude Code on 2026-10-30) | Codex, Claude Code (script) | Original, no licence needed | 2026-10-30 | OpenGL | van interior |
| `body.glb` and `door.glb` (the driver's door split out) | Written by code: `tools/art/build_first_drive_art.py` (Codex; the driver's door, its lowered handle and its share of the trim moved into `door.glb` by Claude Code on 2026-10-31, Run 19) | Codex, Claude Code (script) | Original, no licence needed | 2026-10-31 | OpenGL | van body; the driver's door that swings open when Ethan gets in |
| `cockpit/` in `game/features/vehicles/freight_van/art/`: `cockpit_front`, `cockpit_back`, `cockpit_roof` and `cockpit_wheel` (glTF), 27 textures, two shadow stand-ins | "FREE // Honda E (Detailed Interior) 2021", https://sketchfab.com/3d-models/free-honda-e-detailed-interior-2021-814cf3f8cfd64594b1c4f96e873c3cef | Alex Murias (Sketchfab: Xlay3D), model and textures. Changed by Claude Code in Blender on 2026-10-31: fitted to the van's cab (dash widened to the windshield, doors and seats moved, roof stretched, cab closed behind the seats), Honda badges and screen pictures removed, slimmed with no visible change, textures resized to 1k and 2k, split into four files; its own sunroof frame reopened as a moon roof on 2026-10-31 (Run 16) | CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/) | 2026-10-31 | OpenGL (glTF) | van cockpit (C22); `cabin.glb` and `steering.glb` stay in the repository, unused |
| `ethan.glb` and `pedestrian.glb` in `game/features/characters/`, with six extracted WebP textures | Adobe Mixamo, https://www.mixamo.com: characters "Ch33" (Ethan, C28) and "Ch01" (the pedestrian); animations Breathing Idle, Walking, Walking Backwards, Running, Entering Car, Exiting Car and Hit By Car, downloaded by the author on 2026-10-31 (`source_assets/mixamo/README.md`) | Adobe Mixamo (characters, rigs and motion). Converted by Claude Code with `tools/art/convert_mixamo.py` on 2026-10-31: one material per part with its own roughness, no metal, Mixamo's gloss and specular maps dropped, hair clipped, the pedestrian's polo tinted charcoal, textures halved to 2048 pixels as WebP, one bone prefix, walk and run in place | Adobe Mixamo terms: free in games, including sold games; not to be shared on their own. Committed as an exception to C10 (C27) | 2026-10-31 | glTF; Mixamo's convention not checked | Ethan on foot at the start of Mission 1; the pedestrian in the collision |

Credits files: `game/assets/textures/windshield/ATTRIBUTION.md`,
`game/tests/calibration/ATTRIBUTION.md` and
`game/features/environments/industrial_loop/polyhaven/POLYHAVEN.md`,
`source_assets/polyhaven/POLYHAVEN.md` (checksums and authors) and
`game/features/vehicles/freight_van/art/cockpit/ATTRIBUTION.md`,
`game/features/characters/ATTRIBUTION.md` and `source_assets/mixamo/README.md`.

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
