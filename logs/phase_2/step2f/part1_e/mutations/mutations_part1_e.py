"""Step 2f part 1, E (#250): the jack's handle never in Ethan, his hands closed round it. On an APFS clone of
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
JACK = "features/environments/industrial_loop/pallet_jack.gd"
GAIT = "features/characters/driver/push_gait.gd"
CLEAR = "features/characters/driver/handle_clear.gd"
GRIP = "features/characters/driver/hand_grip.gd"
DRIVER = "features/characters/driver/driver.gd"
LOADING = "test_loading.gd"
MUTATIONS = [
    ("mutation_back_never_straightens", JACK, LOADING, "H11",
     [('\tdriver.call("keep_clear_of", _handle_pieces(hand), ROD, roof)\n', '\tpass\n')]),
    ("mutation_stooped_hands_in_his_chest", GAIT, LOADING, "H11",
     [("const GRIP_STOOPED := Vector2(0.47, 0.96)", "const GRIP_STOOPED := Vector2(0.3, 0.95)")]),
    ("mutation_straightens_through_the_roof", CLEAR, LOADING, "H2: pulling",
     [("\t\t\t\tand _top(points, left, wanted + TRY) + HAIR <= ceiling:\n", "\t\t\t\tand true:\n")]),
    ("mutation_fingers_never_close", DRIVER, LOADING, "H12",
     [("\t_fingers.amount = _hold.influence\n", "\t_fingers.amount = 0.0\n")]),
    ("mutation_fingers_curl_as_the_clip_holds_them", GRIP, LOADING, "H12",
     [("\t\t_straighten(skeleton, side)\n", "")]),
    ("mutation_hand_not_turned_to_the_bar", GRIP, LOADING, "H12",
     [("\t\t_turn_hand(skeleton, index)\n", "")]),
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
