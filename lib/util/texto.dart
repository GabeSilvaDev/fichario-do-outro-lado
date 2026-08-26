import 'package:characters/characters.dart';

/// Comparação de texto para busca: sem acento e sem caixa.
///
/// Quem procura no meio da sessão digita "lider de culto" e "eletrocussao"
/// — sem acento, com pressa. A busca tem que achar assim.
String semAcento(String texto) {
  const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
  const sem = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';
  final saida = StringBuffer();
  for (final c in texto.characters) {
    final i = comAcento.indexOf(c);
    saida.write(i >= 0 ? sem[i] : c);
  }
  return saida.toString();
}

/// True quando [alvo] contém [procurado], ignorando acento e caixa.
bool casaBusca(String alvo, String procurado) =>
    semAcento(alvo).toLowerCase().contains(
        semAcento(procurado).toLowerCase());
