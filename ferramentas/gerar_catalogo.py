#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gera os catálogos do app: assets/catalogo/rituais.json e
assets/catalogo/armas.json.

RITUAIS: a ficha técnica (elemento, círculo, custo, execução, alcance, alvo,
duração, resistência) vem do extrator, que lê o PDF de quem tem o livro; o
EFEITO vem de ferramentas/notacao_rituais.py, escrito à mão em notação de
mesa. Nenhum parágrafo de livro entra aqui.

ARMAS: só a linha da tabela — dano, crítico, alcance, tipo, espaços,
categoria. Tabela é mecânica, e mecânica a licença libera; a descrição em
prosa que o extrator captura é descartada de propósito.

Uso: python3 ferramentas/gerar_catalogo.py
"""

import json
import os
import re
import sys
import unicodedata

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

RITUAIS_CRU = os.path.join(RAIZ, "..", "..", "Ordem", "App-Mestre", "dados",
                           "rituais-cru.json")
REGRAS_LOCAL = os.path.join(RAIZ, "..", "..", "Ordem", "App-Mestre", "dados",
                            "regras.local.js")
SAIDA_RITUAIS = os.path.join(RAIZ, "assets", "catalogo", "rituais.json")
SAIDA_ARMAS = os.path.join(RAIZ, "assets", "catalogo", "armas.json")


def sem_acento(texto):
    return unicodedata.normalize("NFKD", texto).encode(
        "ascii", "ignore").decode()


def carrega_rituais():
    from notacao_rituais import NOTACAO

    if not os.path.exists(RITUAIS_CRU):
        raise SystemExit(
            "Falta %s — rode App-Mestre/ferramentas/extrair_rituais.py"
            % os.path.relpath(RITUAIS_CRU, RAIZ))

    with open(RITUAIS_CRU, encoding="utf-8") as fh:
        cru = json.load(fh)

    saida, faltando = [], []
    for r in cru:
        chave = "%s:%s:%s" % (r["elemento"], r["circulo"], r["nome"])
        notacao = NOTACAO.get(chave)
        if not notacao:
            faltando.append(chave)
            continue

        # o custo de cada ampliação é do livro (número), o texto é nosso
        textos = {n: t for n, t in notacao.get("ampliacoes", [])}
        ampliacoes = []
        for a in r["ampliacoes"]:
            texto = textos.get(a["nome"])
            if not texto:
                continue
            ampliacoes.append({
                "nome": a["nome"], "custo": a["custo"], "efeito": texto,
            })

        # a diagramação às vezes esconde um campo do extrator; a notação
        # pode completar à mão
        campos = dict(notacao.get("ficha", {}))

        saida.append({
            "nome": r["nome"],
            "elemento": r["elemento"],
            "circulo": r["circulo"],
            "custo": r["custo"],
            "execucao": campos.get("execucao", r["execucao"]),
            "alcance": campos.get("alcance", r["alcance"]),
            "alvo": campos.get("alvo", r["alvo"]),
            "duracao": campos.get("duracao", r["duracao"]),
            "resistencia": campos.get("resistencia", r["resistencia"]),
            "efeito": notacao["efeito"],
            "ampliacoes": ampliacoes,
            "pagina": r["pagina"],
        })

    saida.sort(key=lambda r: (r["elemento"], r["circulo"],
                              sem_acento(r["nome"].lower())))
    return saida, faltando


def carrega_armas():
    """A tabela de armas e proteções, sem a prosa que a acompanha no livro."""
    if not os.path.exists(REGRAS_LOCAL):
        raise SystemExit(
            "Falta %s — rode App-Mestre/ferramentas/build_regras.py"
            % os.path.relpath(REGRAS_LOCAL, RAIZ))

    texto = open(REGRAS_LOCAL, encoding="utf-8").read()
    inicio = texto.index("window.REGRAS = ") + len("window.REGRAS = ")
    dados = json.loads(texto[inicio:texto.rindex(";")])

    def limpa(valor):
        return "" if valor in ("—", "-", None) else str(valor).strip()

    armas = [
        {
            "nome": a["nome"],
            "familia": limpa(a.get("familia")),
            "uso": limpa(a.get("uso")),
            "categoria": limpa(a.get("categoria")),
            "dano": limpa(a.get("dano")),
            "critico": limpa(a.get("critico")),
            "alcance": limpa(a.get("alcance")),
            "tipo": limpa(a.get("tipo")),
            "espacos": limpa(a.get("espacos")),
        }
        for a in dados.get("armas", [])
    ]
    protecoes = [
        {
            "nome": p["nome"],
            "defesa": limpa(p.get("defesa")),
            "categoria": limpa(p.get("categoria")),
            "espacos": limpa(p.get("espacos")),
        }
        for p in dados.get("protecoes", [])
    ]
    return armas, protecoes


TIPOS_DANO = {"C": "corte", "P": "perfuração", "I": "impacto",
              "B": "balístico", "F": "fogo", "E": "elétrico",
              "Q": "químico"}


def main():
    rituais, faltando = carrega_rituais()
    if faltando:
        print("rituais sem notação (escreva em notacao_rituais.py): %s"
              % ", ".join(faltando), file=sys.stderr)

    armas, protecoes = carrega_armas()

    os.makedirs(os.path.dirname(SAIDA_RITUAIS), exist_ok=True)
    with open(SAIDA_RITUAIS, "w", encoding="utf-8") as fh:
        json.dump({
            "versao": 1,
            "aviso": "Ficha técnica dos rituais + efeito em notação própria. "
                     "Nenhum texto de livro reproduzido.",
            "rituais": rituais,
        }, fh, ensure_ascii=False, separators=(",", ":"))

    with open(SAIDA_ARMAS, "w", encoding="utf-8") as fh:
        json.dump({
            "versao": 1,
            "aviso": "Tabela de armas e proteções (mecânica). As descrições "
                     "em prosa do livro não entram.",
            "tiposDeDano": TIPOS_DANO,
            "armas": armas,
            "protecoes": protecoes,
        }, fh, ensure_ascii=False, separators=(",", ":"))

    kb = (os.path.getsize(SAIDA_RITUAIS) + os.path.getsize(SAIDA_ARMAS)) // 1024
    print("ok: %d rituais, %d armas, %d proteções (%d KB)"
          % (len(rituais), len(armas), len(protecoes), kb))


if __name__ == "__main__":
    main()
