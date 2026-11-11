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

/// Em que gaveta da galeria a imagem mora. Imagem antiga (sem categoria)
/// cai em [outro].
enum CategoriaGaleria {
  monstro('Monstros', 'Monstro'),
  npc('NPCs', 'NPC'),
  documento('Documentos e pistas', 'Documento'),
  local('Locais', 'Local'),
  outro('Outros', 'Outro');

  final String plural;
  final String singular;
  const CategoriaGaleria(this.plural, this.singular);

  static CategoriaGaleria porNome(String? nome) => CategoriaGaleria.values
      .firstWhere((c) => c.name == nome, orElse: () => CategoriaGaleria.outro);
}

class ItemGaleria {
  final String id;
  final String legenda;
  final String porUid;
  final String miniaturaBase64;
  final DateTime em;
  final CategoriaGaleria categoria;

  /// Já foi para o mural. O jogador só vê na galeria o que o mestre já
  /// mostrou — monstro guardado para depois não estraga a surpresa. Imagem
  /// antiga (sem o campo) conta como mostrada, que era como funcionava.
  final bool mostrada;

  const ItemGaleria({
    required this.id,
    required this.legenda,
    required this.porUid,
    required this.miniaturaBase64,
    required this.em,
    this.categoria = CategoriaGaleria.outro,
    this.mostrada = true,
  });

  factory ItemGaleria.fromJson(String id, Map<String, dynamic> j) =>
      ItemGaleria(
        id: id,
        legenda: (j['legenda'] ?? '') as String,
        porUid: (j['porUid'] ?? '') as String,
        miniaturaBase64: (j['miniatura'] ?? '') as String,
        em: DateTime.parse(j['em'] as String),
        categoria: CategoriaGaleria.porNome(j['categoria'] as String?),
        mostrada: (j['mostrada'] ?? true) as bool,
      );

  Map<String, dynamic> toJson() => {
    'legenda': legenda,
    'porUid': porUid,
    'miniatura': miniaturaBase64,
    'em': em.toIso8601String(),
    'categoria': categoria.name,
    'mostrada': mostrada,
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

  Map<String, dynamic> toJson() => {
    'imagemId': imagemId,
    'legenda': legenda,
    'em': em.toIso8601String(),
  };
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
    return String.fromCharCode(limpo.runes.first).toUpperCase();
  }

