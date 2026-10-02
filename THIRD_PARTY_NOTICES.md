# Third-party notices

- Metroid Fusion decomp: https://github.com/metroidret/mf, commit `419e87c1c82515b05820caca009ef9ca5e8664b0`, MIT, Copyright 2025 YohannDR. Used as an address and implementation reference. License retained in `third_party/mf/LICENSE`; no upstream C/ASM implementation copied into execution integration yet. The diagnostic helper `tools/inspect-room.py` adapts the room RLE decoding algorithm from `src/room.c::RoomRleDecompress` under the same MIT attribution.
- GBARecomp: https://github.com/mstan/gbarecomp, pinned project submodule at `e3c834d399b66f5a823c2f0f9d878b62dc05d25a`, Copyright (c) 2026 Matthew Stanley, PolyForm Noncommercial License 1.0.0. See `gbarecomp/LICENSE` and its attribution files. Regeneration uses this checkout's generator and BIOS configuration.
- arm-recomp-core and other framework dependencies: see the framework's bundled licenses and notices.
- SDL2 2.32.8: existing adjacent development package, zlib license, see `_sdl2/SDL2-2.32.8/LICENSE.txt`.
- recomp-ui: https://github.com/mstan/recomp-ui, pin `6374aae201b930c97425718249f5d39b2275ca13`, MIT, Copyright 2026 Matthew Stanley. Includes Dear ImGui, font/image assets and their separate notices/licenses. Player package notices are maintained in `recomp/player-NOTICES.md`.
- Downloaded font-license texts in `docs/licenses/` come from google/fonts (Lato and Noto Sans Symbols 2 OFL) and hfg-gmuend/openmoji (CC BY-SA 4.0). Recomp-ui's asset notices are retained in player packages.

Full MF MIT text and framework license are preserved in `docs/MF_DECOMP_LICENSE.txt` and `docs/GBARECOMP_LICENSE.txt`.
Nintendo ROM/BIOS assets are supplied locally by the user and are not distributed.
