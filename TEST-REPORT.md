# TEST-REPORT — Assignment 5

| Field | Value |
| --- | --- |
| Source revision | |
| Godot | 4.7.2.stable.official.ed1daf0bf |
| Renderer | Compatibility (`gl_compatibility`, `game/project.godot:125`) |
| Machine | MacBook Air, Apple M4, macOS 26.6.2 |

Machine results come from `./scripts/run-test.sh` logs in `logs/`. A HUMAN CHECK
row records the author's own observation in the editor or a windowed run. A
headless run uses a dummy renderer and draws nothing.

## Baseline (earlier suites, pinned frame rate)

| Suite | FPS | Before Assignment 5 (`2b6b251`) | After Assignment 5 |
| --- | --- | --- | --- |
| `first_drive_regression.gd` | 60 | 64/64 passed, exit 0 | |
| `first_drive_integration.gd` | 60 | 29/29 passed, exit 0 | |
| `check_first_drive_art.py` (Python, outside the wrapper) | n/a | 133/133 | |

Both Godot logs end with an engine "resources still in use at exit" error at
shutdown. It predates Assignment 5 and is not a SHADER or SCRIPT ERROR.

## Shaders parse

Uniform-list assertions for both shaders, no SHADER ERROR line.

## Driver (30, 60 and 144 fps)

The uniform sampled every frame through a real event, including a retrigger:
first value, last value, game-time duration.

## Mutations

| Mutation | Test | Exit status |
| --- | --- | --- |
| Delete one semicolon in the effect shader | | |
| Rename the driven uniform in the shader only | | |
| Remove `source_color` from the colour sampler | | |

## Controlled values (HUMAN CHECK)

One in-engine capture per controlled value, with the sampled pixels beside the
predicted table. One capture with the uniform set to 2.0 from code, answering
the `hint_range` question. One comparison against an OS screenshot.

## In play (HUMAN CHECK)

The state triggered by normal play several times; boundaries hold.

## Hint experiment (HUMAN CHECK)

A capture of both quads, with the sampled band values beside the predictions.

## Interface sweep (HUMAN CHECK)

Each textured-shader uniform at minimum, default and maximum: what changed, and
any setting that breaks the look.

## One shader, two materials (HUMAN CHECK)

Side-by-side captures under the stated lighting. One shader line edited, and
both objects change. One value edited in one material, and only that object
changes.

## Material wiring

The material test after a fresh import (`game/.godot` deleted).

## Texture data

Curl ratio under both conventions for every normal map and for the calibration
pair.

## Import settings

The diff of any `.import` file the editor rewrote, with the reason.

## Inspect-and-revise cycle

At least one observation that led to a change, and what changed.

## What no headless run can show
