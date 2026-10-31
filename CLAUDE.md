@AGENTS.md

## Project context

- Engine: Godot 4.7.2 stable (`README.md:142`), tag `"4.7"` (`game/project.godot:15`).
- Renderer: Compatibility, `renderer/rendering_method="gl_compatibility"` on desktop
  and mobile (`game/project.godot:125-126`). No `rendering/viewport/hdr_2d` key is set.
- Main scene: `res://app/first_drive.tscn` (`game/project.godot:14`). It instances
  the van as node `FreightVan` (`game/app/first_drive.tscn:5,14`).
- How the shaded object (dashboard cluster) is drawn:
  - `instruments.gd` is a `Control` that draws everything in `_draw()`: a
    `Color("080e12")` 640×256 background rect, two dials, gear/speed text,
    indicators, `LIGHTS` and `BRAKE` text
    (`game/features/vehicles/freight_van/instruments.gd:15-36`). The speed dial
    centre is `(155, 136)` and each dial hub is a radius-7 `Color("879c94")` circle
    (`instruments.gd:20,54`). It redraws every 0.05 s (`instruments.gd:8-12`).
  - `van_presentation.gd` creates it in `_displays()` and parents it to a 640×256
    `SubViewport` with `disable_3d = true` and `UPDATE_ALWAYS`; `use_hdr_2d` is not
    set (`game/features/vehicles/freight_van/van_presentation.gd:133-135,159-166`).
  - That viewport texture is shown in the cockpit on a `QuadMesh` with an unshaded
    `StandardMaterial3D` (`van_presentation.gd:136,190-203`).
- Game state that drives the effect: `freight_van.gd` (the `FreightVan`
  `CharacterBody3D`) owns `var headlights_on: bool = true`
  (`game/features/vehicles/freight_van/freight_van.gd:23`), toggled by the
  `headlights` action (`freight_van.gd:117-119`), bound to L (`game/project.godot:57-59`).
  Input is ignored unless `occupied` and `input_enabled` (`freight_van.gd:112`). Each
  physics tick (60 per second, not every rendered frame) `_physics_process` calls
  `_visual.update_vehicle(delta)` (`freight_van.gd:63,100`). Lamps, lenses and `LIGHTS`
  read `headlights_on` (`van_presentation.gd:257-260`, `instruments.gd:33-34`).
- Pause: `get_tree().paused` is set in `game/app/first_drive.gd:52-53`; Escape is
  `pause` (`game/project.godot:112-114`). No `process_mode` is set in
  `game/features/vehicles/freight_van/freight_van.tscn`.
- Recovery: R (`game/project.godot:107-109`) calls `_recover()` (`first_drive.gd:65-76`);
  `FreightVan.recover()` leaves `headlights_on` alone (`freight_van.gd:180-190`).
- 3D objects for the textured (foggy windshield) shader, built in code in
  `_windows_and_wipers()` (`van_presentation.gd:206-228`):
  - Front windshield: 2.12×1.08 `QuadMesh` at `(0, 2.17, -1.34)`, `rotation.x = 0.32`,
    with a code-made `ShaderMaterial` from `windshield.gdshader`
    (`van_presentation.gd:6,215-220`); `wetness`, `wipers_on` and `sweep_angle` are set
    every physics tick (`van_presentation.gd:273-276`).
  - Side windows: two `Build.box` panes (0.015×0.9×1.48) at `x = ±1.13` sharing one
    code-made transparent `StandardMaterial3D` (`van_presentation.gd:207-214`). Index 0
    (`side = -1`) is the driver's (camera at `x = -0.52`, `van_presentation.gd:120`),
    lowered by `left_window` (`van_presentation.gd:254-256`) on J
    (`game/project.godot:82-84`; `tools/tests/first_drive_integration.gd:66-68`).
- Night environment: built in code with `fog_enabled = true` and no tonemap setting,
  so Godot's default Linear tonemap at exposure 1.0 applies
  (`game/features/environments/industrial_loop/industrial_loop.gd:42-53`).
