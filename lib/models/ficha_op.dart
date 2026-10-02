import '../data/dados_op.dart';
import '../regras/efeitos.dart';
import '../regras/opcionais.dart';
import '../regras/poderes.dart';
import 'normalizar.dart';

/// A ficha de Ordem Paranormal.
///
/// Guarda tudo num `Map` interno — o mesmo formato viaja para o Hive, para o
/// export JSON e para a mesa online, sem conversões pelo caminho. Os getters
/// tipados existem para as telas não espalharem strings de chave.
class FichaOP {
  final Map<String, dynamic> dados;

  /// O mapa é consertado no lugar: ficha importada, da mesa ou de versão
  /// antiga não derruba tela por tipo errado.
  FichaOP(this.dados) {
    normalizarFicha(dados);
  }

  /// NPC/criatura já nasce em modo livre: nenhuma ameaça do livro cabe no
  /// orçamento de criação de um agente.
  factory FichaOP.novoNpc(String id) {
    final f = FichaOP.nova(id);
    f.ehNpc = true;
    f.modoLivre = true;
    return f;
  }

  factory FichaOP.nova(String id) => FichaOP({
        'id': id,
        'nome': '',
        'jogador': '',
        'classe': 'Mundano',
        'trilha': '',
        'origem': '',
        'patente': 'Recruta',
        'nex': 0,
        'deslocamento': 9,
        'atributos': {'AGI': 1, 'FOR': 1, 'INT': 1, 'PRE': 1, 'VIG': 1},
        'pv': 9,
        'san': 8,
        'pe': 2,
        'defesaBonus': 0,
        'protecao': '',
        'resistencias': '',
        'pericias': <String, dynamic>{},
        'ataques': <dynamic>[],
        'habilidades': <dynamic>[],
        'rituais': <dynamic>[],
        'inventario': <dynamic>[],
        'nacionalidade': '',
        'idade': 0,
        'proficiencias': <dynamic>[],
        'emCombate': false,
        'morto': false,
        'ocultarPv': false,
        'ocultarSan': false,
        'ocultarPe': false,
        'historia': '',
        'aparencia': '',
        'primeiroEncontro': '',
        'fobias': '',
        'favoritos': '',
        'personalidade': '',
        'piorPesadelo': '',
        'anotacoes': '',
        'retrato': '',
        'criadaEm': DateTime.now().toIso8601String(),
      });

  /// Ficha de NPC/criatura do mestre. NPC não vai para a mesa online: a
  /// mesa publica o personagem do jogador, e o bestiário é do mestre.
  ///
  /// 'pc' (padrão) ou 'npc'. Ficha antiga, sem o campo, entra como 'pc'.
  String get tipo => (dados['tipo'] as String?) ?? 'pc';
  bool get ehNpc => tipo == 'npc';

  set ehNpc(bool v) {
    if (v) {
      dados['tipo'] = 'npc';
    } else {
      dados.remove('tipo');
    }
  }

  /// Regras frouxas: os limites da criação viram aviso em vez de trava.
  /// É o modo do mestre — para montar NPC, criatura, ou um personagem que
  /// já evoluiu além do que a criação permite.
  bool get modoLivre => dados['modoLivre'] == true;
  set modoLivre(bool v) {
    if (v) {
      dados['modoLivre'] = true;
    } else {
      dados.remove('modoLivre');
    }
  }

  String get id => (dados['id'] ?? '') as String;
  String get nome => (dados['nome'] ?? '') as String;
  set nome(String v) => dados['nome'] = v;

  String get jogador => (dados['jogador'] ?? '') as String;
  set jogador(String v) => dados['jogador'] = v;

  String get classe => (dados['classe'] ?? 'Mundano') as String;
  set classe(String v) => _mexendoNosMaximos(() => dados['classe'] = v);

  String get trilha => (dados['trilha'] ?? '') as String;
  set trilha(String v) => dados['trilha'] = v;

  String get origem => (dados['origem'] ?? '') as String;
  set origem(String v) => _mexendoNosMaximos(() => dados['origem'] = v);

  String get patente => (dados['patente'] ?? 'Recruta') as String;
  set patente(String v) => dados['patente'] = v;

  int get nex => (dados['nex'] ?? 0) as int;
  set nex(int v) => _mexendoNosMaximos(() => dados['nex'] = v.clamp(0, 99));

  /// Estágio do Sobrevivente (1 a 5). Ele não sobe de NEX: sobe um estágio
  /// no fim de cada missão. Classe normal ignora este campo.
  int get estagio => ((dados['estagio'] ?? 1) as int).clamp(1, 5);
  set estagio(int v) =>
      _mexendoNosMaximos(() => dados['estagio'] = v.clamp(1, 5));

  bool get porEstagio =>
      DadosOP.classePorNome(classe)?.porEstagio ?? false;

  int get deslocamento => (dados['deslocamento'] ?? 9) as int;
  set deslocamento(int v) => dados['deslocamento'] = v;

  String get retrato => (dados['retrato'] ?? '') as String;
  set retrato(String v) => dados['retrato'] = v;

  String get anotacoes => (dados['anotacoes'] ?? '') as String;
  set anotacoes(String v) => dados['anotacoes'] = v;

  String get nacionalidade => (dados['nacionalidade'] ?? '') as String;
  set nacionalidade(String v) => dados['nacionalidade'] = v;

  int get idade => (dados['idade'] ?? 0) as int;
  set idade(int v) => dados['idade'] = v;

  /// Campos livres da aba Sobre, no mesmo recorte que a ficha oficial usa.
  static const Map<String, String> camposSobre = {
    'historia': 'História',
    'aparencia': 'Aparência',
    'primeiroEncontro': 'Primeiro encontro paranormal',
    'fobias': 'Doenças, fobias e manias',
    'favoritos': 'Favoritos (pessoas, itens…)',
    'personalidade': 'Personalidade',
    'piorPesadelo': 'Pior pesadelo',
    'anotacoes': 'Anotações',
  };

  String sobre(String chave) => (dados[chave] ?? '') as String;
  void definirSobre(String chave, String valor) => dados[chave] = valor;

  bool get emCombate => (dados['emCombate'] ?? false) as bool;
  set emCombate(bool v) => dados['emCombate'] = v;

  bool get morto => (dados['morto'] ?? false) as bool;
  set morto(bool v) => dados['morto'] = v;

  /// O jogador pode esconder um recurso do painel do mestre — a ficha
  /// oficial tem esses três botões, e quem joga com sanidade secreta usa.
  bool oculto(String recurso) =>
      (dados['ocultar${recurso[0].toUpperCase()}${recurso.substring(1)}'] ??
          false) as bool;

