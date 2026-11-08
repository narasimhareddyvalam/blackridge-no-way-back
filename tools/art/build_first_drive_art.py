from pathlib import Path
import math
import json

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from mesh_authoring import Asset, png, rounded_box, tube, ring, extrude, unit

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'source_assets/artwork/first_drive'
VAN = ROOT / 'game/features/vehicles/freight_van/art'
WORLD = ROOT / 'game/features/environments/industrial_loop/art'
for folder in (SOURCE, VAN, WORLD):
    folder.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(41826)
groups = {}
materials = {}
legends = ['AC', 'AUTO', 'MODE', 'FAN', 'REAR', 'B R', 'BLACKRIDGE', 'BR / 084']
atlas = Image.new('RGBA', (512, 512))
font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 40)
for index, words in enumerate(legends):
    ImageDraw.Draw(atlas).text((256, index * 64 + 32), words, font=font,
                              fill=(230, 230, 220, 255), anchor='mm')
atlas_path = VAN / 'legends.png'
atlas.save(atlas_path)
materials['Control_Legends'] = {'rgb': (0.75, 0.75, 0.70), 'roughness': 0.8,
                                'metallic': 0, 'albedo': atlas_path}

def texture(name, values, destination, color=False):
    path = destination / f'{name}.png'
    png(path, values)
    return path

def normal_from_height(height, strength):
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * strength
    dy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * strength
    normals = np.stack((-dx, -dy, np.ones_like(dx)), axis=-1)
    normals /= np.linalg.norm(normals, axis=-1, keepdims=True)
    return normals * 0.5 + 0.5


def smooth_noise(size, passes):
    field = rng.random((size, size)).astype(np.float32)
    for _ in range(passes):
        field = (field + np.roll(field, 1, 0) + np.roll(field, -1, 0)
                 + np.roll(field, 1, 1) + np.roll(field, -1, 1)) / 5
    return (field - field.min()) / (field.max() - field.min())


grain = smooth_noise(256, 2)
grain_normal = texture('cabin_grain_normal', normal_from_height(grain, 1.8), VAN)
grain_orm = texture('cabin_grain_orm', np.stack((np.ones_like(grain), 0.68 + grain * 0.23, np.ones_like(grain)), axis=-1), VAN)
asphalt = smooth_noise(512, 1)
aggregate = smooth_noise(512, 9)
road_color = np.clip(0.12 + asphalt * 0.15 + aggregate * 0.11, 0, 1)
texture('asphalt_albedo', np.stack((road_color * 0.93, road_color * 0.98,
                                  road_color), axis=-1), WORLD, True)
texture('asphalt_normal', normal_from_height(asphalt, 1.5), WORLD)
concrete = smooth_noise(512, 4)
texture('concrete_albedo', np.stack((0.36 + concrete * 0.17,
                                   0.35 + concrete * 0.17,
                                   0.33 + concrete * 0.16), axis=-1), WORLD, True)
texture('concrete_normal', normal_from_height(concrete, 1.0), WORLD)

def material(name, rgb, roughness=0.6, metallic=0, textured=False):
    materials[name] = {'rgb': rgb, 'roughness': roughness, 'metallic': metallic}
    if textured:
        materials[name]['normal'] = grain_normal
        materials[name]['orm'] = grain_orm
    return name


def box(name, at, size, surface, group, bevel=0.015):
    rounded_box(groups.setdefault(group, Asset()), at, size, surface, bevel)


def cylinder(name, at, radius, depth, surface, group, axis=(0, 0, 1), vertices=32):
    tube(groups.setdefault(group, Asset()), at, radius, depth, surface, axis, vertices)


def torus(name, at, radius, thickness, surface, group, axis=(0, 0, 1)):
    ring(groups.setdefault(group, Asset()), at, radius, thickness, surface, axis)


def beam(name, a, b, width, surface, group):
    a, b = np.array(a), np.array(b)
    delta = b - a
    cylinder(name, (a+b)/2, width/2, np.linalg.norm(delta), surface, group, delta, 8)


def profile(name, outline, low, high, surface, group, bevel=0.02):
    extrude(groups.setdefault(group, Asset()), outline, low, high, surface)


