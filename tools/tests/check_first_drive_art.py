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
print(f'ART RESULT: {len(failures)} failures')
raise SystemExit(1 if failures else 0)
