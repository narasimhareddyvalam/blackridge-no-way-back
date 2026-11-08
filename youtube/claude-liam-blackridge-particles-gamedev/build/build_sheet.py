"""Builds beat_sheet.json for "Blackridge, Rain and Vapour" (godot-gamedev, walker).

Deterministic: code excerpts are read verbatim from the game files, evidence media are copied
hash-identical into the Remotion public folder, audio fields measured by Kokoro are kept while a
beat's narration is unchanged, and cue times come from measured word timings (mp3/words.json)
when they exist. Run from anywhere: python3 build/build_sheet.py
"""
import hashlib
import json
import re
import shutil
from pathlib import Path

REEL = Path(__file__).resolve().parents[1]
REPO = REEL.parents[1]
GAME = REPO / "game"
TOOLKIT = Path.home() / "Desktop" / "brutalist.art"
PUB = "blackridge-rain"
PUBLIC = TOOLKIT / "runtime" / "remotion" / "public" / PUB
SLUG = "claude-liam-blackridge-particles-gamedev"
TITLE = "Blackridge, Rain and Vapour"
PROJECT = "Blackridge: No Way Back"
FPS = 30
ASPECT = 1280 / 800
B1_CROP = {"x": 0.3, "y": 0.0, "w": 0.5, "h": 0.8}
B2_CROP = {"x": 0.2, "y": 0.25, "w": 0.6, "h": 0.6}


def lines(rel, a, b):
    text = (GAME / rel).read_text(encoding="utf-8").splitlines()
    return "\n".join(text[a - 1:b])


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


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
    dst.parent.mkdir(parents=True, exist_ok=True)
    if not dst.exists() or sha(dst) != sha(src):
        shutil.copy2(src, dst)
    return f"{PUB}/{name}"


def strip(effect, rnd, frame):
    """A strip frame: staged for Remotion, and copied hash-identical into the reel's evidence/
    folder, whose reel-relative path is what the ledger hashes."""
    src = REPO / f"captures/{effect}/{rnd}/frame{frame:08d}.png"
    rel = f"evidence/strips/{effect}/{rnd}/frame{frame:08d}.png"
    dst = REEL / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    if not dst.exists() or sha(dst) != sha(src):
        shutil.copy2(src, dst)
    return stage(src, f"strips/{effect}/{rnd}/{frame}.png"), rel


def take(name):
    rel = f"capture/takes/{name}/{name}.mp4"
    return stage(REEL / rel, f"takes/{name}.mp4"), rel


def still(frame):
    rel = f"capture/takes/in_play/stills/in_play_f{frame}.png"
    return stage(REEL / rel, f"stills/in_play_f{frame}.png"), rel


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


def image(src, caption="", crop=None, row=0, at=0.0):
    m = {"kind": "image", "src": src, "aspect": ASPECT, "caption": caption, "row": row, "at": at}
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


def log_lines(rel, keys):
    """Verbatim lines from a recorded log, picked by substring, in the order given."""
    text = (REPO / rel).read_text(encoding="utf-8").splitlines()
    return "\n".join(next(l.rstrip() for l in text if k in l) for k in keys)


BEATS = []


def beat(bid, act, narration, shot, role, **extra):
    b = {"beat_id": bid, "act": act, "role_note": role, "voice": "am_onyx", "engine": "kokoro",
         "narration_text": narration, "shot": shot}
    b.update(extra)
    BEATS.append(b)


CLAUDE_CODE = "Claude Code, directed by the author"

# ---------------------------------------------------------------- bookends and setup

beat("B00", "ASK",
     "Namaste. This is Liam, in for Bear. This is Blackridge: No Way Back, a Godot game where you "
     "drive a freight van through a rainy town at night. The prompt on screen is a reconstruction; "
     "the real work began from the author's brief. Let's take apart the four particle effects this "
     "build added, and how each was tested and priced.",
     {"type": "GRAPHIC", "remotion": {"pattern": "ClaudeComposerAsk", "props": {
         "command": "Please use Walker to convert my game design document about Blackridge: No Way "
                    "Back, a narrative crime game where you drive freight through a rainy industrial "
                    "town at night, into four GPU particle effects: the wiper's flick, the roof's "
                    "spill on a hard brake, rain in every lamp's light, and the exhaust's vapour.",
         "topic": "RECONSTRUCTED PROMPT · BLACKRIDGE", "segment": TITLE,
         "greeting": "Namaste, Liam", "runningText": "reading the brief…",
         "output": ["Brief committed before any effect.", "Four effects. Twenty-two frame strips.",
                    "Every price measured; one over budget."],
         "folderLabel": "@NikBearBrown"}},
      "show": [{"at": "Namaste", "event": "Composer types the reconstructed Walker prompt"},
               {"at": "reconstruction", "event": "Running line, then three result lines land"}]},
     "COLD OPEN LAW + walker bookend 1: Claude composer, prompt begins 'Please use Walker to "
     "convert my game design document about …', describing this game. Eyebrow discloses it is "
     "reconstructed.")

