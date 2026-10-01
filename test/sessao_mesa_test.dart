import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ordem_paranormal/data/dados_op.dart';
import 'package:ordem_paranormal/mesa/mesa_service.dart';
import 'package:ordem_paranormal/mesa/mesa_store.dart';
import 'package:ordem_paranormal/mesa/modelos.dart';
import 'package:ordem_paranormal/mesa/ponte_rolagens.dart';
import 'package:ordem_paranormal/mesa/sessao_mesa.dart';
import 'package:ordem_paranormal/models/ficha_op.dart';
import 'package:ordem_paranormal/store/ficha_store.dart';

/// Mesa de mentira que só anota o que o app mandou.
class _MesaFalsa implements MesaService {
  final publicadas = <Map<String, dynamic>>[];
  var pontos = 0;

  @override
  String? get uid => 'eu';

  @override
  Future<String> entrarAnonimo() async => 'eu';

  @override
  Future<void> baterPonto(String mesaId) async => pontos++;

  @override
  Future<void> publicarFicha(
    String mesaId,
    Map<String, dynamic> ficha,
    String nome,
  ) async => publicadas.add(Map.of(ficha));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// O espelho vivia na aba Mesa e morria ao trocar de aba: o mestre via a
/// ficha congelada. Agora segue o estado salvo, em qualquer tela.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _MesaFalsa mesa;

  setUpAll(() async {
    await DadosOP.carregar();
    Hive.init(Directory.systemTemp.createTempSync('sessao').path);
    await Hive.openBox<String>(FichaStore.boxName);
    await Hive.openBox<String>(MesaStore.boxName);
  });

  setUp(() {
    mesa = _MesaFalsa();
    PonteRolagens.servico = mesa;
    SessaoMesa.reiniciarParaTeste();
  });

  tearDown(() async {
    SessaoMesa.reiniciarParaTeste();
    await MesaStore.limpar();
  });

  Future<void> esperarEspelho() =>
      Future<void>.delayed(const Duration(milliseconds: 2300));

  test('edição feita fora da aba Mesa chega ao mestre', () async {
    final f = FichaOP.nova('minha')
      ..nome = 'Agente'
      ..classe = 'Combatente'
      ..nex = 5;
    f.pv = f.pvMax;
    await FichaStore.salvar(f);
    await MesaStore.entrar(
      const EstadoMesa(
        mesaId: 'm1',
        nome: 'Mesa',
        uid: 'eu',
        papel: PapelMesa.jogador,
        fichaPublicadaId: 'minha',
      ),
    );

    SessaoMesa.iniciar();
    await esperarEspelho();
    // Ao ligar, sobe o estado atual (pode ter mudado com o app fechado).
    expect(mesa.publicadas, hasLength(1));
    expect(mesa.pontos, greaterThanOrEqualTo(1));

    // Nenhuma tela da mesa aberta: só a ficha, salvando.
    f.pv = 3;
    await FichaStore.salvar(f);
    f.pv = 2;
    await FichaStore.salvar(f);
    await esperarEspelho();
    expect(mesa.publicadas, hasLength(2), reason: 'rajada vira uma escrita');
    expect(mesa.publicadas.last['pv'], 2);
  });

  test('sair da mesa desliga o espelho', () async {
    final f = FichaOP.nova('outra')..nome = 'B';
    await FichaStore.salvar(f);
    await MesaStore.entrar(
      const EstadoMesa(
        mesaId: 'm2',
        nome: 'Mesa',
        uid: 'eu',
        papel: PapelMesa.jogador,
        fichaPublicadaId: 'outra',
      ),
    );
    SessaoMesa.iniciar();
    await esperarEspelho();
    final antes = mesa.publicadas.length;

    await MesaStore.limpar();
    await Future<void>.delayed(Duration.zero);
    f.nome = 'Mudou';
    await FichaStore.salvar(f);
    await esperarEspelho();
    expect(mesa.publicadas, hasLength(antes));
  });
}
