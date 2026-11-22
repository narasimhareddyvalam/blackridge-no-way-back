"""Writes gamedev-evidence.json (schema 1, teaching_contract code-then-result-v1) for Assignment 7.

Every authored file under game/ (except .godot/ and .uid) is either associated with a component
explained on screen or excluded with a reason. Every file changed during Assignment 7 (since the
brief's parent, e284453^) must belong to a component. Excerpts and code/result pairs are derived
from beat_sheet.json so they cannot drift.
Run: python3 build/ledger.py   (then ./art godot-gamedev --check REEL --game game)
"""
import hashlib
import json
import subprocess
from pathlib import Path

REEL = Path(__file__).resolve().parents[1]
REPO = REEL.parents[1]
GAME = REPO / "game"
A7_START = "e284453^"


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


inventory = sorted(p.relative_to(GAME).as_posix() for p in GAME.rglob("*")
                   if p.is_file() and not any(x in (".godot", ".git") for x in p.relative_to(GAME).parts)
                   and p.suffix != ".uid")


def under(prefix):
    return [p for p in inventory if p.startswith(prefix)]


VAN = "features/vehicles/freight_van/"
DRIVER = "features/characters/driver/"
ETHAN = "features/characters/ethan/"
RIFLE = "features/weapons/rifle/"
COMPONENTS = [
    ("ring-cycle", "The cycle: RingIcon, a Sprite2D slicing the six-cell sheet (hframes 6), and "
     "RingPlayer's frame track (phone_ring.tres: 0.6 s, step 0.1, LOOP_LINEAR, discrete, keys 0-5), "
     "played and stopped only by navigation_display.gd while Maya's call rings.",
     ["B04", "B05", "B06", "B07"],
     ["animations/phone_ring.tres", VAN + "navigation_display.gd", VAN + "van_presentation.gd",
      VAN + "art/ring/phone_ring.png", VAN + "art/ring/phone_ring.png.import",
      VAN + "art/ring/ATTRIBUTION.md", "tests/test_ring_readback.gd"]),
    ("enter-van", "The committing action: Mixamo's Entering Car in ethan.glb (164 frames at 30 fps, "
     "LOOP_NONE in its importer), its phase table as the app's constants (22, 32, 48, 62), the "
     "boarding loop reading clip_time() for the door and the hand, its interrupts and Step 7's r1.",
     ["B08", "B09", "B10", "B11", "B12", "B13", "B15", "B16"],
     [ETHAN + "ethan.glb", ETHAN + "ethan.glb.import", "app/first_drive.gd",
      "tests/test_rig_readback.gd", "tests/test_animation_edges.gd", "tests/test_animation_pins.gd"]),
    ("authority", "One authority over Ethan's AnimationPlayer: driver.gd (play_clip, _play) and the "
     "helpers it builds and calls (push_gait.gd, rifle_carry.gd); stance.gd only reads; the structure "
     "and state tests.",
     ["B14", "B15"],
     [DRIVER + "driver.gd", DRIVER + "push_gait.gd", DRIVER + "stance.gd",
      "tests/test_animation_structure.gd", "tests/test_animation_states.gd"]),
    ("rifle-reload", "The third clip: Mixamo's reloading for Ethan (100 frames, upper body only) on "
     "the UpperBody player rifle_carry.gd builds, the M16 held by rifle_hold.gd with the magazine "
     "and charging handle on the clip's frames, the gun's timer equal to the clip, wired into "
     "Mission 3's fight.",
     ["B17", "B18"],
     [DRIVER + "rifle_carry.gd", RIFLE + "rifle_hold.gd", "features/weapons/pistol/handgun.gd",
      "features/missions/last_run/hangar_encounter.gd", "animations/ethan_rifle.tres"]
     + under(RIFLE) + ["tests/test_reload_readback.gd", "tests/test_reload_edges.gd",
                       "tests/test_reload_pins.gd", "tests/test_hangar.gd"]),
    ("shock", "The fourth clip: Shock, 105 frames keyed by tools/art/make_ethan_shock.gd over "
     "EnterVan's last frame, played by driver.gd's play_seated with the wrists by IK on the wheel's "
     "rim, inside Mission 1's 4 s hold after the van comes to rest.",
     ["B19", "B20"],
     ["animations/ethan_shock.tres", DRIVER + "driver.gd", "app/first_drive.gd",
      "features/missions/night_freight/first_drive.gd", "tests/test_shock_readback.gd",
      "tests/test_shock_state.gd", "tests/test_shock_pins.gd"]),
    ("superseded", "The pistol attempts the author turned down (#386, #393): the hand-keyed reload "
     "and the pistol's upper-body clips, kept converted but unused.",
     ["B22"],
     ["animations/pistol_reload.tres", "animations/ethan_pistol.tres"]),
    ("checks", "The read-back helper and every test: read-backs, structure, states, edges, pins, "
     "and the earlier suites still passing.",
     ["B09", "B21"],
     under("tests/")),
]

