import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/visualizador_imagem.dart';
import '../mesa_service.dart';
import '../modelos.dart';

/// Pistas: imagem da galeria entregue só a quem o mestre escolhe. Quem
/// recebe pode repassar a outro jogador, direto — como passar um papel por
/// baixo da mesa. O mestre vê todas e quem está com cada uma.

/// Nome de quem tem o uid, ou um aviso se a pessoa saiu da mesa.
String _nomeDe(String uid, List<Membro> membros) {
  for (final m in membros) {
    if (m.uid == uid) return m.nome.isEmpty ? 'Sem nome' : m.nome;
  }
  return 'alguém que saiu';
}

/// Escolhe jogadores (o mestre não entra: ele vê tudo). [ja] vem marcado;
/// [travados] aparecem marcados e não desmarcam (repasse só acrescenta).
Future<List<String>?> _escolherJogadores(
  BuildContext context, {
  required String titulo,
  required String botao,
  required List<Membro> jogadores,
  Set<String> ja = const {},
  Set<String> travados = const {},
}) {
  final marcados = {...ja, ...travados};
  return showDialog<List<String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, refazer) => AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: 320,
          child: jogadores.isEmpty
              ? const Text(
                  'Nenhum jogador na mesa agora.',
                  style: TextStyle(color: Cores.tinta2),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final j in jogadores)
                      CheckboxListTile(
                        key: ValueKey('jogador-${j.uid}'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: marcados.contains(j.uid),
                        title: Text(j.nome.isEmpty ? 'Sem nome' : j.nome),
                        subtitle: travados.contains(j.uid)
                            ? const Text(
                                'já tem',
                                style: TextStyle(fontSize: 11),
                              )
                            : null,
                        onChanged: travados.contains(j.uid)
                            ? null
                            : (v) => refazer(() {
                                if (v == true) {
                                  marcados.add(j.uid);
                                } else {
                                  marcados.remove(j.uid);
                                }
                              }),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const ValueKey('confirmar-jogadores'),
            onPressed: () => Navigator.pop(ctx, marcados.toList()),
            child: Text(botao),
          ),
        ],
      ),
    ),
  );
}

Future<List<Membro>> _jogadores(MesaService servico, String mesaId) async {
  final membros = await servico
      .observarMembros(mesaId)
      .first
      .timeout(const Duration(seconds: 8), onTimeout: () => const []);
  return [
    for (final m in membros)
      if (m.papel == PapelMesa.jogador) m,
  ];
}

/// Mestre, na galeria: entrega a imagem como pista a quem ele escolher.
Future<void> entregarComoPista(
  BuildContext context,
  MesaService servico,
  String mesaId,
  ItemGaleria item,
) async {
  final jogadores = await _jogadores(servico, mesaId);
  if (!context.mounted) return;
  final uids = await _escolherJogadores(
    context,
    titulo: 'Entregar "${item.legenda}" a…',
    botao: 'Entregar',
    jogadores: jogadores,
  );
  if (uids == null || uids.isEmpty || !context.mounted) return;
  final mensageiro = ScaffoldMessenger.of(context);
  try {
    await servico.entregarPista(mesaId, item, uids);
    mensageiro.showSnackBar(
      SnackBar(
        content: Text(
          'Pista entregue a ${[for (final u in uids) _nomeDe(u, jogadores)].join(', ')}.',
        ),
      ),
    );
  } catch (e) {
    mensageiro.showSnackBar(SnackBar(content: Text('$e')));
  }
}

/// Abre a imagem cheia da pista. Logo depois da entrega a imagem pode
/// ainda estar subindo: tenta de novo uma vez.
Future<void> abrirPista(
  BuildContext context,
  MesaService servico,
  String mesaId,
  Pista pista, {
  String prefixo = '',
}) async {
  var b64 = await servico.imagemDaPista(mesaId, pista.id);
  if (b64 == null) {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    b64 = await servico.imagemDaPista(mesaId, pista.id);
  }
  if (!context.mounted) return;
  if (b64 == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não consegui abrir a pista.')),
    );
    return;
  }
  VisualizadorImagem.abrir(
    context,
    base64Decode(b64),
    '$prefixo${pista.legenda}',
  );
}

/// A seção "Pistas" da aba Mesa. Mestre: todas, com quem tem cada uma.
/// Jogador: as dele, com o botão de repassar.
class PistasDaMesa extends StatelessWidget {
  final MesaService servico;
  final String mesaId;
  final bool souMestre;

