## Para quem instalou o mod pela Steam Workshop

1. Baixe o [ZIP pequeno da DLL + INI](https://github.com/efac000/Desbloquear-QPS/releases/latest/download/Desbloquear-QPS-DLL-Windows-x64.zip).
2. Extraia todos os arquivos e dê **dois cliques em INSTALAR DLL.bat**.
3. Autorize o Windows se necessário e espere a mensagem de sucesso.

O instalador encontra o DST e copia só a DLL e o INI sem criar outra versão do mod. **Feche o jogo primeiro.** Não substitui automaticamente uma DLL diferente de outro complemento.

As instruções manuais alternativas continuam abaixo.

# Instalação do Desbloquear QPS — passo a passo

O mod possui **duas partes distintas**: os scripts do cliente (obtidos pela Workshop ou pelo pacote local) e a DLL `dinput8.dll` (instalada manualmente no Windows). Para escolher FPS acima de 60, você precisa das duas partes.

## Primeiro: baixe os arquivos

Acesse [GitHub Releases](https://github.com/efac000/Desbloquear-QPS/releases/latest) e baixe **Desbloquear-QPS-v1.0.3-Completo.zip**. Extraia o arquivo ZIP; a pasta extraída se chama `Desbloquear QPS`.

A pasta contém, entre outros:

```text
Desbloquear QPS/
  modinfo.lua
  modmain.lua
  keybind.lua
  modicon.tex
  modicon.xml
  shaders/
  bin64/
    dinput8.dll
    dst_fps.ini
  tools/
    instalar_local.ps1
```

O instalador não altera o idioma do jogo nem configurações globais da Steam ou da NVIDIA.

## Caso A — Você instalou o mod pela Steam Workshop

Neste cenário **não instale outra cópia do mod localmente**. Instale apenas a DLL:

1. Feche o Don't Starve Together por completo.
2. Abra PowerShell dentro da pasta `Desbloquear QPS` extraída.
3. Execute a **simulação**:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\instalar_local.ps1 -SomenteDLL
   ```

4. Leia o resultado. Quando estiver correto, execute:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\instalar_local.ps1 -SomenteDLL -Aplicar
   ```

5. Abra o jogo, ative a versão **Desbloquear QPS** da Workshop em **Mods de Cliente** e aplique.

**Por que `-SomenteDLL`?** A assinatura Workshop já fornece os arquivos Lua e shaders. Instalar outra pasta local criaria duas variantes e poderia causar conflitos.

## Caso B — Você prefere instalar tudo manualmente

Com o jogo fechado, abra o PowerShell na pasta extraída:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\instalar_local.ps1
```

Esse primeiro comando é uma simulação. Para instalar de verdade:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\instalar_local.ps1 -Aplicar
```

Depois, ative **Desbloquear QPS** em **Mods de Cliente**. Não assine outra edição do mesmo mod simultaneamente na Workshop.

## Sua Steam fica em outra unidade?

Informe o caminho real da pasta do jogo:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\instalar_local.ps1 -SomenteDLL -Aplicar -PastaJogo "D:\SteamLibrary\steamapps\common\Don't Starve Together"
```

Apenas ajuste `D:\SteamLibrary...` para seu computador. O caminho padrão do instalador usa `C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together`.

## Instalação completamente manual (sem PowerShell)

1. Feche o DST.
2. Se usar a Workshop, deixe a pasta do mod com a Steam e copie **somente** `bin64/dinput8.dll` e `bin64/dst_fps.ini` do pacote para a pasta `bin64` do jogo.
3. Se não usar a Workshop, copie os arquivos `modinfo.lua`, `modmain.lua`, `keybind.lua`, `modicon.tex`, `modicon.xml` e a pasta `shaders/` para `Don't Starve Together\mods\desbloquear-qps`. Copie também os dois arquivos `bin64` para a pasta `bin64` do jogo.
4. **Faça backup primeiro** caso já existam arquivos chamados `dinput8.dll` ou `dst_fps.ini`. Nunca substitua uma DLL desconhecida sem avaliar o que ela faz.
5. Abra DST, habilite o mod de cliente e aplique.

A DLL requer Windows x64. O arquivo `bin64/dinput8.dll` **não** deve ser colocado dentro da pasta do mod nem do servidor dedicado.

## Como configurar o limite de FPS

Abra o jogo em **Configurações → Vídeo** e selecione 60, 120, 144, 165, 240, 360 ou **Sem limite**. As mesmas opções aparecem na configuração do mod. Se disponível, mantenha a interpolação ativada e comece pelo perfil gráfico **Original**, sem efeitos extras.

Se o monitor tiver 144 Hz, ele continua exibindo 144 atualizações completas por segundo. O jogo pode renderizar mais FPS, mas a GPU/CPU pode não acompanhar o valor escolhido.

## Arquivo INI e sincronização

O complemento utiliza `Don't Starve Together\bin64\dst_fps.ini`.

- `force_unsynced_presentation=1`: libera a apresentação EGL da espera de sincronização vertical. Pode causar *tearing*.
- `force_unsynced_presentation=0`: deixa o jogo solicitar seu intervalo de sincronização habitual.
- `low_latency_gpu_sync=0`: evita a espera adicional da GPU usada pelo complemento.

**O instalador preserva o INI existente** por padrão para não descartar suas preferências anteriores. Em uma instalação nova, copia o INI fornecido.

## Erros comuns

**O jogo continua limitado a 60 FPS:** confira se a DLL está realmente na pasta `bin64`, se a edição x64 do jogo está sendo usada e se o mod está habilitado. Alguns limitadores do driver ou outros mods podem interferir.

**O instalador diz que existe outra DLL:** ele protege sua instalação por padrão. Verifique a origem dessa DLL; só use `-PermitirOutraDLL` depois de decidir substituí-la e aceitar que a ferramenta anterior poderá deixar de funcionar.

**Aparecem duas versões do mod:** desative a cópia antiga do HyperSmooth/Café Smooth ou a cópia local redundante. Para quem usa Workshop, instale apenas a DLL.

**Viu linhas horizontais na imagem (*tearing*)?** Experimente `force_unsynced_presentation=0` e reinicie o jogo, ou escolha uma meta de FPS próxima da taxa do monitor.

**PowerShell bloqueou a instalação:** abra uma sessão normal do PowerShell e utilize o comando completo com `-ExecutionPolicy Bypass`; isso vale somente para a execução desse processo. Confira a origem do pacote antes de executar. Se a pasta Steam exigir permissão administrativa, execute com essas permissões apenas quando necessário.

**Precisa desfazer a instalação?** Com o jogo fechado, restaure os arquivos originais do backup criado na Área de Trabalho; desative o mod no menu. Se a DLL foi instalada pela primeira vez e não havia uma anterior, remova `bin64/dinput8.dll` depois de fechar o jogo.

## Segurança e suporte

Não distribua DLLs renomeadas ou modificadas sem disponibilizar o código-fonte correspondente. O hash da DLL distribuída está registrado nos arquivos de QA. Código e avisos de licença em [LICENSE](../LICENSE) e [licenses/](../licenses/).

Para problemas reproduzíveis, abra uma [issue](https://github.com/efac000/Desbloquear-QPS/issues) com versão do DST, Windows, GPU, lista de mods e logs relevantes — sem dados pessoais.
