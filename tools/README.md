# Development tools

This directory contains standalone validation utilities outside the runtime
project. No external testing framework is required. The offline art tools use
already installed NumPy and Pillow; Godot runtime does not depend on them.

Keep these utilities outside `game/` so they are not imported or shipped as runtime
content. Godot editor plugins, if later needed, belong under `game/addons/` instead.
Do not create tool or plugin infrastructure solely to populate a directory.

For each future tool, document its purpose, prerequisites, repository-root command,
inputs, outputs, and whether it modifies files. Prefer a small script using
existing capabilities before adding a dependency. Keep generated packages and
reports in `builds/`; disposable caches can use the ignored `tools/.cache/` path.

## First-drive regression checks

`tests/first_drive_regression.gd` exercises real Godot physics and imported audio,
then tests checkpoint writes and failure feedback using isolated files. It
requires Godot 4.7.2 and an imported `game/` project. From the repository root:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path game --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
  --script ../tools/tests/first_drive_regression.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
  --script ../tools/tests/first_drive_integration.gd
```

The first command creates/updates Godot's ignored import cache and attempts normal
editor settings access. The second loads the existing main scene and its source
WAVs, injects input, and temporarily creates test obstacles. It writes only its
unique temporary checkpoint fixtures and removes those fixtures on a completed
run. Test checkpoint paths are set before scene initialization; player checkpoint
files are not changed. Startup can still attempt the engine's normal user-data
directory; this session restricts that location.

The checks cover clear-ground turning, adjacent obstacles, measured forward and
reverse speed, full WAV loop frame counts, one-shot effects, successful saving,
replacement and write failures, preserving an earlier checkpoint, accurate HUD
feedback, reload validation, and entry/exit and wall collisions. Expected fault
injection cases are explicitly labeled before their warnings. The process exits
1 for failed assertions or a thirty-second timeout, and 0 when assertions pass.

`tests/first_drive_integration.gd` also exercises accessory controls, windows and
mix changes, gear and camera state, pause/resume, and vehicle handoff. It waits for
physics updates after input so checks do not depend on rendering-frame timing.
Its isolated checkpoint filename is assigned before scene initialization. It has
a thirty-five-second timeout and the same 0/1 assertion exit convention.

Current results: **64/64 regression checks**, **29/29 integration checks**. Initial
runtime and test findings, expected fault warnings, and environment limits are
recorded in the validation report.

Graphics and subjective audio quality are not tested headlessly. Consult
[VALIDATION.md](../docs/VALIDATION.md) for actual results and environment errors;
an exit code alone is insufficient. The author's interactive phase checklist is
[PLAYTEST.md](../docs/PLAYTEST.md).

Tools must preserve source assets and primary documents unless explicitly asked
to modify them. Game code must never depend on this directory at runtime.

See [the development guide](../docs/DEVELOPMENT.md) for conventions and validation,
and [the architecture guide](../docs/ARCHITECTURE.md) for ownership boundaries.

## First-drive art authoring and validation

`art/build_first_drive_art.py` uses `art/mesh_authoring.py` to export original GLB
meshes, surface textures, and a geometry report. Run from the repository root with
Python 3, NumPy, Pillow, and the macOS Arial font available:

```sh
python3 tools/art/build_first_drive_art.py
python3 tools/tests/check_first_drive_art.py
```

The first command overwrites seven GLBs and generated PNGs in the van/industrial
loop `art/` folders, plus the source geometry report. Preserve later replacements
before rebuilding. It does not launch Blender or change engine settings. The
second command is read-only: it independently checks GLB structure, finite
geometry, normal length, vertex indices, winding, geometry limits, and van bounds.
Failure exits 1. These checks do not verify shaders, appearance, or performance.

[VISUALS.md](../docs/VISUALS.md) records package versions, output ownership,
provenance, the Blender startup failure, and graphical review requirements.
