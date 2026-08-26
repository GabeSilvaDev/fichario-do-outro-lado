import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_paranormal/util/texto.dart';

/// O catálogo do sistema: 81 rituais e a tabela de armas.
///
/// Estes testes existem para duas coisas: garantir que a ficha técnica saiu
/// inteira do livro (custo por círculo, execução, alcance) e garantir que o
/// efeito é NOTAÇÃO, não prosa copiada — é o que mantém o app dentro da
/// Licença da Comunidade.
void main() {
  final rituaisJson = jsonDecode(
      File('assets/catalogo/rituais.json').readAsStringSync()) as Map;
  final rituais =
      (rituaisJson['rituais'] as List).cast<Map<String, dynamic>>();

  final armasJson = jsonDecode(
      File('assets/catalogo/armas.json').readAsStringSync()) as Map;
  final armas = (armasJson['armas'] as List).cast<Map<String, dynamic>>();
  final protecoes =
      (armasJson['protecoes'] as List).cast<Map<String, dynamic>>();

  group('rituais', () {
    test('o catálogo inteiro está lá', () {
      expect(rituais.length, greaterThanOrEqualTo(80));
      final elementos = rituais.map((r) => r['elemento']).toSet();
      expect(elementos,
          containsAll(['Sangue', 'Morte', 'Conhecimento', 'Energia', 'Medo']));
    });

    test('nome único por elemento e círculo', () {
      final chaves = rituais
          .map((r) => '${r['elemento']}:${r['circulo']}:${r['nome']}')
          .toList();
      expect(chaves.toSet().length, chaves.length);
    });

    test('custo bate com o círculo (1/3/6/10 PE)', () {
      const tabela = {1: 1, 2: 3, 3: 6, 4: 10};
      for (final r in rituais) {
        expect(r['custo'], tabela[r['circulo']],
            reason: '${r['nome']}: círculo ${r['circulo']}');
      }
    });

    test('ficha técnica completa', () {
      for (final r in rituais) {
        expect((r['nome'] as String).trim(), isNotEmpty);
        expect((r['execucao'] as String).trim(), isNotEmpty,
            reason: '${r['nome']} sem execução');
        expect((r['alcance'] as String).trim(), isNotEmpty,
            reason: '${r['nome']} sem alcance');
        expect((r['duracao'] as String).trim(), isNotEmpty,
            reason: '${r['nome']} sem duração');
        expect(r['pagina'], greaterThan(0), reason: r['nome'] as String);
      }
    });

    test('todo ritual diz o que faz, em notação e não em prosa', () {
      for (final r in rituais) {
        final efeito = (r['efeito'] as String).trim();
        expect(efeito.length, greaterThan(20),
            reason: '${r['nome']}: efeito vazio demais');
        expect(efeito.length, lessThan(700),
            reason: '${r['nome']}: efeito longo demais — virou prosa');
      }
    });

    test('ampliação tem custo e efeito', () {
      for (final r in rituais) {
        for (final a in (r['ampliacoes'] as List).cast<Map>()) {
          expect(a['custo'], greaterThan(0), reason: r['nome'] as String);
          expect((a['efeito'] as String).trim().length, greaterThan(10),
              reason: '${r['nome']}/${a['nome']}');
        }
      }
    });
  });

  group('armas e proteções', () {
    test('a tabela inteira está lá', () {
      expect(armas.length, greaterThanOrEqualTo(40));
      expect(protecoes.length, greaterThanOrEqualTo(3));
    });

    test('cada arma tem nome e linha de tabela', () {
      for (final a in armas) {
        expect((a['nome'] as String).trim(), isNotEmpty);
        // munição não tem dano próprio; arma tem
        final ehMunicao = ['Balas curtas', 'Balas longas', 'Cartuchos',
                'Flechas', 'Foguete', 'Combustível']
            .contains(a['nome']);
        if (!ehMunicao) {
          expect((a['dano'] as String).trim(), isNotEmpty,
              reason: '${a['nome']} sem dano');
        }
      }
    });

    test('sem descrição em prosa do livro', () {
      // o extrator captura a prosa junto; o gerador tem que jogar fora
      for (final a in armas) {
        expect(a.containsKey('desc'), isFalse,
            reason: '${a['nome']} veio com texto de livro');
      }
      for (final p in protecoes) {
        expect(p.containsKey('desc'), isFalse, reason: p['nome'] as String);
      }
    });
  });

  group('ameaça conjuradora', () {
    final bestiario = jsonDecode(
        File('assets/bestiario/bestiario.json').readAsStringSync()) as Map;
    final fichas = [
      for (final g in (bestiario['grupos'] as List))
        for (final f in ((g as Map)['fichas'] as List))
          (f as Map).cast<String, dynamic>()
    ];

    test('nenhum conjurador fica sem a lista de rituais', () {
      final semLista = <String>[];
      for (final f in fichas) {
        final texto = [
          f['anotacoes'] as String,
          for (final h in (f['habilidades'] as List).cast<Map>())
            '${h['nome']} ${h['descricao']}',
        ].join(' ').toLowerCase();
        final falaDeRitual =
            texto.contains('conjur') || texto.contains('ritual');
        if (falaDeRitual && (f['rituais'] as List).isEmpty) {
          semLista.add(f['nome'] as String);
        }
      }
      // sobra só quem cita ritual na narrativa sem conjurar nada
      expect(semLista, ['Turba de Seguidores da Noite'],
          reason: 'ficha que fala em conjurar precisa vir com os rituais');
    });

    test('quem conjura "todos os rituais" tem a lista de verdade', () {
      final conjuradores = fichas.where((f) =>
          (f['rituais'] as List).length >= 10);
      expect(conjuradores.length, greaterThanOrEqualTo(4),
          reason: 'os chefes conjuradores da Villa e o Giordano');
      for (final f in conjuradores) {
        for (final r in (f['rituais'] as List).cast<Map>()) {
          expect((r['nome'] as String).trim(), isNotEmpty);
          expect((r['custo'] as String).contains('PE'), isTrue,
              reason: '${f['nome']}/${r['nome']}: sem custo');
          expect((r['descricao'] as String).length, greaterThan(20),
              reason: '${f['nome']}/${r['nome']}: sem efeito');
        }
      }
    });
  });

  group('busca', () {
    test('acha sem acento e sem caixa', () {
      expect(casaBusca('Líder de Culto', 'lider'), isTrue);
      expect(casaBusca('Eletrocussão', 'eletrocussao'), isTrue);
      expect(casaBusca('Aberração de Carne', 'ABERRACAO'), isTrue);
      expect(casaBusca('Sereia Encarnada', 'zumbi'), isFalse);
    });
  });
}
