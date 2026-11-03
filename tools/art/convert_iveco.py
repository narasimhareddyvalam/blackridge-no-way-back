"""Convert the Sketchfab Iveco Daily into the game's van (decision C31).

The source is Blender's export of "Iveco Daily Van 2014" by Max (CC BY 4.0;
`source_assets/sketchfab/iveco_daily_2014/README.md`), which stays out of Git. This writes two
committed files into `game/features/vehicles/freight_van/art/iveco/`:

- `iveco_exterior.glb`: `Body`, its clear glass (`BodyGlass`: the headlight covers, the
  reflectors and the bulkhead window), the lamp lenses (`Headlights`, `TailLamps`, and the
  indicators `FrontIndicatorLeft`, `FrontIndicatorRight`, `RearIndicatorLeft` and
  `RearIndicatorRight`), the `Windshield` glass, both front doors with their windows
  (`DriverDoor/DriverWindow`, `PassengerDoor/PassengerWindow`) and the wheels
  (`WheelFrontLeft`, `WheelFrontRight`, `WheelRearLeft`, `WheelRearRight`);
- `iveco_cab.glb`: the cab interior (`Cab`) and the `SteeringWheel`.

The conversion:

- bakes the model's real-size transform into its meshes and turns the van half a turn, so it
  faces Godot's -Z with the driver's seat on the left (-X) and the tyres on y = 0;
- removes the raised IVECO letters from the grille and the rear door, and the van's own
  wipers, which the game's wipers replace;
- paints out the name where the textures carry it: on the grille behind those letters, on a
  rear door and on the steering-wheel badge. Texels that only the removed letters used turn
  plain grey;
- paints the Blackridge plate from `tools/make_number_plate.py` over the model's French plate
  ("MA-222-AX", with "DAILY" on its strip), and adds the same plate on the driver's-side rear
  door, which had none;
- splits out the parts that move, each with its own origin: the doors swing about their
  hinges (local Y), the wheels turn about their centres (local X), and the steering wheel
  turns about its column (local Z, which points up the column at the driver);
- splits the lamp lenses from the clear glass, so the game can light them. The top of each
  tail lamp is its indicator;
- cuts the moon roof's opening through the roof and the headliner over the front seats
  (decision C32); the game adds the glass and its frame;
- halves the exterior textures to 2048 pixels and quarters the cab's to 1024, as WebP.

Usage, from the repository root:
    python3 -I tools/make_number_plate.py
    /Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \\
        --python-exit-code 1 --python tools/art/convert_iveco.py

A folder named after `--` receives the files instead, for a trial run.
"""

import math
import pathlib
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

SOURCE = pathlib.Path("source_assets/sketchfab/iveco_daily_2014/iveco_daily_van_2014.gltf")
PLATE = pathlib.Path("source_assets/artwork/number_plate.png")
OUT = pathlib.Path("game/features/vehicles/freight_van/art/iveco")
QUALITY = 90
TURN = Matrix.Rotation(math.pi, 4, "Z")
SAME_PLACE = 1e-4
CAB_MATERIALS = {"Body_Interior", "Dashboard", "Interior", "Interior_2"}
EXTERIOR_TEXTURE = 2048
CAB_TEXTURE = 1024
GRILLE_LETTERS = ((-0.25, 2.85, 0.97), (0.25, 2.95, 1.08))
REAR_LETTERS = ((-0.62, -2.34, 0.87), (-0.36, -2.32, 0.93))
WIPERS = ((-0.75, 2.08, 1.30), (0.75, 2.32, 1.50))
WINDSHIELD = ((-1.0, 1.5, 1.4), (1.0, 2.2, 1.9))
FRONT_PLATE = ((-0.3, 3.0, 0.35), (0.3, 3.05, 0.48))
LAMPS = {"Headlights": (((-0.8, 2.40, 0.95), (0.8, 2.65, 1.15)), 100),
         "FrontIndicators": (((-0.9, 2.28, 1.05), (0.9, 2.40, 1.15)), 50),
         "TailLamps": (((-0.95, -2.30, 0.6), (0.95, -2.20, 1.45)), 50)}
