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

**2026-11-22, Step 6 (#374).** The edge test found Esc during the fade to black (frames 53-60)
seating Ethan behind the pause menu: the HUD runs while paused, so its fade finished. §4's rule
stands (the author: the code was wrong); boarding's fade in `_board_van` now stops while the tree
is paused (`Tween.TWEEN_PAUSE_STOP`), and every interrupt at every boundary passes (48/48,
`TEST-REPORT.md`).

**2026-11-22, two more clips (#377-#383; draft for the author's review).** The author asked for
two more animations, made by us rather than downloaded (#381): a pistol reload and Ethan's shock
after the hit, seen through the windshield (#380). The ring and EnterVan stay the graded pair; these
two follow the same rules (a resource in `game/animations/`, one authority, a phase table in frames
at 30 fps, read-back, state and edge tests). Values marked † are Claude Code's proposals.

*Reload (a committing action; our rig on the pistol, Mission 3).*

| | Reload |
| :-- | :-- |
| What it communicates | Ethan swaps the magazine: the empty one drops out, his left hand brings the fresh one up and seats it, racks the slide, and his hands close on the grip again; the player sees why the gun cannot fire for 2.2 s |
| Plays on | the pistol Ethan holds, `aim_arms.gd`'s own `pistol.glb` (its separate `slide_pistolLow_0`, `clip_pistolLow_0` meshes), and a `SupportHand` marker under it that the left arm's IK reads in place of `LEFT_FROM_RIGHT` while the clip plays |
| Route | **rig, keyed by us:** an `AnimationPlayer` (`ReloadPlayer`) under the held pistol, position and visibility tracks on its parts and the marker; the clip `game/animations/pistol_reload.tres` |
| Authority | `aim_arms.gd` alone calls `play("reload")` and `stop()` on `ReloadPlayer`, reading the handgun's `reloading` (`handgun.gd:27`), which `driver.set_aiming(on, gun)` already hands it (`driver.gd`, the unused `_gun`) |
| Clock | `ReloadPlayer` process idle; `handgun.gd` counts the reload down in `_process` (`:102`), the same tick |

Phase table at 30 fps, 66 frames = `RELOAD_SECONDS` 2.2 s (`handgun.gd:17`); loop `LOOP_NONE`.

| Phase | Frames | What it shows | What the player may do | What the game reads |
| :-- | :-- | :-- | :-- | :-- |
| Startup | 0-17 (18) | the empty magazine drops from the grip (hidden at 17); the left hand leaves the grip and drops to his belt† | fire and R (reload) are ignored; move, aim and Esc work | `reloading` true from frame 0 |
| Active | 18-47 (30) | the hand brings the fresh magazine up and pushes it into the grip, seated at 47 | as Startup | — |
| Recovery | 48-65 (18) | the hand racks the slide (back 48-55, released 56-59) and returns to wrap the grip (60-65) | as Startup | at frame 66 the magazine fills and `reloading` ends (`handgun.gd:109-114`): fire works again |

Interrupts: fire and R are ignored in every phase (`pull()` and `reload()` refuse while reloading,
`handgun.gd:67`, `:77`); lowering the aim mid-reload lets the clip run on with the gameplay timer†;
Esc pauses the clip and the timer together; a retry (`refill()`, `:57`) stops the clip and puts the
parts back (the `RESET` pose).

*Shock (a one-shot in a cutscene; our bone keys on Ethan, Mission 1).*

| | Shock |
| :-- | :-- |
| What it communicates | after the hit, Ethan in the driver's seat: his hands clamp the wheel, a sharp breath lifts his shoulders, his head drops, then he lifts it and stares out through the cracked glass; the player sees his panic (GAME_STORY: "He stops, stares into the rain, and panics") without leaving the cab view |
| Plays on | Ethan's model (`ethan.glb`'s skeleton), seated in the driver's seat for the shot only; his body stays inactive, with no collision added (the struck man's fall moves with any new body) |
| Route | **rig, keyed by us:** bone-rotation tracks in `game/animations/ethan_shock.tres`, its seated base taken from Mixamo's "Male Sitting Pose" (already in `source_assets/mixamo/`, retargeted by name) and the shock keyed over it |
| Authority | `driver.gd` alone plays it (a new `play_seated(clip, seat)` beside `play_clip`); the cutscene director (`cutscene_director.gd`) holds the camera and plays nothing on Ethan |
| Clock | Ethan's `AnimationPlayer`, process idle (as EnterVan) |
| When | inside Mission 1's existing hold after the hit (`HOLD_SECONDS` 4.0 s, `night_freight/first_drive.gd:64`): the shot starts when the van stops and ends before the hold does, so "DRIVE." comes at the same moment as now |

Phase table at 30 fps, 90 frames = 3.0 s†; loop `LOOP_NONE`, ending on the stare.

| Phase | Frames | What it shows |
| :-- | :-- | :-- |
| Grip | 0-11 (12) | his hands close hard on the wheel |
| Breath | 12-35 (24) | a sharp breath: shoulders rise, his head pulls back a little |
| Drop | 36-59 (24) | his head falls toward the wheel, shoulders sag |
| Stare | 60-89 (30) | a slow breath, his head lifts; he stares ahead through the crack |

The shot: the camera outside, off the van's front left corner at the windshield's height, looking
in at him through the crack, the struck man out of frame†. While it plays the player's keys are
held (as in the hold now); E, Enter or Space skips it after 1 s (the director's own rule); Esc
pauses; R recovers as now and ends the shot. It plays once: continuing from the hit's checkpoint
starts in the cab with nothing replayed (C38). The cab view stays bodiless (#355).

*Boundaries for both.* Nothing else changes: Mission 1's timing, the hit, the fall, Mission 3's
fight and the handgun's numbers stay as they are. The exceptions: `aim_arms.gd` reads the marker
while the clip plays; `driver.gd` gains `play_seated`; Mission 1's hold shows the shot.

*Evidence.* Pins before the change (the hold's length and "DRIVE.", the reload's 2.2 s and fire
refused); read-backs (every track resolves: the pistol's parts and the marker as properties, Ethan's
bones as bones; key times within half a frame; `LOOP_NONE`; lengths 66 and 90 frames); the structure
test's table gains both clips and both authorities; state tests by real input (R starts the reload,
the clip plays exactly while `reloading`; the hit plays the shock, then "DRIVE."); edge tests at the
reload's frames 0, 18, 48 and 66 (fire, R, Esc one frame before, on and after); the Mission 1 and
Mission 3 suites; a frame strip of each, read at its phase boundaries, and the author in play.

**2026-11-22, the reload's setup (#385).** Rendered on Ethan's rig, the left hand could not reach
a magazine under the gun held at arm's length (about 0.60 m from his shoulder), so it fell short at
his chest. The clip now also keys the held gun's `Grip:position` (set only once by `aim_arms.gd`,
at setup, so the clip is its one writer while it plays): drawn in toward his chest by frame 6 and
pushed back out from 58 to 65, as a shooter brings a pistol into his workspace to reload. Its keys
ease in and out (linear with a transition of -2; cubic overshot by 18 cm over the long hold). Seen
over his right shoulder, as the game's aim camera sits, the drawn-in gun hides behind his shoulder:
open for the reload's strip and the author's look.

**2026-11-22, the reload by motion capture (#386-#390).** The author rejected the hand-keyed reload
(`3b00d46`: "hes not even holding gun realistically"); its rest pose was Mission 3's IK hold, the
fist above the gun. It is replaced by two Mixamo clips the author downloaded for Ethan (Ch33, 30
fps), whole and untrimmed ("i want exact complete animation in the game"). This supersedes the
reload rows above; the shock is unchanged.

| | Reload (motion capture) |
| :-- | :-- |
| Clips | `PistolReload` (Mixamo "Reloading", 100 frames, 3.33 s, once) and `PistolIdle` ("Pistol Idle", 250 frames, a low ready, looping), converted into `ethan.glb` by `tools/art/convert_mixamo.py` with upper-body tracks only (spine, neck, head, shoulders, arms, hands, fingers); `PistolAim`, the reload's first frame, a one-frame slice set in `ethan.glb.import` |
| Route | **imported 3D rig**; loop modes in `ethan.glb.import` (`PistolIdle` `LOOP_LINEAR`, `PistolReload` and `PistolAim` `LOOP_NONE`) |
| Plays on | Ethan's skeleton, through a second `AnimationPlayer` (`UpperBody`) that `driver.gd` builds and alone plays, keying only upper-body bones, after his own player, so his legs keep Idle, Walk and Run |
| The pistol | attached to his right hand bone (`BoneAttachment3D`), held in his captured grip; its magazine and slide keyed by us in `game/animations/pistol_reload.tres` to his hands' frames (out at about 30, in his left hand to the grip, seated at 45, the slide back in the overhand rack about 58) |
| Gameplay | `RELOAD_SECONDS` 2.2 → 100/30 s (3.33 s), so the magazine fills as his hands finish (PIN5 changes, predicted; its update is its own commit) |
| Authority | `driver.gd` over `UpperBody` (armed: `PistolIdle`; aiming: `PistolAim`; reloading: `PistolReload`), reading the handgun's `reloading`; the gun parts' player owned by the code that attaches the pistol |

Phase table (100 frames at 30 fps): startup 0-29 (the gun tipped up, the left hand to the belt),
active 30-47 (the magazine out, the fresh one in his hand, seated at 45-47), recovery 48-99 (the
overhand rack 52-64, back on aim by 70). Fire and R are ignored throughout; Esc pauses. Every
earlier clip in `ethan.glb` must stay as it was: sampled before and after the re-conversion and
compared.

**2026-11-22, the rifle and its clips (#393-#396).** Ethan's weapon is a rifle (C68): jeandiz's
M16 (`game/features/weapons/rifle/m16.glb`, CC BY), held and moved with fifteen Mixamo clips for Ch33
at 30 fps, whole and untrimmed. It supersedes the pistol rows above (their clips stay converted but
unused); the shock is unchanged. Values marked † are Claude Code's proposals.

| State (armed) | Clip, from | Plays on | Enters when | Leaves when |
| :-- | :-- | :-- | :-- | :-- |
| Slung | none (the rifle on his back, on `Spine2`) | — | Maya hands it over; after Put Away | aim held |
| Draw | `RifleGrab` ("Grab Rifle From Back", 88) | upper body | aim held while slung | its last frame |
| Ready | `RifleIdleA` / `RifleIdleB` ("Rifle Idle", 258; "Rifle Idle (1)", 232), alternating | upper body | drawn, not aiming | aim held; moving; put away |
| Raise | `RifleAimDown` ("Rifle Aim To Down", 46) backward | upper body | aim held while ready | its first frame |
| Aim | `RifleAim` ("rifle aiming idle", 90, looping) | upper body | raised | aim released; fire; R |
| Fire | `RifleFire` ("firing rifle", 9) | upper body | a shot (left mouse while aiming) | its last frame, back to Aim |
| Lower | `RifleAimDown` forward | upper body | aim released | its last frame, to Ready |
| Reload | `RifleReload` ("reloading", 100 = 3.3 s) | upper body | R with room in the magazine | its last frame (the magazine fills) |
| Hit | `RifleHit` ("hit reaction", 14) | upper body | a guard's round hits him | its last frame |
| Put away | `RifleAway` ("Rifle Put Away", 70) | upper body | before he gets into the van | its last frame, to Slung |
| Moving, armed | `RifleWalk`, `RifleWalkBack`, `RifleRun`, `RifleRunBack`, `RifleStrafe`, `RifleStrafeLeft`, `RifleStrafeRight`, `RifleStrafe2` (the pack's gaits, walked in place) | his own player (whole body) | a move key while drawn | input released |
| Turning, armed | `RifleTurnLeft` ("turn left", 27), `RifleTurnRight` ("turning right 45 degrees", 31) | his own player | standing, his facing swinging past 45°† | the turn done |

Left out: "rifle jump" and "toss grenade" (the game has no jump and no grenades; adding them is a
new mechanic); "Ch33_nonPBR" (the character, already in the game).

The committing action, the draw (88 frames at 30 fps)†: startup 0-39 (his right hand goes back over
his shoulder), active 40-59 (the hand takes the rifle: it moves from his back to his hand at the
frame the hand reaches it), recovery 60-87 (the rifle comes round to the ready). Aim, fire and R are
ignored until 88; Esc pauses. The reload (100 frames): startup 0-29, active 30-47 (the magazine
out and the fresh one seated at 45-47), recovery 48-99 (the charging handle pulled at 52-64).

Gameplay numbers†: a 30-round magazine and one spare; `RELOAD_SECONDS` 100/30 s (the clip's length,
so the magazine fills as his hands finish; PIN5 changes, predicted); hitscan, damage and range as
the pistol's. Owners: `driver.gd` alone plays his own player and `UpperBody` (reading the gun's
`armed`, `reloading` and the shot), attaches the rifle to his back or his right hand, and keys
nothing else. Upper-body clips keep only the bones above the waist (`make_rifle_upper_body.gd`);
the gaits keep the whole body. Every earlier clip in `ethan.glb` stays as it was (sampled before
and after and compared).

**2026-11-22, the rifle wired in and the shock remade (#397-#405).** *The rifle* hangs at his
right hip when slung, not across his back: both captured clips put it there (the put-away lets go
at frame 62, the draw takes it at 37). Every frame the rifle is placed from his right fist's grip,
upright through the whole reload, with his left hand moved by IK onto the part it handles (the
handguard, the magazine, the charging handle). The handle and bolt carrier slide 8 cm back at
frames 62-65. He fires only from the aim (`can_fire`) and reloads only with the rifle drawn
(`can_reload`); he puts it away before boarding (`stow_rifle`, then EnterVan). *The shock*
replaces the 90-frame table above. The author's look (#404): his hands must be on the wheel as
seen from outside, and the fear must read. It is 105 frames (3.5 s, `SHOCK_SECONDS`, inside the
4.0 s hold). Its base is EnterVan's last frame, seated at the pedals, not the Sit pose (that pose
raises one leg). Over it he hunches forward over the wheel throughout. Its phases: startle 0-8
(head jerks back 15°, shoulders up), panic 8-30 (heaving breaths, a glance out), disbelief 30-47
(the head shakes "no", ±17-21°), drop 47-63 (the head falls 56°), checks 63-83 (left mirror 44°,
right 27°), stare 83-104 (level). His wrists go by IK to the rim of the cab's own wheel, at ten to
two, read from the wheel mesh's bounds (its origin lies off the rim's middle). The IK's grip closes
over frames 0-11. His shoulders are set 0.43 m from the rim, about 90% of his 0.48 m arm, so his
elbows stay bent. To make that reach he is moved forward in the seat by at most 0.25 m, because
the cab camera's eye sits behind where a driver's shoulders would be. The shot looks down over the
dash from a little above his eyes, fov 37° to 33°, so his head and his hands on the wheel both sit
inside the letterbox.

**2026-11-22, Step 7 (#405-#406; TUNING.md).**
1. **§9's capture frames are two frames early.** EnterVan's frame N falls on capture frame
   12 + N, not 10 + N: one frame for the input to reach the app, one for the walk to
   `BOARD_SPOT`. Read the strip at capture 12, 34, 44, 60, 65, and at 82 for seated (after r1).
2. **r1 (Claude Code's decision under the author's delegation, #406; not the author's
   observation).** §4's cut moves from frame 53 to 62. Recovery becomes 48-68: from 53 he steps up
   (root motion in the clip), at 58 he is on the step, and from 62 he goes in behind the door as
   the fade begins; he is seated at 69. Before this, the cut came while both his feet were still
   on the ground, so §1's "climbs in" was never seen. As predicted, PIN2's seat moves from
   2.017 s to 2.333 s, re-pinned in its own commit. The edge test's seated boundary becomes 69.
   The author's verdict on r1, and the observation-driven revision, are open.
3. **The reload's edges** (the rifle's revision): fire, R and Esc one frame before, on and after
   frames 0, 30, 48 and 99, all as the table says. The gun's timer ends the reload one 60 Hz tick
   before the clip's last frame.
