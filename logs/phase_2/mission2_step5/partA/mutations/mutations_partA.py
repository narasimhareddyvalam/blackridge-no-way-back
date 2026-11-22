"""Step 5 of Mission 2, part A (the compound's boundary, gate and booth): each on an APFS clone of game/, then
test_compound.gd at 60 fps on the clone, three at a time.
Usage: python3 -I mutations_partA.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
COMPOUND = "features/environments/industrial_loop/compound.gd"
BOOTH = "features/environments/industrial_loop/guard_booth.gd"
CARGO = "features/missions/the_wrong_cargo/the_wrong_cargo.gd"
TESTS = ["test_compound.gd"]
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("k1", "the gate gap 9 m", COMPOUND, "\tvar east := GATE_X + GATE_WIDE / 2.0\n", "\tvar east := GATE_X + GATE_WIDE\n"),
    ("k2", "not stepped clear of the yard", COMPOUND, "\tVector2(274.0, 92.0), Vector2(128.0, 92.0), Vector2(128.0, 130.0), Vector2(138.0, 130.0)]\n",
     "\tVector2(274.0, 92.0), Vector2(128.0, 92.0), Vector2(128.0, 130.0), Vector2(135.0, 130.0)]\n"),
    ("k3", "the shed's guard", COMPOUND, "res://features/characters/compound_guard/compound_guard.glb", "res://features/characters/guard/guard.glb"),
    ("k4", "the guard not seated", BOOTH, "\tplayer.play(\"SitIdle\")\n", "\tpass\n"),
    ("k5", "the booth on the far side", COMPOUND, "const BOOTH_FACE_X := GATE_X - 2.0\n", "const BOOTH_FACE_X := GATE_X + 4.5\n"),
    ("k6", "not marked a stand-in", BOOTH, "\tguard.set_meta(\"stand_in\", true)\n", "\tguard.set_meta(\"stand_in\", false)\n"),
    ("k7", "the gate without the run sheet", COMPOUND, "\t_check_left = CHECK_SECONDS\n", "\t_gate_target = GATE_WIDE\n"),
    ("k8", "the window kept up", COMPOUND, "\t\tvehicle.set(\"left_window_target\", 1.0)\n", "\t\tvehicle.set(\"left_window_target\", 0.0)\n"),
    ("k9", "the gate never shuts", COMPOUND, "\t\t_gate_target = 0.0\n\tvar moving", "\t\t_gate_target = GATE_WIDE\n\tvar moving"),
    ("k10", "the booth from anywhere", COMPOUND, "front.z < GATE_Z + STOP_LINE_OUT + 6.0", "front.z < GATE_Z + STOP_LINE_OUT + 60.0"),
    ("k11", "the booth not solid", BOOTH, "\tbody.add_child(collision)\n", "\tpass\n"),
    ("k12", "the gate not solid", COMPOUND, "\t_gate.add_child(collision)\n", "\tpass\n"),
    ("k13", "the fence not solid", COMPOUND, "\t\t\tfence.run(self, _body,", "\t\t\tfence.run(self, StaticBody3D.new(),"),
    ("k14", "the objective not naming it", CARGO, "\treturn [\"DRIVE TO THE WAREHOUSE COMPOUND\",", "\treturn [\"MISSION 2 IS BEING BUILT\","),
    ("k15", "E at the booth not wired", CARGO, "\tif active and stage == 2 and compound != null:\n", "\tif false:\n"),
    ("k16", "no barbed wire", "features/environments/industrial_loop/chain_link_fence.gd", "\tfor strand in range(1, 4):\n", "\tfor strand in range(1, 1):\n"),
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
