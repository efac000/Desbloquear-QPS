<#
Desbloquear QPS — instalador local seguro (Windows 64 bits).
Por padrão, apenas simula a operação. Use -Aplicar para gravar.
-SomenteDLL: ideal para quem já assinou o mod pela Steam Workshop.
-Nunca desativa outros mods nem altera as configurações pessoais.
#>
param(
    [switch]$Aplicar,
    [switch]$SomenteDLL,
    [switch]$PermitirOutraDLL,
    [string]$PastaJogo = "C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together"
)

$ErrorActionPreference = "Stop"
$raiz = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$pastaMods = Join-Path $PastaJogo "mods"
$pastaBin = Join-Path $PastaJogo "bin64"
$modDestino = Join-Path $pastaMods "desbloquear-qps"
$dllOrigem = Join-Path $raiz "bin64\dinput8.dll"
$iniOrigem = Join-Path $raiz "bin64\dst_fps.ini"
$dllDestino = Join-Path $pastaBin "dinput8.dll"
$iniDestino = Join-Path $pastaBin "dst_fps.ini"
$arquivosMod = @("modinfo.lua", "modmain.lua", "keybind.lua", "modicon.tex", "modicon.xml")
$pastasMod = @("shaders")

if (!(Test-Path -LiteralPath $pastaMods -PathType Container) -or
    !(Test-Path -LiteralPath $pastaBin -PathType Container)) {
    throw "Não encontrei as pastas mods e bin64. Confira -PastaJogo."
}
if (!(Test-Path -LiteralPath $dllOrigem -PathType Leaf) -or
    !(Test-Path -LiteralPath $iniOrigem -PathType Leaf)) {
    throw "Pacote incompleto: bin64/dinput8.dll ou bin64/dst_fps.ini ausente."
}
if (!$SomenteDLL) {
    foreach ($nome in $arquivosMod) {
        if (!(Test-Path -LiteralPath (Join-Path $raiz $nome) -PathType Leaf)) {
            throw "Arquivo do mod ausente: $nome"
        }
    }
    foreach ($nome in $pastasMod) {
        if (!(Test-Path -LiteralPath (Join-Path $raiz $nome) -PathType Container)) {
            throw "Pasta do mod ausente: $nome"
        }
    }
}
if (Get-Process "dontstarve_steam_x64" -ErrorAction SilentlyContinue) {
    throw "Feche o Don't Starve Together antes de executar o instalador."
}

$hashPacote = (Get-FileHash -LiteralPath $dllOrigem -Algorithm SHA256).Hash
$dllExistia = Test-Path -LiteralPath $dllDestino -PathType Leaf
$iniExistia = Test-Path -LiteralPath $iniDestino -PathType Leaf
$modExistia = Test-Path -LiteralPath $modDestino -PathType Container
$hashAnterior = if ($dllExistia) {
    (Get-FileHash -LiteralPath $dllDestino -Algorithm SHA256).Hash
} else { "" }
$mesmaDLL = $dllExistia -and ($hashAnterior -eq $hashPacote)

Write-Host "Desbloquear QPS — instalação Windows 64 bits"
Write-Host ("Modo: " + $(if ($SomenteDLL) { "somente complemento DLL (Workshop)" } else { "mod local e complemento DLL" }))
Write-Host "Destino do jogo: $PastaJogo"
Write-Host "DLL: $dllDestino"
Write-Host ("DLL existente coincide com a do pacote: " + $mesmaDLL)
Write-Host ("Configuração nativa existente será preservada: " + $iniExistia)
if ($SomenteDLL) {
    Write-Host "A pasta de mods não será alterada; use apenas a edição da Workshop."
} else {
    Write-Host "Mod local: $modDestino"
    Write-Host "Desative variantes antigas do HyperSmooth/Café Smooth pelo menu do DST."
}
if ($dllExistia -and !$mesmaDLL -and $hashAnterior -ne "2fb50ae2a8a16bf96b238b09de02b209cc113aef2760dfb383643950e642765e" -and $hashAnterior -ne "080AD8F4AA5A25A2DF8EDE6B4E9AF1B20CCFCDC1033B6AC4E10BA13F5A8D50B4" -and $hashAnterior -ne "9062d7198d3791958c74ae96a9bfdf4e80e1df82e40d7973cacd10308d0863dd" -and !$PermitirOutraDLL) {
    Write-Host "Já existe uma DLL diferente no jogo: $hashAnterior" -ForegroundColor Yellow
    Write-Host "Nova DLL: $hashPacote" -ForegroundColor Yellow
    throw "Conflito de DLL. Verifique o arquivo e, somente se autorizado, use -PermitirOutraDLL."
}
if (!$Aplicar) {
    Write-Host "SIMULAÇÃO aprovada: nenhum arquivo alterado. Acrescente -Aplicar para instalar." -ForegroundColor Cyan
    exit 0
}

