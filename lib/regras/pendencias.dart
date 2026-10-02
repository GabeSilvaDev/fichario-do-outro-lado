import '../data/dados_op.dart';
import '../models/ficha_op.dart';
import 'opcionais.dart';

enum Gravidade { erro, aviso, info }

/// Uma coisa que a ficha precisa resolver: fora da regra (erro), faltando
/// escolher (aviso) ou só para saber (info). [aba] diz onde se resolve.
class Pendencia {
  final String id;
  final String texto;
  final Gravidade gravidade;
  final String aba;

  const Pendencia(this.id, this.texto, this.gravidade, this.aba);

  @override
  bool operator ==(Object other) =>
      other is Pendencia && other.id == id && other.texto == texto;

  @override
  int get hashCode => Object.hash(id, texto);
}

/// Confere a ficha inteira contra o livro. Tudo derivado: basta chamar de
/// novo depois de qualquer mudança. NPC e modo livre não são cobrados.
List<Pendencia> pendenciasDe(FichaOP f) {
  if (f.ehNpc) return const [];
  if (f.modoLivre) {
    return const [
      Pendencia(
        'livre',
        'Modo livre: as regras de criação não são cobradas.',
        Gravidade.info,
        'geral',
      ),
    ];
  }
  final c = f.classeOP;
  if (c == null) {
    return [
      Pendencia(
        'classe',
        'Classe "${f.classe}" não existe nas regras: '
            'escolha uma para a ficha calcular.',
        Gravidade.erro,
        'geral',
      ),
    ];
  }
  final saida = <Pendencia>[];
  void add(String id, String texto, Gravidade g, String aba) =>
      saida.add(Pendencia(id, texto, g, aba));

  _classeENex(f, c, add);
  _atributos(f, c, add);
  _pericias(f, c, add);
  _trilhaEPoderes(f, c, add);
  _rituais(f, c, add);
  _equipamento(f, c, add);
  _recursos(f, add);
  _opcionais(f, add);
  return saida;
}

typedef _Add = void Function(String id, String texto, Gravidade g, String aba);

void _classeENex(FichaOP f, ClasseOP c, _Add add) {
  if (f.origem.isEmpty) {
    add('origem', 'Escolha a origem.', Gravidade.aviso, 'geral');
  } else if (f.origemAtual == null && DadosOP.origens.isNotEmpty) {
    add(
      'origem',
      'Origem "${f.origem}" fora da lista: o poder dela não '
          'entra nas contas.',
      Gravidade.info,
      'geral',
    );
  }
  if (c.nome == 'Mundano' && f.nex > 0) {
    add(
      'nex',
      'Mundano não tem NEX: a partir de 5% escolha combatente, '
          'especialista ou ocultista.',
      Gravidade.erro,
      'geral',
    );
  }
  if (c.agente && f.nex == 0) {
    add(
      'nex',
      'Agente começa em NEX 5%. Em 0%, a classe é Mundano '
          '(ou Sobrevivente).',
      Gravidade.erro,
      'geral',
    );
  }
  if (DadosOP.patentes.isNotEmpty &&
      DadosOP.patentePorNome(f.patente) == null &&
      c.agente) {
    add(
      'patente',
      'Patente "${f.patente}" fora da tabela.',
      Gravidade.aviso,
      'geral',
    );
  }
}

