"""Prepares evidence media and result-beat props for "Blackridge, Shaded".

- Copies the exact evidence files into the reel (hash-identical) and into the
  Remotion public folder (blackridge-shaded/), which staticFile() reads.
- Typesets maths with the toolkit's typeset_math.py (structured SVG).
- Writes build/evidence_props.json, merged by build_sheet.py.
Run with the toolkit venv:  ~/Desktop/brutalist.art/.venv/bin/python3 build/evidence.py
"""
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REEL = Path(__file__).resolve().parents[1]
REPO = REEL.parents[1]
GAME = REPO / "game"
TOOLKIT = Path.home() / "Desktop" / "brutalist.art"
PUBLIC = TOOLKIT / "runtime" / "remotion" / "public" / "blackridge-shaded"
sys.path.insert(0, str(TOOLKIT / "runtime" / "scripts"))
import typeset_math  # noqa: E402

WORDS = {}
_w = REEL / "mp3" / "words.json"
if _w.exists():
    data = json.loads(_w.read_text())
    fps = data.get("fps", 30)
    WORDS = {b: [(w["text"].strip(".,;:!?\"'()").lower(), w["startFrame"] / fps) for w in ws]
             for b, ws in data["beats"].items()}


def when(bid, phrase, fallback=0.0):
    target = [t.strip(".,;:!?\"'()").lower() for t in phrase.split()]
    toks = WORDS.get(bid, [])
    for i in range(len(toks) - len(target) + 1):
        if all(toks[i + j][0] == target[j] for j in range(len(target))):
            return round(toks[i][1], 2)
    print(f"  ! {bid}: phrase not found: {phrase!r}; using {fallback}")
    return fallback


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def stage(src, name):
    """Copy an evidence file into reel/evidence and the public folder; return (reel_rel, public_rel)."""
    src = Path(src)
    dst = REEL / "evidence" / name
    dst.parent.mkdir(parents=True, exist_ok=True)
    if not dst.exists() or sha(dst) != sha(src):
        shutil.copy2(src, dst)
    pub = PUBLIC / name
    pub.parent.mkdir(parents=True, exist_ok=True)
    if not pub.exists() or sha(pub) != sha(dst):
        shutil.copy2(dst, pub)
    return f"evidence/{name}", f"blackridge-shaded/{name}"


def stage_reel(rel):
    """Sync a file that already lives in the reel (e.g. capture/...) to the public folder."""
    src = REEL / rel
    pub = PUBLIC / rel
    pub.parent.mkdir(parents=True, exist_ok=True)
    if not pub.exists() or sha(pub) != sha(src):
        shutil.copy2(src, pub)
    return rel, f"blackridge-shaded/{rel}"


def size(p):
    with Image.open(p) as im:
        return im.size


def recorded_output_png(out):
    """Typeset verbatim result lines from logs/ into a terminal-style teaching view."""
    picks = [
        ("logs/test_night_dimming_30fps.log", "NIGHT DIMMING RESULT"),
        ("logs/test_night_dimming_60fps.log", "NIGHT DIMMING RESULT"),
        ("logs/test_night_dimming_144fps.log", "NIGHT DIMMING RESULT"),
        ("logs/test_materials_60fps.log", "MATERIALS RESULT"),
        ("logs/first_drive_regression_60fps.log", "REGRESSION RESULT"),
        ("logs/first_drive_integration_60fps.log", "BEHAVIOR RESULT"),
    ]
    rows = []
    for rel, key in picks:
        line = next(l for l in (REPO / rel).read_text().splitlines() if key in l)
        rows.append((rel, line.strip()))
    font = ImageFont.truetype(str(TOOLKIT / "runtime/fonts/PT_Mono/PTMono-Regular.ttf"), 54)
    small = ImageFont.truetype(str(TOOLKIT / "runtime/fonts/PT_Mono/PTMono-Regular.ttf"), 44)
    w, h = 1900, 150 + 138 * len(rows)
    im = Image.new("RGB", (w, h), (32, 37, 49))
    d = ImageDraw.Draw(im)
    d.text((44, 40), "Recorded output · verbatim from logs/", font=small, fill=(139, 199, 243))
    y = 128
    for rel, line in rows:
        d.text((44, y), rel, font=small, fill=(190, 200, 215))
        d.text((44, y + 52), line, font=font, fill=(237, 241, 247))
        y += 138
    im.save(out)
    return rows


