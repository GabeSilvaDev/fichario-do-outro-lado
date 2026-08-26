# Verificação manual da mesa online

As regras do Firestore **são** a segurança deste app — não existe servidor.
Este roteiro confere, com dois aparelhos, que elas fazem o que prometem.
Rode depois de publicar as regras e a cada mudança nelas.

Precisa de: dois aparelhos (ou um aparelho + o navegador em aba anônima),
já com o Firebase configurado (ver README).

---

## 1 · Criar, entrar e presença

| # | No aparelho A (mestre) | No aparelho B (jogador) | Esperado |
|---|---|---|---|
| 1.1 | Mesa → Criar mesa, nome "Teste" | — | Aparece o código `ORDO-XXXX` e o diálogo da chave, que **não fecha tocando fora** |
| 1.2 | — | Mesa → Entrar com código, digita minúsculo e sem hífen | Entra igual: o código é normalizado |
| 1.3 | — | — | Os dois aparecem em "Quem está na mesa" com bolinha verde |
| 1.4 | — | Fecha o app por 2 min | No A, a bolinha de B fica cinza (presença vale 90s) |
| 1.5 | — | Tenta entrar com um código inventado | "Não encontrei essa mesa." |

## 2 · Fichas em tempo real

| # | A (mestre) | B (jogador) | Esperado |
|---|---|---|---|
| 2.1 | — | Publica uma ficha | Em segundos ela aparece no painel do mestre, com PV/SAN/PE |
| 2.2 | — | Toca em −1 PV três vezes | O painel de A muda sozinho em ~2s (a janela do espelho agrupa as escritas) |
| 2.3 | Abre a ficha de B | — | Abre **somente leitura**: contadores e campos não respondem |
| 2.4 | — | "Tirar da mesa" | Some do painel de A; a ficha continua no aparelho de B |
| 2.5 | Publica a própria ficha | — | O mestre também joga: a ficha dele aparece no painel |

**Um jogador não pode ver a ficha de outro.** Com um terceiro aparelho C na
mesa, a ficha publicada por B nunca aparece para C — a regra corta no
servidor, não na tela.

## 3 · Rolagens (o "Últimos testes")

| # | Onde | Ação | Esperado |
|---|---|---|---|
| 3.1 | B | Rola uma perícia na ficha | Aparece no feed do mestre na hora: nome, perícia, dados e total |
| 3.2 | B | Rola com atributo 0 | O feed mostra `2d20↓` — pegou o pior, como manda o livro |
| 3.3 | B | Rola um ataque e o dano | Duas entradas: "Ataque: X" e "Dano: X" |
| 3.4 | A | Abre a ficha de B (leitura) e rola algo | **Não** entra no feed: o dado é de quem joga a ficha |
| 3.5 | B | Fica sem internet e rola | O resultado aparece normal na tela dele; só não vai para o feed |

## 4 · Imagens (mural e galeria)

| # | A (mestre) | B (jogador) | Esperado |
|---|---|---|---|
| 4.1 | Mural → Mostrar imagem → "Mostrar agora" | — | A imagem abre **em tela cheia sozinha** no aparelho de B |
| 4.2 | — | Fecha a imagem | Ela continua no cartão do mural, para reabrir quando quiser |
| 4.3 | — | Reinicia o app | A imagem **não** reabre sozinha de novo (só uma vez por destaque) |
| 4.4 | "Mostrar agora" numa imagem da galeria | — | Troca o destaque e abre a nova em B |
| 4.5 | Tirar do mural | — | O cartão some nos dois |
| 4.6 | Guardar na galeria (sem mostrar) | — | Aparece na galeria de todos, sem abrir na tela de ninguém |
| 4.7 | — | Tenta apagar uma imagem | Não existe botão para ele; se forçado, a regra recusa |

## 5 · Fim de sessão e recuperação

| # | Ação | Esperado |
|---|---|---|
| 5.1 | A: Encerrar sessão | Todos saem; as fichas publicadas e as rolagens somem; **a galeria e o código continuam** |
| 5.2 | A e B: voltar pela lista de mesas conhecidas | Entram de novo sem digitar código; a galeria está lá |
| 5.3 | A: limpar os dados do app e "Já sou o mestre desta mesa" com código + chave | Volta a ser mestre |
| 5.4 | Mesmo passo com a chave errada | "Chave não confere." |
| 5.5 | A: Apagar mesa (exige digitar o nome) | Some para sempre; em B aparece "Esta mesa foi apagada" e ele volta ao modo offline |
| 5.6 | A: Trocar código | O código antigo para de funcionar na hora |

## 6 · O que tem que continuar funcionando offline

Sem internet, ou num build sem Firebase configurado:

- abrir, criar, editar, exportar e importar fichas — tudo igual;
- rolar dados na ficha;
- a aba Mesa avisa o que houve e oferece "Tentar de novo" / "Sair da mesa",
  sem travar o resto do app.
