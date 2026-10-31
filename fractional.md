# Blackridge development record

This is the running history requested by the author on October 18, 2026. Record
requests, approved scope, decisions, implementation batches, problems, fixes, and
validation honestly. Update it as work continues. The story and design documents
remain the narrative sources of truth. This record does not silently resolve
their open questions or replace `docs/DESIGN_DECISIONS.md`.

## Version control status

Git was initialized locally on 2026-10-28 at the author's request, on branch
`main`, with no remote yet. Commit `e81ec92` holds the project as found that day,
before any Assignment 5 work. Entries dated before 2026-10-28 describe work
sessions, not Git commits. Later entries name their commits.

## 2026-10-18 — Requests and approvals

1. The author asked to begin implementation, including shaders, music, sound
   effects, and realistic presentation. They described thriller pacing built on
   purposeful player activity and unresolved questions, rather than obligatory
   events every thirty seconds.
2. Both primary documents, design decisions, development guidance, architecture,
   and root instructions were read in full. The pasted pursuit scenario was
   treated as a pacing illustration, not approval to replace the freight/family
   story, add branching endings, or implement police and fuel systems.
3. Before the next clarification arrived, a mesh construction helper and three
   initial shaders were added. No playable scene existed at that point.
4. The author required an explanation and approval before further actions. Work
   stopped and the proposed implementation stage was explained.
5. The author clarified that realism applies throughout the game. Their examples
   included functioning indicators, speedometer, wipers, rear camera, mirrors,
   rolling windows, and combat feedback such as flash, recoil, falling casings,
   and sound. This establishes a game-wide quality target; combat is a later
   implementation stage. The falling casing interpretation was stated explicitly;
   ballistic bullet drop was not silently added as a requirement.
6. The detailed van prototype in a compact industrial environment was proposed
   as the first implementation stage. The author approved: “yes. now proceed.”
7. During implementation the author asked whether textures or “normaliser” inputs
   were needed, requested explanations of the code, and requested `fractional.md`
   to track requests, decisions, problems, solutions, and commit-like work history.
   Normal maps were explained as a possible interpretation. No external asset
   purchase, dependency installation, Git operation, or publishing was requested.

## Approved first implementation stage

Build a vehicle prototype with cockpit driving, a bounded industrial road loop,
a depot navigation/parking objective, working instruments, indicators/hazards,
headlights, wipers, live rear/interior/side camera views, opening side windows,
and responsive engine/rain/wind/control audio plus sparse music. Validate the
interactions before proposing further mission or combat work.

The approved realism goal raises the original design's optional instrument
detail target. The primary source documents are preserved. The current work does
not resolve pedestrian identity, villain knowledge, evidence authenticity, Lily's
rescue staging, or legal consequences. It does not claim a complete first mission
or a finished realistic art pass.

## Implementation batch 01 — In progress

- A shared mesh helper creates simple meshes and materials used by the vehicle,
  environment, and temporary driver representation. Actual reuse justifies the
  shared location; no global managers or autoloads are introduced.
- A bounded industrial loop is assembled once at startup with depot geometry,
  roads, signs, warehouses, fences, lamps, distant structures, and collision.
- Wet asphalt and industrial wall shaders provide procedural surface variation.
  Windshield droplets are drawn on the glass, with clearing tied to wiper state.
- The van uses `CharacterBody3D` for predictable arcade handling. This is an
  implementation candidate, not a validated physics simulation. Controls use
  named Input Map actions. Forward/reverse selection requires near-zero speed.
- A separate presentation script owns cabin geometry, controls, instrument and
  navigation textures, lights, windows, and camera views. Mirrors use live
  low-resolution views at a requested fifteen updates per second; the reversing
  view updates while reverse is selected. Performance has not yet been measured.
- Original prototype audio was synthesized with a standard-library Python source
  script outside `game/`. Runtime WAVs live with their playback feature. The audio
  mix responds to speed and window opening. These are synthesized starting sounds,
  not final vehicle recordings. No third-party asset licenses are involved.
- A driving-trial route tracks ordered landmarks, depot parking, and recovery.
  It uses a dedicated `user://driving_prototype.cfg`, separate from future story
  saves. This is a prototype route, not the completed narrative M1.
- A minimal temporary driver supports the vehicle entry/exit check. Final
  character art and animation remain future work.

### Problems and solutions

| Problem | Response | State |
| --- | --- | --- |
| `git status` reports that this is not a Git repository. | Preserve the existing setup; record work here without inventing commits or initializing Git. | Confirmed |
| Live mirrors multiply scene rendering work. | Use small viewports and bounded refresh rates; only request the reversing view in reverse. Measure rather than assume M1 performance. | Implemented, unvalidated |
| Audio source recordings and detailed art do not exist in the scaffold. | Author reproducible procedural materials and synthesized sound assets as a working foundation. Keep their prototype status explicit. | Implemented, unvalidated |
| A patch attempted to delete and add the same shader in one operation and was rejected. | Apply the new presentation file separately and replace the shader in a separate write. No partial application was assumed. | Corrected |

### Validation status

Implementation is in progress. Engine import, rendered inspection, interaction
regressions, route completion, and performance checks have not yet passed or been
claimed. Record actual commands, results, and limitations before finishing.

## Beginner's code map

| File | Purpose in plain language |
| --- | --- |
| `game/shared/components/mesh_builder.gd` | Small construction helpers for boxes, cylinders, materials, and signs; these build the current procedural art. |
| `game/features/environments/industrial_loop/industrial_loop.gd` | Places the road, depot, buildings, lights, and barriers once when the environment starts. |
| `game/features/vehicles/freight_van/freight_van.gd` | Reads the controls, changes speed and direction, checks collisions, and owns accessory state. |
| `game/features/vehicles/freight_van/van_presentation.gd` | Shows what the vehicle is doing: steering wheel, lamps, moving glass, wipers, and live camera displays. |
| `game/features/vehicles/freight_van/instruments.gd` | Draws gauges using the controller's actual speed, gear, and light states. |
| `game/features/vehicles/freight_van/navigation_display.gd` | Draws the small map and the current route destination. |
| `game/features/audio/first_drive/driving_audio.gd` | Plays and mixes vehicle sounds, weather, and music. Window position changes how exposed the cabin sounds. |
| `source_assets/audio/first_drive/synthesize.py` | Recreates the original synthesized WAV files. It is an authoring source, not a runtime dependency. |
| `game/features/missions/night_freight/first_drive.gd` | Checks the test-route landmarks in order and remembers a safe recovery checkpoint. |
| `game/features/characters/driver/driver.gd` | Provides basic third-person movement for leaving and reentering the van. |

A shader is a small program that tells the graphics processor how a surface
looks. These shaders currently calculate detail mathematically. A later texture
set can supply authored color, normal, roughness, and metalness information;
adding maps alone will not replace the need for suitable geometry and lighting.

## 2026-10-18 — Log format clarification

The author shared their previous HOUSEGHOST frictional log as a model and asked
that this record present their work professionally. That example belongs to a
different project; its assignment requirements, personal verdicts, tools, commits,
and account operations are not Blackridge history and are not imported here.

Future entries will use a decisions table and dated, chronological session notes.
New reversals will be appended rather than silently rewriting past decisions.
Codex supplies the factual account of work performed in this session. The author's
judgments will be attributed only when actually expressed; no imagined learning,
reactions, approvals, or personal shortcomings will be written in their voice.
Problems will be explained through their technical cause, response, and verified
result. Unfinished checks remain marked unfinished.

### Decisions and responsibilities

| Topic | Codex proposal or action | Author direction | Outcome |
| --- | --- | --- | --- |
| Starting implementation | Proposed a compact first driving slice against the existing story/design. | Asked to start implementation with shaders, music, effects, and realistic presentation. | Implementation began within the existing game concept. |
| Approval before action | Paused when the new approval requirement arrived and explained the next stage. | Required explanation and approval before actions. | Work resumed only after “yes. now proceed.” |
| Meaning of realism | Initially proposed an atmospheric driving foundation. | Clarified that detailed working interactions are a game-wide target; gave vehicle and firearm examples. | First stage expanded to the detailed vehicle prototype; combat remains later. |
| Art and sound inputs | Proposed procedural materials and reproducible synthesized audio to exercise interactions. | Asked whether they needed to provide textures or other inputs. | No inputs are needed to continue the prototype. Finished art/audio remain an explicit later quality task. |
| Development record | Created `fractional.md` with requests, scope, implementation, and current limitations. | Requested a continuing record and supplied HOUSEGHOST as a style example. | Use factual attribution, dated decisions, technical evidence, and professional wording. |
| Commits | Read-only Git check found no repository. | Has not requested Git initialization or commits. | No Git mutations; work batches are recorded without invented hashes. |

