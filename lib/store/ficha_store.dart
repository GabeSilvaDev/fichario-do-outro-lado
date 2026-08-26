import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/ficha_op.dart';

/// Fichas no aparelho. A verdade mora aqui; a mesa online recebe cópias.
class FichaStore {
  static const String boxName = 'fichas_op';

  /// Chamado a cada salvar — é como o espelho da mesa fica sabendo.
  static void Function(FichaOP)? observador;

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(boxName);
  }

  static Box<String> get _box => Hive.box<String>(boxName);

  static ValueListenable<Box<String>> get listenable => _box.listenable();

  static List<FichaOP> todas() {
    final fichas = <FichaOP>[];
    for (final chave in _box.keys) {
      final s = _box.get(chave);
      if (s == null) continue;
      try {
        fichas.add(FichaOP(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // uma ficha corrompida não derruba a lista inteira
      }
    }
    fichas.sort((a, b) =>
        a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return fichas;
  }

  static FichaOP? porId(String id) {
    final s = _box.get(id);
    if (s == null) return null;
    try {
      return FichaOP(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> salvar(FichaOP f) async {
    await _box.put(f.id, jsonEncode(f.dados));
    observador?.call(f);
  }

  static Future<void> excluir(String id) async => _box.delete(id);
}
