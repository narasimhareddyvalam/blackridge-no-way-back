"""The windshield's water, steps 2-4 (#346): the smear, the ridge, the wiped film: each on an APFS clone of game/, then test_tail_lamps.gd at 60 fps
on the clone, three at a time.
Usage: python3 -I mutations_step2.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
VAN = "features/vehicles/freight_van/van_presentation.gd"
TESTS = ["test_windshield_water.gd"]
APP = "app/first_drive.gd"
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("t1", "no smear", VAN, "const SMEAR_REACH := 0.02\n", "const SMEAR_REACH := 0.0\n"),
    ("t2", "the ridge as wide as before", VAN, "const RIDGE_WIDTH := 0.009\n", "const RIDGE_WIDTH := 0.014\n"),
    ("t3", "the ridge no brighter than a drop", VAN, "const RIDGE_CATCH := 2.5\n", "const RIDGE_CATCH := 1.0\n"),
    ("t4", "no film behind the blade", VAN, "const WIPED_RIPPLE := 0.004\n", "const WIPED_RIPPLE := 0.0\n"),
    ("t5", "a smear of 6%", VAN, "const SMEAR_REACH := 0.02\n", "const SMEAR_REACH := 0.06\n"),
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
