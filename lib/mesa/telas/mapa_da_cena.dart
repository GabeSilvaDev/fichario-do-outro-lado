import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../store/ficha_store.dart';
import '../../theme.dart';
import '../imagem_mural.dart';
import '../mesa_service.dart';

/// O mapa da cena: a planta do lugar com uma peça por personagem.
///
/// É tela à parte, dentro da mesa, e vive em tempo real: o mestre arrasta e
/// todo mundo vê. Sair e voltar não perde nada — a posição está no
/// Firestore, não neste aparelho.
///
/// Mapa NÃO é mural. As plantas moram numa biblioteca própria da mesa
/// (`mapas`), separada da galeria: imagem do mural abre na cara de todo
/// mundo, mapa fica de pé para consulta.
///
/// Jogador só olha — mover é do mestre, e a regra do Firestore diz o mesmo.
class MapaDaCena extends StatefulWidget {
  final MesaService servico;
  final String mesaId;
  final bool mestre;

  const MapaDaCena({
    super.key,
    required this.servico,
    required this.mesaId,
    required this.mestre,
  });

  @override
  State<MapaDaCena> createState() => _MapaDaCenaState();
}

class _MapaDaCenaState extends State<MapaDaCena> {
  StreamSubscription<MapaMesa?>? _assinatura;
  MapaMesa? _mapa;

  Uint8List? _bytes;
  Size? _tamanho;
  String _imagemCarregada = '';
  bool _erroImagem = false;
  bool _ocupado = false;

