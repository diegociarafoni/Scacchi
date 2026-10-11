"""Genera i suoni dell'app in assets/sounds (WAV mono 22050 Hz, opera originale, CC0)."""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def tone(freq, ms, volume=0.5, decay=8.0, start=0.0):
    n = int(RATE * ms / 1000)
    return [
        volume * math.exp(-decay * i / n) * math.sin(2 * math.pi * (freq + start * i / n) * i / RATE)
        for i in range(n)
    ]


def click(ms, volume, decay, lowpass, seed):
    rng = random.Random(seed)
    n = int(RATE * ms / 1000)
    out, prev = [], 0.0
    for i in range(n):
        prev += lowpass * (rng.uniform(-1, 1) - prev)
        out.append(volume * math.exp(-decay * i / n) * prev)
    return out


def silence(ms):
    return [0.0] * int(RATE * ms / 1000)


def mix(*tracks):
    length = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(length)]


def write(name, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = min(1.0, 0.9 / peak)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * scale * 32767)) for s in samples))


SOUNDS = {
    "move": mix(click(60, 0.8, 9, 0.35, 1), tone(180, 60, 0.4, 12)),
    "capture": mix(click(110, 1.0, 6, 0.25, 2), tone(110, 110, 0.6, 7)),
    "castle": click(50, 0.8, 9, 0.35, 3) + silence(40) + click(50, 0.8, 9, 0.35, 4),
    "check": tone(880, 90, 0.4, 3) + tone(660, 140, 0.4, 4),
    "promote": tone(523, 70, 0.35, 2) + tone(659, 70, 0.35, 2) + tone(784, 160, 0.4, 4),
    "game_end": mix(tone(392, 600, 0.3, 3), tone(494, 600, 0.25, 3), tone(587, 600, 0.25, 3)),
    "low_time": tone(1200, 40, 0.3, 6),
}

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name, samples in SOUNDS.items():
        write(name, samples)
