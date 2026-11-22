"""Writes the pistol reload clip (Assignment 7, CHANGE-BRIEF.md's revision #377-#383) from its
phase table: game/animations/pistol_reload.tres, an AnimationLibrary holding 'reload', 66 frames at
30 fps (handgun.gd's RELOAD_SECONDS, 2.2 s), LOOP_NONE.

Phase table (frames at 30 fps):
    startup  0-17   the empty magazine drops from the grip (out of sight at 17); the left hand
                    leaves the grip for the spare at his belt
    active   18-47  the hand brings the fresh magazine up under the grip and pushes it home (47)
    recovery 48-65  the hand racks the slide (back 52-55, released 56-58) and wraps the grip again
Through it the gun is drawn in toward his chest (in by 6, out from 58 to 65), as a shooter brings a
pistol into his workspace to reload, so his left hand can reach it.

It keys, under the Grip that aim_arms.gd builds: the Grip's own position (from the shoulders' middle); the pistol's magazine (clip_pistolLow_0) position
and visibility and its slide (slide_pistolLow_0) position, in the pistol model's own space (metres;
the muzzle is -y, the top +z), and the left hand's IK target (SupportHand) in the Grip's space (+x
his left, +y up, +z ahead). Every track starts and ends on the rest pose. The keys are computed
here from the frames below, so the phase table is the one place to retime it.
Run from the repository root:
    python3 tools/art/make_pistol_reload_clip.py
"""

import pathlib

FPS = 30


def add(a, b, s=1.0):
    return tuple(x + y * s for x, y in zip(a, b))


FRAMES = 66
TARGET = pathlib.Path("game/animations/pistol_reload.tres")

## The pistol model's grip and the palm it sits in (aim_arms.gd's GRIP_IN_MODEL and PALM): a point
## p in the model is at turn(p - GRIP) + PALM in the Grip, turn(x, y, z) = (x, z, -y).
GRIP = (0.6378, 0.67, -0.055)
PALM = (0.0, -0.05, -0.07)
## Rest positions: the magazine and the slide in the model (pistol.glb), the left hand in the Grip
## (aim_arms.gd's LEFT_FROM_RIGHT).
MAGAZINE = (0.63775, 0.660413, -0.040479)
SLIDE = (0.641454, 0.651277, 0.0138)
HAND = (0.05, -0.03, 0.0)
## The magazine's line out of the grip (down and back, as the grip is raked), its length, and the
## slide's travel back when racked.
OUT = (0.0, 0.333, -0.943)
MAGAZINE_LENGTH = 0.12
SLIDE_TRAVEL = 0.025
## The gun held out (aim_arms.gd's HELD) and drawn in to reload, from the shoulders' middle.
HELD = (-0.04, -0.1, 0.52)
WORKSPACE = (-0.02, -0.2, 0.34)
## The spare magazine's pouch at the front of his left hip, from the shoulders' middle, and so in
## the Grip while it is drawn in; the magazine held in the hand, its top this far ahead of the
## wrist along its line.
POUCH = add((0.17, -0.58, 0.08), WORKSPACE, -1.0)
IN_HAND = 0.09




def to_grip(p):
    d = add(p, GRIP, -1.0)
    return add((d[0], d[2], -d[1]), PALM)


def to_model(g):
    d = add(g, PALM, -1.0)
    return add((d[0], -d[2], d[1]), GRIP)


def held(hand):
    """Where the magazine is when the hand at `hand` (in the Grip) holds it."""
    return add(to_model(hand), OUT, -IN_HAND)


def hand_for(magazine):
    """Where the hand is when it holds the magazine at `magazine` (in the model)."""
    return to_grip(add(magazine, OUT, IN_HAND))


SEATED = MAGAZINE
UNDER = add(MAGAZINE, OUT, 0.05)
ENTERING = add(MAGAZINE, OUT, 0.012)
LIFTED = held((0.04, -0.24, -0.12))

