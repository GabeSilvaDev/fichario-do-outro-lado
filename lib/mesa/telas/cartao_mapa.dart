import 'package:flutter/material.dart';

import '../../theme.dart';
import '../mesa_service.dart';
import 'mapa_da_cena.dart';

/// A porta do mapa da cena dentro da aba Mesa.
///
/// Só isso: dizer o que está na mesa e abrir a tela. Subir planta, escolher
/// qual está em jogo, pôr peça e mudar tamanho é tudo lá dentro
/// ([MapaDaCena]) — aqui virava um segundo painel concorrendo com o mesmo
/// trabalho.
class CartaoMapa extends StatelessWidget {
  final MesaService servico;
  final String mesaId;
  final bool souMestre;

  const CartaoMapa({
    super.key,
    required this.servico,
    required this.mesaId,
    required this.souMestre,
  });

  void _abrir(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MapaDaCena(
        servico: servico,
        mesaId: mesaId,
        mestre: souMestre,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MapaMesa?>(
      stream: servico.observarMapa(mesaId),
      builder: (context, snap) {
        final mapa = snap.data;
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _abrir(context),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    mapa == null ? Icons.map_outlined : Icons.map,
                    color: mapa == null ? Cores.tinta2 : Cores.energiaViva,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mapa == null
                              ? 'Nenhum mapa na mesa'
                              : (mapa.titulo.isEmpty
                                  ? 'Mapa da cena'
                                  : mapa.titulo),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mapa == null
                              ? (souMestre
                                  ? 'Abra para subir a planta do lugar e pôr '
                                      'as peças.'
                                  : 'Quando o mestre puser um, aparece aqui.')
                              : '${mapa.tokens.length} peça(s) · atualiza ao '
                                  'vivo enquanto o mestre move',
                          style: const TextStyle(
                              fontSize: 12, color: Cores.tinta2),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Cores.tinta2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
