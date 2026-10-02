param([int]$Frames = 600, [string]$Replay, [switch]$BridgeOnly, [switch]$UseBuild, [string]$Bios = "$PSScriptRoot\..\..\gbarecomp-cli-windows-x86_64\gbabios\gba_bios.bin")
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$hostExe = Join-Path $root 'dist\MetroidFusionRecomp.exe'
if ($UseBuild -or -not (Test-Path -LiteralPath $hostExe)) { $hostExe = Join-Path $root 'build\host\MetroidFusionRecomp.exe' }
if (-not (Test-Path -LiteralPath $hostExe)) { throw 'Host EXE missing; build/stage local binaries first.' }
# Backend regression runs use a disposable copy; normal game boot/load writes
# SRAM metadata even without an explicit in-game save command.
New-Item -ItemType Directory -Force -Path "$root/logs" | Out-Null
$smokeSave = Join-Path $root 'logs\smoke-save.sav'
$playerSave = Join-Path $root 'saves\metroid_fusion_usa.sav'
if (Test-Path -LiteralPath $playerSave) { Copy-Item -LiteralPath $playerSave -Destination $smokeSave -Force }
elseif (Test-Path -LiteralPath $smokeSave) { Remove-Item -LiteralPath $smokeSave -Force }
$priorPath = $env:PATH
$priorHealCxx = $env:GBARECOMP_HEAL_CXX
$priorReplay = $env:GBARECOMP_INPUT_REPLAY
$priorHeal = $env:GBARECOMP_SELFHEAL_RECOMPILE
if ($Replay) { $env:GBARECOMP_INPUT_REPLAY = (Resolve-Path -LiteralPath $Replay).Path }
if ($BridgeOnly) { $env:GBARECOMP_SELFHEAL_RECOMPILE = '0' }
$compiler = Get-Command g++ -ErrorAction SilentlyContinue
if ($compiler) { $env:GBARECOMP_HEAL_CXX = $compiler.Source }
Push-Location $root
try {
    $ErrorActionPreference = 'Continue'
    & $hostExe --rom "$root\Metroid Fusion (USA).gba" --bios $Bios "$root\game.toml" --save $smokeSave --no-window --frames $Frames --dump-png "$root\logs\smoke.png" *> "$root\logs\run.log"
    $smokeExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($smokeExit -ne 0) { throw 'Smoke failed; see logs/run.log' }
} finally {
    Pop-Location
    $env:PATH = $priorPath
    $env:GBARECOMP_HEAL_CXX = $priorHealCxx
    $env:GBARECOMP_INPUT_REPLAY = $priorReplay
    $env:GBARECOMP_SELFHEAL_RECOMPILE = $priorHeal
}
