"""Mission 2's escape, step 6 (#358): each on an APFS clone of game/, then test_escape.gd at 60 fps
on the clone, three at a time.
Usage: python3 -I mutations_guidance.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TESTS = ["test_escape.gd"]
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
TESTS_BY = {"e13": ["test_escape_route.gd"]}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("e1", "guards see 25 m", GUARD, "const SIGHT := 15.0", "const SIGHT := 25.0"),
    ("e2", "caught at a glance", ESC, "const CATCH_AFTER := 1.0", "const CATCH_AFTER := 0.2"),
    ("e3", "guards see through walls", GUARD, "\treturn get_world_3d().direct_space_state.intersect_ray(query).is_empty()", "\treturn true"),
    ("e4", "never caught close", ESC, "const NEAR := 1.5", "const NEAR := 0.3"),
    ("e5", "safe in the van", ESC, "\t\tif _in_van_for >= IN_VAN_CATCH:\n\t\t\t_catch()\n", ""),
    ("e6", "the warning not unsent on a catch", ESC, "\twarned = false\n\toutside = false\n", "\toutside = false\n"),
    ("e7", "the warning sent again and again", ESC, "\tif not warned and _out_for >= WARN_AFTER:", "\tif _out_for >= WARN_AFTER:"),
    ("e8", "the fence not cut", COMPOUND, "\t\tif index == OUTLINE.size() - 1:\n", "\t\tif false:\n"),
    ("e9", "still in the compound past the cut", ESC, "\t\toutside = true\n", "\t\tpass\n"),
    ("e10", "the yard's gate shuts at once on foot", YARD, "\t_hold_for = HOLD_OPEN if on_foot else 0.0\n", "\t_hold_for = 0.0\n"),
    ("e11", "no dark van left at door 3", YARD, "\tvan.call(\"recover\", _left.global_transform)\n\t_dark_left = _parked_iveco(\"DarkVanLeft\", dark_at, DARK)\n", "\tvan.call(\"recover\", _left.global_transform)\n"),
    ("e12", "vans do not block sight", GUARD, "const SOLID := 1 | 2", "const SOLID := 1"),
    ("e13", "the guard by the cut never leaves it", ESC, "\t{\"at\": Vector3(233.4, FLOOR, 134.6), \"yaw\": -PI / 2.0, \"wait\": 3.0,", "\t{\"at\": Vector3(233.4, FLOOR, 134.6), \"yaw\": -PI / 2.0, \"wait\": 999.0,"),
    ("e14", "no mark over a guard who sees him", MARKS, "\t_marks = marks.filter(", "\t_marks = [].filter("),
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
