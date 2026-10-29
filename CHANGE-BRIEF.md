# CHANGE-BRIEF.md

## 1. What I am making

My three shaders are:

1. **Night dashboard dimming** — `game/shaders/night_cluster.gdshader`. Changes the dashboard to a warm, dim colour when the headlights are on.
2. **Foggy windshield** — `game/shaders/foggy_windshield.gdshader`. Uses three textures to create light fog on the front windshield and heavy fog on the driver's side window.
3. **Texture hint experiment** — `game/shaders/hint_experiment.gdshader`. Shows how Godot reads a texture differently with and without `source_color`.

I picked night dimming because I think it fits my game. In real vans, the dashboard lights usually become dim when the headlights are on. I want to add this small detail to make driving feel more real.

This is my plan before I finish and test the shaders.

## 2. Night Dashboard Shader

### 2.1 What it does

When the headlights are on, the dashboard gauges will become dim orange. This helps the player know that the headlights are on without always looking at the LIGHTS text.

The headlight code is already in `freight_van.gd`.

- Variable: `headlights_on`
- Line: 23
- Starting value: `true`
- Press L to change it: lines 117–119

I will use this same variable. I don't need to make another one.

### 2.2 Shader file

File: `game/shaders/night_cluster.gdshader`

Type: `canvas_item`

Render mode: None

I am using `canvas_item` because the dashboard gauges are 2D.

### 2.3 Uniforms

| Name | Type | Hint | Default | Who changes it |
|---|---|---|---|---|
| night_amount | float | hint_range(0.0, 1.0) | 0.0 | The dimming driver |
| night_color | vec4 | source_color | (1.0, 0.55, 0.20, 1.0) | Inspector |
| night_brightness | float | hint_range(0.1, 1.0) | 0.55 | Inspector |

`night_amount` decides how much the dashboard changes.

`night_color` gives the dashboard the orange colour.

`night_brightness` decides how bright the dashboard is at night.

### 2.4 Colour calculation

This is the exact line I will use in my shader:

```glsl
COLOR.rgb = mix(COLOR.rgb, COLOR.rgb * night_color.rgb * night_brightness, night_amount);
```

I used multiply because I want to keep the original dashboard details.

I used `mix()` because it can change the colour slowly from normal to orange.

I didn't use add because it might make the dark parts too bright.

The shader will not change the transparency.

### 2.5 How the effect works

**Starting**

The headlights are already on when the game starts.

So the dashboard will start with `night_amount = 1.0` before the first visible frame, because the headlights start ON.

**When I press L to turn on headlights**

The value will go from 0 to 1 in 0.25 seconds.

**When I press L to turn off headlights**

The value will go from 1 to 0 in 0.35 seconds.

**If I press L during the change**

Retrigger rule: **reverse from current value**.

The effect will change direction from its current value.

For example, if it is at 0.6 and I turn the headlights off, it will go back toward 0 from 0.6. It will not suddenly jump to 0.

The speed will be 4.0 units per second when turning on and about 2.857 units per second when turning off.

**Time**

I will use delta time instead of counting frames.

The full fade should take:

- Turning on: 0.25 seconds
- Turning off: 0.35 seconds

At half game speed, the full on-fade should take about 0.50 seconds in real time.

The allowed difference is one frame:

- 30 FPS: 33.3 milliseconds
- 60 FPS: 16.7 milliseconds
- 144 FPS: 6.9 milliseconds

**Pause**

When the game is paused, the dashboard effect should stop changing.

Pressing L while paused should not change the headlights or dashboard.

**Turning lights off early**

If I turn the headlights off before the orange effect finishes, it will start going back to normal from its current value.

**Recovery**

Pressing R to recover the van should not change the dashboard lighting.

**More than one van**

Each van should have its own ShaderMaterial. This is so one van's dashboard does not change another van's dashboard.

### 2.6 Things I will not change

I will not change:

