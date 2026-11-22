# CAPTURE — Blackridge, Frame by Frame

Every take was recorded by Godot 4.7.2's Movie Maker (`--write-movie`, AVI, `--fixed-fps 30`,
1280×800) from the repository's `game/` at commit `1e7765e`. The batch runner is
`capture/scripts/run_film_captures.sh`. Each AVI was cut with ffmpeg to the frames named in
`manifest.json`, encoded to H.264 (CRF 16) without retiming, and hashed there. The raw AVIs and
the MP4s stay out of Git.

| Take | Script | Kind | Events |
| --- | --- | --- | --- |
| `ring_play` | `tools/captures/capture_a7_clips.gd` | scripted input on the real main scene: the van driven by a lane keeper until Maya's call rings, the camera zoomed to the dash for 6 s; then stopped, out by E, E at the driver's door, EnterVan, seated | `ring_play/events.txt` |
| `interrupt_startup` | `tools/captures/capture_enter_van_interrupt.gd -- startup` | **fixture**: Ethan placed at the driver's door at Mission 1's start (the run sheet treated as signed), then real input: E, W held at clip frame 16 | `events.txt`: moved 0.000 m, seated |
| `interrupt_active` | same, `-- active` | fixture, then E and Esc at clip frame 40; 40 frames paused; Esc again | `events.txt`: clip 41 and door 0.593 held while paused |
| `interrupt_recovery` | same, `-- recovery` | fixture, then E and R at clip frame 56 | `events.txt`: seated at once, door 0 |
| `reload` | `tools/captures/capture_reload_strip.gd` | **fixture**: Mission 3 loaded at stage 3, out of the van by E, placed 3 m from Maya facing away, armed by the encounter's `arm()` (the handover cutscene skipped); then real input: aim held, R | `events.txt`: RifleReload frame per movie frame; magazine 12 → 30 |
| `shock` | `tools/captures/capture_shock_shot.gd` | **fixture**: the van placed on the hill road where the hit happens and held on its brakes, no struck man; the app's own `_shock()` | `events.txt`: the letterboxed shot at movie frames 20-124 |

Stills: the ring cells are crops (×3) of `ring_play` movie frames 123-138, three apart, one
0.6 s cycle. `dash.png` is movie frame 120. `reload_f30.png` is movie frame 317 (clip frame 30).
`shock_f58.png` is movie frame 78 (Shock frame 58). `capture/sheet/phone_ring_on_dark.png` is
the game's `phone_ring.png` scaled ×4 on a dark backing with its cell lines drawn, labelled as
such in the film.

The EnterVan strip frames (`evidence/strips/enter_van/r0`, `r1`) are copies of
`captures/enter_van/r0` and `r1` (Step 7, `TUNING.md`), recorded by
`tools/captures/capture_enter_van_strip.gd`: r0 with `game/` at `bf69b24` (committed in `107af78`;
frames 45-47 added in this film's commit), r1 at `8f618ee` (committed in `c486789`).
