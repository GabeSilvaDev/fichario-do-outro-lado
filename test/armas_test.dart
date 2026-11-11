import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_paranormal/data/dados_op.dart';
import 'package:ordem_paranormal/models/ficha_op.dart';
import 'package:ordem_paranormal/regras/melhorias.dart';

/// As contas do ataque com as habilidades das armas (OPRPG p. 54–59):
/// ágil, arremesso, arco composto, rajada, motosserra e o dano do crítico.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(DadosOP.carregar);

  FichaOP agente({int agi = 1, int forca = 1}) {
    final f = FichaOP.nova('armas-${DateTime.now().microsecondsSinceEpoch}')
      ..classe = 'Combatente'
      ..nex = 5
      ..ehNpc = true; // sem cobrar proficiência: o teste é das armas
    f.definirAtributo('AGI', agi);
    f.definirAtributo('FOR', forca);
    return f;
  }

  Map<String, dynamic> ataque(String arma, {String pericia = 'Luta'}) {
    final a = DadosOP.armaPorNome(arma)!;
    return {
      'nome': arma,
      'arma': arma,
      'pericia': pericia,
      'dano': a['dano'],
      'critico': '${a['critico']}'.contains('x')
          ? 'x${'${a['critico']}'.split('x').last}'
          : '',
      'margem': '${a['critico']}'.split('/').first.startsWith('1')
          ? '${a['critico']}'.split('/').first
          : '',
      'familia': a['familia'],
      'uso': a['uso'],
    };
  }

  test('o catálogo de armas carrega com as habilidades', () {
    expect(DadosOP.armas, hasLength(35));
    expect(DadosOP.armaPorNome('Katana')?['agil'], isTrue);
  });

  test('arma ágil usa Agilidade no ataque e no dano quando é maior', () {
    final f = agente(agi: 3, forca: 1);
    final r = f.resumoAtaque(ataque('Florete'));
    expect(r.dados, 3);
    expect(r.atributoNoDano, 'AGI');
    expect(r.expressaoDano('1d6'), '1d6+3');

    final machado = f.resumoAtaque(ataque('Machado'));
    expect(machado.dados, 1);
    expect(machado.atributoNoDano, 'FOR');
  });

  test('arremesso e arco composto somam Força; arco comum não', () {
    final f = agente(forca: 2);
    expect(
      f.resumoAtaque(ataque('Machadinha', pericia: 'Pontaria')).danoFixo,
      2,
    );
    expect(
      f.resumoAtaque(ataque('Arco composto', pericia: 'Pontaria')).danoFixo,
      2,
    );
    expect(f.resumoAtaque(ataque('Arco', pericia: 'Pontaria')).danoFixo, 0);
  });

  test('rajada: −1d20 no ataque e +1 dado de dano', () {
    final f = agente(agi: 3);
    final a = ataque('Fuzil de assalto', pericia: 'Pontaria');
    final normal = f.resumoAtaque(a);
    final rajada = f.resumoAtaque(a, rajada: true);
    expect(normal.automatica, isTrue);
    expect(rajada.dados, normal.dados - 1);
    expect(rajada.danos.first, '3d10');
    // Arma que não é automática ignora a rajada.
    final revolver = f.resumoAtaque(
      ataque('Revólver', pericia: 'Pontaria'),
      rajada: true,
    );
    expect(revolver.danos.first, '2d6');
  });

  test('motosserra tira 1d20 do ataque', () {
    final f = agente(forca: 3);
    expect(f.resumoAtaque(ataque('Motosserra')).dados, 2);
  });

  test('dano do crítico multiplica só os dados', () {
    final f = agente(forca: 2);
    final r = f.resumoAtaque(ataque('Machado'));
    expect(r.multiplicador, 3);
    expect(r.expressaoCritico('1d8'), '3d8+2');
    expect(r.textoMargem, '20');
    final katana = f.resumoAtaque(ataque('Katana'));
    expect(katana.textoMargem, '19–20');
  });

  group('modificações e maldições', () {
    Map<String, dynamic> com(
      String arma, {
      String pericia = 'Pontaria',
      List<String> mods = const [],
      List<String> mald = const [],
    }) => {
      ...ataque(arma, pericia: pericia),
      'categoria': DadosOP.armaPorNome(arma)!['categoria'],
      'espacos': DadosOP.armaPorNome(arma)!['espacos'],
      'modificacoes': mods,
      'maldicoes': mald,
    };

    test('números: certeira, cruel, perigosa, dum dum', () {
      final f = agente(forca: 2);
      final base = f.resumoAtaque(com('Machado', pericia: 'Luta'));
      final r = f.resumoAtaque(
        com(
          'Machado',
          pericia: 'Luta',
          mods: ['Certeira', 'Cruel', 'Perigosa'],
        ),
      );
      expect(r.bonus, base.bonus + 2);
      expect(r.danoFixo, base.danoFixo + 2);
      expect(r.margem, 18);
      final dum = f.resumoAtaque(com('Revólver', mods: ['Dum dum']));
      expect(dum.multiplicador, 4);
    });

    test(
      'calibre grosso soma um dado; explosiva não multiplica no crítico',
      () {
        final f = agente();
        final r = f.resumoAtaque(
          com('Revólver', mods: ['Calibre grosso', 'Explosiva']),
        );
        expect(r.danos.first, '3d6');
        expect(r.expressaoDano(r.danos.first), '3d6+2d6');
        expect(r.expressaoCritico(r.danos.first), '9d6+2d6');
      },
    );

    test('lancinante multiplica no crítico; predadora dobra a margem', () {
      final f = agente();
      final r = f.resumoAtaque(
        com('Fuzil de caça', mald: ['Lancinante', 'Predadora']),
      );
      expect(r.danos.first, '2d8+1d8');
      expect(r.expressaoCritico(r.danos.first), '6d8+3d8');
      expect(r.margem, 17);
    });

    test('ferrolho deixa automática; compensador anula a rajada', () {
      final f = agente(agi: 3);
      final sem = f.resumoAtaque(com('Pistola'), rajada: true);
      expect(sem.automatica, isFalse);
      final ferrolho = com('Pistola', mods: ['Ferrolho automático']);
      expect(f.resumoAtaque(ferrolho).automatica, isTrue);
      expect(f.resumoAtaque(ferrolho, rajada: true).dados, 2);
      final comp = com('Pistola', mods: ['Ferrolho automático', 'Compensador']);
      expect(f.resumoAtaque(comp, rajada: true).dados, 3);
      expect(f.resumoAtaque(comp, rajada: true).danos.first, '2d12');
    });

    test('categoria: +I por modificação, +II na 1ª maldição e +I depois', () {
      final f = agente();
      expect(f.melhoriasDe(com('Katana', pericia: 'Luta')).categoriaTexto, 'I');
      expect(
        f
            .melhoriasDe(
              com('Katana', pericia: 'Luta', mods: ['Certeira', 'Perigosa']),
            )
            .categoriaTexto,
        'III',
      );
      final m = f.melhoriasDe(
        com('Faca', pericia: 'Luta', mald: ['Lancinante', 'Sanguinária']),
      );
      expect(m.categoriaTexto, 'III');
      expect(m.amaldicoada, isTrue);
      final discreta = f.melhoriasDe(com('Fuzil de caça', mods: ['Discreta']));
      expect(discreta.espacos, 1);
    });

    test('só aparece o que cabe na arma', () {
      final f = agente();
      List<String> mods(String arma, String pericia) => [
        for (final m
            in f.melhoriasDe(com(arma, pericia: pericia)).modificacoesPossiveis)
          m.nome,
      ];
      expect(mods('Katana', 'Luta'), contains('Certeira'));
      expect(mods('Katana', 'Luta'), isNot(contains('Mira laser')));
      expect(mods('Revólver', 'Pontaria'), contains('Dum dum'));
      expect(mods('Espingarda', 'Pontaria'), isNot(contains('Dum dum')));
      expect(mods('Revólver', 'Pontaria'), isNot(contains('Compensador')));
      expect(mods('Fuzil de assalto', 'Pontaria'), contains('Compensador'));
      final mald = [
        for (final m in f.melhoriasDe(com('Fuzil de caça')).maldicoesPossiveis)
          m.nome,
      ];
      expect(mald, isNot(contains('Empuxo')));
    });

    test('elemento opressor trava a maldição', () {
      final f = agente();
      final m = f.melhoriasDe(
        com('Faca', pericia: 'Luta', mald: ['Lancinante']),
      );
      Melhoria pega(String n) =>
          Melhorias.maldicoes.firstWhere((x) => x.nome == n);
      expect(m.conflitoDe(pega('Erosiva')), 'Sangue'); // Morte oprime Sangue
      expect(m.conflitoDe(pega('Antielemento')), 'Sangue'); // Sangue oprime Con
      expect(m.conflitoDe(pega('Vibrante')), isNull); // Energia combina
    });
  });

  group('proficiências', () {
    test('nome antigo digitado à mão vira o do livro, sem repetir', () {
      final f = FichaOP({
        'id': 'p',
        'classe': 'Ocultista',
        'proficiencias': ['armas simples', 'Arma tatica', 'Armas simples'],
      });
      expect(f.proficiencias, ['Armas simples', 'Armas táticas']);
    });

    test('katana sem Armas táticas: −2d20; marcando, some', () {
      final f = FichaOP.nova('prof-katana')
        ..classe = 'Ocultista'
        ..nex = 5
        ..proficiencias = ['Armas simples'];
      final katana = {...ataque('Katana'), 'familia': 'Armas Táticas'};
      expect(f.semProficienciaNaArma(katana), 'Armas táticas');
      f.marcarProficiencia('Armas táticas', true);
      expect(f.semProficienciaNaArma(katana), isNull);
      f.marcarProficiencia('Armas táticas', false);
      expect(f.proficiente('Armas táticas'), isFalse);
    });
  });
}
