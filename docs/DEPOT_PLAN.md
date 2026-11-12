# The bigger depot, part 1: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the transfer shed and its 2c-1 yard with the bigger depot's part 1: the level
platform cut into the hill, the 50 x 30 m shed with its closed doors and office, the yard re-laid
around it, and five yard lights.

**Architecture:** `transfer_shed.gd` keeps the gate and builds three new children in order:
`Ground` (`depot_ground.gd`: the flat plot, the tree clearing and the retaining walls),
`Building` (`transfer_building.gd`: the shed's shell, openings, doors and office) and `Yard`
(`transfer_yard.gd`, rewritten: paving, markings, walkway, bays, signs, light positions). The
generic warehouse loop in `industrial_loop.gd` stops building the old box for the transfer shed
but still draws its random numbers, so nothing else in the world changes. Door models are made
game-ready by a Blender script from `source_assets/sketchfab/` and Poly Haven.

**Tech Stack:** Godot 4.7.2 (GDScript, headless tests), Blender 5.2.2 in background mode
(Python), Poly Haven's API.

**Spec:** `docs/PHASE_BRIEF.md`, revision "Phase 2, step 2c revised: the bigger depot" (rules
E1–E10). Research: `docs/DEPOT_RESEARCH.md`.

## Global Constraints

- Godot 4.7.2 names only; GDScript with tabs, typed, lines under 100 characters, no inline comments.
- Never create, edit or rename anything in `game/shaders/`.
- Outside assets only under CC0, CC-BY (credited in game and in `SOURCES.md`) or MIT (C11, C55).
- Tests run as `LOG_DIR=logs/phase_2/step2c_p1/<step> scripts/run-test.sh <test>.gd 60 300`.
- The gate, booth, barrier, guard and spur (2b) and Mission 1 stay as they are.
- If the struck man's fall moves (test_collision, test_hit_speeds), report it before changing anything (C57).
- Commit only with the author's OK, labelled "(agent)", with no co-author trailer.
- Numbers (world metres, north is −z): platform x −92..−26, z −13..55; shed x −90..−40, z −10..20,
  eaves 9.0, 5° roof; dock floor 1.3; truck docks at x −80 + 4n (n = 0..7), openings 2.74 x 3.05;
  van bay 9 at x −47.75; drive-in door at x −42.75, 3.7 x 2.9 at the yard's level; office x −90..−82,
  z 12..20; court z 20..55; apron z 20..35, x −90..−40; car bays x −88.4..−83.4, z 42.4..54.9;
  trailer bays x −38.7..−28.5, z 23..37; lights (−79, 53.8), (−58, 53.8), (−36, 53.8), (−89.6, 30),
  (−27.4, 30).

## Review Focus

- The van's way from the gate to bay 9 (in, right, then back): nothing solid may stand in it; Task 4 adds a corridor check.
- A check that finds no nodes must fail, not pass: every new check asserts a non-empty set first.
- Terrain must not show in front of a wall or poke through the paving at the platform's edges (grid points every 2 m); Task 1's E2 samples 0.5 m in front of every wall.
- The old shed must leave nothing behind: its box, roof slab, windows, door panels and dock blocks (Task 2's E3 checks none remain near x −71, z 26).
- The rain cap (eight volumes) will leave some yard lights dry near the shed until part 2; the stills record it, nothing in part 1 hides it.

---

### Task 1: The platform and its retaining walls

**Files:**
- Create: `game/features/environments/industrial_loop/depot_ground.gd`
- Modify: `game/features/environments/industrial_loop/transfer_shed.gd` (`flat_plots()`, `clearings`, `build()`)
- Modify: `game/features/environments/industrial_loop/industrial_loop.gd:239-244` (skip the transfer shed's warehouse plot), `:396-410` (skip its box), `:889` (build call)
- Test: `game/tests/test_mission_two.gd` (new `_check_ground`)

**Interfaces:**
- Produces: `DepotGround` (`depot_ground.gd`, `extends Node3D`): `const PLATFORM := Rect2(-92.0, -13.0, 66.0, 68.0)`,
  `const FLAT := Rect2(-90.0, -12.0, 62.0, 65.0)`, `const CLEARING := Rect2(-96.0, -17.0, 74.0, 76.0)`,
  `static func flat_plots() -> Array[Rect2]`, `func build(terrain: Node3D, concrete: Material) -> void`,
  `func top_runs() -> Array[Dictionary]` (each `{"from": Vector3, "to": Vector3, "outward": Vector3}`
  along a wall's top, for the fence). Walls: `RetainingWallNorth` along z −13 (x −92.4..−25.6), and
  stepped 2 m segments `RetainingWallWest*` along x −92 and `RetainingWallEast*` along x −26 wherever
  the ground 3 m behind stands 0.25 m or more; each wall solid, its top the highest ground 3 m behind
  plus 0.2 m; thickness 0.4 m, outside the platform.

- [x] **Step 1: Write the failing checks** in `_check_ground(world)`: E1 (`absf(height_at) <= 0.02` at every
  metre inside the platform, and `forest._is_blocked` true there) and E2 (for each wall, 0.5 m inside
  the platform `height_at <= 0.02`; 3 m outside, `height_at <= wall top`); assert the wall set is non-empty.
- [x] **Step 2: Run** `test_mission_two.gd`; expect E1, E2 to FAIL (the platform is not cut).
- [x] **Step 3: Implement** `depot_ground.gd`; `transfer_shed.flat_plots()` returns `[DepotGround.FLAT, SPUR_PLOT]`
  (APRON_PLOT and the 2c-1 plots go); `clearings` gets `DepotGround.CLEARING`; `industrial_loop`
  skips the transfer shed's entry in `_flat_plots()` and its box (still drawing its two random numbers).
- [x] **Step 4: Run** `test_mission_two.gd`; E1, E2 PASS.

### Task 2: The shed's shell and the office

**Files:**
- Create: `game/features/environments/industrial_loop/transfer_building.gd`
- Create: `game/features/environments/industrial_loop/polyhaven/textures/factory_wall/` (diff made grey, nor_gl, arm, 2k)
- Modify: `transfer_shed.gd` (build `Building`), `SOURCES.md` (Factory Wall row)
- Test: `game/tests/test_mission_two.gd` (new `_check_building`)

**Interfaces:**
- Consumes: Task 1's `Ground`.
- Produces: `TransferBuilding`: `const BUILDING := Rect2(-90.0, -10.0, 50.0, 30.0)`, `const EAVES := 9.0`,
  `const DOCK_FLOOR := 1.3`, `const DOCKS: Array[float] = [-80.0, -76.0, -72.0, -68.0, -64.0, -60.0, -56.0, -52.0]`,
  `const VAN_BAY := -47.75`, `const DRIVE_IN := -42.75`, `const DOCK_OPENING := Vector2(2.74, 3.05)`,
  `const DRIVE_IN_OPENING := Vector2(3.7, 2.9)`, `const OFFICE := Rect2(-90.0, 12.0, 8.0, 8.0)`,
  `func build(cladding: Material, roof: Material, concrete: Material) -> void`. Nodes: `ShedBody`
  (StaticBody3D, solid walls around the openings), `DockOpening1`..`DockOpening9` and `DriveInOpening`
  (Marker3D at each opening's sill centre), `OfficeLight` (OmniLight3D inside), `OfficeDoor`.

- [x] **Step 1: Write the failing checks** `_check_building(shed)`: E3 (the `ShedBody` shapes' union spans
  x −90..−40 and z −10..20 within 0.05 m, top at 9.0 ± 0.1 before the roof; no MeshInstance3D left within
  2 m of the old box's centre (−71, 4.76, 26) except the new building's); E4's positions (markers at
  x −80 + 4n, −47.75 and −42.75, z 20, y 1.3 for docks and 0 for the drive-in); E5 (`OfficeLight.light_energy > 0`
  and inside `OFFICE`; `OfficeDoor` at the yard's level on z 20).
- [x] **Step 2: Run**; expect E3–E5 FAIL.
- [x] **Step 3: Implement** `transfer_building.gd` (walls in the grey Factory Wall cladding over the 1.3 m
  concrete dock face, the 5° gable roof in `corrugated_iron`, gutters and downpipes on the front, the
  office's two floors of lit windows and its door); fetch Factory Wall with the Poly Haven API and
  make its diffuse map grey with PIL (`-I`); add the `SOURCES.md` row.
- [x] **Step 4: Run**; E3–E5 PASS.

### Task 3: The doors' game files, and credits

**Files:**
- Create: `tools/art/convert_depot_models.py`
- Create: `game/features/environments/industrial_loop/art/depot/dock_door.glb`, `drive_in_shutter.glb` (+ textures)
- Modify: `transfer_building.gd` (a door in each opening), `tools/tests/check_first_drive_art.py`,
  `game/features/ui/menus/front_menu.gd` (credits), `game/tests/test_menus.gd` (CREDITED), `SOURCES.md`
- Test: `test_mission_two.gd` (E4's doors), `check_first_drive_art.py`, `test_menus.gd`

**Interfaces:**
- Consumes: Task 2's opening markers and `DOCK_OPENING`, `DRIVE_IN_OPENING`.
- Produces: `convert_depot_models.py` usage `Blender -b --factory-startup --python-exit-code 1 --python
  tools/art/convert_depot_models.py -- <model> ...` with models `dock_door` (from
  `source_assets/sketchfab/01_door_maxwell/`: the red wall and frame removed, scaled to 2.74 x 3.05 m,
  under 6,000 triangles, textures at most 1024) and `drive_in_shutter` (Poly Haven `rollershutter_door`,
  scaled to 3.7 x 2.9 m). Door nodes `DockDoor1`..`DockDoor9`, `DriveInDoor`, each with a solid box.

- [x] **Step 1: Write the failing checks**: E4's doors (each opening has a door whose AABB covers the
  opening within 3 cm and whose body is solid); the art check's two new entries (file exists, under
  6,000 triangles, textures at most 1024); `test_menus.gd` CREDITED gains "Maxwell autodoors".
- [x] **Step 2: Run** the three; expect them to FAIL.
- [x] **Step 3: Implement** the script, run it, import with Godot (`--headless --editor --import`), place the
  doors, add the credits and `SOURCES.md` rows.
- [x] **Step 4: Run** the three; PASS.

### Task 4: The yard re-laid, the fence and the lights

**Files:**
- Modify (rewrite): `game/features/environments/industrial_loop/transfer_yard.gd`
- Modify: `transfer_shed.gd` (fence runs; `yard_lamps`, `yard_lamp_headings`), `game/tests/test_lamp_rain_state.gd` (19)
- Test: `test_mission_two.gd` (`_check_yard` rewritten for E6–E8, `_yard_spots()` for the new court)

**Interfaces:**
- Consumes: `DepotGround.PLATFORM`, `top_runs()`; `TransferBuilding` constants.
- Produces: `TransferYard.LAMPS: Array[Vector3]` = the five lights, `LAMP_HEADINGS: Array[float]` =
  `[-PI / 2.0, -PI / 2.0, -PI / 2.0, PI, 0.0]`; node names kept from 2c-1 where they still mean the
  same (`YardAsphalt*`, `DockApron`, `BayLine`, `BayNumber`, `Arrow`, `Walkway`, `WalkwayRail`, `Sign`,
  `Kerb`, `YardBollard`).

- [x] **Step 1: Rewrite the failing checks**: E6 (every 1 m point inside the platform but outside the
  building is under a `YardAsphalt*` or `DockApron` piece; every 0.5 m along the platform's edge but
  the gate's lane lies within 0.3 m of a fence or wall collider; the court's depth, from the
  `DockFace` mesh's front to the fence's run along z 55, is at least 35 m; the rail between the
  walkway and the court runs from z 21 to 42); E7 (nine bay lines' pairs, numbers 1–9, the 2c-1 arrows
  and sign checks); the corridor check (no collider within 1.5 m of the van's way: (−70, 58) →
  (−70, 46) → (−62, 40) → (−41, 37.5) → (−47.75, 22)); E8 in `test_lamp_rain_state.gd` (19 volumes).
- [x] **Step 2: Run** both tests; expect FAIL.
- [x] **Step 3: Implement** the yard, the fence (gate runs as built; x −92 and x −26 runs at the yard's
  level where no wall stands; chain-link along `top_runs()`), and the five lights.
- [x] **Step 4: Run**; PASS.

### Task 5: Every suite, mutations, stills and records

**Files:**
- Modify: `tools/captures/capture_depot.gd` (views for the new layout)
- Modify: `docs/PHASE_BRIEF.md` (part 1 built), `HANDOFF.md`, `docs/AUTHOR_PROMPTS_AND_DECISIONS.md`

- [x] **Step 1: Import** (`HOME=$PWD/.scratch-home Godot --headless --editor --path game --import`); no errors.
- [x] **Step 2: Every suite** with `run_suites.sh` into `logs/phase_2/step2c_p1/suites/`; every run exits 0 with the
  baseline's counts but Mission 2's and the lamp rain's; if the collision or hit suites move, stop and report (C57).
- [x] **Step 3: Mutations** on an APFS clone, each exit 1 on its own check: the platform unflattened; a wall
  missing; the old warehouse box back; one dock opening moved 0.5 m; the office light off; a door missing;
  the apron unpaved; a fence run missing; a light removed.
- [x] **Step 4: Stills** with `capture_depot.gd` in a window (the author is told first), read against the
  brief's predictions.
- [x] **Step 5: Records**, then ask the author to commit.

---

# The bigger depot, part 2: Implementation Plan

**Goal:** The docks at work (rules F1–F8 in `docs/PHASE_BRIEF.md`, revision "part 2: the docks at
work"): seals, bumpers, levellers, lights, signals, two open docks with the lit inside, and the dock
front's rain.

**Architecture:** `transfer_building.gd` gains the dock fittings, lights, signals, open doors and
the inside, from models made by `tools/art/convert_depot_models.py` (new jobs `dock_seal`,
`dock_leveller`, `forklift`, `pallet_jack`, `pallet`, textures at most 1024). B1 gains
`game/effects/lamp_rain_dock.tscn` (the door scene's settings, its box 23 x 0.1 x 0.6 half-extents
and its counts scaled to its area), placed by `industrial_loop.gd` from a position the shed
exposes (`dock_rain_at`).

**Numbers:** seals on docks at x −80 + 4n and −47.75; bumpers at x c ± 1.25, 0.25 wide, 0.45
tall, top 1.3, 0.13 proud; lights at (c, 4.95, 20.25); signals at (c + 1.75, 2.6, 20.1); levellers
centred 1.2 m inside (z 18.6); open docks 5 (x −64) and 9 (x −47.75); bay lights at z 16 and 9,
x −82..−42 every 8 m, y 8.4; the dock rain volume centred at (−64.0, 4.6, 20.9).

### Task 1: Seals, bumpers and levellers (F1–F3), with their art and credits
- Tests first: F1–F3 in `_check_docks`; the art check's `dock_seal.glb`, `dock_leveller.glb`
  entries; `test_menus.gd` unchanged (Maxwell autodoors is credited).
- Then: the two conversion jobs, the fittings in `transfer_building.gd`, `SOURCES.md`, ATTRIBUTION.
### Task 2: Lights and signals (F4, F5)
- Tests first: F4, F5. Then: ten `DockLight*` SpotLight3D with fixtures, nine `DockSignal*`.
### Task 3: The open docks and the inside (F6), with their art and credits
- Tests first: F6; the art check's `forklift.glb`, `pallet_jack.glb`, `pallet.glb`; `test_menus.gd`
  CREDITED gains "Kamran Mughal", "FFeller", "widthRider".
- Then: the three conversion jobs; doors 5 and 9 open, arm lights, bay lights, lanes, props.
### Task 4: The dock front's rain (F7)
- Tests first: `test_lamp_rain_config.gd` gains `lamp_rain_dock.tscn`; `test_lamp_rain_state.gd`
  counts 20 and checks the court's active set and the shed's dry inside.
- Then: the scene, `dock_rain_at`, the placement.
### Task 5: Every suite, mutations, stills, GPU price, records, and the author's OK to commit.

**Status, 2026-11-11:** tasks 1–5 done, committed at the author's word (#227). What was
built, where it differs from the numbers above (the bay lights' rows, the dock rain's box, the
American pallet, a fourth prop job for the carton) and every result are in `docs/PHASE_BRIEF.md`,
revision "part 2: built".

---

# Step 2d, backing onto bay 9: Implementation Plan

**Goal:** rules G1–G7 in `docs/PHASE_BRIEF.md` (revision "step 2d: backing onto bay 9"), with the
author's decisions U1 a, U2 a, U3 a (#228): bay 9's lift and lights, the van's rear doors, and a
docking judged at the bumpers, retried on the spot, then chocked by Ethan on foot.

**Architecture:** the shed's building cuts a pit for the lift (new `dock_lift.gd`), adds bay 9's
inside light and switches both lights (`set_bay_nine_docked`); the yard adds two wheel guides and
the chock's resting place. The van owns its rear doors (`rear_doors_open`, cut from the Iveco body
by `tools/art/convert_iveco.py` as `RearDoorLeft` and `RearDoorRight`, swung by the presentation)
and `chocked`. The transfer shed judges the stop at bay 9 (`bay_nine_report()`) and places the
chock; Mission 2's script turns that into objectives and Ethan's on-foot actions; the app routes
E and the hint to those actions before boarding.

**Numbers †:** the platform 1.83 x 2.44 m, its top flush with the dock floor (1.3 m), in a pit
1.87 x 2.46 m behind the door down to 0.05 m; the inside light on the right pier at
(−45.5, 3.0, 19.7), the lift's controls below it; the wheel guides' inner faces 1.25 m either side
of x −47.75, from z 20.5 to 24.0, 0.2 m tall (their colliders 0.35 m), flared to z 25; the
docking: the van's rear within 0.3 m of the bumpers' face (z 20.13), within 0.2 m of the bay's
centre line and 3° of square, arrived at 1.4 m/s or less; the chock in front of the driver's side
rear wheel. The model's hold floor stands 0.46 m up (a real Daily's about 0.68 m): 2e's lift
follows the model.

### Task 1: The lift, the lights, the guides and the chock's place (G1, G2 at rest)
- Tests first (new `game/tests/test_bay_nine.gd`): G1; bay 9 green outside and red inside; two
  solid wheel guides; the chock at rest by bay 9.
- Then: the pit, `dock_lift.gd`, the inside light, `set_bay_nine_docked`, the guides, the chock,
  a hazard-stripe texture from `tools/art/make_depot_textures.py`.
### Task 2: The van's rear doors (G3)
- Tests first: G3 by real keys on foot, in Mission 2.
- Then: the conversion's two rear doors and their pivots; the presentation's swing; the van's
  `rear_doors_open`; the mission's on-foot action and the app's routing.
### Task 3: Backing onto bay 9, the retries and the chock (G2, G4–G6)
- Tests first: G4–G6 and G2's switch, by real keys.
- Then: `bay_nine_report()`, the objectives and retry messages, the chock and `chocked`.
### Task 4: Every suite, mutations, the strip's stills, records, and the author's OK to commit.

**Status, 2026-11-11:** tasks 1–4 done, committed at the author's word (#229). The
centre line's rule became 0.1 m (from 0.2 m); what was built and every result are in
`docs/PHASE_BRIEF.md`, revision "step 2d: backing onto bay 9, built".
