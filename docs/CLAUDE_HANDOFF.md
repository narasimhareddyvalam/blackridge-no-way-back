# Claude handoff prompt — October 19, 2026

You are taking over development of **Blackridge: No Way Back** from Codex.
Workspace: `/Users/narasimhareddyvalam/Desktop/Blackridge_No_Way_Back`.
Read the actual project before proposing changes. This handoff is context, not
blanket permission to implement, install, purchase, migrate, or publish.

## My goal and working rules

I want a realistic, detailed 3D crime thriller with first-person cockpit driving
and third-person exploration. My six approved images establish the visual target.
I rejected both the initial block-based prototype and Codex's first visual pass
as unrealistic. Do not offer another collection of boxes as the finished art.
We considered other engines, but I explicitly chose to **continue in Godot**.

Explain each implementation batch, the code you intend to write, its purpose,
affected files, and how we will test it. **Wait for my approval before making
those changes.** Explain the resulting code understandably. Read-only review,
validation, and maintaining the development documentation have standing approval;
do not treat that as approval for new features or runtime fixes.

Work in playable phases. Let me play and judge each phase before expanding it.
Keep `fractional.md` updated alongside affected docs: requests, actual approvals,
decisions, problems, solutions, validation, limitations, and actual commits if
ever authorized. Keep entries chronological; append reversals rather than erasing
history. Attribute Codex's earlier work to Codex, not Claude or me. Use professional
factual wording; do not invent my opinions, experiences, or learning claims. The
HOUSEGHOST log I previously shared was a format example, not this game's history
or assignment requirements.

Protect Blender and all existing work. Do not alter its installation, preferences,
add-ons, or existing files without discussing the exact action and obtaining
approval. No Git initialization, branches, commits, pushes, or publishing unless
I ask. There is currently no Git repository initialized in this project.

## Read first

Read `AGENTS.md`, any more specific instructions, and these documents:

- `docs/GAME_STORY.md` and `docs/GAME_DESIGN.md` in full.
- `docs/DESIGN_DECISIONS.md`, including C01–C09 and open questions N01–N05.
- `docs/ARCHITECTURE.md`, `docs/DEVELOPMENT.md`, and `README.md`.
- `docs/VISUALS.md`, `docs/ENGINE_REVIEW.md`, `docs/AUDIO.md`.
- `docs/PLAYTEST.md`, `docs/VALIDATION.md`, and recent `fractional.md` entries.

The story/design Markdown files are verified conversions of external Word
originals. Preserve both sources and originals. The initial setup-only wording
in AGENTS.md predates the later explicit implementation tasks; playable content
now exists. This does not waive approval for your next batch.

Canon includes Ethan and Maya maintaining strained contact initially; Maya hides
her marriage and daughter. Preserve Ethan's initial belief that the collision
was unseen, Maya's refusal to sacrifice him, earned reconciliation, Adrian's
self-defense confrontation, and Ethan's accountability. Ending order is hopeful
family resolution → unidentified watcher → cut to black → title reveal.
Do not resolve N01–N05 yourself. They concern the pedestrian, discovery of Ethan's
vulnerability, authentication of Maya's evidence, Lily's rescue staging, and legal
consequences. My example driving-thriller timeline was pacing inspiration, not a
replacement story or approval for additional police/chase systems.

## What Codex implemented

Engine baseline: **Godot 4.7.2**, existing **Compatibility** renderer.
`game/` is the only Godot project root. Main scene: `game/app/first_drive.tscn`.
The viewport is configured at 1280 × 800. No autoloads or plugins were added.

The current build is a driving-system prototype, **not the completed M1 mission**:

1. A bounded industrial road loop with buildings, depot, signs, barriers, street
   lights, ordered navigation checkpoints, and a final depot parking objective.
2. A `CharacterBody3D` van with acceleration, braking, steering, handbrake,
   forward/reverse selection, collision handling, and checkpoint recovery.
3. First-person cockpit camera/mouse look, speedometer, approximate tachometer,
   dashboard navigation, three live mirror viewports, and a reverse-camera screen.
   Mirror rendering is limited to approximately 15 updates/second; image quality
   and orientation are not established by headless tests.
4. Indicators, hazards, headlights/brake feedback, horn, wiper speeds/parking,
   and driver/passenger windows. Window opening changes audio mix parameters.
