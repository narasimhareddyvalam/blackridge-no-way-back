"""Builds beat_sheet.json for "Blackridge, Frame by Frame" (godot-gamedev, walker), Assignment 7.

Deterministic: code excerpts are read verbatim from the game files, evidence media are copied
hash-identical into the Remotion public folder, audio fields measured by Kokoro are kept while a
beat's narration is unchanged, and cue times come from measured word timings (mp3/words.json)
when they exist. Run from anywhere: python3 build/build_sheet.py
"""
import hashlib
import json
import shutil
from pathlib import Path

REEL = Path(__file__).resolve().parents[1]
REPO = REEL.parents[1]
GAME = REPO / "game"
TOOLKIT = Path.home() / "Desktop" / "brutalist.art"
PUB = "blackridge-motion"
PUBLIC = TOOLKIT / "runtime" / "remotion" / "public" / PUB
SLUG = "claude-liam-blackridge-animation-gamedev"
TITLE = "Blackridge, Frame by Frame"
PROJECT = "Blackridge: No Way Back"
REVISION = "1e7765e"
FPS = 30
ASPECT = 1280 / 800


def lines(rel, a, b):
    text = (GAME / rel).read_text(encoding="utf-8").splitlines()
    return "\n".join(text[a - 1:b])


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


MISSING = []
WORDS = {}
_words = REEL / "mp3" / "words.json"
if _words.exists():
    _w = json.loads(_words.read_text())
    _fps = _w.get("fps", FPS)
    WORDS = {bid: [(w["text"].strip(".,;:!?\"'()").lower(), w["startFrame"] / _fps) for w in ws]
             for bid, ws in _w.get("beats", {}).items()}


def when(bid, phrase, fallback):
    """Start time (s) of the first occurrence of phrase in beat bid's measured words."""
    target = [t.strip(".,;:!?\"'()").lower() for t in phrase.split()]
    toks = WORDS.get(bid) or []
    for i in range(len(toks) - len(target) + 1):
        if all(toks[i + j][0] == target[j] for j in range(len(target))):
            return round(toks[i][1], 2)
    if toks:
        print(f"  ! {bid}: phrase not found: {phrase!r}; using {fallback}")
    return fallback


def stage(src, name):
    """Copy an evidence file into the Remotion public folder; return its staticFile path."""
    src = Path(src)
    dst = PUBLIC / name
    if not src.exists():
        MISSING.append(str(src))
        return f"{PUB}/{name}"
    dst.parent.mkdir(parents=True, exist_ok=True)
    if not dst.exists() or sha(dst) != sha(src):
        shutil.copy2(src, dst)
    return f"{PUB}/{name}"


def evid(src_rel, rel):
    """A repository file copied hash-identical into the reel's evidence/ folder and staged."""
    src = REPO / src_rel
    dst = REEL / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.exists() and (not dst.exists() or sha(dst) != sha(src)):
        shutil.copy2(src, dst)
    return stage(src, rel.removeprefix("evidence/")), rel


def strip(rnd, frame):
    return evid(f"captures/enter_van/{rnd}/frame_{frame:03d}.png",
                f"evidence/strips/enter_van/{rnd}/frame_{frame:03d}.png")


def take(rel):
    return stage(REEL / rel, rel.removeprefix("capture/")), rel


def workbench(bid, title, rel, a, b, notes, cues, output, credit, font=24):
    return {
        "pattern": "GodotDevWorkbench",
        "props": {
            "mode": "code", "title": title, "project": PROJECT, "path": f"game/{rel}",
            "source": f"{rel}:{a}–{b} · {credit} · verbatim",
            "code": lines(rel, a, b), "startLine": a, "codeFontSize": font,
            "inspectorLabel": "Source notes — not Inspector values",
            "notes": [{"label": k, "value": v} for k, v in notes],
            "cues": [{"at": when(bid, ph, fb), "line": ln, "label": lab} for ph, fb, ln, lab in cues],
            "output": output, "dense": True,
        },
    }


def evidence(title, label, source, layout="media", media=(), cards=(), rows=(), excerpt="",
             document_label="", ticks=(), columns=1):
    return {
        "pattern": "GodotEngineEvidence",
        "props": {"title": title, "label": label, "source": source, "layout": layout,
                  "media": list(media), "cards": list(cards), "rows": list(rows),
                  "excerpt": excerpt, "documentLabel": document_label, "ticks": list(ticks),
                  "cardColumns": columns},
    }


def image(src, caption="", crop=None, row=0, at=0.0, aspect=ASPECT):
    m = {"kind": "image", "src": src, "aspect": aspect, "caption": caption, "row": row, "at": at}
    if crop:
        m["crop"] = crop
    return m


def video(src, caption="", start=0.0, at=0.0, crop=None, row=0):
    m = {"kind": "video", "src": src, "aspect": ASPECT, "caption": caption, "startFrom": start,
         "at": at, "row": row}
    if crop:
        m["crop"] = crop
    return m


def card(label, text, at, tone="neutral", mono=False):
    return {"label": label, "text": text, "at": at, "tone": tone, "mono": mono}


def log_lines(rel, keys, width=118):
    """Verbatim lines from a recorded log, picked by substring, in the order given (cut at width)."""
    text = (REPO / rel).read_text(encoding="utf-8").splitlines()
    out = []
    for k in keys:
        line = next(l.rstrip() for l in text if k in l)
        out.append(line if len(line) <= width else line[:width - 1] + "…")
    return "\n".join(out)


BEATS = []


def beat(bid, act, narration, shot, role, **extra):
    b = {"beat_id": bid, "act": act, "role_note": role, "voice": "am_onyx", "engine": "kokoro",
         "narration_text": narration, "shot": shot}
    b.update(extra)
    BEATS.append(b)


