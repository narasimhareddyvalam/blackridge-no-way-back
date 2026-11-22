"""Mission 2's docks (#352): each on an APFS clone of game/, then test_docks.gd at 60 fps on the
clone, three at a time.
Usage: python3 -I mutations_docks.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TESTS = ["test_docks.gd"]
DRESS = "features/environments/industrial_loop/dock_dressing.gd"
SHED = "features/environments/industrial_loop/transfer_building.gd"
HOUSE = "features/environments/industrial_loop/warehouse.gd"
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("d1", "no plates over the shed's doors", SHED, "\t\tDressing.plate(self, index + 1, _dock_x(index), DOCK_FLOOR, BUILDING.end.y)\n", ""),
    ("d2", "no number painted on the doors", DRESS, 'painted.name = "PaintedNumber"', 'painted.name = "Painted"'),
    ("d3", "a band half the door wide", DRESS, "const BAND := Vector2(2.62, 0.32)", "const BAND := Vector2(1.2, 0.32)"),
    ("d4", "the old small lenses", DRESS, "const LENS_RADIUS := 0.085", "const LENS_RADIUS := 0.05"),
    ("d5", "green over red", DRESS, '{"Red": [LENS_APART, red], "Green": [-LENS_APART, green]}', '{"Red": [-LENS_APART, red], "Green": [LENS_APART, green]}'),
    ("d6", "no visors", DRESS, 'visor.name = "Visor%d" % index', 'visor.name = "Shade%d" % index'),
    ("d7", "no signs at the compound", HOUSE, "\t\tDressing.caution_sign(self, index + 1, at)\n", ""),
    ("d8", "the sign's words wrong", DRESS, "PULL OUT ON\\nGREEN LIGHT", "PULL OUT ON\\nAMBER LIGHT"),
    ("d9", "the compound's seals left grey", HOUSE, "\t\tDressing.seal(pads)\n", "\t\tpass\n"),
    ("d10", "the guide stripes black", DRESS, "var stripe := Build.material(Color(0.95, 0.72, 0.06), 0.6)", "var stripe := Build.material(Color(0.035, 0.035, 0.035), 0.88)"),
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
