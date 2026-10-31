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
