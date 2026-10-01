import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_paranormal/data/dados_op.dart';
import 'package:ordem_paranormal/mesa/mesa_service.dart';
import 'package:ordem_paranormal/mesa/telas/painel_mestre.dart';
import 'package:ordem_paranormal/models/ficha_op.dart';
import 'package:ordem_paranormal/theme.dart';
import 'package:ordem_paranormal/widgets/recurso_contador.dart';

/// Mesa de mentira: só as fichas, empurradas à mão pelo teste.
class _MesaFalsa implements MesaService {
  final fichas = StreamController<List<FichaNaMesa>>.broadcast();
  final umaFicha = StreamController<FichaNaMesa?>.broadcast();

  @override
  Stream<List<FichaNaMesa>> observarFichas(String mesaId) => fichas.stream;

  @override
  Stream<FichaNaMesa?> observarFicha(String mesaId, String donoUid) =>
      umaFicha.stream;

  @override
  Stream<List<RolagemNaMesa>> observarRolagens(
    String mesaId, {
    int limite = 30,
  }) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

FichaNaMesa _publicada(int pv) {
  final f = FichaOP.nova('j1')
    ..nome = 'Jogadora'
    ..classe = 'Combatente'
    ..nex = 5;
  f.definirAtributo('VIG', 2);
  f.pv = pv;
  return FichaNaMesa(
    donoUid: 'uid-1',
    nome: f.nome,
    atualizadaEm: DateTime.now(),
    ficha: f.dados,
  );
}

void main() {
  testWidgets('mestre vê a ficha aberta mudar sem reabrir', (t) async {
    await DadosOP.carregar();
    t.view.physicalSize = const Size(1080, 8000);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);

    final mesa = _MesaFalsa();
    await t.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PainelMestre(servico: mesa, mesaId: 'm1'),
          ),
        ),
      ),
    );
    mesa.fichas.add([_publicada(22)]);
    await t.pumpAndSettle();
    expect(find.text('PV 22/22'), findsOneWidget);

    // Painel ao vivo.
    mesa.fichas.add([_publicada(10)]);
    await t.pumpAndSettle();
    expect(find.text('PV 10/22'), findsOneWidget);

    // Ficha aberta ao vivo.
    await t.tap(find.text('Jogadora'));
    await t.pumpAndSettle();
    int vida() =>
        t.widget<RecursoContador>(find.byType(RecursoContador).first).atual;
    expect(vida(), 10);
    mesa.umaFicha.add(_publicada(3));
    await t.pumpAndSettle();
    expect(vida(), 3);
    expect(find.text('Machucado'), findsOneWidget);
  });
}
