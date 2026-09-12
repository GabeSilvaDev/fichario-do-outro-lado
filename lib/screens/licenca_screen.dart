import 'package:flutter/material.dart';

import '../theme.dart';

/// Os avisos que a Licença da Comunidade de Ordem Paranormal exige, num
/// lugar só.
///
/// A licença pede o selo "na capa (ou equivalente)". App não tem capa: a
/// capa aqui são as duas portas de entrada — a faixa fixa no alto da tela
/// inicial ([SeloLicenca] em modo compacto) e esta tela, que abre com o selo
/// em tamanho cheio. Em ambas o selo passa dos 10% de largura exigidos e
/// aparece com 100% de opacidade.
///
/// Regra de ouro para quem mexer aqui: nada nesta tela é decoração. Cada
/// bloco existe porque uma cláusula da Parte 4 da licença manda existir.
class LicencaScreen extends StatelessWidget {
  const LicencaScreen({super.key});

  static const url = 'https://ordemparanormal.com.br/licenca';

  /// O texto que a licença manda exibir logo depois do título quando o
  /// conteúdo é puramente textual. Vale como legenda do selo em todo canto.
  static const aviso = 'Este é um conteúdo não oficial, publicado sob a '
      'Licença da Comunidade de Ordem Paranormal';

  /// Obrigatório em conteúdo gratuito feito com IA, "próximo ao selo da
  /// licença e seguindo as mesmas regras de aplicação dele".
  static const avisoIA = 'Contém material gerado por inteligência artificial';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Licença e privacidade')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const SeloLicenca(largura: 132),
          const SizedBox(height: 20),
          const FaixaSecao('O que este app é'),
          const _Bloco(
            'Fichário do Outro Lado é uma ferramenta de fã, feita por um '
            'jogador para a própria mesa. Não é produto oficial, não tem '
            'parceria, aprovação, supervisão nem endosso de ninguém ligado a '
            'Ordem Paranormal.',
          ),
          const _Bloco(
            'O universo de Ordem Paranormal — personagens, lugares, história '
            'e estética — é de Rafael "Cellbit" Lange, titular exclusivo dos '
            'direitos. Este app usa apenas a terminologia de sistema que a '
            'Licença da Comunidade libera: os cinco atributos, PV, PE, '
            'Sanidade, NEX, e os nomes de perícias, origens, classes, '
            'trilhas, patentes e poderes.',
          ),
          const _Bloco(
            'Nenhum texto dos livros é reproduzido aqui. As descrições de '
            'poder e habilidade foram reescritas em notação própria, só com '
            'o efeito de regra. O app não traz arte, mapas, lore nem trecho '
            'de aventura oficial.',
          ),
          const FaixaSecao('Avisos obrigatórios'),
          const _Bloco(avisoIA,
              destaque: true,
              icone: Icons.smart_toy_outlined,
              cor: Cores.conhecimento),
          const _Bloco(
            'Contém temas de terror, violência e horror psicológico — é o '
            'gênero do jogo. As fichas e imagens que aparecem na mesa são '
            'criadas pelas pessoas da sua mesa, e a responsabilidade por elas '
            'é de quem as cria.',
            destaque: true,
            icone: Icons.warning_amber_rounded,
            cor: Cores.sangue,
          ),
          const FaixaSecao('Seus dados (LGPD)'),
          const _Bloco(
            'Sem mesa online, nada sai do aparelho: as fichas ficam gravadas '
            'aqui e ponto. Não há conta, cadastro, e-mail nem telefone.',
          ),
          const _Bloco(
            'Ao entrar numa mesa, o app faz um login anônimo (um código '
            'aleatório, sem identificação pessoal) e envia para o Firebase '
            'só o que a mesa precisa: o nome que você digitou, a ficha que '
            'você escolheu publicar, suas rolagens e as imagens que o mestre '
            'mostrar. Quem lê é você e o mestre da sua mesa.',
          ),
          const _Bloco(
            'Nada disso é vendido, cedido ou compartilhado com terceiros, e '
            'não existe rastreamento, anúncio nem telemetria — a Análise do '
            'Firebase está desligada no projeto.',
          ),
          const _Bloco(
            'Para apagar: "Sair da mesa" tira a sua ficha da mesa; '
            '"Encerrar sessão" limpa fichas e rolagens da mesa inteira; '
            '"Apagar mesa" apaga tudo, inclusive a galeria, sem volta.',
          ),
          const FaixaSecao('A licença'),
          const _Bloco(
            'Publicado sob a Licença da Comunidade de Ordem Paranormal, '
            'versão 1.0 (28/06/2026). O texto completo está em:',
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: SelectableText(
              url,
              style: TextStyle(
                  fontSize: 13,
                  color: Cores.energiaViva,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const _Bloco(
            'Este app é gratuito e assim continua: a licença proíbe vender '
            'conteúdo feito com material gerado por IA, e parte deste app '
            'foi. Se um dia virar conteúdo pago, tem que ser reescrito sem IA '
            'e revisto contra a versão da licença vigente naquela data.',
          ),
        ],
      ),
    );
  }
}

