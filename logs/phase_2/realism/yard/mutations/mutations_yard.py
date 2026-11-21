"""Mission 2's container yard (#351): each on an APFS clone of game/, then test_tail_lamps.gd at 60 fps
on the clone, three at a time.
Usage: python3 -I mutations_yard.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
VAN = "features/vehicles/freight_van/van_presentation.gd"
TESTS = ["test_yard_realism.gd"]
YARD = "features/environments/industrial_loop/container_yard.gd"
MARKS = "features/environments/industrial_loop/art/container_yard/container_marks.json"
GATE = "features/environments/industrial_loop/sliding_gate.gd"
MISSION = "features/missions/the_wrong_cargo/the_wrong_cargo.gd"
BOOTH = "features/environments/industrial_loop/guard_booth.gd"
SHED = "features/environments/industrial_loop/transfer_shed.gd"
APP = "app/first_drive.gd"
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("y1", "one serial for every box", YARD, "\t\t\t\t\tvar strip: Dictionary = strips[markings.size()]\n", "\t\t\t\t\tvar strip: Dictionary = strips[0]\n"),
    ("y2", "a wrong check digit", MARKS, '"code": "HLVU4377471"', '"code": "HLVU4377472"'),
    ("y3", "40 ft boxes called 20 ft", YARD, 'const SIZE_TYPES := {"Container20": "22G1", "Container40": "42G1",', 'const SIZE_TYPES := {"Container20": "22G1", "Container40": "22G1",'),
    ("y4", "the old flat paint", YARD, "\t\tmulti.mesh = _painted(meshes[kind] as Mesh, kind)\n", "\t\tmulti.mesh = meshes[kind] as Mesh\n"),
    ("y5", "every box worn alike", YARD, "\t\t\t\t\tvar custom := Color(float(markings.size()), float(strip[\"line\"]), wear.randf(),\n", "\t\t\t\t\tvar custom := Color(float(markings.size()), float(strip[\"line\"]), 0.5,\n"),
    ("y6", "no room made: the two stacks kept", YARD, "const TOP_LOADER_CLEARS: Array[float] = [125.2, 131.6]\n", "const TOP_LOADER_CLEARS: Array[float] = []\n"),
    ("y7", "two floods a mast", YARD, "\t[Vector3(95.0, 0.0, 151.0), Vector3(99.0, 0.0, 147.0), Vector3(103.0, 0.0, 150.0),\n\t\tVector3(97.0, 0.0, 141.0)],\n", "\t[Vector3(95.0, 0.0, 151.0), Vector3(99.0, 0.0, 147.0)],\n"),
    ("y8", "floods aimed off the lane", YARD, "const FLOOD_ANGLE := 46.0\n", "const FLOOD_ANGLE := 4.0\n"),
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
