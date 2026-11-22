# CHANGE-BRIEF.md: Animation (Assignment 7)

**Date:** 2026-11-22
**Status:** Draft by Claude Code for the author's review (the assignment's AI-assisted working
instruction: "Claude Code may draft CHANGE-BRIEF.md, the phase table, the cycle spec, predictions
and proposed verdicts. The student reviews and approves"). Nothing below has been built. Commit it
before the first setup step; later changes go only in dated revisions below. Assignment 6's brief
is at tag `a6` (`git show a6:CHANGE-BRIEF.md`).

**The pair, the author's choice (2026-11-22, #365):** "Phone ring + get in van". Values marked †
are Claude Code's proposals for the author to check.

## 1. The two clips

| | Ring (the cycle) | EnterVan (the committing action) |
| :-- | :-- | :-- |
| What it communicates | Maya's call is ringing: the dash shows a handset with its ring arcs pulsing, so the player sees the call before T or the auto-answer | Ethan gets into his van: he steps to the driver's door, takes the handle, swings it open and climbs in, so the player sees the van taken, not teleported into |
| Plays on | `RingIcon` (`Sprite2D`) on the dash's navigation screen (`navigation_display.gd`, in the van's dash viewport, `van_presentation.gd:490`) | Ethan's model (`ethan.glb`), his `AnimationPlayer`, in `driver.gd` |
| Route | **Sprite2D with an AnimationPlayer frame track** (the preferred route: one player, one authority, the read-back sees it) | **Imported 3D rig** (Mixamo's "Entering Car", `source_assets/mixamo/Entering Car.fbx`, imported in `ethan.glb` as `EnterVan`; `tools/art/convert_mixamo.py:56`) |
| Authority | `navigation_display.gd` alone: it calls `play("ring")` and `stop()` on its own `RingPlayer`, reading `call_state` and `call_seconds` (`navigation_display.gd:107-127`), which the phone call sets | `driver.gd` alone writes Ethan's `AnimationPlayer` (`play_clip`, `_play`); the app's boarding sequence (`first_drive.gd:828-859`) asks it to (`driver.play_clip("EnterVan", ...)`) and reads `clip_time()` |
| Cycle or action | the cycle (loops) | the committing action (one shot) |

The ring replaces the call card's code-drawn pulsing circle (`navigation_display.gd`, `_draw_call_card`,
`pulse := 1.0 + 0.12 * sin(_clock * 8.0)`): the named change on the dash.

## 2. The sheet (the ring)

- **Source:** drawn by a committed script, `tools/art/make_phone_ring_sheet.py` (Pillow), the way
  Assignment 6's textures were (`tools/make_particle_textures.py`). No licence needed: it is ours,
  and the script is its provenance (`game/features/vehicles/freight_van/art/ring/ATTRIBUTION.md`,
  `SOURCES.md`). Date: the day it is drawn.