def label(name, words, at, size, surface, group):
    row = legends.index(words)
    width = size * max(2, len(words)) * 0.62
    height = size * 1.3
    x, y, z = at
    vertices = [(x-width/2, y-height/2, z), (x+width/2, y-height/2, z),
                (x+width/2, y+height/2, z), (x-width/2, y+height/2, z)]
    facing = -1 if z < -2 else 1
    if facing < 0:
        vertices.reverse()
    u_margin = (512 - font.getlength(words)) / 1024
    uv = [(u_margin, (row+1)/8), (1-u_margin, (row+1)/8),
          (1-u_margin, row/8), (u_margin, row/8)]
    groups.setdefault(group, Asset()).face('Control_Legends', vertices,
                                           [(0, 0, facing)]*4, uv)

plastic = material('Cabin_Grained_Charcoal', (0.027, 0.031, 0.035), textured=True)
leather = material('Wheel_Leather', (0.016, 0.019, 0.023), textured=True)
rubber = material('Rubber', (0.012, 0.015, 0.019), 0.9)
cloth = material('Seat_Woven_Cloth', (0.075, 0.084, 0.093), textured=True)
silver = material('Satin_Aluminium', (0.42, 0.46, 0.49), 0.29, 0.8)
paint = material('Ivory_Paint', (0.69, 0.70, 0.66), 0.28, 0.22)
seam = material('Panel_Shadow', (0.019, 0.023, 0.026), 0.8)
stitch = material('Stitching', (0.24, 0.25, 0.23), 0.9)
wood = material('Pallet_Timber', (0.23, 0.14, 0.067), 0.88)
yellow = material('Safety_Ochre', (0.65, 0.37, 0.035), 0.65)
metal = material('Galvanized_Steel', (0.19, 0.22, 0.23), 0.46, 0.65)
cardboard = material('Kraft_Cardboard', (0.34, 0.24, 0.13), 0.9)


profile('Sculpted_Dashboard', [(-1.83, 1.43), (-1.60, 1.64), (-1.33, 1.76),
        (-1.12, 1.75), (-0.99, 1.58), (-1.02, 1.06), (-1.30, 1.05)],
        -1.07, 1.07, plastic, 'cabin', 0.06)
box('Instrument_Recess', (-0.53, 1.70, -1.005), (0.73, 0.30, 0.10), rubber, 'cabin', 0.045)
profile('Instrument_Hood', [(-1.38, 1.70), (-1.13, 1.845), (-0.98, 1.84),
        (-0.925, 1.815), (-0.955, 1.79), (-1.12, 1.78)], -0.94, -0.13, plastic, 'cabin')
box('Center_Stack', (0.30, 1.43, -0.984), (0.70, 0.67, 0.12), plastic, 'cabin', 0.045)
box('Display_Trim', (0.30, 1.64, -0.908), (0.49, 0.32, 0.04), silver, 'cabin', 0.018)
for x, size in ((-0.952, 0.72), (-0.02, 1.0), (0.62, 1.0), (0.952, 0.72)):
    torus('Vent_Bezel', (x, 1.64, -0.925), 0.067 * size, 0.011 * size, silver, 'cabin')
    cylinder('Vent_Cavity', (x, 1.64, -0.945), 0.062 * size, 0.03, rubber, 'cabin', (0, 0, 1),
             24)
    for y in (-0.036 * size, -0.012 * size, 0.012 * size, 0.036 * size):
        half = math.sqrt(max((0.06 * size) ** 2 - y ** 2, 0.0))
        box('Vent_Louver', (x, 1.64 + y, -0.93), (2 * half, 0.007, 0.02), plastic, 'cabin',
            0.003)
    cylinder('Vent_Hub', (x, 1.64, -0.924), 0.013, 0.012, silver, 'cabin', (0, 0, 1), 16)
    box('Vent_Tab', (x, 1.652, -0.917), (0.012, 0.03, 0.008), rubber, 'cabin', 0.003)
for x in (0.08, 0.30, 0.52):
    cylinder('Climate_Ring', (x, 1.30, -0.895), 0.056, 0.018, silver, 'cabin')
    cylinder('Climate_Knob', (x, 1.30, -0.879), 0.045, 0.024, rubber, 'cabin')
    box('Knob_Index', (x, 1.335, -0.864), (0.006, 0.012, 0.003), stitch, 'cabin')
for row in range(2):
    for column in range(5):
        x = -0.005 + column * 0.145
        y = 1.46 - row * 0.30
        box('Console_Switch', (x, y, -0.902), (0.125, 0.045, 0.018), rubber, 'cabin')
        label('Switch_Marking', ('AC', 'AUTO', 'MODE', 'FAN', 'REAR')[column],
              (x, y, -0.889), 0.013, stitch, 'cabin')
