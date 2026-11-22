# Publicação na Steam Workshop — Desbloquear QPS v1.0.0

Esta documentação é para o proprietário do mod. **A preparação no GitHub não publica nada automaticamente na Steam.** Confirme a conta e o item da Workshop antes de qualquer upload.

## Arquivos a publicar

Baixe e extraia `pacotes/Desbloquear-QPS-v1.0.0-Workshop.zip`. Escolha **a pasta interna Desbloquear QPS** ao utilizar o publicador da Workshop. Ela contém:

```text
modinfo.lua
modmain.lua
keybind.lua
modicon.tex
modicon.xml
preview.png
icone-workshop-512.png
shaders/
```

A imagem principal `preview.png` tem **512 × 512 pixels**; `icone-workshop-512.png` é uma cópia para selecionar manualmente no publicador. O ícone dentro do jogo é `modicon.tex` (128 × 128).

**Não coloque** `dinput8.dll`, `dst_fps.ini`, `native_plugin/`, código-fonte ou pacotes ZIP dentro da pasta a enviar para a Workshop. A DLL precisa ser instalada separadamente.

## Nome para a Steam Workshop

**Desbloquear QPS**

## Descrição em português brasileiro — pronta para copiar

> **Desbloquear QPS — FPS e Carregamento Rápido**
>
> Mais liberdade para configurar a taxa de quadros do Don't Starve Together, com animações suaves, melhorias de câmera e interface e otimizações de carregamento e memória.
>
> **Recursos:** FPS alvo de 60, 120, 144, 165, 240, 360 ou Sem limite; interpolação de animações; HUD de FPS e 1% Low; atalhos configuráveis; carregamento rápido de cavernas; perfis visuais opcionais. O visual original do jogo é o padrão.
>
> **IMPORTANTE — DLL necessária para desbloquear FPS:** a Steam Workshop instala os arquivos do mod, mas **não consegue instalar automaticamente `dinput8.dll` em `bin64`**. Para FPS acima do limite nativo, baixe o pacote completo e siga o guia de instalação da DLL:
>
> https://github.com/eduardonnn/Desbloquear-QPS
>
> Se você já assinou este mod pela Workshop, use o instalador do GitHub com a opção **`-SomenteDLL`** para evitar duplicação.
>
> Este é um mod **exclusivo do cliente**. Não é necessário instalá-lo no servidor.
>
> A taxa selecionada é uma meta e depende da capacidade do computador. Desativar a sincronização pode causar *screen tearing*. O mod não acelera a simulação do servidor.
>
> Edição em português brasileiro desenvolvida e mantida por **café**, baseada no HyperSmooth 2.5.0 (MIT), com créditos originais de Hakimi Tech Lab (wangxu1428) preservados. Código-fonte e licenças no GitHub.

## Lista de conferência antes de clicar em Publicar

- [ ] Confirmar que o item pertence à conta Steam correta e que não é o item de outra pessoa.
- [ ] Confirmar nome, autoria da edição, tradução e imagem 512×512.
- [ ] Verificar a pasta exata do pacote Workshop; não enviar código C++, DLL ou arquivos de build.
- [ ] Inserir o link do **repositório público** contendo a DLL, os fontes e o instalador.
- [ ] Usar uma descrição que avise sobre a instalação manual da DLL.
- [ ] Verificar as opções de FPS e a interface no cliente antes do envio.
- [ ] Depois de publicar, abrir a página pública, conferir a imagem e comparar os arquivos baixados.
- [ ] Registrar o Workshop ID, URL e versão no histórico do GitHub.

**Não é correto prometer FPS constantes ou compatibilidade universal**. Os ganhos dependem do hardware, do driver, da versão do DST e dos mods em uso.
