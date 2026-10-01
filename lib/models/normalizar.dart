/// Conserta, no lugar, o mapa de uma ficha vinda de fora — JSON importado,
/// cópia da mesa online, versão antiga do app, arquivo editado à mão.
///
/// Os getters da ficha fazem `as int`/`as String` direto; um `12.0` onde se
/// esperava `12`, ou um número onde se esperava texto, derrubava a tela
/// inicial inteira. Aqui cada campo conhecido vira o tipo certo, e o que
/// não tem conserto sai (o getter cai no padrão).
void normalizarFicha(Map<String, dynamic> d) {
  for (final chave in _inteiros) {
    if (!d.containsKey(chave)) continue;
    final v = paraInt(d[chave]);
    if (v == null) {
      d.remove(chave);
    } else {
      d[chave] = v;
    }
  }
  if (d['nex'] is int) d['nex'] = (d['nex'] as int).clamp(0, 99);
  if (d['estagio'] is int) d['estagio'] = (d['estagio'] as int).clamp(1, 5);
  for (final chave in ['pv', 'san', 'pe', 'pd', 'pvTemporario', 'pp']) {
    if (d[chave] is int && (d[chave] as int) < 0) d[chave] = 0;
  }

  for (final chave in _booleanos) {
    if (!d.containsKey(chave)) continue;
    final v = d[chave];
    d[chave] = v == true || v == 1 || v == 'true';
  }

  for (final chave in _textos) {
    final v = d[chave];
    if (v == null || v is String) continue;
    if (v is num || v is bool) {
      d[chave] = '$v';
    } else {
      d.remove(chave);
    }
  }

  d['atributos'] = _mapaDeInteiros(d['atributos'], limite: (-5, 20));
  d['pericias'] = _mapaDeInteiros(d['pericias'], limite: (0, 99));
  if (d.containsKey('periciaAtributo')) {
    final m = d['periciaAtributo'];
    d['periciaAtributo'] = <String, dynamic>{
      if (m is Map)
        for (final e in m.entries)
          if (e.value is String) '${e.key}': e.value,
    };
  }

  for (final chave in _listasDeMapas) {
    if (!d.containsKey(chave)) continue;
    final bruta = d[chave];
    d[chave] = <dynamic>[
      if (bruta is List)
        for (final item in bruta)
          if (item is Map) _itemNormalizado(item),
    ];
  }

  for (final chave in _listasDeTextos) {
    if (!d.containsKey(chave)) continue;
    final bruta = d[chave];
    d[chave] = <dynamic>[
      if (bruta is List)
        for (final item in bruta)
          if (item is String) item else if (item is num) '$item',
    ];
  }
}

/// `12`, `12.0`, `"12"` → 12. Qualquer outra coisa → null.
int? paraInt(Object? v) {
  if (v is int) return v;
  if (v is double) return v.isFinite ? v.round() : null;
  if (v is String) return int.tryParse(v.trim());
  return null;
}

Map<String, dynamic> _mapaDeInteiros(
  Object? bruto, {
  required (int, int) limite,
}) {
  return <String, dynamic>{
    if (bruto is Map)
      for (final e in bruto.entries)
        if (paraInt(e.value) != null)
          '${e.key}': paraInt(e.value)!.clamp(limite.$1, limite.$2),
  };
}

Map<String, dynamic> _itemNormalizado(Map item) {
  final saida = <String, dynamic>{};
  for (final e in item.entries) {
    final chave = '${e.key}';
    final v = e.value;
    if (_inteirosDeItem.contains(chave)) {
      final n = paraInt(v);
      if (n != null) saida[chave] = n;
    } else if (_booleanosDeItem.contains(chave)) {
      saida[chave] = v == true || v == 1 || v == 'true';
    } else if (v is Map || v is List || v is String || v == null) {
      saida[chave] = v is Map ? v.cast<String, dynamic>() : v;
    } else {
      saida[chave] = '$v';
    }
  }
  return saida;
}

const _inteiros = [
  'nex',
  'estagio',
  'deslocamento',
  'idade',
  'pv',
  'san',
  'pe',
  'pd',
  'pvTemporario',
  'defesaBonus',
  'protecaoDefesa',
  'defesaManual',
  'vd',
  'pvMaxManual',
  'sanMaxManual',
  'peMaxManual',
  'pp',
  'turnosMorrendo',
  'turnosEnlouquecendo',
  'sanPerdida',
  'pvDanoExcedente',
  'sanDanoExcedente',
  'peDanoExcedente',
  'pdDanoExcedente',
  'exSobrevivente',
  'estabilizacoes',
  'acalmado',
];

const _booleanos = [
  'emCombate',
  'morto',
  'ocultarPv',
  'ocultarSan',
  'ocultarPe',
  'modoLivre',
  'escudo',
  'insano',
  'regraDeterminacao',
];

const _textos = [
  'id',
  'nome',
  'jogador',
  'classe',
  'trilha',
  'origem',
  'patente',
  'protecao',
  'resistencias',
  'nacionalidade',
  'retrato',
  'historia',
  'aparencia',
  'primeiroEncontro',
  'fobias',
  'favoritos',
  'personalidade',
  'piorPesadelo',
  'anotacoes',
  'tipo',
  'categoria',
  'tamanho',
  'elemento',
  'sentidos',
  'vulnerabilidades',
  'presenca',
  'afinidade',
  'faixaEtaria',
  'criadaEm',
];

const _listasDeMapas = ['ataques', 'habilidades', 'rituais', 'inventario'];
const _listasDeTextos = [
  'proficiencias',
  'condicoes',
  'ferimentos',
  'desvantagens',
];

const _inteirosDeItem = {
  'bonus',
  'dadosTeste',
  'bonusTeste',
  'espacos',
  'quantidade',
  'nex',
  'estagio',
};
const _booleanosDeItem = {
  'transcender',
  'amaldicoado',
  'armaDaOrigem',
  'automatica',
};
