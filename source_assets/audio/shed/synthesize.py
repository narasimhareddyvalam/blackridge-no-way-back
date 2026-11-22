"""Synthesises the transfer shed's sounds (part G of step 5 of #253, #302) into
game/features/audio/shed/, as the depot's loading sounds are made
(source_assets/audio/loading/synthesize.py): mono, 22,050 Hz, 16 bit, provisional until the author
chooses final audio (docs/AUDIO.md).

forklift_motor: an electric counterbalance truck's traction motor, a whine near 880 Hz with its
    harmonics over the tyres' rumble on the slab; looped, its pitch raised by the game with speed.
forklift_pump: the hydraulic pump while the forks lift: a whine near 420 Hz over a buzz; looped.
forklift_horn: an electric truck's horn, two notes a minor third apart, 0.4 s.
reverse_alarm: a broadband ("white noise") reversing alarm, 0.5 s of band-limited hiss in each
    second, the quieter kind many indoor sites use; looped while the truck backs.
roof_rain: heavy rain on a steel roof heard from under it: a dense drumming, each drop a short
    metallic knock, over the deck's hiss; looped.
heater_run: a gas unit heater running: its propeller fan's whoosh and the burner's low roar;
    looped.
heater_start: the heater lighting: the igniter's ticks, the gas catching with a soft thump.
fan_whoosh: a 20 ft fan turning slowly: a faint swish at its blades' passing (eight blades at
    15 rpm, 2 Hz) over its gearbox's hum; looped.
radio: a small radio on the dock desk playing low, a few bars of plain chords and a bass line
    through a small speaker's narrow band; looped, a stand-in for the author's choice.
scanner_beep: a handheld barcode scanner's read beep, 2.7 kHz for 0.12 s.

Loops cross-fade their last 0.25 s into their start, so they repeat without a click. The same
every run (seeded noise). Usage, from the repository root:
    python3 -I source_assets/audio/shed/synthesize.py
"""

from array import array
from pathlib import Path
import math
import random
import wave

RATE = 22050
TAU = math.tau
FADE = 0.25
OUTPUT = Path(__file__).resolve().parents[3] / "game/features/audio/shed"


