"""Builds beat_sheet.json for "Blackridge, Shaded" (godot-gamedev, walker).

Deterministic: code excerpts are read verbatim from the hashed game files, audio
fields measured by Kokoro are preserved when a beat's narration is unchanged,
and cue times come from measured word timings (mp3/words.json) when present.
Run from anywhere: python3 build/build_sheet.py
"""
import hashlib
import json
from pathlib import Path

REEL = Path(__file__).resolve().parents[1]
REPO = REEL.parents[1]
GAME = REPO / "game"
SLUG = "claude-liam-blackridge-gamedev"
TITLE = "Blackridge, Shaded"
PUB = "blackridge-shaded/"
PROJECT = "Blackridge: No Way Back"
FPS = 30


def lines(rel, a, b):
    text = (GAME / rel).read_text(encoding="utf-8").splitlines()
    return "\n".join(text[a - 1:b])


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


WORDS, WORD_FPS = {}, FPS
words_path = REEL / "mp3" / "words.json"
if words_path.exists():
    _w = json.loads(words_path.read_text())
    WORD_FPS = _w.get("fps", FPS)
    WORDS = {bid: [{"word": w["text"], "start": w["startFrame"] / WORD_FPS} for w in ws]
             for bid, ws in _w.get("beats", {}).items()}


def when(bid, phrase, fallback):
    """Start time (s) of the first occurrence of phrase in beat bid's measured words."""
    seq = WORDS.get(bid) or []
    target = [w.strip(".,;:!?\"'()").lower() for w in phrase.split()]
    toks = [(w["word"].strip(".,;:!?\"'()").lower(), w["start"]) for w in seq]
    for i in range(len(toks) - len(target) + 1):
        if all(toks[i + j][0] == target[j] for j in range(len(target))):
            return round(toks[i][1], 2)
    return fallback


def workbench(bid, title, rel, a, b, notes, cues, output, font=26, credit="hand-written by the author"):
    return {
        "pattern": "GodotDevWorkbench",
        "props": {
            "mode": "code", "title": title, "project": PROJECT,
            "path": f"game/{rel}",
            "source": f"Godot editor reconstruction · game/{rel}:{a}–{b} · {credit} · code shown verbatim",
            "code": lines(rel, a, b), "startLine": a, "codeFontSize": font,
            "inspectorLabel": "Source notes — not Inspector values",
            "notes": [{"label": k, "value": v} for k, v in notes],
            "cues": [{"at": when(bid, ph, fb), "line": ln, "label": lab} for ph, fb, ln, lab in cues],
            "output": output, "dense": True,
        },
    }


BEATS = []


def beat(bid, act, narration, shot, role, **extra):
    b = {"beat_id": bid, "act": act, "role_note": role, "voice": "am_onyx", "engine": "kokoro",
         "narration_text": narration, "shot": shot}
    b.update(extra)
    BEATS.append(b)


beat("B00", "ASK",
     "Namaste. This is Liam, in for Bear. This is Blackridge: No Way Back, a narrative crime game "
     "where you drive freight through a rainy industrial town at night, built in Godot. The prompt on "
     "screen is a reconstruction; the real work started from a written brief. Let's take apart the two "
     "shaders this build added, and how each one was checked.",
     {"type": "GRAPHIC", "remotion": {"pattern": "ClaudeComposerAsk", "props": {
         "command": "Please use Walker to convert my game design document about Blackridge: No Way Back, "
                    "a narrative crime game where you drive freight through a rainy industrial town at night, "
                    "into two shaders: a dashboard that dims when the headlights are on, and fog on the van's "
                    "windows driven by texture maps.",
         "topic": "RECONSTRUCTED PROMPT · BLACKRIDGE",
         "segment": TITLE, "greeting": "Namaste, Liam", "runningText": "reading the brief…",
         "output": ["Brief committed before any shader.", "Two shaders. Two materials. One experiment.",
                    "Every number predicted, then measured."],
         "folderLabel": "@NikBearBrown"}},
      "show": [{"at": "Namaste", "event": "Composer types the reconstructed Walker prompt"},
               {"at": "reconstruction", "event": "Running line, then three result lines land"}]},
     "COLD OPEN LAW + walker bookend 1: Claude composer, prompt begins 'Please use Walker to convert my "
     "game design document about …', describing this game. Eyebrow discloses it is reconstructed.")

