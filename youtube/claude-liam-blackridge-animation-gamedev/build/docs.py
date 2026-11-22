"""Writes SCRIPT.md, SHOTLIST.md and COMPONENTS.md from beat_sheet.json and gamedev-evidence.json,
so the documents cannot drift from the film. Run: python3 build/docs.py
"""
import json
from pathlib import Path

REEL = Path(__file__).resolve().parents[1]
sheet = json.loads((REEL / "beat_sheet.json").read_text())
ledger = json.loads((REEL / "gamedev-evidence.json").read_text())
title = sheet["metadata"]["title"]
beats = sheet["beats"]
total = sum(b.get("actual_duration_s") or 0 for b in beats)

script = [f"# SCRIPT — {title}", "",
          f"Narration as spoken by Liam (Kokoro `am_onyx`), {len(beats)} beats, "
          f"{sum(len(b['narration_text'].split()) for b in beats)} words, {total:.1f} s measured.", ""]
for b in beats:
    dur = b.get("actual_duration_s")
    script += [f"## {b['beat_id']} · {b['act']}" + (f" · {dur:.1f} s" if dur else ""), "",
               b["narration_text"], ""]
(REEL / "SCRIPT.md").write_text("\n".join(script))


def shown(b):
    rem = b["shot"]["remotion"]
    p = rem.get("props", {})
    if rem["pattern"] == "GodotDevWorkbench":
        return f"{p['path']}:{p['startLine']}–{p['startLine'] + p['code'].count(chr(10))} · {p['source'].split(' · ')[2]}"
    if rem["pattern"] == "GodotEngineEvidence":
        media = ", ".join(m["src"].split("/", 1)[1] for m in p.get("media", []))
        return f"{p['label']}" + (f" · {media}" if media else "") + (f" · {p['documentLabel']}" if p.get("documentLabel") else "")
    return rem["pattern"]


rows = ["# SHOTLIST — " + title, "",
        "| Beat | Act | s | Scene | What is shown |", "| --- | --- | --- | --- | --- |"]
for b in beats:
    dur = b.get("actual_duration_s")
    rows.append(f"| {b['beat_id']} | {b['act']} | {dur:.1f} | {b['shot']['remotion']['pattern']} | "
                f"{shown(b).replace('|', '/')} |" if dur else
                f"| {b['beat_id']} | {b['act']} | – | {b['shot']['remotion']['pattern']} | {shown(b).replace('|', '/')} |")
(REEL / "SHOTLIST.md").write_text("\n".join(rows) + "\n")

comp = ["# COMPONENTS — " + title, "",
        f"From `gamedev-evidence.json`: {len(ledger['files'])} files in {len(ledger['components'])} "
        f"components, {len(ledger['exclusions'])} excluded with a reason, {len(ledger['excerpts'])} "
        f"verbatim excerpts, {len(ledger['code_result_pairs'])} code → result pairs.", ""]
for c in ledger["components"]:
    comp += [f"## {c['id']}", "", c["explanation"], "", f"Beats: {', '.join(c['beat_ids'])}", "",
             "Files: " + ", ".join(f"`{f}`" for f in c["files"]), ""]
comp += ["## Code → result pairs", "", "| Code | Result | Observation | Media |", "| --- | --- | --- | --- |"]
for p in ledger["code_result_pairs"]:
    comp.append(f"| {p['code_beat']} | {p['result_beat']} | {p['observation']} | `{p['media']['path']}` |")
(REEL / "COMPONENTS.md").write_text("\n".join(comp) + "\n")
print(f"SCRIPT.md, SHOTLIST.md, COMPONENTS.md · {len(beats)} beats · {total:.1f} s")
