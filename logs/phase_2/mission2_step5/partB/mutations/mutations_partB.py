"""Step 5 of Mission 2, part B (the warehouses rebuilt): each on an APFS clone of game/, then
test_warehouses.gd at 60 fps on the clone, three at a time.
Usage: python3 -I mutations_partB.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
HOUSE = "features/environments/industrial_loop/warehouse.gd"
COMPOUND = "features/environments/industrial_loop/compound.gd"
WORLD = "features/environments/industrial_loop/industrial_loop.gd"
TESTS = ["test_warehouses.gd"]
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("b1", "the Phase 1 boxes kept", WORLD, "\t\tif COMPOUND_WAREHOUSES.has(item):\n\t\t\tcontinue\n", "\t\tpass\n"),
    ("b2", "a warehouse moved", COMPOUND, "\t\thouse.build(footprints_xz[index], heights[index],", "\t\thouse.build(footprints_xz[index].grow(0.5), heights[index],"),
    ("b3", "a metre lower", COMPOUND, "footprints_xz[index], heights[index], docks,", "footprints_xz[index], heights[index] - 1.0, docks,"),
    ("b4", "joints across doors", HOUSE, "const JOINT_CLEAR := 0.3\n", "const JOINT_CLEAR := -2.0\n"),
    ("b5", "12 m panels", HOUSE, "const PANEL := 9.0\n", "const PANEL := 12.0\n"),
    ("b6", "a low parapet", HOUSE, "const PARAPET := 1.0\n", "const PARAPET := 0.3\n"),
    ("b7", "no coping", HOUSE, ".name = \"Coping\"", ".name = \"Cap\""),
    ("b8", "docks at 1.3 m", HOUSE, "const DOCK_FLOOR := 1.22\n", "const DOCK_FLOOR := 1.3\n"),
    ("b9", "bumpers low", HOUSE, "\t\t\tvar at := Vector3(x + side * BUMPER_OFF, DOCK_FLOOR - BUMPER.y / 2.0,\n", "\t\t\tvar at := Vector3(x + side * BUMPER_OFF, DOCK_FLOOR - BUMPER.y / 2.0 - 0.1,\n"),
    ("b10", "no signals", HOUSE, "\t\tlamp.name = \"DockSignal%d\" % (index + 1)\n", "\t\tlamp.name = \"Lamp%d\" % (index + 1)\n"),
    ("b11", "six steep risers", HOUSE, "const RISERS := 7\n", "const RISERS := 6\n"),
    ("b12", "short treads", HOUSE, "const TREAD := 0.28\n", "const TREAD := 0.25\n"),
    ("b13", "low handrails", HOUSE, "const HANDRAIL := 0.9\n", "const HANDRAIL := 0.8\n"),
    ("b14", "a low guard", HOUSE, "const GUARD := 1.1\n", "const GUARD := 0.9\n"),
    ("b15", "downpipes short of the ground", HOUSE, "\t\tvar low := 0.15\n", "\t\tvar low := 1.0\n"),
    ("b16", "wall packs casting shadows", HOUSE, "\t\tlight.spot_range = 18.0\n\t\tlight.shadow_enabled = false\n", "\t\tlight.spot_range = 18.0\n\t\tlight.shadow_enabled = true\n"),
    ("b17", "walls not solid", HOUSE, "\tBuild.box(self, centre, size, surface).name = \"Wall\"\n\t_solid(centre, size)\n", "\tBuild.box(self, centre, size, surface).name = \"Wall\"\n"),
    ("b18", "no dock lights", HOUSE, "\t\t_dock_light(index, x, housing)\n", "\t\tpass\n"),
    ("b19", "doors not solid", HOUSE, "\t\tholder.add_child(body)\n", "\t\tpass\n"),
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
