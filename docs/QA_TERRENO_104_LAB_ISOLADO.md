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