box('Glovebox_Seam', (0.84, 1.37, -1.00), (0.41, 0.25, 0.03), rubber, 'cabin', 0.018)
box('Glovebox_Face', (0.84, 1.37, -0.978), (0.396, 0.234, 0.02), plastic, 'cabin')
box('Glovebox_Latch', (0.84, 1.45, -0.961), (0.12, 0.025, 0.013), silver, 'cabin')
box('Center_Tunnel', (0.12, 0.91, -0.42), (0.45, 0.55, 0.78), plastic, 'cabin', 0.07)
box('Shift_Boot', (0.10, 1.19, -0.59), (0.20, 0.07, 0.27), leather, 'cabin', 0.035)
beam('Gear_Stem', (0.10, 1.21, -0.59), (0.10, 1.40, -0.64), 0.032, silver, 'cabin')
box('Gear_Grip', (0.10, 1.41, -0.64), (0.09, 0.115, 0.11), leather, 'cabin', 0.045)
for z in (-0.18, 0.01):
    cylinder('Cup_Recess', (0.12, 1.195, z), 0.074, 0.008, rubber, 'cabin', (0, 1, 0))
    torus('Cup_Rim', (0.12, 1.202, z), 0.074, 0.006, silver, 'cabin', (0, 1, 0))
for side in (-1, 1):
    box('Seat_Cushion', (side * 0.56, 1.01, 0.12), (0.68, 0.25, 0.72), cloth, 'cabin', 0.095)
    box('Seat_Back', (side * 0.56, 1.53, 0.46), (0.66, 0.93, 0.23), cloth, 'cabin', 0.09)
    box('Headrest', (side * 0.56, 2.10, 0.47), (0.38, 0.27, 0.17), cloth, 'cabin', 0.065)
    for offset in (-0.24, 0.24):
        box('Seat_Bolster', (side * 0.56 + offset, 1.02, 0.10),
            (0.16, 0.29, 0.69), leather, 'cabin', 0.055)
    box('Door_Card', (side * 1.08, 1.31, -0.50), (0.14, 0.78, 1.76), plastic, 'cabin', 0.05)
    box('Door_Armrest', (side * 0.99, 1.51, -0.50), (0.22, 0.10, 0.62), leather, 'cabin', 0.035)
    box('Door_Handle', (side * 1.00, 1.68, -0.83), (0.045, 0.06, 0.18), silver, 'cabin')
    for z in (-0.64, -0.51):
        box('Window_Switch', (side * 0.95, 1.568, z), (0.06, 0.016, 0.09), rubber, 'cabin')
    beam('A_Pillar', (side * 1.06, 1.55, -1.55), (side * 0.97, 2.69, -1.15), 0.095,
         plastic, 'cabin')
    box('Visor', (side * 0.56, 2.67, -1.18), (0.65, 0.16, 0.055), plastic, 'cabin', 0.025)
box('Headliner', (0, 2.77, -0.42), (2.18, 0.08, 1.72), cloth, 'cabin', 0.035)

torus('Leather_Rim', (0, 0, 0), 0.19, 0.031, leather, 'steering')
torus('Rim_Stitch', (0, 0, 0.03), 0.186, 0.0022, stitch, 'steering')
box('Airbag_Hub', (0, 0, 0.02), (0.165, 0.125, 0.07), leather, 'steering', 0.04)
torus('Hub_Ring', (0, 0, 0.056), 0.03, 0.004, silver, 'steering')
for side in (-1, 1):
    beam('Wheel_Spoke', (side * 0.075, -0.005, 0.005), (side * 0.168, 0.02, 0),
         0.045, leather, 'steering')
    beam('Spoke_Trim', (side * 0.08, -0.03, 0.022), (side * 0.165, -0.008, 0.016),
         0.012, silver, 'steering')
    box('Wheel_Buttons', (side * 0.118, 0.022, 0.03), (0.07, 0.05, 0.014),
        rubber, 'steering', 0.01)
    for x in (-0.014, 0.014):
        box('Button_Marking', (side * 0.118 + x, 0.026, 0.0385),
            (0.009, 0.003, 0.002), stitch, 'steering')
beam('Lower_Spoke', (0, -0.055, 0.005), (0, -0.172, 0), 0.05, leather, 'steering')
beam('Lower_Trim', (0, -0.07, 0.024), (0, -0.16, 0.018), 0.012, silver, 'steering')
label('Wheel_Identity', 'B R', (0, 0.0, 0.058), 0.02, silver, 'steering')

