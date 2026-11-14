"""Step 2f part 1, C (#245-#247): the loading's objective only ever going on. On an APFS clone of
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
MISSION = "features/missions/the_wrong_cargo/the_wrong_cargo.gd"
LOADING = "test_loading.gd"
MUTATIONS = [
    ("mutation_no_pallet_on_the_lift", JACK, LOADING, "H10",
     [("\t\t\t\tand at.y > -0.05 and at.y < 0.4:\n\t\t\treturn stack\n",
       "\t\t\t\tand at.y > -0.05 and at.y < 0.4:\n\t\t\treturn null\n")]),
    ("mutation_lowered_lift_says_lower", MISSION, LOADING, "H10",
     [("\t\tif bool(lift.call(\"at_bottom\")):\n\t\t\treturn [\"ROLL THE PALLET IN\",",
       "\t\tif false:\n\t\t\treturn [\"ROLL THE PALLET IN\",")]),
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
