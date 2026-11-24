#requires -Version 5.1
# Instalador com duplo clique para assinantes da Steam Workshop.
param([string]$PastaJogo="",[switch]$Elevado,[switch]$Simular)
$ErrorActionPreference="Stop"
$base=(Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$installer=Join-Path $PSScriptRoot "instalar_local.ps1"

function IsDST([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return $false }
  (Test-Path -LiteralPath (Join-Path $p "mods") -PathType Container) -and
  (Test-Path -LiteralPath (Join-Path $p "bin64") -PathType Container)
}
function FindDST {
  $roots=[System.Collections.Generic.List[string]]::new()
  $add = {
    param([string]$folder)
    if ([string]::IsNullOrWhiteSpace($folder)) { return }
    $folder=$folder.Trim().Trim('"').Replace("\\","\")
    if ((Test-Path -LiteralPath $folder -PathType Container) -and -not ($roots -contains $folder)) {
      $roots.Add($folder)
    }
  }
  foreach ($key in @("HKCU:\Software\Valve\Steam","HKLM:\SOFTWARE\WOW6432Node\Valve\Steam","HKLM:\SOFTWARE\Valve\Steam")) {
    try {
      $reg=Get-ItemProperty -Path $key -ErrorAction Stop
      & $add $reg.SteamPath
      & $add $reg.InstallPath
    } catch {}
  }
  & $add (Join-Path ([Environment]::GetFolderPath("ProgramFilesX86")) "Steam")
  & $add (Join-Path ([Environment]::GetFolderPath("ProgramFiles")) "Steam")
  foreach($drive in (Get-PSDrive -PSProvider FileSystem)) {
    foreach($suffix in @("SteamLibrary","Steam","Program Files (x86)\Steam")) {
      & $add (Join-Path $drive.Root $suffix)
    }
  }
  $libraries=[System.Collections.Generic.List[string]]::new()
  foreach($root in $roots) {
    if (-not ($libraries -contains $root)) {$libraries.Add($root)}
    $vdf=Join-Path $root "steamapps\libraryfolders.vdf"
    if (Test-Path -LiteralPath $vdf -PathType Leaf) {
      $contents=Get-Content -LiteralPath $vdf -Raw -Encoding UTF8
      foreach($match in [regex]::Matches($contents,'(?im)^\s*"path"\s*"([^"]+)"')) {
        $path=$match.Groups[1].Value.Replace("\\","\")
        if ((Test-Path -LiteralPath $path -PathType Container) -and -not ($libraries -contains $path)) {
          $libraries.Add($path)
        }
      }
    }
  }
  $games=[System.Collections.Generic.List[string]]::new()
  foreach($lib in $libraries) {
    $candidate=Join-Path $lib "steamapps\common\Don't Starve Together"
    if ((IsDST $candidate) -and -not ($games -contains $candidate)) {$games.Add($candidate)}
  }
  if ($games.Count -eq 1) {return $games[0]}
  if ($games.Count -gt 1) {
    Write-Host "Foram encontradas varias instalacoes do DST:"
    for($i=0;$i -lt $games.Count;$i++){Write-Host ("{0}. {1}" -f ($i+1),$games[$i])}
    $idx=0
    $answer=Read-Host "Digite o numero da pasta correta"
    if ([int]::TryParse($answer,[ref]$idx) -and $idx -ge 1 -and $idx -le $games.Count) {
      return $games[$idx-1]
    }
    throw "Escolha invalida. Nenhum arquivo foi instalado."
  }
  Write-Host "Nao encontrei o DST automaticamente. Abra Steam > Biblioteca > DST > Propriedades > Arquivos instalados > Procurar."
  $manual=(Read-Host "Cole o caminho da pasta do jogo").Trim().Trim('"')
  if (!(IsDST $manual)){throw "Pasta invalida. Confira se contem mods e bin64."}
  return $manual
}
function CanWrite([string]$folder) {
  $probe=Join-Path $folder (".qps_perm_"+[guid]::NewGuid().ToString("N")+".tmp")
  try {
    $stream=[System.IO.File]::Open($probe,[System.IO.FileMode]::CreateNew,
       [System.IO.FileAccess]::Write,[System.IO.FileShare]::None)
    $stream.Dispose()
    Remove-Item -LiteralPath $probe -Force -ErrorAction Stop
    return $true
  } catch {
    Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
    return $false
  }
}
try {
  Write-Host "=== DESBLOQUEAR QPS - INSTALAR DLL ===" -ForegroundColor Cyan
  Write-Host "So instala o complemento da Workshop. Nao duplica o mod."
  if (Get-Process "dontstarve_steam_x64" -ErrorAction SilentlyContinue) {
    throw "Feche o Don't Starve Together antes de instalar."
  }
  foreach($f in @("bin64\dinput8.dll","bin64\dst_fps.ini","tools\instalar_local.ps1")) {
    if (!(Test-Path -LiteralPath (Join-Path $base $f) -PathType Leaf)) {
      throw "Falta $f. Extraia TODO o ZIP antes de executar o arquivo .bat."
    }
  }
  $game=if (IsDST $PastaJogo) {$PastaJogo} else {FindDST}
  if (!(IsDST $game)) {throw "Nao encontrei uma pasta valida do DST."}
  Write-Host "DST encontrado: $game" -ForegroundColor Green
  $bin=Join-Path $game "bin64"
  $oldDll=Join-Path $bin "dinput8.dll"
  if (Test-Path -LiteralPath $oldDll -PathType Leaf) {
    $h1=(Get-FileHash -LiteralPath $oldDll -Algorithm SHA256).Hash
    $h2=(Get-FileHash -LiteralPath (Join-Path $base "bin64\dinput8.dll") -Algorithm SHA256).Hash
    if ($h1 -ne $h2 -and $h1 -ne "2fb50ae2a8a16bf96b238b09de02b209cc113aef2760dfb383643950e642765e" -and $h1 -ne "080AD8F4AA5A25A2DF8EDE6B4E9AF1B20CCFCDC1033B6AC4E10BA13F5A8D50B4" -and $h1 -ne "9062d7198d3791958c74ae96a9bfdf4e80e1df82e40d7973cacd10308d0863dd" -and $h1 -ne "64d47e0188734069535b9d0b4de70099ac7caf377ba78b8e3c58d2d3884eb5c8") {
      throw "Existe outra dinput8.dll, diferente. Por seguranca, nenhum arquivo foi alterado. Verifique a origem e faca backup."
    }
  }
  if ($Simular) {
    & $installer -SomenteDLL -PastaJogo $game
    Write-Host "Simulacao concluida, sem instalar." -ForegroundColor Green
    exit 0
  }
  if (!$Elevado -and !(CanWrite $bin)) {
    Write-Host "O Windows vai pedir autorizacao de administrador para gravar na pasta do jogo." -ForegroundColor Yellow
    $powershell=Join-Path $PSHOME "powershell.exe"
    $args=@("-NoLogo","-NoProfile","-ExecutionPolicy","Bypass","-STA",
       "-File",('"'+$PSCommandPath+'"'),"-PastaJogo",('"'+$game+'"'),"-Elevado")
    $child=Start-Process -FilePath $powershell -Verb RunAs -ArgumentList $args -Wait -PassThru
    if ($child.ExitCode -ne 0){throw "Instalacao cancelada ou falhou na janela de administrador."}
    exit 0
  }
  if (!(CanWrite $bin)){throw "Nao foi possivel obter permissao de gravacao em bin64."}
  & $installer -SomenteDLL -Aplicar -PastaJogo $game
  Write-Host "INSTALADO COM SUCESSO! Abra o DST e ative Desbloquear QPS nos Mods de Cliente." -ForegroundColor Green
  exit 0
} catch {
  Write-Host ("ERRO: "+$_.Exception.Message) -ForegroundColor Red
  Write-Host "Os arquivos do seu jogo nao devem ser substituidos sem confirmacao."
  exit 1
}