/// O selo da licença. `largura` vale a regra dos 10%: na faixa da tela
/// inicial ele é compacto, aqui dentro é grande — nunca translúcido, nunca
/// recortado.
class SeloLicenca extends StatelessWidget {
  final double largura;
  final bool comLegenda;

  const SeloLicenca({super.key, this.largura = 96, this.comLegenda = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset('assets/licenca/selo-comunidade.png',
            width: largura, filterQuality: FilterQuality.medium),
        if (comLegenda) ...[
          const SizedBox(height: 10),
          const Text(
            LicencaScreen.aviso,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Cores.tinta2, height: 1.35),
          ),
          const SizedBox(height: 4),
          const Text(
            LicencaScreen.avisoIA,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Cores.tinta2),
          ),
        ],
      ],
    );
  }
}

/// Imagem de abertura da tela inicial: funciona como capa visual do app.
class CapaAplicativo extends StatelessWidget {
  const CapaAplicativo({super.key});

  @override
  Widget build(BuildContext context) {
    final altura = (MediaQuery.sizeOf(context).width * .44)
        .clamp(154.0, 230.0)
        .toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Semantics(
        label: 'Capa do Fichário do Outro Lado',
        image: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            height: altura,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/capa_aplicativo.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC080611)],
                    ),
                  ),
                ),
                const Positioned(
                  left: 16,
                  right: 16,
                  bottom: 13,
                  child: Text(
                    'Fichário do Outro Lado',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: .4,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A faixa da tela inicial: selo pequeno + o aviso, sempre visível, abrindo
/// a tela completa no toque. É o "equivalente à capa" do app.
class FaixaLicenca extends StatelessWidget {
  const FaixaLicenca({super.key});

  @override
  Widget build(BuildContext context) {
    final largura =
        (MediaQuery.of(context).size.width * .13).clamp(44.0, 72.0);
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LicencaScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: const BoxDecoration(
          color: Cores.carta,
          border: Border(bottom: BorderSide(color: Cores.linha)),
        ),
        child: Row(
          children: [
            Image.asset('assets/licenca/selo-comunidade.png',
                width: largura, filterQuality: FilterQuality.medium),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conteúdo não oficial, publicado sob a Licença da '
                    'Comunidade de Ordem Paranormal.',
                    style: TextStyle(
                        fontSize: 11, color: Cores.tinta2, height: 1.3),
                  ),
                  SizedBox(height: 3),
                  Text(
                    LicencaScreen.avisoIA,
                    style: TextStyle(fontSize: 10, color: Cores.tinta2),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Cores.tinta2),
          ],
        ),
      ),
    );
  }
}

class _Bloco extends StatelessWidget {
  final String texto;
  final bool destaque;
  final IconData? icone;
  final Color? cor;

  const _Bloco(this.texto, {this.destaque = false, this.icone, this.cor});

  @override
  Widget build(BuildContext context) {
    final conteudo = Text(
      texto,
      style: TextStyle(
          fontSize: 13,
          height: 1.45,
          color: destaque ? Cores.tinta : Cores.tinta2),
    );
    if (!destaque) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
        child: conteudo,
      );
    }
    final c = cor ?? Cores.energia;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .10),
        border: Border.all(color: c.withValues(alpha: .5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone ?? Icons.info_outline, size: 18, color: c),
          const SizedBox(width: 10),
          Expanded(child: conteudo),
        ],
      ),
    );
  }
}
