"""Apply tuning revision r1 (TUNING.md): each effect's draw material becomes the scattering shader.

Run from the repository root, only after the author's approval:
    python3 -I tools/tuning/r1/apply_r1.py tools/tuning/r1/scatter_particle.gdshader
"""

import pathlib
import re
import shutil
import sys

ROOT = pathlib.Path(".")
SHADER = "res://effects/scatter_particle.gdshader"
SHADER_ID = "9_scatter"

DROP = {"face_camera": "true"}
STREAK = {"face_camera": "false"}
SCENES = {
    "wiper_flick.tscn": {
        "Draw_bead": {**DROP, "min_pixels": "1.5", "forward_scatter": "0.85", "scatter": "10.0",
                      "diffuse": "0.3", "glint": "1.0", "sky": "2.0"},
        "Draw_spray": {**DROP, "min_pixels": "1.0", "forward_scatter": "0.85", "scatter": "10.0",
                       "diffuse": "0.3", "glint": "0.0", "sky": "1.0"},
    },
    "roof_spill.tscn": {
        "Draw_stream": {**STREAK, "min_pixels": "1.2", "forward_scatter": "0.85",
                        "scatter": "6.0", "diffuse": "0.3", "glint": "0.0", "sky": "1.0"},
        "Draw_bead": {**DROP, "min_pixels": "1.2", "forward_scatter": "0.85", "scatter": "6.0",
                      "diffuse": "0.3", "glint": "1.0", "sky": "1.0"},
    },
    "exhaust_vapour.tscn": {
        "Draw_puff": {**DROP, "min_pixels": "0.0", "forward_scatter": "0.7", "scatter": "1.0",
                      "diffuse": "0.3", "glint": "0.0", "sky": "0.0"},
    },
}
RAIN = {
    "Draw_streak": {**STREAK, "min_pixels": "2.0", "forward_scatter": "0.8", "scatter": "100.0",
                    "diffuse": "0.5", "glint": "0.0", "sky": "0.0"},
    "Draw_splash": {**DROP, "min_pixels": "1.5", "forward_scatter": "0.8", "scatter": "100.0",
                    "diffuse": "0.5", "glint": "0.0", "sky": "0.0"},
}
for name in ("lamp_rain_post.tscn", "lamp_rain_floodlight.tscn", "lamp_rain_door.tscn"):
    SCENES[name] = RAIN


def swap_scene(path: pathlib.Path, materials: dict) -> None:
    text = path.read_text()
    steps = int(re.search(r"load_steps=(\d+)", text).group(1))
    text = text.replace(f"load_steps={steps}", f"load_steps={steps + 1}", 1)
    last_ext = list(re.finditer(r"^\[ext_resource [^\n]*\]\n", text, re.M))[-1]
    line = f'[ext_resource type="Shader" path="{SHADER}" id="{SHADER_ID}"]\n'
    text = text[:last_ext.end()] + line + text[last_ext.end():]
    for material_id, params in materials.items():
        header = f'[sub_resource type="StandardMaterial3D" id="{material_id}"]\n'
        start = text.index(header)
        end = text.index("\n\n", start) + 1
        block = text[start:end]
        texture = re.search(r'albedo_texture = ExtResource\("([^"]+)"\)', block).group(1)
        lines = [f'[sub_resource type="ShaderMaterial" id="{material_id}"]',
                 "render_priority = 0", f'shader = ExtResource("{SHADER_ID}")',
                 f'shader_parameter/albedo_texture = ExtResource("{texture}")']
        lines += [f"shader_parameter/{key} = {value}" for key, value in params.items()]
        text = text[:start] + "\n".join(lines) + "\n" + text[end:]
    path.write_text(text)


def replace(path: str, pairs: list) -> None:
    file = ROOT / path
    text = file.read_text()
    for old, new, count in pairs:
        assert text.count(old) == count, (path, old[:60], text.count(old))
        text = text.replace(old, new)
    file.write_text(text)


def main() -> None:
    shutil.copyfile(sys.argv[1], ROOT / "game/effects/scatter_particle.gdshader")
    for name, materials in SCENES.items():
        swap_scene(ROOT / "game/effects" / name, materials)
    replace("game/tests/particle_readback.gd", READBACK)
    replace("game/tests/test_wiper_flick_config.gd", WIPER)
    first = (ROOT / "game/tests/test_wiper_flick_config.gd").read_text()
    first = first.replace('\t"draw": DRAW,\n', '\t"draw": BEAD_DRAW,\n', 1)
    first = first.replace('\t"draw": DRAW,\n', '\t"draw": SPRAY_DRAW,\n', 1)
    (ROOT / "game/tests/test_wiper_flick_config.gd").write_text(first)
    replace("game/tests/test_roof_spill_config.gd", ROOF)
    replace("game/tests/test_exhaust_vapour_config.gd", EXHAUST)
    replace("game/tests/test_lamp_rain_config.gd", LAMP)
    print("r1 applied")


