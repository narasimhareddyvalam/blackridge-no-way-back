# CAPTURE.md — engine evidence for "Blackridge, Rain and Vapour"

Claude Code recorded this footage on 2026-11-08, at the author's request (prompt log #172), from
an isolated copy of the game. Nothing in the repository's `game/` was created, edited, renamed or
deleted: `git status --porcelain -- game` was empty before and after.

## Method

- **Engine:** Godot 4.7.2.stable.official.ed1daf0bf, Forward+ on Metal, Apple M4 (MacBook Air).
- **Recorder:** Movie Maker (`--write-movie`), `--fixed-fps 30`, `--resolution 1280x800`: the
  game's own window size, so every take shows what a player's window shows, offline and
  deterministic. **Nothing here is a real-time frame-rate claim.**
- **Isolated copy:** `game/` copied with `cp -Rp` into Claude Code's scratch folder at commit
  `72ac99c` (whose `game/` is `c1c9d8b`); the 876 files outside `.godot/` hashed identical to
  the repository's. Only `capture_drivers/` was added to the copy.
- **Encoding:** PNG frames → H.264 (`-crf 12`, yuv420p) by `scripts/run_film_captures.sh`.
- **Hashes:** `manifest.json` lists every take's SHA-256, frame count and size. The MP4 files stay
  out of Git (`.gitignore`); the events, logs and stills are committed.

## Takes

| Take | Kind | Frames | What it shows |
| --- | --- | --- | --- |
| `in_play` | **scripted input**, real main scene | 480 | Started in the van as the tests and previews start it (`_resume()`); the game's own actions sent as input events: wipers to fast at frame 45, pause at 255, resume at 315, reverse gear at 345, handbrake and throttle held 360–450. Real keys and clicks are swallowed. |
| `a1_repeats` | fixture, `wiper_flick_preview.tscn retrigger=true` | 60 | A1 at the valley road, two top turns (frames 10 and 37) |
| `a1_speed` | fixture, `speed_kmh=50` | 60 | A1 at 50 km/h |
| `a2_office` | fixture, `roof_spill_preview.tscn retrigger=true` | 60 | A2's spill on frame 10; the second hard brake on frame 25 ignored |
| `a2_valley` | fixture, `place=valley` | 60 | A2 on the unlit valley road |
| `b1_post` | fixture, `lamp_rain_preview.tscn` | 120 | B1 at the valley lamp: start 10, stop 70, hidden 109 |
| `b2_rear` | fixture, `exhaust_vapour_preview.tscn` | 190 | B2 behind the van: ignition 10, throttle 40–80, engine off 100 |
| `b2_reverse` | fixture, `view=reverse_camera` | 190 | the same through the reverse camera |

Each take folder holds `events.txt` (the driver's or preview's printed events, each with its
frame) and `godot.log` (the full engine output). The in-play take's log shows the game paused from
frame 255 to 315: the flick count holds at 9 while paused.

The fixtures are the assignment's preview scenes, the same runs as the frame strips in
`captures/`, with every frame kept. They place the van and camera and fix the effect's seeds; the
film labels them as fixtures. The in-play take is labelled scripted input.

## Excerpt of the in-play take

`takes/in_play/in_play_wipers.mp4`: frames 30–254 of the in-play take, the fast wipers up to the
pause pressed at frame 255, encoded from the same lossless frames. B08 shows it, then replays it
once with a "replay" label, so that the take's pause and reverse gear, which B08's narration does
not cover, never appear there. Its hash is in `manifest.json`.

## Stills from the in-play take

`takes/in_play/stills/in_play_f150.png` (fast wipers), `in_play_f280.png` (the pause menu),
`in_play_f420.png` (reverse gear: the dash screen's reverse camera), lossless copies of those
frames.

## Strip frames

Before-and-after frames come from the committed strips in `captures/<effect>/r0|r1/` (captured
by Claude Code at the author's request, #163). Three used as code→result media are copied
hash-identical into `evidence/strips/`.
