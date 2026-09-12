import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../widgets/visualizador_imagem.dart';
import '../imagem_mural.dart';
import '../mesa_service.dart';

/// O mural da mesa, do jeito que cada um vê.
///
/// A imagem abre sozinha quando o mestre a põe, mas quem fechou precisa poder
/// voltar a ela quando quiser: enquanto estiver no mural, fica aqui para
/// reabrir quantas vezes for. Só o mestre põe e tira ([souMestre]).
class MuralDaMesa extends StatefulWidget {
  final MesaService servico;
  final String mesaId;
  final bool souMestre;

  const MuralDaMesa({
    super.key,
    required this.servico,
    required this.mesaId,
    required this.souMestre,
  });

  @override
  State<MuralDaMesa> createState() => _MuralDaMesaState();
}

class _MuralDaMesaState extends State<MuralDaMesa> {
  MesaService get servico => widget.servico;
  String get mesaId => widget.mesaId;

  /// Reduzir uma foto grande e subir leva alguns segundos: sem retorno
  /// visual o mestre toca de novo e manda a mesma imagem duas vezes.
  bool _enviando = false;

  void _erro(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
  }

  Future<void> _mostrarImagem() async {
    if (_enviando) return;
    final escolha = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = escolha?.files.single.bytes;
    if (bytes == null || !mounted) return;

    final resultado = await _pedirLegenda();
    if (resultado == null || !mounted) return;
    final (legenda, mostrarAgora) = resultado;

    setState(() => _enviando = true);
    try {
      final imagemId = await servico.guardarNaGaleria(
        mesaId,
        ImagemMural.preparar(bytes),
        ImagemMural.miniatura(bytes),
        legenda,
      );
      if (mostrarAgora) await servico.mostrarAgora(mesaId, imagemId);
    } catch (e) {
      _erro(e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  /// null quando cancela. Do contrário, a legenda e se é para pôr em
  /// destaque agora ou só guardar no acervo.
  Future<(String, bool)?> _pedirLegenda() {
    final campo = TextEditingController();
    return showDialog<(String, bool)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Legenda (opcional)'),
        content: TextField(
          controller: campo,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Ex.: a pista que vocês acham na cena'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, (campo.text.trim(), false)),
            child: const Text('Guardar na galeria'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, (campo.text.trim(), true)),
            child: const Text('Mostrar agora'),
          ),
        ],
      ),
    );
  }

  Future<void> _tirar() async {
    try {
      await servico.limparMural(mesaId);
    } catch (e) {
      _erro(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ItemMural?>(
      stream: servico.observarMural(mesaId),
      builder: (context, snap) {
        if (_enviando) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final item = snap.data;
        if (item == null) return _vazio();
        return _CartaoDestaque(
          key: ValueKey(item.imagemId),
          servico: servico,
          mesaId: mesaId,
          imagemId: item.imagemId,
          legenda: item.legenda,
          souMestre: widget.souMestre,
          aoTirar: _tirar,
        );
      },
    );
  }

  Widget _vazio() {
    if (!widget.souMestre) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'O mestre ainda não mostrou nenhuma imagem. Quando mostrar, ela '
            'abre sozinha aqui — e continua nesta tela para você olhar de '
            'novo quando quiser.',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A imagem abre em tela cheia no aparelho de todo mundo que '
              'está na mesa, e fica disponível aqui até você tirar.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _mostrarImagem,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Mostrar imagem para a mesa'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A imagem em destaque, sozinha: busca a imagem cheia uma vez em
/// `initState`; a `key: ValueKey(imagemId)` do pai garante que uma imagem
/// nova recria este estado.
class _CartaoDestaque extends StatefulWidget {
  final MesaService servico;
  final String mesaId;
  final String imagemId;
  final String legenda;
  final bool souMestre;
  final VoidCallback aoTirar;

  const _CartaoDestaque({
    super.key,
    required this.servico,
    required this.mesaId,
    required this.imagemId,
    required this.legenda,
    required this.souMestre,
    required this.aoTirar,
  });

  @override
  State<_CartaoDestaque> createState() => _CartaoDestaqueState();
}

class _CartaoDestaqueState extends State<_CartaoDestaque> {
  late final Future<String?> _futuro =
      widget.servico.imagemCheia(widget.mesaId, widget.imagemId);

  void _abrirTelaCheia(String imagemBase64) {
    VisualizadorImagem.abrir(
        context, base64Decode(imagemBase64), widget.legenda);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snap.hasError) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                  'Não consegui carregar a imagem. Confira sua conexão.'),
            ),
          );
        }
        final imagemBase64 = snap.data;
        if (imagemBase64 == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('Imagem não encontrada.'),
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                InkWell(
                  onTap: () => _abrirTelaCheia(imagemBase64),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      base64Decode(imagemBase64),
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        height: 120,
                        child: Icon(Icons.broken_image_outlined, size: 40),
                      ),
                    ),
                  ),
                ),
                if (widget.legenda.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(widget.legenda,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () => _abrirTelaCheia(imagemBase64),
                      icon: const Icon(Icons.open_in_full, size: 18),
                      label: const Text('Ver em tela cheia'),
                    ),
                    if (widget.souMestre)
                      TextButton.icon(
                        onPressed: widget.aoTirar,
                        icon: const Icon(Icons.visibility_off_outlined,
                            size: 18),
                        label: const Text('Tirar do mural'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
