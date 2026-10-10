"""Original, deterministic synthesized music and nature loops (no external samples)."""
from pathlib import Path
import math, wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RATE = 22050

def save(name, data):
    peak = float(np.max(np.abs(data)))
    assert peak < 1, (name, peak)
    pcm = np.round(data * 32767).astype('<i2')
    with wave.open(str(ROOT / 'assets' / (name + '.wav')), 'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(RATE); f.writeframes(pcm.tobytes())

def add_wrapped(dst, start, sound):
    ids = (start + np.arange(len(sound))) % len(dst)
    np.add.at(dst, ids, sound)

# Eight 3-beat bars, rounded to an exact loop. A warm plucked pentatonic melody.
beat = 0.72
length = 24 * beat
music = np.zeros(round(length * RATE))
melody = [72, 76, 79, 81, 79, 76, 74, 76, 79, 84, 81, 79,
          76, 79, 81, 79, 76, 74, 72, 74, 76, 79, 76, 74]
chords = [(48, 55, 60), (45, 52, 57), (53, 60, 65), (55, 62, 67)]
for i, note in enumerate(melody):
    t = np.arange(round(1.4 * RATE)) / RATE
    hz = 440 * 2 ** ((note - 69) / 12)
    env = (1 - np.exp(-t * 45)) * np.exp(-t * 4.0)
    tone = (np.sin(2 * math.pi * hz * t) + 0.22 * np.sin(2 * math.pi * hz * 2 * t)) * env * 0.13
    add_wrapped(music, round(i * beat * RATE), tone)
for bar in range(8):
    t = np.arange(round(3.6 * RATE)) / RATE
    env = (1 - np.exp(-t * 2.5)) * np.exp(-t * 1.5)
    for note in chords[(bar // 2) % 4]:
        hz = 440 * 2 ** ((note - 69) / 12)
        add_wrapped(music, round(bar * 3 * beat * RATE), np.sin(2 * math.pi * hz * t) * env * 0.065)
save('campus_music', music)

# Periodic low wind and sparse soft bird chirps; no clicks at the loop boundary.
t = np.arange(12 * RATE) / RATE
rng = np.random.default_rng(2026)
wind = rng.normal(size=len(t))
wind = np.convolve(wind, np.ones(160) / 160, mode='same')
wind *= 0.24 * (0.55 + 0.45 * np.sin(2 * math.pi * t / 12) ** 2)
fade = np.minimum(np.minimum(t / 0.15, (12-t) / 0.15), 1).clip(0, 1)
ambience = wind * fade
for start, base in [(1.2, 1450), (4.1, 1800), (7.4, 1300), (10.1, 1650)]:
    tt = np.arange(round(0.38 * RATE)) / RATE
    chirp = np.sin(2 * math.pi * (base * tt + 220 * tt ** 2)) * np.sin(math.pi * tt / 0.38) ** 2 * 0.09
    add_wrapped(ambience, round(start * RATE), chirp)
save('garden_ambience', ambience)
print('Saved original seamless music and garden ambience.')
