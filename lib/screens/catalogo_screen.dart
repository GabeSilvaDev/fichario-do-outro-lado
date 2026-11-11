import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../theme.dart';
import '../widgets/filtro_rituais.dart';
import '../util/texto.dart';

/// O catálogo do sistema: os 81 rituais e tudo do capítulo de armas —
/// armas, munições, modificações, maldições, explosivos, componentes
/// ritualísticos e proteções.
///
/// Serve para duas coisas: consultar no meio da sessão ("quanto custa
/// Eletrocussão mesmo?") e **jogar direto numa ficha** — quando a tela é
/// aberta a partir de uma ficha, cada item ganha um botão que devolve o
/// ritual ou o ataque já montado para quem chamou.
///
/// Os dados vêm de `assets/catalogo/*.json`, gerados por
/// `ferramentas/gerar_catalogo.py`: ficha técnica do livro + efeito escrito
/// em notação própria (ver LICENCA.md).
class CatalogoScreen extends StatefulWidget {
  /// Quando true, cada item mostra o botão de adicionar e a tela devolve o
  /// item escolhido pelo Navigator.
  final bool escolhendo;

  /// Abre direto na aba de armas.
  final bool comecarEmArmas;

  /// Círculo mais alto que o NEX da ficha libera (null = sem regra). O que
  /// passa disso continua na lista, marcado: dá para pôr, mas a ficha avisa.
  final int? circuloMaximo;

  /// NEX da ficha, para o aviso dizer de onde vem o limite.
  final int? nex;

  /// Quantos rituais a ficha ainda aprende (null = sem regra). Zero ou menos:
  /// cada ritual escolhido fica além do limite.
  final int? rituaisRestantes;

  /// Rituais já na ficha — ficam de fora da lista.
  final Set<String> nomesExcluidos;

  const CatalogoScreen({
    super.key,
    this.escolhendo = false,
    this.comecarEmArmas = false,
    this.circuloMaximo,
    this.nex,
    this.rituaisRestantes,
    this.nomesExcluidos = const {},
  });

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  List<Map<String, dynamic>>? _rituais;
  List<Map<String, dynamic>>? _armas;
  List<Map<String, dynamic>>? _protecoes;
  Map<String, String> _tiposDano = const {};

