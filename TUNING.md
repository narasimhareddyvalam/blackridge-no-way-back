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
ideas to choose from (#147) and chose seven of the eight offered. Then the author asked for each
effect to be researched and matched to real life: the wiper flick (#148), then the other three
(#149). No strip had been captured yet, so r1 was extended each time rather than starting an r2.
So r1 departs from the loop above in three ways:

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
(`logs/particles/realistic_r1d/SUMMARY.txt`). The configuration tests read the new values,
including each shader parameter (which must be one of the shader's uniforms) and each per-axis
curve, and check that no A emitter uses a sub-emitter, turbulence or a driven `amount_ratio`, the
features the B effects are graded on (the author's decision, #147). The A1 state test adds the
glass colliders, the air's push, the run-off at speed, the spill's water and freeing the van; the
A2 state test adds the water's surge as the van slows.

**Outside the effects (#150):** at the author's request the street lamps and the road's puddles
also changed, uncommitted, with their own patch (`tools/tuning/world/lamps_and_rings.patch`):
lamps that light downward like real ones, with shadows and a glow around the lens, and raindrop
rings in puddles with edges (the prompt log, #150). An r1 capture from the working tree includes
them, so B1's r0 and r1 strips differ in the lamp as well as in the rain, and A1's depot strip
and A2's show the new puddles. Then the depot's three street lamps became security lights on
its wall (#151), each with its rain volume, so A1's depot strip shows them too. The brief's
roadside step (#157) adds grass along the valley road, guardrails on the bends east and west of
the depot, four lamps on the west bend, and lit mist under every lamp. So strips on the valley
road and at the depot show these too, including B1's at the valley lamp. To capture r1 without
these changes, first reverse their patch
(`git apply -R tools/tuning/world/lamps_and_rings.patch`), then apply it again.

## Effect A1 (wiper flick), revision r1

- **What I saw (running game, 1280×800):** _the author, in visual terms._ The author's messages
  of 2026-11-07: "make sure its clearly visible like in real world. all the four effects!" (#144),
  "i want the bigger droplets effect even under no lights in normal when driving" (#146),
  "make wiper flick and roof spill more realistic" (#147), and "make wiper flicker more visible
  and realistic and real physics as if in real life" (#148).
- **Claude's reading of r0:** _to be written from `captures/wiper_flick/r0/` once the author has
  captured it._ Claude Code's own render of the same preview showed no flick at the blade tip
  on any frame: the beads are 3–7 mm, 1–2 px at about 1.2 m, and lit only by the night.
- **Change (applied at the author's direction, #146, #147 and #148):**
  - the quads' material: `StandardMaterial3D` → the shared `ShaderMaterial`, drawn like the
    windshield's own water: the night sky's glow on each drop's lower half and at least 35% of it
    over all its water (`sky` 2), a catch light (`catch_light` 1), the scene behind shifted by a
    few pixels (`refraction` 0.012, the sheet 0.02), `lens_blur` 0.6, `rim_dark` 0.4; each drop's
    upper part shows an average of the headlit scene below it, as a drop's wide-angle lens does
    (`ground_reach` 0.5); `forward_scatter` 0.85, `scatter` 10, `diffuse` 0.3; `glint` 1 on the
    sheet and beads; the mist at `sky` 1.2, `catch_light` 0.5, `refraction` 0.006;
  - the bow wave leaves first (`WaterSheet`, new): 24 overlapping pieces of a water ridge, 10–13
    mm wide and 7–9 cm long, laid along the blade by the van's code at each top turn, run ahead
    toward the pillar at 1–3 m/s and tear into shorter, thinner pieces within 0.15 s;
  - threads that snap into beads: each bead is drawn as a comet turned along its motion
    (`transform_align` Z-billboard, Y to velocity; `tail` 0.35), born twice as long and 0.8 as
    wide and round by 8% of its life (a per-axis `scale_curve`), its tail as bright as its head
    while it is a thread (`thread_life` 0.1), and faint for its first 0.07 s, while the sheet
    tears; a fast drop draws as the streak a 1/60 s glimpse of it would show, 26 times its width
    at 6 m/s (`scale_over_velocity`);
  - real drop sizes: beads 2.5–4.5 mm (`scale` 0.3–0.7 → 0.25–0.45), mist 0.5–1 mm
    (0.15–0.3 → 0.05–0.1), drawn at least 2 px and 1 px wide;
  - drops by size, as on a real windshield: most beads stick where they land and creep about
    4 cm/s parked (`collision_mode` rigid, friction 0.85); 14 heavy drops of 5–6.5 mm
    (`HeavyDrops`, new) slide down the glass (friction 0.25); in the wind, all of them climb;
  - more water: 120 beads, 14 heavy drops and 120 mist droplets a burst (22 and 36 before);
  - where it leaves: the outer half of the blade's leading edge, a box 9 × 26 cm beside it, at
    0.2–2.6 m/s toward the pillar and a little off the glass;
  - simulated with the van (`local_coords` on): each burst is set at the blade tip, turned to the
    windshield's frame, and its directions and boxes are in that frame;
  - the air over the glass, set by the van's code each tick: a push up the glass of g × (v / vₜ)²,
    with v the van's forward speed and vₜ 6 m/s for the sheet, 8 for the beads, 12 for the heavy
    drops and 3 for the mist, up to 40 and 80 m/s²; none parked or reversing;
  - three thin colliders follow the curved windshield, one per third of its width, each a plane
    fitted to the glass model, 3 mm outside it; a mist droplet that touches the glass joins its
    water;
  - side-window run-off (`PillarRunoff`, new): above 5 m/s, each top turn also throws 24 streams
    back along the side window from the pillar, pushed back by the air (g × (v / 5 m/s)², up to
    60 m/s²); seen by turning the driver's head left;
  - the wipers clear a spill (`SpillWater`, new): the first top turn within 3 s of a roof spill
    throws 200 more drops, 3–6 mm.
- **Why, from the research (#148):** at each reversal the blade's quick deceleration throws the
  water it pushed off the side of the windshield (wiper patents US 5642026 and US 5654616); that
  water leaves as a sheet, which tears into strands about its own thickness, each pinching into
  drops about 1.9 times its width (Rayleigh–Plateau), so a 2–3 mm bow wave gives drops of
  2–5 mm; on the glass, large drops slide down, medium ones stay put, and small ones are pushed
  up by the wind (Hooshanginejad and Lee, Physical Review Fluids, 2022); the airflow and the
  wipers drive water over the A-pillar onto the side window (Jaguar Land Rover, SAE
  2012-01-0588).
- **Rules that change with it, for the brief revisions if kept:**
  - the flick's frame is the windshield's;
  - freeing the van frees its bursts with it, as A2's revision 3 did for the spill;
  - §9's answer 2 changes for A1;
  - §8's peak: 2 × (24 + 120 + 14 + 120 + 24) + 200 = 804 particles;
  - B1's feature that the A effects don't use is its splash sub-emitter (the author's decision,
    #147; revision 6).
- **Claude's prediction for r1** (from its own render of these previews):
  - Valley road, parked (`scripts/capture-strips.sh 1`):
    - frame 10: nothing new at the blade; the burst fires at the end of frame 10 and shows from
      frame 11, as in r0, when a continuous pale ridge of water lies along the blade (not a
      frame the strip keeps);
    - frame 12: the ridge torn into pale dashes running from the blade toward the pillar;
    - frame 15: fine pale threads and small beads, most passing behind the pillar;
    - frames 20 and 30: a few specks on the glass between the blade and the pillar, where the
      wipers don't reach, and a heavy drop or two sliding down;
    - frame 50: none.
  - At 50 km/h (`wiper_flick:speed_kmh=50`):
    - frames 12 and 15: a fan of pale streaks blown up and back across the top left of the
      glass;
    - frame 20: a few specks running up the glass;
    - frames 30 and 50: none.
  - Depot (`wiper_flick:place=depot`): frame 12: pale streaks by the pillar in the lamp light;
    frame 15: drops; frames 20 and 30: a few specks; frame 50: none.
  - **Against the author's #146:** on the unlit road the drops themselves stay small and faint,
    as real ones are; what shows clearly is the sheet of water leaving the blade, and, driving,
    the streaks the wind makes of it.
- **Claude's comparison of r1 with its prediction:** _after the author's r1 capture._
- **My verdict (running game, 1280×800):** _the author: kept | reverted, because…_
- **Strips:** `captures/wiper_flick/r0/`, `captures/wiper_flick/r1/`, and the `speed_kmh-50`
  and `place-depot` variants
- **Commits:** _when kept._

## Effect A2 (roof spill), revision r1

- **What I saw (running game, 1280×800):** _the author._ (#144, #146, #147 and #149, as for A1.)
- **Claude's reading of r0:** _from `captures/roof_spill/r0/`._ Claude Code's render showed no
  spill on any frame: the roof lip is above the driver's view, and the streams on the glass
  were too dark to see.
- **Change (applied at the author's direction, #146, #147 and #149):**
  - the quads' material: `StandardMaterial3D` → the shared `ShaderMaterial`, drawn as clear water
    that bends the view: the streams at `scatter` 1.5, `diffuse` 0.15, `sky` 0.8, `refraction`
    0.04, `lens_blur` 0.8; the beads at `scatter` 3, `sky` 1.2, `refraction` 0.015, `glint` 1;
    `catch_light` 1 and `rim_dark` 0.4 on both;
  - a curtain, then down the glass: real gravity, the scene's still air (0, −9.8, 0) in place of
    the brief's gravity laid along the glass, plus the surge of the water as the van slows, set by
    the van's code each tick from the van's own deceleration (about 8–9 m/s² while braking, none
    at rest); the water leaves the lip 10° off the glass, so it falls as a thin curtain just in
    front of the glass and lands on it lower down; the colliders fitted to the glass hold it there,
    and it runs down at the speed of a draining film (`collision_mode` rigid, friction 0.3: about
    1 m/s while braking, 0.5 m/s after);
  - simulated with the van in the glass's frame, as A1's flick is (#149): the spill is turned to
    the windshield at the roof lip, so its boxes lie along the glass, 4–5 cm along it and 2–4 cm
    deep; its directions are written in that frame and leave as before, measured in the van:
    the curtain 10.4° off the glass (`direction` (0, −0.985, −0.18)), the rivulets 5° into it
    ((0, −0.996, 0.09));
  - the streams: 96 (32), 0.6–1.5 cm wide, drawn as comets along their flow (`tail` 0.6),
    31 times their width at 3 m/s; the beads: 120 (48), 2.5–6 mm, the same streaks as A1's;
  - rivulets with wet tails (`Rivulets`, new): 8 rivulets, 3–5 mm wide, appear as the sheet
    breaks up (from 0.3 of their 1.6 s life) and run down the glass, each with a tail as long as
    its last 0.3 s of travel (`tail` 0.8);
  - a clear sheet of water (`WaterWash`, new, #149): 40 pieces of a water film, 12–22 cm, leave
    across the 0.9 m lip 4 cm below it and run down the glass at 0.3–0.8 m/s, first wider than
    long and then longer than wide (a per-axis `scale_curve`: across 1.4 → 0.8, along
    0.8 → 1.6), for 0.6 s (alpha `0:0, 0.15:0.6, 0.5:0.4, 1:0`); drawn with no light of its own
    (`scatter`, `diffuse`, `sky` and `glint` 0, `catch_light` 0.4): only the scene behind it,
    shifted (`refraction` 0.03), blurred (`lens_blur` 1.2) and rippled by a wave that moves over
    the film (`ripple` 0.012, a new uniform of the particle shader); drawn before the streams,
    beads and rivulets (`sorting_offset` −0.25 m), so they show on top of it; the colliders hold
    it on the glass (rigid, friction 0.3);
  - the wipers clear the spill: A1's `SpillWater`, above.
- **Why, from the research (#149):**
  - owners describe water collected on a vehicle's body coming off all at once as they slow
    (Toyota 4Runner owners; a Silverado owner whose truck "slung it onto the windshield all at
    once when slowing"); no technical source was found, so this supports the effect, not a number;
  - water pouring off a rounded edge stays attached to it and follows the surface below (the
    Coandă, or teapot, effect), which supports the curtain leaving close to the glass;
  - a water drop or film acts as a wide-angle lens, showing the scene behind it bent, not light of
    its own (Garg and Nayar); at night a clear film shows by how it bends and smears the lights
    behind it, so the new sheet draws only that.
  - Claude Code's own renders, with and without the sheet and every seed fixed, measured what it
    adds: at 0.47 s it changes 2.9% of the frame by more than 6 levels of 255, and up to 141,
    most in the office's lit windows and the bushes before them, bent and smeared, and faintly
    over the trees.
- **The author's #147 choice:** the sheet is close to "Clear sheet", the one #147 idea for the
  spill that the author did not choose, which drew the spill as a film in place of its streams.
  Here the streams, beads and rivulets stay, on top of it. Deleting the `WaterWash` node and its
  name in `SPILL_EMITTERS` takes it out.
- **Rules that change with it, for the brief revisions if kept:** the spill's frame is the
  glass's, so §3's directions and boxes change frame; the spill lives until its rivulets finish
  (1.6 s), so the brief's "disappears within 1.30 s" becomes 1.6 s; §8's peak:
  40 + 96 + 120 + 8 = 264 particles.
- **Claude's prediction for r1** (office approach; the hard brake comes on frame 10; the wipers
  run, so the drops flung near the office are A1's):
  - frames 10–15: no spill yet: the water starts above the driver's view, behind the roof's
    edge;
  - frame 17: the first stream heads at the top of the glass, right of the middle;
  - frame 20: pale streams with round heads coming down across the top of the glass;
  - frame 30: streams, beads and rivulet tails lower down by the office, and the office's lit
    windows and the bushes before them bent and smeared by the clear sheet;
  - frame 50: none.
- **Claude's comparison of r1 with its prediction:** _after r1._
- **My verdict (running game, 1280×800):** _the author._
- **Strips:** `captures/roof_spill/r0/`, `captures/roof_spill/r1/`
- **Commits:** _when kept._

## Effect B1 (lamp rain), revision r1

- **What I saw (running game, 1280×800):** _the author._ (#144, #146 and #149.)
- **Claude's reading of r0:** _from `captures/lamp_rain/r0/`._ Claude Code's render showed no
  rain under the lamp on any frame.
  - The valley lamp is an omni light of energy 3 with a steep falloff, bright only within a
    couple of metres of its head.
  - A camera-facing streak lit from above takes almost no matt light.
- **Change (applied at the author's direction, #146 and #149), in all three scenes:**
  - the quads' material, `LampRain` and `LampSplash`: `StandardMaterial3D` → the shared
    `ShaderMaterial`: `forward_scatter` 0.5, `scatter` 60, `diffuse` 0.3 (#146's were 0.8, 100
    and 0.5); no `sky`, `glint` or `refraction`; at least 1 px wide (`min_pixels` 1; #146's were
    2 and 1.5). With no lamp, the streaks still draw nothing;
  - real drop sizes and speeds (#149): drops 1–2.5 mm across (`scale` 0.1–0.25 of a 0.01 m
    square, in place of 0.7–1.35 of a 0.01 × 0.25 m streak), falling at 3.5–8.5 m/s (6.5–8.5);
  - each drop drawn as the streak a camera sees (#149): turned along its motion as before and
    stretched by its speed (`scale_over_velocity` 0–9 m/s, the length growing to 201 times the
    width at 9 m/s), so a 1.5 mm drop draws the path it falls in 1/30 s, a bigger one longer;
  - denser rain (#149): 2,000 drops under each post lamp, 3,200 under the floodlight and 300 at
    the door lamp (160 each), brighter while lit (alpha `0:0.1, 0.15:0.8, 0.75:0.8, 1:0`; 0.45);
  - smaller splashes (#149): 3 droplets a landing (4), 0.3–1 mm (1–3 mm), thrown 1–9 cm up at
    0.5–1.3 m/s (0.6–1.6) in a 70° cone (60°), for 0.2 s (0.25); 1,100 under a post lamp, 1,800
    under the floodlight, 170 at the door (160 each).
- **Why, from the research (#149):**
  - a camera sees a falling drop as a streak, the path it moves during the exposure, and each
    drop acts as a wide-angle lens that sends a lamp's light toward the eye, so rain shows as
    bright streaks near lights (Garg and Nayar, "Photorealistic rendering of rain streaks", 2006,
    and "Vision and rain", 2007);
  - a raindrop falls at a speed that grows with its size: about 2 m/s at 0.5 mm, 4 m/s at 1 mm,
    6.6 m/s at 2 mm and 8 m/s at 3 mm (Gunn and Kinzer's measurements, 1949, as fitted by Atlas
    and others, 1973: v ≈ 9.65 − 10.3 e^(−0.6 D), D in mm); the brief's 6.5–8.5 m/s held only
    drops of 2–3.7 mm, and 3.5–8.5 m/s takes in drops from 0.9 mm;
  - real rain is far denser than any game draws: at 10 mm/h, about 250 drops over 1 mm in every
    cubic metre (Marshall and Palmer's distribution, 1948); the 2,000 drops in a post lamp's
    6 × 6 × 6.4 m are about 9 per cubic metre, a limit set by the frame's budget;
  - a drop hitting a wet surface throws up a crown that sheds small droplets before it reaches
    its full height (MIT's splash studies), so each landing throws a few droplets of under a
    millimetre a few centimetres up.
- **A known gap:** a drop slower than about 5.5 m/s does not reach the ground within its 1.1 s
  life, so the slowest fade out 2–4 m above the ground, where the lamp's light is already faint.
  Letting all of them land needs a 1.6 s life and preprocess and about 45% more drops, a single
  change for a later revision if the author wants it; not made, for the price.
- **Rules that change with it, for the brief revisions if kept:** §4's speeds 6.5–8.5 m/s become
  3.5–8.5; its streaks 17–34 cm long become drops of 1–2.5 mm stretched by their speed; its 160
  drops and 160 splash droplets per lamp become 2,000 and 1,100 (post), 3,200 and 1,800
  (floodlight), 300 and 170 (door); 4 droplets a landing become 3, and their 0.25 s life 0.2 s.
  §8's B1 peak becomes 3,100 particles per post lamp (5,000 floodlight, 470 door), up to 24,800
  at eight post volumes, and its GPU price is unmeasured: §7's failure 10, the author's windowed
  price check.
- **Claude's prediction for r1** (the valley post lamp at (−15, 63.8)):
  - frames 10 and 12: no rain yet: `restart()` with preprocess takes effect three frames late
    (a fixture finding, `TEST-REPORT.md`);
  - frame 20: rain from just under the lamp head down beside the post, with splash specks on the
    lit ground;
  - frames 30, 50 and 70: steady rain filling the lamp's light, many short pale streaks, most
    around the head, and splash specks on the lit ground;
  - frame 85: streaks left only in the middle and lower part, as the rain stops from the top;
  - frame 110: empty (hidden on frame 109).
  - With #150's lamp in the working tree: on every frame, the road and the verge under the lamp
    lit in a broad warm pool, puddles on the road, and a soft glow around the lens; with #154's
    amber streetlight, all of it amber and the rain golden.
- **A change with #154 (r1, in `tools/tuning/r1/r1.patch`):** the post scene's `scatter`, for the
  rain under the street lamps and the depot's wall lights, 60 → 5. Since #150 those lamps light
  the drops 20 to 100 times more strongly than the lamps r1 was tuned under, and at 60 the amber
  blew out to white; at 5 it reads golden, as in the author's reference. The floodlight's and the
  door lamp's rain keep 60. This value assumes the world patch's lamps.
- **Changes with #156 (r1):** the street lamps' own scene, `lamp_rain_street.tscn` (10 × 10 m,
  5,000 drops, 2,750 splash droplets); in all four scenes rigid collisions in place of
  `COLLISION_HIDE_ON_CONTACT`, which in Godot 4.7.2 never set off the splash sub-emitter, so B1's
  splashes had never appeared; stopped drops fade (`still_fade`); `fixed_fps` 60; splashes start
  3 cm up; the street and post splashes 0.5–1.5 mm, `scatter` 30, `diffuse` 1. For §8, B1's peak
  becomes 7,750 particles per street lamp.
- **Claude's comparison of r1 with its prediction:** _after r1._
- **My verdict (running game, 1280×800):** _the author._
- **Strips:** `captures/lamp_rain/r0/`, `captures/lamp_rain/r1/`
- **Commits:** _when kept._

## Effect B2 (exhaust vapour), revision r1

- **What I saw (running game, 1280×800):** _the author._ (#144, #146 and #149.)
- **Claude's reading of r0:** _from `captures/exhaust_vapour/r0/`._ Claude Code's render
  showed no vapour behind the van on any frame:
  - the van shades the plume from the floodlight;
  - the tail lamps light it from behind, which a matt material hardly passes.
- **Change (applied at the author's direction, #146 and #149):**
  - the quad's material, `ExhaustPlume`: `StandardMaterial3D` → the shared `ShaderMaterial`:
    `forward_scatter` 0.75, `scatter` 0.8, `diffuse` 0.25 (#146's were 0.7, 0.6 and 0.3); no
    `sky`, `glint`, `refraction` or minimum width;
  - a denser plume: `amount` 96 → 300, still fixed; `amount_ratio` still runs 0.15–0.80 of it;
  - a jet that stops (#149): puffs leave from within 2.5 cm of the pipe's centre
    (`emission_sphere_radius` 0.06 → 0.025) at 4–7 m/s (1–2.2) within 10° (18°), and the still
    air stops them within about a metre (`damping` 0.8–1.4 → 12–18 m/s²); warm, they rise a
    little (`gravity` 0.5 → 0.8 m/s² up), and curl more (`turbulence_noise_strength`
    0.15 → 0.35, scale 1.2 → 1.6, speed (0.2, 0.1, 0.2) → (0.3, 0.25, 0.3));
  - a thin plume that thins out (#149): puffs born 6–10 cm (`scale` 0.6–1.0; #146's 2.4–3.6),
    three times that by 0.3 of their life and six times by its end (36–60 cm; `scale_curve`
    `0:1, 0.3:3, 1:6`), densest at the pipe (alpha `0:0, 0.02:0.22, 0.3:0.14, 0.7:0.05, 1:0`),
    gone in 1.6 s (`lifetime` 2.5 → 1.6); a whiter grey, (0.92, 0.93, 0.94).
- **Why, from the research (#149):** a warm engine's exhaust is mostly invisible; in cold, wet
  air its water vapour condenses into a thin white plume that dissipates soon after the pipe, and
  a diesel, whose exhaust is mostly air, shows less of it at idle (consumer guides and owners'
  forums; none gave how long it stays visible). How fast the jet slows is Claude Code's estimate
  of a jet mixing into still air, not a measured value.
- **Rules that change with it, for the brief revisions if kept:** §5's "Keep `amount = 96` fixed
  at all times" becomes 300 (`test_exhaust_vapour_state.gd` checks it); its lifetime 2.5 s
  becomes 1.6 s, so "existing vapour drifts and fades within 2.5 s" becomes 1.6 s; its
  `visibility_aabb` stays 49 m long, more than the 30 m the van covers in 1.6 s at 19 m/s.
- **Claude's prediction for r1** (site office, rear view; ignition on frame 9):
  - frames 10, 20 and 30: no vapour yet (the 0.4 s wait, then the ramp);
  - frame 40: a faint red smudge just behind the bumper, lit by the tail lamps (idle);
  - frame 55: a small red-lit plume behind the van as it pulls away at full throttle;
  - frame 80: a narrow plume glowing bright red in the brake lamps;
  - frame 100: the van 3.4 m on, engine off; a faint pale grey wisp left behind in the
    floodlight;
  - frame 130: at most a trace; frame 180: none.
- **Claude's comparison of r1 with its prediction:** _after r1._
- **My verdict (running game, 1280×800):** _the author._
- **Strips:** `captures/exhaust_vapour/r0/`, `captures/exhaust_vapour/r1/`
- **Commits:** _when kept._
