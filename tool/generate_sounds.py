"""Genera i suoni dell'app in assets/sounds (WAV mono 22050 Hz, opera originale, CC0).

Il set classico sta in assets/sounds, gli altri in assets/sounds/<set>/.
"""

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


def write(name, samples, out=OUT):
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = min(1.0, 0.9 / peak)
    with wave.open(str(out / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * scale * 32767)) for s in samples))


CLASSICO = {
    "move": mix(click(60, 0.8, 9, 0.35, 1), tone(180, 60, 0.4, 12)),
    "capture": mix(click(110, 1.0, 6, 0.25, 2), tone(110, 110, 0.6, 7)),
    "castle": click(50, 0.8, 9, 0.35, 3) + silence(40) + click(50, 0.8, 9, 0.35, 4),
    "check": tone(880, 90, 0.4, 3) + tone(660, 140, 0.4, 4),
    "promote": tone(523, 70, 0.35, 2) + tone(659, 70, 0.35, 2) + tone(784, 160, 0.4, 4),
    "game_end": mix(tone(392, 600, 0.3, 3), tone(494, 600, 0.25, 3), tone(587, 600, 0.25, 3)),
    "low_time": tone(1200, 40, 0.3, 6),
}


def tock(ms, freq, seed, volume=0.9):
    """Colpo di legno: un impatto secco e una nota bassa che si spegne subito."""
    return mix(click(ms, volume, 11, 0.5, seed), tone(freq, ms, 0.55, 14), tone(freq * 2.4, ms, 0.2, 20))


def chime(freq, ms, volume=0.35, decay=5.0):
    """Nota di vetro: un suono puro con due armonici non interi."""
    return mix(
        tone(freq, ms, volume, decay),
        tone(freq * 2.76, ms, volume * 0.35, decay * 1.8),
        tone(freq * 5.4, ms, volume * 0.12, decay * 2.6),
    )


LEGNO = {
    "move": tock(70, 240, 11),
    "capture": mix(tock(120, 170, 12, 1.0), tock(120, 320, 13)),
    "castle": tock(70, 240, 14) + silence(50) + tock(70, 200, 15),
    "check": tock(80, 420, 16) + silence(30) + tock(110, 520, 17),
    "promote": tock(60, 330, 18) + tock(60, 440, 19) + tock(140, 590, 20),
    "game_end": tock(100, 160, 21) + silence(60) + tock(100, 160, 22) + silence(60) + tock(260, 120, 23),
    "low_time": tock(45, 700, 24, 0.7),
}

CRISTALLO = {
    "move": chime(1568, 90, 0.4, 7),
    "capture": mix(chime(1175, 150, 0.45, 6), click(30, 0.5, 14, 0.7, 31)),
    "castle": chime(1319, 70, 0.4, 7) + silence(30) + chime(1568, 90, 0.4, 7),
    "check": chime(1760, 100, 0.4, 4) + chime(1319, 180, 0.4, 4),
    "promote": chime(1047, 80, 0.35, 3) + chime(1319, 80, 0.35, 3) + chime(1568, 200, 0.4, 3.5),
    "game_end": mix(chime(784, 420, 0.3, 2.6), chime(988, 420, 0.25, 2.6), chime(1175, 420, 0.25, 2.6)),
    "low_time": chime(2093, 45, 0.3, 8),
}

SETS = {"": CLASSICO, "legno": LEGNO, "cristallo": CRISTALLO}

if __name__ == "__main__":
    for folder, sounds in SETS.items():
        out = OUT / folder if folder else OUT
        out.mkdir(parents=True, exist_ok=True)
        for name, samples in sounds.items():
            write(name, samples, out)
