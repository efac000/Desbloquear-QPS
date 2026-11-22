# Perguntas frequentes

**Preciso do HyperSmooth antigo instalado?** Não. O Desbloquear QPS é instalado e ativado de forma independente. Ele contém uma edição derivada do código-base original sob licença MIT.

**Posso jogar em servidores públicos?** O mod é do cliente e não exige instalação no servidor. Ainda assim, algumas combinações de mods e situações de rede podem exigir testes de compatibilidade.

**O mod funciona sem a DLL?** Algumas melhorias Lua podem operar, mas o desbloqueio nativo de FPS depende de `bin64/dinput8.dll` no Windows x64.

**Por que 240 FPS podem aparecer em um monitor de 144 Hz?** O contador mostra quadros renderizados, não a quantidade de atualizações físicas exibidas. Desativar a sincronização pode produzir *tearing*.

**Por que não posso simplesmente assinar pela Workshop e pronto?** Por motivos técnicos, a Workshop não instala DLLs na pasta `bin64` do jogo. A instalação do complemento é separada.

**É obrigatório executar o instalador?** Não. É possível copiar os arquivos manualmente; veja [INSTALACAO.md](INSTALACAO.md).

**Tenho outra `dinput8.dll`. Posso substituir?** Não sem verificar. O instalador interrompe a instalação por padrão quando detecta uma DLL diferente. Faça backup e avalie o conflito antes de optar pela substituição.

**Isso é tradução integral do DST?** Não. O mod oferece interface própria revisada em português brasileiro. Textos nativos do jogo, identificadores de APIs, nomes de teclas herdados do DST e mensagens técnicas internas podem seguir o idioma do jogo ou continuar em inglês.

**Quem é o autor?** A edição, identidade, artes e melhorias são mantidas por café. O código-base HyperSmooth 2.5.0 tem atribuição preservada a Hakimi Tech Lab (wangxu1428), sob licença MIT.
