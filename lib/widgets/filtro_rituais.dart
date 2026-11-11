import 'package:flutter/material.dart';

import '../theme.dart';

/// Como a lista de rituais é separada: por círculo (1º a 4º) ou por
/// elemento (Conhecimento, Energia, Morte, Sangue, Medo).
enum AgrupaRituais { circulo, elemento }

/// Ordem fixa dos elementos na tela.
const List<String> elementosDeRitual = [
  'Conhecimento',
  'Energia',
  'Morte',
  'Sangue',
  'Medo',
];

/// A chave de grupo de um ritual: "1º" … "4º", ou o elemento.
String grupoDoRitual(AgrupaRituais modo, int circulo, String elemento) =>
    modo == AgrupaRituais.circulo
    ? '$circuloº círculo'
    : (elemento.trim().isEmpty ? 'Sem elemento' : elemento);

/// Grupos na ordem da tela, só os que têm ritual.
List<String> gruposEmOrdem(AgrupaRituais modo, Iterable<String> presentes) {
  final set = presentes.toSet();
  final ordem = modo == AgrupaRituais.circulo
      ? [for (var c = 1; c <= 4; c++) '$cº círculo']
      : [...elementosDeRitual, 'Sem elemento'];
  return [
    for (final g in ordem)
      if (set.contains(g)) g,
    for (final g in set)
      if (!ordem.contains(g)) g,
  ];
}

/// Botões Círculo/Elemento e os filtros com contagem. [filtro] null =
/// todos (a lista mostra os grupos com título).
class FiltroRituais extends StatelessWidget {
  final AgrupaRituais modo;
  final String? filtro;

  /// Grupo → quantos rituais.
  final Map<String, int> contagem;
  final ValueChanged<AgrupaRituais> aoMudarModo;
  final ValueChanged<String?> aoFiltrar;

  const FiltroRituais({
    super.key,
    required this.modo,
    required this.filtro,
    required this.contagem,
    required this.aoMudarModo,
    required this.aoFiltrar,
  });

  @override
  Widget build(BuildContext context) {
    final grupos = gruposEmOrdem(modo, contagem.keys);
    final total = contagem.values.fold<int>(0, (s, n) => s + n);
    String curto(String g) => g.replaceAll(' círculo', '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<AgrupaRituais>(
          key: const ValueKey('agrupa-rituais'),
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: const [
            ButtonSegment(
              value: AgrupaRituais.circulo,
              label: Text('Por círculo'),
              icon: Icon(Icons.filter_1, size: 16),
            ),
            ButtonSegment(
              value: AgrupaRituais.elemento,
              label: Text('Por elemento'),
              icon: Icon(Icons.auto_awesome, size: 16),
            ),
          ],
          selected: {modo},
          onSelectionChanged: (s) => aoMudarModo(s.first),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  key: const ValueKey('filtro-ritual-todos'),
                  label: Text('Todos · $total'),
                  selected: filtro == null,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => aoFiltrar(null),
                ),
              ),
              for (final g in grupos)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    key: ValueKey('filtro-ritual-$g'),
                    label: Text('${curto(g)} · ${contagem[g]}'),
                    selected: filtro == g,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => aoFiltrar(filtro == g ? null : g),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Título de grupo dentro da lista (ex.: "2º CÍRCULO · 3").
class TituloGrupoRitual extends StatelessWidget {
  final String texto;
  final int quantos;
  final Color cor;

  const TituloGrupoRitual(
    this.texto,
    this.quantos, {
    super.key,
    this.cor = Cores.conhecimento,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        children: [
          Text(
            '${texto.toUpperCase()} · $quantos',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.6,
              color: cor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: cor.withValues(alpha: .4))),
        ],
      ),
    );
  }
}