### 2026-10-18 — First engine check encounters a save-directory restriction

- **Work and expectation:** Run the installed Godot 4.7.2 editor's headless import
  command after connecting the driving scene, controls, and interface.
- **Observation:** The process reports that it cannot create the default
  application-data directory beneath `~/Library/Application Support/Godot/` and
  cannot open `user://`. That location is outside this session's writable roots.
  It also reports a system certificate access error. These are environment
  observations; they do not establish whether the gameplay scripts are valid.
- **Author contribution:** Set the approval and documentation requirements and
  the intended realism standard. No author action caused this filesystem limit.
- **Codex response:** Investigate an isolated writable test-data location and
  capture actual parse/runtime results before claiming validation.
- **Evidence and next step:** Initial command:
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path game --import`.
  Validation is still in progress. No permission escalation has been requested.

### 2026-10-18 — Approval clarified per code batch; final audio remains the author's choice

- **Author direction:** The author clarified that code must be explained before
  approval for each batch, rather than treating the earlier “now proceed” as
  ongoing permission for the entire prototype. Codex stopped. The author then
  explicitly approved validation and documentation updates, with runtime fixes
  to be explained and approved separately.
- **Audio decision:** The author wants to generate/select final audio in
  ElevenLabs at the end. Current synthesized sounds can be reviewed, kept, or
  replaced according to their preference. Codex recorded this in `docs/AUDIO.md`
  and C06 of `docs/DESIGN_DECISIONS.md`; no external generation was performed.
- **Record convention:** The author reiterated that HOUSEGHOST was only a sample.
  Blackridge's log keeps its own history and evidence, using that example's care
  with attribution and chronology without adopting another project's rules.
- **Implementation boundary:** This validation batch changes documentation and
  produces local diagnostic scripts/logs. Runtime fixes have not been applied.

### 2026-10-18 — Headless checks identify three bounded fixes before visual review

- **Work and expectation:** Check parsing/startup, accessory responses, movement,
  blocked exits, wall collisions, route ordering, source assets, and audio loops.
  Validation scripts use the installed Godot 4.7.2 engine and existing project.
- **Measured results:** Sixteen startup/script checks passed. The behavior suite
  passed 27 checks and failed two: clear-ground steering clearance and resulting
  heading change. Twelve safety/route-state checks passed. All twelve source WAVs
  are readable and their durations/formats match the inventory. Literal resource
  references resolve. One GDScript line exceeds the repository's width convention.
- **Steering finding:** Codex's clearance test includes ground contact. Diagnostic
  output identified the ground mesh, not an obstacle beside the van. Reducing
  only the diagnostic query's height by 0.1 m removed that overlap. The physical
  controller remains unchanged while approval is pending.
- **Audio finding:** Imported WAV format 3 is compressed. Codex's loader derived
  loop-end frames from bytes, which is wrong for this format. For the score, the
  current boundary is 142,780 frames instead of the 705,600 frames in 32 seconds.
  The six inspected continuous sounds all show the issue; the horn uses the same
  path. Proposed correction: use duration and sample rate, then verify all loops.
- **Save feedback finding:** The environment denies writes to the normal Godot
  application-data directory. Route state continues in memory and logs the write
  failure, but the HUD still receives “Checkpoint saved.” Proposed correction:
  make success conditional on the actual write result and expose failure clearly.
  Successful persistence across launches has not been claimed.
- **Graphical check:** A graphical Godot launch aborted with exit 134 during
  macOS application registration, before a rendered capture. The crash stack
  includes `_RegisterApplication` and menu-bar initialization. Its underlying
  cause is not established. No screenshot, mirror-image verdict, shader-rendering
  verdict, audible listening verdict, FPS, or sustained-memory result is claimed.
- **Test interpretation:** The route harness places the van at gates to test
  ordering and stopped parking. This is not a complete driven mission. Headless
  mirror checks confirm shared-world cameras and transform wiring, not rendered
  content. Immediate-shutdown audio warnings disappeared in the harness that
  waited for teardown; no production memory fix was assumed from that observation.
- **Codex contribution:** Wrote and ran the diagnostic checks, isolated the
  steering and loop causes, identified inaccurate save feedback, and updated
  README, architecture/development guidance, decisions, audio inventory, and
  `docs/VALIDATION.md`. These are assistant-authored implementation findings, not
  mistakes or judgments attributed to the author.
- **Evidence and next step:** Local harnesses and logs are preserved in ignored
  `builds/first_drive/`; `docs/VALIDATION.md` lists the actual evidence and limits.
  Explain the three fixes and obtain approval before changing runtime code. No
  Git initialization, commits, pushes, purchases, or external service actions.

### 2026-10-18 — Three fixes approved, with playable phase gates

- **Author approval:** “fix them following best practices. how top games work.”
  This approves the explained steering, loop-boundary, and checkpoint-result
  fixes plus their regression checks. It does not authorize another feature phase.
- **Work performed:** The van's physical box is preserved. A separate cached
  turning query clears the floor while retaining side/front/rear and roof bounds.
  Audio loop ends now use duration and sample rate. Checkpoints write to a
  temporary file and replace the prior file only after a successful write;
  success/failure signals drive the corresponding HUD message. Tests use a
  dedicated path, with the normal runtime path still under `user://`.
- **Author's phase requirement:** The author wants to play and judge each phase
  before further expansion. Codex will finish this approved vehicle batch,
  supply launch instructions and a playtest checklist, and wait for the author's
  actual verdict. Automated checks will not be recorded as a human playtest.
- **Documentation requirement:** Keep this record updated alongside project
  guidance. The requested record remains `fractional.md`; no second spelling
  or duplicate log is introduced.
- **Validation underway:** The editor import has no script parse errors, while
  the existing application-data/editor-settings restrictions remain. Initial
  regression results pass clear-ground left/right turning and turning away from
  an adjacent obstacle, reject turning into that obstacle, and confirm the
  original physical collider dimensions. Remaining results will be appended.
- **Next step:** Finish the regression suite, update current documentation and
  phase checklist with measured results, then hand the build to the author for
  the first interactive review. No commits or additional gameplay features.

### 2026-10-18 — Wall contact exposes a separate gauge issue; author approves its fix

- **Finding:** The initial retained regression suite passed 59 of 60 checks.
  At the failed wall check the van's physical velocity was `(0, 0, 0)` and its
  travel stopped at the expected near face, but the controller's internal speed
  was about 0.44 m/s while throttle remained held. The check had treated that
  internal value as physical motion; the instrument panel did too.
- **Approval boundary:** Codex explained that physical stopping worked but the
  gauge could read about 1.6 km/h while stationary. It asked separately whether
  to fix the measured speed in this phase or record it after the author's test.
  The author answered: “fix it in this phase.”
- **Approved correction:** Record signed longitudinal motion after Godot's
  collision movement; use its magnitude for the analog and digital speedometer.
  Reset measured speed during recovery. Keep the existing controller movement
  state separate rather than changing handling as an incidental gauge fix.
- **Regression interpretation:** The wall test now checks actual physical motion
  and the measured speed used by the gauge separately. New checks cover forward
  measurement, reverse measurement, and immediate reset. This is not simply
  relaxing a failing threshold or hiding the initial result.
- **Status:** The additional fix and updated checks are written. Results follow
  after the next run. The tachometer remains a prototype RPM estimate, not an
  implemented engine/transmission simulation.

### 2026-10-18 — Retained regressions pass; phase remains open for the author's playtest

- **Measured result:** `tools/tests/first_drive_regression.gd` completed with
  **64/64 checks passed**, exit 0, no script errors. Seven source-WAV loop counts,
  separate playback resources, one-shot modes, measured forward/reverse speed,
  recovery reset, clear-ground turning, adjacent obstacles, physical stopping,
  checkpoint write/replacement failures, old-save preservation, real disk reload,
  invalid save values, HUD messages, and safe exit/reentry are covered.
- **Environment limits:** The engine still reports denied normal application-data
  and editor-settings access and a system certificate error. The retained tests
  use unique temporary checkpoint paths before initialization and clean their
  fixtures. Expected write/replacement fault warnings are labeled by the test.
  Passing assertions do not erase those environment observations.
