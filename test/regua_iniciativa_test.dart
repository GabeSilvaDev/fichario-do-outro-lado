import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_paranormal/mesa/mesa_service.dart';
import 'package:ordem_paranormal/mesa/regua.dart';

void main() {
  // Planta de 1000 × 500 px com quadrado de 50 px (5% da largura).
  const imagem = Size(1000, 500);
  const q = .05;

  group('régua', () {
    test('em linha reta conta os quadrados; 1 quadrado = 1,5 m', () {
      final a = const Offset(.1, .5);
      final b = const Offset(.3, .5); // 200 px = 4 quadrados
      expect(Regua.quadrados(a, b, imagem, q), 4);
      expect(Regua.rotulo(a, b, imagem, q), '4 quadrados · 6 m · Curto');
    });

    test('diagonal conta dobrado (p. 89)', () {
      // 3 quadrados para o lado e 3 para baixo: 6 quadrados, 9 m.
      final a = const Offset(.1, .1);
      final b = const Offset(.25, .4);
      expect(Regua.quadrados(a, b, imagem, q), 6);
    });

    test('vizinho, inclusive na diagonal, é corpo a corpo', () {
      final a = const Offset(.5, .5);
      expect(
        Regua.rotulo(a, const Offset(.55, .6), imagem, q),
        'Adjacente · corpo a corpo',
      );
    });

    test('faixas de alcance do livro (p. 54)', () {
      expect(Regua.alcance(6), 'Curto');
      expect(Regua.alcance(7), 'Médio');
      expect(Regua.alcance(12), 'Médio');
      expect(Regua.alcance(24), 'Longo');
      expect(Regua.alcance(60), 'Extremo');
      expect(Regua.alcance(61), 'Além do extremo');
    });

    test('meio metro aparece com vírgula', () {
      final a = const Offset(.1, .5);
      final b = const Offset(.25, .5); // 3 quadrados
      expect(Regua.rotulo(a, b, imagem, q), '3 quadrados · 4,5 m · Curto');
    });

    test('calibrar: linha sobre 4 quadrados dá o lado de um', () {
      final lado = Regua.calibrar(
        const Offset(.1, .5),
        const Offset(.3, .5),
        imagem,
        4,
      );
      expect(lado, closeTo(.05, 1e-9));
      expect(Regua.calibrar(Offset.zero, const Offset(1, 0), imagem, 0), 0);
    });

    test('sem calibragem não mede', () {
      expect(Regua.quadrados(Offset.zero, const Offset(1, 1), imagem, 0), 0);
    });
  });

  group('iniciativa', () {
    const asafe = EntradaIniciativa(id: 'u1', nome: 'Asafe', valor: 14);
    const zumbi = EntradaIniciativa(
      id: 'npc:1',
      nome: 'Zumbi',
      valor: 18,
      inimigo: true,
    );
    const ume = EntradaIniciativa(id: 'u2', nome: 'Umê', valor: 14);

    test('começar ordena do maior e empate mantém a ordem', () {
      final i = const Iniciativa(ordem: [asafe, zumbi, ume]).comecar();
      expect([for (final e in i.ordem) e.nome], ['Zumbi', 'Asafe', 'Umê']);
      expect(i.rodada, 1);
      expect(i.atual?.nome, 'Zumbi');
      expect(i.proximo?.nome, 'Asafe');
    });

    test('próximo turno dá a volta e soma rodada; anterior desfaz', () {
      var i = const Iniciativa(ordem: [zumbi, asafe, ume]).comecar();
      i = i.proximaVez().proximaVez();
      expect(i.atual?.nome, 'Umê');
      i = i.proximaVez();
      expect(i.rodada, 2);
      expect(i.atual?.nome, 'Zumbi');
      i = i.vezAnterior();
      expect(i.rodada, 1);
      expect(i.atual?.nome, 'Umê');
    });

    test('tirar quem está na vez passa para o seguinte', () {
      var i = const Iniciativa(ordem: [zumbi, asafe, ume]).comecar();
      i = i.proximaVez(); // vez do Asafe
      i = i.sem('u1');
      expect(i.atual?.nome, 'Umê');
      i = i.sem('npc:1'); // tirar alguém antes não pula ninguém
      expect(i.atual?.nome, 'Umê');
    });

    test('mudar o valor no meio do combate reordena sem trocar a vez', () {
      var i = const Iniciativa(ordem: [zumbi, asafe, ume]).comecar();
      i = i.proximaVez(); // Asafe
      i = i.com(ume.comValor(30)).ordenada();
      expect(i.ordem.first.nome, 'Umê');
      expect(i.atual?.nome, 'Asafe');
    });

    test('json ida e volta', () {
      final i = const Iniciativa(ordem: [zumbi, asafe]).comecar().proximaVez();
      final volta = Iniciativa.fromJson(i.toJson());
      expect(volta.rodada, 1);
      expect(volta.atual?.nome, 'Asafe');
      expect(volta.ordem.first.inimigo, isTrue);
    });
  });

  test('pista: json com repasses', () {
    final p = Pista(
      id: 'p1',
      legenda: 'Diário',
      miniaturaBase64: '',
      veem: const ['u1', 'u2'],
      repasses: [
        RepasseDePista(
          deUid: 'u1',
          deNome: 'Asafe',
          paraUid: 'u2',
          paraNome: 'Umê',
          em: DateTime(2026, 11, 11),
        ),
      ],
      em: DateTime(2026, 11, 11),
    );
    final volta = Pista.fromJson('p1', p.toJson());
    expect(volta.veem, ['u1', 'u2']);
    expect(volta.repasses.single.paraNome, 'Umê');
  });

  test('PV de combate: cair em 0', () {
    expect(const PvDeCombate(3, 20).somar(-3).caiu, isTrue);
    expect(const PvDeCombate(3, 20).caiu, isFalse);
  });
}
