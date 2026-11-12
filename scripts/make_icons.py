#!/usr/bin/env python3
"""Gera os ícones do Vigi a partir de uma única geometria da coruja.

Saídas:
  - Android: ícone adaptativo (fundo, frente, monocromático), PNGs legados,
    ícone de notificação, corujas do widget e da tela de abertura.
  - Web/PWA: ícones 192, 512, mascaráveis e favicon.
  - iOS, macOS e Windows: conjuntos de ícones do app.

Construção do símbolo (Guia de Design, seção 3): os dois olhos têm o mesmo
diâmetro, a distância entre os centros é 2,3 vezes o raio e a espessura do
anel é 22% do raio. O sobrolho em V parte da altura do topo dos olhos e
encontra o centro entre eles. O bico é um losango.

Uso: python3 scripts/make_icons.py   (requer Pillow)
"""
from __future__ import annotations

import math
import os
import sys
from dataclasses import dataclass

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')

# Tokens de cor (lib/core/theme/app_colors.dart).
PETROLEO_900 = '#0F2221'
PETROLEO_800 = '#1F3D3B'
PETROLEO_300 = '#9DBAB7'
AMBAR_500 = '#E8A33D'
SINAL_500 = '#E24B4A'
LINHO_100 = '#F2EFE8'
LINHO_400 = '#B9B4A8'
BRANCO = '#FFFFFF'


@dataclass
class Owl:
    """Cores e forma dos olhos de uma coruja."""

    ring: str
    pupil: str | None
    brow: str | None
    beak: str | None
    eyes: str = 'open'  # open, wide, alert, closed, happy
    highlight: str | None = BRANCO
    raised_brow: bool = False


def geometry(box: float, ox: float, oy: float, eyes_only: bool = False):
    """Medidas do rosto dentro de um quadrado de lado `box` em (ox, oy)."""
    r = box / 4.3 if eyes_only else box * 0.2
    stroke = r * 0.22
    cx = ox + box / 2
    cy = oy + (box / 2 if eyes_only else box * 0.57)
    return r, stroke, cx, cy


# ── PNG (Pillow) ────────────────────────────────────────────────────────


def hex_rgb(color: str):
    color = color.lstrip('#')
    return tuple(int(color[i:i + 2], 16) for i in (0, 2, 4))


def draw_owl(draw: ImageDraw.ImageDraw, owl: Owl, box: float, ox: float,
             oy: float, eyes_only: bool = False):
    r, stroke, cx, cy = geometry(box, ox, oy, eyes_only)
    dx = r * 1.15
    w = max(1, round(stroke))

    def line(points, color):
        draw.line(points, fill=color, width=w, joint='curve')
        for x, y in (points[0], points[-1]):
            draw.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2],
                         fill=color)

    for ex in (cx - dx, cx + dx):
        if owl.eyes in ('closed', 'happy'):
            radius = r * 0.74
            if owl.eyes == 'closed':
                cyc, a0, a1 = cy - r * 0.2, 0.14 * 180, 0.86 * 180
            else:
                cyc, a0, a1 = cy + r * 0.3, 1.12 * 180, 1.88 * 180
            draw.arc([ex - radius, cyc - radius, ex + radius, cyc + radius],
                     a0, a1, fill=owl.ring, width=w)
            for a in (a0, a1):
                px = ex + radius * math.cos(math.radians(a))
                py = cyc + radius * math.sin(math.radians(a))
                rr = radius - w / 2
                px = ex + rr * math.cos(math.radians(a))
                py = cyc + rr * math.sin(math.radians(a))
                draw.ellipse([px - w / 2, py - w / 2, px + w / 2, py + w / 2],
                             fill=owl.ring)
            continue
        draw.ellipse([ex - r, cy - r, ex + r, cy + r], outline=owl.ring,
                     width=w)
        if owl.pupil:
            pr = r * {'wide': 0.5, 'alert': 0.17}.get(owl.eyes, 0.4)
            draw.ellipse([ex - pr, cy - pr, ex + pr, cy + pr], fill=owl.pupil)
            if owl.highlight and owl.eyes in ('open', 'wide'):
                hx, hy, hr = ex + pr * 0.4, cy - pr * 0.4, pr * 0.3
                draw.ellipse([hx - hr, hy - hr, hx + hr, hy + hr],
                             fill=owl.highlight)

    if eyes_only:
        return
    if owl.brow:
        lift = r * 0.2 if owl.raised_brow else 0
        line([(cx - r * 2.25, cy - r * 1.74 - lift),
              (cx, cy - r * 1.22 - lift),
              (cx + r * 2.25, cy - r * 1.74 - lift)], owl.brow)
    if owl.beak:
        by = cy + r * 0.98
        draw.polygon([(cx, by - r * 0.42), (cx + r * 0.27, by),
                      (cx, by + r * 0.42), (cx - r * 0.27, by)],
                     fill=owl.beak)


