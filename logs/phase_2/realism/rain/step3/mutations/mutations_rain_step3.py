"""The rain's step 3, rain from the light (#354): each on an APFS clone of game/,
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
TESTS_BY = {"r4": ["test_gate_light.gd"], "r5": ["test_gate_light.gd"], "r6": ["test_gate_light.gd"]}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("r1", "slow drops fading above the ground (old life)", STREET, "\nlifetime = 1.7", "\nlifetime = 1.1"),
    ("r2", "the old slowest drop", DOCK, "initial_velocity_min = 4.0", "initial_velocity_min = 3.5"),
    ("r3", "the high floodlight rain leaning the old way", HIGH, "direction = Vector3(0.08, -0.997, 0)", "direction = Vector3(0.023, -0.997, 0.077)"),
    ("r4", "the compound's rain from 4 m again", COMPOUND, "const GATE_RAIN := Vector3(200.0, 7.0, 148.0)", "const GATE_RAIN := Vector3(200.0, 4.0, 148.0)"),
    ("r5", "the compound's rain in the old floodlight scene", WORLD, "lamp_rain.add_volume(LampRain.FLOOD_HIGH, place)", "lamp_rain.add_volume(LampRain.FLOODLIGHT, place)"),
    ("r6", "the yard floods' rain from the ground", COMPOUND, "Vector3(at.x, light.position.y\n\t\t\t- UNDER_HEAD, at.z - YARD_RAIN_OUT)", "Vector3(at.x, GROUND,\n\t\t\tat.z - YARD_RAIN_OUT)"),
    ("r7", "far drops as specks", FLOOD, "shader_parameter/far_pixels = 6.0", "shader_parameter/far_pixels = 0.0"),
    ("r8", "the old early fade", POST, "Vector2(0.95, 0.8)", "Vector2(0.75, 0.8)"),
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
