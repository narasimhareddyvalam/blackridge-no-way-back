# SOURCES: Blackridge: No Way Back, the pitch

What the film shows and where every piece of it came from. Compiled by Claude Code on 2026-11-23
from the repository and the build; nothing below is inferred.

## 1. The film

- **Footage:** real gameplay of Blackridge: No Way Back at `develop` `61cf104` (game/ unchanged
  since), recorded for this film on 2026-11-23 by Godot 4.7.2's Movie Maker at 3840×2160, 30 fps,
  played through the game's own controls by automated film players Claude Code wrote at the
  author's direction (`tools/captures/film_missions.gd`, `film_mission_two.gd`, `film_kit.gd`): scripted input, not a
  person. Every take, its run and its SHA-256 is listed in section 6; the takes themselves are not
  in Git (`captures/pitch/takes4k/`, ignored), and the reel's `coverage.json` records each one.
- **Starts:** Mission 1 from the title screen; Mission 2 from two of its film player's parts
  (`load`, `yard`: a save and the van placed where the part begins); Mission 3 from its stage 3
  save at the service gate (`-- 3 gate`, the checkpoint the game writes when the code is keyed).
- **Narration:** the author's approved script (#457-#459), read by an AI voice, Kokoro `am_onyx`,
  through Brutalist's `runtime/scripts/generate_audio_kokoro.py`; aligned by `runtime/scripts/align.py`.
  It is not the author's own voice; the closing card says so.
- **The film's toolkit:** Brutalist (`~/Desktop/brutalist.art`, commit `6a8380a`) with these
  scenes: `GodotEngineEvidence`, `BrutalistHesitantWriter`, `ClaudeVerdictArtifact`,
  `ClaudeComposerAsk`, `FormACard`. Changes made in that checkout for this film, none committed
  to the toolkit:
  - `GodotEngineEvidence.tsx` (a local scene, untracked, from Assignment 7) gained a `handle` prop
    (default unchanged), so the panels carry the author's name and not the instructor's handle.
  - `remotion.config.ts` (new, local) caps OffthreadVideo's frame cache at 600 MB.
- **Build scripts (this reel):** `build/build_sheet.py` (the sheet, the footage cuts, the cues),
  `build/render_chunked.py` (footage beats in 90-frame runs), `build/coverage.py`, `build/docs.py`.
- **The test shown in B09:** `scripts/run-test.sh test_save_rules.gd 60`, run 2026-11-23 20:33,
  `logs/pitch/test_save_rules_60fps.log`: SAVE RULES RESULT: 29/29 passed; 0 failed.
- **No Claude response is shown.** B14's composer shows a prompt for the viewer to paste; it shows
  no answer.
- **Names:** GTA V and Euro Truck Simulator 2 are named as games the author has played, for
  comparison only; no footage or art from them is used.

## 2. Who made what

