"""The audit's second fix (the forklift): each on an APFS clone of game/, then
test_forklift.gd at 60 fps on the clone, three at a time.
Usage: python3 -I mutations_fix02.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TRUCK = "features/vehicles/forklift/forklift_truck.gd"
LOOK = "features/vehicles/forklift/look_travel.gd"
TESTS = ["test_forklift.gd"]
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("m1", "the steering wheel fixed", TRUCK, "\t\twheel.basis = Basis(COLUMN, -steering_turns() * TAU)\n", "\t\twheel.basis = Basis.IDENTITY\n"),
    ("m2", "the steer wheels straight", TRUCK, "\tif absf(steer) < 0.0001:\n\t\treturn {\"SteerWheelL\": 0.0, \"SteerWheelR\": 0.0}\n", "\tif true:\n\t\treturn {\"SteerWheelL\": 0.0, \"SteerWheelR\": 0.0}\n"),
    ("m3", "both steer wheels alike", TRUCK, "\tvar far := -atan(WHEELBASE / (out + TRACK / 2.0)) * signf(steer)\n", "\tvar far := near\n"),
    ("m4", "the wheels not rolling", TRUCK, "\t\t\t_rolled[label] = float(_rolled[label]) + moved.dot(ahead) / radius\n", "\t\t\t_rolled[label] = float(_rolled[label])\n"),
    ("m5", "the steer shown short", TRUCK, "\t_steer = lerpf(float(a[4]), float(b[4]), t)\n", "\t_steer = lerpf(float(a[4]), float(b[4]), t) * 0.8\n"),
    ("m6", "the wheel spun twice as fast", TRUCK, "const HANDS_RATE := 1.5\n", "const HANDS_RATE := 3.0\n"),
    ("m7", "no tilt back", TRUCK, "const TILT_BACK := deg_to_rad(4.0)\n", "const TILT_BACK := deg_to_rad(0.0)\n"),
    ("m8", "the old slow lift", TRUCK, "const LIFT_RATE := 0.35\n", "const LIFT_RATE := 0.15\n"),
    ("m9", "lowering as slow as lifting", TRUCK, "const LOWER_RATE := 0.5\n", "const LOWER_RATE := 0.35\n"),
    ("m10", "the spot dark in turns", TRUCK, "\t_pose_at(step[\"samples\"], float(step[\"spacing\"]), _turn_s)\n\t_look_ahead(reverse)\n\t_spots_for(-1.0 if reverse else 1.0)\n", "\t_pose_at(step[\"samples\"], float(step[\"spacing\"]), _turn_s)\n\t_look_ahead(reverse)\n\t_spots_for(0.0)\n"),
    ("m11", "turns too tight", TRUCK, "const TURN_RADIUS := 0.9\n", "const TURN_RADIUS := 0.3\n"),
    ("m12", "the bay by the dock edge", TRUCK, "const BAY_TURN := Vector2(-48.0, 12.5)\n", "const BAY_TURN := Vector2(-46.5, 12.5)\n"),
    ("m13", "the left hand off the knob", TRUCK, "\t_grips[0] = _model.to_local(knob_point())\n", "\t_grips[0] = GRIPS[0]\n"),
    ("m14", "the right hand never on the post", TRUCK, "\tvar wanted := GUARD_POST if reversing() else LEVER\n", "\tvar wanted := LEVER\n"),
    ("m15", "the chest not turned", LOOK, "const SHARES := {\"Bip01 Spine2\": 0.4, ", "const SHARES := {\"Bip01 Spine2\": 0.0, "),
    ("m16", "the mast not driven", TRUCK, "\tfor label: String in [\"SteeringWheel\", \"Mast\", \"DriveWheelL\", \"DriveWheelR\", \"SteerWheelL\",\n", "\tfor label: String in [\"SteeringWheel\", \"DriveWheelL\", \"DriveWheelR\", \"SteerWheelL\",\n"),
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
