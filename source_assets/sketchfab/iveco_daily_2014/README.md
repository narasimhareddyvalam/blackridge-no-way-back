# Iveco Daily Van 2014: raw source (not in Git)

- **Model:** "Iveco Daily Van 2014",
  https://sketchfab.com/3d-models/iveco-daily-van-2014-30003fba5b074d6eb7bc74fd5e1e7d19
- **Author:** Max (Sketchfab `Max-7215`; Discord `max7215`).
- **Licence:** CC BY 4.0, plus the author's note: "This model is not free of rights. You must
  inform me of your usage." The Blackridge author told Max about this use on 2026-11-03,
  before the van files were committed, and Max acknowledged it with thanks.
- **Fetched:** 2026-11-01, through the Blender MCP add-on's Sketchfab import, by Claude Code at
  the author's request (`docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #83).
- **This folder** holds Blender's export of the imported model (glTF with separate textures,
  37 files, 260 MB), not the original Sketchfab archive. The add-on deletes its download, and
  Sketchfab's API refused a direct download.
  - **Top node:** it carries the real-size transform. Scale 0.758 gives a 1.996 m body width,
    the real Daily's, and the van stands on the ground.
- **Size:** 5.53 m long, 2.08 m tall, 2.0 m body width (2.49 m with mirrors), 3.50 m
  wheelbase, 0.72 m tyres. It is a Daily 35S L2H1.
- **Contents:** 22 meshes, 89,822 triangles, 12 materials with 4096-pixel PBR maps.
- **Branding:** raised IVECO letters on the grille and on the left rear door, the name painted
  in the textures behind them and on the steering-wheel badge, and a French plate ("MA-222-AX",
  with "DAILY" on its strip). The rear has no plate.
- **Game files:** `tools/art/convert_iveco.py` makes the van's game files in
  `game/features/vehicles/freight_van/art/iveco/` from this copy. It removes all of the
  branding above and puts on the "BR 048" plate (Run 23, step 2).
- **Git:** `.gitignore` keeps these files out of Git; only this README is tracked.