void _atributos(FichaOP f, ClasseOP c, _Add add) {
  const siglas = ['AGI', 'FOR', 'INT', 'PRE', 'VIG'];
  final faixa = RegrasOpcionais.faixa(f.faixaEtaria);
  final forcados = {...?faixa?.tetoAtributo.keys};

  var base = c.pontosAtributo;
  var aumentos = c.aumentosAtributo(f.nex, estagio: f.estagio);
  if (f.exSobrevivente > 0) {
    base = 3;
    aumentos += f.exSobrevivente >= 3 ? 1 : 0;
  }

  var soma = 0;
  var zerosVoluntarios = 0;
  var acimaDe3 = 0;
  for (final s in siglas) {
    final v = f.atributo(s);
    soma += v;
    if (v == 0 && !forcados.contains(s)) zerosVoluntarios++;
    if (v > 3) acimaDe3 += v - 3;
    final tetoFaixa = faixa?.tetoAtributo[s];
    if (tetoFaixa != null && v > tetoFaixa) {
      add(
        'attr-teto-$s',
        '$s passa do teto da faixa etária '
            '(${faixa!.nome}: máx. $tetoFaixa).',
        Gravidade.erro,
        'geral',
      );
    }
    if (v > c.tetoAumento) {
      add(
        'attr-teto-$s',
        '$s acima de ${c.tetoAumento}: '
            '${c.porEstagio ? 'o Sobrevivente não passa de 3' : 'o Aumento de '
                      'Atributo não leva além de 5'}.',
        Gravidade.erro,
        'geral',
      );
    }
    if ((faixa?.semAumento.contains(s) ?? false) && v > 3) {
      add(
        'attr-idoso-$s',
        'Idoso: Aumento de Atributo não sobe $s.',
        Gravidade.erro,
        'geral',
      );
    }
  }
  final inicial = siglas.length - forcados.length;
  final gastos = soma - inicial;
  final permitidos = base + (zerosVoluntarios > 0 ? 1 : 0) + aumentos;

  if (zerosVoluntarios > 1) {
    add(
      'attr-zeros',
      'Só UM atributo pode ser reduzido a 0.',
      Gravidade.erro,
      'geral',
    );
  }
  if (gastos > permitidos) {
    add(
      'attr-pontos',
      'Atributos: ${gastos - permitidos} ponto(s) além do '
          'permitido ($base da criação${aumentos > 0 ? ' + $aumentos de Aumento '
                    'de Atributo' : ''}).',
      Gravidade.erro,
      'geral',
    );
  } else if (gastos < permitidos) {
    add(
      'attr-pontos',
      'Atributos: ${permitidos - gastos} ponto(s) para '
          'distribuir${aumentos > 0 ? ' (inclui Aumento de Atributo do NEX '
                    '${f.nex}%: +1 em um atributo, até ${c.tetoAumento})' : ''}.',
      Gravidade.aviso,
      'geral',
    );
  }
  if (acimaDe3 > aumentos) {
    add(
      'attr-acima3',
      'Acima de 3 só com Aumento de Atributo: '
          '${acimaDe3 - aumentos} ponto(s) sem aumento que os cubra.',
      Gravidade.erro,
      'geral',
    );
  }
}

