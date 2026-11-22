"""Step 2f part 1, A (#245-#246): Ethan smooth on foot. On an APFS clone of game/ (argv[1]);
logs under argv[2]; argv[3] picks which (a comma list of indexes); the clone gets its own HOME.
Each mutation undoes one part and its test must exit 1 on the check named. The clone's file is
restored byte for byte after each."""
import os
import pathlib
import subprocess
import sys

CLONE = pathlib.Path(sys.argv[1])
LOGS = pathlib.Path(sys.argv[2])
PICK = [int(i) for i in sys.argv[3].split(",")]
GODOT = "/Applications/Godot.app/Contents/MacOS/Godot"
STEPS = "features/characters/driver/stair_steps.gd"
DRIVER = "features/characters/driver/driver.gd"
DOCK = "features/environments/industrial_loop/dock_access.gd"
APP = "app/first_drive.gd"
STAIR = "test_stair.gd"
MUTATIONS = [
    ("mutation_steps_without_incline", DOCK, STAIR, "S1 up",
     [("\t\tBuild.box(self, Vector3(x, top / 2.0, z), Vector3(STAIR.size.x, top, TREAD),\n"
       "\t\t\tconcrete).name = \"DockStairStep\"\n",
       "\t\t_solid(body, Vector3(x, top / 2.0, z), Vector3(STAIR.size.x, top, TREAD), concrete,\n"
       "\t\t\t\"DockStairStep\")\n"),
      ("\t_incline(body, x, foot)\n", "")]),
    ("mutation_steps_up_slopes", DRIVER, STAIR, "S9",
     [("\tif ahead.get_normal().y >= cos(floor_max_angle):\n\t\treturn\n", "")]),
    ("mutation_pushed_down_the_incline", DRIVER, STAIR, "S1 up",
     [("\telif climbing and grounded:\n\t\tvelocity.y = _steps.climb(global_position, velocity)\n",
       "")]),
    ("mutation_no_stair_given", APP, STAIR, "S4 up",
     [("\tdriver.set(\"stairs\", stairs)\n", "")]),
    ("mutation_walk_rate_up_the_stair", STEPS, STAIR, "S6 up",
     [("const UP_CADENCE := 76.0\n", "const UP_CADENCE := 116.0\n")]),
    ("mutation_no_glide_up_a_step", DRIVER, STAIR, "S7",
     [("\t_glide -= _step_top - global_position.y\n", "")]),
    ("mutation_camera_snaps_out", DRIVER, STAIR, "S8",
     [("\t\t_shown = minf(_shown + _shown_speed * delta, reach)\n", "\t\t_shown = reach\n")]),
    ("mutation_camera_no_look_ahead", DRIVER, STAIR, "S2 down",
     [("const LOOK_AHEAD := 0.6\n", "const LOOK_AHEAD := 0.0\n")]),
    ("mutation_feet_left_as_walked", DRIVER, STAIR, "S5",
     [("\t\t_soles.weights[side] = 1.0\n", "\t\t_soles.weights[side] = 0.0\n")]),
    ("mutation_planted_foot_creeps", STEPS, STAIR, "S4",
     [("const STANCE_SLACK := 0.008\n", "const STANCE_SLACK := 0.0\n")]),
    ("mutation_heel_never_lifts", STEPS, STAIR, "S5",
     [("\t\tvar lifted := maxf(animated[side].y - ground - ANKLE_UP - STANCE_SLACK, 0.0)\n",
       "\t\tvar lifted := 0.0\n")]),
    ("mutation_any_foot_first", DRIVER, STAIR, "S10",
     [("\t\tvar start := _steps.start_frame(direction)\n", "\t\tvar start := -1.0\n")]),
    ("mutation_swing_from_heel_up", STEPS, STAIR, "S10",
     [("\t_lift_falls[side] = falls[side]\n", "\t_lift_falls[side] = HEEL_UP_FALL\n")]),
    ("mutation_hips_not_lowered", STEPS, STAIR, "S",
     [("\tdrop = _settled + _reach_drop * influence\n", "\tdrop = 0.0\n")]),
]
env = {**os.environ, "HOME": str(CLONE.parent / (CLONE.name + "-home"))}
pathlib.Path(env["HOME"]).mkdir(exist_ok=True)
for index in PICK:
    name, rel, test, expected, edits = MUTATIONS[index]
    path = CLONE / rel
    original = path.read_bytes()
    text = original.decode("utf-8")
    for old, new in edits:
        assert text.count(old) == 1, f"{name}: {old[:60]!r}"
        text = text.replace(old, new)
    path.write_text(text, encoding="utf-8")
    out = LOGS / name
    out.mkdir(parents=True, exist_ok=True)
    log = out / f"{test[:-3]}_60fps.log"
    try:
        result = subprocess.run(["timeout", "400", GODOT, "--headless", "--path", str(CLONE),
                                 "--script", f"res://tests/{test}", "--fixed-fps", "60"],
                                env=env, capture_output=True, text=True)
        log.write_text(result.stdout + result.stderr)
    finally:
        path.write_bytes(original)
    lines = log.read_text().splitlines()
    status = result.returncode
    if any("SCRIPT ERROR" in line or "SHADER ERROR" in line for line in lines):
        status = 1
    failed = [line for line in lines if line.startswith("FAIL")]
    summary = [line for line in lines if "RESULT" in line]
    hit = any(line.startswith("FAIL: " + expected) for line in failed)
    scripted = any("SCRIPT ERROR" in line for line in lines)
    print(f"{name}: exit {status}; {summary[-1] if summary else 'no result'}; "
          f"fails on its check: {hit}; script error: {scripted}")
    for line in failed:
        print("    " + line[:200])
    sys.stdout.flush()
restored = all((CLONE / m[1]).read_bytes() == (pathlib.Path("game") / m[1]).read_bytes()
               for m in MUTATIONS)
print("clone restored byte for byte after each" if restored else "CLONE DIFFERS FROM game/")
