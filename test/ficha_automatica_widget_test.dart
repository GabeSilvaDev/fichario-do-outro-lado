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

  Future<void> lapis(WidgetTester t, String secao) async {
    await t.tap(find.byKey(ValueKey('editar-$secao')));
    await t.pumpAndSettle();
  }

  testWidgets('subir de NEX avisa o que ficou para resolver', (t) async {
    celular(t);
    final f = combatente();
    await abrir(t, f);
    expect(find.byIcon(Icons.fact_check_outlined), findsNothing);
    await lapis(t, 'Identidade');

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

  testWidgets('ficha abre travada: sem campo de digitar, sem régua', (t) async {
    celular(t);
    await abrir(t, combatente());
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(Slider), findsNothing);
    expect(find.text('Teste'), findsWidgets); // nome em texto
    // Recursos seguem com + e −.
    expect(find.byIcon(Icons.add), findsWidgets);
    // Estado, condições e estado na mesa saíram da ficha.
    expect(find.text('CONDIÇÕES'), findsNothing);
    expect(find.text('ESTADO NA MESA'), findsNothing);
    expect(find.text('Fim de cena'), findsNothing);
  });

  testWidgets('lápis edita só a seção; Salvar volta à leitura', (t) async {
    celular(t);
    final f = combatente();
    await abrir(t, f);
    await lapis(t, 'Identidade');
    expect(find.byKey(const ValueKey('salvar-Identidade')), findsOneWidget);
    await t.enterText(
      find.widgetWithText(TextFormField, 'Nome do personagem'),
      'Novo nome',
    );
    await t.tap(find.byKey(const ValueKey('salvar-Identidade')));
    await t.pumpAndSettle();
    expect(f.nome, 'Novo nome');
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Novo nome'), findsWidgets);
  });

  testWidgets('Cancelar desfaz o que mudou no lápis', (t) async {
    celular(t);
    final f = combatente();
    await abrir(t, f);
    await lapis(t, 'Identidade');
    await t.enterText(
      find.widgetWithText(TextFormField, 'Nome do personagem'),
      'Errado',
    );
    expect(f.nome, 'Errado');
    await t.tap(find.byKey(const ValueKey('cancelar-Identidade')));
    await t.pumpAndSettle();
    expect(f.nome, 'Teste');
    expect(FichaStore.porId(f.id)?.nome, 'Teste');
  });

  testWidgets('máximo de PV ajustado pela história no lápis', (t) async {
    celular(t);
    final f = combatente();
    await abrir(t, f);
    final regra = f.pvMax;
    await lapis(t, 'Recursos');
    await t.enterText(
      find.byKey(ValueKey('max-pv-false-$regra')),
      '${regra + 1}',
    );
    await t.tap(find.byKey(const ValueKey('salvar-Recursos')));
    await t.pumpAndSettle();
    expect(f.pvMax, regra + 1);
    expect(f.pvMaxCalculado(), regra);
    expect(find.textContaining('ajustado pela história'), findsOneWidget);
  });

  testWidgets('Ignorar esconde o painel; o ícone mostra de novo', (t) async {
    celular(t);
    final f = combatente()..nex = 20;
    await abrir(t, f);
    expect(find.textContaining('ponto(s) para distribuir'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('ignorar-pendencias')));
    await t.pumpAndSettle();
    expect(find.textContaining('ponto(s) para distribuir'), findsNothing);
    expect(f.pendenciasIgnoradas, contains('attr-pontos'));
    // O ícone continua na barra.
    expect(find.byKey(const ValueKey('icone-pendencias')), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('icone-pendencias')));
    await t.pumpAndSettle();
    expect(find.textContaining('ponto(s) para distribuir'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('reativar-pendencias')));
    await t.pumpAndSettle();
    expect(f.pendenciasIgnoradas, isEmpty);
    expect(find.byKey(const ValueKey('ignorar-pendencias')), findsOneWidget);
  });

  testWidgets('pendência nova reabre o painel ignorado', (t) async {
    celular(t);
    final f = combatente()..nex = 20;
    await abrir(t, f);
    await t.tap(find.byKey(const ValueKey('ignorar-pendencias')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('ignorar-pendencias')), findsNothing);

    // Treinar perícia demais cria uma pendência que não estava ignorada.
    await t.tap(find.byKey(const ValueKey('editar-Atributos')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('atributo-INT')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('atributo-INT')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('ignorar-pendencias')), findsOneWidget);
  });

  testWidgets('liga modificação na arma; categoria e item acompanham', (
    t,
  ) async {
    celular(t);
    final f = combatente();
    f.adicionarEm('ataques', {
      'nome': 'Katana',
      'arma': 'Katana',
      'pericia': 'Luta',
      'dano': '1d10',
      'margem': '19',
      'critico': 'x2',
      'familia': 'Armas Táticas',
      'uso': 'Corpo a Corpo – Duas Mãos',
      'categoria': 'I',
      'espacos': '2',
      'itemId': 'k1',
    });
    f.adicionarEm('inventario', {
      'id': 'k1',
      'nome': 'Katana',
      'categoria': 'I',
      'espacos': 2,
    });
    await abrir(t, f);
    await aba(t, 'Ataques');
    expect(find.byKey(const ValueKey('melhorias-0')), findsNothing);
    await lapis(t, 'Ataques');
    await t.tap(find.byKey(const ValueKey('melhorias-0')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('melhoria-Certeira')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('melhoria-Lancinante')));
    await t.pumpAndSettle();
    expect(find.text('Categoria I → IV · amaldiçoada'), findsOneWidget);
    // Morte oprime Sangue: Erosiva fica travada.
    expect(
      t
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('melhoria-Erosiva')),
          )
          .onChanged,
      isNull,
    );
    expect(f.ataques.first['modificacoes'], ['Certeira']);
    expect(f.inventario.first['categoria'], 'IV');
    expect(f.inventario.first['amaldicoado'], isTrue);
  });

  testWidgets('proficiência se escolhe, não se digita', (t) async {
    celular(t);
    final f = combatente()..proficiencias = ['Armas simples'];
    await abrir(t, f);
    await aba(t, 'Sobre');
    expect(find.byIcon(Icons.cancel_outlined), findsWidgets);
    await lapis(t, 'Proficiências');
    expect(find.byType(TextField), findsNothing);
    await t.tap(find.byKey(const ValueKey('prof-Armas táticas')));
    await t.pumpAndSettle();
    expect(f.proficiente('Armas táticas'), isTrue);
    await t.tap(find.byKey(const ValueKey('prof-Armas táticas')));
    await t.pumpAndSettle();
    expect(f.proficiente('Armas táticas'), isFalse);
  });

  testWidgets('ritual acima do círculo fica avisando na ficha', (t) async {
    celular(t);
    final f = FichaOP.nova('oc-circulo')
      ..nome = 'Ocultista'
      ..classe = 'Ocultista'
      ..nex = 5;
    f.adicionarEm('rituais', {
      'nome': 'Ritual Alto',
      'elemento': 'Sangue',
      'circulo': '3º',
      'custo': '6 PE',
      'efeito': 'Efeito.',
      'ampliacoes': [
        {'nome': 'Discente', 'custo': 3, 'efeito': 'Mais.'},
      ],
    });
    await abrir(t, f);
    await aba(t, 'Poderes');
    expect(
      find.textContaining('3º círculo: em NEX 5% o máximo é o 1º'),
      findsOneWidget,
    );
    expect(find.text('Mais.'), findsNothing);
    await t.tap(find.byKey(const ValueKey('formas-0')));
    await t.pumpAndSettle();
    expect(find.text('Mais.'), findsOneWidget);
    expect(find.textContaining('total 9 PE'), findsOneWidget);
  });

  testWidgets('rituais da ficha separados por círculo ou elemento', (t) async {
    celular(t);
    final f = FichaOP.nova('oc-grupos')
      ..nome = 'Ocultista'
      ..classe = 'Ocultista'
      ..nex = 25;
    for (final (nome, el, c) in [
      ('A', 'Sangue', '1º'),
      ('B', 'Morte', '1º'),
      ('C', 'Sangue', '2º'),
    ]) {
      f.adicionarEm('rituais', {
        'nome': nome,
        'elemento': el,
        'circulo': c,
        'custo': '1 PE',
        'efeito': 'x',
      });
    }
    await abrir(t, f);
    await aba(t, 'Poderes');
    expect(find.text('1º CÍRCULO · 2'), findsOneWidget);
    expect(find.text('2º CÍRCULO · 1'), findsOneWidget);
    await t.tap(find.text('Por elemento'));
    await t.pumpAndSettle();
    expect(find.text('SANGUE · 2'), findsOneWidget);
    expect(find.text('MORTE · 1'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('filtro-ritual-Morte')));
    await t.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    expect(find.text('A'), findsNothing);
  });

  testWidgets('poder além do NEX fica avisando na ficha', (t) async {
    celular(t);
    final f = combatente(); // NEX 5%: nenhum poder de combatente ainda
    f.adicionarEm('habilidades', {
      'nome': 'Poder qualquer',
      'tipoPoder': 'classe',
      'descricao': 'x',
    });
    await abrir(t, f);
    await aba(t, 'Poderes');
    expect(find.textContaining('A mais: em NEX 5%'), findsOneWidget);
  });

  testWidgets('condição antiga gravada não mexe mais na Defesa', (t) async {
    final f = combatente();
    final antes = f.defesa;
    f.condicoes = ['Vulnerável'];
    expect(f.defesa, antes);
  });

  testWidgets('poder do catálogo entra com efeito', (t) async {
    celular(t);
    final f = combatente()..nex = 15;
    await abrir(t, f);
    await aba(t, 'Poderes');
    await lapis(t, 'Habilidades e poderes');
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
    // Cartão novo: custo e elemento à vista, Conjurar sem precisar abrir.
    expect(find.text('1 PE'), findsOneWidget);
    expect(find.text('Medo'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('conjurar-0')));
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
    expect(find.text('19–20 no d20 · dano ×3'), findsOneWidget);
    expect(find.text('6d10'), findsOneWidget);
    await aba(t, 'Sobre');
    expect(find.text('Regras opcionais'.toUpperCase()), findsOneWidget);
  });
}
