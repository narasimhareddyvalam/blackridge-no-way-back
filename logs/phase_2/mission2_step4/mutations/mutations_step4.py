"""Step 4 of Mission 2 (the container yard and the swap): each on an APFS clone of game/, then
test_container_yard.gd at 60 fps on the clone, three at a time.
Usage: python3 -I mutations_step4.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
YARD = "features/environments/industrial_loop/container_yard.gd"
FENCE = "features/environments/industrial_loop/chain_link_fence.gd"
WORLD = "features/environments/industrial_loop/industrial_loop.gd"
CARGO = "features/missions/the_wrong_cargo/the_wrong_cargo.gd"
TESTS = ["test_container_yard.gd"]
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("b0", "before: no container yard", WORLD, "\t_container_yard()\n", "\tpass\n"),
    ("y1", "the gate gap 9 m", YARD, "\tvar east := GATE_X + GATE_WIDE / 2.0\n", "\tvar east := GATE_X + GATE_WIDE\n"),
    ("y2", "the fence 1.8 m", FENCE, "const HEIGHT := 2.4\n", "const HEIGHT := 1.8\n"),
    ("y3", "no barbed wire", FENCE, "\tfor strand in range(1, 4):\n", "\tfor strand in range(1, 1):\n"),
    ("y4", "stacks floating", YARD, "\t\t\t\tvar y := GROUND + PAVING_TOP\n", "\t\t\t\tvar y := GROUND + PAVING_TOP + 0.1\n"),
    ("y5", "four high", YARD, "draw.randi_range(2, MOST_HIGH)", "draw.randi_range(2, 4)"),
    ("y6", "a block in the lane", YARD, "[[\"Container40\", 115.7]", "[[\"Container40\", 108.0]"),
    ("y7", "the gate without the code", YARD, "\t_keys_left = CODE.length()\n", "\t_gate_target = GATE_WIDE\n"),
    ("y8", "the window kept up", YARD, "\t\tvehicle.set(\"left_window_target\", 1.0)\n", "\t\tvehicle.set(\"left_window_target\", 0.0)\n"),
    ("y9", "the gate never shuts", YARD, "\t\t_gate_target = 0.0\n\tvar moving", "\t\t_gate_target = GATE_WIDE\n\tvar moving"),
    ("y10", "the keypad from anywhere", YARD, "absf(front.z - STOP_Z) < STOP_WITHIN", "absf(front.z - STOP_Z) < 50.0"),
    ("y11", "the swap outside the bay", YARD, "\treturn IN_BAY.has_point(at) and", "\treturn true or IN_BAY.has_point(at) and"),
    ("y12", "his van moved 5 cm", YARD, "\t_left.global_transform = van.global_transform\n", "\t_left.global_transform = van.global_transform.translated(Vector3(0.0, 0.0, 0.05))\n"),
    ("y13", "the load not left", YARD, "\t\t\t(child as Node3D).reparent(_left, true)\n", "\t\t\tpass\n"),
    ("y14", "the seal lost", YARD, "\t_left.set_meta(\"seal_number\", str(van.get(\"seal_number\")))\n", "\t_left.set_meta(\"seal_number\", \"\")\n"),
    ("y15", "the dark van left standing", YARD, "\t_dark_van.visible = false\n", "\t_dark_van.visible = true\n"),
    ("y16", "not repainted", YARD, "\tpresentation.call(\"set_paint\", DARK)\n", "\tpresentation.call(\"set_paint\", Color.WHITE)\n"),
    ("y17", "stage 2 not saved", CARGO, "\tconfig.set_value(\"cargo\", \"stage\", stage)\n\tcheckpoint_reached.emit(config)\n\t_update_objective()\n\n\n## Ethan", "\tconfig.set_value(\"cargo\", \"stage\", stage)\n\t_update_objective()\n\n\n## Ethan"),
    ("y18", "the reload not restored", CARGO, "\t\telif stage == 2 and yard != null:\n", "\t\telif false:\n"),
    ("y19", "the stacks not solid", YARD, "\t\t\t\t_solid_box(Vector3(float(cell[1])", "\t\t\t\tif false: _solid_box(Vector3(float(cell[1])"),
    ("y20", "the dark van's box not fitted", YARD, "\t\t\t(parked.shape as BoxShape3D).size = _van_box\n", "\t\t\tpass\n"),
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
