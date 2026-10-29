# COMPONENTS — Blackridge, Shaded

These are the teachable units this film explains, as recorded in `gamedev-evidence.json`.
The checker verifies hashes, inventory, line ranges and associations, but not whether an
explanation is good.

| Component | Files | Beats | What the viewer sees |
| --- | --- | --- | --- |
| night-dimming | `shaders/night_cluster.gdshader`, `features/vehicles/freight_van/night_dimming.gd`, `instruments.gd`, `freight_van.gd` | B04–B08 | The colour line, then the captures against the hand predictions. Then the driver code, then the L key in play. |
| fog-windshield | `shaders/foggy_windshield.gdshader`, `materials/windshield/{light,heavy}_fog.tres`, `van_presentation.gd`, `assets/textures/windshield/*` | B09–B16 | Overlay wiring, then the J key in play. Then the uniform interface and its sweep; the samplers and the actual textures; the material and its two-material/shader-edit result. |
| hint-experiment | `shaders/hint_experiment.gdshader`, `experiments/hint_experiment/*` | B17–B19 | The two samplers, then Compatibility vs Forward+ captures, then the sRGB encode. |
| generated-shader | `shaders/standard_generated.gdshader` | B20–B21 | Two annotated generated lines beside the author's equivalents, then both shaders on the same textures. |
| tests | `tests/*` | B14, B22–B23 | The uniform-list contract, then the recorded results and three mutations. Also the curl check. |
| project-config | `project.godot` | B02–B03 | The renderer (line 125) and the input actions the captures press. |

**Input → state → output trace (B07–B08):** L key (`headlights` action) →
`FreightVan.headlights_on` → `NightDimming.night_amount` (delta-based fade) →
`night_cluster.gdshader:14` → dashboard pixels.

**Excluded files (listed with reasons in the ledger):**
- The pre-existing Blackridge environment, audio, UI, missions, vehicle art and shared
  builders from the baseline `e81ec92`. They appear only as context in the footage.
- Four label textures' `.import` files, rewritten by the editor's Detect 3D reimport
  (`df5a1fd`).
