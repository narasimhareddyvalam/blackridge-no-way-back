# B1, hide time without the splashes (2026-11-07, Claude Code)

- **The edit:** game/features/environments/industrial_loop/lamp_rain.gd, `settle_time()`: returns
  only `rain(index).lifetime` (1.1 s), the hide time before this fix.
- **Run:** `LOG_DIR=logs/particles/b1_settle/mutation_rain_life_only scripts/run-test.sh
  test_lamp_rain_state.gd 60`.
- **Results:** 11/12, exit 1. FAIL: the last lamp left is already hidden 0.1 s before 1.35 s, so
  its last splashes would be cut off.
- **Why the test catches it:** it reads both lifetimes from the effect scene itself
  (`_emptied_after()`), not from the controller.
- **Restored:** the file was copied back from a copy taken before the edit; the fixed run is
  `logs/particles/b1_settle/test_lamp_rain_state_60fps.log`, 12/12.
