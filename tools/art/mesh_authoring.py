import json
import math
import struct
from pathlib import Path

import numpy as np
from PIL import Image


def png(path, values):
    Image.fromarray(np.uint8(np.clip(values, 0, 1) * 255)).save(path)


class Asset:
    def __init__(self):
        self.surfaces = {}

    def face(self, material, vertices, normals, uv=None):
        surface = self.surfaces.setdefault(material, [[], [], [], []])
        start = len(surface[0])
        surface[0].extend(vertices)
        surface[1].extend(normals)
        surface[2].extend(uv if uv is not None else [(0, 0)] * len(vertices))
        surface[3].extend([start, start + 1, start + 2])
        if len(vertices) == 4:
            surface[3].extend([start, start + 2, start + 3])

    def export(self, destination, materials):
        destination = Path(destination)
        binary = bytearray()
        views, accessors, images, textures, definitions = [], [], [], [], []

        def buffer(values, kind, component=5126):
            values = np.array(values, dtype='<u4' if component == 5125 else '<f4')
            while len(binary) % 4:
                binary.append(0)
            offset = len(binary)
            binary.extend(values.tobytes())
            views.append({'buffer': 0, 'byteOffset': offset, 'byteLength': values.nbytes})
            entry = {'bufferView': len(views) - 1, 'componentType': component,
                     'count': len(values), 'type': kind}
            if kind == 'VEC3':
                entry['min'] = values.min(axis=0).tolist()
                entry['max'] = values.max(axis=0).tolist()
            accessors.append(entry)
            return len(accessors) - 1

        def image(path):
            path = Path(path)
            for index, existing in enumerate(images):
                if existing.get('name') == path.name:
                    return index
            while len(binary) % 4:
                binary.append(0)
            offset = len(binary)
            payload = path.read_bytes()
            binary.extend(payload)
            views.append({'buffer': 0, 'byteOffset': offset, 'byteLength': len(payload)})
            images.append({'bufferView': len(views) - 1, 'mimeType': 'image/png',
                           'name': path.name})
            textures.append({'source': len(images) - 1, 'sampler': 0})
            return len(images) - 1

        primitives = []
        triangles = 0
        for name, (vertices, normals, uvs, indices) in self.surfaces.items():
            source = materials[name]
            definition = {'name': name, 'pbrMetallicRoughness': {
                'baseColorFactor': [*source['rgb'], 1],
                'metallicFactor': source['metallic'], 'roughnessFactor': source['roughness']}}
            if source.get('normal'):
                definition['normalTexture'] = {'index': image(source['normal']), 'scale': 0.4}
            if source.get('orm'):
                definition['pbrMetallicRoughness']['metallicRoughnessTexture'] = {
                    'index': image(source['orm'])}
            if source.get('albedo'):
                definition['pbrMetallicRoughness']['baseColorTexture'] = {
                    'index': image(source['albedo'])}
                definition['alphaMode'] = 'MASK'
                definition['alphaCutoff'] = 0.4
            definitions.append(definition)
            primitives.append({'attributes': {'POSITION': buffer(vertices, 'VEC3'),
                               'NORMAL': buffer(normals, 'VEC3'),
                               'TEXCOORD_0': buffer(uvs, 'VEC2')},
                               'indices': buffer(indices, 'SCALAR', 5125),
                               'material': len(definitions) - 1})
            triangles += len(indices) // 3
        while len(binary) % 4:
            binary.append(0)
        document = {'asset': {'version': '2.0', 'generator': 'Blackridge mesh_authoring.py'},
                    'scene': 0, 'scenes': [{'nodes': [0]}],
                    'nodes': [{'name': destination.stem, 'mesh': 0}],
                    'meshes': [{'primitives': primitives}],
                    'materials': definitions, 'buffers': [{'byteLength': len(binary)}],
                    'bufferViews': views, 'accessors': accessors}
        if images:
            document.update(images=images, textures=textures,
                            samplers=[{'magFilter': 9729, 'minFilter': 9987,
                                       'wrapS': 10497, 'wrapT': 10497}])
        encoded = json.dumps(document, separators=(',', ':')).encode()
        encoded += b' ' * (-len(encoded) % 4)
        total = 12 + 8 + len(encoded) + 8 + len(binary)
        destination.write_bytes(struct.pack('<III', 0x46546C67, 2, total)
                                + struct.pack('<II', len(encoded), 0x4E4F534A) + encoded
                                + struct.pack('<II', len(binary), 0x004E4942) + binary)
        return triangles


def unit(value):
    value = np.array(value, dtype=float)
    return value / max(np.linalg.norm(value), 1e-10)


