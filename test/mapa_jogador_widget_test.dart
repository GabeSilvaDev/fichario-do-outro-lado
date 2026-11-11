import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_paranormal/mesa/mesa_service.dart';
import 'package:ordem_paranormal/mesa/telas/mapa_da_cena.dart';
import 'package:ordem_paranormal/theme.dart';

/// PNG 1x1 transparente: só para o mapa ter imagem.
const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

class _MesaFalsa implements MesaService {
  final mapa = StreamController<MapaMesa?>.broadcast();
  final movidas = <TokenMapa>[];

  @override
  String? get uid => 'eu';

  @override
  Stream<MapaMesa?> observarMapa(String mesaId) => mapa.stream;

  @override
  Future<String?> imagemDeMapa(String mesaId, String imagemId) async => _png;

  @override
  Future<void> moverMinhaPeca(String mesaId, TokenMapa peca) async =>
      movidas.add(peca);

  @override
  Future<void> salvarPeca(String mesaId, TokenMapa peca) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('jogador arrasta só a própria peça', (t) async {
    t.view.physicalSize = const Size(1080, 1920);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);
    final mesa = _MesaFalsa();
    await t.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: Scaffold(
          body: MapaDaCena(servico: mesa, mesaId: 'm', mestre: false),
        ),
      ),
    );
    mesa.mapa.add(
      MapaMesa(
        imagemId: 'i',
        titulo: 'Sala',
        em: DateTime(2026),
        tokens: const [
          TokenMapa(id: 'eu', nome: 'Asafe', cor: 0xFFA06BFF, x: .3, y: .5),
          TokenMapa(id: 'outro', nome: 'Bia', cor: 0xFF57B98A, x: .7, y: .5),
        ],
      ),
    );
    await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
    await t.pump();
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await t.pump();
    expect(base64Decode(_png), isNotEmpty);

    // Sem foto: a peça mostra a inicial.
    expect(find.text('A'), findsOneWidget);
    Future<void> arrastar(Finder f) async {
      final g = await t.startGesture(t.getCenter(f));
      for (var i = 0; i < 6; i++) {
        await g.moveBy(const Offset(10, 0));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await t.pump(const Duration(milliseconds: 200));
    }

    await arrastar(find.text('A'));
    await arrastar(find.text('B'));
    expect(mesa.movidas, isNotEmpty);
    expect(mesa.movidas.every((p) => p.id == 'eu'), isTrue);
    expect(mesa.movidas.last.x, greaterThan(.3));
    await mesa.mapa.close();
  });
}