- **Additional integration finding:** The earlier accessory harness rerun passed
  28/29 checks; the reversing screen was observed before the next physics update.
  That harness had waited for process frames after input, which does not guarantee
  a physics tick. A retained integration script now waits for physics and then a
  process frame before checking the result. No production timing was changed.
  Its final outcome will be recorded after completion.
- **Documentation and handoff:** `docs/PLAYTEST.md` now explains how to import/run
  the project, lists the vehicle interactions to try, and leaves every author
  verdict pending. README, architecture, design decisions, development guidance,
  audio documentation, tools guidance, and validation report have been updated.
  The measured-speed change is explained separately from the RPM estimate.
- **Gate:** The author has not yet played or accepted this phase. Next-phase
  features remain outside this batch. The next useful decision comes from actual
  play and feedback, not another automatic feature expansion.

### 2026-10-18 — Phase 1 handed back for interactive review

- **Final automated result:** Retained regression suite **64/64 passed**; retained
  integration suite **29/29 passed**. Both exit 0 with no script errors. The final
  editor import has no GDScript parse errors; known engine environment errors
  remain explicitly recorded. Current local Markdown links and GDScript
  indentation/line-width checks pass.
- **Integration resolution:** Waiting for a physics tick before reading accessory
  display state resolves the old harness's timing-dependent reversing assertion.
  The earlier 28/29 result is preserved in `behavior_after_fixes.log`; the final
  retained outcome is in `integration_final.log`. This changes test synchronization,
  not the game's gear-change or presentation timing.
- **Completed scope:** The approved three fixes plus separately approved measured
  speed are complete. Existing player save files, story sources, renderer, engine
  baseline, and provisional audio selections were not changed by these fixes.
- **Handoff:** Import `game/project.godot` in Godot 4.7.2, run the project, and select
  Begin / continue drive. `docs/PLAYTEST.md` supplies controls and review criteria.
  The current phase is a vehicle/control prototype; final realism is still a
  quality target, not an accepted result.
- **Pending author work:** Actual playtest and verdict. No human review, rendered
  inspection, listening approval, normal-path relaunch test, full driven route,
  sustained performance figure, Git commit, or next-phase approval is invented.
- **Next action:** Wait for the author's Phase 1 feedback before expanding scope.

### 2026-10-18 — Repeatable testing guidance added before the author's first review

- **Author request:** Follow implementation and testing best practices throughout
  development and explain how the author should test the game. The standing
  requirement for explanation/approval before code batches remains in effect.
- **Scope of this batch:** Documentation only. No gameplay, project settings,
  dependencies, assets, save files, or test code changed; existing game suites
  were not rerun for this documentation edit.
- **Guidance added:** `docs/PLAYTEST.md` now starts with stable test conditions and
  a three-minute smoke test. It then covers one-feature-at-a-time checks, moving
  gear/exit restrictions, collision/recovery, normal save/relaunch, sound/visual
  review, and a sustained M1 observation session. New drive's checkpoint-reset
  effect is explicit so save/relaunch testing has a known starting state.
- **Evidence standard:** Use Pass, Fail, Blocked, and Not run. Report exact steps,
  expected and observed behavior, repeatability, impact, and any real error.
  Retest the original failure after a fix, followed by smoke and related checks.
  Assertion counts do not establish a coverage percentage or human acceptance.
- **Official tools checked:** Godot's Debugger and Profiler documentation was
  consulted. Regular Profiler and Monitors provide available frame/physics/script,
  FPS, memory, and object information. Visual Profiler is unsupported with the
  current Compatibility renderer on macOS; GPU figures stay unavailable. No
  renderer switch or external profiling-tool installation was made.
- **Workflow recorded:** `docs/DEVELOPMENT.md` now states the testing sequence,
  isolated fixtures, timeouts, appropriate physics synchronization, evidence-based
  regression checks, and the requirement to preserve failures rather than weakening
  checks for a green result. The practical steps remain in the playtest guide.
- **Current status:** Prior measured results remain 64/64 regression and 29/29
  integration checks. No new human test, visual pass, listening verdict, relaunch
  result, or performance measurement is claimed. Phase 1 awaits author play.

### 2026-10-18 — Author reports an empty view; editor/runtime distinction investigated

- **Author report:** Opened the project and could not see anything; also asked
  whether images can be pasted into the terminal. No screenshot has been received
  and the exact blank view has not yet been confirmed.
- **Read-only investigation:** The environment and cockpit are constructed by
  runtime scripts, and the saved scenes contain their entry nodes rather than
  visible authored mesh children. Consequently, the editor viewport can look
  empty before Run Project. This does not diagnose a blank running game, which
  would remain a launch/view blocker.
- **Clarification requested:** Is the blank view the editor before Run, the game
  after Run/F5, or a failure to open a game window? The answer remains pending.
- **Handoff correction:** `docs/PLAYTEST.md` now explains the runtime-generation
  editor-preview limitation and the distinction between editor and running-game
  failures. Codex had not made this limitation explicit in the initial handoff.
- **Image support:** Installed CLI reports version 0.162.1 and its help lists image
  input flags. The OpenAI Docs skill was used to check official image-input
  documentation, which supports image inputs/pasting and command-line attachment.
  A saved PNG's local path is also sufficient for this assistant to inspect it
  through the available image viewer; no new CLI session is required for that.
- **Scope:** No game/renderer changes, screenshot capture, dependency installation,
  or new test-pass claim. Continue diagnosis from the actual view/image before
  proposing any code fix for approval.

### 2026-10-18 — Clipboard screenshot workflow confirmed

- **Author preference:** Copy screenshots to the clipboard and paste into the
  terminal rather than save a file and provide its path.
- **Verification:** The installed Codex CLI is 0.162.1 in a VS Code terminal.
  Its bundled interactive help explicitly says to paste an image with Ctrl+V
  to attach it to the next message. Official image-input documentation also
  confirms pasting images into the interactive composer.
- **Guidance:** On macOS, capture a selected area to the clipboard with
  Control+Command+Shift+4, focus the Codex prompt, and press Control+V. Confirm
  an image attachment appears before sending. Actual paste success and the
  Godot screenshot remain pending; no clipboard contents were read by Codex.
- **Scope:** No application settings, game code, dependencies, or terminal
  shortcuts changed. The game-view diagnosis is still open.

### 2026-10-18 — Clipboard image received; empty view confirmed as the editor

- **Evidence received:** The author's pasted screenshot shows `first_drive.tscn`
  open in Godot 4.7.2's 3D editor, with the expected FirstDrive, IndustrialLoop,
  FreightVan, DrivingTrial, and DrivingHud scene nodes. The visible empty area
  is the editor viewport, not a captured running-game view.
- **Diagnosis:** This matches the already documented runtime-generation preview
  limitation. The screenshot does not establish whether the running game renders
  correctly. Clipboard attachment worked; no saved-file workaround is needed.
- **Next instruction:** Click Run Project, the triangle in the upper-right toolbar,
  or use F5/Fn+F5. Then select Begin / continue drive if the menu appears. If that
  runtime view is empty or errors appear, capture that state for separate diagnosis.
- **Scope:** No gameplay, scene, renderer, or editor-setting changes. Phase 1's
  interactive result remains pending.

### 2026-10-18 — Running view received; fullscreen guidance

- **Author request:** Make the game fullscreen and confirm whether it is 3D.
- **Evidence received:** The new screenshot shows the running NIGHT FREIGHT menu,
  cockpit instruments, and environment inside Godot's game preview. This confirms
  visible runtime output on the author's machine; driving, audio, sustained
  performance, and phase acceptance remain unverified.
- **Explanation:** The world and vehicle are 3D; the menu and HUD are 2D overlays.
  The small preview is an editor presentation setting.
- **Guidance:** Stop the game, open Editor Settings, search for window placement,
  and select Run > Window Placement > Rect > Force Fullscreen before running
  again. Godot's official EditorSettings documentation confirms that this launch
  mode disables embedding. Fullscreen success awaits the author's check.
- **Scope:** Documentation only. No game code, project configuration, or local
  editor settings changed.

### 2026-10-18 — Correcting the macOS settings instructions

- **Author evidence:** The Editor menu screenshot has no Editor Settings item.
  Codex's previous menu path did not account for macOS native menu placement.
