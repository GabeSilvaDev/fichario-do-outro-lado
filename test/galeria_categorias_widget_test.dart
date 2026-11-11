import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_paranormal/mesa/mesa_service.dart';
import 'package:ordem_paranormal/mesa/telas/galeria_mesa.dart';
import 'package:ordem_paranormal/theme.dart';

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

class _MesaFalsa implements MesaService {
  final galeria = StreamController<List<ItemGaleria>>.broadcast();
  final mudancas = <(String, CategoriaGaleria)>[];

  @override
  Stream<List<ItemGaleria>> observarGaleria(String mesaId) => galeria.stream;

  @override
  Future<void> mudarCategoria(
    String mesaId,
    String imagemId,
    CategoriaGaleria categoria,
  ) async => mudancas.add((imagemId, categoria));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ItemGaleria _item(String id, String legenda, CategoriaGaleria c) => ItemGaleria(
  id: id,
  legenda: legenda,
  porUid: 'm',
  miniaturaBase64: _png,
  em: DateTime(2026),
  categoria: c,
);

void main() {
  testWidgets('galeria separa por categoria e o mestre troca a gaveta', (
    t,
  ) async {
    t.view.physicalSize = const Size(1080, 4000);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);
    final mesa = _MesaFalsa();
    await t.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: GaleriaMesa(servico: mesa, mesaId: 'm', souMestre: true),
          ),
        ),
      ),
    );
    mesa.galeria.add([
      _item('a', 'Cultista', CategoriaGaleria.monstro),
      _item('b', 'Nádia', CategoriaGaleria.npc),
      _item('c', 'Diário', CategoriaGaleria.documento),
      _item('d', 'Antiga', CategoriaGaleria.outro),
    ]);
    await t.pumpAndSettle();

    expect(find.text('Todas · 4'), findsOneWidget);
    expect(find.text('Monstros · 1'), findsWidgets);
    expect(find.text('Cultista'), findsOneWidget);
    expect(find.text('Nádia'), findsOneWidget);

    await t.ensureVisible(find.byKey(const ValueKey('galeria-npc')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('galeria-npc')));
    await t.pumpAndSettle();
    expect(find.text('Nádia'), findsOneWidget);
    expect(find.text('Cultista'), findsNothing);

    await t.tap(find.byKey(const ValueKey('categoria-b')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('mover-documento')));
    await t.pumpAndSettle();
    expect(mesa.mudancas.single, ('b', CategoriaGaleria.documento));
    await mesa.galeria.close();
  });
}
