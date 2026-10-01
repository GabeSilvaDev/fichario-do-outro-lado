import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../widgets/visualizador_imagem.dart';
import 'mesa_service.dart';
import 'mesa_store.dart';

/// Abre em tela cheia a imagem que o mestre põe no mural.
///
/// Envolve a tela principal enquanto o aparelho está numa mesa. Fora de mesa
/// ninguém constrói este widget, então nada é assinado.
class OuvinteMural extends StatefulWidget {
  final MesaService servico;
  final String mesaId;
  final Widget child;

  const OuvinteMural({
    super.key,
    required this.servico,
    required this.mesaId,
    required this.child,
  });

  @override
  State<OuvinteMural> createState() => _OuvinteMuralState();
}

class _OuvinteMuralState extends State<OuvinteMural> {
  StreamSubscription<ItemMural?>? _assinatura;
  Timer? _novaTentativa;

  /// Quando a imagem que já está aberta foi posta. Sem isso a tela reabre a
  /// cada emissão do stream, inclusive na primeira, que só repete o que já
  /// estava lá.
  DateTime? _ultimoAberto;

  @override
  void initState() {
    super.initState();
    _ultimoAberto = _visto();
    _assinar();
  }

  DateTime? _visto() {
    try {
      return MesaStore.muralVisto(widget.mesaId);
    } catch (_) {
      return null; // Hive fechado (testes): segue só em memória.
    }
  }

  /// O login vem antes de observar: o app pode ter aberto já dentro da mesa,
  /// e aí o Firebase sequer foi inicializado. Sem internet o mural
  /// simplesmente não aparece — o resto do app continua igual.
  Future<void> _assinar() async {
    try {
      await widget.servico.entrarAnonimo();
    } catch (_) {
      // Sem rede agora: tenta de novo, senão a imagem nunca chegaria.
      _novaTentativa = Timer(const Duration(seconds: 30), () {
        if (mounted) _assinar();
      });
      return;
    }
    if (!mounted) return;
    _assinatura = widget.servico.observarMural(widget.mesaId).listen(
          _aoMudar,
          onError: (_) {},
        );
  }

  @override
  void dispose() {
    _novaTentativa?.cancel();
    _assinatura?.cancel();
    super.dispose();
  }

  void _aoMudar(ItemMural? item) {
    if (item == null || item.imagemId.isEmpty) return;
    if (_ultimoAberto != null && !item.em.isAfter(_ultimoAberto!)) return;
    // Marca antes de buscar a imagem: o Firestore costuma emitir o mesmo
    // mural duas vezes (escrita local e confirmação do servidor), e as duas
    // chegavam aqui antes da busca terminar — a imagem abria duas vezes.
    _ultimoAberto = item.em;
    _abrir(item);
  }

  Future<void> _abrir(ItemMural item) async {
    final imagem =
        await widget.servico.imagemCheia(widget.mesaId, item.imagemId);
    if (imagem == null || !mounted) return;

    try {
      MesaStore.marcarMuralVisto(widget.mesaId, item.em);
    } catch (_) {}

    VisualizadorImagem.abrir(context, base64Decode(imagem), item.legenda);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
