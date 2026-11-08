# SCRIPT — Blackridge, Rain and Vapour

Narration as spoken by Liam (Kokoro `am_onyx`), 28 beats, 1541 words, 460.3 s measured.

## B00 · ASK · 17.0 s

Namaste. This is Liam, in for Bear. This is Blackridge: No Way Back, a Godot game where you drive a freight van through a rainy town at night. The prompt on screen is a reconstruction; the real work began from the author's brief. Let's take apart the four particle effects this build added, and how each was tested and priced.

## B01 · BLUF · 11.8 s

Particle effects are rules. In Blackridge, four of them answer the wipers, the brakes, the lamps and the engine. Each one was predicted, tested, tuned against frame strips, and priced on the G P U.

## B02 · SETUP · 16.9 s

The author chose four effects and wrote their brief. Effect A: two one-shot events, the wiper's flick at each top turn and the roof's spill on a hard brake. Effect B: two continuous ones, rain in each lamp's light and exhaust that follows the throttle. All are G P U particles in Godot four point seven point two.

## B03 · SPEC · 18.9 s

Before any effect existed, the brief fixed each one's intent: timing phases, contrast, scale, change over life, variation and layered emitters. It predicted ten ways they could fail, every price, and a budget of one point four five milliseconds of G P U time for all four. It was committed before the build, and Claude's project file imports it.

## B04 · CODE · 16.7 s

Every particle system has three parts, and this scene file holds all three. Emission: how many, and for how long, three hundred puffs living one point six seconds. Process: how they move and change, here its own material. Draw: what each puff looks like, a quad and its shader. The settings live in the scene, not in code.

## B05 · RESULT · 12.2 s

Here's that scene behind the van, in a fixture. After the ignition, puffs leave the pipe fast and stop within a metre. On the throttle the plume thickens and glows red in the brake lamps. Switched off, it rises and thins away.

## B06 · PRICE · 16.0 s

Why can't a headless run price this? Headless, Godot uses a dummy renderer: nothing is drawn and no particle is simulated. The cost script's empty-scene control reads two thousandths of a millisecond, the game half a millisecond, and every effect the same as none. That's only the C P U's share.

## B07 · CODE · 15.5 s

A one's event is the van's wiper swept signal, sent every half stroke. The handler acts only at the top turn, with the wipers on. It takes a free burst from a pool of two, so a new flick can overlap the last one's spray. If both are still alive, it logs a miss rather than cut one short.

## B08 · RESULT · 13.9 s

In play, on fast wipers: a flick at every top turn, about one a second, beside the passenger blade's line of water. This is scripted input on the real game. The log has the wipers fast at one and a half seconds, and nine flicks by eight and a half.

## B09 · TUNING · 18.8 s

The first strips showed nothing: three-millimetre drops lit only by the night were invisible, and the spill hid behind the wet glass. At the author's request the drops became water that bends the light behind it. Claude predicted each frame first; three were wrong, and two were off in brightness. The author played both effects and kept them, overruling two of Claude's readings.

## B10 · CODE · 13.8 s

A two fires on a new hard brake. The brake comes on at eight metres a second or more, and the van slows at six metres a second squared for two physics ticks. A second brake while the spill is alive, or during the roof's twenty-second refill, is ignored.

## B11 · RESULT · 13.6 s

In the fixture, a second hard brake at frame twenty-five changes nothing; the first spill's streams run on. In the author's first play the spill never showed at all: it fired, but the wet windshield drew over it. One setting, its render priority, fixed that.

## B12 · CODE · 15.2 s

B one's condition is distance. Each tick, the lamps within sixty-five metres of the camera, eight at most, are wanted. A newly wanted volume is shown and restarted, so its preprocess fills the whole fall path at once. One no longer wanted stops emitting, drains, then hides.

## B13 · RESULT · 15.2 s

The fixture: a few frames after the start, rain fills the light from just under the lamp to the ground, steady, then drains from the top after the stop, gone by frame one hundred and ten. In play, the pause menu pauses it with the game, and resume carries on. On the title screen it's hidden.

## B14 · CODE · 16.7 s

