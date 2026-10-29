"""Extract frames from an encoded clip by frame index, for viewing checks.

Usage: python3 -I extract_frames.py <clip.mp4> <out_dir> <index> [index ...]

Writes <out_dir>/<clip stem>_<index>.png at native size, decoding with the stream's
BT.709 limited-range tags. Only for looking at frames; nothing here is evidence by itself.
"""

import os
import subprocess
import sys


def main():
    clip, out_dir = sys.argv[1], sys.argv[2]
    indices = sorted({int(value) for value in sys.argv[3:]})
    os.makedirs(out_dir, exist_ok=True)
    stem = os.path.splitext(os.path.basename(clip))[0]
    expression = "+".join("eq(n\\,%d)" % index for index in indices)
    chain = ("select='%s',scale=in_color_matrix=bt709:in_range=tv:"
             "flags=accurate_rnd+full_chroma_int,format=rgb24" % expression)
    pattern = os.path.join(out_dir, stem + "_tmp_%03d.png")
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", clip, "-vf", chain,
                    "-fps_mode", "passthrough", pattern], check=True)
    for order, index in enumerate(indices, start=1):
        os.replace(os.path.join(out_dir, stem + "_tmp_%03d.png" % order),
                   os.path.join(out_dir, "%s_%05d.png" % (stem, index)))
        print(os.path.join(out_dir, "%s_%05d.png" % (stem, index)))


if __name__ == "__main__":
    main()
