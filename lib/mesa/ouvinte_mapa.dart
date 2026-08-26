import 'dart:async';

import 'package:flutter/material.dart';

import 'mesa_service.dart';
import 'telas/mapa_da_cena.dart';

/// Abre o mapa da cena no aparelho de todo mundo quando o mestre põe um.
///
/// Só na TROCA de imagem: mover uma peça reescreve o documento a cada 120 ms,
/// e um mapa que se reabre a cada arrasto seria insuportável. Quem fechar o
/// mapa volta a ele pelo cartão da aba Mesa.
class OuvinteMapa extends StatefulWidget {
  final MesaService servico;
  final String mesaId;
  final bool mestre;
  final Widget child;

  const OuvinteMapa({
    super.key,
    required this.servico,
    required this.mesaId,
    required this.mestre,
    required this.child,
  });

  @override
  State<OuvinteMapa> createState() => _OuvinteMapaState();
}

class _OuvinteMapaState extends State<OuvinteMapa> {
  StreamSubscription<MapaMesa?>? _assinatura;

  /// A imagem que este aparelho já abriu. Na primeira emissão ela é gravada
  /// sem abrir nada: entrar na mesa com um mapa velho na tela não é novidade
  /// que justifique tomar a tela de ninguém.
  String? _jaVisto;

  @override
  void initState() {
    super.initState();
    _assinar();
  }

  Future<void> _assinar() async {
    try {
      await widget.servico.entrarAnonimo();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    _assinatura = widget.servico.observarMapa(widget.mesaId).listen(
      (mapa) {
        final id = mapa?.imagemId ?? '';
        final primeira = _jaVisto == null;
        if (id == _jaVisto) return;
        _jaVisto = id;
        if (primeira || id.isEmpty || !mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MapaDaCena(
            servico: widget.servico,
            mesaId: widget.mesaId,
            mestre: widget.mestre,
          ),
        ));
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
