"""The mission map, step 1 (#356): each on an APFS clone of game/, then test_guidance.gd at 60 fps
on the clone, three at a time.
Usage: python3 -I mutations_guidance.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TESTS = ["test_guidance.gd"]
MAP = "features/ui/driving_hud/mission_map.gd"
APP = "app/first_drive.gd"
HUD = "features/ui/driving_hud/driving_hud.gd"
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("m1", "the map a metre off the player", MAP, "\tfocus = at\n", "\tfocus = at + Vector3(1.0, 0.0, 0.0)\n"),
    ("m2", "turned with the driver's head at the wheel", APP, "\tvar forward := -van.global_basis.z\n\tvar yaw := atan2(forward.x, forward.z)\n", "\tvar view := -get_viewport().get_camera_3d().global_basis.z\n\tvar yaw := atan2(view.x, view.z)\n"),
    ("m3", "no buildings standing", MAP, "\t\tblocks.append(block)\n", "\t\tblock.visible = false\n"),
    ("m4", "a flat camera, straight down", MAP, "const TILT := deg_to_rad(52.0)", "const TILT := deg_to_rad(89.0)"),
    ("m5", "a hard frame, no fade", MAP, "\tscreen.material = fade\n", ""),
    ("m6", "the objective back in the corner", HUD, "const OBJECTIVE_LEFT := 392.0", "const OBJECTIVE_LEFT := 32.0"),
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
