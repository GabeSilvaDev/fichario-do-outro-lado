import 'modelos.dart';

/// A mesa procurada não existe (ou o código foi trocado).
class MesaNaoEncontrada implements Exception {
  @override
  String toString() => 'Não encontrei essa mesa.';
}

/// A ação é só do mestre.
class SemPermissao implements Exception {
  @override
  String toString() => 'Só o mestre da mesa pode fazer isso.';
}

/// A chave de recuperação informada não é a da mesa.
class ChaveErrada implements Exception {
  @override
  String toString() => 'Chave não confere.';
}

/// Uma ficha publicada numa mesa. É uma cópia: a verdade continua no Hive do
/// dono. Só o dono escreve; o mestre lê.
class FichaNaMesa {
  final String donoUid;
  final String nome;
  final DateTime atualizadaEm;
  final Map<String, dynamic> ficha;

  const FichaNaMesa({
    required this.donoUid,
    required this.nome,
    required this.atualizadaEm,
    required this.ficha,
  });

  factory FichaNaMesa.fromJson(String donoUid, Map<String, dynamic> j) =>
      FichaNaMesa(
        donoUid: donoUid,
        nome: (j['nome'] ?? '') as String,
        atualizadaEm: DateTime.parse(j['atualizadaEm'] as String),
        ficha: ((j['ficha'] ?? const {}) as Map).cast<String, dynamic>(),
      );

  Map<String, dynamic> toJson() => {
        'dono': donoUid,
        'nome': nome,
        'atualizadaEm': atualizadaEm.toIso8601String(),
        'ficha': ficha,
      };
}

class ItemGaleria {
  final String id;
  final String legenda;
  final String porUid;
  final String miniaturaBase64;
  final DateTime em;

  const ItemGaleria({
    required this.id,
    required this.legenda,
    required this.porUid,
    required this.miniaturaBase64,
    required this.em,
  });

  factory ItemGaleria.fromJson(String id, Map<String, dynamic> j) =>
      ItemGaleria(
        id: id,
        legenda: (j['legenda'] ?? '') as String,
        porUid: (j['porUid'] ?? '') as String,
        miniaturaBase64: (j['miniatura'] ?? '') as String,
        em: DateTime.parse(j['em'] as String),
      );

  Map<String, dynamic> toJson() => {
        'legenda': legenda,
        'porUid': porUid,
        'miniatura': miniaturaBase64,
        'em': em.toIso8601String(),
      };
}

/// O que está em destaque no mural agora. Aponta para uma imagem da galeria;
/// a legenda viaja junto para ninguém precisar reler a galeria inteira (com
/// todas as miniaturas) só para mostrar uma linha de texto.
class ItemMural {
  final String imagemId;
  final String legenda;
  final DateTime em;

  const ItemMural({
    required this.imagemId,
    required this.legenda,
    required this.em,
  });

  factory ItemMural.fromJson(Map<String, dynamic> j) => ItemMural(
        imagemId: (j['imagemId'] ?? '') as String,
        legenda: (j['legenda'] ?? '') as String,
        em: DateTime.parse(j['em'] as String),
      );

  Map<String, dynamic> toJson() =>
      {'imagemId': imagemId, 'legenda': legenda, 'em': em.toIso8601String()};
}

/// Uma rolagem publicada na mesa — o "Últimos testes" do mestre, ao vivo.
/// Todo membro vê todas: é a mesa física, onde os dados rolam à vista.
class RolagemNaMesa {
  final String id;
  final String porUid;
  final String porNome;

  /// "Percepção", "Ataque: Pistola", "2d6+3"…
  final String titulo;
  final String formula;
  final String detalhe;
  final int total;
  final bool critico;
  final bool desastre;
  final DateTime em;

  const RolagemNaMesa({
    required this.id,
    required this.porUid,
    required this.porNome,
    required this.titulo,
    required this.formula,
    required this.detalhe,
    required this.total,
    required this.critico,
    required this.desastre,
    required this.em,
  });

