"""Writes SHOTLIST.md from beat_sheet.json: per beat, the component, on-screen label,
show events, evidence media (with SHA-256) and duration. Run: python3 build/shotlist.py"""
import hashlib
import json
from pathlib import Path

REEL = Path(__file__).resolve().parents[1]
TOOLKIT_PUBLIC = Path.home() / "Desktop/brutalist.art/runtime/remotion/public"
sheet = json.loads((REEL / "beat_sheet.json").read_text())


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


out = ["# SHOTLIST — Blackridge, Shaded", "",
       "Generated from beat_sheet.json by build/shotlist.py. Media paths under `blackridge-shaded/` are "
       "hash-identical copies of the reel's `evidence/` and `capture/` files in the Remotion public folder.", ""]
total = 0.0
for b in sheet["beats"]:
    rem = b["shot"].get("remotion", {})
    props = rem.get("props", {})
    dur = b.get("actual_duration_s") or 0
    total += dur
    out.append(f"## {b['beat_id']} · {b['act']} · {rem.get('pattern')} · {dur:.2f} s")
    out.append("")
    if props.get("title"):
        out.append(f"- Title: {props['title']}")
    if props.get("label"):
        out.append(f"- Label: {props['label']}")
    if props.get("path"):
        out.append(f"- Code: `{props['path']}` from line {props.get('startLine')} (verbatim; Godot editor reconstruction)")
    for ev in b["shot"].get("show", []):
        out.append(f"- Show: at “{ev['at']}” — {ev['event']}")
    for m in props.get("media", []):
        src = m["src"]
        p = TOOLKIT_PUBLIC / src
        h = sha(p)[:16] if p.exists() else "missing"
        out.append(f"- Media: `{src}` ({m['kind']}, sha256 {h}…){' crop ' + json.dumps(m['crop']) if m.get('crop') else ''}")
    if b["shot"].get("evidence_media"):
        p = REEL / b["shot"]["evidence_media"]
        out.append(f"- Paired evidence: `{b['shot']['evidence_media']}` sha256 {sha(p) if p.exists() else 'missing'}")
    out.append("")
out.append(f"Total narration clock: {total:.2f} s ({total / 60:.1f} min).")
(REEL / "SHOTLIST.md").write_text("\n".join(out) + "\n")
print(f"SHOTLIST.md: {len(sheet['beats'])} beats, {total:.1f} s")
