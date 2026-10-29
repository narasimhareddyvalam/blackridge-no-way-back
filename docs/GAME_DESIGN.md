> BLACKRIDGE  /  NO WAY BACK

# BLACKRIDGE: NO WAY BACK

GAME DESIGN DOCUMENT  /  Solo-developer production scope and implementation plan

Creative development draft  |  October 2026

## 1. Product vision

A compact, atmospheric, narrative-driven 3D crime game set in Blackridge. Players drive freight vehicles in first person, explore on foot in third person, accept jobs that become dangerous, and unravel a family betrayal. Target: polished university project built by one developer in Godot 4, with Blender assets, on a MacBook Air M1 over approximately 12 weeks.

Experience pillars: (1) believable industrial-town atmosphere; (2) satisfying cockpit driving; (3) narrative tension and emotional stakes; (4) small number of polished missions; (5) technically achievable systems.

## 2. Audience, platform and constraints

| Item | Decision |
| --- | --- |
| Platform | Desktop (Mac development; PC export only if time permits) |
| Engine | Godot 4.x; GDScript; Blender for lightweight models |
| Camera | Third-person on foot; first-person cockpit when driving |
| Genre | Compact open-world crime thriller; primarily single-player story |
| Team / schedule | Solo beginner-to-intermediate developer; ~12 weeks |
| Target performance | Stable playable frame rate on M1 with conservative geometry, lights and post-processing |
| Presentation | Cinematic low-light realism through composition, fog, lighting and audio rather than photorealistic asset density |

## 3. Scope tiers

### Must ship — minimum viable game

- One contiguous playable district with town street, depot, warehouse, docks set piece and small airfield set piece.

- One drivable truck/van with cockpit view, enter/exit, steering, braking, collision and reset.

- Third-person movement, camera, interact prompts and basic checkpoint saving.

- Three connected playable story missions with objectives and dialogue/subtitles.

- One compact combat encounter: aim, shoot, reload, health, simple guard AI and clear fail/retry.

- Narrative intro, betrayal reveal, reconciliation, airfield climax, six-month epilogue and watcher/title stinger.

- Main menu, pause, audio settings, objective display, subtitles and credits.

### Should ship — if core is stable

- Optional repeatable delivery route for world texture.

- Simple vehicle damage feedback, radio ambience, and traffic parked or scripted.

- Second drivable vehicle, additional weather variation and environmental storytelling.

### Do not attempt in the first release

- Full GTA-style city simulation, complex civilian AI, wanted-level police, multiplayer, large interiors, realistic economy, many guns, sprawling mission branches, multiple endings, full vehicle fleet or procedural traffic.

## 4. World layout

Plan an irregular, compact terrain envelope around 1.2 km × 0.9 km, with a detailed playable core of roughly 400–600 m and approximately 2–3 km of connected roads if performance and time allow. These are planning targets, not commitments. Build the road network as a loop with short branches, so driving feels open without requiring a huge city.

| Zone | Purpose | Required assets |
| --- | --- | --- |
| Ethan’s depot / motel | Tutorial, jobs, emotional opening | Truck, loading dock, small exterior |
| Main street / gas station | Town identity, landmarks, short drives | Storefront shells, signs, lamps |
| Forest highway | Night collision, driving atmosphere | Curves, trees, roadside barriers |
| Industrial warehouse | Escalating criminal work, first danger | Fences, crates, loading bay |
| Docks | Betrayal reveal / ambush | Containers, crane silhouette, water backdrop |
| Private airfield | Final convoy and hangar fight | Runway strip, hangar, gate, aircraft silhouette |
| Family house | Epilogue only; small staged exterior/interior | Porch, moving boxes, parked sedan sightline |

Use terrain changes, occlusion, fog and bends to prevent players seeing the whole small map at once. Reuse industrial materials and props with variations. Block distant districts with silhouettes rather than explorable geometry.

## 5. Core player loop

Receive job → travel through Blackridge → interact with cargo/location → discover complication → drive or fight to resolve → receive story reveal and next objective. Keep travel purposeful, with dialogue, environmental cues, or suspense during drives.

## 6. Controls and cameras

| Action | Suggested mapping |
| --- | --- |
| Move / steer | WASD |
| Look | Mouse |
| Interact / enter / exit | E |
| Sprint on foot | Shift |
| Jump | Space |
| Aim / fire | Right mouse / left mouse |
| Reload | R |
| Pause | Esc |
| Camera toggle in vehicle | C (optional) |

On foot: CharacterBody3D with third-person spring-arm camera, collision-safe camera follow, and a simple animation state machine. Vehicle: start with a controllable physics vehicle or arcade-style rigid body tuned for reliable handling; switch to a fixed interior cockpit camera on entry. Exit only when speed is low and a safe nearby position is clear.

## 7. Driving design

- Prioritize predictable acceleration, braking and cornering over simulation realism.

- Readable dashboard and windshield framing; a limited set of working gauges is optional.

- Route markers should be sparse and believable, with GPS-style objective hints rather than giant arrows.

- Night rain can be suggested with audio, droplets and reflective material patches; avoid expensive real-time global effects.

- Include vehicle recovery/reset and collision checks to prevent soft locks.

## 8. Interaction and combat

Interaction: raycast or proximity Area3D prompts for job boards, crates, gates and vehicle doors. Combat: one handgun, hitscan or simple projectile fire, ammunition, reload, health and one guard archetype with patrol/alert/chase/attack states. Limit combat to one or two deliberately designed spaces. A scripted convoy stop is more realistic for the schedule than dynamic high-speed pursuit AI.

## 9. Mission design — playable vertical slice

