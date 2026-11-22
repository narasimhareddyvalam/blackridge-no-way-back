"""Step 3 part 2's mutations: each on an APFS clone of game/, then test_dock_worker.gd at 60 fps on
the clone. Usage: python3 -I mutations.py <scratch> <out> [comma-separated mutations]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
WORKER = "features/characters/dock_worker/dock_worker.gd"
SHED = "features/environments/industrial_loop/transfer_shed.gd"
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("m1", "he walks off without standing up", WORKER,
     "	_player.play(\"StandUp\", BLEND)\n", "	_timer = 99.0\n"),
    ("m2", "no check against the log, no note", WORKER,
     "			_next(\"checking\", \"Check\")", "			_timer = 0.0\n			state = \"noting\""),
    ("m3", "his way not by the stair", SHED,
     "const WORKER_STAIR_WAY: Array[Vector3] = [Vector3(-44.2, 1.3, 12.4), Vector3(-44.2, 1.3, 12.92),\n	Vector3(-44.2, 0.0, 15.4), Vector3(-44.0, 0.0, 16.4)]",
     "const WORKER_STAIR_WAY: Array[Vector3] = []"),
    ("m4", "the log left on the desk", WORKER,
     "	_carry(true)\n", ""),
    ("m5", "a slow look at the seal, 8 s", WORKER,
     "const CHECK_SECONDS := 3.0", "const CHECK_SECONDS := 8.0"),
    ("m6", "seated at the chair's column, not over the cushion", WORKER,
     "const SEAT_BACK := 0.05", "const SEAT_BACK := -0.25"),
]
scratch, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
summary = ["Step 3 part 2 mutations, each on an APFS clone, test_dock_worker.gd at 60 fps:"]
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
                          str(root / "game"), "--script", "res://tests/test_dock_worker.gd",
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
