#!/usr/bin/env python3
"""Genera le icone e le immagini della schermata di avvio di Rokko.

Le forme vivono solo qui: i PNG in assets/icon/ sono derivati, e icon.svg
è la stessa icona in vettoriale per documenti e store.
Dopo averli rigenerati si eseguono flutter_launcher_icons e
flutter_native_splash (vedi docs/identita-visiva.md).

Uso: python3 -m pip install cairosvg pillow && python3 tool/generate_icons.py
"""

import io
from pathlib import Path

import cairosvg
from PIL import Image, ImageChops

OUT = Path(__file__).resolve().parent.parent / "assets" / "icon"

ORANGE = "#F2994A"
CREAM = "#FFF6E9"
BROWN = "#8A3B12"
NIGHT = "#1C1714"

# Torre su griglia adattiva 108 dp, ingrandita del 20% e contenuta
# nella zona sicura da 66 dp, così regge maschere rotonde e squircle.
BODY = (
    '<rect x="37" y="69" width="34" height="8" rx="3"/>'
    '<path d="M42 46H66L68.5 69H39.5Z"/>'
    '<path d="M38 47V36.5a2.5 2.5 0 0 1 2.5-2.5H45.5V39.5H51V34H57V39.5'
    'H62.5V34H67.5a2.5 2.5 0 0 1 2.5 2.5V47Z"/>'
)
FACE = (
    '<circle cx="49" cy="55" r="3"/><circle cx="59" cy="55" r="3"/>'
    '<path d="M49.5 61.5Q54 65.5 58.5 61.5" fill="none" stroke-width="2.6"'
    ' stroke-linecap="round"/>'
)
SCALE = 'transform="translate(54 54) scale(1.2) translate(-54 -54)"'


def svg(content: str) -> str:
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108">'
        f"{content}</svg>"
    )


def rook(fg: str, face: str) -> str:
    return (
        f'<g {SCALE}><g fill="{fg}">{BODY}</g>'
        f'<g fill="{face}" stroke="{face}">{FACE}</g></g>'
    )


def face_only() -> str:
    return svg(f'<g {SCALE}><g fill="#000" stroke="#000">{FACE}</g></g>')


def background(color: str) -> str:
    return f'<rect width="108" height="108" fill="{color}"/>'


# Con HOLED il viso diventa trasparente: serve alle icone monocromatiche e a
# quelle scure di iOS, dove conta solo il canale alfa o lo sfondo è del sistema.
HOLED = "transparent"

IMAGES = {
    # Icona completa: iOS e Android senza icone adattive.
    "icon": (svg(background(ORANGE) + rook(CREAM, BROWN)), 1024),
    # Primo piano adattivo Android; lo sfondo è il colore in pubspec.yaml.
    "foreground": (svg(rook(CREAM, BROWN)), 432),
    # Icona a tema di Android 13+ e icona colorata dal sistema su iOS 18.
    "monochrome": (svg(rook("#FFFFFF", HOLED)), 432),
    "tinted": (svg(rook("#FFFFFF", HOLED)), 1024),
    # Icona scura di iOS 18: sfondo trasparente, lo aggiunge il sistema.
    "dark": (svg(rook(ORANGE, HOLED)), 1024),
    # Schermata di avvio: 1152 px sono 288 dp in xxxhdpi, la misura
    # richiesta da Android 12; il soggetto sta nel cerchio visibile.
    "splash": (svg(rook(CREAM, BROWN)), 1152),
    "splash-dark": (svg(rook(ORANGE, NIGHT)), 1152),
}


def render(source: str, size: int) -> Image.Image:
    png = cairosvg.svg2png(
        bytestring=source.encode(), output_width=size, output_height=size
    )
    return Image.open(io.BytesIO(png)).convert("RGBA")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "icon.svg").write_text(IMAGES["icon"][0] + "\n", encoding="utf-8")
    for name, (source, size) in IMAGES.items():
        image = render(source, size)
        if HOLED in source:
            # cairosvg ignora le maschere: il viso si toglie dall'alfa qui.
            face = render(face_only(), size).getchannel("A")
            image.putalpha(ImageChops.subtract(image.getchannel("A"), face))
        image.save(OUT / f"{name}.png", optimize=True)
        print(f"assets/icon/{name}.png  {size}×{size}")


if __name__ == "__main__":
    main()
