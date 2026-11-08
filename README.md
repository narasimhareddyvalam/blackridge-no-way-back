# Blackridge: No Way Back

A compact, narrative-driven 3D open-world crime game built with Godot 4 and
GDScript, scoped for a solo developer using a MacBook Air M1. The design targets
one playable district, three connected missions, third-person exploration, and
first-person cockpit driving over an approximately twelve-week university project.

## Current status

**Final-project plan (2026-10-30).** [ROADMAP.md](ROADMAP.md) is the plan to finish the
game by 2026-12-20 for Assignment 10. It covers:
- all three missions;
- a near-photoreal rainy night;
- the Forward+ renderer;
- a macOS export.

A realistic game comes first and the course assignments take priority. Selling it later
is optional. Built so far on the `develop` branch:
- Forward+;
- low-beam headlights that light the road;
- a darker night;
- a single-lane road through about 6,500 pines with ferns and undergrowth;
- windshield rain that the wipers clear;
- a new gauge cluster, round vents and a new steering wheel. The author's decisions are C11–C15 in
[DESIGN_DECISIONS.md](docs/DESIGN_DECISIONS.md). Nothing in that plan is built yet, and the
rest of this section describes the game as it is today.

The first vehicle prototype is implemented in `game/app/first_drive.tscn` and set
as the main scene. It includes an industrial road loop, cockpit controls and
instruments, live-view camera wiring, windows, wipers, lights, synthesized audio,
a depot test objective, and basic third-person entry/exit.

The approved steering, audio-loop, checkpoint-feedback, and measured-speed fixes
are implemented. The retained regression suite passes **64/64 checks**. This is
ready for the author's **Phase 1 playtest**, with acceptance still pending:
[how to launch and what to try](docs/PLAYTEST.md). Graphics, perceived audio
quality, normal application-data persistence across launches, full driving
completion, and sustained M1 performance remain unverified. See the
[current validation report](docs/VALIDATION.md) for results and limitations.

The author sets detailed functional realism as the game-wide quality target.
Current procedural geometry and synthesized sounds are prototype assets. Final
audio may be generated or selected in ElevenLabs at the author's direction;
[current audio and replacement guidance](docs/AUDIO.md) records that decision.

The first approved visual pass now replaces the van/cockpit primitives with
authored GLBs and adds surface maps, depot detail, approximate local reflections,
and revised glass/rain shading. [VISUALS.md](docs/VISUALS.md) explains the code,
asset sources, Blender startup limitation, and pending graphical review. This
pass was rejected by the author as still unrealistic; target-hardware profiling
also remains pending. Automated checks do not establish visual acceptance.

Explain each implementation batch and obtain approval before changing code.
The chronological [development record](fractional.md) tracks requests, approvals,
problems, solutions, and actual checks. Git history starts at the 2026-10-28
baseline commit `e81ec92`.

## Assignment 6 — Particle effects

Four particle effects, all `GPUParticles3D`, designed in [CHANGE-BRIEF.md](CHANGE-BRIEF.md).
Their scenes and textures are in `game/effects/`.

- **A1, wiper flick:** water thrown off the driver's blade at each top turn of its stroke.
  `van_particles.gd` fires it from `wiper_swept`.
- **A2, roof spill:** water pours off the front of the roof onto the glass on a hard brake from
  8 m/s, with a 20 s refill.
- **B1, lamp rain:** rain in every lamp's light while the camera is within 65 m, with splashes
  where the drops land. Driven by `game/features/environments/industrial_loop/lamp_rain.gd`.
- **B2, exhaust vapour:** follows the engine and the throttle through `amount_ratio`.

**Starting point:** the game at `c1ee48f` (2026-11-07): Assignment 5 (tag `a5`) and the final
project's Phase 1, with no particle effect in it.

