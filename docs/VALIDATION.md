# First-drive validation — October 18, 2026

## Current result

The approved steering, audio-loop, and checkpoint-feedback fixes are implemented.
A separately approved speedometer fix now reports measured motion. The retained
regression suite passes **64/64 checks**, exit 0, with no script errors. Expected
save-failure warnings are explicitly labeled by the harness; engine environment
errors remain described below.

**Author visual review: failed for both the prototype and the first art pass.**
After the revised van/depot handoff on October 18, the author again reported
"not realistic at all". The current mesh/material treatment does not satisfy
the selected references. Passing structural and behavioral checks does not
override that verdict. Further visual code changes await an explained batch
and approval.

**Phase 1 functional playtest remains pending.** See
[PLAYTEST.md](PLAYTEST.md) for launch instructions, controls, and acceptance checks.
Automated success is not visual, audible, or user acceptance.

This is an early vehicle prototype, not the completed narrative M1. A full driven
route, independently inspected rendered appearance, physical keyboard/mouse feel, audible mix, export,
normal application-data persistence across launches, and sustained M1 performance
are unverified. Disk writes and fresh-instance reloads have passed with isolated
test paths; actual player data was not changed.

## Environment and commands

### First visual pass — separate result

The author subsequently approved the first van/depot visual pass. Seven new GLBs
import successfully. The independent Python art check reports zero failures for
file headers, finite geometry, references, unit normals, winding agreement,
bounded per-asset geometry, and van dimensions. This does not establish visual
quality. Evidence is in ignored `builds/visual_pass_1/`.

Final runs pass **64/64 regression**, **29/29 integration**, and **133 asset checks**,
all with exit 0. There are no script errors or failed assertions. Logs are
`regression_final.log`, `integration_final.log`, and `art_validation_final.log`
under `builds/visual_pass_1/`. Expected save-failure warnings and restricted
user-log/system/editor-settings access errors are distinguished from assertions.
The project settings SHA-256 matches the value captured before the pass.
GDScript formatting and local documentation links pass.

The revised pass has now also been rejected visually by the author. The graphics launch
attempt in the tool session aborted before producing a usable image. Shader
compilation, image quality, transparency, and sustained performance remain open.
Headless import still reports restricted system/editor settings access errors.

Blender background startup also crashed before script execution, including a
minimal print-only reproduction, in Metal device detection. Its installation,
preferences, add-ons, existing `.blend` files, and GUI session were not edited.
Further Blender launches stopped at the author's request. Direct GLB authoring
is documented in [VISUALS.md](VISUALS.md); no Blender project output is claimed.

- Installed engine: `4.7.2.stable.official.ed1daf0bf`.
- Existing Compatibility project renderer retained.
- Configured viewport: 1280 × 800. Headless runs do not render that image.
- No Git repository, branches, commits, external dependencies, or plugins added.

The prescribed import command was run:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path game --import
```

The latest run has no GDScript parse errors. It still reports inaccessible
application-data/editor-settings paths and system certificate access errors in
this restricted session. Exit code 0 is not a clean validation verdict.

The retained suites can be run from the repository root:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
  --script ../tools/tests/first_drive_regression.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
  --script ../tools/tests/first_drive_integration.gd
```

It injects input, runs actual physics, verifies loops against the source WAV frame
counts, and checks saves with temporary files. It uses a unique directory under
`OS.get_temp_dir()` and overrides the checkpoint path before scene initialization.
Successful and deliberately failed writes exercise the real save/HUD code.

Earlier diagnostic scripts also ran through Godot's `SceneTree` entry point. Their
source copies and output are preserved in the local ignored
`builds/first_drive/` folder. They are development evidence, not runtime content
or committed test infrastructure. For example, from the repository root:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
  --script ../builds/first_drive/blackridge_behaviors.gd
