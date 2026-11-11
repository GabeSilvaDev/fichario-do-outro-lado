import 'package:flutter/material.dart';

import '../../theme.dart';
import '../mesa_service.dart';

/// A ordem de turnos na mesa. Os dados são físicos: o mestre anota o
/// resultado de cada um, o app ordena, marca de quem é a vez e conta as
/// rodadas. Todo mundo vê a ordem; o PV das ameaças, só o mestre.

/// A faixa em cima do mapa: rodada, de quem é a vez e quem vem depois.
/// Mestre passa o turno daqui mesmo, sem abrir nada.
class FaixaIniciativa extends StatelessWidget {
  final MesaService servico;
  final String mesaId;
  final bool mestre;
  final Iniciativa? iniciativa;
  final VoidCallback aoAbrir;

  const FaixaIniciativa({
    super.key,
    required this.servico,
    required this.mesaId,
    required this.mestre,
    required this.iniciativa,
    required this.aoAbrir,
  });

  Future<void> _salvar(BuildContext context, Iniciativa nova) async {
    try {
      await servico.salvarIniciativa(mesaId, nova);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = iniciativa;
    if (i == null || i.ordem.isEmpty) return const SizedBox.shrink();
    if (!i.comecou && !mestre) return const SizedBox.shrink();
    final atual = i.atual;
    final proximo = i.proximo;
    return Material(
      color: Cores.carta,
      child: InkWell(
        key: const ValueKey('faixa-iniciativa'),
        onTap: aoAbrir,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          child: Row(
            children: [
              const Icon(Icons.swap_vert, size: 18, color: Cores.conhecimento),
              const SizedBox(width: 8),
              Expanded(
                child: !i.comecou
                    ? const Text(
                        'Iniciativa montada · toque para conferir e começar',
                        style: TextStyle(fontSize: 13),
                      )
                    : Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Rodada ${i.rodada} · ',
                              style: const TextStyle(color: Cores.tinta2),
                            ),
                            const TextSpan(text: 'Vez de '),
                            TextSpan(
                              text: atual?.nome ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: atual?.inimigo == true
                                    ? Cores.sangue
                                    : Cores.energiaViva,
                              ),
                            ),
                            if (proximo != null)
                              TextSpan(
                                text: ' · depois ${proximo.nome}',
                                style: const TextStyle(color: Cores.tinta2),
                              ),
                          ],
                        ),
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              if (mestre && i.comecou) ...[
                IconButton(
                  tooltip: 'Turno anterior',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _salvar(context, i.vezAnterior()),
                ),
                IconButton(
                  key: const ValueKey('proximo-turno'),
                  tooltip: 'Próximo turno',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _salvar(context, i.proximaVez()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Jogador: a ordem inteira, só leitura.
void verOrdem(BuildContext context, Iniciativa i) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Cores.carta,
    builder: (_) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Iniciativa · rodada ${i.rodada}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          for (var k = 0; k < i.ordem.length; k++)
            ListTile(
              dense: true,
              selected: k == i.vez,
              leading: Text(
                '${i.ordem[k].valor}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              title: Text(i.ordem[k].nome),
              trailing: k == i.vez ? const Icon(Icons.play_arrow) : null,
            ),
        ],
      ),
    ),
  );
}

/// Mestre: monta a ordem a partir das peças do mapa, anota o valor de cada
/// um, passa os turnos e acompanha o PV das ameaças.
class PainelIniciativa extends StatelessWidget {
  final MesaService servico;
  final String mesaId;

  /// As peças do mapa aberto — de onde vem a lista.
  final List<TokenMapa> pecas;

  const PainelIniciativa({
    super.key,
    required this.servico,
    required this.mesaId,
    required this.pecas,
  });

  static Future<void> abrir(
    BuildContext context,
    MesaService servico,
    String mesaId,
    List<TokenMapa> pecas,
  ) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Cores.carta,
    isScrollControlled: true,
    builder: (_) =>
        PainelIniciativa(servico: servico, mesaId: mesaId, pecas: pecas),
  );

  Future<void> _salvar(BuildContext context, Iniciativa? nova) async {
    try {
      await servico.salvarIniciativa(mesaId, nova);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _salvarPv(
    BuildContext context,
    Map<String, PvDeCombate> pv,
  ) async {
    try {
      await servico.salvarPvDeCombate(mesaId, pv);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  /// Quem está no mapa e ainda não está na lista entra com valor 0.
  Iniciativa _puxar(Iniciativa i) {
    var nova = i;
    for (final p in pecas) {
      if (nova.ordem.any((e) => e.id == p.id)) continue;
      nova = nova.com(
        EntradaIniciativa(id: p.id, nome: p.nome, valor: 0, inimigo: p.inimigo),
      );
    }
    return nova;
  }

  Future<int?> _pedirNumero(
    BuildContext context,
    String titulo, {
    int? inicial,
    String dica = '',
  }) {
    final campo = TextEditingController(
      text: inicial == null || inicial == 0 ? '' : '$inicial',
    );
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          key: const ValueKey('numero'),
          controller: campo,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: InputDecoration(hintText: dica),
          onSubmitted: (t) => Navigator.pop(ctx, int.tryParse(t.trim())),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const ValueKey('ok-numero'),
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(campo.text.trim())),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Iniciativa?>(
      stream: servico.observarIniciativa(mesaId),
      builder: (context, snap) {
        final i = snap.data ?? const Iniciativa();
        return StreamBuilder<Map<String, PvDeCombate>>(
          stream: servico.observarPvDeCombate(mesaId),
          builder: (context, snapPv) {
            final pv = snapPv.data ?? const <String, PvDeCombate>{};
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          i.comecou
                              ? 'Iniciativa · rodada ${i.rodada}'
                              : 'Iniciativa',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        key: const ValueKey('puxar-pecas'),
                        onPressed: () => _salvar(context, _puxar(i)),
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Puxar do mapa'),
                      ),
                    ],
                  ),
                  const Text(
                    'Role os dados na mesa e toque no número de cada um para '
                    'anotar. A lista se ordena sozinha. O PV das ameaças só '
                    'você vê.',
                    style: TextStyle(fontSize: 12, color: Cores.tinta2),
                  ),
                  const SizedBox(height: 8),
                  if (i.ordem.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Lista vazia. "Puxar do mapa" traz todas as peças.',
                        style: TextStyle(fontSize: 13, color: Cores.tinta2),
                      ),
                    ),
                  for (var k = 0; k < i.ordem.length; k++)
                    _linha(context, i, k, pv),
                  const SizedBox(height: 12),
                  if (i.ordem.isNotEmpty)
                    Row(
                      children: [
                        if (!i.comecou)
                          Expanded(
                            child: FilledButton.icon(
                              key: const ValueKey('comecar-combate'),
                              onPressed: () => _salvar(context, i.comecar()),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Começar'),
                            ),
                          )
                        else ...[
                          OutlinedButton(
                            onPressed: () => _salvar(context, i.vezAnterior()),
                            child: const Icon(Icons.chevron_left),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _salvar(context, i.proximaVez()),
                              icon: const Icon(Icons.chevron_right),
                              label: const Text('Próximo turno'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 4),
                  if (i.ordem.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const ValueKey('encerrar-combate'),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Encerrar o combate?'),
                              content: const Text(
                                'A ordem e o PV das ameaças somem. As peças '
                                'continuam no mapa.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Encerrar'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true && context.mounted) {
                            await _salvar(context, null);
                          }
                        },
                        icon: const Icon(
                          Icons.stop_circle_outlined,
                          size: 18,
                          color: Cores.sangue,
                        ),
                        label: const Text(
                          'Encerrar combate',
                          style: TextStyle(color: Cores.sangue),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _linha(
    BuildContext context,
    Iniciativa i,
    int k,
    Map<String, PvDeCombate> pv,
  ) {
    final e = i.ordem[k];
    final vez = i.comecou && k == i.vez;
    final vida = pv[e.id];
    final caiu = vida?.caiu ?? false;
    return Container(
      key: ValueKey('ini-${e.id}'),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: vez ? Cores.energiaViva : Cores.linha,
          width: vez ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            key: ValueKey('valor-${e.id}'),
            onTap: () async {
              final n = await _pedirNumero(
                context,
                'Iniciativa de ${e.nome}',
                inicial: e.valor,
                dica: 'Resultado do dado',
              );
              if (n == null || !context.mounted) return;
              await _salvar(context, i.com(e.comValor(n)).ordenada());
            },
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Text(
                e.valor == 0 ? '—' : '${e.valor}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: e.valor == 0 ? Cores.tinta2 : Cores.tinta,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              e.nome,
              style: TextStyle(
                color: e.inimigo ? Cores.sangue : Cores.tinta,
                fontWeight: vez ? FontWeight.bold : FontWeight.normal,
                decoration: caiu ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (e.inimigo) ...[
            IconButton(
              tooltip: '−1 PV',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove, size: 16),
              onPressed: vida == null
                  ? null
                  : () => _salvarPv(context, {...pv, e.id: vida.somar(-1)}),
            ),
            InkWell(
              key: ValueKey('pv-${e.id}'),
              onTap: () => _editarPv(context, e, pv),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  vida == null ? 'PV ?' : '${vida.atual}/${vida.maximo}',
                  style: TextStyle(
                    fontSize: 13,
                    color: caiu ? Cores.sangue : Cores.tinta2,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: '+1 PV',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add, size: 16),
              onPressed: vida == null
                  ? null
                  : () => _salvarPv(context, {...pv, e.id: vida.somar(1)}),
            ),
          ],
          IconButton(
            tooltip: 'Tirar da ordem',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => _salvar(context, i.sem(e.id)),
          ),
        ],
      ),
    );
  }

  /// Toque no PV: sem PV ainda, pede o máximo; com PV, pede o dano
  /// (positivo tira, negativo cura).
  Future<void> _editarPv(
    BuildContext context,
    EntradaIniciativa e,
    Map<String, PvDeCombate> pv,
  ) async {
    final vida = pv[e.id];
    if (vida == null) {
      final max = await _pedirNumero(
        context,
        'PV de ${e.nome}',
        dica: 'PV máximo da ficha',
      );
      if (max == null || max <= 0 || !context.mounted) return;
      await _salvarPv(context, {...pv, e.id: PvDeCombate(max, max)});
      return;
    }
    final dano = await _pedirNumero(
      context,
      'Dano em ${e.nome} (${vida.atual}/${vida.maximo})',
      dica: 'Ex.: 7 tira 7 · -5 cura 5',
    );
    if (dano == null || !context.mounted) return;
    await _salvarPv(context, {...pv, e.id: vida.somar(-dano)});
  }
}
