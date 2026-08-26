import '../data/dados_op.dart';

/// A ficha de Ordem Paranormal.
///
/// Guarda tudo num `Map` interno — o mesmo formato viaja para o Hive, para o
/// export JSON e para a mesa online, sem conversões pelo caminho. Os getters
/// tipados existem para as telas não espalharem strings de chave.
class FichaOP {
  final Map<String, dynamic> dados;

  FichaOP(this.dados);

  /// NPC/criatura já nasce em modo livre: nenhuma ameaça do livro cabe no
  /// orçamento de criação de um agente.
  factory FichaOP.novoNpc(String id) {
    final f = FichaOP.nova(id);
    f.ehNpc = true;
    f.modoLivre = true;
    return f;
  }

  factory FichaOP.nova(String id) => FichaOP({
        'id': id,
        'nome': '',
        'jogador': '',
        'classe': 'Mundano',
        'trilha': '',
        'origem': '',
        'patente': 'Recruta',
        'nex': 0,
        'deslocamento': 9,
        'atributos': {'AGI': 1, 'FOR': 1, 'INT': 1, 'PRE': 1, 'VIG': 1},
        'pv': 9,
        'san': 8,
        'pe': 2,
        'defesaBonus': 0, // equipamento e outros, somado a 10+AGI
        'protecao': '',
        'resistencias': '',
        'pericias': <String, dynamic>{}, // nome -> grau (5, 10, 15)
        'ataques': <dynamic>[],
        'habilidades': <dynamic>[],
        'rituais': <dynamic>[],
        'inventario': <dynamic>[],
        'nacionalidade': '',
        'idade': 0,
        'proficiencias': <dynamic>[],
        // o que o mestre vê no painel — e o que o jogador esconde dele
        'emCombate': false,
        'morto': false,
        'ocultarPv': false,
        'ocultarSan': false,
        'ocultarPe': false,
        // aba Sobre
        'historia': '',
        'aparencia': '',
        'primeiroEncontro': '',
        'fobias': '',
        'favoritos': '',
        'personalidade': '',
        'piorPesadelo': '',
        'anotacoes': '',
        'retrato': '', // base64 (jpeg pequeno), vazio = sem retrato
        'criadaEm': DateTime.now().toIso8601String(),
      });

  /// Ficha de NPC/criatura do mestre. NPC não vai para a mesa online: a
  /// mesa publica o personagem do jogador, e o bestiário é do mestre.
  ///
  /// 'pc' (padrão) ou 'npc'. Ficha antiga, sem o campo, entra como 'pc'.
  String get tipo => (dados['tipo'] as String?) ?? 'pc';
  bool get ehNpc => tipo == 'npc';

  set ehNpc(bool v) {
    if (v) {
      dados['tipo'] = 'npc';
    } else {
      dados.remove('tipo');
    }
  }

  /// Regras frouxas: os limites da criação viram aviso em vez de trava.
  /// É o modo do mestre — para montar NPC, criatura, ou um personagem que
  /// já evoluiu além do que a criação permite.
  bool get modoLivre => dados['modoLivre'] == true;
  set modoLivre(bool v) {
    if (v) {
      dados['modoLivre'] = true;
    } else {
      dados.remove('modoLivre');
    }
  }

  String get id => (dados['id'] ?? '') as String;
  String get nome => (dados['nome'] ?? '') as String;
  set nome(String v) => dados['nome'] = v;

  String get jogador => (dados['jogador'] ?? '') as String;
  set jogador(String v) => dados['jogador'] = v;

  String get classe => (dados['classe'] ?? 'Mundano') as String;
  set classe(String v) => dados['classe'] = v;

  String get trilha => (dados['trilha'] ?? '') as String;
  set trilha(String v) => dados['trilha'] = v;

  String get origem => (dados['origem'] ?? '') as String;
  set origem(String v) => dados['origem'] = v;

  String get patente => (dados['patente'] ?? 'Recruta') as String;
  set patente(String v) => dados['patente'] = v;

  int get nex => (dados['nex'] ?? 0) as int;
  set nex(int v) => dados['nex'] = v.clamp(0, 99);

  /// Estágio do Sobrevivente (1 a 5). Ele não sobe de NEX: sobe um estágio
  /// no fim de cada missão. Classe normal ignora este campo.
  int get estagio => ((dados['estagio'] ?? 1) as int).clamp(1, 5);
  set estagio(int v) => dados['estagio'] = v.clamp(1, 5);

  bool get porEstagio =>
      DadosOP.classePorNome(classe)?.porEstagio ?? false;

  int get deslocamento => (dados['deslocamento'] ?? 9) as int;
  set deslocamento(int v) => dados['deslocamento'] = v;

  String get retrato => (dados['retrato'] ?? '') as String;
  set retrato(String v) => dados['retrato'] = v;

  String get anotacoes => (dados['anotacoes'] ?? '') as String;
  set anotacoes(String v) => dados['anotacoes'] = v;

  String get nacionalidade => (dados['nacionalidade'] ?? '') as String;
  set nacionalidade(String v) => dados['nacionalidade'] = v;

  int get idade => (dados['idade'] ?? 0) as int;
  set idade(int v) => dados['idade'] = v;

  /// Campos livres da aba Sobre, no mesmo recorte que a ficha oficial usa.
  static const Map<String, String> camposSobre = {
    'historia': 'História',
    'aparencia': 'Aparência',
    'primeiroEncontro': 'Primeiro encontro paranormal',
    'fobias': 'Doenças, fobias e manias',
    'favoritos': 'Favoritos (pessoas, itens…)',
    'personalidade': 'Personalidade',
    'piorPesadelo': 'Pior pesadelo',
    'anotacoes': 'Anotações',
  };

  String sobre(String chave) => (dados[chave] ?? '') as String;
  void definirSobre(String chave, String valor) => dados[chave] = valor;

  // ---------- estado de mesa ----------

  bool get emCombate => (dados['emCombate'] ?? false) as bool;
  set emCombate(bool v) => dados['emCombate'] = v;

  bool get morto => (dados['morto'] ?? false) as bool;
  set morto(bool v) => dados['morto'] = v;

  /// O jogador pode esconder um recurso do painel do mestre — a ficha
  /// oficial tem esses três botões, e quem joga com sanidade secreta usa.
  bool oculto(String recurso) =>
      (dados['ocultar${recurso[0].toUpperCase()}${recurso.substring(1)}'] ??
          false) as bool;

  void definirOculto(String recurso, bool valor) => dados[
      'ocultar${recurso[0].toUpperCase()}${recurso.substring(1)}'] = valor;

  String get protecao => (dados['protecao'] ?? '') as String;
  set protecao(String v) => dados['protecao'] = v;

  String get resistencias => (dados['resistencias'] ?? '') as String;
  set resistencias(String v) => dados['resistencias'] = v;

  // ---------- atributos ----------

  Map<String, dynamic> get _atributos =>
      (dados['atributos'] ??= <String, dynamic>{}) as Map<String, dynamic>;

  int atributo(String sigla) => (_atributos[sigla] ?? 0) as int;

  /// Teto 5 na ficha comum; no modo livre vai a 20, que é onde as fichas
  /// de ameaça do livro chegam.
  void definirAtributo(String sigla, int valor) =>
      _atributos[sigla] = valor.clamp(0, modoLivre ? 20 : 5);

  // ---------- recursos ----------

  int get pv => (dados['pv'] ?? 0) as int;
  set pv(int v) => dados['pv'] = v.clamp(0, 999);

  int get san => (dados['san'] ?? 0) as int;
  set san(int v) => dados['san'] = v.clamp(0, 999);

  int get pe => (dados['pe'] ?? 0) as int;
  set pe(int v) => dados['pe'] = v.clamp(0, 999);

  /// Máximos: calculados da classe + NEX + atributos, a não ser que o
  /// jogador tenha gravado um valor manual (chaves `pvMaxManual` etc.).
  /// A origem escolhida, se ela existe na lista carregada.
  Origem? get origemAtual {
    for (final o in DadosOP.origens) {
      if (o.nome == origem) return o;
    }
    return null;
  }

  /// Nível de exposição: NEX 5% = 1 … 99% = 20. Vários poderes de origem
  /// somam "por 5% de NEX", que é o mesmo que por nível.
  int get nivelNex {
    if (nex <= 0) return 0;
    if (nex >= 99) return 20;
    return nex ~/ 5;
  }