DOOR_FRONT, DOOR_BACK, DOOR_GAP, BELT_LINE = -1.45, 0.06, 0.003, 1.57
CAB_HANDLE = 1.05
DOOR_TRIM = range(2, 9)


def arch(center, angle):
    return (center + math.cos(angle) * 0.57, 0.48 + math.sin(angle) * 0.57)


def sill(z):
    return 0.48 + (1.28 - z) * 0.16 / 2.16


hinge_angle = math.acos((DOOR_FRONT + 1.52) / 0.57)
front_arch = np.linspace(0, math.pi, 17)
rear_arch = [arch(1.85, angle) for angle in front_arch]
for side in (-1, 1):
    shell = (side * 1.14 - 0.035, side * 1.14 + 0.035)
    if side > 0:
        outline = [(-2.35, 0.63), (-2.35, 1.32), (-1.67, 1.52),
                   (DOOR_FRONT, BELT_LINE), (DOOR_BACK, BELT_LINE), (0.06, 2.93), (2.73, 2.93),
                   (2.85, 2.78), (2.85, 0.64), (2.48, 0.64), *rear_arch, (-0.88, 0.64)]
        outline += [arch(-1.52, angle) for angle in front_arch]
        profile('Side_Shell', outline + [(-2.18, 0.64)], *shell, paint, 'body', 0.018)
    else:
        fender = [(-2.35, 0.63), (-2.35, 1.32), (-1.67, 1.52), (DOOR_FRONT, BELT_LINE),
                  arch(-1.52, hinge_angle)]
        fender += [arch(-1.52, angle) for angle in front_arch if angle > hinge_angle]
        profile('Side_Shell', fender + [(-2.18, 0.64)], *shell, paint, 'body', 0.018)
        cargo = [(DOOR_BACK, sill(DOOR_BACK)), (DOOR_BACK, 2.93), (2.73, 2.93), (2.85, 2.78),
                 (2.85, 0.64), (2.48, 0.64), *rear_arch]
        profile('Side_Shell', cargo, *shell, paint, 'body', 0.018)
        front, back = DOOR_FRONT + DOOR_GAP, DOOR_BACK - DOOR_GAP
        door = [(front, BELT_LINE), (back, BELT_LINE), (back, sill(back)), (-0.88, 0.64)]
        door += [arch(-1.52, angle) for angle in front_arch if angle < hinge_angle]
        door.append((front, arch(-1.52, hinge_angle)[1]))
        profile('Driver_Door', door, *shell, paint, 'door', 0.018)
    cab = 'door' if side < 0 else 'body'
    for z in (-0.02, 2.55):
        if z < 0 and side < 0:
            box('Cargo_Seam', (side * 1.18, 1.16, z), (0.006, 0.82, 0.009), seam, 'door')
            box('Cargo_Seam', (side * 1.18, 2.20, z), (0.006, 1.26, 0.009), seam, 'body')
        else:
            box('Cargo_Seam', (side * 1.18, 1.79, z), (0.006, 2.08, 0.009), seam, 'body')
    box('Sliding_Rail', (side * 1.18, 1.73, 1.27), (0.015, 0.025, 2.26), silver, 'body')
    if side < 0:
        box('Side_Rub_Strip', (side * 1.19, 0.85, -0.3215), (0.06, 0.18, 0.757), rubber,
            'door')
        box('Side_Rub_Strip', (side * 1.19, 0.85, 0.7315), (0.06, 0.18, 1.337), rubber,
            'body')
    else:
        box('Side_Rub_Strip', (side * 1.19, 0.85, 0.35), (0.06, 0.18, 2.1), rubber, 'body')
    box('Door_Handle', (side * 1.20, CAB_HANDLE, -0.22), (0.05, 0.05, 0.20), rubber, cab)
    box('Door_Handle', (side * 1.20, 1.60, 0.32), (0.05, 0.05, 0.20), rubber, 'body')
    for center in (-1.52, 1.85):
        for index in range(20):
            a, b = index * math.pi / 20, (index + 1) * math.pi / 20
            on_door = side < 0 and center < 0 and index in DOOR_TRIM
            beam('Wheelarch_Trim', (side * 1.19, 0.48 + math.sin(a) * 0.57,
                 center + math.cos(a) * 0.57),
                 (side * 1.19, 0.48 + math.sin(b) * 0.57,
                  center + math.cos(b) * 0.57), 0.045, rubber, 'door' if on_door else 'body')
