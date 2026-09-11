"""Deterministic original hammer/rock/lava sound design; numpy + standard library."""
from pathlib import Path
import json
import wave
import numpy as np

SR = 44100
ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'Sprites/sfx'
REVIEW = ROOT / 'output/forge_guardian_audio'

def lowpass(noise, width):
    return np.convolve(noise, np.ones(width) / width, mode='same')

def impact(skill=False):
    rng = np.random.default_rng(971 if skill else 970)
    duration = 0.72 if skill else 1.05
    t = np.arange(round(SR * duration)) / SR
    n = rng.normal(0, 1, len(t))
    # Heavy descending body, with midrange weight audible on laptop speakers.
    phase = 2 * np.pi * (48 * t + 55 * .028 * (1 - np.exp(-t / .028)))
    body = .70 * np.sin(phase) * np.exp(-t * 12)
    body += .25 * np.sin(2 * np.pi * 123 * t) * np.exp(-t * 20)
    # Short irregular metal modes avoid a musical bell tone.
    metal = sum(a * np.sin(2*np.pi*f*t) * np.exp(-t*d)
                for f,a,d in [(327,.16,28),(731,.11,35),(1183,.06,44),(2107,.035,55)])
    crack = .33 * (n - lowpass(n, 15)) * np.exp(-t * 95)
    lava = lowpass(n, 100)
    lava = lava / (np.std(lava) + 1e-9)
    lava *= .11 * (1-np.exp(-t*65)) * np.exp(-t*(7 if skill else 4.8))
    grit = np.zeros_like(t)
    for delay in [.035,.068,.11,.17,.24]:
        u = np.maximum(t-delay,0)
        grit += .07 * n * (t>=delay) * np.exp(-u*100) * np.exp(-delay*5)
    dry = body + metal + crack + lava + grit
    # Low, short early reflections; skill tail fits repeated 0.3-second impacts.
    wet = dry.copy()
    for delay, gain in [(.029,.13),(.061,.07),(.097,.035)]:
        shift = round(delay*SR)
        wet[shift:] += dry[:-shift]*gain
    wet *= np.minimum(t/.001,1) * np.minimum((duration-t)/.07,1)
    wet = np.tanh(wet*1.15)
    return wet * (.70 if skill else .79) / np.max(np.abs(wet))

def save(path, samples):
    with wave.open(str(path),'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(np.round(np.clip(samples,-1,1)*32767).astype('<i2').tobytes())

def main():
    OUT.mkdir(exist_ok=True); REVIEW.mkdir(parents=True,exist_ok=True)
    (REVIEW/'.gdignore').touch()
    normal, skill = impact(), impact(True)
    report=[]
    for key, samples in [('forge_guardian_slam',normal),('forge_guardian_lava_slam',skill)]:
        path=OUT/(key+'.wav'); save(path,samples)
        assert np.isfinite(samples).all() and np.max(np.abs(samples))<1
        report.append(dict(file=str(path),seconds=len(samples)/SR,bytes=path.stat().st_size,peak_db=float(20*np.log10(np.max(np.abs(samples))))))
    # Audition: normal, pause, then actual five-hit skill rhythm.
    preview=np.zeros(SR*5)
    preview[:len(normal)]+=normal*.85
    for i in range(5):
        start=round((2+i*.3)*SR)
        preview[start:start+len(skill)]+=skill*.70
    assert np.max(np.abs(preview))<1
    save(REVIEW/'forge_guardian_preview.wav',preview)
    (REVIEW/'audio_report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report,indent=2))

if __name__=='__main__':main()
