"""Generate the conifer branch cards used by the roadside trees, from scanned fir twigs.

Each card shows one branch seen from above: the base on the left and the tip on the right.
Both are built from the scanned twigs in Poly Haven's CC0 "Fir Tree 01" (Rob Tuytel, Rico
Cilliers). Each twig is cut out of the atlas with its colour, alpha and OpenGL normal map,
scaled and rotated onto a main stem, and its normals are rotated with it.

- The live branch uses the needle sprays. Twigs low on the branch sit in shade and are
  darker; the tip is lighter new growth.
- The dead branch, for the bare lower trunk, uses the atlas's bare stem, weathered grey.

Cards are built at twice the size and scaled down for soft edges. Colour bleeds into the
transparent pixels so mipmaps do not darken the edges.

Usage, from the repository root:
    python3 -I tools/assets/fetch_polyhaven.py tools/assets/conifer_scan_assets.json
    python3 -I tools/make_conifer_cards.py
"""

import math
import pathlib
import random

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

SOURCE = pathlib.Path("source_assets/polyhaven/maps/fir_tree_01")
FOLDER = pathlib.Path("game/features/environments/industrial_loop/art/conifer")
WIDTH, HEIGHT = 1024, 512
SCALE = 2
SEED = 20261030
ALBEDO_SCALE = 0.7
TINT = np.array([0.92, 1.0, 1.0])
WEATHERED = np.array([1.45, 1.4, 1.35])
DEAD_WIDTH, DEAD_HEIGHT = 512, 256
STEM_COLOUR = np.array([0.17, 0.13, 0.085])


def load_atlas() -> tuple:
    def read(name: str, mode: str) -> np.ndarray:
        path = SOURCE / f"fir_tree_01_twig_{name}_2k.jpg"
        return np.asarray(Image.open(path).convert(mode)).astype(np.float32) / 255.0
    colour = read("diff", "RGB")
    alpha = read("alpha", "L")
    normal = read("nor_gl", "RGB") * 2.0 - 1.0
    return colour, alpha, normal


def label_atlas(alpha: np.ndarray) -> np.ndarray:
    labels, _ = ndimage.label(ndimage.binary_closing(alpha > 0.5, iterations=6))
    return labels


def find_sprays(colour: np.ndarray, alpha: np.ndarray, normal: np.ndarray,
                labels: np.ndarray) -> list:
    sprays = []
    for index, box in enumerate(ndimage.find_objects(labels), start=1):
        region = labels[box] == index
        height = box[0].stop - box[0].start
        width = box[1].stop - box[1].start
        mean = colour[box][region].mean(axis=0)
        if region.sum() < 10000 or height > 3.0 * width or mean[1] <= mean[0]:
            continue
        keep = ndimage.binary_dilation(region, iterations=3)
        spray_alpha = alpha[box] * keep
        rows = np.nonzero((spray_alpha > 0.5).any(axis=1))[0]
        bottom = rows.max()
        base_x = np.nonzero(spray_alpha[max(0, bottom - 12):bottom + 1] > 0.5)[1].mean()
        base = np.array([base_x, float(bottom)])
        ys, xs = np.nonzero(spray_alpha > 0.5)
        tip = np.array([xs.mean(), ys.mean()])
        axis = (tip - base) / np.linalg.norm(tip - base)
        length = float(np.max(-(ys - base[1]) * 1.0))
        sprays.append({"colour": colour[box], "alpha": spray_alpha, "normal": normal[box],
                       "base": base, "axis": axis, "length": max(length, 1.0)})
    return sprays


