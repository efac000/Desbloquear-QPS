# QA de terreno no cliente isolado

Em 28/11/2026, o DST x64 build 763928 foi executado de uma copia local do jogo, com `-persistent_storage_root` e `-conf_dir QA_Terreno`. O mundo e local, de superficie, sem cavernas e com `modoverrides.lua` vazio. A captura usou PresentMon 2.6.0 filtrado por PID. O WPR CPU/GPU retornou `0xc5585011`.

## Defeito de isolamento corrigido

Com a DLL de referencia, o log registrou FPS inicial 60 e a troca para ilimitado 3 ms depois, antes de carregar o mundo. A leitura legada procura o arquivo mais recente no Documents padrao, mesmo com armazenamento alternativo. Reaplicar o INI pelo hot reload restaurou 60 para a coleta de referencia.

Em um INI de QA, adicionar `legacy_mod_bridge=0` em `[FPS]` e reiniciar o cliente desativa a busca inicial e a sondagem periodica da ponte legada. O valor padrao continua 1 e a ponte direta Lua continua disponivel. Para reverter no laboratorio, restaurar a DLL de referencia e retirar a chave do INI da copia de QA com o cliente fechado.

Build MinGW concluido. SHA-256 do binario de QA: `98d0ba6b36eae68436cc42888a847621025f9e34220e25a23b2357d143ca71c5`. Na copia isolada, o modulo foi confirmado no processo, o log registrou FPS inicial 60 e a ponte desativada, e a transicao precoce para ilimitado nao apareceu. `python tools/test_release.py` e `git diff --check` passaram.

## Capturas exploratorias

| Cenario | Quadros | P50 | P95 | P99 | P99.9 | Maximo | Acima de 25 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Sem DLL do QPS | 2696 | 16,67 | 16,88 | 17,23 | 18,94 | 22,16 | 0 |
| DLL de referencia, texturas ativas | 556 | 16,66 | 17,17 | 18,28 | 19,41 | 19,41 | 0 |

Valores em ms, coluna MsBetweenPresents, percentis por posto mais proximo. As capturas tem duracoes diferentes (44,93 s e 9,27 s) e os tempos das acoes nao foram confirmados dentro dos CSVs. O log da referencia registrou ainda 167,9 ms e 47,3 ms antes da captura, sem correlacao com acao. As amostras nao sustentam causalidade ou ganho de desempenho. O gate de terreno continua NO-GO. Falta repetir o roteiro com marcadores precisos em A/B/C, a partir do mesmo save e com o mesmo limite efetivo.

## Instalação para teste pela Steam

Em 28/11/2026 às 11:22 (Brasília), com o DST fechado, a compilação de QA do commit 2642223 foi instalada no bin64 principal. A leitura após a troca confirmou a DLL 98d0ba6b36eae68436cc42888a847621025f9e34220e25a23b2357d143ca71c5 e o INI 0d5a5c61569f87d24656c8de3c25e1ab7b1be2c73ad2e2d52683e3c8bb928a5c. O INI recebeu apenas legacy_mod_bridge=0 em FPS. timeslice_tex_upload=0 e o mod Lua r6 foram preservados.

O backup qps-steam-backup-20261128-112244, na pasta work da sessão Codex, contém a DLL anterior, o INI texture-off anterior e uma cópia do journal qps-native-qa. Para rollback, fechar o DST e restaurar primeiro DLL e INI desse backup, conferindo os hashes anteriores ac60fd192f0fc8632b9c06c1ff7d8bf1afadf00151695ce0920ee77a99f949d5 e 00fc05809f3aa138d7034c5b9949e55398d634eb33bbee8558ea9582cf9476a6, respectivamente. Só então usar qa_native_terrain.py restore se a intenção também for desfazer texture-off. O journal usa os hashes do par anterior.

Antes de pedir validação em jogo, identificar se o usuário abrirá a Steam ou a cópia isolada. Verificar por hash a DLL e o INI no bin64 correspondente. Após iniciar, confirmar o módulo carregado no PID do cliente e o perfil efetivo no log novo. Registrar separadamente build, instalação, execução e resultado do teste. A DLL compilada corrige a leitura de configuração legada em QA. A homologação do stutter com Geometric Placement continua pendente.

## Reteste real com Geometric Placement

A gravação de 28/11/2026 cobre aproximadamente 11:28:04–11:28:17 (Brasília). Os resumos nativos de 11:28:08 e 11:28:18 registraram máximos de 109,2 e 105,2 ms, respectivamente. Antes da gravação houve máximo de 360 ms às 11:27:48. São máximos de janelas agregadas, sem atribuição a ações individuais. A DLL de QA iniciou com a ponte legada desativada, a ponte direta ficou ativa e o FPS mudou para ilimitado após a inicialização. Geometric Placement 3.2.0 e QPS r6 carregaram. A grade reutilizou marcadores e as métricas de textura ficaram com up=0 e slice=0. Portanto, desligar o hook de texturas foi insuficiente neste cenário.

Com o cliente fechado, aplicado o próximo isolamento no INI principal: somente fast_spatial_query=1 passou a 0. DLL, Lua e demais bytes do INI foram conferidos. INI resultante SHA-256 917f0d5685fd003558e508e98f771f67aaea19f7e62973473f20ec6acf6605c6. Backup da configuração usada no vídeo: work/qps-spatial-off-20261128/dst_fps.ini na sessão Codex, SHA-256 0d5a5c61569f87d24656c8de3c25e1ab7b1be2c73ad2e2d52683e3c8bb928a5c. Para desfazer somente este isolamento, fechar o cliente e restaurar esse INI. O contador espacial anterior mede volume, sem medir duração. O resultado espacial-off ainda depende de nova sessão e o gate permanece NO-GO.

## Triagem no laboratório com Geometric Placement ativo

Executados QPS 1.0.4 r6, Geometric Placement 3.2.0 e Geometric Drop 1.4.8 no mundo descartável. Logs confirmaram instalação do hook GP e reutilização efetiva. Mantidos FPS ilimitado e hook de texturas desligado nas duas capturas. O hot reload registrou SpatialZC=0 para a segunda. Nas primeiras janelas de 12 s do PresentMon, o SpatialGrid ativo produziu 4.468 quadros, P99 5,12 ms e máximo 10,87 ms. Com SpatialGrid desativado, foram 4.237 quadros, P99 5,25 ms e máximo 8,39 ms. Ambos tiveram zero quadros acima de 25, 50 e 100 ms. Um pico nativo de 164,9 ms ocorreu durante entrada no mundo, antes do roteiro. Abrir o mundo também reaplicou o FPS ilimitado pela ponte direta.

O roteiro exploratório usou movimentos do forcado e seleção de piso por coordenadas. O personagem se moveu entre as duas amostras e o laboratório ainda carregava somente um subconjunto dos mods registrados na sessão afetada. A redução do máximo nessa amostra não demonstra efeito sobre o defeito, pois os picos de terreno do cenário afetado não foram reproduzidos. Snapping Tills 1.1.9 e ActionQueue RB3 4.4 foram preparados para ampliar o cenário na próxima execução. O WPR CPU/GPU continua indisponível sob o token atual. O gate segue NO-GO.
