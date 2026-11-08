@AGENTS.md

## Project context

- Engine: Godot 4.7.2 stable (`README.md:267`). Renderer: Forward+ on desktop, Godot's default:
  `game/project.godot` sets only `rendering_method.mobile="gl_compatibility"` (`:140`), though
  `config/features` lists "GL Compatibility" (`:15`); MetalFX draws at 75% on macOS (`:142-143`).
- Main scene: `res://app/first_drive.tscn` (`game/project.godot:14`), holding the world
  `IndustrialLoop` and the van `FreightVan` (`game/app/first_drive.tscn:12,14`). The title screen
  and the pause menu pause the tree (`game/app/first_drive.gd:138-140`, `:401-405`).
- Cameras: driving `game/features/vehicles/freight_van/van_presentation.gd:363`, on foot
  `game/features/characters/driver/driver.gd:66`, title `game/app/first_drive.gd:131-134`.
- Assignment 6's four effects, all `GPUParticles3D` (`CHANGE-BRIEF.md` §1–§5, revisions 6–10):
  - **A1 wiper flick:** `wiper_swept` (`game/features/vehicles/freight_van/freight_van.gd:5`),
    emitted every half stroke (`:280-285`); the wipers are built in `van_presentation.gd:588-595`
    from `wiper.gd`, whose blade is at `:27-30`.
  - **A2 roof spill:** `braking` (`freight_van.gd:101`), 9 m/s² (`:22`, `:107-109`), 1.5 m/s²
    with locked wheels (`:16`); the van's speed is `actual_speed` (`:124`).
  - **B1 lamp rain:** the active camera within 65 m of a lamp, at most eight volumes
    (`game/features/environments/industrial_loop/lamp_rain.gd:12-13`). The lamps, in
    `industrial_loop.gd`: street `:714-746` (fading from 65 m, `:735`), bend `:520-540`,
    depot wall `:769-800`, office `:661-703`.
  - **B2 exhaust vapour:** `engine_on` (`freight_van.gd:27`), `engine_started` (`:8`, `:243`),
    `switch_off()` (`:229`); the throttle is `accelerate` (`:90`) or `scripted_throttle` (`:95`),
    read as `throttle` (`:35`).
- Effect scenes go in `game/effects/`, previews in `game/previews/`, tests in `game/tests/`
  (`CHANGE-BRIEF.md` §6). The export leaves out `tests/*`, `experiments/*`, `previews/*` and the
  visual benchmark (`game/export_presets.cfg:11`).
- Test runner: `scripts/run-test.sh <test.gd> <fps|realtime> [timeout-seconds]` runs Godot
  headless on `game/` at `--fixed-fps <fps>` (none for `realtime`), timeout 120 s by default,
  from `game/tests/` or `tools/tests/`, logging `<test>_<fps>fps.log` to `$LOG_DIR` (`logs/`).
  It runs with `HOME=.scratch-home` and fails on `SHADER ERROR`, `SCRIPT ERROR`, a missing test
  file, or any change to the player's real save folder (`scripts/run-test.sh:1-47`).
- Commands, from the repository root. Assignment 6's logs go under `logs/particles/`, so
  Assignment 5's `logs/*.log` are never overwritten:

  ```sh
  LOG_DIR=logs/particles/<step> scripts/run-test.sh first_drive_regression.gd 60
  LOG_DIR=logs/particles/<step> scripts/run-test.sh test_night_dimming.gd 30  # also 60 and 144
  LOG_DIR=logs/particles/<step> scripts/run-test.sh <test>.gd realtime  # tests that wait on audio
  LOG_DIR=logs/particles/<step> scripts/run-test.sh cost_effects.gd 60 300
  python3 tools/tests/check_first_drive_art.py
  ```

  `first_drive_integration.gd` and every `game/tests/test_*.gd` run at 60 too. The baseline of
  2026-11-07, all exit 0: 64/64, 0 failures, 92/92, 21/21, 12/12, 25/25, 33/33, 12/12, 49/49,
  21/21, 44/44, 12/12, 13/13, 12/12, 15/15, 29/29, 13/13, 20/20, 7/7, 30/30 ×3; art 0 failures
  (`logs/particles/baseline/SUMMARY.txt`).

