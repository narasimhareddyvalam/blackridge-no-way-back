# Payphone: raw source (not in Git)

- **Model:** "Pay phone Scan MEDPOLY", https://sketchfab.com/models/8235545da48a4ceeb787f8a138b7a8f3
- **Author:** evan4129.
- **Licence:** CC BY 4.0 (Sketchfab's "CC Attribution"). The game credits the author.
- **Fetched:** 2026-11-14, through the Blender MCP add-on's Sketchfab import, by Claude Code at
  the author's request (`docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #267, #285): the gas station and
  main street on the south valley road.
- **Chosen over:** afsoft's wall-mounted payphone (no pedestal) and a British red payphone.
- **This folder** holds Blender's export of the imported model (`18_payphone.glb`, with its textures), not
  the original Sketchfab archive: the add-on deletes its download. Its top node carries the import's size: 2.0 m to the top of its rod.
- **Contents:** A photo scan of a US pedestal payphone, 25,466 faces in one material with 4096-pixel textures; graffiti on its hood.
- **Branding:** None readable but the graffiti.
- **Game files:** `game/features/environments/industrial_loop/art/town/payphone.glb`, made by
  `tools/art/convert_town_models.py -- payphone` on 2026-11-14.
- **Git:** `.gitignore` keeps these files out of Git; only this README is tracked.
