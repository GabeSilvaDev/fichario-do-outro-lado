import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../regras/poderes.dart';

/// Uma perícia do sistema (TABELA 2.1 do Livro de Regras v1.3).
class Pericia {
  final String nome;
  final String atributo;
  final bool soTreinada;
  final bool sofreCarga;
  final bool usaKit;

  const Pericia({
    required this.nome,
    required this.atributo,
    required this.soTreinada,
    required this.sofreCarga,
    required this.usaKit,
  });

  factory Pericia.fromJson(Map<String, dynamic> j) => Pericia(
    nome: j['nome'] as String,
    atributo: j['atributo'] as String,
    soTreinada: (j['soTreinada'] ?? false) as bool,
    sofreCarga: (j['sofreCarga'] ?? false) as bool,
    usaKit: (j['usaKit'] ?? false) as bool,
  );
}

/// Uma habilidade que a classe dá de saída.
class HabilidadeClasse {
  final String nome;
  final String descricao;

  const HabilidadeClasse(this.nome, this.descricao);
}

/// Uma classe e suas fórmulas de PV/PE/SAN.
///
/// nível = NEX/5 (5% → 1 … 99% → 20). Máximo = inicial + (nível−1)×ganho.
/// Nas classes de agente, o ganho por nível de PV e PE soma o atributo
/// também ("4 PV (+Vig)" na tabela do livro).
class ClasseOP {
  final String nome;
  final int pvIni;
  final int pvPorNivel;
  final bool pvNivelAtributo;
  final int peIni;
  final int pePorNivel;
  final bool peNivelAtributo;
  final int sanIni;
  final int sanPorNivel;
  final String descricao;

  /// Proficiências que a classe concede (OPRPG, caixa de características).
  final List<String> proficiencias;

  /// Perícias que a classe treina de saída. As escolhas do jogador
  /// ("Luta ou Pontaria") ficam em [periciasEscolha].
  final List<String> periciasFixas;
  final List<List<String>> periciasEscolha;

  /// Quantas perícias livres, além das acima: `base + Intelecto`.
  final int periciasLivresBase;

  /// As habilidades que a classe dá já no NEX 5%. O especialista tem duas
  /// (Eclético e Perito); as outras classes, uma.
  final List<HabilidadeClasse> habilidades;

  /// Progressão por estágio em vez de NEX — só o Sobrevivente de
  /// *Sobrevivendo ao Horror* usa. Estágio 1 a 5, e o limite de PE fica
  /// travado em 1 em qualquer estágio.
  final bool porEstagio;

  /// De qual livro a classe veio.
  final String fonte;

  /// Grau de Treinamento (NEX 35% e 70%): quantas perícias sobem um grau,
  /// antes de somar o Intelecto. Zero para quem não é agente.
  final int periciasPorGrau;

  /// Compatibilidade com as telas que mostram só a primeira habilidade.
  String get habilidade => habilidades.isEmpty ? '' : habilidades.first.nome;
  String get habilidadeDescricao =>
      habilidades.isEmpty ? '' : habilidades.first.descricao;

  const ClasseOP({
    required this.nome,
    required this.pvIni,
    required this.pvPorNivel,
    required this.pvNivelAtributo,
    required this.peIni,
    required this.pePorNivel,
    required this.peNivelAtributo,
    required this.sanIni,
    required this.sanPorNivel,
    required this.descricao,
    this.proficiencias = const [],
    this.periciasFixas = const [],
    this.periciasEscolha = const [],
    this.periciasLivresBase = 0,
    this.habilidades = const [],
    this.porEstagio = false,
    this.fonte = 'Livro de Regras',
    this.periciasPorGrau = 0,
  });

  factory ClasseOP.fromJson(Map<String, dynamic> j) => ClasseOP(
    nome: j['nome'] as String,
    pvIni: j['pvIni'] as int,
    pvPorNivel: j['pvPorNivel'] as int,
    pvNivelAtributo: (j['pvNivelAtributo'] ?? false) as bool,
    peIni: j['peIni'] as int,
    pePorNivel: j['pePorNivel'] as int,
    peNivelAtributo: (j['peNivelAtributo'] ?? false) as bool,
    sanIni: j['sanIni'] as int,
    sanPorNivel: j['sanPorNivel'] as int,
    descricao: (j['descricao'] ?? '') as String,
  );

  /// Quantos passos de progressão a ficha já deu. Classe normal conta pelo
  /// NEX; o Sobrevivente conta pelo estágio, que vai de 1 a 5.
  int nivelDe(int nex, int estagio) =>
      porEstagio ? estagio.clamp(1, 5) : _nivel(nex);

