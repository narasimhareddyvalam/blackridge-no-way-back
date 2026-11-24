# PROJECT-BRIEF: Blackridge: No Way Back

**Status:** written by Claude Code from the author's answers, 2026-11-23; the author's own words
(#450, #455) are quoted, and the author accepted the rest as their answers (#456).

**Stack:** Godot 4.7.2 stable, GDScript, Forward+ (Metal), macOS desktop export, built on a MacBook
Air M4 with Claude Code.

## 1. What is it?

A short, story-driven crime thriller where you play a delivery driver who drives his van from the
cab, through a rainy night, and three missions take him from one fatal accident to his sister's
secret. When it is done it will be a **playable macOS desktop build**: one district, title
screen to end screen, three connected missions with checkpoint saving and one compact combat
encounter, plus a test report a stranger can rerun.

## 2. Why would anyone care?

The driving *is* the story: you are inside the cab, with low and high beams, wipers that clear the
rain, real mirrors and a dash phone that rings. The crime plot reaches you through the job, not
around it.

## 3. What does it give the player?

A grounded night in three parts: the dread after the first drive, the wrong cargo, and a last run
to get a child home. The three recordings below run 54 minutes together, but they were
played by a script, not a person; how long a player takes is not measured.

## 4. What makes it different?

The author has played **GTA V** and **Euro Truck Simulator 2** ("GTA V, Euro Truck Simulator 2").
- GTA V has crime stories and driving, but the driving is a fast way between missions, seen
  mostly from outside the car. Blackridge keeps you in one van's cab, and the cab is where the
  story happens.
- Euro Truck Simulator 2 has a cab you live in, but no story and nothing at stake. Blackridge
  puts a crime thriller inside that cab.

## 5. Who opens it, and what do they do?

**Target role:** the author: "i want to be game developer" (a generalist). **Reader:** a hiring
manager or lead at a studio. **First sixty seconds:** they will open the app, press
Start on the title screen and be walking to the van in the depot at night, then driving, with the
controls shown on screen. *(will: the current export is from 2026-11-01, before the missions)*

## 6. What does it prove?

- **Shaders and materials:** the windshield fog and the night gauge cluster, hand-written by the
  author (`game/shaders/`, tag `a5`).
- **Particle effects:** four GPU effects with tuning and measured cost (tag `a6`).
- **Animation and state:** the phone-ring cycle, getting into the van, the rifle reload and
  Ethan's shock, each with its phase table and edge tests (tag `a7`).
- **Profiling:** frame times measured on the M4 Air (`PERFORMANCE.md`), e.g. 69.8 FPS parked in
  the final mirror build (Run 33, 1280×800, vsync off).
- **Verification and directing an agent:** 94 test scripts run headless (`scripts/run-test.sh`),
  bugs fixed only after a failing test (e.g. `61cf104`, `6e4ed08`), and 454 logged prompts and
  decisions (`docs/AUTHOR_PROMPTS_AND_DECISIONS.md`) with ownership rules for the agent
  (`CLAUDE.md`). The human checks are still open: the author has not yet played Missions 2 and 3.

## 7. In, out, first, and risk

- **In:** one district, one van, three missions, checkpoints, one fight (`docs/GAME_DESIGN.md`).
- **Out:** no multiplayer, no police wanted level, no traffic simulation, no open city.
- **First:** a fresh macOS export of Mission 1 that a stranger plays from the title screen to the
  first checkpoint; someone knows it ran because the save file appears and a recorded play shows it.
 
- **Risk:** the frame rate. The rain, mirrors and forest are heavy on Forward+; the slowest 5% of
  frames (17–19 ms) are already just over 60 FPS's 16.7 ms budget, and an exported build on
  another Mac has never been measured. What I will do: measure the export on power and on battery,
  and cut what costs most (mirror rate, shadow distance) before adding anything new.

## 8. Why this project?

"Mostly learning." Every skill in §6 was new to the author in this course: Godot and GDScript,
3D games, shaders, particle effects, animation, profiling, testing, and directing an AI agent
("all new to me, i'm mostly learning"). None was an existing skill brought in to show off; what
exists is what was learned, and the tags `a5`, `a6`, `a7` and the commits above are where each
can be checked.

## Exists today

| What | Where it can be seen |
| :-- | :-- |
| Mission 1, Night Freight, playable to its end | `develop` `5ff34f1`; video recorded by scripted input (6 min 28 s) |
| Mission 2, The Wrong Cargo, playable to its end | `develop` `b7ece7e`; scripted-input video (16 min 47 s) |
| Mission 3, Last Run, playable to the title | `develop` `6e4ed08`; scripted-input video (30 min 51 s, two halves joined at a checkpoint); three errors found in it fixed in `61cf104` |
| Shaders, particles, animation | tags `a5`, `a6`, `a7` |
| Tests and frame-time measurements | `game/tests/`, `TEST-REPORT.md`, `PERFORMANCE.md` |

## Will exist

- A current macOS export, measured on power and battery.
- The author's own play of Missions 2 and 3, and fixes from it.
- A test report covering all three missions that a stranger can rerun.
- Voices for the story scenes.