def find_stem(colour: np.ndarray, alpha: np.ndarray, normal: np.ndarray,
              labels: np.ndarray) -> dict:
    best = None
    for index, box in enumerate(ndimage.find_objects(labels), start=1):
        region = labels[box] == index
        width = box[1].stop - box[1].start
        mean = colour[box][region].mean(axis=0)
        if mean[0] > mean[1] and (best is None or width > best[2]):
            best = (index, box, width)
    index, box, _ = best
    stem_alpha = alpha[box] * ndimage.binary_dilation(labels[box] == index, iterations=3)
    ys, xs = np.nonzero(stem_alpha > 0.5)
    left = xs < xs.min() + 0.25 * (xs.max() - xs.min())
    slope, intercept = np.polyfit(xs[left], ys[left], 1)
    on_line = np.abs(ys - (slope * xs + intercept)) < 30
    tip_x = float(xs[on_line].min()) + 110.0
    node_x = float(xs[on_line].max()) - 170.0
    rows, columns = np.mgrid[0:stem_alpha.shape[0], 0:stem_alpha.shape[1]]
    keep = ((np.abs(rows - (slope * columns + intercept)) < 24)
            & (columns > tip_x) & (columns < node_x))
    piece = colour[box]
    brown = (piece[..., 0] - piece[..., 2]) > 0.04
    cleaned = np.clip((stem_alpha - 0.3) / 0.4, 0.0, 1.0) * keep * brown
    parts, count = ndimage.label(cleaned > 0.5)
    sizes = ndimage.sum(cleaned > 0.5, parts, range(1, count + 1))
    largest = np.isin(parts, 1 + np.nonzero(sizes >= 0.15 * sizes.max())[0])
    largest = ndimage.binary_dilation(largest, iterations=2)
    base = np.array([tip_x, slope * tip_x + intercept])
    tip = np.array([node_x, slope * node_x + intercept])
    return {"colour": colour[box], "alpha": cleaned * largest, "normal": normal[box],
            "base": base, "axis": (tip - base) / np.linalg.norm(tip - base),
            "length": float(np.linalg.norm(tip - base))}


class Canvas:
    def __init__(self, width: int, height: int) -> None:
        self.colour = np.zeros((height, width, 3), np.float32)
        self.alpha = np.zeros((height, width), np.float32)
        self.normal = np.zeros((height, width, 3), np.float32)
        self.normal[..., 2] = 1.0

    def over(self, region: tuple, colour: np.ndarray, alpha: np.ndarray,
             normal: np.ndarray) -> None:
        a = alpha[..., None]
        self.colour[region] = colour * a + self.colour[region] * (1.0 - a)
        self.normal[region] = normal * a + self.normal[region] * (1.0 - a)
        self.alpha[region] = alpha + self.alpha[region] * (1.0 - alpha)


def place(canvas: Canvas, spray: dict, base: np.ndarray, direction: np.ndarray,
          length: float, mirror: bool, brightness: np.ndarray, weathered: bool = False,
          thickness: float = 1.0) -> None:
    scale = length / spray["length"]
    angle = math.atan2(direction[1], direction[0]) - math.atan2(spray["axis"][1],
                                                                spray["axis"][0])
    rotation = np.array([[math.cos(angle), -math.sin(angle)],
                         [math.sin(angle), math.cos(angle)]])
    axis = spray["axis"]
    reflect = 2.0 * np.outer(axis, axis) - np.eye(2) if mirror else np.eye(2)
    along = np.outer(axis, axis)
    stretch = along + thickness * (np.eye(2) - along)
    forward = rotation @ reflect @ stretch * scale
    inverse = np.linalg.inv(forward)
    height, width = spray["alpha"].shape
    corners = np.array([[0, 0], [width, 0], [0, height], [width, height]], np.float32)
    placed = (forward @ (corners - spray["base"]).T).T + base
    low = np.floor(placed.min(axis=0)).astype(int)
    high = np.ceil(placed.max(axis=0)).astype(int)
    low = np.maximum(low, 0)
    high = np.minimum(high, [canvas.alpha.shape[1], canvas.alpha.shape[0]])
    if np.any(high <= low):
        return
    gx, gy = np.meshgrid(np.arange(low[0], high[0]), np.arange(low[1], high[1]))
    offsets = np.stack([gx - base[0], gy - base[1]])
    source = np.tensordot(inverse, offsets, axes=1) + spray["base"][:, None, None]
    coords = [source[1], source[0]]
    alpha = ndimage.map_coordinates(spray["alpha"], coords, order=1, cval=0.0)
    if alpha.max() <= 0.0:
        return
    colour = np.stack([ndimage.map_coordinates(spray["colour"][..., c], coords, order=1)
                       for c in range(3)], axis=-1)
    normal = np.stack([ndimage.map_coordinates(spray["normal"][..., c], coords, order=1,
                                               cval=0.0) for c in range(3)], axis=-1)
    image_xy = np.stack([normal[..., 0], -normal[..., 1]], axis=-1)
    turned = image_xy @ (rotation @ reflect).T
    normal = np.dstack([turned[..., 0], -turned[..., 1], normal[..., 2]])
    region = (slice(low[1], high[1]), slice(low[0], high[0]))
    if weathered:
        grey = colour @ np.array([0.2126, 0.7152, 0.0722])
        colour = colour * 0.45 + grey[..., None] * 0.55
    canvas.over(region, colour * brightness * ALBEDO_SCALE, alpha, normal)