  int pvMax(int nex, int vig, {int estagio = 1}) {
    final nivel = nivelDe(nex, estagio);
    if (nivel == 0) return pvIni + vig;
    final ganho = pvPorNivel + (pvNivelAtributo ? vig : 0);
    return pvIni + vig + (nivel - 1) * ganho;
  }

  int peMax(int nex, int pre, {int estagio = 1}) {
    final nivel = nivelDe(nex, estagio);
    if (nivel == 0) return peIni + pre;
    final ganho = pePorNivel + (peNivelAtributo ? pre : 0);
    return peIni + pre + (nivel - 1) * ganho;
  }

  int sanMax(int nex, {int estagio = 1}) {
    final nivel = nivelDe(nex, estagio);
    if (nivel == 0) return sanIni;
    return sanIni + (nivel - 1) * sanPorNivel;
  }

  static int _nivel(int nex) {
    if (nex <= 0) return 0;
    if (nex >= 99) return 20;
    return nex ~/ 5;
  }

  /// Pontos de atributo na criação: o agente recebe 4; quem ainda é civil
  /// (Mundano em NEX 0%, Sobrevivente) recebe 3, por não ter passado pelo
  /// treinamento da Ordem.
  int get pontosAtributo => (nome == 'Mundano' || porEstagio) ? 3 : 4;

  /// Limite de PE por turno = nível de exposição. O Sobrevivente fica em 1
  /// em qualquer estágio (SAH p. 31).
  int limitePe(int nex) => porEstagio ? 1 : limitePeTurno(nex);

  static int limitePeTurno(int nex) {
    final n = _nivel(nex);
    return n < 1 ? 1 : n;
  }

  /// Combatente, especialista e ocultista — quem sobe pela tabela de NEX.
  bool get agente => !porEstagio && nome != 'Mundano';

  /// Aumentos de Atributo já ganhos: NEX 20%, 50%, 80% e 95%, cada um +1 em
  /// um atributo, até 5. O Sobrevivente ganha o dele no estágio 3.
  int aumentosAtributo(int nex, {int estagio = 1}) {
    if (porEstagio) return estagio >= 3 ? 1 : 0;
    if (!agente) return 0;
    return [20, 50, 80, 95].where((m) => nex >= m).length;
  }

  /// Até onde um Aumento de Atributo leva: 5 no agente; o do Sobrevivente
  /// não passa de 3 (SAH p. 31).
  int get tetoAumento => porEstagio ? 3 : 5;

  /// Graus de Treinamento já ganhos: NEX 35% e 70%.
  int grausTreinamento(int nex) {
    if (!agente || periciasPorGrau == 0) return 0;
    return (nex >= 35 ? 1 : 0) + (nex >= 70 ? 1 : 0);
  }

  /// A régua de NEX: 5% em 5% e o 99% no fim.
  static const List<int> reguaNex = [
    5, 10, 15, 20, 25, 30, 35, 40, 45, 50, //
    55, 60, 65, 70, 75, 80, 85, 90, 95, 99,
  ];

  /// O que a classe ganha exatamente neste NEX (tabela de cada classe).
  List<String> marcos(int nex) {
    if (!agente || !reguaNex.contains(nex) || nex == 5) return const [];
    final lista = <String>[];
    if (nex == 10) {
      lista.add('Trilha: escolha a sua e ganhe o 1º poder');
    } else if (const [40, 65, 99].contains(nex)) {
      lista.add('Poder de trilha');
    }
    if (const [15, 30, 45, 60, 75, 90].contains(nex)) {
      lista.add('Poder de ${nome.toLowerCase()}');
    }
    if (const [20, 50, 80, 95].contains(nex)) {
      lista.add('Aumento de Atributo: +1 em um atributo (máx. 5)');
    }
    if (nex == 35) {
      lista.add(
        'Grau de Treinamento: $periciasPorGrau + Int perícias '
        'treinadas viram veteranas (+10)',
      );
    } else if (nex == 70) {
      lista.add(
        'Grau de Treinamento: $periciasPorGrau + Int perícias sobem '
        'um grau (treinada → veterana +10, veterana → expert +15)',
      );
    }
    if (nex == 50) {
      lista.add(
        'Versatilidade: um poder de ${nome.toLowerCase()} ou o 1º '
        'poder de outra trilha',
      );
      lista.add(
        'Afinidade: escolha um elemento (vale a partir do próximo '
        'Transcender)',
      );
    }
    final melhora = _melhoraDaClasse[nome]?[nex];
    if (melhora != null) lista.add(melhora);
    if (nome == 'Ocultista') {
      final anterior = nex == 99 ? 95 : nex - 5;
      if (DadosOP.rituaisPorNex(nex) > DadosOP.rituaisPorNex(anterior)) {
        lista.add('+1 ritual');
      }
    }
    return lista;
  }

