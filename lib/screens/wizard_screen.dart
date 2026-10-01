import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/dados_op.dart';
import '../models/ficha_op.dart';
import '../store/ficha_store.dart';
import '../theme.dart';
import '../widgets/retrato.dart';
import 'catalogo_screen.dart';
import 'ficha_screen.dart';

/// Assistente de criação de personagem — as regras do livro, na ordem em que
/// o livro pede.
///
/// Só CRIA. Depois de pronta, a ficha vive na [FichaScreen], onde tudo é
/// editável: subir NEX, treinar perícia nova, trocar equipamento. Aqui o
/// aperto das regras é proposital — cada passo só libera o seguinte quando
/// está fechado, para ninguém entrar na mesa com uma ficha ilegal sem saber.
class WizardScreen extends StatefulWidget {
  /// Começa como ficha de NPC/criatura do mestre (já em modo livre).
  final bool npc;

  const WizardScreen({super.key, this.npc = false});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  late final FichaOP f = widget.npc
      ? FichaOP.novoNpc(const Uuid().v4())
      : FichaOP.nova(const Uuid().v4());

  /// Regras frouxas. NPC já começa assim; o mestre liga para qualquer ficha
  /// pelo botão de regras da barra.
  late bool _livre = widget.npc;

  int passo = 0;

  static const List<String> _titulos = [
    'Identidade',
    'Origem',
    'Classe e NEX',
    'Atributos',
    'Perícias',
    'Conferir',
  ];

  /// Escolhas do passo de perícias, separadas por procedência: assim dá para
  /// mostrar de onde veio cada treinamento e refazer só o que é do jogador.
  final Map<int, String> _escolhasDeClasse = {};
  final Set<String> _livres = {};

  /// Grau de Treinamento distribuído no assistente: quantos graus cada
  /// perícia treinada sobe (1 = veterana, 2 = expert).
  final Map<String, int> _graus = {};

  /// O que baixar o NEX tirou, para avisar quando soltar a régua.
  final Set<String> _cortadoPeloNex = {};

  /// Rituais do Ocultista, no formato que a ficha guarda em `rituais`.
  final List<Map<String, dynamic>> _rituais = [];

  bool get _ocultista => f.classe == 'Ocultista';

  /// Quantos rituais o Ocultista conhece neste NEX (0 para outras classes).
  int get _rituaisDisponiveis => _ocultista ? DadosOP.rituaisPorNex(f.nex) : 0;

  int get _circuloMaximo => DadosOP.circuloMaximoPorNex(f.nex);

  static int _circuloDe(Map<String, dynamic> r) =>
      int.tryParse('${r['circulo']}'.replaceAll(RegExp(r'\D'), '')) ?? 1;

  /// Baixar o NEX pode tirar círculos e vagas: corta o que sobrou.
  void _ajustarRituaisAoNex() {
    if (_livre) return;
    _rituais.removeWhere((r) => _circuloDe(r) > _circuloMaximo);
    while (_rituais.length > _rituaisDisponiveis) {
      _rituais.removeLast();
    }
  }

  ClasseOP get classe =>
      DadosOP.classePorNome(f.classe) ?? DadosOP.classes.first;

  Origem? get origem {
    for (final o in DadosOP.origens) {
      if (o.nome == f.origem) return o;
    }
    return null;
  }

  /// Perícias que a origem treina — não contam no limite da classe.
  Set<String> get _daOrigem => {...(origem?.pericias ?? const [])};

  /// Aumentos de Atributo que o NEX escolhido já deu (20%, 50%, 80%, 95%).
  int get _aumentos =>
      _livre ? 0 : classe.aumentosAtributo(f.nex, estagio: f.estagio);

  int get _pontosAtributoTotais {
    final zerado = [
      'AGI',
      'FOR',
      'INT',
      'PRE',
      'VIG',
    ].any((s) => f.atributo(s) == 0);
    return classe.pontosAtributo + (zerado ? 1 : 0) + _aumentos;
  }

  /// Quanto os atributos passam de 3 — só os aumentos levam além disso.
  int get _acimaDe3 {
    var soma = 0;
    for (final s in ['AGI', 'FOR', 'INT', 'PRE', 'VIG']) {
      final v = f.atributo(s);
      if (v > 3) soma += v - 3;
    }
    return soma;
  }

  int get _pontosAtributoGastos {
    var soma = 0;
    for (final s in ['AGI', 'FOR', 'INT', 'PRE', 'VIG']) {
      soma += f.atributo(s);
    }
    return soma - 5;
  }

  int get _pontosAtributoRestantes =>
      _pontosAtributoTotais - _pontosAtributoGastos;

  /// Origem que dá menos de duas perícias (Amnésico, Profetizado): as que
  /// faltam o jogador escolhe aqui, combinando com o mestre.
  int get _faltamDaOrigem {
    final o = origem;
    if (o == null) return 0;
    final n = 2 - o.pericias.length;
    return n < 0 ? 0 : n;
  }

