"""Record local generated source sizes and emitted-function counts."""
import json
import pathlib
import re

root = pathlib.Path(__file__).resolve().parents[1]
report = {}
for kind in ('cart', 'bios'):
    directory = root / 'generated' / kind
    files = sorted(p for p in directory.rglob('*') if p.is_file())
    raw = (root / 'logs' / f'regen-{kind}.log').read_bytes()
    text = raw.decode('utf-16' if raw.startswith((b'\xff\xfe', b'\xfe\xff')) else 'utf-8-sig', errors='replace')
    counts = re.findall(r'TOTAL emitted:\s*(\d+)', text)
    report[kind] = {'directory': f'generated/{kind}', 'bytes': sum(p.stat().st_size for p in files), 'files': len(files), 'translation_units': sum(p.suffix in ('.c', '.cpp') for p in files), 'emitted_functions': int(counts[-1]) if counts else None}
report['total_bytes'] = sum(r['bytes'] for r in report.values())
(root / 'docs/GENERATED_STATS.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
