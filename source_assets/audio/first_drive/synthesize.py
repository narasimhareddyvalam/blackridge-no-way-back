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


def body_impact():
    thump = noise_function(131, 0.05, 1.0)
    crunch = noise_function(137, 0.55, 1.0)
    debris = random.Random(139)
    ticks = [(debris.uniform(0.01, 0.15), debris.uniform(2500, 6500)) for _ in range(9)]
    phase = 0.0

    def sample(t, i):
        nonlocal phase
        phase += TAU * (90 - 40 * min(t / 0.2, 1.0)) / RATE
        body = (math.sin(phase) * 0.9 + thump(t, i) * 0.8) * math.exp(-t * 10)
        hit = crunch(t, i) * math.exp(-t * 55) * 0.45
        tick = sum(math.sin(TAU * pitch * (t - start)) * math.exp(-(t - start) * 700)
                   for start, pitch in ticks if t >= start) * 0.22
        landing = t - 0.42
        fall = 0.0
        if landing >= 0:
            fall = (math.sin(TAU * 62 * landing) * 0.5 + thump(t, i) * 0.4) \
                * math.exp(-landing * 14) * 0.5
        return body + hit + tick + fall

    return sample


def skid():
    hiss = noise_function(151, 0.42, 0.7)
    scrub = noise_function(157, 0.05, 0.6)
    phase = 0.0

    def sample(t, i):
        nonlocal phase
        phase += TAU * (960 + 70 * math.sin(TAU * 1.5 * t) + 25 * math.sin(TAU * 7 * t)) / RATE
        squeal = math.sin(phase) * 0.12 * (0.7 + 0.3 * math.sin(TAU * 2.5 * t))
        return hiss(t, i) * 0.55 + scrub(t, i) * 0.35 + squeal

    return sample


def tone(t, start, length, pitch):
    local = t - start
    if local < 0 or local >= length:
        return 0.0
    edge = min(1.0, local / 0.005, (length - local) / 0.005)
    return math.sin(TAU * pitch * local) * edge


def phone_ring():
    notes = ((0.0, 784.0), (0.16, 988.0), (0.32, 784.0), (0.48, 988.0))

    def sample(t, i):
        value = 0.0
        for start, pitch in notes:
            local = t - start
            if 0.0 <= local < 0.6:
                value += (math.sin(TAU * pitch * local) * 0.7
                          + math.sin(TAU * pitch * 2.01 * local) * 0.15) * math.exp(-local * 9)
        return value * 0.32

    return sample


def breathing():
    air = noise_function(151, 0.32, 1.0)
    body = noise_function(157, 0.06, 1.0)
    rng = random.Random(163)
    breaths = []
    start = 0.25
    for _ in range(3):
        inhale = rng.uniform(1.0, 1.25)
        exhale = rng.uniform(1.3, 1.7)
        breaths.append((start, inhale, exhale))
        start += inhale + exhale + rng.uniform(0.45, 0.8)

    def sample(t, i):
        breath = air(t, i) - body(t, i) * 0.6
        for begin, inhale, exhale in breaths:
            local = t - begin
            if 0.0 <= local < inhale:
                return breath * 0.42 * math.sin(math.pi * local / inhale) ** 1.5
            local -= inhale
            if 0.0 <= local < exhale:
                shake = 1.0 + 0.22 * math.sin(TAU * 7.5 * local)
                level = math.sin(math.pi * (local / exhale) ** 0.7) ** 1.2
                return (breath * 0.7 + body(t, i) * 0.35) * 0.62 * level * shake
        return 0.0

    return sample, start


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
    render('impact_body', 1.4, body_impact())
    render('phone_ring', 2.2, phone_ring(), True)
    render('call_connect', 0.12, lambda t, i:
           math.sin(TAU * 1320 * t) * math.exp(-t * 40) * 0.35)
    render('call_end', 0.36, lambda t, i:
           (tone(t, 0.0, 0.12, 620) + tone(t, 0.2, 0.12, 470)) * 0.3)
    breath, breath_length = breathing()
    render('breathing', breath_length, breath, True)
    render('engine_tick', 0.06, lambda t, i:
           (math.sin(TAU * 3100 * t) * 0.5 + math.sin(TAU * 4700 * t) * 0.3)
           * math.exp(-t * 90) * 0.5)
    render('skid', 2.0, skid(), True)
    print('Rendered 19 original prototype sounds at 22,050 Hz.')