- **The author:** the game's story and design (`docs/GAME_STORY.md`, `docs/GAME_DESIGN.md`), every
  shader in `game/shaders/` (hand-written, `a5`), the answers in `PROJECT-BRIEF.md` (#450, #455),
  the choice of comparables, the role, and every approval logged in
  `docs/AUTHOR_PROMPTS_AND_DECISIONS.md`.
- **Claude Code (at the author's direction, every prompt logged):** the game's code outside
  `game/shaders/`, the tests, the film players, this film's script drafts (approved by the
  author), its build scripts and documents. Its choices made while the author slept (#467) are
  drafts for the author's review.

## 3. Third-party assets in the game


### Characters and motion capture

| Asset | Author | Source | Licence | Used in |
| --- | --- | --- | --- | --- |
| Mixamo character "Ch33" (Ethan) | Adobe Mixamo | https://www.mixamo.com | Adobe Mixamo terms ("free to use in games, including games that are sold ... may not be shared on their own", `game/features/characters/ATTRIBUTION.md`) | `game/features/characters/ethan/ethan.glb` |
| Mixamo character "Ch01" (the pedestrian) | Adobe Mixamo | https://www.mixamo.com | Adobe Mixamo terms | `game/features/characters/pedestrian/pedestrian.glb` (Mission 1 collision) |
| Mixamo animations: Breathing Idle, Walking, Walking Backwards, Running, Entering Car, Exiting Car, Pushing, Push Stop | Adobe Mixamo | https://www.mixamo.com (`source_assets/mixamo/`) | Adobe Mixamo terms | `ethan.glb` (Idle, Walk, WalkBack, Run, EnterVan, ExitVan, Push, PushStop); Walk/Idle also on the pedestrian; Idle/Walk/Run baked onto `patrol_guard.glb` and `syndicate_man.glb` |
| Mixamo animations: Hit By Car, Male Sitting Pose | Adobe Mixamo | https://www.mixamo.com | Adobe Mixamo terms | pedestrian `HitByVan`; `syndicate_man.glb` `Fall` and `Sit` (the watcher); `Sit` in `ethan.glb` (converted, unused) |
| Mixamo animations: Pistol Idle, Reloading (Ch33) | Adobe Mixamo | https://www.mixamo.com | Adobe Mixamo terms | `ethan.glb` `PistolIdle`, `PistolReload`, `PistolAim`; `game/animations/ethan_pistol.tres` (SOURCES.md: converted, now unused after the rifle) |
| Mixamo rifle clips (Ch33) and Mixamo "Basic Shooter Pack": Grab Rifle From Back, Rifle Idle, Rifle Idle (1), Rifle Aim To Down, rifle aiming idle, firing rifle, reloading, hit reaction, Rifle Put Away, plus the pack's walk/run/strafe/turn gaits | Adobe Mixamo | https://www.mixamo.com (`source_assets/mixamo/rifle/`, `basic_shooter_pack/`) | Adobe Mixamo terms | `ethan.glb` `Rifle*` clips; `game/animations/ethan_rifle.tres` (Mission 3) |
| Security_Male_01 avatar + `m_sit_chair_breathe_01` clip | Microsoft (Rocketbox Studios; Microsoft Research) | https://github.com/microsoft/Microsoft-Rocketbox | MIT, Copyright (c) 2020 Microsoft | `game/features/characters/guard/guard.glb` (transfer-shed gate guard) |
| Security_Female_01 avatar + `f_sit_chair_breathe_01` clip | Microsoft (Rocketbox) | https://github.com/microsoft/Microsoft-Rocketbox | MIT, Copyright (c) 2020 Microsoft (stated in `source_assets/rocketbox/README.md` and in-game Credits) | `game/features/characters/compound_guard/compound_guard.glb` (warehouse-compound guard) |
| Construction_Male_08 avatar + clips `m_idle_neutral_01`, `m_walk_neutral_01`, `m_try_door_outwards`, desk/document/crouch/turn/walk-start-stop clips | Microsoft (Rocketbox) | https://github.com/microsoft/Microsoft-Rocketbox | MIT, Copyright (c) 2020 Microsoft | `game/features/characters/dock_worker/dock_worker.glb` (bay 9's dock worker) |
| Construction_Male_07 avatar + `m_sit_table_idle_neutral_01` | Microsoft (Rocketbox) | https://github.com/microsoft/Microsoft-Rocketbox | MIT, Copyright (c) 2020 Microsoft | `game/features/characters/forklift_driver/forklift_driver.glb` |
| Female_Adult_07 avatar + clips `f_idle_nervous_01`, `f_gestic_talk_sad_01`, `f_gestic_talk_femalestressed_01`, `f_idle_breathe_01`, `f_walk_neutral_01` | Microsoft (Rocketbox) | https://github.com/microsoft/Microsoft-Rocketbox | MIT, Copyright (c) 2020 Microsoft | `game/features/characters/maya/maya.glb` (Maya) |
| Female_Child_01 avatar + the same clips | Microsoft (Rocketbox) | https://github.com/microsoft/Microsoft-Rocketbox | MIT, Copyright (c) 2020 Microsoft | `game/features/characters/lily/lily.glb` (Lily) |
| Business_Male_03 avatar + clips `m_idle_angry_01`, `m_gestic_talk_excited_01`, `m_walk_neutral_01` | Microsoft (Rocketbox) | https://github.com/microsoft/Microsoft-Rocketbox | MIT, Copyright (c) 2020 Microsoft | `game/features/characters/adrian/adrian.glb` (Adrian) |
| "Security Guard - Rigged 3D Model" | qsardor57913 | https://sketchfab.com/3d-models/1e3307732bbf4453b30f021bfec5bcaf | CC BY 4.0 | `game/features/characters/patrol_guard/` (warehouse compound patrols) |
| "guard" | bumstrum | https://sketchfab.com/3d-models/9f146fae6af1482ab6bff56ed5677c28 | CC BY 4.0 | `game/features/characters/syndicate_man/` (syndicate men, airfield men, ending watcher) and their pistol `game/features/weapons/pistol/pistol.glb` |

### Vehicles and weapon

| Asset | Author | Source | Licence | Used in |
| --- | --- | --- | --- | --- |
| "Iveco Daily Van 2014" | Max (Sketchfab: Max-7215) | https://sketchfab.com/3d-models/iveco-daily-van-2014-30003fba5b074d6eb7bc74fd5e1e7d19 | CC BY 4.0, plus the author's note "This model is not free of rights. You must inform me of your usage." (informed 2026-11-03, acknowledged) | `game/features/vehicles/freight_van/art/iveco/` (player's van, its cab; the oncoming van); `tail_lamp_masks.png` derived from its texture, shared under the same licence |
| "FREE // Honda E (Detailed Interior) 2021" | Alex Murias (Sketchfab: Xlay3D) | https://sketchfab.com/3d-models/free-honda-e-detailed-interior-2021-814cf3f8cfd64594b1c4f96e873c3cef | CC BY 4.0 | `game/features/vehicles/freight_van/art/cockpit/` (Credits: "used while the cab was being built"; now referenced only by `game/tests/test_cockpit.gd`) |
| "Chevrolet Suburban 2015-Unmarked" | David_Holiday | https://sketchfab.com/3d-models/b01950cf99aa48c1ba2ebd0addc8a9d4 | CC BY 4.0 | `game/features/environments/harbour_flats/art/suburban/` (black convoy and ambush SUVs, repainted) |
| "Pilatus PC 12/47" | helijah | https://sketchfab.com/3d-models/d8ab7be8b9794910930e7919d0bf3f5a | CC BY 4.0 | `game/features/environments/harbour_flats/art/pc12/` (airfield plane) |
| "Semi Truck 1980" | Brian Trepanier (Sketchfab: CMBC) | https://sketchfab.com/3d-models/semi-truck-1980-5f6db10ac12645b8938a4b76942d9133 | CC BY 4.0 | `game/features/environments/industrial_loop/art/depot/tractor_1980.glb` (yard at night) |
| "Truck Trailer FREE" | NLM (Sketchfab: NLM-Group) | https://sketchfab.com/3d-models/truck-trailer-free-575958a53e3d4e9f8bcfb1ee2cef67bf | CC BY 4.0 (author's note: "can be used in games") | `.../art/depot/trailer_dryvan.glb` |
| "LCT 3000 '95 - Low poly model" | Daniel Zhabotinsky | https://sketchfab.com/3d-models/lct-3000-95-low-poly-model-663a0953c038434a918cb85725c88ffa | CC BY 4.0, plus the author's unconditional permission to use and modify | `.../art/depot/box_truck.glb` |
| "Fairheaven LT '80 - Low poly model" | Daniel Zhabotinsky | https://sketchfab.com/3d-models/fairheaven-lt-80-low-poly-model-e2678da920cc4be68dbc193727919ffb | CC BY 4.0, plus the same permission note | `.../art/town/sedan.glb` (town main street) |
| "Warehouse Forklift Gameready" | Kamran Mughal (Sketchfab: absologixemployee) | https://sketchfab.com/3d-models/warehouse-forklift-gameready-94e21059f00c4e989c6403ada034516e | CC BY 4.0 | `.../art/depot/forklift.glb` (transfer shed) |
| "CONTAINER LOADER" | jinjinjin (Sketchfab: thejinjinjin) | https://sketchfab.com/3d-models/container-loader-17cac1aa2d46404ab39766a20c5f2e47 | CC BY 4.0 | `.../art/container_yard/top_loader/top_loader.glb` |
| "M16 Assault Rifle" | jeandiz | https://sketchfab.com/3d-models/339d0f7b21024387853dd926a5d51b50 | CC BY 4.0 | `game/features/weapons/rifle/m16.glb` (Ethan's rifle, Mission 3) |

### Depot, shed, gatehouses, gates, harbour, house, trees, town (Sketchfab)

Folder prefix `.../art/` = `game/features/environments/industrial_loop/art/`.

| Asset | Author | Source | Licence | Used in |
| --- | --- | --- | --- | --- |
| "Industrial Overhead Door" | Maxwell autodoors (Sketchfab: maihupronoob) | https://sketchfab.com/3d-models/industrial-overhead-door-20ced63367824ec1a2ada0fbf118b413 | CC BY 4.0 | `.../art/depot/dock_door.glb` (transfer shed dock doors) |
| "Foam Pad Dock Seal" | Maxwell autodoors | https://sketchfab.com/3d-models/foam-pad-dock-seal-e1225eb3cddf47d7b1d627c3aa0054e0 | CC BY 4.0 | `.../art/depot/dock_seal.glb` |
| "DLHH Electrohydraulic Dock Leveler" | Maxwell autodoors | https://sketchfab.com/3d-models/dlhh-electrohydraulic-dock-leveler-47b0d1d2ed4e4e4a843082f63c9582d9 | CC BY 4.0 | `.../art/depot/dock_leveller.glb` |
| "Pallet Jack" | FFeller | https://sketchfab.com/3d-models/pallet-jack-eccf1ee2e5d64743a7b4be69acfc734f | CC BY 4.0 (author's note: royalty free in a game or video; credit if changed and re-uploaded) | `.../art/depot/pallet_jack.glb` (bay 9) |
| "Euro pallet photoscanned" | widthRider | https://sketchfab.com/3d-models/euro-pallet-photoscanned-84132ceb4323477292ccf22a349b9f9d | CC BY 4.0 | `.../art/depot/pallet.glb` |
| "Office Chair" | Red Fox (Sketchfab: nokillnando) | https://sketchfab.com/3d-models/office-chair-b228a29fa84544c2be501c295653ffe7 | CC BY 4.0 | `.../art/depot/office_chair.glb`; modified copy `.../art/booth/models/draughtsman_chair/` |
| "dumpster" | YJ_ | https://sketchfab.com/3d-models/dumpster-989ea7f01b924859b3484ee27103e8d9 | CC BY 4.0 | `.../art/depot/dumpsters.glb` |
| "Monitor Dell P2314H" | GregorJan (Sketchfab: login166) | https://sketchfab.com/3d-models/monitor-dell-p2314h-c69f09bb812e46cdbd5bf6c62499b848 | CC BY 4.0 | `.../art/booth/models/dell_monitor/` (gatehouses) |
| "PC Setup - Game Ready" (keyboard and mouse only) | Melon Polygons (Sketchfab: Melonpolygons) | https://sketchfab.com/3d-models/pc-setup-game-ready-4126abfe9895488181dbde961e836788 | CC BY 4.0 | `.../art/booth/models/keyboard/`, `mouse/` |
| "Corded Phone With Buttons" | dudecon | https://sketchfab.com/3d-models/corded-phone-with-buttons-b11bc340cda14a75b1d8c1d63e79f8dd | CC BY 4.0 | `.../art/booth/models/desk_phone/` |
| "Walkie Talkie" | barism09 | https://sketchfab.com/3d-models/walkie-talkie-5d57f97915a844f584157cb86a474eba | CC BY 4.0 | `.../art/booth/models/walkie_talkie/` |
| "Indoor air conditioner unit" | Rylae Shylna (Sketchfab: risteralline) | https://sketchfab.com/3d-models/indoor-air-conditioner-unit-d93c5557a9ba46afbb00e35f48343077 | CC BY 4.0 | `.../art/booth/models/ac_indoor_unit/` |
| "Automatic Boom Barriers" | Maxwell autodoors | https://sketchfab.com/3d-models/automatic-boom-barriers-0013365d67f84b8bb22d62e128f69fa2 | CC BY 4.0 | `.../art/gates/barrier_cabinet/` |
| "Sliding Gate Motors - Residential" | Maxwell autodoors | https://sketchfab.com/3d-models/sliding-gate-motors-residential-06f05c51a4994704a3959742a7e8be0e | CC BY 4.0 | `.../art/gates/gate_motor/` |
| "Abandoned Factory Warning Light" | x4vier28 (Sketchfab: xs196441) | https://sketchfab.com/3d-models/abandoned-factory-warning-light-7b12be1b4bd74ee0b10511ddcabf5cc8 | CC BY 4.0 | `.../art/gates/warning_light/` |
| "LED Floodlight" | The Street Light Man (Sketchfab: thestreetlightman) | https://sketchfab.com/3d-models/led-floodlight-17a9f07cbc9540ac8093eaa6f81244a5 | CC BY 4.0 | `.../art/gates/led_flood/` (compound gate) |
| "Harbor crane" | TGVMisterH | https://sketchfab.com/3d-models/d4d582ebd707426f93f1f5a9cdd0ce03 | CC BY 4.0 | `game/features/environments/harbour_flats/art/harbour_crane/` (berth 2) |
| "Suburban House V2" | strielecki | https://sketchfab.com/3d-models/92b305cf37ad4b0daec1630028e4499c | CC BY 4.0 | `game/features/missions/last_run/art/house/family_house.glb` (epilogue) |
| "Realistic HD Mountain hemlock (21/43)" | PlantCatalog | https://sketchfab.com/models/225cd2dfbf7d4163bc3a062a0c0623aa | CC BY 4.0 | `.../art/trees/mountain_hemlock.glb` |
| "Realistic fir trees pack (LODS, gameready)" | lolipop_1707 | https://sketchfab.com/models/f58e8b6d733e4b0586e5b7db847b89e7 | CC BY 4.0 | `.../art/trees/young_firs.glb` |
| "Western Red Cedar *Inspired* Tree - WINTER Ver." | SirSonat | https://sketchfab.com/models/fdd3274350144d8abe119d8a73cdce34 | CC BY 4.0 | `.../art/trees/western_red_cedar.glb` |
| "Gas pump" | SavinienBerault | https://sketchfab.com/models/7fcc112afa0440fd8d286dda2ba3ef96 | CC BY 4.0 | `.../art/town/gas_pump.glb` (gas station) |
| "Pay phone Scan MEDPOLY" | evan4129 | https://sketchfab.com/models/8235545da48a4ceeb787f8a138b7a8f3 | CC BY 4.0 | `.../art/town/payphone.glb` |

### Code and font

| Asset | Author | Source | Licence | Used in |
| --- | --- | --- | --- | --- |
| "Rain Puddle Shader v3" (ripple and reflection functions) | GloriousGlider8 (as YourSoftware Foundation) | https://godotshaders.com/shader/rain-puddles-v1/ | MIT (notice in the shader header) | adapted into `game/features/environments/industrial_loop/wet_ground.gdshader` (wet road, yard, apron) |
| GodotSSRWater (screen-space reflections) | Marcel Bankmann (marcelb) | https://github.com/marcelb/GodotSSRWater | MIT | same shader |
| Barlow Condensed SemiBold (font) | The Barlow Project Authors (Copyright 2017) | https://github.com/jpt/barlow | SIL Open Font License 1.1 (`OFL.txt` beside the font) | `game/features/ui/driving_hud/fonts/BarlowCondensed-SemiBold.ttf` (HUD, objective marker, film look, epilogue); container markings drawn with it |

### Poly Haven (all CC0; per each `POLYHAVEN.md`: "All Poly Haven assets are CC0 (public domain): https://polyhaven.com/license")

Source URL for each is `https://polyhaven.com/a/<id>`.

| Asset | Author | Source | Licence | Used in |
| --- | --- | --- | --- | --- |
| Rollershutter Door (model) | MP | polyhaven.com/a/rollershutter_door | CC0 | `game/features/environments/depot_yard/polyhaven/models/` (freight depot; transfer shed drive-in door) |
| Security Light (model) | Maximilian Schuster | /a/security_light | CC0 | depot_yard (depot wall lights) |
| Modular Metal Gutter (model) | Maxim Domnin | /a/modular_metal_gutter | CC0 | depot_yard |
| Exterior Aircon Unit (model) | Monsta3D | /a/exterior_aircon_unit | CC0 | depot_yard; `.../art/booth/models/` |
| Utility Box 01 (model) | James Ray Cock | /a/utility_box_01 | CC0 | depot_yard |
| Metal Trash Can (model) | GurJas Studios | /a/metal_trash_can | CC0 | depot_yard (also town) |
| Cardboard Box 01 (model) | Rahul Chaudhary | /a/cardboard_box_01 | CC0 | depot_yard; reduced as `.../art/depot/carton.glb` |
| Barrel 03 (model) | Serhii Khromov | /a/barrel_03 | CC0 | depot_yard |
| Concrete Road Barrier (model) | Amal Kumar | /a/concrete_road_barrier | CC0 | depot_yard |
| Modular Chainlink Fence (model) | James Ray Cock, Amal Kumar | /a/modular_chainlink_fence | CC0 | depot_yard |
| Water Manhole Cover (model) | Raunox | /a/water_manhole_cover | CC0 | depot_yard |
| Old Tyre (model) | MP | /a/old_tyre | CC0 | depot_yard |
| Covered Car (model) | MP | /a/covered_car | CC0 | depot_yard (also town) |
| Modular Electricity Poles (model) | James Ray Cock | /a/modular_electricity_poles | CC0 | depot_yard |
| Fire Hydrant (model) | Gonçalo Felício | /a/fire_hydrant | CC0 | depot_yard |
| Asphalt 02 (texture) | Rob Tuytel | /a/asphalt_02 | CC0 | depot_yard |
| Concrete Floor Worn 001 (texture) | Dimitrios Savva, Rico Cilliers | /a/concrete_floor_worn_001 | CC0 | depot_yard |
| Box Profile Metal Sheet (texture) | Amal Kumar | /a/box_profile_metal_sheet | CC0 | depot_yard; base of `.../art/depot/cladding_grey_diff_2k.jpg` (shed cladding) |
| Concrete Wall 006 (texture) | Dario Barresi, Charlotte Baglioni | /a/concrete_wall_006 | CC0 | depot_yard; transfer shed |
| Painted Metal Shutter (texture) | Dario Barresi, Rico Cilliers, Charlotte Baglioni | /a/painted_metal_shutter | CC0 | depot_yard (also town) |
| Metal Plate 02 (texture) | Rob Tuytel | /a/metal_plate_02 | CC0 | depot_yard |
| Rubber Tiles (texture) | Amal Kumar | /a/rubber_tiles | CC0 | depot_yard |
| Rooftop Night (HDRI, 2k) | Greg Zaal | /a/rooftop_night | CC0 | `depot_yard/polyhaven/hdris/rooftop_night/rooftop_night_2k.hdr` (sky, `depot_yard.gd:6`) |
| Fern 02 (model) | Rob Tuytel, Rico Cilliers | /a/fern_02 | CC0 | `game/features/environments/industrial_loop/polyhaven/` (roadside ferns) |
| Dry Branches Medium 01 (model) | Rico Cilliers | /a/dry_branches_medium_01 | CC0 | industrial_loop (fallen branches) |
| Tree Stump 01 (model) | Rob Tuytel | /a/tree_stump_01 | CC0 | industrial_loop |
| Rock Moss Set 02 (model) | Kless Gyzen | /a/rock_moss_set_02 | CC0 | industrial_loop (rocks, landslide) |
| Dead Tree Trunk (model) | Rob Tuytel | /a/dead_tree_trunk | CC0 | industrial_loop |
| Can Rusted (model) | Rahul Chaudhary | /a/can_rusted | CC0 | industrial_loop (verge litter) |
| Plastic Bottle Gallon (model) | Rahul Chaudhary | /a/plastic_bottle_gallon | CC0 | industrial_loop |
| Wine Bottles 01 (model) | Rico Cilliers, Jurita Burger | /a/wine_bottles_01 | CC0 | industrial_loop |
| Trashbag (model) | Benny Weimer | /a/trashbag | CC0 | industrial_loop |
| Modular Street Seating (model) | Stuart Attenborrow | /a/modular_street_seating | CC0 | industrial_loop (listed in `POLYHAVEN.md`; use not described elsewhere) |
| Propane Tank (model) | Slinc | /a/propane_tank | CC0 | industrial_loop (gas station propane cage) |
| Utility Box 02 (model) | James Ray Cock | /a/utility_box_02 | CC0 | industrial_loop (store utility box) |
| Tarred Gravel (texture) | Dimitrios Savva | /a/tarred_gravel | CC0 | industrial_loop (forest road surface) |
| Leaf Scattered Gravel (texture) | Dimitrios Savva | /a/leaf_scattered_gravel | CC0 | industrial_loop (road edges) |
| Forest Leaves 04 (texture) | Rob Tuytel | /a/forest_leaves_04 | CC0 | industrial_loop (forest floor) |
| Pine Bark (texture) | Dimitrios Savva | /a/pine_bark | CC0 | industrial_loop (trunks, logs) |
| Rock Wall 02 (texture) | Rob Tuytel | /a/rock_wall_02 | CC0 | industrial_loop (hill rock faces) |
| Rustic Stone Wall (texture) | Dimitrios Savva | /a/rustic_stone_wall | CC0 | industrial_loop (dry-stone walls) |
| Weathered Plank Siding (texture) | Dimitrios Savva | /a/weathered_plank_siding | CC0 | industrial_loop (site office; town station bench) |
| Corrugated Iron (texture) | Jenelle van Heerden, Dimitrios Savva | /a/corrugated_iron | CC0 | industrial_loop (site office roof) |
| Rough Pine Door (texture) | Dimitrios Savva | /a/rough_pine_door | CC0 | industrial_loop |
| Stair Planks (texture) | Rob Tuytel | /a/stair_planks | CC0 | industrial_loop |
| Brushed Concrete 03 (texture) | Amal Kumar | /a/brushed_concrete_03 | CC0 | industrial_loop |
| Green Metal Rust (texture) | Rob Tuytel | /a/green_metal_rust | CC0 | industrial_loop (street lamp poles) |
| Leafy Grass (texture) | Charlotte Baglioni | /a/leafy_grass | CC0 | industrial_loop (valley road grass) |
| Chinese Hackberry Bark (texture) | Charlotte Baglioni | /a/chinese_hackberry_bark | CC0 | industrial_loop; base of `.../art/trees/red_alder_bark_diff.jpg` |
| Painted Plaster Wall (texture) | Amal Kumar | /a/painted_plaster_wall | CC0 | industrial_loop (store and shop walls) |
| Painted Brick (texture) | Amal Kumar | /a/painted_brick | CC0 | industrial_loop (shop walls) |
| Security Camera 01 (model) | Alexander Otterbeck, Yann Kervran | /a/security_camera_01 | CC0 | `.../art/booth/models/` (gatehouses) |
| Wall Clock (model) | PierreB3D | /a/wall_clock | CC0 | `.../art/booth/models/` |
| Office Notepads (model) | Ulan Cabanilla | /a/office_notepads | CC0 | `.../art/booth/models/` |
| Modified Thermos (model) | Alex Weber | /a/modified_thermos | CC0 | `.../art/booth/models/` |
| Medical Box (model) | Ulan Cabanilla | /a/medical_box | CC0 | `.../art/booth/models/` |
| Metal Office Desk (model) | Ulan Cabanilla | /a/metal_office_desk | CC0 | `.../art/dock_station/models/` (bay 9 desk) |
| Clipboard (model) | ProgrammerOnCoffee | /a/clipboard | CC0 | `.../art/dock_station/models/` |
| Stationery Supplies (model) | Mateusz Sadek | /a/stationery_supplies | CC0 | `.../art/dock_station/models/` |
| Fir Tree 01 (twig atlas) | Rob Tuytel, Rico Cilliers | /a/fir_tree_01 | CC0 | source in `source_assets/polyhaven/`; built into `.../art/conifer/conifer_branch_*.png`, `conifer_deadwood_*.png` |

Row count: 15 characters/motion + 11 vehicles/weapon + 23 environment models + 3 code/font + 60 Poly Haven = 112.

## 4. Made for the project


- **Sounds:** all 37 `.wav` files in `game/features/audio/` (first_drive, shed, loading, last_run, including `music.wav`) are synthesized by `source_assets/audio/*/synthesize.py`; Credits: "Every sound was made in code for this game."
- **Dash ring sheet:** `freight_van/art/ring/phone_ring.png` (`tools/art/make_phone_ring_sheet.py`).
- **Windshield fog textures:** `game/assets/textures/windshield/fog_*.png` (`tools/make_fog_textures.py`).
- **Particle textures:** `game/effects/textures/` (`tools/make_particle_textures.py`).
- **Headlight patterns:** `low_beam_pattern.png`, `high_beam_pattern.png`, drawn from UMTRI-2004-23 and UMTRI-2001-19 measurements (data credited, not an asset).
- **Signs, plates, markings:** `road_signs.png` (lettering rendered with macOS Arial Bold, font not copied), `number_plate.png` x2 (DIN Condensed Bold, not copied), `town_signs.png`, `store_interior.png`, `cage_mesh.png`, container markings (`container_codes/panels/lines.png`, in Barlow), `hazard_stripes.png`, shed signs and rack textures (`make_shed_signs.py`, `make_rack_textures.py`), `ripple_data.png`.
- **Derived from CC0:** `cladding_grey_diff_2k.jpg`, `red_alder_bark_diff.jpg`, the conifer cards.
- **Derived from CC BY:** `iveco/tail_lamp_masks.png` (shared under the Iveco model's CC BY 4.0).
- **Script-built models:** `streetlight.glb`, `office/site_office.glb`, `trees/red_alder.glb`, `containers.glb`, `racking.glb`, `shed_services.glb`, `fitout/shed_fitout.glb`, `fitout/shed_kit.glb`, `van_hinges.glb`, and `cabin.glb`, `steering.glb`, `body.glb`, `door.glb`, `tire.glb`, `bollard.glb`, `crate.glb`, `art/pallet.glb` (`tools/art/build_first_drive_art.py`, Codex and Claude Code).
- **Keyed animations:** `game/animations/phone_ring.tres`; `ethan_shock.tres` (keyed over EnterVan's last frame, a Mixamo base); the rifle's/pistol's part keys in `pistol_reload.tres`.
- **Shaders:** `game/shaders/` hand-written by the author; `wet_ground.gdshader` adapted by Claude Code from the two MIT sources above.

## 5. Flags and gaps found


- **No non-commercial or no-derivatives licence found.** Everything is CC BY 4.0, CC0, MIT, SIL OFL 1.1 or Adobe Mixamo terms.
- **Rifle not in the in-game Credits.** "M16 Assault Rifle" by jeandiz (CC BY 4.0) is credited in `weapons/rifle/ATTRIBUTION.md` and `SOURCES.md` but missing from `front_menu.gd`'s Credits text. The film's SOURCES must credit it.
- **Compound guard has no attribution section.** Security_Female_01 (Rocketbox, MIT) is in the Credits and `source_assets/rocketbox/README.md`, but has no section in `game/features/characters/ATTRIBUTION.md` and no row in `SOURCES.md`. The forklift driver (Construction_Male_07) has no row in `SOURCES.md` either.
- **Mixamo terms aren't a public licence.** The repo paraphrases Adobe's terms; it doesn't quote or link the terms text. The files "may not be shared on their own". The public repo makes them downloadable, which the author accepted (C27).
- **Iveco van has an extra condition** ("You must inform me of your usage"). The repo records it as met on 2026-11-03.
- **Honda E cockpit is shipped but unused.** It is still in `game/`, which the export includes, but only `test_cockpit.gd` references it. It is unlikely to appear in footage. It is credited.
- **Real brands that could show on screen:** the Dell logo on the monitor, the Kenwood name on the walkie-talkie, and the Chevrolet Suburban, Pilatus PC-12 and harbour crane (Credits disclaim affiliation with Chevrolet, Liebherr, Pilatus, Dell, Kenwood). Iveco badges were removed.
- **Poly Haven artists aren't named in game.** The Credits name them only as "Poly Haven, released CC0 by its artists". CC0 requires no credit.
- **Rocketbox MIT notice must go with the files.** The full notice is in the Credits.
- **Not shipped:**
  - "Traffic Cone Low-poly PBR" by MaX3Dd (CC BY 4.0, `source_assets/sketchfab/12_cone/README.md`) has no game file ("not made yet").
  - `game/experiments/rain_puddles_v3/` (the MIT shader trial) and `game/tests/calibration/` (Box Profile Metal Sheet normal maps, CC0) are excluded from export.
- **Pistol clips:** SOURCES.md says the pistol clips (Mixamo) and `ethan_pistol.tres` stay converted but unused since the rifle replaced the pistol for Ethan.
- **Godot Engine (MIT)** and its third-party components are credited in-game through `Engine.get_license_text()` and `get_copyright_info()`.

## 6. The 4K takes

All at `61cf104` (`build_id` e9d3b4cb2419aeb17af72194fdec7c6fc47ed2600d796e834f9d09eb3514b1d8, SHA-256 of `git ls-tree -r 61cf104 game`), 3840×2160, 30 fps, scripted input, recorded 2026-11-23/24. Each is a window of one Movie Maker run, cut at a constant 30 fps from the run's Theora file in one sequential decode; the run's own `.ogv` was deleted after its windows were checked frame for frame (its SHA-256 is in the run's folder).

| Take | Run (player and start) | Seconds of the run | SHA-256 |
| --- | --- | --- | --- |
| `m1_4k_30_80.mp4` | film_missions.gd -- 1 | 30-80 | `cfc5867c53fde430fa4556d8e83c4a0fdeaf8c04755d2f2312bbc479e3b1b41c` |
| `m1_4k_95_120.mp4` | film_missions.gd -- 1 | 95-120 | `f2591ffde7d5d55e358478d3b000918dd1ce5c7c55b33a7b634719d661f5e897` |
| `m1_4k_155_225.mp4` | film_missions.gd -- 1 | 155-225 | `932b4941e3a7bdfad791344212e941cffc3883fd16eef500023e6a2622c0452d` |
| `m1_4k_235_260.mp4` | film_missions.gd -- 1 | 235-260 | `0f2be5775dad2b84040f837cdcc44e35738efc31b0441bab21c6bfc32c38155c` |
| `m1_4k_275_312.mp4` | film_missions.gd -- 1 | 275-312 | `4d2f032fb6789c478f4220ee0b33dd8ead5aa99e57bede2658f0d6a9be477c6b` |
| `m2load_4k_25_50.mp4` | film_mission_two.gd -- load (its part: a stage 0 save, the van placed backed onto bay 9, doors open, chocked) | 25-50 | `776112dbf6f93b10d562b93ae8ec35fb976ae588e899f4a60e383e379c32a159` |
| `m2yard_4k_95_130.mp4` | film_mission_two.gd -- yard (its part: the game's stage 1 save, driven from where that save puts the van) | 95-130 | `4d6e64b04adfe7d1d2a49da9fd6c0ffc48931483319e81e165c89a8719448127` |
| `m3gate_4k_0_50.mp4` | film_missions.gd -- 3 gate (Last Run from its stage 3 save at the service gate, the game's own checkpoint) | 0-50 | `d1a667f9961b7c8447a72ad9c82e7f7e81517d5b375bfc96d116cdf0ff095e8a` |
| `m3gate_4k_80_135.mp4` | film_missions.gd -- 3 gate (Last Run from its stage 3 save at the service gate, the game's own checkpoint) | 80-135 | `8adb226b185c19cbefe7abacc320f2d21a52a94bc41ddae506e6e4838dbc9eb0` |
| `m3gate_4k_230_300.mp4` | film_missions.gd -- 3 gate (Last Run from its stage 3 save at the service gate, the game's own checkpoint) | 230-300 | `a8423ea3ccf333bc6e862335574c4d413d0e395adfcc7f14f956dd0e94705a8e` |
