# MetroidFusionRecomp — Experimental Preview

Windows recompilation of Metroid Fusion (USA) using pinned GBARecomp and recomp-ui.
**Full-game compatibility is not exhaustively tested. Interpreter fallback remains.**
Runtime compilation defaults OFF; this is not a fully static/native release.
ROM/BIOS files are not distributed.

## Players

Download the v0.1.0-preview ZIP, extract into a writable folder, run
**MetroidFusionRecomp.exe**, select your legally obtained MF USA ROM and
retail GBA BIOS, then press **Play**. Valid paths/settings are remembered.
No PowerShell, compiler or regeneration is required.

ROM: AMTE, SHA-1 `ca33f4348c2c05dd330d37b97e2c5a69531dfe87`.
BIOS: 16 KiB, SHA-1 `300c20df6731a33952ded8c436f7f186d25d3492`.
See [baserom.md](baserom.md). Other regions and modified ROMs are unsupported.
Keys: arrows = move; X = A/jump; Z = B/shoot; Enter = Start; Right Shift = Select;
C = L; V = R. Controls are configurable in the launcher.
Saves are in `saves/metroid_fusion_usa.sav` beside the EXE; preserve settings
and saves when updating. Use `--launcher` if Skip Launcher was enabled.

The [frozen ZIP identity](docs/RELEASE_v0.1.0-preview.md) is intended for a
separate GitHub Release upload, never a source commit.

## Developers

Clone the published repository with `git clone --recurse-submodules`, enter
its directory, and install Git, CMake, Ninja, Python 3, MinGW-w64 GCC and an SDL2
SDK. Set `MINGW_ROOT` and `SDL2_ROOT` for your installations; helpers can discover
GCC from PATH. The SDL SDK root contains `include/SDL2`, `lib/libSDL2.dll.a`
and `bin/SDL2.dll`. Supply your private ROM as `Metroid Fusion (USA).gba` in
this root and set `GBA_BIOS` to your retail BIOS file.

```powershell
.\tools\setup-deps.ps1
.\tools\build-generator.ps1   # build the pinned gba_recompile
python .\tools\import-mf-symbols.py
.\tools\regen.ps1 -Bios $env:GBA_BIOS
.\tools\build-host.ps1
.\tools\package-local.ps1
```

Setup initializes pinned desktop framework dependencies, obtains pinned toml++
and clones/verifies the MF reference. Exact commits are in `docs/FRAMEWORK_PIN.json`
and `docs/DECOMP_PIN.json`. No shared framework snapshot is required. Relative
SDK/BIOS fallbacks support existing local layouts; use explicit parameters on a
fresh checkout.

Keep private `generated/cart` and `generated/bios` locally for incremental builds
and study. They are gitignored, excluded from release ZIPs, and never handwritten
source. Cold cleanup removes build/cache only; it preserves generated, dist,
private files and saves. `Play.cmd` is a developer convenience; players use the EXE.

`tools/make_release.ps1 -Version <new-version>` builds, stages and audits a ZIP;
existing versions are preserved. `tools/audit-release.py` checks package boundaries;
`tools/test-release.py` runs bounded isolated regressions using copied saves.
Do not recreate the frozen asset for documentation changes.

## Design, compatibility and license

See [MSTAN_STYLE](docs/MSTAN_STYLE.md) and [COMPATIBILITY](docs/COMPATIBILITY.md).
Source-metadata symbols are not proof of a byte-matching decomp ELF. No
native-decomp implementation is integrated.

Original integration files use MIT; GBARecomp retains **PolyForm Noncommercial
1.0.0**, so the executable is not entirely MIT-licensed. See [LICENSE](LICENSE)
and [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md). Credits include Matthew Stanley,
GBARecomp/recomp-ui, metroidret/mf and YohannDR, SDL2, Dear ImGui and font authors.

Unofficial fan project, unaffiliated with Nintendo. Trademarks belong to their
owners; no affiliation or endorsement is claimed. User ROM/BIOS assets are not
licensed or distributed here.
