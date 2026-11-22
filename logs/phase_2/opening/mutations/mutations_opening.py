"""The opening cutscene (#357): each on an APFS clone of game/, then test_opening.gd at 60 fps,
three at a time.
Usage: python3 -I mutations_opening.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TESTS = ["test_opening.gd"]
DIRECTOR = "features/cinematics/cutscene_director.gd"
OPENING = "features/missions/night_freight/opening_cutscene.gd"
APP = "app/first_drive.gd"
TESTS_BY = {"p7": ["test_on_foot.gd"]}
DRIVER = "features/characters/driver/driver.gd"
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("p1", "no opening on a new game", APP, "\t_begin_on_foot()\n\t_play_opening()\n", "\t_begin_on_foot()\n"),
    ("p2", "Ethan's keys not held", DIRECTOR, "\tdriver.set(\"held\", true)\n", ""),
    ("p3", "the game's title in the opening", OPENING, 'const TITLE := ["NIGHT FREIGHT", "MISSION ONE"]', 'const TITLE := ["BLACKRIDGE: NO WAY BACK", "MISSION ONE"]'),
    ("p4", "hard cuts, no dip", DIRECTOR, "\tfilm.set_dip(_dip_at(each, seconds, hold))\n", ""),
    ("p5", "skipping leaves the HUD hidden", DIRECTOR, "\tif is_instance_valid(_hud):\n\t\t_hud.call(\"set_cinematic\", false)\n", ""),
    ("p6", "ending on its own camera, not the player's", OPENING, '"to": "player"}', '"to": _look(crane_high, crane_at)}'),
    ("p7", "rain falling through Ethan", DRIVER, "\tadd_child(shield)\n", ""),
    ("p8", "the opening on every restart", APP, "\tif new_game:\n\t\t_play_opening()\n", "\t_play_opening()\n"),
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
