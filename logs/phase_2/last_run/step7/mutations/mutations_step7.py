"""Mission 3's step 7, Lily and Adrian (#359): each on an APFS clone of game/, then test_rescue.gd at 60 fps
on the clone, three at a time.
Usage: python3 -I mutations_guidance.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TESTS = ["test_rescue.gd"]
MAP = "features/ui/driving_hud/mission_map.gd"
APP = "app/first_drive.gd"
HUD = "features/ui/driving_hud/driving_hud.gd"
SUVF = "features/vehicles/scripted_suv/scripted_suv.gd"
GUARD = "features/characters/patrol_guard/patrol_guard.gd"
ESC = "features/missions/the_wrong_cargo/escape.gd"
COMPOUND = "features/environments/industrial_loop/compound.gd"
YARD = "features/environments/industrial_loop/container_yard.gd"
MARKS = "features/ui/driving_hud/seen_marks.gd"
MARKER = "features/ui/driving_hud/objective_marker.gd"
CARGO = "features/missions/the_wrong_cargo/the_wrong_cargo.gd"
ROUTE = "features/missions/night_freight/first_drive.gd"
OPENING = "features/missions/the_wrong_cargo/opening_cutscene.gd"
RUN = "features/missions/last_run/last_run.gd"
LOOP = "features/environments/industrial_loop/industrial_loop.gd"
FLATS = "features/environments/harbour_flats/harbour_flats.gd"
FRONT = "features/environments/harbour_flats/waterfront.gd"
AMBUSH = "features/missions/last_run/ambush.gd"
SCENES = "features/missions/last_run/story_scenes.gd"
CONVOY = "features/missions/last_run/convoy.gd"
FIELD = "features/environments/harbour_flats/airfield.gd"
HUD = "features/ui/driving_hud/driving_hud.gd"
ENC = "features/missions/last_run/hangar_encounter.gd"
DRV = "features/characters/driver/driver.gd"
LILY = "features/characters/lily/lily.gd"
GUARD = "features/characters/syndicate_man/armed_guard.gd"
SUVF = "features/vehicles/scripted_suv/scripted_suv.gd"
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ('r1', 'her hand never taken', RUN, '\t\tlily.call("lead", driver)\n', ''),
    ('r2', 'he runs on ahead of her', DRV, '\t\tif lead_pace > 0.0:\n\t\t\tpace = lead_pace\n', ''),
    ('r3', 'her arm never up to his hand', LILY, '\t_arm.influence = move_toward(_arm.influence, 1.0 if holding else 0.0, 4.0 * delta)', '\t_arm.influence = 0.0'),
    ('r4', 'no scene at Maya', RUN, 'const AT_MAYA := 4.5', 'const AT_MAYA := 0.0'),
    ('r5', 'Adrian never draws', RUN, '\t\tadrian.call("draw_at", driver.global_position + Vector3.UP * 1.4)\n', ''),
    ('r6', 'Ethan never fires', RUN, '\t\tgun.call("pull", driver.call("muzzle"), chest, skip)\n', ''),
    ('r7', 'Lily left out of the office', RUN, '\tlily.visible = stage == 4\n', '\tlily.visible = false\n'),
    ('r8', 'the men still about at stage 4', ENC, '\t\tguard.visible = on\n', '\t\tguard.visible = true\n'),
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
