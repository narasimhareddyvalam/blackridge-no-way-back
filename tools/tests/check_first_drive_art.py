from pathlib import Path
import json
import struct

import numpy as np


ROOT = Path(__file__).resolve().parents[2]
VAN = ROOT / 'game/features/vehicles/freight_van/art'
WORLD = ROOT / 'game/features/environments/industrial_loop/art'
failures = []


def check(condition, message):
    print(('PASS: ' if condition else 'FAIL: ') + message)
    if not condition:
        failures.append(message)


for path in sorted([*VAN.glob('*.glb'), *WORLD.glob('*.glb')]):
    raw = path.read_bytes()
    magic, version, length = struct.unpack_from('<III', raw)
    check(magic == 0x46546C67 and version == 2 and length == len(raw), path.name + ' header')
    size, kind = struct.unpack_from('<II', raw, 12)
    document = json.loads(raw[20:20+size])
    binary = raw[28+size:]

    def accessor(index):
        data = document['accessors'][index]
        view = document['bufferViews'][data['bufferView']]
        width = {'VEC3': 3, 'VEC2': 2, 'SCALAR': 1}[data['type']]
        kinds = {5123: '<u2', 5125: '<u4', 5126: '<f4'}
        return np.frombuffer(binary, dtype=kinds[data['componentType']],
                             offset=view.get('byteOffset', 0) + data.get('byteOffset', 0),
                             count=data['count'] * width).reshape(-1, width)

    triangles = 0
    all_points = []
    primitives = [part for mesh in document['meshes'] for part in mesh['primitives']]
    for index, primitive in enumerate(primitives):
        positions = accessor(primitive['attributes']['POSITION'])
        normals = accessor(primitive['attributes']['NORMAL'])
        uvs = accessor(primitive['attributes']['TEXCOORD_0'])
        indices = accessor(primitive['indices']).reshape(-1, 3)
        prefix = f'{path.name} surface {index}'
        check(np.isfinite(positions).all() and np.isfinite(normals).all()
              and np.isfinite(uvs).all(), prefix + ' finite geometry')
        check(len(positions) == len(normals) == len(uvs)
              and indices.max() < len(positions), prefix + ' valid vertex references')
        check(np.allclose(np.linalg.norm(normals, axis=1), 1, atol=0.001),
              prefix + ' unit normals')
        geometric = np.cross(positions[indices[:, 1]] - positions[indices[:, 0]],
                             positions[indices[:, 2]] - positions[indices[:, 0]])
        agreement = (geometric * normals[indices].mean(axis=1)).sum(axis=1)
        check(not np.any(agreement < -1e-8), prefix + ' outward winding agrees with normals')
        triangles += len(indices)
        all_points.append(positions)
    bounds = np.concatenate(all_points)
    check(triangles < 30000, path.name + ' bounded geometry (<30000 triangles)')
    if path.stem == 'body':
        check(bounds[:, 1].min() >= 0.1 and bounds[:, 1].max() <= 3.05,
              'Van body remains above road and near existing collision height')
        check(np.abs(bounds[:, 0]).max() <= 1.3 and np.abs(bounds[:, 2]).max() <= 3.0,
              'Van body fits existing vehicle footprint with trim allowance')
    print(f'GEOMETRY: {path.name}: {triangles} triangles')

check(len(list(VAN.glob('*.glb'))) == 6 and len(list(WORLD.glob('*.glb'))) == 3,
      'All six vehicle assets (with the driver\'s door and the rear doors\' hinges) and three '
      'depot props exist')

COCKPIT = VAN / 'cockpit'
COCKPIT_TRIANGLES = 900000
SHADOW_TRIANGLES = 40000
FILE_LIMIT = 25 * 1024 * 1024
SOURCE_INVERTED = {'cockpit_front.gltf': 49, 'cockpit_back.gltf': 5, 'cockpit_roof.gltf': 5,
                   'cockpit_wheel.gltf': 0}
COMPONENTS = {5121: '<u1', 5123: '<u2', 5125: '<u4', 5126: '<f4'}
WIDTHS = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}


def gltf_parts(path):
    if path.suffix == '.glb':
        raw = path.read_bytes()
        size, _ = struct.unpack_from('<II', raw, 12)
        return json.loads(raw[20:20 + size]), raw[28 + size:]
    document = json.loads(path.read_text())
    return document, (path.parent / document['buffers'][0]['uri']).read_bytes()


