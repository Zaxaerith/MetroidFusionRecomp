# Frozen v0.1.0-preview — 2026-10-02

| Identity | Frozen value |
| --- | --- |
| MF USA ROM SHA-1 / AMTE | `ca33f4348c2c05dd330d37b97e2c5a69531dfe87` |
| Retail BIOS SHA-1 | `300c20df6731a33952ded8c436f7f186d25d3492` |
| gbarecomp gitlink/pin | `e3c834d399b66f5a823c2f0f9d878b62dc05d25a` |
| recomp-ui gitlink/pin | `6374aae201b930c97425718249f5d39b2275ca13` |
| metroidret/mf reference pin | `419e87c1c82515b05820caca009ef9ca5e8664b0` |
| ZIP SHA-256 | `147654f14922851a877ddb3c26bb9b23f842202fc41684ba78c24ffe979e8c49` |
| ZIP bytes | 17,540,329 |

Asset: `MetroidFusionRecomp-windows-x64-v0.1.0-preview.zip`, retained under
ignored `release-stage/`. Intended for separate user upload as a GitHub Release
asset, never a source commit. The validated ZIP/executable is unchanged during
this freeze; source cleanup only replaces machine-specific helper defaults and
consolidates documentation. No build or gameplay test is required for this cleanup.

Generated C++ remains local and gitignored, excluded from source commits and ZIP.
Agent prompts, handoff logs, private assets, local binaries and extraction tests
remain local too. The source repository had no previous commits at freeze;
no contaminated release history was found and no orphan rewrite was needed.

Compatibility evidence/limits are in COMPATIBILITY.md. This freezes Experimental
Preview delivery, not full-game/native acceptance. No new gameplay, coverage,
strict-static or native-decomp work is part of this freeze. A local commit named
`Prepare v0.1.0-preview release` is created after source/index/history audit.
No push or GitHub Release creation is authorized.
