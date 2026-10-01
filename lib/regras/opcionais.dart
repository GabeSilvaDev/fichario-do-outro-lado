/// Regras opcionais que mexem nos números da ficha.
///
/// - Idade variada (OPRPG p. 172–174): faixa etária e desvantagens de idade.
/// - Ferimentos debilitantes (SAH p. 105): −O num atributo; no Vigor, −1 PV
///   máximo por 5% de NEX.
/// - Jogando sem Sanidade (SAH p. 104–105): Pontos de Determinação no lugar
///   de PE e SAN.
class FaixaEtaria {
  final String nome;
  final String efeito;

  /// Atributos que começam em 0 e o teto deles.
  final Map<String, int> tetoAtributo;
  final int deslocamento;
  final int defesa;
  final int testesResistencia;
  final int peFixo;

  /// Poderes de classe a mais (Adulto: Vivência).
  final int poderesExtras;
  final int desvantagens;

  /// NEX que a faixa soma na criação.
  final int nexExtra;

  /// Atributos que o Aumento de Atributo não pode subir (Idoso).
  final List<String> semAumento;

  /// Benefícios de origem (Criança 1, Adolescente 2, normal 3: 2 perícias
  /// e o poder).
  final int beneficiosOrigem;

  const FaixaEtaria(
    this.nome,
    this.efeito, {
    this.tetoAtributo = const {},
    this.deslocamento = 0,
    this.defesa = 0,
    this.testesResistencia = 0,
    this.peFixo = 0,
    this.poderesExtras = 0,
    this.desvantagens = 0,
    this.nexExtra = 0,
    this.semAumento = const [],
    this.beneficiosOrigem = 3,
  });
}

class Desvantagem {
  final String nome;
  final String efeito;
  final Map<String, int> pericias;
  final int deslocamento;
  final int pvPorNivel;
  final int pePorNivel;

  const Desvantagem(
    this.nome,
    this.efeito, {
    this.pericias = const {},
    this.deslocamento = 0,
    this.pvPorNivel = 0,
    this.pePorNivel = 0,
  });
}

class RegrasOpcionais {
  static const List<FaixaEtaria> faixas = [
    FaixaEtaria(
      'Criança',
      'For e Vig começam em 0 (máx. 1); 6m; Pequeno; 1 benefício de '
          'origem; +2 Defesa e +5 em testes de resistência.',
      tetoAtributo: {'FOR': 1, 'VIG': 1},
      deslocamento: -3,
      defesa: 2,
      testesResistencia: 5,
      beneficiosOrigem: 1,
    ),
    FaixaEtaria(
      'Adolescente',
      'For começa em 0 (máx. 2); 2 benefícios de origem; +5 PE.',
      tetoAtributo: {'FOR': 2},
      peFixo: 5,
      beneficiosOrigem: 2,
    ),
    FaixaEtaria('Jovem', 'Sem modificadores.'),
    FaixaEtaria(
      'Adulto',
      '+1 poder de classe; 1 desvantagem de idade.',
      poderesExtras: 1,
      desvantagens: 1,
    ),
    FaixaEtaria(
      'Maduro',
      'NEX +5% na criação; 2 desvantagens de idade.',
      nexExtra: 5,
      desvantagens: 2,
    ),
    FaixaEtaria(
      'Idoso',
      'NEX +10% na criação; Aumento de Atributo não sobe Agi, For ou Vig; '
          '3 desvantagens de idade.',
      nexExtra: 10,
      desvantagens: 3,
      semAumento: ['AGI', 'FOR', 'VIG'],
    ),
  ];

  static const List<Desvantagem> desvantagens = [
    Desvantagem(
      'Catarata',
      '−5 em Percepção e Pontaria.',
      pericias: {'Percepção': -5, 'Pontaria': -5},
    ),
    Desvantagem(
      'Definhamento',
      '−5 em Fortitude e manobras.',
      pericias: {'Fortitude': -5},
    ),
    Desvantagem(
      '"Devagar, Jovem!"',
      '−3m de deslocamento; sem investida.',
      deslocamento: -3,
    ),
    Desvantagem(
      'Distraído',
      'Surpreendido na 1ª rodada de ação; perde o 1º turno de investigação.',
    ),
    Desvantagem('Frágil', '−2 PV por NEX.', pvPorNivel: -2),
    Desvantagem('Gota', '1d6 de dano a cada teste de Agi ou esquiva.'),
    Desvantagem(
      'Juntas Duras',
      '−5 em Acrobacia e Reflexos.',
      pericias: {'Acrobacia': -5, 'Reflexos': -5},
    ),
    Desvantagem('Melancólico', '−1 PE por NEX.', pePorNivel: -1),
    Desvantagem(
      '"No Meu Tempo"',
      '−5 em Intuição e Vontade.',
      pericias: {'Intuição': -5, 'Vontade': -5},
    ),
    Desvantagem(
      'Pulmão Ruim',
      '1d6 de dano a cada teste de For; sem fôlego extra; investida '
          'deixa fatigado.',
    ),
    Desvantagem(
      'Rabugento',
      '−5 em perícias de Pre, exceto Intimidação.',
      pericias: {
        'Adestramento': -5,
        'Artes': -5,
        'Diplomacia': -5,
        'Enganação': -5,
        'Intuição': -5,
        'Percepção': -5,
        'Religião': -5,
        'Vontade': -5,
      },
    ),
    Desvantagem('Recurvado', 'Conta como Pequeno, sem o bônus de Furtividade.'),
    Desvantagem('Sono Ruim', 'Descanso uma categoria pior.'),
    Desvantagem('Teimoso', 'Não dá nem recebe bônus de ajuda.'),
    Desvantagem('Tosse', '1d6 por rodada; no 1, perde o turno (ou −5 em Pre).'),
  ];

  static FaixaEtaria? faixa(String nome) {
    for (final f in faixas) {
      if (f.nome == nome) return f;
    }
    return null;
  }

  static Desvantagem? desvantagem(String nome) {
    for (final d in desvantagens) {
      if (d.nome == nome) return d;
    }
    return null;
  }

  /// Pontos de Determinação (SAH p. 104): (inicial, por NEX, soma Pre por
  /// NEX?). O Sobrevivente sobe por estágio: 4+Pre, +2 por estágio.
  static const Map<String, (int, int, bool)> determinacao = {
    'Combatente': (6, 3, true),
    'Especialista': (8, 4, true),
    'Ocultista': (10, 5, true),
    'Sobrevivente': (4, 2, false),
    'Mundano': (4, 0, false),
  };
}
