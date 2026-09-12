import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_paranormal/data/dados_op.dart';
import 'package:ordem_paranormal/models/ficha_op.dart';

/// As fórmulas do Livro de Regras v1.3, conferidas número a número.
/// Se uma destas quebrar, a ficha passou a mentir para a mesa.
void main() {
  final combatente = DadosOP.classePorNome('Combatente')!;
  final especialista = DadosOP.classePorNome('Especialista')!;
  final ocultista = DadosOP.classePorNome('Ocultista')!;
  final mundano = DadosOP.classePorNome('Mundano')!;

  group('níveis de exposição', () {
    test('NEX 5% é o nível 1 e NEX 99% é o nível 20', () {
      expect(ClasseOP.limitePeTurno(5), 1);
      expect(ClasseOP.limitePeTurno(30), 6);
      expect(ClasseOP.limitePeTurno(95), 19);
      expect(ClasseOP.limitePeTurno(99), 20);
    });

    test('NEX 0% ainda pode gastar 1 PE por turno', () {
      expect(ClasseOP.limitePeTurno(0), 1);
    });
  });

  group('combatente (20+Vig, +4+Vig por nível)', () {
    test('NEX 5% com Vigor 2 = os valores iniciais', () {
      expect(combatente.pvMax(5, 2), 22);
      expect(combatente.peMax(5, 1), 3);
      expect(combatente.sanMax(5), 12);
    });

    test('NEX 10% com Vigor 2 soma um nível', () {
      expect(combatente.pvMax(10, 2), 28);
      expect(combatente.sanMax(10), 15);
    });

    test('NEX 35% com Vigor 3 — o fim de Vendeta Oculta 1', () {
      expect(combatente.pvMax(35, 3), 65);
      expect(combatente.peMax(35, 2), 28);
      expect(combatente.sanMax(35), 30);
    });
  });

  group('especialista e ocultista', () {
    test('especialista NEX 15% com Vigor 1', () {
      expect(especialista.pvMax(15, 1), 25);
      expect(especialista.sanMax(15), 24);
    });

    test('ocultista NEX 20% com Presença 3', () {
      expect(ocultista.peMax(20, 3), 28);
      expect(ocultista.sanMax(20), 35);
    });
  });

  group('mundano (NEX 0%)', () {
    test('8+Vigor de PV, 1+Presença de PE, 8 de Sanidade', () {
      expect(mundano.pvMax(0, 1), 9);
      expect(mundano.peMax(0, 1), 2);
      expect(mundano.sanMax(0), 8);
    });
  });

  group('ficha nova', () {
    test('nasce coerente com um civil de atributos 1', () {
      final f = FichaOP.nova('teste');
      expect(f.classe, 'Mundano');
      expect(f.nex, 0);
      expect(f.pv, 9);
      expect(f.san, 8);
      expect(f.pe, 2);
      expect(f.defesa, 11);
    });
  });

  group('carga', () {
    test('5 espaços por ponto de Força; Força 0 carrega 2', () {
      final f = FichaOP.nova('c');
      f.definirAtributo('FOR', 2);
      expect(f.cargaLimite, 10);
      f.definirAtributo('FOR', 0);
      expect(f.cargaLimite, 2);
    });

    test('sobrecarga tira 5 da Defesa e 3m do deslocamento', () {
      final f = FichaOP.nova('c');
      f.definirAtributo('FOR', 1);
      f.definirAtributo('AGI', 3);
      expect(f.defesa, 13);
      expect(f.deslocamentoEfetivo, 9);

      f.adicionarEm('inventario', {'nome': 'Marreta', 'espacos': 6});
      expect(f.sobrecarregado, isTrue);
      expect(f.defesa, 8);
      expect(f.deslocamentoEfetivo, 6);
    });
  });

  group('poderes de origem que mexem nos números', () {
    setUp(() {
      DadosOP.origens = const [
        Origem(
            nome: 'Desgarrado',
            pericias: ['Fortitude', 'Sobrevivência'],
            periciasTexto: '',
            poder: 'Calejado',
            poderDescricao: '',
            modificadores: {'pvPorNivel': 1}),
        Origem(
            nome: 'Vítima',
            pericias: ['Reflexos', 'Vontade'],
            periciasTexto: '',
            poder: 'Cicatrizes Psicológicas',
            poderDescricao: '',
            modificadores: {'sanPorNivel': 1}),
        Origem(
            nome: 'Policial',
            pericias: ['Percepção', 'Pontaria'],
            periciasTexto: '',
            poder: 'Patrulha',
            poderDescricao: '',
            modificadores: {'defesa': 2}),
        Origem(
            nome: 'Universitário',
            pericias: ['Atualidades', 'Investigação'],
            periciasTexto: '',
            poder: 'Dedicação',
            poderDescricao: '',
            modificadores: {'pe': 1, 'pePorNivelImpar': 1, 'limitePe': 1}),
        Origem(
            nome: 'Cultista Arrependido',
            pericias: ['Ocultismo', 'Religião'],
            periciasTexto: '',
            poder: 'Traços do Outro Lado',
            poderDescricao: '',
            modificadores: {'sanMetade': true}),
        Origem(
            nome: 'Mergulhador',
            pericias: ['Atletismo', 'Fortitude'],
            periciasTexto: '',
            poder: 'Fôlego de Nadador',
            poderDescricao: '',
            modificadores: {'pv': 5}),
        Origem(
            nome: 'Militar',
            pericias: ['Pontaria', 'Tática'],
            periciasTexto: '',
            poder: 'Para Bellum',
            poderDescricao: ''),
      ];
    });

    tearDown(() => DadosOP.origens = const []);

    FichaOP agente(String origem, {int nex = 5}) {
      final f = FichaOP.nova('o');
      f.classe = 'Combatente';
      f.nex = nex;
      f.origem = origem;
      f.definirAtributo('VIG', 1);
      f.definirAtributo('PRE', 1);
      return f;
    }

    test('origem sem efeito numérico não muda nada', () {
      expect(agente('Militar').pvMax, combatente.pvMax(5, 1));
      expect(agente('Militar').defesa, 11);
    });

    test('Calejado dá +1 PV por 5% de NEX', () {
      expect(agente('Desgarrado', nex: 5).pvMax, combatente.pvMax(5, 1) + 1);
      expect(agente('Desgarrado', nex: 30).pvMax, combatente.pvMax(30, 1) + 6);
    });

    test('Cicatrizes Psicológicas dá +1 SAN por 5% de NEX', () {
      expect(agente('Vítima', nex: 20).sanMax, combatente.sanMax(20) + 4);
    });

    test('Fôlego de Nadador dá +5 PV fixos', () {
      expect(agente('Mergulhador', nex: 40).pvMax, combatente.pvMax(40, 1) + 5);
    });

    test('Patrulha dá +2 em Defesa', () {
      expect(agente('Policial').defesa, 13);
    });

    test('Dedicação: +1 PE e mais 1 a cada NEX ímpar', () {
      expect(agente('Universitário', nex: 5).peMax, combatente.peMax(5, 1) + 1);
      expect(
          agente('Universitário', nex: 10).peMax, combatente.peMax(10, 1) + 1);
      expect(
          agente('Universitário', nex: 15).peMax, combatente.peMax(15, 1) + 2);
      expect(
          agente('Universitário', nex: 25).peMax, combatente.peMax(25, 1) + 3);
    });

    test('Dedicação também sobe o limite de PE por turno', () {
      expect(agente('Universitário', nex: 5).limitePeTurno, 2);
      expect(agente('Militar', nex: 5).limitePeTurno, 1);
    });

    test('Traços do Outro Lado corta a Sanidade pela metade', () {
      final f = agente('Cultista Arrependido', nex: 5);
      expect(f.sanMax, combatente.sanMax(5) ~/ 2);
    });

    test('máximo manual continua mandando em tudo', () {
      final f = agente('Desgarrado', nex: 30);
      f.definirMaxManual('pv', 40);
      expect(f.pvMax, 40);
    });
  });

  group('caixas de características (conferidas no livro)', () {
    test('proficiências de cada classe', () {
      expect(mundano.proficiencias, ['Armas simples']);
      expect(combatente.proficiencias,
          ['Armas simples', 'Armas táticas', 'Proteções leves']);
      expect(especialista.proficiencias, ['Armas simples', 'Proteções leves']);
      expect(ocultista.proficiencias, ['Armas simples']);
    });

    test('o especialista tem duas habilidades em NEX 5%', () {
      final nomes = [for (final h in especialista.habilidades) h.nome];
      expect(nomes, ['Eclético', 'Perito']);
    });

    test('as outras classes têm uma só', () {
      expect(combatente.habilidades.length, 1);
      expect(ocultista.habilidades.length, 1);
      expect(mundano.habilidades.length, 1);
    });

    test('aplicar especialista põe Eclético e Perito na ficha', () {
      final f = FichaOP.nova('e');
      f.aplicarClasse(especialista);
      expect(f.habilidades.length, 2);
      f.aplicarClasse(especialista);
      expect(f.habilidades.length, 2);
    });
  });

  group('sobrevivente (Sobrevivendo ao Horror)', () {
    final sobrevivente = DadosOP.classePorNome('Sobrevivente')!;

    test('estágio 1 com Vigor 1 e Presença 1', () {
      expect(sobrevivente.pvMax(0, 1, estagio: 1), 9);
      expect(sobrevivente.peMax(0, 1, estagio: 1), 3);
      expect(sobrevivente.sanMax(0, estagio: 1), 8);
    });

    test('estágio 5 soma quatro passos', () {
      expect(sobrevivente.pvMax(0, 1, estagio: 5), 17);
      expect(sobrevivente.peMax(0, 1, estagio: 5), 7);
      expect(sobrevivente.sanMax(0, estagio: 5), 16);
    });

    test('o limite de PE fica em 1 em qualquer estágio', () {
      expect(sobrevivente.limitePe(0), 1);
      expect(sobrevivente.limitePe(99), 1);
      expect(combatente.limitePe(30), 6);
    });

    test('recebe 3 pontos de atributo, como o civil', () {
      expect(sobrevivente.pontosAtributo, 3);
      expect(combatente.pontosAtributo, 4);
    });

    test('a ficha usa o estágio no lugar do NEX', () {
      final f = FichaOP.nova('s');
      f.classe = 'Sobrevivente';
      f.definirAtributo('VIG', 2);
      f.definirAtributo('PRE', 1);
      expect(f.porEstagio, isTrue);
      expect(f.pvMax, 10);
      f.estagio = 3;
      expect(f.pvMax, 14);
      expect(f.limitePeTurno, 1);
    });

    test('estágio fica preso entre 1 e 5', () {
      final f = FichaOP.nova('s');
      f.estagio = 9;
      expect(f.estagio, 5);
      f.estagio = 0;
      expect(f.estagio, 1);
    });

    test('classe de agente ignora o estágio gravado', () {
      final f = FichaOP.nova('a');
      f.classe = 'Combatente';
      f.nex = 10;
      f.definirAtributo('VIG', 2);
      f.estagio = 5;
      expect(f.pvMax, 28);
      expect(f.porEstagio, isFalse);
    });
  });

  group('proteção e Defesa', () {
    test('vestir proteção leve leva a Defesa de 11 para 16', () {
      final f = FichaOP.nova('p');
      f.definirAtributo('AGI', 1);
      expect(f.defesa, 11);
      f.vestirProtecao('Leve');
      expect(f.defesa, 16);
      expect(f.protecao, 'Leve');
      expect(f.protecaoTipo, 'Leve');
    });

    test('pesada dá +10 e trocar de proteção não acumula', () {
      final f = FichaOP.nova('p');
      f.definirAtributo('AGI', 2);
      f.vestirProtecao('Leve');
      expect(f.defesa, 17);
      f.vestirProtecao('Pesada');
      expect(f.defesa, 22);
      f.vestirProtecao('Nenhuma');
      expect(f.defesa, 12);
      expect(f.protecaoTipo, 'Nenhuma');
    });

    test('escudo soma +2 por cima da proteção', () {
      final f = FichaOP.nova('p');
      f.definirAtributo('AGI', 1);
      f.vestirProtecao('Leve');
      f.escudo = true;
      expect(f.defesa, 18);
      f.escudo = false;
      expect(f.defesa, 16);
      expect(f.dados.containsKey('escudo'), isFalse);
    });

    test('outros bônus e sobrecarga entram no mesmo cálculo', () {
      final f = FichaOP.nova('p');
      f.definirAtributo('AGI', 1);
      f.definirAtributo('FOR', 1);
      f.vestirProtecao('Pesada');
      f.defesaBonus = 1;
      expect(f.defesa, 22);
      f.adicionarEm('inventario', {'nome': 'Marreta', 'espacos': 6});
      expect(f.defesa, 17);
    });

    test('Defesa impressa da ameaça ignora a proteção vestida', () {
      final f = FichaOP.novoNpc('a');
      f.vestirProtecao('Pesada');
      f.defesaManual = 15;
      expect(f.defesa, 15);
    });

    test('ficha antiga, sem os campos novos, mantém 10+Agilidade', () {
      final f = FichaOP({'id': 'x', 'atributos': {'AGI': 3}});
      expect(f.protecaoDefesa, 0);
      expect(f.escudo, isFalse);
      expect(f.defesa, 13);
    });

    test('proteção fora da tabela cai em "Outra" e soma o valor gravado', () {
      final f = FichaOP.nova('p');
      f.definirAtributo('AGI', 0);
      f.protecao = 'Casaco reforçado';
      f.protecaoDefesa = 3;
      expect(f.protecaoTipo, 'Outra');
      expect(f.defesa, 13);
    });
  });

  group('atributo trocado na perícia', () {
    const atletismo = Pericia(
        nome: 'Atletismo',
        atributo: 'FOR',
        soTreinada: false,
        sofreCarga: true,
        usaKit: false);

    test('sem troca, rola o atributo do livro', () {
      final f = FichaOP.nova('t');
      f.definirAtributo('FOR', 3);
      f.definirAtributo('INT', 1);
      expect(f.atributoPericia(atletismo), 'FOR');
      expect(f.atributoTrocado(atletismo), isFalse);
      expect(f.testePericia(atletismo).$1, 3);
    });

    test('trocar por Intelecto muda quantos d20 rolam', () {
      final f = FichaOP.nova('t');
      f.definirAtributo('FOR', 3);
      f.definirAtributo('INT', 1);
      f.definirGrauPericia('Atletismo', 5);
      f.definirAtributoPericia(atletismo, 'INT');
      expect(f.atributoTrocado(atletismo), isTrue);
      expect(f.testePericia(atletismo), (1, true, 5));
    });

    test('voltar ao padrão limpa o campo em vez de gravar o do livro', () {
      final f = FichaOP.nova('t');
      f.definirAtributoPericia(atletismo, 'AGI');
      f.definirAtributoPericia(atletismo, 'FOR');
      expect(f.atributoTrocado(atletismo), isFalse);
      f.definirAtributoPericia(atletismo, 'AGI');
      f.definirAtributoPericia(atletismo, null);
      expect(f.atributoPericia(atletismo), 'FOR');
    });

    test('trocar para um atributo 0 rola 2d20 pegando o pior', () {
      final f = FichaOP.nova('t');
      f.definirAtributo('FOR', 4);
      f.definirAtributo('PRE', 0);
      f.definirAtributoPericia(atletismo, 'PRE');
      expect(f.testePericia(atletismo), (2, false, 0));
    });

    test('a troca sobrevive à cópia da ficha', () {
      final f = FichaOP.nova('t');
      f.definirAtributoPericia(atletismo, 'INT');
      expect(f.copia().atributoPericia(atletismo), 'INT');
    });
  });

  group('teste de perícia', () {
    const luta = Pericia(
        nome: 'Luta',
        atributo: 'FOR',
        soTreinada: false,
        sofreCarga: false,
        usaKit: false);

    test('rola tantos d20 quanto o atributo, pegando o melhor', () {
      final f = FichaOP.nova('p');
      f.definirAtributo('FOR', 3);
      f.definirGrauPericia('Luta', 10);
      final (dados, melhor, bonus) = f.testePericia(luta);
      expect(dados, 3);
      expect(melhor, isTrue);
      expect(bonus, 10);
    });

    test('atributo 0 rola 2d20 e pega o PIOR', () {
      final f = FichaOP.nova('p');
      f.definirAtributo('FOR', 0);
      final (dados, melhor, bonus) = f.testePericia(luta);
      expect(dados, 2);
      expect(melhor, isFalse);
      expect(bonus, 0);
    });
  });

  _criacao();
  _assets();
  _npcELivre();

  group('máximo manual', () {
    test('sobrepõe o cálculo e volta ao automático', () {
      final f = FichaOP.nova('m');
      f.classe = 'Combatente';
      f.nex = 5;
      f.definirAtributo('VIG', 2);
      expect(f.pvMaxManual, isFalse);

      f.definirMaxManual('pv', 40);
      expect(f.pvMax, 40);
      expect(f.pvMaxManual, isTrue);

      f.definirMaxManual('pv', null);
      expect(f.pvMaxManual, isFalse);
      expect(f.pvMax, 22);
    });
  });
}