visible_triangles = 0
shadow_triangles = 0
models = sorted([*COCKPIT.glob('*.gltf'), *COCKPIT.glob('*.glb')])
check([path.name for path in models] == [
    'cockpit_back.gltf', 'cockpit_front.gltf', 'cockpit_roof.gltf', 'cockpit_shadow.glb',
    'cockpit_wheel.gltf', 'cockpit_wheel_shadow.glb'], 'Cockpit parts and shadow stand-ins exist')
for path in models:
    document, binary = gltf_parts(path)

    def values(index):
        data = document['accessors'][index]
        view = document['bufferViews'][data['bufferView']]
        width = WIDTHS[data['type']]
        return np.frombuffer(binary, dtype=COMPONENTS[data['componentType']],
                             offset=view.get('byteOffset', 0) + data.get('byteOffset', 0),
                             count=data['count'] * width).reshape(-1, width)

    triangles = inverted = 0
    finite = referenced = unit = True
    for mesh in document['meshes']:
        for primitive in mesh['primitives']:
            positions = values(primitive['attributes']['POSITION'])
            normals = values(primitive['attributes']['NORMAL'])
            indices = values(primitive['indices']).reshape(-1, 3).astype(np.int64)
            finite &= bool(np.isfinite(positions).all() and np.isfinite(normals).all())
            referenced &= bool(len(positions) == len(normals) and indices.max() < len(positions))
            unit &= bool(np.allclose(np.linalg.norm(normals, axis=1), 1, atol=0.001))
            geometric = np.cross(positions[indices[:, 1]] - positions[indices[:, 0]],
                                 positions[indices[:, 2]] - positions[indices[:, 0]])
            agreement = (geometric * normals[indices].mean(axis=1)).sum(axis=1)
            inverted += int((agreement < -1e-8).sum())
            triangles += len(indices)
    prefix = 'cockpit/' + path.name
    check(finite and referenced and unit,
          prefix + ' finite geometry, valid vertex references and unit normals')
    check(not any('logo' in node.get('name', '').lower() for node in document['nodes']),
          prefix + ' has no badge parts')
    if path.name in SOURCE_INVERTED:
        check(inverted <= SOURCE_INVERTED[path.name],
              f'{prefix} inverted triangles within the source model\'s '
              f'{SOURCE_INVERTED[path.name]} ({inverted})')
        check(all((COCKPIT / image['uri']).is_file() for image in document.get('images', [])),
              prefix + ' textures present')
        visible_triangles += triangles
    else:
        shadow_triangles += triangles
    print(f'GEOMETRY: {prefix}: {triangles} triangles')

check(visible_triangles < COCKPIT_TRIANGLES,
      f'Cockpit within its written budget (<{COCKPIT_TRIANGLES} triangles, CHANGE-BRIEF Run 12)')
check(shadow_triangles < SHADOW_TRIANGLES,
      f'Cockpit shadow stand-ins within budget (<{SHADOW_TRIANGLES} triangles)')
check(all(path.stat().st_size < FILE_LIMIT for path in COCKPIT.rglob('*') if path.is_file()),
      'Every cockpit file is under 25 MB')
print(f'GEOMETRY: cockpit total: {visible_triangles} triangles, shadows {shadow_triangles}')

IVECO = VAN / 'iveco'
IVECO_TRIANGLES = 100000
IVECO_PARTS = {
    'iveco_exterior.glb': {'Body', 'BodyGlass', 'Headlights', 'TailLamps', 'FrontIndicatorLeft',
                           'FrontIndicatorRight', 'RearIndicatorLeft', 'RearIndicatorRight',
                           'Windshield', 'DriverDoor', 'DriverWindow', 'PassengerDoor',
                           'PassengerWindow', 'RearDoorLeft', 'RearDoorRight', 'WheelFrontLeft',
                           'WheelFrontRight', 'WheelRearLeft', 'WheelRearRight'},
    'iveco_cab.glb': {'Cab', 'SteeringWheel'}}
IVECO_INVERTED = {'iveco_exterior.glb': 49, 'iveco_cab.glb': 17}
IVECO_TEXTURE = {'iveco_exterior.glb': 2048, 'iveco_cab.glb': 1024}
BADGE_WORDS = ('logo', 'badge', 'iveco')


