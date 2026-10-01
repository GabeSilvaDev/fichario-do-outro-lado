/// Condições do livro (OPRPG p. 310–311), em notação de mesa.
///
/// Cada condição diz o que muda na ficha. Penalidade em dados é −O (um d20
/// a menos) contada em quantos d20 saem; Defesa em pontos. Efeitos iguais
/// não se somam — vale o mais severo (p. 313) —, então quem junta as
/// condições pega o máximo de cada efeito, não a soma.
class Condicao {
  final String nome;
  final String grupo;

  /// O que a condição já inclui ("fatigado = fraco + vulnerável").
  final List<String> inclui;

  /// Pegar esta condição de novo vira esta outra.
  final String piora;

  /// −Defesa (positivo = penalidade).
  final int defesa;

  /// d20 a menos: 'todos' (qualquer teste), 'pericias', 'ataque',
  /// 'ataqueCorpo', sigla de atributo ou nome de perícia.
  final Map<String, int> dados;

  /// null = normal · 0 = imóvel · 0.5 = metade · 1.5 = fixo em 1,5m.
  final double? deslocamento;

  /// +PE no custo de habilidades e rituais.
  final int custoPe;
  final bool semAcoes;
  final Map<String, int> rd;
  final String efeito;

  const Condicao(
    this.nome,
    this.grupo,
    this.efeito, {
    this.inclui = const [],
    this.piora = '',
    this.defesa = 0,
    this.dados = const {},
    this.deslocamento,
    this.custoPe = 0,
    this.semAcoes = false,
    this.rd = const {},
  });
}