beat("B01", "BLUF",
     "Shaders are rules you can test. In Blackridge, the dashboard dims when the headlights are on, and "
     "the windows fog from texture maps. Every number was predicted by hand first, then measured in the engine.",
     {"type": "GRAPHIC", "remotion": {"pattern": "BrutalistHesitantWriter", "props": {
         "text": "Shaders are decoration.\nIn Blackridge, the dashboard dims\nwhen the headlights are on,\n"
                 "and the windows fog from texture maps.",
         "triggerWords": "decoration", "replacementWords": "rules you can test",
         "fontSize": 80, "mistakeRate": 2, "hesitateWithin": 2, "hesitateBetween": 8, "charMs": 30, "seed": SLUG,
         "contextTitle": TITLE}},
      "show": [{"at": 0.8, "event": "Writer types 'Shaders are decoration.'"},
               {"at": "rules you can test", "event": "Deletes 'decoration', types 'rules you can test'"}]},
     "EXECUTIVE-SUMMARY LAW, walker bookend 2. Single-token trigger (the component matches one word): "
     "'decoration' -> 'rules you can test'. Misconception: shaders as decoration -> testable rules.",
     lead_silence_s=0.8,
     qc={"sparse_by_design": True, "sparse_reason": "Hesitant-writer bookend (EXECUTIVE-SUMMARY LAW): the "
         "overview is typed token by token, so steady-state frames are mostly cream by design."})

beat("B02", "SETUP",
     "Blackridge already had the van, the district and the driving. This build adds four pieces: a shader "
     "whose colour comes from the van's state, a textured shader shared by two materials, an experiment on "
     "what texture hints do to the numbers, and a close reading of the shader Godot generates itself. The "
     "game runs Godot four point seven point two, on the Compatibility renderer. Remember that.",
     {"type": "GRAPHIC", "remotion": {"pattern": "GodotEngineEvidence", "props": {}},
      "show": [{"at": "already had", "event": "Held 4K cockpit frame; 'Already built' card"},
               {"at": "four pieces", "event": "Four component cards light in narration order"},
               {"at": "Compatibility", "event": "Engine card: Godot 4.7.2 · Compatibility · project.godot:125"}]},
     "Verified setup: untouched starter (e81ec92) vs this build's extension. Real engine still.")

beat("B03", "SPEC",
     "Before any shader code, a written brief fixed the contract: the exact colour line, three uniforms, and "
     "rules a test can fail. Fade on in a quarter of a second, and off in zero point three five. A retrigger "
     "reverses from the current value. One frame of tolerance at 30, 60 and 144 frames per second. The commit "
     "history shows the brief landed before the first shader, and the project's Claude dot M D imports it.",
     {"type": "GRAPHIC", "remotion": {"pattern": "GodotEngineEvidence", "props": {}},
      "show": [{"at": "colour line", "event": "Verbatim CHANGE-BRIEF colour line and uniform table"},
               {"at": "quarter", "event": "Rule cards reveal as spoken"},
               {"at": "Git shows", "event": "Commit order card: 2729c26 -> c055037; CLAUDE.md:91 import"}]},
     "Specification shown verbatim from CHANGE-BRIEF.md (outside game/, so not a gamedev excerpt).")

beat("B04", "CODE",
     "Here's the author's hand-written effect. It's a canvas item shader, because the gauges are 2D drawing "
     "inside a sub-viewport. Three uniforms: night amount, driven from code; a warm amber colour; and a "
     "brightness floor. Line 14 is the whole effect. It mixes the original colour toward that colour times "
     "amber times brightness. Multiplying keeps the gauge detail, and mix lets it fade.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B04", "The Effect Is One Line", "shaders/night_cluster.gdshader", 1, 15,
         [("Why canvas_item", "The gauges are 2D drawing inside a 640×256 SubViewport (van_presentation.gd)."),
          ("Big idea 1", "What a shader does → line 14")],
         [("canvas item", 1.5, 1, "shader_type canvas_item — the 2D gauges"),
          ("night amount", 6.0, 4, "night_amount — driven from code, hint_range(0.0, 1.0)"),
          ("amber", 8.0, 7, "night_color — source_color amber"),
          ("brightness floor", 10.0, 10, "night_brightness — hint_range(0.1, 1.0)"),
          ("Line 14", 12.0, 14, "The colour line, verbatim from the brief")],
         ["Headless uniform list: night_amount (float) · night_color (Color) · night_brightness (float)"],
         font=23)},
     "Code beat: the hand-written effect shader.")

