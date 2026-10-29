# Prototype audio and final replacement

## Author decision — October 18, 2026

The author plans to choose or generate final audio in ElevenLabs at the end of
development. The current sounds may be reviewed and retained or replaced at their
discretion. No ElevenLabs API, account, purchase, dependency, or generation has
been used here. Preview approval and final selection remain open.

## Current assets

All twelve WAV files in `game/features/audio/first_drive/` were synthesized for
this prototype with the original source
`source_assets/audio/first_drive/synthesize.py`. They are mono, 16-bit PCM at
22,050 Hz before Godot import. They are provisional synthesized effects, not
recordings of a real vehicle, and have no third-party asset source.

| File | Role | Source duration | Playback intent |
| --- | --- | --- | --- |
| `engine.wav` | Engine pulse; pitch changes with speed | 4 s | Loop |
| `rain.wav` | Exposed exterior rain | 6 s | Loop |
| `cabin_rain.wav` | Muffled rain inside the van | 6 s | Loop |
| `tires.wav` | Rolling surface noise | 4 s | Loop |
| `wind.wav` | Wind; increases with speed and window opening | 4 s | Loop |
| `horn.wav` | Horn while H is held | 2 s | Loop while held |
| `music.wav` | Sparse prototype musical bed | 32 s | Loop |
| `indicator_on.wav` | Indicator relay, lit phase | 0.09 s | One shot |
| `indicator_off.wav` | Indicator relay, unlit phase | 0.07 s | One shot |
| `wiper.wav` | Wiper stroke | 0.44 s | One shot per half-cycle |
| `window.wav` | Window motor | 2 s | One shot per window operation |
| `collision.wav` | Simple impact feedback | 0.7 s | One shot |

These files can be opened individually for audition. The in-game mix has Master,
Vehicle, Ambience, and Music sliders in the pause menu. Headless checks confirm
that window opening changes mix parameters; they do not prove perceived realism
or audio quality. No subjective listening approval is recorded yet.

## How the code uses them

`driving_audio.gd` loads the WAVs when the application starts. Vehicle signals
trigger switches, indicator ticks, wiper strokes, window motors, and impacts.
Each update reads speed and window position to adjust engine pitch and the rain,
tire, and wind mix. The four audio buses allow independent volume adjustment.

The current loader expects `AudioStreamWAV`. Simply changing an extension to MP3
or OGG will not work. Future replacements need compatible WAV exports or an
approved loader change. Final stereo/spatial design and levels remain open.

Initial validation found a loop-boundary bug: imported compressed byte counts were
mistaken for uncompressed sample frames, causing early repetition. The approved
fix derives sample frames from imported duration and sample rate. All seven
looping sounds now pass checks against the source WAV frame count; one-shot
sounds remain unlooped. See [VALIDATION.md](VALIDATION.md). Audible quality and
loop seam smoothness still require the [author's playtest](PLAYTEST.md).

## Future replacement workflow

Before replacement, agree on the intended sound, timing, looping, and game use
with the author. Preserve the generated original and provenance under
`source_assets/audio/`; export runtime audio to its feature owner. Record actual
generation details and applicable usage terms when assets are introduced.

After approval, replace or reconnect the specific runtime sound, preserve import
sidecars, check its duration and loop boundaries, then listen in context. Obtain
the author's verdict rather than marking a provisional sound final automatically.

The current synthesis source overwrites its twelve runtime WAVs when run. Do not
rerun it over author-selected replacements. Its repository-root command is:

```sh
python3 source_assets/audio/first_drive/synthesize.py
```

It requires Python 3's standard library and is not needed to run the game.