  int get pvMax =>
      (dados['pvMaxManual'] as int?) ??
      (() {
        final c = DadosOP.classePorNome(classe);
        if (c == null) return pv;
        final o = origemAtual;
        if (o == null) return c.pvMax(nex, atributo('VIG'), estagio: estagio);
        return c.pvMax(nex, atributo('VIG'), estagio: estagio) +
            o.mod('pv') +
            o.mod('pvPorNivel') * nivelNex;
      })();

  int get sanMax =>
      (dados['sanMaxManual'] as int?) ??
      (() {
        final c = DadosOP.classePorNome(classe);
        if (c == null) return san;
        final o = origemAtual;
        var total = c.sanMax(nex, estagio: estagio);
        if (o == null) return total;
        total += o.mod('sanPorNivel') * nivelNex;
        // Cultista Arrependido troca metade da Sanidade pelo poder paranormal
        if (o.flag('sanMetade')) total = total ~/ 2;
        return total;
      })();

  int get peMax =>
      (dados['peMaxManual'] as int?) ??
      (() {
        final c = DadosOP.classePorNome(classe);
        if (c == null) return pe;
        final o = origemAtual;
        var total = c.peMax(nex, atributo('PRE'), estagio: estagio);
        if (o == null) return total;
        total += o.mod('pe');
        // "+1 a cada NEX ímpar (15%, 25%…)" — nível 3, 5, 7…
        final porImpar = o.mod('pePorNivelImpar');
        if (porImpar > 0 && nex >= 15) total += porImpar * ((nex - 5) ~/ 10);
        return total;
      })();

  bool get pvMaxManual => dados['pvMaxManual'] != null;
  bool get sanMaxManual => dados['sanMaxManual'] != null;
  bool get peMaxManual => dados['peMaxManual'] != null;

  void definirMaxManual(String recurso, int? valor) {
    final chave = '${recurso}MaxManual';
    if (valor == null) {
      dados.remove(chave);
    } else {
      dados[chave] = valor;
    }
  }

  int get limitePeTurno =>
      (DadosOP.classePorNome(classe)?.limitePe(nex) ??
          ClasseOP.limitePeTurno(nex)) +
      (origemAtual?.mod('limitePe') ?? 0);

  int get defesaBonus => (dados['defesaBonus'] ?? 0) as int;
  set defesaBonus(int v) => dados['defesaBonus'] = v;

  /// Proteções do livro (OPRPG, tabela de equipamento): leve +5, pesada +10.
  /// O escudo é item à parte e soma por cima da proteção.
  static const Map<String, int> protecoes = {
    'Nenhuma': 0,
    'Leve': 5,
    'Pesada': 10,
  };

  /// Defesa que a proteção vestida dá. Guardada junto do nome para a ficha
  /// antiga — que só tinha o texto livre — continuar abrindo com Defesa 10+Agi.
  int get protecaoDefesa => (dados['protecaoDefesa'] ?? 0) as int;
  set protecaoDefesa(int v) => dados['protecaoDefesa'] = v;

  /// Veste uma proteção da tabela: grava o nome e já aplica a Defesa.
  void vestirProtecao(String nome) {
    protecao = nome == 'Nenhuma' ? '' : nome;
    protecaoDefesa = protecoes[nome] ?? protecaoDefesa;
  }

  /// Qual entrada da tabela está vestida — 'Outra' quando o texto não é
  /// nenhuma delas (ficha antiga, proteção de campanha, item improvisado).
  String get protecaoTipo {
    if (protecao.isEmpty && protecaoDefesa == 0) return 'Nenhuma';
    for (final nome in protecoes.keys) {
      if (nome != 'Nenhuma' && protecao == nome) return nome;
    }
    return 'Outra';
  }

  bool get escudo => dados['escudo'] == true;
  set escudo(bool v) {
    if (v) {
      dados['escudo'] = true;
    } else {
      dados.remove('escudo');
    }
  }

  static const int defesaEscudo = 2;

  /// Ficha de ameaça traz a Defesa impressa em vez de calculada: a criatura
  /// não usa 10+Agilidade. Quando este campo existe, ele manda.
  int? get defesaManual => dados['defesaManual'] as int?;
  set defesaManual(int? v) {
    if (v == null) {
      dados.remove('defesaManual');
    } else {
      dados['defesaManual'] = v;
    }
  }