beat("B01", "BLUF",
     "Particle effects are rules. In Blackridge, four of them answer the wipers, the brakes, the "
     "lamps and the engine. Each one was predicted, tested, tuned against frame strips, and priced "
     "on the G P U.",
     {"type": "GRAPHIC", "remotion": {"pattern": "BrutalistHesitantWriter", "props": {
         "text": "Particle effects are noise.\nIn Blackridge, four of them answer\nthe wipers, the "
                 "brakes,\nthe lamps and the engine.",
         "triggerWords": "noise", "replacementWords": "rules",
         "fontSize": 80, "mistakeRate": 2, "hesitateWithin": 2, "hesitateBetween": 8, "charMs": 30,
         "seed": SLUG, "contextTitle": TITLE}},
      "show": [{"at": 0.8, "event": "Writer types 'Particle effects are noise.'"},
               {"at": "rules", "event": "Deletes 'noise', types 'rules'"}]},
     "EXECUTIVE-SUMMARY LAW, walker bookend 2. Single-word trigger 'noise' -> 'rules': the "
     "misconception that particles are random decoration, which the body dismantles.",
     lead_silence_s=0.8,
     qc={"sparse_by_design": True, "sparse_reason": "Hesitant-writer bookend (EXECUTIVE-SUMMARY "
         "LAW): the overview is typed token by token, so steady-state frames are mostly cream."})

hero, hero_rel = still(150)
beat("B02", "SETUP",
     "The author chose four effects and wrote their brief. Effect A: two one-shot events, the "
     "wiper's flick at each top turn and the roof's spill on a hard brake. Effect B: two continuous "
     "ones, rain in each lamp's light and exhaust that follows the throttle. All are G P U particles "
     "in Godot four point seven point two.",
     {"type": "GRAPHIC", "remotion": evidence(
         "Four effects, two jobs each", "scripted input · real main scene · held frame",
         f"{hero_rel} · in-play take frame 150 · game c1c9d8b",
         media=[image(hero, "In play: fast wipers, rain in the office lamps' light")],
         cards=[card("A1 · one-shot", "Wiper flick: wiper_swept, at the top turn", when("B02", "wiper's flick", 4.0)),
                card("A2 · one-shot", "Roof spill: a new hard brake", when("B02", "roof's spill", 6.5), "accent"),
                card("B1 · ambience", "Lamp rain: camera within 65 m of a lamp", when("B02", "rain in each", 10.0)),
                card("B2 · feedback", "Exhaust: engine_on, throttle → amount_ratio", when("B02", "exhaust that", 12.0)),
                card("Engine", "Godot 4.7.2 · Forward+ · GPUParticles3D", when("B02", "Godot four", 15.0))]),
      "show": [{"at": "four effects", "event": "Held in-play frame"},
               {"at": "wiper's flick", "event": "Effect cards light in narration order"}]},
     "Identifies the game, both effects, their jobs and the events and conditions that drive them.")

brief_excerpt = "\n".join(l for l in (REPO / "CHANGE-BRIEF.md").read_text(encoding="utf-8").splitlines()
                          if l.startswith("- **Timing phases:** 0.00–0.07 s")
                          or l.startswith("| 1 | Old Godot 3 property names")
                          or l.startswith("| **Total predicted maximum**"))
beat("B03", "SPEC",
     "Before any effect existed, the brief fixed each one's intent: timing phases, contrast, scale, "
     "change over life, variation and layered emitters. It predicted ten ways they could fail, every "
     "price, and a budget of one point four five milliseconds of G P U time for all four. It was "
     "committed before the build, and Claude's project file imports it.",
     {"type": "GRAPHIC", "remotion": evidence(
         "The brief came first", "document · CHANGE-BRIEF.md, verbatim",
         "CHANGE-BRIEF.md §2, §7, §8 · committed 8c3e636 before the first build commit",
         layout="document", excerpt=brief_excerpt, document_label="CHANGE-BRIEF.md",
         cards=[card("Intent", "Timing, contrast, scale, change over life, variation, layers", when("B03", "timing phases", 3.0)),
                card("§7", "Ten predicted failures, each with its check", when("B03", "ten ways", 9.0)),
                card("§8", "Budget: 1.45 ms of GPU time, all four", when("B03", "one point four five", 12.0), "accent"),
                card("Order", "8c3e636 brief → build · CLAUDE.md:68 imports it", when("B03", "committed before", 17.0), mono=True),
                card("Revisions", "1–11 record every kept change", when("B03", "imports it", 19.0))])},
     "Specification shown verbatim from CHANGE-BRIEF.md (outside game/, so not a gamedev excerpt).")

# ---------------------------------------------------------------- the three parts

beat("B04", "CODE",
     "Every particle system has three parts, and this scene file holds all three. Emission: how "
     "many, and for how long, three hundred puffs living one point six seconds. Process: how they "
     "move and change, here its own material. Draw: what each puff looks like, a quad and its "
     "shader. The settings live in the scene, not in code.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B04", "B2's scene: the three parts", "effects/exhaust_vapour.tscn", 59, 70,
         [("Emission", "amount, lifetime, preprocess"),
          ("Process", "Process_plume, lines 22–40"),
          ("Draw", "Quad_puff and its shader")],
         [("three hundred", 5.0, 62, "Emission"), ("Process", 9.0, 69, "Process"),
          ("Draw", 13.0, 70, "Draw")],
         ["test_exhaust_vapour_config.gd: 44/44, every setting read back (recorded)"], CLAUDE_CODE)},
     "The three parts of a particle system, a line from the scene file for each.")

b2_rear, b2_rear_rel = take("b2_rear")
REAR_CROP = {"x": 0.1, "y": 0.15, "w": 0.65, "h": 0.7}
b2h = {f: strip("exhaust_vapour", "r1", f)[0] for f in (55, 80, 100, 130)}
beat("B05", "RESULT",
     "Here's that scene behind the van, in a fixture. After the ignition, puffs leave the pipe fast "
     "and stop within a metre. On the throttle the plume thickens and glows red in the brake lamps. "
     "Switched off, it rises and thins away.",
     {"type": "GRAPHIC", "remotion": evidence(
         "The three parts, running", "fixture capture · B2 preview · the clip in real time, then held strip frames",
         f"{b2_rear_rel} · captures/exhaust_vapour/r1 frames 55, 80, 100, 130 · ignition f10, throttle f40–80, off f100",
         layout="grid",
         media=[video(b2_rear, "the clip, 30 fps, real time", row=0),
                image(b2h[55], "frame 55, held: throttle", REAR_CROP, row=1),
                image(b2h[80], "frame 80, held: brake lamps", REAR_CROP, row=1),
                image(b2h[100], "frame 100, held: engine off", REAR_CROP, row=2),
                image(b2h[130], "frame 130, held", REAR_CROP, row=2)],
         rows=[{"label": "clip", "at": 0.0},
               {"label": "throttle", "at": when("B05", "on the throttle", 6.4)},
               {"label": "off", "at": when("B05", "switched off", 9.4)}]),
      "evidence_media": b2_rear_rel},
     "Result of B04: the scene's three parts, as the engine draws them.")

cost_rel = "logs/particles/mutations_final/cost/cost_effects_60fps.log"
beat("B06", "PRICE",
     "Why can't a headless run price this? Headless, Godot uses a dummy renderer: nothing is drawn "
     "and no particle is simulated. The cost script's empty-scene control reads two thousandths of a "
     "millisecond, the game half a millisecond, and every effect the same as none. That's only the "
     "C P U's share.",
     {"type": "GRAPHIC", "remotion": evidence(
         "Headless: the CPU's share only", "recorded output · cost_effects.gd, headless, 60 fps",
         cost_rel, layout="document", document_label="cost_effects_60fps.log",
         excerpt=log_lines(cost_rel, ["The controls read", "A1, two bursts alive against",
                                      "A2, one burst alive against", "B1, eight lamp volumes against",
                                      "B2, full throttle against"]),
         cards=[card("Dummy renderer", "No particle drawn or simulated", when("B06", "dummy renderer", 4.0)),
                card("Control", "0.002 ms", when("B06", "control", 9.0), mono=True),
                card("Every effect", "Same as none, within noise", when("B06", "every effect", 14.0), "accent")])},
     "Why a GPU effect's headless price is near zero, with the recorded control.")

# ---------------------------------------------------------------- Effect A

beat("B07", "CODE",
     "A one's event is the van's wiper swept signal, sent every half stroke. The handler acts only "
     "at the top turn, with the wipers on. It takes a free burst from a pool of two, so a new flick "
     "can overlap the last one's spray. If both are still alive, it logs a miss rather than cut one "
     "short.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B07", "A1: the top turn fires a flick", "features/vehicles/freight_van/van_particles.gd",
         288, 300,
         [("Event", "wiper_swept, freight_van.gd:5"),
          ("Retrigger", "overlap, FLICK_POOL 2 (line 17)"),
          ("Park turn", "ignored, below the top turn")],
         [("top turn", 4.0, 290, "top turn only"), ("pool of two", 8.0, 292, "free burst"),
          ("logs a miss", 13.0, 295, "both alive")],
         ["test_wiper_flick_state.gd: 27/27, top turns only, two bursts at most (recorded)"], CLAUDE_CODE)},
     "Effect A1's trigger code.")

in_play, in_play_rel = take("in_play")
WIPERS_REL = "capture/takes/in_play/in_play_wipers.mp4"
wipers = stage(REEL / WIPERS_REL, "takes/in_play_wipers.mp4")
beat("B08", "RESULT",
     "In play, on fast wipers: a flick at every top turn, about one a second, beside the passenger "
     "blade's line of water. This is scripted input on the real game. The log has the wipers fast at "
     "one and a half seconds, and nine flicks by eight and a half.",
     {"type": "GRAPHIC", "remotion": evidence(
         "A1 in play: rapid repeats", "scripted input · real main scene · 30 fps, real time",
         f"{WIPERS_REL}: frames 30–254 of the in-play take · events.txt: wipers fast f45, 9 flicks by f255",
         layout="grid",
         media=[video(wipers, "fast wipers at the site office, real time", row=0),
                video(wipers, "replay of the same excerpt", row=1)],
         rows=[{"label": "in play", "at": 0.0}, {"label": "replay", "at": 7.5}]),
      "evidence_media": WIPERS_REL},
     "Result of B07: Effect A1 in play, including rapid repeats.")

a1r0, a1r0_rel = strip("wiper_flick", "r0", 12)
a1r1, a1r1_rel = strip("wiper_flick", "r1", 12)
a2r0, a2r0_rel = strip("roof_spill", "r0", 20)
a2r1, a2r1_rel = strip("roof_spill", "r1", 20)
A1_CROP = {"x": 0.156, "y": 0.1875, "w": 0.203, "h": 0.275}
A2_CROP = {"x": 0.42, "y": 0.0, "w": 0.52, "h": 0.5}
A2_TOP = {"x": 0.42, "y": 0.0, "w": 0.52, "h": 0.36}
beat("B09", "TUNING",
     "The first strips showed nothing: three-millimetre drops lit only by the night were invisible, "
     "and the spill hid behind the wet glass. At the author's request the drops became water that "
     "bends the light behind it. Claude predicted each frame first; three were wrong, and two were off "
     "in brightness. The author played both effects and kept them, overruling two of Claude's readings.",
     {"type": "GRAPHIC", "remotion": evidence(
         "Effect A: first strip, then r1", "fixture captures · frame strips r0 and r1 · crops",
         "captures/wiper_flick/r0|r1/frame 12 · captures/roof_spill/r0|r1/frame 20 · TUNING.md",
         layout="grid",
         media=[image(a1r0, "A1 r0, frame 12", A1_CROP, row=0, at=0.0),
                image(a1r1, "A1 r1, frame 12", A1_CROP, row=0, at=when("B09", "the drops became", 8.0)),
                image(a2r0, "A2 r0, frame 20", A2_CROP, row=1, at=when("B09", "the spill", 5.0)),
                image(a2r1, "A2 r1, frame 20", A2_CROP, row=1, at=when("B09", "the drops became", 8.0))],
         rows=[{"label": "A1", "at": 0.0}, {"label": "A2", "at": when("B09", "the spill", 5.0)}],
         cards=[card("Predicted", "A1 f12: dashes by the pillar ✓", when("B09", "predicted", 11.0), "pass"),
                card("Wrong", "No heavy drop on f20–30 · passenger line from f11 · A2 streams after f15", when("B09", "three were wrong", 13.0), "fail"),
                card("Verdict", "Kept after play (#164); 2 readings overruled", when("B09", "kept them", 16.0), "accent")])},
     "Effect A: the first strip, the tuning revision (prediction, before and after strips) and the "
     "author's verdict.")

beat("B10", "CODE",
     "A two fires on a new hard brake. The brake comes on at eight metres a second or more, and the "
     "van slows at six metres a second squared for two physics ticks. A second brake while the "
     "spill is alive, or during the roof's twenty-second refill, is ignored.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B10", "A2: a new hard brake spills the roof", "features/vehicles/freight_van/van_particles.gd",
         342, 356,
         [("Thresholds", "8 m/s, 6 m/s², 2 ticks (40–42)"),
          ("Retrigger", "ignored unless roof water is ready (360–363)"),
          ("Refill", "ROOF_REFILL 20 s (43)")],
         [("new hard brake", 1.0, 347, "rising edge"), ("eight metres", 3.0, 348, "8 m/s"),
          ("two physics ticks", 7.0, 353, "2 ticks")],
         ["test_roof_spill_state.gd: 13/13, thresholds, rising edge, refill (recorded)"], CLAUDE_CODE)},
     "Effect A2's trigger code.")

a2_20, a2_20_rel = strip("roof_spill", "r1-retrigger-true", 20)
a2_25, a2_25_rel = strip("roof_spill", "r1-retrigger-true", 25)
a2_30, a2_30_rel = strip("roof_spill", "r1-retrigger-true", 30)
a2_events = (REPO / "captures/roof_spill/r1-retrigger-true/events.txt").read_text().splitlines()
beat("B11", "RESULT",
     "In the fixture, a second hard brake at frame twenty-five changes nothing; the first spill's "
     "streams run on. In the author's first play the spill never showed at all: it fired, but the "
     "wet windshield drew over it. One setting, its render priority, fixed that.",
     {"type": "GRAPHIC", "remotion": evidence(
         "A2: the retrigger is ignored", "fixture capture · A2 preview, retrigger on · frame strip",
         "captures/roof_spill/r1-retrigger-true/ frames 20, 25, 30 · events.txt verbatim",
         layout="grid",
         media=[image(a2_20, "frame 20", A2_TOP, row=0, at=0.0),
                image(a2_25, "frame 25: second brake", A2_TOP, row=0, at=when("B11", "twenty-five", 2.5)),
                image(a2_30, "frame 30", A2_TOP, row=0, at=when("B11", "run on", 5.0))],
         rows=[{"label": "r1", "at": 0.0}],
         cards=[card("events.txt", a2_events[4] + "\n" + a2_events[5], when("B11", "twenty-five", 2.5), mono=True),
                card("Author's play (#160)", "Spill fired, but the wet glass drew over it", when("B11", "never showed", 7.0), "fail"),
                card("Fix", "render_priority 1 on the spill's materials", when("B11", "render priority", 12.0), "pass")]),
      "evidence_media": a2_25_rel},
     "Result of B10: the ignored retrigger, and the author's play finding.")

# ---------------------------------------------------------------- Effect B

beat("B12", "CODE",
     "B one's condition is distance. Each tick, the lamps within sixty-five metres of the camera, "
     "eight at most, are wanted. A newly wanted volume is shown and restarted, so its preprocess "
     "fills the whole fall path at once. One no longer wanted stops emitting, drains, then hides.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B12", "B1: rain where the camera is", "features/environments/industrial_loop/lamp_rain.gd",
         70, 84,
         [("Condition", "RANGE 65 m, MOST_ACTIVE 8 (12–13)"),
          ("Start", "restart(): 1.1 s preprocess"),
          ("Stop", "drain, then hide")],
         [("wanted", 4.0, 72, "nearest ≤ 8"), ("restarted", 8.0, 74, "start"),
          ("stops emitting", 13.0, 78, "stop"), ("hides", 15.0, 84, "hidden")],
         ["test_lamp_rain_state.gd: 13/13, start, stop, pause, hidden (recorded)"], CLAUDE_CODE)},
     "Effect B1's condition code: start and stop.")

b1, b1_rel = take("b1_post")
b1h = {f: strip("lamp_rain", "r1", f)[0] for f in (20, 50, 70, 85, 110)}
pause_still, pause_rel = still(280)
beat("B13", "RESULT",
     "The fixture: a few frames after the start, rain fills the light from just under the lamp to the "
     "ground, steady, then drains from the top after the stop, gone by frame one hundred and ten. In "
     "play, the pause "
     "menu pauses it with the game, and resume carries on. On the title screen it's hidden.",
     {"type": "GRAPHIC", "remotion": evidence(
         "B1: start, stop and pause", "fixture capture · B1 preview · clip, then held strip frames",
         f"{b1_rel} · captures/lamp_rain/r1 frames 20–110 · start f10, stop f70, hidden f109 · {pause_rel} · "
         "game/tests/test_lamp_rain_state.gd:50, 130, 136",
         layout="grid",
         media=[video(b1, "the valley lamp, 30 fps, real time", row=0),
                image(b1h[20], "frame 20, held: lamp to ground", B1_CROP, row=1),
                image(b1h[50], "frame 50, held: steady", B1_CROP, row=1),
                image(b1h[70], "frame 70, held: stop", B1_CROP, row=2),
                image(b1h[85], "frame 85, held: draining", B1_CROP, row=2),
                image(b1h[110], "frame 110, held: empty", B1_CROP, row=2),
                image(pause_still, "in play, paused (scripted input)", row=3)],
         rows=[{"label": "clip", "at": 0.0},
               {"label": "steady", "at": when("B13", "to the ground", 3.8)},
               {"label": "stop", "at": when("B13", "after the stop", 6.2)},
               {"label": "in play", "at": when("B13", "in play", 9.2)}],
         cards=[card("Pause", "State test: rain frozen on Esc, resumes. In play: paused f255–f315", when("B13", "pause", 8.0)),
                card("Title", "State test: hidden on the title, then shown", when("B13", "title screen", 12.0))]),
      "evidence_media": b1_rel},
     "Result of B12: Effect B1 starting, stopping and pausing.")

beat("B14", "CODE",
     "B one's own feature is the sub-emitter. Drops collide with a height field, and each landing "
     "sets off a splash of three droplets. Claude's first build used hide-on-contact collisions, "
     "which in four point seven point two never set off the splash. Rigid collisions do. Neither A "
     "effect uses a sub-emitter.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B14", "B1's own feature: splashes", "effects/lamp_rain_street.tscn", 43, 57,
         [("Collider", "a height field per volume"),
          ("Sub-emitter", "LampSplash (line 117)"),
          ("Found (#156)", "hide-on-contact fired no splash")],
         [("collide", 2.0, 53, "rigid collision"), ("three droplets", 5.0, 57, "3 per landing"),
          ("never set off", 9.0, 56, "AT_COLLISION")],
         ["test_lamp_rain_config.gd: 364/364, collision and sub-emitter read back (recorded)"], CLAUDE_CODE)},
     "Effect B1's feature that Effect A does not use: the splash sub-emitter.")

b1g, b1g_rel = strip("lamp_rain", "r1", 50)
beat("B15", "RESULT",
     "Here's the road under that lamp, cropped and enlarged from the strip: drops reaching the "
     "ground, and at most a few specks where they land. Real-size splashes are too faint to pick out "
     "from a few metres away, and the report records that as a limitation.",
     {"type": "GRAPHIC", "remotion": evidence(
         "B1: drops land; splashes faint", "fixture capture · frame strip · crop ×3.2",
         f"{b1g_rel} · crop of the road and verge under the lamp",
         media=[image(b1g, "Frame 50, under the valley lamp",
                      {"x": 0.375, "y": 0.55, "w": 0.3125, "h": 0.2})],
         cards=[card("Seen", "Streaks to the ground; a few specks on the road", when("B15", "drops reaching", 3.0)),
                card("Limitation", "Real-size splashes are faint at this distance", when("B15", "faint", 7.0), "fail")]),
      "evidence_media": b1g_rel},
     "Result of B14: the splashes, honestly faint.")

beat("B16", "CODE",
     "B two's own feature is a value-driven amount ratio. After ignition it waits, ramps up from "
     "zero, then follows the throttle: point one five at idle, plus point six five times the "
     "throttle. The amount stays three hundred; only the share that emits changes. With the engine "
     "off, it's zero at once.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B16", "B2: the throttle drives amount_ratio", "features/vehicles/freight_van/van_particles.gd",
         372, 385,
         [("Ratio", "0.15 + 0.65 × throttle (52–53)"),
          ("Timing", "wait 0.4 s, ramp 0.6 s (54–55)"),
          ("Amount", "300, fixed")],
         [("waits", 3.0, 380, "0.4 s"), ("ramps up", 4.0, 382, "ramp"),
          ("point six five", 8.0, 384, "0.15–0.80"), ("engine off", 14.0, 373, "zero")],
         ["test_exhaust_vapour_state.gd: 10/10, idle 0.15, full 0.80, amount 300 (recorded)"], CLAUDE_CODE)},
     "Effect B2's feedback code and its feature Effect A does not use.")

