"""Synthesize the salon BGM loop and short UI / tool effects."""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"


def _clamp(value: float) -> int:
    return max(-32767, min(32767, int(value * 32767)))


def write_wav(name: str, samples: list[float]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    with wave.open(str(path), "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(b"".join(struct.pack("<h", _clamp(s)) for s in samples))
    print(f"{name}: {len(samples) / RATE:.2f}s")


def tone(
    freq: float,
    seconds: float,
    *,
    volume: float = 0.2,
    decay: float = 0.0,
    attack: float = 0.01,
) -> list[float]:
    n = int(seconds * RATE)
    out: list[float] = []
    for i in range(n):
        t = i / RATE
        env = 1.0
        if attack > 0:
            env *= min(1.0, t / attack)
        if decay > 0:
            env *= math.exp(-t * decay)
        else:
            tail = n - i
            if tail < RATE * 0.02:
                env *= tail / (RATE * 0.02)
        # Soft triangle + sine so it reads as a toy keyboard, not a beep.
        sine = math.sin(2 * math.pi * freq * t)
        tri = 2 * abs(2 * ((t * freq) % 1) - 1) - 1
        out.append(volume * env * (0.72 * sine + 0.28 * tri))
    return out


def noise(seconds: float, volume: float = 0.12, decay: float = 8) -> list[float]:
    n = int(seconds * RATE)
    seed = 1
    out: list[float] = []
    for i in range(n):
        seed = (1103515245 * seed + 12345) & 0x7FFFFFFF
        t = i / RATE
        env = 1.0 if decay <= 0 else math.exp(-t * decay)
        out.append(volume * env * ((seed / 0x7FFFFFFF) * 2 - 1))
    return out


def loop_bed(
    seconds: float,
    *,
    noise_vol: float,
    hum_freq: float,
    hum_vol: float,
    sparkle_freq: float = 0.0,
    sparkle_vol: float = 0.0,
) -> list[float]:
    """Continuous texture so tool loops do not tick every fraction of a second."""
    n = int(seconds * RATE)
    seed = 2463534242
    out: list[float] = []
    for i in range(n):
        seed = (1664525 * seed + 1013904223) & 0xFFFFFFFF
        t = i / RATE
        hiss = ((seed / 0xFFFFFFFF) * 2 - 1) * noise_vol
        hum = math.sin(2 * math.pi * hum_freq * t) * hum_vol
        sparkle = 0.0
        if sparkle_freq > 0:
            sparkle = math.sin(2 * math.pi * sparkle_freq * t) * sparkle_vol
        out.append(hiss + hum + sparkle)
    return out


def mix(*tracks: list[float]) -> list[float]:
    length = max((len(t) for t in tracks), default=0)
    out = [0.0] * length
    for track in tracks:
        for i, sample in enumerate(track):
            out[i] += sample
    peak = max((abs(s) for s in out), default=1.0)
    if peak > 0.95:
        scale = 0.95 / peak
        out = [s * scale for s in out]
    return out


def pad(samples: list[float], seconds: float) -> list[float]:
    return samples + [0.0] * int(seconds * RATE)


def at(start: float, clip: list[float], total: float) -> list[float]:
    out = [0.0] * int(total * RATE)
    offset = int(start * RATE)
    for i, sample in enumerate(clip):
        index = offset + i
        if index < len(out):
            out[index] += sample
    return out


def make_bgm() -> None:
    # 8 bars, 100 BPM, C major pentatonic. Soft enough to loop under play.
    beat = 0.6
    bar = beat * 4
    length = bar * 8
    melody = [
        (0.0, 523.25, 0.45),
        (0.6, 587.33, 0.3),
        (1.2, 659.25, 0.55),
        (2.4, 783.99, 0.4),
        (3.0, 659.25, 0.3),
        (3.6, 587.33, 0.45),
        (4.8, 523.25, 0.4),
        (5.4, 659.25, 0.35),
        (6.0, 783.99, 0.7),
        (7.2, 880.00, 0.35),
        (7.8, 783.99, 0.9),
        (9.6, 659.25, 0.45),
        (10.2, 587.33, 0.3),
        (10.8, 523.25, 0.9),
        (12.0, 392.00, 0.4),
        (12.6, 523.25, 0.4),
        (13.2, 659.25, 0.8),
        (14.4, 587.33, 0.5),
        (15.6, 523.25, 1.1),
    ]
    bass = [
        (0.0, 130.81),
        (2.4, 146.83),
        (4.8, 164.81),
        (7.2, 174.61),
        (9.6, 130.81),
        (12.0, 196.00),
        (14.4, 130.81),
    ]
    parts = [
        at(start, tone(freq, dur, volume=0.11, decay=2.4, attack=0.02), length)
        for start, freq, dur in melody
    ]
    parts += [
        at(start, tone(freq, 1.8, volume=0.07, decay=1.3, attack=0.03), length)
        for start, freq in bass
    ]
    # Soft off-beat sparkle.
    for i in range(16):
        parts.append(
            at(
                i * beat + 0.3,
                tone(1046.5, 0.12, volume=0.035, decay=18, attack=0.005),
                length,
            )
        )
    write_wav("bgm_salon.wav", mix(*parts))


def main() -> None:
    make_bgm()
    write_wav(
        "sfx_tap.wav",
        mix(tone(880, 0.07, volume=0.16, decay=28), tone(1320, 0.05, volume=0.08, decay=32)),
    )
    write_wav(
        "sfx_coin.wav",
        mix(
            tone(784, 0.08, volume=0.16, decay=18),
            pad([], 0.06) + tone(1175, 0.16, volume=0.18, decay=10),
        ),
    )
    write_wav(
        "sfx_success.wav",
        mix(
            tone(523.25, 0.12, volume=0.14, decay=8),
            pad([], 0.08) + tone(659.25, 0.12, volume=0.14, decay=8),
            pad([], 0.16) + tone(783.99, 0.22, volume=0.16, decay=6),
        ),
    )
    write_wav(
        "sfx_locked.wav",
        mix(tone(196, 0.12, volume=0.14, decay=14), tone(147, 0.16, volume=0.1, decay=10)),
    )
    write_wav(
        "sfx_arrive.wav",
        mix(
            tone(392, 0.14, volume=0.12, decay=8),
            pad([], 0.1) + tone(523.25, 0.14, volume=0.12, decay=8),
            pad([], 0.2) + tone(659.25, 0.22, volume=0.13, decay=6),
        ),
    )
    write_wav(
        "sfx_soap.wav",
        loop_bed(
            1.6,
            noise_vol=0.05,
            hum_freq=620,
            hum_vol=0.045,
            sparkle_freq=880,
            sparkle_vol=0.02,
        ),
    )
    write_wav(
        "sfx_spray.wav",
        loop_bed(
            1.4,
            noise_vol=0.12,
            hum_freq=2100,
            hum_vol=0.03,
            sparkle_freq=3200,
            sparkle_vol=0.015,
        ),
    )
    write_wav(
        "sfx_buffer.wav",
        loop_bed(
            1.5,
            noise_vol=0.08,
            hum_freq=180,
            hum_vol=0.055,
            sparkle_freq=90,
            sparkle_vol=0.02,
        ),
    )
    write_wav(
        "sfx_clip.wav",
        mix(
            tone(1480, 0.04, volume=0.2, decay=40),
            tone(990, 0.05, volume=0.1, decay=30),
            noise(0.05, volume=0.08, decay=40),
        ),
    )


if __name__ == "__main__":
    main()