CC = "Claude Code, directed by the author"
DOOR_CROP = {"x": 0.25, "y": 0.22, "w": 0.4, "h": 0.6}
DASH_CROP = {"x": 0.28, "y": 0.2, "w": 0.46, "h": 0.56}

# ---------------------------------------------------------------- bookends and setup

beat("B00", "ASK",
     "Namaste. This is Liam, in for Bear. This is Blackridge: No Way Back, a Godot game where you "
     "drive a freight van through a rainy town at night. The prompt on screen is a reconstruction; "
     "the real work began from the author's brief. Let's take apart the four animation clips this "
     "build added, and how each was timed and tested.",
     {"type": "GRAPHIC", "remotion": {"pattern": "ClaudeComposerAsk", "props": {
         "command": "Please use Walker to convert my game design document about Blackridge: No Way "
                    "Back, a narrative crime game where you drive freight through a rainy town at "
                    "night, into four animation clips: a phone ringing on the dash, Ethan getting "
                    "into his van, a rifle reload, and his shock after the hit.",
         "topic": "RECONSTRUCTED PROMPT · BLACKRIDGE", "segment": TITLE,
         "greeting": "Namaste, Liam", "runningText": "reading the brief…",
         "output": ["Brief and pins committed before any clip.", "Four clips, one owner each.",
                    "Two strips; one revision open for the author."],
         "folderLabel": "@NikBearBrown"}},
      "show": [{"at": "Namaste", "event": "Composer types the reconstructed Walker prompt"},
               {"at": "reconstruction", "event": "Running line, then three result lines land"}]},
     "COLD OPEN LAW + walker bookend 1: Claude composer, prompt begins 'Please use Walker to "
     "convert my game design document about …', describing this game. Eyebrow discloses it is "
     "reconstructed.")

beat("B01", "BLUF",
     "A clip is a resource: tracks, keys, a length and a loop mode. In Blackridge, each of four "
     "clips has exactly one owner that plays it, and its timing is designed in frames.",
     {"type": "GRAPHIC", "remotion": {"pattern": "BrutalistHesitantWriter", "props": {
         "text": "A clip is a movie.\nIn Blackridge, four clips,\none owner each,\ntimed in frames.",
         "triggerWords": "movie", "replacementWords": "resource",
         "fontSize": 80, "mistakeRate": 2, "hesitateWithin": 2, "hesitateBetween": 8, "charMs": 30,
         "seed": SLUG, "contextTitle": TITLE}},
      "show": [{"at": 0.8, "event": "Writer types 'A clip is a movie.'"},
               {"at": "resource", "event": "Deletes 'movie', types 'resource'"}]},
     "EXECUTIVE-SUMMARY LAW, walker bookend 2. Single-word trigger 'movie' -> 'resource': the "
     "misconception that a clip is footage, which the body dismantles.",
     lead_silence_s=0.8,
     qc={"sparse_by_design": True, "sparse_reason": "Hesitant-writer bookend (EXECUTIVE-SUMMARY "
         "LAW): the overview is typed token by token, so steady-state frames are mostly cream."})

dash_still, dash_still_rel = take("capture/takes/ring_play/stills/dash.png")
door_still, _ = strip("r1", 44)
reload_still, _ = take("capture/takes/reload/stills/reload_f30.png")
shock_still, _ = take("capture/takes/shock/stills/shock_f58.png")
beat("B02", "SETUP",
     "Four clips. The ring is the cycle: a sprite on the dash, looping while Maya's call rings. "
     "Enter Van is the committing action: Ethan's imported rig getting into his van, played once. "
     "Two more ride the same rig: a motion captured rifle reload, and a keyed shock after the hit. "
     "Godot four point seven point two.",
     {"type": "GRAPHIC", "remotion": evidence(
         "Four clips, two routes", "held frames · scripted input and fixture captures",
         f"capture/takes/ring_play, captures/enter_van/r1 frame 44, capture/takes/reload, "
         f"capture/takes/shock · game {REVISION}",
         layout="grid",
         media=[image(dash_still, "Ring: Sprite2D frame track, loops", DASH_CROP, row=0),
                image(door_still, "EnterVan: imported rig, commits", DOOR_CROP, row=0),
                image(reload_still, "Rifle reload: motion capture", row=1),
                image(shock_still, "Shock: keyed bones, seated", row=1)],
         rows=[{"label": "the pair", "at": 0.0},
               {"label": "two more", "at": when("B02", "two more", 9.0)}]),
      "show": [{"at": "the ring", "event": "Ring and EnterVan stills"},
               {"at": "two more", "event": "Reload and shock stills"}]},
     "Identifies the game, both graded clips, their routes, which loops and which commits, and "
     "the two further clips.")

brief_excerpt = "\n".join(l for l in (REPO / "CHANGE-BRIEF.md").read_text(encoding="utf-8").splitlines()
                          if l.startswith("| Startup | 0-31 (32)")
                          or l.startswith("| Active | 32-47 (16)")
                          or l.startswith("- **Frames** 6†; **frame rate** 10 fps†")
                          or l.startswith("- **Seam rule (frame track):**"))
