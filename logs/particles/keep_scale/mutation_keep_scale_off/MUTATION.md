# B2, Keep Scale off (2026-11-07, Claude Code)

- **The edit:** game/effects/exhaust_vapour.tscn, `Draw_puff`: the line
  `billboard_keep_scale = true` removed, as the scene was before revision 4.
- **Run:** `LOG_DIR=logs/particles/keep_scale/mutation_keep_scale_off scripts/run-test.sh
  test_exhaust_vapour_config.gd 60`.
- **Results:** 41/42, exit 1. FAIL: ExhaustPlume material.billboard_keep_scale = true (found
  false).
- **Restored:** the scene was copied back from a copy taken before the edit, and holds the line
  again.
