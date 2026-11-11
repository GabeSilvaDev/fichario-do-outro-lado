import 'package:flutter/material.dart';

/// Paleta de Ordem Paranormal, pelos elementos do cenário:
/// Energia (roxo, interação) · Sangue (vermelho, perigo) ·
/// Conhecimento (dourado, destaque) · Morte (o fundo) · Medo (texto claro).
class Cores {
  static const Color fundo = Color(0xFF0A0812);
  static const Color carta = Color(0xFF14101D);
  static const Color carta2 = Color(0xFF1B1526);
  static const Color linha = Color(0xFF2E2640);

  static const Color tinta = Color(0xFFECE7F4);
  static const Color tinta2 = Color(0xFFAAA0C2);

  static const Color energia = Color(0xFFA06BFF);
  static const Color energiaViva = Color(0xFFC19BFF);
  static const Color sangue = Color(0xFFE05545);
  static const Color conhecimento = Color(0xFFD9A441);
  static const Color estavel = Color(0xFF57B98A);
}

ThemeData construirTema() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Cores.fundo,
    colorScheme: base.colorScheme.copyWith(
      primary: Cores.energia,
      secondary: Cores.conhecimento,
      surface: Cores.carta,
      error: Cores.sangue,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Cores.carta,
      foregroundColor: Cores.tinta,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: Cores.carta,
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        side: BorderSide(color: Cores.linha),
      ),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Cores.carta2),
    dividerColor: Cores.linha,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Cores.fundo,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Cores.linha),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Cores.linha),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Cores.energia),
      ),
      labelStyle: const TextStyle(color: Cores.tinta2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Cores.energia,
        foregroundColor: Cores.fundo,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Cores.energiaViva),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Cores.carta2,
      contentTextStyle: TextStyle(color: Cores.tinta),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Cores.energiaViva,
      unselectedLabelColor: Cores.tinta2,
      indicatorColor: Cores.energia,
    ),
  );
}

/// Título de seção com fio, usado nas listas da mesa e da ficha.
class FaixaSecao extends StatelessWidget {
  final String texto;

  /// Lápis no fim da faixa: abre a edição só desta seção. Null = sem lápis
  /// (seção que só mostra, ou ficha aberta pelo mestre).
  final VoidCallback? onEditar;

  /// Esta seção está em edição: o lápis vira Cancelar / Salvar.
  final bool editando;
  final VoidCallback? onSalvar;
  final VoidCallback? onCancelar;

  const FaixaSecao(
    this.texto, {
    super.key,
    this.onEditar,
    this.editando = false,
    this.onSalvar,
    this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final cor = editando ? Cores.energiaViva : Cores.conhecimento;
    return Padding(
      padding: EdgeInsets.only(
        top: 18,
        bottom: onEditar != null || editando ? 2 : 6,
      ),
      child: Row(
        children: [
          if (editando) ...[
            Icon(Icons.edit, size: 14, color: cor),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              texto.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: cor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (editando) const Spacer() else const Expanded(child: Divider()),
          if (editando) ...[
            TextButton(
              key: ValueKey('cancelar-$texto'),
              onPressed: onCancelar,
              style: TextButton.styleFrom(
                foregroundColor: Cores.tinta2,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              key: ValueKey('salvar-$texto'),
              onPressed: onSalvar,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Salvar'),
            ),
          ] else if (onEditar != null)
            IconButton(
              key: ValueKey('editar-$texto'),
              tooltip: 'Editar ${texto.toLowerCase()}',
              onPressed: onEditar,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: Cores.tinta2,
            ),
        ],
      ),
    );
  }
}
