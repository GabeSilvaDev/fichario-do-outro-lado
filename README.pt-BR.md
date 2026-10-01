<div align="center">

<img src="docs/imagens/banner.jpg" alt="Fichário do Outro Lado" width="100%">

# Fichário do Outro Lado

**Ficha de personagem + mesa online ao vivo para *Ordem Paranormal RPG*.**<br>
O mestre vê as fichas e as rolagens dos jogadores em tempo real, e mostra imagens que abrem na tela de todo mundo.

[![Jogar no navegador](https://img.shields.io/badge/%E2%96%B6%20Jogar%20agora-PWA-7c4dff?style=for-the-badge)](https://gabesilvadev.github.io/fichario-do-outro-lado/)

[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![CI](https://github.com/GabeSilvaDev/fichario-do-outro-lado/actions/workflows/ci.yml/badge.svg)](https://github.com/GabeSilvaDev/fichario-do-outro-lado/actions/workflows/ci.yml)
[![Plataformas](https://img.shields.io/badge/Android%20%7C%20Web%20%7C%20PWA-4a3a7a)](#como-usar)
[![Offline](https://img.shields.io/badge/offline-por%20padr%C3%A3o-2e7d32)](#funcionalidades)
[![Firebase](https://img.shields.io/badge/mesa%20online-Firestore-ffca28?logo=firebase&logoColor=black)](#mesa-online-firebase)
[![Licença](https://img.shields.io/badge/licen%C3%A7a-Comunidade%20OP-8e24aa)](LICENCA.md)
[![Release](https://img.shields.io/github/v/release/GabeSilvaDev/fichario-do-outro-lado?label=release&color=555)](https://github.com/GabeSilvaDev/fichario-do-outro-lado/releases/latest)

[English](README.md) · **Português (Brasil)**

<sub>Este é um conteúdo não oficial, publicado sob a Licença da Comunidade de Ordem Paranormal. Contém material gerado por inteligência artificial.<br>
Ferramenta de fã, sem vínculo com os detentores dos direitos — veja <a href="LICENCA.md">LICENCA.md</a>.</sub>

</div>

<br>

<img src="docs/imagens/showcase.png" alt="Ficha, rolagem de perícia, bestiário, mesa do mestre e painel ao vivo" width="100%">

<br>

## Destaques

- **Ficha completa** — 6 abas, 28 perícias, ataques, habilidades, rituais, inventário com carga, e máximos de PV/SAN/PE **calculados automaticamente** a partir de classe, NEX e atributos.
- **Ficha que se confere sozinha** — toda mudança é comparada com o livro (v1.3 e *Sobrevivendo ao Horror*): o que está fora da regra ou faltando aparece na hora, e ganhos de NEX, habilidades de trilha, Transcender, condições e estados se aplicam sozinhos.
- **Criação guiada** — assistente em 6 passos que cobra as regras do livro (origem, classe, pontos e aumentos de atributo, cota de perícias, Grau de Treinamento) e mostra os números finais antes de criar.
- **Rolagem no toque** — perícia rola `Xd20` pegando o melhor, ataque rola teste + dano, crítico e desastre marcados. O dado rápido aceita `2d6+3` e a sintaxe `/AGI` da ficha oficial.
- **Bestiário com 150 fichas** — ameaças dos livros, NPCs nomeados das campanhas publicadas, aliados e figurantes, todos como bloco completo que você importa como NPC em um toque.
- **Catálogo do sistema** — os 81 rituais, a tabela de armas inteira (41 linhas) e 278 poderes/habilidades de trilha dos dois livros, direto para a ficha.
- **Mesa online** — fichas e rolagens espelhadas para o mestre em ~2 s, mural de imagens em tela cheia e mapa da cena ao vivo com peças arrastáveis. Sem conta: jogador entra com um código `ORDO-XXXX`.
- **Offline por padrão** — fichas ficam no aparelho (Hive), exporta/importa `.json`. A mesa online é opcional.
- **Roda em qualquer lugar** — APK Android ou PWA instalável no iPhone, Android e PC.

## Telas

<details open>
<summary><b>Fichas e criação de personagem</b></summary>
<br>

| Suas fichas | Assistente (1/6) | Classe e NEX |
|:---:|:---:|:---:|
| <img src="docs/imagens/fichas-lista.png" width="260" alt="Lista de fichas com agente e NPC"> | <img src="docs/imagens/wizard-identidade.png" width="260" alt="Assistente de criação — identidade"> | <img src="docs/imagens/wizard-classe-nex.png" width="260" alt="Assistente — NEX e classe"> |

| Atributos | Perícias | Conferir e criar |
|:---:|:---:|:---:|
| <img src="docs/imagens/wizard-atributos.png" width="260" alt="Assistente — distribuição de atributos"> | <img src="docs/imagens/wizard-pericias.png" width="260" alt="Assistente — escolha de perícias"> | <img src="docs/imagens/wizard-conferir.png" width="260" alt="Assistente — resumo com PV/SAN/PE calculados"> |

</details>

<details>
<summary><b>A ficha em jogo</b></summary>
<br>

| Ficha completa | 28 perícias | Rolagem no toque |
|:---:|:---:|:---:|
| <img src="docs/imagens/ficha-geral.png" width="260" alt="Ficha — aba geral com recursos"> | <img src="docs/imagens/ficha-pericias.png" width="260" alt="Ficha — perícias com grau de treino"> | <img src="docs/imagens/rolagem.png" width="260" alt="Rolagem 2d20 pegando o melhor"> |

</details>

<details>
<summary><b>Bestiário e catálogo</b></summary>
<br>

| Bestiário (150 fichas) | Ficha de ameaça | Habilidades em notação de mesa |
|:---:|:---:|:---:|
| <img src="docs/imagens/bestiario.png" width="260" alt="Bestiário da campanha por grupos"> | <img src="docs/imagens/npc-ficha.png" width="260" alt="Ameaça importada como NPC"> | <img src="docs/imagens/npc-poderes.png" width="260" alt="Habilidades da ameaça"> |

| 81 rituais | Tabela de armas |
|:---:|:---:|
| <img src="docs/imagens/catalogo-rituais.png" width="260" alt="Catálogo de rituais por elemento e círculo"> | <img src="docs/imagens/catalogo-armas.png" width="260" alt="Catálogo de armas"> |

</details>

<details>
<summary><b>Mesa online</b></summary>
<br>

| Criar ou entrar | A mesa do mestre | A mesa do jogador |
|:---:|:---:|:---:|
| <img src="docs/imagens/mesa-entrar.png" width="260" alt="Criar mesa ou entrar com código"> | <img src="docs/imagens/mesa-mestre.png" width="260" alt="Mesa do mestre com código ORDO e mapa"> | <img src="docs/imagens/mesa-jogador.png" width="260" alt="Mesa do jogador com presença ao vivo"> |

| Mural em tela cheia | Painel do mestre ao vivo | Plantas do mapa |
|:---:|:---:|:---:|
| <img src="docs/imagens/mural-tela-cheia.png" width="260" alt="Imagem do mestre aberta na tela do jogador"> | <img src="docs/imagens/painel-mestre.png" width="260" alt="Ficha publicada e feed de testes no painel do mestre"> | <img src="docs/imagens/mapa-biblioteca.png" width="260" alt="Biblioteca de plantas da mesa"> |

*As telas da mesa online são reais: duas sessões ao vivo no Firestore — o mestre mostrou a imagem e ela abriu na tela da jogadora; a ficha publicada e as rolagens entraram no painel do mestre na hora.*

</details>

## Funcionalidades

### Para o jogador

- **Jogador ou NPC** — a mesma ficha serve para os dois. NPC/criatura nasce em modo livre e **não vai para a mesa online**; o bestiário é do mestre.
- **Modo livre (mestre)** — o botão de regras na barra solta os limites do livro. Os avisos continuam aparecendo, mas nada trava: atributo vai a 20, perícia sem cota, classe e NEX em qualquer combinação. É como se monta criatura, NPC e personagem que já passou do que a criação permite.
- **Assistente de criação em 6 passos**, cobrando as regras do livro: identidade → origem → classe e NEX → atributos (4 pontos para agente, 3 para civil; dá para zerar um atributo em troca de mais um ponto) → perícias (as da origem e da classe já vêm marcadas; você escolhe `base + Intelecto`) → conferir. Cada passo só libera o próximo quando fecha, e a última tela mostra PV/SAN/PE já calculados antes de criar. Começar acima de NEX 5% já dá os **Aumentos de Atributo** daquele NEX (20/50/80/95%, até 5 — até 3 no Sobrevivente) e o **Grau de Treinamento** (35/70%: veterano +10, expert +15), a trilha sai do catálogo, e tudo é conferido de novo ao tocar em *Criar*. Depois disso a ficha é sua e tudo vira edição livre. Os mesmos dois botões (tipo e regras) existem na tela da ficha: dá para promover um personagem a NPC, ou soltar os limites de uma ficha já criada, quando quiser.
- **Ficha completa em 6 abas** — identidade (classe/origem/trilha/patente, nacionalidade, idade), NEX, atributos, PV/SAN/PE com máximos **calculados automaticamente** (classe + NEX + Vigor/Presença, com override manual), defesa e deslocamento com penalidade de sobrecarga, as 28 perícias com grau de treinamento, ataques (tipo de dano, margem e multiplicador de crítico, alcance, especial), habilidades, rituais, inventário com carga (5×Força) e limite de itens por patente, proficiências e a aba **Sobre** (história, aparência, primeiro encontro paranormal, fobias, favoritos, personalidade, pior pesadelo, anotações).
- **Escolher classe ou origem preenche a ficha** — perícias treinadas, proficiências e o poder/habilidade entram sozinhos, com confirmação. Trocar oferece tirar o que a anterior deixou, e o Sobrevivente que vira agente mantém o que tinha (*Treinamento Especial*).
- **Painel de pendências** — no topo da ficha (e como selo na barra) tudo que está fora da regra ou falta resolver: pontos de atributo, cota de perícias e graus, trilha em 10%, poderes por NEX, afinidade em 50%, rituais por círculo, carga, limite de itens da patente, proficiências, máximo fixo desatualizado. Cada mudança que cria uma pendência nova avisa na hora.
- **Progressão automática** — subir de NEX lista o que cada passo dá (poder de classe, trilha, Aumento de Atributo, Grau de Treinamento, Versatilidade, Afinidade); PV/SAN/PE atuais acompanham os máximos guardando o dano já sofrido; habilidades de trilha entram e saem sozinhas; cada poder paranormal conta como Transcender e tira a SAN daquele NEX.
- **Catálogo de poderes** — 278 poderes e 27 trilhas (de classe, gerais, paranormais, habilidades de trilha) em notação de mesa, com pré-requisito conferido; o efeito numérico (Defesa, PV por NEX, bônus em perícia, resistência a dano…) se aplica sozinho.
- **Estados e condições** — machucado, morrendo (conta 3 turnos → morto), perturbado e enlouquecendo saem dos recursos; as 33 condições do livro aplicam a penalidade em Defesa, dados e deslocamento sem somar efeitos iguais; *Fim de cena* limpa temporários e condições.
- **Regras nas rolagens** — −5 de sobrecarga e de proteção pesada, −2d20 sem proficiência, Força no dano corpo a corpo, margem e multiplicador lidos da arma, botão de crítico que multiplica só os dados da arma; PV temporário sai primeiro no dano e o atual nunca passa do máximo.
- **Conjurar rituais** — gasta PE, respeita o limite de PE, mostra a DT e rola o custo do paranormal (Ocultismo DT 20 + custo; ritual de Medo custa SAN permanente).
- **Regras opcionais** — idade variada com desvantagens, ferimentos debilitantes e *Jogando sem Sanidade* (Pontos de Determinação), por ficha.
- **Estado de mesa** — marque *em combate* / *morto*, e esconda Vida, Sanidade ou Esforço do painel do mestre quando o personagem joga com recurso secreto.
- **Rolagem no toque** — perícia rola `Xd20` pegando o melhor (atributo 0: 2d20 pelo pior) + bônus de treinamento; ataque rola teste e dano. Crítico e desastre marcados. O **dado rápido** aceita `2d6+3` e a sintaxe `/AGI` da ficha oficial.
- **Bestiário da campanha** — 150 fichas prontas em 16 grupos: as ameaças dos livros por elemento (Sangue, Morte, Conhecimento, Energia), gente e tropa, animais, os NPCs nomeados de *Vendeta Oculta 1 e 2*, *Casos Paranormais* e missões extras, mais os aliados da Ordem e os figurantes escritos para esta mesa. Ficha de ameaça vem **completa**: VD, categoria e tamanho, presença perturbadora, sentidos, Defesa e PV impressos, resistências e vulnerabilidades, os testes do bloco, cada ataque com o teste que se rola (`3d20+10`) e o dano, e o que cada habilidade faz — em notação de mesa. Importa tudo, um grupo ou uma ficha; tudo entra como NPC em modo livre. Reimportar atualiza a mesma ficha em vez de duplicar.
- **Catálogo do sistema** — os **81 rituais** (todos, dos quatro elementos + Medo, 1º ao 4º círculo) com custo, execução, alcance, alvo, duração, resistência, efeito e as ampliações discente/verdadeiro; e a **tabela de armas** inteira (41 linhas) com dano, crítico, alcance, tipo e espaços, mais as proteções. Dá para consultar na hora e **pôr direto na ficha**: o ritual entra com tudo preenchido, a arma vira ataque com a perícia, dano e crítico certos.
- **Armazenamento local** — fichas ficam no aparelho (Hive), exporta/importa `.json`. Sem conta.

### Para o mestre — a mesa online

- Cria a mesa, dita o código (`ORDO-XXXX`) e recebe uma chave de recuperação. Jogadores entram pelo código, sem conta (login anônimo).
- **Fichas em tempo real** — o jogador publica a ficha e tudo que ele marca (PV, SAN, PE, condições, inventário…) aparece no painel do mestre em ~2 s — de qualquer aba, mesmo depois de reabrir o app — com selos de *combate*, *morto*, *morrendo*, *machucado*, *enlouquecendo* e *fora da regra*, respeitando o que o jogador escolheu esconder. A ficha aberta pelo painel também acompanha o jogador ao vivo.
- **Últimos testes** — toda rolagem feita numa ficha publicada entra no feed da mesa na hora: quem rolou, o quê, os dados e o total.
- **Mural de imagens** — o mestre manda uma imagem e ela **abre em tela cheia no aparelho de todos**: mapa, retrato de NPC, pista. A galeria guarda o acervo da campanha entre sessões.
- **Mapa da cena** — tela à parte dentro da mesa, ao vivo. As plantas ficam numa **biblioteca própria da mesa**, separada da galeria do mural: imagem de mural abre na cara de todo mundo, planta de mapa fica de pé para consulta. O mestre sobe a planta, escolhe qual está em jogo e põe as peças: **agente publicado entra com o retrato da ficha**, **NPC do bestiário entra com o brasão dele**, e ainda dá para criar peça avulsa (marcador, refém, porta). Tocar numa peça abre **tamanho** (0,4× a 3× — criatura Enorme não ocupa o mesmo círculo que um agente), marca de ameaça e remover. **Só o mestre move; jogador só olha**, e quem sai da tela volta com tudo no lugar — a posição mora no Firestore, não no aparelho. As regras do Firestore garantem isso, não só a interface.

A arquitetura da mesa é a mesma do app [Mago: A Ascensão](https://github.com/GabeSilvaDev/mago-ficha): Firestore + regras de segurança como única autoridade, imagens em base64 dentro dos documentos (sem Storage pago), presença por batimento, chave de recuperação da mesa.

## Como usar

### Jogar agora

**[gabesilvadev.github.io/fichario-do-outro-lado](https://gabesilvadev.github.io/fichario-do-outro-lado/)** — funciona no iPhone, Android e PC, sem instalar nada. No iPhone, abra no Safari e use *Compartilhar → Adicionar à Tela de Início* para virar app.

### Android

Baixe o APK mais recente em **[Releases](https://github.com/GabeSilvaDev/fichario-do-outro-lado/releases/latest)** e instale (libere "fontes desconhecidas" uma vez). Ele é assinado com a chave de release do projeto, então cada versão nova instala por cima da anterior sem perder as fichas.

### Compilar do código

Sem Flutter instalado — tudo roda pelo Docker:

```bash
docker compose up -d
docker compose exec flutter flutter pub get

# web com hot reload em http://localhost:8093
docker compose exec flutter flutter run -d web-server \
  --web-port 8093 --web-hostname 0.0.0.0

# APK Android
docker compose exec flutter flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# instalar/atualizar no celular com depuração USB ligada
docker run --rm --privileged -v /dev/bus/usb:/dev/bus/usb -v "$PWD":/app -w /app \
  ghcr.io/cirruslabs/flutter:stable \
  adb install -r build/app/outputs/flutter-apk/app-release.apk

# web estático (hospede a pasta build/web onde quiser)
docker compose exec flutter flutter build web --release
```

### Rodar os testes

```bash
docker compose exec flutter flutter test
```

### Atualizar o app no GitHub Pages

O site em <https://gabesilvadev.github.io/fichario-do-outro-lado/> é a pasta `build/web` publicada na branch `gh-pages`:

```bash
docker compose exec flutter flutter build web --release \
  --base-href /fichario-do-outro-lado/
cd build/web && git init -b gh-pages && git add -A \
  && git commit -m "web build" \
  && git push -f git@github.com:GabeSilvaDev/fichario-do-outro-lado.git gh-pages
```

Para a mesa online funcionar no site, o domínio `gabesilvadev.github.io` precisa estar em **Authentication → Settings → Authorized domains** no console do Firebase (uma vez só).

## Mesa online (Firebase)

O projeto **`ordem-paranormal-mesa`** está de pé e ligado ao app:

| Item | Estado |
|---|---|
| Firestore | criado em `southamerica-east1` (São Paulo) |
| Authentication | login **anônimo** ativado |
| Regras de segurança | **publicadas** (o conteúdo de `firestore.rules`) |
| App Android | `com.gabesilvadev.ordem_paranormal` registrado (id interno antigo: trocar obrigaria a reinstalar do zero e perder as fichas do aparelho) |
| App Web | registrado |
| Credenciais | `lib/firebase_options.dart` + `android/app/google-services.json` |

Não precisa fazer nada: criar mesa no app já grava no Firestore.

**Se mudar as regras**, republique — pelo console (Firestore → Regras → Publicar) ou por linha de comando (`firebase.json` e `.firebaserc` estão no repositório):

```bash
npx firebase-tools login
npx firebase-tools deploy --only firestore:rules --project ordem-paranormal-mesa
```

`firestore.rules` é a única segurança do sistema: só quem está na mesa publica ficha, o dono escreve a própria e o mestre lê; rolagem só em nome próprio; galeria e mural só do mestre; a chave da mesa fica num documento que ninguém consegue ler.

### Usar o seu próprio projeto Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<outro-projeto> --platforms=android,web
```

Depois ative Authentication → Anonymous, crie o Firestore e publique as regras no projeto novo.

## Assinatura do release

O app é assinado com uma chave própria (`android/ordem-paranormal.jks`). Sem ela, o Flutter assina o release com a chave de *debug*, que muda a cada máquina e a cada container — e aí o Android recusa a instalação seguinte com `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, obrigando a desinstalar o app. Desinstalar apaga as fichas do aparelho.

Com a chave fixa, **cada build novo instala por cima do anterior** e os jogadores não perdem nada. Suba o `version:` do `pubspec.yaml` a cada release (`0.2.0+2` → `0.2.1+3`).

`key.properties` e o `.jks` estão no `.gitignore`: **guarde os dois num backup**. Se você perder essa chave, a única saída é publicar com uma nova — e todo mundo precisa desinstalar antes de atualizar.

## Estrutura do projeto

```
lib/
├── main.dart
├── theme.dart                  tema Ordem Paranormal (escuro, roxo/dourado)
├── firebase_options.dart       credenciais de ordem-paranormal-mesa
├── data/dados_op.dart          classes (no código) + perícias, origens,
│                               patentes (assets)
├── models/
│   ├── ficha_op.dart           a ficha (Map + cálculos de PV/SAN/PE/carga)
│   ├── normalizar.dart         conserta ficha importada/antiga ao abrir
│   └── rolagem.dart            motor de dados (Xd20 melhor/pior, expressões)
├── regras/                     o motor de regras
│   ├── pendencias.dart         o que está fora da regra ou faltando
│   ├── efeitos.dart            origem, poderes e condições somados
│   ├── condicoes.dart          as condições do livro e penalidades
│   ├── poderes.dart            modelo do catálogo de poderes/trilhas
│   └── opcionais.dart          idade, ferimentos, Determinação
├── store/ficha_store.dart      fichas no Hive + observador do espelho
├── screens/
│   ├── home_screen.dart        abas Fichas | Mesa
│   ├── bestiario_screen.dart   o elenco pronto (asset) → fichas do aparelho
│   ├── licenca_screen.dart     selo, avisos e privacidade
│   ├── wizard_screen.dart      assistente de criação (6 passos)
│   ├── poderes_screen.dart     escolher poder do catálogo
│   └── ficha_screen.dart       a ficha em 6 abas, edição e leitura
├── widgets/                    retrato, contadores PV/SAN/PE, visualizador,
│                               painel de pendências
└── mesa/                       a mesa online
    ├── mesa_service.dart       interface (contrato = firestore.rules)
    ├── mesa_firestore.dart     implementação real
    ├── sessao_mesa.dart        espelho + presença vivos em qualquer aba
    ├── espelho_ficha.dart      ficha → mesa com janela de 2s
    ├── ponte_rolagens.dart     rolagem → feed da mesa
    ├── ouvinte_mural.dart      imagem do mestre abre sozinha
    ├── imagem_mural.dart       encolhe imagem p/ caber no documento
    ├── ouvinte_mapa.dart       mapa novo abre sozinho na tela de todos
    ├── codigo.dart             ORDO-XXXX ditável em voz alta
    ├── chave_mesa.dart         chave de recuperação da mesa
    └── telas/                  aba mesa, painel do mestre, galeria, mural,
                                mapa da cena (peças arrastáveis)
```

## Dados do sistema

Só mecânica e nomes, nada de texto de livro: 28 perícias com atributo-base, 26 origens (o que cada uma treina e o efeito do poder), 5 patentes com limites de item por categoria — em `assets/data/*.json` — e as 4 classes com as fórmulas de PV/PE/SAN por NEX, que ficam **no código** (`lib/data/dados_op.dart`): um asset que falhasse ao carregar faria os máximos caírem para o valor atual sem avisar ninguém.

Poderes e trilhas (`assets/catalogo/poderes.json` do livro básico, `poderes_sah.json` de *Sobrevivendo ao Horror*) trazem o efeito em notação de mesa e um bloco de máquina (`efeitos`) que a ficha aplica sozinha.

Os efeitos de poder e habilidade estão em notação de mesa — `2 PE → +5 em Ciências ou Investigação. 1×/cena.` — escrita aqui, não copiada. A licença libera nomes e terminologia do sistema, e proíbe reproduzir os textos dos livros; ver [LICENCA.md](LICENCA.md).

### De onde saem os números das ameaças

```bash
# 1. lê os SEUS PDFs e extrai só a mecânica
python3 ../../Ordem/App-Mestre/ferramentas/extrair_ameacas.py   # ameaças
python3 ../../Ordem/App-Mestre/ferramentas/extrair_rituais.py   # rituais
python3 ../../Ordem/App-Mestre/ferramentas/build_regras.py      # tabela de armas
# saem em Ordem/App-Mestre/dados/*-cru.json — arquivos LOCAIS, no .gitignore

# 2. junta esses números com o texto escrito à mão
#    (ferramentas/notacao_ameacas.py e ferramentas/notacao_rituais.py)
python3 ferramentas/gerar_catalogo.py    # rituais + armas
python3 ferramentas/gerar_bestiario.py   # bestiário (usa o catálogo)
```

O bestiário depende do catálogo: **toda ficha que conjura já vem com os rituais dentro**, um por um, com custo, execução, alcance, duração, DT e efeito. Vale para quem o livro descreve por faixa ("todos os rituais de Morte até o 3º círculo" → os 15), por escolha ("escolha 2 de 1º círculo" → os 24 possíveis, com a nota mandando escolher) e por lista fechada (os 6 rituais que Giordano usa para fugir em VO1). Um teste reprova qualquer ficha que fale em conjurar e chegue sem lista.

O `ameacas-cru.json` tem trecho de livro e por isso **não é distribuído**; o que entra no app é número + notação própria. Um teste confere ficha por ficha (`test/bestiario_test.dart`): toda ameaça precisa de PV impresso, Defesa, categoria e pelo menos um ataque ou habilidade, e todo ataque precisa do teste que se rola.

As fórmulas foram conferidas contra a ficha oficial do [fichasop.com](https://fichasop.com): um Combatente NEX 35% com Vigor 3 e Presença 2 dá **PV 65 · SAN 30 · PE 28** nos dois. `test/regras_op_test.dart` trava esses números.

## Licença

**Fichário do Outro Lado** é conteúdo de fã gratuito, feito por um jogador para a própria mesa, publicado sob a [Licença da Comunidade de Ordem Paranormal](https://ordemparanormal.com.br/licenca) v1.0 na categoria *conteúdo de fã gratuito → fichas virtuais para VTTs*. Não é produto oficial e não tem parceria, aprovação nem endosso de ninguém ligado a Ordem Paranormal. O universo de Ordem Paranormal é de Rafael "Cellbit" Lange.

Regras de uso, créditos, privacidade (LGPD) e como cada condição da licença é cumprida: **[LICENCA.md](LICENCA.md)**.
