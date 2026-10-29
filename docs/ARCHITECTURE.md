# Architecture

This is the folder and ownership guide for implementation. The first-drive
prototype now has scenes, scripts, and original procedural/synthesized assets.
No autoloads or plugins are configured. Its validation is incomplete; see
[VALIDATION.md](VALIDATION.md).
[GAME_STORY.md](GAME_STORY.md) and [GAME_DESIGN.md](GAME_DESIGN.md) remain the
primary sources of truth; read [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md) for the
author's clarifications before interpreting them.

## Repository boundaries

| Location | Responsibility |
| --- | --- |
| `game/` | Godot project and shipped resources; `res://` starts here. |
| `docs/` | Markdown story, design, decisions, and development guidance. |
| `source_assets/` | Editable art, Blender models, and audio originals. Export runtime files into their owning feature. |
| `tools/` | Standalone development utilities and their instructions, outside the game import tree. |
| `builds/` | Disposable generated exports and reports; excluded from version control. |

Documentation, source assets, and standalone tools are siblings of `game/`, so
Godot does not import them as part of this project. An additional `.gdignore`
file is unnecessary in those directories. Runtime code must not load from them.

## Feature ownership

Keep a feature's scene, script, data, and exclusive assets together. Add a
subdirectory for a particular character, vehicle, mission, or system when real
content exists. Avoid parallel global collections of scenes, scripts, and models.

| Godot directory | Intended ownership |
| --- | --- |
| `app/` | Application entry point, startup, scene transitions, and connecting feature lifetimes. |
| `features/characters/` | Player and other character scenes, movement, animation, and character-specific behavior. |
| `features/vehicles/` | Vehicle scenes, handling, cockpit camera, entry/exit, and recovery. |
| `features/environments/` | World assembly, district scenes, roads, and environment-specific props and ambience. |
| `features/missions/` | Mission objectives, triggers, progression, and authored mission content. |
| `features/systems/` | Rules shared across features, such as interaction, dialogue coordination, or checkpoint serialization, when needed. |
| `features/ui/` | Menus, HUD, prompts, subtitles, and settings presentation. |
| `features/audio/` | Common playback and mixing behavior and project-wide sound content. |
| `features/cinematics/` | Authored sequences, shot timing, camera handoffs, and sequence-specific resources. |
| `shared/assets/` | Runtime assets with more than one feature owner. |
| `shared/components/` | Small reusable behaviors and resource types with concrete consumers. |

The design document's names such as `Main`, `MissionManager`, and `CutsceneDirector`
describe responsibilities. They do not require global singletons or one large
manager. Their eventual filenames follow the repository's lowercase `snake_case`
convention. Keep mission progression with missions, subtitle display with UI, and
authored cinematic content with cinematics. Small per-mission scripts are suitable
for the initial target; a generic mission framework is not a prerequisite.

## Scene composition and dependencies

The application entry scene owns the active world and UI and connects the
services they need. A feature scene owns its children and private resources.
Supply external collaborators through explicit references or configuration, use
methods to request actions, and use signals to announce results.

Features can use shared components; shared components must not depend on a named
mission, concrete character, UI screen, or application root. Coordinate cross-feature
work through a common owner instead of letting peers search each other's node
trees. Keep world content and UI interchangeable without hard-coded root paths.

Avoid duplicate ownership of state. Missions own their progression; UI displays
it; a checkpoint service stores the required snapshot. Cinematics coordinate with
their owner for camera and input handoff rather than permanently taking control
of unrelated nodes. The exact interfaces are deferred until implementation.

No autoload is configured. Introduce one only when a real application-wide
lifetime requirement exists, with explicit initialization and reset behavior.
Do not preload the whole world or create a streaming, pooling, or dependency
injection framework in advance of a measured need.

## Current first-drive composition

`app/first_drive.tscn` instantiates the industrial loop and van and connects the
trial route, HUD, temporary driver, and audio playback. The van owns movement and
accessory state; its presentation child owns cockpit geometry and live cameras.
UI display, audio playback, environment construction, and authored trial progress
stay in their respective feature directories. The application coordinates camera
handoff and occupancy. There are no application-wide singleton services.

The approved visual pass adds feature-owned GLB art under the van and industrial
loop `art/` folders. Vehicle presentation connects art to existing controls;
`depot_detail.gd` owns decorative depot composition. Offline authoring and GLB
validation stay under `tools/`; neither is a runtime dependency. See
[VISUALS.md](VISUALS.md) for code explanations and the Blender startup limitation.

A mesh helper under `shared/components/` is used by the environment, vehicle, and
temporary driver. Feature-specific shaders stay with their owning environment or
vehicle. Original synthesized sound sources remain outside `game/`; runtime WAVs
and their import sidecars live with the audio feature.

The depot trial is driving-system validation, not the finished narrative M1.
It stores only route checkpoint progress in `user://driving_prototype.cfg`.
Audio preferences use `user://driving_audio.cfg`. Checkpoints write a temporary
file and replace the prior file on success; saved/failed signals drive HUD feedback.
The default checkpoint path can be explicitly supplied for isolated test fixtures.
Temporary-path persistence and failure recovery are tested; normal application-data
persistence across launches remains an interactive check in this restricted session.

## Data and content flow

Author source assets outside `game/`, export game-ready files to their owning
feature, and let Godot generate its ignored import cache. Preserve import settings
and `.uid` sidecars with the corresponding source files. Keep authored tunable
data in small typed resources where helpful; avoid mutating shared resource
definitions when storing an individual instance's runtime state.

Shipped content uses `res://`. Player saves and settings use `user://`, with the
initial scope limited to checkpoints and preferences described by the design.
Full-world serialization is outside that scope. Standalone tools cannot become
runtime dependencies; document any later editor-plugin requirement separately.

## Scale and validation

Prioritize a small active district, reusable assets, and bounded simulation on the
MacBook Air M1. The existing Compatibility setting is provisional; renderer and
content budgets need representative measurements. Additional layers, background
processing, and advanced effects must solve a demonstrated problem.

Validate changed configuration or resources with the headless import command in
the README. Validate actual behavior, camera transitions, and rendering in the
editor once playable scenes exist. See [DEVELOPMENT.md](DEVELOPMENT.md) for the
workflow; this document does not introduce a test framework or performance promise.

The ownership approach follows Godot's guidance on
[project organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)
and [scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html).
