"""Mission 3's step 2, the east road and the harbour flats (#359): each on an APFS clone of game/, then test_harbour_flats.gd at 60 fps
on the clone, three at a time.
Usage: python3 -I mutations_guidance.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TESTS = ["test_harbour_flats.gd"]
MAP = "features/ui/driving_hud/mission_map.gd"
APP = "app/first_drive.gd"
HUD = "features/ui/driving_hud/driving_hud.gd"
GUARD = "features/characters/patrol_guard/patrol_guard.gd"
ESC = "features/missions/the_wrong_cargo/escape.gd"
COMPOUND = "features/environments/industrial_loop/compound.gd"
YARD = "features/environments/industrial_loop/container_yard.gd"
MARKS = "features/ui/driving_hud/seen_marks.gd"
MARKER = "features/ui/driving_hud/objective_marker.gd"
CARGO = "features/missions/the_wrong_cargo/the_wrong_cargo.gd"
ROUTE = "features/missions/night_freight/first_drive.gd"
OPENING = "features/missions/the_wrong_cargo/opening_cutscene.gd"
RUN = "features/missions/last_run/last_run.gd"
LOOP = "features/environments/industrial_loop/industrial_loop.gd"
FLATS = "features/environments/harbour_flats/harbour_flats.gd"
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("f1", "no cut through the rim", LOOP, "terrain.build(road, TERRAIN_AREA, _flat_plots(), _ground, 42021, [EAST_CUT])", "terrain.build(road, TERRAIN_AREA, _flat_plots(), _ground, 42021)"),
    ("f2", "the cut's banks walls", LOOP, "const EAST_CUT: Array = [Vector2(612.0, 151.7), Vector2(672.0, 151.7), 5.0, 0.9]", "const EAST_CUT: Array = [Vector2(612.0, 151.7), Vector2(672.0, 151.7), 5.0, 30.0]"),
    ("f3", "no embankment", FLATS, "\t_embankment(terrain, ground)\n", ""),
    ("f4", "the east wall left shut", LOOP, "\t\t[Vector3(area.end.x, 60, (EAST_GAP.y + area.end.y) / 2.0), Vector3(2, 200,\n\t\t\tarea.end.y - EAST_GAP.y)],\n", "\t\t[Vector3(area.end.x, 60, (EAST_GAP.y + area.end.y) / 2.0), Vector3(2, 200,\n\t\t\tarea.end.y - EAST_GAP.y)],\n\t\t[Vector3(area.end.x, 60, 152.0), Vector3(2, 200, 28.0)],\n"),
    ("f5", "the cut cleared as an ordinary clearing", LOOP, "\tforest = RoadsideForest.new()\n", "\tclearings.append(EAST_CUT_PLOT)\n\tforest = RoadsideForest.new()\n"),
    ("f6", "the flats not playable", LOOP, "\treturn playable_area.has_point(at) or (harbour_flats != null", "\treturn playable_area.has_point(at) or (false"),
    ("f7", "the sea at the quay's edge", FLATS, "const SEA_LEVEL := -2.6", "const SEA_LEVEL := -0.3"),
    ("f8", "lamps 80 m apart", FLATS, "const LAMP_EVERY := 40.0", "const LAMP_EVERY := 80.0"),
]
scratch, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])


def one(entry):
    name, what, path, old, new = entry
    root = scratch / name
    shutil.rmtree(root, ignore_errors=True)
    root.mkdir(parents=True)
    subprocess.run(["cp", "-cR", str(REPO / "game"), str(root / "game")], check=True)
    target = root / "game" / path
    text = target.read_text()
    assert text.count(old) == 1, name
    target.write_text(text.replace(old, new))
    subprocess.run(["diff", "-ru", str(REPO / "game"), str(root / "game"), "-x", ".godot"],
                   stdout=open(out / f"{name}.diff", "w"))
    home = scratch / f"{name}-home"
    home.mkdir(exist_ok=True)
    env = {"HOME": str(home), "PATH": "/usr/bin:/bin"}
    lines = []
    for test in TESTS_BY.get(name, TESTS):
        run = subprocess.run(["/Applications/Godot.app/Contents/MacOS/Godot", "--headless",
                              "--path", str(root / "game"), "--script", f"res://tests/{test}",
                              "--fixed-fps", "60"], env=env, capture_output=True, text=True,
                             timeout=1200)
        (out / f"{name}_{test[:-3]}.log").write_text(run.stdout + run.stderr)
        fails = [l[6:] for l in run.stdout.splitlines() if l.startswith("FAIL: ")]
        result = next((l for l in run.stdout.splitlines() if "RESULT" in l), "no result")
        bad = "SCRIPT ERROR" in run.stdout + run.stderr
        lines.append(f"{test} exit {run.returncode}, {result.split(': ')[-1]}"
                     + (" (SCRIPT ERROR)" if bad else "")
                     + "".join(f"\n      FAIL: {f[:110]}" for f in fails))
    shutil.rmtree(root, ignore_errors=True)
    return f"{name}  {what:<30} " + "\n    ".join(lines)


from concurrent.futures import ThreadPoolExecutor
chosen = [m for m in MUTATIONS if not ONLY or m[0] in ONLY]
with ThreadPoolExecutor(3) as pool:
    summary = list(pool.map(one, chosen))
with (out / "SUMMARY.txt").open("a") as handle:
    handle.write("\n".join(summary) + "\n")
print("\n".join(summary))
