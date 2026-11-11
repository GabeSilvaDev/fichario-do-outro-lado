import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/dados_op.dart';
import '../mesa/ponte_rolagens.dart';
import '../models/ficha_op.dart';
import '../models/rolagem.dart';
import '../regras/melhorias.dart';
import '../regras/opcionais.dart';
import '../regras/pendencias.dart';
import '../regras/poderes.dart';
import '../store/ficha_store.dart';
import '../theme.dart';
import 'catalogo_screen.dart';
import 'poderes_screen.dart';
import '../widgets/painel_pendencias.dart';
import '../widgets/recurso_contador.dart';
import '../widgets/filtro_rituais.dart';
import '../widgets/leitura.dart';
import '../widgets/retrato.dart';
import '../widgets/seletor_trilha.dart';

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
    ficha =
        widget.fichaDireta ??
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

  /// Painel de pendências aberto pelo ícone da barra, mesmo com tudo
  /// ignorado.
  bool _verPendencias = false;

  /// Só as pendências que cobram (erro/aviso) e que não foram ignoradas.
  List<Pendencia> _naoIgnoradas(List<Pendencia> ps) {
    final ignoradas = ficha.pendenciasIgnoradas;
    return [
      for (final p in ps)
        if (p.gravidade != Gravidade.info && !ignoradas.contains(p.id)) p,
    ];
  }

  void _ignorarPendencias() {
    ficha.pendenciasIgnoradas = _idsQueCobram(pendenciasDe(ficha));
    _verPendencias = false;
    _salvar();
  }

  /// Seção aberta no lápis (null = a ficha toda em leitura). Uma por vez:
  /// abrir outra salva a atual.
  String? _editando;

  /// Como a ficha estava ao abrir o lápis — o Cancelar volta para cá.
  String? _copiaAntes;

  /// A seção [secao] está em edição agora.
  bool _ed(String secao) => !leitura && _editando == secao;

  void _abrirEdicao(String secao) {
    if (leitura) return;
    if (_editando != null) _fecharEdicao(salvar: true);
    _copiaAntes = jsonEncode(ficha.dados);
    setState(() => _editando = secao);
  }

  void _fecharEdicao({required bool salvar}) {
    FocusManager.instance.primaryFocus?.unfocus();
    final copia = _copiaAntes;
    if (!salvar && copia != null) {
      final antes = (jsonDecode(copia) as Map).cast<String, dynamic>();
      ficha.dados
        ..clear()
        ..addAll(antes);
    }
    _copiaAntes = null;
    _editando = null;
    _salvar();
  }

  /// Faixa de seção com o lápis dela.
  Widget _faixa(String secao, String titulo) => FaixaSecao(
    titulo,
    onEditar: leitura ? null : () => _abrirEdicao(secao),
    editando: _ed(secao),
    onSalvar: () => _fecharEdicao(salvar: true),
    onCancelar: () => _fecharEdicao(salvar: false),
  );

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
    final agora = pendenciasDe(ficha);
    // Ignorada que se resolveu sai da lista: se voltar, volta a avisar.
    final ignoradas = ficha.pendenciasIgnoradas;
    final ativas = _idsQueCobram(agora);
    if (ignoradas.any((id) => !ativas.contains(id))) {
      ficha.pendenciasIgnoradas = ignoradas.intersection(ativas);
    }
    FichaStore.salvar(ficha);
    final novas = [
      for (final p in _naoIgnoradas(agora))
        if (!_pendenciasVistas.contains(p.id)) p,
    ];
    _pendenciasVistas = _idsQueCobram(agora);
    setState(() {});
    if (novas.isEmpty || !mounted) return;
    final mensageiro = ScaffoldMessenger.maybeOf(context);
    mensageiro?.hideCurrentSnackBar();
    mensageiro?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Icon(
              PainelPendencias.icone(novas.first.gravidade),
              color: PainelPendencias.cor(novas.first.gravidade),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                novas.length == 1
                    ? novas.first.texto
                    : '${novas.first.texto} (+${novas.length - 1} pendência(s))',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _rolarPericia(Pericia p) {
    final (dados, melhor, bonus) = ficha.testePericia(p);
    final r = Rolagem.teste(
      titulo: p.nome,
      dados: dados,
      melhor: melhor,
      bonus: bonus,
    );
    _mostrarResultado(r);
  }

  void _rolarExpressao(String titulo, String expressao) {
    final r = Rolagem.expressao(titulo, expressao);
    if (r == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não entendi "$expressao" — use algo como 2d6+3.'),
        ),
      );
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
            Text(
              r.formula,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Cores.tinta2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              r.detalhe,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Cores.tinta2,
              ),
            ),
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
                child: Text(
                  'CRÍTICO!',
                  style: TextStyle(
                    color: Cores.estavel,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (r.desastre)
              const Center(
                child: Text(
                  'DESASTRE…',
                  style: TextStyle(
                    color: Cores.sangue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendencias = pendenciasDe(ficha);
    final cobrando = pendencias
        .where((p) => p.gravidade != Gravidade.info)
        .length;
    return DefaultTabController(
      length: 6,
      child: Builder(
        builder: (ctxAbas) => Scaffold(
          appBar: AppBar(
            title: Text(ficha.nome.isEmpty ? 'Ficha' : ficha.nome),
            actions: [
              if (cobrando > 0)
                IconButton(
                  key: const ValueKey('icone-pendencias'),
                  tooltip: _naoIgnoradas(pendencias).isEmpty
                      ? '$cobrando pendência(s) ignorada(s) — toque para ver'
                      : '$cobrando pendência(s)',
                  onPressed: () {
                    DefaultTabController.of(ctxAbas).animateTo(0);
                    setState(() => _verPendencias = !_verPendencias);
                  },
                  icon: Badge(
                    label: Text('$cobrando'),
                    textColor: _naoIgnoradas(pendencias).isEmpty
                        ? Cores.tinta
                        : null,
                    backgroundColor: _naoIgnoradas(pendencias).isEmpty
                        ? Cores.linha
                        : pendencias.any((p) => p.gravidade == Gravidade.erro)
                        ? Cores.sangue
                        : Cores.conhecimento,
                    child: const Icon(Icons.fact_check_outlined),
                  ),
                ),
              if (!leitura) _menuFicha(),
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
        ),
      ),
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

  /// Tipo da ficha e regras, num menu só: são ajustes raros, não precisam
  /// de dois ícones na barra.
  Widget _menuFicha() {
    return PopupMenuButton<String>(
      key: const ValueKey('menu-ficha'),
      icon: const Icon(Icons.more_vert),
      tooltip: 'Ajustes da ficha',
      color: Cores.carta2,
      onSelected: (v) {
        switch (v) {
          case 'jogador':
            ficha.ehNpc = false;
          case 'npc':
            ficha.ehNpc = true;
            ficha.modoLivre = true;
          case 'padrao':
            ficha.modoLivre = false;
          case 'livre':
            ficha.modoLivre = true;
        }
        _salvar();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          enabled: false,
          height: 28,
          child: Text('TIPO', style: TextStyle(fontSize: 11)),
        ),
        CheckedPopupMenuItem(
          value: 'jogador',
          checked: !ficha.ehNpc,
          child: const Text('Personagem de jogador'),
        ),
        CheckedPopupMenuItem(
          value: 'npc',
          checked: ficha.ehNpc,
          child: const Text('NPC / criatura (só sua)'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          enabled: false,
          height: 28,
          child: Text('REGRAS', style: TextStyle(fontSize: 11)),
        ),
        CheckedPopupMenuItem(
          value: 'padrao',
          checked: !ficha.modoLivre,
          child: const Text('Padrão (limites do livro)'),
        ),
        CheckedPopupMenuItem(
          value: 'livre',
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
          Icon(
            npc ? Icons.psychology_alt_outlined : Icons.lock_open,
            size: 15,
            color: npc ? Cores.sangue : Cores.conhecimento,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              npc
                  ? 'NPC / criatura — fica só neste aparelho, fora da mesa.'
                  : 'Modo livre — os limites do livro não travam esta ficha.',
              style: TextStyle(
                fontSize: 12,
                color: npc ? Cores.sangue : Cores.conhecimento,
              ),
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
            pendencias:
                _verPendencias || _naoIgnoradas(pendenciasDe(ficha)).isNotEmpty
                ? pendenciasDe(ficha)
                : const [],
            aoIgnorar: leitura ? null : _ignorarPendencias,
            ignoradas:
                _verPendencias && _naoIgnoradas(pendenciasDe(ficha)).isEmpty,
            aoReativar: leitura
                ? null
                : () {
                    ficha.pendenciasIgnoradas = const {};
                    _verPendencias = false;
                    _salvar();
                  },
            aoIrPara: (aba) =>
                DefaultTabController.of(ctx).animateTo(_abasPorNome[aba] ?? 0),
          ),
        ),
        _faixa('identidade', 'Identidade'),
        if (_ed('identidade')) _identidadeEdicao() else _identidadeLeitura(),
        _faixa('atributos', 'Atributos'),
        _atributos(),
        _faixa('recursos', 'Recursos'),
        ..._recursos(),
        if (_ed('recursos')) _editorMaximos(),
        if (ficha.ehNpc) ...[
          const FaixaSecao('Bloco de ameaça'),
          _blocoAmeaca(),
        ],
        _faixa('defesa', 'Defesa e movimento'),
        _defesa(),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- Identidade -------------------------------------------------------

  Widget _identidadeLeitura() {
    final c = ficha.classeOP;
    final agente = c?.agente ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RetratoAvatar(base64: ficha.retrato, tamanho: 76),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ficha.nome.isEmpty ? 'Sem nome' : ficha.nome,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (ficha.jogador.isNotEmpty)
                        Text(
                          'Jogador: ${ficha.jogador}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Cores.tinta2,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Etiqueta(ficha.classe, cor: Cores.energiaViva),
                          if (ficha.origem.isNotEmpty)
                            Etiqueta(ficha.origem, cor: Cores.tinta),
                          if (agente)
                            Etiqueta(
                              ficha.patente,
                              cor: Cores.conhecimento,
                              icone: Icons.military_tech_outlined,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 26),
            _exposicaoLeitura(),
            if (agente) ...[
              const SizedBox(height: 14),
              InfoLeitura('Trilha', ficha.trilha, detalhe: _detalheTrilha()),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InfoLeitura('Nacionalidade', ficha.nacionalidade),
                ),
                Expanded(
                  child: InfoLeitura(
                    'Idade',
                    ficha.idade > 0 ? '${ficha.idade}' : '',
                  ),
                ),
                if (agente) Expanded(child: InfoLeitura('PP', '${ficha.pp}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _detalheTrilha() {
    if (ficha.trilha.isEmpty) {
      return 'Escolhida em NEX 10%.';
    }
    final doLivro = DadosOP.trilhasParaEscolher(ficha.classe);
    final t = DadosOP.trilhaPorNome(ficha.trilha);
    if (t == null || !doLivro.any((x) => x.nome == t.nome)) {
      return 'Fora do Livro de Regras — troque no lápis.';
    }
    return t.resumo;
  }

  /// NEX grande, com o próximo marco embaixo.
  Widget _exposicaoLeitura() {
    final classe = ficha.classeOP;
    final proximo = classe?.proximoMarco(ficha.nex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: Text(
                'NEX',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: Cores.tinta2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${ficha.nex}%',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Cores.energiaViva,
                height: 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: ficha.nex / 99,
                    minHeight: 6,
                    backgroundColor: Cores.fundo,
                    valueColor: const AlwaysStoppedAnimation(Cores.energia),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (proximo != null) ...[
          const SizedBox(height: 6),
          Text(
            'Próximo, em $proximo%: ${classe!.marcos(proximo).join(' · ')}',
            style: const TextStyle(fontSize: 12, color: Cores.tinta2),
          ),
        ],
      ],
    );
  }

  Widget _identidadeEdicao() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final b64 = await escolherRetrato();
                        if (b64 == null) return;
                        ficha.retrato = b64;
                        _salvar();
                      },
                      child: RetratoAvatar(base64: ficha.retrato, tamanho: 72),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'trocar foto',
                      style: TextStyle(fontSize: 11, color: Cores.tinta2),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    children: [
                      _campoTexto(
                        'Nome do personagem',
                        ficha.nome,
                        (v) => ficha.nome = v,
                      ),
                      const SizedBox(height: 8),
                      _campoTexto(
                        'Jogador',
                        ficha.jogador,
                        (v) => ficha.jogador = v,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _seletorClasse()),
                const SizedBox(width: 8),
                Expanded(child: _seletorOrigem()),
              ],
            ),
            const SizedBox(height: 8),
            _seletorTrilha(),
            const SizedBox(height: 8),
            _seletorPatente(),
            if (ficha.classeOP?.agente ?? false) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _campoNumero(
                      'Pontos de prestígio (PP)',
                      ficha.pp,
                      (v) => ficha.pp = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pelos PP: ${ficha.patentePelosPp}',
                      style: const TextStyle(fontSize: 12, color: Cores.tinta2),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _campoTexto(
                    'Nacionalidade / cidade natal',
                    ficha.nacionalidade,
                    (v) => ficha.nacionalidade = v,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: _campoNumero(
                    'Idade',
                    ficha.idade,
                    (v) => ficha.idade = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _linhaNex(),
          ],
        ),
      ),
    );
  }

  // --- Recursos ---------------------------------------------------------

  /// PV, SAN e PE: + e − sempre à mão (é o que muda na sessão). Mudar o
  /// máximo fica no lápis.
  List<Widget> _recursos() {
    ValueChanged<int>? muda(void Function(int) grava) => leitura
        ? null
        : (v) {
            grava(v);
            _salvar();
          };
    return [
      RecursoContador(
        rotulo: 'VIDA',
        atual: ficha.pv,
        maximo: ficha.pvMax,
        maximoManual: ficha.pvMaxManual,
        cor: Cores.sangue,
        extra: ficha.pvTemporario,
        aoMudar: muda((v) {
          if (v < ficha.pv) {
            ficha.sofrerDano(ficha.pv - v);
          } else {
            ficha.pv = v;
          }
        }),
      ),
      ...[
        RecursoContador(
          rotulo: 'SANIDADE',
          atual: ficha.san,
          maximo: ficha.sanMax,
          maximoManual: ficha.sanMaxManual,
          cor: Cores.energia,
          aoMudar: muda((v) => ficha.san = v),
        ),
        RecursoContador(
          rotulo: 'ESFORÇO',
          atual: ficha.pe,
          maximo: ficha.peMax,
          maximoManual: ficha.peMaxManual,
          cor: Cores.conhecimento,
          aoMudar: muda((v) => ficha.pe = v),
        ),
      ],
      if (!_ed('recursos') &&
          (ficha.pvMaxManual || ficha.sanMaxManual || ficha.peMaxManual))
        const Padding(
          padding: EdgeInsets.only(left: 4, top: 2),
          child: Text(
            '* máximo ajustado pela história (lápis para ver a regra).',
            style: TextStyle(fontSize: 11, color: Cores.tinta2),
          ),
        ),
    ];
  }

  /// Lápis dos recursos: o máximo de cada um, com o valor da regra ao lado.
  /// Digitar o número da regra volta ao automático.
  Widget _editorMaximos() {
    Widget linha(
      String recurso,
      String rotulo,
      int maximo,
      int regra,
      bool manual,
    ) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$rotulo máximo',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    manual
                        ? 'Pela regra seria $regra — ajustado pela história.'
                        : 'Pela regra: $regra (automático).',
                    style: TextStyle(
                      fontSize: 12,
                      color: manual ? Cores.conhecimento : Cores.tinta2,
                    ),
                  ),
                ],
              ),
            ),
            if (manual)
              IconButton(
                tooltip: 'Voltar ao valor da regra',
                icon: const Icon(Icons.restart_alt, size: 20),
                onPressed: () {
                  ficha.definirMaxManual(recurso, null);
                  _salvar();
                },
              ),
            SizedBox(
              width: 76,
              child: TextFormField(
                key: ValueKey('max-$recurso-$manual-$regra'),
                initialValue: '$maximo',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(isDense: true),
                onChanged: (v) {
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) return;
                  ficha.definirMaxManual(recurso, n == regra ? null : n);
                  FichaStore.salvar(ficha);
                },
                onFieldSubmitted: (_) => _salvar(),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Mudou o máximo por algo da história? Digite o novo valor. '
                'O app passa a usar ele no lugar da conta da regra.',
                style: TextStyle(fontSize: 12, color: Cores.tinta2),
              ),
            ),
            linha(
              'pv',
              'PV',
              ficha.pvMax,
              ficha.pvMaxCalculado(),
              ficha.pvMaxManual,
            ),
            ...[
              linha(
                'san',
                'SAN',
                ficha.sanMax,
                ficha.sanMaxCalculado(),
                ficha.sanMaxManual,
              ),
              linha(
                'pe',
                'PE',
                ficha.peMax,
                ficha.peMaxCalculado(),
                ficha.peMaxManual,
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PV temporários',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Por cima da vida; saem primeiro no dano.',
                          style: TextStyle(fontSize: 12, color: Cores.tinta2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 76,
                    child: TextFormField(
                      initialValue: '${ficha.pvTemporario}',
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(isDense: true),
                      onChanged: (v) {
                        ficha.pvTemporario = int.tryParse(v.trim()) ?? 0;
                        FichaStore.salvar(ficha);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Defesa -----------------------------------------------------------

  Widget _defesa() {
    final editando = _ed('defesa');
    final avisos = <Widget>[
      if (_textoRd().isNotEmpty)
        Text(
          'Resistência a dano: ${_textoRd()}',
          style: const TextStyle(fontSize: 12),
        ),
      if (ficha.sobrecarregado)
        const Text(
          'Sobrecarregado: −5 na Defesa, −3m de deslocamento e −5 nas '
          'perícias que sofrem carga.',
          style: TextStyle(fontSize: 12, color: Cores.sangue),
        ),
      if (ficha.semProficienciaEmProtecao != null)
        Text(
          'Sem proficiência em ${ficha.semProficienciaEmProtecao}: −2 d20 em '
          'For e Agi, já aplicado nos testes.',
          style: const TextStyle(fontSize: 12, color: Cores.sangue),
        ),
    ];
    final protecao = switch (ficha.protecaoTipo) {
      'Nenhuma' => 'Nenhuma',
      'Outra' => '${ficha.protecao} (+${ficha.protecaoDefesa})',
      final t => '$t (+${ficha.protecaoDefesa})',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _medalha('DEFESA', '${ficha.defesa}'),
                const SizedBox(width: 10),
                _medalha('DESLOC.', _metros(ficha.deslocamentoEfetivo)),
                const SizedBox(width: 10),
                _medalha('PE/TURNO', '${ficha.limitePeTurno}'),
                const SizedBox(width: 10),
                _medalha('DT RIT.', '${ficha.dtRituais}'),
              ],
            ),
            if (!editando) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InfoLeitura(
                      'Proteção',
                      protecao,
                      detalhe: ficha.escudo ? '+ escudo (+2)' : null,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: InfoLeitura(
                      'Outros bônus',
                      ficha.defesaBonus == 0
                          ? ''
                          : '${ficha.defesaBonus > 0 ? '+' : ''}'
                                '${ficha.defesaBonus}',
                    ),
                  ),
                ],
              ),
              if (ficha.resistencias.isNotEmpty) ...[
                const SizedBox(height: 10),
                InfoLeitura('Resistências', ficha.resistencias),
              ],
            ],
            for (final a in avisos)
              Padding(padding: const EdgeInsets.only(top: 8), child: a),
            if (editando) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _seletorProtecao()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _campoNumero(
                      'Deslocamento (m)',
                      ficha.deslocamento,
                      (v) => ficha.deslocamento = v,
                    ),
                  ),
                ],
              ),
              if (ficha.protecaoTipo == 'Outra') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _campoTexto(
                        'Nome da proteção',
                        ficha.protecao,
                        (v) => ficha.protecao = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _campoNumero(
                        'Defesa da proteção',
                        ficha.protecaoDefesa,
                        (v) => ficha.protecaoDefesa = v,
                      ),
                    ),
                  ],
                ),
              ],
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: ficha.escudo,
                title: const Text(
                  'Escudo (+2 Defesa, 2 espaços)',
                  style: TextStyle(fontSize: 14),
                ),
                onChanged: (v) {
                  ficha.escudo = v ?? false;
                  _salvar();
                },
              ),
              _campoNumero(
                'Outros bônus de Defesa',
                ficha.defesaBonus,
                (v) => ficha.defesaBonus = v,
              ),
              const SizedBox(height: 8),
              _campoTexto(
                'Resistências',
                ficha.resistencias,
                (v) => ficha.resistencias = v,
              ),
            ],
          ],
        ),
      ),
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
            Text(
              valor,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Cores.tinta,
              ),
            ),
            Text(
              rotulo,
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: Cores.tinta2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// NEX de quando o jogador pegou a régua — para contar o que ganhou ao
  /// soltar, e não a cada passo do arrasto.
  int? _nexAoPegar;

  Widget _linhaNex() {
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
                const Text(
                  'NEX',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12,
                    color: Cores.energiaViva,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: (ficha.nex == 99 ? 100 : ficha.nex).toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: Cores.energia,
                    label: '${ficha.nex}%',
                    onChangeStart: leitura
                        ? null
                        : (_) => _nexAoPegar = ficha.nex,
                    onChanged: leitura
                        ? null
                        : (v) {
                            final passo = v.round();
                            ficha.nex = passo >= 100 ? 99 : passo;
                            _salvar();
                          },
                    onChangeEnd: leitura ? null : (_) => _mostrarGanhosDeNex(),
                  ),
                ),
                Text(
                  '${ficha.nex}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Cores.tinta,
                  ),
                ),
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
    if (!classe.agente && ficha.nex > 0) {
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
                Text(
                  '${e.key}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Cores.energiaViva,
                  ),
                ),
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
            child: const Text('Entendi'),
          ),
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
          'atributo (máx. 3). O que for da classe entra agora.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('Voltar a 0%'),
          ),
          for (final c in const ['Combatente', 'Especialista', 'Ocultista'])
            TextButton(onPressed: () => Navigator.pop(ctx, c), child: Text(c)),
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

  /// Teste puro de atributo: tantos d20 quanto o valor, o melhor (0: 2d20,
  /// o pior).
  void _rolarAtributo(String sigla) {
    final valor = ficha.atributo(sigla);
    _mostrarResultado(
      Rolagem.teste(
        titulo: sigla,
        dados: valor <= 0 ? 2 : valor,
        melhor: valor > 0,
        bonus: 0,
      ),
    );
  }

  Widget _atributos() {
    const siglas = ['AGI', 'FOR', 'INT', 'PRE', 'VIG'];
    final editando = _ed('atributos');
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
        child: Column(
          children: [
            _linhaAtributos(siglas, editando),
            const SizedBox(height: 6),
            Text(
              editando
                  ? (ficha.modoLivre
                        ? 'Toque num atributo para digitar o valor.'
                        : 'Toque num atributo para mudar (0 a 5).')
                  : 'Toque num atributo para rolar o teste.',
              style: const TextStyle(fontSize: 11, color: Cores.tinta2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaAtributos(List<String> siglas, bool editando) {
    return Builder(
      builder: (_) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final s in siglas)
            Column(
              children: [
                Text(
                  s,
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: Cores.tinta2,
                  ),
                ),
                const SizedBox(height: 2),
                InkWell(
                  key: ValueKey('atributo-$s'),
                  onTap: !editando
                      ? () => _rolarAtributo(s)
                      : () {
                          if (ficha.modoLivre) {
                            _digitarAtributo(s);
                          } else {
                            ficha.definirAtributo(
                              s,
                              (ficha.atributo(s) + 1) % 6,
                            );
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
                      border: Border.all(
                        color: editando ? Cores.conhecimento : Cores.energia,
                        width: editando ? 2 : 1.5,
                      ),
                      color: Cores.carta2,
                    ),
                    child: Text(
                      '${ficha.atributo(s)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Cores.tinta,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
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
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, campo.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (valor == null) return;
    final n = int.tryParse(valor.trim());
    if (n == null) return;
    ficha.definirAtributo(sigla, n);
    _salvar();
  }

  final _campoDadoRapido = TextEditingController();

  /// Aceita "2d6+3" e também a sintaxe da ficha oficial: "/AGI/d20" rola o
  /// atributo (tantos d20 quanto o valor, pegando o melhor).
  void _rolarRapido() {
    final bruto = _campoDadoRapido.text.trim();
    if (bruto.isEmpty) return;
    final atributo = RegExp(
      r'^/?(AGI|FOR|INT|PRE|VIG)(/d?20)?$',
      caseSensitive: false,
    ).firstMatch(bruto);
    if (atributo != null) {
      final sigla = atributo.group(1)!.toUpperCase();
      final valor = ficha.atributo(sigla);
      _mostrarResultado(
        Rolagem.teste(
          titulo: sigla,
          dados: valor <= 0 ? 2 : valor,
          melhor: valor > 0,
          bonus: 0,
        ),
      );
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
                  icon: const Icon(
                    Icons.casino_outlined,
                    color: Cores.energiaViva,
                  ),
                  onPressed: _rolarRapido,
                ),
              ],
            ),
          ),
        ),
        _faixa('pericias', 'Perícias'),
        if (_ed('pericias')) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'Toque no grau para treinar (— → T → V → E). Toque na sigla '
              'para trocar o atributo que a perícia usa.',
              style: TextStyle(fontSize: 12, color: Cores.tinta2),
            ),
          ),
          for (final p in DadosOP.pericias) _linhaPericia(p),
        ] else
          ..._periciasLeitura(),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          children: const [
            Text(
              '— destreinada',
              style: TextStyle(fontSize: 11, color: Cores.tinta2),
            ),
            Text(
              'T treinada +5',
              style: TextStyle(fontSize: 11, color: Cores.estavel),
            ),
            Text(
              'V veterano +10',
              style: TextStyle(fontSize: 11, color: Cores.energiaViva),
            ),
            Text(
              'E expert +15',
              style: TextStyle(fontSize: 11, color: Cores.conhecimento),
            ),
            Text(
              '* só treinada',
              style: TextStyle(fontSize: 11, color: Cores.tinta2),
            ),
            Text(
              '↓ pega o pior dado',
              style: TextStyle(fontSize: 11, color: Cores.tinta2),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Leitura: treinadas em cima, destreinadas embaixo. A linha inteira
  /// rola o teste.
  List<Widget> _periciasLeitura() {
    final treinadas = [
      for (final p in DadosOP.pericias)
        if (ficha.grauPericia(p.nome) > 0) p,
    ];
    final outras = [
      for (final p in DadosOP.pericias)
        if (ficha.grauPericia(p.nome) <= 0) p,
    ];
    Widget titulo(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Cores.tinta2,
        ),
      ),
    );
    return [
      const Padding(
        padding: EdgeInsets.only(bottom: 2),
        child: Text(
          'Toque numa perícia para rolar. O teste aparece para o mestre se '
          'você estiver numa mesa.',
          style: TextStyle(fontSize: 12, color: Cores.tinta2),
        ),
      ),
      titulo('Treinadas (${treinadas.length})'),
      if (treinadas.isEmpty)
        const VazioLeitura('Nenhuma perícia treinada.')
      else
        Card(
          child: Column(
            children: [
              for (var i = 0; i < treinadas.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 12, endIndent: 12),
                _linhaPericiaLeitura(treinadas[i]),
              ],
            ],
          ),
        ),
      titulo('Destreinadas (${outras.length})'),
      Card(
        child: Column(
          children: [
            for (var i = 0; i < outras.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 12, endIndent: 12),
              _linhaPericiaLeitura(outras[i]),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _linhaPericiaLeitura(Pericia p) {
    final grau = ficha.grauPericia(p.nome);
    final (dados, melhor, bonus) = ficha.testePericia(p);
    final treinada = grau > 0;
    // O "só treinada" já está no * (legenda no rodapé): repetir em cada
    // linha só polui a lista.
    final motivos = [
      for (final m in ficha.motivosDoTeste(p))
        if (!m.startsWith('só treinada')) m,
    ];
    return InkWell(
      key: ValueKey('pericia-${p.nome}'),
      onTap: () => _rolarPericia(p),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                ficha.atributoPericia(p),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: ficha.atributoTrocado(p)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: ficha.atributoTrocado(p)
                      ? Cores.energiaViva
                      : Cores.tinta2,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nome + (p.soTreinada && !treinada ? ' *' : ''),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: treinada
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: treinada ? Cores.tinta : Cores.tinta2,
                    ),
                  ),
                  if (motivos.isNotEmpty)
                    Text(
                      motivos.join(' · '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Cores.conhecimento,
                      ),
                    ),
                ],
              ),
            ),
            if (treinada) ...[
              Etiqueta(_rotuloGrau(grau), cor: _corDoGrau(grau)),
              const SizedBox(width: 10),
            ],
            SizedBox(
              width: 74,
              child: Text(
                '${dados}d20${melhor ? '' : '↓'}'
                '${bonus == 0 ? '' : (bonus > 0 ? '+$bonus' : '$bonus')}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: treinada ? Cores.energiaViva : Cores.tinta2,
                ),
              ),
            ),
          ],
        ),
      ),
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
                      fontWeight: grau > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: grau > 0 ? Cores.tinta : Cores.tinta2,
                    ),
                  ),
                  Text(
                    '${dados}d20${melhor ? '' : ' (pior)'}'
                    '${bonus >= 0 ? '+' : ''}$bonus'
                    '${motivos.isEmpty ? '' : ' · ${motivos.join(' · ')}'}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: motivos.isEmpty
                          ? Cores.tinta2
                          : Cores.conhecimento,
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
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
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
                    color: _corDoGrau(grau),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip:
                  'Rolar ${dados}d20 (${melhor ? 'melhor' : 'pior'}) +$bonus',
              icon: const Icon(
                Icons.casino_outlined,
                color: Cores.energiaViva,
                size: 22,
              ),
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
    if (!_ed('pericias')) return texto;

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
                fontWeight: sigla == atual
                    ? FontWeight.bold
                    : FontWeight.normal,
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
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      children: [
        _faixa('ataques', 'Ataques'),
        for (var i = 0; i < ataques.length; i++) _cartaoAtaque(i, ataques[i]),
        if (ataques.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Nenhum ataque ainda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Cores.tinta2),
            ),
          ),
        if (_ed('ataques'))
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
    final semTeste = a['semTeste'] == true;
    final r = ficha.resumoAtaque(a);
    final arma = ficha.armaDoCatalogo(a);
    final melhorias = ficha.melhoriasDe(a);
    final ativas = melhorias.ativas;
    final titulo = nome.isEmpty ? pericia : nome;
    final duasOpcoes = r.danos.length > 1;
    final ehCoronhada = '${a['arma'] ?? nome}' == 'Coronhada';
    String opcao(int i) => !duasOpcoes
        ? ''
        : ehCoronhada
        ? (i == 0 ? ' (arma leve ou de uma mão)' : ' (arma de duas mãos)')
        : (i == 0 ? ' (uma mão)' : ' (duas mãos)');
    final teste = fixos > 0
        ? '${fixos}d20+${a['bonusTeste'] ?? 0}'
        : '${r.dados}d20${r.melhor ? '' : ' (pior)'}'
              '${r.bonus == 0 ? '' : (r.bonus > 0 ? '+${r.bonus}' : '${r.bonus}')}';
    final atributoNoDano = r.atributoNoDano.isEmpty
        ? ''
        : '${r.atributoNoDano == 'AGI' ? 'Agilidade' : 'Força'} '
              '${ficha.atributo(r.atributoNoDano)} já somada';
    final municao = '${arma?['municao'] ?? ''}';
    final regras = [
      for (final e in (arma?['especial'] as List? ?? const [])) '$e',
      if ('${a['especial'] ?? ''}'.trim().isNotEmpty) '${a['especial']}',
      for (final m in ativas) '${m.nome}: ${m.efeito}',
    ];

    Widget linha(String rotulo, String valor, {Color? cor}) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              rotulo,
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: Cores.tinta2,
                height: 1.9,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: cor ?? Cores.tinta,
              ),
            ),
          ),
        ],
      ),
    );

    return Card(
      key: ValueKey('ataque-$indice'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    nome.isEmpty ? 'Sem nome' : nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_ed('ataques'))
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Cores.tinta2,
                    ),
                    onPressed: () => _editarAtaque(indice),
                  ),
              ],
            ),
            if (ativas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final m in ativas)
                      Etiqueta(
                        m.nome,
                        cor: m.maldicao
                            ? (_corElemento[m.elemento] ?? Cores.energiaViva)
                            : Cores.energiaViva,
                        icone: m.maldicao
                            ? Icons.auto_awesome
                            : Icons.build_outlined,
                      ),
                  ],
                ),
              ),
            if ('${arma?['descricao'] ?? ''}'.isNotEmpty)
              Text(
                '${arma!['descricao']}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: Cores.tinta2,
                ),
              ),
            linha(
              'ATAQUE',
              semTeste
                  ? 'Sem teste de ataque — o alvo resiste'
                  : '$pericia $teste',
            ),
            for (var i = 0; i < r.danos.length; i++)
              linha(
                i == 0 ? 'DANO' : '',
                '${r.expressaoDano(r.danos[i])}${opcao(i)}'
                '${tipo.isNotEmpty ? ' $tipo' : ''}',
                cor: Cores.sangue,
              ),
            if (r.danos.isNotEmpty && !semTeste) ...[
              linha(
                'CRÍTICO',
                '${r.textoMargem} no d20 · dano ×${r.multiplicador}',
                cor: Cores.conhecimento,
              ),
              for (var i = 0; i < r.danos.length; i++)
                linha(
                  i == 0 ? 'NO CRÍTICO' : '',
                  '${r.expressaoCritico(r.danos[i])}${opcao(i)}',
                  cor: Cores.conhecimento,
                ),
            ],
            if (alcance.isNotEmpty)
              linha('ALCANCE', melhorias.alcance(alcance)),
            if (ativas.isNotEmpty)
              linha(
                'CATEGORIA',
                '${melhorias.categoriaBaseTexto} → '
                    '${melhorias.categoriaTexto}'
                    '${melhorias.amaldicoada ? ' (amaldiçoada)' : ''}',
              ),
            if (municao.isNotEmpty) linha('MUNIÇÃO', municao),
            if (atributoNoDano.isNotEmpty ||
                r.semProficiencia != null ||
                r.automatica)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  [
                    if (atributoNoDano.isNotEmpty) '$atributoNoDano no dano.',
                    if (r.semProficiencia != null)
                      'Sem proficiência em ${r.semProficiencia}: −2 d20 (já '
                          'no teste).',
                  ].join(' '),
                  style: TextStyle(
                    fontSize: 12,
                    color: r.semProficiencia != null
                        ? Cores.sangue
                        : Cores.tinta2,
                  ),
                ),
              ),
            if (regras.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final t in regras)
                      Text(
                        '• $t',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Cores.tinta2,
                        ),
                      ),
                  ],
                ),
              ),
            if (_ed('ataques'))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  key: ValueKey('melhorias-$indice'),
                  onPressed: () => _editarMelhorias(indice),
                  icon: const Icon(Icons.tune, size: 16),
                  label: Text(
                    ativas.isEmpty
                        ? 'Modificações e maldições'
                        : 'Modificações e maldições (${ativas.length})',
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (!semTeste)
                  OutlinedButton.icon(
                    onPressed: () {
                      final t = fixos > 0
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
                      _mostrarResultado(t);
                    },
                    icon: const Icon(Icons.casino_outlined, size: 16),
                    label: const Text('Teste'),
                  ),
                for (var i = 0; i < r.danos.length; i++) ...[
                  OutlinedButton.icon(
                    onPressed: () => _rolarExpressao(
                      'Dano: $titulo',
                      r.expressaoDano(r.danos[i]),
                    ),
                    icon: const Icon(Icons.bolt_outlined, size: 16),
                    label: Text(duasOpcoes ? 'Dano${opcao(i)}' : 'Dano'),
                  ),
                  if (!semTeste)
                    TextButton(
                      onPressed: () {
                        final res = Rolagem.expressao(
                          'Crítico: $titulo',
                          r.expressaoCritico(r.danos[i]),
                        );
                        if (res != null) _mostrarResultado(res);
                      },
                      child: Text(
                        'Crítico ×${r.multiplicador}${duasOpcoes ? opcao(i) : ''}',
                      ),
                    ),
                ],
                if (r.automatica)
                  OutlinedButton.icon(
                    key: ValueKey('rajada-$indice'),
                    onPressed: () {
                      final rr = ficha.resumoAtaque(a, rajada: true);
                      _mostrarResultado(
                        Rolagem.teste(
                          titulo: 'Rajada: $titulo',
                          dados: rr.dados,
                          melhor: rr.melhor,
                          bonus: rr.bonus,
                          margem: rr.margem,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.local_fire_department_outlined,
                      size: 16,
                    ),
                    label: const Text('Rajada'),
                  ),
                if (r.automatica && r.danos.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      final rr = ficha.resumoAtaque(a, rajada: true);
                      _rolarExpressao(
                        'Dano da rajada: $titulo',
                        rr.expressaoDano(rr.danos.first),
                      );
                    },
                    child: const Text('Dano da rajada'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const Map<String, Color> _corElemento = {
    'Conhecimento': Cores.conhecimento,
    'Energia': Cores.energiaViva,
    'Morte': Cores.tinta2,
    'Sangue': Cores.sangue,
  };

  /// Liga e desliga modificações e maldições de um ataque. Só aparece o que
  /// cabe na arma; maldição de elemento opressor fica travada. A categoria
  /// e o item do inventário acompanham.
  Future<void> _editarMelhorias(int indice) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Cores.carta,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final a = ficha.ataques[indice];
          final m = ficha.melhoriasDe(a);
          final ativasMod = m.nomesModificacoes;
          final ativasMal = m.nomesMaldicoes;

          void alternar(Melhoria x, bool liga) {
            final novo = Map<String, dynamic>.from(a);
            novo['categoriaBase'] ??= '${a['categoria'] ?? ''}';
            novo['espacosBase'] ??= '${a['espacos'] ?? ''}';
            final chave = x.maldicao ? 'maldicoes' : 'modificacoes';
            final lista = [
              for (final n in (a[chave] as List? ?? const [])) '$n',
            ];
            if (liga) {
              if (!lista.contains(x.nome)) lista.add(x.nome);
            } else {
              lista.remove(x.nome);
              // Sem ferrolho, o compensador não tem onde ficar.
              if (x.nome == 'Ferrolho automático') {
                lista.remove('Compensador');
              }
            }
            novo[chave] = lista;
            final efetivas = ficha.melhoriasDe(novo);
            novo['categoria'] = efetivas.categoriaTexto;
            if (efetivas.espacosBase > 0) {
              novo['espacos'] = '${efetivas.espacos}';
            }
            ficha.atualizarEm('ataques', indice, novo);
            _sincronizarItemDaArma(indice);
            _salvar();
            setLocal(() {});
          }

          Widget interruptor(Melhoria x, bool ligada) {
            final conflito = ligada ? null : m.conflitoDe(x);
            return SwitchListTile(
              key: ValueKey('melhoria-${x.nome}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: ligada,
              title: Text(
                x.nome,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: conflito != null ? Cores.tinta2 : Cores.tinta,
                ),
              ),
              subtitle: Text(
                conflito != null
                    ? 'Não combina com maldição de $conflito (elemento '
                          'opressor).'
                    : x.efeito,
                style: TextStyle(
                  fontSize: 12,
                  color: conflito != null ? Cores.sangue : Cores.tinta2,
                ),
              ),
              onChanged: conflito != null ? null : (v) => alternar(x, v),
            );
          }

          final porGrupo = <String, List<Melhoria>>{};
          for (final x in m.modificacoesPossiveis) {
            porGrupo.putIfAbsent(x.para, () => []).add(x);
          }
          final porElemento = <String, List<Melhoria>>{};
          for (final x in m.maldicoesPossiveis) {
            porElemento.putIfAbsent(x.elemento, () => []).add(x);
          }
          final patente = DadosOP.patentePorNome(ficha.patente);
          final semPatente =
              !ficha.ehNpc &&
              ativasMal.isNotEmpty &&
              (patente == null || patente.pp < 50);

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (ctx, rolagem) => ListView(
              controller: rolagem,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              children: [
                Text(
                  '${a['nome']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Categoria ${m.categoriaBaseTexto} → ${m.categoriaTexto}'
                  '${m.amaldicoada ? ' · amaldiçoada' : ''}',
                  key: const ValueKey('categoria-melhorias'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Cores.conhecimento,
                  ),
                ),
                const Text(
                  'Cada modificação sobe I; a 1ª maldição sobe II e as '
                  'outras I. Iguais não acumulam. O item no inventário '
                  'acompanha.',
                  style: TextStyle(fontSize: 12, color: Cores.tinta2),
                ),
                if (semPatente)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Arma amaldiçoada só a partir de Agente Especial.',
                      style: TextStyle(fontSize: 12, color: Cores.sangue),
                    ),
                  ),
                for (final g in porGrupo.entries) ...[
                  FaixaSecao('Modificações · ${g.key}'),
                  for (final x in g.value)
                    interruptor(x, ativasMod.contains(x.nome)),
                ],
                for (final g in porElemento.entries) ...[
                  FaixaSecao('Maldições · ${g.key}'),
                  for (final x in g.value)
                    interruptor(x, ativasMal.contains(x.nome)),
                ],
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Preço da maldição: para cada uma, perde 2 SAN ao falhar '
                    'num teste do atributo do elemento (Conhecimento: Int · '
                    'Energia: Agi · Morte: Pre · Sangue: For ou Vig).',
                    style: TextStyle(fontSize: 12, color: Cores.tinta2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// O item do inventário que é esta arma (ligado pelo `itemId`, ou pelo
  /// nome, na ficha antiga) passa a ter a categoria, os espaços e a marca de
  /// amaldiçoado da arma modificada — é o que conta no limite da patente.
  void _sincronizarItemDaArma(int indice) {
    final a = ficha.ataques[indice];
    final itens = ficha.inventario;
    var alvo = -1;
    final id = '${a['itemId'] ?? ''}';
    if (id.isNotEmpty) alvo = itens.indexWhere((i) => i['id'] == id);
    if (alvo < 0) {
      final nome = '${a['arma'] ?? a['nome']}';
      alvo = itens.indexWhere(
        (i) => i['nome'] == nome && '${i['id'] ?? ''}'.isEmpty,
      );
    }
    if (alvo < 0) return;
    final m = ficha.melhoriasDe(a);
    final novoId = id.isNotEmpty
        ? id
        : 'arma-${DateTime.now().microsecondsSinceEpoch}';
    final item = Map<String, dynamic>.from(itens[alvo])
      ..['id'] = novoId
      ..['categoria'] = m.categoriaTexto
      ..['amaldicoado'] = m.amaldicoada;
    if (m.espacosBase > 0) item['espacos'] = m.espacos;
    ficha.atualizarEm('inventario', alvo, item);
    if (id.isEmpty) {
      ficha.atualizarEm('ataques', indice, {...a, 'itemId': novoId});
    }
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
    final id = 'arma-${DateTime.now().microsecondsSinceEpoch}';
    final item = <String, dynamic>{
      'id': id,
      'nome': escolhido['nome'],
      'categoria': '${escolhido['categoria'] ?? ''}'.isEmpty
          ? '0'
          : escolhido['categoria'],
      'espacos': FichaOP.paraIntSeguro(escolhido['espacos']),
    };
    final ehArma = '${escolhido['dano'] ?? ''}'.isNotEmpty;
    if (ehArma) ficha.adicionarEm('ataques', {...escolhido, 'itemId': id});
    if ('${escolhido['espacos'] ?? ''}'.isNotEmpty) {
      ficha.adicionarEm('inventario', item);
    }
    _salvar();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          ehArma
              ? '${escolhido['nome']}: ataque e item no inventário.'
              : '${escolhido['nome']}: item no inventário.',
        ),
      ),
    );
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
          nex: ficha.nex,
          rituaisRestantes: livre
              ? null
              : limiteDeRituais(ficha).$1 - ficha.rituais.length,
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
    final bonus = TextEditingController(text: '${atual['bonus'] ?? 0}');
    final dano = TextEditingController(text: (atual['dano'] ?? '') as String);
    final critico = TextEditingController(
      text: (atual['critico'] ?? '') as String,
    );
    final margem = TextEditingController(
      text: (atual['margem'] ?? '') as String,
    );
    final alcance = TextEditingController(
      text: (atual['alcance'] ?? '') as String,
    );
    final especial = TextEditingController(
      text: (atual['especial'] ?? '') as String,
    );
    var pericia = (atual['pericia'] ?? 'Luta') as String;
    var tipo = (atual['tipo'] ?? '') as String;
    var familia = '${atual['familia'] ?? ''}';
    if (!const [
      '',
      'Armas Simples',
      'Armas Táticas',
      'Armas Pesadas',
    ].contains(familia)) {
      familia = '';
    }
    var daOrigem = atual['armaDaOrigem'] == true;
    final origemComArma = ficha.origemAtual?.flag('armaFavorita') ?? false;
    const tiposDano = [
      '',
      'corte',
      'impacto',
      'perfuração',
      'balístico',
      'fogo',
      'elétrico',
      'químico',
      'mental',
      'de conhecimento',
      'de energia',
      'de morte',
      'de sangue',
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
                  decoration: const InputDecoration(
                    labelText: 'Nome (ex.: Pistola)',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: pericia,
                  decoration: const InputDecoration(
                    labelText: 'Perícia do teste',
                  ),
                  dropdownColor: Cores.carta2,
                  items: const [
                    DropdownMenuItem(value: 'Luta', child: Text('Luta')),
                    DropdownMenuItem(
                      value: 'Pontaria',
                      child: Text('Pontaria'),
                    ),
                  ],
                  onChanged: (v) => setLocal(() => pericia = v ?? 'Luta'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bonus,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Bônus extra no teste',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: dano,
                  decoration: const InputDecoration(
                    labelText: 'Dano (ex.: 1d12+2)',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo de dano'),
                  dropdownColor: Cores.carta2,
                  items: [
                    for (final t in tiposDano)
                      DropdownMenuItem(
                        value: t,
                        child: Text(t.isEmpty ? '—' : t),
                      ),
                  ],
                  onChanged: (v) => setLocal(() => tipo = v ?? ''),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: margem,
                        decoration: const InputDecoration(
                          labelText: 'Margem (ex.: 19)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: critico,
                        decoration: const InputDecoration(
                          labelText: 'Crítico (ex.: x2)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: alcance,
                  decoration: const InputDecoration(
                    labelText: 'Alcance (ex.: curto)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: especial,
                  decoration: const InputDecoration(
                    labelText: 'Especial / recarga',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: familia,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de arma (proficiência)',
                  ),
                  dropdownColor: Cores.carta2,
                  items: const [
                    DropdownMenuItem(value: '', child: Text('— (sem checar)')),
                    DropdownMenuItem(
                      value: 'Armas Simples',
                      child: Text('Simples'),
                    ),
                    DropdownMenuItem(
                      value: 'Armas Táticas',
                      child: Text('Tática'),
                    ),
                    DropdownMenuItem(
                      value: 'Armas Pesadas',
                      child: Text('Pesada'),
                    ),
                  ],
                  onChanged: (v) => setLocal(() => familia = v ?? ''),
                ),
                if (origemComArma)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: daOrigem,
                    title: const Text(
                      'Arma da origem (Operário)',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Proficiente; +1 ataque, dano e margem',
                      style: TextStyle(fontSize: 12),
                    ),
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
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Cores.sangue),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
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
          // Só a afinidade (NEX 50%) se escolhe aqui: antes disso, sem lápis.
          if (ficha.nex >= 50)
            _faixa('regua', 'Na régua agora')
          else
            const FaixaSecao('Na régua agora'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in escalas) Text('• $e'),
                  Text('• Limite de PE por turno: ${ficha.limitePeTurno}'),
                  Text(
                    '• DT de habilidades: 10 + ${ficha.limitePeBase} + '
                    'atributo · DT de rituais: ${ficha.dtRituais}',
                  ),
                  if (ficha.transcendencias > 0)
                    Text(
                      '• Transcender: ${ficha.transcendencias} '
                      '(−${ficha.transcendencias * c!.sanPorNivel} SAN máx.)',
                    ),
                  if (ficha.nex >= 50) ...[
                    const SizedBox(height: 8),
                    if (_ed('regua'))
                      _seletorAfinidade()
                    else
                      InfoLeitura(
                        'Afinidade',
                        ficha.afinidade,
                        detalhe: ficha.afinidade.isEmpty
                            ? 'Escolha no lápis (NEX 50%).'
                            : null,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
        _faixa('poderes', 'Habilidades e poderes'),
        ..._listaSimples(
          'habilidades',
          'habilidade',
          camposExtras: const [],
          habilidade: true,
          editando: _ed('poderes'),
        ),
        if (_ed('poderes') && DadosOP.poderes.isNotEmpty)
          Center(
            child: TextButton.icon(
              onPressed: _poderDoCatalogo,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Do catálogo de poderes'),
            ),
          ),
        // Quem não conjura (sem ritual e sem limite) não vê a seção vazia;
        // modo livre e NPC sempre podem pôr ritual.
        if (ficha.rituais.isNotEmpty ||
            limite > 0 ||
            ficha.modoLivre ||
            ficha.ehNpc) ...[
          _faixa('rituais', 'Rituais · ${ficha.rituais.length} de $limite'),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'DT ${ficha.dtRituais} para resistir. Conjurar gasta PE e pede '
              'Ocultismo DT 20 + custo (Medo: perde SAN e 1 permanente) — '
              'o app faz a conta.',
              style: const TextStyle(fontSize: 12, color: Cores.tinta2),
            ),
          ),
          ..._listaRituais(),
          if (_ed('rituais'))
            Center(
              child: TextButton.icon(
                onPressed: _ritualDoCatalogo,
                icon: const Icon(Icons.auto_stories_outlined),
                label: const Text('Do catálogo de rituais'),
              ),
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  static const List<(String, String)> _camposRitual = [
    ('circulo', 'Círculo (1º a 4º)'),
    ('custo', 'Custo (PE)'),
    ('elemento', 'Elemento'),
    ('execucao', 'Execução'),
    ('alcance', 'Alcance'),
    ('duracao', 'Duração'),
  ];

  static const Map<String, Color> _corDoElemento = {
    'Conhecimento': Cores.conhecimento,
    'Energia': Cores.energiaViva,
    'Morte': Color(0xFF9E9AA8),
    'Sangue': Cores.sangue,
    'Medo': Cores.tinta,
  };

  /// Rituais abertos para ver as formas Discente e Verdadeira.
  final Set<int> _ritualAberto = {};

  /// Alvo, resistência, efeito e formas maiores do ritual: dos campos
  /// próprios (catálogo novo) ou, na ficha antiga, das linhas da descrição.
  static (String, String, String, List<(String, String, String)>)
  _partesDoRitual(Map<String, dynamic> r) {
    final amp = <(String, String, String)>[
      for (final a in (r['ampliacoes'] as List? ?? const []))
        if (a is Map) ('${a['nome']}', '${a['custo']}', '${a['efeito']}'),
    ];
    if (r['efeito'] != null) {
      return (
        '${r['alvo'] ?? ''}',
        '${r['resistencia'] ?? ''}',
        '${r['efeito']}',
        amp,
      );
    }
    var alvo = '';
    var resistencia = '';
    final efeito = <String>[];
    final forma = RegExp(r'^(Discente|Verdadeir[oa])\s*\(\+(\d+)\s*PE\):\s*');
    for (final linha in '${r['descricao'] ?? ''}'.split('\n')) {
      final l = linha.trim();
      if (l.isEmpty) continue;
      final m = forma.firstMatch(l);
      if (l.startsWith('Alvo: ')) {
        alvo = l.substring(6);
      } else if (l.startsWith('Resistência: ')) {
        resistencia = l.substring(13);
      } else if (m != null) {
        amp.add((m[1]!, m[2]!, l.substring(m.end)));
      } else {
        efeito.add(l);
      }
    }
    return (alvo, resistencia, efeito.join('\n'), amp);
  }

  AgrupaRituais _agrupaRituais = AgrupaRituais.circulo;
  String? _filtroRituais;

  String _elementoDoRitual(Map<String, dynamic> r) {
    final e = '${r['elemento'] ?? ''}'.trim();
    if (e.isNotEmpty) return e;
    return '${DadosOP.ritualPorNome('${r['nome'] ?? ''}')?['elemento'] ?? ''}';
  }

  List<Widget> _listaRituais() {
    final lista = ficha.rituais;
    final avisos = avisosDosRituais(ficha);
    String grupo(int i) => grupoDoRitual(
      _agrupaRituais,
      circuloDoRitual(lista[i]),
      _elementoDoRitual(lista[i]),
    );
    final porGrupo = <String, List<int>>{};
    for (var i = 0; i < lista.length; i++) {
      (porGrupo[grupo(i)] ??= []).add(i);
    }
    // Filtro que sumiu (trocou o modo ou tirou o último ritual) volta a Todos.
    final filtro = porGrupo.containsKey(_filtroRituais) ? _filtroRituais : null;
    final ordem = gruposEmOrdem(_agrupaRituais, porGrupo.keys);
    return [
      if (lista.length > 1)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: FiltroRituais(
            modo: _agrupaRituais,
            filtro: filtro,
            contagem: {for (final e in porGrupo.entries) e.key: e.value.length},
            aoMudarModo: (m) => setState(() {
              _agrupaRituais = m;
              _filtroRituais = null;
            }),
            aoFiltrar: (g) => setState(() => _filtroRituais = g),
          ),
        ),
      for (final g in ordem)
        if (filtro == null || filtro == g) ...[
          if (lista.length > 1)
            TituloGrupoRitual(
              g,
              porGrupo[g]!.length,
              cor: _corDoElemento[g] ?? Cores.conhecimento,
            ),
          for (final i in porGrupo[g]!)
            _cartaoRitualFicha(i, lista[i], avisos[i] ?? const []),
        ],
      if (lista.isEmpty) const VazioLeitura('Nenhum ritual ainda.'),
      if (_ed('rituais'))
        Center(
          child: TextButton.icon(
            onPressed: () =>
                _editarSimples('rituais', 'ritual', null, _camposRitual),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar ritual à mão'),
          ),
        ),
    ];
  }

  Widget _cartaoRitualFicha(
    int i,
    Map<String, dynamic> r,
    List<String> avisos,
  ) {
    // Ritual antigo gravado sem elemento: o catálogo completa pelo nome.
    final elemento = _elementoDoRitual(r);
    final cor = _corDoElemento[elemento] ?? Cores.energiaViva;
    final circulo = circuloDoRitual(r);
    final custo = custoDoRitual(r);
    final (alvo, resistencia, efeito, formas) = _partesDoRitual(r);
    final aberto = _ritualAberto.contains(i);
    final dados = [
      ('Execução', '${r['execucao'] ?? ''}'),
      ('Alcance', '${r['alcance'] ?? ''}'),
      ('Alvo', alvo),
      ('Duração', '${r['duracao'] ?? ''}'),
      ('Resistência', resistencia),
    ].where((d) => d.$2.trim().isNotEmpty).toList();

    return Card(
      key: ValueKey('ritual-$i'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: avisos.isNotEmpty ? Cores.sangue : cor.withValues(alpha: .5),
          width: avisos.isNotEmpty ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r['nome'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (elemento.isNotEmpty) Etiqueta(elemento, cor: cor),
                          Etiqueta('$circuloº círculo', cor: Cores.tinta2),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$custo PE',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cor,
                      ),
                    ),
                    const Text(
                      'custo',
                      style: TextStyle(fontSize: 10, color: Cores.tinta2),
                    ),
                  ],
                ),
              ],
            ),
            if (dados.isNotEmpty) ...[
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, c) => Wrap(
                  runSpacing: 8,
                  children: [
                    for (final d in dados)
                      SizedBox(
                        width: c.maxWidth / 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InfoLeitura(d.$1, d.$2),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (efeito.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(efeito, style: const TextStyle(fontSize: 14, height: 1.35)),
            ],
            if (formas.isNotEmpty) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                key: ValueKey('formas-$i'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => setState(
                  () => aberto ? _ritualAberto.remove(i) : _ritualAberto.add(i),
                ),
                icon: Icon(
                  aberto ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: Text(
                  aberto
                      ? 'Esconder formas maiores'
                      : 'Formas maiores: ${formas.map((f) => '${f.$1} +${f.$2} PE').join(' · ')}',
                ),
              ),
              if (aberto)
                for (final f in formas)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: .08),
                      border: Border.all(color: cor.withValues(alpha: .4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${f.$1.toUpperCase()} · +${f.$2} PE '
                          '(total ${custo + (int.tryParse(f.$2) ?? 0)} PE)',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                            color: cor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(f.$3, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
            ],
            for (final a in avisos) _linhaAviso(a),
            if (!leitura || _ed('rituais')) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (!leitura)
                    FilledButton.icon(
                      key: ValueKey('conjurar-$i'),
                      onPressed: () => _conjurar(r),
                      icon: const Icon(Icons.auto_fix_high, size: 16),
                      label: const Text('Conjurar'),
                    ),
                  const Spacer(),
                  if (_ed('rituais'))
                    TextButton(
                      onPressed: () =>
                          _editarSimples('rituais', 'ritual', i, _camposRitual),
                      child: const Text('Editar'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Linha vermelha com o motivo de estar fora da regra.
  Widget _linhaAviso(String texto) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, size: 16, color: Cores.sangue),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 12.5, color: Cores.sangue),
          ),
        ),
      ],
    ),
  );

  Widget _seletorAfinidade() {
    return DropdownButtonFormField<String>(
      key: ValueKey('afinidade-${ficha.afinidade}'),
      isExpanded: true,
      initialValue: ficha.afinidade,
      decoration: const InputDecoration(
        labelText: 'Afinidade (NEX 50%, irrevogável)',
        isDense: true,
      ),
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
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          '${p.nome} na ficha.'
          '${p.efeitos.isNotEmpty ? ' Efeitos já aplicados.' : ''}'
          '${perdeu > 0 ? ' Transcender: −$perdeu SAN máxima.' : ''}',
        ),
      ),
    );
  }

  /// Conjura: escolhe a forma, confere o limite de PE, gasta os PE e cobra
  /// o custo do paranormal (OPRPG p. 121).
  Future<void> _conjurar(Map<String, dynamic> r) async {
    final nome = '${r['nome'] ?? 'Ritual'}';
    final medo = '${r['elemento'] ?? ''}'.toLowerCase() == 'medo';
    final formas = <(String, int)>[('Básica', 0)];
    for (final linha in '${r['descricao'] ?? ''}'.split('\n')) {
      final m = RegExp(
        r'^(Discente|Verdadeir[oa])\s*\(\+(\d+)\s*PE\)',
        caseSensitive: false,
      ).firstMatch(linha.trim());
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
                  Wrap(
                    spacing: 6,
                    children: [
                      for (var i = 0; i < formas.length; i++)
                        ChoiceChip(
                          label: Text(
                            i == 0
                                ? formas[i].$1
                                : '${formas[i].$1} +${formas[i].$2}',
                          ),
                          selected: forma == i,
                          onSelected: (_) => setLocal(() => forma = i),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  'Custo: $custo PE (tem ${ficha.pe}) · limite '
                  '${ficha.limitePeTurno}/turno',
                ),
                Text('DT para resistir: ${ficha.dtRituais}'),
                const SizedBox(height: 6),
                Text(
                  medo
                      ? 'Medo: perde $custo SAN e ${forma == 0
                                ? 1
                                : forma == 1
                                ? 2
                                : 3} '
                            'de SAN máxima.'
                      : 'Teste de Ocultismo DT ${20 + custo}: falhou, perde '
                            '$custo SAN; falhou por 5+, também 1 de SAN máxima.',
                  style: const TextStyle(fontSize: 12, color: Cores.tinta2),
                ),
                if (acima)
                  const Text(
                    'Passa do limite de PE: esta forma não dá.',
                    style: TextStyle(fontSize: 12, color: Cores.sangue),
                  ),
                if (semPe)
                  const Text(
                    'PE insuficiente.',
                    style: TextStyle(fontSize: 12, color: Cores.sangue),
                  ),
                if (ficha.efeitos.custoPeCondicao > 0)
                  const Text(
                    'Alquebrado: +1 PE já somado.',
                    style: TextStyle(fontSize: 12, color: Cores.conhecimento),
                  ),
                if (ficha.efeitos.custoRitual != 0)
                  const Text(
                    'Reduções de poderes somadas (o livro se contradiz se '
                    'acumulam: p. 78 × Ritual Predileto). Confira com o mestre.',
                    style: TextStyle(fontSize: 11, color: Cores.tinta2),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: acima || semPe
                    ? null
                    : () => Navigator.pop(ctx, true),
                child: const Text('Conjurar'),
              ),
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
      final permanente = forma == 0
          ? 1
          : forma == 1
          ? 2
          : 3;
      ficha.sanPerdida += permanente;
      resultado = 'Medo: −$custo SAN e −$permanente SAN máxima.';
    } else {
      final ocultismo = DadosOP.pericias
          .where((p) => p.nome == 'Ocultismo')
          .toList();
      if (ocultismo.isEmpty) {
        resultado = 'Faça Ocultismo DT ${20 + custo}.';
      } else {
        final (dados, melhor, bonus) = ficha.testePericia(ocultismo.first);
        final teste = Rolagem.teste(
          titulo: 'Custo de $nome',
          dados: dados,
          melhor: melhor,
          bonus: bonus,
        );
        final dt = 20 + custo;
        if (teste.total >= dt) {
          resultado =
              'Ocultismo ${teste.total} contra DT $dt: sem custo de SAN.';
        } else {
          ficha.san -= custo;
          if (dt - teste.total >= 5) {
            ficha.sanPerdida += 1;
            resultado =
                'Ocultismo ${teste.total} contra DT $dt: −$custo SAN '
                'e −1 SAN máxima.';
          } else {
            resultado = 'Ocultismo ${teste.total} contra DT $dt: −$custo SAN.';
          }
        }
        PonteRolagens.publicar(
          teste,
          ficha.nome.isEmpty ? 'Sem nome' : ficha.nome,
        );
      }
    }
    _salvar();
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text('$nome: −$custo PE. $resultado'),
      ),
    );
  }

  Widget _abaInventario() {
    final itens = ficha.inventario;
    final patente = DadosOP.patentePorNome(ficha.patente);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      children: [
        _faixa('inventario', 'Inventário'),
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
                        child: Text(
                          'SOBRECARREGADO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Cores.sangue,
                          ),
                        ),
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
        if (itens.isEmpty) const VazioLeitura('Nenhum item ainda.'),
        if (_ed('inventario'))
          Center(
            child: TextButton.icon(
              onPressed: () => _editarItem(null),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar item'),
            ),
          ),
        _faixa('anotacoes', 'Anotações'),
        if (_ed('anotacoes'))
          TextFormField(
            initialValue: ficha.anotacoes,
            maxLines: 10,
            minLines: 4,
            decoration: const InputDecoration(
              hintText: 'História, contatos, pistas, dívidas…',
            ),
            onChanged: (v) {
              ficha.anotacoes = v;
              FichaStore.salvar(ficha);
            },
          )
        else if (ficha.anotacoes.trim().isEmpty)
          const VazioLeitura('Nada anotado ainda.')
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                ficha.anotacoes,
                style: const TextStyle(fontSize: 14, height: 1.35),
              ),
            ),
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
          Text(
            'Patente ${patente.nome} · crédito ${patente.credito}',
            style: const TextStyle(fontSize: 12, color: Cores.tinta2),
          ),
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
        trailing: !_ed('inventario')
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Cores.tinta2,
                ),
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
                decoration: const InputDecoration(labelText: 'Item'),
              ),
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
                decoration: const InputDecoration(labelText: 'Espaços'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: amaldicoado,
                title: const Text(
                  'Amaldiçoado',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  'Só a partir de Agente Especial',
                  style: TextStyle(fontSize: 12),
                ),
                onChanged: (v) => setLocal(() => amaldicoado = v ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: foraDoLimite,
                title: const Text(
                  'Não conta no limite da patente',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  'Ex.: poder do Criminoso',
                  style: TextStyle(fontSize: 12),
                ),
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
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Cores.sangue),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
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
    'trilha': 'Habilidade de trilha',
    'habilidade': 'Habilidade de classe',
    'origem': 'Poder de origem',
  };

  List<Widget> _listaSimples(
    String chave,
    String rotulo, {
    required List<(String, String)> camposExtras,
    bool habilidade = false,
    bool editando = false,
    Widget Function(int, Map<String, dynamic>)? acoes,
  }) {
    final itens = ficha._listaPublica(chave);
    if (habilidade) {
      final avisos = avisosDasHabilidades(ficha);
      return [
        for (var i = 0; i < itens.length; i++)
          _cartaoHabilidade(
            i,
            itens[i],
            editando,
            camposExtras,
            avisos[i] ?? const [],
          ),
        if (itens.isEmpty) VazioLeitura('Nenhuma $rotulo ainda.'),
        if (editando)
          Center(
            child: TextButton.icon(
              onPressed: () => _editarSimples(
                chave,
                rotulo,
                null,
                camposExtras,
                habilidade: true,
              ),
              icon: const Icon(Icons.add),
              label: Text('Adicionar $rotulo'),
            ),
          ),
      ];
    }
    return [
      for (var i = 0; i < itens.length; i++)
        Card(
          child: ExpansionTile(
            shape: const Border(),
            title: Text(
              '${itens[i]['nome'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
                    if (acoes != null || editando)
                      Row(
                        children: [
                          if (acoes != null) acoes(i, itens[i]),
                          const Spacer(),
                          if (editando)
                            TextButton(
                              onPressed: () => _editarSimples(
                                chave,
                                rotulo,
                                i,
                                camposExtras,
                                habilidade: habilidade,
                              ),
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
          child: Text(
            'Nenhum $rotulo ainda.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Cores.tinta2, fontSize: 13),
          ),
        ),
      if (editando)
        Center(
          child: TextButton.icon(
            onPressed: () => _editarSimples(
              chave,
              rotulo,
              null,
              camposExtras,
              habilidade: habilidade,
            ),
            icon: const Icon(Icons.add),
            label: Text('Adicionar $rotulo'),
          ),
        ),
    ];
  }

  /// Habilidade aberta: o que ela faz já aparece, sem precisar expandir.
  Widget _cartaoHabilidade(
    int i,
    Map<String, dynamic> h,
    bool editando,
    List<(String, String)> camposExtras, [
    List<String> avisos = const [],
  ]) {
    final descricao = '${h['descricao'] ?? ''}'.trim();
    final sub = _subtituloHabilidade(h);
    return Card(
      key: ValueKey('habilidade-$i'),
      shape: avisos.isEmpty
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Cores.sangue, width: 1.5),
            ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${h['nome'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (sub != null)
                    Padding(padding: const EdgeInsets.only(top: 2), child: sub),
                  if (descricao.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        descricao,
                        style: const TextStyle(fontSize: 13.5, height: 1.35),
                      ),
                    ),
                  for (final a in avisos) _linhaAviso(a),
                ],
              ),
            ),
            if (editando)
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Cores.tinta2,
                ),
                onPressed: () => _editarSimples(
                  'habilidades',
                  'habilidade',
                  i,
                  camposExtras,
                  habilidade: true,
                ),
              ),
          ],
        ),
      ),
    );
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
    return Text(
      partes.join(' · '),
      style: const TextStyle(fontSize: 12, color: Cores.tinta2),
    );
  }

  Widget? _subtituloExtras(
    Map<String, dynamic> item,
    List<(String, String)> campos,
  ) {
    final partes = <String>[];
    for (final (chave, _) in campos) {
      final v = '${item[chave] ?? ''}';
      if (v.isNotEmpty) partes.add(v);
    }
    if (partes.isEmpty) return null;
    return Text(partes.join(' · '), style: const TextStyle(fontSize: 12));
  }

  Future<void> _editarSimples(
    String chave,
    String rotulo,
    int? indice,
    List<(String, String)> camposExtras, {
    bool habilidade = false,
  }) async {
    final itens = ficha._listaPublica(chave);
    final atual = indice == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(itens[indice]);
    final nome = TextEditingController(text: '${atual['nome'] ?? ''}');
    final descricao = TextEditingController(
      text: '${atual['descricao'] ?? ''}',
    );
    final extras = {
      for (final (c, _) in camposExtras)
        c: TextEditingController(text: '${atual[c] ?? ''}'),
    };
    var tipoPoder = '${atual['tipoPoder'] ?? ''}';
    if (!_tiposDePoder.containsKey(tipoPoder)) tipoPoder = '';
    var transcender = atual['transcender'] == true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(indice == null ? 'Novo $rotulo' : 'Editar $rotulo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nome,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                for (final (c, r) in camposExtras) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: extras[c],
                    decoration: InputDecoration(labelText: r),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: descricao,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                if (habilidade) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: tipoPoder,
                    decoration: const InputDecoration(
                      labelText: 'Tipo (para a contagem de poderes)',
                    ),
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
                    title: const Text(
                      'Conta como Transcender',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Não ganha a SAN do NEX em que entrou',
                      style: TextStyle(fontSize: 12),
                    ),
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
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Cores.sangue),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
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
        ),
      ),
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
              _linhaAmeaca(
                'Presença perturbadora',
                ficha.presenca,
                Cores.energiaViva,
              ),
            if (ficha.sentidos.isNotEmpty)
              _linhaAmeaca('Sentidos', ficha.sentidos, Cores.tinta2),
            if (ficha.resistencias.isNotEmpty)
              _linhaAmeaca('Resistências', ficha.resistencias, Cores.estavel),
            if (ficha.vulnerabilidades.isNotEmpty)
              _linhaAmeaca(
                'Vulnerabilidades',
                ficha.vulnerabilidades,
                Cores.sangue,
              ),
            if (!leitura) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _campoTexto(
                      'Categoria (Criatura, Pessoa…)',
                      ficha.categoria,
                      (v) => ficha.categoria = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _campoTexto(
                      'Tamanho',
                      ficha.tamanho,
                      (v) => ficha.tamanho = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _campoTexto(
                      'Elemento',
                      ficha.elemento,
                      (v) => ficha.elemento = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _campoNumero(
                      'VD',
                      ficha.vd ?? 0,
                      (v) => ficha.vd = v <= 0 ? null : v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _campoTexto(
                'Presença perturbadora',
                ficha.presenca,
                (v) => ficha.presenca = v,
              ),
              const SizedBox(height: 8),
              _campoTexto(
                'Sentidos',
                ficha.sentidos,
                (v) => ficha.sentidos = v,
              ),
              const SizedBox(height: 8),
              _campoTexto(
                'Vulnerabilidades',
                ficha.vulnerabilidades,
                (v) => ficha.vulnerabilidades = v,
              ),
              const SizedBox(height: 8),
              _campoNumero(
                'Defesa impressa (0 = calcular)',
                ficha.defesaManual ?? 0,
                (v) => ficha.defesaManual = v <= 0 ? null : v,
              ),
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
              style: TextStyle(fontWeight: FontWeight.bold, color: cor),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }

  Widget _abaSobre() {
    final escritos = [
      for (final campo in FichaOP.camposSobre.entries)
        if (ficha.sobre(campo.key).trim().isNotEmpty) campo,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      children: [
        _faixa('proficiencias', 'Proficiências'),
        _proficiencias(),
        _faixa('opcionais', 'Regras opcionais'),
        if (_ed('opcionais')) _regrasOpcionais() else _opcionaisLeitura(),
        _faixa('sobre', 'Sobre o personagem'),
        if (_ed('sobre'))
          for (final campo in FichaOP.camposSobre.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                initialValue: ficha.sobre(campo.key),
                maxLines: campo.key == 'anotacoes' ? 8 : 4,
                minLines: 1,
                decoration: InputDecoration(labelText: campo.value),
                onChanged: (v) {
                  ficha.definirSobre(campo.key, v);
                  FichaStore.salvar(ficha);
                },
              ),
            )
        else if (escritos.isEmpty)
          const VazioLeitura(
            'Nada escrito ainda. Toque no lápis para contar a história.',
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final campo in escritos)
                    ParagrafoLeitura(campo.value, ficha.sobre(campo.key)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Resumo das regras opcionais ligadas — o formulário fica no lápis.
  Widget _opcionaisLeitura() {
    final faixa = RegrasOpcionais.faixa(ficha.faixaEtaria);
    final linhas = <Widget>[
      if (faixa != null)
        InfoLeitura(
          'Idade variada',
          faixa.nome,
          detalhe: [
            faixa.efeito,
            if (ficha.desvantagens.isNotEmpty)
              'Desvantagens: ${ficha.desvantagens.join(', ')}',
          ].join('\n'),
        ),
    ];
    if (linhas.isEmpty) {
      return const VazioLeitura('Nenhuma regra opcional ligada.');
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < linhas.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              linhas[i],
            ],
          ],
        ),
      ),
    );
  }

  /// Idade variada (OPRPG p. 172): ligada por ficha, com efeito já nas
  /// contas.
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
                labelText: 'Idade variada (faixa etária)',
                isDense: true,
              ),
              dropdownColor: Cores.carta2,
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('— (regra desligada)'),
                ),
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
              Text(
                faixa.efeito,
                style: const TextStyle(fontSize: 12, color: Cores.tinta2),
              ),
              if (faixa.nexExtra > 0)
                Text(
                  'Na criação: NEX +${faixa.nexExtra}% (suba a régua).',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Cores.conhecimento,
                  ),
                ),
            ],
            if (faixa != null && faixa.desvantagens > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Desvantagens de idade (${ficha.desvantagens.length} de '
                '${faixa.desvantagens}):',
                style: const TextStyle(fontSize: 12),
              ),
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
          ],
        ),
      ),
    );
  }

  /// As cinco do livro, marcadas ou não. No lápis, cada uma liga e desliga;
  /// a que vem de poder ou origem fica travada. É daqui que sai o −2d20 de
  /// arma ou proteção sem proficiência.
  Widget _proficiencias() {
    final editando = _ed('proficiencias');
    final extras = [
      for (final p in ficha.proficiencias)
        if (!FichaOP.proficienciasDoLivro.any(
          (l) =>
              FichaOP.chaveDeProficiencia(l) == FichaOP.chaveDeProficiencia(p),
        ))
          p,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (editando)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Toque para marcar ou desmarcar. Sem proficiência: −2d20 no '
                  'ataque com a arma, ou em For e Agi com a proteção.',
                  style: TextStyle(fontSize: 12, color: Cores.tinta2),
                ),
              ),
            if (editando)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final p in FichaOP.proficienciasDoLivro)
                    FilterChip(
                      key: ValueKey('prof-$p'),
                      label: Text(
                        ficha.proficienciaDePoder(p) &&
                                !ficha.proficienciaMarcada(p)
                            ? '$p (poder/origem)'
                            : p,
                      ),
                      selected: ficha.proficiente(p),
                      onSelected:
                          ficha.proficienciaDePoder(p) &&
                              !ficha.proficienciaMarcada(p)
                          ? null
                          : (v) {
                              ficha.marcarProficiencia(p, v);
                              _salvar();
                            },
                    ),
                ],
              )
            else
              for (final p in FichaOP.proficienciasDoLivro)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        ficha.proficiente(p)
                            ? Icons.check_circle
                            : Icons.cancel_outlined,
                        size: 18,
                        color: ficha.proficiente(p)
                            ? Cores.estavel
                            : Cores.tinta2,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        p,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: ficha.proficiente(p)
                              ? Cores.tinta
                              : Cores.tinta2,
                        ),
                      ),
                      if (ficha.proficienciaDePoder(p) &&
                          !ficha.proficienciaMarcada(p))
                        const Text(
                          '  · de poder/origem',
                          style: TextStyle(fontSize: 12, color: Cores.tinta2),
                        ),
                    ],
                  ),
                ),
            if (extras.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Fora do livro (anotada à mão; não conta para armas):',
                style: TextStyle(fontSize: 12, color: Cores.tinta2),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in extras)
                    Chip(
                      label: Text(p),
                      backgroundColor: Cores.carta2,
                      side: const BorderSide(color: Cores.linha),
                      onDeleted: editando
                          ? () {
                              ficha.proficiencias = [
                                for (final x in ficha.proficiencias)
                                  if (x != p) x,
                              ];
                              _salvar();
                            }
                          : null,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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

  /// Trilha da classe, só do Livro de Regras (p. 26–35) — escolher já põe
  /// as habilidades que o NEX dá. Nunca é texto livre: uma trilha antiga fora
  /// da lista continua aparecendo até ser trocada.
  Widget _seletorTrilha() {
    return SeletorTrilha(
      key: ValueKey('trilha-${ficha.classe}-${ficha.trilha}'),
      classe: ficha.classe,
      valor: ficha.trilha,
      nex: ficha.nex,
      onChanged: leitura
          ? null
          : (v) {
              ficha.trilha = v;
              final (entrou, saiu) = ficha.sincronizarTrilha();
              _salvar();
              _avisarTrilha(entrou, saiu);
            },
    );
  }

  void _avisarTrilha(List<String> entrou, List<String> saiu) {
    if (entrou.isEmpty && saiu.isEmpty) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          [
            if (entrou.isNotEmpty) 'Entrou: ${entrou.join(', ')}.',
            if (saiu.isNotEmpty) 'Saiu: ${saiu.join(', ')}.',
          ].join(' '),
        ),
      ),
    );
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
  /// agente a partir de 5%), o que a classe antiga deixou para trás e o
  /// que a nova dá.
  Future<void> _trocarClasse(String nome) async {
    final antiga = ficha.classeOP;
    final nova = DadosOP.classePorNome(nome);
    if (nova == null) return;

    ficha.classe = nome;
    if (!nova.agente) {
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
    ficha.trilha =
        DadosOP.trilhasParaEscolher(nome).any((t) => t.nome == ficha.trilha)
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
                style: TextStyle(fontSize: 12, color: Cores.tinta2),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Manter'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tirar'),
          ),
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
            const Text(
              'Preencho na ficha:',
              style: TextStyle(color: Cores.tinta2, fontSize: 13),
            ),
            const SizedBox(height: 6),
            for (final g in ganhos)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $g'),
              ),
            const SizedBox(height: 8),
            const Text(
              'Nada é apagado: o que você já treinou continua.',
              style: TextStyle(color: Cores.tinta2, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Só trocar o nome'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Preencher'),
          ),
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
          DropdownMenuItem(value: o.nome, child: Text(o.nome)),
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
        child: Text(
          'Sem patente (civil)',
          style: TextStyle(fontSize: 12, color: Cores.tinta2),
        ),
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