READBACK = [
    ('## "process" (ParticleProcessMaterial), "draw" (StandardMaterial3D), "mesh" (QuadMesh),\n'
     '## "texture" (the draw material\'s albedo texture path), and "alpha_curve" or "scale_curve"\n'
     '## (the curve\'s points). Every value is checked and reported with what was found.\n',
     '## "process" (ParticleProcessMaterial), "draw" (StandardMaterial3D, or a ShaderMaterial when it\n'
     '## names a "shader" and its "params"), "mesh" (QuadMesh), "texture" (the draw material\'s albedo\n'
     '## texture path), and "alpha_curve" or "scale_curve" (the curve\'s points). Every value is\n'
     '## checked and reported with what was found; a shader parameter must also be one of the\n'
     '## shader\'s uniforms, because a ShaderMaterial stores an undeclared name without an error.\n', 1),
    ('\tvar draw: StandardMaterial3D = mesh.material as StandardMaterial3D if mesh else null\n'
     '\tcheck.call(draw != null, "%s\'s quad uses a StandardMaterial3D" % label)\n',
     '\tvar wanted: Dictionary = expected.get("draw", {})\n'
     '\tvar shaded: ShaderMaterial = mesh.material as ShaderMaterial if mesh else null\n'
     '\tvar draw: StandardMaterial3D = mesh.material as StandardMaterial3D if mesh else null\n'
     '\tif wanted.has("shader"):\n'
     '\t\tcheck.call(shaded != null, "%s\'s quad uses a ShaderMaterial" % label)\n'
     '\telse:\n'
     '\t\tcheck.call(draw != null, "%s\'s quad uses a StandardMaterial3D" % label)\n', 1),
    ('\tif draw:\n\t\t_check_values(draw, expected.get("draw", {}), check, label + " material")\n',
     '\tif shaded and wanted.has("shader"):\n'
     '\t\t_check_shader(shaded, wanted, expected.get("texture", ""), check, label)\n'
     '\telif draw:\n\t\t_check_values(draw, expected.get("draw", {}), check, label + " material")\n', 1),
    ('static func _check_values(target: Object, values: Dictionary, check: Callable,\n',
     'static func _check_shader(material: ShaderMaterial, wanted: Dictionary, texture_path: String,\n'
     '\t\tcheck: Callable, label: String) -> void:\n'
     '\tvar path := material.shader.resource_path if material.shader else "none"\n'
     '\tcheck.call(path == wanted["shader"],\n'
     '\t\t"%s material runs %s (found %s)" % [label, wanted["shader"], path])\n'
     '\tvar declared: Array[String] = []\n'
     '\tif material.shader:\n'
     '\t\tfor uniform in material.shader.get_shader_uniform_list():\n'
     '\t\t\tdeclared.append(uniform["name"])\n'
     '\tvar params: Dictionary = wanted.get("params", {})\n'
     '\tfor name: String in params:\n'
     '\t\tvar found: Variant = material.get_shader_parameter(name)\n'
     '\t\tcheck.call(declared.has(name) and same(found, params[name]),\n'
     '\t\t\t"%s material %s = %s (found %s%s)" % [label, name, params[name], found,\n'
     '\t\t\t"" if declared.has(name) else ", not one of the shader\'s uniforms"])\n'
     '\tif texture_path != "":\n'
     '\t\tvar texture := material.get_shader_parameter("albedo_texture") as Texture2D\n'
     '\t\tvar found_path := texture.resource_path if texture else "none"\n'
     '\t\tcheck.call(found_path == texture_path,\n'
     '\t\t\t"%s texture is %s (found %s)" % [label, texture_path, found_path])\n\n\n'
     'static func _check_values(target: Object, values: Dictionary, check: Callable,\n', 1),
]

WIPER = [
    ('const DRAW := {"transparency": BaseMaterial3D.TRANSPARENCY_ALPHA,\n'
     '\t"blend_mode": BaseMaterial3D.BLEND_MODE_MIX,\n'
     '\t"shading_mode": BaseMaterial3D.SHADING_MODE_PER_PIXEL,\n'
     '\t"billboard_mode": BaseMaterial3D.BILLBOARD_PARTICLES, "billboard_keep_scale": true,\n'
     '\t"vertex_color_use_as_albedo": true}\n',
     'const SCATTER := "res://effects/scatter_particle.gdshader"\n'
     'const BEAD_DRAW := {"shader": SCATTER, "params": {"face_camera": true, "min_pixels": 1.5,\n'
     '\t"forward_scatter": 0.85, "scatter": 10.0, "diffuse": 0.3, "glint": 1.0, "sky": 2.0}}\n'
     'const SPRAY_DRAW := {"shader": SCATTER, "params": {"face_camera": true, "min_pixels": 1.0,\n'
     '\t"forward_scatter": 0.85, "scatter": 10.0, "diffuse": 0.3, "glint": 0.0, "sky": 1.0}}\n', 1),
]

