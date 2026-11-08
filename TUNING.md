# TUNING.md: Assignment 6 tuning record

Each revision follows the handout's loop:

1. The author captures a strip: `scripts/capture-strips.sh <round>`.
2. Claude Code reads it and proposes one change, with a prediction for each frame.
3. The author approves. Claude Code makes only that change and its configuration test's
   expected value, and runs the test.
4. The author recaptures. Claude Code compares the new strip with its prediction.
5. The author judges the change in the running game at 1280×800, keeps or reverts it, and
   records a dated revision in `CHANGE-BRIEF.md` if it is kept.

**About the strips:**
- They are fixture captures from the preview scenes in `game/previews/`, rendered by Movie
  Maker at 1280×800 and 30 fps. Frame numbers count from 0, as Movie Maker numbers its files.
- Each strip folder holds the preview's own event log (`events.txt`), which says on which frame
  each event happened.
- The frames read are the brief's:
  - A1 and A2: 10, 12, 15, 20, 30 and 50; with retrigger on, A1 adds 37, 40 and 45, and A2
    adds 25.
  - B1: 10, 12, 20, 30, 50, 70, 85 and 110.
  - B2: 10, 20, 30, 40, 55, 80, 100, 130 and 180.

Claude Code's reading of a strip is a claim. Where the author's verdict in the running game
differs, the verdict decides, and the disagreement is written here.

## Before the first strip: build fixes, not tuning

Claude Code's own windowed checks of the previews (renders kept in its scratch folder, not
strips) found two places where the build did not match the brief. Both were fixed before r0,
so r0 shows the brief as designed:

- **Revision 4:** camera-facing particles dropped their own scale, because
  `billboard_keep_scale` was off. Every size the brief gives A1's beads and mist, A2's beads,
  B1's splashes and B2's puffs had no effect.
- **Revision 5:** B1's streak texture drew its line across only a quarter of the quad, so the
  streaks were 2–4 mm wide instead of the brief's 7–14 mm.

The same checks showed that every effect fires on its frame and draws where it should: drawn
solid red for one check, each appeared at the blade tip, the roof lip, the lamp and the
tailpipe. With their real materials they could hardly be seen at night (below).

The options were shown to the author side by side, from Claude Code's own test renders, on a
private page: https://claude.ai/artifact/3e4vVuGdFm9fBS5TndPFRZ.

The r1 patch and its shader wait in `tools/tuning/r1/` until the author approves; applying it
changes the effect scenes, `particle_readback.gd` and the four configuration tests.

## Effect A1 (wiper flick), revision r1

