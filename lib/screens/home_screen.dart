import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../mesa/mesa_store.dart';
import '../mesa/modelos.dart';
import '../mesa/ouvinte_mapa.dart';
import '../mesa/ouvinte_mural.dart';
import '../mesa/ponte_rolagens.dart';
import '../mesa/telas/mesa_aba.dart';
import '../models/ficha_op.dart';
import '../store/ficha_store.dart';
import '../theme.dart';
import '../widgets/retrato.dart';
import 'bestiario_screen.dart';
import 'catalogo_screen.dart';
import 'ficha_screen.dart';
import 'licenca_screen.dart';
import 'wizard_screen.dart';

/// Duas abas: as fichas do aparelho e a mesa online.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _aba = 0;

  @override
  Widget build(BuildContext context) {
    final corpo = _aba == 0 ? const _ListaFichas() : const MesaAba();

    // dentro de uma mesa, o mural abre sozinho quando o mestre mostra algo —
    // em qualquer aba, inclusive com a ficha aberta por cima. O
    // ValueListenableBuilder é o que monta o ouvinte NA HORA em que o
    // aparelho entra numa mesa, sem depender de troca de aba.
    final embrulhado = ValueListenableBuilder(
      valueListenable: MesaStore.listenable,
      builder: (context, Box<String> _, _) {
        final estado = MesaStore.atual;
        if (estado == null) return corpo;
        return OuvinteMural(
          // a key derruba e recria o ouvinte quando a mesa muda: assinatura
          // antiga não pode continuar ouvindo a mesa anterior
          key: ValueKey('mural-${estado.mesaId}'),
          servico: PonteRolagens.servico,
          mesaId: estado.mesaId,
          child: OuvinteMapa(
            key: ValueKey('mapa-${estado.mesaId}'),
            servico: PonteRolagens.servico,
            mesaId: estado.mesaId,
            mestre: estado.papel == PapelMesa.mestre,
            child: corpo,
          ),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fichário do Outro Lado',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: .5)),
        actions: [
          IconButton(
            tooltip: 'Licença e privacidade',
            icon: const Icon(Icons.verified_user_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LicencaScreen()),
            ),
          ),
        ],
      ),
      // A faixa do selo fica acima das abas: é a "capa" do app, e some
      // de vista em nenhuma delas.
      body: Column(
        children: [
          const FaixaLicenca(),
          Expanded(child: embrulhado),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        backgroundColor: Cores.carta,
        indicatorColor: Cores.energia.withValues(alpha: .25),
        onDestinationSelected: (i) => setState(() => _aba = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.description_outlined), label: 'Fichas'),
          NavigationDestination(
              icon: Icon(Icons.groups_outlined), label: 'Mesa'),
        ],
      ),
    );
  }
}

class _ListaFichas extends StatefulWidget {
  const _ListaFichas();

  @override
  State<_ListaFichas> createState() => _ListaFichasState();
}

