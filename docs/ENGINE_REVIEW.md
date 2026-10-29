# Rendering and asset approach review — October 18, 2026

The author rejected the block-based appearance and reiterated that the approved
reference images are the visual target. They explicitly allow considering a tool
change to get closer. This authorizes evaluation; no engine migration, renderer
change, installation, asset purchase, or new implementation batch has happened.

**Subsequent author decision:** "alright, lets do with gadot". Godot is retained.
The Unreal comparison below is historical research, not an active migration
proposal. Forward+ and specific replacement assets still need a concrete,
approved experiment; Compatibility has not been changed.

## Findings

The delivered art is simplified geometry. Changing engines alone will not supply
the detailed cockpit and vehicle shape missing from it. The next art choice must
be judged through actual model/interior previews before another broad code pass.

Godot currently uses Compatibility. Official documentation identifies Forward+
as its advanced desktop renderer, with Metal support and features such as
screen-space reflections and volumetric fog that Compatibility lacks. This is
an evaluation option, not proof that switching reproduces the references.
[Godot renderer comparison](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).

Unreal Engine is another candidate for a focused realistic-lighting benchmark.
Epic's versioned macOS requirements must be checked against the actual machine;
supported features vary by chip and engine version. Installation and a playable
sample have not been tested. No performance claim is made.
[Unreal 5.7 macOS requirements](https://dev.epicgames.com/documentation/en-us/unreal-engine/macos-development-requirements-for-unreal-engine?application_version=5.7).

The earlier Godot screenshot reports Apple M4; the design targets MacBook Air M1.
A read-only CPU query was denied by the tool environment. The author was asked
which target to optimize for. Target hardware and available RAM remain unresolved;
do not silently rewrite the project baseline from the screenshot.

## Asset research leads, not selections

| Lead | Verified listing information | Outstanding evaluation |
| --- | --- | --- |
| [Delivery Box Truck with Interior](https://www.fab.com/listings/24555abd-f3d3-4039-8572-4faafaef3e4d) | Seller advertises an interior, rigging, PBR materials, FBX and converted GLB/glTF. | Cockpit suitability, actual asset contents/quality, cost, license selection, performance, and fit to the approved van reference are unverified. |
| [Sprinter Detailed Interior Standard 2023](https://www.cgtrader.com/3d-models/vehicle/truck/mercedes-sprinter-detailed-interior-standard-2023) | Seller lists FBX/OBJ/BLEND, 381,959 polygons, simple materials, Corona previews, and unknown UV unwrapping. | A detailed modeling reference, not an approved game-ready purchase. Requires material/optimization assessment; seller preview quality does not establish engine output. |
| [Poly Haven Asphalt 03](https://polyhaven.com/a/asphalt_03) | Original asset page lists diffuse, normal, roughness and other maps under CC0. | Check actual appearance at appropriate texel density and in-game lighting before integration. |

Two Sketchfab candidate pages returned HTTP 403 to the research tool. Their full
contents and licenses were not verified; neither is selected. BlenderKit leads
require further access/setup evaluation. No plugin was installed.

## Decision gate

Select detailed art, explain its integration with existing accessories, then
establish one cockpit/depot benchmark in Godot. Inspect the actual result and
performance before applying the treatment to the wider route. Evaluate Forward+
deliberately only after the hardware target and proposed test are settled.
Preserve existing work and Blender installation/preferences/files throughout.

The author was asked whether research should include paid assets or remain
free-only. Budget preference is pending. No purchase authority is inferred.

Further free-model leads were found, but not selected: a 2017 VW Crafter listing
advertises an interior, about 149,300 triangles and CC Attribution. Its detail
page returned 403, so cockpit quality, downloadable contents and provenance are
not verified. A 2016 Transit listing says it was exported from another game and
is not shortlisted for use. Incomplete raw scans and intentionally low-detail
models are also not replacements for the selected reference target.
[Crafter listing](https://sketchfab.com/3d-models/2017-volkswagen-crafter-cec0480396cb4c1aa7ecd830a5dd5d64),
[Transit listing](https://sketchfab.com/3d-models/2016-ford-transit-with-interior-52f919aedaa1497a9c0395ec0ac63af1).
