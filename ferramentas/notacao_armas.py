# -*- coding: utf-8 -*-
"""
Notação das armas e do que anda junto delas (OPRPG v1.3, cap. 3).

Os NÚMEROS da tabela (dano, crítico, alcance, tipo, categoria, espaços) vêm
do extrator, lidos do PDF de quem tem o livro. Aqui fica o que a tabela não
diz e a mesa precisa: habilidades (ágil, automática, arremesso), regras
especiais e uma descrição de uma linha — tudo escrito à mão, em notação de
mesa. Nenhuma frase do livro é copiada (licença da comunidade).

Páginas: tabela e características p. 54–55; descrições p. 58–59; munições
p. 59; modificações p. 60–61; equipamento geral p. 63–66; maldições de arma
p. 145–146.
"""

AGIL = "Ágil: use Agilidade no lugar de Força no ataque e no dano."
AUTOMATICA = ("Automática: tiro normal ou rajada (−1d20 no ataque, +1 dado "
              "de dano do mesmo tipo).")
ARREMESSO = "Arremessável em alcance curto (Pontaria; soma Força no dano)."
RECARGA = "Recarga: ação de movimento a cada disparo."

# Por arma: descrição curta, regras especiais e as flags que a ficha usa
# nas contas. municao = nome da munição da Tabela 3.4.
ARMAS = {
    "Coronhada": dict(
        desc="Golpe com a própria arma de fogo, usada como porrete.",
        especial=["1d4 com arma de fogo leve ou de uma mão; 1d6 com arma "
                  "de duas mãos."],
    ),
    "Faca": dict(
        desc="Lâmina curta: navalha, faca de churrasco, faca militar.",
        especial=[AGIL, ARREMESSO, "Faca pequena de cozinha: dano 1d3."],
        agil=True, arremesso=True,
    ),
    "Martelo": dict(
        desc="Ferramenta comum que serve de arma quando não há outra.",
    ),
    "Punhal": dict(
        desc="Faca de lâmina longa e pontuda, comum nos rituais de "
             "cultistas.",
        especial=[AGIL], agil=True,
    ),
    "Bastão": dict(
        desc="Madeira maciça: taco, cassetete, tonfa ou clava com pregos.",
        especial=["1d6 com uma mão; 1d8 com as duas."],
    ),
    "Machete": dict(
        desc="Lâmina longa e larga de abrir trilha no mato.",
    ),
    "Lança": dict(
        desc="Haste de madeira com ponta de metal.",
        especial=[ARREMESSO], arremesso=True,
    ),
    "Cajado": dict(
        desc="Haste longa de madeira ou barra de ferro (inclui o bo).",
        especial=[AGIL, "Com Combater com Duas Armas, conta como uma arma de "
                  "uma mão + uma leve."],
        agil=True,
    ),
    "Arco": dict(
        desc="Arco e flecha comum, de tiro ao alvo.",
        municao="Flechas",
    ),
    "Besta": dict(
        desc="Besta antiga, de disparo mecânico.",
        especial=[RECARGA], municao="Flechas",
    ),
    "Pistola": dict(
        desc="Arma de mão de polícia e militares; recarrega rápido.",
        municao="Balas curtas",
    ),
    "Revólver": dict(
        desc="A arma de fogo mais comum, e das mais confiáveis.",
        municao="Balas curtas",
    ),
    "Fuzil de caça": dict(
        desc="Fuzil de fazendeiro, caçador e atirador esportivo.",
        municao="Balas longas",
    ),
    "Machadinha": dict(
        desc="Machado pequeno de cortar lenha, comum em obra e fazenda.",
        especial=[ARREMESSO], arremesso=True,
    ),
    "Nunchaku": dict(
        desc="Dois bastões curtos ligados por corrente.",
        especial=[AGIL], agil=True,
    ),
    "Corrente": dict(
        desc="Pedaço de corrente grossa usado como chicote pesado.",
        especial=["+2 em testes para desarmar e derrubar."],
    ),
    "Espada": dict(
        desc="Espada longa medieval ou cimitarra.",
        especial=["1d8 com uma mão; 1d10 com as duas."],
    ),
    "Florete": dict(
        desc="Espada fina e comprida de esgrima.",
        especial=[AGIL], agil=True,
    ),
    "Machado": dict(
        desc="Machado de lenhador ou de bombeiro.",
    ),
    "Maça": dict(
        desc="Bastão com cabeça de metal cheia de pontas.",
    ),
    "Acha": dict(
        desc="Machado grande e pesado, de derrubar árvore grossa.",
    ),
    "Gadanho": dict(
        desc="Foice grande de duas mãos, de ceifar cereal.",
    ),
    "Katana": dict(
        desc="Espada japonesa longa e levemente curva.",
        especial=[AGIL, "Veterano em Luta: pode usar com uma mão."],
        agil=True,
    ),
    "Marreta": dict(
        desc="Marreta de demolição; vale também para picareta e outras "
             "ferramentas de obra.",
    ),
    "Montante": dict(
        desc="Espadão de 1,5 m, enorme e pesado.",
    ),
    "Motosserra": dict(
        desc="Ferramenta motorizada de corte; desajeitada, mas brutal.",
        especial=["−1d20 nos testes de ataque.",
                  "Cada 6 num dado de dano: role mais um dado.",
                  "Ligar: ação de movimento."],
        penalidadeDados=1,
    ),
    "Arco composto": dict(
        desc="Arco moderno de roldanas e materiais de alta tensão.",
        especial=["Soma Força no dano (exceção entre as armas de "
                  "disparo)."],
        somaForca=True, municao="Flechas",
    ),
    "Balestra": dict(
        desc="Besta pesada, de disparo potente.",
        especial=[RECARGA], municao="Flechas",
    ),
    "Submetralhadora": dict(
        desc="Arma automática que dá para usar com uma mão só.",
        especial=[AUTOMATICA], automatica=True, municao="Balas curtas",
    ),
    "Espingarda": dict(
        desc="Arma longa de cano liso que dispara chumbo.",
        especial=["Metade do dano em alcance médio ou maior."],
        municao="Cartuchos",
    ),
    "Fuzil de assalto": dict(
        desc="O fuzil padrão dos exércitos modernos.",
        especial=[AUTOMATICA], automatica=True, municao="Balas longas",
    ),
    "Fuzil de precisão": dict(
        desc="Fuzil militar feito para tiro longo e preciso.",
        especial=["Veterano em Pontaria e mirando: +5 na margem de "
                  "ameaça."],
        municao="Balas longas",
    ),
    "Bazuca": dict(
        desc="Lança-foguetes antitanque, eficaz contra criaturas.",
        especial=["Acerta o alvo e todos num raio de 3 m; os outros (não o "
                  "alvo) fazem Reflexos DT Agi para metade.",
                  "Ou mire num ponto em alcance médio: sem teste, não erra, "
                  "mas não acerta ninguém em cheio.",
                  RECARGA],
        municao="Foguete",
    ),
    "Lança-chamas": dict(
        desc="Esguicha líquido inflamável em chamas.",
        especial=["Linha de 1,5 m de largura até alcance curto (não passa "
                  "disso).",
                  "Um teste de ataque contra a Defesa de todos na linha.",
                  "Quem é atingido fica em chamas."],
        municao="Combustível",
    ),
    "Metralhadora": dict(
        desc="Arma de fogo pesada, de uso militar.",
        especial=[AUTOMATICA,
                  "Precisa de Força 4+ ou de uma ação de movimento para "
                  "apoiar no tripé; senão, −5 nos ataques."],
        automatica=True, municao="Balas longas",
    ),
}