- Headlight code and lamps
- LIGHTS text
- Headlight switch sound
- Van movement
- Collisions
- Other controls
- Existing tests, including the L-key test
- Other objects in the game

I may add one screenshot key for testing only.

The dimming driver will read the existing headlight value. It will not control the headlights.

### 2.7 How I will test it

**Code tests:**

- Check that all three uniforms exist.
- Check the starting value.
- Check that pressing L changes the effect.
- Check the time at 30, 60 and 144 FPS.
- Check what happens if I press L during the fade.
- Check pause behaviour.
- Check that two vans do not share the same material.

**Things I will check myself:**

- How the dashboard looks normally.
- How it looks with orange lighting.
- If the gauges are still easy to read.
- If the change looks smooth.
- If the headlights and LIGHTS text still work.
- If the screenshots match my colour calculations.

**Evidence for each rule:**

| Rule | Machine check (headless) | Visual check (my eyes) |
|---|---|---|
| Uniform names, types, hints and defaults (§2.3) | `get_shader_uniform_list()` gives the names and types; hints and defaults are read from the shader source text | — |
| Colour line (§2.4) | The shader source contains exactly the line in §2.4 | In-engine captures at 0, 0.5 and 1.0 compared with §3.1 |
| Starts at 1.0 before the first visible frame | Read `night_amount` on the first frame after the scene loads | The cluster is already dim orange when the game starts |
| On-fade 0 → 1 in 0.25 s | Real L press; `night_amount` sampled every frame from a high-priority node at 30, 60 and 144 FPS; finishes within one frame period | Watch the fade in a windowed run |
| Off-fade 1 → 0 in 0.35 s | Same method as the on-fade | Watch the fade in a windowed run |
| Reverse from current value | Press L, then press it again mid-fade; the value turns around from where it was, with no jump | Press L twice quickly while driving |
| Delta time; half game speed doubles the time | `Engine.time_scale = 0.5`; the on-fade takes about 0.50 s | — |
| Pause stops the effect; L while paused does nothing | Pause mid-fade: the value stays the same; L while paused changes neither `headlights_on` nor `night_amount` | Pause during a fade in a windowed run |
| R recovery does not change the dashboard | Press R; `night_amount` is unchanged | Press R while driving |
| Each van has its own ShaderMaterial | Two vans: different material objects; one van's headlights do not change the other's value | — |
| Nothing outside the boundary changes (§2.6) | Existing regression and integration suites still pass at 60 FPS | Drive normally: headlights, LIGHTS text and switch sound work as before |

## 3. Colour Calculations

I will test three values of `night_amount`:

- 0.0 — normal
- 0.5 — halfway
- 1.0 — full night lighting

My fixed values are:

- Night colour: (1.0, 0.55, 0.20)
- Night brightness: 0.55

I picked two pixels:

- Background: (8, 14, 18) at pixel (10, 10). The cluster fills its background with `Color("080e12")` (`instruments.gd:18`), and nothing else is drawn at that spot.
- Dial hub: (135, 156, 148) at pixel (155, 136), the centre of the speed dial (`instruments.gd:20`). The hub is a filled circle of radius 7 in `Color("879c94")`, drawn on top of the needle (`instruments.gd:54`).

**Where I capture them:** from the cluster's own 640 × 256 screen, the SubViewport made at `van_presentation.gd:135`. I will not capture from the cockpit view, because that view adds the 3D screen quad, fog and tonemap.

**Assumption:** HDR 2D is off, so my colour line works on the stored 0–255 values as written. I checked this in the project: `project.godot` has no `rendering/viewport/hdr_2d` setting, so it stays at its default (off), and the cluster's SubViewport does not turn `use_hdr_2d` on (`van_presentation.gd:159–166`).

### 3.1 My predicted colours

