# Character attribution

`ethan/ethan.glb` and `pedestrian/pedestrian.glb`, with the textures Godot extracts next to
them, are made from Adobe Mixamo characters and animations:

- **Source:** Adobe Mixamo, https://www.mixamo.com
- **Ethan:** Mixamo character "Ch33", with the animations Breathing Idle, Walking, Walking
  Backwards, Running, Entering Car and Exiting Car (decision C28).
- **The pedestrian:** Mixamo character "Ch01", with Hit By Car and Ethan's Walking.
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

The source downloads are described in `source_assets/mixamo/README.md`.
