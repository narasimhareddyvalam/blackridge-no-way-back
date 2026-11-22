"""The audit's third fix (the pallet jack): each on an APFS clone of game/, then
test_pallet_jack.gd (or the test named for it) at 60 fps on the clone, three at a time.
Usage: python3 -I mutations_fix03.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
JACK = "features/environments/industrial_loop/pallet_jack.gd"
DRIVER = "features/characters/driver/driver.gd"
TESTS = ["test_pallet_jack.gd"]
TESTS_BY = {"m15": ["test_loading.gd"], "m16": ["test_loading.gd"]}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("m1", "the forks stay down", JACK, "\t_chassis.position.y = rise\n", "\t_chassis.position.y = -FRAME_DROP\n"),
    ("m2", "the load rises at once", JACK, "\treturn maxf(_forks * FORKS_RAISED - FORKS_MEET, 0.0)\n", "\treturn _forks * (FORKS_RAISED - FORKS_MEET)\n"),
    ("m3", "the frame as drawn", JACK, "const FRAME_DROP := 0.024\n", "const FRAME_DROP := 0.0\n"),
    ("m4", "the rollers ride the forks", JACK, "\t\troller.position.y = ROLLER_RADIUS - rise\n", "\t\troller.position.y = ROLLER_HUB\n"),
    ("m5", "the old 25 degree swing", JACK, "const STEER_SWING := deg_to_rad(105.0)\n", "const STEER_SWING := deg_to_rad(25.0)\n"),
    ("m6", "the handle swung too fast", JACK, "const STEER_RATE := deg_to_rad(120.0)\n", "const STEER_RATE := deg_to_rad(240.0)\n"),
    ("m7", "turning twice as tight", JACK, "\tvar turn := -carry * sin(_swing) / WHEELBASE\n", "\tvar turn := -carry * sin(_swing) / (WHEELBASE * 0.5)\n"),
    ("m8", "the unit rolling along the heading", JACK, "\tvar pivot := _pivot(pose) + _along(Transform3D(middle, pose.origin)) * carry\n", "\tvar pivot := _pivot(pose) + _ahead(pose) * carry\n"),
    ("m9", "the wheels not rolling", JACK, "\t\twheel.rotation.x = wrapf(wheel.rotation.x + moved.dot(axis) / radius, -PI, PI)\n", "\t\twheel.rotation.x = wheel.rotation.x\n"),
    ("m10", "the rollers at the steer wheels' radius", JACK, "\t\tvar radius := STEER_RADIUS if wheel == _steer_wheels else ROLLER_RADIUS\n", "\t\tvar radius := STEER_RADIUS\n"),
    ("m11", "standing swings all the way", JACK, "const STAND_SWING := deg_to_rad(10.0)\n", "const STAND_SWING := deg_to_rad(105.0)\n"),
    ("m12", "the swing not held to his walk", JACK, "\tvar rate := minf(STEER_RATE, SIDE_SHARE * _pace / arm)\n", "\tvar rate := STEER_RATE\n"),
    ("m13", "the handle not easing back", JACK, "\tvar target := -steer * STEER_SWING\n", "\tvar target := -steer * STEER_SWING if steer != 0.0 else _swing\n"),
    ("m14", "the bogies not turning", JACK, "\t\tbogie.rotation.x = drawn - riding\n", "\t\tbogie.rotation.x = 0.0\n"),
    ("m15", "his walk not stopped when he is", JACK, "const STOPPED_FOR := 0.15\n", "const STOPPED_FOR := 1000.0\n"),
    ("m16", "pressed down on the floor as before", DRIVER, "\t\tvelocity.y = 0.0 if is_on_floor() else fall - 18 * delta\n", "\t\tvelocity.y = -0.5 if is_on_floor() else fall - 18 * delta\n"),
    ("m17", "the jack dragged after him sideways", JACK, "\t\tvar followed := _rolled(pose, carry + short.dot(along))\n", "\t\tvar followed := Transform3D(chosen.basis, Vector3(driver.global_position.x, pose.origin.y, driver.global_position.z) + along * (after - STEER_AXIS) - chosen.basis * Vector3(0.0, 0.0, STEER_AXIS))\n"),
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