5. Temporary primitive third-person driver, safe stopped entry/exit, pause/controls
   menu, Begin/Continue, New Drive, Recover, Quit, and four audio-volume sliders.
6. Prototype checkpoint progress under `user://driving_prototype.cfg` and audio
   preferences under `user://driving_audio.cfg`. This is not full-world saving.
7. Twelve original synthesized WAVs, including vehicle/ambience/accessory effects
   and a temporary musical bed. Master, Vehicle, Ambience, and Music buses exist.

Main code ownership:

- `game/app/first_drive.gd`: composition, camera/occupancy handoff, pause/recovery.
- `game/features/vehicles/freight_van/`: controller, presentation, displays, glass.
- `game/features/environments/industrial_loop/`: world and depot presentation.
- `game/features/missions/night_freight/first_drive.gd`: prototype route/checkpoints.
- `game/features/characters/driver/driver.gd`: temporary on-foot controller.
- `game/features/ui/driving_hud/driving_hud.gd`: menu/HUD/audio sliders.
- `game/features/audio/first_drive/driving_audio.gd`: playback and mixing.
- `game/shared/components/mesh_builder.gd`: genuinely reused mesh helper.

Much of the environment/presentation is constructed at runtime. An empty editor
viewport before running does not establish a rendering failure. Run the main
scene to inspect the actual game. The user successfully ran the project and
supplied screenshots, but has not accepted the phase's overall functionality.

## Completed, approved bug fixes

- Steering clearance no longer mistakes ground contact for a blocked turn. The
  separate cached query has bottom clearance; the physical collider remains full.
- WAV loop endpoints use duration × sample rate, not compressed byte counts.
  All seven looping sounds are checked against the source WAV frame counts.
- Checkpoints write a temporary sibling file then replace the old file. Success
  and failure have separate signals; HUD no longer claims a failed save succeeded.
  Failed persistence still permits in-session recovery.
- Speedometer uses measured longitudinal movement after physics, so it reads zero
  against a wall. Tachometer RPM is still an approximation, not a drivetrain sim.

## Graphics work implemented but rejected

The first art pass added seven original generated GLBs: van body, cabin, steering
wheel, tire, pallet, box, and bollard. It added grain/normal/surface maps, cockpit
detail, wheel rolling, depot surrounds/props, revised wall/asphalt/glass shaders,
one stationary depot reflection probe, three shadowed depot lamps, and camera
framing changes. Small new decorative props have no individual colliders.

Runtime art lives under the vehicle and industrial loop `art/` folders. Offline
source is `tools/art/build_first_drive_art.py` and `tools/art/mesh_authoring.py`.
The tool uses existing NumPy/Pillow and writes GLBs directly. No `.blend` output
was produced. It still relies on simplified forms and **does not satisfy me**.
Do not confuse valid geometry, higher triangle counts, or a GLB extension with
meeting the visual references. Do not rerun the generator over future replacements.

## Approved references

Open all six PNGs in `source_assets/artwork/references/approved/`:

- `Mercedes Van Drive to Downtown.png`
- `Mercedes Van Cockpit_ Riverside Drive.png`
- `Sunset Mercedes Van on Wet City Roads.png`
- `Rainy Neon City Drive.png`
- `Riverside Logistics at Dawn.png`
- `Sunlit Countryside Road Through the Valley.png`

They cover cockpit framing/detail, van exterior, wet-night lighting, depot detail,
and daylight surfaces/vegetation. Seven images are in the author-populated
`rejected/` folder. Preserve names and classifications. These are ChatGPT-generated
concept references, not actual gameplay evidence or ready-made 3D assets. Approval
does not automatically authorize pictured branding, music, traffic, locations,
or every depicted control. The inventory and prompt history are in the Markdown
records; don't invent missing generation prompts.

## Validation already recorded

Latest recorded runs from October 18, not newly rerun for this handoff:

- 64/64 driving regression checks.
- 29/29 accessory/integration checks.
- 133/133 independent asset-file/geometry checks.
- GLB imports succeeded; no GDScript parse failures in those runs.