beat("B03", "SPEC",
     "Before any clip existed, the brief fixed the cycle's spec, six frames at ten per second with "
     "its seam rule, and Enter Van's phase table in frames: startup, active and recovery, what the "
     "player may do in each, and what the game reads. Then pins recorded how the game behaved, all "
     "committed before setup.",
     {"type": "GRAPHIC", "remotion": evidence(
         "The brief came first", "document · CHANGE-BRIEF.md, verbatim",
         "CHANGE-BRIEF.md §3, §4 · brief e284453 · pins 1cf092d · first clip f6f5565",
         layout="document", excerpt=brief_excerpt, document_label="CHANGE-BRIEF.md",
         cards=[card("Cycle spec", "6 frames · 10 fps · seam rule", when("B03", "six frames", 3.0)),
                card("Phase table", "startup · active · recovery, in frames", when("B03", "phase table", 7.0), "accent"),
                card("Order", "e284453 brief → 1cf092d pins → f6f5565 clip", when("B03", "committed before", 16.0), mono=True)])},
     "Specification shown verbatim from CHANGE-BRIEF.md (outside game/, so not a gamedev excerpt).")

# ---------------------------------------------------------------- the ring

beat("B04", "CODE",
     "So what is a clip? This file is the whole ring. Length point six seconds, loop mode one, "
     "linear, and a step of point one. One value track, Ring Icon's frame, with update discrete, so "
     "the integer jumps instead of sweeping. Six keys, frames zero to five. The last key sits one "
     "step before the length: that's the seam rule.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B04", "The ring: a clip is a resource", "animations/phone_ring.tres", 4, 18,
         [("Length", "0.6 s · loop_mode 1 = LOOP_LINEAR"),
          ("Track", "RingIcon:frame · update 1 = discrete"),
          ("Seam", "last key 0.5 + step 0.1 = length")],
         [("point six", 3.5, 5, "length"), ("loop mode", 5.0, 6, "loop"),
          ("ring icon's frame", 10.0, 11, "track"), ("update discrete", 12.5, 17, "discrete"),
          ("six keys", 16.0, 15, "keys"), ("seam rule", 21.0, 15, "seam")],
         ["test_ring_readback.gd: 15/15, step, length, LOOP_LINEAR, discrete, seam (recorded)"], CC)},
     "Question 1, what a clip is, pointed at the clip's own lines.")

sheet_dark, sheet_rel = take("capture/sheet/phone_ring_on_dark.png")
ring_cells = [take(f"capture/takes/ring_play/stills/ring_f{i}.png")[0] for i in range(6)]
beat("B05", "RESULT",
     "Here's the sheet that track reads: six sixty-four pixel cells in one row, drawn by a script "
     "in white, so the dash can tint them. The sprite slices it with six frames across and one "
     "down. On the dash, the handset alone, then one, two, three arcs, then the arcs fading away, "
     "and back to the handset.",
     {"type": "GRAPHIC", "remotion": evidence(
         "The sheet, sliced", "the sheet on a dark backing, cell lines drawn · the ring take: six frames 3 apart, one 0.6 s cycle, crops ×3",
         f"{sheet_rel} (from game/features/vehicles/freight_van/art/ring/phone_ring.png) · "
         "tools/art/make_phone_ring_sheet.py · hframes 6, vframes 1 · ring take frames",
         layout="grid",
         media=[image(sheet_dark, "phone_ring.png: 6 × 64 px cells, white on transparent", row=0, aspect=6.0)]
               + [image(ring_cells[i], f"frame {123 + 3 * i}", row=1, aspect=1.5,
                        at=when("B05", "the handset alone", 9.0) + i * 0.6)
                  for i in range(6)],
         rows=[{"label": "sheet", "at": 0.0},
               {"label": "on the dash", "at": when("B05", "on the dash", 9.0)}]),
      "evidence_media": sheet_rel},
     "Result of B04: the sheet, its slicing, and the cells the frame track shows.")

beat("B06", "CODE",
     "One authority means exactly one node writes to an animated node. For the ring it's the "
     "navigation display, and only these lines call play and stop. It reads its own call state and "
     "call seconds: ringing, or answering itself, with the timer below zero. Nothing else touches "
     "the dash.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B06", "One authority over the ring", "features/vehicles/freight_van/navigation_display.gd",
         167, 175,
         [("Owner", "navigation_display.gd alone"),
          ("Reads", "call_state, call_seconds"),
          ("Writes", "RingPlayer play/stop, RingIcon visible")],
         [("only these lines", 6.0, 172, "play"), ("call state", 9.0, 168, "reads state"),
          ("below zero", 13.0, 168, "call_seconds < 0"), ("nothing else", 15.5, 174, "stop")],
         ["test_animation_structure.gd: only navigation_display.gd names the ring's nodes (recorded)"], CC)},
     "Question 2, one authority, pointed at the ring's owner.")

ring_take, ring_take_rel = take("capture/takes/ring_play/ring_dash.mp4")
beat("B07", "RESULT",
     "In play: Maya calls on the climb out of the depot, and the camera zooms to the dash. The "
     "handset pulses while it rings. This is scripted input on the real game, in real time. The "
     "state test saw every cell, the wrap from five to zero, and the icon hidden once the call "
     "connects.",
     {"type": "GRAPHIC", "remotion": evidence(
         "The ring in play", "scripted input · real main scene · 30 fps, real time, then replays",
         f"{ring_take_rel} · tools/captures/capture_a7_clips.gd · game {REVISION}",
         layout="grid",
         media=[video(ring_take, "Maya's call ringing, the dash zoomed, real time", crop=DASH_CROP, row=0, at=0.0),
                video(ring_take, "replay of the same excerpt", crop=DASH_CROP, row=1, at=5.5),
                video(ring_take, "replay of the same excerpt", crop=DASH_CROP, row=2, at=11.0)],
         rows=[{"label": "in play", "at": 0.0}, {"label": "replay", "at": 5.5}, {"label": "replay", "at": 11.0}],
         cards=[card("State test", "every cell seen · wraps 5 → 0 · hidden when talking", when("B07", "state test", 9.0), "pass")]),
      "evidence_media": ring_take_rel},
     "Result of B06: the ring cycle playing under its owner in real play.")

