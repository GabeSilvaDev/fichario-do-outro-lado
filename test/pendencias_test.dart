import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_paranormal/data/dados_op.dart';
import 'package:ordem_paranormal/models/ficha_op.dart';
import 'package:ordem_paranormal/regras/pendencias.dart';

/// O motor de regras: toda mudança na ficha tem de virar conta certa ou
/// pendência clara. Páginas do OPRPG v1.3 e de Sobrevivendo ao Horror.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(DadosOP.carregar);

  /// Combatente legal em NEX 5%: Acadêmico, Agi/For/Pre/Vig 2 (4 pontos),
  /// Luta, Fortitude e 1+Int livres.
  FichaOP combatente() {
    final f = FichaOP.nova('c')
      ..nome = 'Teste'
      ..origem = DadosOP.origens.first.nome
      ..classe = 'Combatente'
      ..nex = 5;
    for (final s in ['AGI', 'FOR', 'VIG', 'PRE']) {
      f.definirAtributo(s, 2);
    }
    f.definirAtributo('INT', 1);
    f.aplicarClasse(DadosOP.classePorNome('Combatente')!);
    f.aplicarOrigem(DadosOP.origens.first);
    for (final p in ['Luta', 'Fortitude', 'Atletismo', 'Percepção']) {
      f.definirGrauPericia(p, 5);
    }
    f.pv = f.pvMax;
    f.san = f.sanMax;
    f.pe = f.peMax;
    return f;
  }

  Iterable<String> ids(FichaOP f, [Gravidade? g]) => [
    for (final p in pendenciasDe(f))
      if (g == null || p.gravidade == g) p.id,
  ];

  group('ficha legal não tem pendência', () {
    test('combatente NEX 5% montado pela regra', () {
      final f = combatente();
      expect(
        pendenciasDe(f),
        isEmpty,
        reason: pendenciasDe(f).map((p) => p.texto).join('\n'),
      );
    });
  });

  group('NEX', () {
    test('subir para 20% pede o Aumento de Atributo', () {
      final f = combatente()..nex = 20;
      expect(ids(f, Gravidade.aviso), contains('attr-pontos'));
      f.definirAtributo('AGI', 3);
      expect(ids(f), isNot(contains('attr-pontos')));
    });

    test('subir para 10% pede a trilha; escolher põe a habilidade', () {
      final f = combatente()..nex = 10;
      expect(ids(f), contains('trilha'));
      f.trilha = DadosOP.trilhasDe('Combatente').first.nome;
      final (entrou, _) = f.sincronizarTrilha();
      expect(entrou, hasLength(1));
      expect(ids(f), isNot(contains('trilha')));
      f.nex = 40;
      expect(f.sincronizarTrilha().$1, hasLength(1));
      f.nex = 10;
      expect(f.sincronizarTrilha().$2, hasLength(1));
    });

    test('15% pede um poder de combatente', () {
      final f = combatente()..nex = 15;
      expect(ids(f), contains('poderes-n'));
      final poder = DadosOP.poderes.firstWhere(
        (p) =>
            p.tipo == 'classe' &&
            p.classe == 'Combatente' &&
            p.requisitosRegra.isEmpty,
      );
      f.adicionarEm('habilidades', poder.paraFicha());
      expect(ids(f), isNot(contains('poderes-n')));
    });

    test('veterano antes de 35% é erro; em 35% falta Grau', () {
      final f = combatente();
      f.definirGrauPericia('Luta', 10);
      expect(ids(f, Gravidade.erro), contains('grau-Luta'));
      f.nex = 35;
      expect(ids(f, Gravidade.erro), isNot(contains('grau-Luta')));
      expect(ids(f, Gravidade.aviso), contains('grau-n'));
    });

    test('Mundano com NEX e agente em 0% são erro', () {
      expect(ids(FichaOP.nova('m')..nex = 10), contains('nex'));
      expect(ids(combatente()..nex = 0), contains('nex'));
    });

    test('afinidade em 50%', () {
      final f = combatente()..nex = 50;
      expect(ids(f), contains('afinidade'));
      f.afinidade = 'Sangue';
      expect(ids(f), isNot(contains('afinidade')));
    });
  });

  group('atributos', () {
    test('dois zeros e acima de 3 sem aumento', () {
      final f = combatente();
      f.definirAtributo('INT', 0);
      f.definirAtributo('PRE', 0);
      expect(ids(f, Gravidade.erro), contains('attr-zeros'));
      final g = combatente();
      g.definirAtributo('FOR', 4);
      expect(ids(g, Gravidade.erro), contains('attr-acima3'));
    });
  });

  group('rituais', () {
    test('ocultista: quantidade e círculo', () {
      final f = FichaOP.nova('o')
        ..classe = 'Ocultista'
        ..nex = 5;
      for (var i = 0; i < 4; i++) {
        f.adicionarEm('rituais', {'nome': 'R$i', 'circulo': '1º'});
      }
      expect(ids(f, Gravidade.erro), contains('rituais-n'));
      f.removerDe('rituais', 3);
      f.atualizarEm('rituais', 0, {'nome': 'R0', 'circulo': '2º'});
      expect(ids(f, Gravidade.erro), contains('ritual-circ-R0'));
    });

    test('DT de ritual = 10 + limite de PE + Pre (p. 121)', () {
      final f = FichaOP.nova('o')
        ..classe = 'Ocultista'
        ..nex = 5;
      f.definirAtributo('PRE', 3);
      expect(f.dtRituais, 14);
    });
  });

  group('Transcender', () {
    test('poder paranormal não dá a SAN do NEX (p. 26)', () {
      final f = combatente()..nex = 15;
      final antes = f.sanMax;
      final paranormal = DadosOP.poderes.firstWhere(
        (p) => p.tipo == 'paranormal',
      );
      f.adicionarEm('habilidades', paranormal.paraFicha());
      expect(f.sanMax, antes - 3);
      expect(f.san, f.sanMax);
    });

    test('Vítima também perde o +1 de SAN do NEX em que transcende', () {
      final f = combatente()
        ..nex = 15
        ..origem = 'Vítima';
      final antes = f.sanMax;
      final paranormal = DadosOP.poderes.firstWhere(
        (p) => p.tipo == 'paranormal',
      );
      f.adicionarEm('habilidades', paranormal.paraFicha());
      expect(f.sanMax, antes - 4);
    });
  });

  group('ferimentos debilitantes (SAH p. 105)', () {
    test('dois no Vigor tiram 2 PV máx. por 5% de NEX', () {
      final f = combatente()..nex = 50;
      final base = f.pvMax;
      f.ferimentos = ['VIG'];
      expect(f.pvMax, base - 10);
      f.ferimentos = ['VIG', 'VIG'];
      expect(f.ferimentosEm('VIG'), 2);
      expect(f.pvMax, base - 20);
    });

    test('cada ferimento no mesmo atributo tira mais um d20', () {
      final f = combatente();
      final fort = DadosOP.pericias.firstWhere((p) => p.nome == 'Fortitude');
      f.ferimentos = ['VIG'];
      final (um, melhorUm, _) = f.testePericia(fort);
      f.ferimentos = ['VIG', 'VIG'];
      final (dois, melhorDois, _) = f.testePericia(fort);
      expect((um, melhorUm), (1, true));
      expect((dois, melhorDois), (2, false));
    });

    test('tirar um ferimento deixa os outros do mesmo atributo', () {
      final f = combatente()..ferimentos = ['VIG', 'VIG', 'AGI'];
      final atuais = f.ferimentos..remove('VIG');
      f.ferimentos = atuais;
      expect(f.ferimentosEm('VIG'), 1);
      expect(f.ferimentosEm('AGI'), 1);
    });
  });

  group('condições', () {
    test('vulnerável + desprevenido tira 5, não 7 (p. 313)', () {
      final f = combatente();
      final base = f.defesa;
      f.condicoes = ['Vulnerável', 'Desprevenido'];
      expect(f.defesa, base - 5);
    });

    test('fatigado = fraco + vulnerável: −O em Agi e −2 Defesa', () {
      final f = combatente();
      final acro = DadosOP.pericias.firstWhere((p) => p.nome == 'Acrobacia');
      final (antes, _, _) = f.testePericia(acro);
      final defesa = f.defesa;
      f.condicoes = ['Fatigado'];
      final (depois, _, _) = f.testePericia(acro);
      expect(depois, antes - 1);
      expect(f.defesa, defesa - 2);
    });

    test('atributo zerado por penalidade rola mais dados no pior', () {
      expect(FichaOP.dadosDoTeste(1, 1), (2, false));
      expect(FichaOP.dadosDoTeste(0, 0), (2, false));
      expect(FichaOP.dadosDoTeste(0, 2), (4, false));
      expect(FichaOP.dadosDoTeste(3, 1), (2, true));
    });

    test('lento anda metade; imóvel não anda', () {
      final f = combatente();
      f.condicoes = ['Lento'];
      expect(f.deslocamentoEfetivo, 4.5);
      f.condicoes = ['Agarrado'];
      expect(f.deslocamentoEfetivo, 0);
    });
  });

  group('proteção e carga', () {
    test('pesada sem proficiência: aviso e −OO em Agi', () {
      final f = combatente();
      final acro = DadosOP.pericias.firstWhere((p) => p.nome == 'Acrobacia');
      final (antes, melhorAntes, bonusAntes) = f.testePericia(acro);
      expect((antes, melhorAntes), (2, true));
      f.vestirProtecao('Pesada');
      expect(ids(f), contains('prof-protecao'));
      final (depois, melhor, bonus) = f.testePericia(acro);
      // Agi 2 − 2 = 0: rola 2d20 e fica com o pior.
      expect((depois, melhor), (2, false));
      expect(bonus, bonusAntes - 5);
      expect(f.cargaUsada, 5);
      expect(f.efeitos.rd['corte'], 2);
    });

    test('aviso de proficiência não liga para maiúsculas', () {
      final f = combatente()..proficiencias = ['proteções leves'];
      f.vestirProtecao('Leve');
      expect(f.semProficienciaEmProtecao, isNull);
    });

    test('Recruta com 3 itens de categoria I', () {
      final f = combatente();
      for (var i = 0; i < 3; i++) {
        f.adicionarEm('inventario', {
          'nome': 'Item $i',
          'categoria': 'I',
          'espacos': 1,
        });
      }
      expect(ids(f, Gravidade.erro), contains('itens-I'));
    });

    test('acima do dobro da carga é erro', () {
      final f = combatente();
      f.adicionarEm('inventario', {
        'nome': 'Cofre',
        'categoria': '0',
        'espacos': 30,
      });
      expect(ids(f, Gravidade.erro), contains('carga'));
    });
  });

  group('ataque', () {
    test('Força no dano corpo a corpo; 19/x3; 1d6/1d8', () {
      final f = combatente()..definirAtributo('FOR', 3);
      final r = f.resumoAtaque({
        'nome': 'Bastão',
        'pericia': 'Luta',
        'dano': '1d6/1d8',
        'critico': '19/x3',
        'familia': 'Armas Simples',
      });
      expect(r.danos, ['1d6', '1d8']);
      expect(r.danoFixo, 3);
      expect(r.margem, 19);
      expect(r.multiplicador, 3);
      expect(r.expressaoDano('1d8'), '1d8+3');
    });

    test('arma tática sem proficiência tira 2 d20', () {
      final f = FichaOP.nova('o')
        ..classe = 'Ocultista'
        ..nex = 5;
      f.definirAtributo('FOR', 3);
      final r = f.resumoAtaque({
        'pericia': 'Luta',
        'dano': '1d10',
        'familia': 'Armas Táticas',
      });
      expect(r.semProficiencia, 'Armas táticas');
      expect(r.dados, 1);
    });
  });

  group('importar', () {
    test('números como texto ou decimal não derrubam a ficha', () {
      final f = FichaOP({
        'classe': 'Combatente',
        'nex': 12.0,
        'pv': '30',
        'atributos': {'VIG': 2.0, 'AGI': '1'},
        'pericias': {'Luta': 5.0},
        'rituais': [
          {'nome': 'X', 'circulo': 1, 'custo': 1},
          'lixo',
        ],
        'proficiencias': ['Armas simples', 3],
      });
      expect(f.nex, 12);
      expect(f.atributo('VIG'), 2);
      expect(f.grauPericia('Luta'), 5);
      expect(f.rituais, hasLength(1));
      expect(f.rituais.first['circulo'], '1');
      expect(f.proficiencias, ['Armas simples', '3']);
      expect(FichaOP({'nex': 250}).nex, 99);
      final acima = FichaOP({'classe': 'Combatente', 'nex': 5, 'pv': 999});
      expect(acima.pv, acima.pvMax);
    });
  });

  group('habilidades que entram sozinhas', () {
    test('Engenhosidade em 40%, sai se o NEX cair', () {
      final f = FichaOP.nova('e')
        ..classe = 'Especialista'
        ..nex = 40;
      final (entrou, _) = f.sincronizarTrilha();
      expect(entrou, contains('Engenhosidade'));
      f.nex = 35;
      expect(f.sincronizarTrilha().$2, contains('Engenhosidade'));
    });

    test('Cicatrizado no estágio 5 do Sobrevivente', () {
      final f = FichaOP.nova('s')..classe = 'Sobrevivente';
      f.estagio = 5;
      expect(f.sincronizarTrilha().$1, contains('Cicatrizado'));
    });
  });

  group('catálogo de poderes', () {
    const chaves = {
      'defesa',
      'pvFixo',
      'pvPorNivel',
      'peFixo',
      'pePorNivel',
      'pePorDoisNiveis',
      'sanFixo',
      'sanPorNivel',
      'limitePe',
      'dt',
      'dtElemento',
      'deslocamento',
      'carga',
      'cargaSomaInt',
      'pericias',
      'testesResistencia',
      'rd',
      'danoCorpo',
      'danoDistancia',
      'danoFogo',
      'danoSomaAtributo',
      'danoSomaAtributoAtaque',
      'margemCorpo',
      'margemDistancia',
      'multiplicador',
      'treinaPericias',
      'treina',
      'quando',
      'semSanNoNex',
      'custoRitual',
      'ritualElemento',
      'peSomaAtributo',
      'proficiencias',
      'pvPorEstagio',
    };

    test('carregou os dois livros', () {
      expect(DadosOP.poderes.length, greaterThan(250));
      expect(DadosOP.trilhasDe('Combatente').length, greaterThanOrEqualTo(8));
      expect(
        DadosOP.trilhasDe('Sobrevivente').map((t) => t.nome),
        containsAll(['Durão', 'Esperto', 'Esotérico']),
      );
    });

    test('notação curta, sem prosa do livro', () {
      for (final p in DadosOP.poderes) {
        expect(p.efeito, isNotEmpty, reason: p.nome);
        expect(p.efeito.length, lessThanOrEqualTo(160), reason: p.nome);
      }
    });

    test('só chaves de efeito que o motor entende', () {
      for (final p in DadosOP.poderes) {
        for (final bloco in [p.efeitos, p.efeitosAfinidade]) {
          for (final k in bloco.keys) {
            expect(chaves, contains(k), reason: '${p.nome}: $k');
          }
        }
      }
    });

    test('habilidade de trilha aponta para trilha que existe', () {
      final trilhas = {for (final t in DadosOP.trilhas) t.nome};
      for (final p in DadosOP.poderes.where((p) => p.tipo == 'trilha')) {
        expect(trilhas, contains(p.trilha), reason: p.nome);
      }
    });
  });

  group('Sobrevivendo ao Horror', () {
    test('Durão: +4 PV no estágio 2', () {
      final f = FichaOP.nova('s')..classe = 'Sobrevivente';
      f.definirAtributo('VIG', 2);
      f.estagio = 2;
      final antes = f.pvMax;
      f.trilha = 'Durão';
      f.sincronizarTrilha();
      expect(f.pvMax, antes + 4);
    });

    test('Treinamento Especial: agente parte do que o sobrevivente tinha', () {
      final f = FichaOP.nova('s')..classe = 'Sobrevivente';
      f.definirAtributo('VIG', 2);
      f.estagio = 5;
      final sobrevivente = f.pvMax;
      f.exSobrevivente = 5;
      f.classe = 'Combatente';
      f.nex = 5;
      expect(f.pvMax, sobrevivente + 8);
      f.nex = 10;
      expect(f.pvMax, sobrevivente + 8 + 4 + 2);
    });
  });
}