- **Correction:** Use the Godot application menu beside the Apple menu to access
  Editor Settings, or press Command+Comma. The official engine source registers
  Command+Comma as the editor settings shortcut. Then select the previously
  described fullscreen launch setting. Success remains pending author testing.
- **Scope:** Documentation only; no editor settings or game files changed.

### 2026-10-18 — Author rejects the prototype's visual quality

- **Author feedback:** "the game isnt realstic at all. its not matchig to gta
  level graphics". This is a visual rejection, not evidence that every functional
  check failed or that the author has completed the driving checklist.
- **Read-only findings:** The vehicle presentation and industrial environment use
  primitive meshes extensively. Asphalt and wall shaders generate simple patterns;
  they do not supply a detailed authored surface texture set. Accessory behavior
  and passing automated checks do not establish realistic visual quality.
- **Expectation gap:** The preserved design specifies stylized realism. The
  author's GTA comparison asks for a higher visual standard. No source document,
  renderer, engine, or production scope was silently changed to resolve this.
- **Proposed next batch:** Establish one cockpit/depot view as a visual benchmark,
  with improved models, surface materials, lighting, glass, and rain. Explain asset
  provenance and code changes before implementation; review the actual playable
  result and measured performance before extending treatment to the whole route.
  GTA-equivalent quality is not promised. Approval remains pending.
- **Documentation:** Updated VALIDATION.md and PLAYTEST.md to record visual
  non-acceptance separately from functional checks. No runtime code, assets,
  dependencies, or settings changed; no new test run was warranted.

### 2026-10-18 — Author supplies ChatGPT cockpit reference provenance

- **Author request:** Record the supplied screenshots in this log. The generated
  image is in Downloads > Image References for Game; more references are still
  being generated. Also add a rejected folder.
- **Provenance:** Both attachments are screenshots of the author's ChatGPT image
  conversation. They document generated concept references, not actual gameplay
  screenshots, a delivered 3D asset, or an engine-rendered quality result. The
  browser screenshots were not copied into the repository because they include
  unrelated browser and conversation UI.
- **Initial prompt, transcribed from screenshot 1:**

  > Photograph from the driver's seat of a modern cargo van, eye level. Full
  > dashboard, leather steering wheel with stitching, lit instrument cluster,
  > windshield with faint dust and small chips, both side mirrors showing the
  > road behind, rear-view mirror, A-pillars, visors. Overcast noon, diffuse light,
  > suburban road ahead with traffic. Everything in focus. - for my game, high
  > real graphics

- **Follow-up prompt, screenshot 2:** "make it look like its in a game". The
  displayed follow-up adds visible driver hands and a warmer, more sunlit scene.
  These are observations of the reference, not authorization to add hands,
  traffic, a branded vehicle, or a new weather system to the game.
- **External original located:**
  `/Users/narasimhareddyvalam/Downloads/Image References for Game/Cinematic Mercedes Van Drive Through Autumn City.png`.
  The file exists; it has not been moved, renamed, imported, or classified as
  accepted/rejected. The author has not selected a final visual reference yet.
- **Requested organization:** Attempted to create
  `/Users/narasimhareddyvalam/Downloads/Image References for Game/rejected`.
  The filesystem returned `Operation not permitted`; Downloads is outside this
  session's writable roots. The directory was not created. The author can create
  it in Finder with Shift+Command+N inside the reference folder and name it
  `rejected`. No image has been selected for rejection or moved.
- **Scope:** Log maintenance and a blocked folder-creation attempt only. No game
  implementation, asset download, image generation, or reference approval occurred.

### 2026-10-18 — Reference organization handled inside the project

- **Author request:** Supplied two further ChatGPT conversation screenshots and
  said "do it for me, i dont want to do manually" after the rejected-folder
  instructions. Codex stated the project-folder fallback before acting.
- **Cockpit-detail prompt, transcribed from screenshot 1:**

  > Macro-detail photograph of a van dashboard and center console. Textured black
  > plastic with uneven gloss, rubberized buttons with worn lettering,
  > chrome-ringed gauges, leather seat bolster, gear shifter, scuffed cup holder,
  > fingerprints on the infotainment screen, dust in seams. Soft window light.
  > Sharp across the frame.

- **Follow-up prompts:** "give me bmw", then "give me bmw and entire dashboard."
  Screenshot 1 shows the earlier van close-up; screenshot 2 shows a BMW-branded
  full-dashboard concept with a digital cluster, navigation display, blue cabin
  trim lighting, and a daylight road scene. This records the author's reference
  exploration; it does not establish selection of a BMW or rejection of a van.
- **Organization completed:** Created `source_assets/artwork/references/` and its
  `rejected/` subfolder within the writable project. Copied the one standalone PNG
  currently present in Downloads, preserving its filename and external original:
  `Cinematic Mercedes Van Drive Through Autumn City.png`. Original and copy match
  SHA-256 `a0c7e4647d18903b8758b1ac762af0d5551c68c77cf78e5abe4ece339d5f568f`.
- **Inventory and status:** Added Markdown inventory/provenance and a rejected
  folder note. No reference is marked accepted or rejected. The two latest
  standalone generated images were not present in the Downloads reference folder
  at the time of inspection; only their supplied conversation screenshots were
  available. Browser screenshots containing unrelated UI were not copied.
- **Boundary:** The Downloads folder remains unchanged because this session
  cannot write there. The requested rejected folder now exists in the project's
  reference collection instead. No manual project-folder setup is needed.
- **Validation:** Verified the copied image against the original using SHA-256
  and confirmed that the rejected directory exists. No runtime resource changes
  or new game test claims; reference selection and visual implementation remain
  pending the author's decisions and approval.

### 2026-10-18 — Approved reference collection inspected

- **Author action and request:** Asked for a name for the approved folder, then
  populated `approved/` and requested "check approved folder now". Folder
  placement is the author's reference selection, not Codex's classification.
- **Inspection:** Opened all six approved PNGs with the image viewer:
  `Mercedes Van Drive to Downtown.png`,
  `Mercedes Van Cockpit_ Riverside Drive.png`,
  `Sunset Mercedes Van on Wet City Roads.png`, `Rainy Neon City Drive.png`,
  `Riverside Logistics at Dawn.png`, and
  `Sunlit Countryside Road Through the Valley.png`.
- **Observed visual direction:** Detailed shaped cockpit/exterior geometry,
  material grain and wear, readable instruments, wet-road reflection variation,
  warm/cool night lighting, layered industrial props, and readable daylight
  foliage, road surfaces, shadows, and distant terrain. The two cockpit views
  differ in layout and framing; exact production geometry still needs a decision.
- **Rejected collection:** Found seven PNGs in the author-populated `rejected/`
  folder. Their filenames are retained in its README; Codex did not visually
  inspect every rejected image or invent per-file reasons. An earlier supplied
  ChatGPT screenshot says "i feel its too realistic all images, remember its for
  a game." That wording records feedback on the generated references, not a
  reversal of the desire for a realistic game.
- **History preserved:** The first copied Mercedes reference is now in rejected;
  its SHA-256 still matches the previously recorded original/copy. Earlier entries
  correctly describe its prior under-review state; they are not rewritten.
- **Documentation:** Updated the reference inventory, rejected inventory, and
  DESIGN_DECISIONS.md (C07). Approved images are visual benchmarks, not runtime
  assets or automatic approval of Mercedes branding, real songs, dense traffic,
  city expansion, every pictured control, or changes to story/renderer.
- **Validation and scope:** Opened all approved images, counted six approved and
  seven rejected PNGs, and computed hashes. No images moved or renamed; no game
  code, settings, assets imported into Godot, or implementation approval inferred.

### 2026-10-18 — First van/depot art pass approved and implemented

- **Author approval:** After approving and asking Codex to inspect the six visual
  references, the author said "proceed with game changes". Codex explained the
  batch before acting: shaped van/cockpit meshes, surface materials, depot detail,
  and revised glass/rain, connected to existing controls on the current renderer.
- **Boundaries:** The existing driving loop remains the test route, not completed
  narrative M1. No new mission, character, traffic simulation, branded vehicle,
  song, weather cycle, or renderer change was approved by the reference images.
- **Blender problem:** The installed 5.2.2 background executable crashed before
  running the authoring script. A factory-startup, print-only reproduction also
  crashed. The trace enters Metal device support detection. Help lists only
  Metal; trying the OpenGL flag did not provide a usable backend. Root cause is
  unresolved. The failed authoring script and logs are preserved under ignored
  `builds/visual_pass_1/`; it did not create a `.blend`.
