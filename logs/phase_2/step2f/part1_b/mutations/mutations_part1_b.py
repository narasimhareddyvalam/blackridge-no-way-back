"""Step 2f part 1, B (#245-#247): the rear doors by Ethan's hands. On an APFS clone of game/
(argv[1]); logs under argv[2]; argv[3] picks which (a comma list of indexes); the clone gets its
own HOME. Each mutation undoes one part and its test must exit 1 on the check named. The clone's
file is restored byte for byte after each."""
import os
import pathlib
import subprocess
import sys

CLONE = pathlib.Path(sys.argv[1])
LOGS = pathlib.Path(sys.argv[2])
PICK = [int(i) for i in sys.argv[3].split(",")]
GODOT = "/Applications/Godot.app/Contents/MacOS/Godot"
HANDS = "features/vehicles/freight_van/rear_door_hands.gd"
DRIVER = "features/characters/driver/driver.gd"
APP = "app/first_drive.gd"
DOORS = "test_rear_doors.gd"
SEALING = "test_sealing.gd"
MUTATIONS = [
    ("mutation_no_hand_on_the_door", HANDS, DOORS, "R1 opening",
     [("\t_driver.call(\"door_hand\", hand, _held[\"grip\"], _hand)\n",
       "\t_driver.call(\"door_hand\", hand, _held[\"grip\"], 0.0)\n")]),
    ("mutation_pulled_before_reached", HANDS, DOORS, "R1 opening",
     [("\t\tplan.append({\"do\": \"reach\", \"door\": door, \"face\": \"outer\", \"hand\": hand})\n"
       "\t\tplan.append({\"do\": \"turn\", \"door\": door, \"face\": \"outer\", \"hand\": hand, \"to\": PULL_TO,",
       "\t\tplan.append({\"do\": \"turn\", \"door\": door, \"face\": \"outer\", \"hand\": hand, \"to\": PULL_TO,")]),
    ("mutation_no_free_swing", HANDS, DOORS, "R5",
     [("\t_spins[door] = maxf(speed, 2.0 * PUSH_BY / PUSH_SECONDS)\n", "\t_spins[door] = 0.0\n")]),
    ("mutation_left_door_first", HANDS, DOORS, "R1 opening: the left",
     [("\tfor door in [1, 0]:\n", "\tfor door in [0, 1]:\n")]),
    ("mutation_counted_open_at_once", HANDS, DOORS, "R4 opening",
     [("\t_driver.set(\"handling\", true)\n", "\t_driver.set(\"handling\", true)\n\tvan.set(\"rear_doors_open\", opening)\n")]),
    ("mutation_stands_in_the_door", HANDS, DOORS, "R2",
     [("const STAND := 0.36\n", "const STAND := 0.05\n")]),
    ("mutation_hops_into_stance", HANDS, DOORS, "R6 closing",
     [("\t_guide = _guide.move_toward(target, SHORT_PACE * delta)\n", "\t_guide = target\n")]),
    ("mutation_no_kerb_step_at_doors", DRIVER, SEALING, "H4",
     [("\t\tvelocity.y = -0.5 if grounded else -18.0 * delta\n\t\t_step_up(Vector3(velocity.x, 0.0, velocity.z))\n",
       "\t\tvelocity.y = -0.5 if grounded else -18.0 * delta\n")]),
    ("mutation_no_lean", DRIVER, DOORS, "R1 opening",
     [("const LEAN_MOST := 0.22\n", "const LEAN_MOST := 0.0\n")]),
    ("mutation_silent_doors", HANDS, DOORS, "R9",
     [("\t\t\t\t\tvan.emit_signal(\"rear_door_sounded\", \"stay\")\n", ""),
      ("\t\t\t\tvan.emit_signal(\"rear_door_sounded\", \"latch\")\n", "")]),
    ("mutation_close_round_the_corner", HANDS, DOORS, "R2 closing",
     [("\t\tvar way: Array[Vector3] = [corner, lane]\n", "\t\tvar way: Array[Vector3] = [corner]\n")]),
    ("mutation_stance_in_the_van", HANDS, DOORS, "R4 opening",
     [("\tif off.length() >= KEEP_OFF:\n\t\treturn at\n", "\treturn at\n")]),
    ("mutation_e_breaks_in", APP, DOORS, "R4",
     [("\t\telif van.rear_doors_busy():\n\t\t\treturn\n", "")]),
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
