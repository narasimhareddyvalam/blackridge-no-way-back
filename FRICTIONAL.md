# FRICTIONAL — honest log

The author's log of what they tried, expected, saw, checked and learned, with
human and AI work kept apart. Each entry is dated and points to a commit,
prompt, test log or capture. AI may organise these notes, but it does not
write the author's experiences. Entries marked "recorded by Claude Code"
contain facts only. Assignment 5's entries come first, as submitted at tag
`a5`; Assignment 6's begin under "Assignment 6" at the end.

## Entry format

- **Tried / expected:**
- **What happened:**
- **Checked or changed in response:**
- **Learned / still unresolved:**
- **Human vs AI:** what I wrote; what the agent wrote; what I accepted,
  modified or rejected
- **Trace:** commit, prompt, log or capture

## 2026-10-28 — Changing games for the final

I decided to change my game from Assignments 2–4 because I wanted to work on
something different for my final project. My previous game was a 2D horror
game, but I wanted to challenge myself by making a 3D first-person game with
better graphics and more interaction. I also wanted to build something that
feels more realistic and has an interesting atmosphere. That is why I chose
*Blackridge: No Way Back*. I felt this game would give me more opportunities to
work with lighting, weather, shaders, and the environment. I knew changing games
would mean more work, but I was more interested in this idea and wanted to try
something new.

## 2026-10-28 — Setup before the specification (recorded by Claude Code)

- Claude Code read the assignment brief and the project, and explained the
  requirements.
- At the author's request it initialized Git with a repo-only identity and made
  three commits:
  - `e81ec92`: the project as found;
  - `7385eb8`: the game-change note in `fractional.md`;
  - `2b6b251`: the course wrapper `scripts/run-test.sh`, adapted for `game/`,
    with the baseline logs.
- Baseline at 60 fps through the wrapper: regression 64/64, integration 29/29.
- Claude suggested candidate effects (impact flash, night illumination, brake
  lamps) and textured objects. The author's choice is recorded in
  `CHANGE-BRIEF.md`.
- Claude created empty skeletons for `CHANGE-BRIEF.md`, `LANGUAGE-NOTES.md`,
  `FRICTIONAL.md`, `TEST-REPORT.md`, `SOURCES.md` and `SUBMISSION.md`: headings
  and copied questions only.
- Correction recorded 2026-10-29: the line above said no shader content
  existed before `CHANGE-BRIEF.md`. That was true when it was written, but
  the author then drafted all three shaders from their own notes before
  writing the brief. The brief was committed (`2729c26`) before any shader
  was committed (`c055037`). No driver or test content existed before the
  brief.

## 2026-10-28 — My own notes (written 2026-10-29, looking back)

At first, I started working on the shaders before properly finishing my change
brief. I was trying to understand how shaders work in Godot, so I started
experimenting with the code instead of planning everything first. Later, I
realized that I should have written the brief first so I knew exactly what I
wanted to build and test.

I also changed some of my shader ideas. Initially, I was considering effects
like wet metal and rain, but I felt that they were not the best choice for my
game. Since my game is mainly from inside a van, I thought dashboard dimming
and foggy windows would make more sense. They would also be easier to notice
while playing.

I reviewed the CLAUDE.md draft and wanted the instructions to be more clear
about what Claude Code could and could not change. I wanted it to follow the
assignment requirements, avoid making unnecessary changes to my existing game,
and check the results properly. I also wanted the instructions to make it clear
which parts I would do myself and which parts Claude Code could help with.

- **Trace** (added by Claude Code): brief `2729c26`, committed before the
  first shader `c055037`; final choices in `CHANGE-BRIEF.md` §1; CLAUDE.md
  draft `ea88542` (`prompts/prompt-1.txt`, `sessions/session-1.jsonl`) and
  review `4bba9b2`.

## 2026-10-28 – 2026-10-29 — Agent work (recorded by Claude Code, facts only)

- **CLAUDE.md, session 1** (`ea88542`, review `4bba9b2`):
  - `claude -p` with the course's tool scope: success in 34 of 40 turns;
  - 4 Bash calls denied;
  - read-only `cat`/`grep` still ran outside the allowed list, so checksums of
    `game/shaders/` were the real guarantee: unchanged.
- **CLAUDE.md review** (`4bba9b2`): Claude listed the fixes; the author
  approved all of them ("yes, apply all fixes and commit"); Claude applied
  them.
