# Fairheaven LT '80 - Low poly model: raw source (not in Git)

- **Model:** "Fairheaven LT '80 - Low poly model", https://sketchfab.com/3d-models/fairheaven-lt-80-low-poly-model-e2678da920cc4be68dbc193727919ffb
- **Author:** Daniel Zhabotinsky (Sketchfab `DanielZhabotinsky`).
- **Licence:** CC BY 4.0 (Sketchfab's "CC Attribution"), plus the author's note: "I unconditionally give you permission to use this model at your discretion, modify it or implement it into a digital product.". The game credits the author.
- **Fetched:** 2026-11-11, through the Blender MCP add-on's Sketchfab import, by Claude Code at
  the author's request (`docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #221-#222).
- **This folder** holds Blender's export of the imported model (`07_sedan_fairheaven.glb`, with its
  textures), not the original Sketchfab archive: the add-on deletes its download. Its top node
  carries the size and turn Claude Code set; the model stands on the ground, centred.
- **Size:** 1.83 x 5.00 x 1.35 m at the source's own scale, a generic early-1980s American sedan.
- **Contents:** 19,703 faces. Its textures are larger than the game needs and are to be
  reduced in its game files.
- **Branding:** The author's own made-up "Fairheaven" badges and number plates; the plates are to be replaced.
- **Game files:** `game/features/environments/industrial_loop/art/town/sedan.glb`, made by
  `tools/art/convert_town_models.py -- sedan` on 2026-11-14 (11,350 triangles), parked on main
  street (#267, part C); its plates kept, the author's own made-up ones.
- **Git:** `.gitignore` keeps these files out of Git; only this README is tracked.
