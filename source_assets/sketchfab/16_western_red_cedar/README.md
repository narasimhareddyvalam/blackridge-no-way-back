# Western red cedar: raw source (not in Git)

- **Model:** "Western Red Cedar *Inspired* Tree - WINTER Ver.", https://sketchfab.com/models/fdd3274350144d8abe119d8a73cdce34
- **Author:** SirSonat.
- **Licence:** CC BY 4.0 (Sketchfab's "CC Attribution"). The game credits the author.
- **Fetched:** 2026-11-14, through the Blender MCP add-on's Sketchfab import, by Claude Code at
  the author's request (`docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #280, #285): the author chose a
  Pacific Northwest forest with real models near the road.
- **Chosen over:** the same tree's spring version, the stylised "Stylized Cedar trees" (mandrake_3d), and cedars of Lebanon, not a Pacific Northwest tree.
- **This folder** holds Blender's export of the imported model (`16_western_red_cedar.glb`, with its textures), not
  the original Sketchfab archive: the add-on deletes its download. Its top node carries the import's size: 24 m from its lowest root.
- **Contents:** A trunk (22,322 faces), foliage (5,960) and a clump of mushrooms at its foot (19,752), each with 4096-pixel textures; the mushrooms are left out of the game.
- **Branding:** None.
- **Game files:** `game/features/environments/industrial_loop/art/trees/western_red_cedar.glb`, made by
  `tools/art/convert_roadside_trees.py -- western_red_cedar` on 2026-11-14.
- **Git:** `.gitignore` keeps these files out of Git; only this README is tracked.
