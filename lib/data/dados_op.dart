import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Uma perícia do sistema (TABELA 2.1 do Livro de Regras v1.3).
class Pericia {
  final String nome;
  final String atributo; // AGI, FOR, INT, PRE, VIG
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
    if (nivel == 0) return pvIni + vig; // mundano NEX 0%
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
          for (final p in (j['pericias'] ?? const []) as List) p as String
        ],
        periciasTexto: (j['periciasTexto'] ?? '') as String,
        poder: (j['poder'] ?? '') as String,
        poderDescricao: (j['poderDescricao'] ?? '') as String,
        fonte: (j['fonte'] ?? 'Livro de Regras') as String,
        modificadores:
            ((j['modificadores'] ?? const {}) as Map).cast<String, dynamic>(),
      );
}

class Patente {
  final String nome;
  final int pp;
  final String credito;
  final Map<String, int> limites; // categoria (I..IV) -> quantidade

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
        limites: ((j['limites'] ?? const {}) as Map)
            .map((k, v) => MapEntry(k as String, v as int)),
      );
}

/// Dados do sistema. As classes são constantes — as fórmulas de PV/PE/SAN
/// são regra fixa do livro, e um asset que falhasse ao carregar faria os
/// máximos caírem para o valor atual sem avisar ninguém. O resto (listas
/// longas de perícias, origens e patentes) vem dos assets.
class DadosOP {
  static List<Pericia> pericias = const [];
  static List<Origem> origens = const [];
  static List<Patente> patentes = const [];

  /// OPRPG v1.3, caixas de características de cada classe.
  static const List<ClasseOP> classes = [
    ClasseOP(
      nome: 'Mundano',
      pvIni: 8, pvPorNivel: 0, pvNivelAtributo: false,
      peIni: 1, pePorNivel: 0, peNivelAtributo: false,
      sanIni: 8, sanPorNivel: 0,
      descricao: 'Pessoa comum, NEX 0%. Ao virar agente (NEX 5%), '
          'escolha uma classe.',
      proficiencias: ['Armas simples'],
      periciasLivresBase: 1,
      habilidades: [
        HabilidadeClasse('Empenho', '1 PE → +2 em um teste de perícia.'),
      ],
    ),
    ClasseOP(
      nome: 'Combatente',
      pvIni: 20, pvPorNivel: 4, pvNivelAtributo: true,
      peIni: 2, pePorNivel: 2, peNivelAtributo: true,
      sanIni: 12, sanPorNivel: 3,
      descricao: 'PV 20+Vig (+4+Vig/NEX) · PE 2+Pre (+2+Pre/NEX) · '
          'SAN 12 (+3/NEX)',
      proficiencias: ['Armas simples', 'Armas táticas', 'Proteções leves'],
      periciasEscolha: [
        ['Luta', 'Pontaria'],
        ['Fortitude', 'Reflexos'],
      ],
      periciasLivresBase: 1,
      habilidades: [
        HabilidadeClasse(
            'Ataque Especial',
            '2 PE → +5 no ataque OU no dano; +1 PE por mais +5, até o teto '
                'do seu NEX (3 PE/+10 em 25%, 4 PE/+15 em 55%, 5 PE/+20 em '
                '85%).'),
      ],
    ),
    ClasseOP(
      nome: 'Especialista',
      pvIni: 16, pvPorNivel: 3, pvNivelAtributo: true,
      peIni: 3, pePorNivel: 3, peNivelAtributo: true,
      sanIni: 16, sanPorNivel: 4,
      descricao: 'PV 16+Vig (+3+Vig/NEX) · PE 3+Pre (+3+Pre/NEX) · '
          'SAN 16 (+4/NEX)',
      proficiencias: ['Armas simples', 'Proteções leves'],
      periciasLivresBase: 7,
      habilidades: [
        HabilidadeClasse('Eclético',
            '2 PE → conta como treinado na perícia do teste que está fazendo.'),
        HabilidadeClasse(
            'Perito',
            '2 perícias treinadas à escolha (exceto Luta e Pontaria): 2 PE → '
                '+1d6 no teste; +1 PE aumenta o dado conforme o NEX.'),
      ],
    ),
    ClasseOP(
      nome: 'Ocultista',
      pvIni: 12, pvPorNivel: 2, pvNivelAtributo: true,
      peIni: 4, pePorNivel: 4, peNivelAtributo: true,
      sanIni: 20, sanPorNivel: 5,
      descricao: 'PV 12+Vig (+2+Vig/NEX) · PE 4+Pre (+4+Pre/NEX) · '
          'SAN 20 (+5/NEX)',
      proficiencias: ['Armas simples'],
      periciasFixas: ['Ocultismo', 'Vontade'],
      periciasLivresBase: 3,
      habilidades: [
        HabilidadeClasse(
            'Escolhido pelo Outro Lado',
            'Começa com 3 rituais de 1º círculo e aprende 1 ritual a cada '
                'NEX. Círculos: 2º em 25%, 3º em 55%, 4º em 85%.'),
      ],
    ),
    // Sobrevivendo ao Horror, p. 30. Sobe por estágio (1 a 5), não por NEX,
    // e o limite de PE fica em 1 em todos eles.
    ClasseOP(
      nome: 'Sobrevivente',
      pvIni: 8, pvPorNivel: 2, pvNivelAtributo: false,
      peIni: 2, pePorNivel: 1, peNivelAtributo: false,
      sanIni: 8, sanPorNivel: 2,
      descricao: 'PV 8+Vig (+2/estágio) · PE 2+Pre (+1/estágio) · '
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

  static Future<void> carregar() async {
    Future<List<dynamic>> le(String arquivo) async =>
        jsonDecode(await rootBundle.loadString('assets/data/$arquivo'))
            as List<dynamic>;

    pericias = [
      for (final j in await le('pericias.json'))
        Pericia.fromJson((j as Map).cast<String, dynamic>())
    ];
    origens = [
      for (final j in await le('origens.json'))
        Origem.fromJson((j as Map).cast<String, dynamic>())
    ];
    patentes = [
      for (final j in await le('patentes.json'))
        Patente.fromJson((j as Map).cast<String, dynamic>())
    ];
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