  factory RolagemNaMesa.fromJson(String id, Map<String, dynamic> j) =>
      RolagemNaMesa(
        id: id,
        porUid: (j['porUid'] ?? '') as String,
        porNome: (j['porNome'] ?? '') as String,
        titulo: (j['titulo'] ?? '') as String,
        formula: (j['formula'] ?? '') as String,
        detalhe: (j['detalhe'] ?? '') as String,
        total: (j['total'] ?? 0) as int,
        critico: (j['critico'] ?? false) as bool,
        desastre: (j['desastre'] ?? false) as bool,
        em: DateTime.parse(j['em'] as String),
      );

  Map<String, dynamic> toJson() => {
        'porUid': porUid,
        'porNome': porNome,
        'titulo': titulo,
        'formula': formula,
        'detalhe': detalhe,
        'total': total,
        'critico': critico,
        'desastre': desastre,
        'em': em.toIso8601String(),
      };
}

/// Uma peça no mapa da cena: quem está onde.
///
/// A posição é relativa à imagem (0..1 em cada eixo), não em pixels: o mapa
/// aparece em telas de tamanhos diferentes e a peça tem que cair no mesmo
/// lugar do desenho em todas elas.
///
/// O retrato viaja junto, minúsculo. Poderia ser lido da ficha publicada,
/// mas as regras não deixam um jogador ler a ficha do outro — e todo mundo
/// precisa ver a peça de todo mundo. Sem retrato, a peça mostra a inicial.
class TokenMapa {
  /// uid do jogador, ou `npc:<algo>` para as peças que o mestre cria.
  final String id;
  final String nome;

  /// base64 de um JPEG pequeno (48px). Vazio = mostra a inicial.
  final String retrato;

  /// ARGB da borda/fundo da peça.
  final int cor;

  /// 0..1, relativo à imagem do mapa.
  final double x;
  final double y;

  /// Peça de ameaça: o mestre marca para separar agentes de inimigos.
  final bool inimigo;

  /// Tamanho da peça em relação ao padrão. Mapa de porão e mapa de cidade
  /// pedem peças de tamanhos diferentes, e criatura Enorme não pode ocupar
  /// o mesmo círculo que um agente.
  final double escala;

  const TokenMapa({
    required this.id,
    required this.nome,
    this.retrato = '',
    required this.cor,
    required this.x,
    required this.y,
    this.inimigo = false,
    this.escala = 1,
  });

  /// A letra que aparece quando não há retrato.
  String get inicial {
    final limpo = nome.trim();
    if (limpo.isEmpty) return '?';
    // pelas runas, não por substring: nome que começa com emoji ou letra
    // fora do BMP viraria meio caractere quebrado.
    return String.fromCharCode(limpo.runes.first).toUpperCase();
  }

  TokenMapa mover(double novoX, double novoY) => copiar(
        x: novoX.clamp(0.0, 1.0),
        y: novoY.clamp(0.0, 1.0),
      );

  /// Entre 0,4× e 3×: menor que isso some no mapa, maior cobre a cena.
  TokenMapa comEscala(double nova) => copiar(escala: nova.clamp(0.4, 3.0));

  TokenMapa copiar({
    String? nome,
    String? retrato,
    int? cor,
    double? x,
    double? y,
    bool? inimigo,
    double? escala,
  }) =>
      TokenMapa(
        id: id,
        nome: nome ?? this.nome,
        retrato: retrato ?? this.retrato,
        cor: cor ?? this.cor,
        x: x ?? this.x,
        y: y ?? this.y,
        inimigo: inimigo ?? this.inimigo,
        escala: escala ?? this.escala,
      );

  factory TokenMapa.fromJson(Map<String, dynamic> j) => TokenMapa(
        id: (j['id'] ?? '') as String,
        nome: (j['nome'] ?? '') as String,
        retrato: (j['retrato'] ?? '') as String,
        cor: (j['cor'] ?? 0xFFA06BFF) as int,
        x: ((j['x'] ?? 0.5) as num).toDouble().clamp(0.0, 1.0),
        y: ((j['y'] ?? 0.5) as num).toDouble().clamp(0.0, 1.0),
        inimigo: (j['inimigo'] ?? false) as bool,
        escala: ((j['escala'] ?? 1) as num).toDouble().clamp(0.4, 3.0),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'retrato': retrato,
        'cor': cor,
        'x': x,
        'y': y,
        'inimigo': inimigo,
        'escala': escala,
      };
}

/// Uma planta guardada na mesa, pronta para virar cena.
///
/// Mora numa coleção só dela — separada da galeria do mural. Mapa não é
/// imagem para abrir na cara de todo mundo: é o tabuleiro, e ele fica
/// disponível o tempo todo para quem quiser olhar.
class ImagemDeMapa {
  final String id;
  final String nome;
  final String miniaturaBase64;
  final DateTime em;

  const ImagemDeMapa({
    required this.id,
    required this.nome,
    required this.miniaturaBase64,
    required this.em,
  });

  factory ImagemDeMapa.fromJson(String id, Map<String, dynamic> j) =>
      ImagemDeMapa(
        id: id,
        nome: (j['nome'] ?? '') as String,
        miniaturaBase64: (j['miniatura'] ?? '') as String,
        em: DateTime.parse(j['em'] as String),
      );

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'miniatura': miniaturaBase64,
        'em': em.toIso8601String(),
      };
}

/// O mapa da cena: a imagem que está na mesa e as peças em cima dela.
///
/// Mora num documento só (`mesas/{id}/mapa/atual`) porque mover uma peça tem
/// que ser uma escrita atômica que todo mundo vê de uma vez — mapa com peça
/// "meio movida" é pior do que mapa nenhum. A imagem fica fora dele, em
/// `imagens/{imagemId}`, para o documento continuar leve a cada arrasto.
class MapaMesa {
  final String imagemId;
  final String titulo;
  final List<TokenMapa> tokens;
  final DateTime em;

  const MapaMesa({
    required this.imagemId,
    required this.titulo,
    required this.tokens,
    required this.em,
  });

  factory MapaMesa.fromJson(Map<String, dynamic> j) => MapaMesa(
        imagemId: (j['imagemId'] ?? '') as String,
        titulo: (j['titulo'] ?? '') as String,
        tokens: [
          for (final t in (j['tokens'] ?? const []) as List)
            TokenMapa.fromJson((t as Map).cast<String, dynamic>())
        ],
        em: DateTime.parse(j['em'] as String),
      );

  Map<String, dynamic> toJson() => {
        'imagemId': imagemId,
        'titulo': titulo,
        'tokens': [for (final t in tokens) t.toJson()],
        'em': em.toIso8601String(),
      };
}

/// Tudo que o app precisa da mesa online. Interface para as telas serem
/// testáveis sem rede; em produção roda `MesaFirestore`.
abstract class MesaService {
  /// Login anônimo. Devolve o uid deste aparelho.
  Future<String> entrarAnonimo();

  /// uid da sessão atual, ou null se ainda não entrou.
  String? get uid;

  /// Cria a mesa e devolve, junto, a chave de recuperação. A chave é
  /// mostrada uma vez: quem a tem manda na mesa.
  Future<(Mesa, String)> criarMesa(String nome, String meuNome);

  /// Entra pelo código. Lança [MesaNaoEncontrada] se não existir.
  Future<Mesa> entrarPorCodigo(String codigo, String meuNome);

  /// Volta a uma mesa já conhecida pelo aparelho, sem código.
  Future<Mesa> entrarPorId(String mesaId, String meuNome);

  /// Volta a ser o mestre provando a chave.
  Future<Mesa> reassumirMesa(String codigo, String chave, String meuNome);

  /// Emite null quando a mesa deixa de existir (mestre apagou).
  Stream<Mesa?> observarMesa(String mesaId);

  Stream<List<Membro>> observarMembros(String mesaId);

  /// Batimento de presença.
  Future<void> baterPonto(String mesaId);

  /// Sai da mesa (remove só o próprio membro).
  Future<void> sair(String mesaId);

  /// Só o mestre.
  Future<void> removerMembro(String mesaId, String uid);

  /// Só o mestre. Gera um código novo e invalida o anterior.
  Future<void> trocarCodigo(String mesaId);

  /// Só o mestre. Esvazia a mesa (membros, fichas e rolagens); a mesa, o
  /// código, a chave e a galeria continuam para a próxima sessão.
  Future<void> encerrarSessao(String mesaId);

  /// Só o mestre. Apaga a mesa inteira, para sempre.
  Future<void> apagarMesa(String mesaId);

  /// Publica (ou atualiza) a MINHA ficha nesta mesa.
  Future<void> publicarFicha(
      String mesaId, Map<String, dynamic> ficha, String nome);

  /// Tira a minha ficha da mesa.
  Future<void> despublicarFicha(String mesaId);

  /// Mestre: todas as fichas publicadas. Jogador: só a dele.
  Stream<List<FichaNaMesa>> observarFichas(String mesaId);

  /// Uma ficha específica. Null se não existe ou se você não pode ver.
  Stream<FichaNaMesa?> observarFicha(String mesaId, String donoUid);

  /// Publica uma rolagem no feed da mesa.
  Future<void> publicarRolagem(String mesaId, RolagemNaMesa rolagem);

  /// As últimas rolagens, mais recente primeiro.
  Stream<List<RolagemNaMesa>> observarRolagens(String mesaId,
      {int limite = 30});

  /// Só o mestre. Guarda a imagem na galeria e devolve o id dela.
  Future<String> guardarNaGaleria(String mesaId, String imagemBase64,
      String miniaturaBase64, String legenda);

  /// Só o mestre.
  Future<void> apagarDaGaleria(String mesaId, String imagemId);

  /// Mais recente primeiro. Só miniaturas.
  Stream<List<ItemGaleria>> observarGaleria(String mesaId);

  /// A imagem cheia, buscada só quando alguém abre.
  Future<String?> imagemCheia(String mesaId, String imagemId);

  /// Só o mestre. Põe a imagem em destaque: abre na tela de todos.
  Future<void> mostrarAgora(String mesaId, String imagemId);

  /// Só o mestre. Tira o que estiver no mural.
  Future<void> limparMural(String mesaId);

  /// Null quando não há nada no mural.
  Stream<ItemMural?> observarMural(String mesaId);

  /// Só o mestre. Guarda uma planta na biblioteca de mapas da mesa e
  /// devolve o id dela. Não passa pela galeria do mural.
  Future<String> guardarMapa(
      String mesaId, String imagemBase64, String miniaturaBase64, String nome);

  /// As plantas guardadas nesta mesa, mais recente primeiro. Só miniaturas.
  Stream<List<ImagemDeMapa>> observarMapasGuardados(String mesaId);

  /// A planta cheia, buscada só quando o mapa abre.
  Future<String?> imagemDeMapa(String mesaId, String imagemId);

  /// Só o mestre. Tira uma planta da biblioteca (não mexe no mapa aberto).
  Future<void> apagarMapaGuardado(String mesaId, String imagemId);

  /// Só o mestre. Põe (ou troca) o mapa da cena, apontando para uma planta
  /// da biblioteca.
  Future<void> abrirMapa(String mesaId, String imagemId, String titulo,
      List<TokenMapa> tokens);

  /// Só o mestre. Reescreve as peças — é assim que se move uma.
  Future<void> salvarTokens(String mesaId, List<TokenMapa> tokens);

  /// Só o mestre. Tira o mapa da mesa.
  Future<void> fecharMapa(String mesaId);

  /// Null quando não há mapa na mesa.
  Stream<MapaMesa?> observarMapa(String mesaId);
}
