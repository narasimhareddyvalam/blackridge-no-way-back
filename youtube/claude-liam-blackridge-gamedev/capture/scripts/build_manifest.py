"""Write capture/manifest.json: every output file of this capture with its SHA-256,
size, media properties and provenance (take, method, driver, rig revision, logs).

Usage: python3 -I build_manifest.py
"""

import hashlib
import json
import os
import subprocess
from datetime import datetime, timezone

from PIL import Image

REEL = "/Users/narasimhareddyvalam/Desktop/Blackridge_No_Way_Back/youtube/claude-liam-blackridge-gamedev"
CAP = os.path.join(REEL, "capture")
TAKE_NAMES = ["take_a_headlights", "take_b_driver_window", "take_c_one_shader_two_materials",
              "take_c2_shader_edit_visible", "take_d_interface_sweep",
              "take_e_hint_gl_compatibility", "take_e_hint_forward_plus",
              "take_f_generated_vs_fog"]
SWEEP_UNIFORMS = ["fog_amount", "fog_opacity", "clear_center", "edge_softness",
                  "normal_strength", "texture_scale", "fog_tint"]

SNAPSHOT = {
    "description": "Isolated copy of the repository's game/ folder (cp -Rp, including .godot/) at "
                   "/private/tmp/claude-501/-Users-narasimhareddyvalam-Desktop-Blackridge-No-Way-Back/"
                   "59cc27ca-ea9d-4bb1-919c-75b671e4d5dd/scratchpad/blackridge-capture/",
    "repository_commit": "25c78737db54c6e9977cddb365fb7518b48833a4",
    "repository_game_status": "git status --porcelain -- game: empty (before and after)",
    "files_hashed": 385,
    "file_list_sha256": "420ca4e6610f4c39d8b54e71ba5b3953130494532bd83223743e4bd318976524",
    "file_lists": ["capture/logs/snapshot/repo_game_before.sha256",
                   "capture/logs/snapshot/copy_game_initial.sha256",
                   "capture/logs/snapshot/repo_game_after.sha256",
                   "capture/logs/snapshot/copy_game_final.sha256"],
    "copy_changes": ["project.godot: application/config/use_custom_user_dir=true and "
                     "custom_user_dir_name=\"blackridge_capture_copy\" (separate user://)",
                     "project.godot: [editor] movie_writer/mjpeg_quality=0.95 (no such key in "
                     "4.7.2, no effect; Movie Maker used only for the probes)",
                     "capture_drivers/: copies of capture/scripts/*.gd"],
    "copy_changes_diff": "capture/logs/snapshot/copy_project_godot.diff",
    "shaders_and_materials_in_copy": "byte-identical to the repository after all takes",
}

RIG1 = "capture/scripts/history/capture_rig.rev1_takes_A_B.gd"
RIG2 = "capture/scripts/history/capture_rig.rev2_takes_C_D_E_F.gd"
RIG3 = "capture/scripts/capture_rig.gd"
RUN1 = "capture/scripts/history/run_take.rev1_takes_A_B.sh"
RUN2 = "capture/scripts/run_take.sh"


def take(name, driver, rig, runner, extra=None, csv=True):
    entry = {"driver_script": "capture/scripts/%s.gd" % driver,
             "rig_revision": rig, "runner": runner,
             "input_log": "capture/%s-inputs.jsonl" % name,
             "result": "capture/logs/%s-result.json" % name,
             "engine_log": "capture/logs/%s.log" % name}
    if csv:
        entry["frames_csv"] = "capture/%s-frames.csv" % name
    entry.update(extra or {})
    return entry


TAKES = {
    "A": take("take_a_headlights", "take_a_headlights", RIG1, RUN1,
              {"shared_scripts": ["capture/scripts/game_take.gd"]}),
    "B": take("take_b_driver_window", "take_b_driver_window", RIG1, RUN1,
              {"shared_scripts": ["capture/scripts/game_take.gd"]}),
    "C": take("take_c_one_shader_two_materials", "take_c_one_shader_two_materials", RIG2, RUN2,
              {"shared_scripts": ["capture/scripts/game_take.gd", "capture/scripts/fog_take.gd"],
               "analysis": "capture/logs/analysis_take_c.json"}),
    "C2": take("take_c2_shader_edit_visible", "take_c2_shader_edit_visible", RIG3, RUN2,
               {"shared_scripts": ["capture/scripts/game_take.gd", "capture/scripts/fog_take.gd"],
                "analysis": "capture/logs/region_change_shares.json"}),
    "D": take("take_d_interface_sweep", "take_d_interface_sweep", RIG2, RUN2,
              {"shared_scripts": ["capture/scripts/game_take.gd", "capture/scripts/fog_take.gd"],
               "analysis": "capture/logs/analysis_take_d.json"}),
    "E-compatibility": take("take_e_hint_gl_compatibility", "take_e_hint", RIG2, RUN2, csv=False),
    "E-forward_plus": take("take_e_hint_forward_plus", "take_e_hint", RIG2, RUN2, csv=False),
    "F": take("take_f_generated_vs_fog", "take_f_generated_vs_fog", RIG2, RUN2,
              {"parameters": "capture/logs/generated_vs_fog_parameters.json"}, csv=False),
}

