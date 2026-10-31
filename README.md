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
is optional. The author's decisions are C11–C15 in
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

The initial renderer is **Compatibility**, a provisional choice to keep the
starting configuration simple. It is not a measured performance result or a
final art requirement. Compare renderer options on the M1 with representative
content before committing to renderer-specific effects. Godot documents the
[renderer tradeoffs](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).

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
