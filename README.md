<div align="center">

<img src="assets/licenca/selo-comunidade.png" width="150" alt="Selo da Licença da Comunidade de Ordem Paranormal">

# Fichário do Outro Lado

**Este é um conteúdo não oficial, publicado sob a Licença da Comunidade de
Ordem Paranormal**

*Contém material gerado por inteligência artificial*

**Ficha de personagem com mesa online: o mestre vê as fichas e as rolagens
dos jogadores em tempo real, e mostra imagens que abrem na tela de todo
mundo.**

Flutter · Android · Web/PWA · offline por padrão · mesa online opcional ·
gratuito

Ferramenta de fã, sem vínculo com os detentores dos direitos.
Regras de uso, créditos e privacidade: **[LICENCA.md](LICENCA.md)**.

</div>

---

## O que o app faz

**Para o jogador**
- **Jogador ou NPC**: a mesma ficha serve para os dois. NPC/criatura nasce
  em modo livre e **não vai para a mesa online** — o bestiário é do mestre.
- **Modo livre (mestre)**: o botão de regras na barra solta os limites do
  livro. Os avisos continuam aparecendo, mas nada trava: atributo vai a 20,
  perícia sem cota, classe e NEX em qualquer combinação. É como se monta
  criatura, NPC e personagem que já passou do que a criação permite.
- **Assistente de criação** em 6 passos, cobrando as regras do livro:
  identidade → origem → classe e NEX → atributos (4 pontos para agente,
  3 para civil; dá para zerar um atributo em troca de mais um ponto) →
  perícias (as da origem e da classe já vêm marcadas; você escolhe
  `base + Intelecto`) → conferir. Cada passo só libera o próximo quando
  fecha, e a última tela mostra PV/SAN/PE já calculados antes de criar.
  Depois disso a ficha é sua e tudo vira edição livre. Os mesmos dois
  botões (tipo e regras) existem na tela da ficha: dá para promover um
  personagem a NPC, ou soltar os limites de uma ficha já criada, quando
  quiser.
- Ficha completa em 6 abas: identidade (classe/origem/trilha/patente,
  nacionalidade, idade), NEX, atributos, PV/SAN/PE com máximos
  **calculados automaticamente** (classe + NEX + Vigor/Presença, com
  override manual), defesa e deslocamento com penalidade de sobrecarga,
  as 28 perícias com grau de treinamento, ataques (tipo de dano, margem e
  multiplicador de crítico, alcance, especial), habilidades, rituais,
  inventário com carga (5×Força) e limite de itens por patente,
  proficiências e a aba **Sobre** (história, aparência, primeiro encontro
  paranormal, fobias, favoritos, personalidade, pior pesadelo, anotações).
- **Escolher classe ou origem preenche a ficha**: perícias treinadas,
  proficiências e o poder/habilidade entram sozinhos, com confirmação —
  nada é apagado do que você já tinha.
- **Estado de mesa**: marque *em combate* / *morto*, e esconda Vida,
  Sanidade ou Esforço do painel do mestre quando o personagem joga com
  recurso secreto.
- **Rolagem no toque**: perícia rola `Xd20` pegando o melhor (atributo 0:
  2d20 pelo pior) + bônus de treinamento; ataque rola teste e dano.
  Crítico e desastre marcados. Tem também o **dado rápido**, que aceita
  `2d6+3` e a sintaxe `/AGI` da ficha oficial.
- **Bestiário da campanha**: 150 fichas prontas em 16 grupos — as ameaças
  dos livros por elemento (Sangue, Morte, Conhecimento, Energia), gente e
  tropa, animais, os NPCs nomeados de Vendeta Oculta 1 e 2, Casos
  Paranormais, missões extras, mais os aliados da Ordem e os figurantes
  escritos para esta mesa. Ficha de ameaça vem **completa**: VD, categoria e
  tamanho, presença perturbadora, sentidos, Defesa e PV impressos,
  resistências e vulnerabilidades, os testes do bloco, cada ataque com o
  teste que se rola (`3d20+10`) e o dano, e o que cada habilidade faz —
  em notação de mesa. Importa tudo, um grupo ou uma ficha; tudo entra como
  NPC em modo livre. Reimportar atualiza a mesma ficha em vez de duplicar.
