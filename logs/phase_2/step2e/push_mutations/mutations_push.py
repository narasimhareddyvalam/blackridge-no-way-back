"""Step 2e's push mutations (#240), on an APFS clone of game/ (argv[1]); logs under argv[2];
argv[3] picks which (a comma list of indexes); the clone gets its own HOME. Each mutation undoes
one part of Ethan's push and test_loading.gd must exit 1 on the check named. The clone's file is
restored byte for byte after each."""
import os
import pathlib
import subprocess
import sys

CLONE = pathlib.Path(sys.argv[1])
LOGS = pathlib.Path(sys.argv[2])
PICK = [int(i) for i in sys.argv[3].split(",")]
GODOT = "/Applications/Godot.app/Contents/MacOS/Godot"
JACK = "features/environments/industrial_loop/pallet_jack.gd"
GAIT = "features/characters/driver/push_gait.gd"
DRIVER = "features/characters/driver/driver.gd"
TEST = "test_loading.gd"
ZEROS = "[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,\n\t0.0, 0.0, 0.0, 0.0, 0.0]"
MUTATIONS = [
    ("mutation_fixed_pace", JACK, "H2: on the dock the jack goes at the pace",
     [("\tvar carry := moved.y\n",
       "\tvar carry := signf(drive) * 0.9 * delta if not is_zero_approx(moved.y) else 0.0\n")]),
    ("mutation_no_hands", DRIVER, "H2: on the dock the jack goes at the pace",
     [("\t_hold.active = _hold.influence > 0.0\n", "\t_hold.active = false\n")]),
    ("mutation_no_push_stop", GAIT, "H2: W let go on the dock",
     [("\tgait = Gait.STOP\n\t_player.play(\"PushStop\", BLEND)\n",
       "\tgait = Gait.STAND\n\t_play(\"Idle\", BLEND, 1.0)\n\tif _stop_rate > 0.0:\n\t\treturn\n"
       "\t_player.play(\"PushStop\", BLEND)\n")]),
    ("mutation_van_at_dock_rate", GAIT, "H2: under the van's low roof",
     [("const VAN_RATE := 1.0\n", "const VAN_RATE := 1.5\n")]),
    ("mutation_stands_in_van", GAIT, "H2: against the bulkhead",
     [("\tif _inside and _clip == \"Push\":\n\t\t_player.speed_scale = 0.0\n\t\thands = 1.0\n"
       "\t\treturn\n", "")]),
    ("mutation_instant_start", GAIT, "H2: on the dock the jack goes at the pace",
     [("const LOAD_ACCEL := 0.45\n", "const LOAD_ACCEL := 45.0\n")]),
    ("mutation_stop_without_travel", GAIT, "H2: W let go on the dock",
     [("[0.0, 0.076, 0.157, 0.253, 0.357, 0.458, 0.524, 0.622, 0.708,\n"
       "\t0.786, 0.815, 0.779, 0.754, 0.756]", ZEROS)]),
    ("mutation_no_lead", JACK, "H2: under the van's low roof",
     [("\tvar lead := clampf((PUSH_REACH - _reach) * LEAD_GAIN, 0.0, 1.0)\n",
       "\tvar lead := 0.0\n")]),
    ("mutation_slides_off_the_plate", DRIVER, "H2: under the van's low roof",
     [("\t\tfloor_constant_speed = value\n", ""),
      ("\tif went.length() > Vector2(flat.x, flat.z).length():\n", "\tif false:\n")]),
    ("mutation_pulls_upright_in_van", GAIT, "H2: pulling the jack back out",
     [("\t_clip = \"Push\" if _inside or str(_player.current_animation) == \"Push\" else \"WalkBack\"\n",
       "\t_clip = \"WalkBack\"\n")]),
]
env = {**os.environ, "HOME": str(CLONE.parent / (CLONE.name + "-home"))}
pathlib.Path(env["HOME"]).mkdir(exist_ok=True)
for index in PICK:
    name, rel, expected, edits = MUTATIONS[index]
    path = CLONE / rel
    original = path.read_bytes()
    text = original.decode("utf-8")
    for old, new in edits:
        assert text.count(old) == 1, f"{name}: {old[:60]!r}"
        text = text.replace(old, new)
    path.write_text(text, encoding="utf-8")
    out = LOGS / name
    out.mkdir(parents=True, exist_ok=True)
    log = out / f"{TEST[:-3]}_60fps.log"
    try:
        result = subprocess.run(["timeout", "500", GODOT, "--headless", "--path", str(CLONE),
                                 "--script", f"res://tests/{TEST}", "--fixed-fps", "60"],
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
    hit = any(expected in line for line in failed)
    scripted = any("SCRIPT ERROR" in line for line in lines)
    print(f"{name}: exit {status}; {summary[-1] if summary else 'no result'}; "
          f"fails on its check: {hit}; script error: {scripted}")
    for line in failed:
        print("    " + line[:200])
    sys.stdout.flush()
restored = all((CLONE / m[1]).read_bytes() == (pathlib.Path("game") / m[1]).read_bytes()
               for m in MUTATIONS)
print("clone restored byte for byte after each" if restored else "CLONE DIFFERS FROM game/")
