# A2, value drift (2026-11-07, Claude Code)

- **The edit:** game/effects/roof_spill.tscn, RoofBeads: `spread = 24.0` changed to `spread = 30.0`,
  with CHANGE-BRIEF.md left at 24.
- **Run:** `LOG_DIR=logs/particles/mutation_a2_value_drift scripts/run-test.sh <test> 60`.
- **Results:**
  - test_roof_spill_config.gd 60: 66/67, exit 1. FAIL: RoofBeads process.spread = 24.0 (found 30.0).
- **Restored:** `git checkout -- game/effects/roof_spill.tscn`; `git status` showed the scene
  unchanged.
