"""Renders one beat the way runtime/scripts/remotion_scenes.py does (same composition, props and
flags: --concurrency=1 --scale=2 --image-format=png --crf=16), but in runs of CHUNK frames, each
in a fresh browser, joined without re-encoding into media/<BID>.mp4.

Why: with about 5 GB free on the author's Mac, headless Chrome refused OffthreadVideo's 4K frame
fetches after about 140 frames of one render ("Failed to fetch ... disk space is low"); its blob
allowance follows free disk space and resets with each browser. A run of 45 frames stays inside
it. Frame N of the composition is the same whichever run renders it. See pitch/FRICTIONAL.md.

Run: python3 build/render_chunked.py B00 [B03 ...]   (after build/build_sheet.py)
CHUNK=20 for a beat whose frame extractor dies on pruning its cache (B10, 2026-11-24).
"""
import json
import os
import math
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

REEL = Path(__file__).resolve().parents[1]
PROJECT = Path.home() / "Desktop" / "brutalist.art" / "runtime" / "remotion"
CHUNK = int(os.environ.get("CHUNK", "45"))
FPS = 30


def render(bid):
    sheet_path = REEL / "beat_sheet.json"
    sheet = json.loads(sheet_path.read_text())
    beat = next(b for b in sheet["beats"] if b["beat_id"] == bid)
    rem = beat["shot"]["remotion"]
    total = math.ceil(float(beat["render_duration_s"]) * FPS)
    out = REEL / "media" / f"{bid}.mp4"
    out.parent.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".remotion-", dir=out.parent) as scratch:
        scratch = Path(scratch)
        props = scratch / "props.json"
        props.write_text(json.dumps(rem["props"]))
        parts = []
        for first in range(0, total, CHUNK):
            last = min(first + CHUNK, total) - 1
            part = scratch / f"p{first:05d}.mp4"
            cmd = ["npx", "remotion", "render", "src/index.ts", rem["pattern"], str(part),
                   f"--props={props}", "--concurrency=1", "--scale=2", "--image-format=png",
                   "--crf=16", "--muted", f"--frames={first}-{last}"]
            r = subprocess.run(cmd, cwd=PROJECT, capture_output=True, text=True)
            if r.returncode != 0 or not part.exists():
                print(f"{bid}: FAIL frames {first}-{last}\n{r.stderr[-600:]}")
                return False
            parts.append(part)
            print(f"{bid}: frames {first}-{last} of {total}", flush=True)
        listing = scratch / "parts.txt"
        listing.write_text("".join(f"file '{p}'\n" for p in parts))
        joined = scratch / "joined.mp4"
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i",
                        str(listing), "-c", "copy", "-movflags", "+faststart", str(joined)],
                       check=True)
        # One silent stereo track over the whole beat, as a single render carries.
        timed = scratch / "timed.mp4"
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(joined), "-f", "lavfi", "-i",
                        "anullsrc=r=48000:cl=stereo", "-map", "0:v", "-map", "1:a", "-c:v",
                        "copy", "-c:a", "aac", "-t", f"{total / FPS:.4f}", "-movflags",
                        "+faststart", str(timed)], check=True)
        timed.replace(joined)
        n = subprocess.run(["ffprobe", "-v", "error", "-count_packets", "-select_streams", "v",
                            "-show_entries", "stream=nb_read_packets", "-of", "csv=p=0",
                            str(joined)], capture_output=True, text=True).stdout.strip()
        if int(n) != total:
            print(f"{bid}: FAIL joined {n} frames, wanted {total}")
            return False
        joined.replace(out)
    rem["rendered"] = {"out": f"media/{bid}.mp4",
                       "at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                       "how": f"build/render_chunked.py, {CHUNK}-frame runs, {total} frames"}
    sheet_path.write_text(json.dumps(sheet, indent=1, ensure_ascii=False) + "\n")
    print(f"{bid}: ok, {total} frames -> media/{bid}.mp4")
    return True


if __name__ == "__main__":
    sys.exit(0 if all([render(b) for b in sys.argv[1:]]) else 1)
