"""Writes gamedev-evidence.json (schema 1, teaching_contract code-then-result-v1).

Every authored file under game/ (except .godot/ and .uid) is either associated with a component
explained on screen or excluded with a reason. Every file changed during Assignment 6 (since
c1ee48f) must belong to a component. Excerpts and code/result pairs are derived from
beat_sheet.json so they cannot drift.
Run: python3 build/ledger.py   (then ./art godot-gamedev --check REEL --game game)
"""
import hashlib
import json
import subprocess
from pathlib import Path

REEL = Path(__file__).resolve().parents[1]
REPO = REEL.parents[1]
GAME = REPO / "game"
A6_START = "c1ee48f"


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


inventory = sorted(p.relative_to(GAME).as_posix() for p in GAME.rglob("*")
                   if p.is_file() and not any(x in (".godot", ".git") for x in p.relative_to(GAME).parts)
                   and p.suffix != ".uid")


def under(prefix):
    return [p for p in inventory if p.startswith(prefix)]


VAN = "features/vehicles/freight_van/"
LOOP = "features/environments/industrial_loop/"
COMPONENTS = [
    ("a1-wiper-flick", "Effect A1: the van's wiper_swept signal fires a burst at each top turn from a pool "
     "of two (overlap); the passenger blade's water is wiped by the driver's blade.",
     ["B07", "B08", "B09"],
     ["effects/wiper_flick.tscn", VAN + "van_particles.gd", VAN + "freight_van.gd",
      VAN + "van_presentation.gd", VAN + "wiper.gd", "previews/wiper_flick_preview.gd",
      "previews/wiper_flick_preview.tscn", "tests/test_wiper_flick_config.gd",
      "tests/test_wiper_flick_state.gd"]),
    ("a2-roof-spill", "Effect A2: a new hard brake (8 m/s, 6 m/s² for two ticks) spills the roof's water "
     "down the glass; a second brake while it lives or during the 20 s refill is ignored.",
     ["B09", "B10", "B11"],
     ["effects/roof_spill.tscn", VAN + "van_particles.gd", VAN + "freight_van.gd",
      "previews/roof_spill_preview.gd", "previews/roof_spill_preview.tscn",
      "tests/test_roof_spill_config.gd", "tests/test_roof_spill_state.gd"]),
    ("b1-lamp-rain", "Effect B1: rain in the light of the lamps within 65 m of the camera, eight volumes at "
     "most, started with preprocess and drained on stop; each landing sets off a splash sub-emitter.",
     ["B12", "B13", "B14", "B15", "B18"],
     ["effects/lamp_rain_post.tscn", "effects/lamp_rain_street.tscn", "effects/lamp_rain_door.tscn",
      "effects/lamp_rain_floodlight.tscn", LOOP + "lamp_rain.gd", LOOP + "industrial_loop.gd",
      "previews/lamp_rain_preview.gd", "previews/lamp_rain_preview.tscn",
      "tests/test_lamp_rain_config.gd", "tests/test_lamp_rain_state.gd"]),
    ("b2-exhaust", "Effect B2: exhaust vapour whose amount_ratio follows ignition and throttle (0.15 to "
     "0.80 of a fixed 300); the scene's emission, process and draw parts.",
     ["B04", "B05", "B16", "B17", "B18"],
     ["effects/exhaust_vapour.tscn", VAN + "van_particles.gd", VAN + "freight_van.gd",
      "previews/exhaust_vapour_preview.gd", "previews/exhaust_vapour_preview.tscn",
      "tests/test_exhaust_vapour_config.gd", "tests/test_exhaust_vapour_state.gd"]),
    ("particle-draw", "The draw step shared by all four effects: one particle shader and the five "
     "script-drawn textures.",
     ["B04", "B20", "B23"],
     ["effects/scatter_particle.gdshader"] + under("effects/textures/")),
    ("process-shader", "Step 6: Godot's conversion of B2's process material, saved by Codex at the "
     "author's direction; its scale-over-life and alpha-over-life lines beside the brief's curves.",
     ["B19", "B20"],
     ["shaders/particles_generated.gdshader", "experiments/process_shader_scratch.tscn"]),
    ("checks", "The preview fixtures behind the frame strips, the configuration and state tests, the "
     "headless cost script, the windowed GPU price script, and the earlier suites still passing.",
     ["B06", "B21", "B22"],
     ["previews/preview_fixture.gd"] + under("tests/")),
    ("game-start", "The main scene, the title screen that hides the lamps' rain, the pause menu, and the "
     "project settings the captures run under; the export leaves the previews out.",
     ["B02", "B13"],
     ["app/first_drive.gd", "app/first_drive.tscn", "project.godot", "export_presets.cfg",
      "features/ui/menus/front_menu.gd"]),
    ("world", "At the author's requests (#150–#158), the world around the effects: lamps lighting "
     "downward, the depot's wall lights, an amber streetlight built by script, the wet road with "
     "raindrop rings, guardrails, verge grass and lit mist.",
     ["B18"],
     [LOOP + p for p in ("forest_floor.gd", "ghat_dressing.gd", "hill_ground.gdshader",
                         "lamp_mist.gdshader", "retroreflector.gdshader", "roadside_grass.gd",
                         "verge_grass.gdshader", "wet_asphalt.gdshader", "polyhaven/POLYHAVEN.md")]
     + under(LOOP + "art/streetlight/") + under(LOOP + "polyhaven/textures/green_metal_rust/")
     + under(LOOP + "polyhaven/textures/leafy_grass/")),
]