def write(name, values):
    data = array("h", (round(max(-0.94, min(0.94, value)) * 32767) for value in values))
    with wave.open(str(OUTPUT / (name + ".wav")), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(data.tobytes())


def render(name, seconds, sample, loop=False):
    total = int(seconds * RATE)
    extra = int(FADE * RATE) if loop else 0
    values = [sample(i / RATE, i) for i in range(total + extra)]
    if loop:
        for i in range(extra):
            mix = i / extra
            values[i] = values[i] * mix + values[total + i] * (1.0 - mix)
        values = values[:total]
    write(name, values)


def make_noise(seed, smoothing):
    rng = random.Random(seed)
    state = [0.0]

    def sample():
        state[0] += (rng.uniform(-1, 1) - state[0]) * smoothing
        return state[0]

    return sample


def band(seed, low, high):
    """Noise between two one-pole filters: a crude band-pass."""
    rng = random.Random(seed)
    a = 1.0 - math.exp(-TAU * high / RATE)
    b = 1.0 - math.exp(-TAU * low / RATE)
    state = [0.0, 0.0]

    def sample():
        state[0] += (rng.uniform(-1, 1) - state[0]) * a
        state[1] += (state[0] - state[1]) * b
        return state[0] - state[1]

    return sample


RUMBLE = make_noise(302, 0.02)


def forklift_motor(t, i):
    whine = sum(math.sin(TAU * 880 * k * t) / k ** 1.6 for k in (1, 2, 3))
    return 0.16 * whine + 0.35 * RUMBLE()


PUMP_BUZZ = make_noise(303, 0.3)


def forklift_pump(t, i):
    whine = math.sin(TAU * 420 * t) + 0.4 * math.sin(TAU * 840 * t)
    return 0.22 * whine * (0.85 + 0.15 * math.sin(TAU * 30 * t)) + 0.12 * PUMP_BUZZ()


def forklift_horn(t, i):
    edge = min(1.0, t / 0.01, (0.4 - t) / 0.03)
    tone = sum(math.copysign(1.0, math.sin(TAU * f * t)) * 0.5 + math.sin(TAU * f * t) * 0.5
               for f in (420, 500))
    return 0.22 * edge * tone


ALARM = band(304, 500, 6000)


def reverse_alarm(t, i):
    phase = t % 1.0
    on = phase < 0.5
    edge = min(1.0, phase / 0.03, (0.5 - phase) / 0.03) if on else 0.0
    return 0.55 * edge * ALARM()


DECK = band(305, 300, 7000)
DROPS = random.Random(306)
RING = [0.0] * 6
RING_AT = [0.0] * 6
RING_PITCH = [0.0] * 6


def roof_rain(t, i):
    if DROPS.random() < 0.09:
        slot = DROPS.randrange(len(RING))
        RING[slot] = DROPS.uniform(0.15, 0.5)
        RING_AT[slot] = t
        RING_PITCH[slot] = DROPS.uniform(900, 3200)
    knocks = 0.0
    for slot in range(len(RING)):
        since = t - RING_AT[slot]
        if 0.0 <= since < 0.03:
            knocks += RING[slot] * math.exp(-since * 160) * math.sin(TAU * RING_PITCH[slot]
                                                                     * since)
    return 0.32 * DECK() + 0.5 * knocks


FAN_AIR = band(307, 150, 2500)
ROAR = make_noise(308, 0.03)


def heater_run(t, i):
    blade = 0.85 + 0.15 * math.sin(TAU * 24 * t)
    return 0.3 * FAN_AIR() * blade + 0.4 * ROAR() + 0.05 * math.sin(TAU * 60 * t)


IGNITE = make_noise(309, 0.9)
CATCH = make_noise(310, 0.05)


def heater_start(t, i):
    ticks = sum(math.exp(-(t - at) * 400) * IGNITE() * 0.6 for at in (0.1, 0.35, 0.6)
                if 0.0 <= t - at < 0.02)
    thump = 0.5 * math.exp(-max(0.0, t - 0.8) * 6) * CATCH() * (t > 0.8)
    return ticks + thump


SWISH = band(311, 100, 1200)


def fan_whoosh(t, i):
    passing = 0.5 + 0.5 * math.sin(TAU * 2.0 * t) ** 2
    return 0.18 * SWISH() * passing + 0.04 * math.sin(TAU * 110 * t)


SPEAKER = [0.0, 0.0]
CHORDS = [(220.0, 277.2, 329.6), (196.0, 246.9, 293.7), (174.6, 220.0, 261.6),
          (196.0, 246.9, 293.7)]
BASS = [110.0, 98.0, 87.3, 98.0]


def radio(t, i):
    bar = int(t // 2.0) % len(CHORDS)
    beat = t % 0.5
    pluck = math.exp(-beat * 5)
    tone = sum(math.sin(TAU * f * t) for f in CHORDS[bar]) * 0.18 * (0.6 + 0.4 * pluck)
    tone += math.sin(TAU * BASS[bar] * t) * 0.25 * math.exp(-(t % 1.0) * 3)
    SPEAKER[0] += (tone - SPEAKER[0]) * 0.35
    SPEAKER[1] += (SPEAKER[0] - SPEAKER[1]) * 0.02
    return (SPEAKER[0] - SPEAKER[1]) * 0.8


def scanner_beep(t, i):
    edge = min(1.0, t / 0.004, (0.12 - t) / 0.004)
    return 0.3 * edge * math.sin(TAU * 2700 * t)


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    render("forklift_motor", 2.0, forklift_motor, True)
    render("forklift_pump", 1.5, forklift_pump, True)
    render("forklift_horn", 0.4, forklift_horn)
    render("reverse_alarm", 1.0, reverse_alarm, True)
    render("roof_rain", 6.0, roof_rain, True)
    render("heater_run", 4.0, heater_run, True)
    render("heater_start", 1.5, heater_start)
    render("fan_whoosh", 4.0, fan_whoosh, True)
    render("radio", 8.0, radio, True)
    render("scanner_beep", 0.12, scanner_beep)
    for path in sorted(OUTPUT.glob("*.wav")):
        print("Wrote", path.name)


if __name__ == "__main__":
    main()