REAR_INDICATORS_ABOVE = 1.22
MOON_ROOF = ((-0.52, 0.86), (0.52, 1.30))
ROOF_ABOVE = 1.95
ROOF_MARGIN = 0.3
REAR_PLATE = (-0.30, 0.62)
PLATE_GAP = 0.004
STEERING_SEARCH = ((-0.7, 1.4, 1.0), (-0.25, 1.9, 1.6))
STEERING_DEPTH = 0.03
STEERING_REACH = 0.2
DOORS = {"DriverDoor": ("Front_door_L", "DriverWindow"),
         "PassengerDoor": ("Front_door_R", "PassengerWindow")}
NAME_LETTERS = {"Body_exterior_1": [(0.284, 0.951, 0.365, 0.967),
                                    (0.725, 0.946, 0.801, 0.979)],
                "Back_door": [(0.636, 0.376, 0.737, 0.405)]}
HUB_BADGE = ("Interior", (0.70, 0.825, 0.93, 0.875))
PLATE_AREA = ("Other", (0.5691, 0.1794, 0.9233, 0.2546))
LETTER_BAKES = [("Other", (0.74, 0.66, 0.985, 0.875)),
                ("Back_door", (0.349, 0.691, 0.576, 0.837))]
MARGIN = 8
NAME_GROWTH = 28
BADGE_GROWTH = 3
SLOT_OPENING = 2
ROW_BLUR = 9
SMOOTHING = 24
UNUSED_REACH = 4
NEIGHBOURS = ((1, 0), (-1, 0), (0, 1), (0, -1))


def selected(objects):
    return bpy.context.temp_override(active_object=objects[0], object=objects[0],
                                     selected_objects=objects,
                                     selected_editable_objects=objects)


def apply_transform(objects):
    with selected(objects):
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def bake():
    hinges = {o.name: (TURN @ o.matrix_world).translation.copy()
              for o in bpy.data.objects if o.type == "EMPTY"}
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    for item in meshes:
        if item.data.users > 1:
            item.data = item.data.copy()
        world = TURN @ item.matrix_world
        item.parent = None
        item.matrix_world = world
    apply_transform(meshes)
    for item in [o for o in bpy.data.objects if o.type != "MESH"]:
        bpy.data.objects.remove(item)
    return {o.name: o for o in meshes}, hinges


def points(item):
    flat = np.empty(len(item.data.vertices) * 3)
    item.data.vertices.foreach_get("co", flat)
    return flat.reshape(-1, 3)


def parts(item):
    mesh = item.data
    where = points(item)
    place = np.unique(np.round(where / SAME_PLACE).astype(np.int64), axis=0,
                      return_inverse=True)[1].ravel()
    root = list(range(len(mesh.polygons)))

    def find(face):
        while root[face] != face:
            root[face] = root[root[face]]
            face = root[face]
        return face

    first = {}
    for polygon in mesh.polygons:
        for vertex in polygon.vertices:
            other = first.setdefault(place[vertex], polygon.index)
            root[find(other)] = find(polygon.index)
    groups = {}
    for polygon in mesh.polygons:
        groups.setdefault(find(polygon.index), []).append(polygon.index)
    found = []
    for faces in groups.values():
        corners = where[[v for face in faces for v in mesh.polygons[face].vertices]]
        found.append((set(faces), corners.min(0), corners.max(0)))
    return found


def inside(box, point):
    return all(box[0][axis] <= point[axis] <= box[1][axis] for axis in range(3))


def faces_in(item, box, what):
    found = set().union(*[faces for faces, low, high in parts(item)
                          if inside(box, (low + high) / 2)])
    if not found:
        raise RuntimeError(f"Found no {what} in {item.name}; has the source model changed?")
    return found


def keep_faces(item, faces):
    mesh = bmesh.new()
    mesh.from_mesh(item.data)
    mesh.faces.ensure_lookup_table()
    bmesh.ops.delete(mesh, geom=[f for f in mesh.faces if f.index not in faces],
                     context="FACES")
    mesh.to_mesh(item.data)
    mesh.free()


def copy_faces(item, faces, name):
    part = item.copy()
    part.data = item.data.copy()
    part.name = part.data.name = name
    bpy.context.scene.collection.objects.link(part)
    keep_faces(part, faces)
    return part


def split(item, faces, name):
    part = copy_faces(item, faces, name)
    keep_faces(item, set(range(len(item.data.polygons))) - faces)
    return part


def join(objects, name):
    with selected(objects):
        bpy.ops.object.join()
    objects[0].name = objects[0].data.name = name
    return objects[0]


def place_origin(item, frame):
    item.matrix_world = frame.inverted() @ item.matrix_world
    apply_transform([item])
    item.matrix_world = frame


