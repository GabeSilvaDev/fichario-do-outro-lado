import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_paranormal/mesa/mesa_service.dart';
import 'package:ordem_paranormal/mesa/telas/mapa_da_cena.dart';
import 'package:ordem_paranormal/theme.dart';

/// O mapa da cena. O que está travado aqui é o que faz a peça cair no mesmo
/// lugar em todos os aparelhos — o resto da tela é desenho.
void main() {
  TokenMapa peca({String nome = 'Márcia', double x = .5, double y = .5}) =>
      TokenMapa(id: 'u1', nome: nome, cor: 0xFFA06BFF, x: x, y: y);

  group('inicial da peça', () {
    test('é a primeira letra, maiúscula', () {
      expect(peca(nome: 'márcia').inicial, 'M');
    });

    test('peça sem nome não fica sem marca', () {
      expect(peca(nome: '   ').inicial, '?');
    });

    test('nome que começa fora do BMP não vira meio caractere', () {
      final t = peca(nome: '🜏 Entidade');
      expect(t.inicial.runes.length, 1);
      expect(t.inicial, '🜏');
    });
  });

  group('mover', () {
    test('a peça nunca sai da imagem', () {
      final t = peca().mover(1.8, -0.4);
      expect(t.x, 1.0);
      expect(t.y, 0.0);
    });

    test('mover preserva o resto da peça', () {
      final t = TokenMapa(
        id: 'npc:1',
        nome: 'Cultista',
        retrato: 'AAA',
        cor: 0xFFE05545,
        x: .1,
        y: .1,
        inimigo: true,
      ).mover(.9, .2);
      expect(t.id, 'npc:1');
      expect(t.retrato, 'AAA');
      expect(t.inimigo, isTrue);
      expect(t.cor, 0xFFE05545);
    });
  });

  group('ida e volta pelo JSON', () {
    test('o mapa inteiro sobrevive', () {
      final antes = MapaMesa(
        imagemId: 'img1',
        titulo: 'Vagão 3',
        tokens: [peca(nome: 'Ana', x: .2, y: .3), peca(nome: 'Bia')],
        em: DateTime.parse('2026-08-19T02:00:00.000'),
      );
      final depois = MapaMesa.fromJson(antes.toJson());
      expect(depois.imagemId, 'img1');
      expect(depois.titulo, 'Vagão 3');
      expect(depois.tokens.length, 2);
      expect(depois.tokens.first.nome, 'Ana');
      expect(depois.tokens.first.x, closeTo(.2, 1e-9));
      expect(depois.em, antes.em);
    });

    test('documento antigo, sem peças, não quebra a tela', () {
      final m = MapaMesa.fromJson({
        'imagemId': 'img',
        'em': '2026-08-19T02:00:00.000',
      });
      expect(m.tokens, isEmpty);
      expect(m.titulo, '');
    });

    test('posição fora da faixa chega presa na borda', () {
      final t = TokenMapa.fromJson(
          {'id': 'x', 'nome': 'n', 'cor': 1, 'x': 4.0, 'y': -2.0});
      expect(t.x, 1.0);
      expect(t.y, 0.0);
    });
  });

  group('tamanho da peça', () {
    test('a escala nasce em 1 e o JSON leva junto', () {
      expect(peca().escala, 1.0);
      final t = TokenMapa.fromJson(peca().comEscala(2.5).toJson());
      expect(t.escala, 2.5);
    });

    test('escala presa entre 0,4× e 3×', () {
      expect(peca().comEscala(9).escala, 3.0);
      expect(peca().comEscala(0.1).escala, 0.4);
    });

    test('ficha antiga, sem escala, entra em 1', () {
      final t = TokenMapa.fromJson(
          {'id': 'x', 'nome': 'n', 'cor': 1, 'x': .5, 'y': .5});
      expect(t.escala, 1.0);
    });

    test('mudar tamanho não move nem descolore a peça', () {
      final t = TokenMapa(
        id: 'u1', nome: 'Ana', retrato: 'AAA', cor: 0xFF112233,
        x: .2, y: .3, inimigo: true,
      ).comEscala(1.8);
      expect(t.x, .2);
      expect(t.y, .3);
      expect(t.retrato, 'AAA');
      expect(t.cor, 0xFF112233);
      expect(t.inimigo, isTrue);
    });
  });

  group('planta guardada', () {
    test('ida e volta pelo JSON', () {
      final antes = ImagemDeMapa(
        id: 'p1',
        nome: 'Vagão 3',
        miniaturaBase64: 'AAA',
        em: DateTime.parse('2026-08-19T12:00:00.000'),
      );
      final depois = ImagemDeMapa.fromJson('p1', antes.toJson());
      expect(depois.nome, 'Vagão 3');
      expect(depois.miniaturaBase64, 'AAA');
      expect(depois.em, antes.em);
    });
  });

  group('cor da peça', () {
    test('ameaça é sempre vermelha', () {
      expect(corDaPeca('Qualquer', inimigo: true), Cores.sangue.toARGB32());
    });

    test('o mesmo agente tem sempre a mesma cor', () {
      expect(corDaPeca('Márcia Nogueira', inimigo: false),
          corDaPeca('Márcia Nogueira', inimigo: false));
    });

    test('agente não recebe a cor de ameaça', () {
      for (final nome in ['Ana', 'Bia', 'Caio', 'Duda', 'Edu', 'Fê', 'Gu']) {
        expect(corDaPeca(nome, inimigo: false),
            isNot(Cores.sangue.toARGB32()));
      }
    });
  });
}
