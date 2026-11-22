# Compila a DLL Cafe Smooth sem instalar nada no jogo.
# Requer Git + MinGW-w64 (gcc, g++) no PATH e Windows x64.
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$deps = Join-Path $root "third_party"
$build = Join-Path $root ".build"
$ld = Join-Path $deps "libdeflate-1.23"
$mi = Join-Path $deps "mimalloc-2.1.7"
$native = Join-Path $root "native_plugin"
New-Item -ItemType Directory -Force -Path $deps,$build | Out-Null
function Check-LastExit([string]$step) {
    if ($LASTEXITCODE -ne 0) { throw ("Falha na etapa " + $step + ": " + $LASTEXITCODE) }
    Write-Host ("OK: " + $step)
}
foreach ($dep in @(
    @{ Path=$ld; Url="https://github.com/ebiggers/libdeflate.git"; Tag="v1.23" },
    @{ Path=$mi; Url="https://github.com/microsoft/mimalloc.git"; Tag="v2.1.7" }
)) {
    if (!(Test-Path -LiteralPath $dep.Path)) {
        & git clone --depth 1 --branch $dep.Tag $dep.Url $dep.Path
        Check-LastExit "git-clone"
    }
}
$common = @("-O3","-march=x86-64","-DNDEBUG")
$zflags = @("-DLIBDEFLATE_ASSEMBLER_DOES_NOT_SUPPORT_AVX512VNNI","-I$ld","-I$ld\lib")
& gcc @common @zflags -c "$ld\lib\utils.c" -o "$build\ld_utils.o"
Check-LastExit "libdeflate utils"
& gcc @common @zflags -c "$ld\lib\x86\cpu_features.c" -o "$build\ld_cpu.o"
Check-LastExit "libdeflate cpu"
& gcc @common @zflags -c "$ld\lib\deflate_decompress.c" -o "$build\ld_decomp.o"
Check-LastExit "libdeflate decompress"
& gcc @common "-I$mi\include" "-DMI_STATIC_LIB=1" -c "$mi\src\static.c" -o "$build\mimalloc_static.o"
Check-LastExit "mimalloc"
& g++ "-std=c++20" @common "-fno-exceptions" "-fno-rtti" "-I$native" "-I$ld" "-I$mi\include" -c "$native\dinput8.cpp" -o "$build\cafe_smooth.o"
Check-LastExit "codigo nativo"
$out = Join-Path $build "dinput8-built.dll"
& g++ -shared "-O3" "-s" "-static" "-static-libgcc" "-static-libstdc++" -o $out "$build\cafe_smooth.o" "$build\mimalloc_static.o" "$build\ld_utils.o" "$build\ld_cpu.o" "$build\ld_decomp.o" "$native\dinput8.def" -lwinmm -lshell32 -lole32 -ladvapi32 -lbcrypt -lpsapi
Check-LastExit "link da DLL"
Write-Host ("CANDIDATO: " + $out)
Write-Host ("SHA256: " + (Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash)
Write-Host "A DLL compilada permanece em .build e NAO substituiu a DLL do jogo."
