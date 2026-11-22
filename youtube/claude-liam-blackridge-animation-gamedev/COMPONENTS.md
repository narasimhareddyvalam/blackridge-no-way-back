# COMPONENTS — Blackridge, Frame by Frame

From `gamedev-evidence.json`: 139 files in 8 components, 1771 excluded with a reason, 8 verbatim excerpts, 8 code → result pairs.

## ring-cycle

The cycle: RingIcon, a Sprite2D slicing the six-cell sheet (hframes 6), and RingPlayer's frame track (phone_ring.tres: 0.6 s, step 0.1, LOOP_LINEAR, discrete, keys 0-5), played and stopped only by navigation_display.gd while Maya's call rings.

Beats: B04, B05, B06, B07

Files: `animations/phone_ring.tres`, `features/vehicles/freight_van/navigation_display.gd`, `features/vehicles/freight_van/van_presentation.gd`, `features/vehicles/freight_van/art/ring/phone_ring.png`, `features/vehicles/freight_van/art/ring/phone_ring.png.import`, `features/vehicles/freight_van/art/ring/ATTRIBUTION.md`, `tests/test_ring_readback.gd`

## enter-van

The committing action: Mixamo's Entering Car in ethan.glb (164 frames at 30 fps, LOOP_NONE in its importer), its phase table as the app's constants (22, 32, 48, 62), the boarding loop reading clip_time() for the door and the hand, its interrupts and Step 7's r1.

Beats: B08, B09, B10, B11, B12, B13, B15, B16

Files: `features/characters/ethan/ethan.glb`, `features/characters/ethan/ethan.glb.import`, `app/first_drive.gd`, `tests/test_rig_readback.gd`, `tests/test_animation_edges.gd`, `tests/test_animation_pins.gd`, `previews/enter_van_preview.gd`, `previews/enter_van_preview.tscn`

## authority

One authority over Ethan's AnimationPlayer: driver.gd (play_clip, _play) and the helpers it builds and calls (push_gait.gd, rifle_carry.gd); stance.gd only reads; the structure and state tests.

Beats: B14, B15

Files: `features/characters/driver/driver.gd`, `features/characters/driver/push_gait.gd`, `features/characters/driver/stance.gd`, `tests/test_animation_structure.gd`, `tests/test_animation_states.gd`

## rifle-reload

The third clip: Mixamo's reloading for Ethan (100 frames, upper body only) on the UpperBody player rifle_carry.gd builds, the M16 held by rifle_hold.gd with the magazine and charging handle on the clip's frames, the gun's timer equal to the clip, wired into Mission 3's fight.

Beats: B17, B18

Files: `features/characters/driver/rifle_carry.gd`, `features/weapons/rifle/rifle_hold.gd`, `features/weapons/pistol/handgun.gd`, `features/missions/last_run/hangar_encounter.gd`, `animations/ethan_rifle.tres`, `features/weapons/rifle/ATTRIBUTION.md`, `features/weapons/rifle/m16.glb`, `features/weapons/rifle/m16.glb.import`, `features/weapons/rifle/m16_M16A3_baseColor.webp`, `features/weapons/rifle/m16_M16A3_baseColor.webp.import`, `features/weapons/rifle/m16_M16A3_metallicRoughness.webp`, `features/weapons/rifle/m16_M16A3_metallicRoughness.webp.import`, `features/weapons/rifle/m16_M16A3_normal.webp`, `features/weapons/rifle/m16_M16A3_normal.webp.import`, `features/weapons/rifle/rifle_hold.gd`, `tests/test_reload_readback.gd`, `tests/test_reload_edges.gd`, `tests/test_reload_pins.gd`, `tests/test_hangar.gd`

## shock

The fourth clip: Shock, 105 frames keyed by tools/art/make_ethan_shock.gd over EnterVan's last frame, played by driver.gd's play_seated with the wrists by IK on the wheel's rim, inside Mission 1's 4 s hold after the van comes to rest.

