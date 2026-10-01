import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_paranormal/data/dados_op.dart';
import 'package:ordem_paranormal/models/ficha_op.dart';

/// O que muda quando o agente sobe de NEX, e o teto dos recursos.
void main() {
  final combatente = DadosOP.classePorNome('Combatente')!;
  final especialista = DadosOP.classePorNome('Especialista')!;
  final ocultista = DadosOP.classePorNome('Ocultista')!;
  final mundano = DadosOP.classePorNome('Mundano')!;
  final sobrevivente = DadosOP.classePorNome('Sobrevivente')!;

  FichaOP agente(String classe, int nex, [Map<String, int> attrs = const {}]) {
    final f = FichaOP.nova('x')..classe = classe;
    f.nex = nex;
    attrs.forEach(f.definirAtributo);
    f.pv = f.pvMax;
    f.san = f.sanMax;
    f.pe = f.peMax;
    return f;
  }

  group('recurso atual não passa do máximo', () {
    test('vida cheia + 3 continua cheia', () {
      final f = agente('Combatente', 5, {'VIG': 1});
      expect(f.pvMax, 21);
      f.pv = f.pv + 3;
      expect(f.pv, 21);
      f.san = f.sanMax + 10;
      expect(f.san, f.sanMax);
      f.pe = f.peMax + 5;
      expect(f.pe, f.peMax);
    });

    test('nunca abaixo de zero', () {
      final f = agente('Combatente', 5);
      f.pv = -4;
      expect(f.pv, 0);
    });

    test('máximo fixado na mão também é teto', () {
      final f = agente('Combatente', 5, {'VIG': 1});
      f.definirMaxManual('pv', 10);
      expect(f.pv, 10);
      f.pv = 30;
      expect(f.pv, 10);
    });

    test('classe fora da lista não trava a vida', () {
      final f = FichaOP.nova('x')..dados['classe'] = 'Inventada';
      f.pv = 40;
      expect(f.pv, 40);
    });
  });

  group('PV temporários', () {
    test('começam em zero e não ficam negativos', () {
      final f = agente('Combatente', 5);
      expect(f.pvTemporario, 0);
      f.pvTemporario = -2;
      expect(f.pvTemporario, 0);
    });

    test('dano tira primeiro dos temporários', () {
      final f = agente('Combatente', 5, {'VIG': 1});
      f.pvTemporario = 3;
      f.sofrerDano(2);
      expect(f.pvTemporario, 1);
      expect(f.pv, 21);
      f.sofrerDano(4);
      expect(f.pvTemporario, 0);
      expect(f.pv, 18);
    });
  });

  group('máximo que muda leva o atual junto', () {
    test('NEX 5% → 15% de vida cheia: atributos iguais, vida cheia', () {
      final f = agente('Combatente', 5, {'AGI': 2, 'FOR': 2, 'VIG': 2});
      final atributos = [
        for (final s in ['AGI', 'FOR', 'INT', 'PRE', 'VIG']) f.atributo(s),
      ];
      f.nex = 15;
      expect([
        for (final s in ['AGI', 'FOR', 'INT', 'PRE', 'VIG']) f.atributo(s),
      ], atributos);
      expect(f.pvMax, 34);
      expect(f.pv, 34);
      expect(f.san, f.sanMax);
      expect(f.pe, f.peMax);
    });

    test('ferido ganha o mesmo tanto que o máximo ganhou', () {
      final f = agente('Combatente', 5, {'VIG': 2});
      f.pv = 10;
      f.nex = 10;
      expect(f.pvMax, 28);
      expect(f.pv, 16);
    });

    test('NEX que desce corta o que sobrou', () {
      final f = agente('Combatente', 50, {'VIG': 3});
      f.nex = 5;
      expect(f.pv, f.pvMax);
      expect(f.pv, 23);
    });

    test('Vigor que desce corta a vida', () {
      final f = agente('Ocultista', 20, {'VIG': 3});
      f.definirAtributo('VIG', 1);
      expect(f.pv, f.pvMax);
    });

    test('Vigor que sobe soma na vida', () {
      final f = agente('Ocultista', 20, {'VIG': 1});
      f.pv = 5;
      final antes = f.pvMax;
      f.definirAtributo('VIG', 2);
      expect(f.pv, 5 + f.pvMax - antes);
    });

    test('ir e voltar na régua não cura', () {
      final f = agente('Combatente', 50, {'VIG': 3});
      f.pv = 10;
      f.nex = 0;
      f.nex = 50;
      expect(f.pv, 10);
      f.nex = 55;
      f.nex = 50;
      expect(f.pv, 10);
    });

    test('ciclar o Vigor não cura', () {
      final f = agente('Combatente', 50, {'VIG': 3});
      f.pv = 10;
      for (final v in [4, 5, 0, 1, 2, 3]) {
        f.definirAtributo('VIG', v);
      }
      expect(f.pv, 10);
    });

    test('ficha importada acima do máximo volta ao máximo', () {
      final f = agente('Combatente', 5, {'VIG': 1});
      f.dados['pv'] = 90;
      f.nex = 10;
      expect(f.pv, f.pvMax);
    });

    test('estágio do sobrevivente também', () {
      final f = agente('Sobrevivente', 0, {'VIG': 1});
      f.estagio = 3;
      expect(f.pv, f.pvMax);
    });
  });

  group('Aumento de Atributo', () {
    test('NEX 20%, 50%, 80% e 95%', () {
      expect(ocultista.aumentosAtributo(15), 0);
      expect(ocultista.aumentosAtributo(20), 1);
      expect(ocultista.aumentosAtributo(65), 2);
      expect(ocultista.aumentosAtributo(80), 3);
      expect(ocultista.aumentosAtributo(99), 4);
    });

    test('sobrevivente ganha o dele no estágio 3; mundano nenhum', () {
      expect(sobrevivente.aumentosAtributo(0, estagio: 2), 0);
      expect(sobrevivente.aumentosAtributo(0, estagio: 3), 1);
      expect(mundano.aumentosAtributo(0), 0);
    });
  });

  group('Grau de Treinamento', () {
    test('NEX 35% e 70%', () {
      expect(ocultista.grausTreinamento(30), 0);
      expect(ocultista.grausTreinamento(35), 1);
      expect(ocultista.grausTreinamento(65), 1);
      expect(ocultista.grausTreinamento(70), 2);
      expect(mundano.grausTreinamento(0), 0);
    });

    test(
      'perícias por grau: combatente 2, especialista 5, ocultista 3 (+ Int)',
      () {
        expect(combatente.periciasPorGrau, 2);
        expect(especialista.periciasPorGrau, 5);
        expect(ocultista.periciasPorGrau, 3);
      },
    );
  });

  group('marcos de NEX', () {
    test('o que cada NEX dá', () {
      expect(
        combatente.marcos(20),
        contains(startsWith('Aumento de Atributo')),
      );
      expect(combatente.marcos(15), contains('Poder de combatente'));
      expect(combatente.marcos(10), contains(startsWith('Trilha')));
      expect(
        combatente.marcos(35),
        contains(startsWith('Grau de Treinamento')),
      );
      expect(combatente.marcos(50), contains(startsWith('Versatilidade')));
      expect(combatente.marcos(50), contains(startsWith('Afinidade')));
      expect(
        ocultista.marcos(25),
        contains(startsWith('Rituais de 2º círculo')),
      );
      expect(ocultista.marcos(10), contains('+1 ritual'));
      expect(ocultista.marcos(99), contains('+1 ritual'));
      expect(mundano.marcos(20), isEmpty);
      expect(especialista.marcos(40), contains(startsWith('Engenhosidade')));
      expect(especialista.marcos(75), contains(startsWith('Engenhosidade')));
      expect(especialista.marcos(75), contains('Poder de especialista'));
    });

    test('entre dois NEX, na ordem', () {
      final m = combatente.marcosEntre(5, 20);
      expect(m.keys, [10, 15, 20]);
      expect(combatente.marcosEntre(20, 5), isEmpty);
      expect(combatente.marcosEntre(95, 99).keys, [99]);
    });

    test('próximo marco', () {
      expect(combatente.proximoMarco(5), 10);
      expect(combatente.proximoMarco(95), 99);
      expect(combatente.proximoMarco(99), isNull);
    });
  });
}
