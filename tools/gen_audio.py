#!/usr/bin/env python3
"""Procedurally synthesise all sound effects and music loops of the game (pure Python, no deps).

Usage: python tools/gen_audio.py  -> assets/sfx/*.wav, assets/music/*.wav
Everything is generated from scratch, so there are no third-party licenses involved.
"""
import math
import os
import random
import struct
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX_DIR = os.path.join(ROOT, "assets", "sfx")
MUSIC_DIR = os.path.join(ROOT, "assets", "music")
SR = 22050
TAU = 2 * math.pi
rnd = random.Random(1337)


# ---------------------------------------------------------------- helpers

def note(n: str) -> float:
    """'A4' -> frequency. Supports sharps like 'C#5'."""
    names = {"C": -9, "C#": -8, "D": -7, "D#": -6, "E": -5, "F": -4, "F#": -3, "G": -2, "G#": -1, "A": 0, "A#": 1, "B": 2}
    pitch, octave = n[:-1], int(n[-1])
    return 440.0 * 2 ** ((names[pitch] + (octave - 4) * 12) / 12)


def buf(seconds: float):
    return [0.0] * int(seconds * SR)


def env_adsr(i, n, a=0.005, d=0.05, s=0.6, r=0.08):
    t = i / SR
    total = n / SR
    if t < a:
        return t / a
    if t < a + d:
        return 1 - (1 - s) * (t - a) / d
    if t > total - r:
        return s * max(total - t, 0) / r
    return s


def osc(kind, phase):
    p = phase % 1.0
    if kind == "sine":
        return math.sin(TAU * p)
    if kind == "square":
        return 1.0 if p < 0.5 else -1.0
    if kind == "saw":
        return 2 * p - 1
    if kind == "tri":
        return 4 * abs(p - 0.5) - 1
    if kind == "noise":
        return rnd.uniform(-1, 1)
    raise ValueError(kind)


def tone(out, start, dur, freq, kind="sine", vol=0.5, freq_end=None, a=0.005, d=0.05, s=0.6, r=0.08, vib=0.0):
    i0 = int(start * SR)
    n = int(dur * SR)
    phase = 0.0
    for i in range(n):
        if i0 + i >= len(out):
            break
        f = freq if freq_end is None else freq + (freq_end - freq) * (i / n)
        if vib:
            f *= 1 + vib * math.sin(TAU * 5.5 * i / SR)
        phase += f / SR
        out[i0 + i] += osc(kind, phase) * vol * env_adsr(i, n, a, d, s, r)


def pluck(out, start, dur, freq, vol=0.4, kind="tri", decay=6.0):
    i0 = int(start * SR)
    n = int(dur * SR)
    phase = 0.0
    for i in range(n):
        if i0 + i >= len(out):
            break
        phase += freq / SR
        e = math.exp(-decay * i / SR) * min(1.0, i / (0.003 * SR))
        out[i0 + i] += osc(kind, phase) * vol * e


def bell(out, start, freq, vol=0.4, dur=1.2):
    for mult, amp, dec in ((1, 1.0, 3.0), (2.76, 0.5, 5.0), (5.4, 0.25, 8.0), (8.9, 0.12, 12.0)):
        i0 = int(start * SR)
        n = int(dur * SR)
        for i in range(n):
            if i0 + i >= len(out):
                break
            out[i0 + i] += math.sin(TAU * freq * mult * i / SR) * vol * amp * math.exp(-dec * i / SR)


def noise_burst(out, start, dur, vol=0.3, lp=0.2, lp_end=None, decay=None):
    i0 = int(start * SR)
    n = int(dur * SR)
    y = 0.0
    for i in range(n):
        if i0 + i >= len(out):
            break
        k = lp if lp_end is None else lp + (lp_end - lp) * (i / n)
        y += k * (rnd.uniform(-1, 1) - y)
        e = math.exp(-decay * i / SR) if decay else env_adsr(i, n, 0.01, 0.05, 0.8, 0.1)
        out[i0 + i] += y * vol * e


