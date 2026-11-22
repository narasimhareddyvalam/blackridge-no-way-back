"""#281's mutations: each on an APFS clone of game/ (with tools/data beside it), then
test_headlights.gd at 60 fps on the clone. Optional third argument: the
mutations to run, comma-separated (their lines are added to SUMMARY.txt). Usage: python3 -I mutations.py <scratch> <out>"""
import pathlib, shutil, subprocess, sys
REPO = pathlib.Path.cwd()
PRES = "features/vehicles/freight_van/van_presentation.gd"
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 else None
MUTATIONS = [
    ("m1", "the low beams aimed 2 degrees down, as before", PRES,
     "const LOW_BEAM_TILT := -1.25", "const LOW_BEAM_TILT := -2.0"),
    ("m2", "the old pattern back (git's low_beam_pattern.png)", None, None, None),
    ("m3", "no mist on the headlights", PRES,
     "\t\t_beam_mist(headlight)\n\t\t_aim_beam(headlight, false)",
     "\t\t_beam_mist(headlight)\n\t\theadlight.get_node(\"Mist\").queue_free()\n\t\t_aim_beam(headlight, false)"),
    ("m4", "the beams' air scattering twice the lamps'", PRES,
     "const BEAM_MIST_SCATTERING := 0.016", "const BEAM_MIST_SCATTERING := 0.032"),
    ("m5", "the mist keeps the low beam's pattern on high beams", PRES,
     '\tair.set_shader_parameter("pattern", headlight.light_projector)\n', ""),
    ("m6", "a stale import: the old pattern's imported copy, the new PNG", "stale", None, None),
    ("m7", "high beams aimed 2 degrees down, as before", PRES,
     "const HIGH_BEAM_TILT := 0.0", "const HIGH_BEAM_TILT := -2.0"),
    ("m8", "high beams at 850, as before", PRES,
     "const HIGH_BEAM_ENERGY := 1147.0", "const HIGH_BEAM_ENERGY := 850.0"),
    ("m9", "the lamp one flat glow again", PRES,
     "\tif lens.material_override != _lens_on:\n\t\t_lens_on = lit_lens(lens)\n\tlight_lens(_lens_on, low, high)",
     "\tlens.material_override = Build.luminous(Color(\"e9ebdc\"), 2.0) if low else null"),
    ("m10", "the oncoming van's lamps at 650 on both beams", "features/vehicles/oncoming_van/oncoming_van.gd",
     "\t\tlamp.light_energy = VanPresentation.HIGH_BEAM_ENERGY if value \\\n\t\t\telse VanPresentation.LOW_BEAM_ENERGY",
     "\t\tlamp.light_energy = 650.0"),
    ("m11", "the old high-beam pattern back (git's high_beam_pattern.png)", "old_high", None, None),
]
scratch, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
summary = ["#281 mutations, each on an APFS clone, test_headlights.gd at 60 fps:"]
for name, what, path, old, new in MUTATIONS:
    if ONLY and name not in ONLY:
        continue
    root = scratch / name
    shutil.rmtree(root, ignore_errors=True)
    (root / "tools").mkdir(parents=True)
    subprocess.run(["cp", "-cR", str(REPO / "game"), str(root / "game")], check=True)
    subprocess.run(["cp", "-cR", str(REPO / "tools/data"), str(root / "tools/data")], check=True)
    if path == "stale":
        imported = "game/.godot/imported/low_beam_pattern.png-a545f8a5032b7f989084dcb48737e340.ctex"
        shutil.copy(scratch / "m2" / imported, root / imported)
    elif path == "old_high":
        png = subprocess.run(["git", "show", "HEAD:game/features/vehicles/freight_van/art/high_beam_pattern.png"],
                             capture_output=True, check=True).stdout
        (root / "game/features/vehicles/freight_van/art/high_beam_pattern.png").write_bytes(png)
    elif path is None:
        png = subprocess.run(["git", "show", "HEAD:game/features/vehicles/freight_van/art/low_beam_pattern.png"],
                             capture_output=True, check=True).stdout
        (root / "game/features/vehicles/freight_van/art/low_beam_pattern.png").write_bytes(png)
    else:
        target = root / "game" / path
        text = target.read_text()
        assert text.count(old) == 1, name
        target.write_text(text.replace(old, new))
    subprocess.run(["diff", "-ru", str(REPO / "game"), str(root / "game"), "-x", ".godot"],
                   stdout=open(out / f"{name}.diff", "w"))
    home = scratch / f"{name}-home"
    home.mkdir(exist_ok=True)
    if path != "stale":
        subprocess.run(["/Applications/Godot.app/Contents/MacOS/Godot", "--headless", "--path",
                    str(root / "game"), "--import"], env={"HOME": str(home), "PATH": "/usr/bin:/bin"},
                   capture_output=True, timeout=300)
    run = subprocess.run(["/Applications/Godot.app/Contents/MacOS/Godot", "--headless", "--path",
                          str(root / "game"), "--script", "res://tests/test_headlights.gd",
                          "--fixed-fps", "60"], env={"HOME": str(home), "PATH": "/usr/bin:/bin"},
                         capture_output=True, text=True, timeout=200)
    (out / f"{name}.log").write_text(run.stdout + run.stderr)
    fails = [l[6:] for l in run.stdout.splitlines() if l.startswith("FAIL: ")]
    result = next((l for l in run.stdout.splitlines() if "RESULT" in l), "no result")
    summary.append(f"{name}  {what:<55} exit {run.returncode}, {result.split(': ')[-1]}"
                   + "".join(f"\n      FAIL: {f[:110]}" for f in fails))
with (out / "SUMMARY.txt").open("a" if ONLY else "w") as handle:
    handle.write("\n".join(summary[1:] if ONLY else summary) + "\n")
print("\n".join(summary))