ROOF = [
    ('const STREAM_DRAW := {"transparency": BaseMaterial3D.TRANSPARENCY_ALPHA,\n'
     '\t"blend_mode": BaseMaterial3D.BLEND_MODE_MIX,\n'
     '\t"shading_mode": BaseMaterial3D.SHADING_MODE_PER_PIXEL,\n'
     '\t"vertex_color_use_as_albedo": true, "billboard_mode": BaseMaterial3D.BILLBOARD_DISABLED}\n'
     'const BEAD_DRAW := {"transparency": BaseMaterial3D.TRANSPARENCY_ALPHA,\n'
     '\t"blend_mode": BaseMaterial3D.BLEND_MODE_MIX,\n'
     '\t"shading_mode": BaseMaterial3D.SHADING_MODE_PER_PIXEL,\n'
     '\t"vertex_color_use_as_albedo": true, "billboard_mode": BaseMaterial3D.BILLBOARD_PARTICLES,\n'
     '\t"billboard_keep_scale": true}\n',
     'const SCATTER := "res://effects/scatter_particle.gdshader"\n'
     'const STREAM_DRAW := {"shader": SCATTER, "params": {"face_camera": false, "min_pixels": 1.2,\n'
     '\t"forward_scatter": 0.85, "scatter": 6.0, "diffuse": 0.3, "glint": 0.0, "sky": 1.0}}\n'
     'const BEAD_DRAW := {"shader": SCATTER, "params": {"face_camera": true, "min_pixels": 1.2,\n'
     '\t"forward_scatter": 0.85, "scatter": 6.0, "diffuse": 0.3, "glint": 1.0, "sky": 1.0}}\n', 1),
]

EXHAUST = [
    ('\t"draw": {"transparency": BaseMaterial3D.TRANSPARENCY_ALPHA,\n'
     '\t\t"blend_mode": BaseMaterial3D.BLEND_MODE_MIX,\n'
     '\t\t"shading_mode": BaseMaterial3D.SHADING_MODE_PER_PIXEL,\n'
     '\t\t"billboard_mode": BaseMaterial3D.BILLBOARD_PARTICLES, "billboard_keep_scale": true,\n'
     '\t\t"vertex_color_use_as_albedo": true},\n',
     '\t"draw": {"shader": "res://effects/scatter_particle.gdshader", "params": {\n'
     '\t\t"face_camera": true, "min_pixels": 0.0, "forward_scatter": 0.7, "scatter": 1.0,\n'
     '\t\t"diffuse": 0.3, "glint": 0.0, "sky": 0.0}},\n', 1),
]

LAMP = [
    ('const BACKLIGHT := Color(0.8, 0.8, 0.8, 1.0)\n',
     'const SCATTER := "res://effects/scatter_particle.gdshader"\n', 1),
    ('\t\t"draw": {"transparency": BaseMaterial3D.TRANSPARENCY_ALPHA,\n'
     '\t\t\t"blend_mode": BaseMaterial3D.BLEND_MODE_MIX,\n'
     '\t\t\t"shading_mode": BaseMaterial3D.SHADING_MODE_PER_PIXEL,\n'
     '\t\t\t"vertex_color_use_as_albedo": true, "backlight_enabled": true,\n'
     '\t\t\t"backlight": BACKLIGHT, "billboard_mode": BaseMaterial3D.BILLBOARD_DISABLED},\n',
     '\t\t"draw": {"shader": SCATTER, "params": {"face_camera": false, "min_pixels": 2.0,\n'
     '\t\t\t"forward_scatter": 0.8, "scatter": 100.0, "diffuse": 0.5, "glint": 0.0, "sky": 0.0}},\n',
     1),
    ('\t\t"draw": {"transparency": BaseMaterial3D.TRANSPARENCY_ALPHA,\n'
     '\t\t\t"blend_mode": BaseMaterial3D.BLEND_MODE_MIX,\n'
     '\t\t\t"shading_mode": BaseMaterial3D.SHADING_MODE_PER_PIXEL,\n'
     '\t\t\t"vertex_color_use_as_albedo": true, "backlight_enabled": true,\n'
     '\t\t\t"backlight": BACKLIGHT, "billboard_mode": BaseMaterial3D.BILLBOARD_PARTICLES,\n'
     '\t\t\t"billboard_keep_scale": true},\n',
     '\t\t"draw": {"shader": SCATTER, "params": {"face_camera": true, "min_pixels": 1.5,\n'
     '\t\t\t"forward_scatter": 0.8, "scatter": 100.0, "diffuse": 0.5, "glint": 0.0, "sky": 0.0}},\n',
     1),
]

if __name__ == "__main__":
    main()