| Mission | Player activity | Story beat / success |
| --- | --- | --- |
| M1 — Night Freight | Drive tutorial, route navigation, collision cutscene, return to depot | Ethan flees the accident; believes he was unseen |
| M2 — The Wrong Cargo | Collect sealed load, inspect anomalies, retrieve vehicle, escape warehouse guards | Routine work becomes criminal; Vale links emerge |
| M3 — Last Run | Docks betrayal cutscene, route to airfield, intercept convoy, rescue Lily, guard encounter | Maya’s sacrifice refusal revealed; Adrian dies in self-defense |

Narrative scenes between missions deliver the separation, evidence of Maya’s refusal, reconciliation, and the epilogue. This compressed three-mission structure preserves the complete emotional arc while remaining finishable. If development progresses faster than expected, split M2 into two missions and give the docks its own mission.

## 10. Story integration and cinematic plan

Use Godot AnimationPlayer, Camera3D cuts, audio cues and subtitle panels for cutscenes. Avoid complex facial animation. Character staging, voice-free subtitles, silhouettes, shot composition and sound can convey emotion effectively. Keep most scenes 20–90 seconds, with the climax and final cinematic longer only if pacing demands it.

Critical narrative gates: never imply Ethan receives proof of the hit-and-run immediately; preserve Maya’s real refusal to sacrifice Ethan; show concrete evidence that earns forgiveness; explicitly acknowledge Ethan’s later cooperation with the collision investigation. After the six-month family drive, hold on the house, reveal the black sedan, show “Found them.” / “All three?” / “Yes.” / “Don’t approach them. Not yet.” Then cut to black and reveal the game title. No earlier end-title splash.

## 11. Technical architecture

| Scene / system | Responsibilities |
| --- | --- |
| Main / GameManager | Mission state, scene transitions, checkpoints |
| World.tscn | Terrain, roads, district instances, ambience |
| Player.tscn | CharacterBody3D, third-person camera, interaction, combat |
| Vehicle.tscn | Physics, cockpit camera, entry/exit, recovery |
| MissionManager.gd | Objective state machine, triggers, completion |
| DialogueManager.gd | Subtitles, timed dialogue, narrative flags |
| Guard.tscn | Navigation, perception, health and attack |
| UI.tscn | HUD, objectives, prompts, pause and settings |
| CutsceneDirector.gd | AnimationPlayer sequences, camera handoffs, skip/restore state |
| SaveData.gd | Checkpoint, mission progress, audio preferences |

Prefer signals and small scripts over monolithic managers. Use typed GDScript where comfortable. Keep mission triggers data-driven only if it reduces complexity; simple per-mission scripts are acceptable for three missions.

## 12. Asset and art direction

Art target: stylized realism with blue-gray rainy nights, muted industrial palettes, warm sodium-vapor lamps, and soft distant fog. Create a consistent low-poly-to-mid-poly asset kit rather than mixing incompatible downloaded models. Hero assets: truck exterior and simple cockpit, Ethan silhouette, Maya/Lily/Adrian scene-ready models, warehouse and hangar. Background civilians can be absent; populate the town with parked cars, signage, fences, props, audio and distant movement.

Audio target: tire noise, idling engine, rain, wind, dock ambience, radio fragments, footsteps, distant machinery and sparse cinematic music. The final scene reprises the opening drive’s musical motif, then drops into near-silence before the title reveal.

## 13. Twelve-week production plan

| Weeks | Milestone | Acceptance criteria |
| --- | --- | --- |
| 1–2 | Greybox town and movement | Walkable map; stable camera; drivable road loop |
| 3 | Vehicle feel and entry/exit | Cockpit driving, enter/exit, reset, collision |
| 4 | Interaction + objective system | Pickup/dropoff mission fully playable |
| 5 | M1 prologue | Night drive, scripted accident, checkpoint |
| 6 | Warehouse and M2 | Cargo route, guarded yard, clear objective flow |
| 7 | Basic combat | One guard AI, aiming, firing, health, retry |
| 8 | Docks and airfield | Climax route, rescue staging, reliable triggers |
| 9 | Narrative scenes | Betrayal, refusal evidence, reconciliation |
| 10 | Ending and title reveal | Family epilogue, watcher stinger, delayed title |
| 11 | Polish / optimize | Lighting, audio, subtitles, M1 performance |
| 12 | Testing / packaging | Full start-to-finish run, bug fixes, export and presentation |

## 14. Risks and fallback decisions

| Risk | Mitigation |
| --- | --- |
| Vehicle physics instability | Use simple arcade vehicle controller and tune before map expansion |
| Performance on M1 | Limit shadowed lights, reduce draw calls, use fog sparingly, bake where possible |
| Character animation scope | Use limited rigs and cinematic camera angles; subtitles over lip sync |
| Too many mission systems | Finish one end-to-end mission before adding combat |
| Oversized map | Trim roads and block out-of-bounds with believable geography |
| Final cutscene schedule | Use scripted camera shots and static poses rather than complex animation |
| Save/load bugs | Use mission checkpoints, not arbitrary world-state persistence |

## 15. Definition of done and testing

- Player can complete a full playthrough from menu to final title without editor intervention.

- Every mission has a visible objective, success state, failure/retry path, and checkpoint.

- No blocking collisions, soft locks, missing subtitles, or broken camera transitions.

- Driving is controllable with keyboard and mouse on target hardware.

- At least one coherent lighting/audio mood pass makes Blackridge recognizable.

- The final watcher scene occurs after the happy ending, with the title appearing only after cut to black.

- A recorded gameplay walkthrough and short development presentation are ready for course submission.

## 16. Stretch backlog / sequel hook

Additional delivery contracts, second car, police response, more interiors, radio stories, improved facial animation and more districts can follow only after the vertical slice is finished. The watcher’s identity should remain unresolved in this game; do not turn the ending into an additional mission or dilute the family resolution.

> Confidential creative working draft
