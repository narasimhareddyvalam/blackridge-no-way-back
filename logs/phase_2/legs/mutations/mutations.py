"""The legs fixes' mutations (#287, steps 4-6 of #289): each on an APFS clone of game/, then
its test(s) at 60 fps on the clone. Usage: python3 -I mutations.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
STEPS = "features/characters/driver/stair_steps.gd"
DRIVER = "features/characters/driver/driver.gd"
STANCE = "features/characters/driver/stance.gd"
STAIR = ["test_stair.gd"]
LOAD = ["test_loading.gd"]
FOOT = ["test_on_foot.gd"]
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("l2", "the stair keeps his feet walking across off the flight", STEPS,
     "	var inside := near(stair, at) and not leaving(at)\n", "	var inside := near(stair, at)\n", STAIR),
    ("l3", "the climb plays walking across the flight", STEPS,
     "	var up_it := _heading.length_squared() < 0.01 or _heading.dot(stair[\"up\"]) > ALONG\n",
     "	var up_it := true\n", STAIR),
    ("l4", "the crouch keeps stale ankles", DRIVER,
     "	if not _watch.active:\n		_watch.seen = false\n", "", LOAD),
    ("l5", "the swinging foot lifted by the walk on top of its arc", STEPS,
     "		targets[side] = _arc(side) if _swinging[side] else _holds[side] + Vector3.UP * lifted\n",
     "		targets[side] = (_arc(side) if _swinging[side] else _holds[side]) + Vector3.UP * lifted\n",
     STAIR),
    ("l6", "his hips lowered to the lower foot", STEPS, "const BETWEEN := 0.5\n",
     "const BETWEEN := 0.0\n", STAIR),
    ("l7", "the climbing foot up to the next tread at once", STEPS,
     "const UP_FIRST := 0.4\nconst UP_REST := 0.7\n", "const UP_FIRST := 0.15\nconst UP_REST := 0.3\n",
     STAIR),
    ("l8", "no foot kept on its own side", STANCE, "const SIDE := 0.045\n", "const SIDE := -1.0\n",
     FOOT + LOAD),
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
