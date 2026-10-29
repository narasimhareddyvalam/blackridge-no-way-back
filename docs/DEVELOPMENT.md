# Development guide

This document records the working process. Game content belongs in
[GAME_STORY.md](GAME_STORY.md) and [GAME_DESIGN.md](GAME_DESIGN.md), not in this guide.
See the root README for setup, engine version, and the directory map; see AGENTS.md
for coding and architecture rules.

Read [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md) with the primary documents for
author clarifications and open questions. [ARCHITECTURE.md](ARCHITECTURE.md)
describes where future work belongs. Neither guide introduces new game content.

## Story and design conversion

**Complete:** both Word documents were read in full and converted without changing
their authored content. Repository documentation is Markdown only. The original
files remain unchanged in `/Users/narasimhareddyvalam/Downloads/`, outside this
repository; they are not needed to read the converted game documents.

| External source filename | Repository document |
| --- | --- |
| `Blackridge_No_Way_Back_Story.docx` | [GAME_STORY.md](GAME_STORY.md) |
| `Blackridge_No_Way_Back_Game_Design_Document.docx` | [GAME_DESIGN.md](GAME_DESIGN.md) |

Source SHA-256 checksums:

- Story: `1579ca0231d281c9d54e7ddac302636438676ffb4663b9048fdeb9b22465f5af`
- Game design: `fdb2c4b7836a473c352eb8fb52c39f1656babec0660d61740da9f43d3cbc3377`

Conversion used Python 3.14.7 standard-library `zipfile` and
`xml.etree.ElementTree` to read WordprocessingML, with the resulting Markdown
applied as a text patch. No conversion dependency or runtime tooling was added.

Verification compared every paragraph, heading, bullet item, table cell, and
header/footer against the source XML in its original order. It covered 65 story
body paragraphs including table cells, one story table, 205 design body paragraphs
including table cells, and seven design tables. An independent macOS `textutil`
extraction also matched each document's complete body text. Source checksums were
verified after conversion.

The repeated page header and footer appear once each as blockquotes in Markdown.
Heading levels, list membership, section numbering, table rows, and all wording
are retained. Fonts, colors, page dimensions, and pagination remain in the Word
originals. Inspection found no document images, hyperlinks, notes, text boxes,
comments, tracked revisions, or embedded objects requiring separate preservation.
Package metadata and preview thumbnails remain in the originals. No authored
content was omitted.

For future revisions, read the complete new source and inspect its structure
before converting. Preserve wording, order, lists, tables, dialogue, meaningful
headers/footers, and any notes or review material. Do not silently accept tracked
changes. If new content cannot be represented faithfully within the Markdown-only
documentation requirement, resolve that limitation with the author rather than
discarding content or adding binary documents. Recheck the full output and update
the source checksum and verification record.

The Markdown files are the everyday source of truth; the external originals
provide conversion provenance. Keep later author-approved amendments explicit
and do not quietly rewrite either format to hide a discrepancy.

## Adding work incrementally

1. Read the story and game design, then identify the exact requested behavior and
   the smallest way to check it. Read the accepted clarifications and open
   questions in `DESIGN_DECISIONS.md`. If a narrative requirement is missing or
   contradictory, ask the author before implementing that behavior; keep the
   question open rather than filling the gap with an assumption.
2. Choose the owning feature directory. Keep its scene, script, data, and exclusive
   assets together; create extra subdirectories only when they improve navigation.
3. Build and check one small piece at a time. Add shared abstractions only after
   concrete reuse appears. Keep system code separate from authored mission content.
4. Validate the affected behavior and inspect changes for accidental asset churn,
   path breakage, engine setting changes, or unrelated files.
5. Update this guide only when an actual development decision changes the workflow.

The design specifies one playable district and three connected missions for the
initial game. The playable mission target does not cap cinematic story sequences.
Its map dimensions and approximately twelve-week plan are targets, not guarantees.
Measure representative scenes on the M1 before expanding, keep optional features
deferred until the core is stable, and preserve the complete emotional arc within
that compact scope.

## Development conventions

- Use the existing feature directories and keep an item's scene, script,
  resources, and exclusive assets together. Follow `ARCHITECTURE.md` for ownership.
- Use lowercase `snake_case` for runtime paths and GDScript functions, variables,
  signals, and input actions. Use `PascalCase` for node and class names, and
  `UPPER_SNAKE_CASE` for constants and enum members. Uppercase documentation names
  and preserved original source filenames are deliberate exceptions.
- Use typed GDScript where types are known, tabs for scripts, and UTF-8/LF text.
  `.editorconfig` and `.gitattributes` contain the formatting defaults. Avoid
  reformatting the story or game design as part of unrelated maintenance.
- Keep text scenes and resources reviewable, retain `.import` and `.uid` sidecars,
  and make case-sensitive paths match exactly even when working on macOS.
- Put standalone authoring, validation, or packaging utilities in `tools/` only
  when a task needs them. Document each tool's command, prerequisites, inputs,
  outputs, and whether it changes files. No tooling dependencies are installed now.
