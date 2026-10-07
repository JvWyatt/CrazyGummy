#!/usr/bin/env python3
"""Quita solo el gris exterior y conserva la placa azul y toda la ilustración.

Prepara los assets fuera de Godot; nunca altera los JPEG fuente.

Uso: python tools/prepare_collection_art.py --preview-sources
     python tools/prepare_collection_art.py
Dependencias del procesado: Pillow, numpy, opencv-python-headless.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/crazy_gummy"
OUTPUT = SOURCE / "ui/collection"
REVIEW = Path("/tmp/opencode")
TOOL_IDS = (
    "tool_fists", "tool_confectioner_knife", "tool_confectioner_hatchet",
    "tool_gummy_hammer", "tool_sugar_mallet", "tool_shredder_axe",
    "tool_candy_crusher", "tool_hydraulic_hammer", "tool_gummy_crusher", "tool_crazy_hammer",
)
RECIPE_IDS = (
    "bear_classic", "ring", "ring_premium", "worm", "worm_premium", "bottle",
    "bottle_premium", "heart", "heart_premium", "fish", "fish_premium", "crocodile",
    "crocodile_premium", "shark", "shark_premium", "dragon", "dragon_premium",
    "unicorn", "unicorn_premium", "bear_crown",
)


def entries():
    for category, prefix, identifiers in [("Armas", "A", TOOL_IDS), ("Recetas", "G", RECIPE_IDS)]:
        for number, item_id in enumerate(identifiers, 1):
            yield category, f"{prefix}{number}", item_id, SOURCE / category / f"{prefix}{number}.jpeg"


def contact_sheet(items, destination: Path, transparent: bool = False):
    width, height = 240, 270
    sheet = Image.new("RGB", (width * 5, height * ((len(items) + 4) // 5)), "#211f36")
    draw = ImageDraw.Draw(sheet)
    for index, (label, source) in enumerate(items):
        image = Image.open(source).convert("RGBA")
        image.thumbnail((width - 24, height - 46), Image.Resampling.LANCZOS)
        x, y = (index % 5) * width, (index // 5) * height
        if transparent:
            for row in range(0, height - 30, 16):
                for col in range(0, width, 16):
                    fill = "#352f4b" if (row // 16 + col // 16) % 2 else "#211f36"
                    draw.rectangle((x + col, y + row, x + col + 15, y + row + 15), fill=fill)
        sheet.paste(image, (x + (width - image.width) // 2, y + (height - 30 - image.height) // 2), image)
        draw.text((x + 10, y + height - 25), label, fill="#f8f2ff")
    sheet.save(destination)


def extract(source: Path) -> Image.Image:
    import cv2
    import numpy as np

    original = ImageOps.exif_transpose(Image.open(source)).convert("RGB")
    rgb = np.asarray(original).astype(np.float32)
    red, green, blue = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    # El azul NO se elimina: solo se estima para recuperar su borde antialias.
    navy = (red < 65) & (green < 90) & (blue < 135) & (green - red > 9) & (blue - green > 12)
    neutral = (rgb.min(axis=2) > 155) & (rgb.max(axis=2) - rgb.min(axis=2) < 28)
    samples = rgb[navy].astype(np.int32)
    bins = samples // 8
    encoded = bins[:, 0] * 1024 + bins[:, 1] * 32 + bins[:, 2]
    mode = np.bincount(encoded).argmax()
    board_color = np.median(samples[encoded == mode], axis=0)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(neutral.astype(np.uint8), connectivity=8)
    frame = np.zeros(neutral.shape, np.uint8)
    # Solo quitar gris conectado a los bordes: el metal plateado no es fondo.
    edge_labels = np.unique(np.concatenate((labels[0], labels[-1], labels[:, 0], labels[:, -1])))
    for label in edge_labels:
        if label != 0:
            frame[labels == label] = 1
    gray_color = np.median(rgb[frame > 0], axis=0)
    area = rgb.shape[0] * rgb.shape[1]
    foreground = 1 - frame
    # Conservar la placa entera, incluidos huecos azules y detalles del objeto.
    count, labels, stats, _ = cv2.connectedComponentsWithStats(foreground, connectivity=8)
    mask = np.zeros(foreground.shape, np.uint8)
    for label in range(1, count):
        if stats[label, cv2.CC_STAT_AREA] > area * 0.01:
            mask[labels == label] = 1
    # Descontaminar solo los pocos píxeles de transición azul/gris del perímetro.
    distance = cv2.distanceTransform(mask, cv2.DIST_L2, 5)
    axis = board_color - gray_color
    projected_alpha = np.clip(((rgb - gray_color) * axis).sum(axis=2) / (axis * axis).sum(), 0, 1)
    alpha = mask.astype(np.float32)
    edge = (distance > 0) & (distance < 4)
    alpha[edge] = projected_alpha[edge]
    unmatted = (rgb - (1 - alpha[..., None]) * gray_color) / np.maximum(alpha[..., None], 0.01)
    rgba = np.concatenate((np.clip(unmatted, 0, 255).astype(np.uint8), (alpha * 255).astype(np.uint8)[..., None]), axis=2)
    rgba[alpha == 0, :3] = 0
    cutout = Image.fromarray(rgba)
    bounds = cutout.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError(f"No se detectó ilustración en {source}")
    cutout = cutout.crop(bounds)
    cutout.thumbnail((500, 500), Image.Resampling.LANCZOS)
    # Padding pequeño y consistente; el PNG conserva proporción y encuadre ajustado.
    canvas = Image.new("RGBA", (cutout.width + 12, cutout.height + 12))
    canvas.paste(cutout, (6, 6))
    assert max(canvas.size) <= 512
    assert canvas.getchannel("A").getextrema() == (0, 255)
    return canvas


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview-sources", action="store_true")
    args = parser.parse_args()
    records = list(entries())
    if args.preview_sources:
        contact_sheet([(f"{key} · {item_id}", source) for _, key, item_id, source in records], REVIEW / "collection_sources.png")
        print("Fuentes: /tmp/opencode/collection_sources.png")
        return
    OUTPUT.mkdir(parents=True, exist_ok=True)
    processed = []
    for _, key, item_id, source in records:
        output = OUTPUT / f"{item_id}.png"
        image = extract(source)
        image.save(output, optimize=True)
        processed.append((f"{key} · {item_id}", output))
        print(f"{key} → {output.name}: {image.width}×{image.height}")
    contact_sheet(processed, REVIEW / "collection_cutouts.png", transparent=True)
    print("Transparencias: /tmp/opencode/collection_cutouts.png")


if __name__ == "__main__":
    main()
