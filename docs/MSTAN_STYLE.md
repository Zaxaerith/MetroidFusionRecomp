# mstan-style project structure

References: [Mario Kart](https://github.com/mstan/MarioKartSuperCircuitRecomp),
[Minish Cap](https://github.com/mstan/MinishCapRecomp),
[Mega Man Zero](https://github.com/mstan/MegaManZeroRecomp).
Their game configs, hints, symbols and assets are not imported.

- `gbarecomp/`, `recomp-ui/`: clean pinned gitlinks; FRAMEWORK_PIN.json records
  identities. Framework desktop dependencies use upstream gitlinks. toml++ is a
  pinned ignored checkout.
- `third_party/mf/`: ignored pinned reference, provisioned by setup-deps; identity
  in DECOMP_PIN.json. No extracted blobs or decomp build output are published.
- `src/`: minimal identity and launcher bridge. Exact USA ROM and retail BIOS
  gates; no widescreen/adaptive view, mods, netplay or ROM patches enabled.
- `symbols/`: pinned MF USA function annotations, asset extents and RAM linker
  names. Regen automatically loads the SHA-gated overlay; `-NoSymbols` permits
  comparison. Conflicting/overlapping annotations are excluded in provenance.
  These facts have not been validated against a byte-matching decomp ELF.
- `generated/cart`, `generated/bios`: private ignored local translations kept
  for development/study, never hand-edited, committed or included in player ZIPs.
- `recomp/`: player README and sanitized notices. UI stages eleven common/GBA
  assets; no copyrighted game box art is imported.
- `tools/`: provisioning, generator/host builds, regen, local packaging, bounded
  diagnostics and allowlisted release tooling.
- `docs/`: lasting design, compatibility, licenses and release identities.
  Agent prompts and chronological handoff logs stay local.

Player startup opens the portable launcher, remembers verified paths/settings
and starts windowed runtime. Saves live beside the EXE. Runtime compilation
defaults OFF, interpreter fallback remains, and players need no compiler.

Release copies EXE/DLLs, launcher assets, licenses/notices, player README and hash
manifest only. It strips debug data and audits stage and ZIP; private assets,
saves, generated/build/decomp output, debug data and developer paths are excluded.
Existing versioned output is preserved. Compatibility and frozen identity are in
COMPATIBILITY.md and RELEASE_v0.1.0-preview.md. Further gameplay, coverage,
strict-static and native-decomp development are outside this freeze.
