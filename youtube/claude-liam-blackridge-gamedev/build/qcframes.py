"""Extract frames for visual QC and stack them into one sheet.

Usage: python3 build/qcframes.py OUT.png B01@5 B01@11.5 B03@0.5f ...
  Bxx@<seconds> samples media/Bxx.mp4 at that time; Bxx@<frac>f samples at a fraction of
  its duration. Frames are full 4K renders scaled to 1280 px wide for reading.
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

REEL = Path(__file__).resolve().parents[1]
out, specs = sys.argv[1], sys.argv[2:]
tmp = REEL / "_qc" / "pilot"
tmp.mkdir(parents=True, exist_ok=True)
tiles = []
for spec in specs:
    bid, at = spec.split("@")
    src = REEL / "media" / f"{bid}.mp4"
    if at.endswith("f"):
        dur = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of",
                                    "default=nw=1:nk=1", str(src)], capture_output=True, text=True).stdout)
        t = dur * float(at[:-1])
    else:
        t = float(at)
    png = tmp / f"{bid}_{t:.2f}.png"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-ss", f"{t:.3f}", "-i", str(src), "-frames:v", "1",
                    "-vf", "scale=1280:-1", str(png)], check=True)
    im = Image.open(png).convert("RGB")
    ImageDraw.Draw(im).text((8, 8), f"{bid} @ {t:.2f}s", fill=(255, 0, 0))
    tiles.append(im)
w = max(t.width for t in tiles)
sheet = Image.new("RGB", (w, sum(t.height for t in tiles)), "white")
y = 0
for t in tiles:
    sheet.paste(t, (0, y))
    y += t.height
sheet.save(out)
print(out)