def rear_plate(other):
    front = copy_faces(other, faces_in(other, FRONT_PLATE, "front plate"), "RearPlate")
    low, high = points(front).min(0), points(front).max(0)
    centre = Vector((low + high) / 2)
    half = Vector((high - low) / 2)
    x, z = REAR_PLATE
    graph = bpy.context.evaluated_depsgraph_get()
    surface = min(bpy.context.scene.ray_cast(graph, Vector((x + dx, -4.0, z + dz)),
                                             Vector((0, 1, 0)))[1].y
                  for dx in (-half.x, 0, half.x) for dz in (-half.z, 0, half.z))
    target = Vector((x, surface - PLATE_GAP - half.y, z))
    print(f"Rear plate: door surface at y {surface:.3f}, "
          f"plate centre {tuple(round(v, 3) for v in target)}")
    front.matrix_world = (Matrix.Translation(target) @ TURN @ Matrix.Translation(-centre))
    apply_transform([front])
    return front


def lamps(glass):
    made = []
    for name, (box, smallest) in LAMPS.items():
        faces = set()
        for part, low, high in parts(glass):
            triangles = sum(len(glass.data.polygons[face].vertices) - 2 for face in part)
            if inside(box, (low + high) / 2) and triangles >= smallest:
                faces |= part
        if not faces:
            raise RuntimeError(f"Found no {name} in {glass.name}; has the source model changed?")
        made.append(split(glass, faces, name))
    tail = made[-1]
    top = {p.index for p in tail.data.polygons if p.center.z > REAR_INDICATORS_ABOVE}
    made.append(split(tail, top, "RearIndicators"))
    for group in [o for o in made if o.name.endswith("Indicators")]:
        left = {p.index for p in group.data.polygons if p.center.x < 0.0}
        made.append(split(group, left, group.name.replace("Indicators", "IndicatorLeft")))
        group.name = group.data.name = group.name.replace("Indicators", "IndicatorRight")
    glass.name = glass.data.name = "BodyGlass"
    return made


def cut_roof(item):
    (x0, y0), (x1, y1) = MOON_ROOF
    mesh = bmesh.new()
    mesh.from_mesh(item.data)

    def near_roof(face, reach):
        centre = face.calc_center_median()
        return (centre.z > ROOF_ABOVE and x0 - reach < centre.x < x1 + reach
                and y0 - reach < centre.y < y1 + reach)

    for point, normal in (((x0, 0, 0), (1, 0, 0)), ((x1, 0, 0), (1, 0, 0)),
                          ((0, y0, 0), (0, 1, 0)), ((0, y1, 0), (0, 1, 0))):
        faces = [f for f in mesh.faces if near_roof(f, ROOF_MARGIN)]
        edges = list({e for f in faces for e in f.edges})
        verts = list({v for f in faces for v in f.verts})
        bmesh.ops.bisect_plane(mesh, geom=faces + edges + verts, plane_co=point,
                               plane_no=normal)
    opening = [f for f in mesh.faces if near_roof(f, 0.0)]
    bmesh.ops.delete(mesh, geom=opening, context="FACES")
    mesh.to_mesh(item.data)
    mesh.free()
    return len(opening)


def steering_wheel(interior):
    found = parts(interior)
    near = [part for part in found if inside(STEERING_SEARCH, (part[1] + part[2]) / 2)]
    rim = max(near, key=lambda part: len(part[0]))
    mesh = interior.data
    ring = points(interior)[sorted({v for face in rim[0] for v in mesh.polygons[face].vertices})]
    centre = ring.mean(0)
    column = Vector(np.linalg.svd(ring - centre)[2][2]).normalized()
    if column.y > 0:
        column = -column
    right = Vector((1, 0, 0))
    right = (right - column * right.dot(column)).normalized()
    frame = Matrix((right, -column, column.cross(right))).transposed().to_4x4()
    frame.translation = Vector(centre)
    faces = set()
    for part, low, high in found:
        offset = Vector((low + high) / 2) - frame.translation
        along = offset.dot(column)
        if abs(along) <= STEERING_DEPTH and (offset - column * along).length <= STEERING_REACH:
            faces |= part
    wheel = split(interior, faces, "SteeringWheel")
    place_origin(wheel, frame)
    return wheel


