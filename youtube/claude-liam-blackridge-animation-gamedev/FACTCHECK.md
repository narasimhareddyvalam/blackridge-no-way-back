# FACTCHECK — Blackridge, Frame by Frame

Every narrated claim and on-screen number, with the record it comes from. Code lines are read
verbatim from `game/` at `1e7765e` by `build/build_sheet.py`; `./art godot-gamedev --check` binds
them by hash.

| Beat | Claim | Source |
| --- | --- | --- |
| B00 | Brief and pins before any clip; four clips; two strips, one revision open | `e284453` brief, `1cf092d` pins, `f6f5565` first clip; `TUNING.md` r0, r1 |
| B01 | A clip is a resource: tracks, keys, length, loop mode; one owner each | `game/animations/phone_ring.tres`; `CLAUDE.md` "One authority" |
| B02 | Ring: Sprite2D frame track, loops; EnterVan: imported rig, once; reload motion-captured; shock keyed; Godot 4.7.2 | `CHANGE-BRIEF.md` §1, the rifle and shock revisions; `README.md` |
| B03 | Six frames at 10 fps, seam rule; phase table in frames; pins; committed before setup | `CHANGE-BRIEF.md` §3, §4; `git log` order e284453 → 1cf092d → f6f5565 |
| B04 | Length 0.6, loop_mode 1 (linear), step 0.1, `RingIcon:frame`, update 1 (discrete), keys 0-5 at 0-0.5 s; last key + step = length | `phone_ring.tres:4-18`; `test_ring_readback.gd` 15/15 |
| B05 | Six 64 px cells, one row, drawn white by a script; hframes 6, vframes 1; handset, 1-3 arcs, arcs fading | `phone_ring.png` (384×64); `navigation_display.gd:8, 88-93`; `tools/art/make_phone_ring_sheet.py` |
| B06 | Only `_drive_ring` calls play and stop; reads call_state and call_seconds | `navigation_display.gd:167-175`; `test_animation_structure.gd` 13/13 |
| B07 | Ring plays while Maya's call rings; every cell seen, wraps 5 → 0, hidden when talking | `capture/takes/ring_play`; `TEST-REPORT.md` (states 8/8) |
| B08 | Mixamo "Entering Car", 164 frames at 30 fps; `settings/loop_mode` 0 in the importer | `ethan.glb.import:44-49`; `test_rig_readback.gd` E5, E8 |
| B09 | Fresh import: 114 bone tracks, LOOP_NONE, 9/9; importer at 1: 7/9; plays once in play | `logs/animation/rig/fresh_cache`, `rig/mutation_loop`; `capture/takes/ring_play/boarding.mp4` |
| B10 | CLIP_FPS 30; REACH_FROM 22, DOOR_GRAB 32, DOOR_OPENED 48, CUT 62 | `app/first_drive.gd:30-38`; `test_rig_readback.gd` 14/14 |
| B11 | Strip r1 at clip 0, 22, 32, 48, 58, 70 (capture = 12 + clip) | `captures/enter_van/r1`; `logs/animation/step7/enter_van_r1.log` |
| B12 | The loop reads `clip_time()`, sets the door, awaits `process_frame`; brief predicted 0 s | `app/first_drive.gd:914-920`; `CHANGE-BRIEF.md` §6 |
| B13 | At clip 34 the door is 0.011, frame 33's value; 1/30 s; reload timer ends at clip 98.5 | `logs/animation/step7/enter_van_r0.log` (capture 46); `TEST-REPORT.md`, the reload's two clocks |
| B14 | `play_clip` is the path into Ethan's player; helpers push_gait.gd, rifle_carry.gd; the structure test checks | `driver.gd:554-568`; `CHANGE-BRIEF.md` Step 5 revision; `test_animation_structure.gd` |
| B15 | W at clip 16: 0.000 m; Esc at 40: frozen at 41 / 0.593, resumed; R at 56: seated; edges 48/48; the Esc-in-fade bug | `capture/takes/interrupt_*/events.txt`; `logs/animation/step7_r1`; `#374` |
| B16 | r0: feet on the ground at 53; Claude's decision (author away); cut to 62; 5 of 6 predictions; PIN2 moved as predicted; verdict open | `TUNING.md` r0, r1; `#406`; `2f91bc5` |
| B17 | Hand-keyed reload rejected; mocap, then rifle; UpperBody keys the upper body only; enter/leave on `reloading`; RELOAD_SECONDS 99/30 | `#386-#393`; `rifle_carry.gd:161-174`; `handgun.gd:21`; `test_reload_readback.gd` R7, R9 |
| B18 | Magazine out 14, seated 47; charging handle 8 cm; fire and R ignored; fixture armed directly | `rifle_hold.gd` DROP, SEAT, CHARGE_TRAVEL; `test_reload_readback.gd` R10, R11; `test_reload_edges.gd` 21/21; `capture/CAPTURE.md` |
| B19 | Keyed over EnterVan's last frame; slid forward to 0.43 m; hand targets on the rim from the mesh; grip over 11 frames | `tools/art/make_ethan_shock.gd`; `driver.gd:1020, 1027-1041`; `SHOCK_REACH`, `SHOCK_GRIP` |
| B20 | Startle, breaths, no, drop, mirrors, stare; inside the 4 s hold; the author's #404; fixture without the struck man | `CHANGE-BRIEF.md` (the shock remade); `test_shock_state.gd`; `#404`; `capture/CAPTURE.md` |
| B21 | Read-backs ring 15, rig 14, reload 12, shock 9; suites 81; mutations m1-m3 exit 1, m4 exit 0 by design | `logs/animation/{repin, step7_r1, reload, shock}`; `logs/animation/final_suites`; `logs/animation/mutations/EXITS.txt` |
| B22 | Mistakes: Esc in the fade, push_gait a second writer, hands short of the rim, §9 two frames early; overruled: #386, #398-#402; sheet by script; revision 1e7765e | `#374`; `CHANGE-BRIEF.md` revisions; `TUNING.md`; `SOURCES.md` |
| B23 | Who did what | `docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #362-#406; `FRICTIONAL.md` |
| B24 | Verdict lines | the beats above |

Not claimed: that the motion reads or the ring wraps without a visible seam (the author's checks,
open); that r1 is kept (the author's verdict, open).
