# Gas pump: raw source (not in Git)

- **Model:** "Gas pump", https://sketchfab.com/models/7fcc112afa0440fd8d286dda2ba3ef96
- **Author:** SavinienBerault.
- **Licence:** CC BY 4.0 (Sketchfab's "CC Attribution"). The game credits the author.
- **Fetched:** 2026-11-14, through the Blender MCP add-on's Sketchfab import, by Claude Code at
  the author's request (`docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #267, #285): the gas station and
  main street on the south valley road.
- **Chosen over:** "Shell Self-Service Gas Pump" (a real brand on it), stylised station kits (Meet_Savani, amirchyk) and vintage pumps carrying real brands (Texaco's Fire-Chief); no modern multi-product dispenser was found.
- **This folder** holds Blender's export of the imported model (`17_gas_pump.glb`, with its textures), not
  the original Sketchfab archive: the add-on deletes its download. Its top node carries the import's size: 1.9 m tall.
- **Contents:** 7,287 faces in four materials: the body and its lit, unlit and white display lights.
- **Branding:** None: its labels read REGULAR, DIESEL and RUNNING.
- **Game files:** `game/features/environments/industrial_loop/art/town/gas_pump.glb`, made by
  `tools/art/convert_town_models.py -- gas_pump` on 2026-11-14.
- **Git:** `.gitignore` keeps these files out of Git; only this README is tracked.
