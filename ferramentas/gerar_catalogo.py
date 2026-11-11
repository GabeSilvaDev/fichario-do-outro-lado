#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gera os catálogos do app: assets/catalogo/rituais.json e
assets/catalogo/armas.json.

RITUAIS: a ficha técnica (elemento, círculo, custo, execução, alcance, alvo,
duração, resistência) vem do extrator, que lê o PDF de quem tem o livro; o
EFEITO vem de ferramentas/notacao_rituais.py, escrito à mão em notação de
mesa. Nenhum parágrafo de livro entra aqui.

ARMAS: a linha da tabela — dano, crítico, alcance, tipo, espaços,
categoria — vem do extrator; habilidades, regras especiais e a descrição de
uma linha vêm de ferramentas/notacao_armas.py, escritas à mão. A prosa que o
extrator captura é descartada de propósito. Munições, modificações,
maldições de arma, itens de ataque e componentes ritualísticos saem da
notação também.

Uso: python3 ferramentas/gerar_catalogo.py [--so-armas]
"""

import json
import os
import re
import sys
import unicodedata

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def _app_mestre(*partes):
    """O App-Mestre mora em pessoal/ordem-paranormal/ (antes, Ordem/)."""
    for pasta in ("ordem-paranormal", "Ordem"):
        caminho = os.path.join(RAIZ, "..", "..", pasta, "App-Mestre", *partes)
        if os.path.exists(caminho):
            return caminho
    return os.path.join(RAIZ, "..", "..", "ordem-paranormal", "App-Mestre",
                        *partes)


RITUAIS_CRU = _app_mestre("dados", "rituais-cru.json")
REGRAS_LOCAL = _app_mestre("dados", "regras.local.js")
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

        textos = {n: t for n, t in notacao.get("ampliacoes", [])}
        ampliacoes = []
        for a in r["ampliacoes"]:
            texto = textos.get(a["nome"])
            if not texto:
                continue
            ampliacoes.append({
                "nome": a["nome"], "custo": a["custo"], "efeito": texto,
            })

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

    import notacao_armas as na

    municoes = {m["nome"] for m in na.MUNICOES}
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
            "pagina": 55,
        }
        for a in dados.get("armas", [])
        if a["nome"] not in municoes
    ]
    faltando = []
    for a in armas:
        nota = na.ARMAS.get(a["nome"])
        if nota is None:
            faltando.append(a["nome"])
            continue
        a["descricao"] = nota["desc"]
        a["especial"] = nota.get("especial", [])
        for flag in ("agil", "automatica", "arremesso", "somaForca"):
            if nota.get(flag):
                a[flag] = True
        if nota.get("penalidadeDados"):
            a["penalidadeDados"] = nota["penalidadeDados"]
        if nota.get("municao"):
            a["municao"] = nota["municao"]
        if a["tipo"] == "Fogo":
            a["tipo"] = "F"
    if faltando:
        raise SystemExit("armas sem notação (escreva em notacao_armas.py): "
                         + ", ".join(faltando))
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


def extras_armas():
    import notacao_armas as na
    return {
        "municoes": na.MUNICOES,
        "modificacoes": na.MODIFICACOES,
        "maldicoes": na.MALDICOES,
        "itensDeAtaque": na.ITENS_DE_ATAQUE,
        "componentes": na.COMPONENTES,
        "opressores": na.OPRESSORES,
        "habilidades": {"agil": na.AGIL, "automatica": na.AUTOMATICA,
                        "arremesso": na.ARREMESSO},
    }


TIPOS_DANO = {"C": "corte", "P": "perfuração", "I": "impacto",
              "B": "balístico", "F": "fogo", "E": "elétrico",
              "Q": "químico"}


def main():
    so_armas = "--so-armas" in sys.argv
    armas, protecoes = carrega_armas()
    os.makedirs(os.path.dirname(SAIDA_ARMAS), exist_ok=True)
    with open(SAIDA_ARMAS, "w", encoding="utf-8") as fh:
        json.dump({
            "versao": 2,
            "aviso": "Tabela de armas e proteções (mecânica) + habilidades, "
                     "regras e descrições em notação própria. Nenhum texto "
                     "de livro reproduzido.",
            "tiposDeDano": TIPOS_DANO,
            "armas": armas,
            "protecoes": protecoes,
            **extras_armas(),
        }, fh, ensure_ascii=False, separators=(",", ":"))
    if so_armas:
        print("ok: %d armas, %d proteções" % (len(armas), len(protecoes)))
        return

    rituais, faltando = carrega_rituais()
    if faltando:
        print("rituais sem notação (escreva em notacao_rituais.py): %s"
              % ", ".join(faltando), file=sys.stderr)

    with open(SAIDA_RITUAIS, "w", encoding="utf-8") as fh:
        json.dump({
            "versao": 1,
            "aviso": "Ficha técnica dos rituais + efeito em notação própria. "
                     "Nenhum texto de livro reproduzido.",
            "rituais": rituais,
        }, fh, ensure_ascii=False, separators=(",", ":"))

    kb = (os.path.getsize(SAIDA_RITUAIS) + os.path.getsize(SAIDA_ARMAS)) // 1024
    print("ok: %d rituais, %d armas, %d proteções (%d KB)"
          % (len(rituais), len(armas), len(protecoes), kb))


if __name__ == "__main__":
    main()