```

The original diagnostic calls supplied absolute `/private/tmp/` script paths. The copies
under `builds/` contain the same check bodies. Generated evidence is not included
in a future clean checkout. The regression script under `tools/tests/` is retained
as source so the current checks can be repeated.

## Current retained regression checks

`builds/first_drive/regression_final.log` records **64 passed, 0 failed**:

- Floor contact permits turning in either direction. Turning into an adjacent
  obstacle is rejected, while turning away remains possible. The full physical
  collision box retains its original dimensions.
- Injected throttle/steering changes position and heading. Braking stops the van.
  Measured forward/reverse speed has the correct sign and recovery resets it.
- Seven looping sounds use the complete source WAV frame count. Each loops forward
  from zero on a separate playback resource; four one-shot effects remain unlooped.
- A successful checkpoint is readable from disk and shows success in the HUD.
  A failed temporary write preserves the prior checkpoint and current in-memory
  progress; recovery still works. Successful replacement updates the old file.
- A failed final replacement emits failure, cleans its temporary file, and preserves
  an obstructing directory. A fresh route instance reloads the stage and safe pose.
  Invalid integer ranges and wrong stage types are rejected.
- Blocked doors prevent exit; clearing them permits exit and reentry. Wall contact
  stops actual motion and the measured speedometer value while throttle is held.

Two save failures are deliberately injected by creating temporary path conflicts.
Their warnings are expected test observations. The harness removes its fixtures
on completion. The default application-data path is still inaccessible in this
session; normal-player-path persistence remains an interactive check.

The retained accessory/integration suite,
`tools/tests/first_drive_integration.gd`, passes **29/29 checks**, exit 0, no script
errors. It covers indicators, window/audio parameters, wiper settings, camera-world
wiring, reverse display state, gear/exit restrictions, driving, pause, and recovery.
The earlier diagnostic rerun passed 28/29 because it could read reversing-display
state before a physics tick. The retained script waits for physics and then a
process frame after input; production timing was not changed. Current GDScript
line width/indentation and local documentation link checks pass.

## Initial diagnostic checks (before fixes)

| Check | Result | What this establishes |
| --- | --- | --- |
| Ten feature/application GDScripts load and instantiate; scene resource, scene instance, pause/resume, input activation, presentation initialization | 16 checks passed | Parsing and basic startup work in the headless engine. |
| Accessory and movement behavior | 27 checks passed, 2 failed | Indicators blink, hazards/headlights toggle, wipers change speed and park, windows travel, window state changes mix parameters, reverse/forward selection and display state work, moving gear changes/exits are rejected, braking/acceleration work, entry/exit, pause, and recovery work. Steering clearance and actual heading change fail. |
| Obstructed exits, wall collision, ordered route state, depot stopping, Shift mapping | 12 checks passed | Obstructed doors reject exit, wall collision stops travel, route gates advance in order, and parking requires a stopped van. Route positions were set by the harness; this is not a driven playthrough. |
| Source WAV structure | 12 readable files | Listed source durations, mono PCM format, and sample rate are valid. This is not an audible quality check. |
| Audio source Python syntax | Passed | The source parses; the generator was not rerun during validation. |
| Literal `res://` file references | Passed | Referenced literal files exist. Dynamic references and rendered material correctness need separate checks. |
| GDScript line width | One violation | `features/missions/night_freight/first_drive.gd:59` reaches 104 columns with four-column tabs. No formatting fix applied. |

Four live-view cameras share the vehicle's actual world, and their transforms
follow the vehicle. Headless tests establish camera wiring and display state,
not the content or orientation of rendered mirror images.

## Findings and approved resolutions

### Steering clearance detects the ground

Originally, `freight_van.gd::_rotation_blocked()` tested the complete vehicle
collision shape with a small margin before turning. Once the van rested on the
floor, that query reported the floor as an overlap and refused rotation.

The diagnostic found the collider beneath the ground mesh at `(0, -0.3, 0)`, size
`(400, 0.6, 310)`, while the van rested at approximately y = −0.1498. A diagnostic
query shortened vertically by 0.1 m reported zero overlaps at the same position.

Applied after approval: the physical shape remains intact. A cached query uses
0.1 m of bottom clearance while retaining the physical roof/side/front/rear bounds.
Tests confirm clear-ground steering and adjacent-obstacle rejection. The code
reuses the query and cached shape pose during turns.

### Compressed sound loop boundaries use byte counts

Originally, `driving_audio.gd::_player()` divided imported data bytes to obtain a
loop-end sample frame. The imported stream format is 3 (compressed), so those
bytes do not represent two-byte PCM frames. The 32 s score contains 705,600 frames
at 22,050 Hz, but its original configured loop end was 142,780.