beat("B05", "RESULT",
     "Big idea one: a shader is a small program the GPU runs for every pixel. Line 14 runs once per dashboard "
     "pixel, so its output can be predicted. The brief predicted two pixels by hand, the dark background and "
     "the dial hub, at three settings. The engine captures match all eighteen numbers exactly. At two point "
     "zero, set from code, the hub goes almost black: hint range draws a slider, but it doesn't clamp.",
     {"type": "GRAPHIC", "remotion": {"pattern": "GodotEngineEvidence", "props": {}},
      "show": [{"at": "three settings", "event": "Captures cycle 0.0 -> 0.5 -> 1.0 with pixel markers"},
               {"at": "eighteen", "event": "Predicted -> measured cards tick 18/18"},
               {"at": "two point zero", "event": "2.0 capture; 'hint_range does not clamp' card"}]},
     "Result of B04: controlled-value captures against the hand predictions.")

beat("B06", "MATH",
     "Here's the hand calculation. Factor the mix, and each channel is the original value times one minus "
     "the amount, plus the amount times amber times brightness. For the hub's red channel at one half, that's "
     "135 times zero point seven seven five: one hundred and four point six two five, which rounds to 105. "
     "The capture reads 105.",
     {"type": "GRAPHIC", "remotion": {"pattern": "TypesetMath", "props": {}},
      "show": [{"at": "Factor", "event": "Row 1: the factored colour line"},
               {"at": "135", "event": "Row 2: the worked hub-red case"}]},
     "Prediction method typeset with TypesetMath (MATH-TYPESETTING.md).")

beat("B07", "CODE",
     "The driver is GDScript written by Claude Code, and it only reads the van's headlights flag. It never "
     "sets it. Each frame, it moves night amount toward its target by delta over the fade time, so the speed "
     "doesn't depend on frame rate. A retrigger simply reverses from wherever the value is. Once it arrives, "
     "lines 25 and 26 stop sending updates.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B07", "The Driver Reads Game State", "features/vehicles/freight_van/night_dimming.gd", 21, 31,
         [("Input → state → output", "L key → FreightVan.headlights_on → night_amount → night_cluster.gdshader:14 → pixels"),
          ("Never writes", "The driver reads headlights_on; it never sets it.")],
         [("headlights flag", 2.0, 24, "Reads FreightVan.headlights_on"),
          ("by delta", 9.0, 28, "move_toward by delta / seconds — frame-rate independent"),
          ("reverses", 14.0, 28, "Retrigger reverses from the current value"),
          ("lines 25 and 26", 17.0, 25, "At the target, stop sending updates")],
         ["test_night_dimming.gd: 30/30 at 30, 60 and 144 fps (recorded)"],
         font=25, credit="written by Claude Code")},
     "Code beat: the dimming driver; complete input -> state -> output trace in notes.")

beat("B08", "RESULT",
     "Here it is in the game. Lights off, and the gauges fade back to mint white in about a third of a second. "
     "Lights on, and the amber returns in a quarter of a second. Tap L twice mid-fade, and it turns around "
     "without a jump. The tests measured these fades at 30, 60 and 144 frames per second, each within one frame.",
     {"type": "GRAPHIC", "remotion": {"pattern": "GodotEngineEvidence", "props": {}},
      "show": [{"at": "Lights off", "event": "Footage: L press, dashboard fades to mint-white"},
               {"at": "Lights on", "event": "L press, amber returns"},
               {"at": "Tap L twice", "event": "Double tap reverses mid-fade"},
               {"at": "The tests", "event": "Recorded frame-count card"}]},
     "Result of B07: the effect in play (scripted-input engine capture).")

