import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../store/ficha_store.dart';
import '../../theme.dart';
import '../imagem_mural.dart';
import '../mesa_service.dart';
import '../regua.dart';
import 'iniciativa_mesa.dart';

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
/// O mestre mexe em todas as peças. O jogador mexe só na dele — a peça que
/// entra quando ele publica a ficha (foto da ficha, ou a inicial) — e a
/// regra do Firestore diz o mesmo.
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

  /// Quantas telas de mapa estão abertas agora. Quem já está no mapa vê a
  /// troca ali mesmo: abrir outra por cima empilhava telas iguais e o
  /// "voltar" parecia não funcionar.
  static int abertas = 0;

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

  StreamSubscription<Iniciativa?>? _assinaturaIniciativa;
  Iniciativa? _iniciativa;

  /// Régua ligada: arrastar no mapa mede em vez de mover a imagem.
  bool _regua = false;

  /// Mestre marcou "calibrar": a próxima linha vira o tamanho da grade.
  bool _calibrando = false;
  Offset? _reguaDe;
  Offset? _reguaAte;

  @override
  void initState() {
    super.initState();
    MapaDaCena.abertas++;
    _assinatura = widget.servico.observarMapa(widget.mesaId).listen((m) {
      if (!mounted) return;
      setState(() => _mapa = m);
      if (m != null && m.imagemId != _imagemCarregada) _carregarImagem(m);
    }, onError: (_) {});
    try {
      _assinaturaIniciativa = widget.servico
          .observarIniciativa(widget.mesaId)
          .listen((i) {
            if (mounted) setState(() => _iniciativa = i);
          }, onError: (_) {});
    } catch (_) {
      // Serviço sem combate (testes antigos): o mapa funciona sem.
    }
  }

  @override
  void dispose() {
    MapaDaCena.abertas--;
    _debounce?.cancel();
    _assinatura?.cancel();
    _assinaturaIniciativa?.cancel();
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
    // Só o tamanho interessa aqui. `ImageDescriptor` não existe no Flutter
    // web — o mestre no navegador ficava preso no carregando; o codec
    // funciona nos dois.
    try {
      final bytes = base64Decode(b64);
      final codec = await ui.instantiateImageCodec(bytes);
      final quadro = await codec.getNextFrame();
      final tamanho = Size(
        quadro.image.width.toDouble(),
        quadro.image.height.toDouble(),
      );
      quadro.image.dispose();
      codec.dispose();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _tamanho = tamanho;
      });
    } catch (_) {
      if (mounted) setState(() => _erroImagem = true);
    }
  }

  void _mover(TokenMapa token, Offset nova) {
    setState(() => _arrastando[token.id] = nova);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), _gravarArrasto);
  }

  /// Soltou: grava a posição final e devolve a peça ao que vem da mesa —
  /// senão este aparelho ficaria preso na posição local e não veria mais
  /// quando outra pessoa (mestre ou dono) movesse a mesma peça.
  Future<void> _soltar() async {
    _debounce?.cancel();
    final soltas = _arrastando.keys.toList();
    await _gravarArrasto();
    if (!mounted) return;
    setState(() {
      for (final id in soltas) {
        _arrastando.remove(id);
      }
    });
  }

  /// A peça é minha (jogador): o id dela é o meu uid.
  bool _minha(TokenMapa t) =>
      !widget.mestre && t.id.isNotEmpty && t.id == widget.servico.uid;

  bool _podeMexer(TokenMapa t) => widget.mestre || _minha(t);

  Future<void> _gravarArrasto() async {
    final mapa = _mapa;
    if (mapa == null || _arrastando.isEmpty) return;
    if (!widget.mestre) {
      for (final t in mapa.tokens) {
        final p = _arrastando[t.id];
        if (p != null && _minha(t)) {
          try {
            await widget.servico.moverMinhaPeca(
              widget.mesaId,
              t.mover(p.dx, p.dy),
            );
          } catch (_) {}
        }
      }
      return;
    }
    // Uma peça por vez: regravar a lista inteira a cada arrasto deixava
    // duas gravações seguidas chegarem fora de ordem.
    for (final t in mapa.tokens) {
      final p = _arrastando[t.id];
      if (p == null) continue;
      try {
        await widget.servico.salvarPeca(widget.mesaId, t.mover(p.dx, p.dy));
      } catch (_) {}
    }
  }

  Future<void> _salvar(List<TokenMapa> tokens) async {
    try {
      await widget.servico.salvarTokens(widget.mesaId, tokens);
    } catch (_) {}
  }

  Offset _posicao(TokenMapa t) => _arrastando[t.id] ?? Offset(t.x, t.y);

  List<TokenMapa> get _tokens => _mapa?.tokens ?? const [];

  Future<void> _trocarToken(TokenMapa novo) async {
    if (!widget.mestre) {
      try {
        await widget.servico.moverMinhaPeca(widget.mesaId, novo);
      } catch (_) {}
      return;
    }
    try {
      await widget.servico.salvarPeca(widget.mesaId, novo);
    } catch (_) {}
  }

  Future<void> _removerToken(TokenMapa alvo) => _salvar([
    for (final t in _tokens)
      if (t.id != alvo.id) t,
  ]);

  void _abrirPeca(TokenMapa token) {
    if (!_podeMexer(token)) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Cores.carta,
      builder: (_) => _FolhaDaPeca(
        token: token,
        mestre: widget.mestre,
        aoMudar: _trocarToken,
        aoRemover: () {
          Navigator.pop(context);
          _removerToken(token);
        },
      ),
    );
  }

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
        servico: widget.servico,
        mesaId: widget.mesaId,
        fichas: fichas,
        tokens: _tokens,
        aoTrocar: _salvar,
      ),
    );
  }

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
          retrato: ImagemMural.peca(
            (fichas[i].ficha['retrato'] ?? '') as String,
          ),
          cor: corDaPeca(fichas[i].nome, inimigo: false),
          x: (i + 1) / (fichas.length + 1),
          y: .88,
        ),
    ];
  }

  Future<void> _porNaMesa(String imagemId, String nome) => _trocarPara(
    ImagemDeMapa(
      id: imagemId,
      nome: nome,
      miniaturaBase64: '',
      em: DateTime.now(),
    ),
  );

  /// Troca o mapa da mesa para [destino], para todo mundo. O mapa que sai
  /// guarda onde estavam as peças; o que entra traz as dele de volta (ou,
  /// se nunca foi usado, só os agentes publicados, na base). Agente que
  /// tirou a ficha da mesa não volta; quem publicou e não tinha peça entra.
  Future<void> _trocarPara(ImagemDeMapa destino) async {
    final atual = _mapa;
    if (atual != null && atual.imagemId == destino.id) return;
    setState(() => _ocupado = true);
    try {
      if (atual != null && atual.imagemId.isNotEmpty) {
        await widget.servico.guardarPecasDoMapa(
          widget.mesaId,
          atual.imagemId,
          _tokens,
        );
      }
      // A planta da faixa pode estar velha: lê as peças guardadas de agora.
      final daBiblioteca =
          (await widget.servico
                  .observarMapasGuardados(widget.mesaId)
                  .first
                  .timeout(
                    const Duration(seconds: 8),
                    onTimeout: () => const [],
                  ))
              .where((m) => m.id == destino.id)
              .firstOrNull;
      final guardadas = daBiblioteca?.pecas ?? destino.pecas;
      final quadrado = daBiblioteca?.quadrado ?? destino.quadrado;
      final agentes = await _pecasIniciais();
      final publicados = {for (final a in agentes) a.id: a};
      final tokens = <TokenMapa>[
        for (final t in guardadas ?? const <TokenMapa>[])
          if (t.id.startsWith('npc:'))
            t
          else if (publicados[t.id] case final agora?)
            // Volta onde estava, com nome e foto de agora.
            t.copiar(nome: agora.nome, retrato: agora.retrato),
      ];
      for (final a in agentes) {
        if (!tokens.any((t) => t.id == a.id)) tokens.add(a);
      }
      await widget.servico.abrirMapa(
        widget.mesaId,
        destino.id,
        destino.nome,
        tokens,
        quadrado: quadrado,
      );
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
      text: sugestao.replaceAll(RegExp(r'\.[A-Za-z0-9]+$'), ''),
    );
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nome da planta'),
        content: TextField(
          controller: campo,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ex.: Vagão 3 · Porão da vinícola',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, campo.text.trim()),
            child: const Text('Guardar'),
          ),
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
          'na biblioteca da mesa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tirar mapa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await widget.servico.fecharMapa(widget.mesaId);
  }

  void _alternarRegua() => setState(() {
    _regua = !_regua;
    _calibrando = false;
    _reguaDe = null;
    _reguaAte = null;
  });

  /// Começar a medir em cima de uma peça prende a ponta no centro dela —
  /// medir "do Asafe até o zumbi" sem precisar de pontaria.
  Offset _grudar(Offset p, Size mapa) {
    for (final t in _tokens) {
      final c = _posicao(t);
      final raio = 23.0 * t.escala;
      final dx = (c.dx - p.dx) * mapa.width;
      final dy = (c.dy - p.dy) * mapa.height;
      if (dx * dx + dy * dy <= raio * raio) return c;
    }
    return p;
  }

  Future<void> _fimDaRegua() async {
    final mapa = _mapa;
    final a = _reguaDe;
    final b = _reguaAte;
    final tamanho = _tamanho;
    if (!widget.mestre || mapa == null || a == null || b == null) return;
    if (tamanho == null) return;
    if (!_calibrando && mapa.quadrado > 0) return;
    final n = await _pedirQuadrados();
    if (n == null || n <= 0 || !mounted) return;
    final lado = Regua.calibrar(a, b, tamanho, n);
    if (lado <= 0) return;
    setState(() => _calibrando = false);
    try {
      await widget.servico.calibrarMapa(widget.mesaId, mapa.imagemId, lado);
    } catch (e) {
      _erro(e);
    }
  }

  Future<int?> _pedirQuadrados() {
    final campo = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quantos quadrados tem essa linha?'),
        content: TextField(
          key: const ValueKey('quadrados-calibrar'),
          controller: campo,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Conte os quadrados da grade',
          ),
          onSubmitted: (t) => Navigator.pop(ctx, int.tryParse(t.trim())),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const ValueKey('ok-calibrar'),
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(campo.text.trim())),
            child: const Text('Calibrar'),
          ),
        ],
      ),
    );
  }

  void _abrirIniciativa() {
    final i = _iniciativa;
    if (widget.mestre) {
      PainelIniciativa.abrir(context, widget.servico, widget.mesaId, _tokens);
    } else if (i != null) {
      verOrdem(context, i);
    }
  }

  Widget _avisoRegua(MapaMesa mapa) {
    final calibrado = mapa.quadrado > 0;
    final texto = _calibrando
        ? 'Arraste por cima de alguns quadrados da grade (quanto mais, '
              'mais preciso).'
        : calibrado
        ? 'Arraste de um ponto a outro. Começar numa peça prende nela.'
        : widget.mestre
        ? 'Grade ainda não calibrada: arraste por cima de alguns quadrados '
              'e diga quantos são.'
        : 'O mestre ainda não calibrou a grade deste mapa.';
    return Material(
      color: Cores.fundo,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
        child: Row(
          children: [
            const Icon(Icons.straighten, size: 16, color: Cores.tinta2),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(fontSize: 12, color: Cores.tinta2),
              ),
            ),
            if (widget.mestre && calibrado && !_calibrando)
              TextButton(
                key: const ValueKey('recalibrar'),
                onPressed: () => setState(() {
                  _calibrando = true;
                  _reguaDe = null;
                  _reguaAte = null;
                }),
                child: const Text('Calibrar'),
              ),
          ],
        ),
      ),
    );
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
          if (mapa != null)
            IconButton(
              key: const ValueKey('botao-regua'),
              tooltip: _regua ? 'Desligar a régua' : 'Régua',
              isSelected: _regua,
              icon: const Icon(Icons.straighten),
              color: _regua ? Cores.energiaViva : null,
              onPressed: _alternarRegua,
            ),
          if (widget.mestre && mapa != null)
            IconButton(
              key: const ValueKey('botao-iniciativa'),
              tooltip: 'Iniciativa',
              icon: const Icon(Icons.swap_vert),
              onPressed: _abrirIniciativa,
            ),
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
      body: Column(
        children: [
          if (widget.mestre)
            _FaixaMapas(
              servico: widget.servico,
              mesaId: widget.mesaId,
              atual: mapa?.imagemId ?? '',
              aoEscolher: _trocarPara,
              aoSubir: _subirPlanta,
              aoErro: _erro,
            ),
          if (mapa != null)
            FaixaIniciativa(
              servico: widget.servico,
              mesaId: widget.mesaId,
              mestre: widget.mestre,
              iniciativa: _iniciativa,
              aoAbrir: _abrirIniciativa,
            ),
          if (_regua && mapa != null) _avisoRegua(mapa),
          Expanded(
            child: _ocupado
                ? const Center(child: CircularProgressIndicator())
                : _corpo(mapa),
          ),
        ],
      ),
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
        texto:
            'A imagem do mapa não veio. Verifique a internet e volte a '
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
        final escala = (limites.maxWidth / tamanho.width).clamp(
          0.0,
          limites.maxHeight / tamanho.height,
        );
        final largura = tamanho.width * escala;
        final altura = tamanho.height * escala;

        return Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 6,
            // Com a régua, um dedo mede; zoom continua com dois dedos.
            panEnabled: !_regua,
            child: SizedBox(
              width: largura,
              height: altura,
              child: Stack(
                children: [
                  Positioned.fill(child: Image.memory(bytes, fit: BoxFit.fill)),
                  for (final t in mapa.tokens) _peca(t, Size(largura, altura)),
                  if (_regua)
                    _camadaRegua(mapa, Size(largura, altura), tamanho),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _camadaRegua(MapaMesa mapa, Size tela, Size imagem) {
    Offset rel(Offset local) => Offset(
      (local.dx / tela.width).clamp(0.0, 1.0),
      (local.dy / tela.height).clamp(0.0, 1.0),
    );
    final a = _reguaDe;
    final b = _reguaAte;
    String? rotulo;
    if (a != null && b != null) {
      if (_calibrando || mapa.quadrado <= 0) {
        rotulo = widget.mestre ? 'Solte para dizer quantos quadrados' : null;
      } else {
        rotulo = Regua.rotulo(a, b, imagem, mapa.quadrado);
      }
    }
    return Positioned.fill(
      child: GestureDetector(
        key: const ValueKey('camada-regua'),
        behavior: HitTestBehavior.opaque,
        // A linha começa onde o dedo encostou, não onde o arrasto foi
        // reconhecido (uns 36 px depois) — senão a calibragem sai torta.
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (d) => setState(() {
          _reguaDe = _grudar(rel(d.localPosition), tela);
          _reguaAte = _reguaDe;
        }),
        onPanUpdate: (d) =>
            setState(() => _reguaAte = _grudar(rel(d.localPosition), tela)),
        onPanEnd: (_) => _fimDaRegua(),
        child: CustomPaint(
          painter: _PintorRegua(
            de: a,
            ate: b,
            rotulo: rotulo,
            calibrando: _calibrando || mapa.quadrado <= 0,
          ),
        ),
      ),
    );
  }

  Widget _peca(TokenMapa t, Size mapa) {
    final lado = 46.0 * t.escala;
    final pos = _posicao(t);
    final daVez = _iniciativa?.atual?.id == t.id;
    final peca = _PecaMapa(token: t, lado: lado, daVez: daVez);

    return Positioned(
      left: pos.dx * mapa.width - lado / 2,
      top: pos.dy * mapa.height - lado / 2,
      child: _podeMexer(t)
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

/// A faixa de plantas do mestre, em cima do mapa: um toque troca o mapa de
/// todo mundo. Agrupa pelo grupo que o mestre der ("Missão 3"); segurar
/// abre renomear, grupo, mover e apagar.
class _FaixaMapas extends StatelessWidget {
  final MesaService servico;
  final String mesaId;
  final String atual;
  final Future<void> Function(ImagemDeMapa) aoEscolher;
  final Future<void> Function() aoSubir;
  final void Function(Object) aoErro;

  const _FaixaMapas({
    required this.servico,
    required this.mesaId,
    required this.atual,
    required this.aoEscolher,
    required this.aoSubir,
    required this.aoErro,
  });

  /// Plantas na ordem da faixa: por grupo (sem grupo primeiro), depois pela
  /// ordem dentro do grupo.
  static List<ImagemDeMapa> ordenar(List<ImagemDeMapa> mapas) {
    final grupos = <String>[];
    for (final m in mapas) {
      if (!grupos.contains(m.grupo)) grupos.add(m.grupo);
    }
    grupos.sort((a, b) {
      if (a.isEmpty) return -1;
      if (b.isEmpty) return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return [for (final g in grupos) ...mapas.where((m) => m.grupo == g)];
  }

  Future<void> _mover(
    BuildContext context,
    List<ImagemDeMapa> doGrupo,
    int de,
    int para,
  ) async {
    final lista = [...doGrupo];
    final m = lista.removeAt(de);
    lista.insert(para, m);
    try {
      for (var i = 0; i < lista.length; i++) {
        if (lista[i].ordem != i * 10) {
          await servico.editarMapaGuardado(mesaId, lista[i].id, ordem: i * 10);
        }
      }
    } catch (e) {
      aoErro(e);
    }
  }

  Future<void> _editar(BuildContext context, ImagemDeMapa m) async {
    final nome = TextEditingController(text: m.nome);
    final grupo = TextEditingController(text: m.grupo);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Planta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('planta-nome'),
              controller: nome,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('planta-grupo'),
              controller: grupo,
              decoration: const InputDecoration(
                labelText: 'Grupo (opcional)',
                hintText: 'Ex.: Missão 3',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await servico.editarMapaGuardado(
        mesaId,
        m.id,
        nome: nome.text.trim().isEmpty ? m.nome : nome.text.trim(),
        grupo: grupo.text.trim(),
      );
    } catch (e) {
      aoErro(e);
    }
  }

  Future<void> _apagar(BuildContext context, ImagemDeMapa m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar esta planta?'),
        content: Text(
          '"${m.nome}" sai da biblioteca da mesa, com as posições das peças '
          'guardadas nela. Isso não pode ser desfeito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await servico.apagarMapaGuardado(mesaId, m.id);
    } catch (e) {
      aoErro(e);
    }
  }

  Future<void> _opcoes(
    BuildContext context,
    ImagemDeMapa m,
    List<ImagemDeMapa> doGrupo,
  ) async {
    final i = doGrupo.indexWhere((x) => x.id == m.id);
    final escolha = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Cores.carta,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                m.nome,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              key: const ValueKey('planta-editar'),
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Renomear / grupo'),
              onTap: () => Navigator.pop(ctx, 'editar'),
            ),
            if (i > 0)
              ListTile(
                leading: const Icon(Icons.arrow_back),
                title: const Text('Mover para a esquerda'),
                onTap: () => Navigator.pop(ctx, 'esq'),
              ),
            if (i >= 0 && i < doGrupo.length - 1)
              ListTile(
                leading: const Icon(Icons.arrow_forward),
                title: const Text('Mover para a direita'),
                onTap: () => Navigator.pop(ctx, 'dir'),
              ),
            if (m.id != atual)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Cores.sangue),
                title: const Text(
                  'Apagar planta',
                  style: TextStyle(color: Cores.sangue),
                ),
                onTap: () => Navigator.pop(ctx, 'apagar'),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (escolha) {
      case 'editar':
        await _editar(context, m);
      case 'esq':
        await _mover(context, doGrupo, i, i - 1);
      case 'dir':
        await _mover(context, doGrupo, i, i + 1);
      case 'apagar':
        await _apagar(context, m);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      color: Cores.carta,
      child: StreamBuilder<List<ImagemDeMapa>>(
        stream: servico.observarMapasGuardados(mesaId),
        builder: (context, snap) {
          final mapas = ordenar(snap.data ?? const []);
          final filhos = <Widget>[];
          String? grupoAnterior;
          for (final m in mapas) {
            if (m.grupo != grupoAnterior) {
              grupoAnterior = m.grupo;
              if (m.grupo.isNotEmpty) {
                filhos.add(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 4, 0),
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        m.grupo.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          color: Cores.conhecimento,
                        ),
                      ),
                    ),
                  ),
                );
              }
            }
            final doGrupo = mapas.where((x) => x.grupo == m.grupo).toList();
            final selecionado = m.id == atual;
            filhos.add(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  key: ValueKey('faixa-${m.id}'),
                  borderRadius: BorderRadius.circular(8),
                  // No mapa já aberto, tocar abre o menu; no PC, o
                  // botão direito também (mouse não faz toque longo).
                  onTap: selecionado
                      ? () => _opcoes(context, m, doGrupo)
                      : () => aoEscolher(m),
                  onLongPress: () => _opcoes(context, m, doGrupo),
                  onSecondaryTap: () => _opcoes(context, m, doGrupo),
                  child: SizedBox(
                    width: 96,
                    child: Column(
                      children: [
                        Container(
                          height: 60,
                          width: 96,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selecionado
                                  ? Cores.energiaViva
                                  : Cores.linha,
                              width: selecionado ? 3 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: m.miniaturaBase64.isEmpty
                              ? const Icon(Icons.map_outlined)
                              : Image.memory(
                                  base64Decode(m.miniaturaBase64),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.broken_image_outlined),
                                ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          m.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selecionado
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selecionado ? Cores.tinta : Cores.tinta2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          filhos.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                width: 72,
                child: OutlinedButton(
                  key: const ValueKey('faixa-subir'),
                  onPressed: aoSubir,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined),
                      SizedBox(height: 2),
                      Text('Nova', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          );
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            children: filhos,
          );
        },
      ),
    );
  }
}

/// A peça em si: retrato quando existe, inicial quando não.
class _PecaMapa extends StatelessWidget {
  final TokenMapa token;
  final double lado;

  /// É a vez dela na iniciativa: ganha um halo para ninguém procurar.
  final bool daVez;

  /// No mapa a etiqueta com o nome é essencial; nas listas o nome já está
  /// do lado, e repetir embaixo do círculo só suja.
  final bool comNome;

  const _PecaMapa({
    required this.token,
    required this.lado,
    this.comNome = true,
    this.daVez = false,
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
            border: Border.all(
              color: daVez ? Cores.energiaViva : cor,
              width: daVez ? 4 : 3,
            ),
            boxShadow: [
              const BoxShadow(
                color: Colors.black87,
                blurRadius: 6,
                spreadRadius: 1,
              ),
              if (daVez)
                BoxShadow(
                  color: Cores.energiaViva.withValues(alpha: .8),
                  blurRadius: 14,
                  spreadRadius: 4,
                ),
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
                      color: cor,
                    ),
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

  /// Jogador na própria peça: só o tamanho. Ameaça e remover são do mestre.
  final bool mestre;
  final Future<void> Function(TokenMapa) aoMudar;
  final VoidCallback aoRemover;

  const _FolhaDaPeca({
    required this.token,
    this.mestre = true,
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
                  child: Text(
                    _token.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tamanho da peça: ${(_token.escala * 100).round()}%',
              style: const TextStyle(fontSize: 12, color: Cores.tinta2),
            ),
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
            if (widget.mestre) ...[
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _token.inimigo,
                onChanged: (v) => _aplicar(
                  _token.copiar(
                    inimigo: v,
                    cor: corDaPeca(_token.nome, inimigo: v),
                  ),
                ),
                title: const Text(
                  'É ameaça (peça vermelha)',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.aoRemover,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Cores.sangue,
                  ),
                  label: const Text(
                    'Tirar do mapa',
                    style: TextStyle(color: Cores.sangue),
                  ),
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  'Esta é a sua peça: arraste no mapa para mover. A foto vem '
                  'da sua ficha publicada.',
                  style: TextStyle(fontSize: 12, color: Cores.tinta2),
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
              const Text(
                'Plantas desta mesa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
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
                  child: Text(
                    'Nenhuma planta guardada ainda.',
                    style: TextStyle(fontSize: 13, color: Cores.tinta2),
                  ),
                ),
              for (final p in plantas)
                ListTile(
                  dense: true,
                  leading: _Miniatura(base64: p.miniaturaBase64),
                  title: Text(
                    p.nome.isEmpty ? 'Sem nome' : p.nome,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: p.id == atual
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: p.id == atual
                      ? const Text(
                          'na mesa agora',
                          style: TextStyle(fontSize: 11, color: Cores.estavel),
                        )
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
      child: Image.memory(
        base64Decode(base64),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Quem está no mapa: fichas publicadas, NPCs do aparelho e peça avulsa.
class _FolhaPecas extends StatefulWidget {
  final MesaService servico;
  final String mesaId;
  final List<FichaNaMesa> fichas;
  final List<TokenMapa> tokens;
  final Future<void> Function(List<TokenMapa>) aoTrocar;

  const _FolhaPecas({
    required this.servico,
    required this.mesaId,
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
        _tokens.add(
          TokenMapa(
            id: f.donoUid,
            nome: f.nome.isEmpty ? 'Sem nome' : f.nome,
            retrato: ImagemMural.peca((f.ficha['retrato'] ?? '') as String),
            cor: corDaPeca(f.nome, inimigo: false),
            x: .5,
            y: .5,
          ),
        );
      }
    });
    _salvar();
  }

  /// NPC do bestiário vira peça com o brasão dele — o mesmo símbolo que
  /// aparece na lista de fichas.
  void _porNpc(String nome, String retrato) {
    setState(() {
      _tokens.add(
        TokenMapa(
          id: 'npc:${DateTime.now().microsecondsSinceEpoch}',
          nome: nome,
          retrato: ImagemMural.peca(retrato),
          cor: corDaPeca(nome, inimigo: true),
          x: .5,
          y: .5,
          inimigo: true,
        ),
      );
    });
    _salvar();
  }

  /// Imagem da galeria (Monstros ou NPCs) vira peça com a própria imagem.
  /// Monstro entra como ameaça; NPC, não.
  void _porDaGaleria(ItemGaleria item) {
    final ameaca = item.categoria == CategoriaGaleria.monstro;
    final nome = item.legenda.isEmpty ? item.categoria.singular : item.legenda;
    setState(() {
      _tokens.add(
        TokenMapa(
          id: 'npc:${DateTime.now().microsecondsSinceEpoch}',
          nome: nome,
          retrato: ImagemMural.peca(item.miniaturaBase64),
          cor: corDaPeca(nome, inimigo: ameaca),
          x: .5,
          y: .5,
          inimigo: ameaca,
        ),
      );
    });
    _salvar();
  }

  Widget _daGaleria() {
    return StreamBuilder<List<ItemGaleria>>(
      stream: widget.servico.observarGaleria(widget.mesaId),
      builder: (context, snap) {
        final itens = [
          for (final i in snap.data ?? const <ItemGaleria>[])
            if (i.categoria == CategoriaGaleria.monstro ||
                i.categoria == CategoriaGaleria.npc)
              i,
        ];
        if (itens.isEmpty) {
          return const Text(
            'Nenhuma imagem em Monstros ou NPCs na galeria.',
            style: TextStyle(fontSize: 12, color: Cores.tinta2),
          );
        }
        return SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final i in itens)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    key: ValueKey('galeria-peca-${i.id}'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _porDaGaleria(i),
                    child: SizedBox(
                      width: 64,
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: i.categoria == CategoriaGaleria.monstro
                                    ? Cores.sangue
                                    : Cores.linha,
                                width: 2,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.memory(
                              base64Decode(i.miniaturaBase64),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            i.legenda,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _escolherNpc() async {
    final npcs = FichaStore.todas().where((f) => f.ehNpc).toList();
    if (!mounted) return;
    if (npcs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nenhum NPC no aparelho. Importe o bestiário na '
            'aba Fichas.',
          ),
        ),
      );
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
              .where(
                (f) => filtro.isEmpty || f.nome.toLowerCase().contains(filtro),
              )
              .take(60)
              .toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Pôr NPC do bestiário',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
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
                      title: Text(f.nome, style: const TextStyle(fontSize: 13)),
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
      _tokens.add(
        TokenMapa(
          id: 'npc:${DateTime.now().microsecondsSinceEpoch}',
          nome: nome,
          cor: corDaPeca(nome, inimigo: _inimigo),
          x: .5,
          y: .5,
          inimigo: _inimigo,
        ),
      );
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
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Peças no mapa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Agente com ficha publicada entra com o retrato dele. Monstro '
              'e NPC da galeria entram com a imagem; do bestiário, com o '
              'brasão. Toque numa peça no mapa para mudar o tamanho.',
              style: TextStyle(fontSize: 12, color: Cores.tinta2),
            ),
            const SizedBox(height: 12),
            if (widget.fichas.isEmpty)
              const Text(
                'Ninguém publicou ficha nesta mesa ainda.',
                style: TextStyle(fontSize: 13, color: Cores.tinta2),
              ),
            for (final f in widget.fichas)
              CheckboxListTile(
                dense: true,
                value: _tokens.any((t) => t.id == f.donoUid),
                onChanged: (_) => _alternarFicha(f),
                title: Text(f.nome.isEmpty ? 'Sem nome' : f.nome),
              ),
            const Divider(height: 24),
            const Text(
              'Da galeria (Monstros e NPCs)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            _daGaleria(),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _escolherNpc,
                icon: const Icon(Icons.pest_control_outlined, size: 16),
                label: const Text('Pôr NPC do bestiário'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Peça avulsa (marcador, porta, refém…)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nome,
                    decoration: const InputDecoration(
                      labelText: 'Nome da peça',
                      isDense: true,
                    ),
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
              title: const Text(
                'É ameaça (peça vermelha)',
                style: TextStyle(fontSize: 13),
              ),
            ),
            if (_tokens.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'No mapa agora',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              for (final t in _tokens)
                ListTile(
                  dense: true,
                  leading: _PecaMapa(token: t, lado: 28, comNome: false),
                  title: Text(t.nome, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    'tamanho ${(t.escala * 100).round()}%',
                    style: const TextStyle(fontSize: 11),
                  ),
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

/// A linha da régua, com as pontas e o rótulo no meio.
class _PintorRegua extends CustomPainter {
  final Offset? de;
  final Offset? ate;
  final String? rotulo;
  final bool calibrando;

  _PintorRegua({
    required this.de,
    required this.ate,
    required this.rotulo,
    required this.calibrando,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final a = de;
    final b = ate;
    if (a == null || b == null) return;
    final pa = Offset(a.dx * size.width, a.dy * size.height);
    final pb = Offset(b.dx * size.width, b.dy * size.height);
    final cor = calibrando ? Cores.conhecimento : Cores.energiaViva;
    final linha = Paint()
      ..color = cor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      pa,
      pb,
      Paint()
        ..color = Colors.black54
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(pa, pb, linha);
    canvas.drawCircle(pa, 5, Paint()..color = cor);
    canvas.drawCircle(pb, 5, Paint()..color = cor);
    final texto = rotulo;
    if (texto == null || (pb - pa).distance < 4) return;
    final pintor = TextPainter(
      text: TextSpan(
        text: texto,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    var centro = Offset.lerp(pa, pb, .5)! - const Offset(0, 22);
    final meia = Offset(pintor.width / 2 + 8, pintor.height / 2 + 4);
    centro = Offset(
      centro.dx.clamp(meia.dx, size.width - meia.dx),
      centro.dy.clamp(meia.dy, size.height - meia.dy),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: centro,
          width: pintor.width + 16,
          height: pintor.height + 8,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.black.withValues(alpha: .8),
    );
    pintor.paint(canvas, centro - Offset(pintor.width / 2, pintor.height / 2));
  }

  @override
  bool shouldRepaint(_PintorRegua velho) =>
      velho.de != de ||
      velho.ate != ate ||
      velho.rotulo != rotulo ||
      velho.calibrando != calibrando;
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
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Cores.tinta2),
            ),
          ],
        ),
      ),
    );
  }
}
