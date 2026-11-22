"""#267 part C's mutations: each on an APFS clone of game/, then test_town.gd at 60 fps on the
clone. Usage: python3 -I mutations.py <scratch> <out> [comma-separated mutations]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TOWN = "features/environments/industrial_loop/town_station.gd"
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("m1", "the canopy 4.0 m up, below a US canopy's 14 ft 6 in", TOWN,
     "const CANOPY_UNDER := 4.6", "const CANOPY_UNDER := 4.0"),
    ("m2", "the islands 2.5 m apart", TOWN,
     "Rect2(10.0, 183.4, 10.0, 1.2)]", "Rect2(10.0, 181.9, 10.0, 1.2)]"),
    ("m3", "the dispensers without bodies", TOWN,
     "			_body(pump, \"Dispenser%dBody\" % pumps, Vector3(PUMP_BODY.z, PUMP_BODY.y,\n				PUMP_BODY.x), Vector3.UP * PUMP_BODY.y / 2.0)\n", ""),
    ("m4", "a real brand on the price sign", TOWN,
     "const SIGN_WORDS: Array[String] = [\"GAS\",", "const SIGN_WORDS: Array[String] = [\"SHELL\","),
    ("m5", "the canopy's downlights casting shadows", TOWN,
     "			light.shadow_enabled = false\n			add_child(light)", "			light.shadow_enabled = true\n			add_child(light)"),
    ("m6", "the price sign on the road's shoulder", TOWN,
     "const PRICE_SIGN := Vector3(29.0, 0.0, 175.5)", "const PRICE_SIGN := Vector3(29.0, 0.0, 172.4)"),
]
scratch, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
summary = ["#267 part C mutations, each on an APFS clone, test_town.gd at 60 fps:"]
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
                          str(root / "game"), "--script", "res://tests/test_town.gd",
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