## Headless facts

- A headless run draws nothing; whether anything looks right is a human check.
- `get_shader_uniform_list()` works headless; a shader that fails to parse prints `SHADER ERROR`.
- Exit 0 is not proof of a clean run: logs end with the engine's "resources still in use at
  exit" error, which the runner does not fail on.
- Godot follows `HOME` for `user://`. The real save folder is
  `~/Library/Application Support/Godot/app_userdata/Blackridge- No Way Back/`.
- A headless run uses a dummy renderer: no particles drawn, no GPU particle process run. Node
  state (`emitting`, `one_shot`, `amount_ratio`, visibility, counts) is observable, the look is
  not, and a GPU effect's CPU price is near zero (`logs/particles/mutations_final/cost/`).
- Frame strips come from a windowed Movie Maker run (`scripts/capture-strips.sh`); for
  Assignment 6, Claude Code started them at the author's request (#163).
- Windowed on Metal, Godot's GPU timer reads 0; `game/tests/gpu_price.gd` gets GPU time from
  Apple's Metal HUD (`MTL_HUD_ENABLED=1 MTL_HUD_LOG_ENABLED=1`; `tools/tests/gpu_price.py`).

## Current change

@CHANGE-BRIEF.md

## Working rule

- The author approves every step before it happens: "at each step take my approval and then
  only do it" (2026-10-30). For Assignment 6 the author asked Claude Code to finish its own parts
  and leave the author's tasks for the end (`docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #142), then to
  do everything left (#165), except the author's own checks, words and Step 6.
- All work happens on `develop`. `main` stays as the last graded submission and changes only
  through a pull request the author approves.
- Each run ends by writing `HANDOFF.md`: the files changed, the exact test commands with their
  real results, what the next run may rely on, and what is unverified. Each run starts by reading
  it and rerunning every test it lists.

## Ownership

- Every file in `game/shaders/` is hand-written by the human. Agents never create, edit,
  reformat, rename or delete files there, even to fix an error; report shader problems instead.
- Effect settings live in scene files in `game/effects/`, not in code. Code places, starts and
  stops effects, and drives `amount_ratio`; it does not set their look.

## Godot 4 names

- Use Godot 4.7.2's class and property names; `docs/PARTICLE_RESEARCH.md` §7 lists them from the
  engine's own API dump. Never use Godot 3 names such as `ParticlesMaterial` or `scale_random`.
  In 4.7.2, `initial_velocity`, `scale` and `damping` are Vector2 ranges beside their `_min` and
  `_max` floats, not single values.
- If unsure whether a property exists in 4.7.2, say so instead of guessing.
- Found in 4.7.2 (`TEST-REPORT.md`, `TUNING.md`): `local_coords` puts `gravity` in the emitter's
  frame; `transform_align` 3 with billboard off turns quads to the camera along their motion;
  `restart()` re-runs `preprocess` about three frames late; `COLLISION_HIDE_ON_CONTACT` never fires
  a sub-emitter; `BILLBOARD_PARTICLES` drops scale unless `billboard_keep_scale` is on.

## Out of scope

- The effects are presentation only: they read game state and never write it. Collision,
  movement, input mappings, the mission's state machine and timings, the save rules, existing
  test expectations, the Assignment 5 shaders and every other object stay as they are
  (`CHANGE-BRIEF.md` §6).
- Still protected:
  - `headlights_on` and L's low, high, off cycle; the `LIGHTS` text and the switch click;
  - the fog materials, which change only with the author's OK;
  - volumetric fog stays off, and AgX at exposure 1.3 (`industrial_loop.gd:163-164`) stays;
  - `project.godot` changes only as approved (renderer, MetalFX, ETC2/ASTC, `cabin_light` on I,
    `answer_call` on T, `vsync_debug` on F9); no autoloads or new controls without the author's OK;
  - Assignment 5's evidence in `logs/*.log` and `evidence/captures/` is never overwritten.

## Unconfirmed

- The tailpipe's position (B2): the Iveco model has none, so the plume starts at an assumed point
  (`CHANGE-BRIEF.md` revision 2) until the author confirms it from a photo of a real Daily.
- Where the chapter's Example 09 cost script is; it is not in this repository.
