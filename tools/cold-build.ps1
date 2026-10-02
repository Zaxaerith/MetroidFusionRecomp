param([switch]$CleanOnly)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$prefix = $root.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
foreach ($relative in @('build', 'recomp_cache')) {
    $target = [IO.Path]::GetFullPath((Join-Path $root $relative))
    if (-not $target.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw "Cleanup target escaped project: $target" }
    if (Test-Path -LiteralPath $target) {
        $item = Get-Item -LiteralPath $target
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Refusing cleanup of reparse point: $target" }
        Remove-Item -LiteralPath $target -Recurse -Force
    }
}
if ($CleanOnly) { return }
& "$PSScriptRoot\build-generator.ps1"
& "$PSScriptRoot\regen.ps1"
& "$PSScriptRoot\build-host.ps1"