- **Author intervention:** Asked "whats happening with blender?", then "make sure
  to not break blender". Codex explained the failure and stopped further Blender
  launches. No installation, preferences, add-ons, existing `.blend` file, or GUI
  session was edited. No fix to Blender itself is claimed.
- **Solution used:** Original offline Python mesh authoring exports GLBs directly
  using already installed NumPy/Pillow. Editable source is the retained authoring
  code, not a claimed Blender project. No dependencies were installed. Godot does
  not need the authoring packages to run the resulting assets.
- **Vehicle changes:** Replaced primitive presentation with shaped cabin/body,
  rounded seats and wheel, vents, console buttons/legends, cup holders, window
  switches, panel seams, wheel arches, and detailed tire/rim meshes. Existing
  live instruments, GPS/reverse view, mirrors, windows, lights, wipers, and input
  remain connected. Wheel roll uses measured motion; headlight lenses follow the
  switch. The wheel uses an original BR mark rather than reference branding.
- **World/material changes:** Original aggregate, normal, and grain/roughness maps;
  varied wet asphalt and wall shaders; depot door surrounds, numbering, downpipes,
  pallets, boxes, bollards, and drains. One stationary depot reflection probe and
  three shadowed depot lamps add local lighting depth. Decorative props have no
  individual collision/interaction. Existing primary world/vehicle colliders and
  parking objective remain unchanged.
- **Glass:** Approximate screen-sampled droplet refraction/highlights connected to
  the wiper sweep mask. No physical water-film simulation is claimed.
- **Review and corrections:** A separate software geometry inspection revealed
  that the first camera framed the steering wheel too small. Camera distance,
  downward angle, and instrument height were adjusted. Winding/normal checks
  caught an authoring-normal sign issue before acceptance. Inspection images are
  explicitly labeled as geometry-only, not Godot screenshots or final art evidence.
- **Validation so far:** Seven GLBs import. Independent asset checks pass for
  structure, indices, finite data, normals/winding, geometry limits, and bounds.
  Initial post-art behavioral runs passed 64 regression and 29 integration checks.
  The final verification runs follow below. A graphical Godot launch aborted in
  this restricted session; actual shader rendering, appearance, and sustained
  hardware performance remain unverified. The earlier graphical-quality rejection
  is not erased by automated passes.
- **Documentation:** Added VISUALS.md with code explanations, provenance, rebuild
  commands, Blender limitation, and review boundaries; aligned README,
  ARCHITECTURE.md, DEVELOPMENT.md, PLAYTEST.md, VALIDATION.md, tools/README.md, and
  design decision C08. Python bytecode caches are ignored. Project configuration
  SHA-256 matches its pre-pass value. No branch, commit, or publication occurred.
- **Next gate:** Author plays the actual revised scene and reviews cockpit/depot
  quality before any wider art expansion. This pass is not presented as matching
  GTA or completing the full realism target.

### 2026-10-18 — First visual pass verification and playtest handoff

- **Final checks:** Regression 64/64, integration 29/29, independent asset checks
  133/133; each process exited 0. No script errors or failed assertions. Expected
  save-failure fixtures and restricted user-log/system/editor-settings errors are
  still recorded separately. Headless import successfully loads the seven GLBs
  but is not called a clean graphics pass.
- **Evidence:** `builds/visual_pass_1/regression_final.log`,
  `integration_final.log`, `art_validation_final.log`, `import_final.log`, and
  the authoring report. These generated logs are ignored, while the tools and
  Markdown reports remain source. Project settings match their pre-pass SHA-256;
  GDScript formatting and local documentation links pass.
- **Handoff:** Stop an existing game run, allow import, run the main scene, and
  inspect cockpit/van/depot while exercising the original controls. PLAYTEST.md
  contains focused review steps. Graphical shader behavior, visual quality, and
  sustained performance remain pending the author's actual playtest. Blender
  remains outside further work during this pass, per the author's instruction.

### 2026-10-18 — First art pass also fails the author's visual review

- **Author verdict after handoff:** "not realistic at all". The revised visual
  pass is rejected. The six approved reference images remain the intended target;
  no lowered quality target or acceptance is inferred.
- **Codex assessment:** The pass improved mesh structure and functional wiring
  but still relied on simplified generated forms. Structural checks and passing
  accessory tests did not establish the required visual fidelity. Codex should
  have established a convincing in-engine benchmark before extending the art
  treatment. This is a limitation of the delivered approach, not an author error.
- **Documentation:** Updated README, VISUALS.md, VALIDATION.md, and PLAYTEST.md
  to reflect the second visual rejection. Kept earlier test results and history
  as measured; they do not override the author's visual judgment.
- **Next direction proposed, not approved:** Select a substantially more detailed
  authored vehicle/interior and suitable surface materials, present actual asset
  previews and provenance before integration, then review a small in-engine
  cockpit/depot benchmark before wider changes. No model purchase, download,
  installation, renderer switch, Blender launch, or further game change occurred
  in this feedback response.

### 2026-10-18 — Author prioritizes matching references and allows tool evaluation

- **Author direction:** "sorry, continue. that level of graphics i want arent
  achievable?? you are working just with blocks, i dont like it." Then:
  "if we have to change the tool we can but i want to get it as close as the
  images." This preserves the quality target and authorizes evaluating tools;
  it does not lower the standard or select an engine migration.
- **Response:** Codex acknowledged that its simplified art approach was the
  immediate limitation. Continued read-only research into detailed vehicle/cockpit
  assets and rendering options rather than another procedural block pass.
- **Research:** Verified official Godot renderer differences and Unreal macOS
  requirements. Reviewed seller listings for an interior-equipped box truck and
  a detailed Sprinter; the latter uses simple materials and Corona-rendered
  previews, so it is not treated as an automatic game-ready solution. Verified
  Poly Haven's Asphalt 03 source/maps. No listing is selected or purchased.
- **Access and hardware uncertainty:** Two Sketchfab detail pages returned 403.
  A read-only CPU query was denied. An earlier Godot screenshot reports M4 while
  source documents target M1; asked the author which hardware to target. No
  machine baseline or performance result inferred. RAM is also unconfirmed.
- **Record:** ENGINE_REVIEW.md holds sourced findings, leads, limits, and the
  proposed benchmark-before-migration decision gate. No runtime code, engine,
  renderer, installed package, or Blender state changed in this evaluation.

### 2026-10-18 — Author confirms Godot; detailed asset selection comes first

- **Author decision:** Asked whether the target could be pursued in Godot, then
  confirmed "alright, lets do with gadot". Recorded as C09. The approved images
  remain the target; the rejected block-based art is not treated as accepted.
- **Next approach explained:** Retain Godot and existing behavior, select a
  properly modeled vehicle/cockpit, explain its accessory integration, and obtain
  approval before replacing it. Establish one convincing cockpit/depot benchmark
  before wider work. The engine decision does not select an asset or silently
  authorize a renderer migration.
- **Research progress:** Found further free interior-equipped van listings.
  The Crafter listing advertises about 149,300 triangles and CC Attribution, but
  its detail page remains inaccessible (403); its actual quality and contents
  are unverified. A Transit listing explicitly describes another game's export,
  so it is not proposed as a usable replacement. Raw scans and low-detail assets
  have not been substituted for the selected quality target. A linked Fab van
  listing returned 404. The direct metadata request failed with a network error;
  no download occurred.
- **Open inputs:** Asked whether to include paid asset candidates for review or
  use free assets only. Hardware target/RAM confirmation is also pending. No
  purchase, account sign-in, package installation, Blender launch, or renderer
  change occurred. Asset previews need review before the next code batch.
- **Documentation:** Updated DESIGN_DECISIONS.md and ENGINE_REVIEW.md. Unreal
  comparison remains as research history, not an active migration proposal.

### 2026-10-19 — Claude handoff requested and prepared

- **Author request:** Explain everything done and still unfinished as a prompt
  to give to Claude.
- **Read-only verification:** Checked the current source/document inventory,
  reference folders, main scene/controller, and saved validation results. The
  project still has no initialized Git repository. The latest recorded runs are
  October 18: 64 regression, 29 integration, and 133 asset checks passed. No tests
  were rerun or newly claimed for this documentation-only handoff.