- Keep editor-only Godot plugins under `game/addons/` if one is later required;
  that directory and any plugin installation are deferred until there is a need.
- Route generated packages and reports to `builds/` and disposable tool caches
  to `tools/.cache/`. Both output locations are ignored. Do not put generated
  output or editable Blender files inside the runtime project accidentally.

## Asset workflow

The first visual pass uses `tools/art/build_first_drive_art.py` to author original
GLBs and PNG maps directly because Blender crashes during startup in this tool
session. This is a documented exception to the Blender source workflow; no
`.blend` was produced. Existing Blender files/settings are untouched. See
[VISUALS.md](VISUALS.md) before rebuilding: generated outputs overwrite their
previous versions, so preserve later manual replacements first.

- Keep editable `.blend` files in `source_assets/blender/`, layered images in
  `source_assets/artwork/`, and audio sessions or original recordings in
  `source_assets/audio/`. Add other source categories only when they are needed.
- Export `.glb` models, textures, and audio into their owning directory under
  `game/features/`. Export truly shared assets into `game/shared/assets/`.
  A character's exclusive sound belongs with that character; common playback
  behavior and project-wide audio belong in `features/audio/`.
- Preserve source-to-export naming so an asset can be traced back to its editable
  original. Use a consistent scale of one Godot 3D unit per meter; check transforms,
  orientation, materials, animation, and collision after import.
- Export models explicitly from Blender. Keeping `.blend` files outside `game/`
  avoids making Godot's import step depend on a local Blender installation.
- Configure Godot import options through the editor and track the resulting
  `.import` sidecars alongside the game-ready files. Cache output under `.godot/`
  is disposable. Keep generated `.uid` sidecars with their source files.
- Record the origin and license of third-party content when it is introduced, and
  retain required notices. No third-party assets or dependencies are included now.
- Before committing large binary assets, decide whether Git LFS is needed and
  available on every development machine and remote. This scaffold does not
  configure LFS filters or assume a hosting provider.

## Validation and performance

For documentation-only changes, check links, filenames, and consistency. For
project configuration or resource changes, run the README's headless import
command and inspect its output for errors. The first-drive prototype is now the
main scene; the setup-stage absence of a main scene no longer applies. Record
parse errors, runtime failures, and environment restrictions separately. A zero
exit code with logged errors is not a clean pass.

The author requires an explanation and approval for each code-change batch.
Validation and documentation updates were separately authorized on October 18,
2026. Report findings and explain proposed code fixes before applying them. Keep
[fractional.md](../fractional.md) chronological, with factual attribution and new
entries for reversals. Do not invent commits or write personal judgments in the
author's voice. The current validation record is [VALIDATION.md](VALIDATION.md).

The author also requires playable phase gates: provide a runnable entry point and
clear review criteria, then wait for the author's actual playtest verdict before
expanding. [PLAYTEST.md](PLAYTEST.md) records the current phase and pending review.
The first-drive regression command and its temporary-file effects are documented
in [tools/README.md](../tools/README.md). Passing that suite does not accept a phase
on the author's behalf.

The repeatable testing order is automated checks, a short interactive smoke test,
focused behavior/failure tests, save/relaunch checks, then visual/audio/feel and
representative performance review. Keep the build and test conditions stable.
Use observable outcomes, explicit expected results, isolated temporary fixtures,
bounded timeouts, and appropriate physics synchronization. Distinguish Pass,
Fail, Blocked, and Not run; preserve test failures and their explanations.
Reproduce a bug before fixing it, retest its original sequence, then cover nearby
behavior. Add regression coverage for meaningful failures rather than every small
edit. Never weaken a check merely to obtain a green result.

Record actual playtest feedback and measurable evidence in `fractional.md` and
the validation report. Do not claim universal best-practice compliance, visual
approval, a coverage percentage, or a performance budget from assertion counts.
On macOS with Compatibility, the Visual Profiler is unavailable; use the regular
Profiler and Monitors for available measurements and mark unavailable GPU data.
Check [PLAYTEST.md](PLAYTEST.md) for concrete steps and official tool references.

Current synthesized audio is provisional. The author plans to select or generate
final audio in ElevenLabs at the end and may keep or replace these sounds. See
[AUDIO.md](AUDIO.md) for source provenance, asset inventory, replacement constraints,
and the synthesis command, which must not overwrite later approved replacements.

When playable content exists, check the changed scene in the editor and exercise
its failure and reset paths. Add a small automated regression test when behavior
warrants it; choose a test framework only when there is real code to test. Test an
export before relying on editor-only behavior or case-insensitive macOS paths.

Profile representative content on the M1 at a stated resolution and renderer.
Record frame times, memory, active content, and results after a sustained session.
Keep visible and active content bounded; use modest texture and lighting budgets
and only introduce streaming, pooling, or background work when measurements show
the need. An empty project cannot establish an FPS or memory budget for the game.

## Reference documentation

- [Godot project organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)
- [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [Version control with Godot](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html)
- [Godot renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- [Supported 3D asset formats](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html)

The `stable` documentation can move to a newer engine release. Select the version
matching the README's baseline when checking a version-specific API or setting.