- **Catálogo do sistema**: os **81 rituais** (todos, dos quatro elementos +
  Medo, 1º ao 4º círculo) com custo, execução, alcance, alvo, duração,
  resistência, efeito e as ampliações discente/verdadeiro; e a **tabela de
  armas** inteira (41 linhas) com dano, crítico, alcance, tipo e espaços,
  mais as proteções. Dá para consultar na hora e **pôr direto na ficha**:
  o ritual entra com tudo preenchido, a arma vira ataque com a perícia,
  dano e crítico certos.
- Fichas ficam no aparelho (Hive), exporta/importa `.json`. Sem conta.

**Para o mestre (a mesa online)**
- Cria a mesa, dita o código (`ORDO-XXXX`) e recebe uma chave de
  recuperação. Jogadores entram pelo código, sem conta (login anônimo).
- **Fichas em tempo real**: o jogador publica a ficha e tudo que ele marca
  (PV, SAN, PE, inventário…) aparece no painel do mestre em ~2s — com selo
  de *combate* / *morto*, e respeitando o que o jogador escolheu esconder.
- **Últimos testes**: toda rolagem feita numa ficha publicada entra no feed
  da mesa na hora — quem rolou, o quê, os dados e o total.
- **Mural de imagens**: o mestre manda uma imagem e ela **abre em tela cheia
  no aparelho de todos** — mapa, retrato de NPC, pista. A galeria guarda o
  acervo da campanha entre sessões.
- **Mapa da cena**: tela à parte dentro da mesa, ao vivo. As plantas ficam
  numa **biblioteca própria da mesa**, separada da galeria do mural —
  imagem de mural abre na cara de todo mundo, planta de mapa fica de pé
  para consulta. O mestre sobe a planta, escolhe qual está em jogo e põe as
  peças: **agente publicado entra com o retrato da ficha**, **NPC do
  bestiário entra com o brasão dele**, e ainda dá para criar peça avulsa
  (marcador, refém, porta). Tocar numa peça abre **tamanho** (0,4× a 3× —
  criatura Enorme não ocupa o mesmo círculo que um agente), marca de ameaça
  e remover. **Só o mestre move; jogador só olha**, e quem sai da tela
  volta com tudo no lugar — a posição mora no Firestore, não no aparelho.
  As regras do Firestore garantem isso, não só a interface.

A arquitetura da mesa é a mesma do app
[Mago: A Ascensão](../MagoAAssencao/): Firestore + regras de segurança como
única autoridade, imagens em base64 dentro dos documentos (sem Storage
pago), presença por batimento, chave de recuperação da mesa.

## Rodar

Sem Flutter instalado, use o Docker (mesmo fluxo do app do Mago):

```bash
docker compose up -d
docker compose exec flutter flutter pub get

# web com hot reload em http://localhost:8093
docker compose exec flutter flutter run -d web-server \
  --web-port 8093 --web-hostname 0.0.0.0

# APK
docker compose exec flutter flutter build apk --release
# sai em build/app/outputs/flutter-apk/app-release.apk

# instalar/atualizar no celular com depuração USB ligada
docker run --rm --privileged -v /dev/bus/usb:/dev/bus/usb -v "$PWD":/app -w /app \
  ghcr.io/cirruslabs/flutter:stable \
  adb install -r build/app/outputs/flutter-apk/app-release.apk

# web estático (hospede a pasta build/web onde quiser)
docker compose exec flutter flutter build web --release
```

## Mesa online — já configurada

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

**Se mudar as regras**, republique — pelo console (Firestore → Regras →
Publicar) ou por linha de comando:

```bash
firebase deploy --only firestore:rules --project ordem-paranormal-mesa
```

`firestore.rules` é a única segurança do sistema: dono escreve a própria
ficha e o mestre lê; rolagem só em nome próprio; galeria e mural só do
mestre; a chave da mesa fica num documento que ninguém consegue ler.

