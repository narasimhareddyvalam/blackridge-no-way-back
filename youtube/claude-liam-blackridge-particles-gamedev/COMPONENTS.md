# COMPONENTS — Blackridge, Rain and Vapour

From `gamedev-evidence.json`: 98 files in 9 components, 680 excluded with a reason, 7 verbatim excerpts, 7 code → result pairs.

## a1-wiper-flick

Effect A1: the van's wiper_swept signal fires a burst at each top turn from a pool of two (overlap); the passenger blade's water is wiped by the driver's blade.

Beats: B07, B08, B09

Files: `effects/wiper_flick.tscn`, `features/vehicles/freight_van/van_particles.gd`, `features/vehicles/freight_van/freight_van.gd`, `features/vehicles/freight_van/van_presentation.gd`, `features/vehicles/freight_van/wiper.gd`, `previews/wiper_flick_preview.gd`, `previews/wiper_flick_preview.tscn`, `tests/test_wiper_flick_config.gd`, `tests/test_wiper_flick_state.gd`

## a2-roof-spill

Effect A2: a new hard brake (8 m/s, 6 m/s² for two ticks) spills the roof's water down the glass; a second brake while it lives or during the 20 s refill is ignored.

Beats: B09, B10, B11

Files: `effects/roof_spill.tscn`, `features/vehicles/freight_van/van_particles.gd`, `features/vehicles/freight_van/freight_van.gd`, `previews/roof_spill_preview.gd`, `previews/roof_spill_preview.tscn`, `tests/test_roof_spill_config.gd`, `tests/test_roof_spill_state.gd`

## b1-lamp-rain

Effect B1: rain in the light of the lamps within 65 m of the camera, eight volumes at most, started with preprocess and drained on stop; each landing sets off a splash sub-emitter.

Beats: B12, B13, B14, B15, B18

Files: `effects/lamp_rain_post.tscn`, `effects/lamp_rain_street.tscn`, `effects/lamp_rain_door.tscn`, `effects/lamp_rain_floodlight.tscn`, `features/environments/industrial_loop/lamp_rain.gd`, `features/environments/industrial_loop/industrial_loop.gd`, `previews/lamp_rain_preview.gd`, `previews/lamp_rain_preview.tscn`, `tests/test_lamp_rain_config.gd`, `tests/test_lamp_rain_state.gd`

## b2-exhaust

Effect B2: exhaust vapour whose amount_ratio follows ignition and throttle (0.15 to 0.80 of a fixed 300); the scene's emission, process and draw parts.

Beats: B04, B05, B16, B17, B18

Files: `effects/exhaust_vapour.tscn`, `features/vehicles/freight_van/van_particles.gd`, `features/vehicles/freight_van/freight_van.gd`, `previews/exhaust_vapour_preview.gd`, `previews/exhaust_vapour_preview.tscn`, `tests/test_exhaust_vapour_config.gd`, `tests/test_exhaust_vapour_state.gd`

## particle-draw

The draw step shared by all four effects: one particle shader and the five script-drawn textures.

Beats: B04, B20, B23

Files: `effects/scatter_particle.gdshader`, `effects/textures/exhaust_puff.png`, `effects/textures/exhaust_puff.png.import`, `effects/textures/fine_spray.png`, `effects/textures/fine_spray.png.import`, `effects/textures/rain_streak.png`, `effects/textures/rain_streak.png.import`, `effects/textures/roof_stream.png`, `effects/textures/roof_stream.png.import`, `effects/textures/water_bead.png`, `effects/textures/water_bead.png.import`

## process-shader

Step 6: Godot's conversion of B2's process material, saved by Codex at the author's direction; its scale-over-life and alpha-over-life lines beside the brief's curves.

Beats: B19, B20

Files: `shaders/particles_generated.gdshader`, `experiments/process_shader_scratch.tscn`

## checks

The preview fixtures behind the frame strips, the configuration and state tests, the headless cost script, the windowed GPU price script, and the earlier suites still passing.

Beats: B06, B21, B22

Files: `previews/preview_fixture.gd`, `tests/calibration/.gdignore`, `tests/calibration/ATTRIBUTION.md`, `tests/calibration/box_profile_metal_sheet_nor_dx_1k.png`, `tests/calibration/box_profile_metal_sheet_nor_gl_1k.png`, `tests/cost_effects.gd`, `tests/gpu_price.gd`, `tests/lane_keeper.gd`, `tests/normal_map_check.gd`, `tests/particle_readback.gd`, `tests/test_cockpit.gd`, `tests/test_collision.gd`, `tests/test_crossing.gd`, `tests/test_dash_screen.gd`, `tests/test_exhaust_vapour_config.gd`, `tests/test_exhaust_vapour_state.gd`, `tests/test_ghat_road.gd`, `tests/test_headlights.gd`, `tests/test_hit_speeds.gd`, `tests/test_lamp_rain_config.gd`, `tests/test_lamp_rain_state.gd`, `tests/test_materials.gd`, `tests/test_maya_call.gd`, `tests/test_menus.gd`, `tests/test_mirrors.gd`, `tests/test_mission_two.gd`, `tests/test_night_dimming.gd`, `tests/test_on_foot.gd`, `tests/test_oncoming_van.gd`, `tests/test_rain_physics.gd`, `tests/test_roof_spill_config.gd`, `tests/test_roof_spill_state.gd`, `tests/test_save_rules.gd`, `tests/test_wiper_flick_config.gd`, `tests/test_wiper_flick_state.gd`, `tests/test_wipers.gd`

