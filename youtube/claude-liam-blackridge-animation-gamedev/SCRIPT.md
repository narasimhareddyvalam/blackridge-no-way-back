# SCRIPT — Blackridge, Frame by Frame

Narration as spoken by Liam (Kokoro `am_onyx`), 27 beats, 1478 words, 439.6 s measured.

## B00 · ASK · 16.9 s

Namaste. This is Liam, in for Bear. This is Blackridge: No Way Back, a Godot game where you drive a freight van through a rainy town at night. The prompt on screen is a reconstruction; the real work began from the author's brief. Let's take apart the four animation clips this build added, and how each was timed and tested.

## B01 · BLUF · 10.9 s

A clip is a resource: tracks, keys, a length and a loop mode. In Blackridge, each of four clips has exactly one owner that plays it, and its timing is designed in frames.

## B02 · SETUP · 16.9 s

Four clips. The ring is the cycle: a sprite on the dash, looping while Maya's call rings. Enter Van is the committing action: Ethan's imported rig getting into his van, played once. Two more ride the same rig: a motion captured rifle reload, and a keyed shock after the hit. Godot four point seven point two.

## B03 · SPEC · 16.4 s

Before any clip existed, the brief fixed the cycle's spec, six frames at ten per second with its seam rule, and Enter Van's phase table in frames: startup, active and recovery, what the player may do in each, and what the game reads. Then pins recorded how the game behaved, all committed before setup.

## B04 · CODE · 17.0 s

So what is a clip? This file is the whole ring. Length point six seconds, loop mode one, linear, and a step of point one. One value track, Ring Icon's frame, with update discrete, so the integer jumps instead of sweeping. Six keys, frames zero to five. The last key sits one step before the length: that's the seam rule.

## B05 · RESULT · 15.9 s

Here's the sheet that track reads: six sixty-four pixel cells in one row, drawn by a script in white, so the dash can tint them. The sprite slices it with six frames across and one down. On the dash, the handset alone, then one, two, three arcs, then the arcs fading away, and back to the handset.

## B06 · CODE · 15.6 s

One authority means exactly one node writes to an animated node. For the ring it's the navigation display, and only these lines call play and stop. It reads its own call state and call seconds: ringing, or answering itself, with the timer below zero. Nothing else touches the dash.

## B07 · RESULT · 15.3 s

In play: Maya calls on the climb out of the depot, and the camera zooms to the dash. The handset pulses while it rings. This is scripted input on the real game, in real time. The state test saw every cell, the wrap from five to zero, and the icon hidden once the call connects.

## B08 · CODE · 14.1 s

Enter Van is Mixamo's Entering Car on Ethan's imported rig, a hundred sixty-four frames at thirty per second. Its loop mode is set here, in the importer's per-animation settings: zero, loop none. In a scene, it would be lost on the next import.

## B09 · RESULT · 16.7 s

In play, it runs once: he gets in, and the cab view takes over. To prove the setting holds, the cache was deleted and the game imported fresh. The read-back resolved all one hundred fourteen bone tracks and read loop none. Set to one in the importer instead, the clip imported looping, and the same test failed two checks.

## B10 · CODE · 14.1 s

Designing feel in frames means the phase table becomes code. The boarding reads Enter Van's frames over thirty: the reach from frame twenty-two, the hand on the handle at thirty-two, the door fully open at forty-eight, and the cut to black at sixty-two.

## B11 · RESULT · 13.8 s

Here's the frame strip at each boundary, a fixture at the depot at night. Frame zero, he faces the door. Twenty-two, the reach. Thirty-two, the hand on the handle, the door shut. Forty-eight, the door open. Fifty-eight, he's rising into the cab. Then black, and seated.

## B12 · CODE · 12.9 s

The two clocks. Ethan's animation player advances on the process tick. The boarding loop reads clip time and sets the door, then waits for the next process frame. The brief predicted no disagreement, because both use the process tick.

## B13 · RESULT · 18.8 s

The per-frame log disagrees by one frame. The process frame signal resumes the loop before the player advances, so on the frame where the clip reads thirty-four, the door holds the value for thirty-three. That's one thirtieth of a second, below what the eye separates, so it stays. The reload has the same kind of gap: its timer ends one sixtieth early.