- **What I saw (running game, 1280×800):** _the author, in visual terms._ The author's message
  of 2026-11-07 (#144): "make sure its clearly visible like in real world. all the four
  effects!"
- **Claude's reading of r0:** _to be written from `captures/wiper_flick/r0/` once the author has
  captured it._ Claude Code's own render of the same preview showed no flick at the blade tip
  on any frame: the beads are 3–7 mm, 1–2 px at about 1.2 m, and lit only by the night.
- **Change (proposed, awaiting the author's approval):** the quads' material, `BigDrops` and
  `FineSpray`: `StandardMaterial3D` → a `ShaderMaterial` running
  `game/effects/scatter_particle.gdshader`. This is one setting, the quad's material, but the
  new material differs from the old in more than one way:
  - light that reaches a drop from behind scatters forward toward the eye, as it does through
    real droplets (Henyey–Greenstein, `forward_scatter` 0.85, `scatter` 10);
  - a little matt shading stays (`diffuse` 0.3);
  - each bead shows the night sky in its lower half, as the windshield's own drops do
    (`sky` 2 on `BigDrops`, 1 on `FineSpray`, the windshield's sky colour);
  - a bead catches a point of light from a lamp (`glint` 1, `BigDrops` only);
  - no drop is drawn under 1.5 px (`BigDrops`) or 1 px (`FineSpray`) wide; it is made fainter by
    the same factor, so a far drop does not gain light.

  The texture, colour, alpha and size curves, the camera facing and the size stay as they are.
- **Claude's prediction for r1:**
  - Valley road: frames 10–15 show a faint cluster of pale blue-grey specks at the driver's
    blade tip, upper left of the glass by the pillar, moving left and down, most of them 1–2 px.
    It is still hard to see against the unlit forest, because the drops are small. Frame 20
    shows a few specks, and frames 30 and 50 none.
  - Depot (`place=depot`): frames 10–15 show only faint specks at the blade tip. Corrected on
    2026-11-07, before any change was applied: Claude Code's first prediction said a clear
    spray, but its own render showed one only with larger drops.
  - A1 will need larger drops to be clearly visible on the unlit road: the next revision.
- **Claude's comparison of r1 with its prediction:** _after the author's r1 capture._
- **My verdict (running game, 1280×800):** _the author: kept | reverted, because…_
- **Strips:** `captures/wiper_flick/r0/`, `captures/wiper_flick/r1/`
- **Commits:** _when kept._

## Effect A2 (roof spill), revision r1

- **What I saw (running game, 1280×800):** _the author._ (#144, as for A1.)
- **Claude's reading of r0:** _from `captures/roof_spill/r0/`._ Claude Code's render showed no
  spill on any frame: the roof lip is above the driver's view, and the streams on the glass
  were too dark to see.
- **Change (proposed, awaiting the author's approval):** the quads' material, `RoofStreams` and
  `RoofBeads`: `StandardMaterial3D` → the same `ShaderMaterial`, with:
  - `forward_scatter` 0.85, `scatter` 6 and `diffuse` 0.3;
  - `sky` 1;
  - `glint` 1 on `RoofBeads`;
  - nothing drawn under 1.2 px.

  The streams stay turned along their motion by `transform_align`; the beads face the camera.
- **Claude's prediction for r1:**
  - Office approach: frames 10 and 12 show no water yet, because the lip is above the view.
  - Frames 15 and 20 show pale streams and beads sliding down the upper middle of the glass,
    lit by the office floodlight ahead.
  - Frame 30 shows a few beads lower on the glass, and frame 50 none.
- **Claude's comparison of r1 with its prediction:** _after r1._
- **My verdict (running game, 1280×800):** _the author._
- **Strips:** `captures/roof_spill/r0/`, `captures/roof_spill/r1/`
- **Commits:** _when kept._

## Effect B1 (lamp rain), revision r1

- **What I saw (running game, 1280×800):** _the author._ (#144.)
- **Claude's reading of r0:** _from `captures/lamp_rain/r0/`._ Claude Code's render showed no
  rain under the lamp on any frame.
  - The valley lamp is an omni light of energy 3 with a steep falloff, bright only within a
    couple of metres of its head.
  - A camera-facing streak lit from above takes almost no matt light.
- **Change (proposed, awaiting the author's approval):** the quads' material, `LampRain` and
  `LampSplash`, in all three scenes: `StandardMaterial3D` → the same `ShaderMaterial`, with:
  - `forward_scatter` 0.8, `scatter` 100 and `diffuse` 0.5;
  - no `sky` and no `glint`;
  - nothing drawn under 2 px (`LampRain`) or 1.5 px (`LampSplash`).

  `scatter` is high because these lamps are dim; with no lamp the streaks still draw nothing.
- **Claude's prediction for r1:**
  - Frames 10 and 12 show no rain yet: `restart()` with preprocess takes effect three frames
    late (a fixture finding, `TEST-REPORT.md`).
  - From frame 13, thin pale streaks fall through the lamp's light from the head to the ground,
    brightest near the head, with splash specks on the lit ground.
  - Frames 20–70 hold steady. Frame 85 shows only the lower streaks, and frame 110 is empty.
- **Claude's comparison of r1 with its prediction:** _after r1._
- **My verdict (running game, 1280×800):** _the author._
- **Strips:** `captures/lamp_rain/r0/`, `captures/lamp_rain/r1/`
- **Commits:** _when kept._

## Effect B2 (exhaust vapour), revision r1

- **What I saw (running game, 1280×800):** _the author._ (#144.)
- **Claude's reading of r0:** _from `captures/exhaust_vapour/r0/`._ Claude Code's render
  showed no vapour behind the van on any frame:
  - the van shades the plume from the floodlight;
  - the tail lamps light it from behind, which a matt material hardly passes.
- **Change (proposed, awaiting the author's approval):** the quad's material, `ExhaustPlume`:
  `StandardMaterial3D` → the same `ShaderMaterial`, with:
  - `forward_scatter` 0.7, `scatter` 1 and `diffuse` 0.3;
  - no `sky`, no `glint` and no minimum width.
- **Claude's prediction for r1:**
  - Frames 10–30 show no vapour: the engine starts on 10 and the plume waits 0.4 s.
  - Frame 40 shows a faint red puff behind the tailpipe, lit by the tail lamps.
  - Frame 55 shows a few glowing red puffs trailing as the van pulls away.
  - Frame 80, braking, shows the puffs brighter red.
  - Frame 100 is the engine off, and frames 130–180 show the last puffs fading.
  - The plume will read as separate round puffs rather than a continuous cloud, and it is
    smaller than the brief's 0.5–0.8 m: the next revision.
- **Claude's comparison of r1 with its prediction:** _after r1._
- **My verdict (running game, 1280×800):** _the author._
- **Strips:** `captures/exhaust_vapour/r0/`, `captures/exhaust_vapour/r1/`
- **Commits:** _when kept._
