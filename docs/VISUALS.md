# First visual pass — October 18, 2026

The author approved game changes after selecting six generated concept references
in [the inventory](../source_assets/artwork/references/README.md). This batch
improves the existing van and depot with the existing Compatibility renderer.
The author rejected the result after handoff: "not realistic at all". This pass
does not meet the selected visual target. Story, route, controller, checkpoint
format, and controls are unchanged. Further implementation requires an explained
batch and approval.

## Code explanation

`tools/art/build_first_drive_art.py` authors meshes and textures offline. Its
`mesh_authoring.py` helper writes GLBs with positions, normals, UVs, material groups,
and textures. Rounded boxes, extruded profiles, rings, and cylinders form the
dashboard, vents, seats, doors, van panels, and wheels. Geometry is grouped by
material rather than creating hundreds of runtime nodes. This is original mesh
authoring code, not an image-to-3D conversion or a production vehicle blueprint.

`van_presentation.gd` instantiates the body, cabin, steering, and tire scenes. It
connects the existing instruments, navigation/reverse display, mirrors, windows,
lamps, and wipers to that art. Steering follows the existing input; cached wheel
meshes roll using measured motion. The camera is closer and angled slightly down
to frame the dashboard. Reference logos and songs were not incorporated.

`depot_detail.gd` composes loading-door surrounds, numbers, downpipes, pallets,
boxes, bollards, and drain grates at the existing depot. These are decorative
props, not new cargo interactions or an accessible warehouse interior. Existing
vehicle/world colliders remain; small new decorative props have no individual
colliders. Props avoid the marked parking bay.

The asphalt shader combines original aggregate color and normal maps with larger
wetness patches and cracks. Roughness controls reflected-light spread; normals
vary apparent surface direction without adding road polygons. The wall shader
adds siding relief, brick variation, and damp lower walls. One stationary depot
ReflectionProbe captures the static world once, excluding vehicle/cabin layers.
This gives approximate local reflections, not moving traffic reflections or SSR.
Three existing depot lamps now cast shadows. Ambient lighting and fog were tuned.

The glass shader samples the opaque scene behind droplets for approximate
refraction/highlights. Existing wiper state attenuates droplets inside sweep
regions. This is not simulated fluid or a persistent water film. Shader
compilation, transparency ordering, and appearance need a graphical playtest.

## Sources and reproduction

All new model geometry and generated maps are authored by the project tool. No
third-party asset downloads, paid services, plugins, copied vehicle logos, or
AI-generated runtime textures were introduced. Approved ChatGPT images remain
concept references outside `game/`.

From the repository root:

```sh
python3 tools/art/build_first_drive_art.py
python3 tools/tests/check_first_drive_art.py
```

Authoring uses already installed NumPy 2.5.3 and Pillow 12.3.0. No packages were
installed. The bitmap legends use the existing macOS Arial font at
`/System/Library/Fonts/Supplemental/Arial.ttf`; the font file is not copied. Godot
needs no authoring dependencies to open the shipped GLBs.

The first command overwrites seven GLBs, generated PNGs, and
`source_assets/artwork/first_drive/geometry_report.md`. Preserve later hand-edited
replacements before rebuilding. Godot may extract embedded GLB textures beside
models; retain those files and their `.import` sidecars. The asset check is
read-only and independently validates file structure and geometry.

Geometry: cabin 26,204 triangles; steering 4,118; body 9,838; each tire 5,696;
pallet 3,000; box 902; bollard 684. These are measurements, not a measured
frame-time budget. Repeated instances share imported mesh resources.

## Blender startup limitation

Blender 5.2.2 crashed before executing the authoring script. Factory startup with
a print-only script also crashed. Its trace enters Metal device support detection
at `supports_barycentric_whitelist` / `MTLBackend::metal_is_supported`. The root
cause is unconfirmed. Help lists only Metal as a supported backend; attempting
OpenGL did not provide a working alternative.

No installation, preferences, add-ons, existing `.blend` files, or GUI session were
edited. At the author's request, further Blender launches stopped. The retained
tool exports GLBs directly; no `.blend` output is claimed. GLBs can later be
imported into Blender when the author approves checking that workflow. Crash
evidence and the unexecuted Blender script are under ignored
`builds/visual_pass_1/`.

## Review limits

Headless import verifies loading, not appearance. A graphical command-line launch
aborted in this restricted session before producing a usable image. A separate
software render checked mesh arrangement only; its images explicitly say they
are not Godot renders. They do not show the final shaders, textures, lighting,
screens, or world and are not acceptance evidence.

Review the cockpit, exterior, wet depot, live displays, glass/wipers, and road
visibility at the chosen window size. Check Godot's Debugger for shader/runtime
errors and measure sustained performance on target hardware. See
[PLAYTEST.md](PLAYTEST.md) and [VALIDATION.md](VALIDATION.md).

Implementation references:

- [Godot reflection probes](https://docs.godotengine.org/en/stable/classes/class_reflectionprobe.html)
- [Godot screen-reading shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html)
- [Godot material parameters](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html)