B one's own feature is the sub-emitter. Drops collide with a height field, and each landing sets off a splash of three droplets. Claude's first build used hide-on-contact collisions, which in four point seven point two never set off the splash. Rigid collisions do. Neither A effect uses a sub-emitter.

## B15 · RESULT · 13.3 s

Here's the road under that lamp, cropped and enlarged from the strip: drops reaching the ground, and at most a few specks where they land. Real-size splashes are too faint to pick out from a few metres away, and the report records that as a limitation.

## B16 · CODE · 16.8 s

B two's own feature is a value-driven amount ratio. After ignition it waits, ramps up from zero, then follows the throttle: point one five at idle, plus point six five times the throttle. The amount stays three hundred; only the share that emits changes. With the engine off, it's zero at once.

## B17 · RESULT · 19.1 s

Through the reverse camera, less of it shows: nothing at idle or on the throttle, a narrow red column once the brake lamps light it, and a faint grey wisp after switch-off, gone a second later. The state test reads the ratio itself: point one five at idle, point eight at full throttle, zero when off, frozen while paused. In play, the dash shows that same camera.

## B18 · TUNING · 20.7 s

The first B strips showed no rain, and almost no vapour. At the author's request the tuning used real drop sizes and speeds, drew each drop as the streak a camera sees, and made the exhaust a jet that stops. Around them, the lamps, the wet road and the roadside were rebuilt too, also at the author's requests. B two matched every predicted frame, B one all but two details. The author kept both.

## B19 · CODE · 18.7 s

Step six: Godot's own code for B two's process material, generated by its converter and saved by Codex at the author's direction. Line two fifty-four grows each puff along the brief's scale curve, to six times its birth size. Line two fifty-five fades it along the alpha curve, densest near the pipe and gone by the end of its life.

## B20 · RESULT · 11.9 s

And that's those two lines on screen: puffs born small and dense at the pipe, growing as they drift, and fading as they grow. The process shader shapes them over their life. How they look belongs to the draw step's material.

## B21 · TESTS · 19.1 s

What the tests proved. Configuration tests read every setting back from the scenes: four hundred fifty-one checks for A one alone. State tests drive the real game through events, retriggers and pause. Both mutations, a Godot three name and a drifted spread, fail as they should, and the twenty-two earlier test runs still pass. None of this shows what the screen shows.

## B22 · PRICE · 18.1 s

Then the G P U price. Godot's own timer reads zero on Metal, so Claude used Apple's Metal H U D, showing and hiding each effect in turn. A one and A two are within budget, B one at its budget, and B two over: one point one milliseconds against point three. The author kept it. The frame itself is already twenty-six milliseconds.

## B23 · LIMITS · 22.9 s

Mistakes caught: particles ignoring their own size, rain streaks a quarter as wide as they should be, splashes that never fired, a spill hidden behind the glass. The author overruled two of Claude's readings. Still uncertain: A one's below-zero price, the tailpipe's position, and that heavy frame. Next step: make B two cheaper. Textures: drawn by a script, plus Poly Haven's C C zero assets. The game shown is revision c one c nine d eight b.

## B24 · CONTRIBUTIONS · 16.4 s

Who did what. The author chose the four effects, wrote the brief, directed every change, played and judged every effect, and made every final call. Claude Code built, tested, tuned, captured the strips and measured, all at the author's direction. Codex saved the Step six shader, also at the author's direction.

## B25 · VERDICT · 17.5 s

Let's recap with Claude. Implemented: four G P U effects, each on a real event or condition, tested and tuned. Verified: predictions against frame strips, and mutations that fail the tests. Still open: B two's G P U cost, and a heavy frame. Human judgement: the author played every effect and made every call.

## B26 · HANDOFF · 28.9 s

Your turn. Paste this into Claude. Please use Walker to help me tune one particle setting in my game. I will pick the setting myself. Before you change anything, ask for my prediction of what the next frame strip will show and what it will cost on the G P U, then capture the strip, measure the price, and show me predicted versus measured. It makes you commit before you look, and makes Claude measure instead of guess. Judge the answer on three things: it asks for your prediction first, shows the strip and the price, and flags any mismatch. Liam, in for Bear.

## B27 · OUTRO · 4.3 s

Blackridge, Rain and Vapour. At Nik Bear Brown.
