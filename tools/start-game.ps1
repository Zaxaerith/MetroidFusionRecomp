param([switch]$SelfHeal, [int]$Frames = 0, [string]$Replay)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath (Join-Path $root 'dist\MetroidFusionRecomp.exe'))) {
    if (-not (Test-Path -LiteralPath (Join-Path $root 'build\host\MetroidFusionRecomp.exe'))) {
        Write-Host 'First launch: building MetroidFusionRecomp. Progress is written to logs/build.log.'
        & "$PSScriptRoot\cold-build.ps1"
    }
    & "$PSScriptRoot\package-local.ps1"
}
$runArgs = @{ Frames = $Frames; BridgeOnly = -not $SelfHeal }
if ($Replay) { $runArgs.Replay = $Replay }
& "$PSScriptRoot\run-host.ps1" @runArgs