beat("B09", "CODE",
     "The textured shader goes on two new overlays, built beside the existing glass, never in place of it. "
     "The windshield gets the light fog material. The driver's window gets the heavy fog material, and "
     "because that overlay is a child of the window pane, it inherits every move the pane makes.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B09", "Two Overlays, One Shader", "features/vehicles/freight_van/van_presentation.gd", 226, 233,
         [("Beside, not instead", "The existing glass keeps its own material; each overlay is a QuadMesh child (_fog_overlay, lines 244–256)."),
          ("Object 1", "Windshield pane → LIGHT_FOG"), ("Object 2", "Driver's window _windows[0] → HEAVY_FOG")],
         [("beside the existing glass", 1.5, 228, "The existing windshield pane"),
          ("light fog", 6.0, 230, "Windshield overlay → light_fog.tres"),
          ("heavy fog", 9.0, 232, "Driver's-window overlay → heavy_fog.tres, a child of the pane")],
         ["test_materials.gd: overlay wiring checks pass (recorded)"],
         font=24, credit="written by Claude Code")},
     "Code beat: where the two fog materials attach.")

beat("B10", "RESULT",
     "Press J, and the driver's window drops zero point eight eight metres in the van's own frame, and the fog "
     "rides down with it. The first version of this test measured in world space and got one point one three "
     "metres, because the whole van also settles onto the ground. Measuring in the van's frame fixed it. The "
     "author confirmed it by hand, too.",
     {"type": "GRAPHIC", "remotion": {"pattern": "GodotEngineEvidence", "props": {}},
      "show": [{"at": "Press J", "event": "Footage: J press, window and fog lower together"},
               {"at": "first version", "event": "Card: 1.13 m world-space bug -> 0.880 m in van frame"}]},
     "Result of B09: J moves the overlay with the glass (scripted-input engine capture).")

beat("B11", "CODE",
     "The fog shader is spatial, because the glass is in 3D. Its render mode blends it over the scene, skips "
     "depth writes, and draws both faces. Seven uniforms sit in three Inspector groups, each with a type, a "
     "range and a default. Big idea four: group uniforms, hint range and source colour aren't plain G L S L. "
     "They're Godot's shading language talking to the editor.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B11", "A Parameter Interface", "shaders/foggy_windshield.gdshader", 1, 10,
         [("Shape group (lines 12–15)", "clear_center 0–0.9 = 0.65 · edge_softness 0.01–0.5 = 0.20"),
          ("Detail group (lines 18–21)", "normal_strength 0–2 = 0.5 · texture_scale 0.5–4 = 1.0"),
          ("Big idea 4", "Godot additions to GLSL → lines 2, 5, 9")],
         [("spatial", 2.0, 1, "shader_type spatial — 3D glass"),
          ("render mode", 4.0, 2, "blend_mix · depth_draw_never · cull_disabled"),
          ("three Inspector groups", 9.0, 5, "group_uniforms Fog (Shape and Detail follow)"),
          ("source colour", 16.0, 9, "fog_tint : source_color")],
         ["Headless: 7 uniforms, 3 samplers, 3 groups (test_materials.gd)"],
         font=26)},
     "Code beat: the fog shader's interface (types, hints, defaults, groups).")

beat("B12", "RESULT",
     "The sweep runs every control at its minimum, default and maximum on the windshield, then measures what "
     "changed. Fog amount is the big one: at its maximum, eight percent of the frame changes and the pane clouds "
     "over. Clear centre at zero lets fog creep in from the corner. The other five barely move a pixel, because "
     "at the light default the fog band sits behind the frame. To judge them, the next sweep needs a heavier base fog.",
     {"type": "GRAPHIC", "remotion": {"pattern": "GodotEngineEvidence", "props": {}}, "show": []},
     "Result of B11: the interface sweep.")

