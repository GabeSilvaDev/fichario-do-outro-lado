import '../models/rolagem.dart';
import 'firebase_app.dart';
import 'mesa_firestore.dart';
import 'mesa_service.dart';
import 'mesa_store.dart';

/// Liga o motor de dados à mesa: toda rolagem feita numa ficha aparece no
/// feed da mesa — se o aparelho estiver numa mesa. Fora de mesa, nada de
/// rede acontece e a rolagem continua só local.
class PonteRolagens {
  static MesaService servico = MesaFirestore();

  /// Publica sem travar a interface: falha de rede não pode impedir o
  /// jogador de ver o próprio dado — o resultado local já está na tela.
  static void publicar(ResultadoRolagem r, String nomePersonagem) {
    final estado = MesaStore.atual;
    if (estado == null || !FirebaseApp.pronto) return;
    final uid = servico.uid;
    if (uid == null) return;
    servico
        .publicarRolagem(
          estado.mesaId,
          RolagemNaMesa(
            id: '',
            porUid: uid,
            porNome: nomePersonagem,
            titulo: r.titulo,
            formula: r.formula,
            detalhe: r.detalhe,
            total: r.total,
            critico: r.critico,
            desastre: r.desastre,
            em: DateTime.now(),
          ),
        )
        .catchError((_) {});
  }
}
