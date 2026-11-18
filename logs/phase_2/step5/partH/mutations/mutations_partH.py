"""Part H's mutations (step 5 of #253, the yard at night): each on an APFS clone of game/, then
test_yard.gd at 60 fps on the clone, three at a time.
Usage: python3 -I mutations_partH.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
YARD = "features/environments/industrial_loop/yard_vehicles.gd"
TESTS = ["test_yard.gd"]
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("h1", "trailers short of the bumpers", YARD, "const DOCK_GAP := 0.02\n", "const DOCK_GAP := 0.5\n"),
    ("h2", "trailers skewed", YARD, "		var at := Transform3D(Basis.IDENTITY, Vector3(x, GROUND, BUMPER_FACE + DOCK_GAP\n",
     "		var at := Transform3D(Basis(Vector3.UP, 0.06), Vector3(x, GROUND, BUMPER_FACE + DOCK_GAP\n"),
    ("h3", "trailers floating", YARD, "		var at := Transform3D(Basis.IDENTITY, Vector3(x, GROUND, BUMPER_FACE + DOCK_GAP\n",
     "		var at := Transform3D(Basis.IDENTITY, Vector3(x, GROUND + 0.2, BUMPER_FACE + DOCK_GAP\n"),
    ("h4", "chocks away from the tandem", YARD, "const CHOCK_AHEAD := 1.25\n", "const CHOCK_AHEAD := 3.5\n"),
    ("h5", "the coupled trailer's gear down", YARD, "const GEAR_LIFT := 0.28\n", "const GEAR_LIFT := 0.0\n"),
    ("h6", "the tractor off the kingpin", YARD, "	var tractor := Transform3D(Basis.IDENTITY, Vector3(_kingpin.x, GROUND, _kingpin.z\n",
     "	var tractor := Transform3D(Basis.IDENTITY, Vector3(_kingpin.x, GROUND, _kingpin.z + 0.5\n"),
    ("h7", "the box truck nose in", YARD, "	var truck := Transform3D(Basis.IDENTITY, Vector3(BAYS[2], GROUND, BAY_BACK + BAY_LENGTH\n",
     "	var truck := Transform3D(Basis(Vector3.UP, PI), Vector3(BAYS[2], GROUND, BAY_BACK + BAY_LENGTH\n"),
    ("h8", "cars over the kerb", YARD, "const FROM_KERB := 0.3\n", "const FROM_KERB := -0.5\n"),
    ("h9", "the sedan nose out", YARD, "		var turn := Basis(Vector3.UP, 0.0 if long_along_x else -PI / 2.0)\n",
     "		var turn := Basis(Vector3.UP, 0.0 if long_along_x else PI / 2.0)\n"),
    ("h10", "dumpsters off the wall", YARD, "const DUMPSTER_FROM_WALL := 0.15\n", "const DUMPSTER_FROM_WALL := 1.0\n"),
    ("h11", "a trailer in the van's way", YARD, "const TRAILER_DOCKS: Array[float] = [-80.0, -76.0, -72.0]\n",
     "const TRAILER_DOCKS: Array[float] = [-80.0, -76.0, -47.75]\n"),
    ("h12", "nothing solid", YARD, "	var collision := CollisionShape3D.new()\n	collision.shape = shape\n	_body.add_child(collision)\n",
     "	var collision := CollisionShape3D.new()\n	collision.shape = shape\n	if false:\n		_body.add_child(collision)\n"),
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
    return f"{name}  {what:<36} " + "\n    ".join(lines)


from concurrent.futures import ThreadPoolExecutor
chosen = [m for m in MUTATIONS if not ONLY or m[0] in ONLY]
with ThreadPoolExecutor(3) as pool:
    summary = list(pool.map(one, chosen))
with (out / "SUMMARY.txt").open("a") as handle:
    handle.write("\n".join(summary) + "\n")
print("\n".join(summary))
