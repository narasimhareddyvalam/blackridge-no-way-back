# PROJECT-BRIEF: Blackridge: No Way Back

Written by Claude Code from the author's answers (#450, #455), accepted by the author (#456);
tightened to one page (#462). Stack: Godot 4.7.2, GDScript, Forward+ (Metal), macOS desktop
export, on a MacBook Air M4, with Claude Code.

**1. What is it?** A short crime thriller you play from the cab of a delivery van, on one rainy
night. Done, it will be a **playable macOS desktop build**: one district, title screen to end
screen, three connected missions with checkpoints and one compact fight, and a test report a
stranger can rerun.

**2. Why care?** The driving *is* the story: low and high beams, wipers that clear the rain,
real mirrors, and a dash phone that rings. The plot reaches you through the job, not around it.

**3. What does the player get?** One grounded night in three acts: the dread after the first
drive, the wrong cargo, and a last run to get a child home. How long a person takes is not yet
measured; the automated player's three runs total about 54 minutes.

**4. What is different?** The author has played GTA V and Euro Truck Simulator 2. GTA V's
driving is mostly the space between missions; Euro Truck Simulator 2 has a cab you live in but
no story and nothing at stake. Blackridge puts a crime thriller inside that cab.

**5. Who opens it?** Role: generalist game developer ("i want to be game developer").
Reader: a hiring manager or a studio lead. First sixty seconds (will): open the app, press
Start, skip the opening with E, and follow the on-screen key prompts ("Get in the van",
"press E") to be driving within a minute without reading anything. Not yet tried with a
stranger; the export on disk (2026-11-01) predates Missions 2 and 3.

**6. What does it prove?** Shaders: the windshield and night gauge cluster, hand-written by the
author (`a5`). Particles: four GPU effects, tuned and priced (`a6`). Animation and state: the
phone ring, EnterVan, the rifle reload and the shock, with edge tests (`a7`). Profiling: frame
times on the M4 Air (`PERFORMANCE.md`). Verification: 94 headless test scripts, bugs fixed after
a failing test (`6e4ed08`, `61cf104`), every prompt logged, and the agent scoped by `CLAUDE.md`
(it never edits `game/shaders/`). A reviewer can fairly conclude the systems run under scripted
input; the human checks (the author's own play of Missions 2 and 3) are still open.

**7. In, out, first, risk.** In: one district, one van, three missions, checkpoints, one fight.
Out: multiplayer, a wanted level, traffic, an open city. First: a fresh macOS export of
Mission 1, played by someone else from the title to its first checkpoint; the save file
appearing shows it ran. Risk: the frame rate. The slowest 5% of frames already take 17-19 ms
(budget 16.7 ms) and no export has been measured; I will measure it on power and battery and
cut the costliest effects first.

**8. Why this project?** "Mostly learning." Every skill above was new to the author in this
course ("all new to me, i'm mostly learning"); the tags show what was learned. The game is not
done: the story still needs improvements.

**Exists today**
- Missions 1-3 played to the end under scripted input: full recordings at `5ff34f1`, `b7ece7e`,
  `6e4ed08`. At `61cf104` (`game/` unchanged since), 2026-11-23: headless runs of Mission 1 to its
  end, Mission 2 to its title and Mission 3 from its stage 2 and stage 3 saves to the title
  screen, and the film's 4K takes.
- Shaders, particles, animation: tags `a5`, `a6`, `a7`.
- Tests and frame times: `game/tests/`, `TEST-REPORT.md`, `PERFORMANCE.md`; save rules 29/29 on
  2026-11-23 (`logs/pitch/test_save_rules_60fps.log`).

**Will exist**
- A current macOS export, measured on power and battery.
- The author's own play of Missions 2 and 3, and its fixes; story improvements.
- A test report for all three missions that a stranger can rerun.
- Voices for the story scenes.
