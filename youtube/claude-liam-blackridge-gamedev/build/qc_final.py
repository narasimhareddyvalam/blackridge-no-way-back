"""Visual QC of the final master (CLAUDE-CODE-VISUAL-QC-CHECK.md):
- 2 fps frames into _qc/frames/ (kept local, gitignored), plus
- each beat at 15/50/85% of its span, stacked into contact sheets _qc/sheet_NN.png
  (6 frames per sheet, 960 px wide each) for reading.
Usage: python3 build/qc_final.py exports/landscape/<film>.mp4
"""
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

REEL = Path(__file__).resolve().parents[1]
film = Path(sys.argv[1])
qc = REEL / "_qc"
(qc / "frames").mkdir(parents=True, exist_ok=True)
subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(film), "-vf", "fps=2,scale=1280:-1",
                str(qc / "frames" / "%05d.png")], check=True)
beats = json.loads((REEL / "beat_sheet.json").read_text())["beats"]
start, shots = 0.0, []
for b in beats:
    d = b.get("render_duration_s") or b["actual_duration_s"]
    for f in (0.15, 0.5, 0.85):
        shots.append((b["beat_id"], f, start + d * f))
    start += d
tiles = []
for bid, f, t in shots:
    out = qc / "frames" / f"beat_{bid}_{int(f * 100)}.png"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-ss", f"{t:.3f}", "-i", str(film), "-frames:v", "1",
                    "-vf", "scale=960:-1", str(out)], check=True)
    im = Image.open(out).convert("RGB")
    ImageDraw.Draw(im).text((6, 4), f"{bid} {int(f * 100)}% t={t:.1f}s", fill=(255, 0, 0))
    tiles.append(im)
for n in range(0, len(tiles), 6):
    group = tiles[n:n + 6]
    sheet = Image.new("RGB", (1920, 540 * ((len(group) + 1) // 2)), "white")
    for i, im in enumerate(group):
        sheet.paste(im, ((i % 2) * 960, (i // 2) * 540))
    sheet.save(qc / f"sheet_{n // 6:02d}.png")
print(f"film {start:.1f} s · {len(shots)} beat frames in {((len(tiles) + 5) // 6)} sheets · 2 fps frames in _qc/frames/")
