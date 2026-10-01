import 'condicoes.dart';

/// Tudo o que poderes, origem, condições, ferimentos e idade somam na
/// ficha, já juntado. Quem calcula Defesa, PV, testes e dano lê daqui em
/// vez de conhecer cada fonte.
///
/// Regras de empilhamento (OPRPG p. 312–313): bônus de fontes diferentes
/// somam; efeitos iguais de condição não somam — vale o mais severo.
class Efeitos {
  int defesa = 0;
  int pvFixo = 0, pvPorNivel = 0;
  int peFixo = 0, pePorNivel = 0, pePorDoisNiveis = 0;
  int sanFixo = 0, sanPorNivel = 0;
  int limitePe = 0;
  int dt = 0;
  int deslocamento = 0;
  int carga = 0;
  bool cargaSomaInt = false;
  String peSomaAtributo = '';
  int testesResistencia = 0;
  int danoCorpo = 0, danoDistancia = 0, danoFogo = 0;
  int margemCorpo = 0, margemDistancia = 0;
  int multiplicador = 0;
  int treinaPericias = 0;
  int custoRitual = 0;

  /// (atributo, 'corpo' | 'distancia' | 'todos').
  final List<(String, String)> danoSomaAtributo = [];
  final Set<String> treina = {};
  final Set<String> proficiencias = {};
  final Map<String, int> pericias = {};
  final Map<String, int> rd = {};

  // Condições: o mais severo de cada efeito.
  int defesaCondicao = 0;
  final Map<String, int> dadosCondicao = {};
  double? deslocamentoCondicao;
  int custoPeCondicao = 0;
  bool semAcoes = false;

  /// d20 a menos que se somam (fontes diferentes): ferimento, proteção sem
  /// proficiência.
  final Map<String, int> dadosPenalidade = {};

  /// Soma um bloco `efeitos` do catálogo (ou da origem).
  void somar(Map<String, dynamic> e) {
    int n(String k) => e[k] is num ? (e[k] as num).toInt() : 0;
    defesa += n('defesa');
    pvFixo += n('pvFixo') + n('pv');
    pvPorNivel += n('pvPorNivel');
    peFixo += n('peFixo') + n('pe');
    pePorNivel += n('pePorNivel');
    pePorDoisNiveis += n('pePorDoisNiveis');
    sanFixo += n('sanFixo') + n('san');
    sanPorNivel += n('sanPorNivel');
    limitePe += n('limitePe');
    dt += n('dt');
    deslocamento += n('deslocamento');
    carga += n('carga');
    if (e['cargaSomaInt'] == true) cargaSomaInt = true;
    if (e['peSomaAtributo'] is String) {
      peSomaAtributo = e['peSomaAtributo'] as String;
    }
    testesResistencia += n('testesResistencia');
    danoCorpo += n('danoCorpo');
    danoDistancia += n('danoDistancia');
    danoFogo += n('danoFogo');
    margemCorpo += n('margemCorpo');
    margemDistancia += n('margemDistancia');
    multiplicador += n('multiplicador');
    treinaPericias += n('treinaPericias');
    custoRitual += n('custoRitual');
    final atributo = e['danoSomaAtributo'];
    if (atributo is String && atributo.isNotEmpty) {
      danoSomaAtributo.add((
        atributo,
        '${e['danoSomaAtributoAtaque'] ?? 'todos'}',
      ));
    }
    for (final t in (e['treina'] is List ? e['treina'] as List : const [])) {
      treina.add('$t');
    }
    for (final p
        in (e['proficiencias'] is List
            ? e['proficiencias'] as List
            : const [])) {
      proficiencias.add('$p');
    }
    _somarMapa(pericias, e['pericias']);
    _somarMapa(rd, e['rd']);
  }

  static void _somarMapa(Map<String, int> alvo, Object? fonte) {
    if (fonte is! Map) return;
    for (final x in fonte.entries) {
      if (x.value is num) {
        alvo['${x.key}'] = (alvo['${x.key}'] ?? 0) + (x.value as num).toInt();
      }
    }
  }

  /// Aplica as condições (e o que cada uma inclui), sem somar iguais.
  void aplicarCondicoes(Iterable<String> nomes) {
    for (final c in Condicoes.expandir(nomes)) {
      if (c.defesa > defesaCondicao) defesaCondicao = c.defesa;
      for (final d in c.dados.entries) {
        if (d.value > (dadosCondicao[d.key] ?? 0)) {
          dadosCondicao[d.key] = d.value;
        }
      }
      final desl = c.deslocamento;
      if (desl != null) {
        // Severidade: imóvel (0) > 1,5m fixo > metade.
        final atual = deslocamentoCondicao;
        int peso(double v) => v == 0 ? 3 : (v == 1.5 ? 2 : 1);
        if (atual == null || peso(desl) > peso(atual)) {
          deslocamentoCondicao = desl;
        }
      }
      if (c.custoPe > custoPeCondicao) custoPeCondicao = c.custoPe;
      if (c.semAcoes) semAcoes = true;
      for (final r in c.rd.entries) {
        if (r.value > (rd[r.key] ?? 0)) rd[r.key] = r.value;
      }
    }
  }

  /// d20 a menos num teste desta perícia, com este atributo-base.
  /// [ataque]: 'corpo' ou 'distancia' quando é teste de ataque.
  int dadosAMenos(String pericia, String atributo, {String ataque = ''}) {
    var condicao = 0;
    void considera(String chave) {
      final v = dadosCondicao[chave] ?? 0;
      if (v > condicao) condicao = v;
    }

    considera('todos');
    considera('pericias');
    considera(atributo);
    considera(pericia);
    if (ataque.isNotEmpty) {
      considera('ataque');
      if (ataque == 'corpo') considera('ataqueCorpo');
    }
    return condicao +
        (dadosPenalidade[atributo] ?? 0) +
        (dadosPenalidade['todos'] ?? 0);
  }
}
