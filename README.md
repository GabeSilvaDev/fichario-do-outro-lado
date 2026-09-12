<div align="center">

<img src="docs/imagens/banner.jpg" alt="Fichário do Outro Lado" width="100%">

# Fichário do Outro Lado

**Character sheet + live online table for the Brazilian horror RPG *Ordem Paranormal*.**<br>
The GM sees every sheet and every roll in real time, and pushes images that open on everyone's screen.

[![Play in the browser](https://img.shields.io/badge/%E2%96%B6%20Play%20now-PWA-7c4dff?style=for-the-badge)](https://gabesilvadev.github.io/fichario-do-outro-lado/)

[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/Android%20%7C%20Web%20%7C%20PWA-4a3a7a)](#getting-started)
[![Offline first](https://img.shields.io/badge/offline-first-2e7d32)](#features)
[![Firebase](https://img.shields.io/badge/online%20table-Firestore-ffca28?logo=firebase&logoColor=black)](#online-table-firebase)
[![License](https://img.shields.io/badge/license-OP%20Community%20License-8e24aa)](LICENCA.md)
[![Version](https://img.shields.io/badge/version-0.9.1-555)](pubspec.yaml)

**English** · [Português (Brasil)](README.pt-BR.md)

<sub>Este é um conteúdo não oficial, publicado sob a Licença da Comunidade de Ordem Paranormal. Contém material gerado por inteligência artificial.<br>
Unofficial fan content published under the Ordem Paranormal Community License. Contains AI-generated material. No affiliation with the rights holders — see <a href="LICENCA.md">LICENCA.md</a>.</sub>

</div>

<br>

<img src="docs/imagens/showcase.png" alt="Character sheet, skill roll, bestiary, GM table and live GM panel" width="100%">

<br>

## Highlights

- **Complete character sheet** — 6 tabs, 28 skills, attacks, abilities, rituals, inventory with load, and HP/SAN/EP maxima **calculated automatically** from class, NEX and attributes.
- **Guided character creation** — a 6-step wizard that enforces the rulebook (origin, class, attribute points, skill quotas) and shows the final numbers before you commit.
- **Tap to roll** — skills roll `Xd20` keep-best, attacks roll test + damage, crits and fumbles flagged. A quick-dice bar accepts `2d6+3` and the official sheet's `/AGI` syntax.
- **150-entry bestiary** — threats from the books, named NPCs from the published campaigns, allies and extras, all as full stat blocks you import as NPCs in one tap.
- **System catalog** — all 81 rituals and the full 41-row weapon table, insertable straight into the sheet.
- **Online table** — sheets and rolls mirrored to the GM in ~2 s, a full-screen image board, and a live scene map with draggable tokens. No accounts: players join with a `ORDO-XXXX` code.
- **Offline by default** — sheets live on the device (Hive), export/import as `.json`. The online table is optional.
- **Runs anywhere** — Android APK or installable PWA on iPhone, Android and desktop.

> The app's interface is in Brazilian Portuguese, the native language of the system.

## Screenshots

<details open>
<summary><b>Sheets & character creation</b></summary>
<br>

| Your sheets | Wizard (1/6) | Class & NEX |
|:---:|:---:|:---:|
| <img src="docs/imagens/fichas-lista.png" width="260" alt="Sheet list with an agent and an NPC"> | <img src="docs/imagens/wizard-identidade.png" width="260" alt="Creation wizard — identity"> | <img src="docs/imagens/wizard-classe-nex.png" width="260" alt="Wizard — NEX and class"> |

| Attributes | Skills | Review & create |
|:---:|:---:|:---:|
| <img src="docs/imagens/wizard-atributos.png" width="260" alt="Wizard — attribute points"> | <img src="docs/imagens/wizard-pericias.png" width="260" alt="Wizard — skill picks"> | <img src="docs/imagens/wizard-conferir.png" width="260" alt="Wizard — summary with HP/SAN/EP"> |

</details>

<details>
<summary><b>The sheet in play</b></summary>
<br>

| Full sheet | 28 skills | Tap to roll |
|:---:|:---:|:---:|
| <img src="docs/imagens/ficha-geral.png" width="260" alt="Sheet — general tab with resources"> | <img src="docs/imagens/ficha-pericias.png" width="260" alt="Sheet — skills with training grade"> | <img src="docs/imagens/rolagem.png" width="260" alt="2d20 keep-best roll"> |

</details>

<details>
<summary><b>Bestiary & catalog</b></summary>
<br>

| Bestiary (150 entries) | Threat stat block | Abilities in table notation |
|:---:|:---:|:---:|
| <img src="docs/imagens/bestiario.png" width="260" alt="Campaign bestiary by group"> | <img src="docs/imagens/npc-ficha.png" width="260" alt="Threat imported as an NPC"> | <img src="docs/imagens/npc-poderes.png" width="260" alt="Threat abilities"> |

| 81 rituals | Weapon table |
|:---:|:---:|
| <img src="docs/imagens/catalogo-rituais.png" width="260" alt="Ritual catalog by element and circle"> | <img src="docs/imagens/catalogo-armas.png" width="260" alt="Weapon catalog"> |

</details>

<details>
<summary><b>Online table</b></summary>
<br>

| Create or join | GM's table | Player's table |
|:---:|:---:|:---:|
| <img src="docs/imagens/mesa-entrar.png" width="260" alt="Create a table or join with a code"> | <img src="docs/imagens/mesa-mestre.png" width="260" alt="GM table with ORDO code and map"> | <img src="docs/imagens/mesa-jogador.png" width="260" alt="Player table with live presence"> |

| Full-screen board | Live GM panel | Map library |
|:---:|:---:|:---:|
| <img src="docs/imagens/mural-tela-cheia.png" width="260" alt="GM image opened on a player's screen"> | <img src="docs/imagens/painel-mestre.png" width="260" alt="Published sheet and roll feed in the GM panel"> | <img src="docs/imagens/mapa-biblioteca.png" width="260" alt="Table map library"> |

*Online-table screenshots are real: two live sessions on Firestore — the GM pushed an image and it opened on the player's screen; the published sheet and its rolls landed in the GM panel instantly.*

</details>

## Features

### For players

- **Player or NPC** — the same sheet serves both. NPCs/creatures start in free mode and **never go to the online table**; the bestiary belongs to the GM.
- **Free mode (GM)** — the rules toggle in the app bar lifts the rulebook limits. Warnings still show, but nothing blocks: attributes up to 20, skills without quotas, any class/NEX combination. This is how you build creatures, NPCs and characters that have outgrown creation rules.
- **6-step creation wizard** that enforces the book: identity → origin → class & NEX → attributes (4 points for agents, 3 for civilians; zero one attribute for an extra point) → skills (origin and class picks pre-checked; you choose `base + Intellect`) → review. Each step unlocks the next only when complete, and the last screen shows HP/SAN/EP before creating. After that the sheet is yours and everything becomes free editing. The same two toggles (type and rules) live on the sheet screen: promote a character to NPC, or lift the limits on an existing sheet, whenever you want.
- **Full sheet in 6 tabs** — identity (class/origin/path/rank, nationality, age), NEX, attributes, HP/SAN/EP with **auto-calculated maxima** (class + NEX + Vigor/Presence, manual override), defense and movement with encumbrance penalty, the 28 skills with training grade, attacks (damage type, crit range and multiplier, reach, special), abilities, rituals, inventory with load (5×Strength) and per-rank item limits, proficiencies, and an **About** tab (backstory, appearance, first paranormal encounter, phobias, favorites, personality, worst nightmare, notes).
- **Picking a class or origin fills the sheet** — trained skills, proficiencies and the power/ability come in on their own, with confirmation; nothing you already had is erased.
- **Table state** — mark *in combat* / *dead*, and hide HP, Sanity or Effort from the GM panel when the character plays with a secret resource.
- **Tap to roll** — skills roll `Xd20` keep-best (attribute 0: 2d20 keep-worst) + training bonus; attacks roll test and damage. Crits and fumbles flagged. The **quick dice** bar accepts `2d6+3` and the official sheet's `/AGI` syntax.
- **Campaign bestiary** — 150 ready stat blocks in 16 groups: the books' threats by element (Blood, Death, Knowledge, Energy), people and troops, animals, the named NPCs of *Vendeta Oculta 1 & 2*, *Casos Paranormais* and extra missions, plus the Order's allies and extras written for this table. A threat comes **complete**: VD (challenge rating), category and size, disturbing presence, senses, printed Defense and HP, resistances and vulnerabilities, block tests, every attack with the roll (`3d20+10`) and damage, and what each ability does — in table notation. Import everything, one group or one entry; all come in as NPCs in free mode. Re-importing updates the same sheet instead of duplicating it.
- **System catalog** — all **81 rituals** (four elements + Fear, 1st to 4th circle) with cost, execution, range, target, duration, resistance, effect and the *discente*/*verdadeiro* upgrades; and the full **weapon table** (41 rows) with damage, crit, range, type and slots, plus armor. Look it up on the spot and **drop it straight into the sheet**: the ritual arrives fully filled, the weapon becomes an attack with the right skill, damage and crit.
- **Local storage** — sheets stay on the device (Hive), export/import `.json`. No account.

### For the GM — the online table

- Create the table, read the code out loud (`ORDO-XXXX`) and receive a recovery key. Players join by code, no account (anonymous sign-in).
- **Live sheets** — a player publishes their sheet and everything they mark (HP, SAN, EP, inventory…) shows in the GM panel within ~2 s, with *combat* / *dead* badges and respecting whatever the player chose to hide.
- **Latest rolls** — every roll made on a published sheet enters the table feed instantly: who rolled, what, the dice and the total.
- **Image board** — the GM sends an image and it **opens full-screen on everyone's device**: map, NPC portrait, clue. The gallery keeps the campaign's collection between sessions.
- **Scene map** — a separate live screen inside the table. Floor plans live in a **map library of their own**, separate from the board gallery: board images pop up in everyone's face, map plans stay up for reference. The GM uploads a plan, picks which one is in play and places tokens: **published agents come in with their sheet portrait**, **bestiary NPCs come in with their crest**, and you can add loose tokens (marker, hostage, door). Tapping a token opens **size** (0.4× to 3× — a Huge creature doesn't fit the same circle as an agent), threat mark and remove. **Only the GM moves; players only watch**, and whoever leaves the screen comes back to everything in place — positions live in Firestore, not on the device. The Firestore rules guarantee that, not just the UI.

The table architecture is shared with the [Mago: A Ascensão](https://github.com/GabeSilvaDev/mago-ficha) app: Firestore + security rules as the single authority, images stored as base64 inside documents (no paid Storage), heartbeat presence, table recovery key.

## Getting started

### Play right now

**[gabesilvadev.github.io/fichario-do-outro-lado](https://gabesilvadev.github.io/fichario-do-outro-lado/)** — works on iPhone, Android and desktop with nothing to install. On iPhone open it in Safari and use *Share → Add to Home Screen* to turn it into an app.

### Build from source

No local Flutter install needed — everything runs through Docker:

```bash
docker compose up -d
docker compose exec flutter flutter pub get

# web with hot reload at http://localhost:8093
docker compose exec flutter flutter run -d web-server \
  --web-port 8093 --web-hostname 0.0.0.0

# Android APK
docker compose exec flutter flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# install / update on a phone with USB debugging enabled
docker run --rm --privileged -v /dev/bus/usb:/dev/bus/usb -v "$PWD":/app -w /app \
  ghcr.io/cirruslabs/flutter:stable \
  adb install -r build/app/outputs/flutter-apk/app-release.apk

# static web build (host the build/web folder anywhere)
docker compose exec flutter flutter build web --release
```

### Run the tests

```bash
docker compose exec flutter flutter test
```

### Deploy to GitHub Pages

The site at <https://gabesilvadev.github.io/fichario-do-outro-lado/> is the `build/web` folder published on the `gh-pages` branch:

```bash
docker compose exec flutter flutter build web --release \
  --base-href /fichario-do-outro-lado/
cd build/web && git init -b gh-pages && git add -A \
  && git commit -m "web build" \
  && git push -f git@github.com:GabeSilvaDev/fichario-do-outro-lado.git gh-pages
```

For the online table to work on the site, the `gabesilvadev.github.io` domain must be listed under **Authentication → Settings → Authorized domains** in the Firebase console (one-time setup).

## Online table (Firebase)

The **`ordem-paranormal-mesa`** project is up and wired to the app:

| Item | State |
|---|---|
| Firestore | created in `southamerica-east1` (São Paulo) |
| Authentication | **anonymous** sign-in enabled |
| Security rules | **published** (the contents of `firestore.rules`) |
| Android app | `com.gabesilvadev.ordem_paranormal` registered (legacy internal id: changing it would force a clean reinstall and wipe on-device sheets) |
| Web app | registered |
| Credentials | `lib/firebase_options.dart` + `android/app/google-services.json` |

Nothing to do: creating a table in the app already writes to Firestore.

**If you change the rules**, republish them — from the console (Firestore → Rules → Publish) or the CLI:

```bash
firebase deploy --only firestore:rules --project ordem-paranormal-mesa
```

`firestore.rules` is the system's only security layer: the owner writes their own sheet and the GM reads it; rolls only in your own name; gallery and board are GM-only; the table key sits in a document nobody can read.

### Using your own Firebase project

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-project> --platforms=android,web
```

Then enable Authentication → Anonymous, create Firestore and publish the rules in the new project.

## Release signing

The app is signed with its own key (`android/ordem-paranormal.jks`). Without it, Flutter signs releases with the *debug* key, which changes on every machine and container — Android then refuses the next install with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, forcing an uninstall that wipes the device's sheets.

With a fixed key, **every new build installs over the previous one** and players lose nothing. Bump `version:` in `pubspec.yaml` on each release (`0.2.0+2` → `0.2.1+3`).

`key.properties` and the `.jks` are in `.gitignore`: **back both up**. Lose the key and the only way out is publishing with a new one — and everyone has to uninstall before updating.

## Project structure

```
lib/
├── main.dart
├── theme.dart                  Ordem Paranormal theme (dark, purple/gold)
├── firebase_options.dart       ordem-paranormal-mesa credentials
├── data/dados_op.dart          classes (in code) + skills, origins,
│                               ranks (assets)
├── models/
│   ├── ficha_op.dart           the sheet (Map + HP/SAN/EP/load math)
│   └── rolagem.dart            dice engine (Xd20 best/worst, expressions)
├── store/ficha_store.dart      sheets in Hive + mirror observer
├── screens/
│   ├── home_screen.dart        Sheets | Table tabs
│   ├── bestiario_screen.dart   the ready cast (asset) → device sheets
│   ├── licenca_screen.dart     seal, notices and privacy
│   ├── wizard_screen.dart      creation wizard (6 steps)
│   └── ficha_screen.dart       the sheet in 6 tabs, edit and read
├── widgets/                    portrait, HP/SAN/EP counters, image viewer
└── mesa/                       the online table
    ├── mesa_service.dart       interface (contract = firestore.rules)
    ├── mesa_firestore.dart     real implementation
    ├── espelho_ficha.dart      sheet → table with a 2 s window
    ├── ponte_rolagens.dart     roll → table feed
    ├── ouvinte_mural.dart      GM image opens by itself
    ├── imagem_mural.dart       shrinks images to fit a document
    ├── ouvinte_mapa.dart       new map opens on everyone's screen
    ├── codigo.dart             ORDO-XXXX, readable out loud
    ├── chave_mesa.dart         table recovery key
    └── telas/                  table tab, GM panel, gallery, board,
                                scene map (draggable tokens)
```

## System data

Only mechanics and names, no book text: 28 skills with base attribute, 26 origins (what each one trains and its power's effect), 5 ranks with per-category item limits — in `assets/data/*.json` — and the 4 classes with their HP/EP/SAN formulas per NEX, which live **in code** (`lib/data/dados_op.dart`): an asset failing to load would silently drop the maxima to the current value.

Power and ability effects are written in table notation — `2 PE → +5 em Ciências ou Investigação. 1×/cena.` — authored here, not copied. The license allows the system's names and terminology and forbids reproducing book text; see [LICENCA.md](LICENCA.md).

### Where the threat numbers come from

```bash
# 1. reads YOUR PDFs and extracts mechanics only
python3 ../../Ordem/App-Mestre/ferramentas/extrair_ameacas.py   # threats
python3 ../../Ordem/App-Mestre/ferramentas/extrair_rituais.py   # rituals
python3 ../../Ordem/App-Mestre/ferramentas/build_regras.py      # weapon table
# output: Ordem/App-Mestre/dados/*-cru.json — LOCAL files, in .gitignore

# 2. merges those numbers with the hand-written text
#    (ferramentas/notacao_ameacas.py and ferramentas/notacao_rituais.py)
python3 ferramentas/gerar_catalogo.py    # rituals + weapons
python3 ferramentas/gerar_bestiario.py   # bestiary (uses the catalog)
```

The bestiary depends on the catalog: **every caster comes with its rituals inside**, one by one, with cost, execution, range, duration, DC and effect. That covers threats described by range ("all Death rituals up to 3rd circle" → the 15), by choice ("pick 2 of 1st circle" → the 24 possible, with a note to choose) and by closed list (the 6 rituals Giordano uses to escape in VO1). A test fails any entry that mentions casting and arrives without a list.

`ameacas-cru.json` contains book excerpts and therefore **is not distributed**; what ships in the app is numbers + original notation. A test checks entry by entry (`test/bestiario_test.dart`): every threat needs printed HP, Defense, category and at least one attack or ability, and every attack needs the roll it uses.

The formulas were checked against the official sheet at [fichasop.com](https://fichasop.com): a Combatente at NEX 35% with Vigor 3 and Presence 2 gives **HP 65 · SAN 30 · EP 28** on both. `test/regras_op_test.dart` locks those numbers.

## License

**Fichário do Outro Lado** is free fan content, made by a player for their own table, published under the [Ordem Paranormal Community License](https://ordemparanormal.com.br/licenca) v1.0 in the *free fan content → virtual sheets for VTTs* category. It is not an official product and has no partnership, approval or endorsement from anyone connected to Ordem Paranormal. The Ordem Paranormal universe belongs to Rafael "Cellbit" Lange.

Terms of use, credits, privacy (LGPD) and how each license condition is met: **[LICENCA.md](LICENCA.md)**.