  void definirOculto(String recurso, bool valor) => dados[
      'ocultar${recurso[0].toUpperCase()}${recurso.substring(1)}'] = valor;

  String get protecao => (dados['protecao'] ?? '') as String;
  set protecao(String v) => dados['protecao'] = v;

  String get resistencias => (dados['resistencias'] ?? '') as String;
  set resistencias(String v) => dados['resistencias'] = v;

  Map<String, dynamic> get _atributos =>
      (dados['atributos'] ??= <String, dynamic>{}) as Map<String, dynamic>;

  int atributo(String sigla) => (_atributos[sigla] ?? 0) as int;

  /// Teto 5 na ficha comum; no modo livre vai a 20, que é onde as fichas
  /// de ameaça do livro chegam.
  void definirAtributo(String sigla, int valor) => _mexendoNosMaximos(
      () => _atributos[sigla] = valor.clamp(0, modoLivre ? 20 : 5));

  /// O atual nunca passa do máximo: cura não enche além da conta, e bônus
  /// acima disso é PV temporário.
  int get pv => ((dados['pv'] ?? 0) as int).clamp(0, _teto('pv'));
  set pv(int v) => _gravarAtual('pv', v);

  int get san => ((dados['san'] ?? 0) as int).clamp(0, _teto('san'));
  set san(int v) => _gravarAtual('san', v);

  int get pe => ((dados['pe'] ?? 0) as int).clamp(0, _teto('pe'));
  set pe(int v) => _gravarAtual('pe', v);

  void _gravarAtual(String recurso, int v) {
    dados[recurso] = v.clamp(0, _teto(recurso));
    dados.remove('${recurso}DanoExcedente');
  }

  /// PV temporários: ficam por cima da vida e são os primeiros a sair no
  /// dano. Fontes diferentes somam, o mesmo efeito não; somem no fim da
  /// cena (OPRPG p. 36 e p. 312).
  int get pvTemporario => (dados['pvTemporario'] ?? 0) as int;
  set pvTemporario(int v) {
    if (v <= 0) {
      dados.remove('pvTemporario');
    } else {
      dados['pvTemporario'] = v;
    }
  }

  /// Dano na vida: gasta primeiro os PV temporários.
  void sofrerDano(int dano) {
    final absorvido = dano.clamp(0, pvTemporario);
    pvTemporario -= absorvido;
    pv -= dano - absorvido;
  }

  /// O máximo de verdade, ou null quando não há: classe fora da lista e
  /// nenhum valor na mão (aí o "máximo" mostrado é o próprio atual).
  int? _maximoReal(String recurso) {
    if (dados['${recurso}MaxManual'] == null &&
        DadosOP.classePorNome(classe) == null) {
      return null;
    }
    return switch (recurso) { 'pv' => pvMax, 'san' => sanMax, _ => peMax };
  }

  int _teto(String recurso) => _maximoReal(recurso) ?? 999;

  /// Muda algo de que os máximos dependem (NEX, atributo, classe…). O que
  /// se preserva é o dano sofrido (máximo − atual): subir de NEX de vida
  /// cheia continua de vida cheia, e ir e voltar na régua não cura ninguém.
  void _mexendoNosMaximos(void Function() mudanca) {
    const recursos = ['pv', 'san', 'pe'];
    final antes = [for (final r in recursos) _maximoReal(r)];
    mudanca();
    for (var i = 0; i < recursos.length; i++) {
      final r = recursos[i];
      final atual = (dados[r] ?? 0) as int;
      final depois = _maximoReal(r);
      if (depois == null) continue;
      // Dano que não coube quando o máximo caiu abaixo dele: volta a contar
      // se o máximo subir de novo.
      final excedente = (dados['${r}DanoExcedente'] ?? 0) as int;
      final gasto = antes[i] == null
          ? 0
          : (antes[i]! - atual).clamp(0, 9999) + excedente;
      final novo = depois - gasto;
      dados[r] = novo.clamp(0, depois);
      if (novo < 0) {
        dados['${r}DanoExcedente'] = -novo;
      } else {
        dados.remove('${r}DanoExcedente');
      }
    }
  }

  /// Máximos: calculados da classe + NEX + atributos, a não ser que o
  /// jogador tenha gravado um valor manual (chaves `pvMaxManual` etc.).
  /// A origem escolhida, se ela existe na lista carregada.
  Origem? get origemAtual {
    for (final o in DadosOP.origens) {
      if (o.nome == origem) return o;
    }
    return null;
  }

  /// Nível de exposição: NEX 5% = 1 … 99% = 20. Vários poderes de origem
  /// somam "por 5% de NEX", que é o mesmo que por nível. Mundano e
  /// Sobrevivente não têm NEX: um valor antigo guardado não conta.
  int get nivelNex {
    if (classeOP?.agente == false) return 0;
    if (nex <= 0) return 0;
    if (nex >= 99) return 20;
    return nex ~/ 5;
  }

  ClasseOP? get classeOP => DadosOP.classePorNome(classe);

  int get pvMax => pvMaxCalculado(manual: true);
  int get sanMax => sanMaxCalculado(manual: true);
  int get peMax => peMaxCalculado(manual: true);

  /// O máximo pela regra, ignorando o valor fixado na mão quando
  /// [manual] é false — é assim que a ficha avisa que o fixo ficou velho.
  int pvMaxCalculado({bool manual = false}) {
    final fixo = dados['pvMaxManual'] as int?;
    if (manual && fixo != null) return fixo;
    final c = classeOP;
    if (c == null) return pv;
    final e = efeitosBase;
    final n = nivelNex;
    final vig = atributo('VIG');
    var total = _baseSobrevivente('pv', c) ??
        c.pvMax(nex, vig, estagio: estagio);
    total += e.pvFixo + e.pvPorNivel * n;
    // Ferimento debilitante no Vigor: −1 PV máximo por 5% de NEX (SAH p. 105).
    if (ferimentos.contains('VIG')) total -= n;
    return total < 1 ? 1 : total;
  }

  int sanMaxCalculado({bool manual = false}) {
    final fixo = dados['sanMaxManual'] as int?;
    if (manual && fixo != null) return fixo;
    final c = classeOP;
    if (c == null) return san;
    final e = efeitosBase;
    var total = _baseSobrevivente('san', c) ?? c.sanMax(nex, estagio: estagio);
    total += e.sanFixo + e.sanPorNivel * nivelNex;
    // Transcender: não ganha a SAN do NEX em que transcendeu (p. 26).
    total -= transcendencias * c.sanPorNivel;
    if (origemAtual?.flag('sanMetade') ?? false) {
      final inicial = _sanInicial(c);
      total -= inicial - inicial ~/ 2;
    }
    total -= sanPerdida;
    return total < 0 ? 0 : total;
  }

