"""Part G's mutations (step 5 of #253, the shed at work): each on an APFS clone of game/, then
test_shed_work.gd at 60 fps on the clone. Usage: python3 -I mutations_partG.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TRUCK = "features/vehicles/forklift/forklift_truck.gd"
LOOK = "features/vehicles/forklift/look_travel.gd"
WORKER = "features/characters/dock_worker/dock_worker.gd"
SHED = "features/environments/industrial_loop/transfer_shed.gd"
STAGING = "features/environments/industrial_loop/dock_staging.gd"
AUDIO = "features/audio/first_drive/driving_audio.gd"
SOUNDS = "features/environments/industrial_loop/shed_sounds.gd"
TESTS = ["test_shed_work.gd"]
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("g1", "the forklift not giving way", TRUCK, "	if walker == null or not is_instance_valid(walker):\n		return INF\n",
     "	if true:\n		return INF\n"),
    ("g2", "over 5 mph", TRUCK, "const TOP_SPEED := 2.2\n", "const TOP_SPEED := 3.0\n"),
    ("g3", "full speed in the aisle", TRUCK, "_turn(PI), _go(\"down_aisle\", AISLE_TURN, false, AISLE_SPEED), _turn(PI / 2.0),\n			_go(\"to_slot\"",
     "_turn(PI), _go(\"down_aisle\", AISLE_TURN, false, TOP_SPEED), _turn(PI / 2.0),\n			_go(\"to_slot\""),
    ("g4", "the load carried high", TRUCK, "const TRAVEL_LIFT := 0.12\n", "const TRAVEL_LIFT := 0.3\n"),
    ("g5", "the blue spot always ahead", TRUCK, "	_spots[0].visible = direction > 0.0 and absf(_speed) > 0.05\n	_spots[1].visible = direction < 0.0 and absf(_speed) > 0.05\n",
     "	_spots[0].visible = absf(_speed) > 0.05\n	_spots[1].visible = false\n"),
    ("g6", "the alarm going forward too", TRUCK, "	var backing := reversing()\n", "	var backing := _phase != \"parked\"\n"),
    ("g7", "no horn", TRUCK, "			_horn.play()\n			horned.emit(global_position)\n", "			_horn.play()\n"),
    ("g8", "the driver not looking back", LOOK, "const LOOK_BACK := deg_to_rad(75.0)\n", "const LOOK_BACK := deg_to_rad(10.0)\n"),
    ("g9", "his hands off the wheel", TRUCK, "const WRISTS: Array[Vector3] = [Vector3(0.139, 1.491, -0.413), Vector3(-0.139, 1.491, -0.413)]\n",
     "const WRISTS: Array[Vector3] = [Vector3(0.339, 1.291, -0.613), Vector3(-0.339, 1.291, -0.613)]\n"),
    ("g10", "working with no one near", TRUCK, "const ACTIVE_REACH := 60.0\n", "const ACTIVE_REACH := 100000.0\n"),
    ("g11", "its load named as the mission's", STAGING, "\"PutawayLoad\"", "\"Pallet20\""),
    ("g12", "the worker over the lowered lift", WORKER, "	if lift == null or not is_instance_valid(lift) or bool(lift.call(\"at_top\")):\n",
     "	if true:\n"),
    ("g13", "a pallet scanned again", SHED, "		_scanned.append(load)\n", ""),
    ("g14", "the yard's rain under the roof", AUDIO, "const SHELTER_DB := 14.0\n", "const SHELTER_DB := 0.0\n"),
    ("g15", "heaters always on", SOUNDS, "	return fmod(time + index * round_length / 3.0, round_length) < ON_SECONDS\n", "	return true\n"),
    ("g16", "the radio loud", SOUNDS, "const RADIO_DB := -16.0\n", "const RADIO_DB := -2.0\n"),
    ("g17", "the scan place on the deck", WORKER, "const SCAN_AT := Vector3(-46.6, 1.3, 17.05)\n", "const SCAN_AT := Vector3(-47.4, 1.3, 17.6)\n"),
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