The six initially inspected continuous streams all showed the mismatch: engine,
exterior rain, cabin rain, tires, wind, and music. Horn uses the same loader path.
Applied after approval: loop frames use imported duration × sample rate, with
loop begin explicitly set to zero. The current suite verifies all seven loop ends
against the source WAV's frame count, independent of imported compressed byte size.
The score's loop end is now 705,600. Final asset selection remains the author's
choice under [the audio decision](AUDIO.md).

### Checkpoint notice can claim a save that failed

The restricted session cannot write the default `user://` directory. Route
progression correctly continues in memory, and warnings report failed writes.
Originally, `_process()` emitted `checkpoint_changed` after `_save_checkpoint()`
even when saving failed; the application displayed “Checkpoint saved”
unconditionally.

Applied after approval: write a sibling temporary file, then replace the prior
checkpoint only after that write succeeds. Return the actual error and emit
separate `checkpoint_saved` / `checkpoint_save_failed` results. HUD success now
requires a successful replacement; failure explains that in-session recovery
remains available. Tests exercise successful and failed writes/replacements and
fresh-instance reloads using an explicit isolated path. Runtime defaults remain
under `user://`.

### Speedometer read internal controller speed at wall contact

The first retained suite passed 59/60 assertions. Diagnostics showed zero physical
velocity at the wall while the internal controller value reached about 0.44 m/s
under sustained throttle. That value also drove the speedometer.

The author separately approved fixing this in the current phase. The controller
now records signed longitudinal motion from `get_real_velocity()` after movement.
Both analog and digital speed read its magnitude; recovery resets it to zero.
The wall checks distinguish physical motion from measured speed and assert both
stop. Forward, reverse, and recovery measurement also pass. The tachometer remains
an approximate RPM display, not a simulated engine/transmission model.

## Environment limitations and investigation

The normal save path is beneath
`~/Library/Application Support/Godot/app_userdata/Blackridge- No Way Back/`, outside
the session's writable roots. No permission escalation or machine-specific runtime
save-path change was made. The earlier diagnostic route harness observed failed
writes to that default path. The new retained suite successfully saves/reloads at
its isolated path and confirms failure feedback; normal-path persistence across
launches and audio-settings persistence remain unverified.

A graphical capture launch exited 134 before reaching the game. Its macOS crash
report shows SIGABRT during application registration (`_RegisterApplication` and
menu-bar initialization). No screenshot was produced. The exact underlying cause
has not been established; do not call this a shader failure or claim visual QA.

Early harnesses reported twelve leaked WAV/playback instances when quitting
immediately after freeing playing audio. A later harness waited for audio teardown
and exited without that warning. This is not evidence of a sustained memory budget
or a completed audio-lifecycle audit.

## Evidence files in this workspace

- `builds/first_drive/import_validation.log`
- `builds/first_drive/script_validation.log`
- `builds/first_drive/behavior_validation.log`
- `builds/first_drive/safety_validation.log`
- `builds/first_drive/diagnosis_validation.log`
- `builds/first_drive/diagnosis_console.log`
- `builds/first_drive/audio_validation.log` (initial failures)
- `builds/first_drive/import_after_fixes.log`
- `builds/first_drive/import_final.log`
- `builds/first_drive/behavior_after_fixes.log` (initial rerun: 28/29)
- `builds/first_drive/regression_after_fixes.log` (59/60; prior to gauge approval)
- `builds/first_drive/regression_diagnostic.log` (wall measurement evidence)
- `builds/first_drive/regression_final.log` (64/64)
- `tools/tests/first_drive_regression.gd` (retained regression source)
- `tools/tests/first_drive_integration.gd` (retained integration source)
- `builds/first_drive/integration_final.log` (29/29)
- Matching `blackridge_*.gd` harness copies under `builds/first_drive/`.

## Current phase gate

The author approved the three explained fixes and separately approved measured
speed. Those fixes and regression checks are complete. The next gate is the
[Phase 1 interactive playtest](PLAYTEST.md). Record the author's verdict, address
approved current-phase feedback, and obtain approval before expanding scope.
Graphical/audio review and target-hardware profiling remain required.
