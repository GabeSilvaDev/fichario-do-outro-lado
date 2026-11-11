import 'package:flutter/material.dart';

import '../data/dados_op.dart';
import '../regras/poderes.dart';
import '../theme.dart';

/// Campo de trilha: nunca é texto livre. Mostra a trilha escolhida com o
/// resumo dela e, ao tocar, abre a lista só com as trilhas da classe — cada
/// uma com o que faz e as habilidades de NEX 10, 40, 65 e 99%.
class SeletorTrilha extends StatelessWidget {
  final String classe;
  final String valor;

  /// NEX atual: marca as habilidades que a ficha já tem.
  final int nex;

  /// Null deixa o campo só de leitura.
  final ValueChanged<String>? onChanged;

  /// Texto curto sob o rótulo quando a trilha ainda não libera
  /// ("libera em NEX 10%").
  final String? bloqueio;

  const SeletorTrilha({
    super.key,
    required this.classe,
    required this.valor,
    required this.nex,
    this.onChanged,
    this.bloqueio,
  });

  @override
  Widget build(BuildContext context) {
    final opcoes = DadosOP.trilhasParaEscolher(classe);
    final atual = DadosOP.trilhaPorNome(valor);
    final semOpcoes = opcoes.isEmpty;
    final habilitado = onChanged != null && !semOpcoes;
    final rotulo = bloqueio == null ? 'Trilha' : 'Trilha · $bloqueio';

    final String titulo;
    final String subtitulo;
    if (semOpcoes) {
      titulo = valor.isEmpty ? '—' : valor;
      subtitulo = '$classe não tem trilha.';
    } else if (valor.isEmpty) {
      titulo = 'Toque para escolher';
      subtitulo = '${opcoes.length} trilhas de ${classe.toLowerCase()}';
    } else {
      titulo = valor;
      final naLista = opcoes.any((t) => t.nome == valor);
      subtitulo = naLista
          ? atual!.resumo
          : atual == null
          ? 'Fora do Livro de Regras: sem automação.'
          : 'Fora do Livro de Regras (${atual.fonte}). Toque para trocar.';
    }

    return InkWell(
      key: const ValueKey('seletor-trilha'),
      borderRadius: BorderRadius.circular(4),
      onTap: habilitado ? () => _abrir(context, opcoes) : null,
      child: InputDecorator(
        isEmpty: false,
        decoration: InputDecoration(
          labelText: rotulo,
          isDense: true,
          enabled: habilitado,
          suffixIcon: habilitado
              ? const Icon(Icons.unfold_more, size: 20)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titulo,
              style: TextStyle(
                fontWeight: valor.isEmpty ? FontWeight.normal : FontWeight.w600,
                color: valor.isEmpty ? Cores.tinta2 : Cores.tinta,
              ),
            ),
            if (subtitulo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitulo,
                  style: const TextStyle(fontSize: 12, color: Cores.tinta2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrir(BuildContext context, List<Trilha> opcoes) async {
    final escolhida = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Cores.carta,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, rolagem) => _ListaTrilhas(
          classe: classe,
          opcoes: opcoes,
          valor: valor,
          nex: nex,
          rolagem: rolagem,
        ),
      ),
    );
    if (escolhida != null && escolhida != valor) onChanged?.call(escolhida);
  }
}

class _ListaTrilhas extends StatelessWidget {
  final String classe;
  final List<Trilha> opcoes;
  final String valor;
  final int nex;
  final ScrollController rolagem;

  const _ListaTrilhas({
    required this.classe,
    required this.opcoes,
    required this.valor,
    required this.nex,
    required this.rolagem,
  });

  @override
  Widget build(BuildContext context) {
    final foraDaLista = valor.isNotEmpty && !opcoes.any((t) => t.nome == valor);
    return ListView(
      controller: rolagem,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(
          'Trilhas de ${classe.toLowerCase()}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Escolhida em NEX 10%. As habilidades entram sozinhas em '
          'NEX 10, 40, 65 e 99%.',
          style: const TextStyle(fontSize: 12, color: Cores.tinta2),
        ),
        const SizedBox(height: 12),
        if (foraDaLista)
          _CartaoSimples(
            titulo: valor,
            texto:
                'Trilha atual, fora do Livro de Regras. Toque para '
                'manter; escolha outra abaixo para trocar.',
            selecionada: true,
            onTap: () => Navigator.pop(context, valor),
          ),
        for (final t in opcoes)
          _CartaoTrilha(
            trilha: t,
            selecionada: t.nome == valor,
            nex: nex,
            onTap: () => Navigator.pop(context, t.nome),
          ),
        if (valor.isNotEmpty)
          _CartaoSimples(
            titulo: 'Sem trilha',
            texto: 'Tira a trilha da ficha e as habilidades dela.',
            selecionada: false,
            onTap: () => Navigator.pop(context, ''),
          ),
      ],
    );
  }
}

class _CartaoTrilha extends StatelessWidget {
  final Trilha trilha;
  final bool selecionada;
  final int nex;
  final VoidCallback onTap;

  const _CartaoTrilha({
    required this.trilha,
    required this.selecionada,
    required this.nex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final habilidades = DadosOP.habilidadesDaTrilha(trilha.nome);
    final requisito = trilha.requisitos.isEmpty ? null : trilha.requisitos;
    return Card(
      key: ValueKey('trilha-opcao-${trilha.nome}'),
      color: selecionada ? Cores.carta2 : Cores.fundo,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selecionada ? Cores.energia : Cores.linha,
          width: selecionada ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trilha.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selecionada)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Cores.energia,
                      ),
                    ),
                  if (trilha.pagina > 0)
                    Text(
                      'p. ${trilha.pagina}',
                      style: const TextStyle(fontSize: 11, color: Cores.tinta2),
                    ),
                ],
              ),
              if (trilha.resumo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(trilha.resumo, style: const TextStyle(fontSize: 13)),
              ],
              if (requisito != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Requisito: $requisito',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Cores.conhecimento,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              for (final h in habilidades) _linhaHabilidade(h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linhaHabilidade(Poder h) {
    final marco = h.nex;
    final tem = nex >= marco;
    final etiqueta = '$marco%';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tem ? Cores.energia.withValues(alpha: 0.25) : null,
              border: Border.all(color: tem ? Cores.energia : Cores.linha),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              etiqueta,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: tem ? Cores.energiaViva : Cores.tinta2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${h.nome}. ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: h.efeito,
                    style: const TextStyle(color: Cores.tinta2),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoSimples extends StatelessWidget {
  final String titulo;
  final String texto;
  final bool selecionada;
  final VoidCallback onTap;

  const _CartaoSimples({
    required this.titulo,
    required this.texto,
    required this.selecionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Cores.fundo,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selecionada ? Cores.energia : Cores.linha),
      ),
      child: ListTile(
        title: Text(titulo),
        subtitle: Text(texto, style: const TextStyle(fontSize: 12)),
        onTap: onTap,
      ),
    );
  }
}
