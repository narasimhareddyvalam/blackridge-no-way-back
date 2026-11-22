"""Builds bare red alders (Alnus rubra) for the forest highway's roadside (#280), in winter as the
game's cold rain has them, as a glTF file for Godot.

Red alder as the US Forest Service's Silvics of North America describes it: the Pacific
Northwest's commonest broadleaf, first to take a cleared or disturbed edge such as a roadside;
a straight trunk, often a little leaning, running up into a narrow, rounded crown; small branches
angled upward; smooth, thin, light grey bark, often whitened by lichen
(`red_alder_bark_diff.jpg`, from tools/art/make_alder_bark.py). In winter the tree is bare, but
holds its woody seed cones (strobili, 1.5-3 cm, in clusters of 3-8) through the winter, and next
spring's male catkins hang from the twig tips already formed (5-10 cm, reddish brown).

Three trees, RedAlder1 to RedAlder3, 13, 16 and 19 m tall (red alders reach 20-25 m), each its
own seed, built as tubes along their branches, three orders of them: limbs from the trunk,
branches from the limbs and twigs from the branches (each with a far version, RedAlder1Far to
RedAlder3Far, for beyond 20 m: the trunk and limbs with fewer sides, no branches, twigs, cones
or catkins), each turning upward along its length as an
alder's branches do. The trunk is 0.012 of the height plus 2 cm in radius at the foot (0.21 m at
16 m: a 0.4 m trunk at breast height, as a 16 m second-growth alder's), with a flare at the foot,
and tapers to the top. Bark is mapped at its real size, 1.8 m a tile. Each tree stands with its
trunk's foot at the origin.

Usage, from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python-exit-code 1 \\
        --python tools/art/build_red_alder.py
"""

import math
import pathlib
import random

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = pathlib.Path.cwd()
TARGET = ROOT / "game/features/environments/industrial_loop/art/trees/red_alder.glb"
BARK = ROOT / "game/features/environments/industrial_loop/art/trees/red_alder_bark_diff.jpg"
BARK_NORMAL = ROOT / ("game/features/environments/industrial_loop/polyhaven/textures/"
                      "chinese_hackberry_bark/chinese_hackberry_bark_nor_gl_2k.jpg")
TREES = [("RedAlder1", 13.0, 2611), ("RedAlder2", 16.0, 2612), ("RedAlder3", 19.0, 2613)]
BARK_TILE = 1.8
CROWN_FROM = 0.38
LIMB_STEP = 0.42
GOLDEN = math.radians(137.5)
CATKIN = (0.35, 0.18, 0.14)
CONE = (0.20, 0.13, 0.08)
CATKIN_LENGTH = (0.05, 0.10)
CONE_SIZE = (0.015, 0.03)
FRUITING = 0.15
SIDES = {0: 10, 1: 5, 2: 4, 3: 3}
FAR_SIDES = {0: 6, 1: 4}


class Tube:
    def __init__(self) -> None:
        self.points: list = []
        self.radii: list = []


def material(name: str, colour: tuple, image: pathlib.Path | None = None,
             normal: pathlib.Path | None = None, roughness: float = 0.75):
    made = bpy.data.materials.new(name)
    made.use_nodes = True
    tree = made.node_tree
    shader = next(node for node in tree.nodes if node.type == "BSDF_PRINCIPLED")
    shader.inputs["Base Color"].default_value = colour + (1.0,)
    shader.inputs["Roughness"].default_value = roughness
    if image is not None:
        texture = tree.nodes.new("ShaderNodeTexImage")
        texture.image = bpy.data.images.load(str(image))
        tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])
    if normal is not None:
        texture = tree.nodes.new("ShaderNodeTexImage")
        texture.image = bpy.data.images.load(str(normal))
        texture.image.colorspace_settings.name = "Non-Color"
        mapping = tree.nodes.new("ShaderNodeNormalMap")
        tree.links.new(texture.outputs["Color"], mapping.inputs["Color"])
        tree.links.new(mapping.outputs["Normal"], shader.inputs["Normal"])
    return made


def trunk_radius(height: float, along: float) -> float:
    foot = 0.012 * height + 0.02
    flare = 1.0 + 0.55 * math.exp(-along * height / 0.45)
    return max(0.012, foot * (1.0 - 0.92 * along) ** 0.9 * flare)


def bend(start: Vector, heading: Vector, length: float, steps: int, rise: float,
         droop: float, wobble: float, rng: random.Random) -> list:
    points = [start.copy()]
    direction = heading.normalized()
    step = length / steps
    for index in range(steps):
        along = (index + 1) / steps
        direction = (direction + Vector((0.0, 0.0, rise * step - droop * step * along))
                     + Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-1, 1)))
                     * wobble * step).normalized()
        points.append(points[-1] + direction * step)
    return points