Beats: B19, B20

Files: `animations/ethan_shock.tres`, `features/characters/driver/driver.gd`, `app/first_drive.gd`, `features/missions/night_freight/first_drive.gd`, `tests/test_shock_readback.gd`, `tests/test_shock_state.gd`, `tests/test_shock_pins.gd`

## superseded

The pistol attempts the author turned down (#386, #393): the hand-keyed reload and the pistol's upper-body clips, kept converted but unused.

Beats: B22

Files: `animations/pistol_reload.tres`, `animations/ethan_pistol.tres`

## import-outputs

Files Godot itself regenerated and that were committed to keep the working tree clean (#409-#411): four Poly Haven .import headers (the VRAM-compressed outputs their unchanged settings ask for) and the crane spreader's extracted emissive texture. Not animation work; context in the footage only.

Beats: B02

Files: `features/environments/industrial_loop/polyhaven/textures/green_metal_rust/green_metal_rust_diff_1k.jpg.import`, `features/environments/industrial_loop/polyhaven/textures/green_metal_rust/green_metal_rust_nor_gl_1k.jpg.import`, `features/environments/industrial_loop/polyhaven/textures/leafy_grass/leafy_grass_diff_1k.jpg.import`, `features/environments/industrial_loop/polyhaven/textures/leafy_grass/leafy_grass_nor_gl_1k.jpg.import`, `features/environments/harbour_flats/art/harbour_crane/harbour_crane_Crane_Spreader_4K_emissive.webp`, `features/environments/harbour_flats/art/harbour_crane/harbour_crane_Crane_Spreader_4K_emissive.webp.import`

## checks

The read-back helper and every test: read-backs, structure, states, edges, pins, and the earlier suites still passing.

Beats: B09, B21

Files: `tests/animation_readback.gd`, `tests/calibration/.gdignore`, `tests/calibration/ATTRIBUTION.md`, `tests/calibration/box_profile_metal_sheet_nor_dx_1k.png`, `tests/calibration/box_profile_metal_sheet_nor_gl_1k.png`, `tests/cost_effects.gd`, `tests/gpu_price.gd`, `tests/gpu_price_depot.gd`, `tests/gpu_price_lighting.gd`, `tests/lane_keeper.gd`, `tests/normal_map_check.gd`, `tests/particle_readback.gd`, `tests/test_airfield.gd`, `tests/test_ambush.gd`, `tests/test_animation_edges.gd`, `tests/test_animation_pins.gd`, `tests/test_animation_states.gd`, `tests/test_animation_structure.gd`, `tests/test_bay_nine.gd`, `tests/test_booths.gd`, `tests/test_cargo_opening.gd`, `tests/test_cockpit.gd`, `tests/test_collision.gd`, `tests/test_compound.gd`, `tests/test_container_yard.gd`, `tests/test_convoy.gd`, `tests/test_crossing.gd`, `tests/test_dash_screen.gd`, `tests/test_dock_worker.gd`, `tests/test_docking.gd`, `tests/test_docks.gd`, `tests/test_ending.gd`, `tests/test_escape.gd`, `tests/test_escape_route.gd`, `tests/test_exhaust_vapour_config.gd`, `tests/test_exhaust_vapour_state.gd`, `tests/test_forklift.gd`, `tests/test_free_exit.gd`, `tests/test_gate_light.gd`, `tests/test_gates.gd`, `tests/test_getaway.gd`, `tests/test_ghat_road.gd`, `tests/test_guidance.gd`, `tests/test_handover.gd`, `tests/test_hangar.gd`, `tests/test_harbour_flats.gd`, `tests/test_headlights.gd`, `tests/test_hit_speeds.gd`, `tests/test_inspection.gd`, `tests/test_lamp_rain_config.gd`, `tests/test_lamp_rain_state.gd`, `tests/test_last_run.gd`, `tests/test_loading.gd`, `tests/test_loading_bay.gd`, `tests/test_materials.gd`, `tests/test_maya_call.gd`, `tests/test_menus.gd`, `tests/test_mirrors.gd`, `tests/test_mission_two.gd`, `tests/test_moon_roof_rain.gd`, `tests/test_night_dimming.gd`, `tests/test_on_foot.gd`, `tests/test_oncoming_van.gd`, `tests/test_opening.gd`, `tests/test_pallet_jack.gd`, `tests/test_proof.gd`, `tests/test_racking.gd`, `tests/test_rain_physics.gd`, `tests/test_rear_camera.gd`, `tests/test_rear_doors.gd`, `tests/test_reload_edges.gd`, `tests/test_reload_pins.gd`, `tests/test_reload_readback.gd`, `tests/test_rescue.gd`, `tests/test_rig_readback.gd`, `tests/test_ring_readback.gd`, `tests/test_roadside.gd`, `tests/test_roadside_trees.gd`, `tests/test_roof_spill_config.gd`, `tests/test_roof_spill_state.gd`, `tests/test_save_rules.gd`, `tests/test_sealing.gd`, `tests/test_shed_fitout.gd`, `tests/test_shed_floor.gd`, `tests/test_shed_kit.gd`, `tests/test_shed_work.gd`, `tests/test_shock_pins.gd`, `tests/test_shock_readback.gd`, `tests/test_shock_state.gd`, `tests/test_stair.gd`, `tests/test_tail_lamps.gd`, `tests/test_town.gd`, `tests/test_warehouses.gd`, `tests/test_waterfront.gd`, `tests/test_wet_ground.gd`, `tests/test_windshield_water.gd`, `tests/test_wiper_flick_config.gd`, `tests/test_wiper_flick_state.gd`, `tests/test_wipers.gd`, `tests/test_yard.gd`, `tests/test_yard_realism.gd`

## Code → result pairs

| Code | Result | Observation | Media |
| --- | --- | --- | --- |
| B04 | B05 | The sheet's six cells: the handset alone, one, two and three arcs, then the arcs fading; on the dash, six frames three apart run through one 0.6 s cycle of the arcs. | `capture/sheet/phone_ring_on_dark.png` |
| B06 | B07 | In play, the dash zoomed while Maya's call rings: the handset's arcs pulse in a steady loop beside 'Maya, incoming call'. | `capture/takes/ring_play/ring_dash.mp4` |
| B08 | B09 | From an empty cache the read-back passes 9/9 with LOOP_NONE and 114 bone tracks; with the importer set to 1 it fails E7 and E8 (7/9). | `capture/takes/ring_play/boarding.mp4` |
| B10 | B11 | Strip r1 at each boundary: facing the door (clip 0), the reach (22), the hand on the handle with the door shut (32), the door open (48), rising into the cab (58), seated (70). | `evidence/strips/enter_van/r1/frame_060.png` |
| B12 | B13 | The per-frame log: at the clip's frame 34 the door reads 0.011, the value for frame 33, so the door runs one frame behind the hand. | `evidence/strips/enter_van/r0/frame_046.png` |
| B14 | B15 | W at clip 16 moves him 0.000 m and boarding runs on; Esc at clip 40 freezes the clip and the door at 41 and 0.593 for 40 frames under the pause menu, then resumes; R at clip 56 seats him at once. | `capture/takes/interrupt_active/interrupt_active.mp4` |
| B17 | B18 | Aiming, R: the HUD reads RELOADING, the empty magazine drops, the fresh one comes up in his left hand and is seated, the charging handle is pulled; the HUD then reads 30/12. | `capture/takes/reload/reload.mp4` |
| B19 | B20 | Through the windshield: he startles, breathes hard, shakes his head, drops toward the wheel, looks to each mirror and stares, his hands on the wheel's rim throughout. | `capture/takes/shock/shock.mp4` |
