"""Bounded backend-only checks of an extracted player ZIP, without a toolchain."""
import hashlib
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import time
import zipfile

root = pathlib.Path(__file__).resolve().parents[1]
archive = pathlib.Path(sys.argv[1]).resolve()
subprocess.run([sys.executable, str(root / 'tools/audit-release.py'), str(archive)], check=True)
scratch = root / 'release-test' / f'{archive.stem}-{time.time_ns()}'
installed = scratch / 'installed'
installed.mkdir(parents=True)
with zipfile.ZipFile(archive) as zipped:
    zipped.extractall(installed)
exe = installed / 'MetroidFusionRecomp.exe'
manifest = json.loads((installed / 'manifest.json').read_text(encoding='utf-8-sig'))
for entry in manifest:
    assert hashlib.sha256((installed / entry['file']).read_bytes()).hexdigest() == entry['sha256']
assert not (installed / 'game.toml').exists()
rom = root / 'Metroid Fusion (USA).gba'
bios = root.parent / 'gbarecomp-cli-windows-x86_64/gbabios/gba_bios.bin'
outside = scratch / 'unrelated-working-directory'
outside.mkdir()
env = os.environ.copy()
for name in list(env):
    if name.startswith('GBARECOMP_'):
        del env[name]
env['PATH'] = os.environ['SystemRoot'] + '\\System32'
player_save = root / 'saves/metroid_fusion_usa.sav'
before = hashlib.sha256(player_save.read_bytes()).hexdigest()
test_save = scratch / 'isolated.sav'
shutil.copyfile(player_save, test_save)
results = {}

def run(name, args, replay=None, expect=0):
    local_env = env.copy()
    if replay:
        local_env['GBARECOMP_INPUT_REPLAY'] = str(replay)
    result = subprocess.run([str(exe)] + args, cwd=outside, env=local_env, capture_output=True, timeout=40)
    output = (result.stdout + result.stderr).decode('utf-8', errors='replace')
    (scratch / f'{name}.log').write_text(output)
    assert result.returncode == expect, f'{name}: exit {result.returncode}; {output[-1000:]}'
    results[name] = {'exit': result.returncode}
    return output

# recomp-ui's built-in CI hook renders a hidden window and quits after a
# few frames. No desktop automation, mouse/key injection or screenshots.
hidden_env = env.copy()
hidden_env.update(LNG_SCRIPT='wait:3;quit', LNG_TEST_HIDDEN='1', LNG_SMOKE_FRAMES='30')
def hidden_launcher(name):
    result = subprocess.run([str(exe)], cwd=outside, env=hidden_env, capture_output=True, timeout=20)
    text = (result.stdout + result.stderr).decode('utf-8', errors='replace')
    (scratch / f'{name}.log').write_text(text)
    assert result.returncode == 0 and '[dbg] script: 2 commands' in text, f'Hidden launcher failed: {text[-1000:]}'
    assert 'SDL_CreateWindow failed' not in text and 'SDL_GL_CreateContext failed' not in text
    assert 'rom_loaded' not in text, 'Quit must not boot game'
    results[name] = {'exit': 0, 'hidden_window': True, 'no_desktop_automation': True}
hidden_launcher('first-launch-no-assets')
(installed / 'rom.cfg').write_text(str(rom.resolve()) + '\n')
(installed / 'bios.cfg').write_text(str(bios.resolve()) + '\n')
hidden_launcher('cached-launcher')

title = scratch / 'title.png'
text = run('cached-title', ['--no-window', '--frames', '600', '--save', str(test_save), '--dump-png', str(title)])
assert 'ppu_frames=600' in text and 'failed=0' in text
assert hashlib.sha256(title.read_bytes()).hexdigest() == '03193a37d932f3930a4c8838e603cc4920f130d23c105876002fca41b49043a4'
assert 'self_heal_coverage=NOT_STATIC' in text
results['cached-title']['coverage'] = re.search(r'self_heal_coverage=[^\r\n]+', text)[0]
loaded = scratch / 'load.png'
text = run('fresh-load', ['--no-window', '--frames', '1800', '--save', str(test_save), '--dump-png', str(loaded)], root / 'tests/load-save-input.csv')
assert 'ppu_frames=1800' in text and 'failed=0' in text
assert hashlib.sha256(loaded.read_bytes()).hexdigest() == 'd44edda637f2ae9e5d2fb4a9546da9ad2e1aab07fe08192209d138a9a0a2fef2'
results['fresh-load']['coverage'] = re.search(r'self_heal_coverage=[^\r\n]+', text)[0]
wrong_rom = scratch / 'wrong.gba'
wrong_rom.write_bytes(bytes(8388608))
wrong_bios = scratch / 'wrong-bios.bin'
wrong_bios.write_bytes(bytes(16384))
run('wrong-rom', ['--rom', str(wrong_rom), '--no-window', '--frames', '1', '--save', str(test_save)], expect=1)
run('wrong-bios', ['--bios', str(wrong_bios), '--no-window', '--frames', '1', '--save', str(test_save)], expect=1)
assert hashlib.sha256(player_save.read_bytes()).hexdigest() == before
report = {'zip': archive.name, 'zip_bytes': archive.stat().st_size, 'zip_sha256': hashlib.sha256(archive.read_bytes()).hexdigest(), 'manifest_files_verified': len(manifest), 'no_game_toml_or_compiler': True, 'external_working_directory': True, 'player_save_unchanged': True, 'results': results, 'gui_interaction': 'Hidden CI renderer startup/quit passed; no desktop automation or visual inspection. Launcher model contract tested separately.'}
(root / 'docs/RELEASE_TEST_RESULT.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
