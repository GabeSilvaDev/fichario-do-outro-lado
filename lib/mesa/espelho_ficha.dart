import 'dart:async';

import '../models/ficha_op.dart';
import 'mesa_service.dart';

/// Manda para a mesa a ficha que o jogador publicou, agrupando as escritas.
///
/// O app salva a cada toque num contador. Espelhar toque a toque seria uma
/// escrita por toque; a janela junta a rajada e envia só o estado final —
/// é o que faz o mestre ver "em segundos" sem estourar cota do Firestore.
class EspelhoFicha {
  static const Duration janelaPadrao = Duration(seconds: 2);

  final MesaService _servico;
  final Duration janela;

  String? _mesaId;
  String? _fichaId;
  FichaOP? _pendente;
  Timer? _timer;

  EspelhoFicha(this._servico, {this.janela = janelaPadrao});

  bool get ligado => _mesaId != null;

  String? get fichaId => _fichaId;

  void ligar(String mesaId, String fichaId) {
    _mesaId = mesaId;
    _fichaId = fichaId;
  }

  void desligar() {
    _timer?.cancel();
    _timer = null;
    _pendente = null;
    _mesaId = null;
    _fichaId = null;
  }

  /// Chamado a cada `FichaStore.salvar`.
  void aoSalvar(FichaOP f) {
    if (!ligado || f.id != _fichaId) return;
    _pendente = f;
    _timer ??= Timer(janela, () {
      _timer = null;
      enviarAgora();
    });
  }

  /// Envia o que estiver pendente sem esperar a janela (ao sair da tela).
  Future<void> enviarAgora() async {
    final f = _pendente;
    final mesaId = _mesaId;
    if (f == null || mesaId == null) return;
    _pendente = null;
    await _servico.publicarFicha(
      mesaId,
      f.dados,
      f.nome.isEmpty ? 'Sem nome' : f.nome,
    );
  }
}
