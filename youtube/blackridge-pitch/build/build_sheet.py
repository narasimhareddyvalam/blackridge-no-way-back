"""Builds the reel's beat_sheet.json for "Blackridge: No Way Back, the Pitch" (Assignment 8).

Deterministic. The authored plan is pitch/beat_sheet.json (approved by the author, #457-#459);
this script keeps the Kokoro-measured audio fields already in the reel's sheet while a beat's
narration is unchanged, cuts each beat's footage from the 4K takes at real speed (a time range re-encoded at
the take's own 30 fps, never retimed), stages the cuts in the
Remotion public folder, and times every card to the first spoken occurrence of its cue phrase
(mp3/words.json, from runtime/scripts/align.py). Run: python3 build/build_sheet.py
"""
import hashlib
import json
import subprocess
from pathlib import Path

REEL = Path(__file__).resolve().parents[1]
REPO = REEL.parents[1]
PLAN = REPO / "pitch" / "beat_sheet.json"
TAKES = REPO / "captures" / "pitch" / "takes4k"
TOOLKIT = Path.home() / "Desktop" / "brutalist.art"
PUB = "blackridge-pitch"
PUBLIC = TOOLKIT / "runtime" / "remotion" / "public" / PUB
FPS = 30
HANDLE = "Narasimha Reddy Valam"
ASPECT = 16 / 9

# Where each beat's footage starts in its 4K take, in seconds (take, start). Times are read from
# the take's own frames and its run log (capture/CAPTURE.md), never guessed from the old videos.
SEGMENTS = json.loads((REEL / "build" / "segments.json").read_text())

WORDS = {}
_words = REEL / "mp3" / "words.json"
if _words.exists():
    _w = json.loads(_words.read_text())
    _fps = _w.get("fps", FPS)
    WORDS = {bid: [(w["text"].strip(".,;:!?\"'()").lower(), w["startFrame"] / _fps) for w in ws]
             for bid, ws in _w.get("beats", {}).items()}
MISSING = []


def when(bid, cue, duration):
    """Seconds into the beat where cue is spoken; a number is taken as seconds already."""
    if isinstance(cue, (int, float)):
        return float(cue)
    if cue in ("", None):
        return 0.0
    target = [t.strip(".,;:!?\"'()").lower() for t in str(cue).split()]
    toks = WORDS.get(bid) or []
    for i in range(len(toks) - len(target) + 1):
        if all(toks[i + j][0] == target[j] for j in range(len(target))):
            return round(toks[i][1], 2)
    MISSING.append(f"{bid}: cue not spoken: {cue!r}")
    return 0.0


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def cut(bid, i, take, start, length):
    """Cut [start, start+length) of a 4K take to the public folder at real speed."""
    src = TAKES / f"{take}.mp4"
    out = PUBLIC / f"{bid}_{i}.mp4"
    PUBLIC.mkdir(parents=True, exist_ok=True)
    stamp = out.with_suffix(".json")
    want = {"take": take, "take_sha256": sha(src), "start_s": start, "length_s": length}
    if out.exists() and stamp.exists() and json.loads(stamp.read_text()) == want:
        return f"{PUB}/{out.name}", want
    # A cut already rendered into its beat and then removed to free disk is not cut again.
    if not out.exists() and stamp.exists() and json.loads(stamp.read_text()) == want \
            and (REEL / "media" / f"{bid}.mp4").exists():
        return f"{PUB}/{out.name}", want
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", f"{start:.3f}", "-i", str(src),
                    "-t", f"{length:.3f}", "-an", "-c:v", "libx264", "-preset", "medium",
                    "-crf", "16", "-pix_fmt", "yuv420p", "-r", str(FPS), str(out)], check=True)
    stamp.write_text(json.dumps(want, indent=1))
    return f"{PUB}/{out.name}", want