| Pixel | 0.0 | 0.5 | 1.0 |
|---|---|---|---|
| Background | (8, 14, 18) | (6, 9, 10) | (4, 4, 2) |
| Dial hub | (135, 156, 148) | (105, 102, 82) | (74, 47, 16) |

### 3.2 How I calculated them

The formula is:

`Result = Original × (1 - amount + amount × night colour × brightness)`

For example, the red value of the dial hub at 0.5:

`135 × (1 - 0.5 + 0.5 × 1.0 × 0.55)`

`= 135 × 0.775`

`= 104.625`

Rounded to 105.

For the green value at full night lighting:

`156 × 0.55 × 0.55 = 47.19`

Rounded to 47.

I used the same formula for the other colours.

### 3.3 Contrast

Contrast tells me how easy it is to see the dial hub against the dark background.

I used this formula:

`Contrast = (Lighter brightness + 0.05) / (Darker brightness + 0.05)`

To find brightness, I first change the RGB values from 0–255 to 0–1 and convert them to linear values.

Then I use:

`L = 0.2126R + 0.7152G + 0.0722B`

My estimated results are:

| Night amount | Contrast |
|---|---|
| 0.0 | 6.67:1 |
| 0.5 | 3.45:1 |
| 1.0 | 1.67:1 |

I expect the dashboard to become harder to read when it is fully dimmed.

I will check this in Godot. If it is too dark, I may need to change the brightness and write down the change.

## 4. Texture Hint Test

File: `game/shaders/hint_experiment.gdshader`

I want to understand why the same image can look different when Godot reads it as colour or as data.

I will use a small image with three grey values:

- 64
- 128
- 192

I will use two texture samplers.

The first one will have `source_color` and `filter_nearest`.

The second one will only have `filter_nearest`.

I will use a bool called `show_data` to switch between them.

### 4.1 My predictions

| Original grey | Read as colour | Read as data |
|---|---|---|
| 64 | 64 | 137 |
| 128 | 128 | 188 |
| 192 | 192 | 225 |

I used this formula to predict the final screen colour:

If `x <= 0.0031308`:

`encode(x) = 12.92 × x`

Otherwise:

`encode(x) = 1.055 × x^(1/2.4) - 0.055`

For example, grey 128:

`128 / 255 = 0.502`

When read as colour, Godot changes it to about 0.216 internally. When it is shown on screen, it becomes about 128 again.

When read as data, Godot keeps 0.502. When shown on screen, it becomes about 188.

So I think the data version will look brighter.

My game uses the Compatibility renderer, but these calculations are for Forward+ or Mobile. I will test it and write down what actually happens.

## 5. Foggy Windshield Textured Shader

### 5.1 What I am making

I am making a foggy glass shader for my first-person van driving game. The game takes place at night.

I want the front windshield to have light fog and the driver's side window to have heavier fog. The fog will look uneven, with soft cloudy patches and small moisture details.

### 5.2 Two objects

**Object 1: Front windshield fog overlay**

- Material: `light_fog.tres`
- Added just inside the existing windshield.
- Uses the existing windshield shape.
- Does not replace the original glass.

**Object 2: Driver's side window fog overlay**

- Material: `heavy_fog.tres`
- Added just inside the driver's side window.
- Moves together with the driver's window when J is pressed.
- Does not replace the original glass.

Both overlays will be created in the existing window-building code.

The original glass, rain, wipers, and window movement must stay unchanged.

Both materials will use the same shader file, but they will be separate ShaderMaterial resources.

### 5.3 Lighting and renderer

I will test both materials in the existing night scene.

The lighting will include cabin light, street lamps, and moonlight.

The scene uses Linear tonemap with exposure 1.0.

The renderer is Compatibility, as set in `project.godot:125`.

For the main comparison, I will turn world fog OFF using the running game's Remote Inspector. This is a temporary test change, so I will not save it to the scene.

I will also take one screenshot with world fog ON.

I will check whether the fog looks too dark in areas away from street lamps.

### 5.4 Shader type

