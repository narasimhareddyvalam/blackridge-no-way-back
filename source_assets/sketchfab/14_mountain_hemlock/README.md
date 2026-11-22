# Mountain hemlock: raw source (not in Git)

- **Model:** "Realistic HD Mountain hemlock (21/43)", https://sketchfab.com/models/225cd2dfbf7d4163bc3a062a0c0623aa
- **Author:** PlantCatalog (Sketchfab `PlantCatalog`).
- **Licence:** CC BY 4.0 (Sketchfab's "CC Attribution"). The game credits the author.
- **Fetched:** 2026-11-14, through the Blender MCP add-on's Sketchfab import, by Claude Code at
  the author's request (`docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #280, #285): the author chose a
  Pacific Northwest forest with real models near the road.
- **Chosen over:** the series' heavier versions (56,000-193,000 faces); no western hemlock, Douglas fir or western red cedar is in the series.
- **This folder** holds Blender's export of the imported model (`14_mountain_hemlock.glb`, with its textures), not
  the original Sketchfab archive: the add-on deletes its download. Its top node carries the import's size: 22 m tall (the add-on's target; second-growth hemlocks reach 20-35 m).
- **Contents:** 19,316 faces in nine materials: foliage cards, branches, dead branches, trunk and cut ends, each with its own base colour and normal map.
- **Branding:** None.
- **Game files:** `game/features/environments/industrial_loop/art/trees/mountain_hemlock.glb`, made by
  `tools/art/convert_roadside_trees.py -- mountain_hemlock` on 2026-11-14.
- **Git:** `.gitignore` keeps these files out of Git; only this README is tracked.
