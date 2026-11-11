"""Gera a assinatura sonora do Vigi (Guia de Design, secao 11).

Duas notas, lembrando o piado de uma coruja: uma nota media seguida de outra
um pouco mais grave, suave, em timbre de madeira. Nao pode parecer sirene.
"""
import sys, wave
import numpy as np

SR = 22050

def wood(freq, dur, decay=0.22, level=1.0):
    """Nota com timbre de madeira (tipo marimba): ataque curto, queda rapida."""
    t = np.arange(int(SR * dur)) / SR
    env = np.exp(-t / decay)
    attack = np.minimum(1.0, t / 0.008)
    tone = (np.sin(2 * np.pi * freq * t)
            + 0.32 * np.sin(2 * np.pi * freq * 4.0 * t) * np.exp(-t / (decay * 0.35))
            + 0.10 * np.sin(2 * np.pi * freq * 9.2 * t) * np.exp(-t / (decay * 0.15))
            + 0.20 * np.sin(2 * np.pi * freq * 2.0 * t) * np.exp(-t / (decay * 0.7)))
    release = np.minimum(1.0, (dur - t) / 0.02)
    return level * tone * env * attack * release

def silence(dur):
    return np.zeros(int(SR * dur))

def call(gap=0.14, d1=0.42, d2=0.62):
    # La4 seguido de Fa4: nota media e outra um pouco mais grave.
    return np.concatenate([wood(440.0, d1), silence(gap), wood(349.23, d2, decay=0.3)])

def save(path, samples, peak=0.85):
    samples = samples / max(1e-9, np.max(np.abs(samples))) * peak
    data = (samples * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(path, f'{len(samples)/SR:.2f}s', f'{len(data)*2/1024:.0f} KB')

out_assets, out_raw = sys.argv[1], sys.argv[2]

# Sua vez: a chamada, uma vez.
chamada = np.concatenate([call(), silence(0.15)])
save(f'{out_assets}/chamada.wav', chamada, peak=0.8)
save(f'{out_raw}/vigi_chamada.wav', chamada, peak=0.8)

# Ultima chamada: o mesmo desenho, repetido, mais rapido e com volume
# crescente (a rampa fica gravada no arquivo, que toca em laco).
pairs = []
n = 13
for i in range(n):
    gain = 0.3 + 0.7 * min(1.0, i / (n - 4))
    pairs.append(gain * np.concatenate([call(gap=0.08, d1=0.28, d2=0.36), silence(0.2)]))
ultima = np.concatenate(pairs)
peak = np.max(np.abs(ultima))
for name in (f'{out_assets}/ultima_chamada.wav', f'{out_raw}/vigi_ultima_chamada.wav'):
    data = (ultima / peak * 0.95 * 32767).astype('<i2')
    with wave.open(name, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(name, f'{len(ultima)/SR:.2f}s', f'{len(data)*2/1024:.0f} KB')

# Alerta confirmado: uma vez, mais grave e firme.
alerta = np.concatenate([wood(196.0, 1.1, decay=0.55), silence(0.1)])
save(f'{out_assets}/alerta.wav', alerta, peak=0.9)