File: `game/shaders/foggy_windshield.gdshader`

Type: `spatial`

Render mode:

```glsl
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;
```

I will use `ALPHA` for transparency.

I will not use a screen-texture sampler because I have not verified it in Compatibility.

I will use a lit shader so the normal map can affect the lighting.

### 5.5 Uniforms

| Uniform | Type | Hint | Range | Default | Group |
|---|---|---|---|---|---|
| fog_amount | float | hint_range | 0–1 | 0.25 | Fog |
| fog_opacity | float | hint_range | 0–1 | 0.45 | Fog |
| clear_center | float | hint_range | 0–0.9 | 0.65 | Shape |
| edge_softness | float | hint_range | 0.01–0.5 | 0.20 | Shape |
| normal_strength | float | hint_range | 0–2 | 0.5 | Detail |
| texture_scale | float | hint_range | 0.5–4 | 1.0 | Detail |
| fog_tint | vec4 | source_color | RGBA 0–1 | (0.82, 0.87, 0.90, 1.0) | Fog |

The controls will work like this:

- `fog_amount` controls how far the fog spreads inward from the edges. At 0 there is no fog, and at 1 it reaches the largest area allowed by the clear-center setting.
- `fog_opacity` controls how see-through the thickest fog is. At 0 it is invisible, and at 1 it is at its strongest.
- `clear_center` controls the clear middle area. At 0 there is almost no protected center, and at 0.9 most of the middle stays clear.
- `edge_softness` controls the fade between clear and foggy areas. At 0.01 the edge is sharp, and at 0.5 it is soft.
- `normal_strength` controls moisture surface detail. At 0 there is no normal-map effect, and at 2 the details are much stronger.
- `texture_scale` controls the pattern size. At 0.5 the pattern is larger, and at 4 it repeats more often.
- `fog_tint` controls the fog colour. The default is a soft grey-blue.

### 5.6 Textures

I will keep all three fog textures in:

`game/assets/textures/windshield/`

The files will be:

- `fog_color.png`
- `fog_normal.png`
- `fog_data.png`

All three textures will be 1024 × 1024 PNG images, generated using `tools/make_fog_textures.py`, written by Claude Code.

I will keep the two ShaderMaterial files in:

`game/materials/windshield/`

The files will be:

- `light_fog.tres` — used on the front windshield overlay.
- `heavy_fog.tres` — used on the driver's side window overlay.

Both materials will use `game/shaders/foggy_windshield.gdshader` and the same three textures. Only their uniform values will be different.

**fog_color.png**

- Soft grey-white fog colour.
- Uses sRGB values.
- Sampler hint: `source_color`.
- Compression: Lossless.
- Mipmaps: On.
- `compress/normal_map`: Disable.

**fog_normal.png**

- Small moisture surface details.
- OpenGL normal-map convention, green up.
- Flat normal approximately RGB (128, 128, 255).
- Sampler hint: `hint_normal`.
- Compression: Lossless.
- Mipmaps: On.
- `compress/normal_map`: Enable.

**fog_data.png**

- Red channel stores fog thickness.
- 0 = clear, 0.5 = medium fog, 1 = thick fog.
- Green and blue channels are unused.
- No `source_color` hint.
- Compression: Lossless.
- Mipmaps: On.
- `compress/normal_map`: Disable.

The images will use matching UV coordinates. The normal map will be generated from a moisture height pattern.

### 5.7 Shader calculations

The shader will read the colour, normal, and data textures.

It will calculate how close each UV point is to the glass edges.

It will use `smoothstep()` to make a soft fog boundary.

`clear_center` will protect the middle area, while `fog_amount` will control how much fog spreads into the remaining area.

The red channel of `fog_data.png` will make the fog uneven.

The colour texture and `fog_tint` will control the final fog colour.

The normal map will add small lighting details.

`fog_opacity` will control the final transparency through `ALPHA`.

