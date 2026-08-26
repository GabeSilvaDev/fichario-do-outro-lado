import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_paranormal/data/dados_op.dart';
import 'package:ordem_paranormal/models/ficha_op.dart';
import 'package:ordem_paranormal/screens/ficha_screen.dart';
import 'package:ordem_paranormal/theme.dart';

/// Ficha de ameaça na tela. O bônus de perícia do livro não segue os graus
/// 5/10/15 do agente (Furtividade +8, Percepção +25) — e era exatamente
/// isso que derrubava a aba de perícias com "Null check operator used on a
/// null value".
void main() {
  testWidgets('aba de perícias aguenta bônus fora da tabela', (tester) async {
    await DadosOP.carregar();
    // tela alta e estreita como a de um celular: cabe a lista inteira de
    // perícias sem precisar rolar no teste
    tester.view.physicalSize = const Size(1500, 6000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final ficha = FichaOP.novoNpc('t1')
      ..nome = 'Criatura de teste'
      ..vd = 40
      ..categoria = 'Criatura'
      ..tamanho = 'Grande'
      ..defesaManual = 23
      ..definirGrauPericia('Percepção', 25)
      ..definirGrauPericia('Furtividade', 8)
      ..definirGrauPericia('Fortitude', 15);

    await tester.pumpWidget(MaterialApp(
      theme: construirTema(),
      home: FichaScreen(fichaDireta: ficha, somenteLeitura: true),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perícias'));
    await tester.pumpAndSettle();

    expect(find.text('E +15'), findsOneWidget);
    expect(find.text('+8'), findsOneWidget);
    expect(find.text('+25'), findsOneWidget);
  });
}
