# FACTCHECK: Blackridge: No Way Back, the pitch

Every narrated claim and on-screen number, with the record it comes from (checked by Claude Code,
2026-11-24). "Exists" means shown running in this film or recorded in the repository at the commit
named; "will" means not yet done.

| Beat | Claim | Source |
| --- | --- | --- |
| B00 | Real gameplay, played through the game's own controls by an automated player | `coverage.json` (every capture `scripted-input`, its run log); `tools/captures/film_kit.gd` presses the Input Map actions |
| B00 | Built in Godot with Claude Code | `README.md` (Godot 4.7.2); `docs/AUTHOR_PROMPTS_AND_DECISIONS.md` |
| B01 | A crime thriller on one rainy night, from the cab; done: a macOS build, three missions, title to end | `docs/GAME_STORY.md`, `docs/GAME_DESIGN.md`; `pitch/PROJECT-BRIEF.md` §1 |
| B02 | Exists = shown running with its commit; Will = everything else | the assignment's honesty rule; `pitch/PROJECT-BRIEF.md` |
| B03 | Ethan drives home in rain; his sister calls; a man in the headlights; "DRIVE." | `docs/GAME_STORY.md` (Maya Cole, Ethan's younger sister); 4K take `m1_4k_95_120` (the call), `m1_4k_275_312` (the hit at about 297.5 s, DRIVE. after) |
| B03 | Mission 1 exists at the commit on screen (61cf104) | the 4K Mission 1 run (340 s, 10,200 frames, 2026-11-23); headless run to its end at `05163d9` (game/ = 61cf104) |
| B04 | Bay 9, the pallet jacked onto the lift by hand; a container yard, a different van | 4K takes `m2load_4k_25_50`, `m2yard_4k_95_130`; `film_mission_two.gd` logs ("pallet on the lift", "the dark van taken") |
| B04 | Mission 2 playable to its end at 61cf104 | full recording at `b7ece7e`; headless run to its title at `05163d9` (game/ = 61cf104) |
| B05 | Maya hands him a rifle at the service gate; a fight at a hangar; Lily walks out with him; plays to the cut to black | 4K take from the stage 3 save (`m3gate_4k_*`); `film_missions.gd` log ("armed", "at the office", "her hand", "the title screen") |
| B05 | Recording it found three bugs, fixed, two with a failing test first | `61cf104` (read-only lines: `test_scene_lines.gd` L1 failed first; SUV route: `test_suv_place.gd` 0/1 first; the handgun's meta: no test of its own) |
| B06 | The author has played GTA V and Euro Truck Simulator 2 | the author's answer (#450) |
| B07 | Generalist game developer; first sixty seconds as a will; the only export is from before Missions 2 and 3 | the author's answer (#450); `builds/macos/` dated 2026-11-01; Mission 2 added 2026-11-04 (`5d5ca7e`), Mission 1 on 2026-10-28 (`e81ec92`) |
| B08 | Shaders by hand at a5; particle effects measured at a6; animations with edge tests at a7 | tags `a5`, `a6`, `a7`; `game/shaders/` (CLAUDE.md: hand-written by the author); `git show a6:CHANGE-BRIEF.md`; `TEST-REPORT.md` (edges 48/48) |
| B09 | 94 headless tests | `git ls-tree -r 61cf104 game/tests`: 94 `test_*.gd` |
| B09 | Bugs fixed after a failing test; every prompt logged; agent never edits game/shaders/ | commit messages `23cc4cf`, `007d62c`, `6e4ed08`, `61cf104`; `docs/AUTHOR_PROMPTS_AND_DECISIONS.md`; `CLAUDE.md` Ownership |
| B09 | The test run for this film: 29/29 | `scripts/run-test.sh test_save_rules.gd 60`, 2026-11-23 20:33, `logs/pitch/test_save_rules_60fps.log` |
| B10 | Slowest frames 17-19 ms against 16.7 ms; no export measured; acts two and three not played by the author | `PERFORMANCE.md:211` and `:87`; `pitch/PROJECT-BRIEF.md` §7; #456 |
| B11 | In, out, first | `docs/GAME_DESIGN.md` (minimum scope), `AGENTS.md`; `pitch/PROJECT-BRIEF.md` §7 |
| B12 | Mostly learning; all new this term; the epilogue's six months later | the author's answers (#455: "all new to me, i'm mostly learning"); 4K take `m3gate_4k_*` (the epilogue) |
| B13 | The recap: exists and will; the story still needs improvements | `pitch/PROJECT-BRIEF.md`; the author (#458) |
| B14 | The viewer's prompt; no answer shown | on screen only the prompt and its rubric |
| B15 | AI narration disclosed | `pitch/SOURCES.md` §1 (Kokoro `am_onyx`) |