b2_rev, b2_rev_rel = take("b2_reverse")
REV_CROP = {"x": 0.15, "y": 0.25, "w": 0.7, "h": 0.7}
b2r = {f: strip("exhaust_vapour", "r1-view-reverse_camera", f)[0] for f in (55, 80, 100, 130)}
dash, dash_rel = still(420)
beat("B17", "RESULT",
     "Through the reverse camera, less of it shows: nothing at idle or on the throttle, a narrow red "
     "column once the brake lamps light it, and a faint grey wisp after switch-off, gone a second "
     "later. The state test reads the ratio itself: point one five at idle, point eight at full "
     "throttle, zero when off, frozen while paused. In play, the dash shows that same camera.",
     {"type": "GRAPHIC", "remotion": evidence(
         "B2: start, throttle, stop", "fixture capture · B2 preview, reverse camera · clip, then held strip frames",
         f"{b2_rev_rel} · captures/exhaust_vapour/r1-view-reverse_camera frames 55–130 · {dash_rel}: in-play dash crop",
         layout="grid",
         media=[video(b2_rev, "the reverse camera, 30 fps, real time", row=0),
                image(b2r[55], "frame 55, held: throttle, none shows", REV_CROP, row=1),
                image(b2r[80], "frame 80, held: brake lamps", REV_CROP, row=1),
                image(b2r[100], "frame 100, held: engine off, a faint wisp", REV_CROP, row=2),
                image(b2r[130], "frame 130, held: gone", REV_CROP, row=2),
                image(dash, "in play: the dash in reverse (scripted input)",
                      {"x": 0.68, "y": 0.62, "w": 0.18, "h": 0.2}, row=3)],
         rows=[{"label": "clip", "at": 0.0},
               {"label": "throttle", "at": when("B17", "a narrow red", 3.9)},
               {"label": "off", "at": when("B17", "faint grey wisp", 6.5)},
               {"label": "in play", "at": when("B17", "in play", 15.0)}],
         cards=[card("test_exhaust_vapour_state.gd", "idle 0.15 · full 0.80 · off 0",
                     when("B17", "state test", 9.5), mono=True),
                card("Pause", "frozen while paused", when("B17", "frozen", 12.5), mono=True)]),
      "evidence_media": b2_rev_rel},
     "Result of B16: Effect B2 through the reverse camera, and the state test's readings of its ratio.")

b1r0, b1r0_rel = strip("lamp_rain", "r0", 50)
b1r1, b1r1_rel = strip("lamp_rain", "r1", 50)
b2r0, b2r0_rel = strip("exhaust_vapour", "r0", 80)
b2r1, b2r1_rel = strip("exhaust_vapour", "r1", 80)
beat("B18", "TUNING",
     "The first B strips showed no rain, and almost no vapour. At the author's request the tuning used real "
     "drop sizes and speeds, drew each drop as the streak a camera sees, and made the exhaust a jet "
     "that stops. Around them, the lamps, the wet road and the roadside were rebuilt too, also at "
     "the author's requests. B two matched every predicted frame, B one all but two details. The "
     "author kept both.",
     {"type": "GRAPHIC", "remotion": evidence(
         "Effect B: first strip, then r1", "fixture captures · frame strips r0 and r1 · crops",
         "captures/lamp_rain/r0|r1/frame 50 · captures/exhaust_vapour/r0|r1/frame 80 · TUNING.md",
         layout="grid",
         media=[image(b1r0, "B1 r0, frame 50", B1_CROP, row=0, at=0.0),
                image(b1r1, "B1 r1, frame 50", B1_CROP, row=0, at=when("B18", "real drop", 4.0)),
                image(b2r0, "B2 r0, frame 80", B2_CROP, row=1, at=when("B18", "the exhaust", 8.0)),
                image(b2r1, "B2 r1, frame 80", B2_CROP, row=1, at=when("B18", "the exhaust", 8.0))],
         rows=[{"label": "B1", "at": 0.0}, {"label": "B2", "at": when("B18", "the exhaust", 8.0)}],
         cards=[card("B2", "Every predicted frame matched", when("B18", "matched", 11.0), "pass"),
                card("B1", "All but two: splashes, spread of streaks", when("B18", "all but two", 13.0)),
                card("World (#150–#158)", "Lamps lighting down · wall lights · wet road · roadside · mist", when("B18", "around them", 10.0)),
                card("Verdict", "Kept after play (#164)", when("B18", "kept both", 15.0), "accent")])},
     "Effect B: the first strip, the tuning revision and the author's verdict.")

# ---------------------------------------------------------------- the process shader

beat("B19", "CODE",
     "Step six: Godot's own code for B two's process material, generated by its converter and saved "
     "by Codex at the author's direction. Line two fifty-four grows each puff along the brief's scale "
     "curve, to six times its birth size. Line two fifty-five fades it along the alpha curve, "
     "densest near the pipe and gone by the end of its life.",
     {"type": "GRAPHIC", "remotion": workbench(
         "B19", "The generated process shader", "shaders/particles_generated.gdshader", 248, 257,
         [("Line 254", "scale_curve 0:1, 0.3:3, 1:6"),
          ("Line 255", "alpha_curve, densest at the pipe"),
          ("Checked", "TEST-REPORT's line references")],
         [("two fifty-four", 7.0, 254, "scale over life"), ("two fifty-five", 12.0, 255, "alpha over life")],
         ["Loaded headless: ShaderMaterial, particles mode, 49 uniforms (recorded)"],
         "generated by Godot, saved by Codex for the author")},
     "Two annotated lines of the generated process shader beside the brief's settings.")

