"""The rain's step 5, splashes (#354): each on an APFS clone of game/,
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
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("p1", "three droplets a landing again", STREET, "sub_emitter_amount_at_collision = 5", "sub_emitter_amount_at_collision = 3"),
    ("p2", "the old tiny droplets", DOCK, "scale_min = 0.1\nscale_max = 0.25\ncolor = Color(0.88, 0.89, 0.9, 1)\nalpha_curve = SubResource(\"CurveTexture_splash_alpha\")", "scale_min = 0.03\nscale_max = 0.1\ncolor = Color(0.88, 0.89, 0.9, 1)\nalpha_curve = SubResource(\"CurveTexture_splash_alpha\")"),
    ("p3", "splashes catching no light", HIGH, "shader_parameter/glint = 1.5", "shader_parameter/glint = 0.0"),
    ("p4", "no bright instant at the hit", POST, "Vector2(0, 0.9), 0.0, 0.0, 0, 0, Vector2(0.3, 0.6)", "Vector2(0, 0.6), 0.0, 0.0, 0, 0, Vector2(0.3, 0.6)"),
    ("p5", "too few splash slots (landings dropped)", FLOOD, "amount = 7500", "amount = 4500"),
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