magazine_keys = [
    (0, MAGAZINE), (2, MAGAZINE),
    (6, add(MAGAZINE, OUT, MAGAZINE_LENGTH)),
    (17, add(add(MAGAZINE, OUT, MAGAZINE_LENGTH), (0.0, 0.0, -0.6))),
    (18, held(POUCH)), (30, LIFTED), (38, UNDER), (44, ENTERING), (47, SEATED), (65, MAGAZINE),
]
visible_keys = [(0, True), (17, False), (18, True)]
grip_keys = [(0, HELD), (6, WORKSPACE), (58, WORKSPACE), (65, HELD)]
slide_keys = [
    (0, SLIDE), (48, SLIDE), (52, SLIDE), (55, add(SLIDE, (0.0, SLIDE_TRAVEL, 0.0))),
    (56, add(SLIDE, (0.0, SLIDE_TRAVEL, 0.0))), (58, SLIDE), (65, SLIDE),
]
hand_keys = [
    (0, HAND), (3, (0.06, -0.07, -0.03)), (12, add(POUCH, (0.0, 0.01, 0.0))), (17, POUCH),
    (18, POUCH), (30, hand_for(LIFTED)), (38, hand_for(UNDER)), (44, hand_for(ENTERING)),
    (47, hand_for(SEATED)), (48, hand_for(SEATED)),
    (52, (0.02, 0.07, -0.02)), (55, (0.02, 0.07, -0.02 - SLIDE_TRAVEL - 0.01)),
    (58, (0.05, 0.10, -0.10)), (62, (0.06, 0.0, -0.02)), (65, HAND),
]


def vec(v):
    return "Vector3(%s)" % ", ".join("%.6g" % x for x in v)


## Each key eases out of itself and into the next (a transition of -2, in and out), so the motion
## starts and stops softly with no overshoot; the magazine falling from frame 6 speeds up as it
## falls (2, in), and the slide moves at an even rate (1).
EASE = -2.0
FALL = {6: 2.0}


def track(index, path, keys, interp, update, value, eases=None):
    times = ", ".join("%.6g" % (frame / FPS) for frame, _ in keys)
    ones = ", ".join("%.6g" % ((eases or {}).get(frame, EASE) if eases is not False else 1.0)
                     for frame, _ in keys)
    values = ", ".join(value(v) for _, v in keys)
    return (f'tracks/{index}/type = "value"\ntracks/{index}/imported = false\n'
            f'tracks/{index}/enabled = true\ntracks/{index}/path = NodePath("{path}")\n'
            f'tracks/{index}/interp = {interp}\ntracks/{index}/loop_wrap = true\n'
            f'tracks/{index}/keys = {{\n"times": PackedFloat32Array({times}),\n'
            f'"transitions": PackedFloat32Array({ones}),\n"update": {update},\n'
            f'"values": [{values}]\n}}\n')


def main():
    for keys in (magazine_keys, visible_keys, slide_keys, hand_keys, grip_keys):
        assert keys[0][0] == 0 and all(0 <= f < FRAMES for f, _ in keys)
    body = (
        '[gd_resource type="AnimationLibrary" load_steps=2 format=3]\n\n'
        '[sub_resource type="Animation" id="Animation_reload"]\n'
        'resource_name = "reload"\n'
        f'length = {FRAMES / FPS:.6g}\n'
        'loop_mode = 0\n'
        'step = 0.0333333\n'
        + track(0, "Pistol/clip_pistolLow_0:position", magazine_keys, 1, 0, vec, FALL)
        + track(1, "Pistol/clip_pistolLow_0:visible", visible_keys, 1, 1,
                lambda v: "true" if v else "false", False)
        + track(2, "Pistol/slide_pistolLow_0:position", slide_keys, 1, 0, vec, False)
        + track(3, "SupportHand:position", hand_keys, 1, 0, vec)
        + track(4, ".:position", grip_keys, 1, 0, vec)
        + '\n[resource]\n_data = {\n&"reload": SubResource("Animation_reload")\n}\n'
    )
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text(body)
    print(f"{TARGET}: 'reload', {FRAMES} frames at {FPS} fps, 5 tracks")


if __name__ == "__main__":
    main()
