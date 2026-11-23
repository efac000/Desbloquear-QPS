# Registro de continuidade e evolução — Desbloquear QPS

Esta é a referência para trabalhos futuros. Consulte também HISTORICO.md, README.md, código atual e PR #58. Priorize dados testados, não promessas.

## Diretrizes fixas
- Nome oficial: **Desbloquear QPS**. Autor desta edição: **café**. Fonte anterior HyperSmooth 2.5.0 MIT: preservar copyright e avisos.
- Independência da pasta/mod Workshop anterior, não independência da base intelectual. Não depende de instalação de outro mod para funcionar. DLL própria em bin64/dinput8.dll necessária para render nativo >60 FPS.
- APIs nativas HyperSmooth_* permanecem como contrato de compatibilidade DLL+Lua; renomear requer alterar os dois lados.
- FPS alvo: 60,120,144,165,240,360,0 (=sem limite). Nunca confundir meta com FPS efetivamente atingido nem monitor físico com render.
- CFG_FILENAME próprio: desbloquear_qps_cfg_v1. Fallback apenas ao configurar pela primeira vez: dst_smooth_highfps_cfg. Preservar a precedência das escolhas explícitas do jogador.
- 24 identificadores internos, defaults e dados de seleção não devem mudar sem migração e testes.
- Visual Original sem efeitos extras por padrão. Interpolação, câmera, otimizações e carregamento ativados. FPS padrão 240 como alvo; pode reduzir para 144 se preferir estabilidade.
- EGL opt-in no arquivo INI (force_unsynced_presentation=1); low_latency_gpu_sync=0. V-Sync OFF pode causar tearing. DLL reversível via backup.
- Arte: somente chave inglesa + cabeça sextavada + rosca curta, creme/cinza sobre fundo carvão, sem texto; arquivo 512x512 em art/icone-mestre-512.png e icone-workshop-512.png; TEX 128.
- Não modificar os outros mods, saves pessoais, identidade do autor original nem outras artes sem autorização.

## Melhorias incluídas nesta revisão de main

- HUD desativado: evita telemetria e formatação periódica, descartando amostras antigas.
- Nomes dos perfis visuais reutilizados para evitar alocação transitória.
- FPS persistido validado contra sete presets, antes de ser encaminhado ao componente nativo.
- Instalador Windows opcional: simulação sem gravar, backups, preservação do INI e bloqueio de conflito com outra dinput8.dll por padrão.
- A DLL já limita o FPS de 0 a 1000 nativamente, tem pacing de deadlines e EGL no-sync validado. Não substituir o binário sem defeito reproduzido ou benchmark justificado.

## Testes obrigatórios antes de merge/Workshop
1. 24 opções no menu PT-BR sem cortes, texto da descrição breve, ícone reconhecível em 64/128/512 px.
2. Persistência após reinício e migração de preferências legadas; atalhos de FPS, interpolação e HUD.
3. FPS efetivo e frame-time P99 para todos os 7 limites, com janela/tela cheia e diferentes frequências físicas; medir tearing e uso CPU/GPU no PC de teste.
4. Superfície, cavernas, host local e cliente de servidor público; opcionalmente LAN/latência e mods de interface/performance.
5. Iniciar sem DLL e com DLL; evitar conflito se outro proxy dinput8 estiver instalado; restaurar backups sem erros.
6. Auditoria de exportações da DLL, recompilação do fonte, hashes, licenças mimalloc/libdeflate e logs de crash.
7. Confirmar Workshop ID e propriedade antes de upload; comparar os bytes do item após publicação; revisar a descrição da DLL manual.

## Melhorias futuras, não presumir implementadas
- Perfis rápidos Estável (144), Alto desempenho e Ilimitado.
- Mensagem clara de tearing/limite físico/efeito GPU, separando FPS de simulação.
- Diagnóstico de gargalos por frame-time, renderização, GPU e uso CPU sem alocações extras no hot path.
- Teste automatizado de migração do DST modindex e interações de atalhos.
- Fallback seguro para API ausente, verificação de versão Lua-DLL, prevenção de duas edições habilitadas.
- Benchmarks reproduzíveis de transição superfície/caverna e uso de memória.
- Roadmap por versões (mudanças pequenas com CI e cliente), sem alegações de 100% compatibilidade sem evidência.

## Como continuar
Consultar a main de efac000/Desbloquear-QPS como fonte atual; a PR #58 do repositório antigo é referência histórica. Revisar o diff antes de cada alteração. Rodar tests, icon build e native build no worktree; não substituir a DLL jogável automaticamente. Atualizar HISTORICO/QA/este documento quando confirmar resultados. Publicar Steam somente após validar a identificação da página e as imagens.

## Melhorias específicas da distribuição pública
- Validar o instalador em cenário de assinatura da Workshop e em instalação local sem duplicação do mod.
- Executar GitHub Actions em Windows e Ubuntu a cada alteração da main; revisar logs e pacotes antes de cada versão.
- Manter documentação, ícones e DLL atualizados juntos com o código-fonte correspondente.
- Não modificar o comportamento da DLL por suposição de ganho: medir antes/depois e registrar hardware e métodos.