# Tabela 3.4 (p. 59). Um pacote dura o tempo indicado, não importa quantos
# tiros.
MUNICOES = [
    dict(nome="Balas curtas", categoria="0", espacos="1",
         duracao="2 cenas", usadaEm="Pistola, revólver, submetralhadora"),
    dict(nome="Balas longas", categoria="I", espacos="1",
         duracao="1 cena", usadaEm="Fuzis e metralhadora"),
    dict(nome="Cartuchos", categoria="I", espacos="1",
         duracao="1 cena", usadaEm="Espingarda"),
    dict(nome="Combustível", categoria="I", espacos="1",
         duracao="1 cena", usadaEm="Lança-chamas"),
    dict(nome="Flechas", categoria="0", espacos="1",
         duracao="1 missão (dá para recolher)",
         usadaEm="Arcos, besta e balestra"),
    dict(nome="Foguete", categoria="I", espacos="1",
         duracao="1 disparo cada", usadaEm="Bazuca"),
]

# Tabela 3.5 (p. 60–61). Cada uma sobe a categoria da arma em I; iguais não
# acumulam.
MODIFICACOES = [
    dict(nome="Certeira", para="Corpo a corpo e disparo",
         efeitos={"ataque": 2},
         efeito="+2 nos testes de ataque."),
    dict(nome="Cruel", para="Corpo a corpo e disparo",
         efeitos={"dano": 2},
         efeito="+2 nas rolagens de dano."),
    dict(nome="Discreta", para="Corpo a corpo e disparo",
         efeitos={"espacos": -1},
         efeito="+5 em Crime para esconder (mesmo sem treino) e −1 espaço."),
    dict(nome="Perigosa", para="Corpo a corpo e disparo",
         efeitos={"margem": 2},
         efeito="+2 na margem de ameaça."),
    dict(nome="Tática", para="Corpo a corpo e disparo",
         efeitos={},
         efeito="Sacar é ação livre."),
    dict(nome="Alongada", para="Armas de fogo",
         efeitos={"ataque": 2},
         efeito="+2 nos testes de ataque."),
    dict(nome="Calibre grosso", para="Armas de fogo",
         efeitos={"dadoArma": 1},
         efeito="+1 dado de dano do mesmo tipo; exige munição de calibre "
                "grosso (mesma categoria)."),
    dict(nome="Compensador", para="Armas de fogo",
         efeitos={"compensador": True}, so="automatica",
         efeito="Só automáticas: anula o −1d20 da rajada."),
    dict(nome="Discreta", para="Armas de fogo",
         efeitos={"espacos": -1},
         efeito="+5 em Crime para esconder (mesmo sem treino) e −1 espaço."),
    dict(nome="Ferrolho automático", para="Armas de fogo",
         efeitos={"automatica": True},
         efeito="A arma vira automática."),
    dict(nome="Mira laser", para="Armas de fogo",
         efeitos={"margem": 2},
         efeito="+2 na margem de ameaça."),
    dict(nome="Mira telescópica", para="Armas de fogo",
         efeitos={"alcance": 1},
         efeito="Alcance sobe uma categoria; Ataque Furtivo vale em "
                "qualquer alcance."),
    dict(nome="Silenciador", para="Armas de fogo",
         efeitos={},
         efeito="Tira 2 d20 da penalidade de Furtividade para se esconder "
                "no turno em que atirou."),
    dict(nome="Tática", para="Armas de fogo",
         efeitos={},
         efeito="Sacar é ação livre."),
    dict(nome="Visão de calor", para="Armas de fogo",
         efeitos={},
         efeito="Ao atirar, ignora a camuflagem do alvo."),
    dict(nome="Dum dum", para="Munição",
         efeitos={"multiplicador": 1}, so="balas",
         efeito="Só balas curtas e longas: +1 no multiplicador de crítico."),
    dict(nome="Explosiva", para="Munição",
         efeitos={"danoExtra": "2d6"}, so="balas",
         efeito="Só balas curtas e longas: +2d6 de dano."),
]