- Asset folders: `game/assets/textures/windshield/`, `game/materials/windshield/`
  (author's choice in `CHANGE-BRIEF.md` §5.6; an exception to `AGENTS.md`).
- Test runner: `scripts/run-test.sh <test-file.gd> <fps>` runs Godot headless on
  `game/` with `--fixed-fps`, a 120 s `timeout`, `game/tests/` first then
  `tools/tests/`, logs to `logs/<name>_<fps>fps.log`, and fails on `SHADER ERROR` or
  `SCRIPT ERROR` (`scripts/run-test.sh:1-11`). Godot comes from `$GODOT`, `godot` on
  `PATH`, or `/Applications/Godot.app/Contents/MacOS/Godot` (`scripts/run-test.sh:6`).
  New Assignment 5 tests go in `game/tests/`.
- Exact test commands, from the repository root:

  ```sh
  scripts/run-test.sh first_drive_regression.gd 60
  scripts/run-test.sh first_drive_integration.gd 60
  ```

  They print `REGRESSION RESULT: n/m passed` (`tools/tests/first_drive_regression.gd:58-60`)
  and `BEHAVIOR RESULT: n failures`; the integration suite already presses `headlights`
  (`tools/tests/first_drive_integration.gd:57-59,121`). Use `30` or `144` as the second
  argument for other rates. Baseline 2026-10-28 at 60 FPS: 64/64 and 29/29, exit 0
  (`logs/first_drive_*_60fps.log`). `capture_scene.gd` (needs a window) and
  `check_first_drive_art.py` (Python) are not wrapper tests.

## Headless facts

Checked on this machine on 2026-10-28 (Godot 4.7.2, macOS 26.6.2):

- `godot` is not on `PATH`, so the wrapper uses the `/Applications` binary;
  `timeout` is `/opt/homebrew/bin/timeout`.
- A headless run draws nothing; whether anything looks right is a human check.
- `get_shader_uniform_list()` works headless; a shader that fails to parse prints
  `SHADER ERROR` and returns an empty list.
- Defaults are not reported headless (`shader_get_parameter_default` returns null),
  so tests read them from the shader source text.
- `set_shader_parameter()` with an undeclared name raises no error and reads back;
  only the uniform-list check catches a renamed uniform.
- A `ShaderMaterial` stores 2.0 for a `hint_range(0.0, 1.0)` uniform unclamped;
  what the shader draws with it is checked by a capture.
- Exit code 0 is not proof of a clean run: both baseline logs end with an engine
  "resources still in use at exit" ERROR, which the wrapper does not fail on.

## Current change

@CHANGE-BRIEF.md

## Working rule

- The author approves every step before it happens: "at each step take my approval and
  then only do it" (2026-10-30). For each step:
  1. Describe it: the files and the commands.
  2. Wait for approval.
  3. Do only that step and show the real output.
  4. Stop.
- All work happens on the `develop` branch. `main` stays exactly as the last graded
  submission, and it changes only through a pull request the author approves.
- Each agent run ends by writing `HANDOFF.md`. It lists the files changed, the exact test
  commands with their real results, what the next run may rely on, and what is
  unverified.
- Each run starts by reading `HANDOFF.md` and rerunning every test it lists. The file
  does not exist until Run 1 ends.

## Ownership

- Every file in `game/shaders/` is hand-written by the human. Agents never create,
  edit, reformat, rename or delete files there, even to fix an error; report shader
  problems to the human instead.

## Out of scope (Phase 1)

- `headlights_on`, the `headlights` action (L), the `LIGHTS` text and the switch click.
  - The headlight lights and lenses change only as `CHANGE-BRIEF.md` §4 says.
  - The dimming driver and `night_cluster` only read `headlights_on` and never set it.
- Van movement, steering, collisions, recovery, gear, indicators, wipers, rain, window
  motion, audio, and every other control or key binding.
- The existing glass and the fog materials, which change only with the author's OK:
  - the glass is `windshield.gdshader` and its material, plus the side-window
    `StandardMaterial3D`;
  - the fog materials are `light_fog.tres` and `heavy_fog.tres`. The fog is re-checked by
    eye under Forward+.
  - If the author approves new fog values, `test_materials.gd` changes with them, recorded
    as a dated revision in `CHANGE-BRIEF.md`. Every other existing test keeps passing
    unchanged.
- The tonemap stays Linear unless lit surfaces clip to white. Any change is shown to the
  author with before/after stills first. Volumetric fog stays off.
- `project.godot` changes only its rendering method.
- The interior, the road's shape and material, models, other scenes, autoloads and new
  controls are later phases in `ROADMAP.md`.

## Unconfirmed

- Whether the night-cluster colours stay exactly at the Assignment 5 values under
  Forward+ (prediction P3). Run 1 measures it.
- The final low-beam values. The 2026-10-30 test values are starting points.
- What a Godot 4.7.2 macOS export needs on this Mac (signing mode, the `.zip`
  contents). Run 3 checks it.