- **Brief:** the author's `night_amount` default was 1.0 in the shader but
  0.0 in the brief. Claude flagged it. The author chose 0.0 and changed it
  themselves with a `!` command; Claude declined to edit the shader.
- **Driver and test** (`132a068`):
  - first run 29/30. The failure was a test bug: it counted one frame after
    the fade had finished. The test was fixed;
  - float rounding made the 60 fps fade land one frame late, so the driver
    now snaps within 1e-6;
  - then 30/30 at 30, 60 and 144 fps; existing suites 64/64 and 29/29.
- **Night cluster captures** (`5669a40`): the measured pixels at 0, 0.5 and
  1.0 equal the author's hand predictions exactly. At 2.0 the result differs
  from 1.0, so `hint_range` did not clamp a value set from code.
- **Hint experiment** (`5669a40`): under Compatibility both quads show
  64/128/192. Under a Forward+ comparison the data quad shows 137/188/225,
  which is the author's prediction. A diagnostic with a separate data-only
  texture gives the same split.
- **Fog** (`0b8fbb0`, `384e5b8`, `2204b55`):
  - textures written by code;
  - the first import defaulted to Detect, no mipmaps, and detect-3D on; all
    were set explicitly;
  - calibration GL 0.5792 / DX 1.4208, and `fog_normal.png` 0.0033 / 1.9967;
  - Claude made both materials from the brief's values and added the overlays.
- **Flagged:** the author's `foggy_windshield.gdshader` draft does not match
  CHANGE-BRIEF §5. It uses a screen texture, is unshaded, has `ALPHA = 1.0`
  and only one uniform group. It needs rewriting by the author.
- **Fog shader rewritten** (`3bac73e`): the author rewrote it. The audit
  (`fe625c4`) then found two differences from the brief, multiply instead of
  `mix()` and fixed ROUGHNESS and SPECULAR values. The author settled both
  with a dated brief revision (`a09eb4e`).

## 2026-10-29 — What I accepted, changed or rejected

I did not accept every idea Claude suggested. I decided not to use brake lamps
because I wanted to focus on effects that I could notice more while driving. I
changed impact flash to night dashboard dimming and wet metal to foggy glass
because I felt they suited my game better.

When Claude pointed out that my fog shader did not match my brief, I rewrote it.
I also chose to keep `night_amount` at 0.0 and corrected it myself. Later, I
changed my Q2 and Q7 answers after Claude pointed out that my explanations were
not fully accurate. I used AI for suggestions, checking, and the parts the
assignment let it write (the CLAUDE.md draft, driver, tests, texture script,
materials, overlays, captures and audit), but I made the final decisions about
what to keep and change.

- **Trace:** candidate effects in the setup entry above;
  final choices in `CHANGE-BRIEF.md` §1; `night_amount` default in the agent
  log above; fog shader rewrite `3bac73e`; revised Q2 and Q7 in
  `LANGUAGE-NOTES.md` (`e72e9d9`).

## 2026-10-29 — My own notes on testing

The recorded shader captures show how the dashboard colour and brightness
changed with different `night_amount` values. They also show how the fog
settings affect the windows, including the fog around the edges and the clear
area in the middle. In the hint experiment, Compatibility showed the same three
grey bands with values 64, 128 and 192 on both quads. In Forward+, the data
quad showed 137, 188 and 225, which matched my prediction. From this, I learned
that the renderer can affect how texture colour values are handled, so I should
not assume the same results in every renderer.

For the gameplay test, I wanted to check whether the shader effects worked
together with the existing controls. The L key is supposed to toggle the
headlights and make the dashboard fade between normal and night lighting. I
also wanted to check that the LIGHTS text and click sound still worked. The J
key is supposed to lower the driver's side window, and the fog overlay should
move together with it. These are the things I used to check whether the effects
were properly connected to the game. I played the game to check them. When I
pressed L, the light on the dashboard changed, I heard the switch click, the
LIGHTS text changed, and the headlights turned off and on. When I pressed J,
the driver's window went down with the fog.

- **Trace** (added by Claude Code): `evidence/captures/night_cluster_*.png`
  and `night_cluster_samples.txt`; `evidence/captures/fog/`;
  `evidence/captures/hint_experiment_compatibility.png`,
  `hint_experiment_forward_plus.png` and `hint_diagnose_results.txt`; playtest
  screenshot `evidence/playtest/os_screenshot_cockpit_headlights_on.png`;
  results in `TEST-REPORT.md`.

