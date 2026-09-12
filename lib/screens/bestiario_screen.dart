import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/ficha_op.dart';
import '../store/ficha_store.dart';
import '../theme.dart';
import '../util/texto.dart';
import '../widgets/retrato.dart';
import 'ficha_screen.dart';

/// O bestiário da campanha: aliados, ameaças, criaturas e figurantes já em
/// ficha, prontos para virar NPC do aparelho.
///
/// O arquivo vem junto com o app (`assets/bestiario/bestiario.json`,
/// gerado por `ferramentas/gerar_bestiario.py`). Importar é copiar para o
/// Hive — daí em diante a ficha é sua e você edita à vontade. O id é fixo
/// (`bestiario-<nome>`), então reimportar ATUALIZA a mesma ficha em vez de
/// encher a lista de repetidos; o preço é que reimportar joga fora o que
/// você tiver mudado nela, e a tela avisa isso antes.
class BestiarioScreen extends StatefulWidget {
  const BestiarioScreen({super.key});

  @override
  State<BestiarioScreen> createState() => _BestiarioScreenState();
}

class _BestiarioScreenState extends State<BestiarioScreen> {
  List<_Grupo>? _grupos;
  String? _erro;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final cru = await rootBundle.loadString('assets/bestiario/bestiario.json');
      final json = jsonDecode(cru) as Map<String, dynamic>;
      setState(() {
        _grupos = [
          for (final g in (json['grupos'] as List))
            _Grupo(
              nome: (g['nome'] ?? '') as String,
              descricao: (g['descricao'] ?? '') as String,
              fichas: [
                for (final f in (g['fichas'] as List))
                  FichaOP((f as Map).cast<String, dynamic>())
              ],
            )
        ];
      });
    } catch (e) {
      setState(() => _erro = '$e');
    }
  }

  List<FichaOP> get _todas =>
      [for (final g in _grupos ?? const <_Grupo>[]) ...g.fichas];

  bool _jaTem(FichaOP f) => FichaStore.porId(f.id) != null;

  Future<void> _importar(List<FichaOP> fichas, {required String oQue}) async {
    final repetidas = fichas.where(_jaTem).length;
    if (repetidas > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(repetidas == 1
              ? 'Essa ficha já está no aparelho'
              : '$repetidas dessas fichas já estão no aparelho'),
          content: const Text(
              'Importar de novo devolve a versão original e descarta o que '
              'você tiver mudado nelas. As outras entram normalmente.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Importar assim mesmo')),
          ],
        ),
      );
      if (ok != true) return;
    }

    for (final f in fichas) {
      await FichaStore.salvar(
          FichaOP(jsonDecode(jsonEncode(f.dados)) as Map<String, dynamic>));
    }
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$oQue: ${fichas.length} ficha(s) no aparelho.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _grupos;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bestiário da campanha'),
        actions: [
          if (grupos != null)
            IconButton(
              tooltip: 'Importar tudo',
              icon: const Icon(Icons.download_for_offline_outlined),
              onPressed: () =>
                  _importar(_todas, oQue: 'Bestiário importado'),
            ),
        ],
      ),
      body: _erro != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Não consegui abrir o bestiário.\n\n$_erro',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Cores.tinta2)),
              ),
            )
          : grupos == null
              ? const Center(child: CircularProgressIndicator())
              : _lista(grupos),
    );
  }

  Widget _lista(List<_Grupo> grupos) {
    final busca = _filtro.trim().toLowerCase();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_todas.length} fichas prontas',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                const Text(
                  'Todas entram como NPC em modo livre: ficam fora da mesa '
                  'online e você edita o que quiser. Ameaça traz o bloco do '
                  'livro — VD, Defesa, PV, resistências, testes, ataques e '
                  'o que cada habilidade faz. O brasão é gerado aqui, não é '
                  'arte oficial.',
                  style: TextStyle(fontSize: 12, color: Cores.tinta2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            isDense: true,
            prefixIcon: Icon(Icons.search, size: 18),
            labelText: 'Procurar por nome ou papel',
          ),
          onChanged: (v) => setState(() => _filtro = v),
        ),
        const SizedBox(height: 8),
        for (final g in grupos)
          _cartaoGrupo(g, [
            for (final f in g.fichas)
              if (busca.isEmpty ||
                  casaBusca(f.nome, busca) ||
                  casaBusca(f.jogador, busca))
                f
          ]),
      ],
    );
  }

  Widget _cartaoGrupo(_Grupo g, List<FichaOP> visiveis) {
    if (visiveis.isEmpty) return const SizedBox.shrink();
    return Card(
      child: ExpansionTile(
        key: ValueKey('${g.nome}-${_filtro.isNotEmpty}'),
        shape: const Border(),
        initiallyExpanded: _filtro.isNotEmpty,
        title: Text(g.nome,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text('${g.fichas.length} fichas · ${g.descricao}',
            style: const TextStyle(fontSize: 12, color: Cores.tinta2)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _importar(g.fichas, oQue: 'Grupo importado'),
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('Importar o grupo'),
              ),
            ),
          ),
          for (final f in visiveis) _linha(f),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _linha(FichaOP f) {
    final tem = _jaTem(f);
    return ListTile(
      dense: true,
      leading: RetratoAvatar(base64: f.retrato, tamanho: 38),
      title: Text(f.nome,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(
        f.vd != null
            ? '${f.jogador} · VD ${f.vd} · PV ${f.pvMax} '
                '(machucado ${f.machucado}) · Defesa ${f.defesa}'
            : '${f.jogador} · ${f.classe} NEX ${f.nex}% · '
                'PV ${f.pvMax} · SAN ${f.sanMax} · Defesa ${f.defesa}',
        style: const TextStyle(fontSize: 11, color: Cores.tinta2),
      ),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => FichaScreen(fichaDireta: f, somenteLeitura: true),
      )),
      trailing: IconButton(
        tooltip: tem ? 'Já está no aparelho — reimportar' : 'Importar',
        icon: Icon(
          tem ? Icons.check_circle : Icons.add_circle_outline,
          color: tem ? Cores.estavel : Cores.energiaViva,
        ),
        onPressed: () => _importar([f], oQue: f.nome),
      ),
    );
  }
}

class _Grupo {
  final String nome;
  final String descricao;
  final List<FichaOP> fichas;

  const _Grupo({
    required this.nome,
    required this.descricao,
    required this.fichas,
  });
}
