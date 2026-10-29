# LANGUAGE-NOTES — Assignment 5

Answers are written by the author, in their own words. Claude Code copied the
questions from the assignment brief and does not write the answers. Line
references use `path:line`.

## A. The generated shader

`game/shaders/standard_generated.gdshader`, converted from a StandardMaterial3D
with albedo, normal and roughness textures.

| Item | Line(s) |
| --- | --- |
| `shader_type` and `render_mode` | |
| Uniform for the Inspector's albedo colour | |
| Uniform for the Inspector's normal-map strength | |
| Albedo sampler, with its hints | |
| Normal-map sampler, with its hints | |
| Line that writes `ALBEDO` | |
| Line that writes `ROUGHNESS` | |
| Line that writes `NORMAL_MAP` | |

## B. Questions

### 1. What does `shader_type` decide? Answer for each type you used, citing the first line of each shader.

### 2. Which processor functions did you write, and when does each run? What would change if you moved your colour line into `vertex()`, and why?

### 3. Name three built-ins you read and two you wrote. Which of the ones you read are read-only?

### 4. For each hint you used, does it change only the Inspector, or also the value the shader receives? Cite your hint experiment.

### 5. Does `hint_range` clamp a value set from code? Cite what you observed.

### 6. Which line of the generated shader makes the albedo sample as colour and the normal map as data, and what is the equivalent line in your textured shader?

### 7. Your `fragment()` runs for every pixel at once. Why can't it read what the neighbouring pixel's `fragment()` is computing, and how does game state reach it instead?

### 8. Name two things the Godot shading language provides that plain GLSL does not, or makes you write yourself.

## C. The four ideas, each with a line of your own code (preparation for the film)

1. What a shader does:
2. How a material differs from a shader:
3. Why a texture is information rather than a picture:
4. What the Godot shading language is:
