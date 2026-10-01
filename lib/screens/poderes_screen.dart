import 'package:flutter/material.dart';

import '../data/dados_op.dart';
import '../models/ficha_op.dart';
import '../regras/pendencias.dart';
import '../regras/poderes.dart';
import '../theme.dart';
import '../util/texto.dart';

/// Escolhe um poder do catálogo para a ficha: de classe, gerais (SAH),
/// paranormais e o 1º poder de outra trilha (Versatilidade). Mostra na hora
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
          1 => p.tipo == 'geral',
          2 => p.tipo == 'paranormal',
          _ =>
            p.tipo == 'trilha' &&
                p.classe == classe &&
                p.trilha != f.trilha &&
                (p.nex == 10 || p.estagio == 2),
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
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Escolher poder'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Da classe'),
              Tab(text: 'Gerais'),
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
                    'Poderes gerais (SAH p. 33): valem no lugar de '
                    'um poder de classe.',
                  ),
                  _lista(
                    2,
                    'Cada poder paranormal é um Transcender: não '
                    'ganha a SAN do NEX em que entra.',
                  ),
                  _lista(
                    3,
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

  Widget _lista(int aba, String explicacao) {
    final poderes = _daAba(aba);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      children: [
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
    return Card(
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
            Icons.add_circle_outline,
            color: bloqueado ? Cores.linha : Cores.energiaViva,
          ),
          onPressed: bloqueado ? null : () => Navigator.of(context).pop(p),
        ),
      ),
    );
  }
}
