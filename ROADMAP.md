# ROADMAP.md: Blackridge: No Way Back, finished by 2026-12-20

**Status:** DRAFT. Claude Code wrote it on 2026-10-30 from the author's answers in chat. The
author edits and approves it.

This is the plan, not an assignment brief. Every change still gets its own
`CHANGE-BRIEF.md`, written and committed before any code, as the course requires.
Assignment 5's brief stays at tag `a5`. The course text may change before December 20.
When it does, a dated revision goes at the bottom of this file; the plan above it is not
rewritten.

## 1. Goal

- **A realistic game first.** "i want a real game as my final portfolio piece." Selling
  it on a store is optional and deferred: "we can skip selling also if its too much work.
  but i want realistic game." (C15, amended 2026-10-30)
- **The course comes first.** "dont do anything that will go against our assignments for
  now. focus on thedevelopement of game"
- **The whole game.** The design doc's must-ship game, with all three missions.
- **Near-photoreal but consistent, on a rainy night,** as realistic as the reference I
  showed:
  - the road looks real: dark wet asphalt, eerie and empty ("ghosted");
  - headlights matter: "the user should see the road little better when turned on. and
    less when turned off.";
  - a better van interior, and "all small details like this";
  - "add like realistic shaders if we need to, add animations do how a top mnc do it,
    follow best practices and techniques."
- **Professional throughout.** Best practices, current documentation, meaningful file
  names and a clean folder structure.
- **The course.** It passes Assignment 10, the final project (250 points), by 2026-12-20.
- **Written down and filed.** Every step and decision goes in the development log (the
  file I call "frequency.md"). Every picture we approve or reject is filed in the right
  folder.

## 2. Decisions

| Question | Decision | Recorded |
| --- | --- | --- |
| Purpose | A realistic, professional game. Selling is optional and deferred (§10). The course comes first | C15 (amended) |
| Scope by December 20 | All three missions from the design doc | C14 |
| Art target | Near-photoreal, but every model matches in detail and material style. This overrides the design doc's "stylized realism, low-to-mid-poly kit" | C11 |
| Renderer | Forward+ (was Compatibility, called provisional in `README.md`) | C12 |
| Export target | macOS desktop, Forward+. Windows follows for the store (§10) | C13 |
| Export templates | Godot 4.7.2's templates, downloaded and checked against the official SHA-512. Phase 1 installs them | C13 |
| Models | Free only: CC0 (Poly Haven) and CC-BY (Sketchfab). The licence must allow commercial use. Each model is credited, logos removed, and shown to me first | C10, C15 |
| Time of day | Rainy night | C11 |
| Target machine | This MacBook Air M4 with 16 GB | C10 |
| Low-beam look | Direction approved. Phase 1 tunes the exact values and shows them again | `captures/approved/` |

## 3. Schedule

| By | Assignment 10 target | Our work |
| --- | --- | --- |
| Nov 3 | Export target and renderer decided; export attempted | **Phase 1:** Forward+, the headlight fix, low beams and a darker night. The macOS export preset, the pack listing, and a release export with templates, launched and played (§6) |
| Nov 13 | Save rules written | **M1 draft playable:** route, objective, return to the depot, fail and retry. **Road realism.** Save rules written before any save code |
| Nov 23 | Persistence and menu working; the Assignment 9 technique arrives | **Saving and menu:** checkpoint and mission progress saved and loaded, and a keyboard-only menu. **New van and interior.** M1 complete |
| Dec 3 | A small complete playable loop; clean-clone rehearsal | **M1 polished,** including the accident beat. **M2 draft playable:** on foot, warehouse, guards. **Rain on glass.** Clean-clone rehearsal |
| Dec 13 | Integration begins | **M3 draft playable:** docks, airfield, guard fight. Story scenes as staged scenes with subtitles. **`GDD.md`** with status labels |
| Dec 13–20 | Integration, playtesting, repairs, two films | Full playtests, fixes, both films, clean clone of `a10`, submission |
| When I say | — | **Phase 0 (§5):** clean names and folders. **Selling (§10):** only if I decide to |

