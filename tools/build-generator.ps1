param([int]$Jobs = 4, [string]$Toolchain = $env:MINGW_ROOT)
$ErrorActionPreference = 'Stop'
if (-not $Toolchain) { $Toolchain = Split-Path -Parent (Split-Path -Parent (Get-Command gcc -ErrorAction Stop).Source) }
$root = Split-Path -Parent $PSScriptRoot
New-Item -ItemType Directory -Force -Path "$root/logs" | Out-Null
$ErrorActionPreference = 'Continue'
& cmake -S "$root/gbarecomp" -B "$root/build/generator" -G Ninja -DCMAKE_BUILD_TYPE=Release "-DCMAKE_C_COMPILER=$Toolchain/bin/gcc.exe" "-DCMAKE_CXX_COMPILER=$Toolchain/bin/g++.exe" "-DGBARECOMP_TOMLPP_INCLUDE_DIR=$root/.deps/tomlplusplus" *> "$root/logs/configure-generator.log"
$result = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($result -ne 0) { throw 'Generator configure failed; see logs/configure-generator.log' }
$ErrorActionPreference = 'Continue'
& cmake --build "$root/build/generator" --target gba_recompile --parallel $Jobs *> "$root/logs/build-generator.log"
$result = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
if ($result -ne 0) { throw 'Generator build failed; see logs/build-generator.log' }