/// Os JSON de `assets/data` — o app os lê pelo rootBundle, que não existe
/// no teste; aqui eles são lidos do disco, que é o que pega um arquivo
/// quebrado antes de ele chegar no celular.
void _assets() {
  Map<String, dynamic> comoMapa(Object? j) =>
      (j as Map).cast<String, dynamic>();

  group('assets do sistema', () {
    test('as 28 perícias com atributo-base válido', () {
      final lista = jsonDecode(
          File('assets/data/pericias.json').readAsStringSync()) as List;
      expect(lista.length, 28);
      final pericias = [for (final j in lista) Pericia.fromJson(comoMapa(j))];
      expect(pericias.map((p) => p.nome), contains('Ocultismo'));
      for (final p in pericias) {
        expect(['AGI', 'FOR', 'INT', 'PRE', 'VIG'], contains(p.atributo),
            reason: '${p.nome} tem atributo-base inválido');
      }
    });

    test('as 46 origens — 26 do básico e 20 de Sobrevivendo ao Horror', () {
      final lista = jsonDecode(
          File('assets/data/origens.json').readAsStringSync()) as List;
      final origens = [for (final j in lista) Origem.fromJson(comoMapa(j))];
      expect(origens.length, 46);
      expect(origens.where((o) => o.fonte == 'Livro de Regras').length, 26);
      expect(
          origens.where((o) => o.fonte == 'Sobrevivendo ao Horror').length, 20);
      expect(origens.map((o) => o.nome).toSet().length, 46,
          reason: 'origem repetida entre os dois livros');

      final nomesDePericia = {
        for (final j in jsonDecode(
            File('assets/data/pericias.json').readAsStringSync()) as List)
          Pericia.fromJson(comoMapa(j)).nome
      };
      const parciais = {'Amnésico', 'Profetizado'};
      for (final o in origens) {
        expect(o.poder, isNotEmpty, reason: '${o.nome} sem poder');
        if (!parciais.contains(o.nome)) {
          expect(o.pericias.length, 2, reason: o.nome);
        }
        for (final p in o.pericias) {
          expect(nomesDePericia, contains(p),
              reason: '${o.nome} treina perícia inexistente: $p');
        }
      }
    });

    test('os poderes conferidos no livro não voltam ao texto antigo', () {
      final origens = {
        for (final j in jsonDecode(
            File('assets/data/origens.json').readAsStringSync()) as List)
          (comoMapa(j)['nome'] as String): Origem.fromJson(comoMapa(j))
      };
      expect(origens['Mercenário']!.poderDescricao, contains('movimento'));
      expect(origens['Policial']!.poderDescricao, contains('Defesa'));
      expect(origens['Religioso']!.poderDescricao, contains('Sanidade'));
      expect(origens['Desgarrado']!.poderDescricao, contains('PV'));
      expect(origens['Vítima']!.poderDescricao, contains('Sanidade'));
      expect(origens['Teórico da Conspiração']!.poderDescricao,
          contains('dano mental'));
      expect(origens['Servidor Público']!.poderDescricao, contains('ajudar'));
      expect(origens['Agente de Saúde']!.poderDescricao, contains('Intelecto'));

      expect(origens['Policial']!.mod('defesa'), 2);
      expect(origens['Desgarrado']!.mod('pvPorNivel'), 1);
      expect(origens['Vítima']!.mod('sanPorNivel'), 1);
      expect(origens['Mergulhador']!.mod('pv'), 5);
      expect(origens['Universitário']!.mod('limitePe'), 1);
      expect(origens['Cultista Arrependido']!.flag('sanMetade'), isTrue);
    });

    test('as perícias com kit são só as quatro da Tabela 2.1', () {
      final lista = jsonDecode(
          File('assets/data/pericias.json').readAsStringSync()) as List;
      final comKit = {
        for (final j in lista)
          if (Pericia.fromJson(comoMapa(j)).usaKit)
            Pericia.fromJson(comoMapa(j)).nome
      };
      expect(comKit, {'Crime', 'Enganação', 'Medicina', 'Tecnologia'});
    });

    test('as 5 patentes em ordem de prestígio', () {
      final lista = jsonDecode(
          File('assets/data/patentes.json').readAsStringSync()) as List;
      final patentes = [for (final j in lista) Patente.fromJson(comoMapa(j))];
      expect(patentes.map((p) => p.nome).toList(), [
        'Recruta',
        'Operador',
        'Agente Especial',
        'Oficial de Operações',
        'Agente de Elite',
      ]);
      expect(patentes.map((p) => p.pp).toList(), [0, 20, 50, 100, 200]);
      expect(patentes.first.limites['I'], 2);
      expect(patentes.last.limites['IV'], 2);
    });
  });
}

