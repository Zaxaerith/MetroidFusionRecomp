# MetroidFusionRecomp — Experimental Preview

Extract the ZIP into a writable folder and run **MetroidFusionRecomp.exe**.
Select your own Metroid Fusion (USA) ROM and original GBA BIOS in the launcher,
then press Play. Valid paths and settings are remembered beside the EXE.
No PowerShell, compiler or code regeneration is needed to play.

Required ROM: AMTE, SHA-1 `ca33f4348c2c05dd330d37b97e2c5a69531dfe87`.
Required BIOS: 16 KiB, SHA-1 `300c20df6731a33952ded8c436f7f186d25d3492`.
Neither file is included. Modified ROMs and other regions are unsupported.

Keys: arrows = move, X = A/jump/confirm, Z = B/shoot, Enter = Start,
Right Shift = Select, C = L, V = R. Configure controls in the launcher.
Original SRAM saves are stored in `saves/metroid_fusion_usa.sav` beside the EXE.
Keep the whole extracted folder when updating or moving your installation.
If Skip Launcher is enabled, start the EXE with `--launcher` to reopen it.

This preview retains interpreter fallback and disables runtime compilation
by default. It is not fully static/native and has not been tested throughout
the entire game. Physical keyboard/gamepad interaction and listening have
not been accepted by automated tests. No automatic updates or downloads are
needed for this preview's game startup.

This is an unofficial fan project, unaffiliated with Nintendo. Supply your
own files; no ROM, BIOS or original game assets are distributed separately.
See LICENSE, THIRD_PARTY_NOTICES.md and licenses/ for component terms,
including GBARecomp's PolyForm Noncommercial 1.0.0 license.