### Trocar de projeto Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<outro-projeto> --platforms=android,web
```
Depois ative Authentication → Anonymous, crie o Firestore e publique as
regras no projeto novo.

## Assinatura — por que existe `android/key.properties`

O app é assinado com uma chave própria (`android/ordem-paranormal.jks`).
Sem ela, o Flutter assina o release com a chave de *debug*, que muda a cada
máquina e a cada container — e aí o Android recusa a instalação seguinte
com `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, obrigando a desinstalar o app.
Desinstalar apaga as fichas do aparelho.

Com a chave fixa, **cada build novo instala por cima do anterior** e os
jogadores não perdem nada. Suba o `version:` do `pubspec.yaml` a cada
release (`0.2.0+2` → `0.2.1+3`).

`key.properties` e o `.jks` estão no `.gitignore`: **guarde os dois num
backup**. Se você perder essa chave, a única saída é publicar com uma nova
— e todo mundo precisa desinstalar antes de atualizar.

## Estrutura

```
lib/
├── main.dart
├── theme.dart                  tema Ordem Paranormal (escuro, roxo/dourado)
├── firebase_options.dart       credenciais de ordem-paranormal-mesa
├── data/dados_op.dart          classes (no código) + perícias, origens,
│                               patentes (assets)
├── models/
│   ├── ficha_op.dart           a ficha (Map + cálculos de PV/SAN/PE/carga)
│   └── rolagem.dart            motor de dados (Xd20 melhor/pior, expressões)
├── store/ficha_store.dart      fichas no Hive + observador do espelho
├── screens/
│   ├── home_screen.dart        abas Fichas | Mesa
│   ├── bestiario_screen.dart   o elenco pronto (asset) → fichas do aparelho
│   ├── licenca_screen.dart     selo, avisos e privacidade
│   ├── wizard_screen.dart      assistente de criação (6 passos)
│   └── ficha_screen.dart       a ficha em 6 abas, edição e leitura
├── widgets/                    retrato, contadores PV/SAN/PE, visualizador
└── mesa/                       a mesa online
    ├── mesa_service.dart       interface (contrato = firestore.rules)
    ├── mesa_firestore.dart     implementação real
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

Só mecânica e nomes, nada de texto de livro: 28 perícias com atributo-base,
26 origens (o que cada uma treina e o efeito do poder), 5 patentes com
limites de item por categoria — em `assets/data/*.json` — e as 4 classes com
as fórmulas de PV/PE/SAN por NEX, que ficam **no código**
(`lib/data/dados_op.dart`): um asset que falhasse ao carregar faria os
máximos caírem para o valor atual sem avisar ninguém.

Os efeitos de poder e habilidade estão em notação de mesa — `2 PE → +5 em
Ciências ou Investigação. 1×/cena.` — escrita aqui, não copiada. A licença
libera nomes e terminologia do sistema, e proíbe reproduzir os textos dos
livros; ver [LICENCA.md](LICENCA.md).

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

O bestiário depende do catálogo: **toda ficha que conjura já vem com os
rituais dentro**, um por um, com custo, execução, alcance, duração, DT e
efeito. Vale para quem o livro descreve por faixa ("todos os rituais de
Morte até o 3º círculo" → os 15), por escolha ("escolha 2 de 1º círculo" →
os 24 possíveis, com a nota mandando escolher) e por lista fechada (os 6
rituais que Giordano usa para fugir em VO1). Um teste reprova qualquer ficha
que fale em conjurar e chegue sem lista.

O `ameacas-cru.json` tem trecho de livro e por isso **não é distribuído**;
o que entra no app é número + notação própria. Um teste confere ficha por
ficha (`test/bestiario_test.dart`): toda ameaça precisa de PV impresso,
Defesa, categoria e pelo menos um ataque ou habilidade, e todo ataque
precisa do teste que se rola.

As fórmulas foram conferidas contra a ficha oficial do
[fichasop.com](https://fichasop.com): um Combatente NEX 35% com Vigor 3 e
Presença 2 dá **PV 65 · SAN 30 · PE 28** nos dois. `test/regras_op_test.dart`
trava esses números.
