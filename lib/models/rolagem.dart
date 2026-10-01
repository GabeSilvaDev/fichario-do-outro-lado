import 'dart:math';

/// O motor de dados de Ordem Paranormal.
///
/// Testes rolam Nd20 e pegam o MELHOR (atributo 0: 2d20 e o PIOR), somando o
/// bônus de perícia. Dano é uma expressão comum ("2d6+3", "1d8+1d4").
class Rolagem {
  static final Random _sorte = Random.secure();

  static int _dado(int faces) => _sorte.nextInt(faces) + 1;

  /// Teste de perícia/atributo: [dados]d20, melhor ou pior, + bônus.
  static ResultadoRolagem teste({
    required String titulo,
    required int dados,
    required bool melhor,
    required int bonus,
    int margem = 20,
  }) {
    final n = dados.clamp(1, 10);
    final rolados = [for (var i = 0; i < n; i++) _dado(20)];
    final escolhido =
        melhor ? rolados.reduce(max) : rolados.reduce(min);
    final formula =
        '${n}d20${melhor ? '↑' : '↓'}${bonus > 0 ? '+$bonus' : bonus < 0 ? '$bonus' : ''}';
    return ResultadoRolagem(
      titulo: titulo,
      formula: formula,
      rolados: rolados,
      escolhido: escolhido,
      total: escolhido + bonus,
      critico: escolhido >= margem,
      desastre: escolhido == 1,
    );
  }

  /// Expressão de dano: termos NdM e números, com + e −. Null se inválida.
  /// [multiplicarDados]: crítico — só os dados da arma multiplicam, o
  /// bônus fixo não (OPRPG p. 54).
  static ResultadoRolagem? expressao(String titulo, String bruta,
      {int multiplicarDados = 1}) {
    final limpa = bruta.toLowerCase().replaceAll('–', '-').replaceAll(' ', '');
    if (limpa.isEmpty) return null;
    if (!RegExp(r'^[+-]?(\d*d\d+|\d+)([+-](\d*d\d+|\d+))*$').hasMatch(limpa)) {
      return null;
    }
    var total = 0;
    final rolados = <int>[];
    final partes = <String>[];
    for (final m in RegExp(r'([+-]?)(\d*)d(\d+)|([+-]?)(\d+)')
        .allMatches(limpa)) {
      if (m.group(3) != null) {
        final sinal = m.group(1) == '-' ? -1 : 1;
        final n = ((m.group(2)!.isEmpty ? 1 : int.parse(m.group(2)!)) *
                multiplicarDados)
            .clamp(1, 80);
        final faces = int.parse(m.group(3)!).clamp(2, 1000);
        var soma = 0;
        final estes = <int>[];
        for (var i = 0; i < n; i++) {
          final d = _dado(faces);
          soma += d;
          estes.add(d);
        }
        rolados.addAll(estes);
        total += sinal * soma;
        partes.add('${sinal < 0 ? '−' : ''}${n}d$faces[${estes.join(' ')}]');
      } else {
        final sinal = m.group(4) == '-' ? -1 : 1;
        final valor = int.parse(m.group(5)!);
        total += sinal * valor;
        partes.add('${sinal < 0 ? '−' : '+'}$valor');
      }
    }
    return ResultadoRolagem(
      titulo: titulo,
      formula: limpa,
      rolados: rolados,
      escolhido: null,
      total: total,
      critico: false,
      desastre: false,
      detalhe: partes.join(' '),
    );
  }
}

class ResultadoRolagem {
  final String titulo;
  final String formula;
  final List<int> rolados;

  /// O d20 que valeu, nos testes. Null em expressões de dano.
  final int? escolhido;
  final int total;
  final bool critico;
  final bool desastre;
  final String detalhe;

  ResultadoRolagem({
    required this.titulo,
    required this.formula,
    required this.rolados,
    required this.escolhido,
    required this.total,
    required this.critico,
    required this.desastre,
    String? detalhe,
  }) : detalhe = detalhe ?? '[${rolados.join(' ')}]';
}
