"""The run sheet handover (#355): each on an APFS clone of game/, then test_handover.gd at 60 fps
on the clone, three at a time.
Usage: python3 -I mutations_handover.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TESTS = ["test_handover.gd"]
BOOTH = "features/environments/industrial_loop/guard_booth.gd"
COMPOUND = "features/environments/industrial_loop/compound.gd"
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("o1", "handed to from any distance", BOOTH, "\treturn leaned.distance_to(point) <= reach * HAND_REACH_SHARE\n", "\treturn true\n"),
    ("o2", "the compound's gate opening before the sheet is back", COMPOUND, "\t\tif bool(booth.call(\"sheet_back\")):\n", "\t\tif _check_left > 0.5:\n"),
    ("o3", "no sheet held out", BOOTH, "\t\t\tsheet.visible = true\n", "\t\t\tsheet.visible = false\n"),
    ("o4", "the sheet going to her hand before she has it", BOOTH, "\t\t\t_hand_on(at_van, smoothstep(0.0, TAKE_SECONDS, _hand_t))\n\t\t\t_lay_sheet(at_van, toward_van, 0.0)\n", "\t\t\t_hand_on(at_van, smoothstep(0.0, TAKE_SECONDS, _hand_t))\n\t\t\t_lay_sheet(grip_point(), toward_van, 0.0)\n"),
    ("o5", "a glance, not a read", BOOTH, "const READ_SECONDS := 3.0", "const READ_SECONDS := 1.0"),
    ("o6", "reading without looking at it", BOOTH, "\telif sheet != null and sheet.visible and handover != \"\" and handover != \"in\":\n", "\telif false:\n"),
    ("o7", "the sheet never going back in", BOOTH, "\t\t\t\tsheet.visible = false\n\t\t\t\t_next(\"back\")\n", "\t\t\t\t_next(\"back\")\n"),
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
