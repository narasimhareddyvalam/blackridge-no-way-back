# Iveco van attribution

The van in this folder is adapted from:

- **Title:** "Iveco Daily Van 2014"
- **Author:** Max (Sketchfab: Max-7215)
- **Source:** https://sketchfab.com/3d-models/iveco-daily-van-2014-30003fba5b074d6eb7bc74fd5e1e7d19
- **Licence:** Creative Commons Attribution 4.0 International,
  https://creativecommons.org/licenses/by/4.0/
- **The author's note on the model page:** "This model is not free of rights. You must inform me
  of your usage." The Blackridge author told Max about this use on 2026-11-03, before the van
  files were committed, and Max acknowledged it with thanks.

The IVECO name and badges are removed (below). Blackridge is not affiliated with Iveco.

## Changes

Claude Code made these changes on 2026-11-01 with `tools/art/convert_iveco.py`, at the author's
request (decision C31):

- **Size and direction:** real size (2.0 m body width, 5.53 m long), turned to face the game's
  forward direction (-Z), with the driver's seat on the left.
- **Removed:**
  - the raised IVECO letters on the grille and on the left rear door;
  - the van's own wipers, which the game replaces with its own.
- **Painted out** of the colour, gloss and bump maps: the IVECO name on the grille behind those
  letters, on the rear door, and on the steering-wheel badge, which is now plain.
- **Plates:** the model's French plate ("MA-222-AX", with "DAILY" on its strip) is replaced by
  the game's own "BR 048" plate (`tools/make_number_plate.py`), and the same plate is added on
  the rear door, which had none.
- **Split into parts:**
  - both front doors with their windows, on their hinges;
  - the four wheels, each on its centre;
  - the steering wheel, on its column;
  - the windshield glass, on its own;
  - the lamp lenses (headlights, tail lamps and the four indicators), apart from the clear
    glass, so the game can light them.
- **Moon roof:** an opening (1.04 × 0.44 m) is cut through the roof and the headliner over the
  front seats (decision C32); the game adds the glass and its frame.
- **Textures:** reduced from 4096 pixels to 2048 (outside) and 1024 (cab), as WebP.
- **Files:** `iveco_exterior.glb` and `iveco_cab.glb`, 88,428 triangles in all (the model has
  89,822).

## A second use: the oncoming van

The game also uses `iveco_exterior.glb` for the oncoming van that dazzles the player (decision
C33, Run 23 step 4): its paint textures are tinted dark grey in code, and a second plate,
"BR 731", is laid over its own front and rear. The files in this folder are not changed for it.