  int peMaxCalculado({bool manual = false}) {
    final fixo = dados['peMaxManual'] as int?;
    if (manual && fixo != null) return fixo;
    final c = classeOP;
    if (c == null) return pe;
    final e = efeitosBase;
    final n = nivelNex;
    var total = _baseSobrevivente('pe', c) ??
        c.peMax(nex, atributo('PRE'), estagio: estagio);
    total += e.peFixo + e.pePorNivel * n + e.pePorDoisNiveis * (n ~/ 2);
    if (e.peSomaAtributo.isNotEmpty) total += atributo(e.peSomaAtributo);
    final porImpar = origemAtual?.mod('pePorNivelImpar') ?? 0;
    if (porImpar > 0 && nex >= 15 && c.agente) {
      total += porImpar * ((nex - 5) ~/ 10);
    }
    return total < 0 ? 0 : total;
  }

  /// Sobrevivente que virou agente (Treinamento Especial, SAH p. 32): o
  /// agente parte do que o sobrevivente já tinha, mais o bônus da classe,
  /// e segue ganhando por NEX. Null se não é o caso.
  int? _baseSobrevivente(String recurso, ClasseOP c) {
    final e = exSobrevivente;
    if (e <= 0 || !c.agente) return null;
    final sobrevivente = DadosOP.classePorNome('Sobrevivente');
    if (sobrevivente == null) return null;
    final bonus = DadosOP.transicaoSobrevivente(c.nome);
    final n = nivelNex < 1 ? 1 : nivelNex;
    switch (recurso) {
      case 'pv':
        final vig = atributo('VIG');
        return sobrevivente.pvMax(0, vig, estagio: e) +
            (bonus['pvFixo'] ?? 0) +
            (n - 1) * (c.pvPorNivel + vig);
      case 'pe':
        final pre = atributo('PRE');
        return sobrevivente.peMax(0, pre, estagio: e) +
            (bonus['peFixo'] ?? 0) +
            (n - 1) * (c.pePorNivel + pre);
      default:
        return sobrevivente.sanMax(0, estagio: e) +
            (bonus['sanFixo'] ?? 0) +
            (n - 1) * c.sanPorNivel;
    }
  }

  /// Sanidade com que o personagem começou o jogo: a do Sobrevivente, se
  /// ele começou assim, senão a inicial da classe.
  int _sanInicial(ClasseOP c) {
    if (exSobrevivente > 0 && c.agente) {
      final sobrevivente = DadosOP.classePorNome('Sobrevivente');
      if (sobrevivente != null) return sobrevivente.sanIni;
    }
    return c.sanIni;
  }

  /// Estágio em que o sobrevivente virou agente (0 = nunca foi).
  int get exSobrevivente => (dados['exSobrevivente'] ?? 0) as int;
  set exSobrevivente(int v) => _mexendoNosMaximos(() {
        if (v <= 0) {
          dados.remove('exSobrevivente');
        } else {
          dados['exSobrevivente'] = v.clamp(1, 5);
        }
      });

  /// Quantos Transcender a ficha tem (poder paranormal conta um).
  int get transcendencias =>
      habilidades.where((h) => h['transcender'] == true).length;

  /// SAN máxima perdida de vez (custo de ritual, efeito de medo…).
  int get sanPerdida => (dados['sanPerdida'] ?? 0) as int;
  set sanPerdida(int v) =>
      _mexendoNosMaximos(() => dados['sanPerdida'] = v < 0 ? 0 : v);

  bool get pvMaxManual => dados['pvMaxManual'] != null;
  bool get sanMaxManual => dados['sanMaxManual'] != null;
  bool get peMaxManual => dados['peMaxManual'] != null;

  void definirMaxManual(String recurso, int? valor) {
    final chave = '${recurso}MaxManual';
    _mexendoNosMaximos(() {
      if (valor == null) {
        dados.remove(chave);
      } else {
        dados[chave] = valor;
      }
    });
  }

  /// Limite de PE por turno: nível de exposição, mais o que origem e
  /// poderes somam (esses não mexem na DT).
  int get limitePeTurno => limitePeBase + efeitos.limitePe;

  int get limitePeBase =>
      classeOP?.limitePe(nex) ?? ClasseOP.limitePeTurno(nex);

  /// DT dos rituais: 10 + limite de PE + Presença (OPRPG p. 121). Só o
  /// limite do NEX conta — Universitário, Dedicação e afins não sobem a DT.
  int get dtRituais => 10 + limitePeBase + atributo('PRE') + efeitos.dt;

  /// DT das habilidades: 10 + limite de PE + o atributo que ela pede (p. 78).
  int dtHabilidade(String atributoBase) =>
      10 + limitePeBase + atributo(atributoBase) + efeitos.dt;

  int get defesaBonus => (dados['defesaBonus'] ?? 0) as int;
  set defesaBonus(int v) => dados['defesaBonus'] = v;

  /// Proteções do livro (OPRPG, tabela de equipamento): leve +5, pesada +10.
  /// O escudo é item à parte e soma por cima da proteção.
  static const Map<String, int> protecoes = {
    'Nenhuma': 0,
    'Leve': 5,
    'Pesada': 10,
  };

  /// Defesa que a proteção vestida dá. Guardada junto do nome para a ficha
  /// antiga — que só tinha o texto livre — continuar abrindo com Defesa 10+Agi.
  int get protecaoDefesa => (dados['protecaoDefesa'] ?? 0) as int;
  set protecaoDefesa(int v) => dados['protecaoDefesa'] = v;

  /// Veste uma proteção da tabela: grava o nome e já aplica a Defesa.
  void vestirProtecao(String nome) {
    protecao = nome == 'Nenhuma' ? '' : nome;
    protecaoDefesa = protecoes[nome] ?? protecaoDefesa;
  }

  /// Qual entrada da tabela está vestida — 'Outra' quando o texto não é
  /// nenhuma delas (ficha antiga, proteção de campanha, item improvisado).
  String get protecaoTipo {
    if (protecao.isEmpty && protecaoDefesa == 0) return 'Nenhuma';
    for (final nome in protecoes.keys) {
      if (nome != 'Nenhuma' && protecao == nome) return nome;
    }
    return 'Outra';
  }

