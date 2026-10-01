import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Imagem em tela cheia, com zoom e legenda. Toque fora fecha.
class VisualizadorImagem extends StatelessWidget {
  final Uint8List bytes;
  final String legenda;

  const VisualizadorImagem({super.key, required this.bytes, this.legenda = ''});

  static void abrir(BuildContext context, Uint8List bytes, String legenda) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisualizadorImagem(bytes: bytes, legenda: legenda),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Esc fecha, como em qualquer visualizador de imagem no computador.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(autofocus: true, child: _tela(context)),
    );
  }

  Widget _tela(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 6,
                child: Center(
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ),
            ),
            if (legenda.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  child: Text(
                    legenda,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