void _pericias(FichaOP f, ClasseOP c, _Add add) {
  final graus = <String, int>{
    for (final p in DadosOP.pericias)
      if (f.grauPericia(p.nome) > 0) p.nome: f.grauPericia(p.nome),
  };
  final treinadas = graus.length;
  final e = f.efeitosBase;
  final intelecto = f.atributo('INT');
  final faixa = RegrasOpcionais.faixa(f.faixaEtaria);

  // Perícias da origem: 2 (criança 0–1, adolescente 1–2 conforme escolha).
  final beneficios = faixa?.beneficiosOrigem ?? 3;
  final origemMin = beneficios >= 3 ? 2 : (beneficios == 2 ? 1 : 0);
  final origemMax = beneficios >= 2 ? 2 : 1;

  int classe;
  if (f.exSobrevivente > 0 && c.agente) {
    final t = DadosOP.transicaoSobrevivente(c.nome);
    classe =
        1 +
        intelecto +
        (t['treinaPericias'] ?? 0) +
        (c.nome == 'Ocultista' ? 2 : 0);
  } else {
    classe =
        c.periciasFixas.length +
        c.periciasEscolha.length +
        c.periciasLivresBase +
        intelecto;
  }
  final poderes = e.treinaPericias + e.treina.length;
  final minimo = origemMin + classe + poderes;
  final maximo = origemMax + classe + poderes;

  if (treinadas < minimo) {
    add(
      'pericias-n',
      'Perícias: pode treinar mais ${minimo - treinadas} '
          '(origem, ${c.nome.toLowerCase()} + Int $intelecto'
          '${poderes > 0 ? ', poderes' : ''}).',
      Gravidade.aviso,
      'pericias',
    );
  } else if (treinadas > maximo) {
    add(
      'pericias-n',
      'Perícias: ${treinadas - maximo} treinada(s) além do '
          'permitido. Subir Int dá +1; o resto vem de poderes.',
      Gravidade.erro,
      'pericias',
    );
  }

  if (c.nome == 'Combatente' && f.exSobrevivente == 0) {
    for (final par in c.periciasEscolha) {
      if (!par.any((p) => (graus[p] ?? 0) > 0)) {
        add(
          'escolha-${par.first}',
          'Combatente: treine ${par.join(' ou ')}.',
          Gravidade.aviso,
          'pericias',
        );
      }
    }
  }

  if (!c.agente) {
    for (final g in graus.entries) {
      if (g.value > 5) {
        add(
          'grau-civil-${g.key}',
          '${g.key}: ${c.nome} não passa de '
              'treinado.',
          Gravidade.erro,
          'pericias',
        );
      }
    }
    return;
  }

  var subidas = 0;
  var experts = 0;
  for (final g in graus.entries) {
    if (g.value >= 10) subidas += g.value >= 15 ? 2 : 1;
    if (g.value >= 15) experts++;
    if (g.value >= 15 && f.nex < 70) {
      add(
        'grau-${g.key}',
        '${g.key} expert (+15) só a partir de NEX 70%.',
        Gravidade.erro,
        'pericias',
      );
    } else if (g.value >= 10 && f.nex < 35) {
      add(
        'grau-${g.key}',
        '${g.key} veterano (+10) só a partir de NEX 35%.',
        Gravidade.erro,
        'pericias',
      );
    }
  }
  final porGrau = c.periciasPorGrau + intelecto;
  final treinamentos = f.habilidades
      .where((h) => h['poder'] == 'Treinamento em Perícia')
      .length;
  final permitidas = c.grausTreinamento(f.nex) * porGrau + 2 * treinamentos;
  if (subidas > permitidas) {
    add(
      'grau-n',
      'Grau de Treinamento: ${subidas - permitidas} grau(s) além '
          'do que o NEX dá ($porGrau perícias em 35% e em 70%).',
      Gravidade.erro,
      'pericias',
    );
  } else if (subidas < c.grausTreinamento(f.nex) * porGrau) {
    add(
      'grau-n',
      'Grau de Treinamento: suba mais '
          '${c.grausTreinamento(f.nex) * porGrau - subidas} grau(s) '
          '($porGrau perícias por Grau, em NEX 35% e 70%).',
      Gravidade.aviso,
      'pericias',
    );
  }
  if (experts > porGrau + 2 * treinamentos) {
    add(
      'grau-experts',
      'Expert: no máximo $porGrau perícias (as mesmas '
          'subidas nos dois Graus de Treinamento).',
      Gravidade.erro,
      'pericias',
    );
  }
}

