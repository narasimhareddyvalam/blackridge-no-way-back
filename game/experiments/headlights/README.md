# Headlights: a trial (#281)

The author asked (#281) for more realistic headlights, "with shaders add texture maybe. see if
there are already shaders existing to use", and then to see every option before choosing.

- `beam_mist_trial.gdshader`: the street lamps' mist
  (`game/features/environments/industrial_loop/lamp_mist.gdshader`) with the headlight's
  projector pattern in place of its round cone. Chosen ("B. Haze in the rain"); the game's copy
  is `game/features/vehicles/freight_van/beam_mist.gdshader`.
- `lens_trial.gdshader`: a lit reflector headlamp seen from the front, a bright core and
  reflector facets. Not chosen.
- "Spatial Light Shaft" by absentSpaghetti (https://godotshaders.com/?p=11405, CC0), an existing
  shader for a visible beam, was tried first on a cone along each beam and removed: it did not
  show from the driver's seat, behind its cone's tip, as it is drawn for a shaft seen from the
  side.

They are put on the van only at run time by `tools/captures/trial_headlights.gd`, for the
labelled stills in `captures/headlights/trial/`. This folder is left out of the export
(`export_presets.cfg`).
