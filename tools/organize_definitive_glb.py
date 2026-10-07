"""Renombra fuentes binarias intactas; conserva los UID de importación existentes."""
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'assets/crazy_gummy'
GUMMIES = ['bear', 'ring', 'ring_premium', 'worm', 'worm_premium',
           'bottle', 'bottle_premium', 'heart', 'heart_premium', 'fish',
           'fish_premium', 'crocodile', 'crocodile_premium', 'shark',
           'shark_premium', 'dragon', 'dragon_premium', 'unicorn',
           'unicorn_premium', 'bear_crown']
CUBES = ['classic', 'wavy', 'faceted', 'relief', 'crown', 'crown_exclusive']


def run():
    mappings = [(BASE / 'gummies' / f'g{i}.glb',
                 BASE / 'gummies' / f'gummy_{i:02}_{name}.glb')
                for i, name in enumerate(GUMMIES, 1)]
    mappings += [(BASE / 'cubes' / f'c{i}.glb',
                  BASE / 'cubes' / f'cube_{i:02}_{name}.glb')
                 for i, name in enumerate(CUBES, 1)]
    mappings += [(BASE / 'Obstaculos' / f'o{i}.glb',
                  BASE / 'Obstaculos' / f'obstacle_hard_candy{suffix}.glb')
                 for i, suffix in [(1, ''), (2, '_broken')]]
    records = []
    for source, target in mappings:
        if target.exists() and not source.exists():
            continue
        assert source.exists() and not target.exists(), (source, target)
        digest = hashlib.sha256(source.read_bytes()).hexdigest()
        source.rename(target)
        assert hashlib.sha256(target.read_bytes()).hexdigest() == digest
        old_import = Path(str(source) + '.import')
        if old_import.exists():
            # Godot regenerará el destino de caché para la nueva ruta.
            text = old_import.read_text().replace(str(source.relative_to(ROOT)), str(target.relative_to(ROOT)))
            Path(str(target) + '.import').write_text(text)
            old_import.unlink()
        records.append({'source': str(source.relative_to(ROOT)),
                        'target': str(target.relative_to(ROOT)), 'sha256': digest})
    Path('/tmp/opencode/definitive_glb_renames.json').write_text(json.dumps(records, indent=2))
    print(f'{len(records)} GLB renombrados; SHA-256 conservados.')


def extract_embedded_bear_image():
    # Imagen original embebida: Godot la referencia externamente al importar.
    raw = (BASE / 'gummies/gummy_01_bear.glb').read_bytes()
    chunks = {}
    offset = 12
    while offset < len(raw):
        length, kind = struct.unpack_from('<II', raw, offset)
        chunks[kind] = raw[offset + 8:offset + 8 + length]
        offset += length + 8
    data = json.loads(chunks[0x4E4F534A])
    for image in data.get('images', []):
        view = data['bufferViews'][image['bufferView']]
        start = view.get('byteOffset', 0)
        target = BASE / 'gummies' / ('gummy_01_bear_' + image['name'] + '.jpg')
        target.write_bytes(chunks[0x004E4942][start:start + view['byteLength']])


if __name__ == '__main__':
    if '--extract-image' in __import__('sys').argv:
        extract_embedded_bear_image()
    else:
        run()