- **Deliverable:** `docs/CLAUDE_HANDOFF.md` is a paste-ready takeover prompt with
  approval rules, source/canon boundaries, implemented behavior and fixes,
  rejected visual work, approved references, validation commands and limits,
  Blender protection, remaining phases, and unresolved asset-budget/hardware/
  narrative inputs. Prior Codex work remains attributed to Codex.
- **Scope:** Handoff documentation only. No runtime code, assets, engine/renderer,
  installed tool, Blender state, account, branch, commit, or publication changed.

### 2026-10-19 — Claude takeover review and proposed visual benchmark

- **Author request:** Claude takes over from Codex. Review the files and approved
  images without changing gameplay, assess the visual gap, propose a concrete
  next batch, then wait for approval.
- **Read:** AGENTS.md, CLAUDE_HANDOFF.md, GAME_STORY.md, GAME_DESIGN.md,
  DESIGN_DECISIONS.md, ARCHITECTURE.md, DEVELOPMENT.md, README.md, VISUALS.md,
  ENGINE_REVIEW.md, AUDIO.md, PLAYTEST.md, VALIDATION.md and recent entries here.
  Opened all six approved PNGs. Rejected images were not individually reviewed.
- **Code inspected:** `van_presentation.gd` builds accessories at hard-coded
  coordinates around the generated GLBs; `industrial_loop.gd` uses a procedural
  sky, flat-colour ambient light, no tonemapping or glow, on Compatibility.
  Integration tests read `mirrors`, `mirror_cameras` and `reverse_screen` from
  the presentation node, so a replacement must keep those properties.
- **Hardware (read-only query):** this machine reports Apple M4, model
  Mac16,12 (MacBook Air), 16 GB RAM, macOS 26.6.2, Godot 4.7.2. Documents still
  say M1; which target to support remains the author's decision.
- **Asset research (read-only, Sketchfab public API and Poly Haven API):** no
  free van was found that has both trustworthy provenance and reference-level
  cockpit detail. "2016 Ford Transit with Interior" is tagged `notmymodel` and
  described as exported from another game. The geyges Transit/Crafter/Savana
  uploads ("Free Standard") come from a catalogue that includes vehicles named
  after another commercial game, so their licence claims are not relied on.
  The 2017 Crafter lead (149,322 faces) has no textures and one material.
  Raw scans (1.1–2.5M faces) are unsuitable as cockpits. Several paid listings
  (Fab, CGTrader, RenderHub) block automated reading; their contents are
  unverified. One RenderHub interior model is editorial-use only, so unsuitable.
  Poly Haven CC0 HDRIs, asphalt/concrete/corrugated-metal textures and a few
  props (street lamp, chain-link fence, cardboard box, trash can) were confirmed.
- **Nothing downloaded, installed, purchased or changed** in game code, project
  settings, Blender or accounts. Preview thumbnails were saved only to the
  session scratchpad. Blender MCP tools are available in this session but were
  not used.
- **Proposed, not approved:** a separate cockpit/depot benchmark scene with an
  authored vehicle, CC0 photographic materials and HDRI lighting, compared on
  Compatibility and Forward+ through the command-line renderer override,
  without editing `project.godot`. Awaiting the author's answers on asset
  budget, branding, hardware target and benchmark lighting.

### 2026-10-19 — Author direction and first depot-yard benchmark (Claude)

- **Author direction:** "it should run on this machine m4. also create realistic
  graphics and props for our game, maybe use blender if you want". Recorded:
  target hardware is this MacBook Air M4 (16 GB). Claude treated the message as
  approval of the proposed separate benchmark and proceeded on stated defaults:
  free CC0 assets, no real brand logos, wet dusk depot lighting. The author later
  asked "whats happening", received a status summary, and replied "yes do it".
- **Blender:** opened the GUI normally; it launched (the earlier crash was in
  background mode). The installed Blender MCP add-on did not answer and its
  port was not listening, so it appears disabled. No preferences, add-ons or
  files were changed; enabling it is left to the author.
- **Assets:** 23 Poly Haven CC0 assets (15 models, 7 textures, 1 HDRI; 126 MB)
  downloaded with `tools/assets/fetch_polyhaven.py`, MD5-verified, manifest in
  `game/features/environments/depot_yard/polyhaven/POLYHAVEN.md`. A grey variant
  of the red cladding texture is derived by `tools/assets/derive_textures.py`.
- **Problem and fix:** script-assigned textures imported lossless without
  mipmaps (shimmer, high memory). `tools/assets/configure_imports.py` applies
  Godot's standard 3D import settings (VRAM compressed, mipmaps, normal-map mode).
- **New, separate from the main game:** `features/environments/depot_yard/`
  (`depot_yard.gd`, `depot_yard.tscn`, `wet_ground.gdshader`),
  `features/ui/performance_overlay/`, `app/visual_benchmark.tscn/.gd`, and
  `tools/tests/capture_scene.gd`. The main scene, controls, tests and
  `project.godot` are unchanged. Forward+ is selected per launch on the command
  line only.
- **Graphical capture works in this session** (unlike Codex's). First render
  pass showed: over-bright flat lighting, paint read as metal (gold posts),
  tiled rubber looked like brick, too-white cladding. Fixed with darker sky and
  ambient, stronger lamps, a non-metallic paint material, plain rubber and a
  darker cladding tint. Typed loop variables fixed a parse error; owner
  warnings from extracted model parts fixed.
- **Measured (Forward+, 1280×800, capture runs):** 47–60 FPS, 341–765 draw calls,
  about 1.1 GB video memory reported. Not a sustained profile.
- **Validation:** regression 64/64, integration 29/29, art check 0 failures,
  all exit 0. Screenshots are under ignored `builds/visual_benchmark/`.
- **Limitations, stated honestly:** the van is still Codex's rejected model, and
  its rear blows out white under this lighting. Lamp light pools and wet
  reflections are weaker than the references. Compatibility comparison and the
  author's in-game verdict are pending. This is not claimed to match the
  references.

### 2026-10-19 — Author verdict on depot-yard benchmark v2

- **Author verdict:** "graphics are better now but still not realistic with
  minute details like real cars etc." Recorded as improved but not accepted.
- **Assessment:** the remaining gap is vehicle-level detail (panel gaps, badges,
  lamps with inner optics, tyre sidewall lettering, cockpit stitching and
  switchgear). That cannot be scripted from primitives. It needs an authored
  production model.
- **Research:** a Sketchfab staff-picked search for downloadable vans found no
  realistic, honestly licensed candidate. Earlier free leads were ripped game
  assets or untextured. The Blender MCP add-on still does not answer.
- **Decision requested:** paid-model approval and budget, or enabling the
  Blender add-on. No purchase or Blender change has occurred.
- **Author decision (same day):** "Free only, via Blender"; budget "Free only".
  No paid assets will be shortlisted or purchased. The vehicle will come from
  free libraries through the Blender MCP add-on once the author enables it.
  Expectation recorded: free models may not reach the reference detail.

### 2026-10-19 — Blender MCP connected; free van shortlist

- **Author:** "also dont forget to keep updating all the docs especially
  frequency.md. also done blender mcp is ready". "frequency.md" is taken to mean
  this file (no frequency.md exists); confirmation requested.
- **Blender MCP:** connected. Blender 5.2.2 LTS, add-on 1.8, protocol 13,
  telemetry off. Its Sketchfab, Poly Haven and Poly Pizza libraries are all
  off; Sketchfab needs the author's own API token. Nothing was changed in Blender.
- **Free van search (Sketchfab public API, vehicle category, CC-BY/CC0):**
  230 unique results reviewed. Shortlist:
  1. Iveco Daily Van 2014 by Max, uid 30003fba5b074d6eb7bc74fd5e1e7d19:
     CC-BY, 89,823 faces, 60 textures (4K PBR), 12 materials, opening doors and
     visible seats. Recommended.
  2. Mercedes Benz Sprinter 2006 by Max, uid f69de1315bb049c8946d57f6006acd73:
     CC-BY, 37,565 faces, 4K PBR. Backup.
  Rejected: Chevrolet Express by Ddiaz Design (tagged `need-for-speed`,
  possible extraction from that game); European Delivery Van (1970s, wrong era).
- **Licence note:** both of Max's models are CC-BY on Sketchfab, but the
  description says "not free of rights. You must inform me of your usage."
  Recommended that the author notify Max (Discord max7215) and that credits
  attribute him. Cockpit detail is unverified until the model is downloaded.
- **Pending author action:** choose a van, and either enable Sketchfab in the
  add-on with an API token or download the glTF to
  `source_assets/vehicles/incoming/`.
- **Author:** "show me how it looks first then we can decide to use it and
  message him or not". Claude opened both shortlisted models' interactive
  Sketchfab viewers in the author's browser for inspection (cockpit, wireframe,
  exterior). Nothing downloaded; the use and contact decision is pending the
  author's review.