The shader will not read or distort the background screen image.

### 5.8 Two material values

| Setting | Light fog | Heavy fog |
|---|---|---|
| Object | Front windshield | Driver's side window |
| fog_amount | 0.25 | 0.75 |
| fog_opacity | 0.45 | 0.60 |
| clear_center | 0.65 | 0.35 |
| edge_softness | 0.20 | 0.25 |
| normal_strength | 0.5 | 0.5 |
| texture_scale | 1.0 | 1.0 |
| fog_tint | (0.82, 0.87, 0.90, 1.0) | Same |

Both materials use the same three textures and the same shader.

### 5.9 Game behaviour

The fog will stay fixed during gameplay.

There will be no fog animation script and no new controls.

The side-window overlay will move with the driver's window when J is pressed.

The fog shader must not change the existing driving, headlights, rain, wipers, or window movement.

### 5.10 Headless tests

I will run these checks:

1. Check that the shader is spatial and has the correct render mode.
2. Check all three sampler hints.
3. Check texture import settings, including `compress/normal_map`.
4. Check all seven uniforms, including ranges, defaults, and groups.
5. Check that all three PNG images exist and are 1024 × 1024.
6. Check that the normal map uses OpenGL green-up convention.
7. I will check my generated normal map using a known normal-map pair from Poly Haven.

   I will use the same texture's OpenGL (`_nor_gl`) and DirectX (`_nor_dx`) normal maps as my calibration pair.

   The OpenGL version has the green channel pointing up, which is the convention Godot expects. The DirectX version has the opposite green-channel direction.

   I will compare the two images and check that the green channel is inverted while the red and blue channels remain approximately the same.

   I will also calculate the curl ratio for my generated `fog_normal.png` and the calibration images. I will record the formula, actual values, and results in `TEST-REPORT.md`.

   I will use the OpenGL convention for my final fog normal map.
8. Run Godot with a fresh import cache and check for errors.
9. Check that both materials use the same shader file.
10. Check that each material uses the values and textures from §5.8.
11. Check that each overlay uses the correct material.
12. Check that the driver's side overlay follows the moving window.
13. Run the existing test suites and check that they still pass.
14. Check that the colour sampler has `source_color`. If it is removed, the dedicated test must exit with status 1. Restore the hint and check that the test passes.

For the curl test, define the formula before running it and record the actual measured values. Do not invent results.

### 5.11 Visual tests

I will test every slider at its minimum, default, and maximum.

I will also check:

- Light fog on the front windshield.
- Heavy fog on the driver's side window.
- Clear middle and foggy edges.
- Fog appearance under cabin light, street lamps, and moonlight.
- Road visibility at night.
- Fog appearance with world fog OFF and ON.
- Side-window movement when J is pressed.
- Rain and wipers still working.

**Shader edit test:** Temporarily change one visible shader line. Both objects should change. Restore the line afterward.

**Material edit test:** Temporarily change one value in `light_fog.tres`. Only the front windshield should change. Restore the value afterward.

### 5.12 Possible problems

| Problem | Check |
|---|---|
| Fog too white | Check road visibility at night |
| Fog too dark | Check areas away from lamps |
| Center too cloudy | Compare center and edge screenshots |
| Normal map too strong | Test strength 0, 0.5, and 2 |
| Texture stretched | Test scale 0.5, 1, and 4 |
| Side overlay does not move | Press J and check the window |
| Materials share values by mistake | Change only one material |
| Shader changes only one object | Edit one shader line |
| Wrong texture settings | Check imports |
| Missing sampler hints | Run source checks |
| Compatibility issue | Fresh-cache and visual tests |
| Existing gameplay changes | Run old tests and check controls |

### 5.13 Expected result

The front windshield will have light fog near the edges, while the driver's side window will have much heavier fog.

Both will use the same shader and texture maps, but different settings.

The fog should look natural in the night scene without blocking the player's view of the road.