CLIPS = {
    "take_a_headlights.mp4": ("A", "final clip", "L (headlights action) handled at 3.000, 8.500, "
                              "12.000 and 12.117 s; off-fade ends 3.333 s, on-fade ends 8.733 s, "
                              "reversal back at 12.183 s"),
    "take_b_driver_window.mp4": ("B", "final clip", "J (window_left action) handled at 2.000 s "
                                 "(fully open 3.983 s) and 11.000 s (closed 12.983 s)"),
    "material_edit.mp4": ("C", "final clip", "light_fog fog_amount 0.25 -> 1.0 at 2.000 s "
                          "(clip frame 120); paused, time_scale 0"),
    "shader_edit.mp4": ("C", "final clip", "shared Shader line replaced in memory at 2.000 s "
                        "(clip frame 120); light_fog at .tres values"),
    "shader_edit_visible.mp4": ("C2", "final clip", "light_fog fog_amount 1.0 set before "
                                "recording (disclosed); shared Shader line replaced in memory at "
                                "2.000 s (clip frame 120)"),
}

STILLS = {
    "cockpit_hero_4k.png": ("G (from A)", "take A clip frame 120, t = 2.000 s, headlights on"),
    "fog_baseline.png": ("C", "both overlays at their .tres values, world fog on"),
    "world_fog_off.png": ("C", "Environment.fog_enabled = false at runtime only"),
    "world_fog_on.png": ("C", "world fog on again; pixel-identical to fog_baseline.png"),
    "material_edit_before.png": ("C", "material_edit clip frame 119 (lossless)"),
    "material_edit_after.png": ("C", "material_edit clip frame 120 (lossless)"),
    "shader_edit_before.png": ("C", "shader_edit clip frame 119 (lossless)"),
    "shader_edit_after.png": ("C", "shader_edit clip frame 120 (lossless)"),
    "shader_edit_visible_before.png": ("C2", "shader_edit_visible clip frame 119 (lossless)"),
    "shader_edit_visible_after.png": ("C2", "shader_edit_visible clip frame 120 (lossless)"),
    "hint_compatibility_4k.png": ("E-compatibility", "hint experiment, gl_compatibility"),
    "hint_forward_plus_4k.png": ("E-forward_plus", "hint experiment, forward_plus comparison"),
    "generated_vs_fog_4k.png": ("F", "standard_generated.gdshader (left) vs light_fog.tres "
                                "with fog_amount 1.0 (right), test scene"),
}


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def probe(path):
    out = json.loads(subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0", "-count_packets", "-show_entries",
         "stream=codec_name,width,height,r_frame_rate,nb_read_packets,pix_fmt,color_space,"
         "color_primaries,color_transfer,color_range:format=duration", "-of", "json", path],
        check=True, stdout=subprocess.PIPE).stdout)
    stream = out["streams"][0]
    audio = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "a", "-show_entries",
                            "stream=index", "-of", "csv=p=0", path], check=True,
                           stdout=subprocess.PIPE).stdout.strip()
    num, den = stream["r_frame_rate"].split("/")
    return {"width": int(stream["width"]), "height": int(stream["height"]),
            "fps": float(num) / float(den), "frames": int(stream["nb_read_packets"]),
            "duration_s": round(float(out["format"]["duration"]), 6),
            "codec": stream["codec_name"], "pix_fmt": stream.get("pix_fmt"),
            "color": {key: stream.get(key) for key in
                      ["color_space", "color_primaries", "color_transfer", "color_range"]},
            "audio_streams": len(audio.splitlines()) if audio else 0}


