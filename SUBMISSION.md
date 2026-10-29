Assignment: Assignment 5 - Shaders, Materials, and the Godot Shading Language
Student: Narasimha Reddy Valam
Project name: Blackridge: No Way Back
GitHub repository URL: https://github.com/narasimhareddyvalam/blackridge-no-way-back
Git tag and submitted commit SHA:
Game-source revision shown in the film: df5a1fd (game/ unchanged through 25c7873, when the captures were made)
Godot version, renderer, and operating system: Godot 4.7.2 stable, Compatibility, macOS 26.6.2
Game state the shader from code communicates: Headlights on (FreightVan.headlights_on, toggled with L): the instrument cluster dims to warm amber
3D object and scene given the textured shader: Fog overlays on the van's windshield (light_fog.tres) and driver's side window (heavy_fog.tres), main scene res://app/first_drive.tscn
Texture sources and licences (or model, version, and terms): fog_color/fog_data/fog_normal.png and greys_3x1.png written by code (tools/make_fog_textures.py, tools/make_hint_png.gd; original, no licence needed); calibration pair box_profile_metal_sheet nor_gl/nor_dx from Poly Haven by Amal Kumar, CC0 1.0
Final film URL and filename: https://northeastern-my.sharepoint.com/:v:/g/personal/valam_n_northeastern_edu/IQCCHHcatHuxT7BIfeUyLjEyAcdyHfosv8mtnbjcAG55b2Q?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=Fk9uVc — Blackridge-Shaded-4K.mp4 (3840×2160, 9:22)
Final film SHA-256: 89066f8d42e86392f157c76ed832ff1b5b9994b20f1c6f5b08fee695d7b6c1c2
Summary of my work: I specified the change first in CHANGE-BRIEF.md (colour line, uniforms, timing rules and hand predictions), then hand-wrote three shaders: a canvas_item night-dashboard shader driven by the van's headlights_on state, a spatial foggy-windshield shader with three textures and seven grouped uniforms shared by two materials, and a hint-experiment shader comparing source_color with raw data. I annotated Godot's generated StandardMaterial3D shader, wrote LANGUAGE-NOTES.md and FRICTIONAL.md, and checked the results in play. Claude Code wrote the driver, tests, texture script, materials, captures, audit and film from my brief; every prediction was checked against engine captures, and deliberate mutations made the tests fail.
Known limitations: In the hint experiment the Compatibility renderer showed no sRGB difference (a Forward+ comparison matched my prediction), and the cause is not yet explained. At the light default, five of the fog's seven controls barely show from the driver's view. The captures are offline renders at a fixed 60 fps, so they say nothing about real-time performance, which has not been profiled on the target MacBook Air M1. Fog layering with the rain pane and night readability were judged by eye only.
Changed games since Assignment 2 (yes/no; if yes, FRICTIONAL.md entry): yes; see FRICTIONAL.md, "2026-10-28 — Changing games for the final"