From the workspace root:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path game --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --script ../tools/tests/first_drive_regression.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --script ../tools/tests/first_drive_integration.gd
python3 tools/tests/check_first_drive_art.py
```

Tests use isolated temporary saves and intentional write-failure fixtures. Do not
overwrite player saves or weaken checks to pass. Logs are under ignored
`builds/first_drive/` and `builds/visual_pass_1/`; retained tools are under `tools/`.
No FPS target, full route playthrough, listening approval, export validation, or
visual acceptance is established by these counts.

## Tool-session limitations

Codex's graphical Godot launch aborted during macOS application/menu registration.
Headless imports/tests worked but reported restricted user-log/editor-settings
and system-access errors. A zero exit code alone was not called a clean pass.
Actual shader rendering, transparency, mirror images, and normal-user-path save/
audio-preference persistence across launches still need interactive verification.

Blender 5.2.2 background startup crashed before running scripts, including a
factory-startup print-only reproduction. The trace entered Metal device support
detection. Root cause is unconfirmed; it is not proof that the installation is
broken. Existing Blender files/settings/add-ons were not edited, and launches
stopped after I emphasized protecting Blender. Software geometry inspection
renders under `builds/` are explicitly not Godot screenshots.

Your Claude environment may have different permissions/capabilities. Reassess
carefully after explaining the proposed action; don't blindly repeat failed
launches or promise graphical verification from headless output.

## What remains, in priority order

1. **Visual foundation:** Select a genuinely detailed, suitable vehicle/interior
   and coherent materials. Show actual asset previews, provenance, license, cost,
   accessory separation, and performance implications before integration. Build
   one approved cockpit/depot benchmark in Godot and obtain my in-game verdict
   before expanding. Forward+ is only a proposed evaluation, not an applied or
   approved renderer switch. Don't promise exact generated-image/GTA equivalence.
2. **Finish Phase 1 acceptance:** Keyboard handling, full driven loop, safe camera/
   entry/exit/recovery, mirror orientation, glass/wipers/windows, menu scaling,
   audible mix, persistence across launches, and sustained target-hardware
   profiling. Keep behavioral passes separate from visual rejection.
3. **Actual game content:** Build the compact district and the three connected
   story missions: M1 Night Freight, M2 The Wrong Cargo, M3 Last Run. Implement
   approved interactions/objectives, narrative presentation, subtitles/dialogue,
   characters/animation, mission failure/retry/checkpoints, and the remaining
   depot/warehouse/docks/airfield/epilogue content. The existing depot route is
   not a completed story mission. No cutscenes or full story playthrough exist.
4. **Combat:** Handgun, aim/fire/reload, ammo/health, guard AI, compact encounter,
   clear failure/retry, and the approved rescue/self-defense staging. Muzzle flash,
   recoil, casing ejection/fall/impact sound and similar small details are quality
   examples I requested, not systems already built. Hitscan versus projectile is
   unresolved; don't assume every realism example is a mandatory simulation.
5. **Final presentation/audio:** Replace provisional art/driver and finish UI,
   cinematics, subtitles, credits and contextual audio. I intend to choose or
   generate final audio in ElevenLabs at the end; current sounds may be kept or
   replaced. No ElevenLabs account/API/generation was used. Current loader expects
   WAV; don't rerun the synthesis script over later approved replacements.
6. **Release validation:** Complete end-to-end playthrough, mission/failure/save
   regressions, normal-path persistence, sustained performance, an actual export,
   packaging and documentation. These are all unfinished.

Keep the design's small scope: one district, one primary drivable van/truck, three
connected missions, checkpoints, one compact combat encounter. Full city/traffic
simulation, wanted-level police, multiplayer, many guns/vehicles, and branching
endings are outside the first release. Keep driving purposeful and tension tied
to unresolved questions rather than forcing arbitrary events every 30 seconds.

## Open inputs before dependent work

- Free assets only, or may paid candidates be considered? This question was asked
  but unanswered. No purchase authorization or budget exists.
- Target Mac and RAM: documents say M1; a supplied Godot screenshot reports M4.
  Clarify whether M1, M4, or both must be supported. No renderer/performance choice
  should silently assume the answer.
- Specific replacement model and visual implementation batch are not selected.
  Historical research leads are in ENGINE_REVIEW.md; prices/access need rechecking.
  Some Sketchfab pages/API requests failed; don't call them verified downloads.
- Narrative questions N01–N05 remain unresolved.

## Your first response

Review the current files and approved images without changing gameplay. Tell me
what you verified, what would genuinely close the visual gap, and your smallest
specific next batch with asset choices, affected code, validation, and any needed
input. Then wait for my approval. Preserve working controls and previous evidence;
do not restart from scratch or repeat the rejected block-based art approach.
