# QA / Release Gate — Desbloquear QPS

## Teste de inicialização independente (22/11/2026)

**Aprovado no PC de teste:** a pasta nova mods/desbloquear-qps foi carregada pelo cliente sem a pasta anterior. O log registrou Loading mod: desbloquear-qps (Desbloquear QPS) Version:1.0.0, importação de keybind, modconfiguration_desbloquear-qps, LOADING LUA SUCCESS e registro de prefabs. O processo ficou responsivo. A DLL registrou EGL swap interval requested=1 effective=0 result=1 (unsynced=1).

**Procedimento:** habilitação temporária usando ForceEnableMod em modsettings.lua somente durante QA. O arquivo modsettings.lua foi restaurado byte a byte a partir do backup ao fim do teste. **A ativação permanente no menu de cliente ainda precisa ser feita pelo jogador.** Esse teste de inicialização não inclui mundo, cavernas ou servidor público.


**Teste complementar de inicialização após a otimização do HUD:** o DST abriu e ficou responsivo, mas o mod não foi carregado nessa tentativa; o log não contém Loading mod: desbloquear-qps. Portanto, a inicialização específica do novo Lua continua pendente de ativação no menu e reteste. O modsettings.lua usado apenas durante QA foi restaurado integralmente.

**Testes adicionais desta revisão:** instalador verificado em simulação, instalação em pasta isolada e cenário com DLL desconhecida. Passou na verificação de integridade, preservou o INI e bloqueou sobrescrita de DLL diferente. O teste de presets valida dados salvos de FPS no Lua 5.1; não mede FPS efetivo em jogo.

Comandos locais (Windows): python tools/test_release.py; python tools/build_icon.py; powershell -NoProfile -ExecutionPolicy Bypass -File tools/build_native.ps1.

Verificações estáticas: Lua 5.1; 24 chaves, dados e defaults; ausência de ideogramas no menu; módulo cliente; artes 512x512 e KTEX 128; shaders; DLL PE x64; fonte EGL e licenças.

Esses testes NÃO comprovam jogabilidade universal, ganho de FPS em qualquer máquina, ausência de tearing, multiplayer nem boa renderização de ícone em todas resoluções.

Antes de declarar pronto para Workshop: confirmar o ícone novo em jogo; testar configurações, migração e atalhos após reinício; FPS real, GPU, frame-time, 1% Low e 7 alvos em janela/tela cheia; mundo/caverna/servidor público; desativação e rollback; compatibilidade com outros mods de cliente e outro dinput8; confirmar Workshop ID e proprietário; verificar pacote da página após upload.

O pacote Workshop NÃO inclui instalação automática de DLL em bin64. O readme e a descrição pública devem deixar esse requisito explícito. Não registrar publicação sem prova real.

## Instalador pós-Workshop de duplo clique

- ZIP da DLL inclui INSTALAR DLL.bat e tools/instalar_workshop.ps1.
- Testados: sintaxe PowerShell, simulação, instalação em DST fictício, integridade SHA-256, INI preservado, ausência de mod duplicado e bloqueio de DLL conflitante.
- Simulação no computador real confirmou identificação automática da instalação Steam mesmo com caminhos usando capitalizações diferentes, sem modificar o jogo.
- A solicitação de permissões UAC só ocorre quando o destino exigir; o caso de elevação ainda depende do Windows do jogador.

## Preparação do repositório público separado

- Fonte de verdade deste lançamento: https://github.com/efac000/Desbloquear-QPS (main).
- O conteúdo foi importado do commit bb103833 do catálogo anterior, que integra a edição da PR #58. O repositório novo não depende da instalação do projeto antigo.
- Corrigidas mensagens do console próprias do mod, opções Ativado/Desativado e rótulos especiais de teclas para PT-BR, sem alterar códigos internos ou DLL.
- São distribuídos dois pacotes independentes: completo com bin64 e fontes, e Workshop apenas com Lua/shaders/ícones. A Workshop não instala a DLL em bin64.
- O instalador novo inclui modo -SomenteDLL para usuários que já assinaram a Workshop; teste de integração no GitHub Actions Windows e testes estáticos Linux.
- O jogo estava aberto durante parte do preparo: não houve alteração da pasta ativa do jogador. As instalações novas devem ser testadas com o DST fechado.
- O autor informou que o HUD e a edição anterior estavam funcionando corretamente no seu PC. Isso é validação funcional do cenário testado, não demonstra desempenho ou compatibilidade universal.
- O upload Steam Workshop será realizado pelo proprietário, após confirmar a ID e o funcionamento da página pública.

**Comandos de verificação no repositório novo:**

    python tools/test_release.py
    python tools/gerar_pacotes.py --verificar

Na máquina com Don't Starve Mod Tools, também pode executar `python tools/build_icon.py` e, com MinGW/Git, `powershell -File tools/build_native.ps1` sem substituir a DLL instalada. O hash da DLL está protegido pela suíte de testes.

## Gate de desempenho e compatibilidade — candidata 1.0.4 r3

Consultar [base de conhecimento](CONHECIMENTO_TERRENO_E_COMPATIBILIDADE.md) e QA_TERRENO_104_R3.md. Exigir telemetria do hook efetivo, teste A/B controlado de frame-time e hitches, verificação visual, cadeia GP + Snapping Tills + ActionQueue, limpeza por mundo, teste multiplayer e regressão. Teste simulado não comprova ganho real. O prewarm r2 foi confirmado, mas o hook não; r3 aguarda confirmação. Não publicar enquanto bloqueios permanecerem.
