"""The audit's fourth fix (the dock worker): each on an APFS clone of game/, then
test_dock_worker.gd at 60 fps on the clone, three at a time.
Usage: python3 -I mutations_fix04.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
WORKER = "features/characters/dock_worker/dock_worker.gd"
STAIR = "features/characters/dock_worker/worker_stair.gd"
CUT = "features/missions/the_wrong_cargo/seal_cutscene.gd"
SHED = "features/environments/industrial_loop/transfer_shed.gd"
APP = "app/first_drive.gd"
TESTS = ["test_dock_worker.gd"]
TESTS_BY = {"m22": ["test_sealing.gd"], "m23": ["test_sealing.gd"], "m34": ["test_dock_worker.gd", "test_sealing.gd"]}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("m1", "the stair at his flat pace", WORKER, "\tvar wanted := float(_stair_walk.call(\"pace\", down)) if on_stair else WALK\n", "\tvar wanted := WALK\n"),
    ("m2", "no feet on the treads", STAIR, "\t_legs.active = _weight > 0.0\n", "\t_legs.active = false\n"),
    ("m3", "no hand on the rail", STAIR, "\t\t_arms[side].active = on > 0.0\n", "\t\t_arms[side].active = false\n"),
    ("m4", "the log in his rail hand going down", WORKER, "\t_carry(true, true)\n", "\t_carry(true)\n"),
    ("m5", "reaching ahead going down", STAIR, "\tvar reach := _rail_t(shoulder + facing * (0.0 if down else RAIL_AHEAD))\n", "\tvar reach := _rail_t(shoulder + facing * RAIL_AHEAD)\n"),
    ("m6", "getting going at once", WORKER, "const ACCEL := WALK / 0.5\n", "const ACCEL := WALK / 0.05\n"),
    ("m7", "no slowing to a stop", WORKER, "\twanted = maxf(minf(wanted, sqrt(2.0 * STOP_DECEL * left)), CREEP)\n", "\twanted = maxf(wanted, CREEP)\n"),
    ("m8", "snapping round", WORKER, "const TURN_AT_ONCE := deg_to_rad(3.0)\n", "const TURN_AT_ONCE := deg_to_rad(180.0)\n"),
    ("m9", "corners walked sharp", WORKER, "const LOOK := 0.25\n", "const LOOK := 0.0001\n"),
    ("m11", "no seal in his hand", WORKER, "\t\t_show_seal(true)\n", "\t\t_show_seal(false)\n"),
    ("m12", "the seal kept in his hand", WORKER, "\t\t\t_show_seal(false)\n\t\t\tsealed.emit()\n", "\t\t\tsealed.emit()\n"),
    ("m13", "no pen", WORKER, "\t_show_pen(true)\n", "\t_show_pen(false)\n"),
    ("m14", "the scanner always lit", WORKER, "\t_window.material_override = _window_lit if on else _window_dark\n", "\t_window.material_override = _window_lit\n"),
    ("m15", "aiming too long", WORKER, "const AIM_SECONDS := 0.4\n", "const AIM_SECONDS := 1.0\n"),
    ("m16", "aimed at the load's middle", WORKER, "\treturn _aim_label.global_position if _aim_label != null else global_position\n", "\treturn _scan_load.global_position if _scan_load != null else global_position\n"),
    ("m17", "no green flash", WORKER, "\t_good_read.visible = _timer >= BEEP_AT and _timer < BEEP_AT + FLASH_SECONDS\n", "\t_good_read.visible = false\n"),
    ("m18", "the stair taken beside it", STAIR, "\treturn a > -float(_stair[\"tread\"]) and a < flight() + float(_stair[\"tread\"]) \\\n\t\tand aside < float(_stair[\"width\"]) / 2.0 + WIDE\n", "\treturn a > -float(_stair[\"tread\"]) and a < flight() + float(_stair[\"tread\"])\n"),
    ("m19", "out with no room behind the van", WORKER, "\tvar waiting := state == \"out\" and (not _room() or door_shut) and (_past_door\n", "\tvar waiting := state == \"out\" and door_shut and (_past_door\n"),
    ("m20", "through the shut door", WORKER, "\tvar door_shut := side_door != null and float(side_door.call(\"swung\")) < 1.0\n", "\tvar door_shut := false\n"),
    ("m21", "no cutscene", SHED, "\tdock_hand_called.emit(van)\n", "\tpass\n"),
    ("m22", "the player's control not held", CUT, "\t_driver.set(\"held\", true)\n", "\t_driver.set(\"held\", false)\n"),
    ("m23", "Ethan not stepping clear", CUT, "\t\t_driver.call(\"walk_to\", [spot] as Array[Vector3])\n", "\t\tpass\n"),
    ("m24", "the cutscene running on", CUT, "const AFTER := 3.0\n", "const AFTER := 30.0\n"),
    ("m25", "no skipping", APP, "\t\t\tseal_cutscene.call(\"skip\")\n", "\t\t\tpass\n"),
    ("m26", "a camera behind the wall", CUT, "const STAIR_EYE := Vector3(-41.0, 2.2, 13.4)\n", "const STAIR_EYE := Vector3(-38.5, 2.2, 13.4)\n"),
    ("m27", "too little room behind the van", WORKER, "const ROOM := 2.5\n", "const ROOM := 0.5\n"),
    ("m28", "the chair left out", WORKER, "\t_roll(1.0 - smoothstep(0.0, 1.0, clampf(_timer / TUCK_SECONDS, 0.0, 1.0)))\n", "\t_roll(1.0)\n"),
    ("m29", "the floor taken from a metre up", WORKER, "const STEP_UP := 0.4\n", "const STEP_UP := 1.0\n"),
    ("m30", "the seal shot as he turns to go", CUT, "const CLEAR_OF_SEAL := 1.0\n", "const CLEAR_OF_SEAL := 0.0\n"),
    ("m31", "the door camera in the trailer", CUT, "const DOOR_EYE := Vector3(-37.8, 1.7, 19.4)\n", "const DOOR_EYE := Vector3(-38.3, 1.6, 17.5)\n"),
    ("m32", "his way by the load as before", SHED, "\tVector3(-46.2, 1.3, 17.3), Vector3(-46.2, 1.3, 15.6), Vector3(-45.3, 1.3, 12.4)]\n", "\tVector3(-46.35, 1.3, 17.3), Vector3(-46.35, 1.3, 15.6), Vector3(-45.3, 1.3, 12.4)]\n"),
    ("m33", "his left hand off the hasp", WORKER, "\t\t\tleft = [_on_hasp(), _at_hasp(LEFT_WRIST, _steady_turn())]\n", "\t\t\tleft = [0.0, Transform3D.IDENTITY]\n"),
    ("m34", "standing as near the doors as before", WORKER, "const AT_HASP := Vector3(0.0, 0.0, 3.66)\n", "const AT_HASP := Vector3(0.0, 0.0, 3.32)\n"),
    ("m35", "the log at 1/100 of its size again", WORKER, "\t_held = Transform3D(HOLD.basis.scaled(Vector3.ONE * scale), HOLD.origin * scale)\n", "\t_held = HOLD\n"),
    ("m36", "his way along the dock face as before", SHED, "\tVector3(-47.9, 0.0, 21.4)]\n", "\tVector3(-46.0, 0.0, 20.25), Vector3(-47.3, 0.0, 20.25)]\n"),
    ("m37", "the wheel guides from 0.5 m as before", "features/environments/industrial_loop/transfer_yard.gd", "const GUIDE := Vector3(0.15, 0.2, 3.0)\nconst GUIDE_FROM := 21.0\n", "const GUIDE := Vector3(0.15, 0.2, 3.5)\nconst GUIDE_FROM := 20.5\n"),
    ("m40", "the log kept in his hand at the hasp", WORKER, "\t\t\t_onto_step()\n", "\t\t\tpass\n"),
    ("m41", "the log over the step's edge as before", WORKER, "const LOG_ON_STEP := Vector3(0.18, 0.538, 2.83)\n", "const LOG_ON_STEP := Vector3(0.18, 0.538, 2.955)\n"),
    ("m42", "sealing standing upright", WORKER, "const RISE_FROM := 1.6\n", "const RISE_FROM := 3.2\n"),
    ("m44", "his hands left turned as the clip has them", WORKER, "\tturn.active = on > 0.0\n", "\tturn.active = false\n"),
    ("m45", "no tug", WORKER, "const TUG_BY := 0.012\n", "const TUG_BY := 0.0\n"),
    ("m46", "no twist", WORKER, "const TWIST_BY := deg_to_rad(25.0)\n", "const TWIST_BY := 0.0\n"),
    ("m47", "the pen's tip off his fingers", WORKER, "const TIP_ON := 0.02\n", "const TIP_ON := 0.12\n"),
    ("m48", "the log held before him walking", WORKER, "\tvar share := 0.0\n", "\tvar share := 1.0\n"),
    ("m49", "no paper shot", CUT, "\tvar reading := bool(_worker.call(\"writing\"))\n", "\tvar reading := false\n"),
    ("m51", "no tick drawn", WORKER, "\tif drawn > _tick:\n", "\tif false:\n"),
    ("m53", "his hand off the seal checking", WORKER, "const ON_THE_SEAL := Vector3(0.025, 0.0, 0.09)\n", "const ON_THE_SEAL := Vector3(0.025, 0.0, 0.25)\n"),
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
