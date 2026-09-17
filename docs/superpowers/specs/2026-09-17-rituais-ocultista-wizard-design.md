# Rituais do Ocultista no wizard de criação

## Regra
- Ocultista existe a partir de NEX 5%.
- Rituais conhecidos = 3 + (NEX − 5) ÷ 5 (5% → 3, 10% → 4, 25% → 7, 99% → 21).
- Círculo máximo: NEX < 25% → 1º; 25–54% → 2º; 55–84% → 3º; ≥ 85% → 4º.
- Funções puras em `lib/data/dados_op.dart` (`DadosOP.rituaisPorNex`, `DadosOP.circuloMaximoPorNex`), com teste em `test/regras_op_test.dart`.

## Wizard (passo Classe e NEX)
- Com Ocultista selecionado, seção "Rituais" após Trilha/Patente: contador "X de N", botão "Do catálogo de rituais", lista dos escolhidos com remover.
- Catálogo abre em modo escolha filtrado por `circuloMaximo` e sem os já escolhidos. Botão desabilita ao atingir N.
- Baixar NEX remove rituais acima do círculo novo e corta excedente. Trocar de classe limpa a lista.
- Obrigatório: `_passoCompleto` do passo 2 exige `rituais.length == N` para Ocultista. Pendência: "Escolha mais X ritual(is)".
- Modo livre (NPC / regras frouxas): sem limite de quantidade nem círculo, não obrigatório.
- Em `_criar`, cada ritual entra em `f.rituais` no formato que `CatalogoScreen._ritualParaFicha` já grava.

## Fora de escopo
- Ficha já criada (subir NEX depois) não ganha automação.