# efeitos = o que a ficha aplica sozinha no ataque: ataque/dano/margem/
# multiplicador (números), dadoArma (+N dados do tipo da arma), danoExtra
# (dados que NÃO multiplicam no crítico), dadosArmaExtra (dados que
# multiplicam), alcance (+N categorias), espacos, automatica, compensador,
# margemDobra. "so" restringe: automatica, balas (curtas/longas), corpo.
# O resto do efeito (gasto de PE, condição) fica no texto para o jogador.

# p. 145–146. 1ª maldição sobe a categoria em II, as seguintes em I. Só para
# Agente Especial em diante. Preço: cada maldição custa 2 SAN quando o
# portador falha num teste do atributo do elemento.
MALDICOES = [
    dict(nome="Antielemento", elemento="Conhecimento",
         efeitos={},
         efeito="Contra criatura de um elemento (1d4: Con, Ene, Mor, San): "
                "2 PE e acertou → +4d8 de dano."),
    dict(nome="Ritualística", elemento="Conhecimento",
         efeitos={},
         efeito="Guarda um ritual (paga os PE na hora); ao acertar, solta "
                "como ação livre no alvo."),
    dict(nome="Senciente", elemento="Conhecimento",
         efeitos={},
         efeito="Movimento + 2 PE: a arma flutua e ataca sozinha 1×/rodada "
                "em alcance curto. Manter: 1 PE por turno."),
    dict(nome="Empuxo", elemento="Energia",
         efeitos={}, so="corpo",
         efeito="Só corpo a corpo: arremessável (alcance +1 categoria se já "
                "era), +1 dado no arremesso e volta para a mão."),
    dict(nome="Energética", elemento="Energia",
         efeitos={},
         efeito="2 PE por ataque: +5 no ataque, ignora RD e o dano vira "
                "Energia."),
    dict(nome="Vibrante", elemento="Energia",
         efeitos={},
         efeito="Ganha Ataque Extra (Operações Especiais); se já tem, custa "
                "−1 PE."),
    dict(nome="Consumidora", elemento="Morte",
         efeitos={},
         efeito="Alvo atingido fica lento até o fim da cena; 2 PE e acertou "
                "→ imóvel por 1 rodada."),
    dict(nome="Erosiva", elemento="Morte",
         efeitos={"danoExtra": "1d8"},
         efeito="+1d8 de dano de Morte; 2 PE e acertou → +2d4 de Morte no "
                "início dos turnos dele por 2 rodadas."),
    dict(nome="Repulsora", elemento="Morte",
         efeitos={},
         efeito="+2 Defesa empunhada; ao bloquear, 2 PE → mais +5 Defesa."),
    dict(nome="Lancinante", elemento="Sangue",
         efeitos={"dadosArmaExtra": "1d8"},
         efeito="+1d8 de dano de Sangue, que multiplica no crítico."),
    dict(nome="Predadora", elemento="Sangue",
         efeitos={"margemDobra": True, "alcance": 1},
         efeito="Ignora camuflagem e cobertura leves; distância: alcance +1 "
                "categoria; a margem de ameaça dobra."),
    dict(nome="Sanguinária", elemento="Sangue",
         efeitos={},
         efeito="Atingido fica sangrando (acumula); no crítico o alvo fica "
                "fraco e você ganha 2d10 PV temporários."),
]