def entry_for(rel):
    path = os.path.join(REEL, rel)
    name = os.path.basename(rel)
    item = {"path": rel, "sha256": sha256(path), "bytes": os.path.getsize(path)}
    media = name in CLIPS or name in STILLS or name.endswith((".mov", ".avi"))         or (name.startswith("sweep_") and rel.count("/") == 1)
    if media:
        item["source_snapshot"] = ("isolated copy of game/ at commit 25c78737db54 (385 files "
                                   "byte-identical to the repository; see source_snapshot)")
    if name in CLIPS:
        key, role, timeline = CLIPS[name]
        item.update({"kind": "clip", "role": role, "take": key, "method": "scripted-input",
                     "timeline": timeline, **probe(path), **TAKES[key],
                     "raw_take": "capture/raw/%s_raw_mjpeg.mov" % name[:-4],
                     "render": "offline, --fixed-fps 60 (not a real-time FPS claim)"})
        if key == "A":
            item["note"] = ("encoded before setparams was added; matrix bt709 and range tv are "
                            "tagged, primaries/transfer read unknown; pixels verified")
    elif rel.startswith("capture/raw/probe/"):
        item.update({"kind": "clip", "role": "Movie Maker resolution probe (not used in the film)",
                     "take": "probe", "method": "scripted",
                     "driver_script": "capture/scripts/probe_resolution.gd", **probe(path),
                     "engine_log": "capture/logs/probe/%s.log" % name[:-4]})
    elif rel.startswith("capture/raw/") and name.endswith("_raw_mjpeg.mov"):
        clip = name[:-len("_raw_mjpeg.mov")] + ".mp4"
        key = CLIPS[clip][0]
        item.update({"kind": "clip", "role": "raw take (MJPEG, quality 0.95 JPEG frames, "
                     "byte-identical to the rendered frames)", "take": key,
                     "method": "scripted-input", **probe(path), **TAKES[key],
                     "encoded_to": "capture/" + clip})
    elif name in STILLS:
        key, what = STILLS[name]
        take_key = "A" if key.startswith("G") else key
        with Image.open(path) as image:
            width, height = image.size
        item.update({"kind": "still", "role": "still", "take": key, "method": "scripted",
                     "what": what, "width": width, "height": height, **TAKES[take_key],
                     "render": "offline, --fixed-fps 60"})
    elif name.startswith("sweep_") and rel.count("/") == 1:
        with Image.open(path) as image:
            width, height = image.size
        stem = name[len("sweep_"):-4]
        uniform, label = stem.rsplit("_", 1)
        item.update({"kind": "still", "role": "interface sweep", "take": "D",
                     "method": "scripted", "uniform": uniform, "value_label": label,
                     "width": width, "height": height, **TAKES["D"]})
    elif rel.startswith("capture/scripts/"):
        item.update({"kind": "script", "role": "capture driver or tool (part of the evidence)"})
    elif name.endswith(".png"):
        with Image.open(path) as image:
            width, height = image.size
        item.update({"kind": "analysis image", "width": width, "height": height,
                     "role": "difference map or verification preview, not footage"})
    else:
        item.update({"kind": "log", "role": "log, data or documentation"})
    return item


def is_mine(rel):
    if rel.count("/") > 1:
        return True
    name = os.path.basename(rel)
    known = {"CAPTURE.md", "hint_samples_4k.txt"} | set(CLIPS) | set(STILLS)
    known |= {"sweep_%s_%s.png" % (u, l) for u in SWEEP_UNIFORMS for l in ["min", "default", "max"]}
    known |= {"%s-inputs.jsonl" % t for t in TAKE_NAMES} | {"%s-frames.csv" % t for t in TAKE_NAMES}
    return name in known


def main():
    files = []
    foreign = {}
    for folder, _dirs, names in os.walk(CAP):
        for name in names:
            if name in (".DS_Store", "manifest.json"):
                continue
            rel = os.path.relpath(os.path.join(folder, name), REEL)
            if not is_mine(rel):
                stamp = datetime.fromtimestamp(os.path.getmtime(os.path.join(REEL, rel)))
                foreign[rel] = ("not produced by these capture drivers; written by another "
                                "process (the reel build), modified %s local time; not hashed "
                                "here" % stamp.strftime("%Y-%m-%d %H:%M"))
                continue
            files.append(rel)
    order = {"clip": 0, "still": 1, "log": 2, "analysis image": 3, "script": 4}
    entries = [entry_for(rel) for rel in sorted(files)]
    entries.sort(key=lambda e: (order.get(e["kind"], 9), e["path"]))
    manifest = {
        "generated_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "documentation": "capture/CAPTURE.md",
        "engine": "Godot 4.7.2.stable.official.ed1daf0bf",
        "renderers": {"gl_compatibility": "OpenGL API 4.1 Metal - Compatibility - Apple M4 "
                                          "(all takes; the project's renderer)",
                      "forward_plus": "Metal 4.0 - Forward+ - Apple M4 (take E comparison only)"},
        "capture_method": "offline render into a SubViewport (3840x2400 cockpit, 3840x2160 test "
                          "scenes) at --fixed-fps 60; Movie Maker probe gave 1280x800 only",
        "real_time_fps_claim": False,
        "source_snapshot": SNAPSHOT,
        "takes": TAKES,
        "not_from_this_capture": dict(sorted(foreign.items())),
        "files": entries,
    }
    with open(os.path.join(CAP, "manifest.json"), "w") as handle:
        json.dump(manifest, handle, indent=2)
        handle.write("\n")
    counts = {}
    for entry in entries:
        counts[entry["kind"]] = counts.get(entry["kind"], 0) + 1
    print("manifest.json: %d files %s" % (len(entries), counts))


if __name__ == "__main__":
    main()
