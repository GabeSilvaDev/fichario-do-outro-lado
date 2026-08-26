import 'package:flutter/material.dart';

import '../theme.dart';

/// PV / SAN / PE: barra colorida com − e +, o coração do acompanhamento de
/// sessão. É o que o mestre vê mudar em tempo real no painel dele.
class RecursoContador extends StatelessWidget {
  final String rotulo;
  final int atual;
  final int maximo;
  final Color cor;
  final bool maximoManual;
  final ValueChanged<int>? aoMudar;
  final VoidCallback? aoEditarMaximo;

  const RecursoContador({
    super.key,
    required this.rotulo,
    required this.atual,
    required this.maximo,
    required this.cor,
    this.maximoManual = false,
    this.aoMudar,
    this.aoEditarMaximo,
  });

  @override
  Widget build(BuildContext context) {
    final fracao = maximo <= 0 ? 0.0 : (atual / maximo).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(rotulo,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 12,
                        color: cor)),
                const Spacer(),
                if (aoMudar != null)
                  _botao(context, Icons.remove, () => aoMudar!(atual - 1)),
                GestureDetector(
                  onTap: aoEditarMaximo,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: '$atual',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Cores.tinta)),
                        TextSpan(
                            text: ' / $maximo${maximoManual ? '*' : ''}',
                            style: const TextStyle(
                                fontSize: 13, color: Cores.tinta2)),
                      ]),
                    ),
                  ),
                ),
                if (aoMudar != null)
                  _botao(context, Icons.add, () => aoMudar!(atual + 1)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: fracao,
                minHeight: 6,
                backgroundColor: Cores.fundo,
                valueColor: AlwaysStoppedAnimation(cor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botao(BuildContext context, IconData icone, VoidCallback aoTocar) {
    return InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Cores.linha),
        ),
        child: Icon(icone, size: 18, color: Cores.tinta2),
      ),
    );
  }
}
