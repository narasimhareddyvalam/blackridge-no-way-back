"""#330: the moon roof's collider and the passenger line: each on an APFS clone of game/, then test_tail_lamps.gd at 60 fps
on the clone, three at a time.
Usage: python3 -I mutations_330.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
VAN = "features/vehicles/freight_van/van_presentation.gd"
TESTS = ["test_moon_roof_rain.gd"]
LINE = "effects/wiper_flick.tscn"
TESTS_BY = {"m5": ["test_wiper_flick_config.gd"], "m6": ["test_wiper_flick_config.gd"]}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("m1", "no collider under the moon roof", VAN, "\t_cabin.add_child(stop)\n", "\tstop.free()\n"),
    ("m2", "it takes only the passenger water", VAN, "\tstop.cull_mask = 0xFFFFFFFF ^ VanParticles.PASSENGER_LAYER\n", "\tstop.cull_mask = VanParticles.PASSENGER_LAYER\n"),
    ("m3", "too thin: drops pass it in a tick", VAN, "const MOON_ROOF_STOP_DEPTH := 0.3\n", "const MOON_ROOF_STOP_DEPTH := 0.05\n"),
    ("m4", "below the glass", VAN, "const MOON_ROOF_SKIN := 0.003\n", "const MOON_ROOF_SKIN := -0.05\n"),
    ("m5", "the line back to 24 pieces", LINE, "amount = 60\n", "amount = 24\n"),
    ("m6", "the line wide again", LINE, "scale_min = 0.2\nscale_max = 0.3\n", "scale_min = 1.0\nscale_max = 0.3\n"),
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
