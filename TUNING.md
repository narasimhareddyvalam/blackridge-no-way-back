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

## r1: applied at the author's direction

After the options page, the author asked (#146): "make them more realistic. i want the bigger
droplets effect even under no lights in normal when driving. make everything realistic as fuck
as if its a real world game". So r1 departs from the loop above in three ways:

- It was applied before the author captured r0, on the author's request rather than on an
  approved prediction. The predictions below were written before the author's r1 capture.
- Each effect's r1 changes several settings, not one; each section lists them.
- It stays uncommitted until the author's verdicts, as the handout asks. The working tree holds
  r1, and commit `4f73f98` holds r0. `tools/tuning/r1/r1.patch` is a copy of the change, which
  `git apply` restores if the working tree is lost. The first r1 proposal, superseded, is in
  `tools/tuning/r1/` at commit `bf962da`.

All four effects now draw with one particle shader, `game/effects/scatter_particle.gdshader`
(an effect resource, not one of the hand-written shaders in `game/shaders/`):
- **forward scattering:** light from behind a drop or puff scatters on toward the eye, as it does
  through real droplets (a Henyey–Greenstein phase: `forward_scatter` is its g, `scatter` its
  strength), with a little matt shading (`diffuse`);
- **water as a lens** (A1, A2): each drop shows the scene behind it, bent and inverted, blurred by
  `lens_blur`, with a darker rim (`rim_dark`); where the bent view would show something nearer
  than the drop, it shows what is straight behind it instead (`refraction` sets how far it bends);
- **the night sky at the rim** (`sky`, in the windshield's sky colour), so a drop reads on an
  unlit road;
- **a glint**, a point of a lamp's light on a bead (`glint`);
- **a minimum width** (`min_pixels`): a particle thinner than that on screen is drawn that wide
  and made fainter by the same factor, so it gains no light.

**Capturing (the author):**
- r0, from the pre-tuning commit, in a temporary checkout that the script imports and removes:
  `FROM=4f73f98 scripts/capture-strips.sh 0`
- r1, from the working tree: `scripts/capture-strips.sh 1`
- A1 at speed and in the depot, for both rounds:
  `FROM=4f73f98 scripts/capture-strips.sh 0 wiper_flick:speed_kmh=50 wiper_flick:place=depot`
  and `scripts/capture-strips.sh 1 wiper_flick:speed_kmh=50 wiper_flick:place=depot`

Claude Code rendered the r1 previews once in its scratch folder before writing the predictions
below. The previews use fixed seeds, so the author's r1 strips should match those renders frame
for frame; a difference would mean the build or the machine differs.

**Tests with r1:** every suite passes: 30 runs and the art check
(`logs/particles/realistic/SUMMARY.txt`). The configuration tests read the new values, including
each shader parameter (which must be one of the shader's uniforms), and the A1 state test adds
the glass collider, the air's push and freeing the van.

## Effect A1 (wiper flick), revision r1

- **What I saw (running game, 1280×800):** _the author, in visual terms._ The author's messages
  of 2026-11-07: "make sure its clearly visible like in real world. all the four effects!" (#144)
  and "i want the bigger droplets effect even under no lights in normal when driving" (#146).
- **Claude's reading of r0:** _to be written from `captures/wiper_flick/r0/` once the author has
  captured it._ Claude Code's own render of the same preview showed no flick at the blade tip
  on any frame: the beads are 3–7 mm, 1–2 px at about 1.2 m, and lit only by the night.
- **Change (applied at the author's direction, #146):**
  - the quads' material, `BigDrops` and `FineSpray`: `StandardMaterial3D` → the shared
    `ShaderMaterial`: `forward_scatter` 0.85, `scatter` 10, `diffuse` 0.3; `refraction` 0.45,
    `lens_blur` 1.5, `rim_dark` 0.3; `sky` 4 and 2; `glint` 1 on `BigDrops`; `min_pixels` 2
    and 1;
  - bigger drops: `scale` 0.3–0.7 → 0.8–1.5 (8–15 mm beads) and 0.15–0.3 → 0.5–1.0 (5–10 mm
    mist);
  - more drops: `amount` 22 → 80 and 36 → 120;
  - simulated with the van: `local_coords` false → true, so the drops leave the blade at the
    van's speed instead of being left behind; each burst is placed at the blade tip in the van
    body's frame;
  - the air over the glass: each physics tick, `van_particles.gd` sets each emitter's gravity to
    the still air's, turned into the van's frame, plus a push up the glass of g × (v / vₜ)², where
    v is the van's forward speed and vₜ 8 m/s for the beads and 3 m/s for the mist, up to 40
    and 80 m/s²; none when parked or reversing;
  - a collider on the glass: a `GPUParticlesCollisionBox3D` the size of the windshield
    (1.77 × 1.0 m, 2 m deep into the cab), its face 4 cm behind the glass, with
    `collision_mode = COLLISION_HIDE_ON_CONTACT` and `collision_base_size` 0.01 on both
    emitters, so a drop that falls back onto the glass joins its water instead of passing into
    the cab.

  The texture, colour, alpha and size curves, speeds, directions and lifetimes stay as they are.
- **Rules that change with it, for the brief revision if kept:** freeing the van now frees its
  bursts with it, as A2's revision 3 did for the spill; and §9's answer 2 changes for A1.
- **Claude's prediction for r1:**
  - Valley road, parked (`scripts/capture-strips.sh 1`):
    - frame 10: nothing new at the blade tip. The burst fires at the end of frame 10 and shows
      from frame 11; r0 has the same lag.
    - frame 12: a few dozen clear beads, about 5–10 px across, around the blade tip in the upper
      left of the glass by the pillar. Each shows the dark forest through it, bent, with a thin
      pale-blue rim. They move left toward the pillar.
    - frame 15: only a few faint specks remain. The beads that fell back onto the glass stopped
      on the collider, and the rest passed behind the pillar.
    - frames 20, 30 and 50: none.
  - At 50 km/h (`wiper_flick:speed_kmh=50`):
    - frame 10: nothing yet;
    - frame 12: the beads have been blown up and back along the glass toward its top-left
      corner, larger and clearer than when parked;
    - frame 15: one or two at the top edge; frame 20: none.
  - Depot (`wiper_flick:place=depot`):
    - frame 12: the same cluster, with the lit depot wall seen through each bead and warm
      highlights;
    - frame 15: one or two specks; frame 20: none.
  - **Against the brief:** the beads are 5–10 px, not 2–5 px, because the author asked for
    bigger drops. The flick lasts about 0.1–0.15 s, much shorter than §2's timing phases (big
    drops falling until 0.65 s, mist until 1.20 s), because of the collider and the pillar.
    The author's verdict in the game decides whether that reads as real.
- **Claude's comparison of r1 with its prediction:** _after the author's r1 capture._
- **My verdict (running game, 1280×800):** _the author: kept | reverted, because…_
- **Strips:** `captures/wiper_flick/r0/`, `captures/wiper_flick/r1/`, and the `speed_kmh-50`
  and `place-depot` variants
- **Commits:** _when kept._

## Effect A2 (roof spill), revision r1

- **What I saw (running game, 1280×800):** _the author._ (#144 and #146, as for A1.)
- **Claude's reading of r0:** _from `captures/roof_spill/r0/`._ Claude Code's render showed no
  spill on any frame: the roof lip is above the driver's view, and the streams on the glass
  were too dark to see.
- **Change (applied at the author's direction, #146):**
  - the quads' material, `RoofStreams` and `RoofBeads`: `StandardMaterial3D` → the shared
    `ShaderMaterial`: `forward_scatter` 0.85, `scatter` 6, `diffuse` 0.3; `refraction` 0.3,
    `lens_blur` 1, `rim_dark` 0.35; `sky` 2; `glint` 1 on `RoofBeads`; `min_pixels` 1.2;
  - `RoofStreams`: `amount` 32 → 96, and its quad 0.01 → 0.03 m, so the streams are three times
    as long and wide (36–84 mm);
  - `RoofBeads`: `amount` 48 → 120, and `scale` 0.3–0.9 → 0.5–1.2 (5–12 mm).

  The streams stay turned along their motion by `transform_align`; the beads face the camera.
- **Claude's prediction for r1** (office approach; the hard brake comes on frame 10):
  - frame 10: nothing yet;
  - frame 12: the first few pale drops at the top edge of the glass;
  - frame 15: pale streams tipping over the top of the glass, upper middle and right;
  - frame 20: a broken sheet of pale streams and beads across the middle and right of the
    glass, with the office, road and trees still seen between them;
  - frame 30: a few beads low on the right; frame 50: none.
- **Claude's comparison of r1 with its prediction:** _after r1._
- **My verdict (running game, 1280×800):** _the author._
- **Strips:** `captures/roof_spill/r0/`, `captures/roof_spill/r1/`
- **Commits:** _when kept._

## Effect B1 (lamp rain), revision r1

- **What I saw (running game, 1280×800):** _the author._ (#144 and #146.)
- **Claude's reading of r0:** _from `captures/lamp_rain/r0/`._ Claude Code's render showed no
  rain under the lamp on any frame.
  - The valley lamp is an omni light of energy 3 with a steep falloff, bright only within a
    couple of metres of its head.
  - A camera-facing streak lit from above takes almost no matt light.
- **Change (applied at the author's direction, #146):** the quads' material, `LampRain` and
  `LampSplash`, in all three scenes: `StandardMaterial3D` → the shared `ShaderMaterial`:
  `forward_scatter` 0.8, `scatter` 100 (the strongest of the three on the options page),
  `diffuse` 0.5; no `sky`, `glint` or `refraction`; `min_pixels` 2 (`LampRain`) and 1.5
  (`LampSplash`). With no lamp, the streaks still draw nothing.
- **Claude's prediction for r1** (the valley post lamp at (−15, 63.8)):
  - frames 10 and 12: no rain yet: `restart()` with preprocess takes effect three frames late
    (a fixture finding, `TEST-REPORT.md`);
  - frames 20–70: thin pale streaks falling around the lamp head and down beside the post,
    brightest within a couple of metres of the head, with a few splash specks on the lit ground
    under it;
  - frame 85: only a few lower streaks; frame 110: empty.
  - Away from the head the rain stays faint: the lamp's own light is small, and the brief
    forbids changing lamps to show particles (§6). If the author wants more, the next single
    change would raise `scatter` (its range goes to 200), or lower `forward_scatter` so that
    drops beside the lamp catch more of its light.
- **Claude's comparison of r1 with its prediction:** _after r1._
- **My verdict (running game, 1280×800):** _the author._
- **Strips:** `captures/lamp_rain/r0/`, `captures/lamp_rain/r1/`
- **Commits:** _when kept._

## Effect B2 (exhaust vapour), revision r1

- **What I saw (running game, 1280×800):** _the author._ (#144 and #146.)
- **Claude's reading of r0:** _from `captures/exhaust_vapour/r0/`._ Claude Code's render
  showed no vapour behind the van on any frame:
  - the van shades the plume from the floodlight;
  - the tail lamps light it from behind, which a matt material hardly passes.
- **Change (applied at the author's direction, #146):**
  - the quad's material, `ExhaustPlume`: `StandardMaterial3D` → the shared `ShaderMaterial`:
    `forward_scatter` 0.7, `scatter` 0.6, `diffuse` 0.3; no `sky`, `glint`, `refraction` or
    minimum width;
  - a denser plume: `amount` 96 → 300, still fixed; `amount_ratio` still runs 0.15–0.80 of it;
  - bigger puffs: `scale` 1.2–2.2 → 2.4–3.6 (24–36 cm, growing 2.5× over their life).
- **Rule that changes with it, for the brief revision if kept:** §5's "Keep `amount = 96` fixed
  at all times" becomes 300; `test_exhaust_vapour_state.gd` checks it.
- **Claude's prediction for r1** (site office, rear view; ignition on frame 9):
  - frames 10, 20 and 30: no vapour yet (the 0.4 s wait, then the ramp);
  - frame 40: a faint red haze at the tailpipe, lit by the tail lamps;
  - frame 55: a soft red-lit cloud behind the van as it pulls away at full throttle;
  - frame 80: the cloud glowing bright red in the brake lamps;
  - frame 100: the van 3.4 m on, engine off; the vapour left behind in the world, pale grey in
    the floodlight;
  - frame 130: a faint grey remnant; frame 180: none.
- **Claude's comparison of r1 with its prediction:** _after r1._
- **My verdict (running game, 1280×800):** _the author._
- **Strips:** `captures/exhaust_vapour/r0/`, `captures/exhaust_vapour/r1/`
- **Commits:** _when kept._
