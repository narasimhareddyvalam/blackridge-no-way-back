"""Step 2f, step 2 of #253 (#254-#257): the captured climb, the rebuilt stair, the heavy pull. On an APFS clone of
game/ (argv[1]); logs under argv[2]; argv[3] picks which; the clone gets its own HOME. Each
mutation undoes one part and its test must exit 1 on the check named. The clone's file is
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
GAIT = "features/characters/driver/push_gait.gd"
CLEAR = "features/characters/driver/handle_clear.gd"
JACK = "features/environments/industrial_loop/pallet_jack.gd"
STAIR = "test_stair.gd"
BUILDING = "features/environments/industrial_loop/transfer_building.gd"
SEALING = "test_sealing.gd"
LOADING = "test_loading.gd"
MUTATIONS = [
    ("mutation_never_the_climb", STEPS, STAIR, "S12 up",
     [("\tvar wanted := CLIMB_GAIT if sense > 0 and", "\tvar wanted := WALK_GAIT if sense > 0 and")]),
    ("mutation_ankle_on_the_riser_line", STEPS, STAIR, "S3 up",
     [("\t\treturn maxf(index * tread - TOE_REACH - TOE_ROOM, (index - 1) * tread + ON_TREAD)",
       "\t\treturn index * tread - TOE_REACH - TOE_ROOM")]),
    ("mutation_a_tread_skipped", STEPS, STAIR, "S4 running up",
     [("\tif (beyond == 0 and other > 0 and other < int(stair[\"risers\"])) or beyond > 1:",
       "\tif beyond == 0 and other > 0 and other < int(stair[\"risers\"]):")]),
    ("mutation_toes_into_the_tread", STEPS, STAIR, "S5 up",
     [("\t\t\tif bool(gait[\"lifted\"]) else _heel_up(side)", "\t\t\tif bool(gait[\"lifted\"]) else 0.0")]),
    ("mutation_bounce_over_the_top", DRIVER, STAIR, "S1 up",
     [("\telif climbing and _steps.on_incline(global_position):", "\telif climbing and grounded:")]),
    ("mutation_running_into_the_stair", DRIVER, STAIR, "S2 running up",
     [("\t\t\t_steps.pace_weight(global_position))", "\t\t\t_steps.influence)")]),
    ("mutation_camera_eases_in_hard", DRIVER, STAIR, "S2 down",
     [("const BOOM_IN := 7.0", "const BOOM_IN := 8.0")]),
    ("mutation_pushed_back_out", GAIT, LOADING, "H2: pulling",
     [("\t_clip = \"PullBack\" if _inside else \"WalkBack\"", "\t_clip = \"Push\" if _inside else \"WalkBack\""),
      ("\t_clip = \"PullBack\" if _inside or (_clip == \"PullBack\" and lead < -CAUGHT_UP) else \"WalkBack\"",
       "\t_clip = \"Push\" if _inside or (_clip == \"Push\" and lead < -CAUGHT_UP) else \"WalkBack\""),
      ("\t_play(_clip, blend, -_pace / clip_speed)", "\t_play(_clip, blend, _pace / PUSH_SPEED if _clip == \"Push\" else -_pace / clip_speed)")]),
    ("mutation_head_through_the_roof", CLEAR, LOADING, "H2: pulling",
     [("\twhile wanted > -DUCK_MOST and _top(points, left, wanted) + HAIR > ceiling \\\n", "\twhile false and _top(points, left, wanted) + HAIR > ceiling \\\n")]),
    ("mutation_ducks_into_the_handle", CLEAR, LOADING, "H11",
     [("\t\t\tand (pieces.size() < 2 or _clear(points, left, wanted - TRY) >= MARGIN):", "\t\t\tand true:")]),
    ("mutation_the_doorway_forgotten", JACK, LOADING, "H2: pulling",
     [("\t\tvar by_door := van.to_local(driver.global_position).z > VAN_REAR - BY_THE_DOOR", "\t\tvar by_door := false")]),
    ("mutation_no_camera_walls", BUILDING, SEALING, "H4: closing them in the court",
     [("\t\t\t_camera_wall(index)\n", "")]),
    ("mutation_jack_meets_camera_walls", JACK, LOADING, "H2",
     [("const ALL_BUT_CAMERA := 0xFFFFFFFF & ~8", "const ALL_BUT_CAMERA := 0xFFFFFFFF")]),
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
