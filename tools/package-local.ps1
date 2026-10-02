$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root 'build\host'
$destination = Join-Path $root 'dist'
$files = @('MetroidFusionRecomp.exe', 'SDL2.dll', 'libgcc_s_seh-1.dll', 'libstdc++-6.dll', 'libwinpthread-1.dll')
foreach ($name in $files) {
    if (-not (Test-Path -LiteralPath (Join-Path $source $name))) { throw "Build output missing: $name" }
}
New-Item -ItemType Directory -Force -Path $destination | Out-Null
if (-not (Test-Path "$source\assets")) { throw 'Launcher assets missing from build output' }
Copy-Item -LiteralPath "$source\assets" -Destination $destination -Recurse -Force
$manifest = foreach ($name in $files) {
    $target = Join-Path $destination $name
    Copy-Item -LiteralPath (Join-Path $source $name) -Destination $target -Force
    [PSCustomObject]@{ file = $name; bytes = (Get-Item -LiteralPath $target).Length; sha256 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() }
}
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $destination 'manifest.json') -Encoding utf8
Write-Host "Local playable binaries: $destination"
