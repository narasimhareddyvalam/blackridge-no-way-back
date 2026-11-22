"""Mission 3's step 8, the ending (#359): each on an APFS clone of game/, then test_ending.gd at 60 fps
on the clone, three at a time.
Usage: python3 -I mutations_guidance.py <scratch> <out> [names]"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
TESTS = ["test_ending.gd"]
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
EPI = "features/missions/last_run/epilogue.gd"
GUARD = "features/characters/syndicate_man/armed_guard.gd"
SUVF = "features/vehicles/scripted_suv/scripted_suv.gd"
TESTS_BY = {}
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ('e1', 'no reunion after the gate', RUN, '\tif _ending_phase == "":\n\t\t_start_reunion()\n\t\treturn\n', '\tif _ending_phase == "":\n\t\treturn\n'),
    ('e2', 'no statement card', SCENES, '\t\t{"name": "reunion_statement", "seconds": 5.5, "black": true, "card": STATEMENT,', '\t\t{"name": "reunion_statement", "seconds": 5.5, "black": true,'),
    ('e3', 'the title before the black', EPI, 'const TITLE_AT := 75.2', 'const TITLE_AT := 72.0'),
    ('e4', 'black held only a moment', EPI, 'const TITLE_AT := 75.2', 'const TITLE_AT := 73.6'),
    ('e5', 'a message out of order', EPI, '[60.6, true, "Yes."]', '[57.0, true, "Yes."]'),
    ('e6', 'rain in the sunlit home', EPI, '\t_light_the_world()\n', '\t_light_the_world()\n\tworld.add_child(GPUParticles3D.new())\n'),
    ('e7', "the night's rain left playing", EPI, '\t\tAudioServer.set_bus_mute(AudioServer.get_bus_index(bus), true)\n', '\t\tpass\n'),
    ('e8', 'never back to the title', APP, '\t_back_to_title()\n\thud.reveal(TITLE_FADE_IN)\n\n\n## Whether Ethan stands armed', '\thud.reveal(TITLE_FADE_IN)\n\n\n## Whether Ethan stands armed'),
    ('e9', "Lily's words changed", EPI, '"Uncle Ethan! You promised we\'d go for a drive!"', '"Uncle Ethan! You said we\'d go for a drive!"'),
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