  const PistasDaMesa({
    super.key,
    required this.servico,
    required this.mesaId,
    required this.souMestre,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Membro>>(
      stream: servico.observarMembros(mesaId),
      builder: (context, snapMembros) {
        final membros = snapMembros.data ?? const <Membro>[];
        return StreamBuilder<List<Pista>>(
          stream: servico.observarPistas(mesaId, mestre: souMestre),
          builder: (context, snap) {
            final pistas = snap.data ?? const <Pista>[];
            if (pistas.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    souMestre
                        ? 'Nenhuma pista entregue. Na galeria, toque na chave '
                              'de uma imagem para entregar só a quem você '
                              'escolher.'
                        : 'Nenhuma pista com você ainda. Quando o mestre (ou '
                              'outro jogador) te passar uma, ela abre na tela '
                              'e fica guardada aqui.',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: [for (final p in pistas) _cartao(context, p, membros)],
            );
          },
        );
      },
    );
  }

  Widget _cartao(BuildContext context, Pista p, List<Membro> membros) {
    final eu = servico.uid;
    final com = [
      for (final u in p.veem)
        if (u != eu) _nomeDe(u, membros),
    ];
    final quem = souMestre
        ? (com.isEmpty ? 'Com ninguém' : 'Com: ${com.join(', ')}')
        : (com.isEmpty ? 'Só com você' : 'Também com: ${com.join(', ')}');
    return Card(
      key: ValueKey('pista-${p.id}'),
      child: InkWell(
        onTap: () => abrirPista(context, servico, mesaId, p),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: p.miniaturaBase64.isEmpty
                    ? const SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(Icons.description_outlined),
                      )
                    : Image.memory(
                        base64Decode(p.miniaturaBase64),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.legenda.isEmpty ? 'Pista' : p.legenda,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      quem,
                      style: const TextStyle(fontSize: 12, color: Cores.tinta2),
                    ),
                    if (p.repasses.isNotEmpty)
                      Text(
                        [
                          for (final r in p.repasses)
                            '${r.deNome} → ${r.paraNome}',
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Cores.tinta2,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              if (souMestre) ...[
                IconButton(
                  key: ValueKey('quem-ve-${p.id}'),
                  tooltip: 'Quem vê',
                  icon: const Icon(Icons.group_outlined, size: 20),
                  onPressed: () => _mudarQuemVe(context, p),
                ),
                IconButton(
                  tooltip: 'Apagar pista',
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _apagar(context, p),
                ),
              ] else
                IconButton(
                  key: ValueKey('repassar-${p.id}'),
                  tooltip: 'Repassar',
                  icon: const Icon(Icons.forward_to_inbox_outlined, size: 20),
                  onPressed: () => _repassar(context, p, membros),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mudarQuemVe(BuildContext context, Pista p) async {
    final jogadores = await _jogadores(servico, mesaId);
    if (!context.mounted) return;
    final uids = await _escolherJogadores(
      context,
      titulo: 'Quem vê "${p.legenda}"',
      botao: 'Salvar',
      jogadores: jogadores,
      ja: p.veem.toSet(),
    );
    if (uids == null || !context.mounted) return;
    // Quem saiu da mesa não aparece na lista, mas continua com a pista.
    final foraDaMesa = [
      for (final u in p.veem)
        if (!jogadores.any((j) => j.uid == u)) u,
    ];
    try {
      await servico.mudarQuemVe(mesaId, p.id, [...uids, ...foraDaMesa]);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _apagar(BuildContext context, Pista p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar esta pista?'),
        content: const Text(
          'Ela some do aparelho de todo mundo que tem. A imagem continua na '
          'galeria.',
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
      await servico.apagarPista(mesaId, p.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _repassar(
    BuildContext context,
    Pista p,
    List<Membro> membros,
  ) async {
    final eu = servico.uid ?? '';
    final jogadores = [
      for (final m in membros)
        if (m.papel == PapelMesa.jogador && m.uid != eu) m,
    ];
    final novos = await _escolherJogadores(
      context,
      titulo: 'Repassar "${p.legenda}" a…',
      botao: 'Repassar',
      jogadores: jogadores,
      travados: {
        for (final u in p.veem)
          if (u != eu) u,
      },
    );
    if (novos == null || !context.mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    final meuNome = _nomeDe(eu, membros);
    final enviados = <String>[];
    try {
      for (final u in novos) {
        if (p.veem.contains(u)) continue;
        final nome = _nomeDe(u, membros);
        await servico.repassarPista(
          mesaId,
          p.id,
          RepasseDePista(
            deUid: eu,
            deNome: meuNome,
            paraUid: u,
            paraNome: nome,
            em: DateTime.now(),
          ),
        );
        enviados.add(nome);
      }
      if (enviados.isNotEmpty) {
        mensageiro.showSnackBar(
          SnackBar(content: Text('Pista repassada a ${enviados.join(', ')}.')),
        );
      }
    } catch (e) {
      mensageiro.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

/// Abre na tela do jogador a pista que acabou de chegar — do mestre ou de
/// outro jogador. As que já estavam com ele quando o app abriu não pulam.
class OuvintePistas extends StatefulWidget {
  final MesaService servico;
  final String mesaId;
  final bool mestre;
  final Widget child;

  const OuvintePistas({
    super.key,
    required this.servico,
    required this.mesaId,
    required this.mestre,
    required this.child,
  });

  @override
  State<OuvintePistas> createState() => _OuvintePistasState();
}

class _OuvintePistasState extends State<OuvintePistas> {
  StreamSubscription<List<Pista>>? _assinatura;
  Set<String>? _conhecidas;

  @override
  void initState() {
    super.initState();
    if (!widget.mestre) _assinar();
  }

  Future<void> _assinar() async {
    try {
      await widget.servico.entrarAnonimo();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    _assinatura = widget.servico
        .observarPistas(widget.mesaId, mestre: false)
        .listen(_aoMudar, onError: (_) {});
  }

  void _aoMudar(List<Pista> pistas) {
    final ids = {for (final p in pistas) p.id};
    final antes = _conhecidas;
    _conhecidas = ids;
    if (antes == null || !mounted) return;
    for (final p in pistas) {
      if (!antes.contains(p.id)) {
        abrirPista(
          context,
          widget.servico,
          widget.mesaId,
          p,
          prefixo: 'Pista nova: ',
        );
        break; // uma por vez: duas de uma vez ficam na seção Pistas
      }
    }
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