  /// A habilidade de 5% que cresce em 25%, 55% e 85% — e a Engenhosidade
  /// do especialista, em 40% e 75% (OPRPG, tabelas 1.3 a 1.5).
  static const Map<String, Map<int, String>> _melhoraDaClasse = {
    'Combatente': {
      25: 'Ataque Especial: até 3 PE (+10)',
      55: 'Ataque Especial: até 4 PE (+15)',
      85: 'Ataque Especial: até 5 PE (+20)',
    },
    'Especialista': {
      25: 'Perito: até 3 PE (+1d8)',
      55: 'Perito: até 4 PE (+1d10)',
      85: 'Perito: até 5 PE (+1d12)',
      40: 'Engenhosidade: Eclético +2 PE conta como veterano',
      75: 'Engenhosidade: Eclético +4 PE conta como expert',
    },
    'Ocultista': {
      25: 'Rituais de 2º círculo',
      55: 'Rituais de 3º círculo',
      85: 'Rituais de 4º círculo',
    },
  };

  /// Em que degrau a habilidade de 5% está neste NEX (Ataque Especial,
  /// Perito, círculo de rituais) — o texto da ficha não muda sozinho.
  List<String> escalasAtuais(int nex) {
    final tabela = _melhoraDaClasse[nome];
    if (tabela == null) return const [];
    final porHabilidade = <String, String>{};
    for (final e in (tabela.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)))) {
      if (e.key > nex) continue;
      porHabilidade[e.value.split(':').first] = e.value;
    }
    return porHabilidade.values.toList();
  }

  /// Os marcos dos NEX depois de [de] até [ate], inclusive, em ordem.
  /// Vazio quando o NEX desceu.
  Map<int, List<String>> marcosEntre(int de, int ate) => {
    for (final n in reguaNex)
      if (n > de && n <= ate && marcos(n).isNotEmpty) n: marcos(n),
  };

  /// O próximo NEX que dá alguma coisa. Null no topo da régua.
  int? proximoMarco(int nex) {
    for (final n in reguaNex) {
      if (n > nex && marcos(n).isNotEmpty) return n;
    }
    return null;
  }
}

class Origem {
  final String nome;

  /// Perícias que a origem treina, prontas para aplicar na ficha.
  final List<String> pericias;

  /// O mesmo, do jeito que o livro escreve ("Ciências e Investigação").
  final String periciasTexto;
  final String poder;
  final String poderDescricao;

  /// De qual livro a origem veio — as 26 do básico e as 20 de
  /// *Sobrevivendo ao Horror* aparecem juntas, mas a mesa precisa saber
  /// qual material está em uso antes de liberar as novas.
  final String fonte;

  /// O que o poder muda nos números da ficha, para o jogador não ter de
  /// somar na mão a cada NEX. Chaves: `pv`, `pvPorNivel`, `pe`,
  /// `pePorNivelImpar`, `sanPorNivel`, `sanMetade`, `defesa`, `limitePe`.
  /// Origem sem efeito numérico (a maioria) vem com o mapa vazio.
  final Map<String, dynamic> modificadores;

  const Origem({
    required this.nome,
    required this.pericias,
    required this.periciasTexto,
    required this.poder,
    required this.poderDescricao,
    this.fonte = 'Livro de Regras',
    this.modificadores = const {},
  });

  int mod(String chave) => (modificadores[chave] ?? 0) as int;
  bool flag(String chave) => modificadores[chave] == true;

  factory Origem.fromJson(Map<String, dynamic> j) => Origem(
    nome: j['nome'] as String,
    pericias: [
      for (final p in (j['pericias'] ?? const []) as List) p as String,
    ],
    periciasTexto: (j['periciasTexto'] ?? '') as String,
    poder: (j['poder'] ?? '') as String,
    poderDescricao: (j['poderDescricao'] ?? '') as String,
    fonte: (j['fonte'] ?? 'Livro de Regras') as String,
    modificadores: ((j['modificadores'] ?? const {}) as Map)
        .cast<String, dynamic>(),
  );
}

class Patente {
  final String nome;
  final int pp;
  final String credito;
  final Map<String, int> limites;

  const Patente({
    required this.nome,
    required this.pp,
    required this.credito,
    required this.limites,
  });

