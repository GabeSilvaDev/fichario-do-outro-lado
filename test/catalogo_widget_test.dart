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
  testWidgets('catálogo lista, busca e devolve item para a ficha', (
    tester,
  ) async {
    Map<String, dynamic>? escolhido;
    // Tela alta: o cartão aberto da arma mostra tudo e empurra o botão.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                escolhido = await Navigator.of(context)
                    .push<Map<String, dynamic>>(
                      MaterialPageRoute(
                        builder: (_) => const CatalogoScreen(escolhendo: true),
                      ),
                    );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // Separado por círculo; o filtro mostra só um grupo.
    expect(find.textContaining('1º CÍRCULO · '), findsOneWidget);
    expect(find.text('Compreensão Paranormal'), findsOneWidget);
    expect(find.textContaining('1 PE · padrão · toque'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('filtro-ritual-2º círculo')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('1º CÍRCULO · '), findsNothing);
    expect(find.textContaining('2º CÍRCULO · '), findsOneWidget);
    // Por elemento: os títulos viram os elementos.
    await tester.tap(find.text('Por elemento'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('CONHECIMENTO · '), findsOneWidget);
    await tester.tap(find.text('Por círculo'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(TextField), 'eletrocuss');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Eletrocussão'), findsOneWidget);

    await tester.tap(find.text('Eletrocussão'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('3d6 de eletricidade'), findsOneWidget);
    expect(find.textContaining('Discente', findRichText: true), findsWidgets);

    await tester.tap(find.widgetWithText(Tab, 'Armas'));
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField), 'espingarda');
    await tester.pump(const Duration(milliseconds: 400));

    // O cartão abre com tudo: dano base, crítico e o dano do crítico.
    await tester.tap(find.text('Espingarda'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('4d6 de balístico'), findsOneWidget);
    expect(find.textContaining('No crítico: 12d6'), findsOneWidget);
    expect(
      find.textContaining('Metade do dano em alcance médio'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Cartuchos · um pacote dura 1 cena'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const ValueKey('por-Espingarda')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('por-Espingarda')));
    await tester.pump(const Duration(seconds: 1));

    expect(escolhido, isNotNull);
    expect(escolhido!['nome'], 'Espingarda');
    expect(escolhido!['pericia'], 'Pontaria');
    expect((escolhido!['dano'] as String).isNotEmpty, isTrue);
    expect(escolhido!['arma'], 'Espingarda');
    expect(escolhido!['critico'], 'x3');
  });
}