  bool get escudo => dados['escudo'] == true;
  set escudo(bool v) {
    if (v) {
      dados['escudo'] = true;
    } else {
      dados.remove('escudo');
    }
  }

  static const int defesaEscudo = 2;

  /// Ficha de ameaça traz a Defesa impressa em vez de calculada: a criatura
  /// não usa 10+Agilidade. Quando este campo existe, ele manda.
  int? get defesaManual => dados['defesaManual'] as int?;
  set defesaManual(int? v) {
    if (v == null) {
      dados.remove('defesaManual');
    } else {
      dados['defesaManual'] = v;
    }
  }

  /// 10 + Agilidade + proteção + escudo + origem/poderes + outros bônus.
  /// Sobrecarregado sofre −5 (OPRPG p. 53); condição tira o mais severo.
  int get defesa {
    final e = efeitos;
    return (defesaManual ??
            (10 +
                atributo('AGI') +
                protecaoDefesa +
                (escudo ? defesaEscudo : 0) +
                e.defesa +
                defesaBonus)) -
        (sobrecarregado ? 5 : 0) -
        e.defesaCondicao;
  }

  /// Valor de Desafio. Null = ficha sem VD (agente, NPC comum).
  int? get vd => dados['vd'] as int?;
  set vd(int? v) {
    if (v == null) {
      dados.remove('vd');
    } else {
      dados['vd'] = v;
    }
  }

  /// "Criatura", "Pessoa", "Construto"… e o tamanho ("Médio", "Enorme").
  String get categoria => (dados['categoria'] ?? '') as String;
  set categoria(String v) => dados['categoria'] = v;

  String get tamanho => (dados['tamanho'] ?? '') as String;
  set tamanho(String v) => dados['tamanho'] = v;

  /// Elemento do Outro Lado a que a ameaça pertence.
  String get elemento => (dados['elemento'] ?? '') as String;
  set elemento(String v) => dados['elemento'] = v;

  String get sentidos => (dados['sentidos'] ?? '') as String;
  set sentidos(String v) => dados['sentidos'] = v;

  String get vulnerabilidades => (dados['vulnerabilidades'] ?? '') as String;
  set vulnerabilidades(String v) => dados['vulnerabilidades'] = v;

  /// Presença perturbadora: DT, dano mental e o NEX que fica imune.
  /// Vazio = a ameaça não perturba quem a vê.
  String get presenca => (dados['presenca'] ?? '') as String;
  set presenca(String v) => dados['presenca'] = v;

  /// Metade dos PV máximos, arredondada para baixo — o limiar em que a
  /// ameaça fica machucada. O livro imprime esse número em toda ficha.
  int get machucado => pvMax ~/ 2;

  /// Sobrecarregado anda 3m a menos; lento anda metade, caído 1,5m,
  /// imóvel nada (p. 89 e p. 310–311).
  double get deslocamentoEfetivo {
    final e = efeitos;
    var d = (deslocamento + e.deslocamento - (sobrecarregado ? 3 : 0))
        .toDouble();
    final cond = e.deslocamentoCondicao;
    if (cond == 0) {
      d = 0;
    } else if (cond == 1.5) {
      d = d < 1.5 ? d : 1.5;
    } else if (cond == 0.5) {
      d = d / 2;
    }
    return d < 0 ? 0 : d;
  }

  /// Carga: 5 espaços por ponto de Força (Força 0 → 2). O dobro é o teto
  /// absoluto, andando sobrecarregado (p. 53).
  int get cargaLimite {
    final e = efeitosBase;
    final f = atributo('FOR') + (e.cargaSomaInt ? atributo('INT') : 0);
    return (f <= 0 ? 2 : 5 * f) + e.carga;
  }

  int get cargaMaxima => cargaLimite * 2;

  /// Espaços da proteção vestida e do escudo (p. 62): leve 2, pesada 5,
  /// escudo 2. Contam na carga mesmo fora do inventário.
  int get espacosProtecao =>
      (protecaoTipo == 'Leve' ? 2 : protecaoTipo == 'Pesada' ? 5 : 0) +
      (escudo ? 2 : 0);

  int get cargaUsada {
    var total = espacosProtecao;
    for (final item in inventario) {
      total += (item['espacos'] ?? 0) as int;
    }
    return total;
  }

  bool get sobrecarregado => cargaUsada > cargaLimite;
  bool get acimaDaCargaMaxima => cargaUsada > cargaMaxima;

  Map<String, dynamic> get _pericias =>
      (dados['pericias'] ??= <String, dynamic>{}) as Map<String, dynamic>;

  /// Grau de treinamento: 0 destreinado, 5 treinado, 10 veterano, 15 expert.
  int grauPericia(String nome) => (_pericias[nome] ?? 0) as int;

  void definirGrauPericia(String nome, int grau) {
    if (grau <= 0) {
      _pericias.remove(nome);
    } else {
      _pericias[nome] = grau;
    }
  }

  /// Atributo que rola esta perícia. O livro fixa um por perícia, mas deixa
  /// o mestre trocar caso a caso ("Atletismo com Força para escalar"), e a
  /// habilidade Eclético do Especialista troca por Intelecto. Aqui o jogador
  /// grava a troca na própria perícia em vez de recalcular na mão.
  Map<String, dynamic> get _atributosPericia =>
      (dados['periciaAtributo'] ??= <String, dynamic>{})
          as Map<String, dynamic>;

  String atributoPericia(Pericia p) =>
      (_atributosPericia[p.nome] as String?) ?? p.atributo;

  bool atributoTrocado(Pericia p) => _atributosPericia[p.nome] != null;

  /// [sigla] null (ou igual ao do livro) volta ao padrão.
  void definirAtributoPericia(Pericia p, String? sigla) {
    if (sigla == null || sigla == p.atributo) {
      _atributosPericia.remove(p.nome);
    } else {
      _atributosPericia[p.nome] = sigla;
    }
  }

  // ---------------------------------------------------------------------
  // Efeitos: origem, poderes, idade, condições e ferimentos, já somados.
  // ---------------------------------------------------------------------

  /// O que muda os máximos e a carga. Não inclui o que depende de estado
  /// (machucado, proteção vestida, cena de ação) nem condições — assim o
  /// máximo de PV não depende do PV atual.
  Efeitos get efeitosBase => _efeitos(estado: false);

  /// Tudo, inclusive o que depende do estado do momento e as condições.
  Efeitos get efeitos => _efeitos(estado: true);

