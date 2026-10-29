# Instructions for Codex

These instructions apply throughout this repository. Read more specific
`AGENTS.md` files before changing files beneath their directories.

## Source of truth and scope

- Read `docs/GAME_STORY.md` and `docs/GAME_DESIGN.md` in full before suggesting or
  implementing story, gameplay, missions, characters, world content, or systems.
  Both are verified conversions; `docs/DEVELOPMENT.md` records their provenance.
- Keep repository documentation in Markdown. The original Word documents remain
  outside the repository in `~/Downloads/`; do not copy them into the repository.
  If a Markdown source is missing, report the limitation and recover it from the
  original when available; do not invent a replacement or claim to have read it.
- Treat the story and design documents as the primary source of truth for the
  game. Do not change canon, add mechanics, or expand scope without an explicit
  request. Surface conflicts instead of silently choosing an interpretation.
- Read `docs/DESIGN_DECISIONS.md` alongside both sources. It records explicit
  author clarifications and unresolved questions; it does not replace either
  source document. Preserve the source documents unless the author requests an
  edit. Ask the author before resolving narrative questions or changing the story.
- Ethan and Maya maintain contact at the start; their relationship is strained
  because Maya hides important parts of her life. Do not interpret the original
  logline's word "estranged" as complete separation or a lack of contact.
- Three playable missions are the initial development target. This does not cap
  the number of cinematic story sequences or authorize removing narrative beats.
- Preserve the hopeful family resolution, suspenseful watcher scene, final cut
  to black, and subsequent title reveal in that order. The watcher remains
  unidentified. Do not move the ending's title reveal ahead of the cut to black.
- Preserve the external originals, their filenames, and existing user work.
  Markdown conversions must preserve all content; follow the conversion guidance in
  `docs/DEVELOPMENT.md` before marking one complete.
- Work is solo development by a beginner on a MacBook Air M1. Prefer the smallest
  understandable implementation that satisfies the requested behavior.
- Respect the design's minimum scope: one district, one drivable truck/van, three
  connected story missions, checkpoint saving, and one compact combat encounter.
  The twelve-week schedule and map dimensions are planning targets. Do not promote
  optional features or sequel ideas into requirements; full city simulation,
  procedural traffic, wanted-level police, and multiplayer are outside the first
  release. Preserve the story's unresolved questions rather than answering them
  through implementation assumptions.
- The current stage is repository setup only. Do not add gameplay, placeholder
  scenes or assets, dependencies, or feature implementations without a later task.

## Architecture and ownership

- `game/` is the only Godot project root. Keep documentation in `docs/`, editable
  source art in `source_assets/`, standalone development utilities in `tools/`,
  and generated exports in `builds/`. Read `docs/ARCHITECTURE.md` before changing
  ownership boundaries or introducing application-wide services.
- Reserve `game/app/` for the application entry point and coordination of scene
  lifetimes. It connects features; feature logic stays with its owning feature.
  Directory markers are not permission to implement their future contents.
- Keep a feature's scenes, scripts, data resources, and exclusive assets together
  under `game/features/`. Create per-character, per-vehicle, per-mission, or
  per-system subdirectories only when implementing that content.
- Environment scenes compose the world. Mission content references reusable
  actors and systems rather than copying their implementation.
- Move content into `game/shared/` only when actual reuse warrants it. Shared
  components must not depend on a particular mission, character, or UI screen.
- Prefer composition using Godot nodes and small scenes. Use typed `Resource`
  objects for authored data where appropriate. Avoid deep inheritance, speculative
  frameworks, generic event buses, and universal manager scripts.
- Use explicit references and signals across scene boundaries. Let the owning
  scene coordinate its children. Avoid absolute scene-tree paths and repeated
  searches for dependencies.
- Add autoloads only for a demonstrated application-wide lifetime requirement;
  document ownership and reset behavior when one is introduced. No autoloads are
  preconfigured.
- Use `res://` for shipped resources and `user://` for player saves and settings.
  Do not write runtime state into source assets or depend on machine-specific paths.

## GDScript and Godot conventions

- Follow Godot 4 APIs and the engine baseline recorded in `README.md`. Do not
  silently upgrade the engine, renderer, plugins, or project settings.
- Use lowercase `snake_case` for runtime folders, files, variables, functions,
  signals, and input actions. Use `PascalCase` for classes and nodes, and
  `UPPER_SNAKE_CASE` for constants and enum members. Preserve original document
  names and the established uppercase Markdown filenames.
- Use descriptive names, typed function arguments and return values, and typed
  properties where types are known. Use `class_name` only when a reusable named
  type is useful; do not register every script globally.
- Use tabs for GDScript indentation, UTF-8, LF endings, and code lines under
  100 characters. Keep functions small and organize declarations consistently
  with the official GDScript style guide.
- Expose genuinely tunable data with `@export`; cache scene references with
  `@onready` or explicit injection when appropriate. Keep gameplay numbers out of
  unrelated UI code.
- Use named Input Map actions instead of hard-coded key checks when controls are
  implemented. Keep physics changes in `_physics_process()` and account for time
  in time-dependent behavior without applying `delta` twice to engine movement APIs.
- Prefer text `.tscn` scenes and `.tres` resources. Move imported resources through
  Godot's FileSystem dock when possible so references can be updated. Preserve
  `.import` and `.uid` sidecars; never edit the generated `.godot/` cache.
- Do not add inline code comments unless requested. Explain non-obvious
  architectural decisions in the development guide when needed.

## Performance and scale

- Treat the MacBook Air M1 as a development constraint. Profile on actual hardware
  with representative content; do not promise an FPS target from an empty project.
- Keep world content modular and the active simulation bounded. Do not preload
  an entire city or build a streaming framework before a measured need exists.
- Avoid idle per-frame work, per-frame tree searches, and repeated allocations.
  Prefer events; limit expensive AI, physics, navigation, and audio work to what
  is relevant. Introduce pooling or concurrency only after profiling justifies it.
- Reuse materials and meshes, right-size textures, and keep shadows, lights,
  transparency, and post-processing budgets modest. Use supported LOD, visibility,
  and culling tools when content warrants them.
- Measure CPU/GPU frame time, memory, and sustained performance. Keep renderer
  changes deliberate; advanced rendering features are not a baseline requirement.

## Workflow and validation

- Inspect relevant files and repository status before editing. Keep changes
  focused, preserve user modifications, and avoid unsolicited refactors.
- Read `docs/DEVELOPMENT.md` for conventions, asset handling, and validation.
  Update `docs/DESIGN_DECISIONS.md` when the author explicitly resolves a narrative
  question. Record the decision and its source without silently rewriting canon.
  Keep documentation aligned with actual behavior; distinguish planned work,
  accepted decisions, and unresolved inputs.
- Validate configuration changes with the installed Godot editor's headless
  import check from `README.md`. For later behavioral changes, test the affected
  scene interactively and add focused regression coverage when warranted.
- Report what was checked and any limitations. A headless import is not proof of
  correct rendering, gameplay, or performance.
- Track source files, `.import` and `.uid` sidecars, and non-secret export presets.
  Exclude caches, credentials, local editor state, and generated builds. Do not
  enable Git LFS filters until the tool and asset storage workflow are established.
- Do not commit, create branches, publish, or change unrelated files unless asked.
