/// Modificações e maldições de arma (OPRPG p. 60–61 e 145–146), do jeito
/// que a ficha liga e desliga num ataque.
///
/// O ataque guarda só os nomes ativos (`modificacoes`, `maldicoes`); o que
/// cada uma faz vem do catálogo (`assets/catalogo/armas.json`).
class Melhoria {
  final String nome;

  /// Modificação: 'Corpo a corpo e disparo', 'Armas de fogo' ou 'Munição'.
  /// Maldição: vazio.
  final String para;

  /// Maldição: Conhecimento, Energia, Morte ou Sangue. Modificação: vazio.
  final String elemento;

  /// O efeito em notação, para o jogador.
  final String efeito;

  /// O que a ficha aplica sozinha (ver ferramentas/notacao_armas.py).
  final Map<String, dynamic> efeitos;

  /// Restrição: 'automatica', 'balas' (curtas/longas) ou 'corpo'.
  final String so;

  const Melhoria({
    required this.nome,
    this.para = '',
    this.elemento = '',
    required this.efeito,
    this.efeitos = const {},
    this.so = '',
  });

  bool get maldicao => elemento.isNotEmpty;

  factory Melhoria.fromJson(Map<String, dynamic> j) => Melhoria(
    nome: '${j['nome'] ?? ''}',
    para: '${j['para'] ?? ''}',
    elemento: '${j['elemento'] ?? ''}',
    efeito: '${j['efeito'] ?? ''}',
    efeitos: j['efeitos'] is Map
        ? (j['efeitos'] as Map).cast<String, dynamic>()
        : const {},
    so: '${j['so'] ?? ''}',
  );

  int _int(String chave) =>
      efeitos[chave] is num ? (efeitos[chave] as num).toInt() : 0;

  int get ataque => _int('ataque');
  int get dano => _int('dano');
  int get margem => _int('margem');
  int get multiplicador => _int('multiplicador');
  int get dadoArma => _int('dadoArma');
  int get alcance => _int('alcance');
  int get espacos => _int('espacos');
  bool get automatica => efeitos['automatica'] == true;
  bool get compensador => efeitos['compensador'] == true;
  bool get margemDobra => efeitos['margemDobra'] == true;
  String get danoExtra => '${efeitos['danoExtra'] ?? ''}';
  String get dadosArmaExtra => '${efeitos['dadosArmaExtra'] ?? ''}';
}

/// Catálogo carregado de armas.json.
class Melhorias {
  static List<Melhoria> modificacoes = const [];
  static List<Melhoria> maldicoes = const [];

  /// elemento → o elemento que o oprime (p. 99–107).
  static Map<String, String> opressores = const {};

  static void carregar(Map<String, dynamic> j) {
    modificacoes = [
      for (final m in (j['modificacoes'] ?? const []) as List)
        Melhoria.fromJson((m as Map).cast<String, dynamic>()),
    ];
    maldicoes = [
      for (final m in (j['maldicoes'] ?? const []) as List)
        Melhoria.fromJson((m as Map).cast<String, dynamic>()),
    ];
    opressores = ((j['opressores'] ?? const {}) as Map).map(
      (k, v) => MapEntry('$k', '$v'),
    );
  }

  /// Dois elementos que não convivem na mesma arma: um oprime o outro.
  static bool conflitam(String a, String b) =>
      opressores[a] == b || opressores[b] == a;

  /// O livro vai até IV; V e VI só existem de soma de modificação e
  /// maldição — nenhuma patente libera.
  static const _categorias = ['0', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

  static int categoriaNumero(String c) {
    final i = _categorias.indexOf(c.trim());
    return i < 0 ? 0 : i;
  }

  static String categoriaTexto(int n) =>
      _categorias[n.clamp(0, _categorias.length - 1)];

  static const _alcances = ['Curto', 'Médio', 'Longo', 'Extremo'];

  /// Sobe o alcance [passos] categorias ("Curto" +1 → "Médio").
  static String subirAlcance(String alcance, int passos) {
    if (passos == 0) return alcance;
    final i = _alcances.indexOf(alcance.trim());
    if (i < 0) return alcance;
    return _alcances[(i + passos).clamp(0, _alcances.length - 1)];
  }
}

/// O que um ataque tem e pode ter.
class MelhoriasDoAtaque {
  final Map<String, dynamic> ataque;

