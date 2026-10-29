# Design decisions and open questions

[GAME_STORY.md](GAME_STORY.md) and [GAME_DESIGN.md](GAME_DESIGN.md) remain the
primary sources of truth. This register records explicit author clarifications
and questions that those sources leave open. It does not rewrite either document
or authorize new plot points, features, or answers.

## Confirmed author clarifications

These decisions come from explicit author clarifications. C01–C04 were recorded
during repository setup; C05–C06 were confirmed on October 18, 2026, during the
first implementation session. They are not implementation assumptions.

| ID | Confirmed decision | How to apply it |
| --- | --- | --- |
| C01 | Ethan and Maya maintain contact initially, but Maya's concealed life strains their relationship. | Interpret the story logline's "estranged" in light of this clarification; do not portray them as entirely out of contact. The source wording remains preserved. |
| C02 | Three playable missions are the initial development target. | Cinematic story sequences are not limited to three. Preserve the full emotional arc and required narrative beats. |
| C03 | Unresolved narrative details remain open until the author decides them. | Ask before inventing an answer or changing established story details. Record the explicit decision before dependent implementation. |
| C04 | The suspenseful watcher scene and title reveal after the final cut to black are essential. | Preserve the hopeful family ending, watcher scene, cut to black, and title reveal in that order. |
| C05 | Detailed functional realism is the quality target throughout the game. The author gave working vehicle accessories and firearm feedback as examples, then approved beginning with the detailed van prototype. | Implement approved interactions with coherent visual, physical, and audio feedback. Prototype assets are provisional. Explain and obtain approval for each implementation batch; examples do not silently replace the story or approve every future system. |
| C06 | The author intends to choose or generate final audio in ElevenLabs at the end. Current synthesized audio may be previewed, kept, or replaced at their discretion. | Keep audio replaceable and label its provenance. No ElevenLabs service call, purchase, generation, or final audio selection has occurred in this session. |
| C07 | On October 18, 2026, the author sorted six generated visual references into `source_assets/artwork/references/approved/` and requested inspection. | Use the reference inventory to guide cockpit, vehicle, wet-night, depot, and daylight visual quality. Approval of references does not select every pictured brand, feature, location, or vehicle detail, authorize implementation, or prove runtime quality/performance. Seven images are separately author-sorted as rejected. |
| C08 | After that review, the author said "proceed with game changes", then explicitly required protecting Blender. | Implement the explained first van/depot visual pass. Preserve Blender installation, preferences, add-ons, and existing work. The implemented pass uses direct GLB authoring after background Blender startup failed; no final visual acceptance or wider-world expansion is inferred. See VISUALS.md. |
| C09 | After considering tool changes, the author explicitly chose to continue in Godot: "alright, lets do with gadot". | Continue the project in Godot. Stop Unreal migration planning. Prioritize detailed authored assets and a small cockpit/depot visual benchmark against the approved references. Specific assets and implementation batches still need approval; Forward+ remains a proposed evaluation, not an applied renderer change. |
| C10 | October 19, 2026: "it should run on this machine m4", then "Free only, via Blender" with budget "Free only". | The target machine is this MacBook Air M4 (16 GB). Use only free assets with verifiable licences; no purchases. Source vehicles through the Blender MCP add-on once the author enables it. Free models may not reach the reference detail; report that honestly rather than substituting generated primitives. |

The ending's established staging and dialogue remain as written in
[the final cinematic](GAME_STORY.md#final-cinematic--someone-is-watching),
including the two-beat black hold. The watcher is deliberately unidentified in
this game; that mystery is not a question to answer during implementation.

## Open narrative questions

All entries below are **open**. They come from the story's existing
[narrative questions](GAME_STORY.md#narrative-questions-to-resolve-during-scripting).
No answers are selected by this repository setup.

| ID | Question for the author | Existing constraint |
| --- | --- | --- |
| N01 | Who is the pedestrian, and how does their death affect the later investigation? | Preserve the victim's significance and Ethan's responsibility. |
| N02 | How do Adrian's people credibly discover Ethan's vulnerability? | Ethan initially believes the collision was unseen; no immediate footage or blackmail message. |
| N03 | How does Maya safely record or preserve the ultimatum, and how does Ethan authenticate it? | Concrete evidence must establish her refusal and resistance before forgiveness. |
| N04 | Where is Lily kept safe during the airfield confrontation, and who gets her out? | Rescue staging must protect Lily and remain consistent with Adrian's self-defense confrontation. |
| N05 | How are the investigation and legal consequences acknowledged? | Ethan cooperates and admits fleeing; the reunion does not automatically absolve him. |

Do not fill these gaps with example dialogue, placeholder backstory, or a
convenient implementation choice. Work that is independent of them can proceed
when authorized. Ask the author when a task depends on a specific answer.

## Deferred implementation decisions

These are engineering choices already left flexible by the design, not approved
feature additions. Resolve them during the relevant implementation work and
record the evidence. Ask the author if a choice would alter story, scope, or
intended player behavior.

| Decision | Current state | Evidence needed |
| --- | --- | --- |
| Vehicle controller | A `CharacterBody3D` arcade controller is prototyped. The approved steering and measured-speed fixes pass regression checks; author playtest acceptance is pending. | Predictable keyboard handling, reliable collisions, safe entry/exit, and recovery on the M1. See `VALIDATION.md`; do not treat this candidate as validated. |
| Weapon implementation | Hitscan or a simple projectile remains undecided. | The smallest reliable implementation of the design's handgun and guard encounter. |
| Renderer and content budgets | Compatibility is the existing provisional setting; no performance budget has been measured. | Representative M1 frame-time and memory measurements at a stated resolution. |
| Final world dimensions | The design's terrain, core, and road dimensions are planning targets. | Required mission routes, measured performance, and available production time. |

## Recording future decisions

Keep identifiers stable. When the author resolves a narrative question, retain the
question and record the approved answer, decision date, and source of approval.
Do not silently turn an open entry into canon. Edit the primary documents only
when explicitly requested, preserving the distinction between original source
content and later author-approved amendments.

There are no approved answers to N01 through N05 yet. The implementation
clarifications above do not add missions, endings, characters, or answers to
those narrative questions. See [fractional.md](../fractional.md) for the dated
request/approval history and [VALIDATION.md](VALIDATION.md) for current evidence.