## B14 · CODE · 12.9 s

Enter Van's owner is the driver script. Play clip is the only path into Ethan's animation player, with the rifle helper it builds and calls. The app asks; it never plays. The structure test checks that no other script reaches the player.

## B15 · RESULT · 20.2 s

Now an interrupt in each phase, by real input. In startup, W is held: he doesn't move and the clip runs on. In the active phase, Escape pauses: the clip and the door freeze, then resume. In recovery, R recovers: he's seated at once with the door shut. The edge test ran forty-eight of these, all passing, and found one bug: Escape during the fade seated him behind the pause menu.

## B16 · TUNING · 19.6 s

Then tuning. Claude read the first strip: at the old cut, frame fifty-three, both his feet were still on the ground, so the brief's climbs in was never seen. The author was away, so Claude decided: move the cut to sixty-two, predicting him rising into the cab before the fade. The second strip matched five of six predictions. The pin moved as predicted. The author's verdict is still open.

## B17 · CODE · 18.0 s

The third clip. The author rejected a hand-keyed pistol reload, chose motion capture, then a rifle. Mixamo's reloading plays on a second player that keys only the upper body, so his legs keep their own clips. These lines enter the reload while the gun reloads, and leave it when the gun is done. The gun's timer is the clip's length, ninety-nine thirtieths.

## B18 · RESULT · 15.4 s

In Mission three: the empty magazine drops at frame fourteen, the fresh one comes up in his left hand, seated at forty-seven, then the charging handle pulled back eight centimetres. Fire and R are ignored until the end. This take is a fixture: he was armed directly, skipping the handover.

## B19 · CODE · 18.3 s

The fourth clip is keyed by a script over Enter Van's last, seated frame. Play seated puts Ethan in the driver's seat and plays it. These lines slide him forward until his shoulders are forty-three centimetres from the rim, so his elbows stay bent; set each hand's target on the rim, read from the wheel mesh itself; and fade the grip in over eleven frames.

## B20 · RESULT · 15.3 s

Seen through the windshield in Mission one's four second hold: a startle, panicked breaths, his head shaking no, the drop toward the wheel, a look at each mirror, then a stare. The author asked for the hands on the wheel and fear that reads; this is that revision. A fixture, with no struck man in frame.

## B21 · TESTS · 20.5 s

What the tests proved. Four read-backs resolve every track and pin each clip's key times, step and loop mode. The structure, state and edge tests pass, and every earlier suite still does. Three mutations, a broken track, loop none on the cycle and a key past the sheet, fail as they should; the fourth, a fresh import, can't, by design. None of this shows the motion reads, or that the ring wraps without a seam.

## B22 · LIMITS · 22.1 s

Mistakes caught: the pause bug, a second script playing Ethan's clips, hands short of the wheel, and the brief's strip frames two early. Overruled: the author rejected Claude's hand-keyed reload, then corrected its rifle hold in five prompts; no strip reading yet. Uncertain: the seam, and r one. Next step: the author plays r one slowed down. The sheet is ours, drawn by a script. The game shown is revision one, E, seven, seven, six, five, E.

## B23 · CONTRIBUTIONS · 15.7 s

Who did what. The author chose the clips, rejected what didn't look real, downloaded the motion capture, corrected every look, ruled on the pause bug and approved each step. Claude Code drafted the brief, built, wired and tested the clips, captured the strips, and made r one while the author was away.

## B24 · VERDICT · 15.1 s

Let's recap with Claude. Implemented: four clips, each a resource with one owner. Verified: read-backs, edges at every boundary, mutations that fail. Still open: the author's verdict on r one and the seam in play. Human judgement: the author corrected every look.

## B25 · HANDOFF · 26.8 s

Your turn. Paste this into Claude. Please use Walker to help me retime one phase of one clip in my game. I will pick the phase myself. Before you change anything, ask for my prediction of what the frame strip will show at each boundary, then change the phase table, not the keys, capture the strip, and show me predicted versus seen. It makes you commit before you look. Judge the answer on three things: it asks for your prediction first, changes only the table, and flags every mismatch. Liam, in for Bear.

## B26 · OUTRO · 4.5 s

Blackridge, Frame by Frame. At Nik Bear Brown.
