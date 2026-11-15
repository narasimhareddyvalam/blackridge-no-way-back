"""Part D's mutations (step 5 of #253, the shed's floor): each on an APFS clone of game/, then
test_shed_floor.gd at 60 fps on the clone. Usage: python3 -I mutations_partD.py <scratch> <out>"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
FLOOR = "features/environments/industrial_loop/shed_floor.gd"
BUILDING = "features/environments/industrial_loop/transfer_building.gd"
TESTS = ["test_shed_floor.gd"]
TESTS_BY = {"d13": ["test_mission_two.gd"]}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("d1", "joints twice ACI's spacing", FLOOR,
     "const JOINT_X: Array[float] = [-78.0, -74.0, -70.0, -66.0, -62.0, -58.0, -54.0, -50.0]\n",
     "const JOINT_X: Array[float] = [-74.0, -66.0, -58.0, -50.0]\n"),
    ("d2", "a joint through the lift's pit", FLOOR,
     "const JOINT_X: Array[float] = [-78.0, -74.0, -70.0, -66.0, -62.0, -58.0, -54.0, -50.0]\n",
     "const JOINT_X: Array[float] = [-78.0, -74.0, -70.0, -66.0, -62.0, -58.0, -54.0, -50.0, -47.75]\n"),
    ("d3", "patches off the joints", FLOOR,
     "		var length := _draw.randf_range(0.2, 0.5)\n",
     "		at += along.orthogonal() * 0.3\n		var length := _draw.randf_range(0.2, 0.5)\n"),
    ("d4", "tyre marks over the walkway", FLOOR, "const WALKWAY_WEST := -46.6\n",
     "const WALKWAY_WEST := -43.5\n"),
    ("d5", "oil beyond the forklift", FLOOR,
     "		drips.append(Vector3(_draw.randf_range(-0.3, 0.3), _draw.randf_range(0.04, 0.1),\n",
     "		drips.append(Vector3(_draw.randf_range(-0.9, 0.9), _draw.randf_range(0.04, 0.1),\n"),
    ("d6", "scuffs far from the levellers", FLOOR,
     "		zones.append(Rect2(x - LEVELLER.x / 2.0 - 0.1, FACE - LEVELLER.y - 1.0,\n			LEVELLER.x + 0.2, 1.0))\n",
     "		zones.append(Rect2(x - LEVELLER.x / 2.0 - 0.1, FACE - LEVELLER.y - 4.0,\n			LEVELLER.x + 0.2, 4.0))\n"),
    ("d7", "tracks that never dry", FLOOR,
     "	return 0.75 * pow(clampf(1.0 - distance / WET_REACH, 0.0, 1.0), 1.3)\n",
     "	return 0.75\n"),
    ("d8", "marks under the loads", FLOOR,
     "		if Rect2(load - LOAD_SIZE / 2.0, LOAD_SIZE).has_point(at):\n			return false\n",
     "		if Rect2(load - LOAD_SIZE / 2.0, LOAD_SIZE).has_point(at):\n			pass\n"),
    ("d9", "an unseeded draw", FLOOR, "	_draw.seed = SEED\n", "	_draw.randomize()\n"),
    ("d10", "maps without mipmaps", FLOOR, "		image.generate_mipmaps()\n", ""),
    ("d11", "the lane in plain concrete", BUILDING,
     "	_piece(at, size, _floor).name = \"LaneFloor\"\n",
     "	_piece(at, size, _concrete).name = \"LaneFloor\"\n"),
    ("d12", "the material missing a joint", FLOOR,
     "	material.set_shader_parameter(\"joint_x\", PackedFloat32Array(JOINT_X))\n",
     "	material.set_shader_parameter(\"joint_x\", PackedFloat32Array(JOINT_X.slice(1)))\n"),
    ("d13", "the lane untextured (E11 taught the floor)", BUILDING,
     "	_piece(at, size, _floor).name = \"LaneFloor\"\n",
     "	_piece(at, size, Build.material(Color(0.5, 0.5, 0.5), 0.8)).name = \"LaneFloor\"\n"),
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