class _ListaFichasState extends State<_ListaFichas> {
  /// Ficha nova passa pelo assistente: ele cobra as regras de criação uma
  /// vez só. Depois disso a ficha vive na tela dela, onde tudo é editável.
  Future<void> _nova({bool npc = false}) async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WizardScreen(npc: npc)));
    if (mounted) setState(() {});
  }

  void _abrirCatalogo() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CatalogoScreen()),
    );
  }

  void _abrirBestiario() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BestiarioScreen()),
    );
  }

  Future<void> _importar() async {
    final escolha = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    final bytes = escolha?.files.single.bytes;
    if (bytes == null) return;
    try {
      final dados =
          jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      // id novo: importar não pode atropelar uma ficha existente
      dados['id'] = const Uuid().v4();
      await FichaStore.salvar(FichaOP(dados));
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Esse arquivo não parece uma ficha exportada.')));
    }
  }

  Future<void> _exportar(FichaOP f) async {
    final nome = f.nome.isEmpty ? 'ficha' : f.nome.replaceAll(' ', '-');
    await Share.share(
      jsonEncode(f.dados),
      subject: 'Ficha $nome (Fichário do Outro Lado)',
    );
  }

  Future<void> _excluir(FichaOP f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir ficha?'),
        content: Text(
            '"${f.nome.isEmpty ? 'Sem nome' : f.nome}" some do aparelho. '
            'Isso não pode ser desfeito.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir',
                  style: TextStyle(color: Cores.sangue))),
        ],
      ),
    );
    if (ok != true) return;
    await FichaStore.excluir(f.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Ouvir o Hive, e não só o próprio setState: ficha salva por OUTRA tela
    // (bestiário, wizard, edição) mexe na caixa sem passar por aqui, e sem
    // isto a lista continua mostrando o estado velho até a próxima ação.
    return ValueListenableBuilder(
      valueListenable: FichaStore.listenable,
      builder: (context, Box<String> _, _) => _corpo(FichaStore.todas()),
    );
  }

  Widget _corpo(List<FichaOP> fichas) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // o mestre monta NPC e criatura aqui: mesma ficha, sem o
          // orçamento da criação e fora da mesa online
          FloatingActionButton.small(
            heroTag: 'npc',
            onPressed: () => _nova(npc: true),
            backgroundColor: Cores.carta2,
            foregroundColor: Cores.sangue,
            tooltip: 'Novo NPC / criatura',
            child: const Icon(Icons.psychology_alt_outlined),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'pc',
            onPressed: _nova,
            backgroundColor: Cores.energia,
            foregroundColor: Cores.fundo,
            icon: const Icon(Icons.add),
            label: const Text('Nova ficha'),
          ),
        ],
      ),
      body: fichas.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_stories_outlined,
                      size: 56, color: Cores.tinta2),
                  const SizedBox(height: 12),
                  const Text('Nenhuma ficha ainda.',
                      style: TextStyle(color: Cores.tinta2)),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _importar,
                    icon: const Icon(Icons.file_open_outlined, size: 18),
                    label: const Text('Importar de um arquivo'),
                  ),
                  TextButton.icon(
                    onPressed: _abrirBestiario,
                    icon: const Icon(Icons.pest_control_outlined, size: 18),
                    label: const Text('Abrir o bestiário da campanha'),
                  ),
                  TextButton.icon(
                    onPressed: _abrirCatalogo,
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text('Catálogo de rituais e armas'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
              children: [
                for (final f in fichas) _cartao(f),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _importar,
                        icon: const Icon(Icons.file_open_outlined, size: 18),
                        label: const Text('Importar ficha (.json)'),
                      ),
                      TextButton.icon(
                        onPressed: _abrirBestiario,
                        icon: const Icon(Icons.pest_control_outlined,
                            size: 18),
                        label: const Text('Bestiário da campanha'),
                      ),
                      TextButton.icon(
                        onPressed: _abrirCatalogo,
                        icon: const Icon(Icons.menu_book_outlined, size: 18),
                        label: const Text('Rituais e armas'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Ameaça não tem classe nem NEX: o que identifica é o VD e a categoria.
  /// Agente continua com classe · NEX · patente.
  static String _linhaDeIdentidade(FichaOP f) {
    if (f.vd != null) {
      final tipo = [f.categoria, f.tamanho, f.elemento]
          .where((x) => x.isNotEmpty)
          .join(' · ');
      return 'VD ${f.vd}${tipo.isEmpty ? '' : ' · $tipo'}';
    }
    return '${f.classe} · NEX ${f.nex}% · ${f.patente}';
  }

  /// Criatura não tem Sanidade nem Esforço: mostrar "SAN 0/0" só ocuparia
  /// espaço com informação falsa.
  static String _linhaDeRecursos(FichaOP f) {
    if (f.vd != null && f.sanMax == 0 && f.peMax == 0) {
      return 'PV ${f.pv}/${f.pvMax} · machucado ${f.machucado} · '
          'Defesa ${f.defesa}';
    }
    return 'PV ${f.pv}/${f.pvMax} · SAN ${f.san}/${f.sanMax} · '
        'PE ${f.pe}/${f.peMax}';
  }

  Widget _cartao(FichaOP f) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => FichaScreen(fichaId: f.id)));
          setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              RetratoAvatar(base64: f.retrato, tamanho: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(f.nome.isEmpty ? 'Sem nome' : f.nome,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        if (f.ehNpc)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 1),
                            decoration: BoxDecoration(
                              border: Border.all(color: Cores.sangue),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text('NPC',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Cores.sangue)),
                          ),
                      ],
                    ),
                    Text(
                      _linhaDeIdentidade(f),
                      style: const TextStyle(
                          fontSize: 12, color: Cores.tinta2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _linhaDeRecursos(f),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: Cores.carta2,
                icon: const Icon(Icons.more_vert, color: Cores.tinta2),
                onSelected: (v) {
                  if (v == 'exportar') _exportar(f);
                  if (v == 'excluir') _excluir(f);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'exportar', child: Text('Exportar (.json)')),
                  PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
