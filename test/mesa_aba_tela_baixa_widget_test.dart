import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ordem_paranormal/mesa/mesa_service.dart';
import 'package:ordem_paranormal/mesa/mesa_store.dart';
import 'package:ordem_paranormal/mesa/telas/mesa_aba.dart';
import 'package:ordem_paranormal/theme.dart';

class _MesaFalsa implements MesaService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// No Safari do iPhone 13 a barra do app, a faixa da licença, a capa e a
/// barra de abas deixam uns 270px para a aba Mesa. A tela "sem mesa" não
/// rolava: "Entrar com código" ficava cortado e não havia como alcançá-lo.
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('mesa_aba').path);
    await Hive.openBox<String>(MesaStore.boxName);
  });

  testWidgets('sem mesa, numa tela baixa, dá para rolar até entrar', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 664);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: Scaffold(
          body: Column(
            children: [
              const SizedBox(height: 394),
              Expanded(child: MesaAba(servico: _MesaFalsa())),
            ],
          ),
        ),
      ),
    );

    final entrar = find.text('Entrar com código');
    await t.scrollUntilVisible(entrar, 50);
    await t.tap(entrar);
    await t.pumpAndSettle();
    expect(find.text('Código da mesa'), findsOneWidget);
  });
}
