"""Deterministic synthesized Slash cast: charge, air cut, metallic tail. No samples."""
from pathlib import Path
import wave
import numpy as np
RATE=44100
rng=np.random.default_rng(220926)
t=np.arange(int(RATE*0.82))/RATE
x=np.zeros_like(t)
def burst(start,duration,gain,low,high):
    global x
    u=t-start
    active=(u>=0)&(u<duration)
    q=np.clip(u/duration,0,1)
    noise=rng.normal(0,1,len(t))
    smooth=np.convolve(noise,np.ones(13)/13,mode="same")
    air=noise-smooth
    env=np.sin(np.pi*q)**2*active
    phase=2*np.pi*(low*u+(high-low)*u*u/(2*duration))
    x+=gain*env*(0.8*air+0.2*np.sin(phase))
burst(0,0.18,0.10,280,1200)
burst(0.14,0.25,0.52,1800,180)
burst(0.30,0.22,0.30,1300,220)
burst(0.45,0.20,0.18,1000,160)
u=np.maximum(t-0.18,0)
for f,g in [(710,.065),(1133,.040),(1829,.020)]:
    x+=g*np.sin(2*np.pi*f*u)*np.exp(-u*12)*(t>=.18)*(1-np.exp(-u*180))
x=np.tanh(x*1.3)
x*=np.minimum(t/.006,1)*np.minimum((t[-1]-t)/.025,1)
x*=0.68/max(abs(x))
path=Path("Sprites/sfx/skill_slash_forged.wav")
with wave.open(str(path),"wb") as w:
    w.setnchannels(1);w.setsampwidth(2);w.setframerate(RATE)
    w.writeframes((x*32767).astype("<i2").tobytes())
print(f"{path}: {len(x)/RATE:.2f}s, peak {max(abs(x)):.3f}, RMS {np.sqrt(np.mean(x*x)):.3f}, {path.stat().st_size} bytes")
