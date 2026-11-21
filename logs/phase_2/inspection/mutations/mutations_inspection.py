"""Mission 2's inspection, step 3 (#358): each on an APFS clone of game/, then test_inspection.gd at 60 fps
on the clone, three at a time.
Usage: python3 -I mutations_guidance.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TESTS = ["test_inspection.gd"]
MAP = "features/ui/driving_hud/mission_map.gd"
APP = "app/first_drive.gd"
HUD = "features/ui/driving_hud/driving_hud.gd"
GUARD = "features/characters/patrol_guard/patrol_guard.gd"
ESC = "features/missions/the_wrong_cargo/escape.gd"
COMPOUND = "features/environments/industrial_loop/compound.gd"
YARD = "features/environments/industrial_loop/container_yard.gd"
MARKS = "features/ui/driving_hud/seen_marks.gd"
MARKER = "features/ui/driving_hud/objective_marker.gd"
CARGO = "features/missions/the_wrong_cargo/the_wrong_cargo.gd"
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("i1", "no paperwork to read", CARGO, "\t_seal_checked = true\n\t_bill_read = false\n", "\t_seal_checked = true\n"),
    ("i2", "no trace of Vale Freight", CARGO, "the print beneath: VALE FREIGHT LT)", "the print beneath: illegible)"),
    ("i3", "E in the cab leaves the van with the paper open", APP, "\t\tif van.occupied and hud.document_visible() and _mission == cargo:\n\t\t\t_close_run_sheet()\n\t\t\treturn\n", ""),
    ("i4", "asked again on every reload", CARGO, "\t_seal_checked = stage >= 1\n\t_bill_read = true\n", "\t_seal_checked = stage >= 1\n\t_bill_read = false\n"),
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
