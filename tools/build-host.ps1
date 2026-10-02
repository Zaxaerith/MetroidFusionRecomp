param([int]$Jobs = 4, [string]$Toolchain = $env:MINGW_ROOT, [switch]$ConfigureOnly, [string]$SdlRoot = $env:SDL2_ROOT)
$ErrorActionPreference = 'Stop'
if (-not $Toolchain) { $Toolchain = Split-Path -Parent (Split-Path -Parent (Get-Command gcc -ErrorAction Stop).Source) }
$root = Split-Path -Parent $PSScriptRoot
$sdl = if ($SdlRoot) { $SdlRoot } else { "$root/../_sdl2/SDL2-2.32.8/x86_64-w64-mingw32" }
New-Item -ItemType Directory -Force -Path "$root/logs" | Out-Null
$ErrorActionPreference = 'Continue'
& cmake -S $root -B "$root/build/host" -G Ninja -DCMAKE_BUILD_TYPE=Release "-DGBARECOMP_ROOT=$root/gbarecomp" "-DGBARECOMP_TOMLPP_INCLUDE_DIR=$root/.deps/tomlplusplus" "-DCMAKE_C_COMPILER=$Toolchain/bin/gcc.exe" "-DCMAKE_CXX_COMPILER=$Toolchain/bin/g++.exe" "-DGBARECOMP_MINGW_RUNTIME_BIN=$Toolchain/bin" "-DSDL2_INCLUDE_DIR=$sdl/include/SDL2" "-DSDL2_LIBRARY=$sdl/lib/libSDL2.dll.a" "-DSDL2_DLL=$sdl/bin/SDL2.dll" *> "$root/logs/configure.log"
$ErrorActionPreference = 'Stop'
if ($LASTEXITCODE -ne 0) { throw 'Configure failed; see logs/configure.log' }
if ($ConfigureOnly) { return }
$ErrorActionPreference = 'Continue'
& cmake --build "$root/build/host" --target MetroidFusionRecomp --parallel $Jobs *> "$root/logs/build.log"
$ErrorActionPreference = 'Stop'
if ($LASTEXITCODE -ne 0) { throw 'Build failed; see logs/build.log' }
