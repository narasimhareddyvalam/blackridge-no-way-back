# Pallet Jack: raw source (not in Git)

- **Model:** "Pallet Jack", https://sketchfab.com/3d-models/pallet-jack-eccf1ee2e5d64743a7b4be69acfc734f
- **Author:** FFeller (Sketchfab `FFeller`).
- **Licence:** CC BY 4.0 (Sketchfab's "CC Attribution"), plus the author's note: "If you use it in a game or in a video it is royalty free, if you make some changes and reupload it, please give me credit.". The game credits the author.
- **Fetched:** 2026-11-11, through the Blender MCP add-on's Sketchfab import, by Claude Code at
  the author's request (`docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #221-#222).
- **This folder** holds Blender's export of the imported model (`10_pallet_jack.glb`, with its
  textures), not the original Sketchfab archive: the add-on deletes its download. Its top node
  carries the size and turn Claude Code set; the model stands on the ground, centred.
- **Size:** 0.78 x 1.60 x 1.21 m (scaled to 1.6 m long).
- **Contents:** 6,450 faces. Its textures are larger than the game needs and are to be
  reduced in its game files.
- **Branding:** None seen.
- **Game files:** `game/features/environments/industrial_loop/art/depot/pallet_jack.glb`,
  made by `tools/art/convert_depot_models.py` on 2026-11-11: 6,450 triangles as made, its
  textures halved to 1024 pixels and saved as JPEG. On 2026-11-12 (step 2f, #244) the same job
  cut it into three meshes as a real jack moves: `Chassis` (the frame and forks), `Steering`
  (the pump and its twin wheels, turning on the pump's vertical axis 0.689 m behind the middle)
  and `Tiller` (the shaft, loop and lever, hinged inside the steering unit at the shaft's foot,
  0.30 m up). The game credits FFeller for the model and this change.
- **Git:** `.gitignore` keeps these files out of Git; only this README is tracked.
