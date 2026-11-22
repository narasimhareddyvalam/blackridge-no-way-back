"""Compares two dumps of Ethan's rig clips (tools/tests/dump_rig_clips.gd): every clip in the first
must be in the second with the same length, loop mode and tracks, every sample within TOLERANCE
(a rotation compared up to its sign). A track the second adds is allowed only when it holds its
bone's rest pose (from the second dump's `__rest__`) at every sample, so it moves nothing. Prints a line per clip and exits 1 on any difference.
Usage: python3 tools/tests/compare_rig_clips.py before.json after.json
"""

import json
import sys

TOLERANCE = 1e-3


def differs(a, b):
    if a is None or b is None:
        return a is not b
    if len(a) == 4:
        same = max(abs(x - y) for x, y in zip(a, b))
        flipped = max(abs(x + y) for x, y in zip(a, b))
        return min(same, flipped) > TOLERANCE
    return max(abs(x - y) for x, y in zip(a, b)) > TOLERANCE


def main():
    before = json.load(open(sys.argv[1]))
    after = json.load(open(sys.argv[2]))
    before.pop("__rest__", None)
    rests = after.pop("__rest__", {})
    bad = 0
    for name, clip in before.items():
        other = after.get(name)
        if other is None:
            print(f"CLIP {name}: MISSING")
            bad += 1
            continue
        problems = []
        if abs(clip["length"] - other["length"]) > 1e-4:
            problems.append(f"length {clip['length']} -> {other['length']}")
        if clip["loop"] != other["loop"]:
            problems.append(f"loop {clip['loop']} -> {other['loop']}")
        missing = set(clip["tracks"]) - set(other["tracks"])
        added = set(other["tracks"]) - set(clip["tracks"])
        at_rest = set()
        for track in added:
            bone, kind = track.split(":")[-1].split("|")
            rest = rests.get(bone, {}).get(kind)
            if rest is not None and not any(differs(v, rest) for v in other["tracks"][track]):
                at_rest.add(track)
        if missing or added - at_rest:
            problems.append(f"tracks -{len(missing)} +{len(added - at_rest)}")
        note = f", +{len(at_rest)} at rest ({', '.join(sorted(t.split(':')[-1] for t in at_rest))})" \
            if at_rest else ""
        worst = 0
        for track, samples in clip["tracks"].items():
            if track in other["tracks"]:
                worst += sum(differs(a, b) for a, b in zip(samples, other["tracks"][track]))
        if worst:
            problems.append(f"{worst} samples differ")
        print(f"CLIP {name}: {'same' if not problems else '; '.join(problems)} "
              f"({len(clip['tracks'])} tracks{note})")
        bad += bool(problems)
    new = sorted(set(after) - set(before))
    print(f"NEW CLIPS {new}")
    print(f"COMPARE RESULT: {len(before) - bad}/{len(before)} earlier clips unchanged")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