  /// 10 + Agilidade + proteção + escudo + origem + outros bônus.
  /// Sobrecarregado sofre −5 (OPRPG p. 54).
  int get defesa =>
      (defesaManual ??
          (10 +
              atributo('AGI') +
              protecaoDefesa +
              (escudo ? defesaEscudo : 0) +
              (origemAtual?.mod('defesa') ?? 0) +
              defesaBonus)) -
      (sobrecarregado ? 5 : 0);

  // ---------- bloco de ameaça ----------
  // O que uma ficha de criatura tem e a de agente não: valor de desafio,
  // categoria, presença perturbadora, sentidos e vulnerabilidades. Tudo
  // opcional — ficha de jogador simplesmente não usa nada disso.

  /// Valor de Desafio. Null = ficha sem VD (agente, NPC comum).
  int? get vd => dados['vd'] as int?;
  set vd(int? v) {
    if (v == null) {
      dados.remove('vd');
    } else {
      dados['vd'] = v;
    }
  }

  /// "Criatura", "Pessoa", "Construto"… e o tamanho ("Médio", "Enorme").
  String get categoria => (dados['categoria'] ?? '') as String;
  set categoria(String v) => dados['categoria'] = v;

  String get tamanho => (dados['tamanho'] ?? '') as String;
  set tamanho(String v) => dados['tamanho'] = v;

  /// Elemento do Outro Lado a que a ameaça pertence.
  String get elemento => (dados['elemento'] ?? '') as String;
  set elemento(String v) => dados['elemento'] = v;

  String get sentidos => (dados['sentidos'] ?? '') as String;
  set sentidos(String v) => dados['sentidos'] = v;

  String get vulnerabilidades => (dados['vulnerabilidades'] ?? '') as String;
  set vulnerabilidades(String v) => dados['vulnerabilidades'] = v;

  /// Presença perturbadora: DT, dano mental e o NEX que fica imune.
  /// Vazio = a ameaça não perturba quem a vê.
  String get presenca => (dados['presenca'] ?? '') as String;
  set presenca(String v) => dados['presenca'] = v;

  /// Metade dos PV máximos, arredondada para baixo — o limiar em que a
  /// ameaça fica machucada. O livro imprime esse número em toda ficha.
  int get machucado => pvMax ~/ 2;

  /// Sobrecarregado anda 3m a menos.
  int get deslocamentoEfetivo {
    final d = deslocamento - (sobrecarregado ? 3 : 0);
    return d < 0 ? 0 : d;
  }

  /// Carga: 5 espaços por ponto de Força (Força 0 → 2). O dobro é o teto
  /// absoluto, andando sobrecarregado.
  int get cargaLimite {
    final f = atributo('FOR');
    return f <= 0 ? 2 : 5 * f;
  }

  int get cargaUsada {
    var total = 0;
    for (final item in inventario) {
      total += (item['espacos'] ?? 0) as int;
    }
    return total;
  }

  bool get sobrecarregado => cargaUsada > cargaLimite;

  // ---------- perícias ----------

  Map<String, dynamic> get _pericias =>
      (dados['pericias'] ??= <String, dynamic>{}) as Map<String, dynamic>;

  /// Grau de treinamento: 0 destreinado, 5 treinado, 10 veterano, 15 expert.
  int grauPericia(String nome) => (_pericias[nome] ?? 0) as int;

  void definirGrauPericia(String nome, int grau) {
    if (grau <= 0) {
      _pericias.remove(nome);
    } else {
      _pericias[nome] = grau;
    }
  }

  /// Atributo que rola esta perícia. O livro fixa um por perícia, mas deixa
  /// o mestre trocar caso a caso ("Atletismo com Força para escalar"), e a
  /// habilidade Eclético do Especialista troca por Intelecto. Aqui o jogador
  /// grava a troca na própria perícia em vez de recalcular na mão.
  Map<String, dynamic> get _atributosPericia =>
      (dados['periciaAtributo'] ??= <String, dynamic>{})
          as Map<String, dynamic>;

  String atributoPericia(Pericia p) =>
      (_atributosPericia[p.nome] as String?) ?? p.atributo;

  bool atributoTrocado(Pericia p) => _atributosPericia[p.nome] != null;

  /// [sigla] null (ou igual ao do livro) volta ao padrão.
  void definirAtributoPericia(Pericia p, String? sigla) {
    if (sigla == null || sigla == p.atributo) {
      _atributosPericia.remove(p.nome);
    } else {
      _atributosPericia[p.nome] = sigla;
    }
  }

