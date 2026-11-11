import 'package:flutter/material.dart';

import '../theme.dart';

/// Peças da ficha em modo leitura: o que está escrito aparece como texto
/// limpo, sem cara de formulário — campo de digitar só no lápis.

/// Rótulo pequeno em caixa alta sobre o valor.
class InfoLeitura extends StatelessWidget {
  final String rotulo;
  final String valor;
  final String? detalhe;
  final Color? corValor;

  const InfoLeitura(
    this.rotulo,
    this.valor, {
    super.key,
    this.detalhe,
    this.corValor,
  });

  @override
  Widget build(BuildContext context) {
    final vazio = valor.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rotulo.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
            color: Cores.tinta2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          vazio ? '—' : valor,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: vazio ? Cores.tinta2 : (corValor ?? Cores.tinta),
          ),
        ),
        if (detalhe != null && detalhe!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              detalhe!,
              style: const TextStyle(fontSize: 12, color: Cores.tinta2),
            ),
          ),
      ],
    );
  }
}

/// Selo colorido curto: classe, origem, patente, grau de perícia.
class Etiqueta extends StatelessWidget {
  final String texto;
  final Color cor;
  final IconData? icone;

  const Etiqueta(this.texto, {super.key, this.cor = Cores.tinta2, this.icone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: .12),
        border: Border.all(color: cor.withValues(alpha: .55)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 13, color: cor),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Texto longo do "Sobre" e das anotações: título + parágrafo.
class ParagrafoLeitura extends StatelessWidget {
  final String titulo;
  final String texto;

  const ParagrafoLeitura(this.titulo, this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Cores.energiaViva,
            ),
          ),
          const SizedBox(height: 3),
          Text(texto, style: const TextStyle(fontSize: 14, height: 1.35)),
        ],
      ),
    );
  }
}

/// Aviso de "nada aqui ainda", discreto.
class VazioLeitura extends StatelessWidget {
  final String texto;
  const VazioLeitura(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Cores.tinta2, fontSize: 13),
      ),
    );
  }
}
