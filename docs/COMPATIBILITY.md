# Compatibility — v0.1.0-preview

Experimental Preview. Full-game compatibility is not exhaustively tested.
Interpreter fallback remains. Fully static/native execution is not claimed.
Only exact USA AMTE ROM and retail BIOS identities are supported.

## Frozen preview evidence

Existing validation, not rerun during the source freeze:

- Stage/ZIP: 35 allowlisted files; 34 manifest hashes (excluding itself).
- Extracted ZIP runs with a system-only PATH, unrelated working directory,
  no developer game.toml/compiler; private assets referenced externally.
- Hidden first-launch and cached-launch renderer startup/quit pass using CI
  hooks, without desktop automation or visual inspection.
- Launcher-model contract passes valid inputs, wrong/missing input rejection,
  recovery, caches, settings and preservation of unrelated settings.
- 600-frame title: exit 0, baseline image match; NOT_STATIC, 11 misses,
  3,784,558 interpreted instructions, zero native calls/healing failures.
- 1,800-frame original-save fresh load/input replay: exit 0, baseline image
  match; NOT_STATIC, 16 misses, 18,287,917 interpreted instructions,
  zero native calls/healing failures. Wrong ROM/BIOS production calls reject.
- Isolated tests use copied SRAM and preserve the player's file. Before
  isolation, earlier boot/load tests wrote normal SRAM metadata; exact-byte
  preservation is not claimed for those earlier runs.

RELEASE_TEST_RESULT.json records bounded release evidence. Local generated output
is 151,119,795 bytes and 14 translation units: 22,809 cartridge functions and
770 BIOS functions. These counts are not execution coverage percentages.

## Historical and unverified scope

Earlier framework-baseline acceptance passed original New Game, move/jump/shoot,
room transitions, first Hornoad combat, save/exit/fresh-process load, and an audio
probe with nonzero PCM and zero reported underruns. The long route/audio checks
were not repeated on this frozen pin; they are historical evidence only.

Human file-picker interaction, physical keyboard/gamepad controls, listening,
visual layout inspection, full-game compatibility, fully static execution and
byte-matching decomp ELF provenance remain unverified. Symbols are source metadata;
9 conflicting/overlapping addresses are excluded. No native-decomp implementation
is linked into this preview.
