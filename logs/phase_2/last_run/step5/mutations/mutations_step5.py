"""Mission 3's step 5, the airfield and the convoy (#359): each on an APFS clone of game/, then test_convoy.gd at 60 fps
on the clone, three at a time.
Usage: python3 -I mutations_guidance.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TESTS = ["test_convoy.gd"]
MAP = "features/ui/driving_hud/mission_map.gd"
APP = "app/first_drive.gd"
HUD = "features/ui/driving_hud/driving_hud.gd"
SUVF = "features/vehicles/scripted_suv/scripted_suv.gd"
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
FRONT = "features/environments/harbour_flats/waterfront.gd"
AMBUSH = "features/missions/last_run/ambush.gd"
SCENES = "features/missions/last_run/story_scenes.gd"
CONVOY = "features/missions/last_run/convoy.gd"
FIELD = "features/environments/harbour_flats/airfield.gd"
HUD = "features/ui/driving_hud/driving_hud.gd"
SUVF = "features/vehicles/scripted_suv/scripted_suv.gd"
TESTS_BY = {"c5": ["test_airfield.gd"], "c6": ["test_airfield.gd"], "s1": ["test_maya_call.gd"]}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ('c1', 'the convoy unseen', CONVOY, '\t\tsuv.visible = true\n', ''),
    ('c2', 'never spotted however close', CONVOY, 'const TOO_CLOSE := 25.0', 'const TOO_CLOSE := 0.0'),
    ('c3', 'the gate left open behind them', CONVOY, '\t\tinside = true\n\t\tairfield.call("close_gate")\n', '\t\tinside = true\n'),
    ('c4', 'the service gate deaf to the code', RUN, '\t\tairfield.call("open_service")\n', ''),
    ('c5', 'runway lights 120 m apart', FIELD, 'const EDGE_EVERY := 60.0', 'const EDGE_EVERY := 120.0'),
    ('c6', 'a door too narrow for the plane', FIELD, 'const DOOR_OPENING := Vector2(22.0, 6.8)', 'const DOOR_OPENING := Vector2(12.0, 6.8)'),
    ('s1', 'subtitles left over the objective', HUD, '\t\tfoot = maxf(foot, OBJECTIVE_FOOT + _heading.size.y + SUBTITLE_GAP)', '\t\tpass'),
    ('c7', 'the gate leaf left across the way', FIELD, '\t\tsliding.call("set_open", float(entry[1]))', '\t\tsliding.call("set_open", 0.0)'),
    ('c8', 'the gate stuck shut', FIELD, '\t\tentry[1] = move_toward(was, float(entry[2]), GATE_SPEED * delta)', '\t\tentry[1] = was'),
    ('c9', "the SUVs' tail lamps never lit", SUVF, '\t_tail_glass.emission_enabled = on\n', '\t_tail_glass.emission_enabled = false\n'),
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