### 2026-10-28 — Game changed for the final; Assignment 5 continues here

- **Author:** "we changed our game for final and we are using this only from now
  on"; "we will use the new folder to continue our assignment". Recorded as:
  *Blackridge: No Way Back* is now the author's course game, and this folder is
  the only working project from Assignment 5 onward.
- **Earlier assignments:** the author confirmed that Assignments 2–4 were built
  on a different game. The course asks for a change of game to be declared, so
  the Assignment 5 submission note will answer "Changed games since Assignment
  2" with yes and point to a matching entry in `FRICTIONAL.md`, the course's
  honest log. That file is separate from this development record.
- **Name:** the author calls this file "frequency.md"; as on 2026-10-19 it is
  taken to mean `fractional.md`, since no `frequency.md` exists.
- **Assignment 5 received:** "Shaders, Materials, and the Godot Shading
  Language", submitted as git tag `a5`. Claude explained the brief against the
  current project and recorded its ownership rule. The author hand-writes both
  shaders, the hint-experiment shader, the colour line and hand-computed
  predictions in `CHANGE-BRIEF.md`, and `LANGUAGE-NOTES.md`. Agents never edit
  `game/shaders/`. Claude drafts `CLAUDE.md` and writes the test wrapper,
  driver, tests and material audit.
- **Version control:** the author approved Git setup and a repo-only identity
  ("Yes, set my identity"). Claude initialized Git and committed the project as
  found (`e81ec92`). This entry and the test wrapper follow as separate commits.
  Nothing has been pushed, and the GitHub `walker-` repository does not exist yet.
- **Baseline:** both Godot suites ran through `scripts/run-test.sh` at 60 fps.
  `first_drive_regression.gd` passed 64/64 and `first_drive_integration.gd`
  passed 29/29, both exiting 0. Each prints an engine "resources still in use at
  exit" error at shutdown. This was there before Assignment 5 and is not a SHADER
  or SCRIPT ERROR. The Python art check `check_first_drive_art.py` passed 133/133.

### 2026-10-30 — Assignment 5 submitted; final-project realism pass begins

- **Assignment 5 closed.** Tag `a5` points at `a2dd684` on the public GitHub
  repository `blackridge-no-way-back`. The author submitted on Canvas with the
  source zip, `SUBMISSION.md`, `FILM-SHA256.txt` and a short note. Work from
  2026-10-28 to today is in `TEST-REPORT.md`, `FRICTIONAL.md`, `SUBMISSION.md`
  and the commit history up to that tag.
- **Author request (realism):** "which tools do you think we should use via mcp
  to get the most realistic game"; "the game is not as realstic as i want it to
  be". The Blender MCP server is configured, but when checked, Blender was not
  running with its add-on started. No Godot MCP is installed. Asked "can we use
  unreal engine to make our game more reaslitic"; Claude advised against
  switching engines. Author: "this is my final project", then "its upto us.
  whatever makes our game more realistic", then "yes run the experiment".
- **Experiment 1, renderer.** Scratch copy, runtime-only settings, the same parked
  driver's view captured at 3840×2400 in three versions: Compatibility, Forward+,
  and Forward+ with the AgX tonemap, SSR, SSAO, glow and volumetric fog (0.015).
  - Forward+ alone barely changed the picture: mean luma 37.9 → 39.2, and 1.3% of
    the gauge pixels changed.
  - The exception was the driver-window fog overlay. It rendered much stronger:
    44% of that area changed by more than 6 levels. Any renderer switch needs an
    eye check of the fog materials.
  - The full stack made the frame 21% darker (39.2 → 30.9), with no visible
    reflections or lamp glow.
  - Conclusion: the gap is content and lighting, not post-processing.
- **Author feedback:** "the road doesnt look like road.. it should look realsictic
  and ghosted. and headlights dont make any difference when switched on and off.
  the user should see the road little better when turned on. and less when turned
  off. i want all small details like this. and i am not happy with car interior".
  "Ghosted" is taken to mean eerie and empty, still to be confirmed with the author.
- **Experiment 2, headlights (scratch copy):**
  - Switching the headlights on or off changed 0.0% of the outside view, even at
    12× energy in Forward+.
  - **Cause:** `_mark_layer(_body, 2)` (`van_presentation.gd:62,259-263`) also
    sets the two headlight SpotLight3Ds' `layers` to 2. The driving camera's
    `cull_mask` is 5 (`:132`), so the camera culls them. The capture log
    confirms `layers_before: [2, 2]`.
  - Moving them to layer 1 alone still changed nothing measurable with today's
    lighting: the moon (0.55) and ambient light (0.30) light the road about as
    much as the headlights do.
  - Next try: a darker night, stronger headlights and thin volumetric fog in
    Forward+. The beam lit the mist: the view got 52% brighter, but the road
    disappeared. **Author: "terrible, cant see the road at all when light is
    on. road should be more visible".**
  - Mist removed for a low-beam test:
    - settings: moon 0.25, ambient 0.12, energy 560, decay 1.0, aimed 2° down,
      35° half-angle, and a pattern texture with a sharp top edge;
    - results: road band 26.3 → 78.9 (3.0×); road just past the dashboard
      19.6 → 105.0; band above the horizon 63.0 → 64.2.
    - Shown to the author; verdict pending.
  - The dashboard hood sits almost at eye level and hides roughly the first 15 m
    of road.
- **Author realism target:** a screenshot of another game's rainy cockpit: "i
  want it to be as realistic as this. this is a game." Claude first filed it as
  an approved reference. The author corrected this: "no i gave it for you to know
  how realistic i want my game to be". The file was removed and is not stored in
  the project. It only sets the level of realism.
- **Author decisions (multiple-choice):**
  - Switch to Forward+.
  - Use free CC0/CC-BY models only, credited in `SOURCES.md` with logos removed,
    each shown before use. This repeats the 2026-10-19 "Free only" decision.
  - Keep the rainy night.
  - Deadline: more than a month away.
- **Author request:** "add like realistic shaders if we need to, add animations do
  how a top mnc do it, follow best practices and techniques. and make sure to
  write in frequency.md whats happening and all our decisions and also make sure
  to save the pictures in assets whatever we are rejecting and approving in
  accurate folders." "frequency.md" means this file, as before.
- **Done:**
  - **`FINAL-BRIEF.md` drafted (status DRAFT).** It covers:
    - goals, decisions (linked to the 2026-10-19 benchmark and van shortlist) and
      test findings;
    - Phase 1: Forward+, the headlight fix, low beams, a darker night and
      reflections, with machine and human checks;
    - how we build: pictures decide, everything is logged, PBR materials before
      custom shaders, and Claude-written shaders stay out of `game/shaders/`;
    - studio animation practices, and later phases 2–8.

    A reviewer subagent checks it before the author reads it.
  - **New `source_assets/artwork/captures/`** with `approved/`, `rejected/` and
    `pending/` folders, and a README listing who decided and in what words.
    Rejected: today's headlights on/off, the post-processing stack, and the
    headlights lighting the mist. Pending: the low-beam test.
  - The references README now points to the new captures folder.
- **Not changed:** nothing in `game/`, `project.godot`, the tests or `CLAUDE.md`.
  Nothing committed or pushed. All experiments ran on a scratch copy with
  runtime-only settings.
- **Open:**
  - the builder check of the brief;
  - the author's approval of the brief, then Phase 1;
  - the author's verdict on the low-beam stills;
  - the meaning of "ghosted".

### 2026-10-30 — Brief review and the author's answers

- **Builder check.** A reviewer subagent read `FINAL-BRIEF.md` against the code. It
  confirmed the headlight diagnosis and raised eight questions.
  - **Correction it caught:** Godot applies a light's pattern image only when that
    light casts shadows, and only the left headlight did. In the low-beam test, the
    right beam therefore had no sharp top edge; that is why the road sign lit up.
  - **Claude settled these in the brief, each marked "Claude's call":**
    - shadows on both headlights;
    - the test values as tunable starting points;
    - a Linear tonemap unless lit surfaces clip;
    - the capture regions and a no-white-out check, with the rig moved into
      `tools/captures/`;
    - a 60 FPS target (never below 45 after a 10-minute drive at 1280×800);
    - `test_materials.gd` following any newly approved fog values;
    - a whole-van swap in Phase 3;
    - "ghosted" read as eerie and empty.
