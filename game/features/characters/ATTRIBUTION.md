# Character attribution

`ethan/ethan.glb` and `pedestrian/pedestrian.glb`, with the textures Godot extracts next to
them, are made from Adobe Mixamo characters and animations:

- **Source:** Adobe Mixamo, https://www.mixamo.com
- **Ethan:** Mixamo character "Ch33", with the animations Breathing Idle, Walking, Walking
  Backwards, Running, Entering Car and Exiting Car (decision C28), and Pushing and Push Stop
  for bay 9's pallet jack (added on 2026-11-12, Phase 2's step 2e, #240).
- **The pedestrian:** Mixamo character "Ch01", with Hit By Car, and Ethan's Walking and
  Breathing Idle (the idle added on 2026-11-01, Run 22, for waiting at the bus stop).
- **Licence:** Adobe's Mixamo terms. They are free to use in games, including games that
  are sold, and may not be shared on their own. The author accepted that this public
  repository makes them downloadable (decision C27).

## Changes

Claude Code converted the downloads with `tools/art/convert_mixamo.py` on 2026-10-31, at the
author's request:

- **Materials:**
  - each part (skin, suit, shirt, tie, belt, trousers, shoes, hair) has its own copy of the
    shared material, with its own roughness;
  - nothing is metallic, and Mixamo's gloss and specular maps are dropped, because they
    made the clothes look like plastic;
  - hair and eyelashes are clipped at half alpha.
- **The pedestrian's polo:** tinted from light grey to charcoal, so he is hard to see at
  night.
- **Textures:** halved from 4096 to 2048 pixels and stored as WebP.
- **Bones:** renamed to one prefix, so either character can play the other's animations.
- **Walk and run:** they play in place, and the game moves the character.
- **The pedestrian at real size (2026-11-01):** Mixamo's 1/100 scale and 90-degree turn are
  baked into his skeleton, so his physics ragdoll can attach to it. In the game Hit By Car now
  gives only his standing pose; the hit itself is physics.
- **Pushing and Push Stop (2026-11-12):** Pushing plays in place like the walk; Push Stop's
  forward travel is taken out at every sixth frame, and the game moves Ethan by the same
  amounts. His hands are held to the pallet jack's handle in the game, not in the clips.

The source downloads are described in `source_assets/mixamo/README.md`.

## The gate guard

`guard/guard.glb`, with the textures Godot extracts next to it, is made from the Microsoft
Rocketbox avatar library (decision C55):

- **Source:** https://github.com/microsoft/Microsoft-Rocketbox: the avatar
  `Assets/Avatars/Professions/Security_Male_01` and the animation
  `Assets/Animations/all_animations_max_motextr_static/m_sit_chair_breathe_01.max.fbx`,
  downloaded on 2026-11-11 (`source_assets/rocketbox/README.md`).
- **Licence:** MIT, copyright (c) 2020 Microsoft (`source_assets/rocketbox/LICENSE.md`). Free for
  any use, including a game that is sold, if the copyright and licence notice go with it; the
  in-game credits carry them.

### Changes

Claude Code converted the downloads with `tools/art/convert_rocketbox.py` on 2026-11-11, at the
author's request:

- **The clip:** baked onto him bone by bone, because a Rocketbox clip's rest pose is its own
  first frame: each bone turns as the clip turns it, on his own bone lengths. It is named
  `SitIdle-loop`, which Godot loops as `SitIdle`.
- **Placement:** turned to face the model's front and moved so that his shoes stand at its
  origin, under his hips.
- **Materials:** one roughness per part (head 0.56, uniform 0.72, kit 0.5); Rocketbox's specular
  maps are dropped and nothing is metallic.
- **Textures:** halved from 2048 to 1024 pixels and stored as WebP.
- **In the game:** he sits at the gate booth's counter, and a `LookAtModifier3D` turns his head
  (`transfer_shed.gd`).

## The dock worker

`dock_worker/dock_worker.glb`, with the textures Godot extracts next to it, is made from the
Microsoft Rocketbox avatar library (decision C58):

- **Source:** https://github.com/microsoft/Microsoft-Rocketbox: the avatar
  `Assets/Avatars/Professions/Construction_Male_08` and the animations
  `Assets/Animations/all_animations_max_motextr_static/m_idle_neutral_01.max.fbx`,
  `Assets/Animations/all_animations_max_motextr_xy/m_walk_neutral_01.max.fbx` and
  `Assets/Animations/all_animations_max_motextr_static/m_try_door_outwards.max.fbx`,
  downloaded on 2026-11-11 (`source_assets/rocketbox/README.md`).
- **Licence:** MIT, copyright (c) 2020 Microsoft (`source_assets/rocketbox/LICENSE.md`), as for
  the gate guard; the in-game credits carry the notice.

### Changes

Claude Code converted the downloads with `tools/art/convert_rocketbox.py` on 2026-11-11, at the
author's request:

- **The clips:** each baked onto him bone by bone, as the guard's is, and named `Idle-loop`,
  `Walk-loop` (the walk in place, its forward motion taken out in the library) and `Seal`, which
  Godot imports as the looping `Idle` and `Walk` and the one-shot `Seal`.
- **Placement:** moved so that his shoes stand at the origin, under his hips; he already faces
  the model's front.
- **Materials:** one roughness per part (head 0.56, work suit 0.72, hard hat 0.35); Rocketbox's
  specular maps are not used and nothing is metallic.
- **Textures:** halved from 2048 to 1024 pixels and stored as WebP.
- **In the game:** he comes out of the transfer shed's side door to seal a loaded van's doors
  at bay 9 and walks back in (`dock_worker.gd`, `transfer_shed.gd`).