## Assignment 6

## 2026-11-07 — From choosing the effects to the brief (recorded by Claude Code, facts only)

- Claude Code checked the project: nothing for Assignment 6 existed (no particle
  node, no `a6` tag).
- It offered effects tied to the game's own events. The author chose A1 the wiper
  flick and A2 the roof spill on hard braking as Effect A, and B1 rain in every
  lamp's light and B2 exhaust vapour as Effect B, all four graded (C52; prompt
  log #131–#141).
- It wrote `docs/PARTICLE_RESEARCH.md`, moved the old brief to
  `docs/PHASE_BRIEF.md` (`7bbf0a4`) and added a headings-only template
  (`c1ee48f`).
- Asked to write the brief, it declined, quoting the assignment ("You write:
  CHANGE-BRIEF.md, every prediction, every verdict and the process-shader
  notes"), and gave step-by-step instructions instead.
- The author then supplied a completed draft
  (`~/Downloads/CHANGE-BRIEF-completed.md`, 2026-11-07 17:18). How the draft was
  written is not recorded here; the author's own entry below says.
- Claude Code reviewed the draft against the assignment and the code, and listed
  8 must-fix and 10 should-fix items.
- At the author's request it then:
  - corrected 14 technical errors: the billboard mode, vertex colour, size
    units, exact Godot names, A1's summary keys and the Assignment 5 shader
    names;
  - wrote in the author's decisions, chosen from its questions: both B effects
    graded, B1's condition (within 65 m of a lamp) and feature (collision with
    splashes), rain that appears already falling, four realism fixes, A2 moving
    with the van, the spill at the hit, AI-generated textures (later drawn by a
    script instead, #142), and having Claude Code propose the exact values;
  - proposed 59 values, marked † in the brief, from the author's descriptions
    and the research, for the author to check: directions, colours, visibility
    boxes, the previews' second triggers, the splash emitter and collider, B1's
    lifetime and streak size, and A2's gravity. Four of B1's frame-strip
    expectations and the two retrigger lines it wrote are marked † too;
  - left the price predictions and the other predictions as the author wrote
    them, except the peak-particle arithmetic (†).
- Still open: the author's check of the † values; the B1 price predictions,
  made for 160 drops per lamp; the textures' model and prompts; and three points
  that only a windowed run or Step 6 can confirm.
- Trace: `7bbf0a4`, `c1ee48f`; `docs/AUTHOR_PROMPTS_AND_DECISIONS.md`
  #131–#141; C52; the brief's "How it was made" line.

## 2026-11-07 – 2026-11-08 — The build, the tuning and the world (recorded by Claude Code, facts only)

- **The build (#142–#144).** Asked to finish its own parts and leave the author's tasks for the
  end, Claude Code:
  - built the four effects, drawing their textures with a script instead of generating them
    (`5913f81`);
  - wired them to the game's events (`0a76154`);
  - wrote the configuration and state tests, the six mutations (all exit 1, `16fcdc5`), the
    previews, the strip script and the cost script (`42772e1`).
- **Its own mistakes, caught in its windowed checks:**
  - the † value `LampSplash` `emitting = false` (brief revision 1);
  - camera-facing particles drawn at the quad's size, ignoring their own scale (revision 4,
    `ae928ff`);
  - B1's streaks a quarter of their quad's width (revision 5, `ed6b45f`).
- **With real materials the effects could hardly be seen at night.** The author asked: "make
  sure its clearly visible like in real world. all the four effects!" (#144), then "make them
  more realistic" (#146). Claude Code tuned all four toward real-world physics as revision r1
  (#146–#149). The author picked ideas on an options page
  (#147), then kept the effects as tuned (#153). r1 stayed uncommitted until the author's
  verdicts; its record and patch were committed first (`2a2d3a1`–`5d4112d`), and the author
  kept it after playing (#164), committed with its strips in `1c8447b`.
- **The world around the effects (#150–#158), at the author's requests.**
  - Each was done one step at a time, after the author approved it:
    - street lamps that light downward like real ones;
    - the depot lit from its wall;
    - the author's pasted brief for a photorealistic rainy road, in five steps (the wet road,
      an amber streetlight built in Blender, the lamps' rain and splashes, the roadside, the
      rendering).
  - Uncommitted until the author's verdict, with a committed patch (`89cd9a3`–`8889880`);
    kept after the author's play (#164) and committed after r1.
- **What the author caught:**
  - "those lights at shed looks so bad", which led to security lights on the depot's wall
    (#151);
  - "those lights shouldnt light up entire depot" (#152);
  - "the street light lits entire road" (#155).
- **What Claude Code found:**
  - B1's splashes had never fired: in Godot 4.7.2 a drop that vanishes on contact sets off no
    collision sub-emitter (#156);
  - its first bend guardrail stood on the curve's inside, because a helper it reused returns a
    curve's inside (#157);
  - new turf looked like snow under the moon (#157);
  - the moon's glint made wet surfaces silver and the pines look frosted (#158).
- **The submission's agent parts (#159):**
  - the F9 vsync key, approved by the author (`c5e307d`);
  - the Effect A mutations repeated on r1, all exit 1;
  - the previews rechecked;
  - `SUBMISSION.md`, `TEST-REPORT.md` and `README.md` brought up to date.
- **The author's play of r1 (#160)** found three faults, which Claude Code fixed:
  - the title screen showed frozen rain: the lamps' rain, paused with the title, now hidden;
  - "the hard break water falling down effect isnt working": the spill fired, but the wet
    glass drew over it, so it now draws after the glass;
  - "the right wiper isnt doing that effect": the passenger blade now leaves its water, which
    the driver's blade wipes.
- **The strips (#163).** The author asked Claude Code to run them ("can you run them for me";
  the handout has the student run them). Claude Code ran 22 and read each. Two of its #160
  predictions were wrong: A1's passenger line on frame 10, and A2's streams on frame 15. A shell
  mistake first made one wrongly named folder per round; the folders were deleted and the
  variants run again.
- **The verdicts (#164).** "i played and all look good proceed": all four effects kept, against
  two of Claude Code's readings (A1's passenger line too bright in the office floodlight, A2's
  streams too white). Committed in the handout's order: r0's strips (`2b9e327`), r1 with its
  strips and the verdict (`1c8447b`), the world changes (`1dfe865`).
- **"do everything for me please" (#165).** At the author's request, Claude Code:
  - wrote the brief's revisions 6–10 for the kept changes;
  - reviewed `CLAUDE.md`, correcting 18 line references that later commits had moved;
  - ran Effect A's mutations again (all exit 1) and the cost script;
  - measured the GPU price with Apple's Metal Performance HUD, since Godot's GPU timer reads 0
    on Metal.
- **Step 6 (#170–#171).** At the author's direction, Codex, in its own session, saved
  `game/shaders/particles_generated.gdshader` by Godot's conversion of a unique copy of
  `ExhaustPlume`'s process material, saved the scratch scene, and wrote line references and an
  explanation into `TEST-REPORT.md`, labelled by Codex as "AI-prepared technical reference notes,
  not an independently written student answer". Asked afterwards, Claude Code had declined Step 6,
  citing the handout. The author's account: "i told codex what to do exactly, i typed my code and
  gave and etc. so keep everything of codex work and mention that i pasted everything to codex what
  to do etc".
- **The author's decisions (#167, #168):** B2 kept over its GPU budget; the † values accepted;
  the lay-by walls kept for now; the human checks answered as "everything i asked for is
  delivered as it is."
- **Own notes:** added below at the author's request, with AI-assisted wording and attribution.
- **Trace:**
  - `8c3e636` to `1dfe865`, and the commits after it;
  - `docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #142–#171;
  - `TUNING.md`, `HANDOFF.md`.

## 2026-11-07 — My own notes (added 2026-11-08)

AI-assisted wording based on the recorded work, added at the author's request.

- **Tried / expected:** I chose wiper flicks, roof spills, lamp rain and exhaust vapour to make the rainy driving scenes feel more realistic.
- **What happened:** During playtesting, I found frozen rain on the title screen, a hidden roof spill and missing passenger-wiper water.
- **Checked or changed in response:** I asked Claude to fix those problems, then played the revised game and accepted all four effects.
- **Learned / still unresolved:** The work showed that passing automated tests does not guarantee visible effects; exhaust remains over its GPU budget, and detailed visual checks are not individually documented.
- **Human vs AI:** I chose the effects and approved their appearance; AI helped with implementation, tuning, testing, and the process-shader conversion and notes.
- **Trace:** `docs/AUTHOR_PROMPTS_AND_DECISIONS.md` #160, #164–#171; `TUNING.md`; `TEST-REPORT.md`; this conversation's approval to add these notes.
