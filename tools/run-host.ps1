param([int]$Frames = 0, [string]$State, [string]$Replay, [switch]$BridgeOnly, [switch]$AudioProbe, [string]$Toolchain = $env:MINGW_ROOT)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$hostExe = Join-Path $root 'dist\MetroidFusionRecomp.exe'
if (-not (Test-Path -LiteralPath $hostExe)) { $hostExe = Join-Path $root 'build\host\MetroidFusionRecomp.exe' }
if (-not (Test-Path -LiteralPath $hostExe)) { throw 'Host EXE missing. Run tools/cold-build.ps1 or Play.cmd first.' }
# Validate optional paths before changing the caller environment.
$replayPath = if ($Replay) { (Resolve-Path -LiteralPath $Replay).Path } else { $null }
$statePath = if ($State) { (Resolve-Path -LiteralPath $State).Path } else { $null }
$launchArgs = @('--window', '--rom', "$root\Metroid Fusion (USA).gba", '--bios', "$root\..\gbarecomp-cli-windows-x86_64\gbabios\gba_bios.bin", "$root\game.toml")
if ($Frames -gt 0) { $launchArgs += @('--frames', "$Frames", '--dump-png', "$root\logs\window-smoke.png") }
if ($statePath) { $launchArgs += @('--load-state', $statePath) }
$names = @('PATH', 'GBARECOMP_HEAL_CXX', 'GBARECOMP_SELFHEAL_RECOMPILE', 'GBARECOMP_INPUT_REPLAY', 'GBARECOMP_AUDIO_DIRECT', 'GBARECOMP_AUDIO_PROBE')
$prior = @{}
foreach ($name in $names) { $prior[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
$pushed = $false
try {
    if ($Toolchain) {
        $env:PATH = "$Toolchain\bin;$env:PATH"
        $env:GBARECOMP_HEAL_CXX = "$Toolchain\bin\g++.exe"
    } else {
        $compiler = Get-Command g++ -ErrorAction SilentlyContinue
        if ($compiler) { $env:GBARECOMP_HEAL_CXX = $compiler.Source }
    }
    $env:GBARECOMP_INPUT_REPLAY = $replayPath
    if ($BridgeOnly) { $env:GBARECOMP_SELFHEAL_RECOMPILE = '0' }
    if ($AudioProbe) { $env:GBARECOMP_AUDIO_DIRECT = '1'; $env:GBARECOMP_AUDIO_PROBE = '1' }
    New-Item -ItemType Directory -Force -Path "$root\logs" | Out-Null
    Push-Location $root
    $pushed = $true
    # Windows PowerShell 5.1 wraps native stderr as ErrorRecords. These
    # diagnostics belong in the log; only the native exit code is failure.
    $ErrorActionPreference = 'Continue'
    & $hostExe @launchArgs *> "$root\logs\window-run.log"
    $hostExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($hostExit -ne 0) { throw 'Host failed; see logs/window-run.log' }
} finally {
    if ($pushed) { Pop-Location }
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $prior[$name], 'Process') }
}
