# 1.0.4 - candidata (não publicada)

- Reutilização experimental de marcadores visuais de terreno do Geometric Placement 3.2.0, com limite e expiração.
- Desativada por padrão; sem mudanças na DLL, no terreno real ou no instalador.
- Homologação gráfica e multiplayer pendentes. Ver docs/QA_TERRENO_104.md.

## Evolução da candidata 1.0.4 (27/11/2026)

- r1 (01d9e51): pool de marcadores; travadas persistiram no teste real.
- r2 (d1bedf7): marcadores leves, pré-aquecimento, refresh limitado e telemetria; pré-aquecimento confirmado, mas fallback de integração no cliente.
- r3 (87d523c): preserva wrappers conhecidos do Snapping Tills e ActionQueue RB3 e instala no SetBuilder do cursor. Testes simulados, lint e integridade aprovados; execução efetiva e melhora em jogo ainda não homologadas.
- Lições, erros, evidências, decisões e protocolo de aceitação em [base de conhecimento](docs/CONHECIMENTO_TERRENO_E_COMPATIBILIDADE.md). A versão pública continua 1.0.3, DLL e BAT preservados.

# 1.0.3 - Instalador

- Mensagens distintas para instalacao, atualizacao e DLL ja atualizada.
- Confirmacao de SHA-256 antes do aviso de sucesso, inclusive apos elevacao.
- DLL nativa sem alteracoes.

# 1.0.2 - Workshop metadata compatibility

- Removed cached ModIndex.LoadModInfo override; preserve native validation after temporary downloads.
- Preserved custom FPS options (30-1000), native DLL 1.0.1 and existing user settings.
- Installer removes the known obsolete cache hook from the installed QPS Workshop item, with backup.

# Atualização 1.0.1 - compatibilidade Workshop

- Desativadas no código nativo as substituições globais de minizip e zlib, inclusive para configurações antigas.
- Desbloqueio de FPS e demais opções preservados.
- A verificação de versões e as regras de acesso do DST continuam originais.

# Histórico de evolução — Desbloquear QPS

## v1.0.0 — revisão pré-lançamento, 22/11/2026

- Nome definitivo **Desbloquear QPS**. Autoria e manutenção da edição: **café**; licenças e atribuições da base HyperSmooth v2.5.0 preservadas.
- Instalação própria em mods/desbloquear-qps, sem a pasta da versão anterior. A DLL x64 continua necessária para desbloqueio nativo acima de 60 FPS.
- Novo ícone minimalista: chave inglesa aberta encaixando-se numa cabeça sextavada grande com rosca visível. Sem texto. Previews Workshop 512×512 e KTEX 128×128.
- Tradução e rótulos das 24 opções mais curtos, sem mudar os nomes internos, dados e defaults.
- Persistência nova desbloquear_qps_cfg_v1; migração dos dados legados dst_smooth_highfps_cfg quando não há config própria.
- Preservada DLL personalizada que corrigiu o bloqueio de 144 FPS usando eglSwapInterval e eglSwapBuffers, com force_unsynced_presentation=1.
- Gráficos Original e efeitos opcionais OFF por padrão; otimizações principais e interpolação ON; alvo inicial 240 FPS selecionável.
- Fontes, scripts de build, testes estáticos, arte-mestre e documentação de continuidade organizados no GitHub.

## Ajustes de eficiência e usabilidade — revisão da candidata 1.0.0

- HUD oculto evita calcular e formatar estatísticas; nomes de perfis visuais reutilizados.
- Migração de configuração valida se o FPS salvo pertence às sete opções permitidas.
- Instalador opcional PowerShell: simulação por padrão, backups e recusa de DLL desconhecida. Testado em ambiente isolado.
- DLL nativa com EGL preservada, por não haver benchmark indicando mudança nativa segura e vantajosa.
- Suíte QA expandida para executar validação de presets em Lua 5.1.

## Histórico anterior

O protótipo **Café Smooth v1.0.0**, adicionado pela PR #58, já havia passado testes locais e a CI do catálogo. Ainda usava o nome e a pasta original hypersmooth-240fps-fastload no computador, o que motivou a preparação desta edição com identificação e caminho próprios. A base técnica é derivada do HyperSmooth MIT, não uma reescrita integral.

**Status:** candidata para lançamento. Não documentar como publicada na Steam até realizar upload e conferência do item.

## v1.0.0 — organização para repositório público e publicação

- Código completo transferido para a raiz do repositório público efac000/Desbloquear-QPS, mantendo licenças MIT e bibliotecas de terceiros.
- Revistos textos próprios da interface, mensagens de console, opções Ativado/Desativado e descrições de teclas; sem alterar códigos Lua/API.
- Novo instalador com opção `-SomenteDLL` para assinantes da Workshop, evitando dupla instalação; mantém simulação, backups, integridade e prevenção de conflitos de DLL.
- Guia de instalação, FAQ, texto de divulgação, imagem 512x512 e pacotes prontos para baixar.
- Automação de QA em Linux e Windows; arquivos ZIP conferidos por CRC, nomes e conteúdo.
- A DLL com correção EGL não foi modificada nesta migração. Não há alteração medida de velocidade do motor ou promessa de FPS universal.

## Facilidade de download para assinantes da Workshop

- Links visíveis e diretos no início do README para DLL, INI e ZIP pequeno.
- Instruções simples em três passos e link único para a página pública.
- Pacote nativo independente para instalar apenas DLL/INI, sem mod duplicado.
- A DLL e o código do mod não foram modificados nesta revisão de distribuição.


## Instalador automático para assinantes da Workshop

- Novo arquivo INSTALAR DLL.bat de dois cliques, distribuído no ZIP pequeno.
- Ajuda a encontrar bibliotecas Steam e solicita administrador só quando necessário.
- Localização automática testada no Windows, corrigindo duplicação do mesmo caminho com diferenças entre maiúsculas e minúsculas.
- Instalador nativo preserva backups e configuração existente e impede conflito com outra DLL diferente.
- Página e documentação atualizadas, sem modificar Lua ou DLL.

## Revisão 4 da candidata 1.0.4

- Log real r3 confirmou novo fallback de OnUpdate desconhecido. Teste de regressão reproduziu a rejeição (RED exit 1); r4 passou ao deixar OnUpdate intacto e atuar nos métodos GP verificados (GREEN).
- Telemetria distingue hook instalado e execução dos métodos de grade. Sem homologação de desempenho em jogo. Ver docs/QA_TERRENO_104_R4.md.