void _trilhaEPoderes(FichaOP f, ClasseOP c, _Add add) {
  final trilhasDaClasse = DadosOP.trilhasDe(c.nome);
  if (c.agente) {
    if (f.nex >= 10 && f.trilha.isEmpty) {
      add(
        'trilha',
        'NEX 10%: escolha a trilha — as habilidades dela entram '
            'sozinhas.',
        Gravidade.aviso,
        'geral',
      );
    }
    if (f.nex < 10 && f.trilha.isNotEmpty) {
      add('trilha', 'Trilha só a partir de NEX 10%.', Gravidade.erro, 'geral');
    }
  } else if (c.porEstagio) {
    if (f.estagio >= 2 && f.trilha.isEmpty) {
      add(
        'trilha',
        'Estágio 2: escolha a trilha do Sobrevivente.',
        Gravidade.aviso,
        'geral',
      );
    }
  }
  if (f.trilha.isNotEmpty &&
      trilhasDaClasse.isNotEmpty &&
      !trilhasDaClasse.any((t) => t.nome == f.trilha)) {
    add(
      'trilha-fora',
      'Trilha "${f.trilha}" não é de ${c.nome.toLowerCase()} '
          'no catálogo: as habilidades dela não entram sozinhas.',
      Gravidade.info,
      'geral',
    );
  }
  final faltamTrilha = [
    for (final p in f.habilidadesDeTrilhaDevidas)
      if (!f.habilidades.any((h) => h['nome'] == p.nome)) p.nome,
  ];
  if (faltamTrilha.isNotEmpty) {
    add(
      'trilha-hab',
      'Faltam habilidades de trilha: '
          '${faltamTrilha.join(', ')}.',
      Gravidade.aviso,
      'poderes',
    );
  }

  if (c.agente) {
    if (f.nex >= 50 && f.afinidade.isEmpty) {
      add(
        'afinidade',
        'NEX 50%: escolha o elemento de afinidade.',
        Gravidade.aviso,
        'poderes',
      );
    }
    if (f.nex < 50 && f.afinidade.isNotEmpty) {
      add(
        'afinidade',
        'Afinidade só a partir de NEX 50%.',
        Gravidade.erro,
        'poderes',
      );
    }
  }

  // Poderes à escolha: de classe (inclui Transcender/paranormal e gerais),
  // Versatilidade em 50% e o de Vivência (idade adulta).
  if (c.agente) {
    final poderClasse = 'Poder de ${c.nome.toLowerCase()}';
    var esperado = 0;
    for (final n in ClasseOP.reguaNex) {
      if (n <= f.nex && c.marcos(n).contains(poderClasse)) esperado++;
    }
    if (f.nex >= 50) esperado++;
    esperado += RegrasOpcionais.faixa(f.faixaEtaria)?.poderesExtras ?? 0;
    final tem = f.habilidades.where((h) {
      final tipo = '${h['tipoPoder'] ?? ''}';
      if (const {'classe', 'paranormal', 'geral'}.contains(tipo)) return true;
      return tipo == 'trilha' &&
          h['automatica'] != true &&
          h['trilha'] != f.trilha;
    }).length;
    if (tem < esperado) {
      add(
        'poderes-n',
        'Poderes: faltam ${esperado - tem} (de '
            '${c.nome.toLowerCase()}, paranormal, geral ou Versatilidade). '
            'Poder digitado à mão só conta se tiver o tipo marcado.',
        Gravidade.aviso,
        'poderes',
      );
    } else if (tem > esperado) {
      add(
        'poderes-n',
        'Poderes: ${tem - esperado} a mais que o NEX '
            '${f.nex}% dá.',
        Gravidade.aviso,
        'poderes',
      );
    }
  }

  // Pré-requisitos e repetição.
  final contagem = <String, int>{};
  for (final h in f.habilidades) {
    final nome = '${h['poder'] ?? ''}';
    if (nome.isEmpty) continue;
    contagem[nome] = (contagem[nome] ?? 0) + 1;
    final p = DadosOP.poderPorNome(nome);
    if (p == null) continue;
    final falta = requisitoQueFalta(f, p.requisitosRegra);
    if (falta != null && h['automatica'] != true) {
      add('req-$nome', '$nome exige $falta.', Gravidade.erro, 'poderes');
    }
  }
  for (final e in contagem.entries) {
    final p = DadosOP.poderPorNome(e.key);
    if (p != null && !p.repetivel && e.value > 1) {
      add(
        'rep-${e.key}',
        '${e.key} não pode ser escolhido de novo.',
        Gravidade.erro,
        'poderes',
      );
    }
  }
}

/// O primeiro pré-requisito que a ficha não cumpre, em texto; null se
/// cumpre todos.
String? requisitoQueFalta(FichaOP f, Map<String, dynamic> r) {
  final atributos = r['atributos'];
  if (atributos is Map) {
    for (final a in atributos.entries) {
      final v = a.value is num ? (a.value as num).toInt() : 0;
      if (f.atributo('${a.key}') < v) return '${a.key} $v';
    }
  }
  final nex = r['nex'];
  if (nex is num && f.nex < nex) return 'NEX ${nex.toInt()}%';
  final treinadas = r['treinadas'];
  if (treinadas is List) {
    for (final t in treinadas) {
      if (f.grauPericia('$t') < 5) return 'treino em $t';
    }
  }
  final poderes = r['poderes'];
  if (poderes is List) {
    for (final p in poderes) {
      if (!f.habilidades.any((h) => h['poder'] == p || h['nome'] == p)) {
        return 'o poder $p';
      }
    }
  }
  final elemento = r['elemento'];
  if (elemento is Map) {
    for (final e in elemento.entries) {
      final precisa = e.value is num ? (e.value as num).toInt() : 1;
      final tem = f.habilidades
          .where(
            (h) =>
                h['elemento'] == e.key &&
                const {'paranormal'}.contains(h['tipoPoder']),
          )
          .length;
      if (tem < precisa) return '$precisa poder(es) de ${e.key}';
    }
  }
  if (r['afinidade'] == true && f.afinidade.isEmpty) return 'afinidade';
  return null;
}