  /// Peças em movimento neste aparelho. Enquanto o dedo está na tela, a
  /// posição local manda; sem isso o stream de volta puxaria a peça para a
  /// posição antiga no meio do arrasto.
  final Map<String, Offset> _arrastando = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _assinatura = widget.servico.observarMapa(widget.mesaId).listen(
      (m) {
        if (!mounted) return;
        setState(() => _mapa = m);
        if (m != null && m.imagemId != _imagemCarregada) _carregarImagem(m);
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _assinatura?.cancel();
    super.dispose();
  }

  Future<void> _carregarImagem(MapaMesa m) async {
    _imagemCarregada = m.imagemId;
    _erroImagem = false;
    final b64 = await widget.servico.imagemDeMapa(widget.mesaId, m.imagemId);
    if (!mounted) return;
    if (b64 == null) {
      setState(() => _erroImagem = true);
      return;
    }
    final bytes = base64Decode(b64);
    final descritor = await ui.ImageDescriptor.encoded(
        await ui.ImmutableBuffer.fromUint8List(bytes));
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _tamanho = Size(descritor.width.toDouble(), descritor.height.toDouble());
    });
    descritor.dispose();
  }

  // ---------- mover ----------

  void _mover(TokenMapa token, Offset nova) {
    setState(() => _arrastando[token.id] = nova);
    // uma escrita a cada 120 ms enquanto o dedo anda: a mesa acompanha o
    // movimento sem transformar um arrasto em cinquenta escritas
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), _gravarArrasto);
  }

  void _soltar() {
    _debounce?.cancel();
    _gravarArrasto();
  }

  Future<void> _gravarArrasto() async {
    final mapa = _mapa;
    if (mapa == null || _arrastando.isEmpty) return;
    await _salvar([
      for (final t in mapa.tokens)
        _arrastando.containsKey(t.id)
            ? t.mover(_arrastando[t.id]!.dx, _arrastando[t.id]!.dy)
            : t
    ]);
  }

  Future<void> _salvar(List<TokenMapa> tokens) async {
    try {
      await widget.servico.salvarTokens(widget.mesaId, tokens);
    } catch (_) {
      // sem rede a peça continua onde o mestre soltou; a próxima gravação
      // que der certo leva a posição junto
    }
  }

  Offset _posicao(TokenMapa t) => _arrastando[t.id] ?? Offset(t.x, t.y);

  List<TokenMapa> get _tokens => _mapa?.tokens ?? const [];

  Future<void> _trocarToken(TokenMapa novo) =>
      _salvar([for (final t in _tokens) t.id == novo.id ? novo : t]);

  Future<void> _removerToken(TokenMapa alvo) =>
      _salvar([for (final t in _tokens) if (t.id != alvo.id) t]);

  // ---------- peça: tamanho, ameaça, remover ----------

  void _abrirPeca(TokenMapa token) {
    if (!widget.mestre) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Cores.carta,
      builder: (_) => _FolhaDaPeca(
        token: token,
        aoMudar: _trocarToken,
        aoRemover: () {
          Navigator.pop(context);
          _removerToken(token);
        },
      ),
    );
  }

  // ---------- peças novas ----------

  Future<void> _editarPecas() async {
    final fichas = await widget.servico
        .observarFichas(widget.mesaId)
        .first
        .timeout(const Duration(seconds: 8), onTimeout: () => const []);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Cores.carta,
      isScrollControlled: true,
      builder: (_) => _FolhaPecas(
        fichas: fichas,
        tokens: _tokens,
        aoTrocar: _salvar,
      ),
    );
  }

  // ---------- biblioteca de plantas ----------

  Future<void> _abrirBiblioteca() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Cores.carta,
      isScrollControlled: true,
      builder: (_) => _FolhaPlantas(
        servico: widget.servico,
        mesaId: widget.mesaId,
        atual: _mapa?.imagemId ?? '',
        aoEscolher: (imagem) async {
          Navigator.pop(context);
          await _porNaMesa(imagem.id, imagem.nome);
        },
        aoSubir: _subirPlanta,
      ),
    );
  }

  /// As peças que já entram com o mapa: uma por ficha publicada,
  /// enfileiradas na base. O mestre arrasta cada uma para o lugar.
  Future<List<TokenMapa>> _pecasIniciais() async {
    final fichas = await widget.servico
        .observarFichas(widget.mesaId)
        .first
        .timeout(const Duration(seconds: 8), onTimeout: () => const []);
    return [
      for (var i = 0; i < fichas.length; i++)
        TokenMapa(
          id: fichas[i].donoUid,
          nome: fichas[i].nome.isEmpty ? 'Sem nome' : fichas[i].nome,
          retrato:
              ImagemMural.peca((fichas[i].ficha['retrato'] ?? '') as String),
          cor: corDaPeca(fichas[i].nome, inimigo: false),
          x: (i + 1) / (fichas.length + 1),
          y: .88,
        ),
    ];
  }

  Future<void> _porNaMesa(String imagemId, String nome) async {
    setState(() => _ocupado = true);
    try {
      // troca de planta mantém as peças que já estavam em jogo; mapa novo
      // começa com o grupo enfileirado embaixo
      final tokens = _tokens.isEmpty ? await _pecasIniciais() : _tokens;
      await widget.servico.abrirMapa(widget.mesaId, imagemId, nome, tokens);
    } catch (e) {
      _erro(e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _subirPlanta() async {
    final escolha = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = escolha?.files.single.bytes;
    if (bytes == null || !mounted) return;
    final nome = await _pedirNome(escolha!.files.single.name);
    if (nome == null || !mounted) return;

    setState(() => _ocupado = true);
    try {
      final id = await widget.servico.guardarMapa(
        widget.mesaId,
        ImagemMural.preparar(bytes),
        ImagemMural.miniatura(bytes),
        nome,
      );
      await _porNaMesa(id, nome);
    } catch (e) {
      _erro(e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<String?> _pedirNome(String sugestao) {
    final campo = TextEditingController(
        text: sugestao.replaceAll(RegExp(r'\.[A-Za-z0-9]+$'), ''));
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nome da planta'),
        content: TextField(
          controller: campo,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Ex.: Vagão 3 · Porão da vinícola'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, campo.text.trim()),
              child: const Text('Guardar')),
        ],
      ),
    );
  }

  Future<void> _tirarDaMesa() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tirar o mapa da mesa?'),
        content: const Text(
            'O mapa some da tela de todo mundo. A planta continua guardada '
            'na biblioteca da mesa.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tirar mapa')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await widget.servico.fecharMapa(widget.mesaId);
  }

  void _erro(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
  }

  @override
  Widget build(BuildContext context) {
    final mapa = _mapa;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Cores.carta,
        title: Text(
          mapa == null || mapa.titulo.isEmpty ? 'Mapa da cena' : mapa.titulo,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          if (widget.mestre) ...[
            IconButton(
              tooltip: 'Plantas da mesa',
              icon: const Icon(Icons.map_outlined),
              onPressed: _abrirBiblioteca,
            ),
            if (mapa != null)
              IconButton(
                tooltip: 'Peças no mapa',
                icon: const Icon(Icons.groups_2_outlined),
                onPressed: _editarPecas,
              ),
            if (mapa != null)
              IconButton(
                tooltip: 'Tirar o mapa da mesa',
                icon: const Icon(Icons.layers_clear_outlined),
                onPressed: _tirarDaMesa,
              ),
          ],
        ],
      ),
      body: _ocupado
          ? const Center(child: CircularProgressIndicator())
          : _corpo(mapa),
    );
  }

  Widget _corpo(MapaMesa? mapa) {
    if (mapa == null) {
      return _Recado(
        icone: Icons.map_outlined,
        texto: widget.mestre
            ? 'Nenhum mapa na mesa. Toque no ícone de planta lá em cima '
                'para escolher uma — ou subir a primeira.'
            : 'O mestre ainda não pôs mapa nesta cena. Esta tela fica '
                'aberta: quando ele puser, aparece aqui na hora.',
      );
    }
    if (_erroImagem) {
      return const _Recado(
        icone: Icons.broken_image_outlined,
        texto: 'A imagem do mapa não veio. Verifique a internet e volte a '
            'abrir.',
      );
    }
    final bytes = _bytes;
    final tamanho = _tamanho;
    if (bytes == null || tamanho == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, limites) {
        // a imagem inteira sempre cabe na tela; o zoom é por cima disso
        final escala = (limites.maxWidth / tamanho.width)
            .clamp(0.0, limites.maxHeight / tamanho.height);
        final largura = tamanho.width * escala;
        final altura = tamanho.height * escala;

        return Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 6,
            child: SizedBox(
              width: largura,
              height: altura,
              child: Stack(
                children: [
                  Positioned.fill(child: Image.memory(bytes, fit: BoxFit.fill)),
                  for (final t in mapa.tokens)
                    _peca(t, Size(largura, altura)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _peca(TokenMapa t, Size mapa) {
    final lado = 46.0 * t.escala;
    final pos = _posicao(t);
    final peca = _PecaMapa(token: t, lado: lado);

    return Positioned(
      left: pos.dx * mapa.width - lado / 2,
      top: pos.dy * mapa.height - lado / 2,
      child: widget.mestre
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _abrirPeca(t),
              onPanUpdate: (d) {
                final atual = _posicao(t);
                _mover(
                  t,
                  Offset(
                    (atual.dx + d.delta.dx / mapa.width).clamp(0.0, 1.0),
                    (atual.dy + d.delta.dy / mapa.height).clamp(0.0, 1.0),
                  ),
                );
              },
              onPanEnd: (_) => _soltar(),
              child: peca,
            )
          : IgnorePointer(child: peca),
    );
  }
}

/// A peça em si: retrato quando existe, inicial quando não.
class _PecaMapa extends StatelessWidget {
  final TokenMapa token;
  final double lado;

  /// No mapa a etiqueta com o nome é essencial; nas listas o nome já está
  /// do lado, e repetir embaixo do círculo só suja.
  final bool comNome;

  const _PecaMapa({
    required this.token,
    required this.lado,
    this.comNome = true,
  });

  @override
  Widget build(BuildContext context) {
    final cor = Color(token.cor);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: lado,
          height: lado,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Cores.fundo,
            border: Border.all(color: cor, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black87, blurRadius: 6, spreadRadius: 1),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: token.retrato.isEmpty
              ? Center(
                  child: Text(
                    token.inicial,
                    style: TextStyle(
                        fontSize: lado * .45,
                        fontWeight: FontWeight.bold,
                        color: cor),
                  ),
                )
              : Image.memory(base64Decode(token.retrato), fit: BoxFit.cover),
        ),
        if (comNome) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .65),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              token.nome.length > 12
                  ? '${token.nome.substring(0, 12)}…'
                  : token.nome,
              style: const TextStyle(fontSize: 10, color: Cores.tinta),
            ),
          ),
        ],
      ],
    );
  }
}

