import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_paranormal/screens/catalogo_screen.dart';
import 'package:ordem_paranormal/theme.dart';

/// A tela do catálogo montada com os assets reais: é o que garante que o
/// que está no JSON chega à mesa.
///
/// Tudo num teste só de propósito: o asset é lido uma vez por execução, e
/// abrir a tela em testes separados deixa o carregamento pendurado.
void main() {
  testWidgets('catálogo lista, busca e devolve item para a ficha',
      (tester) async {
    Map<String, dynamic>? escolhido;

    await tester.pumpWidget(MaterialApp(
      theme: construirTema(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              escolhido =
                  await Navigator.of(context).push<Map<String, dynamic>>(
                MaterialPageRoute(
                  builder: (_) => const CatalogoScreen(escolhendo: true),
                ),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // 1) a lista sai agrupada por elemento e círculo
    expect(find.text('CONHECIMENTO · 1º CÍRCULO'), findsOneWidget);
    expect(find.text('Compreensão Paranormal'), findsOneWidget);
    expect(find.textContaining('1 PE · padrão · toque'), findsWidgets);

    // 2) a busca filtra e o ritual abre com efeito e ampliação
    // (pump com duração em vez de settle: o cursor do campo pisca sempre)
    await tester.enterText(find.byType(TextField), 'eletrocuss');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Eletrocussão'), findsOneWidget);

    await tester.tap(find.text('Eletrocussão'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('3d6 de eletricidade'), findsOneWidget);
    // a ampliação é desenhada com RichText (o nome em destaque)
    expect(find.textContaining('Discente', findRichText: true),
        findsWidgets);

    // 3) na aba de armas, o item volta pronto para virar ataque
    await tester.tap(find.text('Armas'));
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField), 'espingarda');
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pump(const Duration(seconds: 1));

    expect(escolhido, isNotNull);
    expect(escolhido!['nome'], 'Espingarda');
    expect(escolhido!['pericia'], 'Pontaria');
    expect((escolhido!['dano'] as String).isNotEmpty, isTrue);
  });
}