- **Author answers (multiple-choice):**
  - **Final scope:** "I'll paste the assignment". The brief will follow it.
  - **Art target:** "Near-photoreal, consistent". This overrides the design doc's
    stylized low-to-mid-poly kit, recorded as C11 in `docs/DESIGN_DECISIONS.md`.
    The Forward+ switch is recorded as C12.
  - **Low beam:** "Approve the direction". The two low-beam stills moved from
    `captures/pending/` to `captures/approved/`; the exact values are still to be
    tuned in Phase 1.
- **Next:** read the final project assignment, revise the brief to match, then
  hand the brief to the author for approval before any code.

### 2026-10-30 — Assignment 10 (final project) received; roadmap drafted

- **Author:** pasted the Assignment 10 brief, "Final Project: From Brief to Export"
  (250 points), and added: "this will keep changing because my submission in
  december 20th. but i want a real game as my final portfolio piece".
- **What the assignment adds:**
  - The Assignment 9 game-AI technique in real play, with an audit of a gap its
    tests miss.
  - Persistence under save rules written first.
  - A keyboard-only start or pause menu.
  - A clean clone of tag `a10` that reproduces.
  - A macOS export with an inspected pack and an honest source-ready or
    export-ready claim.
  - A pitch ledger against Assignment 8's "will exist" list.
  - Two Brutalist films (godot-walkthrough and godot-gdd) naming the five
    Supervisory Capacities.
  - `HANDOFF.md` after every agent run.
- **Its dates:**
  - Nov 3: export target and renderer decided, export attempted.
  - Nov 13: save rules written.
  - Nov 23: persistence and menu working.
  - Dec 3: a playable loop and a clean-clone rehearsal.
  - Dec 13–20: integration, playtesting and films.

  The brief says a renderer change is cheap before effects and animation are
  final; Phase 1 does exactly that.
- **Author decisions (multiple-choice):**
  - **Export target:** "macOS, Forward+" (C13).
  - **Export templates:** "Yes, download". Downloaded to the session scratchpad,
    1,281,349,702 bytes, and the SHA-512 matches Godot's official
    `SHA512-SUMS.txt`. Not installed yet; Phase 1 installs them.
  - **Scope by December 20:** "All three missions" (C14). Claude had recommended
    a polished Mission 1 and noted that realism work would then be cut back.
- **The brief became a roadmap.** The course reserves `CHANGE-BRIEF.md` for each
  change's brief, committed before code, so `FINAL-BRIEF.md` was replaced by
  `ROADMAP.md`. It holds:
  - the schedule against the Assignment 10 dates, plus a cut list (Claude's
    call);
  - a requirement-by-requirement map of Assignment 10;
  - Phase 1 in detail, now including the macOS export preset, pack listing and
    release export;
  - the three missions as `GAME_DESIGN.md` §9 defines them;
  - the realism phases in priority order, the 2026-10-30 evidence, and open
    items.
- **Open items now:**
  - how Assignments 2–4's layers from the earlier game are carried or explained;
  - which Assignment 9 technique fits the guards;
  - how one `CHANGE-BRIEF.md` serves both Assignments 6–9 and Assignment 10's
    overlapping preparation;
  - the van model choice;
  - "ghosted".
- **Not changed:** nothing in `game/`, `project.godot`, the tests or `CLAUDE.md`;
  nothing committed.

### 2026-10-30 — Goal: a commercial game; structure and documentation audit

- **Author:** "make sure to follow best practices, make sure to update the
  documentation. make sure the file names are appropriate and accurate and
  meaninful and folder strucutre is clean and best practices. the goal is to put
  the game on some game store to sell it. make sure we are doing a realistic and
  professional game". Recorded as C15 in `docs/DESIGN_DECISIONS.md`.
- **What selling changes:**
  - every asset and tool must allow commercial use;
  - real vehicle brands and designs must be avoided;
  - the van creator's extra term ("not free of rights. You must inform me of
    your usage") needs written permission;
  - Windows matters for most buyers;
  - a Mac build sold outside the App Store needs Apple signing and notarization
    ($99 a year);
  - the game needs its own licence decision, a settings menu, controller
    support, a credits screen with every licence, and an age rating.

  None of these were decided yet; they are listed in `ROADMAP.md` §10 and §12.
- **Audit (read-only):**
  - `fractional.md` and `FRICTIONAL.md` are near-identical names for different
    files. 11 files link to `fractional.md`.
  - Two different `first_drive.gd` files exist (app and mission).
  - Assignment 5's deliverables lie loose at the root: `LANGUAGE-NOTES.md`,
    `evidence/` (42 files), `prompts/`, `sessions/`, `logs/`, and A5's
    `TEST-REPORT.md` and `SUBMISSION.md`.
  - A document sits inside the Godot project (`game/MATERIALS.md`).
  - `docs/CLAUDE_HANDOFF.md` clashes with the course's `HANDOFF.md`.
  - There are empty folders and `.gitkeep` files in folders with content.
  - "MacBook Air M1" is stale in README, `AGENTS.md`, `docs/DEVELOPMENT.md` and
    `docs/ARCHITECTURE.md` (C10 made the M4 the target).
  - `AGENTS.md` still says "The current stage is repository setup only".
- **Done:**
  - **README:** a short "Final-project plan" note under "Current status" points to
    `ROADMAP.md` and C11–C15, and says nothing in it is built yet.
  - **`ROADMAP.md`:** rewritten with the goal; Phase 0 (renames and moves using
    `git mv`, docs brought up to date, naming rules, a link check and unchanged
    tests as proof); and §10 "Selling the game". Sections renumbered.
- **Proposed in Phase 0, not done:**
  - this file becomes `docs/DEVELOPMENT_LOG.md`;
  - Assignment 5's files move to `course/assignment-05/`, with tag `a5` keeping
    the originals;
  - `youtube/`, `game/shaders/` and the course-required root names are kept on
    purpose.

  Waiting for the author's approval of the roadmap.

### 2026-10-30 — Priorities: a realistic game, course first; selling and cleanup deferred

- **Author:** "we can skip selling also if its too much work. but i want
  realistic game. dont do anything that will go against our assignments for
  now. focus on thedevelopement of game, we will clean it up when i sat".
- **Recorded:**
  - **C15 amended:** a realistic game first, selling optional and deferred,
    the course first, and the Phase 0 cleanup waits for the author.
  - **`ROADMAP.md`:** Phase 0 and §10 marked deferred. Product-only items (a
    changelog, store work) were removed from Phase 1.
  - **README:** the status note now says selling is optional.
- **Next:** Phase 1 is the course's own November 3 target (export target and
  renderer decided, export attempted). Its `CHANGE-BRIEF.md` is drafted for the
  author's approval and is committed before any code. Assignment 5's brief stays
  at tag `a5`. Assignment 10 requires redoing every earlier look check after a
  renderer switch, so Assignment 5's checks are part of Phase 1.

### 2026-10-30 — Branch `develop`; Phase 1 brief committed before code

- **Author decisions:**
  - Approval before every step: "at each step take my approval and then only do it".
  - Structure: a professional portfolio piece after the course, with no assignment
    folders. Submissions stay as git tags.
  - The Assignment 5 deadline was extended, but the author declined to resubmit: "its
    fine. focus on creating making realistic game".
  - "dont remove everything what we have in files till now. the ta will check our
    assignment", then "make changes and push to a new branch, for now we will make a pr
    later after assignment 5 is graded".
- **Done, on the new `develop` branch:**
  - **`CHANGE-BRIEF.md`:** now the approved Phase 1 brief. Assignment 5's brief stays on
    `main` and at tag `a5`.
  - **`CLAUDE.md`:**
    - a "Working rule" section: approval before each step, `develop` versus `main`, and
      `HANDOFF.md`;
    - Phase 1's "Out of scope" and "Unconfirmed" lists.

    It is now 142 lines, over Assignment 5's 120-line limit. `main` keeps the 117-line
    Assignment 5 version; trimming would be a separate approved step.
  - **`ROADMAP.md`:** a dated revision for the structure, branches and Assignment 5.
  - **GitHub:** `develop` pushed. `main` and tag `a5` are untouched.
- **Next (needs approval):** Run 1, the renderer switch.