# Equipamento geral que se usa para atacar (Tabela 3.8, p. 63–66). Os que
# têm dano entram na ficha como ataque; o resto vira item.
ITENS_DE_ATAQUE = [
    dict(nome="Granada de atordoamento", categoria="0", espacos="1",
         alcance="Médio", area="Raio de 6 m",
         efeito="Atordoados por 1 rodada (Fortitude DT Agi: só ofuscado e "
                "surdo por 1 rodada).",
         uso="Empunhar + ação padrão para arremessar num ponto."),
    dict(nome="Granada de fragmentação", categoria="I", espacos="1",
         alcance="Médio", area="Raio de 6 m", dano="8d6", tipo="P",
         resistencia="Reflexos DT Agi reduz à metade",
         efeito="8d6 de perfuração em todos na área.",
         uso="Empunhar + ação padrão para arremessar num ponto."),
    dict(nome="Granada de fumaça", categoria="0", espacos="1",
         alcance="Médio", area="Raio de 6 m",
         efeito="Quem está na área fica cego e com camuflagem total por 2 "
                "rodadas.",
         uso="Empunhar + ação padrão para arremessar num ponto."),
    dict(nome="Granada incendiária", categoria="I", espacos="1",
         alcance="Médio", area="Raio de 6 m", dano="6d6", tipo="F",
         resistencia="Reflexos DT Agi reduz à metade e evita as chamas",
         efeito="6d6 de fogo e em chamas.",
         uso="Empunhar + ação padrão para arremessar num ponto."),
    dict(nome="Mina antipessoal", categoria="I", espacos="1",
         alcance="Longo (detonar)", area="Cone de 6 m", dano="12d6",
         tipo="P", resistencia="Reflexos DT Int reduz à metade",
         efeito="12d6 de perfuração no cone (você escolhe a direção ao "
                "instalar).",
         uso="Instalar: ação completa + Tática DT 15 (falhou, perde a "
             "mina). Detonar: ação padrão até alcance longo. Achar: "
             "Percepção contra o seu teste."),
    dict(nome="Soqueira", categoria="0", espacos="1",
         efeito="+1 no dano desarmado, que passa a ser letal. Aceita "
                "modificações e maldições de arma corpo a corpo.",
         uso="Usada entre os dedos."),
    dict(nome="Spray de pimenta", categoria="I", espacos="1",
         alcance="Adjacente",
         efeito="Cego por 1d4 rodadas (Fortitude DT Agi evita). 2 usos.",
         uso="Ação padrão contra um ser adjacente."),
    dict(nome="Taser", categoria="I", espacos="1", alcance="Adjacente",
         dano="1d6", tipo="E",
         resistencia="Fortitude DT Agi evita o atordoamento",
         efeito="1d6 de eletricidade e atordoado por 1 rodada. Bateria: 2 "
                "usos.",
         uso="Ação padrão contra um ser adjacente."),
    dict(nome="Pistola de dardos", categoria="I", espacos="1",
         alcance="Curto",
         efeito="Acertou: inconsciente até o fim da cena (Fortitude DT Agi: "
                "só desprevenido e lento por 1 rodada). Vem com 2 dardos.",
         uso="Ataque à distância. Caixa extra com 2 dardos: categoria 0, "
             "1 espaço."),
    dict(nome="Pistola sinalizadora", categoria="0", espacos="1",
         alcance="Curto", dano="2d6", tipo="F", critico="x2",
         efeito="Arma de disparo leve: 2d6 de fogo. Vem com 2 cargas.",
         uso="Ataque à distância. Caixa extra com 2 cargas: categoria 0, "
             "1 espaço."),
    dict(nome="Pé de cabra", categoria="0", espacos="1", dano="1d6/1d8",
         tipo="I", critico="x2",
         efeito="+5 em Força para arrombar portas. Em combate vale como "
                "bastão (1d6 com uma mão, 1d8 com as duas).",
         uso="Corpo a corpo."),
]

# Elemento opressor (p. 99–107): uma arma não leva maldições de um elemento
# e do que o oprime.
OPRESSORES = {"Conhecimento": "Sangue", "Sangue": "Morte",
              "Morte": "Energia", "Energia": "Conhecimento"}

# Tabela 3.10 (p. 66). Um pacote por elemento; sem ele não se conjura
# ritual daquele elemento. Não existe componente de Medo.
COMPONENTES = [
    dict(elemento="Conhecimento",
         exemplos="Livros, papéis, tinta, giz, pedras preciosas, cordas, "
                  "vidro, máscaras."),
    dict(elemento="Energia",
         exemplos="Pilhas, baterias, cabos, circuitos, moedas, dados, "
                  "ímãs, pólvora."),
    dict(elemento="Morte",
         exemplos="Ossos, dentes, cinzas, cabelo, relógios, folhas e galhos "
                  "secos, areia."),
    dict(elemento="Sangue",
         exemplos="Carne, sangue, órgãos, agulhas, navalhas, arame farpado, "
                  "correntes enferrujadas."),
]