**Engine and renderer:** Godot 4.7.2 stable, Forward+ (Godot's desktop default), with MetalFX
temporal upscaling at 75% on macOS.

**Run:** open `game/project.godot` in Godot 4.7.2 and press F5, or run
`/Applications/Godot.app/Contents/MacOS/Godot --path game`. The main scene is
`res://app/first_drive.tscn`. Each effect's preview scene in `game/previews/` also runs on its
own (F6 in the editor). The previews are fixtures that put each effect's event on the brief's
frames, and the export leaves them out.

**Controls:** the opening menu lists them: W / S accelerate and brake, A / D steer, W A S D walk
on foot, Shift run, Q forward or reverse, Space handbrake, Z / C indicators, X hazard lights,
L headlights, V wipers (the wiper flick follows them), I cabin light, J / K windows, H horn, the
mouse to look around, F center view, E get in or out, T answer a call, R recover, Esc pause.
**F9 turns vsync off and on** for the FPS check; it is a debug key, not in the menu.

**What this assignment added:** the four effects, their controllers, the configuration and state
tests, the mutations, the previews, the strip script and the cost script; the brief, the tuning
log and the test report. Revision r1 of all four effects (`TUNING.md`), with its strips before
and after, and the changes to the lamps, the wet road and the roadside around them (prompt log
#150–#158), kept after the author's play (#164).

**Known limitations:**
- Godot's GPU timer reads 0 on Metal, so the GPU price was read from Apple's Metal Performance
  HUD instead (`TEST-REPORT.md`, "GPU price"). B2's exhaust costs 1.1 ms of GPU time behind the
  van, over its 0.30 ms budget; the four effects together, 1.47 ms, are at their 1.45 ms budget.
- The frame itself takes about 26 ms of GPU time from the driver's seat at 1280×800 on the
  MacBook Air's Retina display (about 39 frames a second), above a 60 FPS frame before any
  effect. The world changes (#150–#158) and the display's pixels are the likely causes, unmeasured.
- The Iveco model has no tailpipe, so B2's exhaust position is assumed (brief revision 2).
- B1's real-size splash droplets are faint from a few metres.
- B1's slowest drops fade 2–4 m above the ground.
- A headless run draws no particles and runs no GPU particle process.

**Film:** "Blackridge, Rain and Vapour" (4K, 7 min 41 s), made by Claude Code at the author's
word. The source is in `youtube/claude-liam-blackridge-particles-gamedev/`: script, beat sheet,
the captures' records, evidence ledger, fact check, QC and build log. File:
`Blackridge-Rain-and-Vapour-4K.mp4`, SHA-256 `8080d78ae388f2d6955b40411490b9ec2e64c58eb3e3e8cb44e4728a80539e92`. The
link is added once the author has uploaded it to the course's media storage; the film is not in
GitHub.

To check the effects:

```sh
LOG_DIR=logs/particles/<step> scripts/run-test.sh test_wiper_flick_config.gd 60  # one per effect
LOG_DIR=logs/particles/<step> scripts/run-test.sh test_wiper_flick_state.gd 60   # one per effect
LOG_DIR=logs/particles/<step> scripts/run-test.sh cost_effects.gd 60 300         # headless price
scripts/capture-strips.sh <round>   # frame strips: opens a window per effect
```

- Tuning: [TUNING.md](TUNING.md).
- Results: the Assignment 6 section of [TEST-REPORT.md](TEST-REPORT.md).
- Sources: [SOURCES.md](SOURCES.md).

## Assignment 5 — Shaders, materials and the Godot shading language

This layer adds three hand-written shaders in `game/shaders/` and the code and tests
around them. *Blackridge* replaced the author's Assignment 2–4 game for the final; see
[FRICTIONAL.md](FRICTIONAL.md).

- **Night dashboard dimming** (`night_cluster.gdshader`, `canvas_item`): while the
  headlights are on (L), the instrument cluster fades to a warm, dim amber. The fade
  takes 0.25 s in and 0.35 s out, driven by
  `game/features/vehicles/freight_van/night_dimming.gd`.
- **Foggy windshield** (`foggy_windshield.gdshader`, `spatial`): `light_fog.tres` on the
  windshield and `heavy_fog.tres` on the driver's window. They are overlays, so the
  original glass, rain and wipers are unchanged. The three textures are written by
  `tools/make_fog_textures.py`.
- **Hint experiment** (`hint_experiment.gdshader`): the scene
  `game/experiments/hint_experiment/hint_experiment.tscn` reads one 3×1 grey PNG as
  colour and as data.

Run the tests from the repository root (Godot 4.7.2; the wrapper finds the binary):

```sh
./scripts/run-test.sh test_night_dimming.gd 30   # also 60 and 144
./scripts/run-test.sh first_drive_regression.gd 60
./scripts/run-test.sh first_drive_integration.gd 60
```

In-engine captures open a real window, for example
`/Applications/Godot.app/Contents/MacOS/Godot --path game --script ../tools/captures/capture_night_cluster.gd`.
The results are in [TEST-REPORT.md](TEST-REPORT.md). The spec and context are in
[CHANGE-BRIEF.md](CHANGE-BRIEF.md) and [CLAUDE.md](CLAUDE.md). Credits and who wrote
what are in [SOURCES.md](SOURCES.md).

**Known limitations:**
- Under Compatibility, the hint experiment shows the file's values on both quads. A
  Forward+ comparison matches the sRGB predictions.
- At the light default, five of the fog's seven controls barely show from the driver's
  view (measured in the film's 4K sweep).
- Captures are offline renders at a fixed 60 fps; real-time performance has not been
  profiled on the target MacBook Air M1.
- **Film:** "Blackridge, Shaded" (4K, about 9.5 minutes). The source is in
  `youtube/claude-liam-blackridge-gamedev/`: script, beat sheet, 4K engine captures,
  evidence ledger and build log. File: `Blackridge-Shaded-4K.mp4`, SHA-256 `89066f8d42e86392f157c76ed832ff1b5b9994b20f1c6f5b08fee695d7b6c1c2`;
  watch it on OneDrive: https://northeastern-my.sharepoint.com/:v:/g/personal/valam_n_northeastern_edu/IQCCHHcatHuxT7BIfeUyLjEyAcdyHfosv8mtnbjcAG55b2Q?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=Fk9uVc

The [complete story](docs/GAME_STORY.md) and
[game design document](docs/GAME_DESIGN.md) are verified Markdown conversions of
the author's Word documents. Read both before making content or gameplay
decisions, and resolve any contradictions with the author. Documentation in this
repository is Markdown only; the original Word files remain outside the repository
in `~/Downloads/`. Conversion provenance and checksums are recorded in
[the development guide](docs/DEVELOPMENT.md).

Read the [author clarifications and open questions](docs/DESIGN_DECISIONS.md)
alongside both primary documents. Ethan and Maya initially maintain strained
contact; three playable missions do not limit the number of cinematic sequences.
The watcher scene and the title reveal after the final cut to black are essential.
These clarifications are recorded separately so the source documents remain intact.

## Repository layout

```text
Blackridge_No_Way_Back/
├── AGENTS.md
├── README.md
├── fractional.md
├── .editorconfig
├── .gitattributes
├── .gitignore
├── docs/
│   ├── ARCHITECTURE.md
│   ├── AUDIO.md
│   ├── DESIGN_DECISIONS.md
│   ├── DEVELOPMENT.md
│   ├── GAME_DESIGN.md
│   ├── GAME_STORY.md
│   ├── PLAYTEST.md
│   └── VALIDATION.md
├── game/
│   ├── project.godot
│   ├── app/
│   ├── features/
│   │   ├── characters/
│   │   ├── vehicles/
│   │   ├── environments/
│   │   ├── missions/
│   │   ├── systems/
│   │   ├── ui/
│   │   ├── audio/
│   │   └── cinematics/
│   └── shared/
│       ├── assets/
│       └── components/
├── source_assets/
│   ├── blender/
│   ├── artwork/
│   └── audio/
├── tools/
│   ├── README.md
│   └── tests/
│       ├── first_drive_regression.gd
│       └── first_drive_integration.gd
└── builds/
```

Empty directories contain a `.gitkeep` marker, omitted from the tree. Remove a
marker when its directory contains real tracked files.

| Directory | Purpose |
| --- | --- |
| `docs/` | Verified story and design Markdown documents, conversion provenance, and development guidance. Word originals stay outside the repository. |
| `game/` | The Godot project root; `res://` points here. Only runtime content and required editor tooling belong here. |
| `game/app/` | First-drive entry scene; connects world, vehicle, driver, route, UI, and audio lifetimes. |
| `game/features/characters/` | Each character's scenes, scripts, configuration, and exclusive assets together. |
| `game/features/vehicles/` | Each vehicle's scenes, scripts, configuration, and exclusive assets together. |
| `game/features/environments/` | Environment scenes, world assembly, and local props; add areas only as the design requires. |
| `game/features/missions/` | Authored mission content organized per mission, following the design documents. |
| `game/features/systems/` | Cross-feature gameplay rules, organized per implemented system. |
| `game/features/ui/` | Screens and widgets, with their scripts and exclusive visual resources. |
| `game/features/audio/` | Audio playback and mixing features, plus project-wide sound content. |
| `game/features/cinematics/` | Cinematic sequences, timing, and sequence-specific resources. |
| `game/shared/assets/` | Runtime art, materials, shaders, and other assets genuinely reused by multiple features. |
| `game/shared/components/` | Small reusable behaviors and resources with multiple concrete consumers. |
| `source_assets/` | Editable Blender files, layered artwork, and audio sessions or recordings; outside Godot's import tree. |
| `tools/` | Standalone development utilities and the first-drive regression checks, outside runtime imports. |
| `builds/` | Generated exports and packages, ignored by Git except for the directory marker. |

## Documentation map

- [GAME_STORY.md](docs/GAME_STORY.md): primary narrative source, including the
  emotional arc, narrative rules, and ending.
- [GAME_DESIGN.md](docs/GAME_DESIGN.md): primary gameplay, scope, art, and production
  source. Optional features remain optional.
- [DESIGN_DECISIONS.md](docs/DESIGN_DECISIONS.md): author-approved clarifications,
  open narrative questions, and deferred implementation decisions.
- [ARCHITECTURE.md](docs/ARCHITECTURE.md): feature ownership, scene composition,
  dependencies, and runtime/source/tool boundaries.
- [DEVELOPMENT.md](docs/DEVELOPMENT.md): conventions, asset workflow, source
  conversion provenance, and validation.
- [AUDIO.md](docs/AUDIO.md): provisional sound inventory and author-led final replacement.
- [VISUALS.md](docs/VISUALS.md): first art pass, code explanation, sources, and review limits.
- [VALIDATION.md](docs/VALIDATION.md): measured checks, resolved findings, and remaining review.
- [PLAYTEST.md](docs/PLAYTEST.md): phase gates, launch steps, controls, and author review checklist.
- [fractional.md](fractional.md): dated requests, approvals, decisions, and work history.
- [AGENTS.md](AGENTS.md): permanent instructions for Codex across the repository.

## Development setup

1. Use the standard **Godot 4.7.2 stable** editor, matching the installation
   detected during setup. GDScript does not require the .NET edition. Record and
   validate future engine upgrades in this README.
2. Open Godot's Project Manager, choose **Import**, and select
   `game/project.godot`. Do not create another project at the repository root.
3. Read [AGENTS.md](AGENTS.md) and [the development guide](docs/DEVELOPMENT.md).
   Review both primary documents and the author clarifications before implementing
   features. Use the architecture guide to choose the owning directory.
4. Blender is only needed when authoring models. Keep `.blend` files under
   `source_assets/blender/` and export game-ready `.glb` files into the feature
   that owns them. No Blender installation or third-party plugin is needed to
   open the project. The new GLB art is generated by a standalone Python authoring
   tool; Blender startup is currently blocked in the tool session, as described
   in `docs/VISUALS.md`.
5. Install export templates matching the editor version when exports are needed;
   write exports to `builds/`. Complete interactive validation before treating an
   export as ready.

The project started on **Compatibility**, a provisional choice to keep the starting
configuration simple. On 2026-10-30 it moved to **Forward+** (decision C12 in
[DESIGN_DECISIONS.md](docs/DESIGN_DECISIONS.md)). Side-by-side captures showed that
working headlights with a sharp low-beam cutoff and wet-road reflections need it, and
Assignment 10 asks for the renderer to be settled early. The export target is macOS
(C13). Assignment 5's results were measured under Compatibility, and tag `a5` keeps that
state. Godot documents the
[renderer tradeoffs](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).

**macOS export (2026-11-01, Run 21).**
- **The preset:** `game/export_presets.cfg` holds one preset, "macOS":
  - universal, so the app runs on Intel and natively on Apple Silicon;
  - version 0.1.0, ad-hoc signed, not notarized, with no credentials;
  - it leaves out the tests, `experiments/` and the visual benchmark scene.
- **The template:** Godot's official 4.7.2 macOS template, checked against the published
  SHA-512, is installed in `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`.
- **The command,** from the repository root:

  ```sh
  /Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
    --export-release "macOS" ../builds/macos/Blackridge.zip
  ```

  It writes `builds/macos/Blackridge.zip`, which Git ignores. The ZIP holds
  `Blackridge- No Way Back.app`; macOS turns the title's colon into a dash in the file name.
- **Gatekeeper:** an ad-hoc signed app copied to another Mac is blocked by Gatekeeper until
  the game is signed with a Developer ID and notarized.

From the repository root, the installed macOS application can open the editor:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --editor --path game
```

For an import and editor-startup check without a window:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path game --import
```

The headless import does not validate graphics or gameplay. It creates an ignored
`game/.godot/` cache. Use the equivalent executable path if Godot is installed
elsewhere. Launch the current main scene with F5 or the editor's Run Project
button. The opening menu lists controls and audio settings.
[VALIDATION.md](docs/VALIDATION.md) distinguishes tested behavior from open checks.

## Conventions

Group scenes, scripts, resources, and exclusive assets by feature. Add deeper
folders only as content grows; do not create global `scripts/` and `scenes/`
collections. Use lowercase `snake_case` for runtime paths and `PascalCase` for
node and class names. The standard uppercase Markdown filenames and preserved
original document names are exceptions.

Use typed GDScript, small composed scenes, and explicit dependencies. Keep
`project.godot`, `.tscn`, `.tres`, source assets, `.import` sidecars, and `.uid`
sidecars in version control. Generated caches and builds stay out. Repository
formatting is defined in `.editorconfig` and `.gitattributes`; no plugins, Git LFS
filters, or automated test framework are required by this scaffold.

The project is a Git repository on branch `main` (initialized 2026-10-28). Commit
messages say whether the author or an agent wrote each change.