  TokenMapa mover(double novoX, double novoY) =>
      copiar(x: novoX.clamp(0.0, 1.0), y: novoY.clamp(0.0, 1.0));

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
  }) => TokenMapa(
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

/// Cor da peça. Ameaça é sempre vermelha — no meio do combate, ninguém tem
/// tempo de decorar quem é quem. Agente ganha uma cor estável a partir do
/// nome, para a mesma pessoa ter sempre a mesma peça.
int corDaPeca(String nome, {required bool inimigo}) {
  if (inimigo) return 0xFFE05545; // Cores.sangue
  const paleta = [
    0xFFA06BFF,
    0xFF57B98A,
    0xFFD9A441,
    0xFF4FA8E0,
    0xFFE07FB8,
    0xFF8CD17D,
  ];
  var soma = 0;
  for (final c in nome.codeUnits) {
    soma += c;
  }
  return paleta[soma % paleta.length];
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

  /// Grupo livre do mestre (ex.: "Missão 3") — a faixa de mapas separa por
  /// ele. Vazio = sem grupo.
  final String grupo;

  /// Posição na faixa (menor primeiro). Planta antiga sem ordem vai pelo
  /// tempo.
  final int ordem;

  /// Onde estavam as peças na última vez que este mapa saiu da mesa. Voltar
  /// a ele traz cada uma de volta. Null = mapa nunca usado.
  final List<TokenMapa>? pecas;

  /// Lado de um quadrado da grade, em fração da largura da imagem. O
  /// mestre calibra uma vez por planta; 0 = a régua ainda não sabe medir.
  final double quadrado;

  const ImagemDeMapa({
    required this.id,
    required this.nome,
    required this.miniaturaBase64,
    required this.em,
    this.grupo = '',
    this.ordem = 0,
    this.pecas,
    this.quadrado = 0,
  });

  factory ImagemDeMapa.fromJson(String id, Map<String, dynamic> j) =>
      ImagemDeMapa(
        id: id,
        nome: (j['nome'] ?? '') as String,
        miniaturaBase64: (j['miniatura'] ?? '') as String,
        em: DateTime.parse(j['em'] as String),
        grupo: (j['grupo'] ?? '') as String,
        ordem: (j['ordem'] as num?)?.toInt() ?? 0,
        pecas: j['pecas'] is List
            ? [
                for (final t in j['pecas'] as List)
                  TokenMapa.fromJson((t as Map).cast<String, dynamic>()),
              ]
            : null,
        quadrado: (j['quadrado'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'miniatura': miniaturaBase64,
    'em': em.toIso8601String(),
    'grupo': grupo,
    'ordem': ordem,
    if (quadrado > 0) 'quadrado': quadrado,
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

  /// A calibragem da planta aberta (ver [ImagemDeMapa.quadrado]). Viaja no
  /// documento do mapa porque o jogador também mede, e ele não precisa ler
  /// a biblioteca inteira para isso.
  final double quadrado;

  const MapaMesa({
    required this.imagemId,
    required this.titulo,
    required this.tokens,
    required this.em,
    this.quadrado = 0,
  });

  factory MapaMesa.fromJson(Map<String, dynamic> j) => MapaMesa(
    imagemId: (j['imagemId'] ?? '') as String,
    titulo: (j['titulo'] ?? '') as String,
    tokens: [
      for (final t in (j['tokens'] ?? const []) as List)
        TokenMapa.fromJson((t as Map).cast<String, dynamic>()),
    ],
    em: DateTime.parse(j['em'] as String),
    quadrado: (j['quadrado'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'imagemId': imagemId,
    'titulo': titulo,
    'tokens': [for (final t in tokens) t.toJson()],
    'em': em.toIso8601String(),
    if (quadrado > 0) 'quadrado': quadrado,
  };
}

/// Uma pista entregue a jogadores escolhidos: só quem está em [veem]
/// enxerga. Quem recebeu pode repassar a outro jogador, direto, e a pista
/// guarda quem passou para quem — o mestre acompanha.
class Pista {
  final String id;
  final String legenda;
  final String miniaturaBase64;

  /// uids de quem vê. O mestre vê todas, sem precisar estar aqui.
  final List<String> veem;
  final List<RepasseDePista> repasses;
  final DateTime em;

  const Pista({
    required this.id,
    required this.legenda,
    required this.miniaturaBase64,
    required this.veem,
    this.repasses = const [],
    required this.em,
  });

  factory Pista.fromJson(String id, Map<String, dynamic> j) => Pista(
    id: id,
    legenda: (j['legenda'] ?? '') as String,
    miniaturaBase64: (j['miniatura'] ?? '') as String,
    veem: [for (final u in (j['veem'] ?? const []) as List) '$u'],
    repasses: [
      for (final r in (j['repasses'] ?? const []) as List)
        RepasseDePista.fromJson((r as Map).cast<String, dynamic>()),
    ],
    em: DateTime.parse(j['em'] as String),
  );

  Map<String, dynamic> toJson() => {
    'legenda': legenda,
    'miniatura': miniaturaBase64,
    'veem': veem,
    'repasses': [for (final r in repasses) r.toJson()],
    'em': em.toIso8601String(),
  };
}

class RepasseDePista {
  final String deUid;
  final String deNome;
  final String paraUid;
  final String paraNome;
  final DateTime em;

  const RepasseDePista({
    required this.deUid,
    required this.deNome,
    required this.paraUid,
    required this.paraNome,
    required this.em,
  });

  factory RepasseDePista.fromJson(Map<String, dynamic> j) => RepasseDePista(
    deUid: (j['de'] ?? '') as String,
    deNome: (j['deNome'] ?? '') as String,
    paraUid: (j['para'] ?? '') as String,
    paraNome: (j['paraNome'] ?? '') as String,
    em: DateTime.tryParse('${j['em']}') ?? DateTime(2000),
  );

  Map<String, dynamic> toJson() => {
    'de': deUid,
    'deNome': deNome,
    'para': paraUid,
    'paraNome': paraNome,
    'em': em.toIso8601String(),
  };
}

/// Quem está na ordem de iniciativa. [id] é o da peça no mapa (uid do
/// agente ou `npc:…`) — é assim que o mapa sabe qual peça destacar.
class EntradaIniciativa {
  final String id;
  final String nome;

  /// O resultado do dado físico, anotado pelo mestre.
  final int valor;
  final bool inimigo;

  const EntradaIniciativa({
    required this.id,
    required this.nome,
    required this.valor,
    this.inimigo = false,
  });

  EntradaIniciativa comValor(int novo) =>
      EntradaIniciativa(id: id, nome: nome, valor: novo, inimigo: inimigo);

  factory EntradaIniciativa.fromJson(Map<String, dynamic> j) =>
      EntradaIniciativa(
        id: (j['id'] ?? '') as String,
        nome: (j['nome'] ?? '') as String,
        valor: (j['valor'] as num?)?.toInt() ?? 0,
        inimigo: (j['inimigo'] ?? false) as bool,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'valor': valor,
    'inimigo': inimigo,
  };
}

/// A ordem de turnos do combate, que todo mundo vê. Os dados são físicos:
/// o app só guarda o que o mestre anotou e de quem é a vez.
class Iniciativa {
  /// 0 = montando a lista, combate ainda não começou.
  final int rodada;

  /// Índice em [ordem] de quem está jogando.
  final int vez;
  final List<EntradaIniciativa> ordem;

  const Iniciativa({this.rodada = 0, this.vez = 0, this.ordem = const []});

  bool get comecou => rodada > 0 && ordem.isNotEmpty;

  EntradaIniciativa? get atual =>
      comecou ? ordem[vez.clamp(0, ordem.length - 1)] : null;

  EntradaIniciativa? get proximo =>
      comecou && ordem.length > 1 ? ordem[(vez + 1) % ordem.length] : null;

  /// Maior primeiro. Empate mantém quem já estava na frente.
  Iniciativa ordenada() {
    final quem = atual?.id;
    final lista = [...ordem];
    final pos = {for (var i = 0; i < lista.length; i++) lista[i].id: i};
    lista.sort((a, b) {
      final c = b.valor.compareTo(a.valor);
      return c != 0 ? c : pos[a.id]!.compareTo(pos[b.id]!);
    });
    final novaVez = quem == null ? 0 : lista.indexWhere((e) => e.id == quem);
    return Iniciativa(
      rodada: rodada,
      vez: novaVez < 0 ? 0 : novaVez,
      ordem: lista,
    );
  }

  /// Rodada 1, vez do maior.
  Iniciativa comecar() =>
      Iniciativa(rodada: 1, ordem: Iniciativa(ordem: ordem).ordenada().ordem);

  Iniciativa _naVez(int i) => Iniciativa(rodada: rodada, vez: i, ordem: ordem);

  Iniciativa proximaVez() {
    if (!comecou) return comecar();
    final i = vez + 1;
    return i >= ordem.length
        ? Iniciativa(rodada: rodada + 1, vez: 0, ordem: ordem)
        : _naVez(i);
  }

  Iniciativa vezAnterior() {
    if (!comecou) return this;
    if (vez > 0) return _naVez(vez - 1);
    if (rodada <= 1) return this;
    return Iniciativa(rodada: rodada - 1, vez: ordem.length - 1, ordem: ordem);
  }

  /// Tira alguém (morreu, fugiu). Se era a vez dele, passa para o próximo
  /// sem pular ninguém.
  Iniciativa sem(String id) {
    final i = ordem.indexWhere((e) => e.id == id);
    if (i < 0) return this;
    final lista = [...ordem]..removeAt(i);
    var novaVez = vez;
    if (i < vez) novaVez--;
    if (novaVez >= lista.length) novaVez = 0;
    return Iniciativa(
      rodada: lista.isEmpty ? 0 : rodada,
      vez: novaVez < 0 ? 0 : novaVez,
      ordem: lista,
    );
  }

  Iniciativa com(EntradaIniciativa e) {
    final i = ordem.indexWhere((x) => x.id == e.id);
    final lista = [...ordem];
    if (i < 0) {
      lista.add(e);
    } else {
      lista[i] = e;
    }
    return Iniciativa(rodada: rodada, vez: vez, ordem: lista);
  }

  factory Iniciativa.fromJson(Map<String, dynamic> j) => Iniciativa(
    rodada: (j['rodada'] as num?)?.toInt() ?? 0,
    vez: (j['vez'] as num?)?.toInt() ?? 0,
    ordem: [
      for (final e in (j['ordem'] ?? const []) as List)
        EntradaIniciativa.fromJson((e as Map).cast<String, dynamic>()),
    ],
  );

  Map<String, dynamic> toJson() => {
    'rodada': rodada,
    'vez': vez,
    'ordem': [for (final e in ordem) e.toJson()],
  };
}

/// PV de ameaça durante o combate. Fica num documento que só o mestre lê:
/// jogador não sabe quanto falta para o monstro cair.
class PvDeCombate {
  final int atual;
  final int maximo;

  const PvDeCombate(this.atual, this.maximo);

  bool get caiu => maximo > 0 && atual <= 0;

  PvDeCombate somar(int delta) => PvDeCombate(atual + delta, maximo);

  factory PvDeCombate.fromJson(Map<String, dynamic> j) => PvDeCombate(
    (j['atual'] as num?)?.toInt() ?? 0,
    (j['maximo'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {'atual': atual, 'maximo': maximo};
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
    String mesaId,
    Map<String, dynamic> ficha,
    String nome,
  );

  /// Tira a minha ficha da mesa.
  Future<void> despublicarFicha(String mesaId);

  /// Mestre: todas as fichas publicadas. Jogador: só a dele.
  Stream<List<FichaNaMesa>> observarFichas(String mesaId);

  /// Uma ficha específica. Null se não existe ou se você não pode ver.
  Stream<FichaNaMesa?> observarFicha(String mesaId, String donoUid);

  /// Publica uma rolagem no feed da mesa.
  Future<void> publicarRolagem(String mesaId, RolagemNaMesa rolagem);

  /// As últimas rolagens, mais recente primeiro.
  Stream<List<RolagemNaMesa>> observarRolagens(
    String mesaId, {
    int limite = 30,
  });

  /// Só o mestre. Guarda a imagem na galeria e devolve o id dela.
  Future<String> guardarNaGaleria(
    String mesaId,
    String imagemBase64,
    String miniaturaBase64,
    String legenda, {
    CategoriaGaleria categoria = CategoriaGaleria.outro,
  });

  /// Só o mestre. Muda a gaveta de uma imagem da galeria.
  Future<void> mudarCategoria(
    String mesaId,
    String imagemId,
    CategoriaGaleria categoria,
  );

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
    String mesaId,
    String imagemBase64,
    String miniaturaBase64,
    String nome,
  );

  /// As plantas guardadas nesta mesa, mais recente primeiro. Só miniaturas.
  Stream<List<ImagemDeMapa>> observarMapasGuardados(String mesaId);

  /// A planta cheia, buscada só quando o mapa abre.
  Future<String?> imagemDeMapa(String mesaId, String imagemId);

  /// Só o mestre. Tira uma planta da biblioteca (não mexe no mapa aberto).
  Future<void> apagarMapaGuardado(String mesaId, String imagemId);

  /// Só o mestre. Renomeia, muda de grupo ou de posição na faixa.
  Future<void> editarMapaGuardado(
    String mesaId,
    String imagemId, {
    String? nome,
    String? grupo,
    int? ordem,
  });

  /// Só o mestre. Guarda na planta onde estavam as peças — é o que deixa
  /// voltar a um mapa já usado com tudo no lugar.
  Future<void> guardarPecasDoMapa(
    String mesaId,
    String imagemId,
    List<TokenMapa> pecas,
  );

  /// Só o mestre. Põe (ou troca) o mapa da cena, apontando para uma planta
  /// da biblioteca.
  Future<void> abrirMapa(
    String mesaId,
    String imagemId,
    String titulo,
    List<TokenMapa> tokens, {
    double quadrado = 0,
  });

  /// Só o mestre. Guarda o tamanho do quadrado da grade desta planta (e no
  /// mapa aberto, se for ela) — é o que a régua usa para medir.
  Future<void> calibrarMapa(String mesaId, String imagemId, double quadrado);

  /// Só o mestre. Reescreve as peças — é assim que se move uma.
  Future<void> salvarTokens(String mesaId, List<TokenMapa> tokens);

  /// Jogador: move ou redimensiona a PRÓPRIA peça (id = uid). A regra do
  /// Firestore só deixa mudar posição e tamanho dela.
  Future<void> moverMinhaPeca(String mesaId, TokenMapa peca);

  /// Mestre: grava UMA peça (posição, tamanho, cor, marca de ameaça) sem
  /// reescrever as outras — dois arrastos seguidos não brigam entre si.
  Future<void> salvarPeca(String mesaId, TokenMapa peca);

  /// Jogador que publicou a ficha: põe a própria peça no mapa aberto (se
  /// ainda não estiver) e mantém nome e retrato iguais aos da ficha.
  Future<void> sincronizarMinhaPeca(
    String mesaId,
    String nome,
    String retratoBase64,
  );

  /// Só o mestre. Tira o mapa da mesa.
  Future<void> fecharMapa(String mesaId);

  /// Null quando não há mapa na mesa.
  Stream<MapaMesa?> observarMapa(String mesaId);

  /// Só o mestre. Entrega uma imagem da galeria como pista, só para [uids].
  /// A imagem é copiada: apagar da galeria não tira a pista de ninguém.
  Future<void> entregarPista(
    String mesaId,
    ItemGaleria imagem,
    List<String> uids,
  );

  /// Só o mestre. Muda quem vê a pista (pode tirar gente).
  Future<void> mudarQuemVe(String mesaId, String pistaId, List<String> uids);

  /// Quem tem a pista passa para outra pessoa da mesa, sem pedir ao mestre.
  Future<void> repassarPista(
    String mesaId,
    String pistaId,
    RepasseDePista repasse,
  );

  /// Só o mestre.
  Future<void> apagarPista(String mesaId, String pistaId);

  /// Mestre: todas. Jogador: só as que ele vê. Mais recente primeiro.
  Stream<List<Pista>> observarPistas(String mesaId, {required bool mestre});

  /// A imagem cheia da pista — a regra só entrega a quem a vê.
  Future<String?> imagemDaPista(String mesaId, String pistaId);

  /// Null = sem combate.
  Stream<Iniciativa?> observarIniciativa(String mesaId);

  /// Só o mestre. Null encerra o combate.
  Future<void> salvarIniciativa(String mesaId, Iniciativa? iniciativa);

  /// Só o mestre: PV das ameaças, por id de peça.
  Stream<Map<String, PvDeCombate>> observarPvDeCombate(String mesaId);

  Future<void> salvarPvDeCombate(String mesaId, Map<String, PvDeCombate> pv);
}
