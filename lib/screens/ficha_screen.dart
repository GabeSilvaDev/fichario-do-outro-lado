import 'package:flutter/material.dart';

import '../data/dados_op.dart';
import '../mesa/ponte_rolagens.dart';
import '../models/ficha_op.dart';
import '../models/rolagem.dart';
import '../regras/condicoes.dart';
import '../regras/opcionais.dart';
import '../regras/pendencias.dart';
import '../regras/poderes.dart';
import '../store/ficha_store.dart';
import '../theme.dart';
import 'catalogo_screen.dart';
import 'poderes_screen.dart';
import '../widgets/painel_pendencias.dart';
import '../widgets/recurso_contador.dart';
import '../widgets/retrato.dart';

/// A ficha completa, em abas. Serve dois papéis:
/// - o jogador edita a dele ([somenteLeitura] false — todo toque salva no
///   Hive e, se estiver numa mesa, espelha para o mestre);
/// - o mestre abre a de um jogador ([fichaDireta] + [somenteLeitura] true).
class FichaScreen extends StatefulWidget {
  final String? fichaId;
  final FichaOP? fichaDireta;
  final bool somenteLeitura;

  const FichaScreen({
    super.key,
    this.fichaId,
    this.fichaDireta,
    this.somenteLeitura = false,
  });

  @override
  State<FichaScreen> createState() => _FichaScreenState();
}

class _FichaScreenState extends State<FichaScreen> {
  late FichaOP ficha;

  /// Pendências que já estavam na tela: a cada mudança, as que aparecem
  /// de novo viram aviso na hora.
  Set<String> _pendenciasVistas = {};

  @override
  void initState() {
    super.initState();
    ficha = widget.fichaDireta ??
        FichaStore.porId(widget.fichaId!) ??
        FichaOP.nova(widget.fichaId!);
    if (!leitura) ficha.sincronizarTrilha();
    _pendenciasVistas = _idsQueCobram(pendenciasDe(ficha));
  }

  static Set<String> _idsQueCobram(List<Pendencia> ps) => {
        for (final p in ps)
          if (p.gravidade != Gravidade.info) p.id,
      };

  static const _abasPorNome = {
    'geral': 0,
    'pericias': 1,
    'ataques': 2,
    'poderes': 3,
    'inventario': 4,
    'sobre': 5,
  };

  bool get leitura => widget.somenteLeitura;

  /// Na mesa, o mestre recebe a ficha nova a cada publicação do jogador.
  @override
  void didUpdateWidget(covariant FichaScreen antigo) {
    super.didUpdateWidget(antigo);
    final nova = widget.fichaDireta;
    if (nova != null && !identical(nova, antigo.fichaDireta)) {
      ficha = nova;
    }
  }

  @override
  void dispose() {
    _campoDadoRapido.dispose();
    super.dispose();
  }

  /// Grava, redesenha e avisa o que a mudança deixou para resolver — é o
  /// "e se eu mudar isso aqui?" respondido na hora.
  void _salvar() {
    if (leitura) return;
    FichaStore.salvar(ficha);
    final agora = pendenciasDe(ficha);
    final novas = [
      for (final p in agora)
        if (p.gravidade != Gravidade.info && !_pendenciasVistas.contains(p.id))
          p,
    ];
    _pendenciasVistas = _idsQueCobram(agora);
    setState(() {});
    if (novas.isEmpty || !mounted) return;
    final mensageiro = ScaffoldMessenger.maybeOf(context);
    mensageiro?.hideCurrentSnackBar();
    mensageiro?.showSnackBar(SnackBar(
      duration: const Duration(seconds: 5),
      content: Row(
        children: [
          Icon(PainelPendencias.icone(novas.first.gravidade),
              color: PainelPendencias.cor(novas.first.gravidade), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(novas.length == 1
                ? novas.first.texto
                : '${novas.first.texto} (+${novas.length - 1} pendência(s))'),
          ),
        ],
      ),
    ));
  }

  void _rolarPericia(Pericia p) {
    final (dados, melhor, bonus) = ficha.testePericia(p);
    final r = Rolagem.teste(
        titulo: p.nome, dados: dados, melhor: melhor, bonus: bonus);
    _mostrarResultado(r);
  }

  void _rolarExpressao(String titulo, String expressao) {
    final r = Rolagem.expressao(titulo, expressao);
    if (r == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Não entendi "$expressao" — use algo como 2d6+3.')));
      return;
    }
    _mostrarResultado(r);
  }