# ---------------------------------------------------------------- EnterVan

beat("B08", "CODE",
     "Enter Van is Mixamo's Entering Car on Ethan's imported rig, a hundred sixty-four frames at "
     "thirty per second. Its loop mode is set here, in the importer's per-animation settings: zero, "
     "loop none. In a scene, it would be lost on the next import.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B08", "EnterVan: the loop mode in the importer", "features/characters/ethan/ethan.glb.import",
         44, 49,
         [("Clip", "EnterVan, 164 frames at 30 fps"),
          ("Setting", "settings/loop_mode 0 = LOOP_NONE"),
          ("Why here", "a scene edit is lost on reimport")],
         [("loop mode", 6.0, 49, "loop_mode 0")],
         ["test_rig_readback.gd from an empty cache: 9/9 (recorded)"], CC)},
     "The rig clip's import setting.")

rig_rel = "logs/animation/rig/fresh_cache/test_rig_readback_60fps.log"
mut_rel = "logs/animation/rig/mutation_loop/test_rig_readback_60fps.log"
rig_log, rig_log_rel = evid(rig_rel, "evidence/logs/rig_fresh_cache.log")
board, board_rel = take("capture/takes/ring_play/boarding.mp4")
BOARD_CROP = {"x": 0.28, "y": 0.2, "w": 0.52, "h": 0.6}
beat("B09", "RESULT",
     "In play, it runs once: he gets in, and the cab view takes over. To prove the setting holds, "
     "the cache was deleted and the game imported fresh. The read-back resolved all one hundred "
     "fourteen bone tracks and read loop none. Set to one in the importer instead, the clip "
     "imported looping, and the same test failed two checks.",
     {"type": "GRAPHIC", "remotion": evidence(
         "From an empty cache, then once in play",
         "recorded output · scripted input on the real main scene, 30 fps, real time",
         f"{rig_rel} · {mut_rel} · {board_rel}", layout="grid",
         media=[video(board, "real play: E at the door, EnterVan once, then the cab", crop=BOARD_CROP,
                      row=0, at=0.0),
                video(board, "replay of the same excerpt", crop=BOARD_CROP, row=1, at=8.0)],
         rows=[{"label": "in play", "at": 0.0}, {"label": "replay", "at": 8.0}],
         cards=[card("Fresh import", log_lines(rig_rel, ["E7 it plays once"]).removeprefix("PASS: "),
                     when("B09", "read-back", 3.0), "pass", True),
                card("Fresh import", log_lines(rig_rel, ["RIG READBACK RESULT"]), when("B09", "bone tracks", 5.0), "pass", True),
                card("Importer set to 1", log_lines(mut_rel, ["RIG READBACK RESULT"]), when("B09", "set to one", 8.0), "fail", True)]),
      "evidence_media": board_rel},
     "Result of B08: the importer setting proven from an empty cache, its mutation, and the clip "
     "playing once in real play.")

beat("B10", "CODE",
     "Designing feel in frames means the phase table becomes code. The boarding reads Enter Van's "
     "frames over thirty: the reach from frame twenty-two, the hand on the handle at thirty-two, the "
     "door fully open at forty-eight, and the cut to black at sixty-two.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B10", "The phase table, in frames", "app/first_drive.gd", 30, 38,
         [("Startup", "0–31: the step and the reach"),
          ("Active", "32–47: the handle, the door swings"),
          ("Recovery", "48–68: he climbs in; cut at 62")],
         [("over thirty", 5.0, 32, "CLIP_FPS"), ("twenty-two", 7.0, 34, "REACH_FROM"),
          ("thirty-two", 9.0, 33, "DOOR_GRAB"), ("forty-eight", 11.0, 36, "DOOR_OPENED"),
          ("sixty-two", 13.0, 37, "CUT")],
         ["test_rig_readback.gd: the app's moments on frames 22, 32, 48, 62: 14/14 (recorded)"], CC)},
     "Question 4, feel in frames: the phase table's boundaries as the app's constants.")

r1 = {f: strip("r1", f)[0] for f in (12, 34, 44, 60, 70, 82)}
r1_rel = "evidence/strips/enter_van/r1/frame_060.png"
beat("B11", "RESULT",
     "Here's the frame strip at each boundary, a fixture at the depot at night. Frame zero, he "
     "faces the door. Twenty-two, the reach. Thirty-two, the hand on the handle, the door shut. "
     "Forty-eight, the door open. Fifty-eight, he's rising into the cab. Then black, and seated.",
     {"type": "GRAPHIC", "remotion": evidence(
         "The strip at each phase boundary", "fixture capture · Movie Maker · strip r1 · crops",
         "captures/enter_van/r1 · capture frame = 12 + clip frame · logs/animation/step7/enter_van_r1.log",
         layout="grid",
         media=[image(r1[12], "clip 0: trigger", DOOR_CROP, row=0, at=0.0),
                image(r1[34], "clip 22: the reach", DOOR_CROP, row=0, at=when("B11", "twenty-two", 6.0)),
                image(r1[44], "clip 32: hand on the handle", DOOR_CROP, row=0, at=when("B11", "thirty-two", 8.0)),
                image(r1[60], "clip 48: the door open", DOOR_CROP, row=1, at=when("B11", "forty-eight", 11.0)),
                image(r1[70], "clip 58: rising into the cab", DOOR_CROP, row=1, at=when("B11", "fifty-eight", 13.0)),
                image(r1[82], "clip 70: seated, fading up", DOOR_CROP, row=1, at=when("B11", "seated", 16.0))],
         rows=[{"label": "startup → active", "at": 0.0},
               {"label": "recovery", "at": when("B11", "forty-eight", 11.0)}]),
      "evidence_media": r1_rel},
     "Result of B10: the strip read at each phase boundary of the table.")