  /// Munições, modificações, maldições, itens de ataque e componentes.
  Map<String, dynamic> _extras = const {};
  String _erro = '';
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final r = jsonDecode(
        await rootBundle.loadString('assets/catalogo/rituais.json'),
      );
      final a = jsonDecode(
        await rootBundle.loadString('assets/catalogo/armas.json'),
      );
      setState(() {
        _rituais = [
          for (final x in (r['rituais'] as List))
            (x as Map).cast<String, dynamic>(),
        ];
        _armas = [
          for (final x in (a['armas'] as List))
            (x as Map).cast<String, dynamic>(),
        ];
        _protecoes = [
          for (final x in (a['protecoes'] as List))
            (x as Map).cast<String, dynamic>(),
        ];
        _tiposDano = (a['tiposDeDano'] as Map).map(
          (k, v) => MapEntry(k as String, v as String),
        );
        _extras = (a as Map).cast<String, dynamic>();
      });
    } catch (e) {
      setState(() => _erro = '$e');
    }
  }

  bool _casa(String texto) => _filtro.isEmpty || casaBusca(texto, _filtro);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.comecarEmArmas ? 1 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.escolhendo ? 'Escolher do catálogo' : 'Catálogo'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Rituais'),
              Tab(text: 'Armas'),
            ],
          ),
        ),
        body: _erro.isNotEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Não consegui abrir o catálogo.\n\n$_erro',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Cores.tinta2),
                  ),
                ),
              )
            : _rituais == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: TextField(
                      decoration: const InputDecoration(
                        isDense: true,
                        prefixIcon: Icon(Icons.search, size: 18),
                        labelText: 'Procurar',
                      ),
                      onChanged: (v) => setState(() => _filtro = v),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(children: [_abaRituais(), _abaArmas()]),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _abaRituais() {
    final lista = _rituais!
        .where((r) => !widget.nomesExcluidos.contains(r['nome']))
        .where(
          (r) =>
              _casa(r['nome'] as String) ||
              _casa(r['elemento'] as String) ||
              _casa(r['efeito'] as String),
        )
        .toList();
    if (lista.isEmpty) return const _Vazio('Nenhum ritual com esse nome.');

    String grupo(Map<String, dynamic> r) =>
        grupoDoRitual(_agrupa, r['circulo'] as int, '${r['elemento']}');
    final grupos = <String, List<Map<String, dynamic>>>{};
    for (final r in lista) {
      grupos.putIfAbsent(grupo(r), () => []).add(r);
    }
    // Dentro do grupo, ordena pela outra dimensão e depois pelo nome.
    int ordemElemento(Map<String, dynamic> r) {
      final i = elementosDeRitual.indexOf('${r['elemento']}');
      return i < 0 ? 99 : i;
    }

    for (final g in grupos.values) {
      g.sort((a, b) {
        final c = _agrupa == AgrupaRituais.circulo
            ? ordemElemento(a).compareTo(ordemElemento(b))
            : (a['circulo'] as int).compareTo(b['circulo'] as int);
        return c != 0 ? c : '${a['nome']}'.compareTo('${b['nome']}');
      });
    }
    final filtro = grupos.containsKey(_filtroGrupo) ? _filtroGrupo : null;
    final ordem = gruposEmOrdem(_agrupa, grupos.keys);
    final restantes = widget.rituaisRestantes;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
      children: [
        if (widget.escolhendo && widget.circuloMaximo != null)
          _avisoTopo(
            'NEX ${widget.nex ?? ''}%: até o ${widget.circuloMaximo}º círculo'
            '${restantes == null ? '' : ' · pode aprender mais ${restantes < 0 ? 0 : restantes}'}'
            '. O que passa disso aparece marcado; dá para pôr, mas a ficha '
            'fica avisando.',
            alerta: restantes != null && restantes <= 0,
          ),
        const SizedBox(height: 6),
        FiltroRituais(
          modo: _agrupa,
          filtro: filtro,
          contagem: {for (final e in grupos.entries) e.key: e.value.length},
          aoMudarModo: (m) => setState(() {
            _agrupa = m;
            _filtroGrupo = null;
          }),
          aoFiltrar: (g) => setState(() => _filtroGrupo = g),
        ),
        for (final g in ordem)
          if (filtro == null || filtro == g) ...[
            TituloGrupoRitual(g, grupos[g]!.length),
            for (final r in grupos[g]!) _cartaoRitual(r),
          ],
      ],
    );
  }

  AgrupaRituais _agrupa = AgrupaRituais.circulo;
  String? _filtroGrupo;

  Widget _avisoTopo(String texto, {bool alerta = false}) => Container(
    margin: const EdgeInsets.only(top: 6, bottom: 4),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: (alerta ? Cores.sangue : Cores.conhecimento).withValues(alpha: .1),
      border: Border.all(
        color: (alerta ? Cores.sangue : Cores.conhecimento).withValues(
          alpha: .5,
        ),
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      texto,
      style: TextStyle(
        fontSize: 12.5,
        color: alerta ? Cores.sangue : Cores.conhecimento,
      ),
    ),
  );

  /// Por que este ritual fica fora da regra para a ficha que está escolhendo.
  List<String> _foraDaRegra(Map<String, dynamic> r) {
    if (!widget.escolhendo) return const [];
    final max = widget.circuloMaximo;
    final restantes = widget.rituaisRestantes;
    return [
      if (max != null && (r['circulo'] as int) > max)
        '${r['circulo']}º círculo: em NEX ${widget.nex ?? ''}% o máximo é o '
            '$maxº.',
      if (restantes != null && restantes <= 0)
        'A ficha já tem todos os rituais que o NEX dá.',
    ];
  }

  /// Uma linha curta para o subtítulo: o motivo, não só "fora da regra".
  String _resumoFora(Map<String, dynamic> r) {
    final max = widget.circuloMaximo;
    final acima = max != null && (r['circulo'] as int) > max;
    final cheio =
        widget.rituaisRestantes != null && widget.rituaisRestantes! <= 0;
    if (acima && cheio) return 'acima do círculo e além do limite';
    if (acima) return 'acima do $maxº círculo do seu NEX';
    return 'além do limite de rituais';
  }

  Widget _cartaoRitual(Map<String, dynamic> r) {
    final ampliacoes = (r['ampliacoes'] as List).cast<Map>();
    final fora = _foraDaRegra(r);
    return Card(
      key: ValueKey('ritual-cat-${r['nome']}'),
      shape: fora.isEmpty
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Cores.sangue),
            ),
      child: ExpansionTile(
        key: ValueKey('${r['nome']}-${_filtro.isNotEmpty}'),
        shape: const Border(),
        initiallyExpanded: _filtro.isNotEmpty && _casa(r['nome'] as String),
        title: Text(
          r['nome'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '${_agrupa == AgrupaRituais.circulo ? r['elemento'] : '${r['circulo']}º círculo'} · '
          '${r['custo']} PE · ${r['execucao']} · ${r['alcance']}'
          '${(r['alvo'] as String).isEmpty ? '' : ' · ${r['alvo']}'}'
          '${fora.isEmpty ? '' : '\n⚠ ${_resumoFora(r)}'}',
          style: TextStyle(
            fontSize: 12,
            color: fora.isEmpty ? Cores.tinta2 : Cores.sangue,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _linha('Duração', r['duracao'] as String),
                _linha('Resistência', r['resistencia'] as String),
                const SizedBox(height: 6),
                Text(
                  r['efeito'] as String,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                for (final a in ampliacoes) ...[
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: Cores.tinta2,
                      ),
                      children: [
                        TextSpan(
                          text: '${a['nome']} (+${a['custo']} PE): ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Cores.energiaViva,
                          ),
                        ),
                        TextSpan(text: a['efeito'] as String),
                      ],
                    ),
                  ),
                ],
                for (final f in fora)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Cores.sangue,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            f,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Cores.sangue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.escolhendo) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: fora.isEmpty
                        ? FilledButton.icon(
                            key: ValueKey('por-${r['nome']}'),
                            onPressed: () =>
                                Navigator.of(context).pop(_ritualParaFicha(r)),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Pôr na ficha'),
                          )
                        : OutlinedButton.icon(
                            key: ValueKey('por-${r['nome']}'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Cores.sangue,
                            ),
                            onPressed: () =>
                                Navigator.of(context).pop(_ritualParaFicha(r)),
                            icon: const Icon(Icons.warning_amber, size: 16),
                            label: const Text('Pôr mesmo assim'),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formato que a ficha guarda em `rituais`.
  Map<String, dynamic> _ritualParaFicha(Map<String, dynamic> r) {
    final ampliacoes = (r['ampliacoes'] as List).cast<Map>();
    final extras = [
      for (final a in ampliacoes)
        '${a['nome']} (+${a['custo']} PE): ${a['efeito']}',
    ].join('\n');
    return {
      'nome': r['nome'],
      'elemento': r['elemento'],
      'circulo': '${r['circulo']}º',
      'custo': '${r['custo']} PE',
      'execucao': r['execucao'],
      'alcance': r['alcance'],
      'duracao': r['duracao'],
      'alvo': r['alvo'],
      'resistencia': r['resistencia'],
      'efeito': r['efeito'],
      'ampliacoes': [
        for (final a in ampliacoes)
          {'nome': a['nome'], 'custo': a['custo'], 'efeito': a['efeito']},
      ],
      'pagina': r['pagina'],
      'descricao': [
        if ((r['alvo'] as String).isNotEmpty) 'Alvo: ${r['alvo']}',
        if ((r['resistencia'] as String).isNotEmpty)
          'Resistência: ${r['resistencia']}',
        r['efeito'],
        if (extras.isNotEmpty) extras,
      ].join('\n'),
    };
  }

  // --- Aba de armas -----------------------------------------------------

  /// Seções da aba: o que o capítulo 3 do livro traz para o combate.
  static const _secoes = [
    'Armas',
    'Munições',
    'Modificações',
    'Maldições',
    'Explosivos e itens',
    'Componentes',
    'Proteções',
  ];
  int _secao = 0;

  Widget _abaArmas() {
    return Column(
      children: [
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            children: [
              for (var i = 0; i < _secoes.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    key: ValueKey('secao-armas-$i'),
                    label: Text(_secoes[i]),
                    selected: _secao == i,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _secao = i),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: switch (_secao) {
            0 => _listaArmas(),
            1 => _listaMunicoes(),
            2 => _listaModificacoes(),
            3 => _listaMaldicoes(),
            4 => _listaItensDeAtaque(),
            5 => _listaComponentes(),
            _ => _listaProtecoes(),
          },
        ),
      ],
    );
  }

  static const _distancias = {
    'Curto': 'Curto (9 m)',
    'Médio': 'Médio (18 m)',
    'Longo': 'Longo (36 m)',
    'Extremo': 'Extremo (90 m)',
  };

  /// "19/x3" → (19, 3); "x4" → (20, 4); "18" → (18, 2).
  static (int, int) _critico(String texto) {
    var margem = 20;
    var mult = 2;
    for (final parte in texto.split('/')) {
      final t = parte.trim().toLowerCase();
      if (t.startsWith('x')) {
        mult = int.tryParse(t.substring(1)) ?? mult;
      } else if (int.tryParse(t) != null) {
        margem = int.parse(t);
      }
    }
    return (margem, mult);
  }

  static String _textoMargem(int margem) =>
      margem >= 20 ? 'só no 20 natural' : 'de $margem a 20 no d20';

  static String _multiplicar(String dano, int vezes) =>
      dano.replaceAllMapped(RegExp(r'(\d*)d(\d+)'), (m) {
        final n = (m[1]!.isEmpty ? 1 : int.parse(m[1]!)) * vezes;
        return '${n}d${m[2]}';
      });

  String _tipo(String sigla) => _tiposDano[sigla] ?? sigla;

  /// "1d6/1d8" → duas opções; "1d6/1d6" (cajado, as duas pontas) → uma.
  static List<String> _opcoesDeDano(String dano) {
    final partes = [for (final p in dano.split('/')) p.trim()];
    return partes.toSet().length == 1 ? [partes.first] : partes;
  }

  /// O que cada opção de dano quer dizer na arma.
  static String _rotuloOpcao(String arma, int quantas, int i) {
    if (quantas < 2) return '';
    if (arma == 'Coronhada') {
      return i == 0 ? ' (arma leve ou de uma mão)' : ' (arma de duas mãos)';
    }
    return i == 0 ? ' (uma mão)' : ' (duas mãos)';
  }

  List<Map<String, dynamic>> _lista(String chave) => [
    for (final x in (_extras[chave] as List? ?? const []))
      (x as Map).cast<String, dynamic>(),
  ];

  Widget _listaArmas() {
    final armas = _armas!
        .where(
          (a) =>
              _casa(a['nome'] as String) ||
              _casa(a['familia'] as String) ||
              _casa(a['uso'] as String),
        )
        .toList();
    if (armas.isEmpty) return const _Vazio('Nenhuma arma com esse nome.');
    final grupos = <String, List<Map<String, dynamic>>>{};
    for (final a in armas) {
      grupos.putIfAbsent(a['familia'] as String, () => []).add(a);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
      children: [
        const Text(
          'Toque numa arma para ver tudo: dano, crítico, alcance, munição e '
          'regras especiais. Proficiência: todo mundo usa armas simples; só '
          'o combatente começa com táticas; pesadas, ninguém.',
          style: TextStyle(fontSize: 12, color: Cores.tinta2),
        ),
        for (final entrada in grupos.entries) ...[
          FaixaSecao(entrada.key.isEmpty ? 'Armas' : entrada.key),
          for (final a in entrada.value) _cartaoArma(a),
        ],
      ],
    );
  }

  Widget _cartaoArma(Map<String, dynamic> a) {
    final dano = '${a['dano'] ?? ''}';
    final (margem, mult) = _critico('${a['critico'] ?? ''}');
    final tipo = _tipo('${a['tipo'] ?? ''}');
    final alcance = '${a['alcance'] ?? ''}';
    final uso = '${a['uso'] ?? ''}';
    final usoMin = uso.toLowerCase();
    final corpo = usoMin.contains('corpo a corpo');
    final agil = a['agil'] == true;
    final opcoes = _opcoesDeDano(dano);
    String opcao(int i) => _rotuloOpcao('${a['nome']}', opcoes.length, i);
    final atributo = corpo || a['arremesso'] == true || a['somaForca'] == true
        ? (agil ? '+ Força ou Agilidade (a maior)' : '+ Força')
        : 'sem atributo (disparo/fogo)';
    final municao = '${a['municao'] ?? ''}';
    final pacote = _lista('municoes').where((m) => m['nome'] == municao);
    final especial = [
      for (final e in (a['especial'] as List? ?? const [])) '$e',
    ];

    return Card(
      key: ValueKey('arma-${a['nome']}'),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(
          a['nome'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          [
            '${opcoes.join('/')} $tipo',
            'crítico ${margem < 20 ? '$margem–20 ' : ''}×$mult',
            if (alcance.isNotEmpty) alcance,
          ].join(' · '),
          style: const TextStyle(fontSize: 12.5, color: Cores.tinta2),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ('${a['descricao'] ?? ''}'.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${a['descricao']}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          _bloco('DANO BASE', [
            for (var i = 0; i < opcoes.length; i++)
              '${opcoes[i]}${opcao(i)} de $tipo',
            atributo,
          ]),
          _bloco('CRÍTICO', [
            'Ameaça ${_textoMargem(margem)}; o dano multiplica por $mult.',
            for (var i = 0; i < opcoes.length; i++)
              'No crítico: ${_multiplicar(opcoes[i], mult)}${opcao(i)} '
                  '(bônus fixo e atributo não multiplicam)',
          ]),
          _bloco('USO', [
            uso,
            alcance.isEmpty
                ? (corpo
                      ? 'Corpo a corpo (sem alcance: arremessar dá −1d20 em '
                            'alcance curto)'
                      : 'Sem alcance')
                : 'Alcance ${_distancias[alcance] ?? alcance} · até o dobro '
                      'com −1d20',
            'Proficiência: ${a['familia']}',
            'Categoria ${'${a['categoria']}'.isEmpty ? '—' : a['categoria']} · '
                '${'${a['espacos']}'.isEmpty ? '—' : a['espacos']} espaço(s)',
          ]),
          if (municao.isNotEmpty)
            _bloco('MUNIÇÃO', [
              pacote.isEmpty
                  ? municao
                  : '$municao · um pacote dura ${pacote.first['duracao']} · '
                        'categoria ${pacote.first['categoria']}',
            ]),
          if (especial.isNotEmpty) _bloco('REGRAS DA ARMA', especial),
          Row(
            children: [
              Text(
                'Livro de Regras p. ${a['pagina'] ?? 55}'
                '${especial.isNotEmpty || '${a['descricao'] ?? ''}'.isNotEmpty ? ' e 58–59' : ''}',
                style: const TextStyle(fontSize: 11, color: Cores.tinta2),
              ),
              const Spacer(),
              if (widget.escolhendo)
                FilledButton.icon(
                  key: ValueKey('por-${a['nome']}'),
                  onPressed: () => Navigator.of(context).pop(_armaParaFicha(a)),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Pôr na ficha'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Rótulo pequeno + linhas, dentro do cartão aberto.
  Widget _bloco(String titulo, List<String> linhas) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: Cores.conhecimento,
            ),
          ),
          const SizedBox(height: 3),
          for (final l in linhas)
            if (l.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(l, style: const TextStyle(fontSize: 13.5)),
              ),
        ],
      ),
    );
  }

  /// Formato que a ficha guarda em `ataques`. A perícia sai do uso: arma de
  /// fogo e de disparo rolam Pontaria, o resto rola Luta. `arma` guarda o
  /// nome da tabela: é por ele que a ficha acha as habilidades depois.
  Map<String, dynamic> _armaParaFicha(Map<String, dynamic> a) {
    final uso = (a['uso'] as String).toLowerCase();
    final distancia = uso.contains('fogo') || uso.contains('disparo');
    final (margem, mult) = _critico('${a['critico'] ?? ''}');
    return {
      'nome': a['nome'],
      'arma': a['nome'],
      'pericia': distancia ? 'Pontaria' : 'Luta',
      'bonus': 0,
      'dano': a['dano'],
      'tipo': _tipo('${a['tipo'] ?? ''}'),
      'margem': margem < 20 ? '$margem' : '',
      'critico': 'x$mult',
      'alcance': (a['alcance'] as String).isEmpty
          ? (distancia ? '' : 'Corpo a corpo')
          : a['alcance'] as String,
      'especial': '',
      'familia': a['familia'],
      'uso': a['uso'],
      'categoria': a['categoria'],
      'espacos': a['espacos'],
    };
  }

  Widget _cartaoSimples({
    required String titulo,
    String? subtitulo,
    required List<Widget> corpo,
    Map<String, dynamic>? paraFicha,
  }) {
    return Card(
      key: ValueKey('item-$titulo'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (widget.escolhendo && paraFicha != null)
                  IconButton(
                    key: ValueKey('por-$titulo'),
                    tooltip: 'Pôr na ficha',
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Cores.energiaViva,
                    ),
                    onPressed: () => Navigator.of(context).pop(paraFicha),
                  ),
              ],
            ),
            if (subtitulo != null)
              Text(
                subtitulo,
                style: const TextStyle(fontSize: 12, color: Cores.tinta2),
              ),
            const SizedBox(height: 6),
            ...corpo,
          ],
        ),
      ),
    );
  }

  Widget _texto(String t, {Color? cor}) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Text(t, style: TextStyle(fontSize: 13.5, color: cor)),
  );

  Widget _listaMunicoes() {
    final itens = _lista('municoes').where((m) => _casa('${m['nome']}'));
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
      children: [
        const Text(
          'Munição vem em pacotes: cada um dura o tempo indicado, não importa '
          'quantos tiros você der (p. 59).',
          style: TextStyle(fontSize: 12, color: Cores.tinta2),
        ),
        const SizedBox(height: 8),
        for (final m in itens)
          _cartaoSimples(
            titulo: '${m['nome']}',
            subtitulo:
                'Categoria ${m['categoria']} · ${m['espacos']} espaço(s)',
            corpo: [
              _texto('Dura: ${m['duracao']}'),
              _texto('Usada em: ${m['usadaEm']}', cor: Cores.tinta2),
            ],
            paraFicha: {
              'nome': m['nome'],
              'categoria': m['categoria'],
              'espacos': m['espacos'],
            },
          ),
      ],
    );
  }

  Widget _listaModificacoes() {
    final grupos = <String, List<Map<String, dynamic>>>{};
    for (final m in _lista('modificacoes')) {
      if (!_casa('${m['nome']}') && !_casa('${m['efeito']}')) continue;
      grupos.putIfAbsent('${m['para']}', () => []).add(m);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
      children: [
        const Text(
          'Pedidas no começo da missão. Cada modificação sobe a categoria da '
          'arma em I, e modificações iguais não acumulam (p. 60). Anote no '
          'nome e nos bônus do ataque.',
          style: TextStyle(fontSize: 12, color: Cores.tinta2),
        ),
        for (final g in grupos.entries) ...[
          FaixaSecao(g.key),
          for (final m in g.value)
            _cartaoSimples(
              titulo: '${m['nome']}',
              corpo: [_texto('${m['efeito']}')],
            ),
        ],
      ],
    );
  }

  Widget _listaMaldicoes() {
    final grupos = <String, List<Map<String, dynamic>>>{};
    for (final m in _lista('maldicoes')) {
      if (!_casa('${m['nome']}') && !_casa('${m['efeito']}')) continue;
      grupos.putIfAbsent('${m['elemento']}', () => []).add(m);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
      children: [
        const Text(
          'Só para Agente Especial em diante. A 1ª maldição sobe a categoria '
          'em II, as outras em I. Preço: para cada maldição, perde 2 SAN ao '
          'falhar num teste do atributo do elemento — Conhecimento: Int · '
          'Energia: Agi · Morte: Pre · Sangue: For ou Vig (p. 145).',
          style: TextStyle(fontSize: 12, color: Cores.tinta2),
        ),
        for (final g in grupos.entries) ...[
          FaixaSecao(g.key),
          for (final m in g.value)
            _cartaoSimples(
              titulo: '${m['nome']}',
              corpo: [_texto('${m['efeito']}')],
            ),
        ],
      ],
    );
  }

  Widget _listaItensDeAtaque() {
    final itens = _lista(
      'itensDeAtaque',
    ).where((m) => _casa('${m['nome']}') || _casa('${m['efeito']}'));
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
      children: [
        const Text(
          'Equipamento geral que serve para atacar (p. 63–66). O que tem dano '
          'entra na ficha como ataque e item; o resto, só como item.',
          style: TextStyle(fontSize: 12, color: Cores.tinta2),
        ),
        const SizedBox(height: 8),
        for (final m in itens)
          _cartaoSimples(
            titulo: '${m['nome']}',
            subtitulo:
                'Categoria ${m['categoria']} · ${m['espacos']} espaço(s)'
                '${'${m['alcance'] ?? ''}'.isEmpty ? '' : ' · alcance ${m['alcance']}'}'
                '${'${m['area'] ?? ''}'.isEmpty ? '' : ' · ${m['area']}'}',
            corpo: [
              if ('${m['dano'] ?? ''}'.isNotEmpty)
                _texto(
                  'Dano ${m['dano']} de ${_tipo('${m['tipo'] ?? ''}')}'
                  '${'${m['resistencia'] ?? ''}'.isEmpty ? '' : ' · ${m['resistencia']}'}',
                  cor: Cores.energiaViva,
                ),
              _texto('${m['efeito']}'),
              if ('${m['uso'] ?? ''}'.isNotEmpty)
                _texto('${m['uso']}', cor: Cores.tinta2),
            ],
            paraFicha: _itemDeAtaqueParaFicha(m),
          ),
      ],
    );
  }

  /// Item com dano vira ataque (granada e mina não rolam ataque: o alvo
  /// resiste); sem dano, só item de inventário.
  Map<String, dynamic> _itemDeAtaqueParaFicha(Map<String, dynamic> m) {
    final nome = '${m['nome']}';
    final dano = '${m['dano'] ?? ''}';
    if (dano.isEmpty) {
      return {
        'nome': nome,
        'categoria': m['categoria'],
        'espacos': m['espacos'],
      };
    }
    final corpo = nome == 'Pé de cabra';
    final disparo = nome == 'Pistola sinalizadora';
    final (margem, mult) = _critico('${m['critico'] ?? ''}');
    return {
      'nome': nome,
      'pericia': corpo ? 'Luta' : 'Pontaria',
      if (!corpo && !disparo) 'semTeste': true,
      'bonus': 0,
      'dano': dano,
      'tipo': _tipo('${m['tipo'] ?? ''}'),
      'margem': margem < 20 ? '$margem' : '',
      'critico': 'x$mult',
      'alcance': '${m['alcance'] ?? ''}'.isEmpty
          ? 'Corpo a corpo'
          : '${m['alcance']}${'${m['area'] ?? ''}'.isEmpty ? '' : ' · ${m['area']}'}',
      'especial': [
        '${m['efeito']}',
        if ('${m['resistencia'] ?? ''}'.isNotEmpty) '${m['resistencia']}.',
        if ('${m['uso'] ?? ''}'.isNotEmpty) '${m['uso']}',
      ].join(' '),
      'familia': corpo || disparo ? 'Armas Simples' : '',
      'uso': corpo
          ? 'Corpo a Corpo – Uma Mão'
          : disparo
          ? 'Armas de Disparo – Leves'
          : '',
      'categoria': m['categoria'],
      'espacos': m['espacos'],
    };
  }

  Widget _listaComponentes() {
    final itens = _lista(
      'componentes',
    ).where((c) => _casa('${c['elemento']}') || _casa('${c['exemplos']}'));
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
      children: [
        const Text(
          'Sem os componentes do elemento, não se conjura ritual dele. Não '
          'existe componente de Medo. Categoria 0, 1 espaço (p. 66).',
          style: TextStyle(fontSize: 12, color: Cores.tinta2),
        ),
        const SizedBox(height: 8),
        for (final c in itens)
          _cartaoSimples(
            titulo: 'Componentes ritualísticos de ${c['elemento']}',
            subtitulo: 'Categoria 0 · 1 espaço',
            corpo: [_texto('Exemplos: ${c['exemplos']}', cor: Cores.tinta2)],
            paraFicha: {
              'nome': 'Componentes ritualísticos de ${c['elemento']}',
              'categoria': '0',
              'espacos': '1',
            },
          ),
      ],
    );
  }

  Widget _listaProtecoes() {
    final protecoes = _protecoes!
        .where((p) => _casa(p['nome'] as String))
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
      children: [
        for (final p in protecoes)
          _cartaoSimples(
            titulo: p['nome'] as String,
            subtitulo:
                'Defesa ${p['defesa']} · categoria ${p['categoria']} · '
                '${p['espacos']} espaço(s)',
            corpo: const [],
          ),
      ],
    );
  }

  Widget _linha(String rotulo, String valor) {
    if (valor.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12.5, color: Cores.tinta2),
          children: [
            TextSpan(
              text: '$rotulo: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  final String texto;

  const _Vazio(this.texto);

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Cores.tinta2),
      ),
    ),
  );
}
