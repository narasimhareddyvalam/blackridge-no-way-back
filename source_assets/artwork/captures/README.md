# Look-development captures

These are in-game stills from look-development experiments, sorted by the author's
decision.

- `approved/`: the author accepted the look.
- `rejected/`: the author turned it down, or it was dropped. The table says who
  decided.
- `pending/`: shown to the author and waiting for a decision.

These are not runtime assets. They are kept outside `game/` so Godot does not import
them. The author's target images live in [`../references/`](../references/README.md).

Each experiment ran on a scratch copy of the game with settings changed only at runtime.
None of them changed the project itself. Each still is the same parked view from the
driver's seat, rendered at 3840×2400 and scaled down here. Brightness figures are average
luma on a 0–255 scale. The full record is in [`fractional.md`](../../../fractional.md)
under 2026-10-30.

## Inventory

| File | What it shows | Decision |
| --- | --- | --- |
| [`rejected/2026-10-30_today_headlights_on_off.png`](rejected/2026-10-30_today_headlights_on_off.png) | The game as it is (Compatibility renderer), headlights on and off. The two views are identical outside the cab: 0.0% of the outside view changed. | **Rejected by the author:** "headlights dont make any difference"; "the road doesnt look like road"; "i am not happy with car interior". |
| [`rejected/2026-10-30_post_processing_stack.png`](rejected/2026-10-30_post_processing_stack.png) | Forward+ alone, next to Forward+ with the AgX tonemap, screen-space reflections, ambient occlusion, glow and volumetric fog (density 0.015). The stack made the frame 21% darker and hid the trees and the sign in haze. | **Dropped on Claude Code's analysis** (darker, not more real). The author did not ask to keep it. Forward+ itself was approved separately as the renderer. |
| [`rejected/2026-10-30_headlights_lighting_mist.png`](rejected/2026-10-30_headlights_lighting_mist.png) | Darker night, headlights fixed and 12× stronger, volumetric fog 0.012. The beam lit the mist and the mist hid the road. | **Rejected by the author:** "terrible, cant see the road at all when light is on. road should be more visible". |
| [`approved/2026-10-30_low_beam_headlights.png`](approved/2026-10-30_low_beam_headlights.png) | Close-ups of the road ahead: today's game (top) against the low-beam test (bottom), headlights on and off. The test used Forward+, no mist, moon 0.25 and ambient 0.12, and each headlight had energy 560 with a sharp-topped beam pattern. The road band is 26.3 with the lights off and 78.9 with them on. Only the left headlight cast shadows, so only it had the sharp top edge. | **Direction approved by the author** on 2026-10-30 ("Approve the direction"). The look is approved, not the exact values: Phase 1 tunes them and shows the result again. |
| [`approved/2026-10-30_low_beam_full_view.png`](approved/2026-10-30_low_beam_full_view.png) | The same low-beam test, full driver's view, headlights on and off. | **Direction approved by the author** on 2026-10-30, as above. |
| [`pending/2026-10-30_forest_road_first_pass.png`](pending/2026-10-30_forest_road_first_pass.png) | First pass of the single-lane forest road at night, in Forward+ with the AgX tonemap. About 6,500 code-built pines, Poly Haven asphalt, gravel edges and forest floor, and the working low beams. Top row: the sharp beam cutoff against the softer one. Bottom row: behind the van, and above the road. With the lights on the road reads 62.6, against 16.9 with them off. | **Waiting for the author.** |
| [`pending/2026-10-30_run3_cabin_rain_undergrowth.png`](pending/2026-10-30_run3_cabin_rain_undergrowth.png) | Run 3: the new cabin (lower hood, round chrome vents, tilted three-spoke wheel, two-dial cluster with a centre display), roadside ferns and undergrowth, and windshield rain (drops after 9 s without wipers, zoomed). From the driver's seat the road reads 97.7 with the lights on and 11.2 with them off. | **Waiting for the author.** |
| [`pending/2026-10-30_run5_side_window_rain.png`](pending/2026-10-30_run5_side_window_rain.png) | Run 5: driver's-window rain. Top: Run 4 (drops inside the glass read as dark dots) against Run 5 (drops outside the glass, lit, with sky glow in their lower edge), both zoomed. Bottom: the driver's parked view, and the window at 37 km/h with drops stretched backward. Captured at 1280×800. | **Waiting for the author.** |
| [`pending/2026-10-31_run6_rain_trees.png`](pending/2026-10-31_run6_rain_trees.png) | Run 6. Top: heavier windshield rain with the wipers on (drops and a rippling water sheet), and after 9 s with them off. Bottom: the roadside before (synthetic branch cards, bare trunks) and after (branch cards built from Poly Haven's scanned fir twigs, dead lower branches). Captured at 1280×800. | **Waiting for the author.** |
| [`pending/2026-10-31_run10_undergrowth.png`](pending/2026-10-31_run10_undergrowth.png) | Run 10, undergrowth between the trees. Top: a young fir in a test close-up lit by an added lamp, first pass (a thin stick) against final (bushy, branches to the ground). Bottom: the roadside in game lighting before and after; the young firs stand between the trunks. Captured at 1280×800. | **Waiting for the author.** |
| [`pending/2026-10-31_run11_windshield_drops.png`](pending/2026-10-31_run11_windshield_drops.png) | Run 11, windshield with the wipers off. Top: before, with physically small drops reading as speckle, against after, with more droplets lit by the night sky. Bottom: a debug view (red is a running drop, green its swept lane) at two moments 1.4 s apart, showing random starts, lengths, speeds and wandering paths. | **Waiting for the author.** |
| [`pending/2026-10-31_run15_ghat_dressing.png`](pending/2026-10-31_run15_ghat_dressing.png) | Run 15, the ghat road. Top left: the whole hill in debug light (ambient 6.0, fog off), showing the irregular climb on the right, the ridge and the descent on the left, the valley buildings and the town's glows. Top right: the viewpoint pull-off at night, with the stone wall, a guardrail, chevron backs and the town's lights beyond. Bottom: a hairpin approach with a galvanized guardrail, and the new tandem wipers mid-sweep at the lumber-yard start. Captured at 1280×800. | **Waiting for the author.** |
| [`pending/2026-10-31_run16_wipers.png`](pending/2026-10-31_run16_wipers.png) | Run 16, step 2: the wipers mid up-stroke, zoomed. Top: before, with plain black sticks and wiped glass that looked like wet glass. Bottom: after, with a slimmer beam blade, a lit edge of water pushed ahead of it, a short blur trail behind the moving passenger blade, and crisp wiped glass. The refill, the dump at the turn and the streaks show best in motion. Captured at 1280×800. | **Waiting for the author.** |
| [`pending/2026-10-31_run16_beams.png`](pending/2026-10-31_run16_beams.png) | Run 16, step 3: the driver's view at the start straight with low beams, high beams and the lights off, switched by real L presses. High beams light the road further, the trunks higher up and the sign ahead. Road 50–100 m reads 40.3, 61.6 and 28.7. Captured at 1280×800. | **Waiting for the author.** |
| [`pending/2026-10-31_run16_moon_roof.png`](pending/2026-10-31_run16_moon_roof.png) | Run 16, step 4: the moon roof from the driver's seat, looking up, then up and right, parked and at 45 km/h. The Honda's own sunroof frame opens onto tinted glass with rain drops, the night sky and the pines. Left: the whole view; right: the glass. Captured at 1280×800. | **Waiting for the author.** |
