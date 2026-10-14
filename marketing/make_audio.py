"""Synthetisiert Musik + Soundeffekte (15 s) fuer den JP-Turtle-Teaser -> WAV."""
import sys, wave
import numpy as np

sr, T = 44100, 15.0
N = int(sr * T)
mix = np.zeros(N)
rng = np.random.default_rng(7)

def add(x, t0, g=1.0):
    i = int(t0 * sr)
    if i >= N: return
    x = x[: N - i]
    mix[i:i + len(x)] += x * g

def tt(d): return np.arange(int(d * sr)) / sr

def pluck(f, d=1.4, g=1.0):  # Koto-artig: Obertoene mit schnellem Abklingen
    t = tt(d); s = np.zeros_like(t)
    for h, a in [(1, 1), (2, .5), (3, .3), (4, .18), (5, .1)]:
        s += a * np.sin(2*np.pi*f*h*t) * np.exp(-t * (2.2 + h * 1.8))
    s += 0.25 * rng.standard_normal(len(t)) * np.exp(-t * 90)
    return s * g

def bell(f, d=1.2):
    t = tt(d)
    return sum(a * np.sin(2*np.pi*f*r*t) * np.exp(-t*dk) for r, a, dk in [(1, 1, 3), (2.76, .5, 5), (5.4, .25, 8)])

def tick(f=1500, d=.06):
    t = tt(d); return np.sin(2*np.pi*f*t) * np.exp(-t * 70)

def block(f=900, d=.08):  # Holzblock
    t = tt(d); return (np.sin(2*np.pi*f*t) + .5*np.sin(2*np.pi*f*2.4*t)) * np.exp(-t * 55)

def sweep(f0, f1, d, dk):
    t = tt(d); ph = 2*np.pi*(f0*t + (f1-f0)*t**2/(2*d))
    return np.sin(ph) * np.exp(-t * dk)

def brush(d):  # Pinselstrich: gefiltertes Rauschen
    n = rng.standard_normal(int(d*sr))
    k = np.ones(12)/12; n = n - np.convolve(n, k, 'same')
    env = np.sin(np.linspace(0, np.pi, len(n))) ** 1.5
    return n * env * 0.35

def boom(d=.9):
    t = tt(d); return sweep(130, 42, d, 4.5) + .4*rng.standard_normal(len(t))*np.exp(-t*30)*.3

# Hintergrundmelodie (Yo-Tonleiter D E G A B)
D4, E4, G4, A4, B4, D5 = 293.66, 329.63, 392.0, 440.0, 493.88, 587.33
melody = [(0.0, D4), (0.5, G4), (1.0, A4), (1.5, B4), (2.0, A4), (2.5, G4), (3.0, E4), (3.5, D4),
          (4.0, G4), (4.5, A4), (5.0, B4), (5.5, D5), (6.0, B4), (6.5, A4), (7.0, G4), (7.5, A4),
          (8.0, B4), (8.5, A4), (9.0, G4), (9.5, E4), (10.0, G4), (10.5, A4), (11.0, B4), (11.5, D5),
          (12.0, D5), (12.5, B4), (13.0, A4), (13.5, G4), (14.0, D4)]
for t0, f in melody: add(pluck(f, 1.6), t0, 0.16)

# Effekte, passend zur Animation
for w in (0.35, 0.85, 1.3, 1.6, 1.8): add(block(800 + 80*(w > 1)), w + .02, .5)   # Ei wackelt
add(tick(2200), 1.25, .5); add(tick(2600), 1.7, .5)                                # Risse
add(sweep(400, 1400, .25, 6), 2.0, .5); add(bell(1320), 2.05, .3)                  # Schluepfen
add(bell(1047, 1.0), 2.4, .35)                                                     # Sprechblase
add(brush(1.3), 5.5, .8)                                                           # Pinselstrich
add(bell(1568, 1.2), 6.8, .45)                                                     # Bewertung
for i, f in enumerate((1200, 1400, 1700)): add(tick(f), 8.0 + i*.12, .35)          # Karten
for i, f in enumerate((1318, 1568, 1976)): add(bell(f, .8), 8.55 + i*.45, .3)      # Haekchen
add(bell(2093, 1.2), 9.5, .3)
add(sweep(300, 900, .3, 6), 10.0, .3)                                              # Widget erscheint
add(block(1200), 10.9, .5)                                                         # Aufdecken
add(pluck(A4*2, 1.0), 11.55, .35); add(bell(1760), 11.55, .3)                      # Gewusst
add(boom(), 12.0, .9)                                                              # Kame waechst
for i, f in enumerate((784, 988, 1175, 1568, 1976, 2349)): add(bell(f, .9), 12.1 + i*.09, .22)
for f in (D4, A4, D5): add(pluck(f, 2.0), 13.55, .22)                              # Ausklang
add(bell(1175, 1.4), 13.6, .25)

# Hall + Normalisierung
ir = rng.standard_normal(int(.45*sr)) * np.exp(-tt(.45) * 9)
wet = np.fft.irfft(np.fft.rfft(mix, N + len(ir)) * np.fft.rfft(ir, N + len(ir)))[:N]
mix = mix + 0.12 * wet / (np.abs(wet).max() + 1e-9) * np.abs(mix).max()
mix[-int(.5*sr):] *= np.linspace(1, 0, int(.5*sr))
mix = mix / np.abs(mix).max() * 0.8
pcm = (mix * 32767).astype('<i2')
with wave.open(sys.argv[1], 'wb') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes(pcm.tobytes())
