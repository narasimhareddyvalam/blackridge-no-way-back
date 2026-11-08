# A1, value drift (2026-11-07, Claude Code)

- **The edit:** game/effects/wiper_flick.tscn, BigDrops: `spread = 28.0` changed to `spread = 35.0`,
  with CHANGE-BRIEF.md left at 28.
- **Run:** `LOG_DIR=logs/particles/mutation_a1_value_drift scripts/run-test.sh <test> 60`.
- **Results:**
  - test_wiper_flick_config.gd 60: 67/68, exit 1. FAIL: BigDrops process.spread = 28.0 (found 35.0).
- **Restored:** `git checkout -- game/effects/wiper_flick.tscn`; `git status` showed the scene
  unchanged.
