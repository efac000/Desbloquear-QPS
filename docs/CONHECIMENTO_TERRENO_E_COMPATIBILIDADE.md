# Base de conhecimento — desempenho e compatibilidade de posicionamento DST

Data: 27/11/2026. Escopo: Desbloquear QPS, aprendizado reutilizável em mods de HUD, construção e desempenho. Estado: 1.0.4 r3 candidata, PR #1 em draft; 1.0.3 é estável. Não interpretar este documento como homologação.

## 1. Evolução e evidências
| Revisão | Implementação | Resultado observado |
| --- | --- | --- |
| r1 01d9e51 | Pool de gridplacer, limite 121, TTL 5 s | Testes simulados passaram; usuário relatou travadas; sem confirmação do hook. |
| r2 d1bedf7 | tile_outline passivo, prewarm 25, TTL 30 s, refresh limitado, logs | Usuário relatou melhora parcial; prewarm confirmado, fallback de origem registrado, nenhum hook confirmado. |
| r3 87d523c | Reconhece wrappers conhecidos; instala em SetBuilder do posicionador ativo, preserva cadeia | Lua 5.1, lint, regressões e pacote aprovados; instalação verificada. Novo log indica experimental habilitado, ainda não indica hook/uso. |

Ambiente: build DST 763928; GP 3.2.0 (351325790); Snapping Tills 1.1.9 (2302837868); ActionQueue RB3 4.4 (2873533916). QPS Workshop 3844329122. O GP cria/posiciona marcadores síncronos e consulta tempo do refresh a cada 20 pontos. PlayerController força OnUpdate(0) após criar o posicionador. tile_outline é candidato a marcador local mais leve, não substituto do cursor. Preservar teste do cursor, TestPoint, geometria, cores, Ctrl, controle e RPC. Não mudar arquivos Klei, de terceiros, saves ou cache Workshop.

## 2. Erros e regras preventivas
- E01 — Confundir carregamento do mod ou prewarm com execução do hook. Exigir logs de ativação, origem e contagem de trabalho efetivo; fallback não é sucesso. Em r2, prewarm 25 seguido de fallback, sem linha hook instalado. Causa específica do fallback não registrada; inspeção e fixture demonstram incompatibilidade dos wrappers conhecidos.
- E02 — Teste isolado não reproduz cadeia real de mods. Inventariar mods ativos, versões, prioridade, AddComponentPostInit/AddPrefabPostInit, alterações de classe e instância; testar ordem e composição. Snapping Tills e ActionQueue encapsulam OnUpdate; não sobrescrever cadeia nem desativá-los. Guardar procedência GP da classe e quatro métodos de grade; wrapper desconhecido deve manter original.
- E03 — Hook cedo demais ou em entidades passivas. Inspecionar ciclo de vida real: prefab, componente, SetBuilder, OnUpdate(0), onremove e troca de mundo. Instalar somente no cursor com builder, após post-inits; garantir retorno original e idempotência. Testar ausência de builder, múltiplas instâncias, mudança de estado e tarefas canceladas.
- E04 — Pool não resolve primeira abertura nem custo de alteração do mapa. Separar frio/quente, equipar/desequipar, hover, movimento, colocar/remover piso; medir antes de aumentar o pool, alterar motor ou mudar DLL. Pré-aquecer de forma limitada, validar memória e limpar por mundo. Não adiar validação do cursor.
- E05 — Confundir FPS médio, frame time, tick e captura. Log nativo r1 pico 340,5 ms; r2 424,7 ms em janela anterior à gravação, 113/124,3 ms nas janelas durante a gravação, 42,8 ms na seguinte. Não comparar máximos de sessões não controladas. Vídeo 60 FPS não mede pacing a 144/240 Hz. Contador spatial acumulado não é duração; tempos instrumentados parciais não identificam toda a causa. os.clock não equivale a duração de GPU/tempo real em todas plataformas.
- E06 — Não resolver gargalo por hipótese destrutiva. Medir Lua e motor separadamente, testar limite de FPS e efeitos visuais em A/B, não mexer no binário sem evidência. DLL nativa ac60fd192f0fc8632b9c06c1ff7d8bf1afadf00151695ce0920ee77a99f949d5. ZIP DLL 832e66b7d41fe8aa36218acdc7f414a56bad6aa4af170fbbb64d7807a6b4889a.
- E07 — Instalação e publicação: usar árvore limpa, ZIP validado, hash de origem e destino, jogo fechado antes de copiar, backup e rollback. Falha inicial de resolução de caminho PowerShell r1 solucionada com leitura direta ZIP por Python; falha de identidade Git r3 corrigida por identidade explícita de commit, sem alterar config global. Não commitar backups, logs integrais ou credenciais.
- E08 — Não reintroduzir aceleração ZIP/zlib ou cache LoadModInfo obsoleto: correções 1.0.1/1.0.2 preservam multiplayer. Installer 1.0.3 diferencia instalação, atualização, já atualizada, e bloqueia DLL desconhecida, verifica SHA-256, preserva INI.

