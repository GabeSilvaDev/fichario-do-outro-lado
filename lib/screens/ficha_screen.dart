import 'package:flutter/material.dart';

import '../data/dados_op.dart';
import '../mesa/ponte_rolagens.dart';
import '../models/ficha_op.dart';
import '../models/rolagem.dart';
import '../store/ficha_store.dart';
import '../theme.dart';
import 'catalogo_screen.dart';
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

  @override
  void initState() {
    super.initState();
    ficha = widget.fichaDireta ??
        FichaStore.porId(widget.fichaId!) ??
        FichaOP.nova(widget.fichaId!);
  }

  bool get leitura => widget.somenteLeitura;

  @override
  void dispose() {
    _campoDadoRapido.dispose();
    super.dispose();
  }

  void _salvar() {
    if (leitura) return;
    FichaStore.salvar(ficha);
    setState(() {});
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
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(ficha.nome.isEmpty ? 'Ficha' : ficha.nome),
          actions: leitura ? null : [_menuTipo(), _menuRegras()],
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
          Expanded(
              child: _campoTexto(
                  'Trilha', ficha.trilha, (v) => ficha.trilha = v)),
          const SizedBox(width: 8),
          Expanded(child: _seletorPatente()),
        ]),
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
          aoMudar: leitura
              ? null
              : (v) {
                  ficha.pv = v;
                  _salvar();
                },
          aoEditarMaximo: leitura ? null : () => _editarMaximo('pv'),
        ),
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
        if (ficha.ehNpc) ...[
          const FaixaSecao('Bloco de ameaça'),
          _blocoAmeaca(),
        ],
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
                    _medalha('DESLOC.', '${ficha.deslocamentoEfetivo}m'),
                    const SizedBox(width: 12),
                    _medalha('PE/TURNO', '${ficha.limitePeTurno}'),
                  ],
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
                  title: const Text('Escudo (+2 Defesa)',
                      style: TextStyle(fontSize: 14)),
                  onChanged: leitura
                      ? null
                      : (v) {
                          ficha.escudo = v ?? false;
                          _salvar();
                        },
                ),
                if (_semProficienciaNaProtecao() != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Sem proficiência em ${_semProficienciaNaProtecao()} — '
                      'confira a penalidade com o mestre.',
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

  Widget _linhaNex() {
    if (ficha.porEstagio) return _linhaEstagio();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
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
                onChanged: leitura
                    ? null
                    : (v) {
                        final passo = v.round();
                        ficha.nex = passo >= 100 ? 99 : passo;
                        _salvar();
                      },
              ),
            ),
            Text('${ficha.nex}%',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Cores.tinta)),
          ],
        ),
      ),
    );
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
                              ficha.estagio = e;
                              _salvar();
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 40, child: _seletorAtributoPericia(p)),
            Expanded(
              child: Text(
                p.nome + (p.soTreinada ? ' *' : ''),
                style: TextStyle(
                  fontWeight: grau > 0 ? FontWeight.bold : FontWeight.normal,
                  color: grau > 0 ? Cores.tinta : Cores.tinta2,
                ),
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
    final nome = (a['nome'] ?? '') as String;
    final pericia = (a['pericia'] ?? 'Luta') as String;
    final bonus = (a['bonus'] ?? 0) as int;
    final dano = (a['dano'] ?? '') as String;
    final critico = (a['critico'] ?? '') as String;
    final margem = (a['margem'] ?? '') as String;
    final tipo = (a['tipo'] ?? '') as String;
    final alcance = (a['alcance'] ?? '') as String;
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
                if (((a['dadosTeste'] ?? 0) as int) > 0)
                  '${a['dadosTeste']}d20+${a['bonusTeste'] ?? 0}'
                else
                  '$pericia${bonus != 0 ? (bonus > 0 ? ' +$bonus' : ' $bonus') : ''}',
                if (dano.isNotEmpty)
                  'dano $dano${tipo.isNotEmpty ? ' ($tipo)' : ''}',
                if (margem.isNotEmpty || critico.isNotEmpty)
                  'crítico ${[margem, critico].where((x) => x.isNotEmpty).join('/')}',
                if (alcance.isNotEmpty) alcance,
              ].join(' · '),
              style: const TextStyle(fontSize: 12, color: Cores.tinta2),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    final dadosFixos = (a['dadosTeste'] ?? 0) as int;
                    if (dadosFixos > 0) {
                      _mostrarResultado(Rolagem.teste(
                        titulo: 'Ataque: ${nome.isEmpty ? pericia : nome}',
                        dados: dadosFixos,
                        melhor: true,
                        bonus: (a['bonusTeste'] ?? 0) as int,
                      ));
                      return;
                    }
                    final p = DadosOP.pericias
                        .where((x) => x.nome == pericia)
                        .toList();
                    if (p.isEmpty) return;
                    final (dados, melhor, grau) = ficha.testePericia(p.first);
                    final r = Rolagem.teste(
                        titulo: 'Ataque: ${nome.isEmpty ? pericia : nome}',
                        dados: dados,
                        melhor: melhor,
                        bonus: grau + bonus);
                    _mostrarResultado(r);
                  },
                  icon: const Icon(Icons.casino_outlined, size: 16),
                  label: const Text('Teste'),
                ),
                const SizedBox(width: 8),
                if (dano.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _rolarExpressao(
                        'Dano: ${nome.isEmpty ? pericia : nome}', dano),
                    icon: const Icon(Icons.bolt_outlined, size: 16),
                    label: const Text('Dano'),
                  ),
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
    setState(() => ficha.adicionarEm('ataques', escolhido));
    _salvar();
  }

  /// O mesmo para rituais: entra com custo, execução, alcance, duração,
  /// resistência, efeito e as ampliações.
  Future<void> _ritualDoCatalogo() async {
    final escolhido = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => const CatalogoScreen(escolhendo: true),
      ),
    );
    if (escolhido == null || !mounted) return;
    setState(() => ficha.adicionarEm('rituais', escolhido));
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
                  'nome': nome.text.trim(),
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
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const FaixaSecao('Habilidades e poderes'),
        ..._listaSimples('habilidades', 'habilidade',
            camposExtras: const []),
        const FaixaSecao('Rituais'),
        ..._listaSimples('rituais', 'ritual', camposExtras: const [
          ('circulo', 'Círculo (1º a 4º)'),
          ('custo', 'Custo (PE)'),
          ('execucao', 'Execução'),
          ('alcance', 'Alcance'),
          ('duracao', 'Duração'),
        ]),
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
                      'Carga: ${ficha.cargaUsada}/${ficha.cargaLimite}',
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
                if (patente != null)
                  Text(
                    'Patente ${patente.nome} · crédito ${patente.credito} · '
                    'itens I:${patente.limites['I']} II:${patente.limites['II']} '
                    'III:${patente.limites['III']} IV:${patente.limites['IV']}',
                    style:
                        const TextStyle(fontSize: 12, color: Cores.tinta2),
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

  Widget _linhaItem(int indice, Map<String, dynamic> item) {
    final nome = (item['nome'] ?? '') as String;
    final categoria = (item['categoria'] ?? '') as String;
    final espacos = (item['espacos'] ?? 0) as int;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        title: Text(nome.isEmpty ? 'Sem nome' : nome),
        subtitle: Text(
          [
            if (categoria.isNotEmpty) 'categoria $categoria',
            '$espacos espaço${espacos == 1 ? '' : 's'}',
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
    final nome = TextEditingController(text: (atual['nome'] ?? '') as String);
    final espacos = TextEditingController(text: '${atual['espacos'] ?? 1}');
    var categoria = (atual['categoria'] ?? 'I') as String;
    if (!['0', 'I', 'II', 'III', 'IV'].contains(categoria)) categoria = 'I';

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
                final novo = {
                  'nome': nome.text.trim(),
                  'categoria': categoria,
                  'espacos': int.tryParse(espacos.text.trim()) ?? 1,
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

  List<Widget> _listaSimples(String chave, String rotulo,
      {required List<(String, String)> camposExtras}) {
    final itens = ficha._listaPublica(chave);
    return [
      for (var i = 0; i < itens.length; i++)
        Card(
          child: ExpansionTile(
            shape: const Border(),
            title: Text((itens[i]['nome'] ?? '') as String,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: _subtituloExtras(itens[i], camposExtras),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((itens[i]['descricao'] ?? '') as String),
                    if (!leitura)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              _editarSimples(chave, rotulo, i, camposExtras),
                          child: const Text('Editar'),
                        ),
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
            onPressed: () => _editarSimples(chave, rotulo, null, camposExtras),
            icon: const Icon(Icons.add),
            label: Text('Adicionar $rotulo'),
          ),
        ),
    ];
  }

  Widget? _subtituloExtras(
      Map<String, dynamic> item, List<(String, String)> campos) {
    final partes = <String>[];
    for (final (chave, _) in campos) {
      final v = (item[chave] ?? '') as String;
      if (v.isNotEmpty) partes.add(v);
    }
    if (partes.isEmpty) return null;
    return Text(partes.join(' · '), style: const TextStyle(fontSize: 12));
  }

  Future<void> _editarSimples(String chave, String rotulo, int? indice,
      List<(String, String)> camposExtras) async {
    final itens = ficha._listaPublica(chave);
    final atual = indice == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(itens[indice]);
    final nome = TextEditingController(text: (atual['nome'] ?? '') as String);
    final descricao =
        TextEditingController(text: (atual['descricao'] ?? '') as String);
    final extras = {
      for (final (c, _) in camposExtras)
        c: TextEditingController(text: (atual[c] ?? '') as String)
    };

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
              final novo = {
                'nome': nome.text.trim(),
                'descricao': descricao.text.trim(),
                for (final e in extras.entries) e.key: e.value.text.trim(),
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
        const FaixaSecao('Sobre o personagem'),
        for (final campo in FichaOP.camposSobre.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
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

  /// Nome da proficiência que falta para a proteção vestida, ou null.
  String? _semProficienciaNaProtecao() {
    final tipo = ficha.protecaoTipo;
    if (tipo != 'Leve' && tipo != 'Pesada') return null;
    final exigida = tipo == 'Leve' ? 'Proteções leves' : 'Proteções pesadas';
    return ficha.proficiencias.contains(exigida) ? null : exigida;
  }

  Widget _seletorClasse() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
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
          : (v) async {
              if (v == null) return;
              ficha.classe = v;
              final classe = DadosOP.classePorNome(v);
              if (classe != null && await _confirmarAplicar(v, [
                if (classe.proficiencias.isNotEmpty)
                  'proficiências: ${classe.proficiencias.join(', ')}',
                if (classe.periciasFixas.isNotEmpty)
                  'perícias: ${classe.periciasFixas.join(', ')}',
                for (final h in classe.habilidades) 'habilidade: ${h.nome}',
              ])) {
                ficha.aplicarClasse(classe);
              }
              _salvar();
            },
    );
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
              if (v == null) return;
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
    return DropdownButtonFormField<String>(
      isExpanded: true,
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