def typeset_lines(out, title, picks):
    """Typeset verbatim log lines (path, substring) into a terminal-style teaching view."""
    rows = []
    for rel, key in picks:
        line = next(l for l in (REPO / rel).read_text().splitlines() if key in l)
        rows.append((rel, line.strip()))
    font = ImageFont.truetype(str(TOOLKIT / "runtime/fonts/PT_Mono/PTMono-Regular.ttf"), 46)
    small = ImageFont.truetype(str(TOOLKIT / "runtime/fonts/PT_Mono/PTMono-Regular.ttf"), 38)
    w, h = 2300, 140 + 112 * len(rows)
    im = Image.new("RGB", (w, h), (32, 37, 49))
    d = ImageDraw.Draw(im)
    d.text((48, 36), title, font=small, fill=(139, 199, 243))
    y = 112
    for rel, line in rows:
        d.text((48, y), rel, font=small, fill=(190, 200, 215))
        d.text((48, y + 42), line, font=font, fill=(237, 241, 247))
        y += 112
    im.save(out)


def clip_segments(bid, rel, segments, crop=None):
    """Real-time segments of one take, cut only between inputs. segments: (label, phrase, fallback, press_t, lead)."""
    _, pub = stage_reel(rel)
    w, h = 3840, 2400
    out_media, out_rows = [], []
    for i, (label, phrase, fb, press_t, lead) in enumerate(segments):
        spoken = when(bid, phrase, fb)
        if i == 0:
            spoken = max(spoken, 0.6)
        at = 0.0 if i == 0 else max(0.0, spoken - lead)
        start = max(0.0, press_t - (spoken - at))
        out_rows.append({"label": label, "at": round(at, 2)})
        out_media.append({"kind": "video", "src": pub, "aspect": w / h, "startFrom": round(start, 3), "row": i,
                          "caption": "full frame"})
        if crop:
            out_media.append({"kind": "video", "src": pub, "aspect": w / h, "startFrom": round(start, 3), "row": i,
                              "crop": crop, "caption": "dashboard crop (native pixels)"})
    return out_media, out_rows


def math_rows(exprs):
    return [dict(typeset_math.typeset(e), at=at) for e, at in exprs]


P = {}

# B02 — the game and what this build adds (real 4K engine still)
if (REEL / "capture/cockpit_hero_4k.png").exists():
    rel, pub = stage_reel("capture/cockpit_hero_4k.png")
    w, h = size(REEL / rel)
    P["B02"] = {"props": {
        "title": "What This Build Adds", "layout": "media",
        "label": f"Held frame · engine capture, scripted · native {w} × {h}",
        "media": [{"kind": "image", "src": pub, "aspect": w / h, "caption": "", "at": 0}],
        "source": "capture/cockpit_hero_4k.png · capture/CAPTURE.md · game/project.godot:125",
        "cards": [
            {"label": "Already built", "text": "van · district · driving (baseline e81ec92)", "at": when("B02", "already had", 0.5)},
            {"label": "State → colour", "text": "night_cluster.gdshader, driven by headlights_on", "at": when("B02", "a shader whose", 4)},
            {"label": "Textures → fog", "text": "foggy_windshield.gdshader · two materials", "at": when("B02", "a textured shader", 7)},
            {"label": "Hint experiment", "text": "hint_experiment.gdshader", "at": when("B02", "an experiment", 9)},
            {"label": "Godot's own shader", "text": "standard_generated.gdshader, annotated", "at": when("B02", "a close reading", 12)},
            {"label": "Engine", "text": "Godot 4.7.2 · Compatibility renderer\nproject.godot:125", "tone": "accent", "at": when("B02", "Compatibility", 16)}]}}