$backupRoot = Join-Path ([Environment]::GetFolderPath("Desktop")) (
    "Desbloquear-QPS-backup-" + (Get-Date -Format "yyyyMMdd-HHmmss-fff") + "-" +
    ([guid]::NewGuid().ToString("N").Substring(0,8))
)
New-Item -ItemType Directory -Path $backupRoot -ErrorAction Stop | Out-Null
$backupDLL = Join-Path $backupRoot "dinput8-original.dll"
$backupINI = Join-Path $backupRoot "dst_fps-original.ini"
$backupMod = Join-Path $backupRoot "mod-original"
Write-Host "Backup desta instalação: $backupRoot"

# Captura o estado anterior antes de qualquer gravação.
if ($dllExistia) { Copy-Item -LiteralPath $dllDestino -Destination $backupDLL -ErrorAction Stop }
if ($iniExistia) { Copy-Item -LiteralPath $iniDestino -Destination $backupINI -ErrorAction Stop }
if (!$SomenteDLL -and $modExistia) {
    Copy-Item -LiteralPath $modDestino -Destination $backupMod -Recurse -Force -ErrorAction Stop
}
$modAlterado = $false
$dllAlterada = $false
$iniAlterado = $false

try {
    if (!$SomenteDLL) {
        $modAlterado = $true
        if (Test-Path -LiteralPath $modDestino) {
            Remove-Item -LiteralPath $modDestino -Recurse -Force -ErrorAction Stop
        }
        New-Item -ItemType Directory -Path $modDestino -ErrorAction Stop | Out-Null
        foreach ($nome in $arquivosMod) {
            Copy-Item -LiteralPath (Join-Path $raiz $nome) -Destination (Join-Path $modDestino $nome) -ErrorAction Stop
        }
        foreach ($nome in $pastasMod) {
            Copy-Item -LiteralPath (Join-Path $raiz $nome) -Destination (Join-Path $modDestino $nome) -Recurse -ErrorAction Stop
        }
    }
    if (!$mesmaDLL) {
        $dllAlterada = $true
        Copy-Item -LiteralPath $dllOrigem -Destination $dllDestino -Force -ErrorAction Stop
    }
    if (!$iniExistia) {
        $iniAlterado = $true
        Copy-Item -LiteralPath $iniOrigem -Destination $iniDestino -ErrorAction Stop
    }

    if ((Get-FileHash -LiteralPath $dllDestino -Algorithm SHA256).Hash -ne $hashPacote) {
        throw "A DLL copiada não passou na verificação SHA-256."
    }
    if (!$SomenteDLL) {
        foreach ($nome in $arquivosMod) {
            $h1 = (Get-FileHash -LiteralPath (Join-Path $raiz $nome) -Algorithm SHA256).Hash
            $h2 = (Get-FileHash -LiteralPath (Join-Path $modDestino $nome) -Algorithm SHA256).Hash
            if ($h1 -ne $h2) { throw "Falha de integridade no arquivo $nome" }
        }
        foreach ($nome in $pastasMod) {
            $fonteDir = Join-Path $raiz $nome
            foreach ($arquivo in (Get-ChildItem -LiteralPath $fonteDir -Recurse -File)) {
                $rel = $arquivo.FullName.Substring($raiz.Length + 1)
                $alvo = Join-Path $modDestino $rel
                if (!(Test-Path -LiteralPath $alvo -PathType Leaf)) { throw "Shader ausente: $rel" }
                $ha = (Get-FileHash -LiteralPath $arquivo.FullName -Algorithm SHA256).Hash
                $hb = (Get-FileHash -LiteralPath $alvo -Algorithm SHA256).Hash
                if ($ha -ne $hb) { throw "Falha de integridade do shader: $rel" }
            }
        }
    }
    Write-Host "Instalação concluída; integridade verificada." -ForegroundColor Green
    Write-Host "Backups preservados: $backupRoot"
    if ($SomenteDLL) {
        Write-Host "Abra o jogo e ative a edição da Steam Workshop."
    } else {
        Write-Host "Abra o jogo e ative Desbloquear QPS em Mods de Cliente."
    }
}
catch {
    $falha = $_
    Write-Warning ("Instalação interrompida: " + $falha.Exception.Message)
    Write-Warning "Tentando restaurar o estado anterior..."
    if ($modAlterado) {
        if (Test-Path -LiteralPath $modDestino) { Remove-Item -LiteralPath $modDestino -Recurse -Force -ErrorAction SilentlyContinue }
        if ($modExistia -and (Test-Path -LiteralPath $backupMod)) {
            Copy-Item -LiteralPath $backupMod -Destination $modDestino -Recurse -Force -ErrorAction Stop
        }
    }
    if ($dllAlterada) {
        if ($dllExistia -and (Test-Path -LiteralPath $backupDLL)) {
            Copy-Item -LiteralPath $backupDLL -Destination $dllDestino -Force -ErrorAction Stop
        } elseif (Test-Path -LiteralPath $dllDestino) {
            Remove-Item -LiteralPath $dllDestino -Force -ErrorAction Stop
        }
    }
    if ($iniAlterado -and !$iniExistia -and (Test-Path -LiteralPath $iniDestino)) {
        Remove-Item -LiteralPath $iniDestino -Force -ErrorAction Stop
    }
    throw ("Instalação cancelada; backups em: " + $backupRoot + ". Erro: " + $falha.Exception.Message)
}
