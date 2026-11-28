# QA intensivo — Desbloquear QPS 1.0.4 r6 — 28/11/2026

Base testada: 4e6e7c3896b6cd4a05ec0e5c925591b6ff78977b. PR #1 permanece draft.

## Evidências executadas em Windows
- tools/test_release.py: PASS integral (Lua 5.1, modinfo 27 chaves, UI, DLL PE x64, instaladores, GP, vanilla, transações nativas simuladas).
- tools/gerar_pacotes.py --verificar: PASS dos três ZIPs existentes.
- tools/test_terrain_stress.py: PASS. GP 6000 ciclos, 407000 pontos, 9121 criações leves, 9000 remoções, 121 retidos, 4 linhas de log, CPU Lua 1,316 s nesta execução (não é benchmark de engine). Verificados objetos únicos/válidos, limite do pool, fila drenada, máximo 4 verificações por chamada, orçamento zero, limpeza da estrutura. Vanilla fixture: 10000 elegíveis, 500000 auxiliares simulados evitados, 1000 não elegíveis preservam 50000 criações simuladas.
- Script original instalado scripts/components/placer.lua: 22744 bytes, SHA256 1bc4a3e4529e2d540d6d2497d3bbd49d74993853c2751a058fa602ba963d14f9. PASS test_installed_placer.lua: 50 auxiliares baseline vs 0 quando elegível; mouse/controle, válido/inválido, turf, normal, 100 recriações; APIs nativas mockadas.
- tools/test_native_terrain_stress.py: PASS 100 transações em cópias reais da DLL e INI (50 spatial-off, 50 vanilla, 100 restaurações byte a byte). Nenhum perfil real ativo. DLL SHA256 ac60fd192f0fc8632b9c06c1ff7d8bf1afadf00151695ce0920ee77a99f949d5; INI SHA256 84675edabe9a97d09f1bf693308bc48aacf89a7460162ec0cd8178dbaa1ae251; modmain instalado E6BF8EF85E8921A3EE239C6CF1A7E8F3DF3D442A4C486EC6AA8E9D7737142F91. Nenhuma alteração no runtime instalado nesta rodada.

## Releitura do código vanilla instalado
- playercontroller.lua 2885–2918: deployplacer depende do objeto ativo/deploy_mode; comparação prefab e skin, CancelDeployPlacement, SpawnPrefab, SetBuilder e OnUpdate(0).
- playercontroller.lua 2920–2972: terraformer depende de ação direita/controle, tile_placer e show_tile_placer_fn. Cria apenas quando nil, remove quando ação deixa de ser elegível ou outro placer está presente. Não há evidência de que crie a cada quadro em todas as condições; instrumentar transições antes de otimizar.
- gridplacer.lua 16–42: entidade local não sincronizada, não persistente, Transform, AnimState, componente placer e snap_to_tile.
- terraformer.lua 12–47: validação, seleção de tile, Map:SetTile, loot, pesquisa de entidades e eventos. map.lua 3–8: wrapper nativo SetTile seguido de onterraform. Hover não equivale à mutação; não suprimir eventos nem alterar rede, validade ou ações por hipótese.
- TinyFish: relato histórico 2022 de recriação de placer e lag GP https://kleiforums.com/klei-bug-tracker/dont-starve-together-beta-branch/heavy-lag-when-trying-to-place-certain-items-down-using-the-geometric-placement-mod-r34320 ; orientação geral https://support.klei.com/hc/en-us/articles/360029555272-Network-and-Performance-Troubleshooting-Guide . Firecrawl: https://kleiforums.com/files/file/1108-geometric-placement/ descreve custo de atualização da grade. Resultados de busca são trechos, não prova causal neste build.
- Gate: aprovação de fixtures não comprova FPS. Sem sessão real A/B (vanilla sem DLL/mods, DLL ativa, spatial-off), não promover. Separar equipar, hover em bordas, selecionar piso, alteração real. Igualar FPS efetivo, local, câmera, resolução e sequência; repetir no mínimo 3 vezes cada. Proposta de critério: melhora de P99 e hitches >25ms por minuto sem regressões de correção, com amostras suficientes; não alegar eliminação universal.
- Registrar evidências de QA no repo sem logs privados completos ou saves. A versão estável 1.0.3, Workshop, site e DLL permanecem inalterados.