def kick(out, start, vol=0.8):
    i0 = int(start * SR)
    n = int(0.25 * SR)
    phase = 0.0
    for i in range(n):
        if i0 + i >= len(out):
            break
        t = i / SR
        f = 45 + 110 * math.exp(-t * 30)
        phase += f / SR
        out[i0 + i] += math.sin(TAU * phase) * vol * math.exp(-t * 12)


def lowpass(samples, k):
    y = 0.0
    out = []
    for x in samples:
        y += k * (x - y)
        out.append(y)
    return out


def normalize(samples, peak=0.85):
    m = max(1e-9, max(abs(x) for x in samples))
    return [x * peak / m for x in samples]


def write(path, samples, peak=0.85):
    samples = normalize(samples, peak)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x)) * 32767)) for x in samples))


# ---------------------------------------------------------------- sound effects

def sfx():
    os.makedirs(SFX_DIR, exist_ok=True)
    s = {}

    b = buf(0.06); tone(b, 0, 0.05, 1350, "sine", 0.6, 1100, a=0.001, d=0.02, s=0.3, r=0.02); s["click"] = (b, 0.5)
    b = buf(0.04); tone(b, 0, 0.03, 900, "sine", 0.4, a=0.001, d=0.01, s=0.3, r=0.01); s["hover"] = (b, 0.25)
    b = buf(0.09); tone(b, 0, 0.08, 620, "tri", 0.6, 880, a=0.002, d=0.03, s=0.5, r=0.03); s["select"] = (b, 0.55)

    b = buf(0.5)
    for k, n in enumerate(["C6", "E6", "G6"]):
        pluck(b, k * 0.07, 0.4, note(n), 0.5, "square", 9)
        pluck(b, k * 0.07, 0.4, note(n) * 2, 0.15, "sine", 12)
    s["correct"] = (lowpass(b, 0.45), 0.7)

    b = buf(0.45)
    tone(b, 0, 0.4, 240, "saw", 0.5, 120, a=0.005, d=0.1, s=0.6, r=0.12)
    tone(b, 0, 0.4, 246, "square", 0.25, 124, a=0.005, d=0.1, s=0.6, r=0.12)
    s["wrong"] = (lowpass(b, 0.25), 0.7)

    b = buf(0.04); tone(b, 0, 0.03, 2100, "square", 0.3, a=0.001, d=0.01, s=0.2, r=0.01); s["tick"] = (lowpass(b, 0.5), 0.35)

    b = buf(0.7)
    for k, n in enumerate(["C5", "E5", "G5", "C6", "E6", "G6"]):
        pluck(b, k * 0.055, 0.35, note(n), 0.45, "square", 10)
    bell(b, 0.33, note("C7"), 0.25, 0.4)
    s["streak"] = (lowpass(b, 0.5), 0.75)

    b = buf(1.5)
    for k, (n, d) in enumerate([("C5", 0.14), ("E5", 0.14), ("G5", 0.14), ("C6", 0.9)]):
        st = k * 0.14
        tone(b, st, d + 0.2, note(n), "square", 0.35, a=0.005, d=0.05, s=0.7, r=0.2, vib=0.004 if d > 0.5 else 0)
        tone(b, st, d + 0.2, note(n) / 2, "tri", 0.3, a=0.005, d=0.05, s=0.7, r=0.2)
    s["levelup"] = (lowpass(b, 0.35), 0.8)

    b = buf(1.6)
    for k, n in enumerate(["G4", "D#4", "C4", "G3"]):
        tone(b, k * 0.22, 0.45 if k < 3 else 0.9, note(n), "saw", 0.35, a=0.01, d=0.1, s=0.6, r=0.25)
    s["gameover"] = (lowpass(b, 0.12), 0.75)

    b = buf(0.4); noise_burst(b, 0, 0.35, 0.6, 0.02, 0.35); s["whoosh"] = (b, 0.45)

    b = buf(1.6); bell(b, 0, note("E6"), 0.4, 1.2); bell(b, 0.12, note("B6"), 0.35, 1.4); s["achievement"] = (b, 0.7)

    b = buf(0.16); tone(b, 0, 0.12, 660, "square", 0.4, a=0.002, d=0.03, s=0.6, r=0.04); s["count"] = (lowpass(b, 0.35), 0.5)
    b = buf(0.35); tone(b, 0, 0.3, 1320, "square", 0.4, a=0.002, d=0.03, s=0.6, r=0.1); s["go"] = (lowpass(b, 0.35), 0.6)

    b = buf(0.4); kick(b, 0, 0.9); noise_burst(b, 0, 0.15, 0.35, 0.1, decay=25); s["heart_lost"] = (b, 0.8)

    b = buf(0.12); noise_burst(b, 0, 0.1, 0.5, 0.25, decay=40); tone(b, 0, 0.06, 300, "sine", 0.3, 200); s["flag"] = (b, 0.5)

    b = buf(1.2)
    for k, n in enumerate(["C5", "G5", "C6", "E6"]):
        bell(b, k * 0.09, note(n), 0.3, 1.0)
    s["exam_pass"] = (b, 0.75)

    for name, (samples, peak) in s.items():
        write(os.path.join(SFX_DIR, f"{name}.wav"), samples, peak)
    print(f"{len(s)} sound effects -> {SFX_DIR}")