box('Roof', (0, 2.93, 0.80), (2.28, 0.13, 4.07), paint, 'body', 0.055)
profile('Hood', [(-2.39, 1.23), (-2.27, 1.49), (-1.59, 1.57),
        (-1.48, 1.48), (-1.65, 1.30)], -1.11, 1.11, paint, 'body', 0.045)
box('Front_Grille', (0, 1.07, -2.35), (1.30, 0.43, 0.16), rubber, 'body', 0.09)
for y in (0.96, 1.08, 1.20):
    box('Grille_Bar', (0, y, -2.443), (1.17, 0.023, 0.015), silver, 'body')
for z in (-2.34, 2.85):
    box('Bumper', (0, 0.66, z), (2.31, 0.30, 0.22), rubber, 'body', 0.08)
box('Rear_Doors', (0, 1.80, 2.80), (2.24, 2.15, 0.10), paint, 'body', 0.035)
box('Rear_Door_Seam', (0, 1.81, 2.859), (0.015, 2.05, 0.012), seam, 'body')
for x in (-0.10, 0.10):
    box('Rear_Handle', (x, 1.54, 2.88), (0.055, 0.22, 0.04), rubber, 'body')
label('Front_Identity', 'BLACKRIDGE', (0, 1.12, -2.455), 0.047, silver, 'body')

torus('Tire', (0, 0, 0), 0.348, 0.11, rubber, 'tire', (1, 0, 0))
cylinder('Steel_Wheel', (0, 0, 0), 0.257, 0.235, silver, 'tire', (1, 0, 0))
for side in (-1, 1):
    cylinder('Hub', (side * 0.126, 0, 0), 0.095, 0.028, metal, 'tire', (1, 0, 0))
    for angle in np.linspace(0, math.tau, 10, endpoint=False):
        cylinder('Rim_Recess', (side * 0.122, math.sin(angle) * 0.183,
                 math.cos(angle) * 0.183), 0.034, 0.008, rubber, 'tire', (1, 0, 0), 16)
for angle in np.linspace(0, math.tau, 48, endpoint=False):
    for lateral in (-0.055, 0.055):
        a, b = angle, angle + 0.05
        beam('Tread', (lateral, math.sin(a) * 0.455, math.cos(a) * 0.455),
             (lateral, math.sin(b) * 0.455, math.cos(b) * 0.455), 0.010,
             seam, 'tire')

for x in (-0.42, 0, 0.42):
    box('Pallet_Block', (x, 0.10, 0), (0.16, 0.16, 0.88), wood, 'pallet')
for z in np.linspace(-0.43, 0.43, 7):
    box('Pallet_Board', (0, 0.20, z), (1.1, 0.045, 0.10), wood, 'pallet', 0.005)
box('Box', (0, 0.42, 0), (0.78, 0.84, 0.68), cardboard, 'crate', 0.012)
box('Tape', (0, 0.846, 0), (0.075, 0.006, 0.68), wood, 'crate', 0.001)
box('Shipping_Label', (-0.18, 0.53, 0.347), (0.23, 0.19, 0.006), paint, 'crate', 0.001)
label('Crate_Label', 'BR / 084', (-0.18, 0.53, 0.352), 0.031, seam, 'crate')
cylinder('Bollard', (0, 0.56, 0), 0.105, 1.12, yellow, 'bollard', (0, 1, 0))
for y in (0.30, 0.69):
    cylinder('Bollard_Band', (0, y, 0), 0.108, 0.12, rubber, 'bollard', (0, 1, 0))
box('Baseplate', (0, 0.025, 0), (0.34, 0.05, 0.34), metal, 'bollard')

report = {}
for group, asset in groups.items():
    destination = VAN if group in {'body', 'cabin', 'steering', 'tire', 'door'} else WORLD
    report[group] = {'triangles': asset.export(destination / f'{group}.glb', materials),
                     'surfaces': len(asset.surfaces)}
(SOURCE / 'geometry_report.md').write_text(
    '# Geometry report\n\nGenerated with tools/art/build_first_drive_art.py.\n\n'
    + '\n'.join(f'- {name}: {entry["triangles"]} triangles; {entry["surfaces"]} surfaces.'
                 for name, entry in report.items()) + '\n')
print(json.dumps(report, indent=2))
