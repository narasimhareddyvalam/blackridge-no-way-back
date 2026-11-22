"""The rain's step 4, rain in the headlights (#354): each on an APFS clone of game/,
then test_lamp_rain_config.gd at 60 fps on the clone, three at a time.
Usage: python3 -I mutations_rain_step1.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TESTS = ["test_lamp_rain_config.gd"]
HIGH = "effects/lamp_rain_flood_high.tscn"
COMPOUND = "features/environments/industrial_loop/compound.gd"
WORLD = "features/environments/industrial_loop/industrial_loop.gd"
SHADER = "effects/scatter_particle.gdshader"
STREET = "effects/lamp_rain_street.tscn"
FLOOD = "effects/lamp_rain_floodlight.tscn"
DOCK = "effects/lamp_rain_dock.tscn"
POST = "effects/lamp_rain_post.tscn"
TESTS_BY = {k: ["test_headlights.gd"] for k in ["h1", "h2", "h3", "h4", "h5", "h6"]}
TESTS_BY["h8"] = ["test_oncoming_van.gd"]
BEAMS = "effects/headlight_rain.tscn"
VAN = "features/vehicles/freight_van/van_presentation.gd"
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("h1", "the beams' rain moving with the van", BEAMS, "local_coords = false", "local_coords = true"),
    ("h2", "rain only 12 m out", BEAMS, "emission_box_extents = Vector3(4.5, 1.75, 12)", "emission_box_extents = Vector3(4.5, 1.75, 6)"),
    ("h3", "the rain off the layer the headlights light", BEAMS, "layers = 65", "layers = 64"),
    ("h4", "rain falling in the dark", VAN, "\tvar falling := lit or rain_backlit > 0.0\n", "\tvar falling := true\n"),
    ("h5", "no rain stop on the van", VAN, "\tstop.cull_mask = RAIN_STOP_LAYER\n\tadd_child(stop)\n", "\tstop.cull_mask = RAIN_STOP_LAYER\n"),
    ("h6", "no light thrown back toward the lamps", BEAMS, "shader_parameter/back_scatter = 1.0", "shader_parameter/back_scatter = 0.0"),
    ("h7", "the lamps' rain throwing nothing back", POST, "shader_parameter/back_scatter = 0.3", "shader_parameter/back_scatter = 0.0"),
    ("h8", "an oncoming van's beams not lighting the rain", VAN, "\train_backlit = _oncoming_rain()\n", "\train_backlit = 0.0\n"),
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
