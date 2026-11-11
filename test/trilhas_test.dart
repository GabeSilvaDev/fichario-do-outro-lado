import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ordem_paranormal/data/dados_op.dart';
import 'package:ordem_paranormal/models/ficha_op.dart';
import 'package:ordem_paranormal/screens/ficha_screen.dart';
import 'package:ordem_paranormal/store/ficha_store.dart';
import 'package:ordem_paranormal/theme.dart';

/// Trilhas do Livro de Regras v1.3 (p. 26–35): 5 por classe, escolhidas
/// numa lista que só mostra as da classe da ficha.
void main() {
  setUpAll(() async {
    await DadosOP.carregar();
    Hive.init(Directory.systemTemp.createTempSync('trilhas').path);
    await Hive.openBox<String>(FichaStore.boxName);
  });

  const doLivro = {
    'Combatente': [
      'Aniquilador',
      'Comandante de Campo',
      'Guerreiro',
      'Operações Especiais',
      'Tropa de Choque',
    ],
    'Especialista': [
      'Atirador de Elite',
      'Infiltrador',
      'Médico de Campo',
      'Negociador',
      'Técnico',
    ],
    'Ocultista': [
      'Conduíte',
      'Flagelador',
      'Graduado',
      'Intuitivo',
      'Lâmina Paranormal',
    ],
  };

  group('catálogo', () {
    for (final e in doLivro.entries) {
      test('${e.key}: só as 5 trilhas do Livro de Regras', () {
        final nomes = [
          for (final t in DadosOP.trilhasParaEscolher(e.key)) t.nome,
        ];
        expect(nomes, e.value);
      });
    }

    test('cada trilha do livro tem resumo curto, página e 4 habilidades', () {
      for (final nomes in doLivro.values) {
        for (final nome in nomes) {
          final t = DadosOP.trilhaPorNome(nome)!;
          expect(t.resumo, isNotEmpty, reason: nome);
          // Licença: notação nossa, nunca o parágrafo do livro.
          expect(t.resumo.length, lessThanOrEqualTo(130), reason: nome);
          expect(t.pagina, inInclusiveRange(26, 35), reason: nome);
          final hs = DadosOP.habilidadesDaTrilha(nome);
          expect([for (final h in hs) h.nex], [10, 40, 65, 99], reason: nome);
        }
      }
    });
  });

  test('Mundano (NEX 0%) não tem trilha', () {
    expect(DadosOP.trilhasParaEscolher('Mundano'), isEmpty);
  });

  test('trilha digitada à mão com outra caixa vira a do catálogo', () {
    final f = FichaOP({
      'id': 'antiga',
      'classe': 'Ocultista',
      'nex': 10,
      'trilha': 'flagelador',
    });
    expect(f.trilha, 'Flagelador');
    expect(
      FichaOP({
        'id': 'x',
        'classe': 'Ocultista',
        'trilha': 'lamina paranormal',
      }).trilha,
      'Lâmina Paranormal',
    );
  });

  group('na ficha', () {
    FichaOP ocultista() =>
        FichaOP.nova('trilha-${DateTime.now().microsecondsSinceEpoch}')
          ..nome = 'Teste'
          ..classe = 'Ocultista'
          ..nex = 40;

    Future<void> abrir(WidgetTester t, FichaOP f) async {
      t.view.physicalSize = const Size(1080, 6000);
      t.view.devicePixelRatio = 2.625;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          theme: construirTema(),
          home: FichaScreen(fichaDireta: f),
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('lista só as de ocultista e escolher põe as habilidades', (
      t,
    ) async {
      final f = ocultista();
      await abrir(t, f);
      expect(
        find.byType(TextFormField).evaluate().where((e) {
          final w = e.widget as TextFormField;
          return w.initialValue == f.trilha && f.trilha.isNotEmpty;
        }),
        isEmpty,
      );

      await t.tap(find.byKey(const ValueKey('editar-Identidade')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('seletor-trilha')));
      await t.pumpAndSettle();

      expect(find.text('Trilhas de ocultista'), findsOneWidget);
      final lista = find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first;
      for (final nome in doLivro['Ocultista']!) {
        final cartao = find.byKey(ValueKey('trilha-opcao-$nome'));
        await t.scrollUntilVisible(cartao, 150, scrollable: lista);
        expect(cartao, findsOneWidget);
      }
      for (final nome in [...doLivro['Combatente']!, 'Exorcista']) {
        expect(find.byKey(ValueKey('trilha-opcao-$nome')), findsNothing);
      }

      final graduado = find.byKey(const ValueKey('trilha-opcao-Graduado'));
      await t.scrollUntilVisible(graduado, -150, scrollable: lista);
      await t.tap(graduado);
      await t.pumpAndSettle();

      expect(f.trilha, 'Graduado');
      final nomes = {for (final h in f.habilidades) h['nome']};
      expect(nomes, containsAll(['Saber Ampliado', 'Grimório Ritualístico']));
      expect(nomes, isNot(contains('Rituais Eficientes')));
    });

    testWidgets('trilha antiga fora do livro aparece e pode ser trocada', (
      t,
    ) async {
      final f = ocultista()..trilha = 'Exorcista';
      await abrir(t, f);
      expect(find.text('Exorcista'), findsOneWidget);
      expect(find.textContaining('Fora do Livro de Regras'), findsOneWidget);

      await t.tap(find.byKey(const ValueKey('editar-Identidade')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('seletor-trilha')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('trilha-opcao-Intuitivo')));
      await t.pumpAndSettle();
      expect(f.trilha, 'Intuitivo');
    });
  });
}
