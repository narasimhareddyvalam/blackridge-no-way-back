"""Mission 2's gates (#349): each on an APFS clone of game/, then test_tail_lamps.gd at 60 fps
on the clone, three at a time.
Usage: python3 -I mutations_gates.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
VAN = "features/vehicles/freight_van/van_presentation.gd"
TESTS = ["test_gates.gd"]
GATE = "features/environments/industrial_loop/sliding_gate.gd"
MISSION = "features/missions/the_wrong_cargo/the_wrong_cargo.gd"
BOOTH = "features/environments/industrial_loop/guard_booth.gd"
SHED = "features/environments/industrial_loop/transfer_shed.gd"
APP = "app/first_drive.gd"
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("v1", "the far carriage outside the tail", GATE, "const CARRIAGES: Array[float] = [0.35, 2.55]\n", "const CARRIAGES: Array[float] = [0.35, 3.4]\n"),
    ("v2", "the motor's pinion below the rack", GATE, "\tvar plinth_top := rack_low - PINION_TOP\n", "\tvar plinth_top := rack_low - PINION_TOP - 0.05\n"),
    ("v3", "a short rack", GATE, "Vector3(_wide + 0.5, RACK.y, RACK.x)", "Vector3(3.0, RACK.y, RACK.x)"),
    ("v4", "no braces", GATE, "\t\tbrace.name = \"Brace%d\" % index\n", "\t\tbrace.name = \"Bar%d\" % index\n"),
    ("v5", "the lamp lit while still", GATE, "\tvar on := _moving or _forced\n", "\tvar on := true\n"),
    ("v6", "photocells facing away", GATE, "\t\tcell.basis = Basis.looking_at(Vector3(-side, 0, 0))\n", "\t\tcell.basis = Basis.looking_at(Vector3(side, 0, 0))\n"),
    ("v7", "the arm off the hub", SHED, "\t_arm.position = Vector3(post_x, ARM_PIVOT_HEIGHT, GATE_Z)\n", "\t_arm.position = Vector3(post_x + 0.16, ARM_PIVOT_HEIGHT, GATE_Z)\n"),
    ("v8", "the arm short of its fork", SHED, "const ARM_LENGTH := 6.8\n", "const ARM_LENGTH := 6.4\n"),
    ("v9", "no lamps on the arm", SHED, "\t\t\t_arm_lamps.append(lamp)\n", "\t\t\tlamp.name = \"Stripe\"\n"),
    ("v10", "the barrier's beacon never flashing", SHED, "\t\t_beacon.visible = on and flash\n", "\t\t_beacon.visible = false\n"),
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
