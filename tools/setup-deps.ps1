$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$frameworkPin = Get-Content "$root\docs\FRAMEWORK_PIN.json" -Raw | ConvertFrom-Json
$engine = Join-Path $root 'gbarecomp'
if (-not (Test-Path "$engine\.git")) { throw 'Initialize the gbarecomp submodule before setup: git submodule update --init gbarecomp' }
$engineHead = & git -c "safe.directory=$($engine.Replace('\','/'))" -C $engine rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or $engineHead -ne $frameworkPin.commit) { throw 'Framework pin mismatch; preserve local changes' }
$priorPath = $env:PATH
try {
    $gitExe = (Get-Command git).Source
    $gitRoot = Split-Path -Parent (Split-Path -Parent $gitExe)
    if (Test-Path "$gitRoot\usr\bin") { $env:PATH = "$gitRoot\usr\bin;$env:PATH" }
    & git -c "safe.directory=$($engine.Replace('\','/'))" -C $engine submodule update --init external/arm-recomp-core external/recomp-net external/rbengine
    if ($LASTEXITCODE -ne 0) { throw 'Framework dependency initialization failed' }
} finally { $env:PATH = $priorPath }
$toml = Join-Path $root '.deps\tomlplusplus'
if (-not (Test-Path "$toml\.git")) {
    & git clone $frameworkPin.tomlplusplus_repository $toml
    if ($LASTEXITCODE -ne 0) { throw 'toml++ clone failed' }
    & git -c "safe.directory=$($toml.Replace('\','/'))" -C $toml checkout --detach $frameworkPin.tomlplusplus_commit
    if ($LASTEXITCODE -ne 0) { throw 'toml++ checkout failed' }
}
$tomlHead = & git -c "safe.directory=$($toml.Replace('\','/'))" -C $toml rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or $tomlHead -ne $frameworkPin.tomlplusplus_commit) { throw 'toml++ pin mismatch' }
Write-Host "GBARecomp pinned: $engineHead; toml++ pinned: $tomlHead"
$ui = Join-Path $root 'recomp-ui'
if (-not (Test-Path "$ui\.git")) { throw 'Initialize recomp-ui: git submodule update --init recomp-ui' }
$uiHead = & git -c "safe.directory=$($ui.Replace('\','/'))" -C $ui rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or $uiHead -ne $frameworkPin.recomp_ui_commit) { throw 'recomp-ui pin mismatch' }
Write-Host "recomp-ui pinned: $uiHead"
$dep = "$root\third_party\mf"
$pin = Get-Content "$root\docs\DECOMP_PIN.json" -Raw | ConvertFrom-Json
if (-not (Test-Path "$dep\.git")) {
    & git clone $pin.repository $dep
    if ($LASTEXITCODE -ne 0) { throw 'MF clone failed' }
    & git -c "safe.directory=$($dep.Replace('\','/'))" -C $dep checkout --detach $pin.commit
    if ($LASTEXITCODE -ne 0) { throw 'MF checkout failed' }
}
$actual = & git -c "safe.directory=$($dep.Replace('\','/'))" -C $dep rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or $actual -ne $pin.commit) { throw 'Existing decomp pin mismatch; preserve local changes' }
Write-Host "MF decomp pinned: $actual"