  Efeitos _efeitos({required bool estado}) {
    final e = Efeitos();
    final o = origemAtual;
    if (o != null) e.somar(o.modificadores);

    for (final h in habilidades) {
      final bloco = h['efeitos'];
      if (bloco is Map<String, dynamic>) {
        final quando = '${bloco['quando'] ?? ''}';
        if (quando.isEmpty || (estado && _vale(quando))) e.somar(bloco);
      }
      final afin = h['efeitosAfinidade'];
      if (afin is Map<String, dynamic> &&
          afinidade.isNotEmpty &&
          h['elemento'] == afinidade) {
        final quando = '${afin['quando'] ?? ''}';
        if (quando.isEmpty || (estado && _vale(quando))) e.somar(afin);
      }
    }

    final faixa = RegrasOpcionais.faixa(faixaEtaria);
    if (faixa != null) {
      e.defesa += faixa.defesa;
      e.testesResistencia += faixa.testesResistencia;
      e.deslocamento += faixa.deslocamento;
      e.peFixo += faixa.peFixo;
    }
    for (final nome in desvantagens) {
      final d = RegrasOpcionais.desvantagem(nome);
      if (d == null) continue;
      e.deslocamento += d.deslocamento;
      e.pvPorNivel += d.pvPorNivel;
      e.pePorNivel += d.pePorNivel;
      for (final p in d.pericias.entries) {
        e.pericias[p.key] = (e.pericias[p.key] ?? 0) + p.value;
      }
    }

    // Proteção pesada: RD 2 contra dano físico (p. 62).
    if (protecaoTipo == 'Pesada') {
      for (final t in ['balistico', 'corte', 'impacto', 'perfuracao']) {
        e.rd[t] = (e.rd[t] ?? 0) + 2;
      }
    }

    if (estado) {
      e.aplicarCondicoes(condicoes);
      // Ferimento debilitante: −O no atributo (SAH p. 105). Soma com
      // condição, por ser outra fonte.
      for (final a in ferimentos) {
        e.dadosPenalidade[a] = (e.dadosPenalidade[a] ?? 0) + 1;
      }
      // Proteção ou escudo sem proficiência: −OO em For e Agi (p. 62).
      if (semProficienciaEmProtecao != null) {
        for (final a in ['FOR', 'AGI']) {
          e.dadosPenalidade[a] = (e.dadosPenalidade[a] ?? 0) + 2;
        }
      }
    }
    return e;
  }

  bool _vale(String quando) => switch (quando) {
        'machucado' => estaMachucado,
        'protecaoPesada' => protecaoTipo == 'Pesada',
        'semProtecao' => protecaoTipo == 'Nenhuma',
        'cenaDeAcao' => emCombate,
        _ => false,
      };

  // ---------------------------------------------------------------------
  // Estados que vêm dos recursos (p. 88 e p. 310–311).
  // ---------------------------------------------------------------------

  /// PV em metade do máximo ou menos (o limiar é [machucado]).
  bool get estaMachucado => pv <= machucado;

  /// 0 PV: inconsciente e morrendo. Três turnos iniciados morrendo na mesma
  /// cena e o personagem morre.
  bool get morrendo => pv <= 0 && !morto;

  /// SAN abaixo da metade do máximo.
  bool get perturbado => san < (sanMax + 1) ~/ 2;

  /// 0 SAN: enlouquecendo. Três turnos e fica insano (vira NPC).
  bool get enlouquecendo => san <= 0 && !insano;

  bool get insano => dados['insano'] == true;
  set insano(bool v) {
    if (v) {
      dados['insano'] = true;
    } else {
      dados.remove('insano');
    }
  }

  int get turnosMorrendo => (dados['turnosMorrendo'] ?? 0) as int;
  set turnosMorrendo(int v) =>
      v <= 0 ? dados.remove('turnosMorrendo') : dados['turnosMorrendo'] = v;

  int get turnosEnlouquecendo => (dados['turnosEnlouquecendo'] ?? 0) as int;
  set turnosEnlouquecendo(int v) => v <= 0
      ? dados.remove('turnosEnlouquecendo')
      : dados['turnosEnlouquecendo'] = v;

  /// Fim de cena: somem os pontos temporários, as condições da cena e os
  /// contadores de morrendo/enlouquecendo (p. 36 e p. 311).
  void fimDeCena() {
    pvTemporario = 0;
    condicoes = const [];
    turnosMorrendo = 0;
    turnosEnlouquecendo = 0;
    dados.remove('estabilizacoes');
    dados.remove('acalmado');
  }

  // ---------------------------------------------------------------------
  // Listas de estado.
  // ---------------------------------------------------------------------

  List<String> _textos(String chave) => [
        for (final v in (dados[chave] ?? const []) as List)
          if (v is String) v,
      ];

  void _gravarTextos(String chave, List<String> v) {
    if (v.isEmpty) {
      dados.remove(chave);
    } else {
      dados[chave] = [...v];
    }
  }

  List<String> get condicoes => _textos('condicoes');
  set condicoes(List<String> v) => _gravarTextos('condicoes', v);

  /// Liga ou desliga uma condição. Pegar de novo uma que piora (abalado →
  /// apavorado) já troca pela pior.
  void alternarCondicao(String nome) {
    final atuais = condicoes;
    if (atuais.contains(nome)) {
      atuais.remove(nome);
    } else {
      atuais.add(nome);
    }
    condicoes = atuais;
  }

  /// Ferimentos debilitantes (SAH p. 105): siglas de atributo.
  List<String> get ferimentos => _textos('ferimentos');
  set ferimentos(List<String> v) =>
      _mexendoNosMaximos(() => _gravarTextos('ferimentos', v));

  /// Regra opcional de idade (p. 172): faixa etária e desvantagens.
  String get faixaEtaria => (dados['faixaEtaria'] ?? '') as String;
  set faixaEtaria(String v) => _mexendoNosMaximos(() {
        if (v.isEmpty) {
          dados.remove('faixaEtaria');
        } else {
          dados['faixaEtaria'] = v;
        }
      });

  List<String> get desvantagens => _textos('desvantagens');
  set desvantagens(List<String> v) =>
      _mexendoNosMaximos(() => _gravarTextos('desvantagens', v));

  /// Elemento de afinidade, escolhido a partir do NEX 50% (p. 110).
  String get afinidade => (dados['afinidade'] ?? '') as String;
  set afinidade(String v) => _mexendoNosMaximos(() {
        if (v.isEmpty) {
          dados.remove('afinidade');
        } else {
          dados['afinidade'] = v;
        }
      });

