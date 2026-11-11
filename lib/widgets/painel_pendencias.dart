import 'package:flutter/material.dart';

import '../regras/pendencias.dart';
import '../theme.dart';

/// O que a ficha precisa resolver, no topo da aba Geral. Tocar numa linha
/// leva à aba onde ela se resolve.
class PainelPendencias extends StatelessWidget {
  final List<Pendencia> pendencias;
  final ValueChanged<String>? aoIrPara;

  /// "Ignorar": esconde o painel até surgir uma pendência nova. O ícone da
  /// barra continua lá para abrir de novo.
  final VoidCallback? aoIgnorar;

  /// Painel aberto pelo ícone com as pendências já ignoradas: o botão vira
  /// "Voltar a mostrar", que desfaz o Ignorar.
  final bool ignoradas;
  final VoidCallback? aoReativar;

  const PainelPendencias({
    super.key,
    required this.pendencias,
    this.aoIrPara,
    this.aoIgnorar,
    this.ignoradas = false,
    this.aoReativar,
  });

  static Color cor(Gravidade g) => switch (g) {
    Gravidade.erro => Cores.sangue,
    Gravidade.aviso => Cores.conhecimento,
    Gravidade.info => Cores.tinta2,
  };

  static IconData icone(Gravidade g) => switch (g) {
    Gravidade.erro => Icons.error_outline,
    Gravidade.aviso => Icons.warning_amber_outlined,
    Gravidade.info => Icons.info_outline,
  };

  @override
  Widget build(BuildContext context) {
    if (pendencias.isEmpty) return const SizedBox.shrink();
    final erros = pendencias.where((p) => p.gravidade == Gravidade.erro).length;
    final avisos = pendencias
        .where((p) => p.gravidade == Gravidade.aviso)
        .length;
    final corTitulo = erros > 0
        ? Cores.sangue
        : avisos > 0
        ? Cores.conhecimento
        : Cores.tinta2;
    final ordenadas = [...pendencias]
      ..sort((a, b) => a.gravidade.index.compareTo(b.gravidade.index));
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: corTitulo.withValues(alpha: .6)),
      ),
      child: ExpansionTile(
        shape: const Border(),
        initiallyExpanded: erros + avisos > 0,
        leading: Icon(
          icone(
            erros > 0
                ? Gravidade.erro
                : avisos > 0
                ? Gravidade.aviso
                : Gravidade.info,
          ),
          color: corTitulo,
        ),
        title: Text(
          [
            if (erros > 0) '$erros fora da regra',
            if (avisos > 0) '$avisos para resolver',
            if (erros + avisos == 0) 'Observações',
          ].join(' · '),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: corTitulo,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        children: [
          for (final p in ordenadas)
            InkWell(
              onTap: aoIrPara == null ? null : () => aoIrPara!(p.aba),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icone(p.gravidade), size: 16, color: cor(p.gravidade)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.texto,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (ignoradas && aoReativar != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const ValueKey('reativar-pendencias'),
                onPressed: aoReativar,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Voltar a mostrar'),
                style: TextButton.styleFrom(foregroundColor: Cores.tinta2),
              ),
            )
          else if (aoIgnorar != null && erros + avisos > 0)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const ValueKey('ignorar-pendencias'),
                onPressed: aoIgnorar,
                icon: const Icon(Icons.visibility_off_outlined, size: 18),
                label: const Text('Ignorar'),
                style: TextButton.styleFrom(foregroundColor: Cores.tinta2),
              ),
            ),
        ],
      ),
    );
  }
}