  int get _livresDisponiveis =>
      classe.periciasLivresBase + f.atributo('INT') + _faltamDaOrigem;

  /// Graus de Treinamento que o NEX já deu (35% e 70%).
  int get _eventosGrau => _livre ? 0 : classe.grausTreinamento(f.nex);

  /// Perícias por Grau de Treinamento: base da classe + Intelecto.
  int get _periciasPorGrau => classe.periciasPorGrau + f.atributo('INT');

  int get _grausTotais => _eventosGrau * _periciasPorGrau;

  int get _grausUsados => _graus.values.fold(0, (a, b) => a + b);

  Set<String> get _treinadas => {
    ..._daOrigem,
    ...classe.periciasFixas,
    ..._escolhasDeClasse.values,
    ..._livres,
  };

  /// Solta o grau de quem deixou de ser treinada ou passou do que o NEX dá.
  void _ajustarGraus() {
    final treinadas = _treinadas;
    _graus.removeWhere((p, g) => !treinadas.contains(p) || g > _eventosGrau);
    var experts = _graus.values.where((g) => g == 2).length;
    for (final p in _graus.keys.toList().reversed) {
      if (experts <= _periciasPorGrau) break;
      if (_graus[p] == 2) {
        _graus[p] = 1;
        experts--;
      }
    }
    while (_grausUsados > _grausTotais && _graus.isNotEmpty) {
      _graus.remove(_graus.keys.last);
    }
  }

  /// O próximo grau desta perícia, ou 0 se não cabe mais. Cada Grau de
  /// Treinamento sobe perícias diferentes, então só [_periciasPorGrau]
  /// delas chegam a expert.
  int _proximoGrau(String pericia) {
    final atual = _graus[pericia] ?? 0;
    final novo = atual + 1;
    if (novo > _eventosGrau || _grausUsados >= _grausTotais) return 0;
    if (novo == 2) {
      final experts = _graus.values.where((g) => g == 2).length;
      if (experts >= _periciasPorGrau) return 0;
    }
    return novo;
  }

  /// O passo atual está fechado? É o que libera o botão "Próximo".
  ///
  /// No modo livre nada trava: os limites viram aviso, e quem monta a ficha
  /// decide. É assim que se monta uma criatura com Vigor 8 ou um NPC sem
  /// origem nenhuma.
  bool get _passoCompleto => _completoEm(passo);

  bool _completoEm(int p) {
    if (_livre) return true;
    switch (p) {
      case 0:
        return f.nome.trim().isNotEmpty;
      case 1:
        return f.origem.isNotEmpty;
      case 2:
        return f.classe.isNotEmpty &&
            (!_ocultista ||
                (_rituais.length == _rituaisDisponiveis &&
                    _rituais.every((r) => _circuloDe(r) <= _circuloMaximo)));
      case 3:
        return _pontosAtributoRestantes == 0 && _acimaDe3 <= _aumentos;
      case 4:
        return _escolhasDeClasse.length == classe.periciasEscolha.length &&
            _livres.length == _livresDisponiveis &&
            _grausUsados == _grausTotais;
      default:
        return true;
    }
  }

  String? get _pendencia {
    if (_livre && passo == 0) {
      return f.nome.trim().isEmpty
          ? 'Sem nome, a ficha entra como "Sem nome".'
          : null;
    }
    switch (passo) {
      case 0:
        return f.nome.trim().isEmpty ? 'Dê um nome ao personagem.' : null;
      case 1:
        return f.origem.isEmpty ? 'Escolha uma origem.' : null;
      case 2:
        if (!_ocultista) return null;
        final faltam = _rituaisDisponiveis - _rituais.length;
        if (faltam > 0) return 'Escolha mais $faltam ritual(is).';
        if (faltam < 0) return 'Remova ${-faltam} ritual(is).';
        return null;
      case 3:
        final r = _pontosAtributoRestantes;
        if (r > 0) return 'Ainda faltam $r ponto(s) para distribuir.';
        if (r < 0) return 'Você passou ${-r} ponto(s) do limite.';
        final acima = _acimaDe3 - _aumentos;
        if (acima > 0) {
          return 'Acima de 3 só com Aumento de Atributo: tire $acima.';
        }
        return null;
      case 4:
        final faltamEscolhas =
            classe.periciasEscolha.length - _escolhasDeClasse.length;
        if (faltamEscolhas > 0) {
          return 'Resolva as escolhas da classe.';
        }
        final faltam = _livresDisponiveis - _livres.length;
        if (faltam > 0) return 'Escolha mais $faltam perícia(s).';
        if (faltam < 0) return 'Desmarque ${-faltam} perícia(s).';
        final graus = _grausTotais - _grausUsados;
        if (graus > 0) return 'Grau de Treinamento: suba mais $graus.';
        return null;
      default:
        return null;
    }
  }

