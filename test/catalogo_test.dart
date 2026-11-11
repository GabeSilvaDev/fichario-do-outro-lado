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
  final rituaisJson =
      jsonDecode(File('assets/catalogo/rituais.json').readAsStringSync())
          as Map;
  final rituais = (rituaisJson['rituais'] as List).cast<Map<String, dynamic>>();

  final armasJson =
      jsonDecode(File('assets/catalogo/armas.json').readAsStringSync()) as Map;
  final armas = (armasJson['armas'] as List).cast<Map<String, dynamic>>();
  final protecoes = (armasJson['protecoes'] as List)
      .cast<Map<String, dynamic>>();

  group('rituais', () {
    test('o catálogo inteiro está lá', () {
      expect(rituais.length, greaterThanOrEqualTo(80));
      final elementos = rituais.map((r) => r['elemento']).toSet();
      expect(
        elementos,
        containsAll(['Sangue', 'Morte', 'Conhecimento', 'Energia', 'Medo']),
      );
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
        expect(
          r['custo'],
          tabela[r['circulo']],
          reason: '${r['nome']}: círculo ${r['circulo']}',
        );
      }
    });

    test('ficha técnica completa', () {
      for (final r in rituais) {
        expect((r['nome'] as String).trim(), isNotEmpty);
        expect(
          (r['execucao'] as String).trim(),
          isNotEmpty,
          reason: '${r['nome']} sem execução',
        );
        expect(
          (r['alcance'] as String).trim(),
          isNotEmpty,
          reason: '${r['nome']} sem alcance',
        );
        expect(
          (r['duracao'] as String).trim(),
          isNotEmpty,
          reason: '${r['nome']} sem duração',
        );
        expect(r['pagina'], greaterThan(0), reason: r['nome'] as String);
      }
    });

    test('todo ritual diz o que faz, em notação e não em prosa', () {
      for (final r in rituais) {
        final efeito = (r['efeito'] as String).trim();
        expect(
          efeito.length,
          greaterThan(20),
          reason: '${r['nome']}: efeito vazio demais',
        );
        expect(
          efeito.length,
          lessThan(700),
          reason: '${r['nome']}: efeito longo demais — virou prosa',
        );
      }
    });

    test('ampliação tem custo e efeito', () {
      for (final r in rituais) {
        for (final a in (r['ampliacoes'] as List).cast<Map>()) {
          expect(a['custo'], greaterThan(0), reason: r['nome'] as String);
          expect(
            (a['efeito'] as String).trim().length,
            greaterThan(10),
            reason: '${r['nome']}/${a['nome']}',
          );
        }
      }
    });
  });

  group('armas e proteções', () {
    List<Map<String, dynamic>> lista(String chave) =>
        (armasJson[chave] as List).cast<Map<String, dynamic>>();

    test('as 35 armas da Tabela 3.3, sem munição misturada', () {
      expect(armas, hasLength(35));
      expect(protecoes.length, greaterThanOrEqualTo(3));
      final nomes = armas.map((a) => a['nome']).toSet();
      expect(nomes, hasLength(35));
      expect(nomes, isNot(contains('Balas curtas')));
    });

    test('cada arma tem dano, crítico, descrição e categoria', () {
      for (final a in armas) {
        final nome = a['nome'] as String;
        expect((a['dano'] as String).trim(), isNotEmpty, reason: nome);
        expect((a['critico'] as String).trim(), isNotEmpty, reason: nome);
        expect((a['descricao'] as String).trim(), isNotEmpty, reason: nome);
        expect(a['tipo'], isIn(['C', 'P', 'I', 'B', 'F']), reason: nome);
      }
    });

    test('o resto do capítulo: munição, modificações, maldições, itens', () {
      expect(lista('municoes'), hasLength(6));
      expect(lista('modificacoes'), hasLength(17));
      expect(lista('maldicoes'), hasLength(12));
      expect(
        lista('componentes').map((c) => c['elemento']),
        unorderedEquals(['Conhecimento', 'Energia', 'Morte', 'Sangue']),
      );
      expect(
        lista('itensDeAtaque').map((i) => i['nome']),
        containsAll(['Granada de fragmentação', 'Mina antipessoal', 'Taser']),
      );
      // Toda munição citada por uma arma existe na Tabela 3.4.
      final municoes = lista('municoes').map((m) => m['nome']).toSet();
      for (final a in armas) {
        if (a['municao'] != null) {
          expect(municoes, contains(a['municao']), reason: a['nome']);
        }
      }
    });

    test('habilidades das armas batem com o livro (p. 59)', () {
      Map<String, dynamic> arma(String n) =>
          armas.firstWhere((a) => a['nome'] == n);
      for (final n in [
        'Faca',
        'Punhal',
        'Cajado',
        'Nunchaku',
        'Florete',
        'Katana',
      ]) {
        expect(arma(n)['agil'], isTrue, reason: n);
      }
      for (final n in ['Fuzil de assalto', 'Submetralhadora', 'Metralhadora']) {
        expect(arma(n)['automatica'], isTrue, reason: n);
      }
      expect(armas.where((a) => a['agil'] == true), hasLength(6));
      expect(armas.where((a) => a['automatica'] == true), hasLength(3));
    });

    test('notação curta, não prosa do livro', () {
      for (final a in armas) {
        expect(a.containsKey('desc'), isFalse, reason: a['nome'] as String);
        expect(
          (a['descricao'] as String).length,
          lessThanOrEqualTo(110),
          reason: a['nome'] as String,
        );
        for (final e in (a['especial'] as List? ?? const [])) {
          expect((e as String).length, lessThanOrEqualTo(150), reason: e);
        }
      }
      for (final chave in ['modificacoes', 'maldicoes', 'itensDeAtaque']) {
        for (final m in lista(chave)) {
          expect(
            (m['efeito'] as String).length,
            lessThanOrEqualTo(160),
            reason: m['nome'] as String,
          );
        }
      }
      for (final p in protecoes) {
        expect(p.containsKey('desc'), isFalse, reason: p['nome'] as String);
      }
    });
  });

  group('ameaça conjuradora', () {
    final bestiario =
        jsonDecode(File('assets/bestiario/bestiario.json').readAsStringSync())
            as Map;
    final fichas = [
      for (final g in (bestiario['grupos'] as List))
        for (final f in ((g as Map)['fichas'] as List))
          (f as Map).cast<String, dynamic>(),
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
      expect(semLista, [
        'Turba de Seguidores da Noite',
      ], reason: 'ficha que fala em conjurar precisa vir com os rituais');
    });

    test('quem conjura "todos os rituais" tem a lista de verdade', () {
      final conjuradores = fichas.where(
        (f) => (f['rituais'] as List).length >= 10,
      );
      expect(
        conjuradores.length,
        greaterThanOrEqualTo(4),
        reason: 'os chefes conjuradores da Villa e o Giordano',
      );
      for (final f in conjuradores) {
        for (final r in (f['rituais'] as List).cast<Map>()) {
          expect((r['nome'] as String).trim(), isNotEmpty);
          expect(
            (r['custo'] as String).contains('PE'),
            isTrue,
            reason: '${f['nome']}/${r['nome']}: sem custo',
          );
          expect(
            (r['descricao'] as String).length,
            greaterThan(20),
            reason: '${f['nome']}/${r['nome']}: sem efeito',
          );
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
