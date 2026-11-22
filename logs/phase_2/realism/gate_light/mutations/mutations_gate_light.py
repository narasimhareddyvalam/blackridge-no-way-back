"""The compound gate's light (#353): each on an APFS clone of game/, then test_gate_light.gd at
60 fps on the clone, three at a time.
Usage: python3 -I mutations_gate_light.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TESTS = ["test_gate_light.gd"]
COMPOUND = "features/environments/industrial_loop/compound.gd"
MENU = "features/ui/menus/front_menu.gd"
TESTS_BY = {"l9": ["test_menus.gd"]}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("l1", "no gate flood", COMPOUND, "\t_gate_flood(metal)\n", ""),
    ("l2", "heads aimed off the lane", COMPOUND, "const GATE_AIMS: Array[Vector3] = [Vector3(199.0, 0.0, 151.5), Vector3(200.0, 0.0, 144.5)]", "const GATE_AIMS: Array[Vector3] = [Vector3(215.0, 0.0, 151.5), Vector3(215.0, 0.0, 144.5)]"),
    ("l3", "the model as imported: glass opaque, LEDs unlit", COMPOUND, "\tfor surface in range(face.mesh.get_surface_count()):\n", "\tfor surface in range(0):\n"),
    ("l4", "the pole on the driveway", COMPOUND, "const GATE_POLE := Vector3(204.6, 0.0, 147.4)", "const GATE_POLE := Vector3(202.2, 0.0, 147.4)"),
    ("l5", "the pole not solid", COMPOUND, "\t_solid_box(at + Vector3.UP * 1.0, Vector3(0.3, 2.0, 0.3))\n\t_footprints.append(Rect2(at.x - 0.2,", "\t_footprints.append(Rect2(at.x - 0.2,"),
    ("l6", "no rain at the gate", COMPOUND, "\train_places.append(Transform3D(Basis.IDENTITY, GATE_RAIN))\n", ""),
    ("l7", "no rain under the yard floods", COMPOUND, "\t\train_places.append(Transform3D(Basis.IDENTITY, Vector3(at.x, GROUND, at.z\n\t\t\t- YARD_RAIN_OUT)))\n", ""),
    ("l8", "an amber gate flood", COMPOUND, "\tlight.light_color = FLOOD\n\tlight.light_energy = GATE_FLOOD_ENERGY", "\tlight.light_color = Color(1.0, 0.6, 0.2)\n\tlight.light_energy = GATE_FLOOD_ENERGY"),
    ("l9", "the model's author not credited", MENU, 'by The Street Light Man "', 'by its author "'),
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
