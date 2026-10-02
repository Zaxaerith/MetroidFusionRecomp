"""Audit both stage directories and ZIPs against the player-package boundary."""
import hashlib
import os
import pathlib
import re
import sys
import zipfile

ASSETS = {'assets/fonts/' + f for f in ('LatoLatin-Regular.ttf', 'LatoLatin-Bold.ttf', 'OpenMoji-black-glyf.ttf', 'NotoSansSymbols2-Regular.ttf')}
ASSETS |= {'assets/img/' + f for f in ('brand_mark.tga', 'verdict_ok.tga', 'verdict_warn.tga', 'verdict_bad.tga', 'verdict_none.tga', 'flags.png', 'pad_gba.tga')}
TOP = {'MetroidFusionRecomp.exe', 'SDL2.dll', 'libgcc_s_seh-1.dll', 'libstdc++-6.dll', 'libwinpthread-1.dll', 'LICENSE', 'THIRD_PARTY_NOTICES.md', 'README.md', 'manifest.json'}
PRIVATE_HASHES = {'ca33f4348c2c05dd330d37b97e2c5a69531dfe87', '300c20df6731a33952ded8c436f7f186d25d3492'}

def audit(entries):
    count = 0
    seen = set()
    for name, data in entries:
        path = pathlib.PurePosixPath(name)
        assert not path.is_absolute() and '..' not in path.parts, f'Unsafe path: {name}'
        assert name not in seen, f'Duplicate file: {name}'
        seen.add(name)
        allowed = name in TOP or name in ASSETS or (len(path.parts) == 2 and path.parts[0] == 'licenses' and path.suffix == '.txt')
        assert allowed, f'Forbidden file: {name}'
        assert hashlib.sha1(data).hexdigest() not in PRIVATE_HASHES, f'Private ROM/BIOS bytes: {name}'
        for text in (data.lower(), data.decode('utf-16-le', errors='ignore').lower().encode('utf-8')):
            normalized = text.replace(b'\\', b'/')
            private_roots = [str(pathlib.Path(__file__).resolve().parents[2]), os.environ.get('USERPROFILE', ''), os.environ.get('MINGW_ROOT', '')]
            assert not any(p and p.lower().replace('\\', '/').encode() in normalized for p in private_roots), f'Developer path: {name}'
        count += 1
    assert TOP <= seen, f'Missing package files: {TOP - seen}'
    assert ASSETS <= seen, f'Missing launcher assets: {ASSETS - seen}'
    assert any(name.startswith('licenses/') for name in seen), 'Missing third-party licenses'
    print(f'PASS: {count} allowlisted files; no private assets, developer paths or development output')

if __name__ == '__main__':
    target = pathlib.Path(sys.argv[1])
    if target.suffix == '.zip':
        with zipfile.ZipFile(target) as archive:
            audit((item.filename, archive.read(item)) for item in archive.infolist() if not item.is_dir())
    else:
        audit((p.relative_to(target).as_posix(), p.read_bytes()) for p in sorted(target.rglob('*')) if p.is_file())