# Símbolo da marca sobre Petróleo: anéis Âmbar, o resto em Linho.
BRAND = Owl(ring=AMBAR_500, pupil=LINHO_100, brow=LINHO_100, beak=LINHO_100,
            highlight=PETROLEO_900)


def app_icon(size: int, *, radius: float = 0.0, scale: float = 0.62,
             background: str = PETROLEO_800, alpha: bool = True) -> Image.Image:
    """Ícone do app: o símbolo em Linho e Âmbar sobre Petróleo."""
    ss = 4  # superamostragem para bordas suaves
    big = size * ss
    image = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    if radius > 0:
        draw.rounded_rectangle([0, 0, big - 1, big - 1], radius=big * radius,
                               fill=background)
    else:
        draw.rectangle([0, 0, big, big], fill=background)
    box = big * scale
    # O rosto fica um pouco acima do centro geométrico para parecer centrado.
    draw_owl(draw, BRAND, box, (big - box) / 2, (big - box) / 2 - box * 0.036)
    image = image.resize((size, size), Image.LANCZOS)
    if not alpha:
        flat = Image.new('RGB', (size, size), hex_rgb(background))
        flat.paste(image, mask=image.split()[3])
        return flat
    return image


def save(image: Image.Image, *parts: str):
    path = os.path.join(ROOT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save(path)
    print('  ', os.path.relpath(path, ROOT))


# ── Vetores do Android ──────────────────────────────────────────────────


def n(value: float) -> str:
    return f'{value:.2f}'.rstrip('0').rstrip('.')


def circle_path(cx: float, cy: float, r: float) -> str:
    return (f'M{n(cx - r)},{n(cy)} a{n(r)},{n(r)} 0 1,0 {n(2 * r)},0 '
            f'a{n(r)},{n(r)} 0 1,0 {n(-2 * r)},0 Z')


def arc_path(cx: float, cy: float, r: float, a0: float, a1: float) -> str:
    """Arco de a0 a a1 (em frações de pi), no sentido horário da tela."""
    x0 = cx + r * math.cos(a0 * math.pi)
    y0 = cy + r * math.sin(a0 * math.pi)
    x1 = cx + r * math.cos(a1 * math.pi)
    y1 = cy + r * math.sin(a1 * math.pi)
    return f'M{n(x0)},{n(y0)} A{n(r)},{n(r)} 0 0,1 {n(x1)},{n(y1)}'


def vector(owl: Owl, *, size_dp: int, viewport: float, box: float,
           eyes_only: bool = False, comment: str = '') -> str:
    ox = (viewport - box) / 2
    oy = (viewport - box) / 2 - (0 if eyes_only else box * 0.036)
    r, stroke, cx, cy = geometry(box, ox, oy, eyes_only)
    dx = r * 1.15
    rc = r - stroke / 2
    paths: list[str] = []

    def stroke_path(data: str, color: str):
        paths.append(
            f'    <path\n'
            f'        android:pathData="{data}"\n'
            f'        android:strokeColor="{color}"\n'
            f'        android:strokeWidth="{n(stroke)}"\n'
            f'        android:strokeLineCap="round"\n'
            f'        android:strokeLineJoin="round" />')

    def fill_path(data: str, color: str):
        paths.append(
            f'    <path\n'
            f'        android:pathData="{data}"\n'
            f'        android:fillColor="{color}" />')

    for ex in (cx - dx, cx + dx):
        if owl.eyes == 'closed':
            stroke_path(arc_path(ex, cy - r * 0.2, r * 0.74 - stroke / 2,
                                 0.14, 0.86), owl.ring)
            continue
        if owl.eyes == 'happy':
            stroke_path(arc_path(ex, cy + r * 0.3, r * 0.74 - stroke / 2,
                                 1.12, 1.88), owl.ring)
            continue
        stroke_path(circle_path(ex, cy, rc), owl.ring)
        if owl.pupil:
            pr = r * {'wide': 0.5, 'alert': 0.17}.get(owl.eyes, 0.4)
            fill_path(circle_path(ex, cy, pr), owl.pupil)
            if owl.highlight and owl.eyes in ('open', 'wide'):
                fill_path(circle_path(ex + pr * 0.4, cy - pr * 0.4, pr * 0.3),
                          owl.highlight)

    if not eyes_only:
        if owl.brow:
            lift = r * 0.2 if owl.raised_brow else 0
            stroke_path(
                f'M{n(cx - r * 2.25)},{n(cy - r * 1.74 - lift)} '
                f'L{n(cx)},{n(cy - r * 1.22 - lift)} '
                f'L{n(cx + r * 2.25)},{n(cy - r * 1.74 - lift)}', owl.brow)
        if owl.beak:
            by = cy + r * 0.98
            fill_path(
                f'M{n(cx)},{n(by - r * 0.42)} L{n(cx + r * 0.27)},{n(by)} '
                f'L{n(cx)},{n(by + r * 0.42)} L{n(cx - r * 0.27)},{n(by)} Z',
                owl.beak)

    header = '<?xml version="1.0" encoding="utf-8"?>\n'
    if comment:
        header += f'<!-- {comment} Gerado por scripts/make_icons.py. -->\n'
    return (header +
            '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
            f'    android:width="{size_dp}dp"\n'
            f'    android:height="{size_dp}dp"\n'
            f'    android:viewportWidth="{n(viewport)}"\n'
            f'    android:viewportHeight="{n(viewport)}">\n' +
            '\n'.join(paths) + '\n</vector>\n')


def write(text: str, *parts: str):
    path = os.path.join(RES, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as handle:
        handle.write(text)
    print('  ', os.path.relpath(path, ROOT))


# Estados do mascote no widget (Guia de Design, seção 4).
WIDGET_OWLS = {
    'ic_vigi_descansando': (Owl(ring=LINHO_400, pupil=None, brow=LINHO_400,
                                beak=LINHO_400, eyes='closed'),
                            'Vigi descansando: olhos fechados, cinza.'),
    'ic_vigi_vigiando': (Owl(ring=PETROLEO_800, pupil=PETROLEO_800,
                             brow=PETROLEO_800, beak=AMBAR_500),
                         'Vigi vigiando: olhos abertos, Petróleo.'),
    # Sobre o fundo Âmbar do widget "Estou bem".
    'ic_vigi_sua_vez': (Owl(ring=PETROLEO_800, pupil=PETROLEO_800,
                            brow=PETROLEO_800, beak=PETROLEO_800,
                            eyes='wide', highlight=AMBAR_500),
                        'Vigi na sua vez: olhos arregalados.'),
    # Sobre o fundo Sinal 600 do widget em alerta.
    'ic_vigi_alerta': (Owl(ring=BRANCO, pupil=BRANCO, brow=BRANCO,
                           beak=BRANCO, eyes='alert', highlight=None,
                           raised_brow=True),
                       'Vigi em alerta: pupilas pequenas, sobrolho erguido.'),
    'ic_vigi_noturno': (Owl(ring=AMBAR_500, pupil=LINHO_100,
                            brow=PETROLEO_300, beak=AMBAR_500,
                            highlight=None),
                        'Vigi noturno: olhos Âmbar sobre Petróleo 900.'),
}


def main() -> int:
    print('Android: ícone adaptativo')
    write(vector(BRAND, size_dp=108, viewport=108, box=58,
                 comment='Frente do ícone adaptativo (zona segura de 66 dp).'),
          'drawable', 'ic_launcher_foreground.xml')
    mono = Owl(ring=BRANCO, pupil=BRANCO, brow=BRANCO, beak=BRANCO,
               highlight=None)
    write(vector(mono, size_dp=108, viewport=108, box=58,
                 comment='Versão monocromática para ícones temáticos.'),
          'drawable', 'ic_launcher_monochrome.xml')
    write('<?xml version="1.0" encoding="utf-8"?>\n'
          '<!-- Ícone adaptativo do Vigi: símbolo em Linho e Âmbar sobre '
          'Petróleo. -->\n'
          '<adaptive-icon xmlns:android='
          '"http://schemas.android.com/apk/res/android">\n'
          '    <background android:drawable="@color/vigi_petroleo_800" />\n'
          '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n'
          '    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />\n'
          '</adaptive-icon>\n', 'mipmap-anydpi-v26', 'ic_launcher.xml')

    print('Android: ícones legados')
    for density, size in (('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                          ('xxhdpi', 144), ('xxxhdpi', 192)):
        save(app_icon(size, radius=0.22), 'android', 'app', 'src', 'main',
             'res', f'mipmap-{density}', 'ic_launcher.png')

    print('Android: notificação, widget e abertura')
    stat = Owl(ring=BRANCO, pupil=BRANCO, brow=BRANCO, beak=None,
               highlight=None)
    write(vector(stat, size_dp=24, viewport=24, box=23,
                 comment='Ícone pequeno das notificações (silhueta branca).'),
          'drawable', 'ic_stat_vigi.xml')
    for name, (owl, comment) in WIDGET_OWLS.items():
        write(vector(owl, size_dp=64, viewport=64, box=62, comment=comment),
              'drawable', f'{name}.xml')
    splash = Owl(ring=PETROLEO_800, pupil=AMBAR_500, brow=PETROLEO_800,
                 beak=AMBAR_500)
    write(vector(splash, size_dp=120, viewport=120, box=116,
                 comment='Símbolo da tela de abertura, sobre Linho.'),
          'drawable', 'ic_vigi_splash.xml')
    write(vector(BRAND, size_dp=120, viewport=120, box=116,
                 comment='Símbolo da tela de abertura noturna.'),
          'drawable', 'ic_vigi_splash_night.xml')

    print('Web / PWA')
    save(app_icon(192, radius=0.22), 'web', 'icons', 'Icon-192.png')
    save(app_icon(512, radius=0.22), 'web', 'icons', 'Icon-512.png')
    # Mascaráveis: sem cantos e com o símbolo dentro da zona segura (80%).
    save(app_icon(192, scale=0.5), 'web', 'icons', 'Icon-maskable-192.png')
    save(app_icon(512, scale=0.5), 'web', 'icons', 'Icon-maskable-512.png')
    save(app_icon(32, radius=0.22, scale=0.72), 'web', 'favicon.png')

    print('iOS')
    ios = os.path.join('ios', 'Runner', 'Assets.xcassets',
                       'AppIcon.appiconset')
    for base, scales in ((20, (1, 2, 3)), (29, (1, 2, 3)), (40, (1, 2, 3)),
                         (60, (2, 3)), (76, (1, 2)), (83.5, (2,)),
                         (1024, (1,))):
        for s in scales:
            name = f'Icon-App-{base:g}x{base:g}@{s}x.png'
            # O iOS aplica a máscara: sem transparência e sem cantos.
            save(app_icon(round(base * s), alpha=False), ios, name)

    print('macOS')
    mac = os.path.join('macos', 'Runner', 'Assets.xcassets',
                       'AppIcon.appiconset')
    for size in (16, 32, 64, 128, 256, 512, 1024):
        save(app_icon(size, radius=0.22), mac, f'app_icon_{size}.png')

    print('Windows')
    ico = os.path.join(ROOT, 'windows', 'runner', 'resources', 'app_icon.ico')
    if os.path.isdir(os.path.dirname(ico)):
        app_icon(256, radius=0.22).save(
            ico, sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128),
                        (256, 256)])
        print('  ', os.path.relpath(ico, ROOT))
    return 0


if __name__ == '__main__':
    sys.exit(main())
