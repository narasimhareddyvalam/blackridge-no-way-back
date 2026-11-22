"""Mission 3's sounds (#359), synthesized as Mission 1's are (source_assets/audio/first_drive/):
a pistol fired outdoors between container stacks (a broadband crack of a few milliseconds, the
lower muzzle boom, and the echoes the stacks throw back at 60, 140 and 260 ms), and a bullet
striking the windshield's laminated glass (a click, a bright burst and a few fragments tinkling).

Usage, from the repository root:
    python3 -I source_assets/audio/last_run/synthesize.py
"""

from array import array
from pathlib import Path
import math
import random
import wave

RATE = 22050
TAU = math.tau
OUTPUT = Path(__file__).resolve().parents[3] / 'game/features/audio/last_run'


def render(name, seconds, sample):
    count = int(seconds * RATE)
    data = array('h')
    for i in range(count):
        t = i / RATE
        value = max(-0.95, min(0.95, sample(t, i)))
        data.append(round(value * 32767))
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT / (name + '.wav')), 'wb') as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(data.tobytes())


def pistol_shot():
    rng = random.Random(359)
    low = 0.0
    echoes = [(0.0, 1.0), (0.06, 0.32), (0.14, 0.18), (0.26, 0.09)]

    def shot(t):
        crack = rng.uniform(-1, 1) * math.exp(-t / 0.004)
        return crack

    def boom(t):
        nonlocal low
        low += (rng.uniform(-1, 1) - low) * 0.08
        return low * 3.2 * math.exp(-t / 0.07) * (1.0 - math.exp(-t / 0.002))

    def sample(t, i):
        value = 0.0
        for delay, gain in echoes:
            local = t - delay
            if local >= 0.0:
                value += gain * (0.9 * shot(local) + boom(local))
        return value * 0.85

    return sample


def glass_hit():
    rng = random.Random(3591)
    bright = 0.0
    previous = 0.0
    tinkles = [(rng.uniform(0.02, 0.2), rng.uniform(3200, 6200)) for _ in range(6)]

    def sample(t, i):
        nonlocal bright, previous
        raw = rng.uniform(-1, 1)
        high = raw - previous
        previous = raw
        click = math.exp(-t / 0.0015) * rng.uniform(-1, 1)
        burst = high * 0.6 * math.exp(-t / 0.035)
        ring = 0.0
        for start, pitch in tinkles:
            local = t - start
            if local >= 0.0:
                ring += 0.12 * math.sin(TAU * pitch * local) * math.exp(-local / 0.03)
        return click + burst + ring

    return sample


render('pistol_shot', 0.9, pistol_shot())
render('glass_hit', 0.35, glass_hit())