owner = {}
for cid, _, _, paths in COMPONENTS:
    for p in paths:
        owner.setdefault(p, []).append(cid)
missing = [p for p in owner if p not in inventory]
assert not missing, f"component paths not in inventory: {missing}"
changed = subprocess.check_output(["git", "-C", str(REPO), "diff", "--name-only", A6_START, "HEAD",
                                   "--", "game"], text=True).split()
changed = [c.removeprefix("game/") for c in changed if not c.endswith(".uid")]
orphans = [c for c in changed if c in inventory and c not in owner]
assert not orphans, f"files changed in Assignment 6 without a component: {orphans}"

ROLES = {".gdshader": "shader", ".gd": "script", ".tres": "material", ".tscn": "scene",
         ".import": "import settings", ".png": "texture", ".jpg": "texture", ".glb": "model",
         ".godot": "configuration", ".cfg": "configuration", ".md": "documentation"}
files, exclusions = [], []
for p in inventory:
    if p in owner:
        role = next((r for ext, r in ROLES.items() if p.endswith(ext)), "data")
        files.append({"path": p, "sha256": sha(GAME / p), "role": role, "component_ids": owner[p]})
    else:
        exclusions.append({"path": p, "reason":
            "Pre-existing Blackridge system or asset from before Assignment 6 (c1ee48f): environment, "
            "audio, UI, missions, characters, vehicle art and shared builders, unchanged by this "
            "assignment. It appears only as context inside the captured footage."})

sheet = json.loads((REEL / "beat_sheet.json").read_text())
beats = sheet["beats"]
excerpts, pairs = [], []
OBS = {
    "B05": "Behind the van, the plume appears after the ignition ramp, stops near the pipe, rises and "
           "thins, and glows red in the brake lamps.",
    "B08": "In play on fast wipers, a flick shows at every top turn; the log has nine flicks by frame "
           "255 after the switch to fast at frame 45.",
    "B11": "The second hard brake at frame 25 is ignored (events.txt); the first spill's streams run on "
           "through frames 25 and 30.",
    "B13": "A few frames after the start the fixture's rain fills the light, steady; it drains from the "
           "top after the stop at frame 70 and is hidden by frame 110; in play the pause menu pauses the game.",
    "B15": "Under the lamp, streaks reach the road, with at most a few specks where they land; real-size "
           "splashes are too faint to pick out at this distance.",
    "B17": "In the reverse camera, nothing shows at idle or on the throttle; a narrow red column rises in "
           "the brake lamps at frame 80 and a faint grey wisp at frame 100, gone by frame 130.",
    "B20": "The puffs start small and dense at the pipe and grow and fade as they drift, as lines 254 "
           "(scale_curve) and 255 (alpha_curve) describe.",
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
        assert media, f"{nxt['beat_id']} has no evidence_media"
        pairs.append({"code_beat": b["beat_id"], "result_beat": nxt["beat_id"],
                      "observation": OBS[nxt["beat_id"]],
                      "media": {"path": media, "sha256": sha(REEL / media)}})

ledger = {"schema_version": 1, "teaching_contract": "code-then-result-v1",
          "game": "Blackridge: No Way Back", "game_root": "game/",
          "components": [{"id": c, "explanation": e, "beat_ids": bs, "files": ps}
                         for c, e, bs, ps in COMPONENTS],
          "files": files, "exclusions": exclusions, "excerpts": excerpts, "code_result_pairs": pairs}
(REEL / "gamedev-evidence.json").write_text(json.dumps(ledger, indent=2, ensure_ascii=False) + "\n")
print(f"files {len(files)} · exclusions {len(exclusions)} · excerpts {len(excerpts)} · pairs {len(pairs)}")