  /// Regra opcional "Jogando sem Sanidade" (SAH p. 104): Pontos de
  /// Determinação no lugar de PE e SAN.
  bool get regraDeterminacao => dados['regraDeterminacao'] == true;
  set regraDeterminacao(bool v) {
    if (v) {
      dados['regraDeterminacao'] = true;
      dados['pd'] ??= pdMax;
    } else {
      dados.remove('regraDeterminacao');
    }
  }

  int get pdMax {
    final c = classeOP;
    final pre = atributo('PRE');
    final (ini, por, somaPre) = RegrasOpcionais.determinacao[c?.nome] ??
        RegrasOpcionais.determinacao['Sobrevivente']!;
    if (c == null || !c.agente) {
      final e = c?.porEstagio == true ? estagio : 1;
      return ini + pre + (e - 1) * por;
    }
    final n = nivelNex < 1 ? 1 : nivelNex;
    return ini + pre + (n - 1) * (por + (somaPre ? pre : 0));
  }

  int get pd => ((dados['pd'] ?? pdMax) as int).clamp(0, pdMax);
  set pd(int v) => dados['pd'] = v.clamp(0, pdMax);

  /// Custo real de um ritual: o do catálogo, +1 alquebrado, menos as
  /// reduções de poderes. Nunca abaixo de 1 PE (p. 78).
  int custoDeRitual(int custo) {
    final e = efeitos;
    final total = custo + e.custoPeCondicao + e.custoRitual;
    return total < 1 ? 1 : total;
  }

  /// Pontos de prestígio: a patente sai deles (p. 51–52).
  int get pp => (dados['pp'] ?? 0) as int;
  set pp(int v) => dados['pp'] = v < 0 ? 0 : v;

  /// A patente que os PP dão hoje.
  String get patentePelosPp {
    var nome = 'Recruta';
    for (final p in DadosOP.patentes) {
      if (pp >= p.pp) nome = p.nome;
    }
    return nome;
  }

  // ---------------------------------------------------------------------
  // Proficiências.
  // ---------------------------------------------------------------------

  static String _semCaixa(String s) => s.trim().toLowerCase();

  /// Tem a proficiência? Sem diferença de maiúscula, e contando as que os
  /// poderes dão.
  bool proficiente(String nome) {
    final alvo = _semCaixa(nome);
    return proficiencias.any((p) => _semCaixa(p) == alvo) ||
        efeitosBase.proficiencias.any((p) => _semCaixa(p) == alvo);
  }

  /// A proficiência que falta para a proteção e o escudo vestidos, ou null.
  /// O escudo pede a de proteção pesada (p. 62).
  String? get semProficienciaEmProtecao {
    if (ehNpc) return null;
    final tipo = protecaoTipo;
    if (tipo == 'Leve' && !proficiente('Proteções leves')) {
      return 'Proteções leves';
    }
    if ((tipo == 'Pesada' || escudo) && !proficiente('Proteções pesadas')) {
      return 'Proteções pesadas';
    }
    return null;
  }

  /// A proficiência que a arma do ataque pede e a ficha não tem, ou null.
  String? semProficienciaNaArma(Map<String, dynamic> ataque) {
    if (ehNpc) return null;
    if (ataque['armaDaOrigem'] == true) return null;
    final familia = _semCaixa('${ataque['familia'] ?? ''}');
    if (familia.isEmpty) return null;
    final exigida = familia.contains('tática')
        ? 'Armas táticas'
        : familia.contains('pesada')
            ? 'Armas pesadas'
            : 'Armas simples';
    return proficiente(exigida) ? null : exigida;
  }

  // ---------------------------------------------------------------------
  // Testes.
  // ---------------------------------------------------------------------

  /// Bônus fixo que poderes, origem e idade dão nesta perícia.
  int bonusDeEfeitos(String pericia, [Efeitos? pronto]) {
    final e = pronto ?? efeitos;
    var b = e.pericias[pericia] ?? 0;
    if (const {'Fortitude', 'Reflexos', 'Vontade'}.contains(pericia)) {
      b += e.testesResistencia;
    }
    return b;
  }

  /// −5 que a perícia sofre por carga: sobrecarregado ou de proteção
  /// pesada (p. 53 e p. 62). Não somam entre si: a regra é a mesma.
  int penalidadeDeCarga(Pericia p) =>
      p.sofreCarga && (sobrecarregado || protecaoTipo == 'Pesada') ? 5 : 0;

  /// Quantos d20 e se fica com o melhor, depois de tirar [menos] dados.
  /// Atributo 0 rola 2d20 e fica com o pior; cada ponto abaixo disso soma
  /// mais um d20 no pior (SAH p. 81) — o livro básico não diz o que fazer
  /// quando a penalidade passa do atributo.
  static (int, bool) dadosDoTeste(int atributo, int menos) {
    final efetivo = atributo - menos;
    if (efetivo >= 1) return (efetivo, true);
    return (2 - efetivo, false);
  }

  /// Dados e bônus do teste desta perícia: (quantidade de d20, melhor?,
  /// bônus). Já com condições, ferimentos, carga, proteção e poderes.
  (int, bool, int) testePericia(Pericia p, {String ataque = ''}) {
    final e = efeitos;
    final sigla = atributoPericia(p);
    final menos = e.dadosAMenos(p.nome, sigla, ataque: ataque);
    final (dados, melhor) = dadosDoTeste(atributo(sigla), menos);
    final bonus = grauPericia(p.nome) +
        bonusDeEfeitos(p.nome, e) -
        penalidadeDeCarga(p);
    return (dados, melhor, bonus);
  }

  /// O que falta para o teste explicar ao jogador de onde veio cada número.
  List<String> motivosDoTeste(Pericia p, {String ataque = ''}) {
    final e = efeitos;
    final sigla = atributoPericia(p);
    final motivos = <String>[];
    final menos = e.dadosAMenos(p.nome, sigla, ataque: ataque);
    if (menos > 0) motivos.add('−$menos d20 (condição/ferimento/proteção)');
    final carga = penalidadeDeCarga(p);
    if (carga > 0) {
      motivos.add(sobrecarregado ? '−5 sobrecarregado' : '−5 proteção pesada');
    }
    final b = bonusDeEfeitos(p.nome, e);
    if (b != 0) motivos.add('${b > 0 ? '+' : ''}$b de poderes/origem');
    if (p.soTreinada && grauPericia(p.nome) == 0) {
      motivos.add('só treinada: sem treino, o mestre pode não permitir');
    }
    return motivos;
  }

