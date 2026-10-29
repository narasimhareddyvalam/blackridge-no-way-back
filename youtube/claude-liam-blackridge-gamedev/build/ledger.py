"""Writes gamedev-evidence.json (schema 1, teaching_contract code-then-result-v1).

Every authored file under game/ (except .godot/ and .uid) is either associated with
a component explained on screen or excluded with a reason. Excerpts and
code/result pairs are derived from beat_sheet.json so they cannot drift.
Run: python3 build/ledger.py   (then ./art godot-gamedev --check REEL --game game)
"""
import hashlib
import json
from pathlib import Path

REEL = Path(__file__).resolve().parents[1]
GAME = REEL.parents[1] / "game"


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


inventory = sorted(p.relative_to(GAME).as_posix() for p in GAME.rglob("*")
                   if p.is_file() and not any(x in (".godot", ".git") for x in p.relative_to(GAME).parts)
                   and p.suffix != ".uid")

COMPONENTS = [
    ("night-dimming", "Hand-written canvas_item shader dims the 2D instrument cluster toward amber while "
     "FreightVan.headlights_on is true; a code-made driver fades night_amount by delta and reverses mid-fade.",
     ["B04", "B05", "B06", "B07", "B08"],
     ["shaders/night_cluster.gdshader", "features/vehicles/freight_van/night_dimming.gd",
      "features/vehicles/freight_van/instruments.gd", "features/vehicles/freight_van/freight_van.gd"]),
    ("fog-windshield", "Spatial fog shader with seven grouped uniforms and three textures (colour, normal, "
     "data); one shader, two ShaderMaterials on overlays beside the windshield and the driver's window.",
     ["B09", "B10", "B11", "B12", "B13", "B14", "B15", "B16"],
     ["shaders/foggy_windshield.gdshader", "materials/windshield/light_fog.tres",
      "materials/windshield/heavy_fog.tres", "features/vehicles/freight_van/van_presentation.gd"]
     + [p for p in inventory if p.startswith("assets/textures/windshield/")]),
    ("hint-experiment", "Two samplers read one three-band image with and without source_color; unshaded quads "
     "show the values under Compatibility and a Forward+ comparison.",
     ["B17", "B18", "B19"],
     ["shaders/hint_experiment.gdshader"] + [p for p in inventory if p.startswith("experiments/hint_experiment/")]),
    ("generated-shader", "Godot's StandardMaterial3D conversion, annotated by the author, compared line-by-line "
     "and rendered beside the hand-written fog shader with the same textures.",
     ["B20", "B21"], ["shaders/standard_generated.gdshader"]),
    ("tests", "Headless suites: uniform-list contract, real input timing at 30/60/144 fps, material/import "
     "audit, and the normal-map curl check calibrated on a Poly Haven pair.",
     ["B14", "B22", "B23"],
     [p for p in inventory if p.startswith("tests/")]),
    ("project-config", "project.godot names the Compatibility renderer (line 125), the main scene and the "
     "headlights (L) and left_window (J) input actions the captures press.",
     ["B02", "B03"], ["project.godot"]),
]

files, exclusions = [], []
owner = {}
for cid, _, _, paths in COMPONENTS:
    for p in paths:
        owner.setdefault(p, []).append(cid)
missing = [p for p in owner if p not in inventory]
assert not missing, f"component paths not in inventory: {missing}"
for p in inventory:
    if p in owner:
        role = ("shader" if p.endswith(".gdshader") else "script" if p.endswith(".gd") else
                "material" if p.endswith(".tres") else "scene" if p.endswith(".tscn") else
                "import settings" if p.endswith(".import") else "texture" if p.endswith(".png") else
                "configuration" if p.endswith(".godot") else "documentation")
        files.append({"path": p, "sha256": sha(GAME / p), "role": role, "component_ids": owner[p]})
    elif p.endswith("_legends.png.import"):
        exclusions.append({"path": p, "reason":
            "Pre-existing label texture's import settings. The Godot editor's Detect 3D reimport rewrote them "
            "during this work (VRAM Compressed; TEST-REPORT.md, commit df5a1fd). Not shader code and not "
            "taught in this film."})
    else:
        exclusions.append({"path": p, "reason":
            "Pre-existing Blackridge system or asset from the baseline project (commit e81ec92: environment, "
            "audio, UI, missions, vehicle art, shared builders). Unchanged in substance by this shader work and "
            "outside this film's scope; it appears only as context inside the captured footage."})

sheet = json.loads((REEL / "beat_sheet.json").read_text())
beats = sheet["beats"]
order = [b["beat_id"] for b in beats]
excerpts, pairs = [], []
OBS = {
    "B05": "Captured cluster pixels at night_amount 0.0/0.5/1.0 equal the hand predictions (18/18); 2.0 set from code goes darker, so hint_range did not clamp.",
    "B08": "Pressing L fades the dashboard between amber and mint-white; a mid-fade double tap reverses without a jump.",
    "B10": "Pressing J lowers the driver's window and its heavy-fog overlay together.",
    "B12": "Each uniform swept min/default/max on light_fog changes the windshield fog as its range describes.",
    "B14": "The three bound textures are the actual generated files with explicit import settings; the normal map reads as OpenGL (curl check).",
    "B16": "Editing the light_fog material changes only the windshield; editing the shared shader line changes both windows.",
    "B18": "Forward+ shows 137/188/225 on the data quad as predicted; Compatibility shows the file values on both quads.",
    "B21": "Godot's generated shader renders the textures as an opaque lit surface; the hand-written fog shader is transparent with a clear centre.",
    "B23": "Recorded suite results pass; each deliberate mutation made its test exit 1.",
}
for i, b in enumerate(beats):
    rem = b.get("shot", {}).get("remotion", {})
    if rem.get("pattern", "").startswith("GodotDevWorkbench") and rem.get("props", {}).get("code"):
        p = rem["props"]
        rel = p["path"].removeprefix("game/")
        n = p["code"].count("\n") + 1
        excerpts.append({"beat_id": b["beat_id"], "path": rel, "start_line": p["startLine"],
                         "end_line": p["startLine"] + n - 1, "text": p["code"]})
        nxt = beats[i + 1]
        media = nxt["shot"].get("evidence_media")
        assert media, f"{nxt['beat_id']} has no evidence_media yet"
        pairs.append({"code_beat": b["beat_id"], "result_beat": nxt["beat_id"],
                      "observation": OBS[nxt["beat_id"]],
                      "media": {"path": media, "sha256": sha(REEL / media)}})

ledger = {"schema_version": 1, "teaching_contract": "code-then-result-v1",
          "game": "Blackridge: No Way Back", "game_root": "game/",
          "components": [{"id": c, "explanation": e, "beat_ids": bs, "files": ps} for c, e, bs, ps in COMPONENTS],
          "files": files, "exclusions": exclusions, "excerpts": excerpts, "code_result_pairs": pairs}
(REEL / "gamedev-evidence.json").write_text(json.dumps(ledger, indent=2, ensure_ascii=False) + "\n")
print(f"files {len(files)} · exclusions {len(exclusions)} · excerpts {len(excerpts)} · pairs {len(pairs)}")
