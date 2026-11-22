"""#280's mutations: each on an APFS clone of game/, then test_roadside_trees.gd at 60 fps on the
clone. Usage: python3 -I mutations.py <scratch> <out> [comma-separated mutations]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
FOREST = "features/environments/industrial_loop/roadside_forest.gd"
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("m1", "no roadside kinds (the band 0 m)", FOREST,
     "const SPECIES_BAND := 8.0", "const SPECIES_BAND := 0.0"),
    ("m2", "the edge and the band behind swapped", FOREST,
     "	var mix: Dictionary = EDGE_MIX if beyond < SPECIES_EDGE else BEHIND_MIX",
     "	var mix: Dictionary = BEHIND_MIX if beyond < SPECIES_EDGE else EDGE_MIX"),
    ("m3", "trunk colliders not sized with their tree", FOREST,
     "		shape.radius = float(models[model][\"trunk\"]) * size",
     "		shape.radius = float(models[model][\"trunk\"])"),
    ("m4", "the foliage left as imported, without the wind", FOREST,
     "			mesh.surface_set_material(surface, _foliage(used, high))\n",
     ""),
    ("m5", "a draw from the forest's own random sequence for the kind", FOREST,
     "	var kind := _kind(x, z)",
     "	var kind := _kind(x, z) if rng.randf() < 2.0 else \"\""),
    ("m6", "the cedar at its modelled girth, 2.1 m at breast height", FOREST,
     "		shape.radius = float(models[model][\"trunk\"]) * size",
     "		shape.radius = float(models[model][\"trunk\"]) * size * (1.67 if kind == \"western_red_cedar\" else 1.0)"),
]
scratch, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
summary = ["#280 mutations, each on an APFS clone, test_roadside_trees.gd at 60 fps:"]
for name, what, path, old, new in MUTATIONS:
    if ONLY and name not in ONLY:
        continue
    root = scratch / name
    shutil.rmtree(root, ignore_errors=True)
    (root / "tools").mkdir(parents=True)
    subprocess.run(["cp", "-cR", str(REPO / "game"), str(root / "game")], check=True)
    target = root / "game" / path
    text = target.read_text()
    assert text.count(old) == 1, name
    target.write_text(text.replace(old, new))
    subprocess.run(["diff", "-ru", str(REPO / "game"), str(root / "game"), "-x", ".godot"],
                   stdout=open(out / f"{name}.diff", "w"))
    home = scratch / f"{name}-home"
    home.mkdir(exist_ok=True)
    if True:
        subprocess.run(["/Applications/Godot.app/Contents/MacOS/Godot", "--headless", "--path",
                    str(root / "game"), "--import"], env={"HOME": str(home), "PATH": "/usr/bin:/bin"},
                   capture_output=True, timeout=300)
    run = subprocess.run(["/Applications/Godot.app/Contents/MacOS/Godot", "--headless", "--path",
                          str(root / "game"), "--script", "res://tests/test_roadside_trees.gd",
                          "--fixed-fps", "60"], env={"HOME": str(home), "PATH": "/usr/bin:/bin"},
                         capture_output=True, text=True, timeout=200)
    (out / f"{name}.log").write_text(run.stdout + run.stderr)
    fails = [l[6:] for l in run.stdout.splitlines() if l.startswith("FAIL: ")]
    result = next((l for l in run.stdout.splitlines() if "RESULT" in l), "no result")
    summary.append(f"{name}  {what:<55} exit {run.returncode}, {result.split(': ')[-1]}"
                   + "".join(f"\n      FAIL: {f[:110]}" for f in fails))
with (out / "SUMMARY.txt").open("a" if ONLY else "w") as handle:
    handle.write("\n".join(summary[1:] if ONLY else summary) + "\n")
print("\n".join(summary))