def rounded_box(asset, at, size, material, radius):
    half = np.array(size) * 0.5
    at = np.array(at)
    radius = min(radius, min(half) * 0.9)
    inner = half - radius
    for axis in range(3):
        u, v = (axis + 1) % 3, (axis + 2) % 3
        for sign in (-1, 1):
            samples_u = sorted(set([-half[u], -inner[u], -inner[u] - radius * 0.5,
                                    inner[u], inner[u] + radius * 0.5, half[u]]))
            samples_v = sorted(set([-half[v], -inner[v], -inner[v] - radius * 0.5,
                                    inner[v], inner[v] + radius * 0.5, half[v]]))
            for i in range(len(samples_u) - 1):
                for j in range(len(samples_v) - 1):
                    coords = [(samples_u[i], samples_v[j]), (samples_u[i+1], samples_v[j]),
                              (samples_u[i+1], samples_v[j+1]), (samples_u[i], samples_v[j+1])]
                    vertices, normals, uv = [], [], []
                    for a, b in coords:
                        point = np.zeros(3)
                        point[axis], point[u], point[v] = sign * half[axis], a, b
                        core = np.clip(point, -inner, inner)
                        normal = unit(point - core)
                        vertices.append((at + core + normal * radius).tolist())
                        normals.append(normal.tolist())
                        uv.append((a * 6, b * 6))
                    if sign < 0:
                        vertices.reverse()
                        normals.reverse()
                        uv.reverse()
                    asset.face(material, vertices, normals, uv)


def tube(asset, at, radius, depth, material, axis, segments):
    direction = unit(axis)
    u = unit(np.cross(direction, (0, 1, 0) if abs(direction[1]) < 0.9 else (1, 0, 0)))
    v = np.cross(direction, u)
    at = np.array(at)
    for i in range(segments):
        a, b = i * math.tau / segments, (i + 1) * math.tau / segments
        n0, n1 = u * math.cos(a) + v * math.sin(a), u * math.cos(b) + v * math.sin(b)
        points = [at + n0 * radius - direction * depth / 2,
                  at + n1 * radius - direction * depth / 2,
                  at + n1 * radius + direction * depth / 2,
                  at + n0 * radius + direction * depth / 2]
        asset.face(material, points, [n0, n1, n1, n0],
                   [(i / segments, 0), ((i+1) / segments, 0),
                    ((i+1) / segments, 1), (i / segments, 1)])
        for sign in (-1, 1):
            cap = [at + direction * sign * depth / 2,
                   at + n0 * radius + direction * sign * depth / 2,
                   at + n1 * radius + direction * sign * depth / 2]
            if sign < 0:
                cap.reverse()
            asset.face(material, cap, [direction * sign] * 3)


def ring(asset, at, radius, thickness, material, axis):
    direction = unit(axis)
    u = unit(np.cross(direction, (0, 1, 0) if abs(direction[1]) < 0.9 else (1, 0, 0)))
    v = np.cross(direction, u)
    at = np.array(at)
    for i in range(48):
        for j in range(10):
            vertices, normals, uvs = [], [], []
            for k, m in ((i, j), (i+1, j), (i+1, j+1), (i, j+1)):
                a, b = math.tau * k / 48, math.tau * m / 10
                radial = u * math.cos(a) + v * math.sin(a)
                normal = radial * math.cos(b) + direction * math.sin(b)
                vertices.append(at + radial * radius + normal * thickness)
                normals.append(normal)
                uvs.append((k / 48 * 8, m / 10))
            asset.face(material, vertices, normals, uvs)


def extrude(asset, outline, low, high, material):
    outline = np.array(outline, dtype=float)
    area = sum(outline[i, 0] * outline[(i+1) % len(outline), 1]
               - outline[(i+1) % len(outline), 0] * outline[i, 1]
               for i in range(len(outline)))
    if area < 0:
        outline = outline[::-1]
    indices = list(range(len(outline)))
    faces = []
    def cross(a, b, c):
        return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
    while len(indices) > 3:
        found = False
        for j, b in enumerate(indices):
            a, c = indices[j-1], indices[(j+1) % len(indices)]
            if cross(outline[a], outline[b], outline[c]) <= 1e-9:
                continue
            others = [k for k in indices if k not in (a, b, c)]
            if any(all(cross(outline[p], outline[q], outline[k]) >= -1e-9
                       for p, q in ((a, b), (b, c), (c, a))) for k in others):
                continue
            faces.append((a, b, c))
            indices.pop(j)
            found = True
            break
        if not found:
            raise ValueError('Cannot triangulate authoring outline')
    faces.append(tuple(indices))
    for x, sign in ((low, -1), (high, 1)):
        for face in faces:
            sequence = face if sign < 0 else face[::-1]
            asset.face(material, [(x, outline[i, 1], outline[i, 0]) for i in sequence],
                       [(sign, 0, 0)] * 3, [(outline[i, 0]*6, outline[i, 1]*6) for i in sequence])
    for i in range(len(outline)):
        a, b = outline[i], outline[(i+1) % len(outline)]
        normal = unit((0, a[0]-b[0], b[1]-a[1]))
        asset.face(material, [(low, a[1], a[0]), (high, a[1], a[0]),
                             (high, b[1], b[0]), (low, b[1], b[0])], [normal]*4)
