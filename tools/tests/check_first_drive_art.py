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
        return np.frombuffer(binary, dtype='<u4' if data['componentType'] == 5125 else '<f4',
                             offset=view.get('byteOffset', 0) + data.get('byteOffset', 0),
                             count=data['count'] * width).reshape(-1, width)

    triangles = 0
    all_points = []
    for index, primitive in enumerate(document['meshes'][0]['primitives']):
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

check(len(list(VAN.glob('*.glb'))) == 4 and len(list(WORLD.glob('*.glb'))) == 3,
      'All four vehicle assets and three depot props exist')

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
print(f'ART RESULT: {len(failures)} failures')
raise SystemExit(1 if failures else 0)
