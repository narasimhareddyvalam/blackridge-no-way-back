"""Makes the south valley road's gas station and main street (#267, part C) game files from the
models in source_assets/sketchfab (CC BY 4.0), with tools/art/convert_depot_models.py's helpers.

gas_pump: SavinienBerault's "Gas pump", an unbranded two-hose dispenser (REGULAR and DIESEL), its
    lit and unlit display materials kept, 1.9 m tall (dispensers stand 1.8-2.0 m), its base at
    the origin, its front (the display) toward +Z.
payphone: evan4129's "Pay phone Scan MEDPOLY", a scanned US pedestal payphone on its post, 2.0 m
    to the top of its rod, reduced to about 9,000 triangles.
sedan: Daniel Zhabotinsky's "Fairheaven LT '80", a generic early-1980s American sedan, 5.0 m long
    as its source has it, reduced to about 9,000 triangles, its front toward +Z.
Textures larger than 1024 pixels are halved until they fit, saved as JPEG or PNG as they need.

Usage, from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 \\
        --python tools/art/convert_town_models.py -- gas_pump payphone sedan
"""

import importlib.util
import pathlib
import sys

ROOT = pathlib.Path.cwd()
TARGET = ROOT / "game/features/environments/industrial_loop/art/town"
PAYPHONE_TO = 9000
SEDAN_TO = 9000


def helpers():
    spec = importlib.util.spec_from_file_location(
        "convert_depot_models", ROOT / "tools/art/convert_depot_models.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.TARGET = TARGET
    return module


DEPOT = helpers()


def gas_pump() -> None:
    meshes = DEPOT.load("17_gas_pump")
    DEPOT.standing(meshes)
    DEPOT.finish(meshes, "gas_pump", "GasPump")


def payphone() -> None:
    meshes = DEPOT.load("18_payphone")
    DEPOT.standing(meshes)
    DEPOT.slim(meshes, meshes, PAYPHONE_TO + 500, PAYPHONE_TO)
    DEPOT.finish(meshes, "payphone", "Payphone")


def sedan() -> None:
    meshes = DEPOT.load("07_sedan_fairheaven")
    DEPOT.standing(meshes)
    DEPOT.slim(meshes, meshes, SEDAN_TO + 500, SEDAN_TO)
    DEPOT.finish(meshes, "sedan", "Sedan")


JOBS = {"gas_pump": gas_pump, "payphone": payphone, "sedan": sedan}


if __name__ == "__main__":
    for job in sys.argv[sys.argv.index("--") + 1:]:
        JOBS[job]()
