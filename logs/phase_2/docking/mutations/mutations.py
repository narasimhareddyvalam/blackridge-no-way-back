"""The docking fixes' mutations (#287, steps 1-3 of #289): each on an APFS clone of game/, then
its test(s) at 60 fps on the clone. Usage: python3 -I mutations.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
GUIDES = "features/vehicles/freight_van/parking_guides.gd"
PRES = "features/vehicles/freight_van/van_presentation.gd"
BAY = "features/environments/industrial_loop/van_bay.gd"
LIFT = "features/environments/industrial_loop/dock_lift.gd"
JACK = "features/environments/industrial_loop/pallet_jack.gd"
CAM = ["test_rear_camera.gd"]
DOCK = ["test_docking.gd"]
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("d1", "the guides float 0.5 m up", GUIDES, "	return point + Vector3.UP * ABOVE\n",
     "	return point + Vector3.UP * 0.5\n", CAM),
    ("d2", "the guides drawn through what stands behind", GUIDES,
     "	return hit.is_empty() or (hit[\"position\"] as Vector3).distance_to(point) < SEEN_BY\n",
     "	return true\n", CAM),
    ("d3", "the guides too wide (3.8 m apart)", GUIDES, "const HALF_WIDTH := 1.0\n",
     "const HALF_WIDTH := 1.9\n", CAM),
    ("d4", "the camera back in the air, tilted 16°", PRES,
     "const REVERSE_CAMERA := Vector3(0, 2.22, 2.84)\nconst REVERSE_TURN := Vector3(-PI / 4.0, PI, 0)\n",
     "const REVERSE_CAMERA := Vector3(0, 2.15, 3.0)\nconst REVERSE_TURN := Vector3(-0.28, PI, 0)\n", CAM),
    ("d5", "the bay measures at the van's middle only", BAY,
     "	for side: float in [-1.0, 1.0]:\n		gap = minf(gap, (rear + across * side * BUMPER_X).z - BUMPERS_Z)\n",
     "", DOCK),
    ("d6", "the bay docks within 0.3 m again", BAY,
     "const DOCKED_WITHIN := ParkingGuides.STOP_LINE\n", "const DOCKED_WITHIN := 0.3\n", DOCK),
    ("d7", "no red stop line", GUIDES, "	_stop_line(found, camera, space)\n", "", DOCK),
    ("d8", "the hold does not settle with the body", PRES,
     "	if hold != null:\n		hold.transform = transform\n", "", DOCK),
    ("d9", "the plate laid once, not kept on the sill", LIFT,
     "		_rest = _rest_on(global_position.y, _support())\n		_pivot.rotation.x = -_rest\n",
     "		pass\n", DOCK),
    ("d10", "the load rides the van's frame, not its body", JACK,
     "	return van.call(\"body\") as Node3D if van.has_method(\"body\") else van\n",
     "	return van\n", DOCK),
]
scratch, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
summary = []
for name, what, path, old, new, tests in MUTATIONS:
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
    subprocess.run(["/Applications/Godot.app/Contents/MacOS/Godot", "--headless", "--path",
                    str(root / "game"), "--import"], env=env, capture_output=True, timeout=300)
    lines = []
    codes = []
    for test in tests:
        run = subprocess.run(["/Applications/Godot.app/Contents/MacOS/Godot", "--headless",
                              "--path", str(root / "game"), "--script", f"res://tests/{test}",
                              "--fixed-fps", "60"], env=env, capture_output=True, text=True,
                             timeout=600)
        (out / f"{name}_{test[:-3]}.log").write_text(run.stdout + run.stderr)
        fails = [l[6:] for l in run.stdout.splitlines() if l.startswith("FAIL: ")]
        result = next((l for l in run.stdout.splitlines() if "RESULT" in l), "no result")
        codes.append(run.returncode)
        lines.append(f"{test} exit {run.returncode}, {result.split(': ')[-1]}"
                     + "".join(f"\n      FAIL: {f[:110]}" for f in fails))
    summary.append(f"{name}  {what:<48} " + "\n    ".join(lines))
with (out / "SUMMARY.txt").open("a") as handle:
    handle.write("\n".join(summary) + "\n")
print("\n".join(summary))
