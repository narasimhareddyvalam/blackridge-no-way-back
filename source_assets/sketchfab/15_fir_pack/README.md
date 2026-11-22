# Realistic fir trees pack: raw source (not in Git)

- **Model:** "Realistic fir trees pack (LODS, gameready)", https://sketchfab.com/models/f58e8b6d733e4b0586e5b7db847b89e7
- **Author:** lolipop_1707.
- **Licence:** CC BY 4.0 (Sketchfab's "CC Attribution"). The game credits the author.
- **Fetched:** 2026-11-14, through the Blender MCP add-on's Sketchfab import, by Claude Code at
  the author's request (`docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #280, #285): the author chose a
  Pacific Northwest forest with real models near the road.
- **Chosen over:** rhcreations' "Douglas Fir Tree" (2,211 faces of coarse cards) and stylised or low-poly firs.
- **This folder** holds Blender's export of the imported model (`15_fir_pack.glb`, with its textures), not
  the original Sketchfab archive: the add-on deletes its download. Its top node carries the import's size: the pack's nine trees spread over 40 m, the largest 9.7 m tall.
- **Contents:** Nine young firs, each with four levels of detail (LOD0 6,000-13,000 faces to a 20-face billboard), in bark and branch materials.
- **Branding:** None.
- **Game files:** `game/features/environments/industrial_loop/art/trees/young_firs.glb`, made by
  `tools/art/convert_roadside_trees.py -- young_firs` on 2026-11-14.
- **Git:** `.gitignore` keeps these files out of Git; only this README is tracked.
