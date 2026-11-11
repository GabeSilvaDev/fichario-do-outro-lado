import 'dart:convert';

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/visualizador_imagem.dart';
import '../mesa_service.dart';
import 'pistas_mesa.dart';

/// O acervo de imagens da mesa: tudo que o mestre já guardou, mais recente
/// primeiro. O que está em destaque agora mora em [MuralDaMesa] — aqui é o
/// resto, para reabrir quando quiser.
class GaleriaMesa extends StatefulWidget {
  final MesaService servico;
  final String mesaId;
  final bool souMestre;

  const GaleriaMesa({
    super.key,
    required this.servico,
    required this.mesaId,
    required this.souMestre,
  });

  @override
  State<GaleriaMesa> createState() => _GaleriaMesaState();
}

class _GaleriaMesaState extends State<GaleriaMesa> {
  /// id do item sendo aberto agora, para a célula mostrar o carregando por
  /// cima só da miniatura dela — as outras continuam clicáveis.
  String? _carregando;

  /// Gaveta escolhida no filtro (null = todas, separadas por título).
  CategoriaGaleria? _filtro;

  static const Map<CategoriaGaleria, IconData> _icones = {
    CategoriaGaleria.monstro: Icons.pest_control_outlined,
    CategoriaGaleria.npc: Icons.person_outline,
    CategoriaGaleria.documento: Icons.description_outlined,
    CategoriaGaleria.local: Icons.place_outlined,
    CategoriaGaleria.outro: Icons.image_outlined,
  };

  Future<void> _mudarCategoria(ItemGaleria item) async {
    final nova = await showModalBottomSheet<CategoriaGaleria>(
      context: context,
      backgroundColor: Cores.carta,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                item.legenda.isEmpty
                    ? 'Mover para…'
                    : 'Mover "${item.legenda}" para…',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (final c in CategoriaGaleria.values)
              ListTile(
                key: ValueKey('mover-${c.name}'),
                leading: Icon(_icones[c]),
                title: Text(c.plural),
                trailing: c == item.categoria
                    ? const Icon(Icons.check, color: Cores.energiaViva)
                    : null,
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (nova == null || nova == item.categoria) return;
    try {
      await widget.servico.mudarCategoria(widget.mesaId, item.id, nova);
    } catch (e) {
      _erro(e);
    }
  }

  void _erro(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
  }

  Future<void> _abrir(ItemGaleria item) async {
    setState(() => _carregando = item.id);
    try {
      final cheia = await widget.servico.imagemCheia(widget.mesaId, item.id);
      if (!mounted) return;
      if (cheia == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não consegui carregar a imagem.')),
        );
        return;
      }
      VisualizadorImagem.abrir(context, base64Decode(cheia), item.legenda);
    } catch (e) {
      _erro(e);
    } finally {
      if (mounted) setState(() => _carregando = null);
    }
  }

  Future<void> _mostrarAgora(ItemGaleria item) async {
    try {
      await widget.servico.mostrarAgora(widget.mesaId, item.id);
    } catch (e) {
      _erro(e);
    }
  }

  Future<void> _apagar(ItemGaleria item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar esta imagem?'),
        content: const Text(
          'Ela some da galeria e do mural (se estiver em destaque). Isso '
          'não pode ser desfeito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.servico.apagarDaGaleria(widget.mesaId, item.id);
    } catch (e) {
      _erro(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ItemGaleria>>(
      stream: widget.servico.observarGaleria(widget.mesaId),
      builder: (context, snap) {
        final todas = snap.data ?? const <ItemGaleria>[];
        // Jogador vê só o que já foi mostrado; o resto é surpresa do mestre.
        final itens = widget.souMestre
            ? todas
            : [
                for (final i in todas)
                  if (i.mostrada) i,
              ];
        if (itens.isEmpty) return _vazia();
        final porCategoria = <CategoriaGaleria, List<ItemGaleria>>{
          for (final c in CategoriaGaleria.values)
            c: [
              for (final i in itens)
                if (i.categoria == c) i,
            ],
        }..removeWhere((_, v) => v.isEmpty);
        final filtro = porCategoria.containsKey(_filtro) ? _filtro : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _filtros(itens.length, porCategoria, filtro),
            for (final e in porCategoria.entries)
              if (filtro == null || filtro == e.key) ...[
                if (filtro == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
                    child: Row(
                      children: [
                        Icon(_icones[e.key], size: 16, color: Cores.tinta2),
                        const SizedBox(width: 6),
                        Text(
                          '${e.key.plural} · ${e.value.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Cores.tinta2,
                          ),
                        ),
                      ],
                    ),
                  ),
                _grade(e.value),
              ],
          ],
        );
      },
    );
  }

  Widget _vazia() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          widget.souMestre
              ? 'Nenhuma imagem nesta mesa ainda. Use "Mostrar imagem para a '
                    'mesa" acima.'
              : 'Nenhuma imagem nesta mesa ainda.',
          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _filtros(
    int total,
    Map<CategoriaGaleria, List<ItemGaleria>> porCategoria,
    CategoriaGaleria? filtro,
  ) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              key: const ValueKey('galeria-todas'),
              label: Text('Todas · $total'),
              selected: filtro == null,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => setState(() => _filtro = null),
            ),
          ),
          for (final e in porCategoria.entries)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                key: ValueKey('galeria-${e.key.name}'),
                avatar: Icon(_icones[e.key], size: 16),
                label: Text('${e.key.plural} · ${e.value.length}'),
                selected: filtro == e.key,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                onSelected: (_) =>
                    setState(() => _filtro = filtro == e.key ? null : e.key),
              ),
            ),
        ],
      ),
    );
  }

  Widget _grade(List<ItemGaleria> itens) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itens.length,
      itemBuilder: (_, i) => _celula(itens[i]),
    );
  }

  Widget _celula(ItemGaleria item) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrir(item),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    base64Decode(item.miniaturaBase64),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                  if (_carregando == item.id)
                    const ColoredBox(
                      color: Colors.black38,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                item.legenda,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.souMestre)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final b in [
                    IconButton(
                      tooltip: 'Mostrar agora',
                      icon: const Icon(Icons.present_to_all, size: 18),
                      onPressed: () => _mostrarAgora(item),
                    ),
                    IconButton(
                      key: ValueKey('pista-${item.id}'),
                      tooltip: 'Entregar como pista',
                      icon: const Icon(Icons.key_outlined, size: 18),
                      onPressed: () => entregarComoPista(
                        context,
                        widget.servico,
                        widget.mesaId,
                        item,
                      ),
                    ),
                    IconButton(
                      key: ValueKey('categoria-${item.id}'),
                      tooltip: 'Mudar categoria',
                      icon: Icon(_icones[item.categoria], size: 18),
                      onPressed: () => _mudarCategoria(item),
                    ),
                    IconButton(
                      tooltip: 'Apagar da galeria',
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => _apagar(item),
                    ),
                  ])
                    // Quatro botões numa célula de ~120dp: sem o mínimo de
                    // 48dp do Material, que estourava no celular.
                    IconButtonTheme(
                      data: IconButtonThemeData(
                        style: IconButton.styleFrom(
                          minimumSize: const Size(30, 30),
                          padding: const EdgeInsets.all(4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      child: b,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
