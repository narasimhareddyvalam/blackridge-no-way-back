"""Samples every beat of a rendered master (or the per-beat media) at 15%, 50% and 85% of its span,
for the frame-level visual QC in CLAUDE-CODE-VISUAL-QC-CHECK.md. Writes _qc/frames/<beat>_<pct>.png
and one contact sheet per four beats, _qc/sheets/<first>-<last>.png, for reading.
Usage: python3 build/qcframes.py [master.mp4]   (default: media/<beat>.mp4 per beat)
"""
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

REEL = Path(__file__).resolve().parents[1]
sheet = json.loads((REEL / "beat_sheet.json").read_text())
master = Path(sys.argv[1]) if len(sys.argv) > 1 else None
frames_dir = REEL / "_qc" / "frames"
sheets_dir = REEL / "_qc" / "sheets"
frames_dir.mkdir(parents=True, exist_ok=True)
sheets_dir.mkdir(parents=True, exist_ok=True)

start = 0.0
rows = []
for b in sheet["beats"]:
    bid = b["beat_id"]
    dur = b.get("actual_duration_s") or 0.0
    shots = []
    for pct in (15, 50, 85):
        t = dur * pct / 100
        src, at = (master, start + t) if master else (REEL / "media" / f"{bid}.mp4", t)
        out = frames_dir / f"{bid}_{pct}.png"
        if src.exists():
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-ss", f"{at:.3f}", "-i", str(src),
                            "-frames:v", "1", "-vf", "scale=1920:-1", str(out)], check=False)
        shots.append(out if out.exists() else None)
    rows.append((bid, shots))
    start += dur

for i in range(0, len(rows), 4):
    group = rows[i:i + 4]
    tile_w, tile_h = 640, 360
    canvas = Image.new("RGB", (3 * (tile_w + 8), len(group) * (tile_h + 8)), (40, 40, 40))
    for r, (bid, shots) in enumerate(group):
        for c, path in enumerate(shots):
            tile = Image.open(path).convert("RGB").resize((tile_w, tile_h)) if path else \
                Image.new("RGB", (tile_w, tile_h), (90, 0, 0))
            d = ImageDraw.Draw(tile)
            d.rectangle((0, 0, 92, 18), fill=(0, 0, 0))
            d.text((4, 4), f"{bid} {(15, 50, 85)[c]}%", fill=(255, 255, 0))
            canvas.paste(tile, (c * (tile_w + 8), r * (tile_h + 8)))
    canvas.save(sheets_dir / f"{group[0][0]}-{group[-1][0]}.png")
print(f"sampled {len(rows)} beats into {frames_dir.relative_to(REEL)}; sheets in {sheets_dir.relative_to(REEL)}")
