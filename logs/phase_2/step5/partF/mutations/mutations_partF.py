"""Part F's mutations (step 5 of #253, the shed's safety and work kit): each on an APFS clone of
game/, then test_shed_kit.gd at 60 fps on the clone. Usage:
python3 -I mutations_partF.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
KIT = "features/environments/industrial_loop/shed_kit.gd"
BUILDING = "features/environments/industrial_loop/transfer_building.gd"
TESTS = ["test_shed_kit.gd"]
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("f1", "the strip left unfloored", BUILDING,
     "	_slab(BUILDING.position.x + WALL, office_end, back, OFFICE.position.y, 0.0).name = \\\n		\"DockFloor4\"\n", ""),
    ("f2", "one exit only", KIT,
     "		{\"door\": WEST_EXIT, \"sign\": WEST_EXIT + Vector3(0.06, DOOR_TALL + SIGN_ABOVE, 0.0)}]\n",
     "		]\n"),
    ("f3", "the EXIT signs unlit", KIT, "		paint.emission_enabled = true\n", "		paint.emission_enabled = false\n"),
    ("f4", "4 in EXIT letters", KIT, "const EXIT_LETTERS := 6 * 0.0254\n", "const EXIT_LETTERS := 4 * 0.0254\n"),
    ("f5", "no emergency light by the west exit", KIT,
     "		Transform3D(Basis(Vector3.UP, -PI / 2.0), Vector3(WEST_WALL, FLOOR + 2.7, 4.9)),\n", ""),
    ("f6", "no extinguisher down the lane", KIT, "	for z: float in [18.6, 0.0]:\n", "	for z: float in [18.6]:\n"),
    ("f7", "extinguishers hung too high", KIT, "const EXTINGUISHER_UP := 1.2\n", "const EXTINGUISHER_UP := 1.5\n"),
    ("f8", "the extinguishers' signs away from them", KIT,
     "		var at := placed.origin + Vector3.UP * (EXTINGUISHER_TALL / 2.0 + 0.3) - front * 0.07\n",
     "		var at := placed.origin + Vector3.UP * (EXTINGUISHER_TALL / 2.0 + 0.3) - front * 0.07 + Vector3(0.0, 0.0, 1.0)\n"),
    ("f9", "the eyewash out of reach", KIT, "const EYEWASH := Vector3(WEST_WALL, FLOOR + 1.0, 7.8)\n",
     "const EYEWASH := Vector3(WEST_WALL, FLOOR + 1.0, -8.0)\n"),
    ("f10", "the spill kit far from the charger", KIT, "const SPILL_KIT := Vector2(-88.9, 9.4)\n",
     "const SPILL_KIT := Vector2(-88.9, -4.0)\n"),
    ("f11", "NO SMOKING far from the charger", KIT,
     "		Transform3D(Basis(Vector3.UP, PI), Vector3(-84.9, FLOOR + 1.9, OFFICE_BACK - 0.005)))\n",
     "		Transform3D(Basis(Vector3.UP, PI), Vector3(-60.0, FLOOR + 1.9, OFFICE_BACK - 0.005)))\n"),
    ("f12", "no mirror at the last aisle", KIT, "	for index in range(rows.size()):\n		var last := index == rows.size() - 1\n",
     "	for index in range(rows.size() - 1):\n		var last := index == rows.size() - 1\n"),
    ("f13", "mirrors too high", KIT, "const MIRROR_UP := 2.9\n", "const MIRROR_UP := 3.5\n"),
    ("f14", "first aid far from the side door", KIT,
     "const FIRST_AID := Vector3(EAST_WALL, LANE_FLOOR + 1.4, 13.3)\n",
     "const FIRST_AID := Vector3(EAST_WALL, LANE_FLOOR + 1.4, 9.0)\n"),
    ("f15", "the crossing off the walkway", KIT, "const CROSSING_X := -46.0\n", "const CROSSING_X := -48.0\n"),
    ("f16", "the wrap stand on the cross-aisle", KIT, "const WRAP_STAND := Vector2(-66.3, 15.8)\n",
     "const WRAP_STAND := Vector2(-66.3, 12.0)\n"),
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