## 6. Things That Might Go Wrong

### Problem 1: Fade speed changes with FPS

The dashboard might change faster at 144 FPS than at 30 FPS.

**Test:** Check the effect at 30, 60 and 144 FPS. It should finish within one frame of the planned time.

### Problem 2: Two vans use the same material

Changing one van's dashboard might also change the other van.

**Test:** Use two vans with separate materials and check that only one changes.

### Problem 3: Wrong uniform name

The game code might use a name that is not in the shader.

**Test:** Check that the shader and driver both use `night_amount`.

### Problem 4: Fog overlay and transparency problems

The fog might appear too bright or dark, cover too much of the road, or render in the wrong order with rain and glass.

**Test:** I will test it at night with the Compatibility renderer and check the windshield, side window, rain, and wipers.

### Problem 5: Pressing L while paused

The dashboard might change even when the game is paused.

**Test:** Pause the game, press L, and check that nothing changes.

### Problem 6: Dashboard becomes too dark

The gauges might be hard to read.

**Test:** Take screenshots at `night_amount = 0` and `1` and compare them.

## 7. Short Questions

**Q1. Which renderer does `project.godot` name, and what does it rule out?**

My game uses the Compatibility renderer. In `project.godot:125`, the setting is `renderer/rendering_method="gl_compatibility"`.

This renderer supports normal 2D and 3D shaders, textures, transparency, and basic lighting. However, it does not support some advanced features like VoxelGI, volumetric fog, screen-space reflections, and compute shaders.

It also does not support Decal nodes in the Godot 4 renderer version I am targeting.

For my foggy windshield, I will use a spatial shader with normal textures and `ALPHA` transparency instead of depending on these advanced features.

**Q2. What colour arrives in your fragment function before you change it, and what would the tempting alternative give you?**

In my CanvasItem dashboard shader, `COLOR` inside `fragment()` already contains the incoming colour multiplied by the default texture.

My dashboard cluster is made using rectangles, lines, and text. The rectangles and lines mostly use Godot's default white texture.

This means I can directly use `COLOR` for my dashboard dimming calculation.

If I multiply `COLOR` by `texture(TEXTURE, UV)` again, I would apply the texture a second time.

For the white rectangles and lines, this would make little difference because multiplying by white does not change the colour much.

However, the text edges have partially transparent pixels. Multiplying the texture again could make those edges look thinner or more transparent.

I will use my Q3 scratch test to compare the two methods.

**Q3. For `canvas_item`: what would `texture(TEXTURE, UV)` give you instead of `COLOR`?**

I think it will read the texture directly and may not include the colour already applied to the object. I will test this in a scratch scene.

**Q4. For `spatial`: what does `ALBEDO` hold if you never write it, and what does `COLOR` hold?**

In a spatial shader, `ALBEDO` is the base colour of the material.

If I never write to `ALBEDO`, its default value is `vec3(1.0)`, which is white.

`COLOR` is different. In a spatial shader, `COLOR` contains the vertex colour coming from the mesh. It is passed from `vertex()` to `fragment()`.

If I change `COLOR` inside `vertex()`, the changed values are passed to `fragment()` and interpolated across the mesh.

Unlike a CanvasItem shader, spatial `COLOR` does not automatically contain the mesh's texture colour.

For my foggy windshield, I will read the colour texture myself and write the result into `ALBEDO`. I will use `ALPHA` to control transparency.

**Q5. How long would a frame-counting version of your effect last at 30, 60 and 144 frames per second?**

If I make my dashboard fade finish after a fixed number of frames, the duration will change depending on the FPS.

For example, I want my fade to take 0.25 seconds at 60 FPS.

The number of frames would be:

`0.25 × 60 = 15 frames`

If I always use 15 frames, the duration changes:

| FPS | Fixed frames | Actual duration |
|---|---:|---:|
| 30 | 15 | 0.500 seconds |
| 60 | 15 | 0.250 seconds |
| 144 | 15 | 0.104 seconds |

