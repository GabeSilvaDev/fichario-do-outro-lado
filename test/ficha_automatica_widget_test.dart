import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ordem_paranormal/data/dados_op.dart';
import 'package:ordem_paranormal/models/ficha_op.dart';
import 'package:ordem_paranormal/screens/ficha_screen.dart';
import 'package:ordem_paranormal/screens/poderes_screen.dart';
import 'package:ordem_paranormal/store/ficha_store.dart';
import 'package:ordem_paranormal/theme.dart';

/// A ficha avisa e recalcula sozinha: pendências, estados, condições,
/// poderes do catálogo, conjurar ritual — num celular de 411dp.
void main() {
  setUpAll(() async {
    await DadosOP.carregar();
    Hive.init(Directory.systemTemp.createTempSync('auto').path);
    await Hive.openBox<String>(FichaStore.boxName);
  });

  void celular(WidgetTester t) {
    t.view.physicalSize = const Size(1080, 14000);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);
  }

  FichaOP combatente() {
    final f = FichaOP.nova('auto-${DateTime.now().microsecondsSinceEpoch}')
      ..nome = 'Teste'
      ..origem = DadosOP.origens.first.nome
      ..classe = 'Combatente'
      ..nex = 5;
    for (final s in ['AGI', 'FOR', 'VIG', 'PRE']) {
      f.definirAtributo(s, 2);
    }
    f.aplicarClasse(DadosOP.classePorNome('Combatente')!);
    f.aplicarOrigem(DadosOP.origens.first);
    for (final p in ['Luta', 'Fortitude', 'Atletismo', 'Percepção']) {
      f.definirGrauPericia(p, 5);
    }
    f.pv = f.pvMax;
    f.san = f.sanMax;
    f.pe = f.peMax;
    return f;
  }

  Future<void> abrir(WidgetTester t, FichaOP f) async {
    await t.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: FichaScreen(fichaDireta: f),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> aba(WidgetTester t, String nome) async {
    const ordem = [
      'Geral',
      'Perícias',
      'Ataques',
      'Poderes',
      'Inventário',
      'Sobre',
    ];
    DefaultTabController.of(
      t.element(find.byType(TabBarView)),
    ).animateTo(ordem.indexOf(nome));
    await t.pumpAndSettle();
  }

  testWidgets('subir de NEX avisa o que ficou para resolver', (t) async {
    celular(t);
    final f = combatente();
    await abrir(t, f);
    expect(find.byIcon(Icons.fact_check_outlined), findsNothing);

    final regua = t.widget<Slider>(find.byType(Slider).first);
    regua.onChangeStart!(5);
    regua.onChanged!(20);
    regua.onChangeEnd!(20);
    await t.pumpAndSettle();
    expect(find.text('NEX 5% → 20%'), findsOneWidget);
    await t.tap(find.text('Entendi'));
    await t.pumpAndSettle();

    // Painel e selo: faltam o ponto do aumento, a trilha e o poder.
    expect(find.byIcon(Icons.fact_check_outlined), findsOneWidget);
    expect(find.textContaining('ponto(s) para distribuir'), findsWidgets);
    expect(find.textContaining('escolha a trilha'), findsWidgets);
  });

  testWidgets('PV a zero: morrendo conta turnos e mata no 3º', (t) async {
    celular(t);
    final f = combatente();
    await abrir(t, f);
    f.pv = 0;
    await t.tap(find.text('Fim de cena'));
    await t.pumpAndSettle();
    expect(find.text('Morrendo'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await t.tap(find.text('+1 turno').first);
      await t.pumpAndSettle();
    }
    expect(f.morto, isTrue);
    expect(find.text('Morto'), findsWidgets);
  });

  testWidgets('condição muda a Defesa na hora', (t) async {
    celular(t);
    final f = combatente();
    await abrir(t, f);
    final antes = f.defesa;
    await t.tap(find.widgetWithText(FilterChip, 'Vulnerável'));
    await t.pumpAndSettle();
    expect(f.defesa, antes - 2);
    expect(find.text('${antes - 2}'), findsWidgets);
  });

  testWidgets('poder do catálogo entra com efeito', (t) async {
    celular(t);
    final f = combatente()..nex = 15;
    await abrir(t, f);
    await aba(t, 'Poderes');
    await t.tap(find.text('Do catálogo de poderes'));
    await t.pumpAndSettle();
    expect(find.byType(PoderesScreen), findsOneWidget);
    await t.tap(find.byIcon(Icons.add_circle_outline).first);
    await t.pumpAndSettle();
    expect(
      f.habilidades.where((h) => h['tipoPoder'] == 'classe'),
      hasLength(1),
    );
  });

  testWidgets('conjurar gasta PE e cobra o custo do paranormal', (t) async {
    celular(t);
    final f = FichaOP.nova('oc')
      ..nome = 'Ocultista'
      ..classe = 'Ocultista'
      ..nex = 5;
    f.definirAtributo('PRE', 3);
    f.pe = f.peMax;
    f.san = f.sanMax;
    f.adicionarEm('rituais', {
      'nome': 'Teste',
      'elemento': 'Medo',
      'circulo': '1º',
      'custo': '1 PE',
      'descricao': 'Efeito.\nDiscente (+2 PE): mais efeito.',
    });
    await abrir(t, f);
    await aba(t, 'Poderes');
    await t.tap(find.text('Teste'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(OutlinedButton, 'Conjurar'));
    await t.pumpAndSettle();
    expect(find.textContaining('Custo: 1 PE'), findsOneWidget);
    final pe = f.pe;
    final sanMax = f.sanMax;
    await t.tap(find.widgetWithText(TextButton, 'Conjurar'));
    await t.pumpAndSettle();
    expect(f.pe, pe - 1);
    expect(f.sanMax, sanMax - 1);
  });

  testWidgets('abas renderizam no celular sem estourar', (t) async {
    celular(t);
    final f = combatente()
      ..nex = 55
      ..condicoes = ['Fatigado'];
    f.vestirProtecao('Pesada');
    f.adicionarEm('ataques', {
      'nome': 'Fuzil',
      'pericia': 'Pontaria',
      'dano': '2d10',
      'margem': '19',
      'critico': 'x3',
      'familia': 'Armas Táticas',
      'uso': 'Armas de Fogo – Duas Mãos',
    });
    f.adicionarEm('inventario', {
      'nome': 'Kit',
      'categoria': 'I',
      'espacos': 1,
    });
    await abrir(t, f);
    for (final nome in [
      'Perícias',
      'Ataques',
      'Poderes',
      'Inventário',
      'Sobre',
    ]) {
      await aba(t, nome);
    }
    await aba(t, 'Ataques');
    expect(find.textContaining('crítico 19/x3'), findsOneWidget);
    await aba(t, 'Sobre');
    expect(find.text('Regras opcionais'.toUpperCase()), findsOneWidget);
  });
}