/// O que abre ao tocar numa peça: tamanho, marca de ameaça e remover.
class _FolhaDaPeca extends StatefulWidget {
  final TokenMapa token;
  final Future<void> Function(TokenMapa) aoMudar;
  final VoidCallback aoRemover;

  const _FolhaDaPeca({
    required this.token,
    required this.aoMudar,
    required this.aoRemover,
  });

  @override
  State<_FolhaDaPeca> createState() => _FolhaDaPecaState();
}

class _FolhaDaPecaState extends State<_FolhaDaPeca> {
  late TokenMapa _token = widget.token;

  void _aplicar(TokenMapa novo) {
    setState(() => _token = novo);
    widget.aoMudar(novo);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PecaMapa(token: _token, lado: 46 * _token.escala),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(_token.nome,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Tamanho da peça: ${(_token.escala * 100).round()}%',
                style: const TextStyle(fontSize: 12, color: Cores.tinta2)),
            Slider(
              value: _token.escala,
              min: 0.4,
              max: 3,
              divisions: 26,
              label: '${(_token.escala * 100).round()}%',
              onChanged: (v) => setState(() => _token = _token.comEscala(v)),
              onChangeEnd: (v) => _aplicar(_token.comEscala(v)),
            ),
            const Text(
              'Mapa de porão pede peça grande; mapa de cidade, peça '
              'pequena. Criatura Enorme merece o dobro de um agente.',
              style: TextStyle(fontSize: 11, color: Cores.tinta2),
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _token.inimigo,
              onChanged: (v) => _aplicar(_token.copiar(
                inimigo: v,
                cor: corDaPeca(_token.nome, inimigo: v),
              )),
              title: const Text('É ameaça (peça vermelha)',
                  style: TextStyle(fontSize: 13)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.aoRemover,
                icon: const Icon(Icons.delete_outline, size: 18,
                    color: Cores.sangue),
                label: const Text('Tirar do mapa',
                    style: TextStyle(color: Cores.sangue)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A biblioteca de plantas da mesa.
class _FolhaPlantas extends StatelessWidget {
  final MesaService servico;
  final String mesaId;
  final String atual;
  final Future<void> Function(ImagemDeMapa) aoEscolher;
  final Future<void> Function() aoSubir;

  const _FolhaPlantas({
    required this.servico,
    required this.mesaId,
    required this.atual,
    required this.aoEscolher,
    required this.aoSubir,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<ImagemDeMapa>>(
        stream: servico.observarMapasGuardados(mesaId),
        builder: (context, snap) {
          final plantas = snap.data ?? const <ImagemDeMapa>[];
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Plantas desta mesa',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              const Text(
                'Ficam guardadas aqui, fora da galeria do mural — mapa não '
                'abre na cara de ninguém.',
                style: TextStyle(fontSize: 12, color: Cores.tinta2),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  aoSubir();
                },
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('Subir planta nova'),
              ),
              const SizedBox(height: 8),
              if (plantas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Nenhuma planta guardada ainda.',
                      style: TextStyle(fontSize: 13, color: Cores.tinta2)),
                ),
              for (final p in plantas)
                ListTile(
                  dense: true,
                  leading: _Miniatura(base64: p.miniaturaBase64),
                  title: Text(p.nome.isEmpty ? 'Sem nome' : p.nome,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: p.id == atual
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  subtitle: p.id == atual
                      ? const Text('na mesa agora',
                          style:
                              TextStyle(fontSize: 11, color: Cores.estavel))
                      : null,
                  onTap: () => aoEscolher(p),
                  trailing: IconButton(
                    tooltip: 'Apagar planta',
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => servico.apagarMapaGuardado(mesaId, p.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  final String base64;

  const _Miniatura({required this.base64});

  @override
  Widget build(BuildContext context) {
    if (base64.isEmpty) {
      return const Icon(Icons.image_outlined, color: Cores.tinta2);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.memory(base64Decode(base64),
          width: 48, height: 48, fit: BoxFit.cover),
    );
  }
}

/// Quem está no mapa: fichas publicadas, NPCs do aparelho e peça avulsa.
class _FolhaPecas extends StatefulWidget {
  final List<FichaNaMesa> fichas;
  final List<TokenMapa> tokens;
  final Future<void> Function(List<TokenMapa>) aoTrocar;

  const _FolhaPecas({
    required this.fichas,
    required this.tokens,
    required this.aoTrocar,
  });

  @override
  State<_FolhaPecas> createState() => _FolhaPecasState();
}

class _FolhaPecasState extends State<_FolhaPecas> {
  late final List<TokenMapa> _tokens = [...widget.tokens];
  final _nome = TextEditingController();
  bool _inimigo = true;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _salvar() => widget.aoTrocar(_tokens);

  void _alternarFicha(FichaNaMesa f) {
    setState(() {
      if (_tokens.any((t) => t.id == f.donoUid)) {
        _tokens.removeWhere((t) => t.id == f.donoUid);
      } else {
        _tokens.add(TokenMapa(
          id: f.donoUid,
          nome: f.nome.isEmpty ? 'Sem nome' : f.nome,
          retrato: ImagemMural.peca((f.ficha['retrato'] ?? '') as String),
          cor: corDaPeca(f.nome, inimigo: false),
          x: .5,
          y: .5,
        ));
      }
    });
    _salvar();
  }

  /// NPC do bestiário vira peça com o brasão dele — o mesmo símbolo que
  /// aparece na lista de fichas.
  void _porNpc(String nome, String retrato) {
    setState(() {
      _tokens.add(TokenMapa(
        // marca de tempo no id: dois "Zumbi de Sangue" são duas peças
        id: 'npc:${DateTime.now().microsecondsSinceEpoch}',
        nome: nome,
        retrato: ImagemMural.peca(retrato),
        cor: corDaPeca(nome, inimigo: true),
        x: .5,
        y: .5,
        inimigo: true,
      ));
    });
    _salvar();
  }

  Future<void> _escolherNpc() async {
    final npcs = FichaStore.todas().where((f) => f.ehNpc).toList();
    if (!mounted) return;
    if (npcs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nenhum NPC no aparelho. Importe o bestiário na '
              'aba Fichas.')));
      return;
    }
    final busca = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Cores.carta,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, refazer) {
          final filtro = busca.text.trim().toLowerCase();
          final lista = npcs
              .where((f) => filtro.isEmpty ||
                  f.nome.toLowerCase().contains(filtro))
              .take(60)
              .toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Pôr NPC do bestiário',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: busca,
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search, size: 18),
                      labelText: 'Procurar NPC',
                    ),
                    onChanged: (_) => refazer(() {}),
                  ),
                  const SizedBox(height: 8),
                  for (final f in lista)
                    ListTile(
                      dense: true,
                      leading: _PecaMapa(
                        token: TokenMapa(
                          id: 'pre',
                          nome: f.nome,
                          retrato: f.retrato,
                          cor: corDaPeca(f.nome, inimigo: true),
                          x: 0,
                          y: 0,
                        ),
                        lado: 30,
                        comNome: false,
                      ),
                      title: Text(f.nome,
                          style: const TextStyle(fontSize: 13)),
                      onTap: () {
                        Navigator.pop(context);
                        _porNpc(f.nome, f.retrato);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _novoAvulso() {
    final nome = _nome.text.trim();
    if (nome.isEmpty) return;
    setState(() {
      _tokens.add(TokenMapa(
        id: 'npc:${DateTime.now().microsecondsSinceEpoch}',
        nome: nome,
        cor: corDaPeca(nome, inimigo: _inimigo),
        x: .5,
        y: .5,
        inimigo: _inimigo,
      ));
      _nome.clear();
    });
    _salvar();
  }

  void _remover(TokenMapa t) {
    setState(() => _tokens.removeWhere((x) => x.id == t.id));
    _salvar();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Peças no mapa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text(
              'Agente com ficha publicada entra com o retrato dele. NPC do '
              'bestiário entra com o brasão. Toque numa peça no mapa para '
              'mudar o tamanho.',
              style: TextStyle(fontSize: 12, color: Cores.tinta2),
            ),
            const SizedBox(height: 12),
            if (widget.fichas.isEmpty)
              const Text('Ninguém publicou ficha nesta mesa ainda.',
                  style: TextStyle(fontSize: 13, color: Cores.tinta2)),
            for (final f in widget.fichas)
              CheckboxListTile(
                dense: true,
                value: _tokens.any((t) => t.id == f.donoUid),
                onChanged: (_) => _alternarFicha(f),
                title: Text(f.nome.isEmpty ? 'Sem nome' : f.nome),
              ),
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _escolherNpc,
                icon: const Icon(Icons.pest_control_outlined, size: 16),
                label: const Text('Pôr NPC do bestiário'),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Peça avulsa (marcador, porta, refém…)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nome,
                    decoration: const InputDecoration(
                        labelText: 'Nome da peça', isDense: true),
                    onSubmitted: (_) => _novoAvulso(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _novoAvulso, child: const Text('Pôr')),
              ],
            ),
            SwitchListTile(
              dense: true,
              value: _inimigo,
              onChanged: (v) => setState(() => _inimigo = v),
              title: const Text('É ameaça (peça vermelha)',
                  style: TextStyle(fontSize: 13)),
            ),
            if (_tokens.isNotEmpty) ...[
              const Divider(height: 24),
              const Text('No mapa agora',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              for (final t in _tokens)
                ListTile(
                  dense: true,
                  leading: _PecaMapa(token: t, lado: 28, comNome: false),
                  title: Text(t.nome, style: const TextStyle(fontSize: 13)),
                  subtitle: Text('tamanho ${(t.escala * 100).round()}%',
                      style: const TextStyle(fontSize: 11)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _remover(t),
                  ),
                ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Cor da peça. Ameaça é sempre vermelha — no meio do combate, ninguém tem
/// tempo de decorar quem é quem. Agente ganha uma cor estável a partir do
/// nome, para a mesma pessoa ter sempre a mesma peça.
int corDaPeca(String nome, {required bool inimigo}) {
  if (inimigo) return Cores.sangue.toARGB32();
  const paleta = [
    0xFFA06BFF, // energia
    0xFF57B98A, // membrana estável
    0xFFD9A441, // conhecimento
    0xFF4FA8E0, // frio
    0xFFE07FB8, // rosa
    0xFF8CD17D, // verde claro
  ];
  var soma = 0;
  for (final c in nome.codeUnits) {
    soma += c;
  }
  return paleta[soma % paleta.length];
}

class _Recado extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _Recado({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 44, color: Cores.tinta2),
            const SizedBox(height: 12),
            Text(texto,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Cores.tinta2)),
          ],
        ),
      ),
    );
  }
}