  void _mostrarResultado(ResultadoRolagem r) {
    if (!leitura) {
      PonteRolagens.publicar(r, ficha.nome.isEmpty ? 'Sem nome' : ficha.nome);
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(r.titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.formula,
                style: const TextStyle(
                    fontFamily: 'monospace', color: Cores.tinta2)),
            const SizedBox(height: 4),
            Text(r.detalhe,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Cores.tinta2)),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '${r.total}',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: r.critico
                      ? Cores.estavel
                      : r.desastre
                          ? Cores.sangue
                          : Cores.tinta,
                ),
              ),
            ),
            if (r.critico)
              const Center(
                  child: Text('CRÍTICO!',
                      style: TextStyle(
                          color: Cores.estavel, fontWeight: FontWeight.bold))),
            if (r.desastre)
              const Center(
                  child: Text('DESASTRE…',
                      style: TextStyle(
                          color: Cores.sangue, fontWeight: FontWeight.bold))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendencias = pendenciasDe(ficha);
    final cobrando =
        pendencias.where((p) => p.gravidade != Gravidade.info).length;
    return DefaultTabController(
      length: 6,
      child: Builder(builder: (ctxAbas) => Scaffold(
        appBar: AppBar(
          title: Text(ficha.nome.isEmpty ? 'Ficha' : ficha.nome),
          actions: [
            if (cobrando > 0)
              IconButton(
                tooltip: '$cobrando pendência(s)',
                onPressed: () => DefaultTabController.of(ctxAbas).animateTo(0),
                icon: Badge(
                  label: Text('$cobrando'),
                  backgroundColor: pendencias
                          .any((p) => p.gravidade == Gravidade.erro)
                      ? Cores.sangue
                      : Cores.conhecimento,
                  child: const Icon(Icons.fact_check_outlined),
                ),
              ),
            if (!leitura) ...[_menuTipo(), _menuRegras()],
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Geral'),
              Tab(text: 'Perícias'),
              Tab(text: 'Ataques'),
              Tab(text: 'Poderes'),
              Tab(text: 'Inventário'),
              Tab(text: 'Sobre'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (ficha.ehNpc || ficha.modoLivre) _faixaEstado(),
            Expanded(child: _abas()),
          ],
        ),
      )),
    );
  }

  Widget _abas() {
    return TabBarView(
          children: [
            _abaGeral(),
            _abaPericias(),
            _abaAtaques(),
            _abaPoderes(),
            _abaInventario(),
            _abaSobre(),
          ],
        );
  }

  /// Jogador ou NPC. NPC fica fora da mesa online: o bestiário é do mestre.
  Widget _menuTipo() {
    return PopupMenuButton<bool>(
      icon: Icon(
          ficha.ehNpc ? Icons.psychology_alt_outlined : Icons.person_outline),
      tooltip: 'Tipo da ficha',
      color: Cores.carta2,
      onSelected: (v) {
        ficha.ehNpc = v;
        if (v) ficha.modoLivre = true;
        _salvar();
      },
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: false,
          checked: !ficha.ehNpc,
          child: const Text('Personagem de jogador'),
        ),
        CheckedPopupMenuItem(
          value: true,
          checked: ficha.ehNpc,
          child: const Text('NPC / criatura (só sua)'),
        ),
      ],
    );
  }

  /// Modo livre: solta os tetos da ficha (atributo até 20) para montar
  /// criatura, NPC ou um personagem que já passou do que a criação permite.
  Widget _menuRegras() {
    return PopupMenuButton<bool>(
      icon: Icon(ficha.modoLivre ? Icons.lock_open : Icons.rule),
      tooltip: 'Regras da ficha',
      color: Cores.carta2,
      onSelected: (v) {
        ficha.modoLivre = v;
        _salvar();
      },
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: false,
          checked: !ficha.modoLivre,
          child: const Text('Padrão (limites do livro)'),
        ),
        CheckedPopupMenuItem(
          value: true,
          checked: ficha.modoLivre,
          child: const Text('Livre — mestre / evolução'),
        ),
      ],
    );
  }

  Widget _faixaEstado() {
    final npc = ficha.ehNpc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: (npc ? Cores.sangue : Cores.conhecimento).withValues(alpha: .14),
      child: Row(
        children: [
          Icon(npc ? Icons.psychology_alt_outlined : Icons.lock_open,
              size: 15, color: npc ? Cores.sangue : Cores.conhecimento),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              npc
                  ? 'NPC / criatura — fica só neste aparelho, fora da mesa.'
                  : 'Modo livre — os limites do livro não travam esta ficha.',
              style: TextStyle(
                  fontSize: 12,
                  color: npc ? Cores.sangue : Cores.conhecimento),
            ),
          ),
        ],
      ),
    );
  }

  Widget _abaGeral() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Builder(
          builder: (ctx) => PainelPendencias(
            pendencias: pendenciasDe(ficha),
            aoIrPara: (aba) => DefaultTabController.of(ctx)
                .animateTo(_abasPorNome[aba] ?? 0),
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: leitura
                  ? null
                  : () async {
                      final b64 = await escolherRetrato();
                      if (b64 == null) return;
                      ficha.retrato = b64;
                      _salvar();
                    },
              child: RetratoAvatar(base64: ficha.retrato, tamanho: 72),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  _campoTexto('Nome do personagem', ficha.nome,
                      (v) => ficha.nome = v),
                  const SizedBox(height: 8),
                  _campoTexto(
                      'Jogador', ficha.jogador, (v) => ficha.jogador = v),
                ],
              ),
            ),
          ],
        ),
        const FaixaSecao('Identidade'),
        Row(children: [
          Expanded(child: _seletorClasse()),
          const SizedBox(width: 8),
          Expanded(child: _seletorOrigem()),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _seletorTrilha()),
          const SizedBox(width: 8),
          Expanded(child: _seletorPatente()),
        ]),
        if (ficha.classeOP?.agente ?? false) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _campoNumero('Pontos de prestígio (PP)', ficha.pp,
                  (v) => ficha.pp = v),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pelos PP: ${ficha.patentePelosPp}',
                style: const TextStyle(fontSize: 12, color: Cores.tinta2),
              ),
            ),
          ]),
        ],
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _campoTexto('Nacionalidade / cidade natal',
                  ficha.nacionalidade, (v) => ficha.nacionalidade = v)),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: _campoNumero('Idade', ficha.idade, (v) => ficha.idade = v),
          ),
        ]),
        const SizedBox(height: 10),
        _linhaNex(),
        const FaixaSecao('Atributos'),
        _atributos(),
        const FaixaSecao('Recursos'),
        RecursoContador(
          rotulo: 'VIDA',
          atual: ficha.pv,
          maximo: ficha.pvMax,
          maximoManual: ficha.pvMaxManual,
          cor: Cores.sangue,
          extra: ficha.pvTemporario,
          rotuloExtra: 'PV temporários',
          aoEditarExtra: leitura ? null : _editarPvTemporario,
          aoMudar: leitura
              ? null
              : (v) {
                  if (v < ficha.pv) {
                    ficha.sofrerDano(ficha.pv - v);
                  } else {
                    ficha.pv = v;
                  }
                  _salvar();
                },
          aoEditarMaximo: leitura ? null : () => _editarMaximo('pv'),
        ),
        if (ficha.regraDeterminacao)
          RecursoContador(
            rotulo: 'DETERMINAÇÃO',
            atual: ficha.pd,
            maximo: ficha.pdMax,
            cor: Cores.energia,
            aoMudar: leitura
                ? null
                : (v) {
                    ficha.pd = v;
                    _salvar();
                  },
          )
        else ...[
        RecursoContador(
          rotulo: 'SANIDADE',
          atual: ficha.san,
          maximo: ficha.sanMax,
          maximoManual: ficha.sanMaxManual,
          cor: Cores.energia,
          aoMudar: leitura
              ? null
              : (v) {
                  ficha.san = v;
                  _salvar();
                },
          aoEditarMaximo: leitura ? null : () => _editarMaximo('san'),
        ),
        RecursoContador(
          rotulo: 'ESFORÇO',
          atual: ficha.pe,
          maximo: ficha.peMax,
          maximoManual: ficha.peMaxManual,
          cor: Cores.conhecimento,
          aoMudar: leitura
              ? null
              : (v) {
                  ficha.pe = v;
                  _salvar();
                },
          aoEditarMaximo: leitura ? null : () => _editarMaximo('pe'),
        ),
        ],
        if (ficha.ehNpc) ...[
          const FaixaSecao('Bloco de ameaça'),
          _blocoAmeaca(),
        ],
        const FaixaSecao('Estado'),
        _estadoDoPersonagem(),
        const FaixaSecao('Condições'),
        _condicoes(),
        const FaixaSecao('Estado na mesa'),
        _estadoDeMesa(),
        const FaixaSecao('Defesa e movimento'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _medalha('DEFESA', '${ficha.defesa}'),
                    const SizedBox(width: 12),
                    _medalha('DESLOC.', _metros(ficha.deslocamentoEfetivo)),
                    const SizedBox(width: 12),
                    _medalha('PE/TURNO', '${ficha.limitePeTurno}'),
                    const SizedBox(width: 12),
                    _medalha('DT RIT.', '${ficha.dtRituais}'),
                  ],
                ),
                if (_textoRd().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Resistência a dano: ${_textoRd()}',
                        style: const TextStyle(fontSize: 12)),
                  ),
                if (ficha.efeitos.defesaCondicao > 0 ||
                    ficha.efeitos.deslocamentoCondicao != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Condições já aplicadas: '
                      '${ficha.efeitos.defesaCondicao > 0 ? '−${ficha.efeitos.defesaCondicao} Defesa' : ''}'
                      '${ficha.efeitos.deslocamentoCondicao != null ? ' · deslocamento alterado' : ''}',
                      style: const TextStyle(
                          fontSize: 12, color: Cores.conhecimento),
                    ),
                  ),
                if (ficha.sobrecarregado)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Sobrecarregado: −5 na Defesa, −3m de deslocamento e −5 '
                      'nas perícias que sofrem carga.',
                      style: TextStyle(fontSize: 12, color: Cores.sangue),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _seletorProtecao()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _campoNumero('Deslocamento (m)',
                        ficha.deslocamento, (v) => ficha.deslocamento = v),
                  ),
                ]),
                if (ficha.protecaoTipo == 'Outra') ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: _campoTexto('Nome da proteção', ficha.protecao,
                          (v) => ficha.protecao = v),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _campoNumero('Defesa da proteção',
                          ficha.protecaoDefesa,
                          (v) => ficha.protecaoDefesa = v),
                    ),
                  ]),
                ],
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: ficha.escudo,
                  title: const Text('Escudo (+2 Defesa, 2 espaços)',
                      style: TextStyle(fontSize: 14)),
                  onChanged: leitura
                      ? null
                      : (v) {
                          ficha.escudo = v ?? false;
                          _salvar();
                        },
                ),
                if (ficha.semProficienciaEmProtecao != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Sem proficiência em ${ficha.semProficienciaEmProtecao} '
                      '— −2 d20 em For e Agi, já aplicado nos testes.',
                      style: const TextStyle(
                          fontSize: 12, color: Cores.sangue),
                    ),
                  ),
                _campoNumero('Outros bônus de Defesa', ficha.defesaBonus,
                    (v) => ficha.defesaBonus = v),
                const SizedBox(height: 8),
                _campoTexto('Resistências', ficha.resistencias,
                    (v) => ficha.resistencias = v),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _medalha(String rotulo, String valor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Cores.linha),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(valor,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Cores.tinta)),
            Text(rotulo,
                style: const TextStyle(
                    fontSize: 10, letterSpacing: 1.5, color: Cores.tinta2)),
          ],
        ),
      ),
    );
  }

  /// NEX de quando o jogador pegou a régua — para contar o que ganhou ao
  /// soltar, e não a cada passo do arrasto.
  int? _nexAoPegar;

  Widget _linhaNex() {
    if (ficha.porEstagio) return _linhaEstagio();
    final classe = DadosOP.classePorNome(ficha.classe);
    final proximo = classe?.proximoMarco(ficha.nex);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('NEX',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 12,
                        color: Cores.energiaViva)),
                Expanded(
                  child: Slider(
                    value: (ficha.nex == 99 ? 100 : ficha.nex).toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: Cores.energia,
                    label: '${ficha.nex}%',
                    onChangeStart:
                        leitura ? null : (_) => _nexAoPegar = ficha.nex,
                    onChanged: leitura
                        ? null
                        : (v) {
                            final passo = v.round();
                            ficha.nex = passo >= 100 ? 99 : passo;
                            _salvar();
                          },
                    onChangeEnd:
                        leitura ? null : (_) => _mostrarGanhosDeNex(),
                  ),
                ),
                Text('${ficha.nex}%',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Cores.tinta)),
              ],
            ),
            if (proximo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Próximo: NEX $proximo% — '
                  '${classe!.marcos(proximo).join(' · ')}',
                  style: const TextStyle(fontSize: 11, color: Cores.tinta2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Subiu de NEX: lista o que a tabela da classe dá em cada passo. Os
  /// números (PV, SAN, PE, limite, rituais) o app já fez; o resto é escolha
  /// do jogador, e a ficha avisa para ninguém esquecer.
  Future<void> _mostrarGanhosDeNex() async {
    final de = _nexAoPegar;
    _nexAoPegar = null;
    final classe = DadosOP.classePorNome(ficha.classe);
    if (de == null || classe == null) return;
    final (entrou, saiu) = ficha.sincronizarTrilha();
    _salvar();
    if (!classe.agente && ficha.nex > 0 && !classe.porEstagio) {
      await _virarAgente();
      return;
    }
    if (ficha.nex < de) {
      _avisarTrilha(entrou, saiu);
      return;
    }
    final ganhos = classe.marcosEntre(de, ficha.nex);
    if (entrou.isNotEmpty) {
      ganhos[ficha.nex] = [
        ...?ganhos[ficha.nex],
        'Entrou na ficha: ${entrou.join(', ')}',
      ];
    }
    if (ganhos.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('NEX $de% → ${ficha.nex}%'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in ganhos.entries) ...[
                Text('${e.key}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Cores.energiaViva)),
                for (final g in e.value)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Text('• $g'),
                  ),
                const SizedBox(height: 6),
              ],
              const Text(
                'PV, SAN, PE e o limite de PE já foram recalculados. O resto '
                'é escolha sua: atributo tocando no círculo, grau tocando na '
                'perícia, poderes e rituais nas abas.',
                style: TextStyle(fontSize: 12, color: Cores.tinta2),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendi')),
        ],
      ),
    );
  }

  Future<void> _editarPvTemporario() async {
    final campo = TextEditingController(
        text: ficha.pvTemporario == 0 ? '' : '${ficha.pvTemporario}');
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PV temporários'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ficam por cima da vida e saem primeiro no dano. Fontes '
              'diferentes somam; o mesmo efeito de novo não. Somem no fim '
              'da cena. Digite o total.',
              style: TextStyle(fontSize: 13, color: Cores.tinta2),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: campo,
              autofocus: true,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, '0'),
              child: const Text('Zerar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, campo.text),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (resultado == null) return;
    ficha.pvTemporario = int.tryParse(resultado.trim()) ?? 0;
    _salvar();
  }

  /// Subiu de estágio: o que cada um dá (SAH p. 30).
  Future<void> _mostrarGanhosDeEstagio(
      int de, int ate, List<String> entrou, List<String> saiu) async {
    if (ate <= de) {
      _avisarTrilha(entrou, saiu);
      return;
    }
    const ganhos = {
      2: 'Trilha: escolha Durão, Esperto ou Esotérico (1º poder)',
      3: 'Aumento de Atributo: +1 em um atributo, sem passar de 3',
      4: 'Trilha: 2º poder',
      5: 'Cicatrizado: escolha o elemento (−1d20 em resistência contra ele)',
    };
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Estágio $de → $ate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var e = de + 1; e <= ate; e++)
              if (ganhos[e] != null) Text('• $e: ${ganhos[e]}'),
            if (entrou.isNotEmpty) Text('• Entrou: ${entrou.join(', ')}'),
            const SizedBox(height: 8),
            const Text(
              'PV, PE e SAN já subiram. Treinamento Especial (virar agente) '
              'é decisão da história: troque a classe quando o mestre disser.',
              style: TextStyle(fontSize: 12, color: Cores.tinta2),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendi')),
        ],
      ),
    );
  }

  /// Mundano passou de 0%: vira agente, e agente precisa de classe.
  Future<void> _virarAgente() async {
    final escolha = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Virou agente'),
        content: const Text(
            'Em NEX 5% o mundano escolhe uma classe e ganha +1 ponto de '
            'atributo (máx. 3). O que for da classe entra agora.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              child: const Text('Voltar a 0%')),
          for (final c in const ['Combatente', 'Especialista', 'Ocultista'])
            TextButton(
                onPressed: () => Navigator.pop(ctx, c),
                child: Text(c)),
        ],
      ),
    );
    if (escolha == null || escolha.isEmpty) {
      ficha.nex = 0;
      _salvar();
      return;
    }
    await _trocarClasse(escolha);
  }

  /// Os cinco estágios do Sobrevivente, no lugar da régua de NEX.
  /// SAH p. 30: 1 Empenho · 2 trilha · 3 atributo · 4 trilha · 5 Cicatrizado.
  Widget _linhaEstagio() {
    const marcos = {
      1: 'Empenho',
      2: 'Trilha (1º poder)',
      3: 'Aumento de atributo',
      4: 'Trilha (2º poder)',
      5: 'Cicatrizado',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('ESTÁGIO',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 12,
                        color: Cores.energiaViva)),
                const SizedBox(width: 8),
                for (var e = 1; e <= 5; e++)
                  Expanded(
                    child: GestureDetector(
                      onTap: leitura
                          ? null
                          : () {
                              final antes = ficha.estagio;
                              ficha.estagio = e;
                              final (entrou, saiu) = ficha.sincronizarTrilha();
                              _salvar();
                              _mostrarGanhosDeEstagio(antes, e, entrou, saiu);
                            },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: e <= ficha.estagio
                              ? Cores.energia
                              : Colors.transparent,
                          border: Border.all(color: Cores.linha),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('$e',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: e <= ficha.estagio
                                  ? Cores.tinta
                                  : Cores.tinta2,
                            )),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${marcos[ficha.estagio]} · sobe um estágio no fim de cada '
              'missão · limite de PE sempre 1',
              style: const TextStyle(fontSize: 11, color: Cores.tinta2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _atributos() {
    const siglas = ['AGI', 'FOR', 'INT', 'PRE', 'VIG'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final s in siglas)
              Column(
                children: [
                  Text(s,
                      style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: Cores.tinta2)),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: leitura
                        ? null
                        : () {
                            if (ficha.modoLivre) {
                              _digitarAtributo(s);
                            } else {
                              ficha.definirAtributo(
                                  s, (ficha.atributo(s) + 1) % 6);
                              _salvar();
                            }
                          },
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Cores.energia, width: 1.5),
                        color: Cores.carta2,
                      ),
                      child: Text('${ficha.atributo(s)}',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Cores.tinta)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// No modo livre o atributo vai a 20 — ciclar no toque seria sofrimento.
  Future<void> _digitarAtributo(String sigla) async {
    final campo = TextEditingController(text: '${ficha.atributo(sigla)}');
    final valor = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sigla),
        content: TextField(
          controller: campo,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Valor (0 a 20)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, campo.text),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (valor == null) return;
    final n = int.tryParse(valor.trim());
    if (n == null) return;
    ficha.definirAtributo(sigla, n);
    _salvar();
  }

  Future<void> _editarMaximo(String recurso) async {
    final rotulo = {'pv': 'PV', 'san': 'SAN', 'pe': 'PE'}[recurso]!;
    final atual = {'pv': ficha.pvMax, 'san': ficha.sanMax, 'pe': ficha.peMax}[
        recurso]!;
    final campo = TextEditingController(text: '$atual');
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$rotulo máximo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'O máximo é calculado da classe, NEX e atributos. Digite um '
              'valor para fixar na mão, ou volte ao automático.',
              style: TextStyle(fontSize: 13, color: Cores.tinta2),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: campo,
              autofocus: true,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'auto'),
              child: const Text('Usar automático')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, campo.text),
              child: const Text('Fixar')),
        ],
      ),
    );
    if (resultado == null) return;
    if (resultado == 'auto') {
      ficha.definirMaxManual(recurso, null);
    } else {
      final v = int.tryParse(resultado.trim());
      if (v != null && v > 0) ficha.definirMaxManual(recurso, v);
    }
    _salvar();
  }

  final _campoDadoRapido = TextEditingController();

  /// Aceita "2d6+3" e também a sintaxe da ficha oficial: "/AGI/d20" rola o
  /// atributo (tantos d20 quanto o valor, pegando o melhor).
  void _rolarRapido() {
    final bruto = _campoDadoRapido.text.trim();
    if (bruto.isEmpty) return;
    final atributo = RegExp(r'^/?(AGI|FOR|INT|PRE|VIG)(/d?20)?$',
            caseSensitive: false)
        .firstMatch(bruto);
    if (atributo != null) {
      final sigla = atributo.group(1)!.toUpperCase();
      final valor = ficha.atributo(sigla);
      _mostrarResultado(Rolagem.teste(
        titulo: sigla,
        dados: valor <= 0 ? 2 : valor,
        melhor: valor > 0,
        bonus: 0,
      ));
    } else {
      _rolarExpressao('Dado rápido', bruto);
    }
    _campoDadoRapido.clear();
  }

  Widget _abaPericias() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _campoDadoRapido,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Dado rápido: 2d6+3 ou /AGI',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _rolarRapido(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.casino_outlined,
                      color: Cores.energiaViva),
                  onPressed: _rolarRapido,
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'Toque no grau para treinar (— → T → V → E). Toque no dado para '
            'rolar: o teste aparece na hora para o mestre, se você estiver '
            'numa mesa.',
            style: TextStyle(fontSize: 12, color: Cores.tinta2),
          ),
        ),
        for (final p in DadosOP.pericias) _linhaPericia(p),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          children: const [
            Text('— destreinada',
                style: TextStyle(fontSize: 11, color: Cores.tinta2)),
            Text('T treinada +5',
                style: TextStyle(fontSize: 11, color: Cores.estavel)),
            Text('V veterano +10',
                style: TextStyle(fontSize: 11, color: Cores.energiaViva)),
            Text('E expert +15',
                style: TextStyle(fontSize: 11, color: Cores.conhecimento)),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  static const Map<int, String> _graus = {0: '—', 5: 'T', 10: 'V', 15: 'E'};

  /// Agente treina em 5/10/15. Ficha de ameaça traz o bônus impresso do
  /// livro, que é qualquer número (Furtividade +8, Percepção +25) — por
  /// isso rótulo e cor saem por FAIXA, e não por valor exato. Procurar o
  /// valor exato num mapa era o que fazia a aba de perícias quebrar em
  /// criatura.
  static String _rotuloGrau(int grau) {
    final conhecido = _graus[grau];
    if (conhecido != null) return grau > 0 ? '$conhecido +$grau' : '—';
    return '+$grau';
  }

  static Color _corDoGrau(int grau) {
    if (grau >= 15) return Cores.conhecimento;
    if (grau >= 10) return Cores.energiaViva;
    if (grau >= 5) return Cores.estavel;
    return Cores.tinta2;
  }

  /// O toque cicla entre os graus do livro; um bônus fora da tabela sobe
  /// para o degrau seguinte em vez de sumir.
  static int _proximoGrau(int grau) {
    if (grau < 5) return 5;
    if (grau < 10) return 10;
    if (grau < 15) return 15;
    return 0;
  }

  Widget _linhaPericia(Pericia p) {
    final grau = ficha.grauPericia(p.nome);
    final (dados, melhor, bonus) = ficha.testePericia(p);
    final motivos = ficha.motivosDoTeste(p);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 40, child: _seletorAtributoPericia(p)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nome + (p.soTreinada ? ' *' : ''),
                    style: TextStyle(
                      fontWeight:
                          grau > 0 ? FontWeight.bold : FontWeight.normal,
                      color: grau > 0 ? Cores.tinta : Cores.tinta2,
                    ),
                  ),
                  Text(
                    '${dados}d20${melhor ? '' : ' (pior)'}'
                    '${bonus >= 0 ? '+' : ''}$bonus'
                    '${motivos.isEmpty ? '' : ' · ${motivos.join(' · ')}'}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: motivos.isEmpty ? Cores.tinta2 : Cores.conhecimento,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: leitura
                  ? null
                  : () {
                      ficha.definirGrauPericia(p.nome, _proximoGrau(grau));
                      _salvar();
                    },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                constraints: const BoxConstraints(minWidth: 46),
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: _corDoGrau(grau)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _rotuloGrau(grau),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _corDoGrau(grau)),
                ),
              ),
            ),
            IconButton(
              tooltip:
                  'Rolar ${dados}d20 (${melhor ? 'melhor' : 'pior'}) +$bonus',
              icon: const Icon(Icons.casino_outlined,
                  color: Cores.energiaViva, size: 22),
              onPressed: () => _rolarPericia(p),
            ),
          ],
        ),
      ),
    );
  }

  /// A sigla do atributo, clicável: troca qual atributo rola a perícia.
  /// Fica destacada quando não é o do livro, para ninguém esquecer a troca
  /// ligada de uma cena para a outra.
  Widget _seletorAtributoPericia(Pericia p) {
    final atual = ficha.atributoPericia(p);
    final trocado = ficha.atributoTrocado(p);
    final texto = Text(
      atual,
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 1,
        fontWeight: trocado ? FontWeight.bold : FontWeight.normal,
        color: trocado ? Cores.energiaViva : Cores.tinta2,
      ),
    );
    if (leitura) return texto;

    return PopupMenuButton<String>(
      tooltip: 'Trocar o atributo de ${p.nome}',
      padding: EdgeInsets.zero,
      color: Cores.carta2,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        for (final sigla in const ['AGI', 'FOR', 'INT', 'PRE', 'VIG'])
          PopupMenuItem(
            value: sigla,
            child: Text(
              sigla == p.atributo ? '$sigla (padrão)' : sigla,
              style: TextStyle(
                fontWeight:
                    sigla == atual ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
      ],
      onSelected: (sigla) {
        ficha.definirAtributoPericia(p, sigla);
        _salvar();
      },
      child: texto,
    );
  }

  Widget _abaAtaques() {
    final ataques = ficha.ataques;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        for (var i = 0; i < ataques.length; i++) _cartaoAtaque(i, ataques[i]),
        if (ataques.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Nenhum ataque ainda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Cores.tinta2)),
          ),
        if (!leitura)
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _editarAtaque(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar ataque'),
                ),
                TextButton.icon(
                  onPressed: _armaDoCatalogo,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Do catálogo de armas'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _cartaoAtaque(int indice, Map<String, dynamic> a) {
    final nome = '${a['nome'] ?? ''}';
    final pericia = '${a['pericia'] ?? 'Luta'}';
    final tipo = '${a['tipo'] ?? ''}';
    final alcance = '${a['alcance'] ?? ''}';
    final fixos = FichaOP.paraIntSeguro(a['dadosTeste']);
    final r = ficha.resumoAtaque(a);
    final titulo = nome.isEmpty ? pericia : nome;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(nome.isEmpty ? 'Sem nome' : nome,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                if (!leitura)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: Cores.tinta2),
                    onPressed: () => _editarAtaque(indice),
                  ),
              ],
            ),
            Text(
              [
                if (fixos > 0)
                  '${fixos}d20+${a['bonusTeste'] ?? 0}'
                else
                  '$pericia ${r.dados}d20${r.melhor ? '' : ' (pior)'}'
                      '${r.bonus >= 0 ? '+' : ''}${r.bonus}',
                if (r.danos.isNotEmpty)
                  'dano ${r.danos.map(r.expressaoDano).join(' ou ')}'
                      '${tipo.isNotEmpty ? ' ($tipo)' : ''}',
                'crítico ${r.margem < 20 ? '${r.margem}/' : ''}x${r.multiplicador}',
                if (alcance.isNotEmpty) alcance,
              ].join(' · '),
              style: const TextStyle(fontSize: 12, color: Cores.tinta2),
            ),
            if (r.semProficiencia != null)
              Text('Sem proficiência em ${r.semProficiencia}: −2 d20 (já no '
                  'teste).',
                  style: const TextStyle(fontSize: 12, color: Cores.sangue)),
            if (pericia == 'Luta' && ficha.atributo('FOR') != 0)
              Text('Força ${ficha.atributo('FOR')} já somada no dano.',
                  style: const TextStyle(fontSize: 11, color: Cores.tinta2)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    final teste = fixos > 0
                        ? Rolagem.teste(
                            titulo: 'Ataque: $titulo',
                            dados: fixos,
                            melhor: true,
                            bonus: FichaOP.paraIntSeguro(a['bonusTeste']),
                          )
                        : Rolagem.teste(
                            titulo: 'Ataque: $titulo',
                            dados: r.dados,
                            melhor: r.melhor,
                            bonus: r.bonus,
                            margem: r.margem,
                          );
                    _mostrarResultado(teste);
                  },
                  icon: const Icon(Icons.casino_outlined, size: 16),
                  label: const Text('Teste'),
                ),
                for (final d in r.danos) ...[
                  OutlinedButton.icon(
                    onPressed: () =>
                        _rolarExpressao('Dano: $titulo', r.expressaoDano(d)),
                    icon: const Icon(Icons.bolt_outlined, size: 16),
                    label: Text(r.danos.length > 1 ? 'Dano $d' : 'Dano'),
                  ),
                  TextButton(
                    onPressed: () {
                      final res = Rolagem.expressao('Crítico: $titulo',
                          r.expressaoDano(d),
                          multiplicarDados: r.multiplicador);
                      if (res != null) _mostrarResultado(res);
                    },
                    child: Text('Crítico x${r.multiplicador}'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pega uma arma da tabela do sistema e monta o ataque na ficha — com
  /// dano, margem, multiplicador e a perícia certa já preenchidos.
  Future<void> _armaDoCatalogo() async {
    final escolhido = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) =>
            const CatalogoScreen(escolhendo: true, comecarEmArmas: true),
      ),
    );
    if (escolhido == null || !mounted) return;
    // A arma também é item: ocupa espaço e conta no limite da patente.
    // Munição não é ataque, só item.
    final item = <String, dynamic>{
      'nome': escolhido['nome'],
      'categoria': '${escolhido['categoria'] ?? ''}'.isEmpty
          ? '0'
          : escolhido['categoria'],
      'espacos': FichaOP.paraIntSeguro(escolhido['espacos']),
    };
    final ehArma = '${escolhido['dano'] ?? ''}'.isNotEmpty;
    if (ehArma) ficha.adicionarEm('ataques', escolhido);
    if ('${escolhido['espacos'] ?? ''}'.isNotEmpty) {
      ficha.adicionarEm('inventario', item);
    }
    _salvar();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text(ehArma
          ? '${escolhido['nome']}: ataque e item no inventário.'
          : '${escolhido['nome']}: item no inventário.'),
    ));
  }

  /// O mesmo para rituais: entra com custo, execução, alcance, duração,
  /// resistência, efeito e as ampliações.
  Future<void> _ritualDoCatalogo() async {
    final livre = ficha.modoLivre || ficha.ehNpc;
    final escolhido = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => CatalogoScreen(
          escolhendo: true,
          circuloMaximo: livre ? null : circuloMaximoDe(ficha),
          nomesExcluidos: {for (final r in ficha.rituais) '${r['nome']}'},
        ),
      ),
    );
    if (escolhido == null || !mounted) return;
    ficha.adicionarEm('rituais', escolhido);
    _salvar();
  }

  Future<void> _editarAtaque(int? indice) async {
    final atual = indice == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(ficha.ataques[indice]);
    final nome = TextEditingController(text: (atual['nome'] ?? '') as String);
    final bonus =
        TextEditingController(text: '${atual['bonus'] ?? 0}');
    final dano = TextEditingController(text: (atual['dano'] ?? '') as String);
    final critico =
        TextEditingController(text: (atual['critico'] ?? '') as String);
    final margem =
        TextEditingController(text: (atual['margem'] ?? '') as String);
    final alcance =
        TextEditingController(text: (atual['alcance'] ?? '') as String);
    final especial =
        TextEditingController(text: (atual['especial'] ?? '') as String);
    var pericia = (atual['pericia'] ?? 'Luta') as String;
    var tipo = (atual['tipo'] ?? '') as String;
    var familia = '${atual['familia'] ?? ''}';
    if (!const ['', 'Armas Simples', 'Armas Táticas', 'Armas Pesadas']
        .contains(familia)) {
      familia = '';
    }
    var daOrigem = atual['armaDaOrigem'] == true;
    final origemComArma = ficha.origemAtual?.flag('armaFavorita') ?? false;
    const tiposDano = [
      '', 'corte', 'impacto', 'perfuração', 'balístico', 'fogo',
      'elétrico', 'químico', 'mental', 'de conhecimento', 'de energia',
      'de morte', 'de sangue',
    ];
    if (!tiposDano.contains(tipo)) tipo = '';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(indice == null ? 'Novo ataque' : 'Editar ataque'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nome,
                    decoration:
                        const InputDecoration(labelText: 'Nome (ex.: Pistola)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
      isExpanded: true,
                  initialValue: pericia,
                  decoration:
                      const InputDecoration(labelText: 'Perícia do teste'),
                  dropdownColor: Cores.carta2,
                  items: const [
                    DropdownMenuItem(value: 'Luta', child: Text('Luta')),
                    DropdownMenuItem(
                        value: 'Pontaria', child: Text('Pontaria')),
                  ],
                  onChanged: (v) => setLocal(() => pericia = v ?? 'Luta'),
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: bonus,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Bônus extra no teste')),
                const SizedBox(height: 8),
                TextField(
                    controller: dano,
                    decoration: const InputDecoration(
                        labelText: 'Dano (ex.: 1d12+2)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
      isExpanded: true,
                  initialValue: tipo,
                  decoration:
                      const InputDecoration(labelText: 'Tipo de dano'),
                  dropdownColor: Cores.carta2,
                  items: [
                    for (final t in tiposDano)
                      DropdownMenuItem(
                          value: t, child: Text(t.isEmpty ? '—' : t)),
                  ],
                  onChanged: (v) => setLocal(() => tipo = v ?? ''),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                        controller: margem,
                        decoration: const InputDecoration(
                            labelText: 'Margem (ex.: 19)')),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                        controller: critico,
                        decoration: const InputDecoration(
                            labelText: 'Crítico (ex.: x2)')),
                  ),
                ]),
                const SizedBox(height: 8),
                TextField(
                    controller: alcance,
                    decoration: const InputDecoration(
                        labelText: 'Alcance (ex.: curto)')),
                const SizedBox(height: 8),
                TextField(
                    controller: especial,
                    decoration: const InputDecoration(
                        labelText: 'Especial / recarga')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: familia,
                  decoration: const InputDecoration(
                      labelText: 'Tipo de arma (proficiência)'),
                  dropdownColor: Cores.carta2,
                  items: const [
                    DropdownMenuItem(value: '', child: Text('— (sem checar)')),
                    DropdownMenuItem(
                        value: 'Armas Simples', child: Text('Simples')),
                    DropdownMenuItem(
                        value: 'Armas Táticas', child: Text('Tática')),
                    DropdownMenuItem(
                        value: 'Armas Pesadas', child: Text('Pesada')),
                  ],
                  onChanged: (v) => setLocal(() => familia = v ?? ''),
                ),
                if (origemComArma)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: daOrigem,
                    title: const Text('Arma da origem (Operário)',
                        style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Proficiente; +1 ataque, dano e margem',
                        style: TextStyle(fontSize: 12)),
                    onChanged: (v) => setLocal(() => daOrigem = v),
                  ),
              ],
            ),
          ),
          actions: [
            if (indice != null)
              TextButton(
                onPressed: () {
                  ficha.removerDe('ataques', indice);
                  Navigator.pop(ctx, true);
                },
                child: const Text('Excluir',
                    style: TextStyle(color: Cores.sangue)),
              ),
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                final novo = {
                  ...atual,
                  'nome': nome.text.trim(),
                  'familia': familia,
                  'armaDaOrigem': daOrigem,
                  'pericia': pericia,
                  'bonus': int.tryParse(bonus.text.trim()) ?? 0,
                  'dano': dano.text.trim(),
                  'tipo': tipo,
                  'margem': margem.text.trim(),
                  'critico': critico.text.trim(),
                  'alcance': alcance.text.trim(),
                  'especial': especial.text.trim(),
                };
                if (indice == null) {
                  ficha.adicionarEm('ataques', novo);
                } else {
                  ficha.atualizarEm('ataques', indice, novo);
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) _salvar();
  }

  Widget _abaPoderes() {
    final c = ficha.classeOP;
    final escalas = c?.escalasAtuais(ficha.nex) ?? const <String>[];
    final (limite, _, _) = limiteDeRituais(ficha);
    final agente = c?.agente ?? false;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (agente) ...[
          const FaixaSecao('Na régua agora'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in escalas) Text('• $e'),
                  Text('• Limite de PE por turno: ${ficha.limitePeTurno}'),
                  Text('• DT de habilidades: 10 + ${ficha.limitePeBase} + '
                      'atributo · DT de rituais: ${ficha.dtRituais}'),
                  if (ficha.transcendencias > 0)
                    Text('• Transcender: ${ficha.transcendencias} '
                        '(−${ficha.transcendencias * c!.sanPorNivel} SAN máx.)'),
                  if (ficha.nex >= 50) ...[
                    const SizedBox(height: 8),
                    _seletorAfinidade(),
                  ],
                ],
              ),
            ),
          ),
        ],
        const FaixaSecao('Habilidades e poderes'),
        ..._listaSimples('habilidades', 'habilidade',
            camposExtras: const [], habilidade: true),
        if (!leitura && DadosOP.poderes.isNotEmpty)
          Center(
            child: TextButton.icon(
              onPressed: _poderDoCatalogo,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Do catálogo de poderes'),
            ),
          ),
        FaixaSecao('Rituais · ${ficha.rituais.length} de $limite'),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'DT ${ficha.dtRituais} para resistir. Conjurar gasta PE e pede '
            'Ocultismo DT 20 + custo (Medo: perde SAN e 1 permanente) — '
            'o app faz a conta.',
            style: const TextStyle(fontSize: 12, color: Cores.tinta2),
          ),
        ),
        ..._listaSimples('rituais', 'ritual', camposExtras: const [
          ('circulo', 'Círculo (1º a 4º)'),
          ('custo', 'Custo (PE)'),
          ('elemento', 'Elemento'),
          ('execucao', 'Execução'),
          ('alcance', 'Alcance'),
          ('duracao', 'Duração'),
        ], acoes: leitura
            ? null
            : (i, r) => OutlinedButton.icon(
                  onPressed: () => _conjurar(r),
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: const Text('Conjurar'),
                )),
        if (!leitura)
          Center(
            child: TextButton.icon(
              onPressed: _ritualDoCatalogo,
              icon: const Icon(Icons.auto_stories_outlined),
              label: const Text('Do catálogo de rituais'),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _seletorAfinidade() {
    return DropdownButtonFormField<String>(
      key: ValueKey('afinidade-${ficha.afinidade}'),
      isExpanded: true,
      initialValue: ficha.afinidade,
      decoration: const InputDecoration(
          labelText: 'Afinidade (NEX 50%, irrevogável)', isDense: true),
      dropdownColor: Cores.carta2,
      items: [
        const DropdownMenuItem(value: '', child: Text('—')),
        for (final e in const ['Conhecimento', 'Energia', 'Morte', 'Sangue'])
          DropdownMenuItem(value: e, child: Text(e)),
      ],
      onChanged: leitura
          ? null
          : (v) {
              ficha.afinidade = v ?? '';
              _salvar();
            },
    );
  }

  Future<void> _poderDoCatalogo() async {
    final p = await Navigator.of(context).push<Poder>(
      MaterialPageRoute(builder: (_) => PoderesScreen(ficha: ficha)),
    );
    if (p == null || !mounted) return;
    final sanAntes = ficha.sanMax;
    ficha.adicionarEm('habilidades', p.paraFicha(nexAtual: ficha.nex));
    _salvar();
    final perdeu = sanAntes - ficha.sanMax;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text('${p.nome} na ficha.'
          '${p.efeitos.isNotEmpty ? ' Efeitos já aplicados.' : ''}'
          '${perdeu > 0 ? ' Transcender: −$perdeu SAN máxima.' : ''}'),
    ));
  }

  /// Conjura: escolhe a forma, confere o limite de PE, gasta os PE e cobra
  /// o custo do paranormal (OPRPG p. 121).
  Future<void> _conjurar(Map<String, dynamic> r) async {
    final nome = '${r['nome'] ?? 'Ritual'}';
    final medo = '${r['elemento'] ?? ''}'.toLowerCase() == 'medo';
    final formas = <(String, int)>[('Básica', 0)];
    for (final linha in '${r['descricao'] ?? ''}'.split('\n')) {
      final m = RegExp(r'^(Discente|Verdadeir[oa])\s*\(\+(\d+)\s*PE\)',
              caseSensitive: false)
          .firstMatch(linha.trim());
      if (m != null) formas.add((m.group(1)!, int.parse(m.group(2)!)));
    }
    final base = custoDoRitual(r);
    var forma = 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final custo = ficha.custoDeRitual(base + formas[forma].$2);
          final acima = forma > 0 && custo > ficha.limitePeTurno;
          final semPe = custo > ficha.pe;
          return AlertDialog(
            title: Text('Conjurar $nome'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (formas.length > 1)
                  Wrap(spacing: 6, children: [
                    for (var i = 0; i < formas.length; i++)
                      ChoiceChip(
                        label: Text(i == 0
                            ? formas[i].$1
                            : '${formas[i].$1} +${formas[i].$2}'),
                        selected: forma == i,
                        onSelected: (_) => setLocal(() => forma = i),
                      ),
                  ]),
                const SizedBox(height: 8),
                Text('Custo: $custo PE (tem ${ficha.pe}) · limite '
                    '${ficha.limitePeTurno}/turno'),
                Text('DT para resistir: ${ficha.dtRituais}'),
                const SizedBox(height: 6),
                Text(
                  medo
                      ? 'Medo: perde $custo SAN e ${forma == 0 ? 1 : forma == 1 ? 2 : 3} '
                          'de SAN máxima.'
                      : 'Teste de Ocultismo DT ${20 + custo}: falhou, perde '
                          '$custo SAN; falhou por 5+, também 1 de SAN máxima.',
                  style: const TextStyle(fontSize: 12, color: Cores.tinta2),
                ),
                if (acima)
                  const Text('Passa do limite de PE: esta forma não dá.',
                      style: TextStyle(fontSize: 12, color: Cores.sangue)),
                if (semPe)
                  const Text('PE insuficiente.',
                      style: TextStyle(fontSize: 12, color: Cores.sangue)),
                if (ficha.efeitos.custoPeCondicao > 0)
                  const Text('Alquebrado: +1 PE já somado.',
                      style: TextStyle(fontSize: 12, color: Cores.conhecimento)),
                if (ficha.efeitos.custoRitual != 0)
                  const Text(
                      'Reduções de poderes somadas (o livro se contradiz se '
                      'acumulam: p. 78 × Ritual Predileto). Confira com o mestre.',
                      style: TextStyle(fontSize: 11, color: Cores.tinta2)),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: acima || semPe
                      ? null
                      : () => Navigator.pop(ctx, true),
                  child: const Text('Conjurar')),
            ],
          );
        },
      ),
    );
    if (ok != true || !mounted) return;
    final custo = ficha.custoDeRitual(base + formas[forma].$2);
    ficha.pe -= custo;
    String resultado;
    if (medo) {
      ficha.san -= custo;
      final permanente = forma == 0 ? 1 : forma == 1 ? 2 : 3;
      ficha.sanPerdida += permanente;
      resultado = 'Medo: −$custo SAN e −$permanente SAN máxima.';
    } else {
      final ocultismo =
          DadosOP.pericias.where((p) => p.nome == 'Ocultismo').toList();
      if (ocultismo.isEmpty) {
        resultado = 'Faça Ocultismo DT ${20 + custo}.';
      } else {
        final (dados, melhor, bonus) = ficha.testePericia(ocultismo.first);
        final teste = Rolagem.teste(
            titulo: 'Custo de $nome',
            dados: dados,
            melhor: melhor,
            bonus: bonus);
        final dt = 20 + custo;
        if (teste.total >= dt) {
          resultado = 'Ocultismo ${teste.total} contra DT $dt: sem custo de SAN.';
        } else {
          ficha.san -= custo;
          if (dt - teste.total >= 5) {
            ficha.sanPerdida += 1;
            resultado = 'Ocultismo ${teste.total} contra DT $dt: −$custo SAN '
                'e −1 SAN máxima.';
          } else {
            resultado =
                'Ocultismo ${teste.total} contra DT $dt: −$custo SAN.';
          }
        }
        PonteRolagens.publicar(
            teste, ficha.nome.isEmpty ? 'Sem nome' : ficha.nome);
      }
    }
    _salvar();
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      duration: const Duration(seconds: 6),
      content: Text('$nome: −$custo PE. $resultado'),
    ));
  }

  Widget _abaInventario() {
    final itens = ficha.inventario;
    final patente = DadosOP.patentePorNome(ficha.patente);
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Carga: ${ficha.cargaUsada}/${ficha.cargaLimite} '
                      '(máx. ${ficha.cargaMaxima})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ficha.sobrecarregado
                            ? Cores.sangue
                            : Cores.tinta,
                      ),
                    ),
                    if (ficha.sobrecarregado)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text('SOBRECARREGADO',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Cores.sangue)),
                      ),
                  ],
                ),
                if (ficha.espacosProtecao > 0)
                  Text(
                    'Proteção/escudo vestidos: ${ficha.espacosProtecao} espaços '
                    '(já na carga).',
                    style: const TextStyle(fontSize: 12, color: Cores.tinta2),
                  ),
                if (patente != null && (ficha.classeOP?.agente ?? false))
                  _limitesDaPatente(patente)
                else
                  const Text(
                    'Sem patente: 1 item de categoria I e quantos de 0 quiser.',
                    style: TextStyle(fontSize: 12, color: Cores.tinta2),
                  ),
              ],
            ),
          ),
        ),
        for (var i = 0; i < itens.length; i++) _linhaItem(i, itens[i]),
        if (!leitura)
          Center(
            child: TextButton.icon(
              onPressed: () => _editarItem(null),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar item'),
            ),
          ),
        const FaixaSecao('Anotações'),
        TextFormField(
          key: leitura ? ValueKey('anotacoes|${ficha.anotacoes}') : null,
          initialValue: ficha.anotacoes,
          readOnly: leitura,
          maxLines: 8,
          decoration: const InputDecoration(
              hintText: 'História, contatos, pistas, dívidas…'),
          onChanged: (v) {
            ficha.anotacoes = v;
            if (!leitura) FichaStore.salvar(ficha);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Itens por categoria contra o limite da patente (p. 52), já contando
  /// proteção e escudo vestidos.
  Widget _limitesDaPatente(Patente patente) {
    final conta = contarCategorias(ficha);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 10,
        children: [
          Text('Patente ${patente.nome} · crédito ${patente.credito}',
              style: const TextStyle(fontSize: 12, color: Cores.tinta2)),
          for (final cat in const ['I', 'II', 'III', 'IV'])
            Text(
              '$cat: ${conta[cat] ?? 0}/${patente.limites[cat] ?? 0}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: (conta[cat] ?? 0) > (patente.limites[cat] ?? 0)
                    ? Cores.sangue
                    : Cores.tinta2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _linhaItem(int indice, Map<String, dynamic> item) {
    final nome = '${item['nome'] ?? ''}';
    final categoria = '${item['categoria'] ?? ''}';
    final espacos = FichaOP.paraIntSeguro(item['espacos']);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        title: Text(nome.isEmpty ? 'Sem nome' : nome),
        subtitle: Text(
          [
            if (categoria.isNotEmpty) 'categoria $categoria',
            '$espacos espaço${espacos == 1 ? '' : 's'}',
            if (item['amaldicoado'] == true) 'amaldiçoado',
            if (item['foraDoLimite'] == true) 'fora do limite',
          ].join(' · '),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: leitura
            ? null
            : IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: Cores.tinta2),
                onPressed: () => _editarItem(indice),
              ),
      ),
    );
  }

  Future<void> _editarItem(int? indice) async {
    final atual = indice == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(ficha.inventario[indice]);
    final nome = TextEditingController(text: '${atual['nome'] ?? ''}');
    final espacos = TextEditingController(text: '${atual['espacos'] ?? 1}');
    var categoria = '${atual['categoria'] ?? 'I'}';
    if (!['0', 'I', 'II', 'III', 'IV'].contains(categoria)) categoria = 'I';
    var amaldicoado = atual['amaldicoado'] == true;
    var foraDoLimite = atual['foraDoLimite'] == true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(indice == null ? 'Novo item' : 'Editar item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nome,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Item')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
      isExpanded: true,
                initialValue: categoria,
                decoration: const InputDecoration(labelText: 'Categoria'),
                dropdownColor: Cores.carta2,
                items: const [
                  DropdownMenuItem(value: '0', child: Text('0 (livre)')),
                  DropdownMenuItem(value: 'I', child: Text('I')),
                  DropdownMenuItem(value: 'II', child: Text('II')),
                  DropdownMenuItem(value: 'III', child: Text('III')),
                  DropdownMenuItem(value: 'IV', child: Text('IV')),
                ],
                onChanged: (v) => setLocal(() => categoria = v ?? 'I'),
              ),
              const SizedBox(height: 8),
              TextField(
                  controller: espacos,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Espaços')),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: amaldicoado,
                title: const Text('Amaldiçoado',
                    style: TextStyle(fontSize: 14)),
                subtitle: const Text('Só a partir de Agente Especial',
                    style: TextStyle(fontSize: 12)),
                onChanged: (v) => setLocal(() => amaldicoado = v ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: foraDoLimite,
                title: const Text('Não conta no limite da patente',
                    style: TextStyle(fontSize: 14)),
                subtitle: const Text('Ex.: poder do Criminoso',
                    style: TextStyle(fontSize: 12)),
                onChanged: (v) => setLocal(() => foraDoLimite = v ?? false),
              ),
            ],
          ),
          actions: [
            if (indice != null)
              TextButton(
                onPressed: () {
                  ficha.removerDe('inventario', indice);
                  Navigator.pop(ctx, true);
                },
                child: const Text('Excluir',
                    style: TextStyle(color: Cores.sangue)),
              ),
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                final novo = <String, dynamic>{
                  ...atual,
                  'nome': nome.text.trim(),
                  'categoria': categoria,
                  'espacos': int.tryParse(espacos.text.trim()) ?? 1,
                  'amaldicoado': amaldicoado,
                  'foraDoLimite': foraDoLimite,
                };
                if (indice == null) {
                  ficha.adicionarEm('inventario', novo);
                } else {
                  ficha.atualizarEm('inventario', indice, novo);
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) _salvar();
  }

  static const _tiposDePoder = {
    '': '— (não conta)',
    'classe': 'Poder de classe',
    'paranormal': 'Paranormal (Transcender)',
    'geral': 'Poder geral (SAH)',
    'trilha': 'Habilidade de trilha',
    'habilidade': 'Habilidade de classe',
    'origem': 'Poder de origem',
  };

  List<Widget> _listaSimples(String chave, String rotulo,
      {required List<(String, String)> camposExtras,
      bool habilidade = false,
      Widget Function(int, Map<String, dynamic>)? acoes}) {
    final itens = ficha._listaPublica(chave);
    return [
      for (var i = 0; i < itens.length; i++)
        Card(
          child: ExpansionTile(
            shape: const Border(),
            title: Text('${itens[i]['nome'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: habilidade
                ? _subtituloHabilidade(itens[i])
                : _subtituloExtras(itens[i], camposExtras),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${itens[i]['descricao'] ?? ''}'),
                    if (!leitura)
                      Row(
                        children: [
                          if (acoes != null) acoes(i, itens[i]),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _editarSimples(
                                chave, rotulo, i, camposExtras,
                                habilidade: habilidade),
                            child: const Text('Editar'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      if (itens.isEmpty)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Nenhum $rotulo ainda.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Cores.tinta2, fontSize: 13)),
        ),
      if (!leitura)
        Center(
          child: TextButton.icon(
            onPressed: () => _editarSimples(chave, rotulo, null, camposExtras,
                habilidade: habilidade),
            icon: const Icon(Icons.add),
            label: Text('Adicionar $rotulo'),
          ),
        ),
    ];
  }

  Widget? _subtituloHabilidade(Map<String, dynamic> h) {
    final partes = [
      if ('${h['tipoPoder'] ?? ''}'.isNotEmpty)
        _tiposDePoder['${h['tipoPoder']}'] ?? '${h['tipoPoder']}',
      if (h['automatica'] == true) 'entra sozinha pelo NEX',
      if (h['efeitos'] is Map && (h['efeitos'] as Map).isNotEmpty)
        'efeito já aplicado',
      if (h['transcender'] == true) 'Transcender',
    ];
    if (partes.isEmpty) return null;
    return Text(partes.join(' · '),
        style: const TextStyle(fontSize: 12, color: Cores.tinta2));
  }

  Widget? _subtituloExtras(
      Map<String, dynamic> item, List<(String, String)> campos) {
    final partes = <String>[];
    for (final (chave, _) in campos) {
      final v = '${item[chave] ?? ''}';
      if (v.isNotEmpty) partes.add(v);
    }
    if (partes.isEmpty) return null;
    return Text(partes.join(' · '), style: const TextStyle(fontSize: 12));
  }

  Future<void> _editarSimples(String chave, String rotulo, int? indice,
      List<(String, String)> camposExtras,
      {bool habilidade = false}) async {
    final itens = ficha._listaPublica(chave);
    final atual = indice == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(itens[indice]);
    final nome = TextEditingController(text: '${atual['nome'] ?? ''}');
    final descricao =
        TextEditingController(text: '${atual['descricao'] ?? ''}');
    final extras = {
      for (final (c, _) in camposExtras)
        c: TextEditingController(text: '${atual[c] ?? ''}')
    };
    var tipoPoder = '${atual['tipoPoder'] ?? ''}';
    if (!_tiposDePoder.containsKey(tipoPoder)) tipoPoder = '';
    var transcender = atual['transcender'] == true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
        title: Text(indice == null ? 'Novo $rotulo' : 'Editar $rotulo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nome,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nome')),
              for (final (c, r) in camposExtras) ...[
                const SizedBox(height: 8),
                TextField(
                    controller: extras[c],
                    decoration: InputDecoration(labelText: r)),
              ],
              const SizedBox(height: 8),
              TextField(
                  controller: descricao,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Descrição')),
              if (habilidade) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: tipoPoder,
                  decoration: const InputDecoration(
                      labelText: 'Tipo (para a contagem de poderes)'),
                  dropdownColor: Cores.carta2,
                  items: [
                    for (final e in _tiposDePoder.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) => setLocal(() {
                    tipoPoder = v ?? '';
                    if (tipoPoder == 'paranormal') transcender = true;
                  }),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: transcender,
                  title: const Text('Conta como Transcender',
                      style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Não ganha a SAN do NEX em que entrou',
                      style: TextStyle(fontSize: 12)),
                  onChanged: (v) => setLocal(() => transcender = v ?? false),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (indice != null)
            TextButton(
              onPressed: () {
                ficha.removerDe(chave, indice);
                Navigator.pop(ctx, true);
              },
              child:
                  const Text('Excluir', style: TextStyle(color: Cores.sangue)),
            ),
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final novo = <String, dynamic>{
                ...atual,
                'nome': nome.text.trim(),
                'descricao': descricao.text.trim(),
                for (final e in extras.entries) e.key: e.value.text.trim(),
                if (habilidade) ...{
                  'tipoPoder': tipoPoder,
                  'transcender': transcender,
                },
              };
              if (indice == null) {
                ficha.adicionarEm(chave, novo);
              } else {
                ficha.atualizarEm(chave, indice, novo);
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Salvar'),
          ),
        ],
      )),
    );
    if (ok == true) _salvar();
  }

  /// Em combate / morto e o que o mestre NÃO vê. A ficha oficial tem esses
  /// botões e eles mudam o que aparece no painel de quem mestra.
  /// O que a ficha de criatura tem e a de agente não: VD, categoria,
  /// presença perturbadora, sentidos, vulnerabilidades e o limiar de
  /// machucado. Só aparece em ficha marcada como NPC.
  Widget _blocoAmeaca() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _medalha('VD', ficha.vd == null ? '—' : '${ficha.vd}'),
                const SizedBox(width: 12),
                _medalha('MACHUCADO', '${ficha.machucado}'),
                const SizedBox(width: 12),
                _medalha('DEFESA', '${ficha.defesa}'),
              ],
            ),
            const SizedBox(height: 10),
            if (ficha.presenca.isNotEmpty)
              _linhaAmeaca('Presença perturbadora', ficha.presenca,
                  Cores.energiaViva),
            if (ficha.sentidos.isNotEmpty)
              _linhaAmeaca('Sentidos', ficha.sentidos, Cores.tinta2),
            if (ficha.resistencias.isNotEmpty)
              _linhaAmeaca('Resistências', ficha.resistencias, Cores.estavel),
            if (ficha.vulnerabilidades.isNotEmpty)
              _linhaAmeaca(
                  'Vulnerabilidades', ficha.vulnerabilidades, Cores.sangue),
            if (!leitura) ...[
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: _campoTexto('Categoria (Criatura, Pessoa…)',
                      ficha.categoria, (v) => ficha.categoria = v),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _campoTexto('Tamanho', ficha.tamanho,
                      (v) => ficha.tamanho = v),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: _campoTexto('Elemento', ficha.elemento,
                      (v) => ficha.elemento = v),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _campoNumero('VD', ficha.vd ?? 0,
                      (v) => ficha.vd = v <= 0 ? null : v),
                ),
              ]),
              const SizedBox(height: 8),
              _campoTexto('Presença perturbadora', ficha.presenca,
                  (v) => ficha.presenca = v),
              const SizedBox(height: 8),
              _campoTexto('Sentidos', ficha.sentidos,
                  (v) => ficha.sentidos = v),
              const SizedBox(height: 8),
              _campoTexto('Vulnerabilidades', ficha.vulnerabilidades,
                  (v) => ficha.vulnerabilidades = v),
              const SizedBox(height: 8),
              _campoNumero('Defesa impressa (0 = calcular)',
                  ficha.defesaManual ?? 0,
                  (v) => ficha.defesaManual = v <= 0 ? null : v),
            ],
          ],
        ),
      ),
    );
  }

  Widget _linhaAmeaca(String rotulo, String valor, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12.5, color: Cores.tinta),
          children: [
            TextSpan(
                text: '$rotulo: ',
                style: TextStyle(fontWeight: FontWeight.bold, color: cor)),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }

  Widget _estadoDeMesa() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Em combate'),
                  selected: ficha.emCombate,
                  showCheckmark: false,
                  avatar: Icon(Icons.local_fire_department_outlined,
                      size: 18,
                      color: ficha.emCombate ? Cores.conhecimento : Cores.tinta2),
                  selectedColor: Cores.conhecimento.withValues(alpha: .18),
                  onSelected: leitura
                      ? null
                      : (v) {
                          ficha.emCombate = v;
                          _salvar();
                        },
                ),
                FilterChip(
                  label: const Text('Morto'),
                  selected: ficha.morto,
                  showCheckmark: false,
                  avatar: Icon(Icons.dangerous_outlined,
                      size: 18,
                      color: ficha.morto ? Cores.sangue : Cores.tinta2),
                  selectedColor: Cores.sangue.withValues(alpha: .18),
                  onSelected: leitura
                      ? null
                      : (v) {
                          ficha.morto = v;
                          _salvar();
                        },
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Esconder do mestre',
                style: TextStyle(fontSize: 12, color: Cores.tinta2)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final r in const [
                  ('pv', 'Vida'),
                  ('san', 'Sanidade'),
                  ('pe', 'Esforço'),
                ])
                  FilterChip(
                    label: Text(r.$2),
                    selected: ficha.oculto(r.$1),
                    showCheckmark: false,
                    avatar: Icon(
                        ficha.oculto(r.$1)
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color:
                            ficha.oculto(r.$1) ? Cores.energiaViva : Cores.tinta2),
                    selectedColor: Cores.energia.withValues(alpha: .18),
                    onSelected: leitura
                        ? null
                        : (v) {
                            ficha.definirOculto(r.$1, v);
                            _salvar();
                          },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _abaSobre() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const FaixaSecao('Proficiências'),
        _proficiencias(),
        const FaixaSecao('Regras opcionais'),
        _regrasOpcionais(),
        const FaixaSecao('Sobre o personagem'),
        for (final campo in FichaOP.camposSobre.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              key: leitura
                  ? ValueKey('${campo.key}|${ficha.sobre(campo.key)}')
                  : null,
              initialValue: ficha.sobre(campo.key),
              readOnly: leitura,
              maxLines: campo.key == 'anotacoes' ? 8 : 3,
              decoration: InputDecoration(labelText: campo.value),
              onChanged: (v) {
                ficha.definirSobre(campo.key, v);
                if (!leitura) FichaStore.salvar(ficha);
              },
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  /// Idade (OPRPG p. 172), ferimentos debilitantes e Determinação (SAH
  /// p. 104–105): cada uma ligada por ficha, com efeito já nas contas.
  Widget _regrasOpcionais() {
    final faixa = RegrasOpcionais.faixa(ficha.faixaEtaria);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey('faixa-${ficha.faixaEtaria}'),
              isExpanded: true,
              initialValue: ficha.faixaEtaria,
              decoration: const InputDecoration(
                  labelText: 'Idade variada (faixa etária)', isDense: true),
              dropdownColor: Cores.carta2,
              items: [
                const DropdownMenuItem(value: '', child: Text('— (regra desligada)')),
                for (final f in RegrasOpcionais.faixas)
                  DropdownMenuItem(value: f.nome, child: Text(f.nome)),
              ],
              onChanged: leitura
                  ? null
                  : (v) {
                      ficha.faixaEtaria = v ?? '';
                      if (v == null || v.isEmpty) ficha.desvantagens = const [];
                      _salvar();
                    },
            ),
            if (faixa != null) ...[
              const SizedBox(height: 4),
              Text(faixa.efeito,
                  style: const TextStyle(fontSize: 12, color: Cores.tinta2)),
              if (faixa.nexExtra > 0)
                Text('Na criação: NEX +${faixa.nexExtra}% (suba a régua).',
                    style: const TextStyle(
                        fontSize: 12, color: Cores.conhecimento)),
            ],
            if (faixa != null && faixa.desvantagens > 0) ...[
              const SizedBox(height: 8),
              Text(
                  'Desvantagens de idade (${ficha.desvantagens.length} de '
                  '${faixa.desvantagens}):',
                  style: const TextStyle(fontSize: 12)),
              Wrap(
                spacing: 6,
                children: [
                  for (final d in RegrasOpcionais.desvantagens)
                    FilterChip(
                      label: Text(d.nome, style: const TextStyle(fontSize: 12)),
                      tooltip: d.efeito,
                      selected: ficha.desvantagens.contains(d.nome),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      onSelected: leitura
                          ? null
                          : (on) {
                              final atuais = ficha.desvantagens;
                              on ? atuais.add(d.nome) : atuais.remove(d.nome);
                              ficha.desvantagens = atuais;
                              _salvar();
                            },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            const Text('Ferimentos debilitantes (−1 d20 no atributo; Vigor '
                'tira 1 PV máx. por 5% de NEX; acumulam — toque para '
                'somar, × para tirar):',
                style: TextStyle(fontSize: 12)),
            Wrap(
              spacing: 6,
              children: [
                for (final a in const ['AGI', 'FOR', 'INT', 'PRE', 'VIG'])
                  _chipFerimento(a),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: ficha.regraDeterminacao,
              title: const Text('Jogando sem Sanidade (Determinação)',
                  style: TextStyle(fontSize: 14)),
              subtitle: Text(
                  'PD substituem PE e SAN: ${ficha.pdMax} PD. Perturbado '
                  'abaixo da metade.',
                  style: const TextStyle(fontSize: 12)),
              onChanged: leitura
                  ? null
                  : (v) {
                      ficha.regraDeterminacao = v;
                      _salvar();
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipFerimento(String sigla) {
    final n = ficha.ferimentosEm(sigla);
    return InputChip(
      key: ValueKey('ferimento-$sigla'),
      label: Text(n > 1 ? '$sigla ×$n' : sigla,
          style: const TextStyle(fontSize: 12)),
      selected: n > 0,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      onPressed: leitura
          ? null
          : () {
              ficha.ferimentos = [...ficha.ferimentos, sigla];
              _salvar();
            },
      onDeleted: leitura || n == 0
          ? null
          : () {
              final atuais = ficha.ferimentos;
              atuais.remove(sigla);
              ficha.ferimentos = atuais;
              _salvar();
            },
    );
  }

  Widget _proficiencias() {
    final lista = ficha.proficiencias;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lista.isEmpty)
              const Text('Nenhuma ainda. A classe preenche as dela.',
                  style: TextStyle(fontSize: 12, color: Cores.tinta2)),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var i = 0; i < lista.length; i++)
                  Chip(
                    label: Text(lista[i]),
                    backgroundColor: Cores.carta2,
                    side: const BorderSide(color: Cores.linha),
                    onDeleted: leitura
                        ? null
                        : () {
                            final novas = ficha.proficiencias..removeAt(i);
                            ficha.proficiencias = novas;
                            _salvar();
                          },
                  ),
              ],
            ),
            if (!leitura)
              TextButton.icon(
                onPressed: _adicionarProficiencia,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar proficiência'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _adicionarProficiencia() async {
    final campo = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Proficiência'),
        content: TextField(
          controller: campo,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Ex.: armas pesadas, proteções pesadas'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, campo.text.trim()),
              child: const Text('Adicionar')),
        ],
      ),
    );
    if (nome == null || nome.isEmpty) return;
    ficha.proficiencias = ficha.proficiencias..add(nome);
    _salvar();
  }

  Widget _campoTexto(String rotulo, String valor, ValueChanged<String> grava) {
    return TextFormField(
      // Em leitura (mestre na mesa) o valor muda por fora: recria o campo.
      key: leitura ? ValueKey('$rotulo|$valor') : null,
      initialValue: valor,
      readOnly: leitura,
      decoration: InputDecoration(labelText: rotulo, isDense: true),
      onChanged: (v) {
        grava(v);
        _salvar();
      },
    );
  }

  Widget _campoNumero(String rotulo, int valor, ValueChanged<int> grava) {
    return TextFormField(
      key: leitura ? ValueKey('$rotulo|$valor') : null,
      initialValue: '$valor',
      readOnly: leitura,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: rotulo, isDense: true),
      onChanged: (v) {
        final n = int.tryParse(v.trim());
        if (n == null) return;
        grava(n);
        _salvar();
      },
    );
  }

  /// Proteção da tabela do livro. Escolher já soma a Defesa — antes o campo
  /// era texto livre e o número tinha de ser digitado à mão em outro campo.
  Widget _seletorProtecao() {
    final tipo = ficha.protecaoTipo;
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: tipo,
      decoration: const InputDecoration(labelText: 'Proteção', isDense: true),
      dropdownColor: Cores.carta2,
      items: [
        for (final e in FichaOP.protecoes.entries)
          DropdownMenuItem(
            value: e.key,
            child: Text(e.value == 0 ? e.key : '${e.key} (+${e.value})'),
          ),
        const DropdownMenuItem(value: 'Outra', child: Text('Outra…')),
      ],
      onChanged: leitura
          ? null
          : (v) {
              if (v == null) return;
              if (v == 'Outra') {
                if (ficha.protecao.isEmpty) ficha.protecao = 'Proteção';
              } else {
                ficha.vestirProtecao(v);
              }
              _salvar();
            },
    );
  }

  static String _metros(double m) =>
      '${m == m.roundToDouble() ? m.toInt() : m.toString().replaceAll('.', ',')}m';

  String _textoRd() {
    final rd = ficha.efeitos.rd;
    return [
      for (final e in rd.entries)
        if (e.value > 0) '${e.key} ${e.value}',
    ].join(' · ');
  }

  /// Machucado, morrendo, perturbado, enlouquecendo — saem sozinhos dos
  /// recursos. Morrendo e enlouquecendo contam turnos: no 3º, o livro
  /// decide (p. 88).
  Widget _estadoDoPersonagem() {
    final chips = <Widget>[];
    void estado(String nome, Color cor, IconData icone) => chips.add(Chip(
          avatar: Icon(icone, size: 16, color: cor),
          label: Text(nome, style: TextStyle(color: cor, fontSize: 12)),
          side: BorderSide(color: cor.withValues(alpha: .6)),
          backgroundColor: cor.withValues(alpha: .1),
          visualDensity: VisualDensity.compact,
        ));
    if (ficha.morto) estado('Morto', Cores.sangue, Icons.dangerous_outlined);
    if (ficha.morrendo) {
      estado('Morrendo', Cores.sangue, Icons.monitor_heart_outlined);
    } else if (ficha.estaMachucado && !ficha.morto) {
      estado('Machucado', Cores.sangue, Icons.healing_outlined);
    }
    if (ficha.insano) {
      estado('Insano', Cores.energia, Icons.psychology_alt_outlined);
    } else if (ficha.enlouquecendo) {
      estado('Enlouquecendo', Cores.energia, Icons.psychology_alt_outlined);
    } else if (!ficha.regraDeterminacao && ficha.perturbado) {
      estado('Perturbado', Cores.energia, Icons.blur_on);
    }
    if (ficha.regraDeterminacao && ficha.pd < (ficha.pdMax + 1) ~/ 2) {
      estado('Perturbado', Cores.energia, Icons.blur_on);
    }
    if (ficha.sobrecarregado) {
      estado('Sobrecarregado', Cores.conhecimento, Icons.backpack_outlined);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chips.isEmpty)
              const Text('Tudo em ordem.',
                  style: TextStyle(fontSize: 12, color: Cores.tinta2))
            else
              Wrap(spacing: 6, runSpacing: 4, children: chips),
            if (ficha.morrendo)
              _contadorDeTurnos(
                'Morrendo: inconsciente. Medicina DT '
                    '${20 + 5 * FichaOP.paraIntSeguro(ficha.dados['estabilizacoes'])} '
                    'estabiliza (fica com 1 PV). 3 turnos e morre.',
                ficha.turnosMorrendo,
                (v) {
                  ficha.turnosMorrendo = v;
                  if (v >= 3) ficha.morto = true;
                },
                Cores.sangue,
              ),
            if (ficha.enlouquecendo)
              _contadorDeTurnos(
                'Enlouquecendo: Diplomacia ou Religião DT '
                    '${20 + 5 * FichaOP.paraIntSeguro(ficha.dados['acalmado'])} '
                    'acalma (fica com 1 SAN). 3 turnos e fica insano (vira NPC).',
                ficha.turnosEnlouquecendo,
                (v) {
                  ficha.turnosEnlouquecendo = v;
                  if (v >= 3) ficha.insano = true;
                },
                Cores.energia,
              ),
            if (!leitura) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [
                if (ficha.morrendo)
                  OutlinedButton(
                    onPressed: () {
                      ficha.dados['estabilizacoes'] = FichaOP.paraIntSeguro(
                              ficha.dados['estabilizacoes']) +
                          1;
                      ficha.pv = 1;
                      ficha.turnosMorrendo = 0;
                      _salvar();
                    },
                    child: const Text('Estabilizado (1 PV)'),
                  ),
                if (ficha.enlouquecendo)
                  OutlinedButton(
                    onPressed: () {
                      ficha.dados['acalmado'] =
                          FichaOP.paraIntSeguro(ficha.dados['acalmado']) + 1;
                      ficha.san = 1;
                      ficha.turnosEnlouquecendo = 0;
                      _salvar();
                    },
                    child: const Text('Acalmado (1 SAN)'),
                  ),
                if (ficha.insano)
                  TextButton(
                    onPressed: () {
                      ficha.insano = false;
                      _salvar();
                    },
                    child: const Text('Desfazer insano'),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    ficha.fimDeCena();
                    _salvar();
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(
                        content: Text('Fim de cena: temporários, condições e '
                            'contadores zerados.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.flag_outlined, size: 16),
                  label: const Text('Fim de cena'),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _contadorDeTurnos(
      String texto, int turnos, ValueChanged<int> grava, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texto, style: TextStyle(fontSize: 12, color: cor)),
          Row(
            children: [
              for (var i = 1; i <= 3; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6, top: 4),
                  child: Icon(
                    i <= turnos ? Icons.circle : Icons.circle_outlined,
                    size: 16,
                    color: cor,
                  ),
                ),
              const Spacer(),
              if (!leitura)
                TextButton(
                  onPressed: turnos >= 3
                      ? null
                      : () {
                          grava(turnos + 1);
                          _salvar();
                        },
                  child: const Text('+1 turno'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// As condições do livro, com efeito já aplicado em Defesa, testes e
  /// deslocamento. Tocar liga e desliga; a que piora com repetição avisa.
  Widget _condicoes() {
    final ativas = ficha.condicoes;
    final implicitas = {
      for (final c in Condicoes.expandir(ativas))
        if (!ativas.contains(c.nome)) c.nome,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: [
                for (final c in Condicoes.todas)
                  if (!leitura || ativas.contains(c.nome))
                    FilterChip(
                      label: Text(c.nome, style: const TextStyle(fontSize: 12)),
                      tooltip: c.efeito,
                      selected: ativas.contains(c.nome) ||
                          implicitas.contains(c.nome),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      selectedColor: implicitas.contains(c.nome)
                          ? Cores.carta2
                          : Cores.sangue.withValues(alpha: .22),
                      onSelected: leitura
                          ? null
                          : (_) => _alternarCondicao(c),
                    ),
              ],
            ),
            for (final c in Condicoes.expandir(ativas))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${c.nome}: ${c.efeito}',
                    style: const TextStyle(fontSize: 12, color: Cores.tinta2)),
              ),
          ],
        ),
      ),
    );
  }

  /// Tocar numa condição que já vale e que piora com repetição pergunta:
  /// tirar ou pegar de novo (abalado → apavorado, fraco → debilitado…).
  Future<void> _alternarCondicao(Condicao c) async {
    final ativas = ficha.condicoes;
    final jaVale = Condicoes.expandir(ativas).any((x) => x.nome == c.nome);
    if (jaVale && c.piora.isNotEmpty) {
      final escolha = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(c.nome),
          content: Text('Ficar ${c.nome.toLowerCase()} de novo vira '
              '${c.piora.toLowerCase()}.'),
          actions: [
            if (ativas.contains(c.nome))
              TextButton(
                  onPressed: () => Navigator.pop(ctx, 'tirar'),
                  child: const Text('Tirar')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'piorar'),
                child: Text('Pegar de novo (${c.piora})')),
          ],
        ),
      );
      if (escolha == 'tirar') {
        ficha.alternarCondicao(c.nome);
      } else if (escolha == 'piorar') {
        ficha.condicoes = [
          for (final a in ativas)
            if (a != c.nome) a,
          c.piora,
        ];
      } else {
        return;
      }
    } else {
      ficha.alternarCondicao(c.nome);
    }
    _salvar();
  }

  /// Trilha da classe, do catálogo — escolher já põe as habilidades que o
  /// NEX dá. "Outra" deixa digitar (trilha de campanha, sem automação).
  Widget _seletorTrilha() {
    final c = ficha.classeOP;
    final opcoes = c == null ? const <Trilha>[] : DadosOP.trilhasDe(c.nome);
    final conhecida = opcoes.any((t) => t.nome == ficha.trilha);
    if (opcoes.isEmpty || (!conhecida && ficha.trilha.isNotEmpty)) {
      return _campoTexto('Trilha', ficha.trilha, (v) => ficha.trilha = v);
    }
    return DropdownButtonFormField<String>(
      key: ValueKey('trilha-${ficha.classe}-${ficha.trilha}'),
      isExpanded: true,
      initialValue: conhecida ? ficha.trilha : '',
      decoration: const InputDecoration(labelText: 'Trilha', isDense: true),
      dropdownColor: Cores.carta2,
      items: [
        const DropdownMenuItem(value: '', child: Text('—')),
        for (final t in opcoes)
          DropdownMenuItem(
            value: t.nome,
            child: Text(
                '${t.nome}${t.fonte != 'Livro de Regras' ? ' (SAH)' : ''}'),
          ),
      ],
      onChanged: leitura
          ? null
          : (v) {
              ficha.trilha = v ?? '';
              final (entrou, saiu) = ficha.sincronizarTrilha();
              _salvar();
              _avisarTrilha(entrou, saiu);
            },
    );
  }

  void _avisarTrilha(List<String> entrou, List<String> saiu) {
    if (entrou.isEmpty && saiu.isEmpty) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text([
        if (entrou.isNotEmpty) 'Entrou: ${entrou.join(', ')}.',
        if (saiu.isNotEmpty) 'Saiu: ${saiu.join(', ')}.',
      ].join(' ')),
    ));
  }

  Widget _seletorClasse() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      key: ValueKey('classe-${ficha.classe}'),
      initialValue: DadosOP.classePorNome(ficha.classe) != null
          ? ficha.classe
          : 'Mundano',
      decoration: const InputDecoration(labelText: 'Classe', isDense: true),
      dropdownColor: Cores.carta2,
      items: [
        for (final c in DadosOP.classes)
          DropdownMenuItem(value: c.nome, child: Text(c.nome)),
      ],
      onChanged: leitura
          ? null
          : (v) {
              if (v == null || v == ficha.classe) return;
              _trocarClasse(v);
            },
    );
  }

  /// Troca de classe com tudo que vem junto: NEX coerente (civil em 0%,
  /// agente a partir de 5%), Treinamento Especial do sobrevivente, o que
  /// a classe antiga deixou para trás e o que a nova dá.
  Future<void> _trocarClasse(String nome) async {
    final antiga = ficha.classeOP;
    final nova = DadosOP.classePorNome(nome);
    if (nova == null) return;

    var viraAgenteDeSobrevivente = false;
    if (antiga?.porEstagio == true && nova.agente) {
      viraAgenteDeSobrevivente = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Treinamento Especial?'),
              content: Text(
                  'O sobrevivente (estágio ${ficha.estagio}) vira $nome em '
                  'NEX 5% e MANTÉM o que já tinha, somando o bônus da classe '
                  '(SAH p. 32).'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Não, ficha nova de agente')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Sim, Treinamento Especial')),
              ],
            ),
          ) ??
          false;
    }

    final estagio = ficha.estagio;
    ficha.classe = nome;
    if (viraAgenteDeSobrevivente) ficha.exSobrevivente = estagio;
    if (!nova.agente) {
      ficha.exSobrevivente = 0;
      ficha.nex = 0;
    } else if (ficha.nex == 0) {
      ficha.nex = 5;
    }
    if (!mounted) return;

    if (antiga != null && antiga.nome != nome) {
      final (profs, pericias, indices) = ficha.restosDaClasse(antiga);
      final lista = ficha.habilidades;
      final restos = [
        for (final p in profs) 'proficiência: $p',
        for (final p in pericias) 'perícia: $p',
        for (final i in indices) 'habilidade: ${lista[i]['nome']}',
        if (nome != 'Ocultista' &&
            antiga.nome == 'Ocultista' &&
            ficha.rituais.isNotEmpty)
          '${ficha.rituais.length} ritual(is) (sem Escolhido pelo Outro Lado)',
      ];
      if (restos.isNotEmpty && await _confirmarRemover(antiga.nome, restos)) {
        ficha.removerClasse(antiga);
        if (nome != 'Ocultista' && antiga.nome == 'Ocultista') {
          ficha.dados['rituais'] = <dynamic>[];
        }
      }
    }
    if (!mounted) return;
    if (await _confirmarAplicar(nome, [
      if (nova.proficiencias.isNotEmpty)
        'proficiências: ${nova.proficiencias.join(', ')}',
      if (nova.periciasFixas.isNotEmpty)
        'perícias: ${nova.periciasFixas.join(', ')}',
      for (final h in nova.habilidades) 'habilidade: ${h.nome}',
    ])) {
      ficha.aplicarClasse(nova);
    }
    ficha.trilha = DadosOP.trilhasDe(nome).any((t) => t.nome == ficha.trilha)
        ? ficha.trilha
        : '';
    ficha.sincronizarTrilha();
    _salvar();
  }

  Future<bool> _confirmarRemover(String nome, List<String> restos) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tirar o que era de $nome?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final r in restos) Text('• $r'),
              const SizedBox(height: 8),
              const Text(
                  'Perícias que você subiu de grau ficam. Manter tudo deixa '
                  'pendências na ficha.',
                  style: TextStyle(fontSize: 12, color: Cores.tinta2)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Manter')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tirar')),
        ],
      ),
    );
    return ok == true;
  }

  /// A ficha oficial preenche sozinha o que classe e origem dão. Aqui a
  /// mesma coisa, mas perguntando: trocar de classe no meio da campanha
  /// não pode encher a ficha de habilidade repetida sem o jogador saber.
  Future<bool> _confirmarAplicar(String nome, List<String> ganhos) async {
    if (ganhos.isEmpty) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Aplicar $nome?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preencho na ficha:',
                style: TextStyle(color: Cores.tinta2, fontSize: 13)),
            const SizedBox(height: 6),
            for (final g in ganhos)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $g'),
              ),
            const SizedBox(height: 8),
            const Text('Nada é apagado: o que você já treinou continua.',
                style: TextStyle(color: Cores.tinta2, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Só trocar o nome')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Preencher')),
        ],
      ),
    );
    return ok == true;
  }

  Widget _seletorOrigem() {
    final nomes = [for (final o in DadosOP.origens) o.nome];
    return DropdownButtonFormField<String>(
      isExpanded: true,
      key: ValueKey('origem-${ficha.origem}'),
      initialValue: nomes.contains(ficha.origem) ? ficha.origem : null,
      decoration: const InputDecoration(labelText: 'Origem', isDense: true),
      dropdownColor: Cores.carta2,
      items: [
        for (final o in DadosOP.origens)
          DropdownMenuItem(
            value: o.nome,
            child: Row(
              children: [
                Expanded(child: Text(o.nome)),
                if (o.fonte != 'Livro de Regras')
                  const Text('SAH',
                      style: TextStyle(fontSize: 10, color: Cores.tinta2)),
              ],
            ),
          ),
      ],
      onChanged: leitura
          ? null
          : (v) async {
              if (v == null || v == ficha.origem) return;
              final antiga = ficha.origemAtual;
              if (antiga != null) {
                final (pericias, poder) = ficha.restosDaOrigem(antiga);
                final restos = [
                  for (final p in pericias) 'perícia: $p',
                  if (poder >= 0) 'poder: ${antiga.poder}',
                ];
                if (restos.isNotEmpty &&
                    await _confirmarRemover(antiga.nome, restos)) {
                  ficha.removerOrigem(antiga);
                }
              }
              ficha.origem = v;
              final origem = DadosOP.origens.where((o) => o.nome == v);
              if (origem.isNotEmpty) {
                final o = origem.first;
                if (await _confirmarAplicar(v, [
                  if (o.pericias.isNotEmpty)
                    'perícias: ${o.pericias.join(', ')}',
                  if (o.poder.isNotEmpty) 'poder: ${o.poder}',
                ])) {
                  ficha.aplicarOrigem(o);
                }
              }
              _salvar();
            },
    );
  }

  Widget _seletorPatente() {
    if (DadosOP.patentes.isEmpty || !(ficha.classeOP?.agente ?? true)) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text('Sem patente (civil)',
            style: TextStyle(fontSize: 12, color: Cores.tinta2)),
      );
    }
    return DropdownButtonFormField<String>(
      isExpanded: true,
      key: ValueKey('patente-${ficha.patente}'),
      initialValue: DadosOP.patentePorNome(ficha.patente) != null
          ? ficha.patente
          : 'Recruta',
      decoration: const InputDecoration(labelText: 'Patente', isDense: true),
      dropdownColor: Cores.carta2,
      items: [
        for (final p in DadosOP.patentes)
          DropdownMenuItem(value: p.nome, child: Text(p.nome)),
      ],
      onChanged: leitura
          ? null
          : (v) {
              if (v == null) return;
              ficha.patente = v;
              _salvar();
            },
    );
  }
}

/// Acesso de leitura às listas do model sem repetir o cast em toda tela.
extension on FichaOP {
  List<Map<String, dynamic>> _listaPublica(String chave) {
    switch (chave) {
      case 'habilidades':
        return habilidades;
      case 'rituais':
        return rituais;
      case 'ataques':
        return ataques;
      case 'inventario':
        return inventario;
    }
    return const [];
  }
}