Assignments 6–9 arrive in between, each with its own brief. Realism work that fits one
is scheduled into it, so it counts twice:
- **Assignment 6 (particles):** rain, tyre spray and drain steam.
- **The animation layer:** stalks, switches, needles and hands.
- **Assignment 8 (pitch):** its "will exist" list is this roadmap's items.
- **Assignment 9 (game AI):** the warehouse and airfield guards.

**This is a lot for seven weeks alongside Assignments 6–9.** It only works if each mission
stays small, as the design doc's compressed plan intends, and if we follow the cut list
when a date slips.

**Cut list (Claude's call).** If we are behind at a checkpoint, cut in this order:
1. small details beyond the top few;
2. hands on the wheel;
3. van and camera motion;
4. world dressing outside the mission locations;
5. the scale of M3's convoy set piece.

**Never cut:**
- the three missions' playable spines;
- lighting, road and van realism;
- saving, the menu and the export;
- the Assignment 9 technique in real play;
- the tests and both films.

## 4. What Assignment 10 needs, and where it comes from

| Requirement | How this game meets it | When |
| --- | --- | --- |
| Generated art and sound | Existing synthesized audio and generated art | Exists |
| Blender assets | The new van is prepared and made fictional in Blender (§9.3). Assignment 3's assets were made for the earlier game, and the README explains that (§12) | Nov 23 |
| GDD and a 3D interaction with collision or physics | Van driving with collisions and recovery | Exists |
| A shader and a material | Assignment 5's dashboard and window-fog work | Exists |
| Particle effects | Rain, tyre spray, drain steam | Assignment 6 |
| Animation wired to player actions | Stalks, switches and needles; on-foot character animation | Nov–Dec |
| The game-AI technique | Guards in M2 and M3 (if Assignment 9 uses a state machine; §12) | Assignment 9 → Dec |
| Persistence | Checkpoint and mission progress, plus audio settings, as the design doc's `SaveData` plans | Rules Nov 13, working Nov 23 |
| Front door | Main menu and pause, keyboard only, focus set on start, accessible names | Nov 23 |
| Export | macOS preset with tests and dev scenes excluded and no credentials; inspected pack listing; release export launched and played; SHA-256 | Nov 3, final in Dec |
| Reproduction | A clean clone of `a10` imports and passes every check | Rehearsal Dec 3 |
| Pitch ledger | Assignment 8's "will exist" items marked delivered, changed or dropped | Dec |
| Documents | `GDD.md` with status labels, `HANDOFF.md`, `TEST-REPORT.md`, `PERFORMANCE.md`, `FRICTIONAL.md` with the five capacities, `SOURCES.md`, `LICENSE`, README | Ongoing; final in Dec |
| Two films | godot-walkthrough and godot-gdd, both with the walker modifier | Dec 13–20 |

## 5. Phase 0: clean names, folders and documentation (deferred)

**Deferred until I ask** (2026-10-30: "we will clean it up when i sat"). Until then,
documentation still changes in the same commit as the behaviour it describes, and new
files follow §5.3. The renames and moves below wait.

### 5.1 Renames and moves

Every move uses `git mv`, so history follows the file.

| Now | Becomes | Why |
| --- | --- | --- |
| `fractional.md` | `docs/DEVELOPMENT_LOG.md` | The name says nothing and sits next to the course's `FRICTIONAL.md`, a different file. This is the dated development record. Its links in 11 files are updated. When I say "frequency.md", Claude knows I mean this file |
| `game/MATERIALS.md` | `docs/MATERIALS_AUDIT.md` | Documentation belongs in `docs/`, not inside the Godot project |
| `docs/CLAUDE_HANDOFF.md` | `docs/history/CODEX_TO_CLAUDE_HANDOFF_2026-10-19.md` | A one-time history note. Its old name clashes with the course's `HANDOFF.md` |
| `LANGUAGE-NOTES.md`, `TEST-REPORT.md`, `SUBMISSION.md`, `evidence/`, `prompts/`, `sessions/`, `logs/` (Assignment 5's contents) | `course/assignment-05/` (same names inside), plus a copy of the `a5` brief | Assignment 5 deliverables in one place. The root keeps only what the product and the current assignment need. Tag `a5` still holds the originals where they were. The Assignment 10 versions of `TEST-REPORT.md` and `SUBMISSION.md` start fresh at the root |
| Empty `tools/blender/` and `source_assets/blender/first_drive/` (untracked); `.gitkeep` in folders that now have content | Removed | Clutter |

**Kept as they are, on purpose:**
- **`youtube/`:** the Brutalist film workflow's folder, which the next two films also use.
- **`game/shaders/`:** my own shaders.
- **Course-required names at the root:** `CHANGE-BRIEF.md`, `FRICTIONAL.md`,
  `SOURCES.md`, and later `HANDOFF.md`, `TEST-REPORT.md`, `PERFORMANCE.md`, `GDD.md` and
  `LICENSE`.
- **The approved reference images:** their original file names.

**Later, when that work happens:**
- **The two `first_drive.gd` files** (`game/app/` and `game/features/missions/night_freight/`):
  renamed when the mission flow is built. The app entry becomes `main`, and the mission
  script becomes `night_freight_mission.gd`. Renaming now would disturb Phase 1's tests.
- **The window-fog files** in `game/materials/windshield/` and
  `game/assets/textures/windshield/`: these were my Assignment 5 choice, outside the
  feature folders. They move into the van's feature folder when the new van arrives (§9.3),
  with the fog test updated.
- **Development-only scenes** (`game/experiments/`, `game/app/visual_benchmark.*`): they
  stay, but the export preset excludes them (§6).

### 5.2 Documentation brought up to date

- **README:**
  - "Current status", "Repository layout" and "Documentation map" are rewritten for
    today's state.
  - The goal and this roadmap are linked.
  - "MacBook Air M1" becomes M4 (C10).
- **`AGENTS.md`, `docs/DEVELOPMENT.md` and `docs/ARCHITECTURE.md`:**
  - "MacBook Air M1" becomes M4.
  - `AGENTS.md`'s old line "The current stage is repository setup only" is replaced with
    a pointer to this roadmap. I approve the `AGENTS.md` edits with this roadmap.
- **`docs/VISUALS.md`:** the art target follows C11.
- **`docs/DESIGN_DECISIONS.md`:** C11–C15 are already recorded.

### 5.3 Naming rules from now on

- **Godot files and folders** use `snake_case`. Nodes and `class_name` use `PascalCase`.
  Constants use `UPPER_SNAKE_CASE`, as `AGENTS.md` already says.
- **A scene and its script** share one name, such as `night_freight_mission.tscn` and
  `.gd`.
- **Tests** are named `test_<feature>.gd` and live in `game/tests/`.
- **Documents in `docs/`** use `UPPER_SNAKE_CASE.md`. Course-required files keep the
  course's names at the root.
- **Captures and evidence** are named `YYYY-MM-DD_what_it_shows.png`.
- **New file names** have no spaces and no brand names.

### 5.4 How Phase 0 is checked

- A link check over every Markdown file finds zero broken links.
- The Godot import is clean. Every test suite passes at 60 FPS with the same results as
  before.
- `git status` shows only renames and documentation edits. Nothing in the game's behaviour
  changes.

## 6. Phase 1: renderer, headlights, night lighting and export (by Nov 3)

### 6.1 Changes

1. **Renderer.** `game/project.godot:125` changes to `forward_plus`. README's renderer
   note records why.
2. **Headlight bug.** `_mark_layer` sets layers only on meshes, not on lights. The
   headlights then stay on the world layer and the driver's camera sees them.
3. **Low beams.** The headlights start from the §11.5 test values. A low-beam pattern
   image, made by a script, gives the beam:
   - a sharp top edge just below the horizon;
   - the brightest band right under that edge;
   - dimmer light toward the sides;
   - a slightly raised right side, because traffic keeps right.

   Both headlights cast shadows, because Godot needs that for the pattern image. The test
   values are starting points (Claude's call). Any of them may be tuned to pass §6.3 and
   my look check, and every change is logged.
4. **Darker night.** Moon 0.55 → 0.25, ambient 0.30 → 0.12, as starting values.
   Street-lamp pools should now show on the road.
5. **Wet-road reflections.** Screen-space reflections are turned on.
6. **No mist in Phase 1.** Volumetric fog stays off. The eerie mist comes with the road.
7. **Export.**
   - A macOS preset in a committed `export_presets.cfg`. It excludes tests and
     development-only scenes and carries no credentials.
   - The preset's version is `0.1.0`.
   - `--export-pack` is run and its listing inspected.
   - The 4.7.2 templates are installed, then `--export-release` is run.
   - The exported app is launched and played, and its SHA-256 recorded.

### 6.2 Not changed in Phase 1

- `headlights_on`, the L key, the `LIGHTS` text, the switch click, and the dashboard
  dimming shader and driver.
- Every file in `game/shaders/`: these belong to the author only.
- The window fog materials. They are re-checked by eye under Forward+ and changed only
  with my OK. If I approve new values, `test_materials.gd` changes to match, with a dated
  revision here. Assignment 5's brief stays at tag `a5` (Claude's call).
- The tonemap stays Linear unless lit surfaces clip to white (§6.3). Any tonemap change
  is shown to me with before/after stills (Claude's call).
- Everything in later phases.

### 6.3 How Phase 1 is tested

Captures use the parked start view at 3840×2400. Phase 1 moves the capture rig into
`tools/captures/` and adds a night-lighting take, so anyone can re-run the captures. The
rig is in `youtube/claude-liam-blackridge-gamedev/capture/scripts/`, and the film folder
keeps its copy. Regions (Claude's call):

| Region | Pixels |
| --- | --- |
| Road band | x 1300–2700, y 975–1140 |
| Band above the horizon | x 1300–2700, y 650–940 |
| Outside view | x 1100–3840, y 600–1100 |

The above-horizon band catches glow in the air. The white-out row catches lit objects.
Captures need a window, so they are evidence runs, labelled as such.

| Rule | Machine check | My check |
| --- | --- | --- |
| The driver's camera sees the headlights | New `game/tests/test_headlights.gd`: each headlight's layers overlap the driving camera's cull mask, and each headlight lights the world layer | Headlights light the road from the driver's seat |
| L still switches them | Same test: real L presses switch the lights off and on again | Press L while driving |
| The test catches the bug | Undo the layer fix: the new test exits 1. Restore it: the test passes | — |
| The road is clearly visible with the lights on | Capture: road band ≥ 2.5× brighter on than off | Drive the loop: easy to see the road |
| Less visible with the lights off, but not black | Capture: road band ≥ 20 with the lights off | Drive with the lights off |
| No glow above the road | Capture: the band above the horizon changes < 5% | No haze in front of the van |
| No white-out | Capture: under 1% of the outside view is pure white | Lit barriers, crates and doors keep their texture |
| Nothing else breaks | All existing suites pass at 60 FPS, unchanged except where §6.2 allows for new fog values | Dashboard dimming, `LIGHTS` text, wipers, windows and window fog look right |
| Export | The preset excludes tests and dev scenes; the pack listing is inspected; the release export's output is kept; SHA-256 recorded | The exported app launches and plays |
| Speed | — | Target 60 FPS in the 1280×800 window, never below 45 after a 10-minute drive (Claude's call). If it drops, cut reflection quality first, then shadow quality, then model detail. Recorded in `PERFORMANCE.md` |

## 7. How we build (every change)

- **Course process:**
  1. A `CHANGE-BRIEF.md` for each change, approved by me and committed before any code.
  2. Agent runs end by writing `HANDOFF.md`: files changed, exact test commands, real
     results, and what is unverified.
  3. My gate between runs: read the diff, run the import, rerun the tests, read the
     logs, commit.
  4. A run is clean only if every test exits 0 with no "SCRIPT ERROR", "SHADER ERROR"
     or "Failed loading resource" line. Any other "ERROR:" line is explained.
  5. Tests never touch my real save folder.
- **Pictures decide the look.** Every visual change gets before/after stills from the same
  fixed views, plus a windowed run for motion. I approve by eye. The stills are filed in
  `source_assets/artwork/captures/` under `approved/`, `rejected/` or `pending/`, and
  listed in its README.
- **Everything is written down:**
  - Requests, decisions, problems, fixes and results go in the development log on the
    day they happen.
  - My own honest notes, tagged with the five capacities (PA, PF, TO, IJ, EI), go in
    `FRICTIONAL.md`.
  - The README and the docs change in the same commit as the behaviour they describe.
- **Materials before custom shaders.** Physically based materials come first. A custom
  shader is written only where a standard material cannot do the job: the wet road, rain
  on glass, and road paint and signs that shine back at headlights. Shaders Claude Code
  writes live in the feature folder that uses them, never in `game/shaders/`, which stays
  mine only.
- **Animation the way large studios do it:**
  - The game state (speed, steering, switches) drives every animation. An animation never
    changes the game state.
  - Mechanical parts move on eased curves; needles and suspension move on damped springs.
  - Every motion uses real time (`delta`) and is tested at 30, 60 and 144 FPS.
  - One-off moves are AnimationPlayer clips, with the click sound on the right frame.
  - Characters and hands use AnimationTree state machines and blend spaces, plus inverse
    kinematics (IK) where a hand or foot must touch something.
  - Timings and strengths sit in editable resources.
  - Camera motion stays subtle and can be turned down in settings.
- **Models.** Free CC0/CC-BY only. Each one is credited, logos removed, and shown to me
  first. Every model in a scene matches the others in detail and material style.
- **Names.** Every new file follows the §5.3 naming rules, and the export preset carries a
  version number.
- **Speed.** Frame time is measured on the M4 after every phase, in `PERFORMANCE.md`.

## 8. The three missions (from `docs/GAME_DESIGN.md` §9)

| Mission | Player activity in the design doc | Story beat |
| --- | --- | --- |
| M1: Night Freight | Drive tutorial, route navigation, collision cutscene, return to depot | Ethan flees the accident and believes he was unseen |
| M2: The Wrong Cargo | Collect sealed load, inspect anomalies, retrieve vehicle, escape warehouse guards | Routine work becomes criminal; Vale links emerge |
| M3: Last Run | Docks betrayal cutscene, route to airfield, intercept convoy, rescue Lily, guard encounter | Maya's refusal to sacrifice revealed; Adrian dies in self-defence |

The design doc's must-ship list also needs:
- third-person movement on foot, with interact prompts;
- one compact combat encounter: aim, shoot, reload, health, simple guard AI, fail and retry;
- a checkpoint on every mission;
- the intro, betrayal, reconciliation, airfield climax, six-month epilogue, and the
  watcher and title stinger, in the order C04 fixes;
- a main menu, pause, audio settings, objective display, subtitles and credits.

Story details stay as `docs/GAME_STORY.md` writes them. Open narrative questions (N01–N05)
are asked, not invented.

## 9. Realism phases, in priority order

1. **Lighting and headlights.** Phase 1, §6.
2. **Road.**
   - Real asphalt textures (CC0).
   - Two lanes with edge lines and worn paint that shines in the headlights (shader).
   - Kerbs, gutters, drains, manholes, and crossing stripes at the depot.
   - Puddles that reflect lamps and ripple in the rain (shader).
   - Low, eerie mist far down the road, never in front of the headlights.
   - "Ghosted" is read as eerie and empty (Claude's reading; correct me). Faint traces of
     old lane paint that show when wet could add to it.
3. **Van and interior.**
   - **Model:** from the 2026-10-19 shortlist. First choice "Iveco Daily Van 2014" by Max
     (CC-BY, about 90k faces, 4K PBR, opening doors, seats); backup "Mercedes Benz
     Sprinter 2006" by Max. The cockpit detail is unverified.
   - **For a game we sell, two problems:**
     - Max adds a term beyond CC-BY ("not free of rights. You must inform me of your
       usage"). We need his written permission before selling, or another model.
     - Both are real, branded van designs, so the van must be made fictional in
       Blender: new grille, lights and badges.
     - I see the model before deciding.
   - **Whole van, not only the cab (Claude's call):** today's body was rejected too. So
     the headlights, mirrors, wheels and collision move with the new model.
   - **Dashboard:** low enough to see the road just ahead, as in the approved reference
     "Mercedes Van Drive to Downtown". The gauges, navigation screen and mirrors move in.
   - **Animation:** needles on springs with a start-up sweep; stalks, switches and the
     gear lever move when used, timed with their clicks.
4. **Rain on all glass.** Droplets on the side windows and mirrors that slide with speed
   (shader); the wipers clear them; lamps glare through wet glass. The rain, spray and
   steam particles come in Assignment 6.
5. **World for the mission locations.** Depot, warehouse, docks and airfield, built first
   from the Poly Haven CC0 assets already in
   `game/features/environments/depot_yard/polyhaven/`. Real buildings, fences, containers,
   poles and wires, trees instead of cones, and a night sky with bounce light.
6. **Hands on the wheel.** IK arms that follow the rim and reach for the stalks
   (first to cut).
7. **Van and camera motion.** Squat, dive and roll, small bumps, and a setting to turn
   motion down.
8. **Small details.** I pick from this list:
   - road signs glow in the headlights;
   - brake lights tint the road and the mirrors red;
   - indicators flash amber on walls and inside the cab;
   - the dashboard reflects faintly in the windshield;
   - reversing lights show in the reverse camera;
   - tyre spray;
   - wiper streaks;
   - small camera shake on bumps;
   - rain sounds louder with the window down;
   - steam from drains;
   - clutter in the cab: a clipboard, a cup, an air freshener.

## 10. Selling the game (optional, deferred)

Kept for reference only. I said "we can skip selling also if its too much work", so
nothing here is planned work until I decide to sell. The one rule that stays is cheap:
free CC0/CC-BY assets with credits (C10), which keeps selling possible.

The course build is due December 20. A store launch comes after that, once the game is
finished, tested on Windows, signed, and its store page approved.

**Licences (to settle before release):**
- **My own code and content.** The course allows MIT or my own copyright statement. To
  sell the game, "All rights reserved" is usual; MIT would let anyone reuse the code. The
  course needs a `LICENSE` file by December 20.
- **Every asset must allow commercial use.**
  - CC0 is fine.
  - CC-BY is fine with a credit in the game.
  - Never use a non-commercial (NC) or no-derivatives (ND) licence.
- **Godot is MIT.** Its licence notice and the third-party notices must appear in the
  game's credits.
- **Final audio from ElevenLabs** (C06) needs a paid plan for commercial rights. That
  conflicts with "Free only" (C10), so decide when we get there.
- **Fonts:** each font's licence is checked. The SIL Open Font License is fine.

**Platforms and signing:**
- **Platforms.** macOS first (the course target). Most store buyers use Windows, so a
  Windows export follows. It is tested on a real Windows PC before selling. Linux and
  Steam Deck are optional.
- **Mac signing.** A Mac build sold outside the Mac App Store needs an Apple Developer ID
  and notarization ($99 a year), or players see security warnings.
- **Windows signing.** Optional, but it reduces warnings.

**Choosing a store (after Dec 20):**
- **Steam:** the largest audience, a $100 fee per game, store page review, and an
  age-rating questionnaire.
- **itch.io:** no fee and quick to publish, but a smaller audience.

**What a store-ready game needs beyond the course:**
- A settings menu:
  - graphics quality presets, so weaker machines can run the game;
  - resolution and fullscreen;
  - audio volumes;
  - key rebinding;
  - subtitles;
  - a camera-motion setting.
- Controller support.
- A credits screen with every licence and attribution.
- Saves in the player's own folder, with a version field (the course's save rules cover
  this).
- A version number on every build, and a changelog.
- Full playthroughs with no crashes on the minimum machine, against a QA checklist.
- Store page material: capsule art, screenshots, a trailer and a description.
- An age rating. The game has gun violence and crime themes.

## 11. Evidence from the 2026-10-30 experiments

All tests ran on a scratch copy of the game with runtime-only changes. Each one captured
the same parked driver's view at 3840×2400. The stills and who decided on each are in
`source_assets/artwork/captures/README.md`.

1. **Forward+ alone barely changes the look.** Reflections, ambient occlusion, volumetric
   fog, glow and AgX together made the frame 21% darker, not more real. The gap is
   models and lighting.
2. **The headlights are hidden from the driver's camera.** `_mark_layer(_body, 2)`
   (`van_presentation.gd:62,259-263`) puts the two SpotLight3Ds on render layer 2. The
   driving camera sees only layers 1 and 3 (`cull_mask = 5`, `:132`). Switching the
   lights off changed 0.0% of the outside view, even at 12× the energy.
3. **The night is too bright for headlights to show.** Moon 0.55 and ambient 0.30
   (`industrial_loop.gd:47,59`) light the road roughly as much as the headlights would.
4. **Mist in front of the van hides the road.** Author: "terrible, cant see the road at
   all".
5. **A real low beam works.** Settings: Forward+, no mist, moon 0.25, ambient 0.12, and
   each headlight at energy 560 with a distance falloff of 1.0, aimed 2° down, with a 35°
   half-angle and a sharp-topped pattern.
   - The road band went from 26.3 to 78.9 (3.0×).
   - The road just past the dashboard went from 19.6 to 105.0.
   - The band above the horizon went from 63.0 to 64.2.

   Only the left headlight cast shadows, so only it had the pattern. Phase 1 re-measures
   with both.
6. **The dashboard hood sits almost at eye level.** It hides roughly the first 15 m of
   road.

## 12. Open items

- **Earlier layers:** Assignments 2–4 were built on an earlier game. The README must say
  how their layers (Blender assets, the Assignment 4 interaction) are carried or replaced.
  That is my call.
- **Assignment 9's technique:** not chosen yet. A state machine or behaviour tree would
  drop straight into the M2 and M3 guards (Claude's suggestion).
- **`CHANGE-BRIEF.md` during the overlap:** Assignment 10's preparation (saving, menu,
  export) overlaps Assignments 6–9. How one `CHANGE-BRIEF.md` serves both is unclear. Ask
  the instructor or decide when Assignment 6 arrives.
- **Repository name:** the course expects a name starting `walker-`. I kept
  `blackridge-no-way-back` (2026-10-30), and the README says so.
- **Selling (§10), deferred:**
  - the store;
  - my own licence;
  - Apple signing and notarization ($99 a year);
  - Max's permission or another van;
  - ElevenLabs versus "Free only".
- **The van model choice and "ghosted"** (§9).

## 13. Files that change with Phases 0 and 1

- **Phase 0 (deferred):**
  - the renames and moves in §5.1;
  - README, `AGENTS.md`, `docs/DEVELOPMENT.md`, `docs/ARCHITECTURE.md` and
    `docs/VISUALS.md` (§5.2);
  - every Markdown link that pointed at a moved file.
- **Phase 1:**
  - **`CHANGE-BRIEF.md`:** replaced by Phase 1's brief and committed before code.
  - **`CLAUDE.md`:**
    - the current change and `HANDOFF.md` pointers;
    - the renderer line says Forward+;
    - Assignment 5's "Out of scope" list is replaced by §6.2.
  - **New files:** `export_presets.cfg`, `HANDOFF.md` and `PERFORMANCE.md`.
  - **`TEST-REPORT.md`:** a dated final-project section. Assignment 5's section stays
    until the Phase 0 cleanup.
  - **README:** the renderer note and the export state.
  - **The development log:** a dated entry for every request, decision and result.
  - **`source_assets/artwork/captures/`:** the Phase 1 stills.

## Revision 2026-10-30 (evening): repository structure, branches, Assignment 5

- **No assignment folders.** "i dont want it to look like assignment 5 and assignment 6
  after done with this course. i want to keep it as professional and i developed and
  portfolio piece". Course submissions are kept only as git tags (`a5` … `a10`). This
  replaces §5.1's plan to move Assignment 5's files into `course/assignment-05/`.
- **Branches.** `main` stays exactly as the last graded submission, which is what the TA
  sees. All work happens on `develop`, which is pushed as a backup. After Assignment 5 is
  graded, a pull request merges `develop` into `main`: "for now we will make a pr later
  after assignment 5 is graded". Later assignments follow the same path: merge, then tag.
- **Nothing removed for the TA.** "dont remove everything what we have in files till now.
  the ta will check our assignment". `main` and tag `a5` keep every Assignment 5 file
  unchanged.
- **Portfolio cleanup after December 20.** This replaces §5 as the cleanup plan, and it
  needs my approval at the time:
  - the README becomes the game's page;
  - course-only files move to `docs/development/`, or off `main` (the tags keep them);
  - a `v1.0` tag marks the portfolio version.

  §5.3's naming rules apply to new files now.
- **Assignment 5 is not resubmitted.** "its fine. focus on creating making realistic
  game".
- **Every step is approved first.** "at each step take my approval and then only do it".
  This is recorded in `CLAUDE.md`.
