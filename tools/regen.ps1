param([string]$Bios = "$PSScriptRoot\..\..\gbarecomp-cli-windows-x86_64\gbabios\gba_bios.bin", [switch]$NoSymbols)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$rom = Join-Path $root 'Metroid Fusion (USA).gba'
if ((Get-FileHash -LiteralPath $rom -Algorithm SHA1).Hash -ne 'ca33f4348c2c05dd330d37b97e2c5a69531dfe87') { throw 'ROM SHA1 mismatch' }
$bytes = [IO.File]::ReadAllBytes($rom)
if ([Text.Encoding]::ASCII.GetString($bytes,172,4) -ne 'AMTE') { throw 'ROM game code mismatch' }
if ((Get-FileHash -LiteralPath $Bios -Algorithm SHA1).Hash -ne '300c20df6731a33952ded8c436f7f186d25d3492') { throw 'BIOS SHA1 mismatch' }
New-Item -ItemType Directory -Force -Path "$root\logs" | Out-Null
$tool = "$root\build\host\framework\gba_recompile.exe"
if (-not (Test-Path -LiteralPath $tool)) {
    $tool = "$root\build\generator\gba_recompile.exe"
}
if (-not (Test-Path -LiteralPath $tool)) { throw 'Run tools/build-generator.ps1 first' }
$cartArgs = @('--rom', $rom, '--config', "$root\game.toml")
if (-not $NoSymbols) {
    $cartArgs += @('--config', "$root\symbols\AMTE_symbols.toml", '--symbols', "$root\symbols\imported_symbols.tsv", '--data-symbols', "$root\symbols\imported_data_symbols.tsv")
}
$cartArgs += @('--out', "$root\generated\cart", '--max-functions', '65536')
$ErrorActionPreference = 'Continue'
& $tool @cartArgs *> "$root\logs\regen-cart.log"
$ErrorActionPreference = 'Stop'
if ($LASTEXITCODE -ne 0) { throw 'Cart regen failed; see logs/regen-cart.log' }
$ErrorActionPreference = 'Continue'
& $tool --bios $Bios --config "$root\gbarecomp\bios\gba_bios.toml" --out "$root\generated\bios" *> "$root\logs\regen-bios.log"
$ErrorActionPreference = 'Stop'
if ($LASTEXITCODE -ne 0) { throw 'BIOS regen failed; see logs/regen-bios.log' }
