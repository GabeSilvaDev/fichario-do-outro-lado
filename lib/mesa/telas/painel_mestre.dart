import 'package:flutter/material.dart';

import '../../models/ficha_op.dart';
import '../../screens/ficha_screen.dart';
import '../../theme.dart';
import '../../widgets/retrato.dart';
import '../mesa_service.dart';

/// O painel do mestre: as fichas publicadas E as rolagens, ao vivo.
///
/// Só leitura, sempre. A ficha é do jogador; aqui é a janela para ela.
class PainelMestre extends StatelessWidget {
  final MesaService servico;
  final String mesaId;

  const PainelMestre({super.key, required this.servico, required this.mesaId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FaixaSecao('Fichas da sessão'),
        _fichas(),
        const FaixaSecao('Últimos testes'),
        _rolagens(),
      ],
    );
  }

  Widget _fichas() {
    return StreamBuilder<List<FichaNaMesa>>(
      stream: servico.observarFichas(mesaId),
      builder: (context, snap) {
        final fichas = snap.data ?? const <FichaNaMesa>[];
        if (fichas.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Ninguém publicou ficha nesta mesa ainda. Peça para o '
                'pessoal entrar e publicar na aba Mesa.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          );
        }
        final ordenadas = [...fichas]..sort(
            (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
        return Column(
          children: [for (final f in ordenadas) _cartao(context, f)],
        );
      },
    );
  }

  Widget _cartao(BuildContext context, FichaNaMesa naMesa) {
    final ficha = FichaOP(Map<String, dynamic>.from(naMesa.ficha));
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              FichaScreen(fichaDireta: ficha, somenteLeitura: true),
        )),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RetratoAvatar(base64: ficha.retrato, tamanho: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                              naMesa.nome.isEmpty ? 'Sem nome' : naMesa.nome,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        if (ficha.emCombate) _selo('COMBATE', Cores.conhecimento),
                        if (ficha.morto) _selo('MORTO', Cores.sangue),
                      ],
                    ),
                    Text(
                      '${ficha.classe} · NEX ${ficha.nex}% · '
                      'Defesa ${ficha.defesa}',
                      style: const TextStyle(
                          fontSize: 12, color: Cores.tinta2),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        ficha.oculto('pv')
                            ? _pilulaOculta('PV')
                            : _pilula('PV', ficha.pv, ficha.pvMax, Cores.sangue),
                        ficha.oculto('san')
                            ? _pilulaOculta('SAN')
                            : _pilula(
                                'SAN', ficha.san, ficha.sanMax, Cores.energia),
                        ficha.oculto('pe')
                            ? _pilulaOculta('PE')
                            : _pilula('PE', ficha.pe, ficha.peMax,
                                Cores.conhecimento),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'atualizada ${_desde(naMesa.atualizadaEm)}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Cores.tinta2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selo(String texto, Color cor) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: .18),
        border: Border.all(color: cor),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(texto,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: cor)),
    );
  }

  /// O jogador escondeu este recurso. Mostrar "0/0" seria pior que não
  /// mostrar nada: o mestre acharia que ele está morrendo.
  Widget _pilulaOculta(String rotulo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Cores.linha),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_off_outlined,
              size: 12, color: Cores.tinta2),
          const SizedBox(width: 4),
          Text(rotulo,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Cores.tinta2)),
        ],
      ),
    );
  }

  Widget _pilula(String rotulo, int atual, int maximo, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: cor.withValues(alpha: .6)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$rotulo $atual/$maximo',
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: cor),
      ),
    );
  }

  Widget _rolagens() {
    return StreamBuilder<List<RolagemNaMesa>>(
      stream: servico.observarRolagens(mesaId),
      builder: (context, snap) {
        final rolagens = snap.data ?? const <RolagemNaMesa>[];
        if (rolagens.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Nenhum teste ainda. Toda rolagem que um jogador fizer na '
                'ficha aparece aqui na hora.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          );
        }
        return Card(
          child: Column(
            children: [
              for (final r in rolagens.take(15)) _linhaRolagem(r),
            ],
          ),
        );
      },
    );
  }

  Widget _linhaRolagem(RolagemNaMesa r) {
    final cor = r.critico
        ? Cores.estavel
        : r.desastre
            ? Cores.sangue
            : Cores.tinta;
    return ListTile(
      dense: true,
      title: Text('${r.porNome} · ${r.titulo}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text('${r.formula}  ${r.detalhe}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontFamily: 'monospace', fontSize: 11, color: Cores.tinta2)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${r.total}',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: cor)),
          Text(_desde(r.em),
              style: const TextStyle(fontSize: 10, color: Cores.tinta2)),
        ],
      ),
    );
  }

  static String _desde(DateTime quando) {
    final s = DateTime.now().difference(quando).inSeconds;
    if (s < 60) return 'agora';
    if (s < 3600) return 'há ${s ~/ 60} min';
    if (s < 86400) return 'há ${s ~/ 3600} h';
    return 'há ${s ~/ 86400} d';
  }
}
