# FACTCHECK — Blackridge, Rain and Vapour

Every narrated claim with the source it rests on. Paths are repository-relative.

| Beat | Claim | Source |
| --- | --- | --- |
| B00 | Prompt is a reconstruction; work began from the author's brief | `CHANGE-BRIEF.md` header; prompt log #141 |
| B02 | The author chose the four effects and wrote the brief | prompt log #131–#141; `FRICTIONAL.md` (Assignment 6) |
| B02 | A1 on `wiper_swept`, A2 on a hard brake, B1 within 65 m, B2 engine and throttle | `CHANGE-BRIEF.md` §1; `CLAUDE.md` Project context |
| B02 | Godot 4.7.2, GPU particles | `README.md:267`; `game/effects/*.tscn` (`GPUParticles3D`) |
| B03 | Ten predicted failures; budget 1.45 ms for all four | `CHANGE-BRIEF.md` §7 (rows 1–10), §8 |
| B03 | Brief committed before the build; CLAUDE.md imports it | `8c3e636` precedes `7f1f7bb`; `CLAUDE.md:68` |
| B04 | 300 puffs, 1.6 s; process material; quad and shader | `game/effects/exhaust_vapour.tscn:62–63, 69, 70, 53–55` |
| B05 | Puffs stop near the pipe, thicken on throttle, glow red, thin away | `capture/takes/b2_rear` frames; `captures/exhaust_vapour/r1` frames 55, 80, 100 |
| B06 | Control 0.002 ms, game ≈ 0.46 ms, every effect the same as none | `logs/particles/mutations_final/cost/cost_effects_60fps.log` |
| B06 | Headless: dummy renderer, nothing drawn or simulated | `CLAUDE.md` Headless facts; the cost log's per-effect deltas |
| B07 | `wiper_swept` every half stroke; top turn only; pool of two; miss logged | `freight_van.gd:280–285`; `van_particles.gd:17, 288–296` |
| B08 | Wipers fast at 1.5 s; nine flicks by 8.5 s | `capture/takes/in_play/events.txt` (frames 45 and 255) |
| B09 | r0 showed nothing; A2 hidden behind the wet glass | `TUNING.md` (readings of r0; #160) |
| B09 | Three predictions wrong (A1's heavy drop on frames 20–30, the passenger line on frame 10, A2's streams on frame 15), two off in brightness (A1 at 50 km/h frame 15, A2 frame 20); the author kept both, overruling two readings | `TUNING.md` (comparisons: "Not as predicted", "wrong on frame 10", "not as #160 predicted", "fainter than predicted", "brighter and more solid than the 'pale' predicted"; verdicts #164; "Claude against the author") |
| B10 | 8 m/s, 6 m/s² for two ticks; ignored while alive or refilling 20 s | `van_particles.gd:40–43, 342–363` |
| B11 | Second brake at frame 25 ignored | `captures/roof_spill/r1-retrigger-true/events.txt` |
| B11 | One render-priority setting fixed the hidden spill | `TUNING.md` (#160); `game/effects/roof_spill.tscn` (`render_priority = 1`) |
| B12 | Lamps within 65 m, eight at most; restart, stop, drain, hide | `lamp_rain.gd:12–13, 64–98` |
| B13 | Rain a few frames after the start (none on frames 10 and 12), stop at 70, hidden by 110 | `TUNING.md` B1 ("frames 10 and 12: no rain"; `restart()` with preprocess takes effect three frames late); `capture/takes/b1_post/events.txt` (stop f70, hidden f109) |
| B13 | Pause freezes the rain and resume carries on; hidden on the title | `game/tests/test_lamp_rain_state.gd:50, 130, 136`; `capture/takes/in_play/events.txt` (paused f255–f315) |
| B14 | Height-field collision; three droplets a landing; hide-on-contact never fired the splash | `lamp_rain_street.tscn:53–57, 117`; `TUNING.md` (#156) |
| B14 | Neither A effect uses a sub-emitter | `test_wiper_flick_config.gd`, `test_roof_spill_config.gd` check that no A emitter uses one (`TUNING.md`, Tests with r1); brief revision 6 |
| B15 | At most a few specks where drops land; splashes too faint to pick out at this distance | `TUNING.md` (B1 comparison: "No splash specks can be picked out on the lit ground at the strip's distance, at most a few dots on the road"); `SUBMISSION.md` known limitations |
| B16 | 0.15 + 0.65 × throttle; amount 300; zero with the engine off | `van_particles.gd:52–55, 372–385`; `exhaust_vapour.tscn:62` |
| B17 | Reverse camera: nothing at idle or on the throttle, a red column in the brake lamps, a faint wisp after switch-off, gone a second later | `TUNING.md` B2, the reverse-camera reading: "frame 80 shows a narrow column of red-lit vapour …, frame 100 a faint grey wisp, and the other frames none"; frames 100 and 130 are 30 frames apart at 30 fps |
| B17 | The state test reads 0.15 at idle, 0.80 at full throttle, 0 when off | `game/tests/test_exhaust_vapour_state.gd:51,81,95,121,136` |
| B17 | Freezes when paused, checked by the state test | `game/tests/test_exhaust_vapour_state.gd`; `TEST-REPORT.md` State |
| B18 | Real drop sizes and speeds; streaks; a jet that stops | `TUNING.md` (B1 and B2 changes); brief revisions 9–10 |
| B18 | World rebuilt at the author's requests | prompt log #150–#158 |
| B18 | The first B strips: no rain, and almost no vapour | `TUNING.md` (readings of r0: no rain on any frame; B2's rear view none, its reverse camera a dozen red dots on frame 80) |
| B18 | B2 matched every frame; B1 all but two details | `TUNING.md` (comparisons) |
| B19 | Step 6 by Codex at the author's direction | `TEST-REPORT.md` (The process shader; #171) |
| B19 | Line 254 samples the scale curve (to six times the birth size); line 255 the alpha curve (densest near the pipe, gone by the end) | `game/shaders/particles_generated.gdshader:254–255`; brief revision 10 (`scale_curve` 0:1, 0.3:3, 1:6; alpha 0:0, 0.02:0.22, 0.3:0.14, 0.7:0.05, 1:0) |
| B20 | Frame 55: a small plume as the van pulls away; frame 80: dense at the pipe, wider and fainter further out | `TUNING.md` B2 r1 comparison (frame 55 "a small pinkish-red plume as the van pulls away"); the frame itself, `evidence/strips/exhaust_vapour/r1/frame00000080.png` (read at full size in the second QC pass) |
| B21 | 451 checks for A1; state tests; mutations exit 1; the 22 earlier runs pass (19 suites, night dimming at three rates) | `logs/particles/strips_163/SUMMARY.txt` (30 runs: 22 earlier, 8 Assignment 6); `logs/particles/mutations_final/SUMMARY.txt` |
| B22 | Godot's GPU timer reads 0 on Metal; Metal HUD; prices; B2 over; 26 ms frame | `logs/particles/gpu_price/RESULT.txt`; `TEST-REPORT.md` (GPU price) |
| B22 | The author kept B2 | prompt log #167 |
| B23 | Mistakes: keep_scale, streaks a quarter as wide as their quads, no splash, spill behind glass | brief revisions 4, 5 ("only the middle quarter of its 16 pixels"); `TUNING.md` #156, #160 |
| B23 | Uncertain: A1 below zero, tailpipe, frame | `TEST-REPORT.md`; brief revision 2; `CLAUDE.md` Unconfirmed |
| B23 | Textures by script, Poly Haven CC0; revision c1c9d8b | `SOURCES.md` (repository); `git log -1 -- game` |
| B24 | Who did what | prompt log #131–#173; `FRICTIONAL.md`; `SUBMISSION.md` |

Pronunciation checked with a faster-whisper transcript of B01, B02, B07, B19, B22 and B23:
"GPU", "Godot 4.7.2", "wiper swept", "403", "422", "HUD", "CC zero" and "C1C9D8B" read as
written. "Mist" in B07 was heard as "missed", so the word became "spray". The seven beats regenerated after the
second QC pass (B09, B13, B15, B17, B18, B21, B23) were transcribed the same way.
