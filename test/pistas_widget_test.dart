import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_paranormal/mesa/mesa_service.dart';
import 'package:ordem_paranormal/mesa/modelos.dart';
import 'package:ordem_paranormal/mesa/telas/galeria_mesa.dart';
import 'package:ordem_paranormal/mesa/telas/pistas_mesa.dart';
import 'package:ordem_paranormal/theme.dart';

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

class _MesaFalsa implements MesaService {
  _MesaFalsa(this.uid);

  @override
  final String? uid;

  final galeria = StreamController<List<ItemGaleria>>.broadcast();
  final pistas = StreamController<List<Pista>>.broadcast();
  final membros = StreamController<List<Membro>>.broadcast();
  List<Membro> ultimosMembros = const [];
  final entregas = <(String, List<String>)>[];
  final repasses = <(String, RepasseDePista)>[];

  @override
  Stream<List<ItemGaleria>> observarGaleria(String mesaId) => galeria.stream;

  @override
  Stream<List<Pista>> observarPistas(String mesaId, {required bool mestre}) =>
      pistas.stream;

  @override
  Stream<List<Membro>> observarMembros(String mesaId) async* {
    yield ultimosMembros;
    yield* membros.stream;
  }

  @override
  Future<void> entregarPista(
    String mesaId,
    ItemGaleria imagem,
    List<String> uids,
  ) async => entregas.add((imagem.id, uids));

  @override
  Future<void> repassarPista(
    String mesaId,
    String pistaId,
    RepasseDePista repasse,
  ) async => repasses.add((pistaId, repasse));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Membro _membro(String uid, String nome, {bool mestre = false}) => Membro(
  uid: uid,
  nome: nome,
  papel: mestre ? PapelMesa.mestre : PapelMesa.jogador,
  entrouEm: DateTime(2026),
  visto: DateTime(2026),
);

ItemGaleria _item(String id, String legenda, {bool mostrada = true}) =>
    ItemGaleria(
      id: id,
      legenda: legenda,
      porUid: 'm',
      miniaturaBase64: _png,
      em: DateTime(2026),
      categoria: CategoriaGaleria.documento,
      mostrada: mostrada,
    );

Future<void> _montar(WidgetTester t, Widget filho) async {
  t.view.physicalSize = const Size(1080, 4000);
  t.view.devicePixelRatio = 2.625;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: construirTema(),
      home: Scaffold(body: SingleChildScrollView(child: filho)),
    ),
  );
}

void main() {
  final todos = [
    _membro('mestre', 'Mestre', mestre: true),
    _membro('u1', 'Asafe'),
    _membro('u2', 'Umê'),
    _membro('u3', 'Torvi'),
  ];

  testWidgets('jogador só vê na galeria o que o mestre já mostrou', (t) async {
    final mesa = _MesaFalsa('u1');
    await _montar(t, GaleriaMesa(servico: mesa, mesaId: 'm', souMestre: false));
    mesa.galeria.add([
      _item('a', 'Mostrado'),
      _item('b', 'Guardado', mostrada: false),
    ]);
    await t.pumpAndSettle();
    expect(find.text('Mostrado'), findsOneWidget);
    expect(find.text('Guardado'), findsNothing);
  });

  testWidgets('mestre entrega pista só aos jogadores escolhidos', (t) async {
    final mesa = _MesaFalsa('mestre')..ultimosMembros = todos;
    await _montar(t, GaleriaMesa(servico: mesa, mesaId: 'm', souMestre: true));
    mesa.galeria.add([_item('a', 'Diário', mostrada: false)]);
    await t.pumpAndSettle();
    // O mestre vê a guardada.
    expect(find.text('Diário'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('pista-a')));
    await t.pumpAndSettle();
    // O mestre não aparece na lista: ele vê tudo.
    expect(find.byKey(const ValueKey('jogador-mestre')), findsNothing);
    await t.tap(find.byKey(const ValueKey('jogador-u2')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('confirmar-jogadores')));
    await t.pumpAndSettle();
    final (imagem, uids) = mesa.entregas.single;
    expect(imagem, 'a');
    expect(uids, ['u2']);
  });

  testWidgets('jogador repassa a pista; quem já tem vem travado', (t) async {
    final mesa = _MesaFalsa('u1')..ultimosMembros = todos;
    await _montar(
      t,
      PistasDaMesa(servico: mesa, mesaId: 'm', souMestre: false),
    );
    await t.pumpAndSettle();
    mesa.pistas.add([
      Pista(
        id: 'p1',
        legenda: 'Carta',
        miniaturaBase64: _png,
        veem: const ['u1', 'u2'],
        em: DateTime(2026),
      ),
    ]);
    await t.pumpAndSettle();
    expect(find.text('Também com: Umê'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('repassar-p1')));
    await t.pumpAndSettle();
    // Umê já tem: aparece marcada e não desmarca. Eu não apareço.
    expect(find.byKey(const ValueKey('jogador-u1')), findsNothing);
    final ume = t.widget<CheckboxListTile>(
      find.byKey(const ValueKey('jogador-u2')),
    );
    expect(ume.value, isTrue);
    expect(ume.onChanged, isNull);

    await t.tap(find.byKey(const ValueKey('jogador-u3')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('confirmar-jogadores')));
    await t.pumpAndSettle();
    expect(mesa.repasses, hasLength(1));
    final (pista, r) = mesa.repasses.single;
    expect(pista, 'p1');
    expect(r.paraUid, 'u3');
    expect(r.paraNome, 'Torvi');
    expect(r.deNome, 'Asafe');
  });
}
