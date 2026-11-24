"""Writes SCRIPT.md and SHOTLIST.md from beat_sheet.json (and the 4K footage from
build/segments.json), so the documents cannot drift from the film. Run: python3 build/docs.py
"""
import json
from pathlib import Path

REEL = Path(__file__).resolve().parents[1]
sheet = json.loads((REEL / "beat_sheet.json").read_text())
segments = json.loads((REEL / "build" / "segments.json").read_text())
title = sheet["metadata"]["title"]
beats = sheet["beats"]
total = sum(b.get("actual_duration_s") or 0 for b in beats)
words = sum(len(b["narration_text"].split()) for b in beats)

script = [f"# SCRIPT: {title}", "",
          "The author's approved narration (#457-#459), read by an AI voice (Kokoro `am_onyx`); "
          f"{len(beats)} beats, {words} words, {total:.1f} s measured.", ""]
for b in beats:
    dur = b.get("actual_duration_s")
    script += [f"## {b['beat_id']} · {b['act']}" + (f" · {dur:.1f} s" if dur else ""), "",
               b["narration_text"], ""]
(REEL / "SCRIPT.md").write_text("\n".join(script))


def shown(b):
    rem = b["shot"]["remotion"]
    p = rem.get("props", {})
    if rem["pattern"] == "GodotEngineEvidence":
        parts = [p.get("label", "")]
        for i, m in enumerate(p.get("media", [])):
            seg = segments.get(f"{b['beat_id']}_{i}")
            where = f"{seg[0]}.mp4 +{seg[1]:g} s" if seg else "?"
            parts.append(f"{m.get('caption', '')} ({where})")
        for c in p.get("cards", []):
            parts.append(f"card '{c.get('label', '')}'")
        return " · ".join(x for x in parts if x)
    if rem["pattern"] == "BrutalistHesitantWriter":
        return (f"typed: {p.get('text', '').replace(chr(10), ' ')} (corrected on screen: "
                f"{p.get('triggerWords')} → {p.get('replacementWords')})")
    if rem["pattern"] == "FormACard":
        return " / ".join(p.get("lines", []))
    return rem["pattern"]


rows = [f"# SHOTLIST: {title}", "",
        "| Beat | Act | s | Scene | What is shown |", "| --- | --- | --- | --- | --- |"]
for b in beats:
    dur = b.get("actual_duration_s")
    rows.append(f"| {b['beat_id']} | {b['act']} | {dur:.1f} | {b['shot']['remotion']['pattern']} | "
                f"{shown(b).replace('|', '/')} |")
(REEL / "SHOTLIST.md").write_text("\n".join(rows) + "\n")
print(f"SCRIPT.md, SHOTLIST.md · {len(beats)} beats · {words} words · {total:.1f} s")