beat("B12", "CODE",
     "The two clocks. Ethan's animation player advances on the process tick. The boarding loop "
     "reads clip time and sets the door, then waits for the next process frame. The brief predicted "
     "no disagreement, because both use the process tick.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B12", "Two clocks: the clip and the door", "app/first_drive.gd", 914, 920,
         [("Clip clock", "Ethan's AnimationPlayer, process idle"),
          ("Reader", "_board_van, resumed on process_frame"),
          ("Predicted", "0 s apart (brief §6)")],
         [("reads clip time", 5.0, 916, "clip_time()"), ("sets the door", 7.0, 917, "driver_door"),
          ("next process frame", 9.0, 920, "await")],
         ["logs/animation/step7/enter_van_r0.log: clip and door, frame by frame (recorded)"], CC)},
     "Question 3, the two clocks, pointed at the reader and its clock.")

r0log_rel = "logs/animation/step7/enter_van_r0.log"
r0log, r0log_ev = evid(r0log_rel, "evidence/logs/enter_van_r0.log")
r0f = {f: strip("r0", f) for f in (44, 45, 46)}
beat("B13", "RESULT",
     "The per-frame log disagrees by one frame. The process frame signal resumes the loop before the "
     "player advances, so on the frame where the clip reads thirty-four, the door holds the value for "
     "thirty-three. That's one thirtieth of a second, below what the eye separates, so it stays. The "
     "reload has the same kind of gap: its timer ends one sixtieth early.",
     {"type": "GRAPHIC", "remotion": evidence(
         "The clocks, measured", "fixture capture · strip r0 frames with the per-frame log's lines",
         f"{r0log_rel} · captures/enter_van/r0 frames 44-46 · TEST-REPORT.md, the reload's two clocks",
         layout="grid",
         media=[image(r0f[44][0], "clip 32: door 0.000", DOOR_CROP, row=0),
                image(r0f[45][0], "clip 33: door 0.000", DOOR_CROP, row=0),
                image(r0f[46][0], "clip 34: door 0.011 (= frame 33's value)", DOOR_CROP, row=0)],
         rows=[{"label": "r0", "at": 0.0}],
         cards=[card("Log", log_lines(r0log_rel, ["capture 46 movie"]).removeprefix("STRIP "), when("B13", "thirty-four", 6.0), "accent", True),
                card("Size", "1/30 s · kept, recorded", when("B13", "one thirtieth", 11.0)),
                card("Reload", "timer ends at clip 98.5 of 99", when("B13", "reload", 15.0), mono=True)]),
      "evidence_media": r0f[46][1]},
     "Result of B12: the clocks' measured disagreement.")

beat("B14", "CODE",
     "Enter Van's owner is the driver script. Play clip is the only path into Ethan's animation "
     "player, with the rifle helper it builds and calls. The app asks; it never plays. The structure "
     "test checks that no other script reaches the player.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B14", "One authority over Ethan's player", "features/characters/driver/driver.gd", 554, 568,
         [("Owner", "driver.gd (play_clip, _play)"),
          ("Helpers it owns", "push_gait.gd, rifle_carry.gd"),
          ("Caller", "first_drive.gd asks; never plays")],
         [("play clip", 4.0, 554, "play_clip"), ("animation player", 7.0, 564, "_player.play")],
         ["test_animation_structure.gd: 13/13, no other script reaches Ethan's player (recorded)"], CC)},
     "Question 2 for the rig: one authority over Ethan's player.")

ints = {p: take(f"capture/takes/interrupt_{p}/interrupt_{p}.mp4") for p in ("startup", "active", "recovery")}
beat("B15", "RESULT",
     "Now an interrupt in each phase, by real input. In startup, W is held: he doesn't move and the "
     "clip runs on. In the active phase, Escape pauses: the clip and the door freeze, then resume. "
     "In recovery, R recovers: he's seated at once with the door shut. The edge test ran forty-eight "
     "of these, all passing, and found one bug: Escape during the fade seated him behind the pause "
     "menu.",
     {"type": "GRAPHIC", "remotion": evidence(
         "An interrupt in each phase", "fixture captures · real input after the setup · 30 fps, real time",
         "capture/takes/interrupt_startup, _active, _recovery · events.txt · test_animation_edges.gd 48/48",
         layout="grid",
         media=[video(ints["startup"][0], "startup: W held at clip 16, ignored; he ends seated", row=0, at=0.0),
                video(ints["active"][0], "active: Esc at clip 40, the menu over the frozen door, resumed", row=1,
                      at=when("B15", "in the active phase", 6.0)),
                video(ints["recovery"][0], "recovery: R at clip 56, seated at once", row=2,
                      at=when("B15", "in recovery", 11.5))],
         rows=[{"label": "startup", "at": 0.0},
               {"label": "active", "at": when("B15", "in the active phase", 6.0)},
               {"label": "recovery", "at": when("B15", "in recovery", 11.5)}],
         cards=[card("Edge test", "W, E, R, Esc · before, on, after 0, 32, 48, 69 · 48/48", when("B15", "edge test", 15.0), "pass"),
                card("Found", "Esc in the fade → TWEEN_PAUSE_STOP (#374)", when("B15", "found one bug", 18.0), "fail")]),
      "evidence_media": ints["active"][1]},
     "Result of B14: the state machine playing EnterVan in real play, interrupted in each phase.")

