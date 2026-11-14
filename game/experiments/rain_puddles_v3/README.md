# Rain Puddles V3: a trial (#273)

The author asked (#273) to try a ready-made shader first, as it comes: "Try Rain Puddles V3 first".

- `rain_puddles_v3.gdshader`: "Rain Puddle Shader v3" by GloriousGlider8 (as YourSoftware
  Foundation), https://godotshaders.com/shader/rain-puddles-v1/, fetched 2026-11-13, copied
  unchanged, its MIT licence in its header. Its screen-space reflections are adapted from
  marcelb's GodotSSRWater, https://github.com/marcelb/GodotSSRWater (MIT).
- `ripple_data.png`: the ripple data texture the shader asks for and the page does not supply,
  drawn by `tools/art/make_ripple_data.py` from Sébastien Lagarde's description ("Water drop 2b
  - Dynamic rain and its effects", 2013): non-overlapping rings, red the radial gradient (1 at a
  ring's centre to 0 at its edge), green and blue the ring's outward direction, alpha a random
  time offset per ring; lossless, as the shader requires.

It lives in `game/experiments/`, which the export leaves out (`export_presets.cfg`). It is put
on the dock apron, the freight depot's yard and the road only at run time, by
`tools/captures/trial_rain_puddles_v3.gd`, for labelled before-and-after stills; no game file
uses it.