- **The file:** `game/features/vehicles/freight_van/art/ring/phone_ring.png`, as the script writes
  it (the "original as downloaded" is the script's output, committed with its `.import`).
- **Cell size** 64 × 64 px†; **grid** `hframes = 6`, `vframes = 1`†; **frame order** 0 → 5, left to
  right: the handset alone (0), then one, two and three ring arcs growing out from it (1-3), the
  outer arc fading (4-5)†. White on transparent, tinted by the card's colours in the game.

## 3. The cycle spec (the ring)

- **Frames** 6†; **frame rate** 10 fps†; **length** 0.6 s; **`Animation.step`** 0.1 s.
- **Loop mode:** `Animation.LOOP_LINEAR`.
- **Track:** one value track, `RingIcon:frame`, `UPDATE_DISCRETE`, keys at 0.0, 0.1, 0.2, 0.3, 0.4
  and 0.5 s holding frames 0-5.
- **Seam rule (frame track):** no duplicate across the wrap (frame 5 is not frame 0), and the gap
  from the last key (0.5 s) to `length` (0.6 s) equals the key interval (0.1 s).
- **The clip lives as a resource:** `game/animations/phone_ring.tres` (an `AnimationLibrary`),
  loaded by `navigation_display.gd`, never built in code.

## 4. The phase table (EnterVan)

Measured from the clip (164 frames at 30 fps, 5.47 s, `ethan.glb`, probed 2026-11-22) and from the
moments the game already reads from it (`first_drive.gd:30-38`). The game uses its first 2.0 s:
it cuts to black at the cut and Ethan is seated behind it. **Frame rate 30 fps; `Animation.step`
1/30 s** (the importer's 30 fps, `ethan.glb.import`).

| Phase | Frames | Begins | What the player may do | What the game reads |
| :-- | :-- | :-- | :-- | :-- |
| Startup | 0-31 (32) | 0 (E by the van) | Nothing moves him: W/A/S/D, sprint and E are ignored; R (recover) and Esc (pause) still work | from frame 22 his left hand reaches for the handle (IK weight rises, `REACH_FROM`) |
| Active | 32-47 (16) | 32 (hand on the handle) | as Startup | the door's opening, `driver_door = smoothstep(32, 48)` frames, his hand on the handle |
| Recovery | 48-59 (12) | 48 (door fully open) | as Startup | at frame 53 the cut begins (`CUT`), a 0.25 s fade to black; at 60 he is seated, the engine starts 0.6 s later |

**Named change:** the boarding constants re-expressed from the table in frames at 30 fps
(`REACH_FROM` 0.75 → 22/30 s, `DOOR_GRAB` 1.05 → 32/30, `DOOR_OPENED` 1.6 → 48/30, `CUT` 1.75 →
53/30); each moves by at most 1/60 s. Retiming the clip itself only through the importer or
`speed_scale`, never by editing it.

**Interrupts (what each does, in every phase):** W (or any move key) and E are ignored; R
recovers: boarding is cancelled, the door shuts and Ethan is seated in the van at the checkpoint;
Esc pauses: the clip and the door freeze on their frame and resume from it.

**Import:** `EnterVan`'s loop mode is set explicitly in the importer's per-animation settings
(`ethan.glb.import`, `_subresources` → `animations` → `EnterVan` → `settings/loop_mode = 0`,
`LOOP_NONE`), not in a scene, and is verified from an empty import cache.

## 5. The state machine

No `AnimationTree`: the states are code, each naming its clip.

| State | Clip | Enters when | Leaves when |
| :-- | :-- | :-- | :-- |
| On foot: idle | `Idle` | no move input | a move key (walk) |
| On foot: walking / running | `Walk` / `Run` | a move key / with sprint | input released |
| Boarding | `EnterVan` | E within reach of the driver's door, the van stopped | the cut at frame 53 (seated), or R |
| In the van | none (Ethan hidden) | boarding ends | E stopped (getting out, `ExitVan`) |
| Dash: no call | none (`RingIcon` hidden) | no call, or a call answered, missed or ended | a call rings |
| Dash: ringing | `ring` | `call_state` "ringing" or "auto", `call_seconds < 0` | answered (talking), missed or ended |

## 6. The two clocks

- Ethan's `AnimationPlayer`: `callback_mode_process = ANIMATION_CALLBACK_MODE_PROCESS_IDLE` (1,
  probed). The app reads `clip_time()` on the process tick (`first_drive.gd`, `_board_van`'s
  `await get_tree().process_frame`): the same clock, largest disagreement 0 s.
- `RingPlayer`: `ANIMATION_CALLBACK_MODE_PROCESS_IDLE`†. Nothing in gameplay reads the ring.
- No method tracks are used to make clocks agree.

## 7. Boundaries

Collision, movement, input, the mission and save rules, the existing tests and their expectations,
the Assignment 5 shaders (`game/shaders/`), the Assignment 6 effects and every other object stay as
they are, except: the call card's drawn pulse becomes the ring sprite; the boarding constants are
re-expressed in frames (above); `EnterVan`'s loop mode becomes an explicit importer setting.
Presentation reads game state and never writes it.

## 8. The evidence split

| Rule | Checked by |
| :-- | :-- |
| Every track resolves (node, property, bone) | read-back tests, both clips |
| Ring: 6 frames, keys 0.1 s apart, step 0.1, `LOOP_LINEAR`, discrete, frames < 6 | ring read-back |
| EnterVan: 164 frames, `LOOP_NONE`, step 1/30, from an empty cache | rig read-back (fresh-cache run) |
| Boarding reads frames 22, 32, 48, 53 | rig read-back (the app's constants) and the edge tests |
| States and clips | structure test (every clip the code requests exists) and the state test (real input via `Input.parse_input_event`) |
| Interrupts at every phase boundary | edge tests (input one frame before, on and after frames 32 and 48, and at 0 and 60) |
| The existing behaviour | pins, committed before the change |
| The motion reads; the phases are distinct | frame strip (fixture) and the author in play |
| The ring wraps with no seam | the author in play (five wraps at normal speed) |
| Registration (the handset does not drift in its cells) | the ring's frame strip, the author |
| Against the background | the author: the dash at night on the valley road and under the depot's lights |

## 9. The frame strip (EnterVan)

Background: the real depot forecourt at night, the van where Mission 1 starts, Ethan walking up to
it (the van's own position, not a preview set†). Captured with Movie Maker at 30 fps, trigger (E)
at capture frame 10. Read: frame 10 (trigger, he turns to the door), 32 (frame 22: his hand
starts to reach), 42 (frame 32: hand on the handle, the door still shut), 58 (frame 48: the door
fully open, his foot lifting), 63 (frame 53: the cut begins), 70 (black, seated).

## 10. Predicted failures

| # | Failure | The check that catches it |
| :-- | :-- | :-- |
| 1 | A Godot 3 name (`loop = true`, `playback_speed`) leaves the ring not looping | the ring read-back's `loop_mode == LOOP_LINEAR` |
| 2 | The frame track left on continuous updates sweeps every frame between keys | the read-back's `UPDATE_DISCRETE` check |
| 3 | `EnterVan`'s loop set in a scene, lost on reimport | the rig read-back from an empty import cache |
| 4 | The sheet sliced to the wrong grid shows the wrong cells | the frame-range check and the ring's frame strip |
| 5 | The drawn pulse and the sprite both drawn (two authorities over the ring) | the structure test (the pulse gone) and the strip |
| 6 | Re-expressed constants shift the door so the hand misses the handle | the edge tests and the EnterVan strip at frame 32 |

## 11. Questions

1. **Routes.** The ring is a `Sprite2D` frame track: its read-back sees the `frame` keys, so it can
   check every key is a cell the sheet has and that updates are discrete. EnterVan is an imported
   rig: its read-back resolves bone tracks (`Skeleton3D:mixamorig_Hips`) and pins the clip's length
   and loop mode from an empty import cache, which a frame track has no need of.
2. **Continuous updates on the frame track** would interpolate the integer between keys, showing
   every in-between value (rounded): with consecutive frames it barely shows, but any jump in the
   order would sweep through the cells between.
3. **`Animation.step`** will be 0.1 s for the ring (10 fps) and 1/30 s for EnterVan. Left at the
   default 1/30 s, the ring's keys at 0.1 s would still land (0.1 is three steps), but editor
   snapping would offer positions the brief never names.
4. **Authorities.** `navigation_display.gd` over `RingIcon` (nothing else touches the dash's nodes);
   `driver.gd` over Ethan's `AnimationPlayer` (the cutscene director holds Ethan but plays nothing
   on him; the app asks `driver.gd`).
5. **Clocks.** Both players advance on the process tick; the app reads the door's frame on the
   process tick: no disagreement. If it read on the physics tick at 60 Hz while rendering at 30 fps,
   it could lag by up to one physics step, 1/60 s.
6. **Seam.** A frame track: no duplicate across the wrap, the last key's gap equal to the interval.
   A duplicate (frame 0 keyed again at 0.6 s) would hold the handset alone for two frames each
   wrap: a visible hitch in the pulse.
7. **Imported rig.** In the importer's per-animation settings in `ethan.glb.import`; proven by
   deleting `game/.godot`, importing, and running the read-back.

## Revisions

**2026-11-22, Step 5 (#370).**

1. **Ethan's authority, corrected.** §1 and §11.4 name `driver.gd` alone as the writer of Ethan's
   `AnimationPlayer`. Wiring found a second file that calls `play()`, `seek()` and `speed_scale` on
   it: `push_gait.gd`, the pallet jack's push gait. `driver.gd` builds it with its own player
   (`driver.gd:214`, `PushGait.new(_player)`) and calls it only from its own methods
   (`push_gait()`, `:386`), so the authority is `driver.gd` and the helper it owns, never a second
   owner; `stance.gd` only reads the current clip. The structure test (S5-S8) checks that no other
   script reaches the player.
2. **The ring on the card.** The handset plays in the call card's disc (`RING_AT`, the circle the
   pulse drew), the disc now a fixed 24 px; the caller's initial is drawn only while the handset is
   hidden (talking). `_clock`, used only by the pulse, is gone.
3. **The boarding moments** are `frames / CLIP_FPS` in `first_drive.gd` (`CLIP_FPS := 30.0`), as
   §4 says. PIN2's sampled door start moved one physics sample (1.083 to 1.100 s) and the seat
   (2.017 to 2.033 s), inside its ±0.02 s tolerance: predicted, and the pin is unchanged.
