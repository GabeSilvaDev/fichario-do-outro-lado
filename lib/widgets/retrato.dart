import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../theme.dart';

/// O retrato do personagem, redondo. `base64` vazio mostra o ícone padrão.
class RetratoAvatar extends StatelessWidget {
  final String base64;
  final double tamanho;

  const RetratoAvatar({super.key, required this.base64, this.tamanho = 44});

  @override
  Widget build(BuildContext context) {
    Widget miolo =
        Icon(Icons.person_outline, color: Cores.tinta2, size: tamanho * .55);
    if (base64.isNotEmpty) {
      try {
        miolo = ClipOval(
          child: Image.memory(base64Decode(base64),
              width: tamanho, height: tamanho, fit: BoxFit.cover),
        );
      } catch (_) {
        // base64 estragado não derruba a tela
      }
    }
    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Cores.carta2,
        border: Border.all(color: Cores.energia, width: 1.5),
      ),
      child: miolo,
    );
  }
}

/// Abre o seletor de arquivo e devolve a imagem já pequena (jpeg ~256px) em
/// base64, pronta para morar dentro da ficha. Null se cancelar ou falhar.
Future<String?> escolherRetrato() async {
  final escolha = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  final bytes = escolha?.files.single.bytes;
  if (bytes == null) return null;
  try {
    final original = img.decodeImage(bytes);
    if (original == null) return null;
    final pequena = original.width > 256
        ? img.copyResize(original,
            width: 256, interpolation: img.Interpolation.average)
        : original;
    return base64Encode(img.encodeJpg(pequena, quality: 70));
  } catch (_) {
    return null;
  }
}
