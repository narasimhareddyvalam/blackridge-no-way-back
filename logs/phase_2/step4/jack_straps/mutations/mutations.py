"""Step 4 (2 and 3) mutations, pumping the jack and strapping by hand: each on an APFS clone of game/, then test_loading.gd at 60 fps on
the clone. Usage: python3 -I mutations.py <scratch> <out> [comma-separated mutations]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
JACK = "features/environments/industrial_loop/pallet_jack.gd"
HOLD = "features/vehicles/freight_van/van_hold.gd"
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("m7", "one stroke lifts the load", JACK, "const PUMPS := 4\n", "const PUMPS := 1\n"),
    ("m8", "the handle does not rock as he pumps", JACK,
     "		_tiller.rotation.x = maxf(tilt - _pump_depth * sin(PI * _stroke / STROKE), 0.0)\n",
     "		_tiller.rotation.x = tilt\n"),
    ("m9", "W rolls the pallet still on the floor", JACK,
     "	if _under != null or _lowering >= 0.0:\n		steer = 0.0", "	if false:\n		steer = 0.0"),
    ("m10", "the pallet dropped at once", JACK,
     "const LOWER_SECONDS := 1.2", "const LOWER_SECONDS := 0.01"),
    ("m11", "no pause at neutral after the last stroke", JACK,
     "const TO_NEUTRAL := 0.4", "const TO_NEUTRAL := 0.0"),
    ("m12", "a strap thrown and hooked in one go", JACK,
     "	if _strap_stage < 3:\n		_strap_stage += 1", "	if _strap_stage < 3:\n		_strap_stage = 3"),
    ("m13", "strapped after the first strap", JACK,
     "		if _strap_index >= STRAPS:", "		if _strap_index >= 1:"),
    ("m14", "no lashing rings in the hold", HOLD, "	_rings()\n", ""),
    ("m15", "he pushes from where he pumped, never stepping in", JACK,
     "	driver.call(\"push_step_in\")\n", ""),
]
scratch, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
summary = ["Step 4 (2 and 3) mutations, each on an APFS clone, test_loading.gd at 60 fps:"]
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
                          str(root / "game"), "--script", "res://tests/test_loading.gd",
                          "--fixed-fps", "60"], env={"HOME": str(home), "PATH": "/usr/bin:/bin"},
                         capture_output=True, text=True, timeout=400)
    (out / f"{name}.log").write_text(run.stdout + run.stderr)
    fails = [l[6:] for l in run.stdout.splitlines() if l.startswith("FAIL: ")]
    result = next((l for l in run.stdout.splitlines() if "RESULT" in l), "no result")
    summary.append(f"{name}  {what:<55} exit {run.returncode}, {result.split(': ')[-1]}"
                   + "".join(f"\n      FAIL: {f[:110]}" for f in fails))
with (out / "SUMMARY.txt").open("a" if ONLY else "w") as handle:
    handle.write("\n".join(summary[1:] if ONLY else summary) + "\n")
print("\n".join(summary))