  factory Patente.fromJson(Map<String, dynamic> j) => Patente(
    nome: j['nome'] as String,
    pp: j['pp'] as int,
    credito: (j['credito'] ?? '') as String,
    limites: ((j['limites'] ?? const {}) as Map).map(
      (k, v) => MapEntry(k as String, v as int),
    ),
  );
}

/// Dados do sistema. As classes são constantes — as fórmulas de PV/PE/SAN
/// são regra fixa do livro, e um asset que falhasse ao carregar faria os
/// máximos caírem para o valor atual sem avisar ninguém. O resto (listas
/// longas de perícias, origens e patentes) vem dos assets.
class DadosOP {
  /// Ocultista: 3 rituais em NEX 5% e mais 1 a cada avanço de NEX — o
  /// 95% → 99% também conta (OPRPG p. 32, "sempre que avança de NEX").
  static int rituaisPorNex(int nex) {
    if (nex < 5) return 0;
    if (nex >= 99) return 22;
    return 3 + (nex - 5) ~/ 5;
  }

  /// Círculo mais alto que o Ocultista conhece: 2º em 25%, 3º em 55%,
  /// 4º em 85%.
  static int circuloMaximoPorNex(int nex) {
    if (nex >= 85) return 4;
    if (nex >= 55) return 3;
    if (nex >= 25) return 2;
    return 1;
  }

  static List<Pericia> pericias = const [];
  static List<Origem> origens = const [];
  static List<Patente> patentes = const [];

  /// Poderes, habilidades de trilha e trilhas dos dois livros. Vazio se o
  /// catálogo não carregou — a ficha segue funcionando, só sem automação.
  static List<Poder> poderes = const [];
  static List<Trilha> trilhas = const [];

  static List<Trilha> trilhasDe(String classe) => [
    for (final t in trilhas)
      if (t.classe == classe) t,
  ];

  static Poder? poderPorNome(String nome) {
    for (final p in poderes) {
      if (p.nome == nome) return p;
    }
    return null;
  }

  /// Treinamento Especial (SAH p. 32): o que o sobrevivente ganha ao virar
  /// agente desta classe, por cima do que já tinha.
  static Map<String, int> transicaoSobrevivente(String classe) {
    for (final p in poderes) {
      final t = p.transicao[classe];
      if (t is Map) {
        return {
          for (final e in t.entries)
            if (e.value is num) '${e.key}': (e.value as num).toInt(),
        };
      }
    }
    return _transicaoPadrao[classe] ?? const {};
  }

  static const Map<String, Map<String, int>> _transicaoPadrao = {
    'Combatente': {'pvFixo': 8},
    'Especialista': {'pvFixo': 4, 'peFixo': 1, 'sanFixo': 4},
    'Ocultista': {'peFixo': 2, 'sanFixo': 8},
  };