  /// Teste de ataque e dano de uma arma da ficha, já com tudo aplicado.
  ResumoAtaque resumoAtaque(Map<String, dynamic> a) {
    final e = efeitos;
    final periciaNome = '${a['pericia'] ?? 'Luta'}';
    final corpo = periciaNome == 'Luta';
    final uso = _semCaixa('${a['uso'] ?? ''}');
    final fogo = uso.contains('fogo');
    final daOrigem = a['armaDaOrigem'] == true &&
        (origemAtual?.flag('armaFavorita') ?? false);
    final pericia = DadosOP.pericias.where((x) => x.nome == periciaNome);
    var (dados, melhor, bonus) = pericia.isEmpty
        ? (1, true, 0)
        : testePericia(pericia.first, ataque: corpo ? 'corpo' : 'distancia');
    final prof = semProficienciaNaArma(a);
    if (prof != null) {
      (dados, melhor) = dadosDoTeste(
          melhor ? dados : 2 - dados, 2);
    }
    bonus += paraIntSeguro(a['bonus']) + (daOrigem ? 1 : 0);

    var danoFixo = corpo ? e.danoCorpo : e.danoDistancia;
    if (fogo) danoFixo += e.danoFogo;
    if (daOrigem) danoFixo += 1;
    // Força soma no dano corpo a corpo e de arremesso (p. 54).
    if (corpo) danoFixo += atributo('FOR');
    for (final (sigla, escopo) in e.danoSomaAtributo) {
      if (escopo == 'todos' ||
          (escopo == 'corpo' && corpo) ||
          (escopo == 'distancia' && !corpo)) {
        danoFixo += atributo(sigla);
      }
    }

    final critico = '${a['critico'] ?? ''}';
    final margemTexto = '${a['margem'] ?? ''}';
    var margem = 20;
    var mult = 2;
    for (final parte in [...margemTexto.split('/'), ...critico.split('/')]) {
      final t = parte.trim().toLowerCase();
      if (t.startsWith('x')) {
        mult = int.tryParse(t.substring(1)) ?? mult;
      } else if (int.tryParse(t) != null) {
        margem = int.parse(t);
      }
    }
    margem -= (corpo ? e.margemCorpo : e.margemDistancia) + (daOrigem ? 1 : 0);
    mult += e.multiplicador;

    final danos = [
      for (final d in '${a['dano'] ?? ''}'.split('/'))
        if (d.trim().isNotEmpty) d.trim(),
    ];
    return ResumoAtaque(
      dados: dados,
      melhor: melhor,
      bonus: bonus,
      danos: danos,
      danoFixo: danoFixo,
      margem: margem.clamp(2, 20),
      multiplicador: mult,
      semProficiencia: prof,
    );
  }

  static int paraIntSeguro(Object? v) => paraInt(v) ?? 0;

  List<Map<String, dynamic>> _lista(String chave) {
    final bruta = (dados[chave] ??= <dynamic>[]) as List<dynamic>;
    return [
      for (final item in bruta)
        if (item is Map) item.cast<String, dynamic>(),
    ];
  }

  List<String> get proficiencias => _textos('proficiencias');

  set proficiencias(List<String> v) => dados['proficiencias'] = [...v];

  List<Map<String, dynamic>> get ataques => _lista('ataques');
  List<Map<String, dynamic>> get habilidades => _lista('habilidades');
  List<Map<String, dynamic>> get rituais => _lista('rituais');
  List<Map<String, dynamic>> get inventario => _lista('inventario');

  List<dynamic> _listaBruta(String chave) =>
      (dados[chave] ??= <dynamic>[]) as List<dynamic>;

  /// Pôr, tirar e trocar poderes pode mudar máximos (Sangue de Ferro,
  /// Transcender…): passam pelo ajuste dos recursos.
  void adicionarEm(String chave, Map<String, dynamic> item) =>
      _mexendoNosMaximos(() => _listaBruta(chave).add(item));

  void removerDe(String chave, int indice) =>
      _mexendoNosMaximos(() => _listaBruta(chave).removeAt(indice));

  void atualizarEm(String chave, int indice, Map<String, dynamic> item) =>
      _mexendoNosMaximos(() => _listaBruta(chave)[indice] = item);

  // ---------------------------------------------------------------------
  // Classe, origem e trilha: o que entra e o que sai junto.
  // ---------------------------------------------------------------------

  /// Aplica o que a origem dá: as duas perícias treinadas e o poder.
  /// Não mexe no que já estiver treinado acima de 5 — quem virou veterano
  /// não volta a treinado só por trocar a origem.
  void aplicarOrigem(Origem origem) {
    for (final nome in origem.pericias) {
      if (grauPericia(nome) < 5) definirGrauPericia(nome, 5);
    }
    if (origem.poder.isEmpty) return;
    final item = {
      'nome': '${origem.poder} (origem)',
      'descricao': origem.poderDescricao,
      'fonte': 'origem:${origem.nome}',
      'tipoPoder': 'origem',
    };
    final indice = _indiceHabilidade('${origem.poder} (origem)');
    if (indice < 0) {
      adicionarEm('habilidades', item);
    } else {
      atualizarEm('habilidades', indice, item);
    }
  }

  /// O que a origem [origem] pôs na ficha e ainda está lá: perícias só
  /// treinadas (grau 5) que a classe não dá, e o poder.
  (List<String>, int) restosDaOrigem(Origem origem) {
    final fixas = {...?classeOP?.periciasFixas};
    final pericias = [
      for (final p in origem.pericias)
        if (grauPericia(p) == 5 && !fixas.contains(p)) p,
    ];
    final poder = _indiceHabilidade('${origem.poder} (origem)');
    return (pericias, poder);
  }

  /// Tira o que a origem antiga deu. Perícias que o jogador subiu de grau
  /// ficam.
  void removerOrigem(Origem origem) {
    final (pericias, poder) = restosDaOrigem(origem);
    for (final p in pericias) {
      definirGrauPericia(p, 0);
    }
    if (poder >= 0) removerDe('habilidades', poder);
  }

  /// Aplica o que a classe dá: proficiências, perícias fixas e a habilidade
  /// inicial. As perícias "à escolha" ficam para o jogador marcar.
  void aplicarClasse(ClasseOP classe) {
    final atuais = proficiencias;
    for (final p in classe.proficiencias) {
      if (!atuais.any((a) => _semCaixa(a) == _semCaixa(p))) atuais.add(p);
    }
    proficiencias = atuais;

    for (final nome in classe.periciasFixas) {
      if (grauPericia(nome) < 5) definirGrauPericia(nome, 5);
    }
    for (final h in classe.habilidades) {
      final item = {
        'nome': '${h.nome} (classe)',
        'descricao': h.descricao,
        'fonte': 'classe:${classe.nome}',
        'tipoPoder': 'habilidade',
      };
      final indice = _indiceHabilidade('${h.nome} (classe)');
      if (indice < 0) {
        adicionarEm('habilidades', item);
      } else {
        atualizarEm('habilidades', indice, item);
      }
    }
  }

