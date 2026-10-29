from array import array
from pathlib import Path
import math
import random
import wave

RATE = 22050
TAU = math.tau
OUTPUT = Path(__file__).resolve().parents[3] / 'game/features/audio/first_drive'


def render(name, seconds, sample, loop=False):
    count = int(seconds * RATE)
    data = array('h')
    for i in range(count):
        t = i / RATE
        envelope = 1.0 if loop else min(1.0, t / 0.008, (seconds - t) / 0.04)
        value = max(-0.94, min(0.94, sample(t, i) * envelope))
        data.append(round(value * 32767))
    with wave.open(str(OUTPUT / (name + '.wav')), 'wb') as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(data.tobytes())


def noise_function(seed, smoothing, amplitude):
    rng = random.Random(seed)
    state = 0.0

    def sample(t, i):
        nonlocal state
        state += (rng.uniform(-1, 1) - state) * smoothing
        return state * amplitude

    return sample


def engine(t, i):
    cycle = TAU * 36 * t
    pulse = math.sin(cycle) * 0.28 + math.sin(cycle * 2) * 0.14
    pulse += math.sin(cycle * 3) * 0.07 + math.sin(cycle * 7) * 0.035
    return pulse * (0.86 + math.sin(TAU * 9 * t) * 0.14)


def score(t, i):
    notes = [110.0, 130.8128, 164.8138, 146.8324, 110.0, 130.8128, 164.8138, 123.4708]
    step = int(t / 4) % len(notes)
    local = t % 4
    envelope = math.sin(math.pi * local / 4) ** 2
    root = notes[step]
    note = math.sin(TAU * root * t) * 0.12 + math.sin(TAU * root * 2 * t) * 0.028
    drone = math.sin(TAU * 55 * t) * 0.07 + math.sin(TAU * 82.5 * t) * 0.028
    return (note * envelope + drone) * math.sin(math.pi * t / 32) ** 2


if __name__ == '__main__':
    OUTPUT.mkdir(parents=True, exist_ok=True)
    render('engine', 4, engine, True)
    render('rain', 6, noise_function(35, 0.7, 0.63), True)
    render('cabin_rain', 6, noise_function(35, 0.026, 1.3), True)
    render('tires', 4, noise_function(48, 0.14, 0.60), True)
    render('wind', 4, noise_function(62, 0.04, 1.0), True)
    render('music', 32, score, True)
    render('indicator_on', 0.09, lambda t, i:
           math.sin(TAU * 1600 * t) * math.exp(-t * 120) * 0.45)
    render('indicator_off', 0.07, lambda t, i:
           math.sin(TAU * 1100 * t) * math.exp(-t * 140) * 0.38)
    swipe = noise_function(84, 0.15, 0.7)
    render('wiper', 0.44, lambda t, i:
           swipe(t, i) * math.sin(math.pi * t / 0.44) ** 0.7)
    motor = noise_function(19, 0.08, 0.3)
    render('window', 2.0, lambda t, i:
           math.sin(TAU * 155 * t) * 0.06 + motor(t, i))
    render('horn', 2.0, lambda t, i:
           math.sin(TAU * 330 * t) * 0.16 + math.sin(TAU * 415 * t) * 0.14, True)
    crash = noise_function(97, 0.17, 1.0)
    render('collision', 0.7, lambda t, i:
           (crash(t, i) + math.sin(TAU * 68 * t) * 0.3) * math.exp(-t * 9))
    print('Rendered 12 original prototype sounds at 22,050 Hz.')