r0_65, _ = strip("r0", 65)
r1_70, r1_70_rel = strip("r1", 70)
beat("B16", "TUNING",
     "Then tuning. Claude read the first strip: at the old cut, frame fifty-three, both his feet were "
     "still on the ground, so the brief's climbs in was never seen. The author was away, so Claude "
     "decided: move the cut to sixty-two, predicting him rising into the cab before the fade. The "
     "second strip matched five of six predictions. The pin moved as predicted. The author played it "
     "and judged it good, with more to improve next.",
     {"type": "GRAPHIC", "remotion": evidence(
         "r0 → r1: the cut moved", "fixture captures · strips r0 and r1 · crops",
         "captures/enter_van/r0 frame 65 · r1 frame 70 · TUNING.md r1 · PIN2 re-pinned 2f91bc5",
         layout="grid",
         media=[image(r0_65, "r0, clip 53: the fade begins, feet on the ground", DOOR_CROP, row=0),
                image(r1_70, "r1, clip 58: rising into the cab, no fade", DOOR_CROP, row=0,
                      at=when("B16", "move the cut", 10.0))],
         rows=[{"label": "r0 · r1", "at": 0.0}],
         cards=[card("Decision", "Claude's, under the author's delegation (#406)", when("B16", "claude decided", 9.0)),
                card("Prediction", "5 of 6 seen; the foot lift unreadable", when("B16", "five of six", 16.0)),
                card("Verdict", "“good as well, can be improved” (#417)", when("B16", "the author played", 20.0), "accent")]),
      "evidence_media": r1_70_rel},
     "Inspect-and-revise: Claude's reading, one change with a prediction, two strips; the author's "
     "verdict and observation-driven revision are stated as open.")

# ---------------------------------------------------------------- the reload and the shock

beat("B17", "CODE",
     "The third clip. The author rejected a hand-keyed pistol reload, chose motion capture, then a "
     "rifle. Mixamo's reloading plays on a second player that keys only the upper body, so his legs "
     "keep their own clips. These lines enter the reload while the gun reloads, and leave it when "
     "the gun is done. The gun's timer is the clip's length, ninety-nine thirtieths.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B17", "The reload: the gun decides, the clip follows", "features/characters/driver/rifle_carry.gd",
         161, 174,
         [("Clip", "RifleReload, 100 frames, upper body"),
          ("Player", "UpperBody, over his own player"),
          ("Timer", "RELOAD_SECONDS = 99 / 30 (handgun.gd:21)")],
         [("enter the reload", 10.0, 163, "reloading → reload"), ("leave it", 13.0, 173, "done → aim/ready")],
         ["test_reload_readback.gd 12/12 · test_reload_edges.gd 21/21 (recorded)"], CC)},
     "The reload's state code.")

reload_take, reload_take_rel = take("capture/takes/reload/reload.mp4")
beat("B18", "RESULT",
     "In Mission three: the empty magazine drops at frame fourteen, the fresh one comes up in his "
     "left hand, seated at forty-seven, then the charging handle pulled back eight centimetres. Fire "
     "and R are ignored until the end. This take is a fixture: he was armed directly, skipping the "
     "handover.",
     {"type": "GRAPHIC", "remotion": evidence(
         "The reload in Mission 3", "fixture capture · armed by arm(), then real input (aim, R) · 30 fps, real time, then replays",
         f"{reload_take_rel} · tools/captures/capture_reload_strip.gd · game {REVISION}",
         layout="grid",
         media=[video(reload_take, "aim held, R pressed, the whole reload, real time", row=0, at=0.0),
                video(reload_take, "replay of the same excerpt", row=1, at=5.0),
                video(reload_take, "replay of the same excerpt", row=2, at=10.0)],
         rows=[{"label": "reload", "at": 0.0}, {"label": "replay", "at": 5.0}, {"label": "replay", "at": 10.0}],
         cards=[card("Magazine", "out 14 · in hand 26 · seated 47", when("B18", "frame fourteen", 3.0), mono=True),
                card("Charging handle", "8 cm back at 64-65", when("B18", "charging handle", 9.0), mono=True),
                card("Edges", "fire, R, Esc at 0, 30, 48, 99 · 21/21", when("B18", "ignored", 12.0), "pass")]),
      "evidence_media": reload_take_rel},
     "Result of B17: the reload played in Mission 3.")

beat("B19", "CODE",
     "The fourth clip is keyed by a script over Enter Van's last, seated frame. Play seated puts Ethan "
     "in the driver's seat and plays it. These lines slide him forward until his shoulders are "
     "forty-three centimetres from the rim, so his elbows stay bent; set each hand's target on the "
     "rim, read from the wheel mesh itself; and fade the grip in over eleven frames.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B19", "The shock: seated, hands on the rim", "features/characters/driver/driver.gd", 1027, 1041,
         [("Clip", "shock/Shock, 105 frames, LOOP_NONE (played at line 1020)"),
          ("Keys", "tools/art/make_ethan_shock.gd"),
          ("Reach", "SHOCK_REACH 0.43 m of a 0.48 m arm")],
         [("slide him forward", 7.0, 1030, "slide"), ("each hand's target", 13.0, 1035, "rim target"),
          ("eleven frames", 19.0, 1041, "grip tween")],
         ["test_shock_readback.gd 9/9 · test_shock_state.gd 3/3, wrists within 0.021 m (recorded)"], CC)},
     "The shock's playing code: the seat reach and the grip.")