At 30 FPS, the fade takes twice as long. At 144 FPS, it finishes much faster.

This is why I will use `delta` in my dimming driver. It will measure elapsed time instead of depending on the number of frames.

**Extra calculation — expected frame counts for my delta-based fade**

My fade-in duration is 0.25 seconds and my fade-out duration is 0.35 seconds.

| FPS | Fade in (0.25 s) | Fade out (0.35 s) |
|---|---|---|
| 30 | 8 frames (266.7 ms) | 11 frames (366.7 ms) |
| 60 | 15 frames (250 ms) | 21 frames (350 ms) |
| 144 | 36 frames (250 ms) | 51 frames (354.2 ms) |

These are the expected counts when measuring in whole frames, starting from a frame boundary.

I will allow a tolerance of one frame:

- 30 FPS: 33.3 ms
- 60 FPS: 16.7 ms
- 144 FPS: 6.9 ms

I will measure the actual fade times during testing.

**Q6. Which resource holds your uniform's default, which holds its current value, and what happens if two objects share the material?**

The shader file stores the uniform declarations and their default values.

A ShaderMaterial stores the values assigned to those uniforms for a material.

During gameplay, the dimming driver will update the current `night_amount` value on the dashboard's ShaderMaterial.

If two objects use the same ShaderMaterial resource, changing a uniform on that material can change both objects.

To prevent unwanted changes, I will give each van its own ShaderMaterial instance.

For the foggy windshield, both materials will share the same shader file, but `light_fog.tres` and `heavy_fog.tres` will be separate material resources. This lets me change the fog on one window without changing the other.

**Q7. Does `hint_range` clamp a value your driver sets from code? Predict now; you will check in Use It.**

I predict that `hint_range` will create a slider in the Godot Inspector with the minimum and maximum values I specify.

For example:

```glsl
uniform float fog_amount : hint_range(0.0, 1.0) = 0.25;
```

I expect the Inspector to show a slider from 0.0 to 1.0, starting at 0.25.

I also predict that `hint_range` will not automatically clamp every value assigned through code. It mainly tells the Inspector how to display and edit the uniform.

I will test this by setting a value outside the range through code and checking what the shader receives. If I need a strict limit, I will use `clamp()` in the shader or the dimming driver.

I will record the actual result in `TEST-REPORT.md`.

## 8. My Work Order

1. Write and commit this `CHANGE-BRIEF.md` first.
2. Finish and commit `night_cluster.gdshader`.
3. Foggy windshield:
   1. Update and commit `CHANGE-BRIEF.md` before implementing the new shader.
   2. Write `foggy_windshield.gdshader`.
   3. Write the texture generation script and generate the three PNG images.
   4. Set the texture import settings.
   5. Create `light_fog.tres` and `heavy_fog.tres`.
   6. Add the two fog overlays to the existing window-building code.
   7. Make the driver's side overlay move with the J-controlled window.
   8. Run headless and visual tests.
   9. Record the results in `TEST-REPORT.md`.
   10. Record my actual development steps in `FRICTIONAL.md`.
4. Write and commit `hint_experiment.gdshader`.
5. Convert a StandardMaterial3D to a ShaderMaterial and write `LANGUAGE-NOTES.md`.
6. Test everything and add screenshots to `TEST-REPORT.md`.
7. Update `FRICTIONAL.md`. I will mention that I tried writing the shaders first while learning, but finished the brief before committing the shader files.

I will write down any changes I make after this plan as a new dated note at the bottom instead of changing the original plan.

Revision — October 29, 2026

In my foggy windshield shader, I used multiplication instead of mix() to combine the colour texture with fog_tint. I also set ROUGHNESS to 0.95 and SPECULAR to 0.1 so the fog stays matte and does not look too shiny. I updated this explanation to match how I actually wrote the shader.