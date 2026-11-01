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
| C11 | October 30, 2026: the author chose "Near-photoreal, consistent" over the design doc's "stylized realism" with "a consistent low-poly-to-mid-poly asset kit rather than mixing incompatible downloaded models" (`GAME_DESIGN.md` §2 and §12). Earlier the author shared another game's rainy cockpit to set the level, saying "i want it to be as realistic as this. this is a game." That screenshot is for calibration only and is not stored. The author also chose to keep "Rainy night". | Realism now takes priority over the low-to-mid-poly limit. Every model must still match the others in detail level, texel density and material workflow, so mismatched downloads are still avoided. The blue-gray rainy-night art target stays. Models remain free CC0/CC-BY only, credited, with logos removed (C10). `GAME_DESIGN.md` is not edited; this entry records the amendment. Work follows `ROADMAP.md`. |
| C12 | October 30, 2026: the author chose "Yes, switch" to Forward+ after the scratch-copy renderer and headlight experiments recorded in `fractional.md`. | Switch `game/project.godot` to Forward+ in Phase 1 of `ROADMAP.md`, and record the reason in README's renderer note. Measure frame time on the M4 after each phase. The submitted `a5` tag keeps Compatibility. |
| C13 | October 30, 2026, after reading Assignment 10: the author chose "macOS, Forward+" as the export target and "Yes, download" for Godot's export templates. | Export for macOS desktop with Forward+. Web would force Compatibility. A committed macOS preset excludes tests and carries no credentials. The 4.7.2 templates were downloaded and checked against Godot's official SHA-512 (1,281,349,702 bytes), and Phase 1 installs them. Build, launch and play the exported app, and record its SHA-256 before claiming export-ready. |
| C14 | October 30, 2026: for the December 20 submission, the author chose "All three missions" over a polished Mission 1 alone, and wants "a real game as my final portfolio piece". | Build the design doc's must-ship game: M1, M2 and M3 with checkpoints, on-foot movement, the combat encounter and the required story beats (C04). Keep each mission small, as the design doc's compressed plan intends. The realism work follows the priority order and cut list in `ROADMAP.md`. Story details stay as written; open narrative questions are asked, not invented. |
| C15 | October 30, 2026: "the goal is to put the game on some game store to sell it. make sure we are doing a realistic and professional game." The author also asked for best practices, current documentation, meaningful file names and a clean folder structure. | Treat Blackridge as a commercial product. Every asset and tool must allow commercial use, so avoid non-commercial and no-derivatives licences, record each licence in `SOURCES.md`, and avoid real vehicle brands and trade dress. Choose the store, the game's own licence, and signing or notarization costs before release; they are not decided yet. Keep documentation current with each change, and keep names and folders clean (`ROADMAP.md` Phase 0). The December 20 course submission is not the store launch. **Amended the same day:** "we can skip selling also if its too much work. but i want realistic game. dont do anything that will go against our assignments for now. focus on thedevelopement of game, we will clean it up when i sat". So a realistic game is the priority; selling is optional and deferred; the course assignments come first; and the Phase 0 cleanup waits until the author asks. Free CC0/CC-BY assets with credits stay the rule (C10), which keeps selling possible. No other selling preparation is done for now. |
| C16 | October 30, 2026: after rejecting the code-built wheel and interior, the author chose "Free prebuilt, I pick", style "Modern van", and access through "Blender + Sketchfab token". | Offer 2–3 free cockpits with pictures; the author picks. Remove logos and wire the wheel, gauges, mirrors and switches into the chosen interior. |
| C17 | October 30, 2026: "Drops and drips, no fog" for the driver's side window. | Rain drops and drips replace the fog overlay on both side windows. `heavy_fog.tres` stays in the repository, unused. |
| C18 | October 31, 2026: the author chose cockpit option A, the Hyundai Staria on Sketchfab (CC-BY), "I want A". After being told its uploader's catalogue suggests the licence may not be valid, the author said "its fine use it for now". | Use it, but mark its provenance as unverified in `SOURCES.md`, keep it replaceable, and remove the logos. Revisit before any public release or sale. |
| C19 | October 31, 2026: "make this for realstici understand the gravity, physics and do it", about water on the glass. | Drive drop motion from physical forces (gravity along the glass, air drag, contact-line pinning), not hand-picked speed thresholds. |
| C20 | October 31, 2026: "lets rebuild it in blender just to be safe". This supersedes C18's "use it for now". | Claude Code models the cockpit in Blender. The Sketchfab Staria is only a local reference: never committed, shipped or traced mesh-for-mesh. Use our own shapes, no logos, and Poly Haven or our own textures. |
| C21 | October 31, 2026: "how to keep all of them and switch to 60fps?" | Target 60 FPS on the MacBook Air M4 without removing effects. Limit shadows to distances where they are visible, add level of detail, upscale with MetalFX, and record measurements in `PERFORMANCE.md`. |
| C22 | October 31, 2026: after Claude Code imported free interiors and showed the driver's views, the author chose the Honda e interior ("i like this more"). It is CC-BY, released by its creator Alex Murias. | Adapt it into the van: the dashboard extended to the windshield, van-width door panels, our gauges and map on its screens, the wheel turning, every logo removed, and performance kept at 60 FPS. Credit Alex Murias in `SOURCES.md`. Restyle the trim and screens before any sale. This supersedes C18 and C20's reference plan. |
| C23 | October 31, 2026: the author asked for "the road full of twists and turns like driving on ghats. not just a circle road", then chose "real ghats" over twists on flat ground and approved the proposed layout ("start with run 14"). | The flat 0.7 km rounded-rectangle loop becomes a 3.2 km loop over Blackridge Hill, still starting and ending at the depot. It climbs 79 m through five hairpins, runs along the ridge, and comes down through five more. Grades stay at or below 9.1%, with hairpins flatter and widened to 6.5 m. Following the story's American setting, the dressing is an American mountain road (guardrails, curve and switchback signs, rock cuts), not Indian painted parapets. It is the design's "forest highway" zone; the road network stays a loop, inside the 1.2 km by 0.9 km envelope. Plain concrete barriers stand at every drop until the dressing run (Run 15). |
| C24 | October 31, 2026: "dont make it a pattern. make sure its uniqque. something like this" (with a drawn ghat road map), "also make the wipers more realisitc and spawn the user away from the depot" (approving Run 15). | The road becomes one irregular mountain road from 38 hand-placed waypoints: four hairpins up and four down, each leg and hairpin different, a 3.0 km lap, grades up to 9.7%. The dressing stays American (C23): W-beam guardrails, dry-stone walls at the hairpins, MUTCD warning signs and chevrons, convex mirrors, and a viewpoint pull-off facing the town's lights. The wipers park flat and sweep in tandem. The drive starts at a lumber yard 589 m from the depot and ends at the depot. Claude Code's own calls, shown to the author in the Run 15 report: the lumber yard as the start, and a landslide closing the valley road east of the depot, which explains the route over the hill. From the reference, the river, waterfalls, tunnel, rest stop, fuel station and numbered hairpins are not built. |
| C25 | October 31, 2026, answering how to switch the high beams: "Add it to the L. when L is pressed once low beam should turn on, when pressed twice high beam, when thrice lights off." Approved as Run 16 step 3 ("yes start step 3"). | The protected `headlights` action (L) now cycles low beam, high beam, off. The game still starts on low beams, so the first press gives high beams. `headlights_on` keeps its meaning (true while either beam is on), so the dimming driver, `night_cluster`, the `LIGHTS` text, the lamps and the switch click are unchanged. High beams use the same two shadowed headlights with a no-cutoff pattern and a 220 m reach, and a blue lamp shows on the cluster. The same answers chose the moon roof (glass over the front seats) and named what was wrong with the wipers ("They look like sticks", "Water doesn't react"). |
| C26 | October 31, 2026: asked how to show rain falling through the headlight beams, given that Assignment 6 (particles) was to make falling rain, the author chose "Shader rain now (Recommended)". | Rain streaks are drawn by a shader (`beam_rain.gdshader`, in the van's folder) on eight layers in front of the van, lit only where the real beam pattern reaches, with no particle system. Assignment 6's particles can replace it later. |

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
| Renderer and content budgets | Forward+ chosen on 2026-10-30 (C12); the switch happens in Phase 1 of `ROADMAP.md`. No sustained budget measured yet. The 2026-10-19 depot benchmark capture runs gave 47–60 FPS at 1280×800. | Representative M4 frame-time and memory measurements at 1280×800 after each phase. The brief's starting target is 60 FPS, never below 45 after a 10-minute drive. |
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
