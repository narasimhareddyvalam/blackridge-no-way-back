"""Writes SCRIPT.md, the exact voiced script, from beat_sheet.json.
The author-approved draft is kept as SCRIPT-DRAFT.md; BUILD-LOG.md lists the changes since.
Run: python3 build/script_md.py"""
import json
from pathlib import Path

REEL = Path(__file__).resolve().parents[1]
sheet = json.loads((REEL / "beat_sheet.json").read_text())
m = sheet["metadata"]
lines = [f"# SCRIPT.md — {m['title']}", "",
         f"Voiced script, generated from `beat_sheet.json`. Narrator: {m['persona']} (Kokoro "
         f"`{m['voice_kokoro']}`); register {m['register']}; godot-gamedev with the `{m['modifier']}` modifier.",
         "The author-approved draft is `SCRIPT-DRAFT.md`; changes since then are listed in `BUILD-LOG.md`.", ""]
total = 0.0
for b in sheet["beats"]:
    rem = b["shot"].get("remotion", {})
    dur = b.get("actual_duration_s") or 0
    total += dur
    lines += [f"## {b['beat_id']} — {b['act'].title()} ({rem.get('pattern')}, {dur:.1f} s)", ""]
    show = b["shot"].get("show", [])
    if show:
        lines.append("**On screen:** " + " · ".join(f"{e['event']}" for e in show) + ".")
        lines.append("")
    lines += [f"**Liam:** {b['narration_text']}", ""]
lines.append(f"Total narration clock: {total / 60:.1f} minutes.")
(REEL / "SCRIPT.md").write_text("\n".join(lines) + "\n")
print(f"SCRIPT.md written ({total:.0f} s)")
