# Warehouse Forklift Gameready: raw source (not in Git)

- **Model:** "Warehouse Forklift Gameready", https://sketchfab.com/3d-models/warehouse-forklift-gameready-94e21059f00c4e989c6403ada034516e
- **Author:** Kamran Mughal (Sketchfab `absologixemployee`).
- **Licence:** CC BY 4.0 (Sketchfab's "CC Attribution"). The game credits the author.
- **Fetched:** 2026-11-11, through the Blender MCP add-on's Sketchfab import, by Claude Code at
  the author's request (`docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #221-#222).
- **This folder** holds Blender's export of the imported model (`09_forklift.glb`, with its
  textures), not the original Sketchfab archive: the add-on deletes its download. Its top node
  carries the size and turn Claude Code set; the model stands on the ground, centred.
- **Size:** 1.12 x 3.30 x 2.21 m (scaled to 3.3 m long with its forks).
- **Contents:** 7,786 faces. Its textures are larger than the game needs and are to be
  reduced in its game files.
- **Branding:** its body carries the lettering "SQUIRE" and "e-TL2" and an S mark. A web
  search on 2026-11-11 found no forklift maker of that name, so it reads as the modeller's
  own invented make; no real maker's name or logo was seen.
- **Game files:** `game/features/environments/industrial_loop/art/depot/forklift.glb`, made
  by `tools/art/convert_depot_models.py` on 2026-11-11: 7,786 triangles as made, its specular
  map left out, its textures halved to 1024 pixels and saved as JPEG.
- **Git:** `.gitignore` keeps these files out of Git; only this README is tracked.