def draw_stem(canvas: Canvas, start: np.ndarray, end: np.ndarray, rng: random.Random) -> None:
    height, width = canvas.alpha.shape
    ys = np.arange(height, dtype=np.float32)
    columns = int(end[0]) - int(start[0])
    noise = np.array([rng.random() for _ in range(columns)])
    shades = 0.85 + 0.3 * np.convolve(noise, np.ones(9) / 9.0, mode="same")
    for x in range(int(start[0]), int(end[0])):
        t = (x - start[0]) / (end[0] - start[0])
        centre = start[1] + (end[1] - start[1]) * t
        radius = (9.0 - 6.5 * t) * SCALE / 2.0 + 1.0
        offset = (ys - centre) / radius
        inside = np.abs(offset) < 1.0
        if not inside.any():
            continue
        cover = np.clip((1.0 - np.abs(offset)) * radius, 0.0, 1.0) * inside
        shade = shades[x - int(start[0])]
        roundness = np.sqrt(np.clip(1.0 - offset ** 2, 0.0, 1.0))
        colour = STEM_COLOUR[None, :] * shade * (0.75 + 0.25 * roundness)[:, None]
        normal = np.stack([np.zeros_like(offset), -offset,
                           np.sqrt(np.clip(1.0 - offset ** 2, 0.0, 1.0))], axis=-1)
        canvas.over((slice(None), slice(x, x + 1)), colour[:, None, :],
                    cover[:, None], normal[:, None, :])