def wheels(item):
    found = parts(item)
    made = []
    for side, x_sign in (("Left", -1), ("Right", 1)):
        for end, y_sign in (("Front", 1), ("Rear", -1)):
            group = [part for part in found
                     if np.sign((part[1] + part[2])[0]) == x_sign
                     and np.sign((part[1] + part[2])[1]) == y_sign]
            tyre = max(group, key=lambda part: len(part[0]))
            wheel = copy_faces(item, set().union(*[part[0] for part in group]),
                               f"Wheel{end}{side}")
            place_origin(wheel, Matrix.Translation(Vector((tyre[1] + tyre[2]) / 2)))
            made.append(wheel)
    bpy.data.objects.remove(item)
    return made


def doors(objects, hinges):
    made = []
    for name, (prefix, window_name) in DOORS.items():
        pieces = [o for key, o in objects.items() if key.startswith(prefix + "_")]
        window = next(o for o in pieces if "Window" in o.name)
        door = join([o for o in pieces if o is not window], name)
        window.name = window.data.name = window_name
        frame = Matrix.Translation(hinges[prefix])
        place_origin(door, frame)
        place_origin(window, frame)
        window.parent = door
        window.matrix_parent_inverse = Matrix.Identity(4)
        window.matrix_basis = Matrix.Identity(4)
        made.append(door)
    return made


def maps(material):
    found = []
    for node in bpy.data.materials[material].node_tree.nodes:
        if node.type == "TEX_IMAGE" and node.image and node.image not in found:
            found.append(node.image)
    return sorted(found, key=lambda image: "baseColor" not in image.name)


def pixels(image):
    width, height = image.size
    data = np.empty(width * height * 4, np.float32)
    image.pixels.foreach_get(data)
    return data.reshape(height, width, 4)


def store(image, data):
    image.pixels.foreach_set(np.ascontiguousarray(data, np.float32).ravel())
    image.update()


def window_of(data, rect, margin=MARGIN):
    height, width = data.shape[:2]
    x0, y0 = int(rect[0] * width) - margin, int(rect[1] * height) - margin
    x1, y1 = int(rect[2] * width) + margin, int(rect[3] * height) + margin
    inner = np.zeros((y1 - y0, x1 - x0), bool)
    inner[margin:-margin or None, margin:-margin or None] = True
    return (slice(y0, y1), slice(x0, x1)), inner


def grow(mask, steps):
    for _ in range(steps):
        mask = mask | np.logical_or.reduce([np.roll(mask, shift, (0, 1)) for shift in NEIGHBOURS])
    return mask


def opened(mask, steps):
    return grow(~grow(~mask, steps), steps)


def fill(area, mask, source):
    known = source & ~mask
    value = np.where(known[..., None], area, 0.0)
    todo = mask.copy()
    while todo.any():
        total = np.zeros_like(area)
        count = np.zeros(mask.shape)
        for shift in NEIGHBOURS:
            near = np.roll(known, shift, (0, 1))
            total += np.where(near[..., None], np.roll(value, shift, (0, 1)), 0.0)
            count += near
        ready = todo & (count > 0)
        if not ready.any():
            break
        value[ready] = total[ready] / count[ready][:, None]
        known |= ready
        todo &= ~ready
    value[~mask] = area[~mask]
    for _ in range(SMOOTHING):
        blurred = sum(np.roll(value, shift, (0, 1)) for shift in NEIGHBOURS) / 4.0
        value[mask] = blurred[mask]
    area[mask] = value[mask]
    return int(mask.sum())


def painted_name(colour, rect):
    where, letters = window_of(colour, rect, NAME_GROWTH + MARGIN)
    area = colour[where]
    light = area[..., :3].mean(-1)
    warmth = area[..., 0] - area[..., 2]
    slot = opened((light < 120 / 255) & (warmth < 20 / 255), SLOT_OPENING)
    core = (warmth >= 20 / 255) & (light < 200 / 255) & letters
    mask = grow(core, NAME_GROWTH) & ~slot
    return where, mask, (light > 170 / 255) & ~mask


def badge_letters(colour, rect):
    where, _ = window_of(colour, rect, 0)
    dark = colour[where][..., :3].mean(-1) < 45 / 255
    outside = np.zeros_like(dark)
    outside[[0, -1], :] = outside[:, [0, -1]] = True
    outside &= ~dark
    while True:
        spread = grow(outside, 1) & ~dark
        if (spread == outside).all():
            break
        outside = spread
    mask = grow(~dark & ~outside, BADGE_GROWTH) & ~outside
    return where, mask, dark & ~mask