owner = {}
for cid, _, _, paths in COMPONENTS:
    for p in paths:
        owner.setdefault(p, []).append(cid)
missing = [p for p in owner if p not in inventory]
assert not missing, f"component paths not in inventory: {missing}"
changed = subprocess.check_output(["git", "-C", str(REPO), "diff", "--name-only", A7_START, "HEAD",
                                   "--", "game"], text=True).split()
changed = [c.removeprefix("game/") for c in changed if not c.endswith(".uid")]
orphans = [c for c in changed if c in inventory and c not in owner]
assert not orphans, f"files changed in Assignment 7 without a component: {orphans}"

ROLES = {".gdshader": "shader", ".gd": "script", ".tres": "animation", ".tscn": "scene",
         ".import": "import settings", ".png": "texture", ".webp": "texture", ".jpg": "texture",
         ".glb": "model", ".godot": "configuration", ".cfg": "configuration", ".md": "documentation"}
files, exclusions = [], []
for p in inventory:
    if p in owner:
        role = next((r for ext, r in ROLES.items() if p.endswith(ext)), "data")
        files.append({"path": p, "sha256": sha(GAME / p), "role": role, "component_ids": owner[p]})
    else:
        exclusions.append({"path": p, "reason":
            "Pre-existing Blackridge system or asset from before Assignment 7 (e284453^): environment, "
            "audio, UI, missions, characters, vehicle art, shaders, effects and shared builders, "
            "unchanged by this assignment. It appears only as context inside the captured footage."})

sheet = json.loads((REEL / "beat_sheet.json").read_text())
beats = sheet["beats"]
excerpts, pairs = [], []
OBS = {
    "B05": "The sheet's six cells: the handset alone, one, two and three arcs, then the arcs fading; "
           "on the dash, six frames three apart run through one 0.6 s cycle of the arcs.",
    "B07": "In play, the dash zoomed while Maya's call rings: the handset's arcs pulse in a steady loop "
           "beside 'Maya, incoming call'.",
    "B09": "From an empty cache the read-back passes 9/9 with LOOP_NONE and 114 bone tracks; with the "
           "importer set to 1 it fails E7 and E8 (7/9).",
    "B11": "Strip r1 at each boundary: facing the door (clip 0), the reach (22), the hand on the handle "
           "with the door shut (32), the door open (48), rising into the cab (58), seated (70).",
    "B13": "The per-frame log: at the clip's frame 34 the door reads 0.011, the value for frame 33, so "
           "the door runs one frame behind the hand.",
    "B15": "W at clip 16 moves him 0.000 m and boarding runs on; Esc at clip 40 freezes the clip and the "
           "door at 41 and 0.593 for 40 frames under the pause menu, then resumes; R at clip 56 seats "
           "him at once.",
    "B18": "Aiming, R: the HUD reads RELOADING, the empty magazine drops, the fresh one comes up in his "
           "left hand and is seated, the charging handle is pulled; the HUD then reads 30/12.",
    "B20": "Through the windshield: he startles, breathes hard, shakes his head, drops toward the "
           "wheel, looks to each mirror and stares, his hands on the wheel's rim throughout.",
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
