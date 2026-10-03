import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/ficha_op.dart';
import '../../store/ficha_store.dart';
import '../../theme.dart';
import '../../widgets/retrato.dart';
import '../mesa_firestore.dart';
import '../mesa_service.dart';
import '../mesa_store.dart';
import '../sessao_mesa.dart';
import '../modelos.dart';
import 'entrar_mesa_dialogo.dart';
import 'cartao_mapa.dart';
import 'galeria_mesa.dart';
import 'mural_da_mesa.dart';
import 'painel_mestre.dart';

/// A aba Mesa: criar, entrar, ver quem está online e sair.
///
/// [servico] existe para o teste injetar o fake; em produção fica null e a
/// tela usa `MesaFirestore`.
class MesaAba extends StatefulWidget {
  final MesaService? servico;
  const MesaAba({super.key, this.servico});

  @override
  State<MesaAba> createState() => _MesaAbaState();
}

class _MesaAbaState extends State<MesaAba> {
  late final MesaService _servico;
  bool _ocupado = false;

  /// A sessão online está de pé (login feito) e dá para observar a mesa.
  bool _sessaoPronta = false;
  String? _erroSessao;

  /// Já disparou a checagem de "a mesa sumiu" para a entrada atual. Sem isto
  /// o `StreamBuilder` reconstruiria e agendaria a checagem de novo a cada
  /// frame enquanto `snap.data` continuar nulo — um `entrarPorId` por
  /// rebuild em vez de um só por saída. Zera sempre que uma mesa nova é
  /// aberta (`_criar`, `_entrar`, `_voltarPara`, `_reassumir`, `_religar`).
  bool _cuidandoDaSaida = false;

  @override
  void initState() {
    super.initState();
    _servico = widget.servico ?? MesaFirestore();
    if (MesaStore.atual != null) _religar();
  }

  /// O app reabriu já dentro de uma mesa. O estado veio do disco, mas a
  /// sessão online não existe ainda: sem refazer o login, observar a mesa
  /// estoura porque o Firebase sequer foi inicializado.
  Future<void> _religar() async {
    try {
      await _servico.entrarAnonimo();
      final estado = MesaStore.atual;
      if (!mounted || estado == null) return;
      _ligarPonto();
      final fichaId = estado.fichaPublicadaId;
      if (fichaId != null) _ligarEspelho(estado.mesaId, fichaId);
      _cuidandoDaSaida = false;
      setState(() => _sessaoPronta = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erroSessao = '$e');
    }
  }

  // Espelho da ficha e presença não são desta aba: vivem na [SessaoMesa],
  // que segue o [MesaStore] em qualquer tela. Aqui só se pede para ela
  // conferir o estado depois de cada mudança.
  void _ligarEspelho(String mesaId, String fichaId) => SessaoMesa.reconciliar();

  void _desligarEspelho() => SessaoMesa.pararEspelho();

  void _ligarPonto() => SessaoMesa.reconciliar();

  void _desligarPonto() => SessaoMesa.parar();

  void _erro(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$e')));
  }