def build_branch(sprays: list, rng: random.Random) -> Canvas:
    width, height = WIDTH * SCALE, HEIGHT * SCALE
    canvas = Canvas(width, height)
    start = np.array([24.0 * SCALE, height / 2.0])
    end = np.array([width - 40.0 * SCALE, height / 2.0 - 14.0 * SCALE])
    draw_stem(canvas, start, end, rng)
    by_size = sorted(sprays, key=lambda spray: spray["length"])
    large, small = by_size[len(by_size) // 2:], by_size[:len(by_size) // 2 + 1]

    def point(t: float) -> np.ndarray:
        return start + (end - start) * t

    t, side = 0.03, 1.0
    while t < 0.88:
        sides = (side, -side) if rng.random() < 0.6 else (side,)
        for this_side in sides:
            reach = (0.95 - 0.5 * t) * 215.0 * SCALE * rng.uniform(0.8, 1.1)
            angle = math.radians(rng.uniform(32.0, 55.0)) * this_side
            direction = np.array([math.cos(angle), -math.sin(angle)])
            shade = TINT * (0.7 + 0.3 * t) * rng.uniform(0.9, 1.05)
            place(canvas, rng.choice(large), point(t), direction, reach, rng.random() < 0.5,
                  shade)
        t += rng.uniform(0.03, 0.05)
        side = -side
    t = 0.05
    while t < 0.85:
        reach = (0.65 - 0.3 * t) * 200.0 * SCALE * rng.uniform(0.8, 1.1)
        angle = math.radians(rng.uniform(8.0, 30.0)) * (1.0 if rng.random() < 0.5 else -1.0)
        direction = np.array([math.cos(angle), -math.sin(angle)])
        shade = TINT * (0.85 + 0.2 * t) * rng.uniform(0.92, 1.05)
        place(canvas, rng.choice(small), point(t), direction, reach, rng.random() < 0.5,
              shade)
        t += rng.uniform(0.05, 0.07)
    tip_shade = TINT * np.array([1.08, 1.06, 1.0]) * 1.05
    tip_base = point(0.78)
    place(canvas, by_size[-1], tip_base, np.array([1.0, -0.06]) / math.hypot(1.0, 0.06),
          (end[0] - tip_base[0]) * 1.08, False, tip_shade)
    return canvas


def build_deadwood(stem: dict, rng: random.Random) -> Canvas:
    width, height = DEAD_WIDTH * SCALE, DEAD_HEIGHT * SCALE
    canvas = Canvas(width, height)
    start = np.array([10.0 * SCALE, height / 2.0])
    direction = np.array([1.0, 0.03]) / math.hypot(1.0, 0.03)
    length = 0.94 * width
    shade = WEATHERED * rng.uniform(0.95, 1.05)
    place(canvas, stem, start, direction, length, False, shade, True, 2.0)
    t, side = 0.18, 1.0
    while t < 0.82:
        reach = (0.32 - 0.2 * t) * width * rng.uniform(0.8, 1.1)
        angle = math.radians(rng.uniform(28.0, 50.0)) * side
        twig = np.array([math.cos(angle), -math.sin(angle)])
        place(canvas, stem, start + direction * length * t, twig, reach, rng.random() < 0.5,
              WEATHERED * rng.uniform(0.85, 1.05), True, 2.2)
        t += rng.uniform(0.12, 0.2)
        side = -side
    return canvas


def save_card(canvas: Canvas, name: str) -> tuple:
    coverage = downsample(canvas.alpha)
    premultiplied = downsample(canvas.colour * canvas.alpha[..., None])
    rgb = premultiplied / np.maximum(coverage[..., None], 1e-4)
    blurred = np.asarray(Image.fromarray(np.uint8(np.clip(premultiplied, 0, 1) * 255))
                         .filter(ImageFilter.GaussianBlur(6))).astype(np.float32) / 255.0
    weight = np.asarray(Image.fromarray(np.uint8(coverage * 255))
                        .filter(ImageFilter.GaussianBlur(6))).astype(np.float32) / 255.0
    bled = blurred / np.maximum(weight[..., None], 1e-3)
    rgb = np.where(coverage[..., None] > 0.02, rgb, bled)
    out = np.dstack([np.clip(rgb, 0, 1), coverage]) * 255.0
    FOLDER.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.uint8(np.round(out)), "RGBA").save(FOLDER / f"{name}_diff.png")
    normal_out = downsample(canvas.normal)
    normal_out /= np.maximum(np.linalg.norm(normal_out, axis=2, keepdims=True), 1e-6)
    encoded = np.uint8(np.round((normal_out * 0.5 + 0.5) * 255.0))
    Image.fromarray(encoded, "RGB").save(FOLDER / f"{name}_nor_gl.png")
    solid = coverage > 0.5
    return float((coverage > 0.35).mean()), np.round(rgb[solid].mean(axis=0) * 255).astype(int)


def downsample(values: np.ndarray) -> np.ndarray:
    height, width = values.shape[:2]
    shaped = values.reshape(height // SCALE, SCALE, width // SCALE, SCALE, *values.shape[2:])
    return shaped.mean(axis=(1, 3))


def main() -> None:
    rng = random.Random(SEED)
    colour, alpha, normal = load_atlas()
    labels = label_atlas(alpha)
    sprays = find_sprays(colour, alpha, normal, labels)
    coverage, mean = save_card(build_branch(sprays, rng), "conifer_branch")
    print(f"wrote {FOLDER}/conifer_branch_diff.png and _nor_gl.png ({WIDTH}x{HEIGHT}) "
          f"from {len(sprays)} scanned sprays; coverage {coverage:.3f}; "
          f"mean colour {mean.tolist()}")
    stem = find_stem(colour, alpha, normal, labels)
    coverage, mean = save_card(build_deadwood(stem, rng), "conifer_deadwood")
    print(f"wrote {FOLDER}/conifer_deadwood_diff.png and _nor_gl.png "
          f"({DEAD_WIDTH}x{DEAD_HEIGHT}); coverage {coverage:.3f}; mean colour {mean.tolist()}")


if __name__ == "__main__":
    main()
