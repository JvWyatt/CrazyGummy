"""Inspección binaria glTF sin modificar originales; componentes y huellas."""
import hashlib
import json
import struct
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def inspect(path):
    raw = path.read_bytes()
    chunks = {}
    offset = 12
    while offset < len(raw):
        length, kind = struct.unpack_from('<II', raw, offset)
        chunks[kind] = raw[offset + 8:offset + 8 + length]
        offset += 8 + length
    data = json.loads(chunks[0x4E4F534A])
    binary = chunks.get(0x004E4942, b'')

    def accessor(index):
        a = data['accessors'][index]
        view = data['bufferViews'][a['bufferView']]
        types = {5126: 'f', 5125: 'I', 5123: 'H', 5121: 'B'}
        components = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}
        fmt = '<' + types[a['componentType']] * components[a['type']]
        start = view.get('byteOffset', 0) + a.get('byteOffset', 0)
        stride = view.get('byteStride', struct.calcsize(fmt))
        return [struct.unpack_from(fmt, binary, start + n * stride) for n in range(a['count'])]

    geometries = []
    for mesh in data.get('meshes', []):
        for primitive in mesh['primitives']:
            positions = accessor(primitive['attributes']['POSITION'])
            indices = [v[0] for v in accessor(primitive['indices'])] if 'indices' in primitive else list(range(len(positions)))
            # Soldadura solo para auditoría topológica: costuras UV no son piezas.
            points = [tuple(round(v, 5) for v in p) for p in positions]
            parents = {p: p for p in points}

            def root(p):
                while parents[p] != p:
                    parents[p] = parents[parents[p]]
                    p = parents[p]
                return p

            for n in range(0, len(indices), 3):
                a, b, c = (points[i] for i in indices[n:n + 3])
                r = root(a)
                parents[root(b)] = r
                parents[root(c)] = r
            sizes = Counter(root(p) for p in set(points))
            geometries.append({'vertices': len(positions), 'triangles': len(indices) // 3,
                               'components': sorted(sizes.values(), reverse=True),
                               'hash': hashlib.sha256(repr((positions, indices)).encode()).hexdigest()})
    return {'file': str(path.relative_to(ROOT)), 'sha256': hashlib.sha256(raw).hexdigest(),
            'bytes': len(raw), 'nodes': data.get('nodes', []), 'meshes': geometries,
            'materials': data.get('materials', []), 'images': data.get('images', []),
            'animations': len(data.get('animations', [])), 'skins': len(data.get('skins', []))}


if __name__ == '__main__':
    records = []
    for folder in ['gummies', 'cubes', 'Obstaculos', 'obstacles']:
        for path in sorted((ROOT / 'assets/crazy_gummy' / folder).glob('*.glb')):
            record = inspect(path)
            records.append(record)
            print(path.name, 'sha=', record['sha256'][:16], 'mesh=', record['meshes'],
                  'images=', record['images'], 'materials=', len(record['materials']))
    Path('/tmp/opencode/glb_structure.json').write_text(json.dumps(records, indent=2))
    baseline = {}
    for pattern in ['data/**/*.tres', 'scripts/game/Ballistic.gd',
                    'scripts/game/BlockSpawner.gd', 'scripts/game/GummyBlock.gd',
                    'scripts/autoload/GameManager.gd', 'scripts/autoload/StatsManager.gd',
                    'scripts/autoload/SaveManager.gd', 'scripts/models/SaveMigration.gd',
                    'assets/crazy_gummy/materials/**/*']:
        for path in ROOT.glob(pattern):
            if path.is_file():
                baseline[str(path.relative_to(ROOT))] = hashlib.sha256(path.read_bytes()).hexdigest()
    baseline_path = Path('/tmp/opencode/cg_3d_balance_baseline.json')
    if not baseline_path.exists():
        baseline_path.write_text(json.dumps(baseline, indent=2))
    else:
        before = json.loads(baseline_path.read_text())
        changed = [key for key in before if baseline.get(key) != before[key]]
        print('Archivos de balance/materiales/gameplay modificados:', changed)
