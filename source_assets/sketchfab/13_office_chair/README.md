# Office Chair: raw source (not in Git)

- **Model:** "Office Chair", https://sketchfab.com/3d-models/office-chair-b228a29fa84544c2be501c295653ffe7
- **Author:** Red Fox (Sketchfab `nokillnando`), published 2021-04-30.
- **Licence:** CC BY 4.0 (Sketchfab's "CC Attribution"). The game credits the author.
- **Fetched:** 2026-11-13, through the Blender MCP add-on's Sketchfab import, by Claude Code at
  the author's request (`docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #264-#265): the author asked for
  the plastic chair at bay 9's dock desk to be changed and chose a swivel office chair.
- **Chosen over:** a photo-scanned worn office chair (Mario_r_o_c_h_a), whose close-up surfaces
  were lumpy with reflections baked into its texture, and FordVFX's "Worn Leather Office Chair",
  an antique tub chair on wooden legs.
- **This folder** holds Blender's export of the imported model (`13_office_chair.glb`, with its
  textures), not the original Sketchfab archive: the add-on deletes its download. Its top node
  carries the size Claude Code set: the import came without a real scale, so it is sized by its
  seat, the cushion's top 0.47 m up (task chairs adjust over about 0.41-0.52 m), which makes its
  five-star base 0.69 x 0.66 m (real ones are about 0.64-0.70 m) and the chair 0.89 m tall, a
  mid-back task chair. It stands on the ground, centred on its gas lift, its front toward glTF's
  front.
- **Contents:** 9,454 faces in four materials (cloth, leather, metal and plastic), each with its
  own textures, larger than the game needs: reduced in its game file.
- **Branding:** None seen.
- **Game files:** `game/features/environments/industrial_loop/art/depot/office_chair.glb`, made by
  `tools/art/convert_depot_models.py -- office_chair` on 2026-11-13: 9,450 triangles, its textures
  halved to 1024 pixels and saved as JPEG.
- **Git:** `.gitignore` keeps these files out of Git; only this README is tracked.