# B03 — the specification, verbatim
brief = (REPO / "CHANGE-BRIEF.md").read_text().splitlines()
excerpt = "CHANGE-BRIEF.md:59\n" + brief[58] + "\n\nCHANGE-BRIEF.md:42–46\n" + "\n".join(brief[41:46])
claude_md = (REPO / "CLAUDE.md").read_text().splitlines()
assert claude_md[90] == "@CHANGE-BRIEF.md"
P["B03"] = {
    "props": {"title": "The Specification Came First", "label": "Document excerpt · verbatim",
              "layout": "document", "documentLabel": "CHANGE-BRIEF.md (committed 2729c26, before any shader)",
              "excerpt": excerpt,
              "source": "CHANGE-BRIEF.md:42–46, 59 · CLAUDE.md:91 · git log --oneline",
              "cards": [
                  {"label": "Fade", "text": "on 0.25 s · off 0.35 s", "at": when("B03", "quarter", 7)},
                  {"label": "Retrigger", "text": "reverse from the current value", "at": when("B03", "retrigger", 10)},
                  {"label": "Tolerance", "text": "± one frame: 33.3 / 16.7 / 6.9 ms\nat 30 / 60 / 144 fps", "at": when("B03", "One frame", 12)},
                  {"label": "Time scale", "text": "0.5 → on-fade ≈ 0.50 s of real time", "at": when("B03", "One frame", 12) + 1.5},
                  {"label": "Commit order", "text": "2729c26 brief → c055037 first shader", "mono": True, "at": when("B03", "commit history", 16)},
                  {"label": "Imported", "text": "CLAUDE.md:91  @CHANGE-BRIEF.md", "mono": True, "at": when("B03", "imports", 19)}]}}

# B05 — controlled values (existing engine SubViewport captures)
items, rows = [], []
for i, v in enumerate(["0.0", "0.5", "1.0", "2.0"]):
    rel, pub = stage(REPO / f"evidence/captures/night_cluster_{v}.png", f"night_cluster_{v}.png")
    w, h = size(REEL / rel)
    items.append({"kind": "image", "src": pub, "aspect": w / h, "pixelated": True, "row": i,
                  "caption": f"night_amount = {v}" + (" (set from code)" if v == "2.0" else ""),
                  "markers": [{"x": 10 / w, "y": 10 / h, "label": "bg (10,10)"},
                              {"x": 155 / w, "y": 136 / h, "label": "hub (155,136)"}]})
t_three, t_18, t_2 = when("B05", "three settings", 9), when("B05", "eighteen", 12), when("B05", "two point zero", 15)
rows = [{"label": "0.0", "at": 0}, {"label": "0.5", "at": t_three}, {"label": "1.0", "at": t_18},
        {"label": "2.0", "at": t_2}]
P["B05"] = {"evidence_media": "evidence/night_cluster_1.0.png", "props": {
    "title": "Predicted, Then Measured", "layout": "grid", "media": items, "rows": rows,
    "label": "Held frames · engine capture of the 640×256 cluster SubViewport (scripted) · shown enlarged, pixels not smoothed",
    "source": "evidence/captures/night_cluster_*.png · night_cluster_samples.txt · tools/captures/capture_night_cluster.gd",
    "cards": [
        {"label": "Background (10, 10)", "mono": True, "at": when("B05", "dark background", 8),
         "text": "0.0  (8, 14, 18)   → (8, 14, 18)\n0.5  (6, 9, 10)    → (6, 9, 10)\n1.0  (4, 4, 2)     → (4, 4, 2)"},
        {"label": "Dial hub (155, 136)", "mono": True, "at": when("B05", "dial hub", 9),
         "text": "0.0  (135, 156, 148) → (135, 156, 148)\n0.5  (105, 102, 82)  → (105, 102, 82)\n1.0  (74, 47, 16)    → (74, 47, 16)"},
        {"label": "18 of 18 values match", "text": "predicted by hand → measured in the engine", "tone": "pass", "at": t_18},
        {"label": "2.0, set from code", "text": "hub (13, 0, 0) · background (0, 0, 0)\nhint_range draws a slider; it does not clamp", "tone": "fail", "at": t_2}]}}

# B06 — the hand calculation
P["B06"] = {"props": {"title": "Predicted 105, Measured 105", "rows": math_rows([
    (r"R = C\,(1 - a + a\,n\,b)", when("B06", "Factor", 2)),
    (r"135 \times (1 - 0.5 + 0.5 \times 1.0 \times 0.55)", when("B06", "135", 9)),
    (r"= 135 \times 0.775 = 104.625 \approx 105", when("B06", "rounds", 13))]),
    "note": "the colour line, factored",
    "conditions": ""}}

