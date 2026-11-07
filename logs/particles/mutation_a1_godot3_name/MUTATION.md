# A1, Godot 3 name (2026-11-07, Claude Code)

- **The edit:** game/effects/wiper_flick.tscn, BigDrops: `initial_velocity_min = 1.2` renamed to the
  Godot 3 name `initial_velocity = 1.2`.
- **Run:** `LOG_DIR=logs/particles/mutation_a1_godot3_name scripts/run-test.sh <test> 60`.
- **Results:**
  - test_wiper_flick_config.gd 60: 67/68, exit 1. FAIL: BigDrops process.initial_velocity_min = 1.2
    (found 0.0).
  - test_wiper_flick_state.gd 60: 9/9, exit 0. The state test checks behaviour, not values, so only
    the config test catches this.
- **Why it is silent:** In Godot 4.7.2 `initial_velocity` is a Vector2 range; one float written to
  it is silently dropped and the minimum stays 0. No error line is printed.
- **Restored:** `git checkout -- game/effects/wiper_flick.tscn`; `git status` showed the scene
  unchanged.
