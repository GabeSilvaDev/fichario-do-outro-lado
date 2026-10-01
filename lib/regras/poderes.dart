/// Um poder, habilidade de trilha ou habilidade de classe do catálogo
/// (`assets/catalogo/poderes*.json`), em notação de mesa.
///
/// [efeitos] é a parte que a ficha aplica sozinha (Defesa, PV por NEX,
/// bônus em perícia…); o resto fica no texto [efeito] para o jogador.
class Poder {
  final String nome;

  /// 'classe', 'trilha', 'paranormal', 'geral' ou 'habilidade'.
  final String tipo;
  final String classe;
  final String trilha;
  final int nex;
  final int estagio;
  final String elemento;
  final String requisitos;
  final Map<String, dynamic> requisitosRegra;
  final String efeito;
  final String afinidade;
  final bool repetivel;
  final Map<String, dynamic> efeitos;
  final Map<String, dynamic> efeitosAfinidade;
  final Map<String, dynamic> transicao;
  final String fonte;
  final int pagina;

  const Poder({
    required this.nome,
    required this.tipo,
    this.classe = '',
    this.trilha = '',
    this.nex = 0,
    this.estagio = 0,
    this.elemento = '',
    this.requisitos = '',
    this.requisitosRegra = const {},
    this.efeito = '',
    this.afinidade = '',
    this.repetivel = false,
    this.efeitos = const {},
    this.efeitosAfinidade = const {},
    this.transicao = const {},
    this.fonte = 'Livro de Regras',
    this.pagina = 0,
  });

  factory Poder.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> mapa(Object? v) =>
        v is Map ? v.cast<String, dynamic>() : const {};
    int inteiro(Object? v) => v is num ? v.toInt() : 0;
    return Poder(
      nome: '${j['nome'] ?? ''}',
      tipo: '${j['tipo'] ?? 'classe'}',
      classe: '${j['classe'] ?? ''}',
      trilha: '${j['trilha'] ?? ''}',
      nex: inteiro(j['nex']),
      estagio: inteiro(j['estagio']),
      elemento: '${j['elemento'] ?? ''}',
      requisitos: '${j['requisitos'] ?? ''}',
      requisitosRegra: mapa(j['requisitosRegra']),
      efeito: '${j['efeito'] ?? ''}',
      afinidade: '${j['afinidade'] ?? ''}',
      repetivel: j['repetivel'] == true,
      efeitos: mapa(j['efeitos']),
      efeitosAfinidade: mapa(j['efeitosAfinidade']),
      transicao: mapa(j['transicao']),
      fonte: '${j['fonte'] ?? 'Livro de Regras'}',
      pagina: inteiro(j['pagina']),
    );
  }

  /// Um poder paranormal é sempre um Transcender: não ganha a SAN do NEX em
  /// que entra (OPRPG p. 26 e p. 110).
  bool get transcende => tipo == 'paranormal' || efeitos['semSanNoNex'] == true;

  /// O item que a ficha guarda em `habilidades`. Os efeitos vão junto: a
  /// ficha continua certa mesmo sem o catálogo (na mesa, noutro aparelho).
  Map<String, dynamic> paraFicha({int nexAtual = 0, bool automatica = false}) =>
      {
        'nome': nome,
        'descricao': [
          efeito,
          if (afinidade.isNotEmpty) 'Afinidade: $afinidade',
        ].join('\n'),
        'poder': nome,
        'tipoPoder': tipo,
        if (trilha.isNotEmpty) 'trilha': trilha,
        if (elemento.isNotEmpty) 'elemento': elemento,
        if (efeitos.isNotEmpty) 'efeitos': efeitos,
        if (efeitosAfinidade.isNotEmpty) 'efeitosAfinidade': efeitosAfinidade,
        if (transcende) 'transcender': true,
        if (nex > 0) 'nex': nex else if (nexAtual > 0) 'nex': nexAtual,
        if (estagio > 0) 'estagio': estagio,
        if (automatica) 'automatica': true,
      };
}

/// Uma trilha de classe, com o nome e o livro.
class Trilha {
  final String nome;
  final String classe;
  final String fonte;

  const Trilha(this.nome, this.classe, this.fonte);

  factory Trilha.fromJson(Map<String, dynamic> j) => Trilha(
    '${j['nome'] ?? ''}',
    '${j['classe'] ?? ''}',
    '${j['fonte'] ?? 'Livro de Regras'}',
  );
}
