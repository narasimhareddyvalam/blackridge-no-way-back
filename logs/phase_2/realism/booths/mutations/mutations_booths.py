"""Mission 2's guard booths (#348): each on an APFS clone of game/, then test_tail_lamps.gd at 60 fps
on the clone, three at a time.
Usage: python3 -I mutations_booths.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
VAN = "features/vehicles/freight_van/van_presentation.gd"
TESTS = ["test_booths.gd"]
MISSION = "features/missions/the_wrong_cargo/the_wrong_cargo.gd"
BOOTH = "features/environments/industrial_loop/guard_booth.gd"
SHED = "features/environments/industrial_loop/transfer_shed.gd"
APP = "app/first_drive.gd"
TESTS_BY = {"w1": ["test_booths.gd", "test_mission_two.gd"], "w2": ["test_mission_two.gd"],
            "w6": ["test_mission_two.gd"]}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("b1", "the shed's own booth again (no door)", SHED, "\t_booth_node = Booth.new()\n", "\t_booth_node = (load(\"res://features/environments/industrial_loop/guard_booth.gd\") as GDScript).new()\n\t_booth_node.set_script(null)\n\t_booth_node = Node3D.new()\n"),
    ("b2", "the door facing the lane", BOOTH, "\tvar west := normal.x < 0.0\n", "\tvar west := normal.x > 2.0\n"),
    ("b3", "a door 0.7 m wide", BOOTH, "const DOOR := Vector2(0.86, 2.03)\n", "const DOOR := Vector2(0.7, 2.03)\n"),
    ("b4", "frames 20 mm", BOOTH, "const FRAME := Vector2(0.05, 0.07)\n", "const FRAME := Vector2(0.02, 0.07)\n"),
    ("b5", "the sash fixed", BOOTH, "\t\t_sash[index].position = _sash_shut[index] + _sash_way * _open * SASH_SLIDE\n", "\t\tpass\n"),
    ("b6", "the sash out of its track", BOOTH, "\t_sash_way = across\n", "\t_sash_way = (across + basis.z * 0.2).normalized()\n"),
    ("b7", "no heater", BOOTH, "\theater.name = \"Heater\"\n", "\theater.name = \"Box\"\n"),
    ("b8", "the camera facing away from the lane", BOOTH, "\tcamera.basis = Basis.looking_at(Vector3(1.0, -0.35, 0.45).normalized(), Vector3.UP)\n", "\tcamera.basis = Basis.looking_at(Vector3(-1.0, -0.35, 0.45).normalized(), Vector3.UP)\n"),
    ("b9", "the downpipe stopping short", BOOTH, "\tvar reach := SIZE.y - 0.06 - PLINTH\n", "\tvar reach := SIZE.y - 0.06 - PLINTH - 0.8\n"),
    ("b10", "the door lamp casting shadows", BOOTH, "\tlight.shadow_enabled = false\n\tdoor.add_child(light)\n", "\tlight.shadow_enabled = true\n\tdoor.add_child(light)\n"),
    ("b11", "the logbook's pages blank", BOOTH, "\tpaper.albedo_texture = _ruled_pages()\n", "\tpass\n"),
    ("r1", "the sash moving before her hand is on it", BOOTH, "const REACH_SECONDS := 0.8\n", "const REACH_SECONDS := 0.1\n"),
    ("r2", "her hand left where the pull was", BOOTH, "\tvar pull := _sash[2].global_position\n\tvar shoulder", "\tvar pull := global_transform * _sash_shut[2]\n\tvar shoulder"),
    ("r3", "her chair not pulled in", BOOTH, "\tchair.position.x += shift\n\tguard.position.x += shift\n", "\tpass\n"),
    ("r4", "no lean", BOOTH, "const LEAN_MOST := 0.6\n", "const LEAN_MOST := 0.05\n"),
    ("r5", "her elbow thrown up", BOOTH, "const ARM_POLE := Vector3(0.45, 0.9, 0.05)\n", "const ARM_POLE := Vector3(-0.4, 2.2, 0.6)\n"),
    ("r6", "her hand not turned to the pull", BOOTH, "\t_turn.set(\"aim\", aim)\n", "\tpass\n"),
    ("g1", "not watching the hand", BOOTH, "const LOOK_AT_HAND := 0.15\n", "const LOOK_AT_HAND := 99.0\n"),
    ("g2", "no look at the driver", BOOTH, "const GREET_SECONDS := 1.5\n", "const GREET_SECONDS := 0.0\n"),
    ("k1", "the notepads spread as sold", BOOTH, "\t\tmesh.visible = named.contains(\"yellow\") or named.contains(\"sticky\")\n", "\t\tmesh.visible = true\n\t\tcontinue\n"),
    ("k2", "the thermos off the counter", BOOTH, "\t_place(_prop(THERMOS, \"Thermos\"), Vector3(1.08, top, 0.0), \"counter\")\n", "\t_place(_prop(THERMOS, \"Thermos\"), Vector3(1.08, top + 0.1, 0.0), \"counter\")\n"),
    ("k3", "the box monitor back", BOOTH, "\tmodel.name = \"DellMonitor\"\n", "\tmodel.name = \"DellMonitor\"\n\tmodel.scene_file_path = \"\"\n"),
    ("w1", "the opening away from the driver's window", BOOTH, "const OPENING_AT := -0.1\n", "const OPENING_AT := 0.35\n"),
    ("w2", "the sheet taken from anywhere at the gate", SHED, "const WINDOW_REACH := 0.4\n", "const WINDOW_REACH := 9.0\n"),
    ("w3", "his shoulders never turning", BOOTH, "const TORSO_SHARE := 0.35\n", "const TORSO_SHARE := 0.0\n"),
    ("w4", "his head turning further than a neck", BOOTH, "\tlook.use_angle_limitation = true\n", "\tlook.use_angle_limitation = false\n"),
    ("w5", "the thermos before the open window", BOOTH, "\t_place(_prop(THERMOS, \"Thermos\"), Vector3(1.08, top, 0.3), \"counter\")\n", "\t_place(_prop(THERMOS, \"Thermos\"), Vector3(1.08, top, -0.1), \"counter\")\n"),
    ("w6", "no wait while the arm rises", MISSION, "\t\telif shed.barrier_rising():\n", "\t\telif false:\n"),
    ("k4", "the clock off the wall", BOOTH, "\t_place(_prop(CLOCK, \"WallClock\", Vector3(0, PI, 0)), Vector3(0.15, 2.47, lining.z),\n", "\t_place(_prop(CLOCK, \"WallClock\", Vector3(0, PI, 0)), Vector3(0.15, 2.47, lining.z - 0.2),\n"),
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
