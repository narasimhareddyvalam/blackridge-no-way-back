"""Compare an encoded MP4 with the JPEG frames it was made from.

Usage: python3 -I verify_clip.py <frames_dir> <prefix> <mp4> <expected_frames> [index ...]

Decodes the chosen MP4 frames to RGB with ffmpeg (BT.709 limited range, as tagged),
decodes the matching source JPEGs with Pillow, and reports the mean and 99.9th
percentile absolute difference per frame. Fails (exit 1) if the MP4 has the wrong frame
count or any sampled frame differs by more than an encode-noise threshold. Also writes
1280-wide previews of the decoded MP4 frames to capture/logs/verify_<prefix>/ for viewing.
"""

import json
import os
import subprocess
import sys

import numpy as np
from PIL import Image


def mp4_frames(mp4, indices, width, height):
    expression = "+".join("eq(n\\,%d)" % index for index in indices)
    chain = ("select='%s',scale=in_color_matrix=bt709:in_range=tv:"
             "flags=accurate_rnd+full_chroma_int,format=rgb24" % expression)
    raw = subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", mp4, "-vf", chain,
         "-fps_mode", "passthrough", "-f", "rawvideo", "-"],
        check=True, stdout=subprocess.PIPE).stdout
    size = width * height * 3
    if len(raw) != size * len(indices):
        raise SystemExit("decoded %d bytes, expected %d" % (len(raw), size * len(indices)))
    return [np.frombuffer(raw[i * size:(i + 1) * size], dtype=np.uint8).reshape(height, width, 3)
            for i in range(len(indices))]


def main():
    frames_dir, prefix, mp4, expected = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
    indices = sorted({int(value) for value in sys.argv[5:]} | {0, expected // 2, expected - 1})
    probe = json.loads(subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0", "-count_frames", "-show_entries",
         "stream=width,height,nb_read_frames,r_frame_rate", "-of", "json", mp4],
        check=True, stdout=subprocess.PIPE).stdout)["streams"][0]
    width, height = int(probe["width"]), int(probe["height"])
    count = int(probe["nb_read_frames"])
    failures = []
    if count != expected:
        failures.append("frame count %d != %d" % (count, expected))
    if probe["r_frame_rate"] != "60/1":
        failures.append("frame rate %s" % probe["r_frame_rate"])
    preview_dir = os.path.join(os.path.dirname(mp4), "logs", "verify_" + prefix)
    os.makedirs(preview_dir, exist_ok=True)
    decoded = mp4_frames(mp4, indices, width, height)
    report = {"mp4": os.path.basename(mp4), "width": width, "height": height,
              "frames": count, "fps": probe["r_frame_rate"], "samples": []}
    for index, frame in zip(indices, decoded):
        source_path = os.path.join(frames_dir, "%s_%05d.jpg" % (prefix, index))
        source = np.asarray(Image.open(source_path).convert("RGB"))
        if source.shape != frame.shape:
            failures.append("frame %d shape %s vs %s" % (index, frame.shape, source.shape))
            continue
        difference = np.abs(source.astype(np.int16) - frame.astype(np.int16))
        mean = float(difference.mean())
        p999 = float(np.percentile(difference, 99.9))
        report["samples"].append({"frame": index, "mean_abs_diff": round(mean, 3),
                                  "p99_9_abs_diff": p999})
        print("frame %5d: mean |mp4 - jpg| = %.3f, 99.9th percentile = %.0f" % (index, mean, p999))
        if mean > 2.5 or p999 > 40:
            failures.append("frame %d differs (mean %.3f, p99.9 %.0f)" % (index, mean, p999))
        Image.fromarray(frame).resize((1280, round(1280 * height / width)), Image.LANCZOS).save(
            os.path.join(preview_dir, "mp4_frame_%05d.png" % index))
    report["failures"] = failures
    with open(os.path.join(os.path.dirname(mp4), "logs", "verify_%s.json" % prefix), "w") as out:
        json.dump(report, out, indent=2)
    if failures:
        print("VERIFY FAIL: " + "; ".join(failures))
        sys.exit(1)
    print("VERIFY PASS: %s %dx%d, %d frames at %s" % (os.path.basename(mp4), width, height,
                                                       count, probe["r_frame_rate"]))


if __name__ == "__main__":
    main()