shock_take, shock_take_rel = take("capture/takes/shock/shock.mp4")
beat("B20", "RESULT",
     "Seen through the windshield in Mission one's four second hold: a startle, panicked breaths, his "
     "head shaking no, the drop toward the wheel, a look at each mirror, then a stare. The author asked "
     "for the hands on the wheel and fear that reads; this is that revision. A fixture, with no struck "
     "man in frame.",
     {"type": "GRAPHIC", "remotion": evidence(
         "The shock, through the windshield", "fixture capture · the van placed and held · 30 fps, real time, then replays",
         f"{shock_take_rel} · tools/captures/capture_shock_shot.gd · #404 · game {REVISION}",
         layout="grid",
         media=[video(shock_take, "the 3.5 s shot inside the 4 s hold, real time", row=0, at=0.0),
                video(shock_take, "replay of the same shot", row=1, at=4.0),
                video(shock_take, "replay of the same shot", row=2, at=8.0)],
         rows=[{"label": "the shot", "at": 0.0}, {"label": "replay", "at": 4.0}, {"label": "replay", "at": 8.0}],
         cards=[card("Phases", "startle · panic · no · drop · mirrors · stare", when("B20", "a startle", 3.0)),
                card("Author's look", "hands on the wheel; fear that reads (#404)", when("B20", "the author asked", 11.0), "accent")]),
      "evidence_media": shock_take_rel},
     "Result of B19: the shock in Mission 1.")

# ---------------------------------------------------------------- checks, limits, contributions

tests_excerpt = "\n".join([
    log_lines("logs/animation/repin/test_ring_readback_60fps.log", ["RING READBACK RESULT"]),
    log_lines("logs/animation/step7_r1/test_rig_readback_60fps.log", ["RIG READBACK RESULT"]),
    log_lines("logs/animation/reload/test_reload_readback_60fps.log", ["RELOAD READBACK RESULT"]),
    log_lines("logs/animation/shock/test_shock_readback_60fps.log", ["SHOCK READBACK RESULT"]),
    log_lines("logs/animation/step7_r1/test_animation_edges_60fps.log", ["ANIMATION EDGES RESULT"]),
    log_lines("logs/animation/step7_r1/test_animation_pins_60fps.log", ["ANIMATION PINS RESULT"]),
    log_lines("logs/animation/mutations/EXITS.txt", ["m1 exit"]),
    log_lines("logs/animation/mutations/EXITS.txt", ["m2 exit"]),
    log_lines("logs/animation/mutations/EXITS.txt", ["m3 exit"]),
    log_lines("logs/animation/mutations/EXITS.txt", ["m4 exit"])])
beat("B21", "TESTS",
     "What the tests proved. Four read-backs resolve every track and pin each clip's key times, step "
     "and loop mode. The structure, state and edge tests pass, and every earlier suite still does. "
     "Three mutations, a broken track, loop none on the cycle and a key past the sheet, fail as they "
     "should; the fourth, a fresh import, can't, by design. None of this shows the motion reads, or "
     "that the ring wraps without a seam.",
     {"type": "GRAPHIC", "remotion": evidence(
         "What the tests proved", "recorded output · scripts/run-test.sh, headless, 60 fps",
         "logs/animation/{repin, step7_r1, reload, shock, mutations} · TEST-REPORT.md",
         layout="document", excerpt=tests_excerpt, document_label="results, verbatim",
         cards=[card("Read-backs", "ring 15 · rig 14 · reload 12 · shock 9", when("B21", "four read-backs", 2.0), "pass"),
                card("Suites", "81 earlier runs pass", when("B21", "every earlier suite", 9.0), "pass"),
                card("Mutations", "3 fail · the importer's passes by design", when("B21", "three mutations", 12.0), "fail"),
                card("Can't show", "the motion reading · the seam", when("B21", "none of this", 21.0), "accent")])},
     "What the read-backs proved, the mutations that failed them, and what no headless run can show.")

beat("B22", "LIMITS",
     "Mistakes caught: the pause bug, a second script playing Ethan's clips, hands short of the wheel, "
     "and the brief's strip frames two early. Overruled: the author rejected Claude's hand-keyed "
     "reload, then corrected its rifle hold in five prompts; no strip reading yet. Uncertain: the seam over five wraps. Next step: the author "
     "improves Enter Van. The sheet is ours, drawn by a script. The game shown is revision one, E, seven, "
     "seven, six, five, E.",
     {"type": "GRAPHIC", "remotion": evidence(
         "Mistakes, limits and sources", "records · CHANGE-BRIEF.md revisions · TUNING.md · SOURCES.md",
         f"brief revisions · #374 · #386 · #404 · TUNING.md · SOURCES.md · git {REVISION}",
         layout="cards", columns=2,
         cards=[card("Mistakes caught", "Esc in the fade · push_gait a 2nd writer · hands short of the rim · §9 two frames early", when("B22", "mistakes", 0.5), "fail"),
                card("Overruled", "the hand-keyed reload (#386) · the rifle hold, five prompts (#398-#402) · no strip reading yet", when("B22", "overruled", 7.0)),
                card("Uncertain", "the ring's seam over five wraps", when("B22", "uncertain", 12.0)),
                card("Next step", "the author improves EnterVan (#417)", when("B22", "next step", 15.0), "accent"),
                card("Sheet", "tools/art/make_phone_ring_sheet.py · ours, no licence needed; Mixamo terms; M16 CC BY", when("B22", "the sheet", 18.0)),
                card("Revision shown", f"game/ at {REVISION}", when("B22", "revision", 21.0), "neutral", True)])},
     "Agent mistakes caught, readings overruled, what remains uncertain, one next step, the sheet's "
     "source and licence and the revision shown.")