  Future<void> _comEspera(Future<void> Function() acao) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await acao();
    } catch (e) {
      _erro(e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _criar() async {
    final dados = await pedirDadosDaMesa(context);
    if (dados == null) return;
    final (nomeMesa, meuNome) = dados;
    String? chaveCriada;
    await _comEspera(() async {
      final uid = await _servico.entrarAnonimo();
      final (mesa, chave) = await _servico.criarMesa(nomeMesa, meuNome);
      chaveCriada = chave;
      await MesaStore.entrar(EstadoMesa(
        mesaId: mesa.id,
        nome: mesa.nome,
        uid: uid,
        papel: PapelMesa.mestre,
        chave: chave,
      ));
      await MesaStore.lembrar(MesaConhecida(
        mesaId: mesa.id,
        nome: mesa.nome,
        papel: PapelMesa.mestre,
        chave: chave,
        meuNome: meuNome,
      ));
      _ligarPonto();
      _cuidandoDaSaida = false;
      _sessaoPronta = true;
    });
    if (chaveCriada != null && mounted) await _mostrarChave(chaveCriada!);
  }

  Future<void> _entrar() async {
    final dados = await pedirCodigo(context);
    if (dados == null) return;
    final (codigo, meuNome) = dados;
    await _comEspera(() async {
      final uid = await _servico.entrarAnonimo();
      final mesa = await _servico.entrarPorCodigo(codigo, meuNome);
      final papel =
          mesa.mestreUid == uid ? PapelMesa.mestre : PapelMesa.jogador;
      final chave =
          papel == PapelMesa.mestre ? MesaStore.chaveDe(mesa.id) : null;
      await MesaStore.entrar(EstadoMesa(
        mesaId: mesa.id,
        nome: mesa.nome,
        uid: uid,
        papel: papel,
        chave: chave,
      ));
      await MesaStore.lembrar(MesaConhecida(
        mesaId: mesa.id,
        nome: mesa.nome,
        papel: papel,
        chave: chave,
        meuNome: meuNome,
      ));
      _ligarPonto();
      _cuidandoDaSaida = false;
      _sessaoPronta = true;
    });
  }

  /// Voltar sem código: o registro de membro vem antes de ler a mesa, porque
  /// depois de encerrada a sessão ninguém é membro — e a regra só libera a
  /// leitura para quem já é.
  Future<void> _voltarPara(MesaConhecida m) async {
    await _comEspera(() async {
      final uid = await _servico.entrarAnonimo();
      final meuNome = m.meuNome ??
          (m.papel == PapelMesa.mestre ? 'Mestre' : 'Jogador');
      Mesa mesa;
      try {
        mesa = await _servico.entrarPorId(m.mesaId, meuNome);
      } on MesaNaoEncontrada {
        await MesaStore.esquecer(m.mesaId);
        rethrow;
      }
      final papel = mesa.mestreUid == uid ? PapelMesa.mestre : PapelMesa.jogador;
      await MesaStore.entrar(EstadoMesa(
        mesaId: mesa.id,
        nome: mesa.nome,
        uid: uid,
        papel: papel,
        chave: m.chave,
      ));
      await MesaStore.lembrar(MesaConhecida(
        mesaId: mesa.id,
        nome: mesa.nome,
        papel: papel,
        chave: m.chave,
        meuNome: meuNome,
      ));
      _ligarPonto();
      _cuidandoDaSaida = false;
      _sessaoPronta = true;
    });
  }

  Future<void> _esquecer(MesaConhecida m) async {
    final perdeAMestria = m.papel == PapelMesa.mestre && m.chave != null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Cores.carta2,
        title: const Text('Esquecer esta mesa?'),
        content: Text(perdeAMestria
            ? 'O aparelho para de lembrar "${m.nome}" — e a chave de '
                'recuperação, que só existe aqui, some junto. Sem ela '
                'anotada em outro lugar, você perde a mestria desta mesa '
                'para sempre: mesmo com o código, quem entrar de novo entra '
                'como jogador.'
            : 'O aparelho para de lembrar "${m.nome}". Para voltar, '
                'alguém precisa te passar o código de novo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Esquecer')),
        ],
      ),
    );
    if (ok != true) return;
    await MesaStore.esquecer(m.mesaId);
    if (mounted) setState(() {});
  }

  /// A chave prova que fui mestre desta mesa: com ela dá para reassumi-la
  /// noutro aparelho, mesmo sem ser mais membro.
  Future<void> _reassumir() async {
    final dados = await pedirChaveDeMesa(context);
    if (dados == null) return;
    final (codigo, chave) = dados;
    const meuNome = 'Mestre';
    await _comEspera(() async {
      final uid = await _servico.entrarAnonimo();
      final mesa = await _servico.reassumirMesa(codigo, chave, meuNome);
      await MesaStore.entrar(EstadoMesa(
        mesaId: mesa.id,
        nome: mesa.nome,
        uid: uid,
        papel: PapelMesa.mestre,
        chave: chave,
      ));
      await MesaStore.lembrar(MesaConhecida(
        mesaId: mesa.id,
        nome: mesa.nome,
        papel: PapelMesa.mestre,
        chave: chave,
        meuNome: meuNome,
      ));
      _ligarPonto();
      _cuidandoDaSaida = false;
      _sessaoPronta = true;
    });
  }

  /// Intransponível: a chave só é mostrada esta vez, e ela não pode ficar
  /// presa atrás de um toque sem querer no fundo da tela.
  Future<void> _mostrarChave(String chave) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Cores.carta2,
        title: const Text('Guarde a chave da mesa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Guarde esta chave. É com ela que você recupera a mesa se '
              'trocar de celular ou limpar os dados do app. Quem tem a '
              'chave manda na mesa.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    chave,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 16),
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar chave',
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: chave));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chave copiada.')));
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Já guardei'),
          ),
        ],
      ),
    );
  }

  Future<void> _sair(String mesaId) async {
    await _comEspera(() async {
      await _servico.sair(mesaId);
      _desligarPonto();
      _desligarEspelho();
      await MesaStore.limpar();
    });
  }

  /// Sem pedir nada: a mesa acabou por fora (fechada ou fui removido).
  Future<void> _voltarParaOffline(String motivo) async {
    _desligarPonto();
    _desligarEspelho();
    await MesaStore.limpar();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(motivo)));
  }

  /// Só esvazia: a mesa, o código e a galeria continuam de pé para o mestre
  /// reencontrar a mesma crônica no sábado seguinte.
  Future<void> _encerrarSessao(String mesaId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Cores.carta2,
        title: const Text('Encerrar sessão?'),
        content: const Text(
            'Todo mundo sai da mesa. A mesa, o código e a galeria continuam.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Encerrar')),
        ],
      ),
    );
    if (ok != true) return;
    await _comEspera(() async {
      await _servico.encerrarSessao(mesaId);
      _desligarPonto();
      _desligarEspelho();
      await MesaStore.limpar();
    });
  }

  /// Irreversível e leva a galeria junto — por isso a confirmação exige
  /// digitar o nome da mesa, não só um toque em "Apagar".
  Future<void> _apagarMesa(String mesaId, String nomeMesa) async {
    final controlador = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final bate = controlador.text == nomeMesa;
          return AlertDialog(
            backgroundColor: Cores.carta2,
            title: const Text('Apagar mesa?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'A mesa, o código e a galeria inteira somem para sempre. '
                  'Isso não pode ser desfeito.',
                ),
                const SizedBox(height: 12),
                Text('Digite "$nomeMesa" para confirmar:',
                    style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                TextField(
                  controller: controlador,
                  autofocus: true,
                  onChanged: (_) => setLocal(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              TextButton(
                onPressed: bate ? () => Navigator.pop(ctx, true) : null,
                child: const Text('Apagar mesa'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    await _comEspera(() async {
      await _servico.apagarMesa(mesaId);
      _desligarPonto();
      _desligarEspelho();
      await MesaStore.limpar();
      await MesaStore.esquecer(mesaId);
    });
  }

  /// Escolhe uma ficha local e a espelha na mesa. NPC fica de fora: quem
  /// publica é o jogador com o próprio personagem, e o bestiário do mestre
  /// não tem por que viajar para os aparelhos da mesa.
  Future<void> _publicar(EstadoMesa estado) async {
    final minhas = FichaStore.todas().where((f) => !f.ehNpc).toList();
    if (minhas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Você ainda não tem nenhum personagem para '
              'publicar. Fichas de NPC não vão para a mesa.')));
      return;
    }
    final escolhida = await showDialog<FichaOP>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: Cores.carta2,
        title: const Text('Publicar uma ficha'),
        children: [
          for (final f in minhas)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, f),
              child: Row(
                children: [
                  RetratoAvatar(base64: f.retrato, tamanho: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(f.nome.isEmpty ? 'Sem nome' : f.nome,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (escolhida == null) return;

    await _comEspera(() async {
      await _servico.publicarFicha(
        estado.mesaId,
        escolhida.dados,
        escolhida.nome.isEmpty ? 'Sem nome' : escolhida.nome,
      );
      await MesaStore.entrar(estado.comFicha(escolhida.id));
      _ligarEspelho(estado.mesaId, escolhida.id);
    });
  }

  /// Remover tira o jogador da mesa na hora: um toque sem querer não pode
  /// derrubar alguém no meio da cena.
  Future<void> _removerMembro(EstadoMesa estado, Membro m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Cores.carta2,
        title: Text('Remover ${m.nome.isEmpty ? 'este jogador' : m.nome}?'),
        content: const Text('Sai da mesa agora e a ficha dele some do painel. '
            'Ele pode voltar com o código.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remover')),
        ],
      ),
    );
    if (ok != true) return;
    await _comEspera(() => _servico.removerMembro(estado.mesaId, m.uid));
  }

  Future<void> _tirarDaMesa(EstadoMesa estado) async {
    await _comEspera(() async {
      await _servico.despublicarFicha(estado.mesaId);
      _desligarEspelho();
      await MesaStore.entrar(estado.comFicha(null));
    });
  }

  @override
  Widget build(BuildContext context) {
    final estado = MesaStore.atual;
    if (estado == null) return _semMesa();
    if (_erroSessao != null) return _semConexao(estado);
    if (!_sessaoPronta) {
      return const Center(child: CircularProgressIndicator());
    }
    return _naMesa(estado);
  }

  /// Estava numa mesa e o app voltou sem internet. O resto do app continua
  /// funcionando; aqui só dá para esperar ou sair da mesa.
  Widget _semConexao(EstadoMesa estado) {
    return _centralizadaRolavel(
      Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: Cores.tinta2),
            const SizedBox(height: 12),
            Text(
              'Não consegui conectar à mesa "${estado.nome}".\n'
              'Suas fichas continuam aqui do mesmo jeito.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(_erroSessao!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _erroSessao = null;
                _religar();
              }),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar de novo'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                _desligarPonto();
                _desligarEspelho();
                await MesaStore.limpar();
                if (mounted) setState(() => _erroSessao = null);
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sair da mesa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _semMesa() {
    final conhecidas = MesaStore.conhecidas();
    return _centralizadaRolavel(
      Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_outlined, size: 56, color: Cores.tinta2),
            const SizedBox(height: 12),
            const Text(
              'Você não está em nenhuma mesa.\n'
              'O app continua funcionando offline do mesmo jeito. Na mesa, '
              'o mestre acompanha as fichas e os testes ao vivo, e as '
              'imagens que ele mostra abrem na tela de todo mundo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            for (final m in conhecidas) _mesaConhecida(m),
            if (conhecidas.isNotEmpty) const SizedBox(height: 10),
            if (_ocupado)
              const CircularProgressIndicator()
            else ...[
              ElevatedButton.icon(
                onPressed: _criar,
                icon: const Icon(Icons.add),
                label: const Text('Criar mesa'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _entrar,
                icon: const Icon(Icons.login),
                label: const Text('Entrar com código'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Cores.energiaViva,
                    side: const BorderSide(color: Cores.energia)),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _reassumir,
                child: const Text('Já sou o mestre desta mesa'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Centraliza quando cabe e rola quando não cabe. No Safari do iPhone a
  /// capa e as barras deixam pouca altura para esta aba, e uma `Column`
  /// presa num `Center` cortava os botões de entrar sem deixar rolar.
  Widget _centralizadaRolavel(Widget filho) {
    return LayoutBuilder(
      builder: (context, limites) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: limites.maxHeight),
          child: Center(child: filho),
        ),
      ),
    );
  }

  Widget _mesaConhecida(MesaConhecida m) {
    return Card(
      child: ListTile(
        title: Text(m.nome.isEmpty ? 'Sem nome' : m.nome,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle:
            Text(m.papel == PapelMesa.mestre ? 'mestre' : 'jogador'),
        onTap: () => _voltarPara(m),
        trailing: IconButton(
          tooltip: 'Esquecer esta mesa',
          icon: const Icon(Icons.close, color: Cores.tinta2),
          onPressed: () => _esquecer(m),
        ),
      ),
    );
  }

  /// A mesa sumiu do stream — como `null` (documento apagado) ou como erro
  /// (o registro de membro caiu antes do documento, e a regra nega a
  /// leitura: mesmo efeito visível, `permission-denied`). Os dois casos
  /// possíveis por trás disso são bem diferentes: `encerrarSessao` (a mesa
  /// continua de pé, reversível) e `apagarMesa` (foi para sempre). Só
  /// `entrarPorId` sabe dizer qual foi: se a mesa ainda existir, ele
  /// readmite este uid como membro dela e devolve normalmente; se não
  /// existir mais, lança `MesaNaoEncontrada`. Uma falha de rede no meio do
  /// caminho é tratada como sessão encerrada — o caso reversível — para não
  /// prender ninguém nem destruir uma mesa conhecida só porque a internet
  /// caiu.
  Future<void> _tratarMesaSumida(EstadoMesa estado) async {
    final conhecida =
        MesaStore.conhecidas().where((m) => m.mesaId == estado.mesaId);
    final meuNome = conhecida.isEmpty ? null : conhecida.first.meuNome;
    final nomeParaEntrar =
        meuNome ?? (estado.papel == PapelMesa.mestre ? 'Mestre' : 'Jogador');
    var apagada = false;
    var sondaOk = false;
    try {
      await _servico.entrarPorId(estado.mesaId, nomeParaEntrar);
      sondaOk = true;
    } on MesaNaoEncontrada {
      apagada = true;
    } catch (_) {
    }
    if (apagada) {
      await MesaStore.esquecer(estado.mesaId);
    } else if (sondaOk) {
      try {
        await _servico.sair(estado.mesaId);
      } catch (_) {}
    }
    await _voltarParaOffline(
        apagada ? 'Esta mesa foi apagada.' : 'A sessão foi encerrada.');
  }

  Widget _naMesa(EstadoMesa estado) {
    return StreamBuilder<Mesa?>(
      stream: _servico.observarMesa(estado.mesaId),
      builder: (context, snap) {
        final mesa = snap.data;
        final souMestre = mesa != null
            ? mesa.mestreUid == estado.uid
            : estado.papel == PapelMesa.mestre;

        final sumiu = snap.hasError ||
            (snap.connectionState == ConnectionState.active &&
                snap.data == null);
        if (sumiu && !_cuidandoDaSaida) {
          _cuidandoDaSaida = true;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _tratarMesaSumida(estado));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(mesa?.nome ?? estado.nome,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        if (souMestre && mesa != null)
                          PopupMenuButton<String>(
                            tooltip: 'Mais opções',
                            icon: const Icon(Icons.more_vert,
                                color: Cores.tinta2),
                            color: Cores.tinta,
                            onSelected: (v) {
                              if (v == 'apagar') {
                                _apagarMesa(mesa.id, mesa.nome);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'apagar',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_forever_outlined,
                                        color: Cores.sangue),
                                    SizedBox(width: 8),
                                    Text('Apagar mesa'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Código: '),
                        SelectableText(
                          mesa?.codigo ?? '—',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 16),
                        ),
                        IconButton(
                          tooltip: 'Copiar código',
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: mesa == null
                              ? null
                              : () {
                                  Clipboard.setData(
                                      ClipboardData(text: mesa.codigo));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Código copiado.')));
                                },
                        ),
                        if (souMestre && mesa != null)
                          IconButton(
                            tooltip: 'Trocar código',
                            icon: const Icon(Icons.autorenew, size: 18),
                            onPressed: () => _comEspera(
                                () => _servico.trocarCodigo(mesa.id)),
                          ),
                      ],
                    ),
                    const Text(
                      'Dite esse código para quem for entrar.',
                      style:
                          TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            const FaixaSecao('Quem está na mesa'),
            _membros(estado, souMestre),
            const FaixaSecao('Mural da mesa'),
            MuralDaMesa(
                servico: _servico,
                mesaId: estado.mesaId,
                souMestre: souMestre),
            const FaixaSecao('Mapa da cena'),
            CartaoMapa(
                servico: _servico,
                mesaId: estado.mesaId,
                souMestre: souMestre),
            const FaixaSecao('Galeria da mesa'),
            GaleriaMesa(
                servico: _servico,
                mesaId: estado.mesaId,
                souMestre: souMestre),
            if (souMestre)
              PainelMestre(servico: _servico, mesaId: estado.mesaId),
            const FaixaSecao('Minha ficha nesta mesa'),
            _minhaFicha(estado),
            const SizedBox(height: 16),
            if (_ocupado)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _sair(estado.mesaId),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sair da mesa'),
                  ),
                  if (souMestre)
                    TextButton.icon(
                      onPressed: () => _encerrarSessao(estado.mesaId),
                      icon: const Icon(Icons.stop_circle_outlined, size: 18),
                      label: const Text('Encerrar sessão'),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  /// A ficha que EU publiquei. O mestre também joga com uma às vezes, então
  /// isto vale para os dois papéis.
  Widget _minhaFicha(EstadoMesa estado) {
    final fichaId = estado.fichaPublicadaId;
    final ficha = fichaId == null ? null : FichaStore.porId(fichaId);

    if (fichaId == null || ficha == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Publicando a ficha, o mestre acompanha o que você marca nela '
                'durante a sessão. Os outros jogadores não veem.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _ocupado ? null : () => _publicar(estado),
                  icon: const Icon(Icons.upload_outlined),
                  label: const Text('Publicar uma ficha'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Cores.energiaViva,
                      side: const BorderSide(color: Cores.energia)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: RetratoAvatar(base64: ficha.retrato),
            title: Text(ficha.nome.isEmpty ? 'Sem nome' : ficha.nome,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('o mestre vê as mudanças em segundos'),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: TextButton.icon(
              onPressed: _ocupado ? null : () => _tirarDaMesa(estado),
              icon: const Icon(Icons.cloud_off_outlined, size: 18),
              label: const Text('Tirar da mesa'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _membros(EstadoMesa estado, bool souMestre) {
    return StreamBuilder<List<Membro>>(
      stream: _servico.observarMembros(estado.mesaId),
      builder: (context, snap) {
        final membros = snap.data ?? const <Membro>[];
        if (membros.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('Ninguém aqui ainda.'),
            ),
          );
        }
        final agora = DateTime.now();
        return Card(
          child: Column(
            children: [
              for (final m in membros)
                ListTile(
                  leading: Icon(
                    Icons.circle,
                    size: 12,
                    color: m.onlineEm(agora)
                        ? Colors.green.shade600
                        : Colors.grey,
                  ),
                  title: Text(m.nome.isEmpty ? 'Sem nome' : m.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      m.papel == PapelMesa.mestre ? 'mestre' : 'jogador'),
                  trailing: souMestre && m.uid != estado.uid
                      ? IconButton(
                          tooltip: 'Remover da mesa',
                          icon: const Icon(Icons.person_remove_outlined,
                              color: Cores.tinta2),
                          onPressed: () => _removerMembro(estado, m),
                        )
                      : null,
                ),
            ],
          ),
        );
      },
    );
  }
}