  /// OPRPG v1.3, caixas de características de cada classe.
  static const List<ClasseOP> classes = [
    ClasseOP(
      nome: 'Mundano',
      pvIni: 8,
      pvPorNivel: 0,
      pvNivelAtributo: false,
      peIni: 1,
      pePorNivel: 0,
      peNivelAtributo: false,
      sanIni: 8,
      sanPorNivel: 0,
      descricao:
          'Pessoa comum, NEX 0%. Ao virar agente (NEX 5%), '
          'escolha uma classe.',
      proficiencias: ['Armas simples'],
      periciasLivresBase: 1,
      habilidades: [
        HabilidadeClasse('Empenho', '1 PE → +2 em um teste de perícia.'),
      ],
    ),
    ClasseOP(
      nome: 'Combatente',
      pvIni: 20,
      pvPorNivel: 4,
      pvNivelAtributo: true,
      peIni: 2,
      pePorNivel: 2,
      peNivelAtributo: true,
      sanIni: 12,
      sanPorNivel: 3,
      descricao:
          'PV 20+Vig (+4+Vig/NEX) · PE 2+Pre (+2+Pre/NEX) · '
          'SAN 12 (+3/NEX)',
      proficiencias: ['Armas simples', 'Armas táticas', 'Proteções leves'],
      periciasEscolha: [
        ['Luta', 'Pontaria'],
        ['Fortitude', 'Reflexos'],
      ],
      periciasLivresBase: 1,
      periciasPorGrau: 2,
      habilidades: [
        HabilidadeClasse(
          'Ataque Especial',
          '2 PE → +5 no ataque OU no dano; +1 PE por mais +5, até o teto '
              'do seu NEX (3 PE/+10 em 25%, 4 PE/+15 em 55%, 5 PE/+20 em '
              '85%).',
        ),
      ],
    ),
    ClasseOP(
      nome: 'Especialista',
      pvIni: 16,
      pvPorNivel: 3,
      pvNivelAtributo: true,
      peIni: 3,
      pePorNivel: 3,
      peNivelAtributo: true,
      sanIni: 16,
      sanPorNivel: 4,
      descricao:
          'PV 16+Vig (+3+Vig/NEX) · PE 3+Pre (+3+Pre/NEX) · '
          'SAN 16 (+4/NEX)',
      proficiencias: ['Armas simples', 'Proteções leves'],
      periciasLivresBase: 7,
      periciasPorGrau: 5,
      habilidades: [
        HabilidadeClasse(
          'Eclético',
          '2 PE → conta como treinado na perícia do teste que está fazendo.',
        ),
        HabilidadeClasse(
          'Perito',
          '2 perícias treinadas à escolha (exceto Luta e Pontaria): 2 PE → '
              '+1d6 no teste; +1 PE aumenta o dado conforme o NEX.',
        ),
      ],
    ),
    ClasseOP(
      nome: 'Ocultista',
      pvIni: 12,
      pvPorNivel: 2,
      pvNivelAtributo: true,
      peIni: 4,
      pePorNivel: 4,
      peNivelAtributo: true,
      sanIni: 20,
      sanPorNivel: 5,
      descricao:
          'PV 12+Vig (+2+Vig/NEX) · PE 4+Pre (+4+Pre/NEX) · '
          'SAN 20 (+5/NEX)',
      proficiencias: ['Armas simples'],
      periciasFixas: ['Ocultismo', 'Vontade'],
      periciasLivresBase: 3,
      periciasPorGrau: 3,
      habilidades: [
        HabilidadeClasse(
          'Escolhido pelo Outro Lado',
          'Começa com 3 rituais de 1º círculo e aprende 1 ritual a cada '
              'NEX. Círculos: 2º em 25%, 3º em 55%, 4º em 85%.',
        ),
      ],
    ),
    ClasseOP(
      nome: 'Sobrevivente',
      pvIni: 8,
      pvPorNivel: 2,
      pvNivelAtributo: false,
      peIni: 2,
      pePorNivel: 1,
      peNivelAtributo: false,
      sanIni: 8,
      sanPorNivel: 2,
      descricao:
          'PV 8+Vig (+2/estágio) · PE 2+Pre (+1/estágio) · '
          'SAN 8 (+2/estágio). Limite de PE sempre 1.',
      proficiencias: ['Armas simples'],
      periciasLivresBase: 1,
      porEstagio: true,
      fonte: 'Sobrevivendo ao Horror',
      habilidades: [
        HabilidadeClasse('Empenho', '1 PE → +2 em um teste de perícia.'),
      ],
    ),
  ];

  /// Lê um asset como texto sem `loadString`: acima de 50 KB ele decodifica
  /// num isolate, o que trava dentro dos testes de widget.
  static Future<String> _texto(String caminho) async =>
      utf8.decode((await rootBundle.load(caminho)).buffer.asUint8List());

  static Future<void> carregar() async {
    Future<List<dynamic>> le(String arquivo) async =>
        jsonDecode(await _texto('assets/data/$arquivo')) as List<dynamic>;

    pericias = [
      for (final j in await le('pericias.json'))
        Pericia.fromJson((j as Map).cast<String, dynamic>()),
    ];
    origens = [
      for (final j in await le('origens.json'))
        Origem.fromJson((j as Map).cast<String, dynamic>()),
    ];
    patentes = [
      for (final j in await le('patentes.json'))
        Patente.fromJson((j as Map).cast<String, dynamic>()),
    ];

    final ps = <Poder>[];
    final ts = <Trilha>[];
    for (final arquivo in ['poderes.json', 'poderes_sah.json']) {
      try {
        final j =
            jsonDecode(await _texto('assets/catalogo/$arquivo'))
                as Map<String, dynamic>;
        for (final p in (j['poderes'] ?? const []) as List) {
          ps.add(Poder.fromJson((p as Map).cast<String, dynamic>()));
        }
        for (final t in (j['trilhas'] ?? const []) as List) {
          ts.add(Trilha.fromJson((t as Map).cast<String, dynamic>()));
        }
      } catch (_) {
        // Catálogo ausente ou quebrado: segue sem ele.
      }
    }
    poderes = ps;
    trilhas = ts;
  }

  static ClasseOP? classePorNome(String nome) {
    for (final c in classes) {
      if (c.nome == nome) return c;
    }
    return null;
  }

  static Patente? patentePorNome(String nome) {
    for (final p in patentes) {
      if (p.nome == nome) return p;
    }
    return null;
  }
}
