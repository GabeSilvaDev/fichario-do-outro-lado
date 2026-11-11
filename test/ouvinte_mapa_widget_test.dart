import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_paranormal/mesa/mesa_service.dart';
import 'package:ordem_paranormal/mesa/ouvinte_mapa.dart';
import 'package:ordem_paranormal/mesa/telas/mapa_da_cena.dart';
import 'package:ordem_paranormal/theme.dart';

class _MesaFalsa implements MesaService {
  final mapa = StreamController<MapaMesa?>.broadcast();

  @override
  String? get uid => 'u1';

  @override
  Future<String> entrarAnonimo() async => 'u1';

  @override
  Stream<MapaMesa?> observarMapa(String mesaId) => mapa.stream;

  @override
  Future<String?> imagemDeMapa(String mesaId, String imagemId) async => null;

  @override
  Stream<Iniciativa?> observarIniciativa(String mesaId) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MapaMesa _mapa(String id) =>
    MapaMesa(imagemId: id, titulo: id, tokens: const [], em: DateTime(2026));

void main() {
  testWidgets('mapa novo abre uma tela só, mesmo trocando várias vezes', (
    t,
  ) async {
    final mesa = _MesaFalsa();
    await t.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: OuvinteMapa(
          servico: mesa,
          mesaId: 'm',
          mestre: false,
          child: const Scaffold(body: Text('aba')),
        ),
      ),
    );
    await t.pump();
    mesa.mapa.add(_mapa('a')); // o que já estava: não abre
    await t.pumpAndSettle();
    expect(find.byType(MapaDaCena), findsNothing);

    mesa.mapa.add(_mapa('b'));
    await t.pumpAndSettle();
    expect(find.byType(MapaDaCena), findsOneWidget);

    mesa.mapa.add(_mapa('c'));
    await t.pumpAndSettle();
    mesa.mapa.add(_mapa('d'));
    await t.pumpAndSettle();
    // Continua uma: a tela aberta troca de mapa sozinha.
    expect(find.byType(MapaDaCena, skipOffstage: false), findsOneWidget);

    await t.pageBack();
    await t.pumpAndSettle();
    expect(find.text('aba'), findsOneWidget);
  });
}
