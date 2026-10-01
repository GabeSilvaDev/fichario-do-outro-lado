import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ordem_paranormal/data/dados_op.dart';
import 'package:ordem_paranormal/models/ficha_op.dart';
import 'package:ordem_paranormal/screens/ficha_screen.dart';
import 'package:ordem_paranormal/screens/wizard_screen.dart';
import 'package:ordem_paranormal/store/ficha_store.dart';
import 'package:ordem_paranormal/theme.dart';

/// Assistente e ficha num celular comum (411dp): o que o NEX dá, e o teto
/// dos recursos.
void main() {
  setUpAll(() async {
    await DadosOP.carregar();
    Hive.init(Directory.systemTemp.createTempSync('nex').path);
    await Hive.openBox<String>(FichaStore.boxName);
  });

  void celular(WidgetTester t) {
    t.view.physicalSize = const Size(1080, 12000);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);
  }

  Finder linha(String texto, Type tipo) =>
      find.ancestor(of: find.text(texto), matching: find.byType(tipo)).first;

  Future<void> tocarMais(WidgetTester t, String atributo, int vezes) async {
    for (var i = 0; i < vezes; i++) {
      await t.tap(
        find.descendant(
          of: linha(atributo, Card),
          matching: find.byIcon(Icons.add_circle_outline),
        ),
      );
      await t.pump();
    }
  }

  int valorDe(WidgetTester t, String atributo) => int.parse(
    t
        .widget<Text>(
          find
              .descendant(
                of: linha(atributo, Card),
                matching: find.byType(Text),
              )
              .at(2),
        )
        .data!,
  );

  Future<void> proximo(WidgetTester t) async {
    await t.tap(find.text('Próximo'));
    await t.pumpAndSettle();
  }

  Future<void> ateAtributos(WidgetTester t, String classe, int nex) async {
    await t.pumpWidget(
      MaterialApp(theme: construirTema(), home: const WizardScreen()),
    );
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField).first, 'Agente');
    await t.pump();
    await proximo(t);
    await t.tap(find.text(DadosOP.origens.first.nome));
    await t.pump();
    await proximo(t);
    t.widget<Slider>(find.byType(Slider).first).onChanged!(nex.toDouble());
    await t.pump();
    await t.tap(find.text(classe).first);
    await t.pump();
    await proximo(t);
  }

  testWidgets('NEX 65%: dois aumentos, atributo vai a 5', (t) async {
    celular(t);
    await ateAtributos(t, 'Combatente', 65);

    expect(find.textContaining('2 Aumento(s) de Atributo'), findsOneWidget);
    await tocarMais(t, 'Vigor', 6);
    expect(valorDe(t, 'Vigor'), 5);
    await tocarMais(t, 'Intelecto', 6);
    expect(valorDe(t, 'Intelecto'), 3);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Amnésico: as duas perícias da origem entram nas livres', (
    t,
  ) async {
    celular(t);
    await t.pumpWidget(
      MaterialApp(theme: construirTema(), home: const WizardScreen()),
    );
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField).first, 'Sem memória');
    await t.pump();
    await proximo(t);
    await t.tap(find.text('Amnésico'));
    await t.pump();
    await proximo(t);
    t.widget<Slider>(find.byType(Slider).first).onChanged!(5);
    await t.pump();
    await t.tap(find.text('Combatente').first);
    await t.pump();
    await proximo(t);
    await tocarMais(t, 'Agilidade', 2);
    await tocarMais(t, 'Força', 2);
    await proximo(t);
    // Combatente 1 + Int 1 + 2 da origem que não vieram.
    expect(find.text('ESCOLHA MAIS 4'), findsOneWidget);
    expect(find.textContaining('dá só 0 perícia(s)'), findsOneWidget);
  });

  testWidgets('NEX 15%: sem aumento, teto 3', (t) async {
    celular(t);
    await ateAtributos(t, 'Combatente', 15);

    expect(find.textContaining('Aumento(s) de Atributo'), findsNothing);
    await tocarMais(t, 'Vigor', 6);
    expect(valorDe(t, 'Vigor'), 3);
  });

  testWidgets('Sobrevivente estágio 3: ponto extra, teto 3', (t) async {
    celular(t);
    await t.pumpWidget(
      MaterialApp(theme: construirTema(), home: const WizardScreen()),
    );
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField).first, 'Civil');
    await t.pump();
    await proximo(t);
    await t.tap(find.text(DadosOP.origens.first.nome));
    await t.pump();
    await proximo(t);
    await t.tap(find.text('Sobrevivente').first);
    await t.pump();
    await t.tap(find.text('3').first);
    await t.pump();
    await proximo(t);

    expect(find.textContaining('1 Aumento(s) de Atributo'), findsOneWidget);
    await tocarMais(t, 'Vigor', 6);
    expect(valorDe(t, 'Vigor'), 3);
    await tocarMais(t, 'Força', 6);
    expect(valorDe(t, 'Força'), 3);
  });

  testWidgets('NEX 70%: Grau de Treinamento leva a expert', (t) async {
    celular(t);
    await ateAtributos(t, 'Combatente', 70);
    await tocarMais(t, 'Agilidade', 6);
    await tocarMais(t, 'Força', 2);
    await proximo(t);

    // 2 + Int(1) = 3 perícias por grau, dois graus: 6 subidas.
    expect(find.textContaining('GRAU DE TREINAMENTO · 0 de 6'), findsOneWidget);
    await t.tap(find.widgetWithText(ChoiceChip, 'Luta'));
    await t.tap(find.widgetWithText(ChoiceChip, 'Reflexos'));
    await t.pump();
    await t.tap(linha('Atletismo', ListTile));
    await t.tap(linha('Percepção', ListTile));
    await t.pump();

    Future<void> subir(String pericia, int vezes) async {
      for (var i = 0; i < vezes; i++) {
        await t.tap(
          find.descendant(
            of: linha(pericia, ListTile),
            matching: find.byType(ActionChip),
          ),
        );
        await t.pump();
      }
    }

    await subir('Luta', 2);
    await subir('Reflexos', 2);
    await subir('Atletismo', 2);
    expect(find.textContaining('GRAU DE TREINAMENTO · 6 de 6'), findsOneWidget);
    // Quarta perícia não cabe: o toque não sobe.
    await subir('Percepção', 1);
    expect(
      find.descendant(
        of: linha('Percepção', ListTile),
        matching: find.text('+5'),
      ),
      findsOneWidget,
    );

    await proximo(t);
    expect(find.text('Luta +15'), findsOneWidget);
    expect(find.text('Atletismo +15'), findsOneWidget);
    expect(find.text('Percepção +5'), findsOneWidget);
    expect(find.text('ANOTE NA FICHA'), findsOneWidget);
    expect(find.textContaining('Poder de combatente'), findsOneWidget);
  });

  testWidgets(
    'ficha: vida cheia não sobe, temporário sai primeiro, NEX avisa',
    (t) async {
      celular(t);
      final f = FichaOP.nova('ficha-nex')
        ..nome = 'Teste'
        ..classe = 'Combatente'
        ..nex = 5;
      f.definirAtributo('VIG', 1);
      f.pv = f.pvMax;
      f.pvTemporario = 2;
      await t.pumpWidget(
        MaterialApp(
          theme: construirTema(),
          home: FichaScreen(fichaDireta: f),
        ),
      );
      await t.pumpAndSettle();

      final vida = linha('VIDA', Card);
      await t.tap(find.descendant(of: vida, matching: find.byIcon(Icons.add)));
      await t.pump();
      expect(f.pv, 21);

      await t.tap(
        find.descendant(of: vida, matching: find.byIcon(Icons.remove)),
      );
      await t.pump();
      expect(f.pvTemporario, 1);
      expect(f.pv, 21);

      expect(find.textContaining('Próximo: NEX 10%'), findsOneWidget);
      final regua = t.widget<Slider>(find.byType(Slider).first);
      regua.onChangeStart!(5);
      regua.onChanged!(20);
      regua.onChangeEnd!(20);
      await t.pumpAndSettle();
      expect(find.text('NEX 5% → 20%'), findsOneWidget);
      expect(find.textContaining('Aumento de Atributo'), findsWidgets);
      expect(f.pv, f.pvMax);
      expect(f.atributo('VIG'), 1);
    },
  );
}