/// As regras que o assistente de criação cobra (OPRPG p. 30-31 e 171).
void _criacao() {
  group('pontos de atributo na criação', () {
    test('agente recebe 4 e civil recebe 3', () {
      expect(DadosOP.classePorNome('Combatente')!.pontosAtributo, 4);
      expect(DadosOP.classePorNome('Especialista')!.pontosAtributo, 4);
      expect(DadosOP.classePorNome('Ocultista')!.pontosAtributo, 4);
      expect(DadosOP.classePorNome('Mundano')!.pontosAtributo, 3);
    });
  });

  group('perícias livres da classe', () {
    test('base + Intelecto, por classe', () {
      final f = FichaOP.nova('p');
      f.definirAtributo('INT', 2);
      expect(f.periciasLivres(DadosOP.classePorNome('Combatente')!), 3);
      expect(f.periciasLivres(DadosOP.classePorNome('Especialista')!), 9);
      expect(f.periciasLivres(DadosOP.classePorNome('Ocultista')!), 5);
      expect(f.periciasLivres(DadosOP.classePorNome('Mundano')!), 3);
    });
  });

  group('o que classe e origem preenchem', () {
    test('combatente traz proficiências e a habilidade de classe', () {
      final f = FichaOP.nova('c');
      f.classe = 'Combatente';
      f.aplicarClasse(DadosOP.classePorNome('Combatente')!);
      expect(f.proficiencias, contains('Armas táticas'));
      expect(f.habilidades.any((h) => (h['nome'] as String).contains('Ataque Especial')),
          isTrue);
    });

    test('ocultista treina Ocultismo e Vontade', () {
      final f = FichaOP.nova('o');
      f.aplicarClasse(DadosOP.classePorNome('Ocultista')!);
      expect(f.grauPericia('Ocultismo'), 5);
      expect(f.grauPericia('Vontade'), 5);
    });

    test('origem treina as duas perícias dela e dá o poder', () {
      const militar = Origem(
        nome: 'Militar',
        pericias: ['Pontaria', 'Tática'],
        periciasTexto: 'Pontaria e Tática',
        poder: 'Para Bellum',
        poderDescricao: '+2 de dano com arma de fogo.',
      );
      final f = FichaOP.nova('m');
      f.aplicarOrigem(militar);
      expect(f.grauPericia('Pontaria'), 5);
      expect(f.grauPericia('Tática'), 5);
      expect(f.habilidades.any((h) => (h['nome'] as String).contains('Para Bellum')),
          isTrue);
    });

    test('aplicar de novo não duplica a habilidade', () {
      final classe = DadosOP.classePorNome('Combatente')!;
      final f = FichaOP.nova('d');
      f.aplicarClasse(classe);
      f.aplicarClasse(classe);
      expect(f.habilidades.length, 1);
      expect(f.proficiencias.length, 3);
    });

    test('não rebaixa quem já é veterano', () {
      final f = FichaOP.nova('v');
      f.definirGrauPericia('Ocultismo', 10);
      f.aplicarClasse(DadosOP.classePorNome('Ocultista')!);
      expect(f.grauPericia('Ocultismo'), 10);
    });

    test('reaplicar a origem corrige o texto do poder na ficha antiga', () {
      final f = FichaOP.nova('r');
      f.adicionarEm('habilidades', {
        'nome': 'Posição de Combate (origem)',
        'descricao': '+2 em ataque no 1º turno do combate.',
      });
      const mercenario = Origem(
        nome: 'Mercenário',
        pericias: ['Iniciativa', 'Intimidação'],
        periciasTexto: 'Iniciativa e Intimidação',
        poder: 'Posição de Combate',
        poderDescricao: '1 ação de movimento extra no 1º turno do combate.',
      );
      f.aplicarOrigem(mercenario);
      expect(f.habilidades.length, 1);
      expect(f.habilidades.first['descricao'],
          '1 ação de movimento extra no 1º turno do combate.');
    });
  });

  group('ficha recém-criada', () {
    test('entra em jogo com os recursos cheios', () {
      final f = FichaOP.nova('n');
      f.classe = 'Especialista';
      f.nex = 5;
      f.definirAtributo('VIG', 2);
      f.definirAtributo('PRE', 3);
      f.pv = f.pvMax;
      f.san = f.sanMax;
      f.pe = f.peMax;
      expect(f.pv, 18);
      expect(f.san, 16);
      expect(f.pe, 6);
    });
  });
}


