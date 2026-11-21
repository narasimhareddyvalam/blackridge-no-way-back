"""Mission 2's opening, dispatch and Maya's call, step 8 (#358): each on an APFS clone of game/, then test_cargo_opening.gd at 60 fps
on the clone, three at a time.
Usage: python3 -I mutations_guidance.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TESTS = ["test_cargo_opening.gd"]
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
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("c1", "Mission 1's end asks for no opening", ROUTE, "\tconfig.set_value(\"cargo\", \"opening\", true)\n", ""),
    ("c2", "the opening on every Mission 2 start", CARGO, "\topening_pending = stage == 0 and bool(config.get_value(\"cargo\", \"opening\", false))", "\topening_pending = stage == 0"),
    ("c3", "the game's title in it", OPENING, "const TITLE := [\"THE WRONG CARGO\", \"MISSION TWO\"]", "const TITLE := [\"BLACKRIDGE: NO WAY BACK\", \"THE WRONG CARGO\"]"),
    ("c4", "no dispatch", APP, "\t\thud.show_text_message(WrongCargo.DISPATCHER, WrongCargo.DISPATCH)\n", ""),
    ("c5", "the save still asks for it", CARGO, "\topening_pending = false\n\tcall_pending = true\n\tcheckpoint_reached.emit(start_progress())\n", "\topening_pending = false\n\tcall_pending = true\n"),
    ("c6", "Maya never calls", APP, "\t\troute.phone_call.start(\"MAYA\", WrongCargo.MAYA_CHECK_IN)\n", "\t\tpass\n"),
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