# ---------------------------------------------------------------- music

def menu_loop():
    bpm = 84
    beat = 60 / bpm
    bars = 8
    out = buf(bars * 4 * beat)
    chords = [["A3", "C4", "E4"], ["F3", "A3", "C4"], ["C4", "E4", "G4"], ["G3", "B3", "D4"]] * 2
    for bar, chord in enumerate(chords):
        t0 = bar * 4 * beat
        for n in chord:  # soft detuned pad
            f = note(n)
            tone(out, t0, 4 * beat + 0.05, f, "tri", 0.10, a=0.6, d=0.3, s=0.8, r=0.5)
            tone(out, t0, 4 * beat + 0.05, f * 1.004, "sine", 0.08, a=0.6, d=0.3, s=0.8, r=0.5)
        tone(out, t0, 4 * beat, note(chord[0]) / 2, "sine", 0.18, a=0.05, d=0.3, s=0.7, r=0.3)
        arp = chord + [chord[1]]
        for k in range(8):  # gentle eighth-note arpeggio
            f = note(arp[k % 4]) * 2
            pluck(out, t0 + k * beat / 2, beat * 0.9, f, 0.09 if k % 2 == 0 else 0.06, "tri", 5)
        for k in range(4):
            noise_burst(out, t0 + k * beat + beat / 2, 0.05, 0.03, 0.6, decay=60)
    out = lowpass(out, 0.3)
    write(os.path.join(MUSIC_DIR, "menu_loop.wav"), out, 0.6)


def arcade_loop():
    bpm = 124
    beat = 60 / bpm
    bars = 8
    out = buf(bars * 4 * beat)
    roots = ["A2", "A2", "F2", "G2", "A2", "A2", "C3", "E2"]
    arps = [["A4", "C5", "E5", "A5"], ["A4", "C5", "E5", "G5"], ["F4", "A4", "C5", "F5"], ["G4", "B4", "D5", "G5"],
            ["A4", "C5", "E5", "A5"], ["A4", "E5", "C5", "E5"], ["C5", "E5", "G5", "C6"], ["E4", "G#4", "B4", "E5"]]
    for bar in range(bars):
        t0 = bar * 4 * beat
        for k in range(4):
            kick(out, t0 + k * beat, 0.55)
            noise_burst(out, t0 + k * beat + beat / 2, 0.04, 0.07, 0.7, decay=70)
        for k in range(8):  # driving bass
            pluck(out, t0 + k * beat / 2, beat / 2, note(roots[bar]), 0.28, "saw", 9)
        for k in range(16):  # sixteenth arpeggio
            f = note(arps[bar][k % 4])
            pluck(out, t0 + k * beat / 4, beat / 4, f, 0.08, "square", 14)
    out = lowpass(out, 0.35)
    write(os.path.join(MUSIC_DIR, "arcade_loop.wav"), out, 0.6)


if __name__ == "__main__":
    sfx()
    os.makedirs(MUSIC_DIR, exist_ok=True)
    menu_loop()
    arcade_loop()
    print(f"music loops -> {MUSIC_DIR}")
