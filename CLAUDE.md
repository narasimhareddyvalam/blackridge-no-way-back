@AGENTS.md

## Project context

- Engine: Godot 4.7.2 stable (`README.md:74`). Renderer: Forward+ on desktop, Godot's default:
  `game/project.godot` sets only `rendering_method.mobile="gl_compatibility"` (`:155`), though
  `config/features` lists "GL Compatibility" (`:15`).
- Main scene: `res://app/first_drive.tscn` (`game/project.godot:14`), holding the world
  `IndustrialLoop` and the van `FreightVan`. The title screen and the pause menu pause the tree.
- Assignment 7's two clips (`CHANGE-BRIEF.md` §1):
  - **Ring** (the cycle): route `Sprite2D` with an `AnimationPlayer` frame track. Node
    `RingIcon` on the dash's navigation screen, `game/features/vehicles/freight_van/
    navigation_display.gd`, created by `van_presentation.gd:490`. Its call states are
    `ring`, `talk`, `miss`, `end_call` (`navigation_display.gd:107-127`); the drawn pulse it
    replaces is `_draw_call_card` (`:291`, `:299`). Clip resource: `game/animations/
    phone_ring.tres`; sheet `game/features/vehicles/freight_van/art/ring/phone_ring.png`, drawn
    by `tools/art/make_phone_ring_sheet.py`.
  - **EnterVan** (the committing action): route imported 3D rig, Mixamo's "Entering Car"
    (`source_assets/mixamo/Entering Car.fbx`, `tools/art/convert_mixamo.py:56`) in
    `game/features/characters/ethan/ethan.glb`, imported at 30 fps (`ethan.glb.import`,
    `animation/fps=30`). Played by `driver.gd`'s `play_clip` (`game/features/characters/driver/
    driver.gd:527`) on Ethan's `AnimationPlayer` (`:123`, `:197`), read through `clip_time()`
    (`:566`).
- The player's state machine: Ethan's on-foot states in `driver.gd` (`_play`, `:931`), and the
  boarding sequence that plays EnterVan in `game/app/first_drive.gd` (`_board_van`, `:828`,
  `:838`; its moments `REACH_FROM` to `CUT`, `:28-38`; `_cancel_boarding`, `:862`).
- Tests: `scripts/run-test.sh <test.gd> <fps|realtime> [timeout-seconds]` runs Godot headless on
  `game/` (none for `realtime`), timeout 120 s by default, from `game/tests/` or `tools/tests/`,
  logging `<test>_<fps>fps.log` to `$LOG_DIR` (default `logs/`). It runs with
  `HOME=.scratch-home` and fails on `SHADER ERROR`, `SCRIPT ERROR`, `Failed loading resource`, a
  missing test file, or any change to the player's real save folder (`scripts/run-test.sh`).
- Commands, from the repository root. Assignment 7's logs go under `logs/animation/`:

  ```sh
  LOG_DIR=logs/animation/<step> scripts/run-test.sh <test>.gd 60
  LOG_DIR=logs/animation/<step> scripts/run-test.sh <test>.gd realtime  # tests that wait on audio
  bash logs/animation/baseline/run_suites.sh <scratch>   # every earlier suite, in three workers
  python3 tools/tests/check_first_drive_art.py
  ```

- Earlier layers stay as built: Assignment 5's shaders (`game/shaders/`), Assignment 6's effects
  (`game/effects/`, revisions in `git show a6:CHANGE-BRIEF.md`), Phase 2's missions
  (`docs/PHASE_BRIEF.md`).

## Headless facts

- A headless run draws nothing; whether anything looks right is a human check.
- Exit 0 is not proof of a clean run: logs end with the engine's "resources still in use at
  exit" error, which the runner does not fail on.
- Godot follows `HOME` for `user://`. The real save folder is
  `~/Library/Application Support/Godot/app_userdata/Blackridge- No Way Back/`.
- Frame strips come from a windowed Movie Maker run; for Assignments 6 and 7 Claude Code starts
  them at the author's request (`docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #163, #365).

## Current change

@CHANGE-BRIEF.md

## Working rule

- The author approves every step before it happens: "at each step take my approval and then
  only do it" (2026-10-30, `docs/AUTHOR_PROMPTS_AND_DECISIONS.md`).
- All work happens on `develop`. `main` stays as the last graded submission and changes only
  through a pull request the author approves.
- Each run ends by writing `HANDOFF.md`: the files changed, the exact test commands with their
  real results, what the next run may rely on, and what is unverified.

## Ownership

- Every file in `game/shaders/` is hand-written by the human. Agents never create, edit,
  reformat, rename or delete files there, even to fix an error; report shader problems instead.
- Effect settings live in scene files in `game/effects/`, not in code.
- Clips live as resources in `game/animations/` or in the scene that owns them (an imported
  model's clips in its `.glb`, set through its `.import` file), never built in code at runtime.

## One authority

- Exactly one node writes to each animated node; never add a second writer to one that has one.
- `RingIcon` and its `RingPlayer`: `navigation_display.gd` alone calls `play("ring")` and `stop()`,
  reading its own `call_state` and `call_seconds`. Nothing else touches the dash's nodes.
- Ethan's `AnimationPlayer`: `driver.gd` alone calls `play()` on it (`play_clip`, `_play`). The
  app and the missions ask `driver.gd`; the cutscene director holds Ethan but plays nothing on
  him.

## Godot 4 names

- Use Godot 4.7.2's class and property names: `loop_mode` (`Animation.LOOP_NONE`,
  `LOOP_LINEAR`), `speed_scale`, `AnimatedSprite2D` with `sprite_frames` and `play()`. Never
  Godot 3 names such as a boolean `loop`, `playback_speed` or `AnimatedSprite`.
- An imported clip's loop mode belongs in the importer's per-animation settings (`.import`,
  `_subresources` → `animations`), never in an edit to the imported clip in a scene.
- If unsure whether a property exists in 4.7.2, say so instead of guessing.

## Out of scope

- The animations are presentation: they read game state and never write it. Collision, movement,
  input mappings, the missions' state machines and timings (except the boarding constants the
  brief re-expresses in frames), the save rules, existing tests and their expectations, the
  Assignment 5 shaders, the Assignment 6 effects and every other object stay as they are
  (`CHANGE-BRIEF.md` §7).
- Still protected:
  - `headlights_on` and L's low, high, off cycle; the `LIGHTS` text and the switch click;
  - the fog materials, which change only with the author's OK;
  - volumetric fog stays off, and AgX at exposure 1.3 (`industrial_loop.gd:206-207`) stays;
  - `project.godot` changes only as approved (`fire`, `aim`, `reload` at `:137-151`, flagged
    for the author, Mission 3); no autoloads or new controls without the author's OK;
  - Assignment 5's evidence in `logs/*.log` and `evidence/captures/`, and Assignment 6's in
    `logs/particles/` and `captures/`, are never overwritten.
- The original sheet file, as the script first writes it, is not edited by hand.

## Unconfirmed

- The tailpipe's position (Assignment 6, B2): an assumed point until the author confirms it.
- Whether `RingPlayer` needs its `callback_mode_process` set explicitly (the brief proposes the
  default, process idle); confirmed when the ring is set up.
- That `settings/loop_mode` is the 4.7.2 importer key for an animation's loop mode; confirmed
  from an empty import cache in Step 4.
