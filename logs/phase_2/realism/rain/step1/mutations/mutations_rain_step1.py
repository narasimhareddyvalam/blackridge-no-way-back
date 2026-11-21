"""The rain's step 1, each drop drawn as a camera sees it (#354): each on an APFS clone of game/,
then test_lamp_rain_config.gd at 60 fps on the clone, three at a time.
Usage: python3 -I mutations_rain_step1.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TESTS = ["test_lamp_rain_config.gd"]
SHADER = "effects/scatter_particle.gdshader"
STREET = "effects/lamp_rain_street.tscn"
FLOOD = "effects/lamp_rain_floodlight.tscn"
DOCK = "effects/lamp_rain_dock.tscn"
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("s1", "the street lamps' rain drawn as before", STREET, "shader_parameter/camera_streak = true", "shader_parameter/camera_streak = false"),
    ("s2", "1-pixel streaks again (dashes)", FLOOD, "shader_parameter/min_pixels = 1.6", "shader_parameter/min_pixels = 1.0"),
    ("s3", "the shader without the camera streak", SHADER, "uniform bool camera_streak = false;", "uniform bool camera_streak_off = false;"),
    ("s4", "a straight-down fall, not the wind's slant", DOCK, "shader_parameter/fall = Vector3(0.079984, -0.996796, 0)", "shader_parameter/fall = Vector3(0, -1, 0)"),
    ("s5", "a long exposure", STREET, "shader_parameter/exposure = 0.025", "shader_parameter/exposure = 0.1"),
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