def main():
    plan = json.loads(PLAN.read_text())
    built_path = REEL / "beat_sheet.json"
    built = json.loads(built_path.read_text()) if built_path.exists() else {"beats": []}
    measured = {b["beat_id"]: b for b in built.get("beats", [])}
    evidence = []
    for beat in plan["beats"]:
        bid = beat["beat_id"]
        old = measured.get(bid, {})
        if old.get("narration_text") == beat["narration_text"]:
            for key in ("audio_file", "actual_duration_s", "audio_notes"):
                if key in old:
                    beat[key] = old[key]
        if "rendered" in old.get("shot", {}).get("remotion", {}):
            beat["shot"]["remotion"]["rendered"] = old["shot"]["remotion"]["rendered"]
        dur = float(beat.get("actual_duration_s") or 0)
        if not dur:
            MISSING.append(f"{bid}: no measured audio")
            continue
        beat["render_duration_s"] = round(round(dur * FPS) / FPS, 4)
        rem = beat["shot"]["remotion"]
        props = rem["props"]
        if rem["pattern"] == "GodotEngineEvidence":
            props["durationSeconds"] = beat["render_duration_s"]
            props["handle"] = HANDLE
            for c in props.get("cards", []):
                c["at"] = when(bid, c.get("at"), dur)
            media = props.get("media", [])
            for i, m in enumerate(media):
                m["at"] = when(bid, m.get("at"), dur)
                if f"{bid}_{i}" not in SEGMENTS:
                    MISSING.append(f"{bid}: no segment for media {i}")
                    continue
                take, start = SEGMENTS[f"{bid}_{i}"]
                length = dur - m["at"] + 0.5
                src, rec = cut(bid, i, take, float(start), length)
                m.update({"src": src, "startFrom": 0.0, "aspect": ASPECT})
                rec.update({"beat_id": bid, "media": i, "staged": src})
                evidence.append(rec)
            # The footer names the 4K takes the footage is cut from, then the plan's own sources.
            takes = [f"takes4k/{SEGMENTS[f'{bid}_{i}'][0]}.mp4 +{SEGMENTS[f'{bid}_{i}'][1]:g} s"
                     for i in range(len(media)) if f"{bid}_{i}" in SEGMENTS]
            props["source"] = " · ".join(takes + ([props["source"]] if props.get("source") else []))
            if len(media) > 1:
                props["layout"] = "grid"
                props["rows"] = [{"label": m["caption"], "at": m["at"]} for m in media]
                for r, m in enumerate(media):
                    m["row"] = r
            elif len(media) == 1:
                props["layout"] = "media"
            beat["shot"]["evidence_media"] = [e["staged"] for e in evidence if e["beat_id"] == bid]
        elif rem["pattern"] == "ClaudeVerdictArtifact":
            props["brandLabel"] = HANDLE
        elif rem["pattern"] == "ClaudeComposerAsk":
            props.update({"folderLabel": "Blackridge: No Way Back", "modelLabel": "Claude Code",
                          "topic": "YOUR TURN · BLACKRIDGE", "segment": "Check the pitch"})
        elif rem["pattern"] == "TO_CHOOSE_AT_BUILD":
            rem["pattern"] = "FormACard"
            rem["props"] = {"lines": ["Blackridge: No Way Back.", "Still in progress."],
                            "meta": ["a pitch by Narasimha Reddy Valam",
                                     "narration: an AI voice (Kokoro am_onyx)",
                                     "reading the author's approved script"], "dark": True}
    plan["metadata"]["build"] = {"footage": "4K takes in captures/pitch/takes4k/",
                                 "staged": PUB, "cuts": len(evidence)}
    built_path.write_text(json.dumps(plan, indent=1, ensure_ascii=False) + "\n")
    (REEL / "build" / "staged.json").write_text(json.dumps(evidence, indent=1) + "\n")
    print(f"built {len(plan['beats'])} beats, {len(evidence)} footage cuts")
    for m in MISSING:
        print("  !", m)
    return 1 if MISSING else 0


if __name__ == "__main__":
    raise SystemExit(main())