beat("B13", "CODE",
     "Three textures, three jobs. Fog colour has source colour, so Godot decodes it as colour. Fog normal has "
     "hint normal: these are directions, not colours. Fog data has no hint at all, and line 35 reads only its "
     "red channel, as a thickness from zero to one. Big idea three: a texture is information, not just a picture.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B13", "Three Textures, Three Jobs", "shaders/foggy_windshield.gdshader", 26, 35,
         [("Colour", "fog_color : source_color — decoded as sRGB colour"),
          ("Directions", "fog_normal : hint_normal — a normal map, not a colour"),
          ("Big idea 3", "A texture is information → line 35 reads .r as thickness")],
         [("Fog colour", 2.0, 26, "source_color: treat as colour"),
          ("Fog normal", 5.0, 27, "hint_normal: directions"),
          ("Fog data", 9.0, 28, "No hint: raw data"),
          ("line 35", 11.0, 35, "Red channel = fog thickness, 0 to 1")],
         ["Import settings explicit for all three (MATERIALS.md)"], font=24)},
     "Code beat: the three samplers and the data read.")

beat("B14", "RESULT",
     "Here are the three files. A seeded script written by Claude Code generated them, so they're original and "
     "reproducible. Their import settings are written down explicitly: lossless, mipmaps on, normal-map mode set "
     "by hand. That's why opening the editor later didn't change them. And a curl check against a known Poly "
     "Haven pair confirms the normal map's green channel points up, the convention Godot expects.",
     {"type": "GRAPHIC", "remotion": {"pattern": "GodotEngineEvidence", "props": {}},
      "show": [{"at": "three files", "event": "The three actual texture files"},
               {"at": "import settings", "event": "Import-settings cards"},
               {"at": "curl check", "event": "Curl-ratio card: calibration vs fog_normal"}]},
     "Result of B13: the actual texture data, imports and normal-map check.")

beat("B15", "CODE",
     "A material holds settings, not the program. Light fog points at the same shader and the same three "
     "textures, then sets its own values. Heavy fog differs in exactly four of them. Big idea two: the shader "
     "declares fog amount once, on line 7, and each material gives it its own value: a quarter here, three "
     "quarters on the side window.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B15", "A Material Is Settings", "materials/windshield/light_fog.tres", 8, 19,
         [("heavy_fog.tres differs in four", "fog_amount 0.75 · fog_opacity 0.6 · clear_center 0.35 · edge_softness 0.25"),
          ("Big idea 2", "Shader vs material → foggy_windshield.gdshader:7 declares fog_amount once")],
         [("same shader", 2.5, 9, "Same shader resource"),
          ("three textures", 4.5, 10, "Same three textures"),
          ("own values", 6.5, 13, "Its own values"),
          ("a quarter", 14.0, 13, "fog_amount = 0.25 here; 0.75 in heavy_fog.tres")],
         ["Two separate ShaderMaterial resources share one Shader (test_materials.gd)"],
         font=25, credit="written by Claude Code from the brief's values")},
     "Code beat: the material resource.")

beat("B16", "RESULT",
     "Side by side: light fog on the windshield, heavy fog on the driver's window. Change one value in the "
     "light fog material, and only the windshield clouds over, because materials don't share values. Now turn "
     "that fog up so it shows, and change one line of the shader: both windows turn red, because they share the "
     "program. Two edits, and the difference between a material and a shader is on screen.",
     {"type": "GRAPHIC", "remotion": {"pattern": "GodotEngineEvidence", "props": {}},
      "show": [{"at": "Side by side", "event": "Baseline: both overlays"},
               {"at": "Change one value", "event": "Material edit clip: only the windshield thickens"},
               {"at": "Change one line", "event": "Shader edit clip: both windows change"}]},
     "Result of B15: one shader, two materials, shader-edit and material-edit observations.")

beat("B17", "CODE",
     "The hint experiment isolates a single word. A tiny image holds three grey bands: 64, 128 and 192. The "
     "author's shader reads it through two samplers, one with source colour and one without, and a show data "
     "switch picks which one an unshaded quad displays. Same file, same pixels, one hint different.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B17", "One Hint, Isolated", "shaders/hint_experiment.gdshader", 1, 16,
         [("Input image", "greys_3x1.png: 64 · 128 · 192 (tools/make_hint_png.gd)"),
          ("Unshaded", "render_mode unshaded: no lighting changes the value")],
         [("single word", 1.5, 5, "color_read : source_color"),
          ("one without", 8.0, 6, "data_read : no colour hint"),
          ("show data", 11.0, 9, "show_data picks the sampler"),
          ("unshaded quad", 13.0, 15, "ALBEDO = the chosen read")],
         ["hint_as_color.tres (show_data false) · hint_as_data.tres (show_data true)"], font=23)},
     "Code beat: the hint-experiment shader.")

