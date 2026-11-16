"""Part E's mutations (step 5 of #253, the shed's fit-out): each on an APFS clone of game/, then
test_shed_fitout.gd at 60 fps on the clone. Usage: python3 -I mutations_partE.py <scratch> <out>"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
FIT = "features/environments/industrial_loop/shed_fitout.gd"
BUILDING = "features/environments/industrial_loop/transfer_building.gd"
TESTS = ["test_shed_fitout.gd"]
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("e1", "heaters hung too high", FIT, "const HEATER_BOTTOM := 3.97\n", "const HEATER_BOTTOM := 4.8\n"),
    ("e2", "level louvers", FIT, "const LOUVER_DOWN := deg_to_rad(30.0)\n", "const LOUVER_DOWN := deg_to_rad(5.0)\n"),
    ("e3", "flues short of the roof", FIT,
     "		flues.append(_upright(Vector3(flue.x, top, flue.z), Racking.underside(flue.z) - top))\n",
     "		flues.append(_upright(Vector3(flue.x, top, flue.z), chord(flue.z) - top))\n"),
    ("e4", "heaters against the raised doors", FIT, "const HEATER_Z := 17.0\n", "const HEATER_Z := 19.0\n"),
    ("e5", "a fan under a light", FIT,
     "const FAN_CENTRES: Array[Vector2] = [Vector2(-74.0, 15.55), Vector2(-58.0, 15.55)]\n",
     "const FAN_CENTRES: Array[Vector2] = [Vector2(-70.0, 15.55), Vector2(-58.0, 15.55)]\n"),
    ("e6", "fans up among the sprinklers", FIT, "const FAN_BLADES_UP := 6.0\n", "const FAN_BLADES_UP := 7.2\n"),
    ("e7", "fans off centre of the heads", FIT, "const HEAD_PHASE := -72.6667\n", "const HEAD_PHASE := -72.0\n"),
    ("e8", "fans too fast", FIT, "const FAN_RPM := 15.0\n", "const FAN_RPM := 60.0\n"),
    ("e9", "a fan hung from one joist", FIT, "const FAN_MOUNT_SPAN := 3.0\n", "const FAN_MOUNT_SPAN := 1.0\n"),
    ("e10", "sprinkler lines too far apart", FIT,
     "const SPRINKLER_ZS: Array[float] = [9.7, 13.6, 17.5]\n", "const SPRINKLER_ZS: Array[float] = [9.7, 16.5]\n"),
    ("e11", "tray rods too far apart", FIT, "const TRAY_SECTION := 3.0\n", "const TRAY_SECTION := 4.5\n"),
    ("e12", "the numbers over the doors", FIT, "const PIER := 2.0\n", "const PIER := 0.0\n"),
    ("e13", "stations too high", FIT, "const STATION_UP := 1.45\n", "const STATION_UP := 2.0\n"),
    ("e14", "the shut docks' lights green", BUILDING,
     "		shut.rotation.y = PI\n		_show(shut, false)\n", "		shut.rotation.y = PI\n		_show(shut, true)\n"),
    ("e15", "the clock far from the side door", FIT,
     "const CLOCK := Vector3(EAST_WALL, LANE_FLOOR + 1.35, 16.2)\n",
     "const CLOCK := Vector3(EAST_WALL, LANE_FLOOR + 1.35, 13.0)\n"),
    ("e16", "the fans still", FIT, "		blades.rotation.y = wrapf(blades.rotation.y + FAN_RPM / 60.0 * TAU * delta, -PI, PI)\n",
     "		blades.rotation.y = wrapf(blades.rotation.y, -PI, PI)\n"),
]
scratch, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
summary = []
for name, what, path, old, new in MUTATIONS:
    if ONLY and name not in ONLY:
        continue
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
                             timeout=600)
        (out / f"{name}_{test[:-3]}.log").write_text(run.stdout + run.stderr)
        fails = [l[6:] for l in run.stdout.splitlines() if l.startswith("FAIL: ")]
        result = next((l for l in run.stdout.splitlines() if "RESULT" in l), "no result")
        lines.append(f"{test} exit {run.returncode}, {result.split(': ')[-1]}"
                     + "".join(f"\n      FAIL: {f[:110]}" for f in fails))
    summary.append(f"{name}  {what:<36} " + "\n    ".join(lines))
    shutil.rmtree(root, ignore_errors=True)
with (out / "SUMMARY.txt").open("a") as handle:
    handle.write("\n".join(summary) + "\n")
print("\n".join(summary))
