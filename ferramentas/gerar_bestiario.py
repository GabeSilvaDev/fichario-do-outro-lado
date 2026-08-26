#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gera assets/bestiario/bestiario.json: o elenco inteiro da campanha em fichas
prontas para o app importar.

Nada aqui é copiado de livro nenhum. Os números saem das fórmulas do sistema
(as mesmas de lib/data/dados_op.dart) aplicadas à classe e ao NEX que este
projeto escolheu para cada figura, e o texto é escrito aqui, em notação de
mesa. Quando existe versão oficial da ameaça, a ficha aponta a página do
livro em vez de reproduzi-la — ver LICENCA.md.

Retratos: nenhum é arte oficial. Cada ficha ganha um brasão gerado aqui —
monograma sobre a cor do elemento — para dar rosto à peça no mapa e à lista.

Uso: python3 ferramentas/gerar_bestiario.py
"""

import base64
import io
import json
import os
import re
import sys
import unicodedata

from PIL import Image, ImageDraw, ImageFont

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SAIDA = os.path.join(RAIZ, "assets", "bestiario", "bestiario.json")

# ---------------------------------------------------------------- fórmulas
# Espelham ClasseOP de lib/data/dados_op.dart. Se lá mudar, muda aqui — o
# teste do app confere os dois contra os mesmos números.
CLASSES = {
    # nome:        (pvIni, pvNivel, peIni, peNivel, sanIni, sanNivel)
    "Mundano":     (8,  2, 1, 1, 8,  0),
    "Combatente":  (20, 4, 2, 2, 12, 3),
    "Especialista": (16, 3, 3, 3, 16, 4),
    "Ocultista":   (12, 2, 4, 4, 20, 5),
}


def nivel(nex):
    if nex <= 0:
        return 0
    if nex >= 99:
        return 20
    return nex // 5


def recursos(classe, nex, vig, pre):
    pv_i, pv_n, pe_i, pe_n, san_i, san_n = CLASSES[classe]
    n = nivel(nex)
    if n == 0:
        return pv_i + vig, san_i, pe_i + pre
    pv = pv_i + vig + (n - 1) * (pv_n + vig)
    pe = pe_i + pre + (n - 1) * (pe_n + pre)
    san = san_i + (n - 1) * san_n
    return pv, san, pe


# ---------------------------------------------------------------- retratos
ELEMENTOS = {
    "energia": (0xA0, 0x6B, 0xFF),
    "sangue": (0xE0, 0x55, 0x45),
    "morte": (0x7A, 0x8A, 0x9E),
    "conhecimento": (0xD9, 0xA4, 0x41),
    "medo": (0xC9, 0xC2, 0xDA),
    "humano": (0x8A, 0x80, 0xA4),
    "ordem": (0x57, 0xB9, 0x8A),
}

_FONTES = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
]


def _fonte(tamanho):
    for caminho in _FONTES:
        if os.path.exists(caminho):
            return ImageFont.truetype(caminho, tamanho)
    return ImageFont.load_default()


def monograma(nome, elemento):
    """Brasão do NPC: iniciais sobre a cor do elemento. 96px, JPEG."""
    partes = [p for p in re.split(r"[\s\-]+", nome) if p and p[0].isalpha()]
    letras = "".join(p[0] for p in partes[:2]).upper() or "?"

    lado = 96
    cor = ELEMENTOS.get(elemento, ELEMENTOS["humano"])
    fundo = tuple(max(0, int(c * 0.16)) for c in cor)

    im = Image.new("RGB", (lado * 4, lado * 4), fundo)
    d = ImageDraw.Draw(im)
    # anel duplo: o de fora marca o elemento, o de dentro dá profundidade
    d.ellipse([10, 10, lado * 4 - 10, lado * 4 - 10], outline=cor, width=14)
    d.ellipse([34, 34, lado * 4 - 34, lado * 4 - 34],
              outline=tuple(int(c * 0.45) for c in cor), width=5)
    f = _fonte(150 if len(letras) > 1 else 190)
    caixa = d.textbbox((0, 0), letras, font=f)
    d.text(((lado * 4 - (caixa[2] - caixa[0])) / 2 - caixa[0],
            (lado * 4 - (caixa[3] - caixa[1])) / 2 - caixa[1]),
           letras, font=f, fill=cor)

    im = im.resize((lado, lado), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, format="JPEG", quality=72, optimize=True)
    return base64.b64encode(buf.getvalue()).decode("ascii")


def slug(nome):
    s = unicodedata.normalize("NFKD", nome).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")


# ---------------------------------------------------------------- fichas
def ficha(nome, *, papel, classe, nex, atributos, elemento="humano",
          pericias=None, ataques=(), habilidades=(), rituais=(),
          rituais_do_livro=None,
          defesa_bonus=0, protecao="", resistencias="", deslocamento=9,
          patente="Recruta", origem="", trilha="", taticas="", nota="",
          referencia=""):
    agi, forc, intel, pre, vig = atributos
    pv, san, pe = recursos(classe, nex, vig, pre)
    return {
        "id": "bestiario-" + slug(nome),
        "tipo": "npc",
        "modoLivre": True,
        "nome": nome,
        "jogador": papel,
        "classe": classe,
        "trilha": trilha,
        "origem": origem,
        "patente": patente,
        "nex": nex,
        "deslocamento": deslocamento,
        "atributos": {"AGI": agi, "FOR": forc, "INT": intel,
                      "PRE": pre, "VIG": vig},
        "pv": pv, "san": san, "pe": pe,
        "defesaBonus": defesa_bonus,
        "protecao": protecao,
        "resistencias": resistencias,
        "pericias": pericias or {},
        "ataques": [dict(a) for a in ataques],
        "habilidades": [dict(h) for h in habilidades],
        # NPC conjurador entra com os rituais que ele pode usar já na
        # ficha: no meio da cena ninguém abre o livro para lembrar custo e
        # efeito
        "rituais": [dict(r) for r in rituais]
        + (rituais_do_catalogo(rituais_do_livro) if rituais_do_livro else []),
        "inventario": [],
        "nacionalidade": "",
        "idade": 0,
        "proficiencias": [],
        "emCombate": False, "morto": False,
        "ocultarPv": False, "ocultarSan": False, "ocultarPe": False,
        "historia": nota,
        "aparencia": "",
        "primeiroEncontro": "",
        "fobias": "",
        "favoritos": "",
        "personalidade": "",
        "piorPesadelo": "",
        "anotacoes": ("TÁTICA: " + taticas + "\n\n" if taticas else "")
                     + (referencia and "ONDE ESTÁ NO MATERIAL OFICIAL: "
                        + referencia + "\nA ficha oficial fica no livro; "
                        "esta aqui é a versão desta mesa, montada com as "
                        "fórmulas do sistema."),
        "retrato": monograma(nome, elemento),
        "criadaEm": "2026-08-19T00:00:00.000",
    }


def atq(nome, pericia, bonus, dano, *, critico="x2", margem="20",
        tipo="", alcance="Corpo a corpo", especial=""):
    return {"nome": nome, "pericia": pericia, "bonus": bonus, "dano": dano,
            "critico": critico, "margem": margem, "tipo": tipo,
            "alcance": alcance, "especial": especial}


def hab(nome, descricao):
    return {"nome": nome, "descricao": descricao}


def rit(nome, circulo, custo, descricao, execucao="Padrão",
        alcance="Curto", duracao="Instantânea"):
    return {"nome": nome, "circulo": circulo, "custo": custo,
            "execucao": execucao, "alcance": alcance, "duracao": duracao,
            "descricao": descricao}


# ================================================================ o elenco
CATALOGO_RITUAIS = os.path.join(RAIZ, "assets", "catalogo", "rituais.json")
_catalogo = None


def rituais_do_catalogo(filtro):
    """Expande o filtro de uma ameaça conjuradora na lista real de rituais.

    Aceita duas formas: por FAIXA (elementos + círculos, para quem "conjura
    todos os rituais de Sangue até o 3º círculo") e por LISTA (nomes exatos,
    para quem o livro diz quais usa)."""
    global _catalogo
    if _catalogo is None:
        if not os.path.exists(CATALOGO_RITUAIS):
            raise SystemExit("Falta assets/catalogo/rituais.json — rode "
                             "ferramentas/gerar_catalogo.py antes")
        with open(CATALOGO_RITUAIS, encoding="utf-8") as fh:
            _catalogo = json.load(fh)["rituais"]

    elementos = set(filtro.get("elementos") or [])
    piso = filtro.get("circuloMin", 1)
    teto = filtro.get("circuloMax", 4)
    escolhidos = set(filtro.get("nomes") or [])
    dt = filtro.get("dt")
    nota = filtro.get("nota", "")

    saida = []
    for r in _catalogo:
        if escolhidos:
            if r["nome"] not in escolhidos:
                continue
        else:
            if elementos and r["elemento"] not in elementos:
                continue
            if r["circulo"] > teto or r["circulo"] < piso:
                continue
        ampliacoes = "\n".join(
            "%s (+%s PE): %s" % (a["nome"], a["custo"], a["efeito"])
            for a in r["ampliacoes"])
        descricao = "\n".join(x for x in [
            "Alvo: %s" % r["alvo"] if r["alvo"] else "",
            "Resistência: %s%s" % (r["resistencia"],
                                   " (DT %s)" % dt if dt else "")
            if r["resistencia"] else ("DT %s" % dt if dt else ""),
            r["efeito"],
            ampliacoes,
            nota,
        ] if x)
        saida.append({
            "nome": r["nome"],
            "circulo": "%sº" % r["circulo"],
            "custo": "%s PE" % r["custo"],
            "execucao": r["execucao"],
            "alcance": r["alcance"],
            "duracao": r["duracao"],
            "descricao": descricao,
        })
    return saida


GRUPOS = []


def grupo(nome, descricao, fichas):
    GRUPOS.append({"nome": nome, "descricao": descricao, "fichas": fichas})

# ---------------------------------------------------------------- aliados
# Estes não vêm de livro nenhum: são os NPCs desta mesa, escritos aqui.
grupo(
    "Ordo Realitas — aliados",
    "Quem chega para ajudar. Use com parcimônia: aliado que resolve a cena "
    "rouba a cena.",
    [
        ficha("Eduarda Flom", papel="Aliada · mentora do Ato I",
              classe="Especialista", nex=30, atributos=(3, 1, 3, 3, 2),
              elemento="ordem", patente="Agente Especial",
              pericias={"Investigação": 10, "Percepção": 10, "Intuição": 10,
                        "Diplomacia": 5, "Ocultismo": 5, "Pontaria": 5},
              ataques=[atq("Pistola .40", "Pontaria", 8, "2d6",
                           margem="19", tipo="Balístico", alcance="Curto")],
              habilidades=[hab("Chegou tarde de novo",
                               "1×/sessão: refaz um teste falho de um "
                               "agente que ela esteja vendo. Custa a ela "
                               "uma cena fora de campo depois."),
                           hab("Rede da Ordem",
                               "Consegue transporte, um contato ou um "
                               "documento em 1d4 horas de mesa.")],
              taticas="Não luta se puder evitar. Cobre a retirada, "
                      "estabiliza quem caiu, sai de cena antes do clímax.",
              nota="Recruta o grupo na missão 00. Esconde muita desgraça "
                   "atrás da postura de adulta responsável (Intuição DT 20 "
                   "percebe). Candidata natural a Âncora coletiva."),
        ficha("Caio Leal", papel="Aliado · veterano",
              classe="Combatente", nex=45, atributos=(3, 3, 2, 2, 3),
              elemento="ordem", patente="Oficial de Operações",
              pericias={"Luta": 15, "Pontaria": 15, "Fortitude": 10,
                        "Reflexos": 10, "Tática": 10, "Percepção": 5},
              defesa_bonus=3, protecao="Colete tático (+3 Defesa)",
              ataques=[atq("Fuzil de assalto", "Pontaria", 14, "2d8+3",
                           margem="19", tipo="Balístico", alcance="Médio",
                           especial="Rajada: −5 no teste, +1d8 de dano"),
                       atq("Faca de combate", "Luta", 12, "1d6+3",
                           margem="19", tipo="Corte")],
              habilidades=[hab("Segura a linha",
                               "Enquanto estiver de pé, aliados adjacentes "
                               "recebem +2 em resistências contra Medo."),
                           hab("Veterano cansado",
                               "Não avança sozinho. Se o grupo recuar, ele "
                               "recua junto e cobre.")],
              taticas="Ocupa a porta, atira em quem tentar flanquear, "
                      "grita ordens. Cai antes de fugir.",
              nota="Entra na missão 06. Refém preferencial da missão 12 — "
                   "matá-lo cedo desperdiça o gancho."),
        ficha("Naomi Akechi", papel="Aliada · Equipe Delta",
              classe="Combatente", nex=50, atributos=(3, 4, 1, 2, 3),
              elemento="ordem", patente="Oficial de Operações",
              pericias={"Luta": 15, "Atletismo": 10, "Fortitude": 10,
                        "Reflexos": 10, "Iniciativa": 10},
              defesa_bonus=4, protecao="Proteção pesada da Ordem",
              ataques=[atq("Machado tático", "Luta", 16, "1d12+4",
                           critico="x3", tipo="Corte"),
                       atq("Escopeta", "Pontaria", 12, "4d6",
                           tipo="Balístico", alcance="Curto",
                           especial="Cone de 6m com o resto do pente")],
              habilidades=[hab("Frente da Delta",
                               "Puxa a atenção da criatura por 1 rodada "
                               "1×/combate: alvos adjacentes atacam ela.")],
              taticas="Entra primeiro, apanha primeiro, sai por último.",
              nota="Equipe Delta: apoio, mentoria ou vítima que motiva "
                   "vingança. Nunca protagonismo."),
        ficha("Olivia Lefleur", papel="Aliada · Equipe Delta (suporte)",
              rituais_do_livro={"elementos": ["Morte"], "circuloMax": 2, "dt": 22,
                                "nota": "A cura de Ordem Paranormal é Morte: são estes os rituais que ela leva."},
              classe="Ocultista", nex=50, atributos=(2, 1, 3, 4, 2),
              elemento="ordem", patente="Oficial de Operações",
              pericias={"Ocultismo": 15, "Medicina": 15, "Vontade": 15,
                        "Intuição": 10},
              rituais=[rit("Curar Ferimentos", "1º", "1 PE",
                           "Cura 2d8+2 PV num toque. Sobe 1d8 por PE extra."),
                       rit("Restaurar Sanidade", "2º", "3 PE",
                           "Devolve 2d6 SAN e tira uma condição mental.")],
              habilidades=[hab("Enquanto eu respirar",
                               "Reação: quando um aliado à vista chega a 0 "
                               "PV, gasta 3 PE para deixá-lo com 1 PV. "
                               "1×/cena.")],
              taticas="Fica atrás, cura o que estiver mais perto de morrer, "
                      "não gasta PE em dano.",
              nota="Equipe Delta. É a rede de segurança da mesa quando o "
                   "grupo apanha demais — use e tire de cena."),
        ficha("Jiro Yukami", papel="Aliado · Equipe Delta (campo)",
              classe="Especialista", nex=50, atributos=(4, 2, 3, 2, 2),
              elemento="ordem", patente="Oficial de Operações",
              pericias={"Furtividade": 15, "Crime": 15, "Percepção": 15,
                        "Tecnologia": 10, "Pontaria": 10},
              ataques=[atq("Pistola com supressor", "Pontaria", 13, "2d6+2",
                           margem="19", tipo="Balístico", alcance="Curto",
                           especial="+2d6 contra alvo desprevenido")],
              habilidades=[hab("Já abri a porta",
                               "Abre fechadura, tranca ou terminal comum "
                               "sem teste, em 1 rodada.")],
              taticas="Some, aparece atrás, abre o caminho e some de novo.",
              nota="Equipe Delta."),
        ficha("Agente de apoio da Ordem", papel="Aliado genérico",
              classe="Especialista", nex=20, atributos=(2, 2, 2, 2, 2),
              elemento="ordem", patente="Operador",
              pericias={"Pontaria": 10, "Percepção": 10, "Medicina": 5,
                        "Tecnologia": 5},
              ataques=[atq("Pistola 9mm", "Pontaria", 8, "2d6",
                           margem="19", tipo="Balístico", alcance="Curto")],
              taticas="Cumpre ordem, não improvisa. Morre para mostrar que "
                      "a cena é séria.",
              nota="Coringa: qualquer agente sem nome que a Ordem mandar."),
        ficha("Médica de campo da Ordem", papel="Aliada genérica",
              classe="Especialista", nex=25, atributos=(2, 1, 3, 2, 2),
              elemento="ordem", patente="Operador",
              pericias={"Medicina": 15, "Ciências": 10, "Intuição": 5},
              habilidades=[hab("Estabiliza qualquer um",
                               "Tira um agente de morrendo sem teste, com "
                               "kit médico e 1 rodada.")],
              nota="Fica na retaguarda. Se o grupo a perder, perde a cura "
                   "fácil do resto da missão."),
    ])

# ------------------------------------------------- NPCs desta campanha
# Gente e criatura que só existem nesta mesa: adaptações, pontes entre as
# missões e ameaças montadas para as cenas que a campanha inventou. As que
# têm ficha oficial estão nos grupos dos livros, não aqui.
grupo(
    "NPCs desta campanha — Ato I",
    "Missões 00 a 03, NEX 0% → 15%. Os PJs são civis com 10 PV: a pressão "
    "vem de acerto e de PV das ameaças, nunca de dano alto.",
    [
        ficha("Tripulante possuído", papel="Ameaça comum",
              classe="Combatente", nex=10, atributos=(2, 3, 0, 1, 3),
              elemento="energia",
              pericias={"Luta": 5, "Fortitude": 5},
              ataques=[atq("Investida", "Luta", 6, "1d6+3", tipo="Impacto",
                           especial="Se acertar, alvo faz Fortitude DT 15 "
                                    "ou fica atordoado 1 rodada")],
              habilidades=[hab("Não sente dor",
                               "Ignora a condição debilitado.")],
              taticas="Corre para o barulho. Não recua nunca.",
              nota="Foi gente até uma hora atrás. Alguém do grupo pode "
                   "reconhecê-lo — use isso."),
        ficha("Fumaça Púrpura", papel="Criatura · ambiente da missão 00",
              classe="Ocultista", nex=15, atributos=(3, 1, 1, 3, 2),
              elemento="energia", deslocamento=12,
              pericias={"Furtividade": 15, "Ocultismo": 10},
              defesa_bonus=4,
              ataques=[atq("Descarga difusa", "Ocultismo", 8, "2d6",
                           tipo="Energia", alcance="Curto",
                           especial="Ignora proteção que não seja isolante")],
              habilidades=[hab("Corpo de vapor",
                               "Dano físico causa metade. Passa por "
                               "frestas."),
                           hab("Sufoca",
                               "Quem terminar o turno dentro dela: "
                               "Fortitude DT 15 ou perde 1d6 PV e 1 SAN.")],
              taticas="Envolve o vagão, separa o grupo, some quando "
                      "alguém abre uma janela.",
              nota="A ameaça de ambiente do trem: mede o quanto o grupo "
                   "sabe trabalhar junto no escuro."),
        ficha("Passageiro em pânico", papel="Figurante",
              classe="Mundano", nex=0, atributos=(1, 1, 1, 1, 1),
              elemento="humano",
              taticas="Atrapalha. Corre na direção errada, abre a porta "
                      "errada, grita na hora errada.",
              nota="Multiplique à vontade: o custo da missão 00 se mede em "
                   "quantos deles sobram."),
        ficha("Comissária de bordo (morta)", papel="Ameaça · missão 01",
              classe="Combatente", nex=10, atributos=(2, 2, 1, 2, 2),
              elemento="morte",
              pericias={"Luta": 5, "Enganação": 10},
              ataques=[atq("Unhas", "Luta", 6, "1d6+2", margem="19",
                           tipo="Corte")],
              habilidades=[hab("Ainda sorri",
                               "Na primeira rodada parece viva: quem "
                               "falhar em Percepção DT 15 perde a ação.")],
              taticas="Serve o carrinho, sorri, arranca uma garganta.",
              nota="O voo da morte funciona pelo contraste: cortesia até "
                   "a primeira mordida."),
        ficha("Piloto sem rosto", papel="CHEFE menor · missão 01",
              classe="Combatente", nex=15, atributos=(2, 3, 1, 2, 3),
              elemento="morte",
              pericias={"Luta": 10, "Fortitude": 10, "Pilotagem": 10},
              defesa_bonus=2,
              ataques=[atq("Machadinha da cabine", "Luta", 9, "1d8+3",
                           critico="x3", tipo="Corte")],
              habilidades=[hab("A rota é minha",
                               "Enquanto vivo, o avião não muda de curso. "
                               "Toda rodada, o piso inclina: Reflexos DT "
                               "15 ou cai."),
                           hab("CHEFE — resistência a foco",
                               "+5 Defesa a partir do 3º ataque na mesma "
                               "rodada.")],
              taticas="Luta na cabine apertada, usa a inclinação, joga "
                      "gente contra o para-brisa.",
              nota="Missão 01 é costela: não dá NEX, mas dá pânico."),
        ficha("Helena Martins", papel="Aliada que vira ameaça · missão 03",
              classe="Ocultista", nex=15, atributos=(2, 2, 2, 3, 2),
              elemento="morte",
              pericias={"Ocultismo": 10, "Vontade": 10, "Enganação": 5},
              ataques=[atq("Canção", "Ocultismo", 8, "2d6",
                           tipo="Mental", alcance="Médio",
                           especial="Vontade DT 16 ou o alvo caminha para "
                                    "o mar no próximo turno")],
              habilidades=[hab("Duas vozes",
                               "Enquanto a entidade não domina, ela pede "
                               "ajuda entre um ataque e outro. Se o grupo "
                               "acalmá-la (Diplomacia DT 20, 3 sucessos), "
                               "ela sobrevive.")],
              taticas="Ataca com dor, não com ódio. Alveja quem tentar "
                      "chegar perto do corpo da prima.",
              nota="Prima da vítima mais recente. Salvar Helena é o final "
                   "bom da missão 03 — e ela reaparece em VO2.",
              referencia="A Canção do Mar (VO1, p. 35–63)"),
        ficha("Afogado da Praia da Sereia", papel="Criatura comum",
              classe="Combatente", nex=15, atributos=(2, 3, 0, 1, 3),
              elemento="morte", deslocamento=6,
              pericias={"Luta": 5, "Atletismo": 10, "Fortitude": 5},
              ataques=[atq("Agarrão encharcado", "Luta", 8, "1d8+3",
                           tipo="Impacto",
                           especial="Se acertar, alvo fica agarrado; sair "
                                    "exige Atletismo DT 15")],
              taticas="Agarra e puxa para o mar. Nunca solta sozinho.",
              nota="Suba o número deles conforme o grupo demora a resolver "
                   "a cena da praia."),
        ficha("Pastor do abrigo", papel="CHEFE menor · missão 02",
              rituais_do_livro={"elementos": ["Conhecimento"], "circuloMax": 1,
                                "dt": 15,
                                "nota": "Conjura como ocultista de NEX 10%."},
              classe="Ocultista", nex=10, atributos=(1, 2, 3, 3, 2),
              elemento="conhecimento",
              pericias={"Diplomacia": 15, "Ocultismo": 10, "Enganação": 10,
                        "Vontade": 5},
              ataques=[atq("Bordão", "Luta", 5, "1d6+2", tipo="Impacto")],
              rituais=[rit("Palavra que acalma", "1º", "2 PE",
                           "Alvo faz Vontade DT 15 ou não pode atacar o "
                           "conjurador na próxima rodada.")],
              habilidades=[hab("O rebanho ouve",
                               "Enquanto ele fala, os fiéis não atacam. "
                               "Silenciá-lo começa a briga.")],
              taticas="Negocia, chantageia, usa os fiéis como escudo.",
              nota="Missão 02 é sobre acolhimento que cobra caro. Ele "
                   "acredita no que diz — é o que assusta."),
        ficha("Fiel do abrigo", papel="Figurante hostil",
              classe="Mundano", nex=0, atributos=(1, 2, 1, 1, 2),
              elemento="humano",
              pericias={"Luta": 5},
              ataques=[atq("Pedaço de pau", "Luta", 3, "1d6+2",
                           tipo="Impacto")],
              taticas="Só ataca quando o pastor manda. Recua se dois "
                      "caírem.",
              nota="Matar fiel é o tipo de coisa que a mesa lembra na "
                   "missão 12."),
    ])

grupo(
    "NPCs desta campanha — Ato II",
    "Missões 04 a 07, NEX 15% → 35%. O grupo já é agente: as ameaças passam "
    "a agir em conjunto e o Grupo Argento aparece de terno, não de faca.",
    [
        ficha("Regina Ferreira da Cunha", papel="CHEFE · missão 05",
              rituais_do_livro={"elementos": ["Sangue"], "circuloMax": 2, "dt": 18,
                                "nota": "Conjura como ocultista de NEX 30%."},
              classe="Ocultista", nex=30, atributos=(2, 2, 3, 4, 2),
              elemento="sangue",
              pericias={"Ocultismo": 15, "Vontade": 15, "Adestramento": 10,
                        "Enganação": 10},
              defesa_bonus=3,
              ataques=[atq("Faca curva", "Luta", 9, "1d6+3", margem="19",
                           tipo="Corte")],
              rituais=[rit("Sangue que obedece", "2º", "3 PE",
                           "Uma criatura de sangue à vista age de novo "
                           "imediatamente."),
                       rit("Talho à distância", "2º", "3 PE",
                           "3d6 de dano de Sangue; Fortitude reduz à "
                           "metade e evita o sangramento.")],
              habilidades=[hab("A matilha é minha",
                               "Criaturas de sangue num raio de 30m "
                               "recebem +2 em ataque e resistência."),
                           hab("CHEFE — iniciativa dupla",
                               "Age duas vezes por rodada."),
                           hab("CHEFE — resistência a foco",
                               "+5 Defesa do 3º ataque em diante na mesma "
                               "rodada.")],
              taticas="Fica atrás dos bichos, manda-os avançar, só encara "
                      "quando a matilha morre.",
              nota="É quem transforma o Pantanal em ritual. Se escapar, "
                   "vira recado de Giordano nas missões seguintes."),
        ficha("Julieta Argento", papel="Aliada · missão 05",
              classe="Mundano", nex=0, atributos=(1, 1, 3, 3, 1),
              elemento="humano",
              pericias={"Diplomacia": 10, "Atualidades": 5, "Profissão": 10},
              habilidades=[hab("Assina o que precisar",
                               "Consegue acesso a área privada do Grupo "
                               "Argento — uma vez, e com consequência.")],
              taticas="Não luta. Negocia até quando não devia.",
              nota="Salvá-la abre os esgotos da Villa na missão 11. É "
                   "parente do vilão e não sabe metade do que ele faz."),
        ficha("Lívia Takeda", papel="Aliada · missão 05",
              classe="Combatente", nex=25, atributos=(3, 3, 1, 2, 2),
              elemento="ordem",
              pericias={"Luta": 10, "Pontaria": 10, "Iniciativa": 10},
              ataques=[atq("Espingarda", "Pontaria", 10, "4d6",
                           tipo="Balístico", alcance="Curto")],
              taticas="Luta ao lado do grupo em Campo Grande e cobre a "
                      "retirada dos civis.",
              nota="Citada em VO2 — mantê-la viva paga depois."),
        ficha("Motorista da carga", papel="Figurante · missão 04",
              classe="Mundano", nex=0, atributos=(2, 2, 1, 1, 2),
              elemento="humano",
              pericias={"Pilotagem": 10, "Fortitude": 5},
              taticas="Dirige, xinga, entrega o patrão se for pressionado.",
              nota="A missão 04 é perseguição: ele é o volante do outro "
                   "lado."),
        ficha("Sacerdotisa da Aurora Escarlate", papel="CHEFE · missão 06",
              rituais_do_livro={"elementos": ["Sangue"], "circuloMax": 2, "dt": 18,
                                "nota": "Conjura como ocultista de NEX 30%."},
              classe="Ocultista", nex=30, atributos=(2, 2, 3, 4, 3),
              elemento="sangue",
              pericias={"Ocultismo": 15, "Vontade": 15, "Diplomacia": 10},
              defesa_bonus=4,
              ataques=[atq("Espinho ritual", "Luta", 10, "1d8+3",
                           margem="19", tipo="Perfuração")],
              rituais=[rit("Coroa de espinhos", "2º", "3 PE",
                           "Área de 6m: 2d8 de Sangue por rodada a quem "
                           "ficar dentro."),
                       rit("Colheita", "3º", "5 PE",
                           "Mata um alvo em 0 PV e cura 3d8 na "
                           "conjuradora.")],
              habilidades=[hab("CHEFE — iniciativa dupla e resistência a foco",
                               "Age duas vezes; +5 Defesa do 3º ataque em "
                               "diante na mesma rodada.")],
              taticas="Deixa os zumbis segurarem o grupo enquanto prepara "
                      "a colheita.",
              nota="Missão 06 é costela, mas é onde o culto ganha rosto "
                   "de instituição."),
        ficha("Espinho vivo", papel="Criatura · missão 06",
              classe="Combatente", nex=20, atributos=(1, 3, 0, 1, 4),
              elemento="sangue", deslocamento=0,
              pericias={"Luta": 10, "Fortitude": 10},
              defesa_bonus=2,
              ataques=[atq("Chicotada", "Luta", 10, "1d10+3", tipo="Corte",
                           alcance="3m", especial="Puxa o alvo 3m")],
              habilidades=[hab("Enraizado",
                               "Não se move. Quem passa a 3m é atacado de "
                               "graça.")],
              taticas="Controla corredor e passagem estreita.",
              nota="Bom para tirar o grupo do caminho fácil."),
        ficha("Dr. Nicácio", papel="CHEFE · missão 07",
              rituais_do_livro={"elementos": ["Conhecimento"], "circuloMax": 3,
                                "dt": 20,
                                "nota": "Conjura como ocultista de NEX 40%; dentro do manicômio, recupera 5 PE por rodada."},
              classe="Ocultista", nex=40, atributos=(2, 2, 4, 4, 3),
              elemento="conhecimento",
              pericias={"Ocultismo": 15, "Medicina": 15, "Vontade": 15,
                        "Ciências": 15, "Enganação": 10},
              defesa_bonus=4,
              ataques=[atq("Bisturi longo", "Luta", 12, "1d8+3",
                           margem="19", tipo="Perfuração")],
              rituais=[rit("Sessão de choque", "3º", "5 PE",
                           "Alvo perde 3d6 SAN e revive a pior lembrança "
                           "dele; Vontade DT 20 reduz à metade."),
                       rit("Membrana rasgada", "3º", "5 PE",
                           "Abre uma fenda: a cada rodada, uma criatura "
                           "menor entra em cena.")],
              habilidades=[hab("O manicômio é dele",
                               "Dentro do Coração das Chagas, recupera 5 "
                               "PE por rodada."),
                           hab("CHEFE — completo",
                               "Iniciativa dupla, resistência a foco e "
                               "fôlego (ver regras da mesa).")],
              taticas="Fala com cada PJ pelo nome do trauma. Só ataca "
                      "quando o grupo já está sem SAN.",
              nota="Ligado à infância de Giordano: foi ele quem ensinou o "
                   "menino a não sentir. Revela o vilão da campanha.",
              referencia="Coração da Insanidade (VO1, p. 119–141)"),
        ficha("Enfermeiro corrompido", papel="Ameaça comum · missão 07",
              classe="Combatente", nex=30, atributos=(3, 3, 1, 2, 3),
              elemento="conhecimento",
              pericias={"Luta": 15, "Medicina": 10, "Furtividade": 10},
              defesa_bonus=2,
              ataques=[atq("Seringa comprida", "Luta", 12, "1d6+3",
                           margem="19", tipo="Perfuração",
                           especial="Fortitude DT 17 ou fica lento 2 "
                                    "rodadas")],
              taticas="Aparece pelas costas, sada o mais isolado.",
              nota="Andam em dupla pelos corredores."),
        ficha("Paciente esquecido", papel="Criatura · missão 07",
              classe="Ocultista", nex=25, atributos=(2, 2, 1, 3, 2),
              elemento="medo", deslocamento=9,
              pericias={"Ocultismo": 10, "Furtividade": 15},
              ataques=[atq("Grito lembrado", "Ocultismo", 10, "2d6",
                           tipo="Mental", alcance="Curto",
                           especial="Vontade DT 17 ou perde 1d6 SAN")],
              habilidades=[hab("Repete o que ouviu",
                               "Devolve, com a voz de um PJ, uma frase "
                               "dita pela mesa nesta sessão.")],
              taticas="Não persegue. Espera na sala em que o grupo "
                      "precisa entrar.",
              nota="Ferramenta de horror, não de dano. Use um por "
                   "corredor."),
        ficha("Vigia de muitos olhos", papel="Criatura · Conhecimento",
              classe="Ocultista", nex=35, atributos=(2, 2, 4, 3, 3),
              elemento="conhecimento", deslocamento=9,
              pericias={"Percepção": 15, "Ocultismo": 15, "Vontade": 10},
              defesa_bonus=3,
              ataques=[atq("Olhar que sabe", "Ocultismo", 13, "3d6",
                           tipo="Mental", alcance="Longo",
                           especial="Revela um segredo do alvo para toda a "
                                    "cena; Vontade DT 18 evita")],
              habilidades=[hab("Não se esconde dela",
                               "Ignora Furtividade e camuflagem.")],
              taticas="Expõe segredo de PJ antes de atacar — o dano de "
                      "verdade é social.",
              nota="Perfeita para o momento em que a mesa acha que "
                   "escondeu algo bem."),
    ])

grupo(
    "NPCs desta campanha — Ato III",
    "Missões 08 a 11, NEX 35% → 65%. Agora é o Grupo Argento que caça o "
    "grupo: os chefes vêm com estrutura, dinheiro e gente.",
    [
        ficha("O Ciborgue de (Não) Siga a Luz", papel="CHEFE · missão 08",
              classe="Combatente", nex=40, atributos=(3, 5, 2, 2, 4),
              elemento="energia",
              pericias={"Luta": 15, "Pontaria": 15, "Fortitude": 15,
                        "Iniciativa": 10},
              defesa_bonus=6, protecao="Blindagem cirúrgica (+6)",
              resistencias="Resistência a balístico 5",
              ataques=[atq("Braço-serra", "Luta", 18, "2d10+5", critico="x3",
                           tipo="Corte"),
                       atq("Descarga do peito", "Pontaria", 15, "3d8",
                           tipo="Energia", alcance="Médio",
                           especial="Recarrega: só a cada 2 rodadas")],
              habilidades=[hab("Alvo travado",
                               "Escolhe um PJ no começo do combate: +3 em "
                               "ataque contra ele até que caia."),
                           hab("CHEFE — completo",
                               "Iniciativa dupla, resistência a foco e "
                               "fôlego.")],
              taticas="Persegue o alvo travado pelo hospital inteiro. "
                      "Derruba parede em vez de contornar.",
              nota="O grupo acorda sem memória e sem equipamento: ele "
                   "existe para ensinar que fugir é uma opção. A versão do "
                   "livro de regras está no grupo de Energia.",
              referencia="(Não) Siga a Luz (VO1, p. 76–95)"),
        ficha("Enfermeira da Luz", papel="Criatura · missão 08",
              classe="Ocultista", nex=35, atributos=(3, 2, 2, 4, 2),
              elemento="medo", deslocamento=9,
              pericias={"Ocultismo": 15, "Enganação": 15, "Medicina": 10},
              defesa_bonus=3,
              ataques=[atq("Convite", "Ocultismo", 13, "2d8",
                           tipo="Mental", alcance="Médio",
                           especial="Vontade DT 18 ou o alvo anda até a "
                                    "luz no fim do turno")],
              habilidades=[hab("Só quero ajudar",
                               "Se o grupo aceitar 'tratamento', cura PV "
                               "de verdade — e cobra 1d10 SAN.")],
              taticas="Nunca ataca primeiro. Oferece.",
              nota="O terror da missão 08 é aceitar ajuda."),
        ficha("Sombra de corredor", papel="Criatura comum",
              classe="Especialista", nex=30, atributos=(4, 2, 1, 3, 2),
              elemento="medo", deslocamento=12,
              pericias={"Furtividade": 15, "Luta": 10, "Reflexos": 15},
              defesa_bonus=4,
              ataques=[atq("Toque frio", "Luta", 12, "2d6",
                           tipo="Mental", especial="Alvo perde 1d4 SAN")],
              habilidades=[hab("Só existe no escuro",
                               "Sob luz forte, fica indefesa e foge.")],
              taticas="Apaga a luz, ataca, some. Repete.",
              nota="Lanterna vira recurso de sobrevivência."),
        ficha("Caetano", papel="CHEFE · missão 09",
              classe="Combatente", nex=55, atributos=(4, 4, 3, 3, 4),
              elemento="humano",
              pericias={"Luta": 15, "Pontaria": 15, "Tática": 15,
                        "Reflexos": 15, "Iniciativa": 15, "Intimidação": 10},
              defesa_bonus=5, protecao="Blindagem executiva (+5)",
              ataques=[atq("Fuzil curto", "Pontaria", 20, "2d8+4",
                           margem="19", tipo="Balístico", alcance="Médio",
                           especial="Dois disparos por ação padrão"),
                       atq("Faca tática", "Luta", 19, "1d8+4", margem="19",
                           tipo="Corte")],
              habilidades=[hab("Sai antes de perder",
                               "Com metade dos PV, gasta a ação para "
                               "escapar — e volta na próxima parte da "
                               "missão, curado."),
                           hab("CHEFE — completo",
                               "Iniciativa dupla, resistência a foco e "
                               "fôlego.")],
              taticas="Prédio: emboscada. Cassino: reféns. Alpes: terreno "
                      "e frio contra o grupo.",
              nota="Chefe de segurança de Giordano. É perseguição em três "
                   "atos — ele foge duas vezes, e isso é de propósito.",
              referencia="Perseguição Mortal (VO2, p. 9–42)"),
        ficha("Seph", papel="Ameaça · inteligência",
              classe="Especialista", nex=50, atributos=(3, 2, 4, 4, 2),
              elemento="conhecimento",
              pericias={"Investigação": 15, "Tecnologia": 15,
                        "Enganação": 15, "Percepção": 15, "Intuição": 10},
              defesa_bonus=2,
              ataques=[atq("Pistola discreta", "Pontaria", 12, "2d6",
                           margem="19", tipo="Balístico", alcance="Curto")],
              habilidades=[hab("Sabe o nome da sua mãe",
                               "Uma vez por sessão, revela uma Âncora de "
                               "um PJ e o que vai acontecer com ela."),
                           hab("Nunca está na sala",
                               "Aparece por tela, bilhete ou voz. Só "
                               "encara na missão 12.")],
              taticas="Não luta: negocia com informação e some.",
              nota="É quem levanta as Âncoras dos PJs e arma os sequestros "
                   "da missão 12. Cada aparição deve dar frio na barriga."),
        ficha("Segurança de elite do Grupo Argento", papel="Ameaça comum",
              classe="Combatente", nex=40, atributos=(3, 4, 2, 2, 3),
              elemento="humano",
              pericias={"Pontaria": 15, "Luta": 15, "Reflexos": 10,
                        "Tática": 10},
              defesa_bonus=4, protecao="Colete pesado (+4)",
              ataques=[atq("Fuzil", "Pontaria", 16, "2d8+3", margem="19",
                           tipo="Balístico", alcance="Médio"),
                       atq("Granada de luz", "Pontaria", 12, "—",
                           alcance="Curto",
                           especial="Reflexos DT 18 ou cego 1 rodada")],
              taticas="Trabalha em esquadra de quatro: dois atiram, dois "
                      "avançam.",
              nota="O padrão de tropa do Ato III."),
        ficha("Atirador do cassino", papel="Ameaça · missão 09",
              classe="Especialista", nex=40, atributos=(4, 2, 3, 2, 2),
              elemento="humano",
              pericias={"Pontaria": 15, "Furtividade": 15, "Percepção": 15},
              ataques=[atq("Rifle de precisão", "Pontaria", 17, "3d8+3",
                           critico="x3", margem="19", tipo="Balístico",
                           alcance="Longo",
                           especial="+2d8 contra alvo que não o localizou")],
              habilidades=[hab("Já estava lá",
                               "Age antes de todo mundo na primeira "
                               "rodada.")],
              taticas="Fica alto, atira em quem cura, muda de posição.",
              nota="Um por cena grande basta."),
        ficha("Mercenário dos Alpes", papel="Ameaça · missão 09",
              classe="Combatente", nex=45, atributos=(3, 4, 2, 2, 4),
              elemento="humano", deslocamento=9,
              pericias={"Luta": 15, "Pontaria": 15, "Sobrevivência": 15,
                        "Fortitude": 15},
              defesa_bonus=4, resistencias="Imune a frio",
              ataques=[atq("Metralhadora leve", "Pontaria", 17, "2d8+4",
                           tipo="Balístico", alcance="Longo",
                           especial="Suprime área de 6m: quem atravessar "
                                    "leva o dano")],
              taticas="Usa a neve: obriga o grupo a atravessar campo "
                      "aberto.",
              nota="O frio é metade da ameaça — cobre Fortitude por hora."),
        ficha("Névoa que sussurra", papel="CHEFE · missão 10",
              classe="Ocultista", nex=50, atributos=(3, 2, 3, 5, 3),
              elemento="medo", deslocamento=12,
              pericias={"Ocultismo": 15, "Furtividade": 15, "Vontade": 15},
              defesa_bonus=5, resistencias="Dano físico pela metade",
              ataques=[atq("Sussurro de dentro", "Ocultismo", 18, "4d6",
                           tipo="Mental", alcance="Longo",
                           especial="Vontade DT 20 ou perde 2d6 SAN e "
                                    "ataca o aliado mais próximo")],
              habilidades=[hab("A cidade inteira é o corpo dela",
                               "Só morre quando o grupo desfizer o que "
                               "prende a névoa a Vento Baixo — dano "
                               "sozinho não resolve."),
                           hab("CHEFE — completo",
                               "Iniciativa dupla, resistência a foco e "
                               "fôlego.")],
              taticas="Separa o grupo na bruma, imita voz de aliado, "
                      "vira PJ contra PJ.",
              nota="Missão 10 é sobre confiança: o combate é o menor dos "
                   "problemas. A criatura oficial das brumas (Xilosapien) "
                   "está no grupo das missões extras.",
              referencia="Brumas de Vento Baixo (missão extra 2)"),
        ficha("Morador enevoado", papel="Criatura comum · missão 10",
              classe="Combatente", nex=35, atributos=(2, 3, 1, 2, 3),
              elemento="medo", deslocamento=9,
              pericias={"Luta": 10, "Furtividade": 15},
              ataques=[atq("Mãos de vizinho", "Luta", 13, "2d6+3",
                           tipo="Impacto")],
              habilidades=[hab("Tem o rosto de alguém",
                               "Na primeira rodada, parece um NPC que o "
                               "grupo conhece.")],
              taticas="Ataca em silêncio, no meio da névoa.",
              nota="Use nome de NPC que a mesa gosta. Dói mais."),
        ficha("Chefe do Porto", papel="CHEFE regional · missão 11",
              classe="Especialista", nex=55, atributos=(4, 3, 4, 3, 3),
              elemento="humano",
              pericias={"Pontaria": 15, "Crime": 15, "Tática": 15,
                        "Pilotagem": 10},
              defesa_bonus=4,
              ataques=[atq("Fuzil de contrabando", "Pontaria", 20, "2d8+4",
                           margem="19", tipo="Balístico", alcance="Longo"),
                       atq("Explosivo de doca", "Pontaria", 16, "4d6",
                           tipo="Impacto", alcance="Médio",
                           especial="Área de 6m; Reflexos DT 20 reduz à "
                                    "metade")],
              habilidades=[hab("Conhece cada contêiner",
                               "Reposiciona-se 12m como ação livre uma vez "
                               "por rodada."),
                           hab("CHEFE — completo", "Iniciativa dupla, "
                               "resistência a foco e fôlego.")],
              taticas="Combate em labirinto de contêineres, nunca à vista "
                      "por duas rodadas seguidas.",
              nota="Uma das cinco frentes da Villa Argento. Os três chefes "
                   "com nome (Coveiro, Moleira, Engenheiro) estão no grupo "
                   "de Vendeta Oculta 2."),
        ficha("Chefe dos Esgotos", papel="CHEFE regional · missão 11",
              rituais_do_livro={"elementos": ["Sangue"], "circuloMax": 3, "dt": 20,
                                "nota": "Conjura como ocultista de NEX 55%."},
              classe="Ocultista", nex=55, atributos=(3, 3, 3, 4, 4),
              elemento="sangue", deslocamento=12,
              pericias={"Ocultismo": 15, "Furtividade": 15, "Fortitude": 15},
              defesa_bonus=4, resistencias="Resistência a corte 5",
              ataques=[atq("Tentáculo de esgoto", "Luta", 19, "2d10+4",
                           tipo="Impacto", alcance="6m",
                           especial="Agarra: Atletismo DT 20 para sair")],
              rituais=[rit("Maré negra", "3º", "5 PE",
                           "Inunda 9m: quem estiver dentro perde 2d8 e "
                           "não pode correr.")],
              habilidades=[hab("CHEFE — completo", "Iniciativa dupla, "
                               "resistência a foco e fôlego.")],
              taticas="Luta na água suja, puxa gente para o fundo.",
              nota="É por aqui que Julieta salva o grupo — se ela estiver "
                   "viva."),
        ficha("Servo da Villa", papel="Ameaça comum · missão 11",
              classe="Combatente", nex=45, atributos=(3, 3, 1, 2, 3),
              elemento="sangue",
              pericias={"Luta": 15, "Fortitude": 10},
              defesa_bonus=3,
              ataques=[atq("Ferramenta de trabalho", "Luta", 16, "2d6+3",
                           tipo="Corte")],
              taticas="Vem aos seis. Não fala, não recua.",
              nota="Encha a Villa com eles: a sensação tem que ser de "
                   "lugar habitado por gente errada."),
    ])

grupo(
    "NPCs desta campanha — Ato IV",
    "Missão 12, NEX 65% → 80%. Tudo cobra: as Âncoras viram reféns. As "
    "fichas do próprio Giordano estão nos grupos dos livros.",
    [
        ficha("Pretoriano do Argento", papel="Ameaça de elite",
              classe="Combatente", nex=60, atributos=(4, 5, 2, 3, 4),
              elemento="humano",
              pericias={"Luta": 15, "Pontaria": 15, "Reflexos": 15,
                        "Tática": 15},
              defesa_bonus=6, protecao="Blindagem de corpo inteiro (+6)",
              ataques=[atq("Fuzil pesado", "Pontaria", 22, "3d8+4",
                           margem="19", tipo="Balístico", alcance="Longo"),
                       atq("Escudo", "Luta", 20, "1d8+5", tipo="Impacto",
                           especial="Empurra 3m")],
              habilidades=[hab("Morre no lugar dele",
                               "Reação: toma para si um ataque feito "
                               "contra Giordano.")],
              taticas="Fica entre o patrão e o grupo. Sempre.",
              nota="Três deles fazem a missão 12 parecer guerra."),
        ficha("Entidade do Medo antigo", papel="Criatura de clímax",
              classe="Ocultista", nex=70, atributos=(3, 4, 4, 6, 4),
              elemento="medo", deslocamento=12,
              pericias={"Ocultismo": 15, "Vontade": 15, "Furtividade": 15},
              defesa_bonus=6, resistencias="Dano físico pela metade",
              ataques=[atq("O que você mais teme", "Ocultismo", 24, "6d6",
                           tipo="Mental", alcance="Longo",
                           especial="Usa a Fobia anotada na ficha do PJ; "
                                    "Vontade DT 24 reduz à metade")],
              habilidades=[hab("Só existe enquanto olham",
                               "Um PJ que fechar os olhos não pode ser "
                               "alvo dela — mas também não age.")],
              taticas="Ataca a aba Sobre das fichas: fobias, pior "
                      "pesadelo, primeiro encontro paranormal.",
              nota="Coringa de clímax para qualquer campanha, não só "
                   "esta."),
    ])

# ---------------------------------------------------------------- coringas
grupo(
    "Figurantes de qualquer cena",
    "Gente comum. Serve para qualquer missão, em qualquer NEX: são o mundo "
    "que os agentes juraram proteger.",
    [
        ficha("Delegado de plantão", papel="Figurante",
              classe="Mundano", nex=0, atributos=(1, 1, 3, 3, 1),
              elemento="humano",
              pericias={"Investigação": 10, "Intuição": 5, "Diplomacia": 5},
              taticas="Quer processo, assinatura e explicação.",
              nota="Porta de entrada de investigação — ou parede."),
        ficha("Repórter insistente", papel="Figurante",
              classe="Mundano", nex=0, atributos=(2, 1, 3, 3, 1),
              elemento="humano",
              pericias={"Investigação": 10, "Diplomacia": 10,
                        "Percepção": 5},
              habilidades=[hab("Já publiquei",
                               "O que ela vir vai ao ar na próxima cena.")],
              taticas="Segue o grupo, filma, pergunta o que não devia.",
              nota="Ótima para transformar sucesso em problema."),
        ficha("Médico de plantão", papel="Figurante",
              classe="Mundano", nex=0, atributos=(1, 1, 3, 2, 2),
              elemento="humano",
              pericias={"Medicina": 15, "Ciências": 10},
              taticas="Trata quem chegar. Faz perguntas sobre o ferimento "
                      "estranho.",
              nota="A desculpa que o grupo dá aqui vira problema depois."),
        ficha("Enfermeiro do turno da noite", papel="Figurante",
              classe="Mundano", nex=0, atributos=(2, 2, 2, 2, 2),
              elemento="humano",
              pericias={"Medicina": 10, "Percepção": 5},
              nota="Vê tudo, fala pouco, dorme mal."),
        ficha("Motorista de aplicativo", papel="Figurante",
              classe="Mundano", nex=0, atributos=(2, 1, 2, 2, 1),
              elemento="humano",
              pericias={"Pilotagem": 10, "Atualidades": 5},
              taticas="Leva o grupo a qualquer lugar por dinheiro — até "
                      "ver sangue.",
              nota="Testemunha involuntária número um da campanha."),
        ficha("Segurança de prédio", papel="Figurante",
              classe="Mundano", nex=0, atributos=(2, 2, 1, 1, 2),
              elemento="humano",
              pericias={"Percepção": 5, "Luta": 5},
              ataques=[atq("Cassetete", "Luta", 4, "1d6+2", tipo="Impacto")],
              nota="Tem a chave que o grupo precisa e um turno de 12 "
                   "horas."),
        ficha("Vizinha curiosa", papel="Figurante",
              classe="Mundano", nex=0, atributos=(1, 1, 2, 3, 1),
              elemento="humano",
              pericias={"Percepção": 10, "Intuição": 5},
              habilidades=[hab("Viu tudo pela janela",
                               "Sabe um detalhe verdadeiro e dois "
                               "inventados.")],
              nota="A melhor fonte de pista errada que existe."),
        ficha("Criança do bairro", papel="Figurante",
              classe="Mundano", nex=0, atributos=(2, 0, 1, 2, 1),
              elemento="humano", deslocamento=9,
              pericias={"Furtividade": 5, "Percepção": 5},
              nota="Use com cuidado: criança em cena de horror muda o "
                   "tom da mesa inteira. Combine na sessão zero."),
        ficha("Idoso que lembra", papel="Figurante",
              classe="Mundano", nex=0, atributos=(0, 1, 3, 2, 1),
              elemento="humano", deslocamento=6,
              pericias={"Atualidades": 10, "Ocultismo": 5},
              habilidades=[hab("Isso já aconteceu antes",
                               "Conta um fato verdadeiro de 40 anos atrás "
                               "que ninguém registrou.")],
              nota="Ponte de lore barata e boa."),
        ficha("Advogado do Grupo Argento", papel="Figurante hostil",
              classe="Mundano", nex=0, atributos=(1, 1, 4, 4, 1),
              elemento="humano",
              pericias={"Diplomacia": 15, "Enganação": 15,
                        "Atualidades": 10},
              habilidades=[hab("Ordem judicial",
                               "Encerra uma cena de investigação sem "
                               "violência — e o grupo não pode voltar "
                               "àquele lugar legalmente.")],
              taticas="Chega sorrindo, com papel na mão e câmera atrás.",
              nota="O golpe mais frustrante do Ato II. É de propósito."),
    ])


# ==================================================== ameaças dos livros
# Aqui o bestiário para de ser invenção e passa a ser a ficha real: os
# números vêm do extrator (App-Mestre/ferramentas/extrair_ameacas.py, que lê
# o PDF de quem tem o livro) e o texto das habilidades vem de
# notacao_ameacas.py, escrito à mão em notação de mesa.

AMEACAS_CRU = os.path.join(RAIZ, "..", "..", "Ordem", "App-Mestre", "dados",
                           "ameacas-cru.json")

ELEMENTO_POR_GRUPO = {
    "Sangue": "sangue", "Morte": "morte", "Conhecimento": "conhecimento",
    "Energia": "energia", "Medo": "medo",
    "Gente e tropa": "humano", "Animais": "humano",
    "Vendeta Oculta": "sangue", "Vendeta Oculta 2": "morte",
    "Casos Paranormais": "conhecimento", "Missões extras": "energia",
}

ORDEM_GRUPOS = [
    ("Ameaças de Sangue", "Sangue",
     "O elemento do corpo e da fome. Vulneráveis a Morte."),
    ("Ameaças de Morte", "Morte",
     "Lodo, tempo e corpos que não param. Vulneráveis a Energia."),
    ("Ameaças de Conhecimento", "Conhecimento",
     "O que sabe demais sobre você. Vulneráveis a Sangue."),
    ("Ameaças de Energia", "Energia",
     "Movimento sem controle. Vulneráveis a Conhecimento."),
    ("Gente e tropa", "Gente e tropa",
     "Capangas, mercenários, cultistas e polícia — as ameaças sem nada de "
     "paranormal, e por isso as mais frequentes."),
    ("Animais", "Animais", "Bicho comum, do cão de guarda à sucuri."),
    ("Vendeta Oculta — NPCs e criaturas", "Vendeta Oculta",
     "As ameaças nomeadas da primeira temporada."),
    ("Vendeta Oculta 2 — NPCs e criaturas", "Vendeta Oculta 2",
     "A Villa Argento e o que mora nela."),
    ("Casos Paranormais", "Casos Paranormais",
     "As ameaças das missões avulsas."),
    ("Missões extras", "Missões extras",
     "O Voo da Morte e as Brumas de Vento Baixo."),
]

PERICIA_POR_TESTE = {
    "percepção": "Percepção", "iniciativa": "Iniciativa",
    "fortitude": "Fortitude", "reflexos": "Reflexos", "vontade": "Vontade",
}

PERICIA_CORRIGIDA = {
    "Ciência": "Ciências", "Ciências": "Ciências", "Ocultismo": "Ocultismo",
    "Furtividade": "Furtividade", "Atletismo": "Atletismo",
    "Enganação": "Enganação", "Sobrevivência": "Sobrevivência",
    "Religião": "Religião", "Luta": "Luta", "Pontaria": "Pontaria",
    "Percepção": "Percepção", "Iniciativa": "Iniciativa",
    "Fortitude": "Fortitude", "Reflexos": "Reflexos", "Vontade": "Vontade",
    "Intuição": "Intuição", "Investigação": "Investigação",
    "Medicina": "Medicina", "Tecnologia": "Tecnologia", "Crime": "Crime",
    "Diplomacia": "Diplomacia", "Tática": "Tática",
    "Intimidação": "Intimidação", "Acrobacia": "Acrobacia",
    "Pilotagem": "Pilotagem", "Profissão": "Profissão",
    "Adestramento": "Adestramento", "Artes": "Artes",
    "Atualidades": "Atualidades", "Iniciativa": "Iniciativa",
}


def sem_acento(texto):
    return unicodedata.normalize("NFKD", texto).encode(
        "ascii", "ignore").decode()


def carrega_ameacas():
    if not os.path.exists(AMEACAS_CRU):
        return {}
    with open(AMEACAS_CRU, encoding="utf-8") as fh:
        bruto = json.load(fh)
    por_chave = {}
    for a in bruto:
        chave = "%s:%s:%s" % (a["fonte"], a["pagina"], a["pv"])
        # duas fichas na mesma página com o mesmo PV: a segunda vira "…b"
        if chave in por_chave:
            chave += "b"
        por_chave[chave] = a
    return por_chave


def pericia_de_alcance(alcance):
    return "Pontaria" if "dist" in alcance.lower() else "Luta"


def ficha_de_ameaca(notacao, cru):
    """Junta os números do livro com a notação escrita aqui."""
    base = dict(cru or {})
    base.update(notacao.get("manual", {}))
    if not base:
        return None

    nome = notacao["nome"]
    grupo_nome = notacao["grupo"]
    atributos = base.get("atributos") or {
        "AGI": 1, "FOR": 1, "INT": 1, "PRE": 1, "VIG": 1}

    # perícias: o teste impresso vira grau. O app rola (atributo)d20 + grau,
    # que é exatamente o "3⬡+10" do livro.
    pericias = {}
    # bônus 0 não entra: na ficha do app, grau 0 é "destreinado", e o
    # resultado da rolagem é o mesmo (só os dados do atributo).
    for chave_teste, valor in (base.get("testes") or {}).items():
        nome_p = PERICIA_POR_TESTE.get(chave_teste)
        if nome_p and valor["bonus"] > 0:
            pericias[nome_p] = valor["bonus"]
    for nome_p, valor in (base.get("pericias") or {}).items():
        certo = PERICIA_CORRIGIDA.get(nome_p)
        if certo and valor["bonus"] > 0:
            pericias[certo] = valor["bonus"]

    ataques = []
    for a in notacao.get("ataques") or []:
        nome_a, alcance, dados, bonus, dano, critico = a
        ataques.append({
            "nome": nome_a, "pericia": pericia_de_alcance(alcance),
            "bonus": 0, "dadosTeste": dados, "bonusTeste": bonus,
            "dano": dano, "critico": critico, "margem": "", "tipo": "",
            "alcance": alcance, "especial": "",
        })
    if not ataques:
        for a in base.get("ataques") or []:
            ataques.append({
                "nome": a["nome"],
                "pericia": pericia_de_alcance(a["alcance"]),
                "bonus": 0,
                "dadosTeste": a["dados"], "bonusTeste": a["bonus"],
                "dano": a["dano"],
                "critico": a.get("critico", ""),
                "margem": "",
                "tipo": "",
                "alcance": (a["alcance"] + " " + a.get("extra", "")).strip(),
                "especial": "",
            })

    habilidades = [
        {"nome": "%s (%s)" % (h[1], h[0].lower()), "descricao": h[2]}
        for h in notacao.get("habilidades", [])
    ]

    rituais = []
    if notacao.get("rituais"):
        rituais.append({"nome": "Rituais", "circulo": "", "custo": "",
                        "execucao": "", "alcance": "", "duracao": "",
                        "descricao": notacao["rituais"]})
    # "conjura todos os rituais de Morte até o 3º círculo" vira a LISTA dos
    # rituais, um por um, com custo e efeito — no meio da cena ninguém quer
    # abrir o livro para lembrar o que cada um faz
    filtro = notacao.get("rituaisDoLivro")
    if filtro:
        rituais.extend(rituais_do_catalogo(filtro))

    presenca = ""
    p = base.get("presenca")
    if p:
        presenca = "DT %s · %s mental" % (p["dt"], p["dano"])
        if p.get("nexImune"):
            presenca += " · NEX %s%%+ é imune" % p["nexImune"]

    # a diagramação de alguns cartões esconde a categoria do extrator; a
    # notação preenche à mão nesses casos
    categoria = notacao.get("categoria") or base.get("tipo") or ""
    tamanho = notacao.get("tamanho") or base.get("tamanho") or ""
    elemento = notacao.get("elemento") or base.get("elemento") or ""
    papel = " · ".join(x for x in [categoria, tamanho, elemento] if x) \
        or "Ameaça"

    fonte = base.get("fonte", "")
    pagina = base.get("pagina", "")
    referencia = ("%s p. %s" % (fonte, pagina)) if fonte else ""

    f = {
        "id": "bestiario-" + slug(nome),
        "tipo": "npc", "modoLivre": True,
        "nome": nome,
        "jogador": papel,
        "classe": "Mundano", "trilha": "", "origem": "", "patente": "Recruta",
        "nex": 0,
        "deslocamento": base.get("deslocamento") or 9,
        "atributos": atributos,
        "pv": base["pv"], "san": 0, "pe": 0,
        "pvMaxManual": base["pv"], "sanMaxManual": 0, "peMaxManual": 0,
        "defesaBonus": 0,
        "defesaManual": base.get("defesa"),
        "vd": base.get("vd"),
        "categoria": categoria, "tamanho": tamanho, "elemento": elemento,
        "sentidos": base.get("sentidos", ""),
        "presenca": presenca,
        "protecao": "",
        "resistencias": base.get("resistencias", ""),
        "vulnerabilidades": base.get("vulnerabilidades", ""),
        "pericias": pericias,
        "ataques": ataques,
        "habilidades": habilidades,
        "rituais": rituais,
        "inventario": [], "nacionalidade": "", "idade": 0,
        "proficiencias": [],
        "emCombate": False, "morto": False,
        "ocultarPv": False, "ocultarSan": False, "ocultarPe": False,
        "historia": "",
        "aparencia": "", "primeiroEncontro": "", "fobias": "",
        "favoritos": "", "personalidade": "", "piorPesadelo": "",
        "anotacoes": (
            ("TÁTICA: " + notacao["tatica"] + "\n\n")
            if notacao.get("tatica") else "")
        + (("A ficha oficial está em %s. Os números aqui saem dela; o texto "
            "das habilidades foi reescrito em notação de mesa." % referencia)
           if referencia else ""),
        "retrato": monograma(nome, ELEMENTO_POR_GRUPO.get(grupo_nome,
                                                          "humano")),
        "criadaEm": "2026-08-19T00:00:00.000",
    }
    if f["defesaManual"] is None:
        del f["defesaManual"]
    if f["vd"] is None:
        del f["vd"]
    return f


def grupos_das_ameacas():
    from notacao_ameacas import NOTACAO
    cru = carrega_ameacas()
    por_grupo = {}
    faltando = []
    for chave, notacao in NOTACAO.items():
        pronta = ficha_de_ameaca(notacao, cru.get(chave))
        if pronta is None:
            faltando.append(chave)
            continue
        por_grupo.setdefault(notacao["grupo"], []).append(pronta)

    saida = []
    for titulo, chave_grupo, descricao in ORDEM_GRUPOS:
        fichas = sorted(por_grupo.get(chave_grupo, []),
                        key=lambda f: sem_acento(f["nome"].lower()))
        if fichas:
            saida.append({"nome": titulo, "descricao": descricao,
                          "fichas": fichas})
    return saida, faltando


def main():
    ameacas, faltando = grupos_das_ameacas()
    if faltando:
        print("sem números (rode extrair_ameacas.py): %s"
              % ", ".join(faltando), file=sys.stderr)
    # as ameaças do livro entram entre os aliados e os figurantes
    GRUPOS[1:1] = ameacas

    total = sum(len(g["fichas"]) for g in GRUPOS)
    ids = [f["id"] for g in GRUPOS for f in g["fichas"]]
    repetidos = {i for i in ids if ids.count(i) > 1}
    if repetidos:
        raise SystemExit("ids repetidos: %s" % sorted(repetidos))

    os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
    with open(SAIDA, "w", encoding="utf-8") as fh:
        json.dump({
            "versao": 1,
            "aviso": "Conteúdo não oficial sob a Licença da Comunidade de "
                     "Ordem Paranormal. Mecânica escrita para esta mesa; "
                     "nenhum texto de livro reproduzido.",
            "grupos": GRUPOS,
        }, fh, ensure_ascii=False, separators=(",", ":"))

    kb = os.path.getsize(SAIDA) // 1024
    print("ok: %d fichas em %d grupos (%d KB)" % (total, len(GRUPOS), kb))


if __name__ == "__main__":
    main()
