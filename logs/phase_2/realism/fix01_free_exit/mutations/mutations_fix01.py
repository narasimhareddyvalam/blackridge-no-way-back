"""The audit's first fix (free exit from the shed and the container yard): each on an APFS clone of game/, then
test_free_exit.gd at 60 fps on the clone, three at a time.
Usage: python3 -I mutations_fix01.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
SHED = "features/environments/industrial_loop/transfer_shed.gd"
YARD = "features/environments/industrial_loop/container_yard.gd"
CARGO = "features/missions/the_wrong_cargo/the_wrong_cargo.gd"
TESTS = ["test_free_exit.gd"]
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("e1", "no loop at the shed", SHED, "\t\tif _target == 0.0 and _on_exit_loop(front):\n", "\t\tif false:\n"),
    ("e2", "the shed's loop either way", SHED, "\treturn over and (-vehicle.global_basis.z.normalized()).z > FACING_OUT\n\n\nfunc _gaze", "\treturn over and (-vehicle.global_basis.z.normalized()).z > -2.0\n\n\nfunc _gaze"),
    ("e3", "the arm stays up after", SHED, "\t\t\t\tand (minf(front.z, rear.z) > GATE_Z + CLEAR_BEHIND\n", "\t\t\t\tand (minf(front.z, rear.z) > GATE_Z + 500.0\n"),
    ("e4", "no loop at the yard", YARD, "\telif _gate_target == 0.0 and _on_exit_loop():\n", "\telif false:\n"),
    ("e5", "the yard's loop either way", YARD, "\treturn over and (-vehicle.global_basis.z.normalized()).z > FACING_OUT\n\n\nfunc _behind", "\treturn over and (-vehicle.global_basis.z.normalized()).z > -2.0\n\n\nfunc _behind"),
    ("e6", "the gate stays open after", YARD, "\t\treturn outside > YARD.end.y + CLEAR_BEHIND or nearest < EXIT_LOOP.position.y - 2.0\n", "\t\treturn false\n"),
    ("e7", "no word to wait", CARGO, "\t\treturn [\"WAIT FOR THE GATE\", \"The yard's gate is sliding open.\"]\n", "\t\tpass\n"),
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
