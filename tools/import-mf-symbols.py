"""Import documented USA address/size facts from the pinned MF reference.

This is a source-metadata overlay, not an ELF import or a byte-matching
decomp build claim. No decomp implementation is copied into the runtime.
"""
import hashlib
import json
import pathlib
import re
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
MF = ROOT / 'third_party/mf'
PIN = json.loads((ROOT / 'docs/DECOMP_PIN.json').read_text())
actual = subprocess.check_output(['git', '-c', f'safe.directory={MF.as_posix()}', '-C', str(MF), 'rev-parse', 'HEAD'], text=True).strip()
assert actual == PIN['commit'], 'MF pin mismatch'
sha = hashlib.sha1((ROOT / 'Metroid Fusion (USA).gba').read_bytes()).hexdigest()
assert sha == PIN['rom_sha1']
assert (MF / 'mf_us.sha1').read_text().split()[0].lower() == sha
out = ROOT / 'symbols'
out.mkdir(exist_ok=True)
functions = {}
sources = {}
ambiguous = set()
pattern = re.compile(r'/\*\*\s*\n\s*\* @brief ([0-9a-fA-F]+) \| ([0-9a-fA-F]+) \|.*?\*/\s*(?:[\w*]+\s+)+([A-Za-z_]\w*)\s*\([^;]*?\)\s*\{', re.S)
for path in sorted((MF / 'src').rglob('*.c')):
    for match in pattern.finditer(path.read_text(encoding='utf-8')):
        offset, size, name = int(match[1], 16), int(match[2], 16), match[3]
        if not (0x230 <= offset < 0xA5224 and size > 0 and offset + size <= 0xA5224):
            continue
        addr = 0x08000000 + offset
        if addr in functions and functions[addr] != (size, name):
            ambiguous.add(addr)
            continue
        functions[addr] = (size, name)
        sources[addr] = path.relative_to(MF).as_posix()
for addr in ambiguous:
    functions.pop(addr, None)
# Reject overlapping annotated extents as unverified source documentation.
rows = sorted(functions.items())
for (a, (size, _)), (b, _) in zip(rows, rows[1:]):
    if a + size > b:
        ambiguous.update((a, b))
for addr in ambiguous:
    functions.pop(addr, None)
assert len({name for size, name in functions.values()}) == len(functions), 'Duplicate function names'
ranges = []
data = []
for entry in json.loads((MF / 'database.json').read_text()):
    if 'us' not in entry.get('addr', {}):
        continue
    offset = int(entry['addr']['us'], 0)
    count = entry['count']
    size = (int(count, 0) if isinstance(count, str) else count) * entry['size']
    assert 0xA5224 <= offset < offset + size <= 0x800000, 'Unexpected asset extent'
    addr = 0x08000000 + offset
    name = 'mf_asset_' + re.sub(r'\W', '_', entry.get('dir', '') + '_' + entry['path'])
    ranges.append((addr, addr + size - 1))
    data.append((addr, size, name))
# RAM linker assignments have no authoritative size here; do not infer it.
linker = (MF / 'linker.ld').read_text()
for region, base in [('ewram', 0x02000000), ('iwram', 0x03000000)]:
    block = re.search(rf'{region} \(NOLOAD\).*?\{{(.*?)\}} >{region}', linker, re.S)[1]
    for offset, name in re.findall(r'\. = (0x[0-9a-fA-F]+);\s*(\w+) = \.;', block):
        data.append((base + int(offset, 0), 0, name))
merged = []
for start, end in sorted(ranges):
    if merged and start <= merged[-1][1] + 1:
        merged[-1] = (merged[-1][0], max(end, merged[-1][1]))
    else:
        merged.append((start, end))
header = f'# Pinned MF {actual}; documented USA metadata; not ELF/build validation.\n'
(out / 'imported_symbols.tsv').write_text(header + '# addr\tmode\tname\n' + ''.join(f'0x{a:08X}\tthumb\t{n}\n' for a, (s, n) in sorted(functions.items())))
(out / 'function_boundaries.tsv').write_text(header + '# start\tend\tmode\tname\tsource\n' + ''.join(f'0x{a:08X}\t0x{a+s-1:08X}\tthumb\t{n}\t{sources[a]}\n' for a, (s, n) in sorted(functions.items())))
(out / 'imported_data_symbols.tsv').write_text(header + '# addr\tregion\tsize\tname\n' + ''.join(f'0x{a:08X}\t{"rom" if a >= 0x08000000 else "ewram" if a < 0x03000000 else "iwram"}\t0x{s:X}\t{n}\n' for a, s, n in sorted(data)))
(out / 'AMTE_symbols.toml').write_text(header + f'[identity]\nsha1 = "{sha}"\n' + ''.join(f'\n[[data_range]]\nstart = 0x{a:08X}\nend = 0x{b:08X}\nnote = "MF database USA asset extent"\n' for a, b in merged))
report = {'decomp_commit': actual, 'rom_sha1': sha, 'source': 'MF C @brief annotations, database.json and linker.ld', 'validation': 'Source metadata only; no byte-matching ELF build performed', 'functions': len(functions), 'excluded_conflicting_or_overlapping_addresses': [f'0x{a:08X}' for a in sorted(ambiguous)], 'data_symbols': len(data), 'data_ranges': len(merged)}
(out / 'provenance.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report))
