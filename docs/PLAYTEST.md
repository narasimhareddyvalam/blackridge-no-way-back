# Playable phase gates

## Working agreement — October 18, 2026

The author wants to play and judge the game in phases. Each phase needs a clear
purpose, a runnable entry point, checks for the affected behavior, and an author
playtest before expansion. Codex explains the next implementation batch and gets
approval first. Feedback on the current phase determines its remaining fixes.

Update [fractional.md](../fractional.md), the current validation report, and any
affected guides as work happens. Keep automated results, Codex's visual review,
and the author's verdict separate. Record only reviews that actually occurred.

## Phase 1 — Van controls and driving foundation

Purpose: judge whether cockpit driving and the requested vehicle interactions
are usable and worth developing further. The test includes a bounded industrial
loop, depot objective, recovery, and entry/exit. Its procedural geometry, temporary
driver, shaders, and synthesized audio are an early presentation foundation.
Final visual realism and final audio have not been accepted.

Author review on October 18: both the original prototype and the implemented
first visual pass fail the intended realism target. After the latter handoff,
the author said "not realistic at all". Functional acceptance remains pending.
Further visual work needs a newly explained and approved batch; the passing
automated checks do not accept the current art.

Entry point: `game/app/first_drive.tscn`, configured as the main scene in
`game/project.godot`. Engine: Godot 4.7.2, existing Compatibility renderer.

### Prepare a repeatable session

Keep the same engine, renderer, window size, controls, and code throughout a
session. Record the date, phase/work batch, Mac model, window size, and whether
you ran from the editor. The configured viewport is 1280 × 800; note window or
display scaling differences if known. There is currently no Git commit hash;
use the work-batch description from `fractional.md` rather than inventing one.

For the first functional pass, use the default-sized window. Later, check another
window size separately for clipped menus and unreadable instruments. Do not change
several settings while trying to reproduce a problem. Record existing checkpoint
state before resetting anything. **New drive** starts the route again and writes
that new prototype checkpoint; use it deliberately to establish a baseline.

The earlier headless runs passed 64 regression and 29 integration assertions.
Those are recorded observations of the covered behavior, not a percentage of
test coverage or an interactive pass. The repeatable commands and fixture effects
are in [tools/README.md](../tools/README.md). Codex reruns affected checks when code
changes; documentation edits alone do not require another gameplay run.

### Review the first visual pass

After stopping any previous run, let Godot import the new GLBs and run the main
scene again. New identifying details are the rounded wheel/seats, dashboard vents,
center console, shaped pale van body, and depot bay surrounds/pallets/bollards.
The previous primitive driver and much of the wider district remain provisional.

1. Check the forward cockpit view, then look down and sideways. Confirm gauges,
   GPS, road, mirrors, and controls are visible without clipping or model overlap.
2. Operate L, V, J/K, Z/C, X, Q, and Esc. Check lens brightness, glass/wipers,
   windows, blinkers, reverse view, and pause against the existing control list.
3. Drive the existing loop and approach the depot. Judge road detail, wet/dry
   variation, reflections, shadows, door surrounds, and readable signage.
4. Stop and exit with E to inspect van panels, wheel arches, tires, and seats.
   Small new decorative props currently have no separate collision shapes.
5. Open the Debugger and record shader/runtime errors. Capture the cockpit and
   depot at the same window size as the prior view; use the approved images as
   comparison references. Judge the real game rather than geometry-only previews.

Record performance under the sustained-test procedure below. The art/shader pass
has not been graphically validated in Codex's tool session. See
[VISUALS.md](VISUALS.md) for code explanations, sources, and approximations.

### Start the game

1. Open Godot. Import `game/project.godot` if it is not in the project list.
2. Open that project and let import finish.
3. Click **Run Project** (the play button), or press **F5**. On a Mac keyboard
   configured for media/function controls, use the toolbar button or Fn+F5.
4. Select **Begin / continue drive**. The mouse now controls your view.
5. Press **Esc** whenever you need the pointer, controls, volume settings, or Quit.

If the editor looks empty before running, the current prototype constructs its
environment and cockpit in runtime `_ready()` code. Those meshes are not stored
as visible authored children in the editor scene. Open `app/first_drive.tscn` if
needed, then use **Run Project** to see the generated content. This is an editor
preview limitation of the current implementation, not a passed rendered review.