def fill_rows(area, mask, source):
    weight = source & ~mask
    kernel = np.ones(ROW_BLUR)
    total = np.apply_along_axis(np.convolve, 1, area * weight[..., None], kernel, "same")
    count = np.apply_along_axis(np.convolve, 1, weight.astype(float), kernel, "same")
    smooth = total / np.maximum(count, 1)[..., None]
    for row in np.nonzero(mask.any(1))[0]:
        known = np.nonzero(weight[row])[0]
        holes = np.nonzero(mask[row])[0]
        if not len(known):
            continue
        for channel in range(area.shape[2]):
            area[row, holes, channel] = np.interp(holes, known, smooth[row, known, channel])
    return int(mask.sum())


def paint_out(material, rect, letters, method):
    images = maps(material)
    colour = pixels(images[0])
    where, mask, source = letters(colour, rect)
    for image in images:
        data = colour if image is images[0] else pixels(image)
        method(data[where], mask, source)
        store(image, data)
    return int(mask.sum())


def paint_plate(data, rect, front):
    where, _ = window_of(data, rect, 0)
    height, width = data[where].shape[:2]
    plate = bpy.data.images.load(str(PLATE.resolve()))
    plate.scale(width, height)
    picture = pixels(plate)
    corners = []
    uv = front.data.uv_layers.active.data
    for polygon in front.data.polygons:
        if polygon.normal.y > 0.9:
            for loop in polygon.loop_indices:
                vertex = front.data.loops[loop].vertex_index
                corners.append((*front.data.vertices[vertex].co, *uv[loop].uv))
    corners = np.array(corners)
    if corners[corners[:, 0].argmax(), 3] > corners[corners[:, 0].argmin(), 3]:
        picture = picture[:, ::-1]
    if corners[corners[:, 2].argmax(), 4] < corners[corners[:, 2].argmin(), 4]:
        picture = picture[::-1]
    data[where][..., :3] = picture[..., :3]
    bpy.data.images.remove(plate)
    return width, height


def used_texels(material, data, rect):
    where, _ = window_of(data, rect, 0)
    height, width = data.shape[:2]
    rows, columns = where
    used = np.zeros((rows.stop - rows.start, columns.stop - columns.start), bool)
    for item in [o for o in bpy.data.objects if o.type == "MESH"]:
        mesh = item.data
        if material not in [m.name for m in mesh.materials if m]:
            continue
        mesh.calc_loop_triangles()
        flat = np.empty(len(mesh.loops) * 2)
        mesh.uv_layers.active.data.foreach_get("uv", flat)
        uv = flat.reshape(-1, 2) * (width, height)
        for triangle in mesh.loop_triangles:
            if mesh.materials[triangle.material_index].name != material:
                continue
            a, b, c = uv[list(triangle.loops)]
            low = np.floor(np.minimum(np.minimum(a, b), c)).astype(int)
            high = np.ceil(np.maximum(np.maximum(a, b), c)).astype(int)
            xs = np.arange(max(low[0], columns.start), min(high[0], columns.stop))
            ys = np.arange(max(low[1], rows.start), min(high[1], rows.stop))
            area = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
            if not len(xs) or not len(ys) or abs(area) < 1e-9:
                continue
            gx, gy = np.meshgrid(xs + 0.5, ys + 0.5)
            first = ((b[1] - c[1]) * (gx - c[0]) + (c[0] - b[0]) * (gy - c[1])) / area
            second = ((c[1] - a[1]) * (gx - c[0]) + (a[0] - c[0]) * (gy - c[1])) / area
            hit = (first >= -0.02) & (second >= -0.02) & (1 - first - second >= -0.02)
            used[np.ix_(ys - rows.start, xs - columns.start)] |= hit
    return where, used


def grey_unused(material, rect):
    images = maps(material)
    where, used = used_texels(material, pixels(images[0]), rect)
    spare = ~grow(used, UNUSED_REACH)
    for image in images:
        data = pixels(image)
        area = data[where]
        area[spare, :3] = area[used, :3].mean(0)
        store(image, data)
    return int(spare.sum())