b2s55, b2s55_rel = strip("exhaust_vapour", "r1", 55)
b2s80, b2s80_rel = strip("exhaust_vapour", "r1", 80)
PIPE_CROP = {"x": 0.25, "y": 0.3, "w": 0.5, "h": 0.55}
beat("B20", "RESULT",
     "And that's those two lines on screen: puffs born small and dense at the pipe, growing as they "
     "drift, and fading as they grow. The process shader shapes them over their life. How they look "
     "belongs to the draw step's material.",
     {"type": "GRAPHIC", "remotion": evidence(
         "Scale and alpha over life, drawn", "fixture capture · frame strip r1 · crops",
         f"{b2s55_rel}, {b2s80_rel}",
         layout="grid",
         media=[image(b2s55, "frame 55: a small plume, pulling away", PIPE_CROP, row=0, at=0.0),
                image(b2s80, "frame 80: dense at the pipe, fainter out", PIPE_CROP, row=0, at=when("B20", "growing", 4.0))],
         rows=[{"label": "B2 r1", "at": 0.0}],
         cards=[card("Process", "Scale and alpha over life (254–255)", when("B20", "process shader", 6.0)),
                card("Draw", "The quad's material decides the look", when("B20", "draw step's", 8.0), "accent")]),
      "evidence_media": b2s80_rel},
     "Result of B19: what the two shader lines do.")

# ---------------------------------------------------------------- checks, prices, honesty

tests_excerpt = "\n".join([
    log_lines("logs/particles/strips_163/SUMMARY.txt", ["test_wiper_flick_config.gd", "test_roof_spill_config.gd",
                                                        "test_lamp_rain_config.gd", "test_exhaust_vapour_config.gd",
                                                        "test_wiper_flick_state.gd", "test_lamp_rain_state.gd"]),
    log_lines("logs/particles/mutations_final/SUMMARY.txt", ["- test_wiper_flick_config.gd: WIPER FLICK CONFIG RESULT: 450/451",
                                                             "- first failure: FAIL: BigDrops process.initial_velocity_min"])])
beat("B21", "TESTS",
     "What the tests proved. Configuration tests read every setting back from the scenes: four "
     "hundred fifty-one checks for A one alone. State tests drive the real game through events, "
     "retriggers and pause. Both mutations, a Godot three name and a drifted spread, fail as they "
     "should, and the twenty-two earlier test runs still pass. None of this shows what the screen shows.",
     {"type": "GRAPHIC", "remotion": evidence(
         "What the tests proved", "recorded output · scripts/run-test.sh, headless, 60 fps",
         "logs/particles/strips_163/SUMMARY.txt · logs/particles/mutations_final/SUMMARY.txt",
         layout="document", excerpt=tests_excerpt, document_label="SUMMARY.txt, verbatim",
         cards=[card("Configuration", "451 · 221 · 364 · 44 checks, exit 0", when("B21", "configuration", 2.0), "pass"),
                card("Mutations", "Godot 3 name and value drift: exit 1", when("B21", "mutations", 10.0), "fail"),
                card("Earlier suites", "22 runs pass; art 0 failures", when("B21", "earlier test runs", 16.0), "pass"),
                card("Can't show", "Anything on screen", when("B21", "none of this", 18.0), "accent")])},
     "What the tests proved, the mutations that failed them, and what no headless run can show.")

gpu_rel = "logs/particles/gpu_price/RESULT.txt"
gpu_lines = [l.rstrip() for l in (REPO / gpu_rel).read_text().splitlines()]
gpu_excerpt = "\n".join(l for l in gpu_lines if l.startswith("fx    price")
                        or re.match(r"^(A1|A2|B1|B2|all)\s+-?\d", l))
beat("B22", "PRICE",
     "Then the G P U price. Godot's own timer reads zero on Metal, so Claude used Apple's Metal H U "
     "D, showing and hiding each effect in turn. A one and A two are within budget, B one at its "
     "budget, and B two over: one point one milliseconds against point three. The author kept it. "
     "The frame itself is already twenty-six milliseconds.",
     {"type": "GRAPHIC", "remotion": evidence(
         "GPU price against the budget",
         "recorded output · Metal Performance HUD, windowed, Apple M4 · each effect shown, then hidden",
         f"{gpu_rel} · game/tests/gpu_price.gd · tools/tests/gpu_price.py · B2 kept over budget: "
         "CHANGE-BRIEF.md revision 11 (#167) · the 26 ms frame: TEST-REPORT.md, GPU price",
         layout="document", excerpt=gpu_excerpt, document_label="RESULT.txt, verbatim")},
     "Both prices against the budget (headless in B06, GPU here).")

beat("B23", "LIMITS",
     "Mistakes caught: particles ignoring their own size, rain streaks a quarter as wide as they should "
     "be, splashes that "
     "never fired, a spill hidden behind the glass. The author overruled two of Claude's readings. "
     "Still uncertain: A one's below-zero price, the tailpipe's position, and that heavy frame. Next "
     "step: make B two cheaper. Textures: drawn by a script, plus Poly Haven's C C zero assets. The "
     "game shown is revision c one c nine d eight b.",
     {"type": "GRAPHIC", "remotion": evidence(
         "Mistakes, limits and sources", "records · CHANGE-BRIEF.md revisions · TUNING.md · SOURCES.md",
         "brief revisions 1, 4, 5 · #156 · #160 · TEST-REPORT.md · SOURCES.md · git c1c9d8b",
         layout="cards", columns=2,
         cards=[card("Mistakes caught", "keep_scale off · streaks ¼ wide · no splash · spill behind glass", when("B23", "mistakes", 0.5), "fail"),
                card("Overruled", "Passenger line too bright; A2 streams too white", when("B23", "overruled", 7.0)),
                card("Uncertain", "A1 below zero · tailpipe position · 26 ms frame", when("B23", "uncertain", 10.0)),
                card("Next step", "Make B2 cheaper, then price it again", when("B23", "next step", 15.0), "accent"),
                card("Textures", "tools/make_particle_textures.py · Poly Haven CC0", when("B23", "textures", 17.0)),
                card("Revision shown", "game/ at c1c9d8b", when("B23", "revision", 21.0), "neutral", True)])},
     "Agent mistakes caught, readings overruled, what remains uncertain, one next step, texture "
     "sources and the revision shown.")