If the game window itself is blank after Run Project, stop the smoke test and
report that as a launch/view blocker. Note whether the menu appears and preserve
any error from Godot's Debugger/Errors panel. A screenshot can be saved as a PNG
and its local path supplied to Codex for inspection; clipboard image attachment
is not required for that workflow. The exact view/cause must be established before
changing rendering or scene code.

The user interface identifies this as a driving prototype. The objective is to
follow the freight loop, then stop in the marked depot bay. Earlier gates must
be reached in order; the dashboard map and road signs provide route information.

### Start here: a three-minute smoke test

A smoke test asks whether the current build is usable enough for deeper checks.
Try these in order:

1. Launch and begin the drive. Confirm that the road, objective, and controls are
   visible and the view is usable.
2. Hold W briefly, brake with S, then make gentle left/right turns using A/D.
   Check that the van moves, turns, stops, and the speedometer responds.
3. Press Esc, release all controls, and confirm the van remains still while the
   menu is open. Resume and confirm input returns.
4. Stop fully, press E to exit, return near the van, and press E to enter.
5. Press R. Confirm the van returns stopped to a safe checkpoint and can drive.

If launch, the view, essential controls, or recovery fails, stop this pass and
report that issue first. Mark dependent tests **Blocked**. Preserve the exact
error before relaunching; do not try to diagnose several faults at once.

### Functional review — one feature at a time

After the smoke test passes, use the table below. Establish the expected state,
perform the action, and compare the actual result. Allow animations to finish;
window travel takes about two seconds and camera refresh is intentionally bounded.
After a failure, repeat the same short sequence once if practical to establish
whether it is reproducible. Return to a known state before the next feature.

Use **Pass**, **Fail**, **Blocked**, or **Not run** for each row, with a short note.
An untested row stays Not run; a known limitation does not automatically become a
pass. Separate a broken function from your preference about its feel or appearance.

All author checks below are **pending**. Expected behavior is a test criterion,
not a claim that rendered behavior has already been seen.

| Try | Expected result | Author verdict |
| --- | --- | --- |
| Start, pause with Esc, resume | Menu is readable; input and cursor change cleanly; van stays still while paused. | Pending |
| Hold W; steer with A/D; brake with S | Van accelerates, turns predictably, and stops. The speedometer follows movement. | Pending |
| Stop, press Q, then hold W | Reverse engages and the rear camera appears. S brakes; Q changes back to forward when stopped. | Pending |
| Look at the mirrors while moving; press F to center your view | Interior and side views show the actual surroundings, update, and have useful framing. | Pending |
| Press Z or C, then X | Left/right indicators and hazards flash with dashboard feedback and relay sounds. Turn indicators cancel after a completed turn. | Pending |
| Press V through high, off, then low | Blades change speed, park when off, and rain visibility responds. Judge whether the effect is convincing. | Pending |
| Press J and K | Driver/passenger windows lower and raise over about two seconds. Outside rain/wind becomes more exposed when open. | Pending |
| Press L; hold H | Headlights change road illumination; horn sounds only while held. | Pending |
| Gently approach a barrier and stop against it | Van stays on the near side; speedometer reads stopped when motion stops. Recovery remains usable. | Pending |
| Stop and press E; walk with WASD; return and press E | Third-person exit and nearby reentry work. Exit is rejected while moving or when both sides are obstructed. | Pending |
| Drive the loop and park at the depot | Objectives advance in order and require a stopped van in the final bay. | Pending |
| Press R or use Recover van in the menu | Van returns stopped to the last safe route checkpoint. | Pending |
| Reach a checkpoint, quit, reopen, and continue | A successful save restores the checkpoint. If saving fails, the message reports that clearly. | Pending |
| Adjust audio, close and reopen the game | Preferences persist and the audible mix is comfortable. | Pending |

The tachometer currently estimates RPM from controller state. There is no full
engine/transmission simulation. Character animation, final cockpit models,
weather/material polish, and final audio remain subject to later approved work.

### Check failure paths and persistence

Once normal driving works, try changing gear and exiting while moving; both
should be rejected. Approach an obstruction gently and confirm it blocks travel.
Try recovery after a collision. Check that repeated pause/resume and entry/exit
do not duplicate input, leave the wrong camera active, or lose control.

The automated suite creates blocked-door and save-write/replacement fixtures.
There is no need to alter operating-system permissions or edit player files to
repeat those faults manually. Save failures must never produce a success message.

For a normal save/relaunch check:

1. Reach a new route checkpoint and note the objective and saved confirmation.
2. Quit using the game's menu. Stop the editor run if it is still open.
3. Run the project again and choose **Begin / continue drive**. Use Continue here,
   rather than New drive, so the saved checkpoint is exercised.
4. Compare the restored stage and safe location with your notes. Recovery is to
   an authored checkpoint pose, not the exact place you quit.
5. Change one audio slider, note its value, quit/relaunch, and check that value.
   If you mute a bus for comparison, restore your preferred level afterward.

The default data paths have not passed a relaunch check in Codex's restricted
session. A failure here is a real finding to record, even though isolated-file
save tests pass.

### Review visuals, sound, and feel separately

Judge the current experience from the normal seated view: can you read the
instruments, see enough road, use mirrors, understand the route, and steer without
fighting the camera? Observe mirrors while moving past a distinctive object so
that a frozen or incorrectly framed view is obvious. Check menus at a second
window size in a separate pass.

For sound, temporarily lower Music to hear engine, tire, rain, wiper, horn, and
indicator feedback. Compare the same speed and location with a window closed and
open. Listen for abrupt cuts, repetitive seams, missing sounds, and uncomfortable
levels. Then judge the full mix. These are provisional sounds; your preference
determines whether to keep them or replace them later in ElevenLabs.

Final asset realism is still pending, but road visibility, readable UI, usable
controls, and comfortable feedback matter in this phase. Record quality concerns
without treating prototype status as proof that the experience is acceptable.

### Check sustained performance on the M1

Do this after the smoke and functional checks. First drive without profiling
enabled and note where stutters occur. For an initial sustained check, drive the
same loop for about ten minutes after a short warm-up. Keep the window size,
power mode, renderer, and background workload consistent; record those conditions.
This establishes an observation window, not a guaranteed performance budget.

While running from Godot, open the bottom **Debugger** panel:

- **Errors:** preserve new errors/warnings and their context.
- **Monitors:** observe FPS, memory, and node/object counts over repeated loops.
  Record noticeable spikes or continued growth rather than a single idle value.
- **Profiler:** start a separate short capture around the action that stutters;
  inspect frame, physics, and script time. Profiling has overhead, so distinguish
  these captures from the unprofiled play session.

These tools are described in Godot's
[Debugger guide](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/debugger_panel.html)
and [Profiler guide](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/the_profiler.html).
The Visual Profiler is unavailable with Compatibility on macOS. GPU timing stays
**Unavailable** in this configuration; do not substitute a guessed GPU figure or
change the renderer just to obtain one. Record the actual available metrics and
the scene/action that caused a spike. No FPS target is accepted from this prototype.

### What to report

Report what you tried, what happened, and what you expected. Start with anything
that prevents playing: failure to launch, a blocked view, missing controls,
unreadable instruments, unusable steering, a soft lock, or failed recovery. Then
give your verdict on driving feel, camera comfort, appearance, and sound. Your
preferences determine which provisional assets are kept or replaced.

Use one report per problem. A short example format:

```text
Phase / work batch:
Date and engine version:
Mac / window size / editor or export:
Starting state (objective, gear, occupied/on foot):
Steps:
1.
2.
3.
Expected:
Observed:
Repeatability (e.g. 2 of 2 attempts):
Impact (blocks play / breaks a feature / polish or preference):
Exact Godot error, if present:
Optional evidence (image, short clip, or log):
```

Launch failure, crashes, lost progress, and unrecoverable stuck states block phase
acceptance. Broken controls or required interactions need a fix and retest before
that part passes. Smaller presentation preferences can be recorded for discussion;
deferring one requires an explicit decision rather than silently closing it.

After a fix, repeat the original failing sequence first. Then do the smoke test
and nearby related checks. Run broader tests only when the change or another
finding justifies them. The author's phase verdict should name what was played,
what passed, remaining issues, and whether the next phase may be proposed.

### Gate status

- Automated regression result: see [VALIDATION.md](VALIDATION.md).
- Codex rendered review: unavailable; the graphical launch aborted during macOS
  initialization in this session. No visual pass is recorded.
- Author playtest: **pending**.
- Phase acceptance: **pending the author's verdict and any required fixes**.
- Next phase: scope to be discussed after this playtest; no automatic expansion.

The current save path is `user://driving_prototype.cfg`; audio preferences use
`user://driving_audio.cfg`. Successful disk I/O can be checked with isolated test
files here, but normal application-data persistence and physical controls still
need the interactive review above.