  /// O que a classe [antiga] deixou e a atual não dá: proficiências,
  /// perícias fixas (só treinadas) e habilidades de classe.
  (List<String>, List<String>, List<int>) restosDaClasse(ClasseOP antiga) {
    final nova = classeOP;
    bool daNova(String p) =>
        nova?.proficiencias.any((x) => _semCaixa(x) == _semCaixa(p)) ?? false;
    final profs = [
      for (final p in antiga.proficiencias)
        if (!daNova(p) && proficiente(p)) p,
    ];
    final fixasNova = {...?nova?.periciasFixas};
    final origemPericias = {...?origemAtual?.pericias};
    final pericias = [
      for (final p in antiga.periciasFixas)
        if (grauPericia(p) == 5 &&
            !fixasNova.contains(p) &&
            !origemPericias.contains(p))
          p,
    ];
    final indices = <int>[];
    final lista = habilidades;
    for (var i = 0; i < lista.length; i++) {
      final fonte = '${lista[i]['fonte'] ?? ''}';
      final nome = '${lista[i]['nome'] ?? ''}';
      final daAntiga = fonte == 'classe:${antiga.nome}' ||
          (fonte.isEmpty &&
              antiga.habilidades.any((h) => nome == '${h.nome} (classe)')) ||
          lista[i]['automatica'] == true;
      final daNovaTambem = nova?.habilidades
              .any((h) => nome == '${h.nome} (classe)') ??
          false;
      if (daAntiga && !daNovaTambem) indices.add(i);
    }
    return (profs, pericias, indices);
  }

  void removerClasse(ClasseOP antiga) {
    final (profs, pericias, indices) = restosDaClasse(antiga);
    proficiencias = [
      for (final p in proficiencias)
        if (!profs.any((x) => _semCaixa(x) == _semCaixa(p))) p,
    ];
    for (final p in pericias) {
      definirGrauPericia(p, 0);
    }
    _mexendoNosMaximos(() {
      final bruta = _listaBruta('habilidades');
      for (final i in indices.reversed) {
        bruta.removeAt(i);
      }
    });
  }

  /// Habilidades que entram sozinhas pelo NEX (ou estágio): as da trilha
  /// escolhida e as de classe que chegam depois da criação (Engenhosidade
  /// em 40%, Cicatrizado no estágio 5). As de 5% já vêm com a classe.
  List<Poder> get habilidadesDeTrilhaDevidas {
    final c = classeOP;
    if (c == null) return const [];
    bool alcancou(Poder p) =>
        c.porEstagio ? p.estagio <= estagio : p.nex <= nex;
    final daClasse = {
      for (final h in c.habilidades) _semCaixa(h.nome),
    };
    return [
      for (final p in DadosOP.poderes)
        if (p.classe == c.nome &&
            alcancou(p) &&
            ((p.tipo == 'trilha' && trilha.isNotEmpty && p.trilha == trilha) ||
                (p.tipo == 'habilidade' &&
                    p.transicao.isEmpty &&
                    (c.porEstagio ? p.estagio > 1 : p.nex > 5) &&
                    !daClasse.contains(_semCaixa(p.nome)))))
          p,
    ];
  }

  /// Põe as habilidades de trilha que o NEX já deu e tira as que ele não
  /// dá mais (ou de outra trilha). Só mexe nas que o próprio app pôs.
  /// Devolve (entraram, saíram), para a tela avisar.
  (List<String>, List<String>) sincronizarTrilha() {
    if (DadosOP.poderes.isEmpty) return (const [], const []);
    final devidas = habilidadesDeTrilhaDevidas;
    final nomesDevidos = {for (final p in devidas) p.nome};
    final lista = habilidades;
    final saiu = <String>[];
    final indices = <int>[];
    for (var i = 0; i < lista.length; i++) {
      final h = lista[i];
      if (h['automatica'] == true &&
          const {'trilha', 'habilidade'}.contains(h['tipoPoder']) &&
          !nomesDevidos.contains(h['nome'])) {
        indices.add(i);
        saiu.add('${h['nome']}');
      }
    }
    final temNomes = {for (final h in lista) '${h['nome']}'};
    final entrou = <String>[];
    _mexendoNosMaximos(() {
      final bruta = _listaBruta('habilidades');
      for (final i in indices.reversed) {
        bruta.removeAt(i);
      }
      for (final p in devidas) {
        if (temNomes.contains(p.nome)) continue;
        bruta.add(p.paraFicha(automatica: true));
        entrou.add(p.nome);
      }
    });
    return (entrou, saiu);
  }

  int _indiceHabilidade(String nomeExato) {
    final alvo = _semCaixa(nomeExato);
    final lista = habilidades;
    for (var i = 0; i < lista.length; i++) {
      if (_semCaixa('${lista[i]['nome'] ?? ''}') == alvo) return i;
    }
    return -1;
  }

  /// Quantas perícias livres a classe ainda dá (base + Intelecto).
  int periciasLivres(ClasseOP classe) =>
      classe.periciasLivresBase + atributo('INT');

  FichaOP copia() => FichaOP(_copiaProfunda(dados));

  static Map<String, dynamic> _copiaProfunda(Map<String, dynamic> m) {
    Object? copiar(Object? v) {
      if (v is Map) {
        return {
          for (final e in v.entries) e.key as String: copiar(e.value),
        };
      }
      if (v is List) return [for (final i in v) copiar(i)];
      return v;
    }

    return copiar(m) as Map<String, dynamic>;
  }
}

/// Ataque pronto para rolar: d20, bônus, dano(s) e crítico.
class ResumoAtaque {
  final int dados;
  final bool melhor;
  final int bonus;

  /// "1d6/1d8" vira duas opções (uma mão / duas mãos, coronhada…).
  final List<String> danos;

  /// O que soma no dano: Força no corpo a corpo, poderes, origem.
  final int danoFixo;
  final int margem;
  final int multiplicador;
  final String? semProficiencia;

  const ResumoAtaque({
    required this.dados,
    required this.melhor,
    required this.bonus,
    required this.danos,
    required this.danoFixo,
    required this.margem,
    required this.multiplicador,
    this.semProficiencia,
  });

  /// "1d8" + 3 → "1d8+3".
  String expressaoDano(String dano) => danoFixo == 0
      ? dano
      : '$dano${danoFixo > 0 ? '+' : ''}$danoFixo';
}
