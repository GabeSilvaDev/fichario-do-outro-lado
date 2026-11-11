import 'package:flutter/material.dart';

import '../data/dados_op.dart';
import '../models/ficha_op.dart';
import '../regras/pendencias.dart';
import '../regras/poderes.dart';
import '../theme.dart';
import '../util/texto.dart';

/// Escolhe um poder do catálogo para a ficha: de classe, paranormais e o 1º poder de outra trilha (Versatilidade). Mostra na hora
/// se a ficha cumpre o pré-requisito e se o poder já foi escolhido.
class PoderesScreen extends StatefulWidget {
  final FichaOP ficha;

  const PoderesScreen({super.key, required this.ficha});

  @override
  State<PoderesScreen> createState() => _PoderesScreenState();
}

class _PoderesScreenState extends State<PoderesScreen> {
  String _filtro = '';

  FichaOP get f => widget.ficha;

  List<Poder> _daAba(int aba) {
    final classe = f.classe;
    return [
      for (final p in DadosOP.poderes)
        if (switch (aba) {
          0 => p.tipo == 'classe' && p.classe == classe,
          1 => p.tipo == 'paranormal',
          _ =>
            p.tipo == 'trilha' &&
                p.classe == classe &&
                p.trilha != f.trilha &&
                p.nex == 10,
        })
          if (_filtro.isEmpty ||
              casaBusca(p.nome, _filtro) ||
              casaBusca(p.efeito, _filtro))
            p,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Escolher poder'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Da classe'),
              Tab(text: 'Paranormais'),
              Tab(text: 'Outra trilha'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar poder',
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _filtro = v.trim()),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _lista(
                    0,
                    'Poderes de ${f.classe.toLowerCase()}. '
                    'Transcender = escolha um paranormal (aba ao lado).',
                  ),
                  _lista(
                    1,
                    'Cada poder paranormal é um Transcender: não '
                    'ganha a SAN do NEX em que entra.',
                  ),
                  _lista(
                    2,
                    'Versatilidade (NEX 50%): o 1º poder de outra '
                    'trilha da sua classe.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _cobra => !f.ehNpc && !f.modoLivre;
  int get _esperado => poderesQueONexDa(f);
  int get _tem => f.habilidades.where((h) => ehPoderEscolhido(f, h)).length;

  Widget _lista(int aba, String explicacao) {
    final poderes = _daAba(aba);
    final cheio = _cobra && _tem >= _esperado;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      children: [
        if (_cobra)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (cheio ? Cores.sangue : Cores.conhecimento).withValues(
                alpha: .1,
              ),
              border: Border.all(
                color: (cheio ? Cores.sangue : Cores.conhecimento).withValues(
                  alpha: .5,
                ),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'NEX ${f.nex}%: $_esperado poder(es) à escolha · a ficha tem '
              '$_tem. ${cheio ? 'Escolher mais fica fora da regra (a ficha avisa).' : 'Pode escolher mais ${_esperado - _tem}.'}',
              style: TextStyle(
                fontSize: 12.5,
                color: cheio ? Cores.sangue : Cores.conhecimento,
              ),
            ),
          ),
        Text(
          explicacao,
          style: const TextStyle(fontSize: 12, color: Cores.tinta2),
        ),
        const SizedBox(height: 8),
        if (poderes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Nada aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Cores.tinta2),
            ),
          ),
        for (final p in poderes) _linha(p),
      ],
    );
  }

  Widget _linha(Poder p) {
    final falta = requisitoQueFalta(f, p.requisitosRegra);
    final jaTem =
        !p.repetivel && f.habilidades.any((h) => h['poder'] == p.nome);
    final bloqueado = jaTem;
    final avisos = <String>[
      if (_cobra && _tem >= _esperado)
        'Acima do que o NEX ${f.nex}% dá ($_esperado).',
      if (_cobra && p.tipo == 'trilha' && f.nex < 50)
        'Versatilidade (outra trilha) só a partir de NEX 50%.',
    ];
    return Card(
      key: ValueKey('poder-${p.nome}'),
      shape: (avisos.isEmpty && (falta == null || !_cobra)) || bloqueado
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Cores.sangue),
            ),
      child: ListTile(
        title: Text(
          '${p.nome}${p.elemento.isNotEmpty ? ' · ${p.elemento}' : ''}'
          '${p.trilha.isNotEmpty ? ' · ${p.trilha}' : ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.efeito, style: const TextStyle(fontSize: 12.5)),
            if (p.afinidade.isNotEmpty)
              Text(
                'Afinidade: ${p.afinidade}',
                style: const TextStyle(fontSize: 12, color: Cores.energiaViva),
              ),
            if (p.requisitos.isNotEmpty)
              Text(
                'Requisito: ${p.requisitos}'
                '${falta != null ? ' — falta $falta' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: falta != null ? Cores.sangue : Cores.tinta2,
                ),
              ),
            if (jaTem)
              const Text(
                'Já está na ficha.',
                style: TextStyle(fontSize: 12, color: Cores.tinta2),
              )
            else
              for (final a in avisos)
                Text(
                  '⚠ $a',
                  style: const TextStyle(fontSize: 12, color: Cores.sangue),
                ),
            Text(
              '${p.fonte} p. ${p.pagina}',
              style: const TextStyle(fontSize: 10, color: Cores.tinta2),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Pôr na ficha',
          icon: Icon(
            avisos.isEmpty && (falta == null || !_cobra)
                ? Icons.add_circle_outline
                : Icons.warning_amber,
            color: bloqueado
                ? Cores.linha
                : (avisos.isEmpty && (falta == null || !_cobra)
                      ? Cores.energiaViva
                      : Cores.sangue),
          ),
          onPressed: bloqueado ? null : () => Navigator.of(context).pop(p),
        ),
      ),
    );
  }
}