def accessor_values(document, binary, index):
    data = document['accessors'][index]
    view = document['bufferViews'][data['bufferView']]
    width = WIDTHS[data['type']]
    return np.frombuffer(binary, dtype=COMPONENTS[data['componentType']],
                         offset=view.get('byteOffset', 0) + data.get('byteOffset', 0),
                         count=data['count'] * width).reshape(-1, width)


def webp_size(data):
    kind = data[12:16]
    if kind == b'VP8X':
        return 1 + int.from_bytes(data[24:27], 'little'), 1 + int.from_bytes(data[27:30], 'little')
    if kind == b'VP8L':
        bits = int.from_bytes(data[21:25], 'little')
        return (bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1
    width, height = struct.unpack_from('<HH', data, 26)
    return width & 0x3FFF, height & 0x3FFF


def rotated(rotation, vector):
    axis, scalar = np.array(rotation[:3]), rotation[3]
    turn = np.cross(axis, vector)
    return vector + 2 * scalar * turn + 2 * np.cross(axis, turn)


iveco_triangles = 0
places = {}
check(sorted(path.name for path in IVECO.glob('*.glb')) == sorted(IVECO_PARTS),
      'Iveco van files exist: the exterior and the cab (C31)')
for name, wanted in IVECO_PARTS.items():
    document, binary = gltf_parts(IVECO / name)
    prefix = 'iveco/' + name
    nodes = {node['name']: node for node in document['nodes']}
    check(set(nodes) == wanted, f'{prefix} holds its parts: {", ".join(sorted(wanted))}')
    named = [*nodes, *(material['name'] for material in document['materials'])]
    check(not any(word in label.lower() for label in named for word in BADGE_WORDS),
          prefix + ' has no badge parts')
    triangles = inverted = 0
    finite = referenced = unit = True
    for label, node in nodes.items():
        corners = []
        for primitive in document['meshes'][node['mesh']]['primitives']:
            positions = accessor_values(document, binary, primitive['attributes']['POSITION'])
            normals = accessor_values(document, binary, primitive['attributes']['NORMAL'])
            indices = accessor_values(document, binary, primitive['indices'])
            indices = indices.reshape(-1, 3).astype(np.int64)
            finite &= bool(np.isfinite(positions).all() and np.isfinite(normals).all())
            referenced &= bool(len(positions) == len(normals) and indices.max() < len(positions))
            unit &= bool(np.allclose(np.linalg.norm(normals, axis=1), 1, atol=0.001))
            geometric = np.cross(positions[indices[:, 1]] - positions[indices[:, 0]],
                                 positions[indices[:, 2]] - positions[indices[:, 0]])
            agreement = (geometric * normals[indices].mean(axis=1)).sum(axis=1)
            inverted += int((agreement < -1e-8).sum())
            triangles += len(indices)
            corners += [positions.min(0), positions.max(0)]
        places[label] = (np.array(node.get('translation', [0, 0, 0])),
                         node.get('rotation', [0, 0, 0, 1]), np.min(corners, 0), np.max(corners, 0))
    check(finite and referenced and unit,
          prefix + ' finite geometry, valid vertex references and unit normals')
    check(inverted <= IVECO_INVERTED[name], f'{prefix} inverted triangles within the source '
          f'model\'s {IVECO_INVERTED[name]} ({inverted})')
    sizes = []
    for image in document['images']:
        view = document['bufferViews'][image['bufferView']]
        start = view.get('byteOffset', 0)
        sizes.append((image['mimeType'], webp_size(binary[start:start + view['byteLength']])))
    check(all(kind == 'image/webp' and max(size) <= IVECO_TEXTURE[name] for kind, size in sizes),
          f'{prefix} textures are WebP, at most {IVECO_TEXTURE[name]} pixels ({len(sizes)} images)')
    iveco_triangles += triangles
    print(f'GEOMETRY: {prefix}: {triangles} triangles')

wheels_true = []
for end, side in (('Front', 'Left'), ('Front', 'Right'), ('Rear', 'Left'), ('Rear', 'Right')):
    at, _, low, high = places[f'Wheel{end}{side}']
    centred = np.allclose(((low + high) / 2)[1:], 0, atol=0.001)
    wheels_true.append(centred and np.sign(at[0]) == (-1 if side == 'Left' else 1)
                       and np.sign(at[2]) == (-1 if end == 'Front' else 1)
                       and abs(at[1] + low[1]) < 0.005)
check(all(wheels_true), 'Iveco wheels turn about their own centres, front ones at -Z, left ones '
      'at -X, tyres on y = 0')
door, _, _, _ = places['DriverDoor']
check(door[0] < 0 and door[2] < 0 and places['PassengerDoor'][0][0] > 0
      and places['Windshield'][2][2] + places['Windshield'][3][2] < 0,
      'Iveco faces -Z with the driver\'s door on the left (-X)')
left, _, left_low, left_high = places['RearDoorLeft']
right, _, right_low, right_high = places['RearDoorRight']
check(left[0] < -0.95 and right[0] > 0.95 and left[2] > 2.3 and right[2] > 2.3
      and left_low[0] > 0.1 and abs(left_high[0] - 1.0) < 0.05
      and right_high[0] < -0.1 and abs(right_low[0] + 1.0) < 0.05,
      'Iveco rear doors turn about the body\'s outer rear corners (step 2d): the left one at -X, '
      'the right one at +X, each door reaching in from its pivot to the middle')
hub, turn, _, _ = places['SteeringWheel']
column = rotated(turn, np.array([0.0, 0.0, 1.0]))
check(hub[0] < 0 and column[1] > 0.5 and column[2] > 0.5,
      'Iveco steering wheel turns about its column: local Z points up the column at the driver')
check(iveco_triangles < IVECO_TRIANGLES,
      f'Iveco van within its written budget (<{IVECO_TRIANGLES} triangles, CHANGE-BRIEF Run 23)')
check(all(path.stat().st_size < FILE_LIMIT for path in IVECO.rglob('*') if path.is_file()),
      'Every Iveco van file is under 25 MB')
print(f'GEOMETRY: iveco total: {iveco_triangles} triangles')

OFFICE = WORLD / 'office'
OFFICE_NODES = {'SiteOffice', 'RunSheet', 'NoticeLamp', 'Floodlight', 'WindowLight',
                'Building-convcolonly', 'Landing-convcolonly'}
OFFICE_MATERIALS = {'siding', 'trim', 'roof', 'door', 'deck', 'concrete', 'metal', 'glass',
                    'blinds', 'window_glow', 'lamp_glow', 'sign', 'letters', 'paper',
                    'clipboard'}
METRE_UVS = ('siding', 'door', 'deck', 'concrete')

check(sorted(path.name for path in OFFICE.glob('*.glb')) == ['site_office.glb'],
      'The timber site office exists (C36)')
document, binary = gltf_parts(OFFICE / 'site_office.glb')
nodes = {node['name']: node for node in document['nodes']}
check(set(nodes) == OFFICE_NODES,
      'office/site_office.glb holds the office, its four markers and two collision boxes')
check({material['name'] for material in document['materials']} == OFFICE_MATERIALS
      and not document.get('images'),
      'office/site_office.glb names its 15 materials for Godot and embeds no image')
triangles = inverted = 0
finite = referenced = unit = True
areas = {}
for primitive in document['meshes'][nodes['SiteOffice']['mesh']]['primitives']:
    positions = accessor_values(document, binary, primitive['attributes']['POSITION'])
    normals = accessor_values(document, binary, primitive['attributes']['NORMAL'])
    uvs = accessor_values(document, binary, primitive['attributes']['TEXCOORD_0'])
    indices = accessor_values(document, binary, primitive['indices'])
    indices = indices.reshape(-1, 3).astype(np.int64)
    finite &= bool(np.isfinite(positions).all() and np.isfinite(normals).all()
                   and np.isfinite(uvs).all())
    referenced &= bool(len(positions) == len(normals) == len(uvs)
                       and indices.max() < len(positions))
    unit &= bool(np.allclose(np.linalg.norm(normals, axis=1), 1, atol=0.001))
    geometric = np.cross(positions[indices[:, 1]] - positions[indices[:, 0]],
                         positions[indices[:, 2]] - positions[indices[:, 0]])
    agreement = (geometric * normals[indices].mean(axis=1)).sum(axis=1)
    inverted += int((agreement < -1e-8).sum())
    triangles += len(indices)
    across, up = uvs[indices[:, 1]] - uvs[indices[:, 0]], uvs[indices[:, 2]] - uvs[indices[:, 0]]
    flat = across[:, 0] * up[:, 1] - across[:, 1] * up[:, 0]
    areas[document['materials'][primitive['material']]['name']] = (
        np.abs(flat).sum() / np.linalg.norm(geometric, axis=1).sum())
check(finite and referenced and unit,
      'office/site_office.glb finite geometry, valid vertex references and unit normals')
check(inverted == 0, f'office/site_office.glb has no inverted triangles ({inverted})')
check(all(abs(areas[name] - 1.0) < 0.01 for name in METRE_UVS),
      'office/site_office.glb UVs are in metres, so textures lie at real size ('
      + ', '.join(f'{name} {areas[name]:.3f}' for name in METRE_UVS) + ')')
sheet = np.array(nodes['RunSheet']['translation'])
flood = rotated(nodes['Floodlight']['rotation'], np.array([0.0, 0.0, -1.0]))
lamp = rotated(nodes['NoticeLamp']['rotation'], np.array([0.0, 0.0, -1.0]))
check(1.8 < sheet[2] < 1.85 and 1.2 < sheet[1] < 1.7 and flood[2] > 0.8 and flood[1] < 0
      and lamp[1] < -0.9 and lamp[2] < 0,
      'The office faces +Z: the clipboard on its front wall, the floodlight turned out and down '
      'toward the road, the lamp down at the clipboard')
building = accessor_values(document, binary, document['meshes'][
    nodes['Building-convcolonly']['mesh']]['primitives'][0]['attributes']['POSITION'])
check(np.allclose(building.min(0), [-3.0, 0.0, -1.8], atol=0.001)
      and np.allclose(building.max(0), [3.0, 2.95, 1.8], atol=0.001),
      'The office\'s collision box matches its walls (6.0 x 2.95 x 3.6 m)')
check(triangles < 30000, f'office/site_office.glb bounded geometry (<30000 triangles)')
check((OFFICE / 'site_office.glb').stat().st_size < FILE_LIMIT, 'The office file is under 25 MB')
print(f'GEOMETRY: office/site_office.glb: {triangles} triangles')

GUARD = ROOT / 'game/features/characters/guard'
check(sorted(path.name for path in GUARD.glob('*.glb')) == ['guard.glb'],
      "The gate guard exists: Microsoft Rocketbox's Security_Male_01 (C55)")
guard_triangles = 0
if (GUARD / 'guard.glb').exists():
    document, binary = gltf_parts(GUARD / 'guard.glb')
    for mesh in document['meshes']:
        for primitive in mesh['primitives']:
            guard_triangles += document['accessors'][primitive['indices']]['count'] // 3
    clips = [animation['name'] for animation in document.get('animations', [])]
    sizes = []
    for image in document.get('images', []):
        view = document['bufferViews'][image['bufferView']]
        start = view.get('byteOffset', 0)
        sizes.append(max(webp_size(binary[start:start + view['byteLength']])))
    joints = len(document['skins'][0]['joints']) if document.get('skins') else 0
    check(guard_triangles < 12000, 'guard/guard.glb bounded geometry (<12000 triangles)')
    check(clips == ['SitIdle-loop'], 'guard/guard.glb carries one clip, the seated idle, looping')
    check(len(sizes) == 6 and max(sizes) <= 1024,
          'guard/guard.glb holds six WebP textures of at most 1024 pixels (colour and normal '
          'for head, uniform and kit)')
    check(joints == 80, 'guard/guard.glb keeps Rocketbox\'s 80-bone skeleton')
    check((GUARD / 'guard.glb').stat().st_size < FILE_LIMIT, 'The guard file is under 25 MB')
print(f'GEOMETRY: guard/guard.glb: {guard_triangles} triangles')

WORKER = ROOT / 'game/features/characters/dock_worker'
check(sorted(path.name for path in WORKER.glob('*.glb')) == ['dock_worker.glb'],
      "Bay 9's dock worker exists: Microsoft Rocketbox's Construction_Male_08 (C58)")
worker_triangles = 0
if (WORKER / 'dock_worker.glb').exists():
    document, binary = gltf_parts(WORKER / 'dock_worker.glb')
    for mesh in document['meshes']:
        for primitive in mesh['primitives']:
            worker_triangles += document['accessors'][primitive['indices']]['count'] // 3
    clips = sorted(animation['name'] for animation in document.get('animations', []))
    sizes = []
    for image in document.get('images', []):
        view = document['bufferViews'][image['bufferView']]
        start = view.get('byteOffset', 0)
        sizes.append(max(webp_size(binary[start:start + view['byteLength']])))
    joints = len(document['skins'][0]['joints']) if document.get('skins') else 0
    check(worker_triangles < 12000,
          'dock_worker/dock_worker.glb bounded geometry (<12000 triangles)')
    check(clips == ['Idle-loop', 'Seal', 'Walk-loop'],
          'dock_worker/dock_worker.glb carries three clips: the standing idle and the walk, '
          'looping, and the reach to the doors\' hasp')
    check(len(sizes) == 6 and max(sizes) <= 1024,
          'dock_worker/dock_worker.glb holds six WebP textures of at most 1024 pixels (colour and '
          'normal for head, work suit and hard hat)')
    check(joints == 81, 'dock_worker/dock_worker.glb keeps Rocketbox\'s 81-bone skeleton')
    check((WORKER / 'dock_worker.glb').stat().st_size < FILE_LIMIT,
          'The dock worker file is under 25 MB')
print(f'GEOMETRY: dock_worker/dock_worker.glb: {worker_triangles} triangles')

ETHAN = ROOT / 'game/features/characters/ethan'


def hips_drift(document, binary, animation):
    """How far, across the floor, an animation's hips get from where they start, at most and at
    its end, in metres: the armature's own turn and 1/100 scale applied, glTF's Y up. In place,
    only their sway is left: Pushing's swings 0.14 m to the side, and Push Stop ends 0.05 m to
    one side; with their travel, Pushing's go 1.0 m and Push Stop's 0.82 m."""
    hips = next(index for index, node in enumerate(document['nodes'])
                if node.get('name') == 'mixamorig:Hips')
    armature = next(node for node in document['nodes'] if node.get('name') == 'Armature')
    x, y, z, w = armature.get('rotation', [0.0, 0.0, 0.0, 1.0])
    turn = np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                     [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                     [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])
    scale = armature.get('scale', [1.0, 1.0, 1.0])[0]
    channel = next(c for c in animation['channels'] if c['target'].get('node') == hips
                   and c['target']['path'] == 'translation')
    output = document['accessors'][animation['samplers'][channel['sampler']]['output']]
    view = document['bufferViews'][output['bufferView']]
    start = view.get('byteOffset', 0) + output.get('byteOffset', 0)
    points = np.frombuffer(binary, dtype='<f4', count=output['count'] * 3,
                           offset=start).reshape(-1, 3) @ turn.T * scale
    across = np.linalg.norm((points - points[0])[:, [0, 2]], axis=1)
    return across.max(), across[-1]


if (ETHAN / 'ethan.glb').exists():
    document, binary = gltf_parts(ETHAN / 'ethan.glb')
    animations = {animation['name']: animation for animation in document.get('animations', [])}
    check(sorted(animations) == ['EnterVan', 'ExitVan', 'Idle-loop', 'PullBack-loop', 'Push-loop',
                                 'PushStop', 'Run-loop', 'StairsUp-loop', 'Walk-loop',
                                 'WalkBack-loop'],
          'ethan/ethan.glb carries his ten clips: the idle, walk, walk back and run, looping, '
          'the van\'s way in and out, Mixamo\'s Pushing, looping, and Push Stop (#240), and its '
          'Running Up Stairs and Pull Heavy Object, looping (#254-#257)')
    for name in ('Walk-loop', 'Push-loop', 'PushStop', 'StairsUp-loop', 'PullBack-loop'):
        if name in animations:
            most, end = hips_drift(document, binary, animations[name])
            check(most < 0.25 and end < 0.06,
                  f'ethan/ethan.glb\'s {name} walks in place, the game moving him: his hips get '
                  f'at most {most:.3f} m from where they start across the floor, {end:.3f} m at '
                  f'its end')
    joints = len(document['skins'][0]['joints']) if document.get('skins') else 0
    check(joints == 65, 'ethan/ethan.glb keeps Mixamo\'s 65-bone skeleton')
    check((ETHAN / 'ethan.glb').stat().st_size < FILE_LIMIT, 'The Ethan file is under 25 MB')

DEPOT = WORLD / 'depot'
door_triangles = 0
check((DEPOT / 'dock_door.glb').exists(),
      "The dock door exists: Maxwell autodoors' sectional door, made game-ready")
if (DEPOT / 'dock_door.glb').exists():
    document, binary = gltf_parts(DEPOT / 'dock_door.glb')
    for mesh in document['meshes']:
        for primitive in mesh['primitives']:
            door_triangles += document['accessors'][primitive['indices']]['count'] // 3
    check(0 < door_triangles < 6000, 'depot/dock_door.glb bounded geometry (<6000 triangles)')
    check(not document.get('images'),
          'depot/dock_door.glb carries no textures (its wall is gone)')
    check((DEPOT / 'dock_door.glb').stat().st_size < FILE_LIMIT, 'The dock door file is under 25 MB')
print(f'GEOMETRY: depot/dock_door.glb: {door_triangles} triangles')


def image_size(data):
    if data[:8] == b'\x89PNG\r\n\x1a\n':
        return int.from_bytes(data[16:20], 'big'), int.from_bytes(data[20:24], 'big')
    if data[:2] == b'\xff\xd8':
        index = 2
        while index < len(data) - 9:
            marker = data[index + 1]
            length = int.from_bytes(data[index + 2:index + 4], 'big')
            if 0xC0 <= marker <= 0xCF and marker not in (0xC4, 0xC8, 0xCC):
                return (int.from_bytes(data[index + 7:index + 9], 'big'),
                        int.from_bytes(data[index + 5:index + 7], 'big'))
            index += 2 + length
    if data[:4] == b'RIFF':
        return webp_size(data)
    return (0, 0)


DEPOT_MODELS = {'dock_seal.glb': (2000, False), 'dock_leveller.glb': (12000, True),
                'forklift.glb': (12000, True), 'pallet_jack.glb': (8000, True),
                'pallet.glb': (6000, True), 'carton.glb': (1000, True)}
for name, (limit, textured) in DEPOT_MODELS.items():
    triangles = 0
    check((DEPOT / name).exists(), f'depot/{name} exists, made game-ready')
    if not (DEPOT / name).exists():
        continue
    document, binary = gltf_parts(DEPOT / name)
    for mesh in document['meshes']:
        for primitive in mesh['primitives']:
            triangles += document['accessors'][primitive['indices']]['count'] // 3
    sizes = []
    for image in document.get('images', []):
        view = document['bufferViews'][image['bufferView']]
        start = view.get('byteOffset', 0)
        sizes.append(max(image_size(binary[start:start + view['byteLength']])))
    check(0 < triangles < limit, f'depot/{name} bounded geometry (<{limit} triangles)')
    check(bool(sizes) == textured and all(0 < size <= 1024 for size in sizes),
          f'depot/{name} textures at most 1024 pixels ({len(sizes)})')
    print(f'GEOMETRY: depot/{name}: {triangles} triangles, textures {sizes}')
if (DEPOT / 'pallet_jack.glb').exists():
    document, _ = gltf_parts(DEPOT / 'pallet_jack.glb')
    nodes = {node.get('name'): (index, node) for index, node in enumerate(document['nodes'])}
    steering = nodes.get('Steering', (None, {}))
    tiller = nodes.get('Tiller', (None, {}))
    at = steering[1].get('translation', [0.0, 0.0, 0.0])
    foot = tiller[1].get('translation', [0.0, 0.0, 0.0])
    hinged = tiller[0] is not None and tiller[0] in steering[1].get('children', [])
    meshes = [name for name, (_, node) in nodes.items() if 'mesh' in node]
    check(sorted(meshes) == ['Chassis', 'Steering', 'Tiller'] and hinged
          and abs(at[0]) < 0.01 and abs(at[1]) < 0.01 and abs(at[2] - 0.689) < 0.01
          and abs(foot[0]) < 0.01 and abs(foot[1] - 0.30) < 0.01 and abs(foot[2] - 0.071) < 0.01,
          'depot/pallet_jack.glb turns and tilts as a real one: its frame, its steering unit '
          'turning on the pump\'s axis 0.689 m behind its middle, and its handle hinged inside it '
          f'at the shaft\'s foot, 0.30 m up (meshes {meshes}; steering at {at}, handle at {foot})')

print(f'ART RESULT: {len(failures)} failures')
raise SystemExit(1 if failures else 0)
