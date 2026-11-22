# Euro pallet photoscanned: raw source (not in Git)

- **Model:** "Euro pallet photoscanned", https://sketchfab.com/3d-models/euro-pallet-photoscanned-84132ceb4323477292ccf22a349b9f9d
- **Author:** widthRider (Sketchfab `widthRider`).
- **Licence:** CC BY 4.0 (Sketchfab's "CC Attribution"). The game credits the author.
- **Fetched:** 2026-11-11, through the Blender MCP add-on's Sketchfab import, by Claude Code at
  the author's request (`docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #221-#222).
- **This folder** holds Blender's export of the imported model (`11_pallet.glb`, with its
  textures), not the original Sketchfab archive: the add-on deletes its download. Its top node
  carries the size and turn Claude Code set; the model stands on the ground, centred.
- **Size:** 0.87 x 1.20 x 0.19 m, laid flat (it came standing on its edge); a scanned Euro pallet, a little larger than the real 0.8 x 1.2 x 0.144 m.
- **Contents:** 42,662 faces. Its textures are larger than the game needs and are to be
  reduced in its game files.
- **Branding:** checked on 2026-11-11 at full size: no EPAL or EUR stamp on its blocks.
- **Game files:** `game/features/environments/industrial_loop/art/depot/pallet.glb`, made by
  `tools/art/convert_depot_models.py` on 2026-11-11: sized as the American 48 x 40 in pallet
  (1.219 x 1.016 x 0.15 m), since the game is set in an American town; reduced to 3,000
  triangles; its wood matte; its textures halved to 1024 pixels and saved as JPEG.
- **Git:** `.gitignore` keeps these files out of Git; only this README is tracked.