## 3. Protocolo de aceitação para próxima etapa
1. Confirmar versão e hash instalados, jogo/build, mundo, lista e ordem de mods, configuração e FPS real. Não habilitar QPS estável e candidato simultaneamente.
2. Confirmar no client_log r3 experimental habilitado, hook instalado com origem, e update com reused ou light >0; se fallback, investigar método exato. Ausência de linhas não prova que não há problema. Registrar contagem de placers ativos, marcas e tarefas.
3. Testar OFF/ON no mesmo mundo e local, mesma câmera, mods, efeitos e alvo (60,144,240, ilimitado). Repetir ações frias e quentes, grade pequena/grande, borda do terreno, movimento rápido, piso/forcado normal e dourado, Ctrl, controle e ActionQueue. Separar hover de mutação de piso, não misturar amostras de carregamento com ações. Usar marcação temporal e janelas iguais.
4. Coletar P50/P95/P99, 1% low, pior frame, quantidade de hitches por minuto e tempo por operação, memória antes/depois, eventual crash. Critério proposto: melhora repetível de P99 e hitches sem degradação visual/funcional, sem regressão de estabilidade; definir limiar numérico após baseline. Não afirmar eliminação universal.
5. Testar mundo local e servidor remoto, superfície/cavernas, reconexão, rollback da opção, cores/animações e compatibilidade de pisos de mods. Confirmar logs sem erro Lua e sem fallback inesperado. Revisar CI Linux/Windows e pacotes antes de release.
6. Se persistir: medir criação/destruição real do cursor, TriggerDeployHelpers, TestPoint, fila de refresh, map SetTile/RebuildLayer e renderização; investigar se há recriação por quadro. Considerar cache visual de estados e deduplicação da fila somente com invariantes e testes; não alterar validação real nem ações de rede. Criação progressiva para grades maiores permanece proposta, não implementação.
7. Manter PR draft e 1.0.3 pública até evidência e aceite. Atualizar Workshop/site/download/documentação somente na promoção autorizada.

## 4. Referências
- HISTORICO.md; docs/QA_TERRENO_104.md; docs/QA_TERRENO_104_R2.md; docs/QA_TERRENO_104_R3.md.
- https://github.com/efac000/Desbloquear-QPS/pull/1
- https://github.com/rezecib/Geometric-Placement — Refresh Speed; documentação de origem.
- https://kleiforums.com/klei-bug-tracker/dont-starve-together-beta-branch/heavy-lag-when-trying-to-place-certain-items-down-using-the-geometric-placement-mod-r34320/ — relato histórico de 2022, hipótese, não diagnóstico atual.
- Evidência local: client_log.txt, dst_fps_plugin.log; não publicar logs completos.

## Atualização r4 — erro E09 (prevalece sobre a guarda de wrappers r3)

O log da r3 mostrou fallback de OnUpdate desconhecido mesmo após aceitar dois wrappers conhecidos. Não ampliar indefinidamente a lista de mods: validar o menor contrato efetivamente modificado. R4 preserva a identidade do OnUpdate por instância (inclusive wrapper de origem desconhecida), verifica classe e quatro métodos GP, não força o caminho original se outro mod o desviar. Red/green demonstrado em Lua 5.1. Telemetria deve indicar hook instalado E grade executada com reused/light positivos. R4 não foi homologada em jogo; veja [QA_TERRENO_104_R4.md](QA_TERRENO_104_R4.md). Se o hook atuar, medir outros gargalos antes de modificar a DLL ou o mapa.

## E10 — mods cliente OFF não equivale a vanilla

Relato de stutter sem mods cliente não exclui DLL, servidor ou motor. Fazer baseline sem DLL e sem mods em ambiente controlado. No build inspecionado, SetBuilder cria 50 marcadores auxiliares mesmo em snap_to_tile, que não usa o alinhamento auxiliar. R5 evita apenas essa alocação quando métodos originais verificados, opção independente OFF por padrão; manter método externo intacto. Testes com script real e APIs simuladas demonstram contagem 50→0, não ganho real. Distinguir equipar/hover de Map:SetTile e eventos. Ver [QA r5](QA_TERRENO_104_R5_VANILLA.md).