## game-start

The main scene, the title screen that hides the lamps' rain, the pause menu, and the project settings the captures run under; the export leaves the previews out.

Beats: B02, B13

Files: `app/first_drive.gd`, `app/first_drive.tscn`, `project.godot`, `export_presets.cfg`, `features/ui/menus/front_menu.gd`

## world

At the author's requests (#150–#158), the world around the effects: lamps lighting downward, the depot's wall lights, an amber streetlight built by script, the wet road with raindrop rings, guardrails, verge grass and lit mist.

Beats: B18

Files: `features/environments/industrial_loop/forest_floor.gd`, `features/environments/industrial_loop/ghat_dressing.gd`, `features/environments/industrial_loop/hill_ground.gdshader`, `features/environments/industrial_loop/lamp_mist.gdshader`, `features/environments/industrial_loop/retroreflector.gdshader`, `features/environments/industrial_loop/roadside_grass.gd`, `features/environments/industrial_loop/verge_grass.gdshader`, `features/environments/industrial_loop/wet_asphalt.gdshader`, `features/environments/industrial_loop/polyhaven/POLYHAVEN.md`, `features/environments/industrial_loop/art/streetlight/streetlight.glb`, `features/environments/industrial_loop/art/streetlight/streetlight.glb.import`, `features/environments/industrial_loop/polyhaven/textures/green_metal_rust/green_metal_rust_arm_1k.jpg`, `features/environments/industrial_loop/polyhaven/textures/green_metal_rust/green_metal_rust_arm_1k.jpg.import`, `features/environments/industrial_loop/polyhaven/textures/green_metal_rust/green_metal_rust_diff_1k.jpg`, `features/environments/industrial_loop/polyhaven/textures/green_metal_rust/green_metal_rust_diff_1k.jpg.import`, `features/environments/industrial_loop/polyhaven/textures/green_metal_rust/green_metal_rust_nor_gl_1k.jpg`, `features/environments/industrial_loop/polyhaven/textures/green_metal_rust/green_metal_rust_nor_gl_1k.jpg.import`, `features/environments/industrial_loop/polyhaven/textures/leafy_grass/leafy_grass_arm_1k.jpg`, `features/environments/industrial_loop/polyhaven/textures/leafy_grass/leafy_grass_arm_1k.jpg.import`, `features/environments/industrial_loop/polyhaven/textures/leafy_grass/leafy_grass_diff_1k.jpg`, `features/environments/industrial_loop/polyhaven/textures/leafy_grass/leafy_grass_diff_1k.jpg.import`, `features/environments/industrial_loop/polyhaven/textures/leafy_grass/leafy_grass_nor_gl_1k.jpg`, `features/environments/industrial_loop/polyhaven/textures/leafy_grass/leafy_grass_nor_gl_1k.jpg.import`

## Code → result pairs

| Code | Result | Observation | Media |
| --- | --- | --- | --- |
| B04 | B05 | Behind the van, the plume appears after the ignition ramp, stops near the pipe, rises and thins, and glows red in the brake lamps. | `capture/takes/b2_rear/b2_rear.mp4` |
| B07 | B08 | In play on fast wipers, a flick shows at every top turn; the log has nine flicks by frame 255 after the switch to fast at frame 45. | `capture/takes/in_play/in_play_wipers.mp4` |
| B10 | B11 | The second hard brake at frame 25 is ignored (events.txt); the first spill's streams run on through frames 25 and 30. | `evidence/strips/roof_spill/r1-retrigger-true/frame00000025.png` |
| B12 | B13 | A few frames after the start the fixture's rain fills the light, steady; it drains from the top after the stop at frame 70 and is hidden by frame 110; in play the pause menu pauses the game. | `capture/takes/b1_post/b1_post.mp4` |
| B14 | B15 | Under the lamp, streaks reach the road, with at most a few specks where they land; real-size splashes are too faint to pick out at this distance. | `evidence/strips/lamp_rain/r1/frame00000050.png` |
| B16 | B17 | In the reverse camera, nothing shows at idle or on the throttle; a narrow red column rises in the brake lamps at frame 80 and a faint grey wisp at frame 100, gone by frame 130. | `capture/takes/b2_reverse/b2_reverse.mp4` |
| B19 | B20 | The puffs start small and dense at the pipe and grow and fade as they drift, as lines 254 (scale_curve) and 255 (alpha_curve) describe. | `evidence/strips/exhaust_vapour/r1/frame00000080.png` |