class Condicoes {
  static const List<Condicao> todas = [
    Condicao(
      'Abalado',
      'medo',
      '−O em testes. De novo: apavorado.',
      dados: {'todos': 1},
      piora: 'Apavorado',
    ),
    Condicao(
      'Apavorado',
      'medo',
      '−OO em perícias; foge da fonte do medo.',
      dados: {'pericias': 2},
    ),
    Condicao(
      'Alquebrado',
      'mental',
      '+1 PE no custo de habilidades e rituais.',
      custoPe: 1,
    ),
    Condicao(
      'Atordoado',
      'mental',
      'Desprevenido e sem ações.',
      inclui: ['Desprevenido'],
      semAcoes: true,
    ),
    Condicao('Confuso', 'mental', 'Rola 1d6 no turno para saber o que faz.'),
    Condicao(
      'Esmorecido',
      'mental',
      '−OO em Int e Pre.',
      dados: {'INT': 2, 'PRE': 2},
    ),
    Condicao(
      'Fascinado',
      'mental',
      '−OO em Percepção; só observa.',
      dados: {'Percepção': 2},
    ),
    Condicao(
      'Frustrado',
      'mental',
      '−O em Int e Pre. De novo: esmorecido.',
      dados: {'INT': 1, 'PRE': 1},
      piora: 'Esmorecido',
    ),
    Condicao('Pasmo', 'mental', 'Sem ações.', semAcoes: true),
    Condicao(
      'Fraco',
      'fadiga',
      '−O em Agi, For e Vig. De novo: debilitado.',
      dados: {'AGI': 1, 'FOR': 1, 'VIG': 1},
      piora: 'Debilitado',
    ),
    Condicao(
      'Debilitado',
      'fadiga',
      '−OO em Agi, For e Vig. De novo: inconsciente.',
      dados: {'AGI': 2, 'FOR': 2, 'VIG': 2},
      piora: 'Inconsciente',
    ),
    Condicao(
      'Fatigado',
      'fadiga',
      'Fraco e vulnerável. De novo: exausto.',
      inclui: ['Fraco', 'Vulnerável'],
      piora: 'Exausto',
    ),
    Condicao(
      'Exausto',
      'fadiga',
      'Debilitado, lento e vulnerável. De novo: inconsciente.',
      inclui: ['Debilitado', 'Lento', 'Vulnerável'],
      piora: 'Inconsciente',
    ),
    Condicao(
      'Enjoado',
      'fadiga',
      'Só uma ação por turno (padrão ou movimento).',
    ),
    Condicao(
      'Desprevenido',
      'defesa',
      '−5 Defesa e −O em Reflexos.',
      defesa: 5,
      dados: {'Reflexos': 1},
    ),
    Condicao('Vulnerável', 'defesa', '−2 Defesa.', defesa: 2),
    Condicao(
      'Indefeso',
      'defesa',
      '−10 Defesa, falha em Reflexos, sofre golpe de misericórdia.',
      defesa: 10,
    ),
    Condicao(
      'Caído',
      'defesa',
      '−OO em ataque corpo a corpo; −5 Defesa contra corpo a corpo '
          '(+5 contra distância); desloca 1,5m.',
      dados: {'ataqueCorpo': 2},
      deslocamento: 1.5,
    ),
    Condicao(
      'Cego',
      'sentidos',
      'Desprevenido e lento; −OO em perícias de Agi e For.',
      inclui: ['Desprevenido', 'Lento'],
      dados: {'AGI': 2, 'FOR': 2},
    ),
    Condicao(
      'Ofuscado',
      'sentidos',
      '−O em ataque e Percepção.',
      dados: {'ataque': 1, 'Percepção': 1},
    ),
    Condicao(
      'Surdo',
      'sentidos',
      '−OO em Iniciativa; conjurar é condição ruim.',
      dados: {'Iniciativa': 2},
    ),
    Condicao(
      'Surpreendido',
      'defesa',
      'Desprevenido e sem ações.',
      inclui: ['Desprevenido'],
      semAcoes: true,
    ),
    Condicao(
      'Agarrado',
      'paralisia',
      'Desprevenido e imóvel; −O em ataque; só armas leves.',
      inclui: ['Desprevenido', 'Imóvel'],
      dados: {'ataque': 1},
    ),
    Condicao(
      'Enredado',
      'paralisia',
      'Lento e vulnerável; −O em ataque.',
      inclui: ['Lento', 'Vulnerável'],
      dados: {'ataque': 1},
    ),
    Condicao('Imóvel', 'paralisia', 'Deslocamento 0.', deslocamento: 0),
    Condicao(
      'Lento',
      'paralisia',
      'Deslocamento pela metade; não corre nem investe.',
      deslocamento: 0.5,
    ),
    Condicao(
      'Paralisado',
      'paralisia',
      'Imóvel e indefeso.',
      inclui: ['Imóvel', 'Indefeso'],
      semAcoes: true,
    ),
    Condicao(
      'Inconsciente',
      'paralisia',
      'Indefeso e sem ações.',
      inclui: ['Indefeso'],
      semAcoes: true,
    ),
    Condicao(
      'Petrificado',
      'paralisia',
      'Inconsciente; RD 10.',
      inclui: ['Inconsciente'],
      rd: {'geral': 10},
    ),
    Condicao('Em chamas', 'dano', '1d6 de fogo por turno.'),
    Condicao(
      'Sangrando',
      'dano',
      'Vigor DT 20 no turno; falhou, perde 1d6 PV. Medicina DT 20 estanca.',
    ),
    Condicao(
      'Asfixiado',
      'dano',
      'Prende o fôlego Vig rodadas; depois Fortitude DT 5 (+5/teste) '
          'ou perde 1d6 PV.',
    ),
    Condicao(
      'Envenenado',
      'dano',
      'Dano recorrente do veneno; sempre acumula.',
    ),
  ];

  static Condicao? porNome(String nome) {
    for (final c in todas) {
      if (c.nome == nome) return c;
    }
    return null;
  }

  /// A lista com o que cada uma inclui, sem repetir.
  static List<Condicao> expandir(Iterable<String> nomes) {
    final vistas = <String>{};
    final saida = <Condicao>[];
    void visita(String nome) {
      if (!vistas.add(nome)) return;
      final c = porNome(nome);
      if (c == null) return;
      saida.add(c);
      for (final i in c.inclui) {
        visita(i);
      }
    }

    for (final n in nomes) {
      visita(n);
    }
    return saida;
  }
}