def paint_textures(front_plate):
    for material, rects in NAME_LETTERS.items():
        for rect in rects:
            count = paint_out(material, rect, painted_name, fill_rows)
            print(f"  {material}: painted out {count} texels of the name in each map")
    material, rect = HUB_BADGE
    print(f"  {material}: painted out {paint_out(material, rect, badge_letters, fill)} texels "
          "of the hub badge in each map")
    material, rect = PLATE_AREA
    image = maps(material)[0]
    data = pixels(image)
    print(f"  {material}: plate painted at {paint_plate(data, rect, front_plate)} texels")
    store(image, data)
    for material, rect in LETTER_BAKES:
        print(f"  {material}: {grey_unused(material, rect)} texels only the letters used, grey")


def shrink(image, size):
    width = image.size[0]
    if width <= size:
        return
    factor = width // size
    small = pixels(image).reshape(size, factor, size, factor, 4).mean((1, 3))
    image.scale(size, size)
    store(image, small)


def shrink_textures():
    for material in bpy.data.materials:
        if not material.node_tree:
            continue
        size = CAB_TEXTURE if material.name in CAB_MATERIALS else EXTERIOR_TEXTURE
        for node in material.node_tree.nodes:
            if node.type == "TEX_IMAGE" and node.image:
                shrink(node.image, size)


def out_folder():
    if "--" in sys.argv[:-1]:
        return pathlib.Path(sys.argv[sys.argv.index("--") + 1])
    return OUT


def export(objects, name):
    for item in bpy.data.objects:
        item.select_set(False)
    for item in objects:
        item.select_set(True)
        for child in item.children:
            child.select_set(True)
    out_folder().mkdir(parents=True, exist_ok=True)
    target = out_folder() / f"{name}.glb"
    bpy.ops.export_scene.gltf(filepath=str(target), export_format="GLB", use_selection=True,
                              export_image_format="WEBP", export_image_quality=QUALITY,
                              export_apply=False, export_yup=True, export_animations=False,
                              export_cameras=False, export_lights=False, export_extras=False)
    triangles = sum(sum(len(p.vertices) - 2 for p in o.data.polygons)
                    for o in objects + [c for o in objects for c in o.children])
    print(f"Wrote {target}: {target.stat().st_size / 1e6:.1f} MB, {triangles} triangles")
    for item in objects + [c for o in objects for c in o.children]:
        place = item.matrix_world.translation
        print(f"  {item.name}: origin ({place.x:.3f}, {place.y:.3f}, {place.z:.3f}) Blender, "
              f"{sum(len(p.vertices) - 2 for p in item.data.polygons)} triangles")


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE.resolve()))
    objects, hinges = bake()
    other = objects["Other_Other_0"]
    letters = faces_in(other, GRILLE_LETTERS, "grille letters")
    blades = faces_in(other, WIPERS, "wipers")
    keep_faces(other, set(range(len(other.data.polygons))) - letters - blades)
    rear_door = objects["Back_door_1_Back door_0"]
    rear_letters = faces_in(rear_door, REAR_LETTERS, "rear-door letters")
    keep_faces(rear_door, set(range(len(rear_door.data.polygons))) - rear_letters)
    print(f"Removed {len(letters)} grille-letter faces, {len(rear_letters)} rear-door letter "
          f"faces and {len(blades)} wiper faces")
    front_plate = copy_faces(other, faces_in(other, FRONT_PLATE, "front plate"), "FrontPlateUV")
    plate = rear_plate(other)
    glass = objects["Window_Window_0"]
    windshield = split(glass, faces_in(glass, WINDSHIELD, "windshield"), "Windshield")
    lenses = lamps(glass)
    wheel_parts = wheels(objects.pop("Wheel_Wheel_0"))
    steering = steering_wheel(objects["Interior_Interior_0"])
    hinged = doors(objects, hinges)
    paint_textures(front_plate)
    bpy.data.objects.remove(front_plate)
    rest = [o for name, o in objects.items()
            if not name.startswith("Front_door_") and name != "Wheel_Wheel_0"]
    cab = [o for o in rest if all(m.name in CAB_MATERIALS for m in o.data.materials if m)]
    body = join([o for o in rest if o not in cab and o is not glass] + [plate], "Body")
    cab = join(cab, "Cab")
    print(f"Moon roof: cut {cut_roof(body)} roof faces and {cut_roof(cab)} headliner faces")
    shrink_textures()
    export([body, glass, windshield] + lenses + hinged + wheel_parts, "iveco_exterior")
    export([cab, steering], "iveco_cab")


main()