beat("B23", "CONTRIBUTIONS",
     "Who did what. The author chose the clips, rejected what didn't look real, downloaded the "
     "motion capture, corrected every look, ruled on the pause bug and approved each step. Claude "
     "Code drafted the brief, built, wired and tested the clips, captured the strips, and made r one "
     "while the author was away.",
     {"type": "GRAPHIC", "remotion": evidence(
         "Who did what", "records · docs/AUTHOR_PROMPTS_AND_DECISIONS.md #362-#406 · FRICTIONAL.md",
         "prompt log · FRICTIONAL.md · SUBMISSION.md",
         layout="cards",
         cards=[card("The author", "Chose the clips · rejected what wasn't real · downloaded the mocap · corrected every look · ruled on the bug · approved each step", when("B23", "the author", 1.0), "accent"),
                card("Claude Code", "Drafted the brief · built, wired, tested · captured strips · made r1 while the author was away", when("B23", "claude code", 11.0))])},
     "Human and AI contributions, stated as the records state them.")

beat("B24", "VERDICT",
     "Let's recap with Claude. Implemented: four clips, each a resource with one owner. Verified: "
     "read-backs, edges at every boundary, mutations that fail. Still open: the Enter Van revision the "
     "author plans next, and the seam over five wraps. Human judgement: the author corrected every "
     "look and judged all four.",
     {"type": "GRAPHIC", "remotion": {"pattern": "ClaudeVerdictArtifact", "props": {
         "artifactTitle": "Verdict", "artifactHeading": TITLE,
         "artifactLines": [
             "Implemented: four clips, each a resource with one owner.",
             "Verified: read-backs, edges at every boundary, mutations that fail.",
             "Open: the EnterVan revision the author plans next; the seam over five wraps.",
             "Human judgement: the author corrected every look and judged all four."]}}},
     "Walker bookend 4a: verdict separates implemented work, limitations and human judgement.",
     lead_silence_s=0.5,
     qc={"sparse_by_design": True, "sparse_reason": "Locked ClaudeVerdictArtifact bookend: the "
         "component fixes the card layout and the four recap lines are the mandated content."})

beat("B25", "HANDOFF",
     "Your turn. Paste this into Claude. Please use Walker to help me retime one phase of one clip in "
     "my game. I will pick the phase myself. Before you change anything, ask for my prediction of "
     "what the frame strip will show at each boundary, then change the phase table, not the keys, "
     "capture the strip, and show me predicted versus seen. It makes you commit before you look. "
     "Judge the answer on three things: it asks for your prediction first, changes only the table, "
     "and flags every mismatch. Liam, in for Bear.",
     {"type": "GRAPHIC", "remotion": {"pattern": "ClaudeComposerAsk", "props": {
         "command": "Please use Walker to help me retime one phase of one clip in my game. I will "
                    "pick the phase myself. Before you change anything, ask for my prediction of what "
                    "the frame strip will show at each boundary, then change the phase table, not the "
                    "keys, capture the strip, and show me predicted versus seen.",
         "topic": "YOUR TURN · BLACKRIDGE", "segment": TITLE, "greeting": "Your turn.",
         "runningText": "paste this into Claude…", "folderLabel": "@NikBearBrown"}}},
     "HANDOFF LAW + walker Your Turn: Liam reads the prompt aloud, discusses it, signs off.")

beat("B26", "OUTRO",
     f"{TITLE}. At Nik Bear Brown.",
     {"type": "GRAPHIC", "remotion": {"pattern": "ClaudeTitleOutro", "props": {"title": TITLE, "slug": SLUG}}},
     "OUTRO-LOCK: exact title, hardcoded @NikBearBrown, slug-seeded mascot, spoken title + handle, "
     "1.0 s silent tail.",
     kind="outro_voice", tail_silence_s=1.0)

# ---------------------------------------------------------------- write

old = {}
sheet_path = REEL / "beat_sheet.json"
if sheet_path.exists():
    old = {b["beat_id"]: b for b in json.loads(sheet_path.read_text())["beats"]}
for b in BEATS:
    prev = old.get(b["beat_id"])
    if prev and prev.get("narration_text") == b["narration_text"]:
        for k in ("audio_file", "actual_duration_s", "render_duration_s", "build", "audio_notes"):
            if k in prev:
                b[k] = prev[k]
    dur = b.get("actual_duration_s")
    props = b["shot"].get("remotion", {}).get("props")
    if dur and isinstance(props, dict) and b["shot"]["remotion"]["pattern"] in (
            "GodotDevWorkbench", "GodotEngineEvidence"):
        props["durationSeconds"] = dur

sheet = {
    "metadata": {
        "title": TITLE, "slug": SLUG, "kind": "godot-gamedev", "modifier": "walker",
        "game": PROJECT, "game_project": "game/", "game_revision": REVISION, "brand": "claude-liam",
        "audience": "Godot developers and students following the @NikBearBrown Claude workflows",
        "register": "Teardown", "engine": "kokoro", "voice": "am_onyx", "voice_kokoro": "am_onyx",
        "palette": "claude", "style_preset": "claude", "aspect_ratio": "16:9", "fit": "contain",
        "fps": FPS, "captions": False, "channel": "@NikBearBrown", "channel_title": "@NikBearBrown",
        "folderLabel": "@NikBearBrown", "greeting": "Namaste, Liam",
        "greeting_note": "hello lexicon: Namaste (Hindi), as in the author's earlier films.",
        "persona": "Liam (in for Bear)", "presenter": "Liam (in for Bear)", "in_for_bear": True,
        "teaching_contract": "code-then-result-v1",
        "note": "Contributions are stated as the records state them (prompt log #362-#406).",
    },
    "beats": BEATS,
}
sheet_path.write_text(json.dumps(sheet, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
words = sum(len(b["narration_text"].split()) for b in BEATS)
print(f"wrote {sheet_path.relative_to(REPO)}: {len(BEATS)} beats, {words} words")
for m in MISSING:
    print(f"  ! missing media: {m}")
