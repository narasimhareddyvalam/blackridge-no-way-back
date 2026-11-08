# A2, Godot 3 name (2026-11-07, Claude Code)

- **The edit:** game/effects/roof_spill.tscn, RoofStreams: `initial_velocity_min = 0.5` renamed to
  the Godot 3 name `initial_velocity = 0.5`.
- **Run:** `LOG_DIR=logs/particles/mutation_a2_godot3_name scripts/run-test.sh <test> 60`.
- **Results:**
  - test_roof_spill_config.gd 60: 66/67, exit 1. FAIL: RoofStreams process.initial_velocity_min =
    0.5 (found 0.0).
  - test_roof_spill_state.gd 60: 11/11, exit 0. As for A1, only the config test catches it.
- **Restored:** `git checkout -- game/effects/roof_spill.tscn`; `git status` showed the scene
  unchanged.
