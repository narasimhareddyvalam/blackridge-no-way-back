"""Writes coverage.json for `./art godot-waikthrough --check` from build/features.json.

Each capture is a 4K window of a Movie Maker run (captures/pitch/takes4k/, ignored by git),
hard-linked into capture/ so the reel holds it without a second copy on disk; its run's log is
copied to capture/logs/ as the input log. build_id is the SHA-256 of `git ls-tree -r 61cf104 game`
(the game's source snapshot every take was recorded from; game/ is unchanged since then).
Run: python3 build/coverage.py
"""
import hashlib
import json
import os
import shutil
import subprocess
from pathlib import Path

REEL = Path(__file__).resolve().parents[1]
REPO = REEL.parents[1]
TAKES = REPO / "captures" / "pitch" / "takes4k"
RUNS = Path("/private/tmp/claude-501/-Users-narasimhareddyvalam-Desktop-Blackridge-No-Way-Back/"
            "6d179fcb-f42d-4bcc-9794-abf1186d54dc/scratchpad/rec4k")
REV = "61cf104"


def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


tree = subprocess.run(["git", "-C", str(REPO), "ls-tree", "-r", REV, "game"],
                      capture_output=True, check=True).stdout
build_id = hashlib.sha256(tree).hexdigest()
plan = json.loads((REEL / "build" / "features.json").read_text())
(REEL / "capture" / "logs").mkdir(parents=True, exist_ok=True)
captures = {}
for cid, cap in plan["captures"].items():
    src = TAKES / f"{cid}.mp4"
    dst = REEL / "capture" / f"{cid}.mp4"
    if not dst.exists() or os.stat(dst).st_ino != os.stat(src).st_ino:
        dst.unlink(missing_ok=True)
        os.link(src, dst)
    log_dst = REEL / "capture" / "logs" / f"{cap['run']}.log"
    log_src = RUNS / cap["run"] / "run.log"
    if log_src.exists():
        shutil.copyfile(log_src, log_dst)
    captures[cid] = {"path": f"capture/{cid}.mp4", "sha256": sha(dst), "build_id": build_id,
                     "method": "scripted-input", "input_log": f"capture/logs/{cap['run']}.log",
                     "player": cap["player"], "run_seconds_from": cap["from_s"],
                     "recorded": "2026-11-23, Godot 4.7.2 Movie Maker, 3840x2160, 30 fps, "
                                 "scripted input through the real controls (film_kit.gd)"}
coverage = {"schema_version": 1,
            "game": {"name": "Blackridge: No Way Back", "build_id": build_id,
                     "build_id_is": f"SHA-256 of `git ls-tree -r {REV} game`",
                     "revision": REV},
            "observations_by": plan["observations_by"],
            "captures": captures, "features": plan["features"]}
(REEL / "coverage.json").write_text(json.dumps(coverage, indent=1, ensure_ascii=False) + "\n")
print(f"coverage.json: {len(captures)} captures, {len(plan['features'])} features")
