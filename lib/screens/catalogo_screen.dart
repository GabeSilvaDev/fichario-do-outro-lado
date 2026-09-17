import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../theme.dart';
import '../util/texto.dart';

/// O catálogo do sistema: os 81 rituais e a tabela de armas e proteções.
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

  /// Só mostra rituais até este círculo (null = todos).
  final int? circuloMaximo;

  /// Rituais já na ficha — ficam de fora da lista.
  final Set<String> nomesExcluidos;

  const CatalogoScreen({
    super.key,
    this.escolhendo = false,
    this.comecarEmArmas = false,
    this.circuloMaximo,
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
    final max = widget.circuloMaximo;
    final lista = _rituais!
        .where(
          (r) =>
              (max == null || (r['circulo'] as int) <= max) &&
              !widget.nomesExcluidos.contains(r['nome']),
        )
        .where(
          (r) =>
              _casa(r['nome'] as String) ||
              _casa(r['elemento'] as String) ||
              _casa(r['efeito'] as String),
        )
        .toList();
    if (lista.isEmpty) return const _Vazio('Nenhum ritual com esse nome.');

    final grupos = <String, List<Map<String, dynamic>>>{};
    for (final r in lista) {
      grupos
          .putIfAbsent('${r['elemento']} · ${r['circulo']}º círculo', () => [])
          .add(r);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
      children: [
        for (final entrada in grupos.entries) ...[
          FaixaSecao(entrada.key),
          for (final r in entrada.value) _cartaoRitual(r),
        ],
      ],
    );
  }

  Widget _cartaoRitual(Map<String, dynamic> r) {
    final ampliacoes = (r['ampliacoes'] as List).cast<Map>();
    return Card(
      child: ExpansionTile(
        key: ValueKey('${r['nome']}-${_filtro.isNotEmpty}'),
        shape: const Border(),
        initiallyExpanded: _filtro.isNotEmpty && _casa(r['nome'] as String),
        title: Text(
          r['nome'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '${r['custo']} PE · ${r['execucao']} · ${r['alcance']}'
          '${(r['alvo'] as String).isEmpty ? '' : ' · ${r['alvo']}'}',
          style: const TextStyle(fontSize: 12, color: Cores.tinta2),
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
                if (widget.escolhendo) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pop(_ritualParaFicha(r)),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Pôr na ficha'),
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
      'circulo': '${r['circulo']}º',
      'custo': '${r['custo']} PE',
      'execucao': r['execucao'],
      'alcance': r['alcance'],
      'duracao': r['duracao'],
      'descricao': [
        if ((r['alvo'] as String).isNotEmpty) 'Alvo: ${r['alvo']}',
        if ((r['resistencia'] as String).isNotEmpty)
          'Resistência: ${r['resistencia']}',
        r['efeito'],
        if (extras.isNotEmpty) extras,
      ].join('\n'),
    };
  }

  Widget _abaArmas() {
    final armas = _armas!
        .where(
          (a) =>
              _casa(a['nome'] as String) ||
              _casa(a['familia'] as String) ||
              _casa(a['uso'] as String),
        )
        .toList();
    final protecoes = _protecoes!
        .where((p) => _casa(p['nome'] as String))
        .toList();
    if (armas.isEmpty && protecoes.isEmpty) {
      return const _Vazio('Nenhuma arma com esse nome.');
    }

    final grupos = <String, List<Map<String, dynamic>>>{};
    for (final a in armas) {
      grupos.putIfAbsent(a['familia'] as String, () => []).add(a);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
      children: [
        for (final entrada in grupos.entries) ...[
          FaixaSecao(entrada.key.isEmpty ? 'Armas' : entrada.key),
          for (final a in entrada.value) _cartaoArma(a),
        ],
        if (protecoes.isNotEmpty) ...[
          const FaixaSecao('Proteções'),
          for (final p in protecoes)
            Card(
              child: ListTile(
                dense: true,
                title: Text(
                  p['nome'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Defesa ${p['defesa']} · categoria ${p['categoria']} · '
                  '${p['espacos']} espaço(s)',
                  style: const TextStyle(fontSize: 12, color: Cores.tinta2),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _cartaoArma(Map<String, dynamic> a) {
    final tipo = _tiposDano[a['tipo']] ?? (a['tipo'] as String);
    final detalhe = [
      if ((a['dano'] as String).isNotEmpty) 'dano ${a['dano']}',
      if (tipo.isNotEmpty) tipo,
      if ((a['critico'] as String).isNotEmpty) 'crítico ${a['critico']}',
      if ((a['alcance'] as String).isNotEmpty) a['alcance'] as String,
      if ((a['espacos'] as String).isNotEmpty) '${a['espacos']} esp.',
      if ((a['categoria'] as String).isNotEmpty) 'cat. ${a['categoria']}',
    ].join(' · ');

    return Card(
      child: ListTile(
        dense: true,
        title: Text(
          a['nome'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${a['uso']}\n$detalhe',
          style: const TextStyle(fontSize: 12, color: Cores.tinta2),
        ),
        isThreeLine: true,
        trailing: widget.escolhendo
            ? IconButton(
                tooltip: 'Pôr na ficha',
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Cores.energiaViva,
                ),
                onPressed: () => Navigator.of(context).pop(_armaParaFicha(a)),
              )
            : null,
      ),
    );
  }

  /// Formato que a ficha guarda em `ataques`. A perícia sai do uso: arma de
  /// fogo e de disparo rolam Pontaria, o resto rola Luta.
  Map<String, dynamic> _armaParaFicha(Map<String, dynamic> a) {
    final uso = (a['uso'] as String).toLowerCase();
    final distancia = uso.contains('fogo') || uso.contains('disparo');
    final critico = a['critico'] as String;
    return {
      'nome': a['nome'],
      'pericia': distancia ? 'Pontaria' : 'Luta',
      'bonus': 0,
      'dano': a['dano'],
      'tipo': _tiposDano[a['tipo']] ?? '',
      'margem': critico.startsWith('1') ? critico : '',
      'critico': critico.startsWith('x') ? critico : '',
      'alcance': (a['alcance'] as String).isEmpty
          ? (distancia ? '' : 'Corpo a corpo')
          : a['alcance'] as String,
      'especial': '',
    };
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