beat("B18", "RESULT",
     "The prediction: read as colour, each band is decoded to linear light and encoded back on the way out, so "
     "it stays 64, 128 and 192. Read as data, the raw value is only encoded: 137, 188 and 225. A Forward Plus "
     "comparison matched that exactly. But in Compatibility, the game's renderer, both quads showed the file's "
     "values. Same shader, different renderer, different numbers.",
     {"type": "GRAPHIC", "remotion": {"pattern": "GodotEngineEvidence", "props": {}},
      "show": [{"at": "read as colour", "event": "Predicted values card"},
               {"at": "Forward Plus", "event": "Forward+ capture with measured bands"},
               {"at": "Compatibility", "event": "Compatibility capture: file values on both quads"}]},
     "Result of B17: hint experiment predicted vs measured, two renderers.")

beat("B19", "MATH",
     "Here's the encode the prediction used. Above a tiny threshold, the stored value is one point zero five "
     "five times the linear value to the power one over two point four, minus zero point zero five five. Feed "
     "in 64 over 255, about zero point two five one, and you get about zero point five three eight: 137.",
     {"type": "GRAPHIC", "remotion": {"pattern": "TypesetMath", "props": {}},
      "show": [{"at": "encode", "event": "Row 1: sRGB encode"}, {"at": "Feed in", "event": "Row 2: 64 -> 137"}]},
     "sRGB encode typeset (MATH-TYPESETTING.md); algebra checked in FACTCHECK.md.")

beat("B20", "CODE",
     "To learn the language, the author converted a standard material into a shader and annotated what Godot "
     "generated. Lines 6 and 7: an albedo colour and an albedo texture, both marked source colour. The author's "
     "equivalents are fog tint, on line 9, and fog colour, on line 26. They make the same promise: these values "
     "are colours, so decode them.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B20", "What Godot Generates", "shaders/standard_generated.gdshader", 6, 7,
         [("Mine: foggy_windshield.gdshader:9", "uniform vec4 fog_tint : source_color = vec4(0.82, 0.87, 0.90, 1.0);"),
          ("Mine: foggy_windshield.gdshader:26", "uniform sampler2D fog_color : source_color, filter_linear, repeat_enable;")],
         [("Lines 6 and 7", 7.0, 6, "Generated albedo colour — annotated by the author"),
          ("albedo texture", 9.0, 7, "Generated albedo texture, source_color — annotated")],
         ["Generated by Godot from a StandardMaterial3D; end-of-line comments are the author's"],
         font=30, credit="generated by Godot, comments by the author")},
     "Code beat: two annotated generated lines beside the author's equivalents.")

beat("B21", "RESULT",
     "Here are the same texture files through both shaders. Godot's generated shader paints the colour texture "
     "onto an opaque, lit surface, and the normal map raises tiny bumps. The author's shader turns them into fog: "
     "the data texture makes it patchy, and alpha lets the stripes behind it show through. The generated code "
     "teaches the vocabulary; the hand-written shader decides what the textures mean.",
     {"type": "GRAPHIC", "remotion": {"pattern": "GodotEngineEvidence", "props": {}}, "show": []},
     "Result of B20: the same textures through Godot's generated shader and the author's shader.")

beat("B22", "CODE",
     "Tests get their own look. This is Claude Code's driver test asking Godot for the shader's uniform list. "
     "If the shader fails to parse, that list comes back empty, so one check catches a broken shader. Other "
     "checks press the real L key through Godot's input system and sample night amount on every frame.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B22", "A Test That Can Fail", "tests/test_night_dimming.gd", 70, 75,
         [("Limit", "Input.parse_input_event simulates the key; a headless run draws nothing."),
          ("Sampling", "A process_priority 1000 node records night_amount every frame.")],
         [("uniform list", 4.0, 73, "get_shader_uniform_list() — works headless"),
          ("comes back empty", 8.0, 75, "A parse failure empties the list → this check fails")],
         ["scripts/run-test.sh test_night_dimming.gd 60 → NIGHT DIMMING RESULT: 30/30 passed"],
         font=26, credit="written by Claude Code")},
     "Code beat: a test excerpt.")

