@AGENTS.md

## Project context

- Engine: Godot 4.7.2 stable (`README.md:142`), tag `"4.7"` (`game/project.godot:15`).
- Renderer: Compatibility, `renderer/rendering_method="gl_compatibility"` on desktop
  and mobile (`game/project.godot:125-126`). No `rendering/viewport/hdr_2d` key is set
  in `game/project.godot`.
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
  (`game/features/vehicles/freight_van/freight_van.gd:23`) and toggles it on the
  `headlights` action (`freight_van.gd:117-119`), which is bound to L
  (`game/project.godot:57-59`, physical keycode 76). Input is ignored unless
  `occupied` and `input_enabled` (`freight_van.gd:112`). Each frame the van calls
  `_visual.update_vehicle(delta)` from `_physics_process` (`freight_van.gd:63,100`).
  `van_presentation.gd` reads `headlights_on` for lamps and lenses
  (`van_presentation.gd:257-260`); `instruments.gd` reads it for `LIGHTS`
  (`instruments.gd:33-34`).
- Pause: `first_drive.gd` sets `get_tree().paused` (`game/app/first_drive.gd:52-53`);
  the `pause` action is Escape (`game/project.godot:112-114`). `freight_van.tscn`
  sets no `process_mode` (`game/features/vehicles/freight_van/freight_van.tscn`).
- Recovery: R (`game/project.godot:107-109`) calls `_recover()`
  (`game/app/first_drive.gd:65-76`); `FreightVan.recover()` does not touch
  `headlights_on` (`freight_van.gd:180-190`).
- 3D objects for the textured (foggy windshield) shader, all built in code inside
  `_windows_and_wipers()` (`van_presentation.gd:206-228`):
  - Front windshield: a 2.12×1.08 `QuadMesh` at `(0, 2.17, -1.34)`, `rotation.x =
    0.32`, using a `ShaderMaterial` created in code from the preloaded
    `windshield.gdshader` (`van_presentation.gd:6,215-220`). Its `wetness`,
    `wipers_on` and `sweep_angle` parameters are set every frame
    (`van_presentation.gd:273-276`).
  - Side windows: two `Build.box` panes (0.015×0.9×1.48) at `x = ±1.13` sharing one
    transparent `StandardMaterial3D` made in code (`van_presentation.gd:207-214`).
    Index 0 is the left (`side = -1`) pane, moved down by `left_window`
    (`van_presentation.gd:254-256`). The driver camera sits at `x = -0.52`
    (`van_presentation.gd:120`); `window_left` is J (`game/project.godot:82-84`) and
    the integration test calls it the driver window
    (`tools/tests/first_drive_integration.gd:66-68`).
- Night environment is built in code with `fog_enabled = true`
  (`game/features/environments/industrial_loop/industrial_loop.gd:42-53`).
- Test runner: `scripts/run-test.sh <test-file.gd> <fps>`. It runs Godot headless on
  `game/` with `--fixed-fps <fps>`, a 120 s `timeout`, prefers `game/tests/<file>`
  and falls back to `tools/tests/<file>`, logs to `logs/<name>_<fps>fps.log`, and
  fails on `SHADER ERROR` or `SCRIPT ERROR` (`scripts/run-test.sh:1-11`). Godot is
  taken from `$GODOT`, then `godot` on `PATH`, then
  `/Applications/Godot.app/Contents/MacOS/Godot` (`scripts/run-test.sh:6`).
- Exact test commands, from the repository root:

  ```sh
  scripts/run-test.sh first_drive_regression.gd 60
  scripts/run-test.sh first_drive_integration.gd 60
  ```

  The regression suite prints `REGRESSION RESULT: n/m passed`
  (`tools/tests/first_drive_regression.gd:58-60`); the integration suite prints
  `BEHAVIOR RESULT: n failures` and already toggles headlights with a real
  `headlights` action (`tools/tests/first_drive_integration.gd:57-59,121`). For
  30/144 FPS runs, pass `30` or `144` as the second argument.

## Current change

@CHANGE-BRIEF.md

## Ownership

- Every file in `game/shaders/` (`night_cluster.gdshader`,
  `foggy_windshield.gdshader`, `hint_experiment.gdshader`) is hand-written by the
  human. Agents never create, edit, reformat, rename, or delete files there, even
  to fix an error. Report shader problems to the human instead.

## Out of scope

- Headlight logic, the `headlights_on` variable, lamps and lens materials, the
  `LIGHTS` text, and the switch click sound. The dimming driver only reads
  `headlights_on`; it never sets it.
- Van movement, steering, collisions, recovery, gear, indicators, wipers, rain,
  window motion, audio, and every other control or key binding.
- The existing glass: the windshield `ShaderMaterial` and `windshield.gdshader`, and
  the side-window `StandardMaterial3D`. Fog overlays are added beside them, never
  in place of them.
- Existing tests, including the L-key check; they must keep passing unchanged.
- Other objects, scenes, the world environment, renderer, and `project.godot`
  settings. World-fog-off comparisons are runtime-only and never saved.
- No fog animation, new controls, autoloads, or screen-texture sampling. At most
  one test-only screenshot key, as the brief allows.

## Unconfirmed

- Tonemap: `industrial_loop.gd` does not set `tonemap_mode` or `tonemap_exposure`
  in the lines found (`industrial_loop.gd:42-53`). The brief's "Linear, exposure
  1.0" would rest on engine defaults; not verified in a running scene.
- Whether `timeout` (GNU coreutils, not stock macOS) and `godot` are on this
  machine's `PATH`; I could not run the check.
- Which node the `night_cluster` material goes on (the `instruments.gd` Control or
  another node), and where the dimming driver lives. Neither exists yet.
- Baseline pass counts (64/64 regression, 29/29 integration at 60 FPS) come from
  a commit message and `README.md:16`; I did not rerun the suites.
- `capture_scene.gd` needs a window and `--` user arguments
  (`tools/tests/capture_scene.gd:3-6`), so it cannot run through
  `scripts/run-test.sh`, which is headless and passes no user arguments.
  `tools/tests/check_first_drive_art.py` is Python and also outside the wrapper.
- No `game/tests/` exists, so where new tests go is undecided.
- The brief's `game/assets/` and `game/materials/` do not exist, and `AGENTS.md`
  puts feature assets under `game/features/`; ask before creating either path.
- I did not read the contents of `game/shaders/*.gdshader`.
