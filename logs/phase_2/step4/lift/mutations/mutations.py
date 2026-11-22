"""Step 4 (1 and 4) mutations, the hold-to-run lift and its pendant: each on an APFS clone of game/, then test_loading.gd at 60 fps on
the clone. Usage: python3 -I mutations.py <scratch> <out> [comma-separated mutations]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
LIFT = "features/environments/industrial_loop/dock_lift.gd"
BAY = "features/environments/industrial_loop/van_bay.gd"
BEEP = "features/audio/loading/lift_beep.wav.import"
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("m1", "the lift runs on a tap, held or not", LIFT,
     "		if held:\n", "		if true:\n"),
    ("m2", "letting go of E does not stop it", BAY,
     "	if _holder != null and (not Input.is_action_pressed(\"interact\")",
     "	if _holder != null and (false"),
    ("m3", "walking away does not stop it", BAY,
     "			or (_holder != _lift and not _at_controls(_holder.global_position))):",
     "			or false):"),
    ("m4", "no beep while it moves", LIFT,
     "			beep.play()\n", "			pass\n"),
    ("m5", "the beep plays once, not looped", BEEP,
     "edit/loop_mode=2", "edit/loop_mode=0"),
    ("m6", "no emergency stop on the pendant", LIFT,
     "	stop.name = \"PendantStop\"", "	stop.name = \"PendantCap\""),
]
scratch, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
summary = ["Step 4 (1 and 4) mutations, each on an APFS clone, test_loading.gd at 60 fps:"]
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
