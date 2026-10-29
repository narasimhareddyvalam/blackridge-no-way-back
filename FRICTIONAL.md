# FRICTIONAL — Assignment 5 honest log

The author's log of what they tried, expected, saw, checked and learned, with
human and AI work kept apart. Each entry is dated and points to a commit,
prompt, test log or capture. AI may organise these notes, but it does not
write the author's experiences. Entries marked "recorded by Claude Code"
contain facts only.

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