# B08 — the effect in play (take A, real-time segments cut only between presses)
TAKE_A = "capture/take_a_headlights.mp4"
if (REEL / TAKE_A).exists():
    CLUSTER = {"x": 0.234, "y": 0.575, "w": 0.581, "h": 0.208}
    media, rows = clip_segments("B08", TAKE_A, [
        ("L · lights off", "Lights off", 1.5, 2.983, 0.0),
        ("L · lights on", "Lights on", 6.5, 8.483, 1.0),
        ("L L · reverses mid-fade", "Tap L twice", 10.5, 11.983, 1.0)], crop=CLUSTER)
    timing = REEL / "evidence" / "recorded_fade_timing.png"
    typeset_lines(timing, "Recorded output · test_night_dimming.gd through scripts/run-test.sh (typeset verbatim)", [
        ("logs/test_night_dimming_30fps.log", "Off-fade 1 -> 0"), ("logs/test_night_dimming_30fps.log", "On-fade 0 -> 1"),
        ("logs/test_night_dimming_60fps.log", "Off-fade 1 -> 0"), ("logs/test_night_dimming_60fps.log", "On-fade 0 -> 1"),
        ("logs/test_night_dimming_144fps.log", "Off-fade 1 -> 0"), ("logs/test_night_dimming_144fps.log", "On-fade 0 -> 1")])
    trel, tpub = stage(timing, "recorded_fade_timing.png")
    tw, th = size(REEL / trel)
    media.append({"kind": "image", "src": tpub, "aspect": tw / th, "row": 3, "caption": ""})
    rows.append({"label": "recorded timing · 30 / 60 / 144 fps", "at": when("B08", "The tests", 12.5)})
    keys = REEL / "capture" / "take_a_headlights_keyframes.png"
    if not keys.exists():
        tiles = []
        for t in (2.9, 3.4, 8.8, 12.1):
            f = REEL / "_qc" / "pilot" / f"_k_{t}.png"
            f.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-ss", str(t), "-i", str(REEL / TAKE_A),
                            "-frames:v", "1", str(f)], check=True)
            tiles.append(Image.open(f).convert("RGB").resize((960, 600)))
        strip = Image.new("RGB", (1920, 1200))
        for i, im in enumerate(tiles):
            strip.paste(im, ((i % 2) * 960, (i // 2) * 600))
        strip.save(keys)
    P["B08"] = {"evidence_media": "capture/take_a_headlights_keyframes.png", "props": {
        "title": "The Effect in Play", "layout": "grid", "media": media, "rows": rows,
        "label": "Engine capture · scripted input (L) · real-time segments of one take, cut only between presses · fixed 60 fps offline render, not an FPS claim",
        "source": "capture/take_a_headlights.mp4 · capture/take_a_headlights-inputs.jsonl · capture/take_a_headlights-frames.csv · logs/test_night_dimming_*fps.log"}}

# B10 — J lowers the driver's window and its fog (take B)
TAKE_B = "capture/take_b_driver_window.mp4"
if (REEL / TAKE_B).exists():
    WINDOW = {"x": 0.0, "y": 0.146, "w": 0.391, "h": 0.479}
    media, rows = clip_segments("B10", TAKE_B, [("J · window lowers with its fog", "Press J", 0.3, 1.983, 0.0)], crop=WINDOW)
    media[1]["caption"] = "driver's window crop (native pixels)"
    checks = [json.loads(l) for l in (REEL / "capture/take_b_driver_window-inputs.jsonl").read_text().splitlines()]
    labels = [c["label"] for c in checks if c.get("kind") == "check" and c.get("passed") and
              any(k in c["label"] for k in ("lowers the pane by", "overlay moves with the pane", "offset from the pane"))]
    tr = (REPO / "TEST-REPORT.md").read_text().splitlines()
    first = " ".join(l.strip() for l in tr[208:211])
    img = REEL / "evidence" / "window_checks.png"
    font = ImageFont.truetype(str(TOOLKIT / "runtime/fonts/PT_Mono/PTMono-Regular.ttf"), 40)
    small = ImageFont.truetype(str(TOOLKIT / "runtime/fonts/PT_Mono/PTMono-Regular.ttf"), 34)
    import textwrap
    blocks = [("capture/take_b_driver_window-inputs.jsonl (this take's own checks)", labels),
              ("TEST-REPORT.md:209–211 (the first version of the test)", [first])]
    wrapped = [(h, [w for line in ls for w in textwrap.wrap(line, 78)]) for h, ls in blocks]
    hgt = 90 + sum(60 + 52 * len(ls) for _, ls in wrapped)
    im = Image.new("RGB", (2000, hgt), (32, 37, 49)); d = ImageDraw.Draw(im)
    d.text((40, 30), "Recorded output · verbatim", font=small, fill=(139, 199, 243)); y = 90
    for head, ls in wrapped:
        d.text((40, y), head, font=small, fill=(190, 200, 215)); y += 52
        for line in ls:
            d.text((40, y), line, font=font, fill=(237, 241, 247)); y += 52
        y += 8
    im.save(img)
    rel, pub = stage(img, "window_checks.png")
    w, h = size(REEL / rel)
    media.append({"kind": "image", "src": pub, "aspect": w / h, "row": 1, "caption": ""})
    rows.append({"label": "measured in the van's frame", "at": when("B10", "The first version", 7)})
    keys = REEL / "capture" / "take_b_driver_window_keyframes.png"
    if not keys.exists():
        tiles = []
        for t in (1.5, 3.0, 5.0, 13.5):
            f = REEL / "_qc" / "pilot" / f"_kb_{t}.png"
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-ss", str(t), "-i", str(REEL / TAKE_B),
                            "-frames:v", "1", str(f)], check=True)
            tiles.append(Image.open(f).convert("RGB").resize((960, 600)))
        strip = Image.new("RGB", (1920, 1200))
        for i, t_im in enumerate(tiles):
            strip.paste(t_im, ((i % 2) * 960, (i // 2) * 600))
        strip.save(keys)
    P["B10"] = {"evidence_media": "capture/take_b_driver_window_keyframes.png", "props": {
        "title": "The Fog Rides With the Glass", "layout": "grid", "media": media, "rows": rows,
        "label": "Engine capture · scripted input (J) · one real-time take · fixed 60 fps offline render, not an FPS claim",
        "source": "capture/take_b_driver_window.mp4 · -inputs.jsonl · -frames.csv · TEST-REPORT.md:209–211"}}

# B12 — the interface sweep (21 frozen 4K stills, windshield crop) with measured change
SWEEP = [("fog_amount", "0", "0.25", "1"), ("clear_center", "0", "0.65", "0.9"), ("fog_opacity", "0", "0.45", "1"),
         ("edge_softness", "0.01", "0.2", "0.5"), ("normal_strength", "0", "0.5", "2"), ("texture_scale", "0.5", "1", "4"),
         ("fog_tint", "black", "default", "white")]
if (REEL / "capture/sweep_diff.txt").exists():
    diff = {}
    for line in (REEL / "capture/sweep_diff.txt").read_text().splitlines()[1:]:
        name, end = line.split()[0], line.split()[1].rstrip(":")
        diff[(name, end)] = float(line.split()[2].rstrip("%"))
    WS = {"x": 0.286, "y": 0.0, "w": 0.714, "h": 0.574}
    t_fa, t_cc, t_other = when("B12", "Fog amount", 4), when("B12", "Clear centre", 10), when("B12", "The other five", 13)
    media, rows = [], []
    for i, (n, lo, mid, hi) in enumerate(SWEEP):
        for end, val in (("min", lo), ("default", mid), ("max", hi)):
            rel, pub = stage_reel(f"capture/sweep_{n}_{end}.png")
            media.append({"kind": "image", "src": pub, "aspect": 1.6, "crop": WS, "row": i, "caption": f"{end} · {val}"})
        big = max(diff[(n, "min")], diff[(n, "max")])
        at = 0.0 if i == 0 else t_cc if i == 1 else t_other + (i - 2) * 1.2
        rows.append({"label": f"{n} · {big:.2f}%", "at": round(at, 2)})
    assert all(rows[k]["at"] <= rows[k + 1]["at"] for k in range(len(rows) - 1)), rows
    P["B12"] = {"evidence_media": "capture/sweep_fog_amount_max.png", "props": {
        "title": "Every Control, Swept", "layout": "grid", "media": media, "rows": rows,
        "label": "Held frames · engine captures, time frozen, wipers parked · windshield crop of 3840 × 2400 · % = largest share of pixels changed >6 levels vs default",
        "source": "capture/sweep_*.png · capture/sweep_diff.txt (build/sweep_diff.py) · ranges from foggy_windshield.gdshader:7–21"}}

# B18 — hint experiment at 4K, two renderers
if (REEL / "capture/hint_compatibility_4k.png").exists():
    mk = lambda vals: [{"x": x, "y": 0.6875, "label": v} for x, v in zip((0.383, 0.5, 0.617), vals)]
    m = []
    for f, cap, vals in (("hint_forward_plus_4k.png", "Forward+ comparison run", ("137", "188", "225")),
                         ("hint_compatibility_4k.png", "Compatibility · the game's renderer", ("64", "128", "192"))):
        rel, pub = stage_reel(f"capture/{f}")
        m.append({"kind": "image", "src": pub, "aspect": 16 / 9, "caption": cap, "markers": mk(vals),
                  "at": 0 if "forward" in f else when("B18", "But in Compatibility", 15)})
    P["B18"] = {"evidence_media": "capture/hint_compatibility_4k.png", "props": {
        "title": "Same Shader, Two Renderers", "layout": "media", "media": m,
        "label": "Held frames · engine captures at 3840 × 2160, scripted · markers show the sampled data-quad values",
        "source": "capture/hint_*_4k.png · capture/hint_samples_4k.txt · CHANGE-BRIEF.md §4.1",
        "cards": [
            {"label": "Predicted by hand", "mono": True, "at": 0.5, "text": "as colour  64 · 128 · 192\nas data   137 · 188 · 225"},
            {"label": "Forward+ comparison", "mono": True, "tone": "pass", "at": when("B18", "Forward Plus", 11),
             "text": "colour  64 · 128 · 192\ndata   137 · 188 · 225"},
            {"label": "Compatibility (the game)", "mono": True, "tone": "fail", "at": when("B18", "But in Compatibility", 15),
             "text": "colour  64 · 128 · 192\ndata    64 · 128 · 192"},
            {"label": "Still open", "tone": "accent", "at": when("B18", "different numbers", 20),
             "text": "why Compatibility shows no colour-space split here"}]}}

# B21 — generated shader vs the author's fog shader, same texture files
if (REEL / "capture/generated_vs_fog_4k.png").exists():
    rel, pub = stage_reel("capture/generated_vs_fog_4k.png")
    P["B21"] = {"evidence_media": rel, "props": {
        "title": "Same Files, Two Shaders", "layout": "media",
        "media": [{"kind": "image", "src": pub, "aspect": 16 / 9, "caption": "left: generated shader · right: the author's fog shader"}],
        "label": "Engine capture · scripted test scene on an isolated copy (not the game) · 3840 × 2160",
        "source": "capture/generated_vs_fog_4k.png · capture/CAPTURE.md (every parameter set) · capture/scripts/take_f_generated_vs_fog.gd",
        "cards": [
            {"label": "Left · Godot's generated shader", "at": when("B21", "Godot's generated shader", 3),
             "text": "standard_generated.gdshader · fog_color as albedo, fog_normal as normal map · opaque and lit"},
            {"label": "Right · the author's fog shader", "at": when("B21", "The author's shader", 10),
             "text": "light_fog.tres, fog_amount set to 1.0 at runtime for visibility · fog_data makes it patchy · alpha shows the stripes"},
            {"label": "Vocabulary vs meaning", "tone": "accent", "at": when("B21", "The generated code", 15),
             "text": "same texture files; the shader decides what they mean"}]}}

# B16 — one shader, two materials (baseline still, material-edit clip, visible shader-edit clip)
if (REEL / "capture/shader_edit_visible.mp4").exists() and (REEL / "capture/material_edit.mp4").exists():
    _, base_pub = stage_reel("capture/fog_baseline.png")
    _, mat_pub = stage_reel("capture/material_edit.mp4")
    _, sh_pub = stage_reel("capture/shader_edit_visible.mp4")
    t_val = when("B16", "Change one value", 5)
    t_only = when("B16", "only the windshield", 7)
    t_turn = when("B16", "Now turn", 11)
    t_both = when("B16", "both windows", 14)
    r1, r2 = max(0.0, t_val - 0.5), max(0.0, t_turn - 0.3)
    media = [{"kind": "image", "src": base_pub, "aspect": 1.6, "row": 0, "caption": "baseline · light fog on the windshield, heavy fog on the driver's window"},
             {"kind": "video", "src": mat_pub, "aspect": 1.6, "row": 1, "startFrom": round(max(0.0, 2.0 - (t_only - r1)), 3),
              "caption": "material edit · light_fog fog_amount 0.25 → 1.0"},
             {"kind": "video", "src": sh_pub, "aspect": 1.6, "row": 2, "startFrom": round(max(0.0, 2.0 - (t_both - r2)), 3),
              "caption": "shader edit · one line, in memory · windshield fog raised to 1.0 first"}]
    _, mat_after = stage_reel("capture/material_edit_after.png")
    _, sh_after = stage_reel("capture/shader_edit_visible_after.png")
    t_two = max(when("B16", "Two edits", 16.5), r2 + 6.5)
    media += [{"kind": "image", "src": mat_after, "aspect": 1.6, "row": 3, "caption": "held frame · after the material edit"},
              {"kind": "image", "src": sh_after, "aspect": 1.6, "row": 3, "caption": "held frame · after the shader edit"}]
    rows = [{"label": "baseline", "at": 0.0}, {"label": "edit the material", "at": round(r1, 2)},
            {"label": "edit the shader", "at": round(r2, 2)}, {"label": "two edits", "at": round(t_two, 2)}]
    assert t_two <= r2 + 7.0, "shader clip would run out before the recap row"
    P["B16"] = {"evidence_media": "capture/shader_edit_visible_after.png", "props": {
        "title": "One Shader, Two Materials", "layout": "grid", "media": media, "rows": rows,
        "label": "Engine capture · scripted, cockpit paused, wipers parked · real-time clips · fixed 60 fps offline render",
        "source": "capture/fog_baseline.png · material_edit.mp4 · shader_edit_visible.mp4 · take_c*_inputs.jsonl",
        "cards": [
            {"label": "Two materials", "at": 0.5, "text": "light_fog and heavy_fog are different ShaderMaterial objects"},
            {"label": "Material edit", "tone": "pass", "at": t_only, "text": "only the windshield changes; heavy_fog stayed 0.75 on every frame"},
            {"label": "One shader", "at": t_turn, "text": "both materials use the same Shader object: foggy_windshield.gdshader"},
            {"label": "Shader edit (in memory)", "tone": "pass", "at": t_both,
             "text": "ALBEDO line replaced for 5 s, then restored · the file on disk is unchanged"}]}}

# B14 — the actual textures and their import settings
tex = []
for name, cap in [("fog_color.png", "fog_color.png · source_color"), ("fog_normal.png", "fog_normal.png · hint_normal"),
                  ("fog_data.png", "fog_data.png · data, red channel")]:
    rel, pub = stage(GAME / "assets/textures/windshield" / name, name)
    w, h = size(REEL / rel)
    tex.append({"kind": "image", "src": pub, "aspect": w / h, "caption": cap, "at": 0})
P["B14"] = {"evidence_media": "evidence/fog_data.png", "props": {
    "title": "Three Files, Three Meanings", "layout": "media", "media": tex,
    "label": "Source textures · the actual 1024 × 1024 PNG files",
    "source": "game/assets/textures/windshield/*.png + .import · tools/make_fog_textures.py · game/tests/normal_map_check.gd",
    "cards": [
        {"label": "Provenance", "text": "tools/make_fog_textures.py · seed 20261029\nwritten by Claude Code", "at": when("B14", "seeded script", 2)},
        {"label": "Imports, all three", "mono": True, "at": when("B14", "import settings", 7),
         "text": "compress/mode=0   (Lossless)\nmipmaps/generate=true\ndetect_3d/compress_to=0"},
        {"label": "Normal-map mode", "mono": True, "at": when("B14", "normal-map mode", 10),
         "text": "fog_normal       1 (Enable)\nfog_color, data  2 (Disabled)"},
        {"label": "Curl check: lower = reads as GL", "mono": True, "tone": "pass", "at": when("B14", "curl check", 15),
         "text": "Poly Haven GL file  GL 0.5792 · DX 1.4208\nfog_normal.png      GL 0.0033 · DX 1.9967"}]}}

# B19 — the sRGB encode
P["B19"] = {"props": {"title": "The Encode Behind 137", "rows": math_rows([
    (r"\mathrm{encode}(x) = 1.055\,x^{1/2.4} - 0.055", when("B19", "encode", 1)),
    (r"x = \frac{64}{255} \approx 0.251 \quad \Rightarrow \quad \mathrm{encode}(x) \approx 0.538", when("B19", "Feed", 12)),
    (r"0.538 \times 255 \approx 137", when("B19", "137", 17))]),
    "note": "Read as data, the stored value is encoded once on output.",
    "conditions": "For x ≤ 0.0031308 the encode is 12.92 x instead. 128 → 188 and 192 → 225 follow the same way."}}

# B23 — recorded output and the three mutations
out_png = REEL / "evidence" / "recorded_test_output.png"
out_png.parent.mkdir(parents=True, exist_ok=True)
recorded_output_png(out_png)
rel, pub = stage(out_png, "recorded_test_output.png")
w, h = size(REEL / rel)
P["B23"] = {"evidence_media": rel, "props": {
    "title": "What the Tests Prove", "layout": "media",
    "media": [{"kind": "image", "src": pub, "aspect": w / h, "caption": "", "at": 0}],
    "label": "Recorded output · logs/ (typeset verbatim)",
    "source": "logs/*.log · logs/mutation_*_60fps.log · scripts/run-test.sh",
    "cards": [
        {"label": "Semicolon removed", "mono": True, "tone": "fail", "at": when("B23", "missing semicolon", 6),
         "text": "SHADER ERROR: Expected a ';'.\nexit 1 · 25/30"},
        {"label": "Uniform renamed", "mono": True, "tone": "fail", "at": when("B23", "renamed uniform", 7),
         "text": "night_amount → night_level\nexit 1 · 27/30"},
        {"label": "source_color removed", "mono": True, "tone": "fail", "at": when("B23", "deleted source colour", 8),
         "text": "fog_color sampler\nexit 1 · 75/76"},
        {"label": "No headless run can show", "tone": "accent", "at": when("B23", "can't show", 12),
         "text": "readability · natural fog · transparent layering · real-window colour · performance"}]}}

# B24 — caught along the way
P["B24"] = {"props": {"title": "Caught Along the Way", "layout": "cards", "cardColumns": 1,
    "label": "From FRICTIONAL.md and TEST-REPORT.md",
    "source": "FRICTIONAL.md · TEST-REPORT.md (inspect-and-revise) · commits 4bba9b2, 132a068, 2204b55, fe625c4, a09eb4e",
    "cards": [
        {"label": "CLAUDE.md draft", "text": "'each frame' → 'each physics tick' · caught in review, approved by the author (4bba9b2)", "at": when("B24", "every frame", 3)},
        {"label": "Driver test", "text": "counted a frame after the fade ended · caught by a failing test (29/30)", "at": when("B24", "Two agent-written", 9)},
        {"label": "Window test", "text": "measured in world space (1.13 m) · caught by a failing test → 0.880 m in the van's frame", "at": when("B24", "until they failed", 10)},
        {"label": "Audit", "text": "fog shader multiplied instead of mix() · settled by the author's dated brief revision (a09eb4e)", "at": when("B24", "An audit", 12)},
        {"label": "Scope", "text": "Claude searched outside the project folder · stopped by the author", "at": when("B24", "stopped Claude", 17)}]}}

# B25 — who did what (revision filled at render time from build/revision.txt)
revision = (REEL / "build" / "revision.txt").read_text().strip() if (REEL / "build" / "revision.txt").exists() else "set at render"
P["B25"] = {"props": {"title": "Who Did What", "layout": "cards", "cardColumns": 2,
    "label": "From SOURCES.md and FRICTIONAL.md",
    "source": "SOURCES.md · game/assets/textures/windshield/ATTRIBUTION.md · game/tests/calibration/ATTRIBUTION.md",
    "cards": [
        {"label": "The author", "text": "brief + hand predictions · three shaders · annotations · language notes · playtest and human checks · every decision", "at": when("B25", "The author", 1)},
        {"label": "Claude Code", "text": "CLAUDE.md draft · driver · tests + wrapper · texture script · materials + overlays · captures · audit + reports · this film", "at": when("B25", "Claude Code wrote", 8)},
        {"label": "Fog textures", "text": "generated by tools/make_fog_textures.py (seed 20261029) · original\ngreys_3x1.png: tools/make_hint_png.gd", "at": when("B25", "fog textures", 14)},
        {"label": "Calibration only", "text": "Poly Haven box_profile_metal_sheet nor_gl / nor_dx · CC0 · used in a test", "at": when("B25", "Poly Haven", 16)},
        {"label": "Narration", "text": "Kokoro-82M voice am_onyx · local, free (Apache-2.0)", "at": when("B25", "Poly Haven", 16) + 1},
        {"label": "Revision shown", "text": revision, "mono": True, "tone": "accent", "at": when("B25", "revision shown", 19)}]}}

(REEL / "build" / "evidence_props.json").write_text(json.dumps(P, indent=2, ensure_ascii=False) + "\n")
print("evidence props:", ", ".join(sorted(P)))
