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
as if its a real world game". Then, for the wiper flick and the roof spill, the author asked for
ideas to choose from (#147) and chose seven of the eight offered. No strip had been captured yet,
so A1's and A2's r1 were extended with them rather than starting an r2. So r1 departs from the
loop above in three ways:

- It was applied before the author captured r0, on the author's requests rather than on an
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
- **water drawn like the windshield's own drops** (A1, A2; `rain_drops.gdshaderinc`): the sky
  fills each drop's lower half (`sky`, in the windshield's sky colour), a catch light comes from
  the same fixed direction (`catch_light`), and the drop shows the scene behind it shifted by a
  few pixels (`refraction`), blurred (`lens_blur`) and darker at its rim (`rim_dark`); where the
  shifted view would show something nearer than the drop, it shows what is straight behind it;
- **a comet** (A1, A2): a drop turned along its motion draws as a round head with a tail behind it
  (`tail` is the tail's strength); while the drop is still a thread, the tail is as bright as the
  head (`thread_life`, a share of its life);
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

Claude Code rendered the r1 previews in its scratch folder before writing the predictions
below. Each preview fixes the seeds of its effect's own particles, and two renders of one build
matched in the effects (A1's frames within 8 of 255 levels everywhere; B1's and B2's effects
the same). The game's own rain is not seeded, so its streaks differ a little from run to run.
The author's r1 strips should show the same effects as those renders; a difference in an
effect would mean the build or the machine differs.

**Tests with r1:** every suite passes: 30 runs and the art check
(`logs/particles/realistic_r1b/SUMMARY.txt`). The configuration tests read the new values,
including each shader parameter (which must be one of the shader's uniforms) and each per-axis
curve, and check that no A emitter uses a sub-emitter, turbulence or a driven `amount_ratio`, the
features the B effects are graded on (the author's decision, #147). The A1 state test adds the
glass colliders, the air's push, the run-off at speed, the spill's water and freeing the van; the
A2 state test adds the water's surge as the van slows.

## Effect A1 (wiper flick), revision r1

- **What I saw (running game, 1280×800):** _the author, in visual terms._ The author's messages
  of 2026-11-07: "make sure its clearly visible like in real world. all the four effects!" (#144),
  "i want the bigger droplets effect even under no lights in normal when driving" (#146), and
  "make wiper flick and roof spill more realistic" (#147).
- **Claude's reading of r0:** _to be written from `captures/wiper_flick/r0/` once the author has
  captured it._ Claude Code's own render of the same preview showed no flick at the blade tip
  on any frame: the beads are 3–7 mm, 1–2 px at about 1.2 m, and lit only by the night.
- **Change (applied at the author's direction, #146 and #147):**
  - the quads' material: `StandardMaterial3D` → the shared `ShaderMaterial`, drawn like the
    windshield's drops: `sky` 2, `catch_light` 1, `refraction` 0.012, `lens_blur` 0.6,
    `rim_dark` 0.4; `forward_scatter` 0.85, `scatter` 10, `diffuse` 0.3; `glint` 1 on the beads;
    the mist (`FineSpray`) at `sky` 1.2, `catch_light` 0.5, `refraction` 0.006;
  - threads that snap into beads: each bead is drawn as a comet turned along its motion
    (`transform_align` Z-billboard, Y to velocity; `tail` 0.35); it is born twice as long and 0.8
    as wide, and is round by 8% of its life (a per-axis `scale_curve`), its tail as bright as its
    head while it is a thread (`thread_life` 0.1); a fast drop draws as the streak a 1/60 s
    glimpse of it would show, 26 times its width at 6 m/s (`scale_over_velocity`);
  - real drop sizes: beads 2.5–5.5 mm (`scale` 0.3–0.7 → 0.25–0.55), mist 0.5–1 mm
    (0.15–0.3 → 0.05–0.1), drawn at least 2 px and 1 px wide;
  - more water: 120 beads and 120 mist droplets a burst (22 and 36);
  - where it leaves: the outer half of the blade's leading edge, a box 9 × 26 cm beside it, at
    0.2–2.6 m/s toward the pillar and a little off the glass;
  - simulated with the van (`local_coords` on): each burst is set at the blade tip, turned to the
    windshield's frame, and its directions and boxes are in that frame;
  - the air over the glass, set by the van's code each tick: a push up the glass of g × (v / vₜ)²,
    with v the van's forward speed and vₜ 8 m/s for the beads and 3 m/s for the mist, up to 40
    and 80 m/s²; none parked or reversing;
  - drops land and slide: three thin colliders follow the curved windshield, one per third of its
    width, each a plane fitted to the glass model, 3 mm outside it; a bead that lands stays and
    creeps (`collision_mode` rigid, friction 0.6): about 15 cm/s down the glass parked, about
    0.5 m/s up it at 50 km/h; a mist droplet that touches the glass joins its water;
  - side-window run-off (`PillarRunoff`, new): above 5 m/s, each top turn also throws 24 streams
    back along the side window from the pillar, pushed back by the air (g × (v / 5 m/s)², up to
    60 m/s²);
  - the wipers clear a spill (`SpillWater`, new): the first top turn within 3 s of a roof spill
    throws 200 more drops, 3–6 mm.
- **Rules that change with it, for the brief revisions if kept:**
  - the flick's frame is the windshield's;
  - freeing the van frees its bursts with it, as A2's revision 3 did for the spill;
  - §9's answer 2 changes for A1;
  - §8's peak: 2 × (120 + 120 + 24) + 200 = 728 particles;
  - B1's feature that the A effects don't use is its splash sub-emitter (the author's decision,
    #147; revision 6).
- **Claude's prediction for r1** (from its own render of these previews):
  - Valley road, parked (`scripts/capture-strips.sh 1`):
    - frame 10: nothing new at the blade; the burst fires at the end of frame 10 and shows from
      frame 11, as in r0;
    - frame 12: a fine spray of pale threads leaving the blade's upper half toward the pillar,
      1–2 px wide and faint against the dark forest;
    - frame 15: the threads have snapped into small beads; most have passed behind the pillar,
      and a few lie on the glass below the blade's path;
    - frames 20 and 30: a few specks creeping down the glass, like the glass's own drops;
    - frame 50: none.
  - At 50 km/h (`wiper_flick:speed_kmh=50`):
    - frames 12 and 15: a fan of pale streaks blown up and back across the top left of the
      glass;
    - frame 20: a few specks running up the glass; the run-off is beyond the pillar, out of this
      view;
    - frames 30 and 50: none.
  - Depot (`wiper_flick:place=depot`): frames 12 and 15: fine streaks by the pillar in the lamp
    light; frame 20: a few specks; frames 30 and 50: none.
  - **Against the author's #146:** real drops are small. Parked on the unlit road, the flick shows
    about as much as the glass's own drops do, faint in a still frame; driving, the wind turns it
    into a fan of streaks that shows clearly. The author chose real sizes in #147, knowing this.
- **Claude's comparison of r1 with its prediction:** _after the author's r1 capture._
- **My verdict (running game, 1280×800):** _the author: kept | reverted, because…_
- **Strips:** `captures/wiper_flick/r0/`, `captures/wiper_flick/r1/`, and the `speed_kmh-50`
  and `place-depot` variants
- **Commits:** _when kept._

## Effect A2 (roof spill), revision r1

- **What I saw (running game, 1280×800):** _the author._ (#144, #146 and #147, as for A1.)
- **Claude's reading of r0:** _from `captures/roof_spill/r0/`._ Claude Code's render showed no
  spill on any frame: the roof lip is above the driver's view, and the streams on the glass
  were too dark to see.
- **Change (applied at the author's direction, #146 and #147):**
  - the quads' material: `StandardMaterial3D` → the shared `ShaderMaterial`, drawn as clear water
    that bends the view: the streams at `scatter` 1.5, `diffuse` 0.15, `sky` 0.8, `refraction`
    0.04, `lens_blur` 0.8; the beads at `scatter` 3, `sky` 1.2, `refraction` 0.015, `glint` 1;
    `catch_light` 1 and `rim_dark` 0.4 on both;
  - a curtain, then down the glass: real gravity, the scene's still air (0, −9.8, 0) in place of
    the brief's gravity laid along the glass, plus the surge of the water as the van slows, set by
    the van's code each tick from the van's own deceleration (about 8–9 m/s² while braking, none
    at rest); the water leaves the lip 10° off the glass (`direction` (0, −0.56, −0.83)), so it
    falls as a thin curtain just in front of the glass and lands on it lower down; the colliders
    fitted to the glass hold it there, and it runs down at the speed of a draining film
    (`collision_mode` rigid, friction 0.3: about 1 m/s while braking, 0.5 m/s after);
  - the streams: 96 (32), 0.6–1.5 cm wide, drawn as comets along their flow (`tail` 0.6),
    31 times their width at 3 m/s; the beads: 120 (48), 2.5–6 mm, the same streaks as A1's;
  - rivulets with wet tails (`Rivulets`, new): 8 rivulets, 3–5 mm wide, appear as the sheet
    breaks up (from 0.3 of their 1.6 s life) and run down the glass, each with a tail as long as
    its last 0.3 s of travel (`tail` 0.8);
  - the wipers clear the spill: A1's `SpillWater`, above.
- **Rules that change with it, for the brief revisions if kept:** the spill lives until its
  rivulets finish (1.6 s), so the brief's "disappears within 1.30 s" becomes 1.6 s; §8's peak:
  96 + 120 + 8 = 224 particles.
- **Claude's prediction for r1** (office approach; the hard brake comes on frame 10):
  - frames 10–15: nothing yet: the water starts above the driver's view, behind the roof's edge,
    and moves at a draining film's speed;
  - frame 17: the first drops at the top right of the glass;
  - frame 20: thin pale streams coming down the top of the glass, right of the middle;
  - frame 30: streams and rivulet tails lower down, near the office, with the office and the road
    seen between them;
  - frame 50: a rivulet or none.
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