  /// Dados e bônus do teste desta perícia: (quantidade de d20, melhor?, bônus).
  /// Atributo 0 rola 2d20 e pega o PIOR.
  (int, bool, int) testePericia(Pericia p) {
    final valor = atributo(atributoPericia(p));
    final bonus = grauPericia(p.nome);
    if (valor <= 0) return (2, false, bonus);
    return (valor, true, bonus);
  }

  // ---------- listas ----------

  List<Map<String, dynamic>> _lista(String chave) {
    final bruta = (dados[chave] ??= <dynamic>[]) as List<dynamic>;
    return [
      for (final item in bruta) (item as Map).cast<String, dynamic>(),
    ];
  }

  List<String> get proficiencias => [
        for (final p in (dados['proficiencias'] ??= <dynamic>[]) as List)
          p as String
      ];

  set proficiencias(List<String> v) => dados['proficiencias'] = [...v];

  List<Map<String, dynamic>> get ataques => _lista('ataques');
  List<Map<String, dynamic>> get habilidades => _lista('habilidades');
  List<Map<String, dynamic>> get rituais => _lista('rituais');
  List<Map<String, dynamic>> get inventario => _lista('inventario');

  void adicionarEm(String chave, Map<String, dynamic> item) =>
      (dados[chave] as List<dynamic>).add(item);

  void removerDe(String chave, int indice) =>
      (dados[chave] as List<dynamic>).removeAt(indice);

  void atualizarEm(String chave, int indice, Map<String, dynamic> item) =>
      (dados[chave] as List<dynamic>)[indice] = item;

  /// Aplica o que a origem dá: as duas perícias treinadas e o poder.
  /// Não mexe no que já estiver treinado acima de 5 — quem virou veterano
  /// não volta a treinado só por trocar a origem.
  void aplicarOrigem(Origem origem) {
    for (final nome in origem.pericias) {
      if (grauPericia(nome) < 5) definirGrauPericia(nome, 5);
    }
    if (origem.poder.isEmpty) return;
    final indice = _indiceHabilidade(origem.poder);
    final item = {
      'nome': '${origem.poder} (origem)',
      'descricao': origem.poderDescricao,
    };
    if (indice < 0) {
      adicionarEm('habilidades', item);
    } else {
      // reaplica a origem para corrigir ficha antiga com texto desatualizado
      atualizarEm('habilidades', indice, item);
    }
  }

  /// Aplica o que a classe dá: proficiências, perícias fixas e a habilidade
  /// inicial. As perícias "à escolha" ficam para o jogador marcar.
  void aplicarClasse(ClasseOP classe) {
    final atuais = proficiencias;
    for (final p in classe.proficiencias) {
      if (!atuais.contains(p)) atuais.add(p);
    }
    proficiencias = atuais;

    for (final nome in classe.periciasFixas) {
      if (grauPericia(nome) < 5) definirGrauPericia(nome, 5);
    }
    for (final h in classe.habilidades) {
      final item = {
        'nome': '${h.nome} (classe)',
        'descricao': h.descricao,
      };
      final indice = _indiceHabilidade(h.nome);
      if (indice < 0) {
        adicionarEm('habilidades', item);
      } else {
        atualizarEm('habilidades', indice, item);
      }
    }
  }

  int _indiceHabilidade(String nome) {
    final alvo = nome.toLowerCase();
    final lista = habilidades;
    for (var i = 0; i < lista.length; i++) {
      if (((lista[i]['nome'] ?? '') as String).toLowerCase().contains(alvo)) {
        return i;
      }
    }
    return -1;
  }

  /// Quantas perícias livres a classe ainda dá (base + Intelecto).
  int periciasLivres(ClasseOP classe) =>
      classe.periciasLivresBase + atributo('INT');

  FichaOP copia() => FichaOP(_copiaProfunda(dados));

  static Map<String, dynamic> _copiaProfunda(Map<String, dynamic> m) {
    Object? copiar(Object? v) {
      if (v is Map) {
        return {
          for (final e in v.entries) e.key as String: copiar(e.value),
        };
      }
      if (v is List) return [for (final i in v) copiar(i)];
      return v;
    }

    return copiar(m) as Map<String, dynamic>;
  }
}