  void _trocarClasse(String nome) {
    final perdeu =
        _escolhasDeClasse.isNotEmpty ||
        _livres.isNotEmpty ||
        _rituais.isNotEmpty ||
        _graus.isNotEmpty;
    setState(() {
      f.classe = nome;
      _escolhasDeClasse.clear();
      _livres.clear();
      _rituais.clear();
      _graus.clear();
      if (!DadosOP.trilhasDe(nome).any((t) => t.nome == f.trilha)) {
        f.trilha = '';
      }
    });
    if (perdeu) {
      _avisar(
        'Classe trocada para $nome: escolhas de perícia, graus e '
        'rituais recomeçam.',
      );
    }
  }

  void _avisar(String texto) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  void _trocarOrigem(String nome) {
    setState(() {
      f.origem = nome;
      _livres.removeWhere(_daOrigem.contains);
      _ajustarGraus();
    });
  }

  Future<void> _criar() async {
    // Ligar e desligar o modo livre no meio do caminho não pode criar
    // ficha ilegal: tudo é conferido de novo aqui.
    if (!_livre) {
      for (var p = 0; p < 5; p++) {
        if (!_completoEm(p)) {
          setState(() => passo = p);
          _avisar('Falta resolver: ${_titulos[p]}.');
          return;
        }
      }
    }
    f.aplicarClasse(classe);
    if (origem != null) f.aplicarOrigem(origem!);

    for (final nome in _escolhasDeClasse.values) {
      f.definirGrauPericia(nome, 5);
    }
    for (final nome in _livres) {
      f.definirGrauPericia(nome, 5);
    }
    _ajustarGraus();
    for (final e in _graus.entries) {
      f.definirGrauPericia(e.key, 5 + 5 * e.value);
    }
    for (final r in _rituais) {
      f.adicionarEm('rituais', r);
    }

    if (!_livre && !(f.porEstagio ? f.estagio >= 2 : f.nex >= 10)) {
      f.trilha = '';
    }
    f.sincronizarTrilha();
    f.pv = f.pvMax;
    f.san = f.sanMax;
    f.pe = f.peMax;

    await FichaStore.salvar(f);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => FichaScreen(fichaId: f.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${passo + 1}/6 · ${_titulos[passo]}'),
        actions: [_menuTipo(), _menuRegras()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (passo + 1) / 6,
            minHeight: 3,
            backgroundColor: Cores.carta2,
            valueColor: const AlwaysStoppedAnimation(Cores.energia),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_livre) _faixaLivre(),
          Expanded(
            child: switch (passo) {
              0 => _passoIdentidade(),
              1 => _passoOrigem(),
              2 => _passoClasse(),
              3 => _passoAtributos(),
              4 => _passoPericias(),
              _ => _passoConferir(),
            },
          ),
          _rodape(),
        ],
      ),
    );
  }

  /// Jogador ou NPC. O que muda de verdade: NPC não é publicado na mesa
  /// (o mestre não manda o próprio bestiário para os jogadores) e já entra
  /// com as regras frouxas.
  Widget _menuTipo() {
    return PopupMenuButton<bool>(
      icon: Icon(
        f.ehNpc ? Icons.psychology_alt_outlined : Icons.person_outline,
      ),
      tooltip: 'Tipo da ficha',
      color: Cores.carta2,
      onSelected: (v) => setState(() {
        f.ehNpc = v;
        if (v) {
          _livre = true;
          f.modoLivre = true;
        }
      }),
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: false,
          checked: !f.ehNpc,
          child: const Text('Personagem de jogador'),
        ),
        CheckedPopupMenuItem(
          value: true,
          checked: f.ehNpc,
          child: const Text('NPC / criatura (só sua)'),
        ),
      ],
    );
  }

  /// As regras que esta ficha segue.
  Widget _menuRegras() {
    return PopupMenuButton<bool>(
      icon: Icon(_livre ? Icons.lock_open : Icons.rule),
      tooltip: 'Regras da ficha',
      color: Cores.carta2,
      onSelected: (v) => setState(() {
        _livre = v;
        f.modoLivre = v;
      }),
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: false,
          checked: !_livre,
          child: const Text('Criação (cobra as regras)'),
        ),
        CheckedPopupMenuItem(
          value: true,
          checked: _livre,
          child: const Text('Livre — mestre / evolução'),
        ),
      ],
    );
  }

  Widget _faixaLivre() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: Cores.conhecimento.withValues(alpha: .14),
      child: Row(
        children: [
          const Icon(Icons.lock_open, size: 16, color: Cores.conhecimento),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              f.ehNpc
                  ? 'NPC — sem limite de pontos, e fora da mesa online.'
                  : 'Modo livre — os limites viram aviso; nada trava.',
              style: const TextStyle(fontSize: 12, color: Cores.conhecimento),
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _livre = false;
              f.modoLivre = false;
            }),
            child: const Text('cobrar regras'),
          ),
        ],
      ),
    );
  }

  Widget _rodape() {
    final pendencia = _pendencia;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Cores.carta,
        border: Border(top: BorderSide(color: Cores.linha)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pendencia != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  pendencia,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Cores.conhecimento,
                  ),
                ),
              ),
            Row(
              children: [
                if (passo > 0)
                  TextButton.icon(
                    onPressed: () => setState(() => passo--),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Voltar'),
                  ),
                const Spacer(),
                if (passo < 5)
                  ElevatedButton.icon(
                    onPressed: _passoCompleto
                        ? () => setState(() => passo++)
                        : null,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Próximo'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _criar,
                    icon: const Icon(Icons.check),
                    label: const Text('Criar ficha'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _passoIdentidade() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _Explicacao(
          'Quem é essa pessoa antes do Outro Lado entrar na vida dela. '
          'Só o nome é obrigatório — o resto dá para preencher depois.',
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final b64 = await escolherRetrato();
                  if (b64 == null) return;
                  setState(() => f.retrato = b64);
                },
                child: RetratoAvatar(base64: f.retrato, tamanho: 96),
              ),
              const SizedBox(height: 6),
              const Text(
                'toque para escolher um retrato',
                style: TextStyle(fontSize: 12, color: Cores.tinta2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          initialValue: f.nome,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome do personagem *',
            hintText: 'Ex.: Márcia Nogueira',
          ),
          onChanged: (v) => setState(() => f.nome = v),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: f.jogador,
          decoration: const InputDecoration(labelText: 'Jogador'),
          onChanged: (v) => f.jogador = v,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: f.nacionalidade,
                decoration: const InputDecoration(
                  labelText: 'Cidade natal',
                  hintText: 'Ex.: Recife, PE',
                ),
                onChanged: (v) => f.nacionalidade = v,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 90,
              child: TextFormField(
                initialValue: f.idade == 0 ? '' : '${f.idade}',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Idade'),
                onChanged: (v) => f.idade = int.tryParse(v.trim()) ?? 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _passoOrigem() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _Explicacao(
          'O que você fazia da vida. A origem treina duas perícias e dá um '
          'poder — tudo entra na ficha sozinho.',
        ),
        const SizedBox(height: 10),
        for (final o in DadosOP.origens)
          Card(
            color: f.origem == o.nome ? Cores.carta2 : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: f.origem == o.nome ? Cores.energia : Cores.linha,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _trocarOrigem(o.nome),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      f.origem == o.nome
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: f.origem == o.nome ? Cores.energia : Cores.tinta2,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  o.nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (o.fonte != 'Livro de Regras')
                                Text(
                                  o.fonte,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Cores.tinta2,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            'Treina ${o.periciasTexto}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Cores.tinta2,
                            ),
                          ),
                          Text(
                            o.poder,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Cores.conhecimento,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (f.origem == o.nome && o.poderDescricao.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                o.poderDescricao,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Mundano e Sobrevivente são as classes de quem ainda não é agente:
  /// as duas ficam em NEX 0%.
  static bool _ehCivil(ClasseOP c) => c.nome == 'Mundano' || c.porEstagio;

  Widget _passoClasse() {
    final civil = f.nex == 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _Explicacao(
          'NEX é o quanto do Outro Lado já entrou em você. Em 0% você ainda '
          'não é agente — pode ser Mundano ou Sobrevivente (Sobrevivendo ao '
          'Horror, que sobe por estágio em vez de NEX). A partir de 5% você é '
          'agente e escolhe combatente, especialista ou ocultista.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'NEX',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 12,
                        color: Cores.energiaViva,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${f.nex}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: (f.nex == 99 ? 100 : f.nex).toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: Cores.energia,
                  label: '${f.nex}%',
                  onChangeEnd: (_) {
                    if (_cortadoPeloNex.isEmpty) return;
                    _avisar(
                      'NEX ${f.nex}%: ${_cortadoPeloNex.join(' e ')} '
                      'saíram (não cabem mais).',
                    );
                    _cortadoPeloNex.clear();
                  },
                  onChanged: (v) {
                    final passoNex = v.round();
                    final rituaisAntes = _rituais.length;
                    final grausAntes = _grausUsados;
                    setState(() {
                      f.nex = passoNex >= 100 ? 99 : passoNex;
                      if (_livre) return;
                      final atual = DadosOP.classePorNome(f.classe);
                      final eraCivil = atual != null && _ehCivil(atual);
                      if (f.nex == 0) {
                        if (!eraCivil) _trocarClasse('Mundano');
                      } else if (eraCivil) {
                        _trocarClasse('Combatente');
                      }
                      _ajustarRituaisAoNex();
                      _ajustarGraus();
                      if (_rituais.length < rituaisAntes) {
                        _cortadoPeloNex.add('rituais');
                      }
                      if (_grausUsados < grausAntes) {
                        _cortadoPeloNex.add('graus de treinamento');
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        if (f.porEstagio) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ESTÁGIO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 12,
                      color: Cores.energiaViva,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (var e = 1; e <= 5; e++)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => f.estagio = e),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: e <= f.estagio
                                    ? Cores.energia
                                    : Colors.transparent,
                                border: Border.all(color: Cores.linha),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$e',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: e <= f.estagio
                                      ? Cores.tinta
                                      : Cores.tinta2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'O sobrevivente começa no estágio 1 e sobe um no fim de '
                    'cada missão. Não usa NEX nem patente.',
                    style: TextStyle(fontSize: 11, color: Cores.tinta2),
                  ),
                ],
              ),
            ),
          ),
        ],
        const FaixaSecao('Classe'),
        for (final c in DadosOP.classes)
          if (_livre || _ehCivil(c) == civil)
            Card(
              color: f.classe == c.nome ? Cores.carta2 : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: f.classe == c.nome ? Cores.energia : Cores.linha,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _trocarClasse(c.nome),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        f.classe == c.nome
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: f.classe == c.nome
                            ? Cores.energia
                            : Cores.tinta2,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              c.descricao,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Cores.tinta2,
                              ),
                            ),
                            if (c.proficiencias.isNotEmpty)
                              Text(
                                'Proficiências: '
                                '${c.proficiencias.join(', ')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Cores.tinta2,
                                ),
                              ),
                            if (c.habilidades.isNotEmpty)
                              Text(
                                [
                                  for (final h in c.habilidades) h.nome,
                                ].join(' · '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Cores.conhecimento,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (c.fonte != 'Livro de Regras')
                              Text(
                                c.fonte,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Cores.tinta2,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _campoTrilha()),
            const SizedBox(width: 10),
            // Mundano e Sobrevivente não têm patente (p. 171; SAH p. 31).
            if (!_ehCivil(classe) && DadosOP.patentes.isNotEmpty)
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: DadosOP.patentePorNome(f.patente) != null
                      ? f.patente
                      : DadosOP.patentes.first.nome,
                  decoration: const InputDecoration(labelText: 'Patente'),
                  dropdownColor: Cores.carta2,
                  items: [
                    for (final p in DadosOP.patentes)
                      DropdownMenuItem(value: p.nome, child: Text(p.nome)),
                  ],
                  onChanged: (v) => setState(() => f.patente = v ?? 'Recruta'),
                ),
              ),
          ],
        ),
        if (_ocultista) ..._secaoRituais(),
      ],
    );
  }

  /// Trilha do catálogo da classe; só abre quando o NEX (ou o estágio do
  /// sobrevivente) já dá trilha. As habilidades entram sozinhas ao criar.
  Widget _campoTrilha() {
    final opcoes = DadosOP.trilhasDe(f.classe);
    final libera = f.porEstagio ? f.estagio >= 2 : f.nex >= 10;
    if (opcoes.isEmpty || _livre) {
      return TextFormField(
        initialValue: f.trilha,
        decoration: const InputDecoration(
          labelText: 'Trilha (a partir do NEX 10%)',
          hintText: 'Ex.: Aniquilador',
        ),
        onChanged: (v) => f.trilha = v,
      );
    }
    return DropdownButtonFormField<String>(
      key: ValueKey('trilha-${f.classe}-$libera'),
      isExpanded: true,
      initialValue: opcoes.any((t) => t.nome == f.trilha) ? f.trilha : '',
      decoration: InputDecoration(
        labelText: libera
            ? 'Trilha'
            : (f.porEstagio ? 'Trilha (estágio 2)' : 'Trilha (NEX 10%)'),
      ),
      dropdownColor: Cores.carta2,
      items: [
        const DropdownMenuItem(value: '', child: Text('—')),
        for (final t in opcoes)
          DropdownMenuItem(value: t.nome, child: Text(t.nome)),
      ],
      onChanged: libera ? (v) => setState(() => f.trilha = v ?? '') : null,
    );
  }

  Future<void> _ritualDoCatalogo() async {
    final escolhido = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => CatalogoScreen(
          escolhendo: true,
          circuloMaximo: _livre ? null : _circuloMaximo,
          nomesExcluidos: {for (final r in _rituais) r['nome'] as String},
        ),
      ),
    );
    if (escolhido == null || !mounted) return;
    setState(() => _rituais.add(escolhido));
  }

  /// Escolhido pelo Outro Lado: 3 rituais de 1º círculo em 5% e mais um a
  /// cada NEX, com círculos novos em 25%, 55% e 85%.
  List<Widget> _secaoRituais() {
    final n = _rituaisDisponiveis;
    final cheio = !_livre && _rituais.length >= n;
    return [
      const SizedBox(height: 12),
      const FaixaSecao('Rituais'),
      _Explicacao(
        _livre
            ? 'Regras frouxas: ponha quantos rituais quiser, de qualquer círculo.'
            : 'Em NEX ${f.nex}% o Ocultista conhece $n ritual(is), até o '
                  '$_circuloMaximoº círculo. Escolhidos: ${_rituais.length} de $n.',
      ),
      for (var i = 0; i < _rituais.length; i++)
        Card(
          child: ListTile(
            dense: true,
            title: Text(
              _rituais[i]['nome'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${_rituais[i]['circulo']} círculo · ${_rituais[i]['custo']}',
              style: const TextStyle(fontSize: 12, color: Cores.tinta2),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Remover',
              onPressed: () => setState(() => _rituais.removeAt(i)),
            ),
          ),
        ),
      const SizedBox(height: 6),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.tonalIcon(
          onPressed: cheio ? null : _ritualDoCatalogo,
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: const Text('Do catálogo de rituais'),
        ),
      ),
    ];
  }

  Widget _passoAtributos() {
    const siglas = ['AGI', 'FOR', 'INT', 'PRE', 'VIG'];
    const nomes = {
      'AGI': 'Agilidade',
      'FOR': 'Força',
      'INT': 'Intelecto',
      'PRE': 'Presença',
      'VIG': 'Vigor',
    };
    final restantes = _pontosAtributoRestantes;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Explicacao(
          _livre
              ? 'Modo livre: ponha o valor que a ficha pedir, até 20. É '
                    'assim que se monta criatura e NPC — as fichas de ameaça '
                    'do livro não cabem no orçamento de um agente.'
              : 'Todos começam em 1. Você tem ${classe.pontosAtributo} '
                    'pontos para distribuir, e nenhum atributo passa de 3 na '
                    'criação. Pode zerar UM atributo para ganhar 1 ponto a '
                    'mais — mas um atributo 0 rola 2d20 e fica com o pior '
                    'resultado.',
        ),
        if (_aumentos > 0) ...[
          const SizedBox(height: 8),
          _Explicacao(
            '${f.porEstagio ? 'No estágio ${f.estagio}' : 'Em NEX ${f.nex}%'} '
            'você já ganhou $_aumentos Aumento(s) de Atributo '
            '(NEX 20%, 50%, 80% e 95%; estágio 3 no Sobrevivente): '
            '+$_aumentos ponto(s), cada um +1 em um atributo. '
            '${f.porEstagio ? 'No Sobrevivente, nem assim passa de 3.' : 'Só eles passam de 3, até 5. Acima de 3 agora: $_acimaDe3 de $_aumentos.'}',
          ),
        ],
        const SizedBox(height: 14),
        if (!_livre)
          Card(
            color: restantes == 0 ? Cores.carta : Cores.carta2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: restantes == 0 ? Cores.estavel : Cores.conhecimento,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$restantes',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: restantes == 0
                          ? Cores.estavel
                          : Cores.conhecimento,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    restantes == 1 ? 'ponto restante' : 'pontos restantes',
                    style: const TextStyle(color: Cores.tinta2),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        for (final s in siglas) _linhaAtributo(s, nomes[s]!),
      ],
    );
  }

  Widget _linhaAtributo(String sigla, String nome) {
    final valor = f.atributo(sigla);
    final jaTemZero = [
      'AGI',
      'FOR',
      'INT',
      'PRE',
      'VIG',
    ].any((x) => x != sigla && f.atributo(x) == 0);
    final podeSubir = _livre
        ? valor < 20
        : _pontosAtributoRestantes > 0 &&
              (valor < 3 ||
                  (valor < classe.tetoAumento && _acimaDe3 < _aumentos));
    final podeDescer = valor > 0 && (_livre || !(valor == 1 && jaTemZero));

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                sigla,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Cores.energiaViva,
                ),
              ),
            ),
            Expanded(child: Text(nome)),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: podeDescer ? Cores.tinta2 : Cores.linha,
              onPressed: podeDescer
                  ? () => setState(() {
                      f.definirAtributo(sigla, valor - 1);
                      _ajustarGraus();
                    })
                  : null,
            ),
            SizedBox(
              width: 34,
              child: Text(
                '$valor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: valor == 0 ? Cores.sangue : Cores.tinta,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: podeSubir ? Cores.energiaViva : Cores.linha,
              onPressed: podeSubir
                  ? () => setState(() {
                      f.definirAtributo(sigla, valor + 1);
                      _ajustarGraus();
                    })
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _passoPericias() {
    final daOrigem = _daOrigem;
    final escolhidasClasse = _escolhasDeClasse.values.toSet();
    final fixasClasse = {...classe.periciasFixas};
    final faltam = _livresDisponiveis - _livres.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Explicacao(
          _livre
              ? 'Modo livre: marque as perícias que a ficha precisar, sem '
                    'limite. Treinada dá +5 no teste; o grau (veterano, '
                    'expert) você ajusta depois, na ficha.'
              : 'A origem e a classe já treinam algumas. Depois disso você '
                    'escolhe $_livresDisponiveis perícia(s) — '
                    '${classe.periciasLivresBase} da classe + '
                    '${f.atributo('INT')} do Intelecto. Treinada dá +5 no '
                    'teste.${_faltamDaOrigem > 0 ? ' A origem ${f.origem} dá só ${origem!.pericias.length} perícia(s): mais $_faltamDaOrigem entra(m) aqui, à escolha do mestre.' : ''} '
                    'Veterana (+10) e expert (+15) vêm do Grau de '
                    'Treinamento, em NEX 35% e 70%: a cada um, '
                    '${classe.periciasPorGrau} + Intelecto perícias treinadas '
                    'sobem um grau.',
        ),
        if (_eventosGrau > 0) ...[const SizedBox(height: 8), _cartaoGrau()],
        const SizedBox(height: 12),
        if (daOrigem.isNotEmpty || fixasClasse.isNotEmpty) ...[
          const FaixaSecao('Já vêm treinadas'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final p in daOrigem)
                Chip(
                  label: Text(p),
                  avatar: const Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Cores.tinta2,
                  ),
                  backgroundColor: Cores.carta2,
                  side: const BorderSide(color: Cores.linha),
                ),
              for (final p in fixasClasse)
                Chip(
                  label: Text(p),
                  avatar: const Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Cores.tinta2,
                  ),
                  backgroundColor: Cores.carta2,
                  side: const BorderSide(color: Cores.linha),
                ),
            ],
          ),
        ],
        if (classe.periciasEscolha.isNotEmpty) ...[
          const FaixaSecao('Escolhas da classe'),
          for (var i = 0; i < classe.periciasEscolha.length; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classe.periciasEscolha[i].join(' ou '),
                      style: const TextStyle(fontSize: 12, color: Cores.tinta2),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final nome in classe.periciasEscolha[i])
                          ChoiceChip(
                            label: Text(nome),
                            selected: _escolhasDeClasse[i] == nome,
                            selectedColor: Cores.energia.withValues(alpha: .22),
                            backgroundColor: Cores.carta2,
                            side: const BorderSide(color: Cores.linha),
                            onSelected: (_) => setState(() {
                              _escolhasDeClasse[i] = nome;
                              _livres.remove(nome);
                              _ajustarGraus();
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
        FaixaSecao(
          _livre
              ? 'Perícias (${_livres.length} marcadas)'
              : faltam > 0
              ? 'Escolha mais $faltam'
              : faltam < 0
              ? 'Desmarque ${-faltam}'
              : 'Perícias livres — completo',
        ),
        for (final p in DadosOP.pericias)
          _linhaPericiaEscolha(p, daOrigem, escolhidasClasse, fixasClasse),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _linhaPericiaEscolha(
    Pericia p,
    Set<String> daOrigem,
    Set<String> escolhidasClasse,
    Set<String> fixasClasse,
  ) {
    final jaTreinada =
        daOrigem.contains(p.nome) ||
        escolhidasClasse.contains(p.nome) ||
        fixasClasse.contains(p.nome);
    final marcada = _livres.contains(p.nome);
    final podeMarcar = _livre || marcada || _livres.length < _livresDisponiveis;
    final grau = _graus[p.nome] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        enabled: !jaTreinada && podeMarcar,
        leading: Icon(
          jaTreinada
              ? Icons.lock_outline
              : marcada
              ? Icons.check_box
              : Icons.check_box_outline_blank,
          color: jaTreinada
              ? Cores.tinta2
              : marcada
              ? Cores.estavel
              : (podeMarcar ? Cores.tinta2 : Cores.linha),
          size: 20,
        ),
        title: Text(
          p.nome + (p.soTreinada ? ' *' : ''),
          style: TextStyle(
            fontSize: 14,
            fontWeight: jaTreinada || marcada
                ? FontWeight.bold
                : FontWeight.normal,
            color: jaTreinada ? Cores.tinta2 : Cores.tinta,
          ),
        ),
        subtitle: Text(
          jaTreinada
              ? 'já treinada'
              : '${p.atributo}${p.soTreinada ? ' · só treinada' : ''}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: _eventosGrau > 0 && (jaTreinada || marcada)
            ? ActionChip(
                label: Text(const ['+5', 'V +10', 'E +15'][grau]),
                tooltip: 'Grau de Treinamento',
                backgroundColor: grau > 0
                    ? Cores.energia.withValues(alpha: .22)
                    : Cores.carta2,
                side: BorderSide(color: grau > 0 ? Cores.energia : Cores.linha),
                onPressed: () => setState(() {
                  final novo = _proximoGrau(p.nome);
                  if (novo == 0) {
                    _graus.remove(p.nome);
                  } else {
                    _graus[p.nome] = novo;
                  }
                }),
              )
            : null,
        onTap: jaTreinada || !podeMarcar
            ? null
            : () => setState(() {
                if (marcada) {
                  _livres.remove(p.nome);
                  _ajustarGraus();
                } else {
                  _livres.add(p.nome);
                }
              }),
      ),
    );
  }

  /// Resumo do Grau de Treinamento que o NEX escolhido já deu.
  Widget _cartaoGrau() {
    final faltam = _grausTotais - _grausUsados;
    return Card(
      color: faltam == 0 ? Cores.carta : Cores.carta2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: faltam == 0 ? Cores.estavel : Cores.conhecimento,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GRAU DE TREINAMENTO · $_grausUsados de $_grausTotais',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 12,
                color: faltam == 0 ? Cores.estavel : Cores.conhecimento,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _eventosGrau == 1
                  ? 'NEX 35%: $_periciasPorGrau perícias treinadas viram '
                        'veteranas (+10). Toque no +5 de uma perícia treinada '
                        'da lista.'
                  : 'NEX 35% e 70%: duas vezes $_periciasPorGrau perícias '
                        'sobem um grau. Toque no +5 para veterana (+10) e de '
                        'novo para expert (+15) — até $_periciasPorGrau '
                        'experts.',
              style: const TextStyle(fontSize: 12, color: Cores.tinta2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passoConferir() {
    final pv = f.pvMax;
    final san = f.sanMax;
    final pe = f.peMax;
    final treinadas = _treinadas.toList()..sort();
    // O que o assistente já aplicou sozinho não entra na lista de anotar.
    final aAnotar = <String>[
      for (final m in classe.marcosEntre(5, f.nex).values)
        for (final g in m)
          if (!g.startsWith('Aumento de Atributo') &&
              !g.startsWith('Grau de Treinamento') &&
              !g.startsWith('Rituais de') &&
              !g.startsWith('Engenhosidade') &&
              // Trilha escolhida: as habilidades dela entram sozinhas.
              !(f.trilha.isNotEmpty &&
                  (g.startsWith('Trilha') || g == 'Poder de trilha')) &&
              g != '+1 ritual')
            g,
    ];
    final contagem = <String, int>{};
    for (final g in aAnotar) {
      contagem[g] = (contagem[g] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _Explicacao(
          'Confira e crie. Depois disso a ficha é sua: tudo continua '
          'editável na tela dela — subir NEX, treinar perícia nova, mudar '
          'equipamento.',
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                RetratoAvatar(base64: f.retrato, tamanho: 60),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.nome.isEmpty ? 'Sem nome' : f.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        [
                          f.classe,
                          if (f.origem.isNotEmpty) f.origem,
                          if (f.porEstagio)
                            'estágio ${f.estagio}'
                          else
                            'NEX ${f.nex}%',
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Cores.tinta2,
                        ),
                      ),
                      if (f.ehNpc)
                        const Text(
                          'NPC — não vai para a mesa online',
                          style: TextStyle(
                            fontSize: 12,
                            color: Cores.sangue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Text(
                        f.patente,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Cores.conhecimento,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const FaixaSecao('Recursos'),
        Row(
          children: [
            _quadro('VIDA', '$pv', Cores.sangue),
            const SizedBox(width: 8),
            _quadro('SANIDADE', '$san', Cores.energia),
            const SizedBox(width: 8),
            _quadro('ESFORÇO', '$pe', Cores.conhecimento),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _quadro('DEFESA', '${f.defesa}', Cores.tinta2),
            const SizedBox(width: 8),
            _quadro(
              'CARGA',
              '${f.atributo('FOR') <= 0 ? 2 : 5 * f.atributo('FOR')}',
              Cores.tinta2,
            ),
            const SizedBox(width: 8),
            _quadro('PE/TURNO', '${classe.limitePe(f.nex)}', Cores.tinta2),
          ],
        ),
        const FaixaSecao('Atributos'),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final s in ['AGI', 'FOR', 'INT', 'PRE', 'VIG'])
                  Column(
                    children: [
                      Text(
                        s,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Cores.tinta2,
                        ),
                      ),
                      Text(
                        '${f.atributo(s)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: f.atributo(s) == 0
                              ? Cores.sangue
                              : Cores.tinta,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        FaixaSecao('Perícias treinadas (${treinadas.length})'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final p in treinadas)
                  Chip(
                    label: Text('$p +${5 + 5 * (_graus[p] ?? 0)}'),
                    backgroundColor: Cores.carta2,
                    side: const BorderSide(color: Cores.linha),
                  ),
              ],
            ),
          ),
        ),
        const FaixaSecao('Vêm junto'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final h in classe.habilidades)
                  Text('• ${h.nome} (classe)'),
                if (origem != null && origem!.poder.isNotEmpty)
                  Text('• ${origem!.poder} (origem)'),
                if (classe.proficiencias.isNotEmpty)
                  Text('• Proficiências: ${classe.proficiencias.join(', ')}'),
              ],
            ),
          ),
        ),
        if (contagem.isNotEmpty) ...[
          const FaixaSecao('Anote na ficha'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in contagem.entries)
                    Text('• ${e.value > 1 ? '${e.value}× ' : ''}${e.key}'),
                  const SizedBox(height: 6),
                  Text(
                    'Ganhos até NEX ${f.nex}%. Atributos, Grau de '
                    'Treinamento e rituais já estão na '
                    'ficha. Poderes são escolha sua: entram na aba de '
                    'habilidades.',
                    style: const TextStyle(fontSize: 12, color: Cores.tinta2),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _quadro(String rotulo, String valor, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Cores.linha),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
            Text(
              rotulo,
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                color: Cores.tinta2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Caixa de explicação do passo — o wizard ensina a regra enquanto pede.
class _Explicacao extends StatelessWidget {
  final String texto;
  const _Explicacao(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Cores.carta,
        border: Border.all(color: Cores.linha),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Cores.energiaViva),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13, color: Cores.tinta2),
            ),
          ),
        ],
      ),
    );
  }
}
