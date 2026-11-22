"""Synthesises the depot's loading sounds (#286) into game/features/audio/loading/, as the first
drive's sounds are made (source_assets/audio/first_drive/synthesize.py): mono, 22,050 Hz, 16 bit.

lift_beep: a dock lift's motion alarm, a piezo beep at 2.8 kHz, 0.3 s on and 0.3 s off, looped
    by the game while the lift moves.
jack_pump: one stroke of a hand pallet jack's pump: the handle's creak down, the hydraulic
    piston's knock and the check valve's click.
jack_lower: the release valve opened: oil hissing back, falling away over 1.2 s.
ratchet_click: one pull of a ratchet strap's handle: its pawl clicking over three teeth of the
    gear in 0.3 s, each a little higher as the webbing tightens.
strap_hook: a strap's steel hook snapped into a floor ring.

Usage, from the repository root:
    python3 -I source_assets/audio/loading/synthesize.py
"""

from array import array
from pathlib import Path
import math
import random
import wave

RATE = 22050
TAU = math.tau
OUTPUT = Path(__file__).resolve().parents[3] / "game/features/audio/loading"


def render(name, seconds, sample):
    data = array("h")
    for i in range(int(seconds * RATE)):
        value = max(-0.94, min(0.94, sample(i / RATE, i)))
        data.append(round(value * 32767))
    with wave.open(str(OUTPUT / (name + ".wav")), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(data.tobytes())


def lift_beep(t, i):
    on = (t % 0.6) < 0.3
    edge = min(1.0, (t % 0.6) / 0.004, (0.3 - (t % 0.6)) / 0.004) if on else 0.0
    return 0.35 * edge * (math.copysign(1.0, math.sin(TAU * 2800 * t)) * 0.5
                          + math.sin(TAU * 2800 * t) * 0.5)


def knock(t, at, pitch, decay, loud):
    if t < at:
        return 0.0
    since = t - at
    return loud * math.exp(-since * decay) * math.sin(TAU * pitch * since)


def make_noise(seed, smoothing):
    rng = random.Random(seed)
    state = [0.0]

    def sample():
        state[0] += (rng.uniform(-1, 1) - state[0]) * smoothing
        return state[0]

    return sample


PUMP_NOISE = make_noise(286, 0.2)
HISS = make_noise(287, 0.6)
CLICK = make_noise(288, 0.9)


def jack_pump(t, i):
    creak = 0.12 * math.sin(TAU * (180 + 60 * t) * t) * math.exp(-((t - 0.12) / 0.08) ** 2)
    return creak + knock(t, 0.22, 95, 30, 0.6) + PUMP_NOISE() * 0.15 * math.exp(-max(0, t - 0.22)
        * 25) * (t > 0.22) + knock(t, 0.3, 2400, 120, 0.25)


def jack_lower(t, i):
    swell = min(1.0, t / 0.05) * math.exp(-t * 2.2)
    return HISS() * 0.45 * swell


def ratchet_click(t, i):
    total = 0.0
    for index, at in enumerate((0.0, 0.11, 0.21)):
        if t >= at:
            total += knock(t, at, 3000 + 150 * index, 260, 0.5) + CLICK() * 0.3 \
                * math.exp(-(t - at) * 300)
    return total


def strap_hook(t, i):
    return knock(t, 0.0, 1700, 90, 0.4) + knock(t, 0.006, 640, 60, 0.35) + CLICK() * 0.2 \
        * math.exp(-t * 120)


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    render("lift_beep", 0.6, lift_beep)
    render("jack_pump", 0.5, jack_pump)
    render("jack_lower", 1.2, jack_lower)
    render("ratchet_click", 0.32, ratchet_click)
    render("strap_hook", 0.2, strap_hook)
    for path in sorted(OUTPUT.glob("*.wav")):
        print(path.name, path.stat().st_size)


if __name__ == "__main__":
    main()
