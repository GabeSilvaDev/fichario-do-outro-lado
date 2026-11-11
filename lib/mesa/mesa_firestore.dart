import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:async';

import 'chave_mesa.dart';
import 'codigo.dart';
import 'firebase_app.dart';
import 'imagem_mural.dart';
import 'mesa_service.dart';
import 'modelos.dart';

/// Mesa online de verdade.
///
/// Espelha, chamada por chamada, o que `MesaFake` faz em memória — e o que as
/// regras de segurança (`firestore.rules`) permitem. Se os três divergirem, os
/// testes passam a mentir sobre o comportamento real.
class MesaFirestore implements MesaService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  String? get uid =>
      FirebaseApp.pronto ? FirebaseAuth.instance.currentUser?.uid : null;

  @override
  Future<String> entrarAnonimo() async {
    await FirebaseApp.garantir();
    final atual = FirebaseAuth.instance.currentUser;
    if (atual != null) return atual.uid;
    final cred = await FirebaseAuth.instance.signInAnonymously();
    return cred.user!.uid;
  }

  DocumentReference<Map<String, dynamic>> _mesa(String id) =>
      _db.collection('mesas').doc(id);

  @override
  Future<(Mesa, String)> criarMesa(String nome, String meuNome) async {
    final meuUid = await entrarAnonimo();
    final agora = DateTime.now();

    final ref = _db.collection('mesas').doc();
    var codigo = CodigoMesa.gerar();
    await ref.set({
      'nome': nome,
      'codigo': codigo,
      'mestreUid': meuUid,
      'criadaEm': agora.toIso8601String(),
    });

    for (var tentativa = 0; tentativa < 5; tentativa++) {
      final doc = _db.collection('codigos').doc(codigo);
      if (!(await doc.get()).exists) {
        await doc.set({'mesaId': ref.id});
        break;
      }
      codigo = CodigoMesa.gerar();
      await ref.update({'codigo': codigo});
    }

    await ref.collection('membros').doc(meuUid).set({
      'nome': meuNome,
      'papel': 'mestre',
      'entrouEm': agora.toIso8601String(),
      'visto': agora.toIso8601String(),
    });

    final chave = ChaveMesa.gerar();
    await ref.collection('privado').doc('chave').set({'chave': chave});

    return (
      Mesa(
        id: ref.id,
        nome: nome,
        codigo: codigo,
        mestreUid: meuUid,
        criadaEm: agora,
      ),
      chave,
    );
  }

  @override
  Future<Mesa> entrarPorCodigo(String codigo, String meuNome) async {
    final meuUid = await entrarAnonimo();
    final alvo = CodigoMesa.normalizar(codigo);

    final atalho = await _db.collection('codigos').doc(alvo).get();
    if (!atalho.exists) throw MesaNaoEncontrada();
    final mesaId = atalho.data()!['mesaId'] as String;

    final membros = _mesa(mesaId).collection('membros').doc(meuUid);
    final agora = DateTime.now();

    try {
      final jaEra = await membros.get();
      final papelProvisorio = (jaEra.data()?['papel'] as String?) ?? 'jogador';

      await membros.set({
        'nome': meuNome,
        'papel': papelProvisorio,
        'entrouEm':
            (jaEra.data()?['entrouEm'] as String?) ?? agora.toIso8601String(),
        'visto': agora.toIso8601String(),
      });

      final doc = await _mesa(mesaId).get();
      if (!doc.exists) throw MesaNaoEncontrada();
      final mesa = Mesa.fromJson(mesaId, doc.data()!);

      final papelCerto = mesa.mestreUid == meuUid ? 'mestre' : 'jogador';
      if (papelCerto != papelProvisorio) {
        await membros.update({'papel': papelCerto});
      }
      return mesa;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw MesaNaoEncontrada();
      rethrow;
    }
  }

  @override
  Future<Mesa> entrarPorId(String mesaId, String meuNome) async {
    final meuUid = await entrarAnonimo();
    final membros = _mesa(mesaId).collection('membros').doc(meuUid);
    final agora = DateTime.now();

    try {
      final jaEra = await membros.get();
      final papelProvisorio = (jaEra.data()?['papel'] as String?) ?? 'jogador';

      await membros.set({
        'nome': meuNome,
        'papel': papelProvisorio,
        'entrouEm':
            (jaEra.data()?['entrouEm'] as String?) ?? agora.toIso8601String(),
        'visto': agora.toIso8601String(),
      });

      final doc = await _mesa(mesaId).get();
      if (!doc.exists) throw MesaNaoEncontrada();
      final mesa = Mesa.fromJson(mesaId, doc.data()!);

      final papelCerto = mesa.mestreUid == meuUid ? 'mestre' : 'jogador';
      if (papelCerto != papelProvisorio) {
        await membros.update({'papel': papelCerto});
      }
      return mesa;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw MesaNaoEncontrada();
      rethrow;
    }
  }

  @override
  Future<Mesa> reassumirMesa(
    String codigo,
    String chave,
    String meuNome,
  ) async {
    final meuUid = await entrarAnonimo();
    final alvo = CodigoMesa.normalizar(codigo);
    final atalho = await _db.collection('codigos').doc(alvo).get();
    if (!atalho.exists) throw MesaNaoEncontrada();
    final mesaId = atalho.data()!['mesaId'] as String;

    try {
      await _mesa(mesaId).collection('privado').doc('pedido').set({
        'chave': ChaveMesa.normalizar(chave),
        'uid': meuUid,
      });
      await _mesa(mesaId).update({'mestreUid': meuUid});
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw ChaveErrada();
      rethrow;
    }

    try {
      await _mesa(mesaId).collection('privado').doc('pedido').delete();
    } catch (_) {}

    await _mesa(mesaId).collection('membros').doc(meuUid).set({
      'nome': meuNome,
      'papel': 'mestre',
      'entrouEm': DateTime.now().toIso8601String(),
      'visto': DateTime.now().toIso8601String(),
    });

    final doc = await _mesa(mesaId).get();
    if (!doc.exists) throw MesaNaoEncontrada();
    return Mesa.fromJson(mesaId, doc.data()!);
  }

  @override
  Future<void> publicarFicha(
    String mesaId,
    Map<String, dynamic> ficha,
    String nome,
  ) async {
    final meuUid = uid;
    if (meuUid == null) throw SemPermissao();
    await _mesa(mesaId).collection('fichas').doc(meuUid).set({
      'dono': meuUid,
      'nome': nome,
      'atualizadaEm': DateTime.now().toIso8601String(),
      'ficha': ficha,
    });
    // Publicou: a peça dele entra no mapa (ou acompanha nome e foto).
    try {
      await sincronizarMinhaPeca(mesaId, nome, '${ficha['retrato'] ?? ''}');
    } catch (_) {}
  }

  @override
  Future<void> despublicarFicha(String mesaId) async {
    final meuUid = uid;
    if (meuUid == null) return;
    await _mesa(mesaId).collection('fichas').doc(meuUid).delete();
    // Sem ficha na mesa, sem peça no mapa.
    _pecaSincronizada.remove(mesaId);
    try {
      await _pecas(mesaId).doc(meuUid).delete();
    } catch (_) {}
  }

  @override
  Stream<List<FichaNaMesa>> observarFichas(String mesaId) => _mesa(mesaId)
      .collection('fichas')
      .snapshots()
      .map(
        (q) => q.docs.map((d) => FichaNaMesa.fromJson(d.id, d.data())).toList(),
      );

  @override
  Stream<FichaNaMesa?> observarFicha(String mesaId, String donoUid) =>
      _mesa(mesaId)
          .collection('fichas')
          .doc(donoUid)
          .snapshots()
          .map((d) => d.exists ? FichaNaMesa.fromJson(d.id, d.data()!) : null);

  CollectionReference<Map<String, dynamic>> _rolagens(String mesaId) =>
      _mesa(mesaId).collection('rolagens');

  @override
  Future<void> publicarRolagem(String mesaId, RolagemNaMesa rolagem) async {
    final meuUid = uid;
    if (meuUid == null) return;
    final dados = rolagem.toJson()..['porUid'] = meuUid;
    await _rolagens(mesaId).add(dados);
  }

  @override
  Stream<List<RolagemNaMesa>> observarRolagens(
    String mesaId, {
    int limite = 30,
  }) => _rolagens(mesaId)
      .orderBy('em', descending: true)
      .limit(limite)
      .snapshots()
      .map(
        (q) =>
            q.docs.map((d) => RolagemNaMesa.fromJson(d.id, d.data())).toList(),
      );

  DocumentReference<Map<String, dynamic>> _mural(String mesaId) =>
      _mesa(mesaId).collection('mural').doc('atual');

  CollectionReference<Map<String, dynamic>> _galeria(String mesaId) =>
      _mesa(mesaId).collection('galeria');

  CollectionReference<Map<String, dynamic>> _imagens(String mesaId) =>
      _mesa(mesaId).collection('imagens');

  DocumentReference<Map<String, dynamic>> _mapa(String mesaId) =>
      _mesa(mesaId).collection('mapa').doc('atual');

  /// Uma peça por documento (`mapa/atual/pecas/{id}`): é o que deixa a regra
  /// do Firestore dar a cada jogador só a peça dele. A peça do agente tem o
  /// uid do dono como id.
  CollectionReference<Map<String, dynamic>> _pecas(String mesaId) =>
      _mapa(mesaId).collection('pecas');

  Future<void> _apagarPecas(String mesaId) async {
    final docs = await _pecas(mesaId).get();
    for (final d in docs.docs) {
      await d.reference.delete();
    }
  }

  /// Última peça sincronizada por mesa (nome + retrato), para a publicação
  /// da ficha — que roda a cada 2 s enquanto o jogador mexe — não gastar
  /// leitura à toa.
  final Map<String, String> _pecaSincronizada = {};

  /// A biblioteca de plantas: separada da galeria do mural de propósito —
  /// mapa não é imagem para abrir na cara de ninguém.
  CollectionReference<Map<String, dynamic>> _mapas(String mesaId) =>
      _mesa(mesaId).collection('mapas');

  CollectionReference<Map<String, dynamic>> _mapasImagens(String mesaId) =>
      _mesa(mesaId).collection('mapasImagens');

  @override
  Future<String> guardarNaGaleria(
    String mesaId,
    String imagemBase64,
    String miniaturaBase64,
    String legenda,
  ) async {
    final meuUid = uid;
    if (meuUid == null) throw SemPermissao();
    final ref = _galeria(mesaId).doc();
    try {
      await _imagens(mesaId).doc(ref.id).set({'imagem': imagemBase64});
      await ref.set(
        ItemGaleria(
          id: ref.id,
          legenda: legenda,
          porUid: meuUid,
          miniaturaBase64: miniaturaBase64,
          em: DateTime.now(),
        ).toJson(),
      );
      return ref.id;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw SemPermissao();
      rethrow;
    }
  }

  @override
  Future<void> apagarDaGaleria(String mesaId, String imagemId) async {
    try {
      await _imagens(mesaId).doc(imagemId).delete();
      await _galeria(mesaId).doc(imagemId).delete();
      final atual = await _mural(mesaId).get();
      if (atual.exists && atual.data()!['imagemId'] == imagemId) {
        await _mural(mesaId).delete();
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw SemPermissao();
      rethrow;
    }
  }

  @override
  Stream<List<ItemGaleria>> observarGaleria(String mesaId) => _galeria(mesaId)
      .orderBy('em', descending: true)
      .snapshots()
      .map(
        (q) => q.docs.map((d) => ItemGaleria.fromJson(d.id, d.data())).toList(),
      );

  @override
  Future<String?> imagemCheia(String mesaId, String imagemId) async {
    final doc = await _imagens(mesaId).doc(imagemId).get();
    if (!doc.exists) return null;
    return doc.data()!['imagem'] as String?;
  }

  @override
  Future<void> mostrarAgora(String mesaId, String imagemId) async {
    try {
      final item = await _galeria(mesaId).doc(imagemId).get();
      final legenda = item.exists
          ? (item.data()!['legenda'] ?? '') as String
          : '';
      await _mural(mesaId).set(
        ItemMural(
          imagemId: imagemId,
          legenda: legenda,
          em: DateTime.now(),
        ).toJson(),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw SemPermissao();
      rethrow;
    }
  }

  @override
  Future<void> limparMural(String mesaId) async {
    try {
      await _mural(mesaId).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw SemPermissao();
      rethrow;
    }
  }

  @override
  Stream<ItemMural?> observarMural(String mesaId) => _mural(
    mesaId,
  ).snapshots().map((d) => d.exists ? ItemMural.fromJson(d.data()!) : null);

  @override
  Stream<Mesa?> observarMesa(String mesaId) => _mesa(
    mesaId,
  ).snapshots().map((d) => d.exists ? Mesa.fromJson(mesaId, d.data()!) : null);

  @override
  Stream<List<Membro>> observarMembros(String mesaId) => _mesa(mesaId)
      .collection('membros')
      .snapshots()
      .map((q) => q.docs.map((d) => Membro.fromJson(d.id, d.data())).toList());

  @override
  Future<void> baterPonto(String mesaId) async {
    final meuUid = uid;
    if (meuUid == null) return;
    await _mesa(mesaId).collection('membros').doc(meuUid).update({
      'visto': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> sair(String mesaId) async {
    final meuUid = uid;
    if (meuUid == null) return;
    await despublicarFicha(mesaId);
    await _mesa(mesaId).collection('membros').doc(meuUid).delete();
  }

  @override
  Future<void> removerMembro(String mesaId, String alvo) async {
    try {
      await _mesa(mesaId).collection('membros').doc(alvo).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw SemPermissao();
      rethrow;
    }
  }

  @override
  Future<void> trocarCodigo(String mesaId) async {
    final doc = await _mesa(mesaId).get();
    if (!doc.exists) throw MesaNaoEncontrada();
    final antigo = doc.data()!['codigo'] as String;
    final novo = CodigoMesa.gerar();
    try {
      await _db.collection('codigos').doc(novo).set({'mesaId': mesaId});
      await _mesa(mesaId).update({'codigo': novo});
      await _db.collection('codigos').doc(antigo).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw SemPermissao();
      rethrow;
    }
  }

  @override
  Future<void> encerrarSessao(String mesaId) async {
    try {
      for (final c in ['fichas', 'rolagens', 'membros']) {
        final docs = await _mesa(mesaId).collection(c).get();
        for (final d in docs.docs) {
          await d.reference.delete();
        }
      }
      await _apagarPecas(mesaId);
      await _mapa(mesaId).delete();
      // Senão a imagem da sessão passada pula na tela de todos na próxima.
      await _mural(mesaId).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw SemPermissao();
      rethrow;
    }
  }

  @override
  Future<void> apagarMesa(String mesaId) async {
    final doc = await _mesa(mesaId).get();
    if (!doc.exists) return;
    final codigo = doc.data()!['codigo'] as String;
    try {
      for (final c in [
        'galeria',
        'imagens',
        'mapas',
        'mapasImagens',
        'fichas',
        'rolagens',
        'membros',
      ]) {
        final docs = await _mesa(mesaId).collection(c).get();
        for (final d in docs.docs) {
          await d.reference.delete();
        }
      }
      await _mesa(mesaId).collection('privado').doc('chave').delete();
      await _mesa(mesaId).collection('privado').doc('pedido').delete();
      await _mural(mesaId).delete();
      await _apagarPecas(mesaId);
      await _mapa(mesaId).delete();
      await _db.collection('codigos').doc(codigo).delete();
      await _mesa(mesaId).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw SemPermissao();
      rethrow;
    }
  }

  @override
  Future<String> guardarMapa(
    String mesaId,
    String imagemBase64,
    String miniaturaBase64,
    String nome,
  ) async {
    final ref = _mapas(mesaId).doc();
    try {
      await _mapasImagens(mesaId).doc(ref.id).set({'imagem': imagemBase64});
      await ref.set(
        ImagemDeMapa(
          id: ref.id,
          nome: nome,
          miniaturaBase64: miniaturaBase64,
          em: DateTime.now(),
        ).toJson(),
      );
      return ref.id;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw SemPermissao();
      rethrow;
    }
  }

  @override
  Stream<List<ImagemDeMapa>> observarMapasGuardados(String mesaId) =>
      _mapas(mesaId).snapshots().map((q) {
        final itens =
            q.docs.map((d) => ImagemDeMapa.fromJson(d.id, d.data())).toList()
              ..sort((a, b) => b.em.compareTo(a.em));
        return itens;
      });

  @override
  Future<String?> imagemDeMapa(String mesaId, String imagemId) async {
    final doc = await _mapasImagens(mesaId).doc(imagemId).get();
    if (doc.exists) return doc.data()!['imagem'] as String?;
    return imagemCheia(mesaId, imagemId);
  }

  @override
  Future<void> apagarMapaGuardado(String mesaId, String imagemId) async {
    try {
      await _mapasImagens(mesaId).doc(imagemId).delete();
      await _mapas(mesaId).doc(imagemId).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw SemPermissao();
      rethrow;
    }
  }

  @override
  Future<void> abrirMapa(
    String mesaId,
    String imagemId,
    String titulo,
    List<TokenMapa> tokens,
  ) async {
    try {
      await _mapa(mesaId).set({
        'imagemId': imagemId,
        'titulo': titulo,
        'em': DateTime.now().toIso8601String(),
      });
      await salvarTokens(mesaId, tokens);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw SemPermissao();
      rethrow;
    }
  }

  @override
  Future<void> salvarTokens(String mesaId, List<TokenMapa> tokens) async {
    try {
      final atuais = await _pecas(mesaId).get();
      final lote = _db.batch();
      final ids = {for (final t in tokens) t.id};
      for (final d in atuais.docs) {
        if (!ids.contains(d.id)) lote.delete(d.reference);
      }
      for (final t in tokens) {
        lote.set(_pecas(mesaId).doc(t.id), t.toJson());
      }
      // Mapa do formato antigo (peças dentro do documento): migra.
      lote.update(_mapa(mesaId), {
        'tokens': FieldValue.delete(),
        'em': DateTime.now().toIso8601String(),
      });
      await lote.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw SemPermissao();
      if (e.code == 'not-found') return;
      rethrow;
    }
  }

  @override
  Future<void> moverMinhaPeca(String mesaId, TokenMapa peca) async {
    final meuUid = uid;
    if (meuUid == null || peca.id != meuUid) throw SemPermissao();
    try {
      await _pecas(
        mesaId,
      ).doc(meuUid).update({'x': peca.x, 'y': peca.y, 'escala': peca.escala});
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw SemPermissao();
      if (e.code == 'not-found') return;
      rethrow;
    }
  }

  @override
  Future<void> salvarPeca(String mesaId, TokenMapa peca) async {
    try {
      await _pecas(mesaId).doc(peca.id).set(peca.toJson());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw SemPermissao();
      rethrow;
    }
  }

  @override
  Future<void> sincronizarMinhaPeca(
    String mesaId,
    String nome,
    String retratoBase64,
  ) async {
    final meuUid = uid;
    if (meuUid == null) return;
    final retrato = ImagemMural.peca(retratoBase64);
    final nomePeca = nome.trim().isEmpty ? 'Sem nome' : nome.trim();
    final assinatura = '$nomePeca|${retrato.hashCode}';
    if (_pecaSincronizada[mesaId] == assinatura) return;
    final mapa = await _mapa(mesaId).get();
    if (!mapa.exists) return; // sem mapa aberto, nada a pôr
    final ref = _pecas(mesaId).doc(meuUid);
    final atual = await ref.get();
    if (!atual.exists) {
      await ref.set(
        TokenMapa(
          id: meuUid,
          nome: nomePeca,
          retrato: retrato,
          cor: corDaPeca(nomePeca, inimigo: false),
          x: .5,
          y: .88,
        ).toJson(),
      );
    } else {
      final d = atual.data()!;
      if (d['nome'] != nomePeca || d['retrato'] != retrato) {
        await ref.update({'nome': nomePeca, 'retrato': retrato});
      }
    }
    _pecaSincronizada[mesaId] = assinatura;
  }

  @override
  Future<void> fecharMapa(String mesaId) async {
    try {
      await _apagarPecas(mesaId);
      await _mapa(mesaId).delete();
      _pecaSincronizada.remove(mesaId);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw SemPermissao();
      rethrow;
    }
  }

  /// O documento do mapa e as peças, juntos. Mapa antigo (peças dentro do
  /// documento) continua aparecendo até o mestre mexer nele.
  @override
  Stream<MapaMesa?> observarMapa(String mesaId) {
    late final StreamController<MapaMesa?> saida;
    StreamSubscription? doc;
    StreamSubscription? pecas;
    Map<String, dynamic>? ultimoDoc;
    var docVeio = false;
    List<TokenMapa>? ultimasPecas;

    void emitir() {
      if (!docVeio) return;
      final d = ultimoDoc;
      if (d == null) {
        saida.add(null);
        return;
      }
      final base = MapaMesa.fromJson(d);
      final daColecao = ultimasPecas ?? const <TokenMapa>[];
      saida.add(
        MapaMesa(
          imagemId: base.imagemId,
          titulo: base.titulo,
          tokens: daColecao.isNotEmpty ? daColecao : base.tokens,
          em: base.em,
        ),
      );
    }

    saida = StreamController<MapaMesa?>(
      onListen: () {
        doc = _mapa(mesaId).snapshots().listen((s) {
          docVeio = true;
          ultimoDoc = s.exists ? s.data() : null;
          emitir();
        }, onError: saida.addError);
        pecas = _pecas(mesaId).snapshots().listen((q) {
          ultimasPecas = [
            for (final d in q.docs)
              TokenMapa.fromJson({...d.data(), 'id': d.id}),
          ]..sort((a, b) => a.id.compareTo(b.id));
          emitir();
        }, onError: (_) {});
      },
      onCancel: () async {
        await doc?.cancel();
        await pecas?.cancel();
      },
    );
    return saida.stream;
  }
}