beat("B23", "RESULT",
     "Every suite passes through the test wrapper at fixed frame rates. Then come three deliberate breaks: a "
     "missing semicolon, a renamed uniform, a deleted source colour. Each one made a test exit with status one, "
     "which proves the tests can fail. What they can't show is whether any of this looks right. A headless run "
     "draws nothing. That part takes eyes.",
     {"type": "GRAPHIC", "remotion": {"pattern": "GodotEngineEvidence", "props": {}},
      "show": [{"at": "Every suite", "event": "Recorded output lines"},
               {"at": "three deliberate breaks", "event": "Three mutation cards turn red: exit 1"},
               {"at": "can't show", "event": "What no headless run can show"}]},
     "Result of B22: recorded test output and mutations.")

beat("B24", "CAUGHT",
     "Not everything was right the first time. The Claude dot M D draft said the van updates every frame; it's "
     "every physics tick, fixed in review with the author's approval. Two agent-written tests were wrong until "
     "they failed. An audit caught the fog shader drifting from its brief, which the author settled with a dated "
     "revision. And the author stopped Claude from searching outside the project folder.",
     {"type": "GRAPHIC", "remotion": {"pattern": "GodotEngineEvidence", "props": {}},
      "show": [{"at": "every frame", "event": "Card 1"}, {"at": "Two agent-written", "event": "Card 2"},
               {"at": "An audit", "event": "Card 3"}, {"at": "stopped Claude", "event": "Card 4"}]},
     "Agent mistakes caught, with who/what caught each (FRICTIONAL.md, TEST-REPORT.md).")

beat("B25", "CONTRIBUTIONS",
     "Who did what. The author wrote the brief and its predictions, all three shaders, the annotations and the "
     "language notes, and played the build. Claude Code wrote the driver, the tests, the texture script, the "
     "materials and overlays, the captures, the audit and this film. The fog textures are original, generated by "
     "code; the Poly Haven pair is only used in a test. The revision shown is on screen.",
     {"type": "GRAPHIC", "remotion": {"pattern": "GodotEngineEvidence", "props": {}},
      "show": [{"at": "The author", "event": "Author column"}, {"at": "Claude Code wrote", "event": "Claude Code column"},
               {"at": "fog textures", "event": "Sources card"}, {"at": "revision", "event": "Revision card"}]},
     "Human/AI contributions, texture sources, revision shown.")

beat("B26", "VERDICT",
     "Let's recap with Claude. Implemented: a dashboard shader driven by the headlights, and a textured fog shader "
     "shared by two materials. Verified: hand predictions matched the captures, and the tests failed when they "
     "should. Still open: why Compatibility showed no colour-space split, and how the fog layers with rain. Human "
     "judgement: whether it reads well at night. Next step: profile the fog on the MacBook Air M one this game targets.",
     {"type": "GRAPHIC", "remotion": {"pattern": "ClaudeVerdictArtifact", "props": {
         "artifactTitle": "Verdict", "artifactHeading": TITLE,
         "artifactLines": [
             "Implemented: a headlight-driven dashboard shader and a textured fog shader with two materials.",
             "Verified: hand predictions matched the captures; deliberate breaks failed the tests.",
             "Open: the Compatibility hint result, fog layered with rain, and M1 performance.",
             "Human judgement: whether it reads well at night."]}}},
     "Walker bookend 4a: verdict separates implemented work, limitations and human judgement.",
     lead_silence_s=0.5,
     qc={"sparse_by_design": True, "sparse_reason": "Locked ClaudeVerdictArtifact bookend: the component fixes "
         "the card layout and the four recap lines are the mandated content; the cream around it is the card's page."})

