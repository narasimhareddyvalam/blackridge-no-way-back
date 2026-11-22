"""The objective's marker, pin, distance and key prompt, step 2 (#358): each on an APFS clone of game/, then test_guidance.gd at 60 fps
on the clone, three at a time.
Usage: python3 -I mutations_guidance.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TESTS = ["test_guidance.gd"]
MAP = "features/ui/driving_hud/mission_map.gd"
APP = "app/first_drive.gd"
HUD = "features/ui/driving_hud/driving_hud.gd"
MARKER = "features/ui/driving_hud/objective_marker.gd"
CARGO = "features/missions/the_wrong_cargo/the_wrong_cargo.gd"
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("s1", "the objective sends nowhere", CARGO, "\tif not active or vehicle == null:\n\t\treturn Vector3.INF\n\tvar rear", "\tif true:\n\t\treturn Vector3.INF\n\tvar rear"),
    ("s2", "the marker never drawn", MARKER, "\treturn _target != Vector3.INF and _camera != null and _fade() > 0.0", "\treturn false"),
    ("s3", "the distance half what it is", HUD, "\tvar metres := Vector2(point.x - from.x, point.z - from.z).length()", "\tvar metres := Vector2(point.x - from.x, point.z - from.z).length() * 0.5"),
    ("s4", "no pin on the map", MAP, "\tif _target == Vector3.INF:\n\t\treturn Vector2.INF\n\tvar middle", "\tif true:\n\t\treturn Vector2.INF\n\tvar middle"),
    ("s5", "the key left among the controls", HUD, "\tif parts.size() != 2 or parts[0].length() != 1", "\tif true or parts.size() != 2 or parts[0].length() != 1"),
    ("s6", "no prompt at the gate", APP, "\t\treturn \"E  \" + cargo.interact_label()", "\t\treturn \"\""),
    ("s7", "the prompt off centre", HUD, "\t\tprompt.offset_left = -width / 2.0\n", "\t\tprompt.offset_left = 0.0\n"),
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
