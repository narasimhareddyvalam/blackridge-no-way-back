"""Step 5 of Mission 2, part C (the loading bay, the yard dressed, stage 3): each on an APFS clone of game/, then
test_loading_bay.gd at 60 fps on the clone, three at a time.
Usage: python3 -I mutations_partC.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
HOUSE = "features/environments/industrial_loop/warehouse.gd"
COMPOUND = "features/environments/industrial_loop/compound.gd"
JUDGE = "features/environments/industrial_loop/dock_judge.gd"
CARGO = "features/missions/the_wrong_cargo/the_wrong_cargo.gd"
TESTS = ["test_loading_bay.gd"]
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("c1", "door 3 shut", COMPOUND, "\t\tvar open := OPEN_DOCK if index == 1 else -1\n", "\t\tvar open := -1\n"),
    ("c2", "its door not raised", HOUSE, "\t\tif index == _open:\n\t\t\t_raise(holder)\n", "\t\tpass\n"),
    ("c3", "the floor half the warehouse", HOUSE, "\tvar inner := Vector3(rect.size.x - WALL * 2.0, DOCK_FLOOR, rect.size.y - WALL * 2.0)\n", "\tvar inner := Vector3(rect.size.x - WALL * 2.0, DOCK_FLOOR, rect.size.y * 0.5)\n"),
    ("c4", "no leveller", HOUSE, "\tdeck.name = \"DockLeveller%d\" % (_open + 1)\n", "\tdeck.name = \"Deck%d\" % (_open + 1)\n"),
    ("c5", "one pallet", HOUSE, "\tfor index in range(2):\n\t\tvar holder := Node3D.new()\n\t\tholder.name = \"BayPallet", "\tfor index in range(1):\n\t\tvar holder := Node3D.new()\n\t\tholder.name = \"BayPallet"),
    ("c6", "the bay unlit", HOUSE, "\tlight.name = \"BayLight1\"\n", "\tlight.name = \"Lamp1\"\n"),
    ("c7", "no numbers on the court", HOUSE, "\t\tnumber.name = \"CourtNumber%d\" % (index + 1)\n", "\t\tnumber.name = \"Mark%d\" % (index + 1)\n"),
    ("c8", "short guide lines", HOUSE, "const GUIDE := Vector3(0.1, 0.004, 8.0)\n", "const GUIDE := Vector3(0.1, 0.004, 4.0)\n"),
    ("c9", "every flood casting shadows", COMPOUND, "\t\tlight.shadow_enabled = index == 1\n", "\t\tlight.shadow_enabled = true\n"),
    ("c10", "trailers skewed", COMPOUND, "\t\tvar at := Transform3D(Basis.IDENTITY, Vector3(x, GROUND + PAVING_TOP, bumper_face\n", "\t\tvar at := Transform3D(Basis(Vector3.UP, 0.05), Vector3(x, GROUND + PAVING_TOP, bumper_face\n"),
    ("c11", "trailers off the bumpers", COMPOUND, "const DOCK_GAP := 0.02\n", "const DOCK_GAP := 0.5\n"),
    ("c12", "the forklift not solid", COMPOUND, "\t_solid_box(FORKLIFT_AT.origin", "\tif false: _solid_box(FORKLIFT_AT.origin"),
    ("c13", "a pole in the way", COMPOUND, "Vector3(222.0, 0.0, 145.4)", "Vector3(222.0, 0.0, 140.0)"),
    ("c14", "docked a metre out", JUDGE, "const DOCKED_WITHIN := ParkingGuides.STOP_LINE\n", "const DOCKED_WITHIN := 1.0\n"),
    ("c15", "the signal stays green", COMPOUND, "\t\teast.call(\"set_docked\", judge.get(\"verdict\") == \"docked\"))\n", "\t\teast.call(\"set_docked\", false))\n"),
    ("c16", "stage 3 not saved", CARGO, "\tcheckpoint_reached.emit(config)\n\t_update_objective()\n\n\n## What a reload", "\t_update_objective()\n\n\n## What a reload"),
    ("c17", "the reload not docked", CARGO, "[START, LOADED_AT, DARK_VAN, AT_DOOR_THREE][stage]", "[START, LOADED_AT, DARK_VAN, DARK_VAN][stage]"),
    ("c18", "its doors shut on a reload", CARGO, "\t\tvehicle.set(\"rear_doors_open\", true)\n", "\t\tvehicle.set(\"rear_doors_open\", false)\n"),
    ("c19", "a miss not named", CARGO, "\t\tif MISSES.has(verdict):\n\t\t\tvar words := String(MISSES[verdict])", "\t\tif false:\n\t\t\tvar words := String(MISSES[verdict])"),
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