/// Quantos rituais a ficha conhece pela regra: os do Ocultista pelo NEX
/// (p. 32), os de Aprender Ritual até o Intelecto (p. 119) e o do Iniciado
/// (Esotérico, SAH p. 32). Devolve (limite, da classe, do poder).
(int, int, int) limiteDeRituais(FichaOP f) {
  final c = f.classeOP;
  final aprender = f.habilidades
      .where((h) => h['poder'] == 'Aprender Ritual')
      .length;
  final intelecto = f.atributo('INT');
  final daClasse = c?.nome == 'Ocultista' ? DadosOP.rituaisPorNex(f.nex) : 0;
  final doPoder = aprender < intelecto ? aprender : intelecto;
  final extras = f.habilidades
      .where((h) => h['poder'] == 'Iniciado' || h['nome'] == 'Iniciado')
      .length;
  return (daClasse + doPoder + extras, daClasse, doPoder);
}

/// Círculo mais alto que a ficha pode aprender neste NEX. Ocultista pela
/// classe; os outros pelo Aprender Ritual: 2º em 45%, 3º em 75% (p. 114).
int circuloMaximoDe(FichaOP f) => f.classeOP?.nome == 'Ocultista'
    ? DadosOP.circuloMaximoPorNex(f.nex)
    : (f.nex >= 75
          ? 3
          : f.nex >= 45
          ? 2
          : 1);

void _rituais(FichaOP f, ClasseOP c, _Add add) {
  final rituais = f.rituais;
  final aprender = f.habilidades
      .where((h) => h['poder'] == 'Aprender Ritual')
      .length;
  final (limite, daClasse, doPoder) = limiteDeRituais(f);

  if (rituais.length > limite) {
    add(
      'rituais-n',
      'Rituais: ${rituais.length - limite} além do que a ficha '
          'conhece ($limite: ${c.nome == 'Ocultista' ? '$daClasse do NEX' : ''}'
          '${doPoder > 0 ? ' + $doPoder de Aprender Ritual' : ''}).',
      c.nome == 'Ocultista' || aprender > 0 ? Gravidade.erro : Gravidade.aviso,
      'poderes',
    );
  } else if (rituais.length < limite) {
    add(
      'rituais-n',
      'Rituais: pode aprender mais ${limite - rituais.length}.',
      Gravidade.aviso,
      'poderes',
    );
  }

  final circulo = circuloMaximoDe(f);
  final vistos = <String>{};
  for (final r in rituais) {
    final nome = '${r['nome'] ?? ''}';
    if (!vistos.add(nome)) {
      add(
        'ritual-dup-$nome',
        'Ritual repetido: $nome.',
        Gravidade.erro,
        'poderes',
      );
    }
    final n = circuloDoRitual(r);
    if (n > circulo) {
      add(
        'ritual-circ-$nome',
        '$nome é de $nº círculo; em NEX ${f.nex}% o '
            'máximo é o $circuloº.',
        Gravidade.erro,
        'poderes',
      );
    }
  }
}

int circuloDoRitual(Map<String, dynamic> r) =>
    int.tryParse('${r['circulo'] ?? ''}'.replaceAll(RegExp(r'\D'), '')) ?? 1;