  /// A arma do catálogo, se o ataque veio de lá.
  final Map<String, dynamic>? arma;

  const MelhoriasDoAtaque(this.ataque, this.arma);

  String get _uso => '${ataque['uso'] ?? arma?['uso'] ?? ''}'.toLowerCase();
  bool get deFogo => _uso.contains('fogo');
  bool get corpoACorpo =>
      _uso.contains('corpo a corpo') || '${ataque['pericia']}' == 'Luta';
  bool get usaBalas => const {
    'Balas curtas',
    'Balas longas',
  }.contains('${arma?['municao'] ?? ''}');

  List<String> _nomes(String chave) => [
    for (final n in (ataque[chave] as List? ?? const [])) '$n',
  ];

  List<String> get nomesModificacoes => _nomes('modificacoes');
  List<String> get nomesMaldicoes => _nomes('maldicoes');

  /// As modificações que cabem nesta arma: de fogo ou de corpo a corpo e
  /// disparo, mais as de munição se ela usa balas curtas ou longas.
  List<Melhoria> get modificacoesPossiveis => [
    for (final m in Melhorias.modificacoes)
      if (_cabe(m)) m,
  ];

  bool _cabe(Melhoria m) {
    if (m.maldicao) return m.so != 'corpo' || corpoACorpo;
    final grupoOk = switch (m.para) {
      'Armas de fogo' => deFogo,
      'Munição' => deFogo && usaBalas,
      _ => !deFogo,
    };
    if (!grupoOk) return false;
    if (m.so == 'automatica') return automaticaBase || _temFerrolho;
    return true;
  }

  bool get automaticaBase =>
      ataque['automatica'] == true || arma?['automatica'] == true;
  bool get _temFerrolho => nomesModificacoes.contains('Ferrolho automático');

  List<Melhoria> get maldicoesPossiveis => [
    for (final m in Melhorias.maldicoes)
      if (_cabe(m)) m,
  ];

  /// As ativas, já resolvidas pelo catálogo (só as que cabem na arma).
  List<Melhoria> get ativas => [
    for (final m in modificacoesPossiveis)
      if (nomesModificacoes.contains(m.nome)) m,
    for (final m in maldicoesPossiveis)
      if (nomesMaldicoes.contains(m.nome)) m,
  ];

  /// Elemento já presente que impede esta maldição, ou null.
  String? conflitoDe(Melhoria m) {
    if (!m.maldicao) return null;
    for (final n in nomesMaldicoes) {
      final outra = Melhorias.maldicoes.where((x) => x.nome == n);
      if (outra.isEmpty || outra.first.nome == m.nome) continue;
      if (Melhorias.conflitam(m.elemento, outra.first.elemento)) {
        return outra.first.elemento;
      }
    }
    return null;
  }

  int get _categoriaBase => Melhorias.categoriaNumero(
    '${ataque['categoriaBase'] ?? ataque['categoria'] ?? arma?['categoria'] ?? '0'}',
  );

  /// Cada modificação +I; a 1ª maldição +II e as seguintes +I (p. 60, 145).
  int get categoria {
    final mods = ativas.where((m) => !m.maldicao).length;
    final mald = ativas.where((m) => m.maldicao).length;
    return _categoriaBase + mods + (mald == 0 ? 0 : mald + 1);
  }

  String get categoriaTexto => Melhorias.categoriaTexto(categoria);
  String get categoriaBaseTexto => Melhorias.categoriaTexto(_categoriaBase);

  bool get amaldicoada => ativas.any((m) => m.maldicao);

  int get espacosBase =>
      int.tryParse(
        '${ataque['espacosBase'] ?? ataque['espacos'] ?? arma?['espacos'] ?? ''}',
      ) ??
      0;

  int get espacos {
    final menos = ativas.fold<int>(0, (s, m) => s + m.espacos);
    final v = espacosBase + menos;
    return v < 0 ? 0 : v;
  }

  String alcance(String base) => Melhorias.subirAlcance(
    base,
    ativas.fold<int>(0, (s, m) => s + m.alcance),
  );
}
