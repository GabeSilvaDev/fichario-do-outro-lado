import 'dart:math' as math;
import 'dart:ui';

/// A régua do mapa, pelas regras do livro (OPRPG p. 54 e 89):
/// um quadrado = 1,5 m; curto 6 quadrados (9 m), médio 12 (18 m),
/// longo 24 (36 m), extremo 60 (90 m); na diagonal, cada quadrado conta 2.
///
/// Os pontos chegam relativos à imagem (0..1 em cada eixo), como as peças.
/// O tamanho do quadrado vem da calibragem do mestre, em fração da largura
/// da imagem — cada planta tem a grade de um tamanho.
class Regua {
  static const double metrosPorQuadrado = 1.5;

  /// Quantos quadrados cabem entre [a] e [b]. Andar na diagonal custa o
  /// dobro: o total fica sendo a soma dos dois eixos.
  static int quadrados(Offset a, Offset b, Size imagem, double quadrado) {
    final lado = quadrado * imagem.width;
    if (lado <= 0) return 0;
    final dx = ((b.dx - a.dx) * imagem.width).abs() / lado;
    final dy = ((b.dy - a.dy) * imagem.height).abs() / lado;
    return dx.round() + dy.round();
  }

  /// Colado (inclusive na diagonal): é o alcance do corpo a corpo.
  static bool adjacente(Offset a, Offset b, Size imagem, double quadrado) {
    final lado = quadrado * imagem.width;
    if (lado <= 0) return false;
    final dx = ((b.dx - a.dx) * imagem.width).abs() / lado;
    final dy = ((b.dy - a.dy) * imagem.height).abs() / lado;
    return dx.round() <= 1 && dy.round() <= 1;
  }

  static String alcance(int quadrados) {
    if (quadrados <= 6) return 'Curto';
    if (quadrados <= 12) return 'Médio';
    if (quadrados <= 24) return 'Longo';
    if (quadrados <= 60) return 'Extremo';
    return 'Além do extremo';
  }

  /// "4 quadrados · 6 m · Curto".
  static String rotulo(Offset a, Offset b, Size imagem, double quadrado) {
    if (adjacente(a, b, imagem, quadrado)) return 'Adjacente · corpo a corpo';
    final q = quadrados(a, b, imagem, quadrado);
    final m = q * metrosPorQuadrado;
    final metros = m == m.roundToDouble()
        ? m.toStringAsFixed(0)
        : m.toStringAsFixed(1).replaceAll('.', ',');
    return '$q quadrado${q == 1 ? '' : 's'} · $metros m · ${alcance(q)}';
  }

  /// Da linha que o mestre arrastou sobre [n] quadrados da grade, o lado de
  /// um quadrado em fração da largura da imagem.
  static double calibrar(Offset a, Offset b, Size imagem, int n) {
    if (n <= 0 || imagem.width <= 0) return 0;
    final dx = (b.dx - a.dx) * imagem.width;
    final dy = (b.dy - a.dy) * imagem.height;
    return math.sqrt(dx * dx + dy * dy) / n / imagem.width;
  }
}
