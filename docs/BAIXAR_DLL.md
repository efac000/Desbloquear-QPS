## Mais fácil: baixar, extrair e executar

1. Baixe o [ZIP pequeno com DLL + INI](https://github.com/eduardonnn/Desbloquear-QPS/releases/latest/download/Desbloquear-QPS-DLL-Windows-x64.zip).
2. Extraia o ZIP completo, abra a pasta Desbloquear QPS e dê **dois cliques no arquivo INSTALAR DLL.bat**.
3. Depois da mensagem de sucesso, abra o DST e habilite o mod nos Mods de Cliente.

O instalador encontra automaticamente a pasta do jogo e solicita permissão de administrador apenas quando necessária. Ele preserva o INI e interrompe se encontrar outra DLL diferente. Feche o jogo antes de executar.

**A instalação manual mostrada abaixo é opcional.**

# Baixe somente a DLL do Desbloquear QPS

Esta página é para quem **já assinou o mod pela Steam Workshop**. Você precisa instalar separadamente o complemento nativo para Windows 64 bits.

## Baixar

**[DOWNLOAD — DLL + INI (ZIP pequeno)](https://github.com/eduardonnn/Desbloquear-QPS/releases/latest/download/Desbloquear-QPS-DLL-Windows-x64.zip)**

Links individuais: [dinput8.dll](https://github.com/eduardonnn/Desbloquear-QPS/releases/latest/download/dinput8.dll) · [dst_fps.ini](https://github.com/eduardonnn/Desbloquear-QPS/releases/latest/download/dst_fps.ini).

## Instalar manualmente

1. Feche Don't Starve Together.
2. Extraia o ZIP e abra a pasta `Desbloquear QPS/bin64`.
3. Copie `dinput8.dll` para a pasta `bin64` do jogo.
4. Copie `dst_fps.ini` para a mesma pasta **somente se não houver um arquivo com esse nome**.
5. No jogo, ative **Desbloquear QPS** nos Mods de Cliente.

**Caminho habitual:** `C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together\bin64`

Se sua Steam estiver em outra unidade, use Steam → Biblioteca → Don't Starve Together → Propriedades → Arquivos instalados → Procurar e entre na pasta `bin64`.

**Atenção:** não coloque a DLL em `mods` nem dentro de `bin64\bin64`. Se já existir outra `dinput8.dll`, não a substitua sem saber a origem e fazer backup.

## Instalador opcional incluído no ZIP

Abra o PowerShell na pasta extraída. Simulação, sem alterar arquivos:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\instalar_local.ps1 -SomenteDLL

Para instalar após conferir os caminhos:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\instalar_local.ps1 -SomenteDLL -Aplicar

O instalador faz backup, preserva seu INI e bloqueia conflitos de DLL.

**Não instale uma segunda cópia do mod** se já o assinou na Workshop. A DLL não aumenta a frequência física do monitor e a sincronização desativada pode causar `tearing`.

Ajuda: [guia completo](INSTALACAO.md) e [perguntas frequentes](FAQ.md).

**Link único que pode ser colocado na Steam Workshop:** https://github.com/eduardonnn/Desbloquear-QPS