/// NPC e modo livre — o que o mestre precisa para montar ficha à vontade.
void _npcELivre() {
  group('NPC', () {
    test('nasce marcado e já em modo livre', () {
      final n = FichaOP.novoNpc('n');
      expect(n.ehNpc, isTrue);
      expect(n.modoLivre, isTrue);
      expect(n.tipo, 'npc');
    });

    test('ficha comum é de jogador por padrão', () {
      final f = FichaOP.nova('p');
      expect(f.ehNpc, isFalse);
      expect(f.modoLivre, isFalse);
      expect(f.tipo, 'pc');
    });

    test('dá para promover e despromover sem sujar o JSON', () {
      final f = FichaOP.nova('t');
      f.ehNpc = true;
      expect(f.dados['tipo'], 'npc');
      f.ehNpc = false;
      expect(f.dados.containsKey('tipo'), isFalse);
      expect(f.ehNpc, isFalse);
    });

    test('ficha importada sem o campo entra como jogador', () {
      final f = FichaOP({'id': 'x', 'nome': 'Antiga'});
      expect(f.ehNpc, isFalse);
      expect(f.modoLivre, isFalse);
    });
  });

  group('modo livre', () {
    test('atributo para em 5 na ficha comum e em 20 no livre', () {
      final f = FichaOP.nova('a');
      f.definirAtributo('VIG', 9);
      expect(f.atributo('VIG'), 5);

      f.modoLivre = true;
      f.definirAtributo('VIG', 9);
      expect(f.atributo('VIG'), 9);
      f.definirAtributo('VIG', 40);
      expect(f.atributo('VIG'), 20);
    });

    test('nunca deixa atributo negativo', () {
      final f = FichaOP.nova('b');
      f.modoLivre = true;
      f.definirAtributo('FOR', -3);
      expect(f.atributo('FOR'), 0);
    });

    test('criatura com Vigor alto tem os PV que a fórmula manda', () {
      final f = FichaOP.novoNpc('c');
      f.classe = 'Ocultista';
      f.nex = 50;
      f.definirAtributo('VIG', 8);
      expect(f.pvMax, 110);
    });
  });

  group('licença da comunidade', () {
    test('o selo está no repositório e declarado como asset', () {
      expect(File('assets/licenca/selo-comunidade.png').existsSync(), isTrue,
          reason: 'o selo tem que ser exibido na "capa" do app');
      expect(File('pubspec.yaml').readAsStringSync(),
          contains('assets/licenca/'));
    });

    test('o nome público do app não usa a marca', () {
      final publicos = [
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        File('web/index.html').readAsStringSync(),
        File('web/manifest.json').readAsStringSync(),
      ];
      for (final texto in publicos) {
        for (final linha in texto.split('\n')) {
          if (!linha.contains('Ordem Paranormal')) continue;
          expect(linha, contains('Licença da Comunidade'),
              reason: 'linha usa a marca fora do aviso: $linha');
        }
      }
      expect(
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
          contains('android:label="Fichário do Outro Lado"'));
    });

    test('poder de origem é notação de regra, não texto de livro', () {
      final origens = jsonDecode(
          File('assets/data/origens.json').readAsStringSync()) as List;
      for (final o in origens) {
        final d = (o as Map)['poderDescricao'] as String;
        expect(d, isNotEmpty, reason: '${o['nome']} sem efeito descrito');
        expect(d.length, lessThanOrEqualTo(130),
            reason: '${o['nome']}: descrição longa demais, virou prosa');
      }
    });
  });
}