def frames(points: list) -> list:
    normals = []
    tangent = (points[1] - points[0]).normalized()
    normal = tangent.orthogonal().normalized()
    for index, point in enumerate(points):
        if 0 < index < len(points) - 1:
            next_tangent = (points[index + 1] - points[index - 1]).normalized()
        else:
            next_tangent = (points[min(index + 1, len(points) - 1)]
                            - points[max(index - 1, 0)]).normalized()
        axis = tangent.cross(next_tangent)
        if axis.length > 1e-6:
            angle = math.asin(min(1.0, axis.length))
            normal = (Matrix.Rotation(angle, 3, axis.normalized()) @ normal).normalized()
        tangent = next_tangent
        normals.append((tangent, normal, tangent.cross(normal).normalized()))
    return normals


def add_tube(mesh: bmesh.types.BMesh, uv, tube: Tube, sides: int, slot: int) -> None:
    rings = []
    along = 0.0
    for index, ((tangent, normal, binormal), point, radius) in enumerate(
            zip(frames(tube.points), tube.points, tube.radii)):
        if index > 0:
            along += (point - tube.points[index - 1]).length
        ring = []
        for side in range(sides + 1):
            angle = math.tau * side / sides
            offset = (normal * math.cos(angle) + binormal * math.sin(angle)) * radius
            vertex = mesh.verts.new(point + offset)
            ring.append((vertex, (side / sides * math.tau * max(radius, 0.01) / BARK_TILE,
                                  along / BARK_TILE)))
        rings.append(ring)
    for lower, upper in zip(rings, rings[1:]):
        for side in range(sides):
            corners = [lower[side], lower[side + 1], upper[side + 1], upper[side]]
            face = mesh.faces.new([corner[0] for corner in corners])
            face.material_index = slot
            for loop, corner in zip(face.loops, corners):
                loop[uv].uv = corner[1]


def grow(height: float, seed: int) -> tuple:
    rng = random.Random(seed)
    tubes = {0: [], 1: [], 2: [], 3: []}
    fruit = []
    lean = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), 0.0)).normalized() * math.radians(
        rng.uniform(1.0, 4.0))
    trunk = Tube()
    steps = 18
    for index in range(steps + 1):
        along = index / steps
        point = Vector((math.sin(lean.x) * along * height + 0.08 * math.sin(along * 7 + seed),
                        math.sin(lean.y) * along * height + 0.08 * math.cos(along * 5 + seed),
                        along * height))
        trunk.points.append(point)
        trunk.radii.append(trunk_radius(height, along) if index < steps else 0.004)
    tubes[0].append(trunk)
    z = CROWN_FROM * height
    turn = rng.random() * math.tau
    while z < height * 0.96:
        along = z / height
        crown = (along - CROWN_FROM) / (1.0 - CROWN_FROM)
        profile = math.sqrt(max(0.0, 1.0 - ((crown - 0.35) / 0.68) ** 2))
        length = height * 0.3 * profile * rng.uniform(0.8, 1.15) + 0.4
        base = trunk.points[0].lerp(trunk.points[-1], along)
        pitch = math.radians(rng.uniform(22, 35) + 30.0 * crown)
        heading = Vector((math.cos(turn) * math.cos(pitch), math.sin(turn) * math.cos(pitch),
                          math.sin(pitch)))
        limb = Tube()
        limb.points = bend(base, heading, length, 6, 0.10, 0.06 * (1.0 - crown), 0.25, rng)
        root = min(trunk_radius(height, along) * 0.55, 0.012 + 0.018 * length)
        limb.radii = [root * (1.0 - 0.9 * i / 6) for i in range(7)]
        tubes[1].append(limb)
        branch_off(limb, length, tubes, fruit, rng)
        turn += GOLDEN + rng.uniform(-0.3, 0.3)
        z += LIMB_STEP * rng.uniform(0.7, 1.3)
    return tubes, fruit


