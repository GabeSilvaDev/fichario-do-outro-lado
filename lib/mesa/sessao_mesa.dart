import 'dart:async';

import '../store/ficha_store.dart';
import 'espelho_ficha.dart';
import 'mesa_service.dart';
import 'mesa_store.dart';
import 'ponte_rolagens.dart';

/// O que precisa ficar ligado o tempo todo enquanto o aparelho está numa
/// mesa, em qualquer tela: o espelho da ficha publicada e o batimento de
/// presença.
///
/// Antes os dois moravam na aba Mesa e morriam ao trocar de aba — e a ficha
/// só se edita na aba Fichas. O mestre via a ficha congelada no momento da
/// publicação. Aqui eles seguem o estado salvo em [MesaStore], como o mural
/// e o mapa: entrou, publicou, saiu — a sessão acompanha sozinha.
class SessaoMesa {
  static MesaService get _servico => PonteRolagens.servico;

  static bool _iniciada = false;
  static String? _mesaId;
  static String? _fichaId;
  static EspelhoFicha? _espelho;
  static Timer? _ponto;
  static Timer? _novaTentativa;

  static const Duration intervaloPonto = Duration(seconds: 30);

  /// Chamado uma vez, na tela principal.
  static void iniciar() {
    if (_iniciada) return;
    _iniciada = true;
    MesaStore.listenable.addListener(reconciliar);
    reconciliar();
  }

  /// Confere o estado salvo e liga, troca ou desliga o que for preciso.
  /// Pode ser chamado à vontade: sem mudança, não faz nada.
  static Future<void> reconciliar() async {
    final estado = MesaStore.atual;
    if (estado == null) {
      _pararTudo();
      return;
    }

    if (_mesaId != estado.mesaId) {
      _pararTudo();
      try {
        await _servico.entrarAnonimo();
      } catch (_) {
        // Sem rede ao abrir: tenta de novo daqui a pouco.
        _novaTentativa?.cancel();
        _novaTentativa = Timer(intervaloPonto, reconciliar);
        return;
      }
      if (MesaStore.atual?.mesaId != estado.mesaId) return;
      _mesaId = estado.mesaId;
      _baterPonto();
      _ponto = Timer.periodic(intervaloPonto, (_) => _baterPonto());
    }

    final fichaId = MesaStore.atual?.fichaPublicadaId;
    if (fichaId == _fichaId) return;
    _desligarEspelho();
    _fichaId = fichaId;
    if (fichaId == null) return;
    final espelho = EspelhoFicha(_servico)..ligar(estado.mesaId, fichaId);
    _espelho = espelho;
    FichaStore.observador = espelho.aoSalvar;
    // O que mudou enquanto nada espelhava (app fechado, sem rede) sobe já.
    final atual = FichaStore.porId(fichaId);
    if (atual != null) espelho.aoSalvar(atual);
  }

  static void _baterPonto() {
    final mesaId = _mesaId;
    if (mesaId == null) return;
    _servico.baterPonto(mesaId).catchError((_) {});
  }

  static void _desligarEspelho() {
    FichaStore.observador = null;
    _espelho?.desligar();
    _espelho = null;
    _fichaId = null;
  }

  static void _pararTudo() {
    _novaTentativa?.cancel();
    _novaTentativa = null;
    _ponto?.cancel();
    _ponto = null;
    _mesaId = null;
    _desligarEspelho();
  }

  /// Para já tudo (antes de sair da mesa, para nenhuma escrita atrasada
  /// cair numa mesa que o aparelho acabou de deixar).
  static void parar() => _pararTudo();

  /// Para só o espelho (antes de tirar a ficha da mesa).
  static void pararEspelho() => _desligarEspelho();

  /// Para os testes: esquece tudo sem depender do Hive.
  static void reiniciarParaTeste() {
    _pararTudo();
    if (_iniciada) MesaStore.listenable.removeListener(reconciliar);
    _iniciada = false;
  }
}