/// Custo em PE do ritual como a ficha guarda ("3 PE", 3…).
int custoDoRitual(Map<String, dynamic> r) =>
    int.tryParse('${r['custo'] ?? ''}'.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

void _equipamento(FichaOP f, ClasseOP c, _Add add) {
  if (f.acimaDaCargaMaxima) {
    add(
      'carga',
      'Carga ${f.cargaUsada} passa do dobro do limite '
          '(${f.cargaMaxima}): não dá para carregar.',
      Gravidade.erro,
      'inventario',
    );
  } else if (f.sobrecarregado) {
    add(
      'carga',
      'Sobrecarregado (${f.cargaUsada}/${f.cargaLimite}): −5 '
          'Defesa, −3m e −5 em Acrobacia, Crime e Furtividade.',
      Gravidade.aviso,
      'inventario',
    );
  }

  final porCategoria = contarCategorias(f);
  if (!c.agente || f.ehNpc) {
    final acima =
        (porCategoria['II'] ?? 0) +
        (porCategoria['III'] ?? 0) +
        (porCategoria['IV'] ?? 0);
    if ((porCategoria['I'] ?? 0) > 1 || acima > 0) {
      add(
        'itens-civil',
        'Sem patente: 1 item de categoria I e quantos de '
            'categoria 0 quiser.',
        Gravidade.erro,
        'inventario',
      );
    }
  } else {
    final patente = DadosOP.patentePorNome(f.patente);
    if (patente != null) {
      for (final cat in const ['I', 'II', 'III', 'IV']) {
        final tem = porCategoria[cat] ?? 0;
        final pode = patente.limites[cat] ?? 0;
        if (tem > pode) {
          add(
            'itens-$cat',
            'Categoria $cat: $tem item(ns), a patente '
                '${patente.nome} permite $pode.',
            Gravidade.erro,
            'inventario',
          );
        }
      }
      final amaldicoados = f.inventario
          .where((i) => i['amaldicoado'] == true)
          .length;
      if (amaldicoados > 0 && patente.pp < 50) {
        add(
          'amaldicoado',
          'Item amaldiçoado só a partir de Agente Especial.',
          Gravidade.erro,
          'inventario',
        );
      }
    }
    if (f.pp > 0 || f.patente != 'Recruta') {
      final certa = f.patentePelosPp;
      if (certa != f.patente) {
        add(
          'patente-pp',
          'Com ${f.pp} PP a patente é $certa (vale a partir '
              'da próxima missão).',
          Gravidade.aviso,
          'geral',
        );
      }
    }
  }

  final prot = f.semProficienciaEmProtecao;
  if (prot != null) {
    add(
      'prof-protecao',
      'Sem proficiência em $prot: −2 d20 em testes de '
          'For e Agi (já aplicado).',
      Gravidade.aviso,
      'geral',
    );
  }
  for (final a in f.ataques) {
    final falta = f.semProficienciaNaArma(a);
    if (falta != null) {
      add(
        'prof-${a['nome']}',
        '${a['nome']}: sem proficiência em $falta, '
            '−2 d20 no ataque (já aplicado).',
        Gravidade.aviso,
        'ataques',
      );
    }
  }
}

/// Itens por categoria que contam no limite da patente: inventário,
/// proteção vestida (leve I, pesada II) e escudo (I).
Map<String, int> contarCategorias(FichaOP f) {
  final conta = <String, int>{};
  void soma(String cat) {
    if (cat.isEmpty || cat == '0') return;
    conta[cat] = (conta[cat] ?? 0) + 1;
  }

  for (final i in f.inventario) {
    if (i['foraDoLimite'] == true) continue;
    soma('${i['categoria'] ?? ''}');
  }
  if (f.protecaoTipo == 'Leve') soma('I');
  if (f.protecaoTipo == 'Pesada') soma('II');
  if (f.escudo) soma('I');
  return conta;
}

void _recursos(FichaOP f, _Add add) {
  for (final (recurso, rotulo) in const [
    ('pv', 'PV'),
    ('san', 'SAN'),
    ('pe', 'PE'),
  ]) {
    if (f.dados['${recurso}MaxManual'] == null) continue;
    final fixo = switch (recurso) {
      'pv' => f.pvMax,
      'san' => f.sanMax,
      _ => f.peMax,
    };
    final regra = switch (recurso) {
      'pv' => f.pvMaxCalculado(),
      'san' => f.sanMaxCalculado(),
      _ => f.peMaxCalculado(),
    };
    if (fixo != regra) {
      add(
        'max-$recurso',
        '$rotulo máximo fixo em $fixo; pela regra seria '
            '$regra.',
        Gravidade.info,
        'geral',
      );
    }
  }
}

void _opcionais(FichaOP f, _Add add) {
  final faixa = RegrasOpcionais.faixa(f.faixaEtaria);
  if (faixa != null && faixa.desvantagens != f.desvantagens.length) {
    add(
      'desvantagens',
      '${faixa.nome}: escolha ${faixa.desvantagens} '
          'desvantagem(ns) de idade (tem ${f.desvantagens.length}).',
      Gravidade.aviso,
      'sobre',
    );
  }
}