def branch_off(limb: Tube, length: float, tubes: dict, fruit: list,
               rng: random.Random) -> None:
    count = max(2, int(length * 2.2))
    for index in range(count):
        at = 0.25 + 0.7 * (index + rng.random() * 0.5) / count
        point_index = min(int(at * (len(limb.points) - 1)), len(limb.points) - 2)
        base = limb.points[point_index]
        forward = (limb.points[point_index + 1] - base).normalized()
        side = forward.cross(Vector((0.0, 0.0, 1.0)))
        if side.length < 1e-3:
            side = Vector((1.0, 0.0, 0.0))
        side = side.normalized() * (1 if index % 2 else -1)
        heading = (forward + side * rng.uniform(0.6, 1.0)
                   + Vector((0.0, 0.0, rng.uniform(0.2, 0.6)))).normalized()
        reach = length * (1.0 - at) * rng.uniform(0.45, 0.7) + 0.25
        branch = Tube()
        branch.points = bend(base, heading, reach, 3, 0.25, 0.0, 0.35, rng)
        root = max(0.006, limb.radii[point_index] * 0.55)
        branch.radii = [root * (1.0 - 0.85 * i / 3) for i in range(4)]
        tubes[2].append(branch)
        twigs(branch, reach, tubes, fruit, rng)


def twigs(branch: Tube, reach: float, tubes: dict, fruit: list, rng: random.Random) -> None:
    for index in range(max(2, int(reach * 3.0))):
        at = 0.3 + 0.65 * (index + rng.random() * 0.5) / max(2, int(reach * 3.0))
        point_index = min(int(at * (len(branch.points) - 1)), len(branch.points) - 2)
        base = branch.points[point_index]
        forward = (branch.points[point_index + 1] - base).normalized()
        heading = (forward + Vector((rng.uniform(-1, 1), rng.uniform(-1, 1),
                                     rng.uniform(0.1, 0.7)))).normalized()
        twig = Tube()
        twig.points = bend(base, heading, rng.uniform(0.2, 0.55), 1, 0.4, 0.0, 0.4, rng)
        twig.radii = [0.005, 0.0015]
        tubes[3].append(twig)
        if rng.random() < FRUITING:
            fruit.append((twig.points[-1], rng.random() < 0.5))


def add_fruit(mesh: bmesh.types.BMesh, uv, fruit: list, rng: random.Random) -> None:
    for tip, catkins in fruit:
        for index in range(rng.randint(2, 3) if catkins else rng.randint(3, 4)):
            hang = Vector((rng.uniform(-0.25, 0.25), rng.uniform(-0.25, 0.25), -1.0)).normalized()
            item = Tube()
            if catkins:
                length = rng.uniform(*CATKIN_LENGTH)
                item.points = [tip, tip + hang * length * 0.5, tip + hang * length]
                item.radii = [0.002, 0.0045, 0.0015]
                add_tube(mesh, uv, item, 3, 1)
            else:
                size = rng.uniform(*CONE_SIZE)
                start = tip + hang * 0.01
                item.points = [start, start + hang * size * 0.5, start + hang * size]
                item.radii = [0.002, size * 0.38, 0.001]
                add_tube(mesh, uv, item, 4, 2)


def build(name: str, height: float, seed: int, materials: list, far: bool = False):
    tubes, fruit = grow(height, seed)
    mesh = bmesh.new()
    uv = mesh.loops.layers.uv.new("UVMap")
    sides = FAR_SIDES if far else SIDES
    for order, items in tubes.items():
        if order in sides:
            for tube in items:
                add_tube(mesh, uv, tube, sides[order], 0)
    if not far:
        add_fruit(mesh, uv, fruit, random.Random(seed + 1))
    data = bpy.data.meshes.new(name)
    mesh.to_mesh(data)
    mesh.free()
    for item in materials:
        data.materials.append(item)
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    for polygon in data.polygons:
        polygon.use_smooth = True
    data.calc_loop_triangles()
    print("BUILT %s: %.1f m, %d limbs, %d branches, %d twigs, %d with cones or catkins, "
          "%d triangles" % (name, height, len(tubes[1]), len(tubes[2]), len(tubes[3]),
                            len(fruit), len(data.loop_triangles)))
    return obj


def main() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    materials = [material("AlderBark", (1.0, 1.0, 1.0), BARK, BARK_NORMAL, 0.7),
                 material("AlderCatkin", CATKIN), material("AlderCone", CONE, roughness=0.85)]
    made = [build(name, height, seed, materials) for name, height, seed in TREES]
    made += [build(name + "Far", height, seed, materials, True) for name, height, seed in TREES]
    for obj in bpy.context.scene.objects:
        obj.select_set(obj in made)
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(TARGET), export_format="GLB", use_selection=True,
                              use_active_scene=True, export_apply=True, export_yup=True,
                              export_cameras=False, export_lights=False,
                              export_image_format="WEBP", export_jpeg_quality=90)
    print("WROTE %s, %.1f kB" % (TARGET, TARGET.stat().st_size / 1e3))


if __name__ == "__main__":
    main()
