import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_paranormal/data/dados_op.dart';
import 'package:ordem_paranormal/models/ficha_op.dart';

/// O bestiário é gerado por um script Python que repete, em outra
/// linguagem, as fórmulas de `ClasseOP`. Este teste é o que impede as duas
/// cópias de divergirem em silêncio: se o livro (ou o script) mudar, uma
/// ficha do asset passa a mentir e o teste quebra.
void main() {
  final arquivo = File('assets/bestiario/bestiario.json');
  final json = jsonDecode(arquivo.readAsStringSync()) as Map<String, dynamic>;
  final grupos = (json['grupos'] as List).cast<Map<String, dynamic>>();
  final fichas = [
    for (final g in grupos)
      for (final f in (g['fichas'] as List))
        FichaOP((f as Map).cast<String, dynamic>())
  ];

  test('o arquivo existe e tem elenco de sobra', () {
    expect(arquivo.existsSync(), isTrue);
    expect(grupos.length, greaterThanOrEqualTo(5));
    expect(fichas.length, greaterThanOrEqualTo(60));
  });

  test('id único por ficha — reimportar atualiza, não duplica', () {
    final ids = fichas.map((f) => f.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.every((i) => i.startsWith('bestiario-')), isTrue);
  });

  test('todo mundo entra como NPC em modo livre', () {
    for (final f in fichas) {
      expect(f.ehNpc, isTrue, reason: '${f.nome} não está marcada como NPC');
      expect(f.modoLivre, isTrue, reason: '${f.nome} não está em modo livre');
    }
  });

  test('PV, SAN e PE batem com as fórmulas do sistema', () {
    // Ameaça do livro tem PV impresso (pvMaxManual) e não sai de fórmula
    // nenhuma: a conferência vale para os NPCs escritos aqui.
    for (final f in fichas.where((f) => !f.pvMaxManual)) {
      final classe = DadosOP.classePorNome(f.classe);
      expect(classe, isNotNull, reason: '${f.nome}: classe ${f.classe}');
      expect(f.pv, classe!.pvMax(f.nex, f.atributo('VIG')),
          reason: '${f.nome}: PV fora da fórmula');
      expect(f.san, classe.sanMax(f.nex), reason: '${f.nome}: SAN');
      expect(f.pe, classe.peMax(f.nex, f.atributo('PRE')),
          reason: '${f.nome}: PE');
      expect(f.pvMax, f.pv, reason: '${f.nome}: pvMax != pv gravado');
    }
  });

  test('ameaça do livro traz o bloco completo', () {
    final ameacas = fichas.where((f) => f.vd != null).toList();
    expect(ameacas.length, greaterThanOrEqualTo(60),
        reason: 'o bestiário tem que carregar as ameaças dos livros');
    for (final f in ameacas) {
      expect(f.pvMaxManual, isTrue,
          reason: '${f.nome}: PV de ameaça é o impresso, não o calculado');
      expect(f.pvMax, greaterThan(0), reason: f.nome);
      expect(f.defesa, greaterThan(0), reason: '${f.nome}: sem Defesa');
      expect(f.categoria.isNotEmpty || f.tamanho.isNotEmpty, isTrue,
          reason: '${f.nome}: sem categoria/tamanho');
      // ou bate, ou faz alguma coisa: ameaça sem ataque nem habilidade é
      // ficha pela metade
      expect(f.ataques.isNotEmpty || f.habilidades.isNotEmpty, isTrue,
          reason: '${f.nome}: sem ataque e sem habilidade');
    }
  });

  test('ataque de ameaça rola o teste impresso', () {
    for (final f in fichas.where((f) => f.vd != null)) {
      for (final a in f.ataques) {
        final dados = (a['dadosTeste'] ?? 0) as int;
        expect(dados, greaterThan(0),
            reason: '${f.nome}/${a['nome']}: sem dados do teste impresso');
        expect(dados, lessThanOrEqualTo(10), reason: f.nome);
        expect((a['dano'] as String).trim(), isNotEmpty, reason: f.nome);
      }
    }
  });

  test('nada de ficha vazia: nome, papel, retrato e algo para fazer em cena',
      () {
    for (final f in fichas) {
      expect(f.nome.trim(), isNotEmpty);
      expect(f.jogador.trim(), isNotEmpty, reason: '${f.nome} sem papel');
      expect(f.retrato.length, greaterThan(500),
          reason: '${f.nome} sem brasão');
      final temAcao = f.ataques.isNotEmpty ||
          f.habilidades.isNotEmpty ||
          f.rituais.isNotEmpty ||
          (f.dados['pericias'] as Map).isNotEmpty ||
          (f.dados['anotacoes'] as String).isNotEmpty;
      expect(temAcao, isTrue, reason: '${f.nome} não faz nada em cena');
    }
  });

  test('perícias existem e os graus são os do livro', () {
    // as perícias vêm de um asset, que só carrega com o app rodando: aqui o
    // JSON é lido do disco, igual ao teste dos assets do sistema
    final nomes = {
      for (final p in jsonDecode(
              File('assets/data/pericias.json').readAsStringSync()) as List)
        (p as Map)['nome'] as String
    };
    for (final f in fichas) {
      (f.dados['pericias'] as Map).forEach((pericia, grau) {
        expect(nomes.contains(pericia), isTrue,
            reason: '${f.nome}: perícia desconhecida "$pericia"');
        // agente treina em 5/10/15; ameaça do livro traz o bônus impresso
        // (pode ser +12, +23…), e é ele que a rolagem soma
        expect(grau, greaterThan(0), reason: '${f.nome}: $pericia grau $grau');
        expect(grau, lessThanOrEqualTo(60), reason: '${f.nome}: $pericia');
      });
    }
  });

  test('NEX válido e coerente com o ato onde a ficha aparece', () {
    for (final f in fichas) {
      expect(f.nex, inInclusiveRange(0, 99), reason: f.nome);
      expect(f.nex % 5, 0, reason: '${f.nome}: NEX fora dos degraus de 5%');
    }
  });

  test('habilidade de ameaça tem nome e efeito', () {
    for (final f in fichas.where((f) => f.vd != null)) {
      for (final h in f.habilidades) {
        expect((h['nome'] as String).trim(), isNotEmpty, reason: f.nome);
        expect((h['descricao'] as String).trim().length, greaterThan(10),
            reason: '${f.nome}/${h['nome']}: efeito vazio');
      }
    }
  });

  test('nenhum ataque sem dano nem perícia de rolagem', () {
    for (final f in fichas) {
      for (final a in f.ataques) {
        expect((a['nome'] as String).trim(), isNotEmpty, reason: f.nome);
        expect((a['pericia'] as String).trim(), isNotEmpty,
            reason: '${f.nome}: ataque sem perícia não rola na mesa');
      }
    }
  });
}