beat("B27", "HANDOFF",
     "Your turn. Paste this into Claude. Please use Walker to help me test one change to my night dashboard "
     "shader. I will add a clamp to night amount myself. Before I run anything, check my prediction for the "
     "dial hub pixel at night amount two point zero after the clamp, then run the capture script and show me "
     "predicted versus measured. One small change, a prediction you commit to first, and a capture that can "
     "prove you wrong. Judge Claude's answer on three things: it asks for your number before running anything, "
     "it shows the measured pixel, and it flags a mismatch instead of explaining it away. Liam, in for Bear.",
     {"type": "GRAPHIC", "remotion": {"pattern": "ClaudeComposerAsk", "props": {
         "command": "Please use Walker to help me test one change to my night dashboard shader. I will add a "
                    "clamp to night_amount myself. Before I run anything, check my prediction for the dial-hub "
                    "pixel at night_amount 2.0 after the clamp, then run the capture script and show me "
                    "predicted versus measured.",
         "topic": "YOUR TURN · BLACKRIDGE", "segment": TITLE, "greeting": "Your turn.",
         "runningText": "paste this into Claude…", "folderLabel": "@NikBearBrown"}}},
     "HANDOFF LAW + walker Your Turn: Liam reads the prompt aloud, discusses it, signs off.")

beat("B28", "OUTRO",
     f"{TITLE}. At Nik Bear Brown.",
     {"type": "GRAPHIC", "remotion": {"pattern": "ClaudeTitleOutro", "props": {"title": TITLE, "slug": SLUG}}},
     "OUTRO-LOCK: exact title, hardcoded @NikBearBrown, slug-seeded mascot, spoken title + handle, 1.0 s silent tail.",
     kind="outro_voice", tail_silence_s=1.0)

EVIDENCE = REEL / "build" / "evidence_props.json"
if EVIDENCE.exists():
    extra = json.loads(EVIDENCE.read_text())
    for b in BEATS:
        add = extra.get(b["beat_id"])
        if add:
            if "narration_text" in add:
                b["narration_text"] = add["narration_text"]
            if "props" in add:
                b["shot"]["remotion"]["props"] = add["props"]
            if "evidence_media" in add:
                b["shot"]["evidence_media"] = add["evidence_media"]
            if "show" in add:
                b["shot"]["show"] = add["show"]

old = {}
sheet_path = REEL / "beat_sheet.json"
if sheet_path.exists():
    old = {b["beat_id"]: b for b in json.loads(sheet_path.read_text())["beats"]}
for b in BEATS:
    prev = old.get(b["beat_id"])
    if prev and prev.get("narration_text") == b["narration_text"]:
        for k in ("audio_file", "actual_duration_s", "render_duration_s", "build", "audio_notes"):
            if k in prev:
                b[k] = prev[k]
    dur = b.get("actual_duration_s")
    props = b["shot"].get("remotion", {}).get("props")
    if dur and isinstance(props, dict) and b["shot"]["remotion"]["pattern"] in ("GodotDevWorkbench", "GodotEngineEvidence"):
        props["durationSeconds"] = dur

sheet = {
    "metadata": {
        "title": TITLE, "slug": SLUG, "kind": "godot-gamedev", "modifier": "walker",
        "game": PROJECT, "game_project": "game/", "brand": "claude-liam",
        "audience": "Godot developers and students following the @NikBearBrown Claude workflows",
        "register": "Teardown", "engine": "kokoro", "voice": "am_onyx", "voice_kokoro": "am_onyx",
        "palette": "claude", "style_preset": "claude", "aspect_ratio": "16:9", "fit": "contain", "fps": FPS,
        "captions": False, "channel": "@NikBearBrown", "channel_title": "@NikBearBrown",
        "folderLabel": "@NikBearBrown", "greeting": "Namaste, Liam",
        "greeting_note": "hello lexicon: Namaste (Hindi). Liam never takes Wagwan (IN-FOR-BEAR LAW).",
        "persona": "Liam (in for Bear)", "presenter": "Liam (in for Bear)", "in_for_bear": True,
        "teaching_contract": "code-then-result-v1",
        "note": "Narration never frames the work as course requirements (author's instruction, 2026-10-29).",
    },
    "beats": BEATS,
}
sheet_path.write_text(json.dumps(sheet, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"wrote {sheet_path.relative_to(REPO)}: {len(BEATS)} beats")