beat("B24", "CONTRIBUTIONS",
     "Who did what. The author chose the four effects, wrote the brief, directed every change, "
     "played and judged every effect, and made every final call. Claude Code built, tested, tuned, "
     "captured the strips and measured, all at the author's direction. Codex saved the Step six "
     "shader, also at the author's direction.",
     {"type": "GRAPHIC", "remotion": evidence(
         "Who did what", "records · docs/AUTHOR_PROMPTS_AND_DECISIONS.md #131–#173 · FRICTIONAL.md",
         "prompt log · FRICTIONAL.md · SUBMISSION.md",
         layout="cards",
         cards=[card("The author", "Chose the effects · wrote the brief · directed every change · played and judged · every final call", when("B24", "the author", 1.0), "accent"),
                card("Claude Code", "Built · tested · tuned · captured strips · measured — at the author's direction", when("B24", "claude code", 9.0)),
                card("Codex", "Saved Step 6's shader — at the author's direction", when("B24", "codex", 15.0))])},
     "Human and AI contributions, stated as the records state them.")

beat("B25", "VERDICT",
     "Let's recap with Claude. Implemented: four G P U effects, each on a real event or condition, "
     "tested and tuned. Verified: predictions against frame strips, and mutations that fail the "
     "tests. Still open: B two's G P U cost, and a heavy frame. Human judgement: the author played "
     "every effect and made every call.",
     {"type": "GRAPHIC", "remotion": {"pattern": "ClaudeVerdictArtifact", "props": {
         "artifactTitle": "Verdict", "artifactHeading": TITLE,
         "artifactLines": [
             "Implemented: four GPU particle effects on real events and conditions.",
             "Verified: predictions against frame strips; mutations fail the tests.",
             "Open: B2 over its GPU budget, and a heavy frame.",
             "Human judgement: the author played every effect and made every call."]}}},
     "Walker bookend 4a: verdict separates implemented work, limitations and human judgement.",
     lead_silence_s=0.5,
     qc={"sparse_by_design": True, "sparse_reason": "Locked ClaudeVerdictArtifact bookend: the "
         "component fixes the card layout and the four recap lines are the mandated content."})

beat("B26", "HANDOFF",
     "Your turn. Paste this into Claude. Please use Walker to help me tune one particle setting in my "
     "game. I will pick the setting myself. Before you change anything, ask for my prediction of what "
     "the next frame strip will show and what it will cost on the G P U, then capture the strip, "
     "measure the price, and show me predicted versus measured. It makes you commit before you look, "
     "and makes Claude measure instead of guess. Judge the answer on three things: it asks for your "
     "prediction first, shows the strip and the price, and flags any mismatch. Liam, in for Bear.",
     {"type": "GRAPHIC", "remotion": {"pattern": "ClaudeComposerAsk", "props": {
         "command": "Please use Walker to help me tune one particle setting in my game. I will pick "
                    "the setting myself. Before you change anything, ask for my prediction of what "
                    "the next frame strip will show and what it will cost on the GPU, then capture "
                    "the strip, measure the price, and show me predicted versus measured.",
         "topic": "YOUR TURN · BLACKRIDGE", "segment": TITLE, "greeting": "Your turn.",
         "runningText": "paste this into Claude…", "folderLabel": "@NikBearBrown"}}},
     "HANDOFF LAW + walker Your Turn: Liam reads the prompt aloud, discusses it, signs off.")

beat("B27", "OUTRO",
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
        "game": PROJECT, "game_project": "game/", "game_revision": "c1c9d8b", "brand": "claude-liam",
        "audience": "Godot developers and students following the @NikBearBrown Claude workflows",
        "register": "Teardown", "engine": "kokoro", "voice": "am_onyx", "voice_kokoro": "am_onyx",
        "palette": "claude", "style_preset": "claude", "aspect_ratio": "16:9", "fit": "contain",
        "fps": FPS, "captions": False, "channel": "@NikBearBrown", "channel_title": "@NikBearBrown",
        "folderLabel": "@NikBearBrown", "greeting": "Namaste, Liam",
        "greeting_note": "hello lexicon: Namaste (Hindi), as in the author's Assignment 5 film.",
        "persona": "Liam (in for Bear)", "presenter": "Liam (in for Bear)", "in_for_bear": True,
        "teaching_contract": "code-then-result-v1",
        "note": "Contributions are stated as the records state them (prompt log #173).",
    },
    "beats": BEATS,
}
sheet_path.write_text(json.dumps(sheet, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
words = sum(len(b["narration_text"].split()) for b in BEATS)
print(f"wrote {sheet_path.relative_to(REPO)}: {len(BEATS)} beats, {words} words")
