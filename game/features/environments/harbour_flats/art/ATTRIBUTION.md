# The harbour flats: attribution

Mission 3's waterfront and airfield (#359-#360, `docs/PHASE_BRIEF.md`, revision of 2026-11-21 for
steps 3, 4 and 5). Each fetched through the Blender MCP add-on's Sketchfab import by Claude Code
on 2026-11-21, at the author's word to finish Mission 3 (#359); the raw files are in
`source_assets/sketchfab/30_harbour_crane/`, `31_suburban/` and `33_pc12/` (not in Git).

- `harbour_crane/harbour_crane.glb`: "Harbor crane" by TGVMisterH,
  https://sketchfab.com/3d-models/d4d582ebd707426f93f1f5a9cdd0ce03, licensed CC BY 4.0
  (https://creativecommons.org/licenses/by/4.0/). Changed: its emissive glow removed (it lit the
  whole crane white at night), textures without images dropped
  (`tools/assets/drop_sourceless_textures.py`), textures halved to 1024 pixels as WebP; placed on
  the apron by berth 2, its boom over the water (`waterfront.gd`). Credited in the game's credits
  ("THE HARBOUR").
- `suburban/suburban.glb`: "Chevrolet Suburban 2015-Unmarked" by David_Holiday,
  https://sketchfab.com/3d-models/b01950cf99aa48c1ba2ebd0addc8a9d4, licensed CC BY 4.0. Changed:
  repainted black, scaled to a Suburban's 5.7 m; the convoy's and the ambush's SUVs
  (`scripted_suv.gd`). Credited there. Blackridge is not affiliated with Chevrolet.
- `pc12/pc12.glb`: "Pilatus PC 12/47" by helijah,
  https://sketchfab.com/3d-models/d8ab7be8b9794910930e7919d0bf3f5a, licensed CC BY 4.0. Changed:
  repainted white as a private charter's, scaled to the real 16.28 m span, textures halved to
  1024 pixels as WebP; on the airfield's apron (`airfield.gd`). Credited there. Blackridge is not
  affiliated with Pilatus.
