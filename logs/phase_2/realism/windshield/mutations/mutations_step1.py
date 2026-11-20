"""The windshield's water, step 1 (#346): the soak, blobs, patches and the lamps' catch light: each on an APFS clone of game/, then test_tail_lamps.gd at 60 fps
on the clone, three at a time.
Usage: python3 -I mutations_step1.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
VAN = "features/vehicles/freight_van/van_presentation.gd"
TESTS = ["test_windshield_water.gd"]
APP = "app/first_drive.gd"
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("s1", "the soak as quick as the wet", VAN, "const SOAK_SECONDS := 8.0\n", "const SOAK_SECONDS := 2.0\n"),
    ("s2", "blobs not by the drops' hold", VAN, "\t_glass.set_shader_parameter(\"blob_most\", most)\n", "\t_glass.set_shader_parameter(\"blob_most\", 0.004)\n"),
    ("s3", "a lens of 2 degrees", VAN, "const BLOB_PATCH_HALF := 4.0\n", "const BLOB_PATCH_HALF := 1.0\n"),
    ("s4", "no lamps handed to the van", APP, "\tvan.get_node(\"VanPresentation\").set(\"lamps\", lamps)\n", "\tpass\n"),
    ("s5", "hidden lamps caught too", VAN, "\t\tif _blocked(eye, lamp.global_position):\n", "\t\tif false:\n"),
    ("s6", "dimmest lamps first", VAN, "\tseen.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])\n", "\tseen.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])\n"),
    ("s7", "lamps off the glass caught", VAN, "\t\tif at == OFF_GLASS:\n\t\t\tcontinue\n\t\tvar to_eye", "\t\tif false:\n\t\t\tcontinue\n\t\tvar to_eye"),
    ("s8", "patches twice as tall", VAN, "\t_glass.set_shader_parameter(\"patch_height\", most * 2.0)\n", "\t_glass.set_shader_parameter(\"patch_height\", most * 4.0)\n"),
    ("s9", "the soak never wiped", VAN, "\tpainter.vehicle = vehicle\n", "\tpainter.vehicle = vehicle if seconds < SOAK_SECONDS else null\n"),
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
