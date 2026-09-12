import 'package:flutter/material.dart';

import 'data/dados_op.dart';
import 'mesa/mesa_store.dart';
import 'screens/home_screen.dart';
import 'store/ficha_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (detalhes) => _TelaDeErro(detalhes: detalhes);
  await DadosOP.carregar();
  await FichaStore.init();
  await MesaStore.init();
  runApp(const AppOrdemParanormal());
}

class AppOrdemParanormal extends StatelessWidget {
  const AppOrdemParanormal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fichário do Outro Lado',
      debugShowCheckedModeBanner: false,
      theme: construirTema(),
      home: const HomeScreen(),
    );
  }
}


/// O que aparece no lugar de um pedaço da tela que falhou.
class _TelaDeErro extends StatelessWidget {
  final FlutterErrorDetails detalhes;

  const _TelaDeErro({required this.detalhes});

  @override
  Widget build(BuildContext context) {
    final pilha = detalhes.stack
            ?.toString()
            .split('\n')
            .take(6)
            .join('\n') ??
        '';
    return Material(
      color: const Color(0xFF0A0812),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Esta tela quebrou',
                    style: TextStyle(
                        color: Color(0xFFE05545),
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SelectableText(
                  '${detalhes.exception}',
                  style: const TextStyle(
                      color: Color(0xFFECE7F4), fontSize: 13),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  pilha,
                  style: const TextStyle(
                      color: Color(0xFFAAA0C2),
                      fontFamily: 'monospace',
                      fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
