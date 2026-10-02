param([string]$Version = '0.1.0-preview', [string]$Python = 'python', [string]$Toolchain = $env:MINGW_ROOT, [switch]$SkipBuild)
$ErrorActionPreference = 'Stop'
if (-not $Toolchain) { $Toolchain = Split-Path -Parent (Split-Path -Parent (Get-Command gcc -ErrorAction Stop).Source) }
if ($Version -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$') { throw 'Invalid release version' }
$root = Split-Path -Parent $PSScriptRoot
$pin = Get-Content "$root/docs/FRAMEWORK_PIN.json" -Raw | ConvertFrom-Json
foreach ($entry in @(@('gbarecomp', $pin.commit), @('recomp-ui', $pin.recomp_ui_commit))) {
    $dep = Join-Path $root $entry[0]
    $head = & git -c "safe.directory=$($dep.Replace('\','/'))" -C $dep rev-parse HEAD
    if ($LASTEXITCODE -ne 0 -or $head -ne $entry[1]) { throw "Pin mismatch: $dep" }
    $changes = & git -c "safe.directory=$($dep.Replace('\','/'))" -C $dep status --porcelain --untracked-files=no
    if ($LASTEXITCODE -ne 0 -or $changes) { throw "Dependency has tracked changes: $dep" }
}
if (-not $SkipBuild) { & "$PSScriptRoot/build-host.ps1" -Toolchain $Toolchain }
$source = Join-Path $root 'build/host'
$stage = Join-Path $root "release-stage/MetroidFusionRecomp-windows-x64-v$Version"
$zip = "$stage.zip"
if ((Test-Path -LiteralPath $stage) -or (Test-Path -LiteralPath $zip)) { throw 'Release output exists; use a new version to preserve it' }
$files = @('MetroidFusionRecomp.exe', 'SDL2.dll', 'libgcc_s_seh-1.dll', 'libstdc++-6.dll', 'libwinpthread-1.dll')
foreach ($name in $files) { if (-not (Test-Path "$source/$name")) { throw "Missing binary: $name" } }
New-Item -ItemType Directory -Force -Path "$stage/licenses" | Out-Null
foreach ($name in $files) {
    Copy-Item -LiteralPath "$source/$name" -Destination "$stage/$name"
    $ErrorActionPreference = 'Continue'
    & "$Toolchain/bin/strip.exe" --strip-debug "$stage/$name"
    $result = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($result -ne 0) { throw "Strip failed: $name" }
}
Copy-Item -LiteralPath "$source/assets" -Destination "$stage/assets" -Recurse
Copy-Item -LiteralPath "$root/LICENSE" -Destination "$stage/LICENSE"
Copy-Item -LiteralPath "$root/recomp/player-README.md" -Destination "$stage/README.md"
Copy-Item -LiteralPath "$root/recomp/player-NOTICES.md" -Destination "$stage/THIRD_PARTY_NOTICES.md"
$licenses = @{
    'GBARecomp.txt' = "$root/gbarecomp/LICENSE";
    'RecompUI.txt' = "$root/recomp-ui/LICENSE";
    'ImGui.txt' = "$root/recomp-ui/src/third_party/imgui/LICENSE.txt";
    'MF-Decomp.txt' = "$root/docs/MF_DECOMP_LICENSE.txt";
    'ArmRecompCore.txt' = "$root/gbarecomp/external/arm-recomp-core/LICENSE";
    'SDL2.txt' = "$root/../_sdl2/SDL2-2.32.8/LICENSE.txt";
    'GCC-GPL3.txt' = "$Toolchain/licenses/gcc/COPYING3";
    'GCC-Runtime-Exception.txt' = "$Toolchain/licenses/gcc/COPYING.RUNTIME";
    'GCC-LGPL3.txt' = "$Toolchain/licenses/gcc/COPYING3.LIB";
    'MinGW-Runtime.txt' = "$Toolchain/licenses/mingw-w64/COPYING.MinGW-w64-runtime.txt";
    'Font-Notices.txt' = "$root/recomp-ui/assets/common/fonts/NOTICE.md";
    'Image-Notices.txt' = "$root/recomp-ui/assets/common/img/NOTICE.md"
}
foreach ($name in $licenses.Keys) { Copy-Item -LiteralPath $licenses[$name] -Destination "$stage/licenses/$name" }
Get-ChildItem -LiteralPath "$root/docs/licenses" -File | Copy-Item -Destination "$stage/licenses"
$manifest = Get-ChildItem -LiteralPath $stage -Recurse -File | Sort-Object FullName | ForEach-Object {
    [PSCustomObject]@{file=$_.FullName.Substring($stage.Length+1).Replace('\','/'); bytes=$_.Length; sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}
}
$manifest | ConvertTo-Json | Set-Content -LiteralPath "$stage/manifest.json" -Encoding utf8
& $Python "$PSScriptRoot/audit-release.py" $stage
if ($LASTEXITCODE -ne 0) { throw 'Stage audit failed' }
Compress-Archive -Path "$stage/*" -DestinationPath $zip -CompressionLevel Optimal
& $Python "$PSScriptRoot/audit-release.py" $zip
if ($LASTEXITCODE -ne 0) { throw 'ZIP audit failed' }
Write-Host "Release ZIP: $zip"
