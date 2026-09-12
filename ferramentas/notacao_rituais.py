# -*- coding: utf-8 -*-
"""
O que cada ritual FAZ, escrito aqui — em notação de mesa, não em prosa de
livro.

A ficha técnica (elemento, círculo, custo, execução, alcance, alvo, duração,
resistência) sai do extrator, que lê o PDF de quem tem o livro. O efeito e
as ampliações são escritos neste arquivo, à mão, no formato
`efeito · condição · resistência`. É o que mantém o catálogo dentro da
Licença da Comunidade: nomes e mecânica são liberados, os textos dos livros
não podem ser reproduzidos.

Chave: "Elemento:círculo:Nome" — o mesmo trio que identifica o ritual no
extrator. Campos: efeito (obrigatório) e ampliacoes [(nome, efeito)] — o
custo de cada ampliação vem do extrator.
"""

NOTACAO = {
    "Conhecimento:1:Compreensão Paranormal": {
        "efeito": "Você entende qualquer idioma escrito ou falado do alvo "
                  "tocado — texto, gravação ou fala. Não traduz o que você "
                  "diz de volta.",
    },
    "Conhecimento:1:Enfeitiçar": {
        "efeito": "Alvo fica prestativo: interpreta o que você diz e faz da "
                  "melhor forma possível, e você ganha +10 em Diplomacia "
                  "com ele. Não é controle. Alvo hostil ou em combate tem "
                  "+5 na resistência. Qualquer ação hostil sua ou de aliado "
                  "quebra o efeito.",
    },
    "Conhecimento:1:Ouvir os Sussurros": {
        "efeito": "Faça uma pergunta de sim/não sobre algo que você vai "
                  "fazer nesta cena. O mestre rola 1d6 escondido: 2 a 6, "
                  "você recebe a resposta; 1, o Outro Lado mente.",
        "ampliacoes": [
            ("Discente", "Execução vira 1 minuto e a chance de acerto sobe."),
            ("Verdadeiro", "Execução vira 10 minutos e a resposta é a mais "
                           "confiável que o ritual dá."),
        ],
    },
    "Conhecimento:1:Perturbação": {
        "efeito": "Ordem de uma palavra que o alvo tem que ouvir (não "
                  "precisa entender). Falhou na resistência, gasta o turno "
                  "obedecendo: fugir de você, largar o que segura, ficar "
                  "parado, se aproximar ou cair no chão.",
    },
    "Conhecimento:1:Tecer Ilusão": {
        "efeito": "Cria imagem ou som simples em até 4 cubos de 1,5m — uma "
                  "pessoa, uma parede, um grito. Sem cheiro, textura, "
                  "temperatura, música ou diálogo. Quem interage tem "
                  "Vontade para desacreditar.",
        "ampliacoes": [("Discente", "Dobra a área para 8 cubos de 1,5m.")],
    },
    "Conhecimento:1:Terceiro Olho": {
        "efeito": "Enxerga auras paranormais em alcance longo e sabe o "
                  "elemento e a força: fraca (1º círculo, VD até 80), "
                  "moderada (2º–3º, VD 81–280), poderosa (4º, VD 281+).",
        "ampliacoes": [
            ("Discente", "Duração vira 1 dia."),
            ("Verdadeiro", "Enxerga também objetos e lugares marcados pelo "
                           "Outro Lado."),
        ],
    },

    "Conhecimento:2:Aprimorar Mente": {
        "efeito": "+1 em Intelecto ou Presença (escolha do alvo), com tudo "
                  "que isso arrasta: PE, perícias, graus.",
        "ampliacoes": [
            ("Discente", "Bônus vira +2. Requer 3º círculo."),
            ("Verdadeiro", "Bônus vira +3. Requer 4º círculo e afinidade."),
        ],
    },
    "Conhecimento:2:Detecção de Ameaças": {
        "efeito": "Esfera de 18m: quando um hostil ou armadilha entra nela, "
                  "você sente. Ação de movimento + Percepção DT 20 revela "
                  "direção e distância.",
        "ampliacoes": [
            ("Discente", "Você não fica desprevenido contra o que detectou "
                         "e ganha +5 para resistir a armadilhas."),
            ("Verdadeiro", "Duração vira 1 dia e o benefício vale para os "
                           "aliados por perto."),
        ],
    },
    "Conhecimento:2:Esconder dos Olhos": {
        "efeito": "Fica invisível com o equipamento: camuflagem total e +15 "
                  "em Furtividade; quem não te vê fica desprevenido contra "
                  "você. Acabou se você atacar ou usar habilidade hostil.",
        "ampliacoes": [
            ("Discente", "Duração vira sustentada."),
            ("Verdadeiro", "Execução vira ação livre e o efeito aguenta um "
                           "ataque antes de cair."),
        ],
    },
    "Conhecimento:2:Invadir Mente": {
        "efeito": "Escolha: RAJADA MENTAL (alcance médio, 6d6 de "
                  "Conhecimento e atordoado 1 rodada; Vontade reduz à "
                  "metade e evita) ou LIGAÇÃO TELEPÁTICA (toque, 2 pessoas "
                  "voluntárias conversam mentalmente por 1 dia).",
        "ampliacoes": [
            ("Discente", "Rajada mental: +2d6 de dano."),
            ("Verdadeiro", "Rajada mental: dano bem maior e atinge um "
                           "segundo alvo próximo."),
        ],
    },
    "Conhecimento:2:Localização": {
        "efeito": "Círculo de 90m: aponta direção e distância da pessoa ou "
                  "objeto mais próximo do tipo que você descrever. Descrição "
                  "muito específica pode simplesmente não achar nada.",
        "ampliacoes": [
            ("Discente", "Vira toque e passa a procurar por objeto "
                         "conhecido, não por tipo."),
            ("Verdadeiro", "Área sobe para um círculo bem maior."),
        ],
    },

    "Conhecimento:3:Alterar Memória": {
        "efeito": "Altera ou apaga as lembranças da última hora do alvo "
                  "tocado — detalhes de eventos, não a vida inteira. Ele "
                  "recupera tudo em 1d4 dias.",
        "ampliacoes": [
            ("Verdadeiro", "Alcança as últimas 24 horas. Requer 4º círculo."),
        ],
    },
    "Conhecimento:3:Contato Paranormal": {
        "efeito": "Recebe 6d6 de auxílio para o dia: gaste um dado em "
                  "qualquer teste de perícia e some ao resultado. Cada 6 "
                  "rolado custa 2 de Sanidade — a entidade cobra.",
        "ampliacoes": [
            ("Discente", "Os dados de auxílio viram d8."),
            ("Verdadeiro", "Os dados de auxílio viram d10."),
        ],
    },
    "Conhecimento:3:Mergulho Mental": {
        "efeito": "Toque sustentado: no início de cada turno seu o alvo "
                  "resiste com Vontade; falhou, responde uma pergunta de "
                  "sim/não sem poder mentir. Você fica desprevenido "
                  "enquanto mergulha.",
        "ampliacoes": [
            ("Verdadeiro", "Execução vira 1 dia de trabalho e as respostas "
                           "deixam de ser só sim/não."),
        ],
    },
    "Conhecimento:3:Vidência": {
        "efeito": "Numa superfície reflexiva, vê e ouve um alvo escolhido e "
                  "uns 6m ao redor dele, a qualquer distância. O alvo "
                  "resiste no início de cada turno; dois sucessos seguidos "
                  "encerram e o deixam imune.",
    },

    "Conhecimento:4:Controle Mental": {
        "efeito": "Domina uma pessoa ou animal: obedece qualquer ordem, "
                  "menos ordem suicida. Resiste com Vontade no fim de cada "
                  "turno; quem escapa fica pasmo 1 rodada (uma vez por "
                  "cena).",
        "ampliacoes": [
            ("Discente", "Até cinco alvos."),
            ("Verdadeiro", "Até dez alvos. Requer afinidade com "
                           "Conhecimento."),
        ],
    },
    "Conhecimento:4:Inexistir": {
        "efeito": "Toque que apaga o alvo da existência: dano altíssimo de "
                  "Conhecimento e, se o matar, ninguém lembra que ele "
                  "existiu. Vontade reduz e evita o apagamento.",
        "ampliacoes": [
            ("Discente", "Dano vira 15d12+15."),
            ("Verdadeiro", "Dano vira 20d12+20 e o apagamento fica mais "
                           "difícil de resistir."),
        ],
    },
    "Conhecimento:4:Possessão": {
        "efeito": "Projeta sua consciência num corpo vivo ou morto em "
                  "alcance longo, por 1 dia. Usa a sua ficha com os "
                  "atributos físicos e o deslocamento do corpo; o seu corpo "
                  "fica caído e indefeso.",
    },

    "Energia:1:Amaldiçoar Tecnologia": {
        "efeito": "Um acessório ou arma de fogo recebe uma modificação à sua "
                  "escolha pela cena.",
        "ampliacoes": [
            ("Discente", "Duas modificações. Requer 2º círculo."),
            ("Verdadeiro", "Três modificações. Requer 3º círculo e "
                           "afinidade."),
        ],
    },
    "Energia:1:Coincidência Forçada": {
        "efeito": "O alvo recebe +2 em testes de perícia pela cena — o caos "
                  "trabalhando a favor dele.",
        "ampliacoes": [
            ("Discente", "Passa a valer para aliados à sua escolha. Requer "
                         "2º círculo."),
            ("Verdadeiro", "Vale para os aliados e o bônus vira +5. Requer "
                           "3º círculo e afinidade."),
        ],
    },
    "Energia:1:Eletrocussão": {
        "efeito": "3d6 de eletricidade num alvo em alcance curto e "
                  "vulnerável por 1 rodada (Fortitude reduz à metade e "
                  "evita). Contra eletrônico: dobro de dano e ignora "
                  "resistência.",
        "ampliacoes": [
            ("Discente", "Vira linha de 30m com 6d6 em tudo no caminho."),
            ("Verdadeiro", "Passa a acertar vários alvos escolhidos dentro "
                           "do alcance."),
        ],
    },
    "Energia:1:Embaralhar": {
        "efeito": "Três cópias ilusórias imitam você: +6 de Defesa. Cada "
                  "ataque que erra apaga uma cópia e tira 2 do bônus. Só "
                  "funciona contra quem enxerga as cópias.",
        "ampliacoes": [
            ("Discente", "Cinco cópias."),
            ("Verdadeiro", "Ainda mais cópias e o bônus dura mais tempo."),
        ],
    },
    "Energia:1:Luz": {
        "efeito": "O objeto ilumina 9m de raio com luz fria e colorida. "
                  "Guardado no bolso, apaga; revelado, volta. Objeto de "
                  "alguém contra a vontade dá direito a Vontade.",
        "ampliacoes": [
            ("Discente", "Alcance longo e quatro esferas de luz "
                         "independentes."),
            ("Verdadeiro", "A luz vira cálida como a do sol."),
        ],
    },
    "Energia:1:Polarização Caótica": {
        "efeito": "Aura magnética sustentada. ATRAIR: ação de movimento "
                  "puxa objeto metálico de espaço 2 ou menor para a sua "
                  "mão. REPELIR: empurra projéteis e objetos pequenos para "
                  "longe de você.",
        "ampliacoes": [
            ("Discente", "Duração vira instantânea, sem sustentar."),
            ("Verdadeiro", "Alcance médio e a força do efeito sobe."),
        ],
    },

    "Energia:2:Chamas do Caos": {
        "efeito": "Escolha: CHAMEJAR (arma corpo a corpo causa +1d6 de "
                  "fogo) ou ESQUENTAR (objeto sofre 1d6 de fogo por rodada "
                  "e queima quem o segura ou veste).",
        "ampliacoes": [
            ("Discente", "Duração sustentada e o dano de fogo sobe."),
        ],
    },
    "Energia:2:Contenção Fantasmagórica": {
        "efeito": "Três laços de Energia agarram o alvo (Reflexos evita). "
                  "Sair: ação padrão + Atletismo contra a DT do ritual — "
                  "quebra um laço, mais um a cada 5 de margem. Cada laço "
                  "tem Defesa 10, 10 PV, RD 5 e é imune a Energia.",
        "ampliacoes": [("Discente", "Mais laços para arrebentar.")],
    },
    "Energia:2:Dissonância Acústica": {
        "efeito": "Esfera de 6m sustentada: todo mundo dentro fica surdo e "
                  "ninguém consegue conjurar ritual ali.",
        "ampliacoes": [
            ("Discente", "Vira um objeto que carrega o silêncio de 3m "
                         "junto."),
            ("Verdadeiro", "Duração vira cena e som nenhum atravessa a "
                           "área."),
        ],
    },
    "Energia:2:Sopro do Caos": {
        "efeito": "Massa de ar sustentada. ASCENDER: ergue um alvo Médio e "
                  "sobe ou desce até 6m por rodada, até 30m. Outras formas "
                  "empurram, derrubam ou seguram no ar.",
        "ampliacoes": [
            ("Discente", "Afeta alvos Grandes."),
            ("Verdadeiro", "Afeta alvos Enormes."),
        ],
    },

    "Energia:2:Tela de Ruído": {
        "efeito": "Película de Energia: 30 PV temporários que só absorvem "
                  "balístico, corte, impacto e perfuração. Pode ser "
                  "conjurado como reação ao sofrer dano — aí vira "
                  "resistência 15 contra aquele dano.",
        "ampliacoes": [
            ("Discente", "PV temporários viram 60 e a resistência, 30."),
            ("Verdadeiro", "Alcance curto: protege outro alvo."),
        ],
    },

    "Energia:3:Convocação Instantânea": {
        "efeito": "Traz para a sua mão, de qualquer distância, um objeto de "
                  "até 2 espaços que você preparou antes com o símbolo do "
                  "ritual. Se alguém estiver segurando, resiste com Vontade "
                  "— e mesmo assim você fica sabendo onde o objeto está e "
                  "com quem.",
        "ampliacoes": [
            ("Discente", "Objeto maior."),
            ("Verdadeiro", "Passa a convocar um recipiente inteiro, com o "
                           "que estiver dentro."),
        ],
    },
    "Energia:3:Salto Fantasma": {
        "efeito": "Vira Energia e reaparece em outro ponto em alcance "
                  "médio. Não precisa ver o destino, mas precisa já ter "
                  "visto o lugar alguma vez (ao vivo, em foto, em vídeo).",
        "ampliacoes": [
            ("Discente", "Execução vira reação."),
            ("Verdadeiro", "Alcance longo e leva um aliado junto."),
        ],
    },
    "Energia:3:Transfigurar Terra": {
        "efeito": "9 cubos de 1,5m de terra, pedra, lama ou areia obedecem. "
                  "AMOLECER teto ou coluna derruba tudo: 10d6 de impacto "
                  "(Reflexos reduz à metade); no chão, vira terreno "
                  "difícil. Outras formas erguem parede ou abrem caminho.",
        "ampliacoes": [
            ("Discente", "Área vira 15 cubos."),
            ("Verdadeiro", "Passa a afetar qualquer tipo de solo e material "
                           "de construção."),
        ],
    },
    "Energia:3:Transfigurar Água": {
        "efeito": "Esfera de 30m de água obedece pela cena. CONGELAR prende "
                  "quem estiver nadando (sair: ação padrão + Atletismo "
                  "contra a DT). Outras formas empurram, afundam ou abrem "
                  "caminho seco.",
        "ampliacoes": [
            ("Verdadeiro", "Aumenta o deslocamento que a água concede a "
                           "quem você escolher."),
        ],
    },

    "Energia:4:Alterar Destino": {
        "efeito": "Reação: +15 em um teste de resistência ou na Defesa "
                  "contra um ataque — você viu a possibilidade certa antes "
                  "de ela acontecer.",
        "ampliacoes": [
            ("Verdadeiro", "Alcance curto: salva um aliado no lugar."),
        ],
    },
    "Energia:4:Deflagração de Energia": {
        "ficha": {"duracao": "instantânea"},
        "efeito": "Explosão de 15m: 3d10×10 de Energia e todo item "
                  "tecnológico na área quebra. Você não é atingido. "
                  "Fortitude reduz.",
        "ampliacoes": [
            ("Verdadeiro", "Atinge só os alvos que você escolher."),
        ],
    },
    "Energia:4:Teletransporte": {
        "efeito": "Até 5 voluntários viram energia e reaparecem a até "
                  "1.000 km. Teste de Ocultismo com DT pelo quanto você "
                  "conhece o destino: 25 lugar que frequenta, 30 lugar "
                  "visitado uma vez, mais alto para lugar só descrito.",
        "ampliacoes": [
            ("Verdadeiro", "Consegue mirar lugares que nunca visitou."),
        ],
    },

    "Medo:1:Cinerária": {
        "efeito": "Névoa de 6m: ritual conjurado dentro dela tem DT +5.",
        "ampliacoes": [
            ("Discente", "Ritual conjurado dentro custa −2 PE."),
            ("Verdadeiro", "Ritual conjurado dentro causa dano maximizado."),
        ],
    },

    "Medo:2:Proteção contra Rituais": {
        "efeito": "Alvo tocado recebe resistência 5 a dano paranormal e +5 "
                  "para resistir a rituais e habilidades de criaturas.",
        "ampliacoes": [
            ("Discente", "Até 5 alvos tocados. Requer 3º círculo."),
            ("Verdadeiro", "Até 5 alvos, resistência 10 e bônus +10. Requer "
                           "4º círculo."),
        ],
    },
    "Medo:2:Rejeitar Névoa": {
        "efeito": "Névoa de 6m: ritual conjurado dentro custa +2 PE por "
                  "círculo e sobe um passo de execução (livre→movimento→"
                  "padrão→completa→duas rodadas). Anula Cinerária.",
        "ampliacoes": [
            ("Discente", "Também aumenta a DT dos testes feitos dentro da "
                         "área."),
        ],
    },

    "Medo:3:Dissipar Ritual": {
        "efeito": "Encerra rituais ativos num alvo ou numa esfera de 3m: "
                  "role Ocultismo e anule todo ritual com DT igual ou menor "
                  "que o resultado. Efeito já instantâneo não volta atrás.",
    },

    "Medo:4:Canalizar o Medo": {
        "efeito": "Passa a outra pessoa um ritual seu de até 3º círculo: "
                  "ela conjura uma vez, de graça, na forma básica. Até isso "
                  "acontecer, o seu PE máximo cai pelo custo do ritual.",
    },
    "Medo:4:Conhecendo o Medo": {
        "efeito": "Falhou na Vontade: a Sanidade do alvo vai a 0 e ele fica "
                  "enlouquecendo. Passou: 10d6 mental e apavorado 1 rodada. "
                  "Quem enlouquece por este ritual vira criatura "
                  "paranormal.",
    },
    "Medo:4:Lâmina do Medo": {
        "efeito": "Golpe adjacente: falhou na Fortitude, os PV do alvo vão "
                  "a 0 e ele fica morrendo. Passou: 10d8 de Medo "
                  "(atravessa qualquer resistência) e apavorado 1 rodada.",
    },
    "Medo:4:Medo Tangível": {
        "efeito": "Seu corpo vira Medo: imune a atordoado, cego, "
                  "debilitado, enjoado, envenenado, exausto, fatigado, "
                  "fraco e lento — e ao que for mundano.",
    },
    "Medo:4:Presença do Medo": {
        "efeito": "Emanação de 9m sustentada: quem estiver dentro na "
                  "conjuração ou no início do próprio turno sofre 5d8 "
                  "mental + 5d8 de Medo (Vontade reduz os dois à metade) e "
                  "fica atordoado 1 rodada se falhar.",
    },

    "Morte:1:Cicatrização": {
        "efeito": "Cura 3d8+3 PV no toque — e o alvo envelhece 1 ano.",
        "ampliacoes": [
            ("Discente", "Cura vira 5d8+5. Requer 2º círculo."),
            ("Verdadeiro", "Alcance curto, vários alvos, cura 7d8+7. "
                           "Requer 4º círculo e afinidade com Morte."),
        ],
    },
    "Morte:1:Consumir Manancial": {
        "efeito": "Suga o tempo de vida do que está por perto (plantas, "
                  "insetos, solo) e ganha 3d6 PV temporários, que somem no "
                  "fim da cena.",
        "ampliacoes": [
            ("Discente", "PV temporários viram 6d6. Requer 2º círculo."),
            ("Verdadeiro", "Vira esfera de 6m e suga também dos seres vivos "
                           "na área (Fortitude reduz à metade)."),
        ],
    },
    "Morte:1:Decadência": {
        "efeito": "Toque: 2d8+2 de Morte (Fortitude reduz à metade).",
        "ampliacoes": [
            ("Discente", "Sem resistência e dano 3d8+3; dá para transferir "
                         "as espirais para uma arma e somar ao golpe."),
            ("Verdadeiro", "Vira explosão de 6m com 8d8+8."),
        ],
    },
    "Morte:1:Definhar": {
        "efeito": "Lufada de cinzas: alvo fica fatigado; passou na "
                  "Fortitude, fica só vulnerável.",
        "ampliacoes": [
            ("Discente", "Alvo fica exausto. Requer 2º círculo."),
            ("Verdadeiro", "Como discente, até 5 alvos. Requer 3º círculo e "
                           "afinidade com Morte."),
        ],
    },
    "Morte:1:Espirais da Perdição": {
        "efeito": "Espirais no corpo do alvo: −1 dado nos testes de ataque "
                  "dele pela cena.",
        "ampliacoes": [
            ("Discente", "Penalidade vira −2 dados. Requer 2º círculo."),
            ("Verdadeiro", "Penalidade −2 dados em vários alvos escolhidos. "
                           "Requer 3º círculo."),
        ],
    },
    "Morte:1:Nuvem de Cinzas": {
        "efeito": "Nuvem de 6m de raio por 6m de altura: até 1,5m dentro "
                  "dela dá camuflagem leve, de 3m em diante camuflagem "
                  "total. Vento forte dispersa em 4 rodadas; vendaval, em "
                  "1. Não funciona debaixo d'água.",
        "ampliacoes": [
            ("Discente", "Alguns seres escolhidos enxergam através dela."),
            ("Verdadeiro", "A nuvem também sufoca quem estiver dentro."),
        ],
    },

    "Morte:2:Desacelerar Impacto": {
        "efeito": "Reação: a queda de um ser (ou até 10 espaços de objetos) "
                  "cai para 18m por rodada — sem dano. Serve para frear "
                  "projétil também.",
        "ampliacoes": [("Verdadeiro", "Mais alvos ao mesmo tempo.")],
    },
    "Morte:2:Eco Espiral": {
        "efeito": "Cria uma cópia do alvo em cinzas. Turno seguinte: ação "
                  "padrão para concentrar (senão some). Turno depois: ação "
                  "padrão para descarregar — a cópia explode e o alvo sofre "
                  "dano de Morte (Fortitude reduz à metade).",
        "ampliacoes": [
            ("Discente", "Até 5 alvos."),
            ("Verdadeiro", "Ganha uma rodada a mais de carga, e o dano "
                           "sobe."),
        ],
    },
    "Morte:2:Miasma Entrópico": {
        "efeito": "Nuvem de 6m: 4d8 de dano químico e enjoado 1 rodada "
                  "(Fortitude reduz à metade e evita).",
        "ampliacoes": [
            ("Discente", "Dano vira 6d8 de Morte."),
            ("Verdadeiro", "Dura 3 rodadas e reaplica o dano em quem "
                           "começar o turno dentro. Requer 3º círculo."),
        ],
    },
    "Morte:2:Paradoxo": {
        "efeito": "Implosão temporal em esfera de 6m: 6d6 de Morte "
                  "(Fortitude reduz à metade).",
        "ampliacoes": [
            ("Discente", "Vira uma esfera pequena e persistente que causa "
                         "4d6 de Morte em quem ocupar o espaço dela."),
            ("Verdadeiro", "Dano vira 13d6."),
        ],
    },
    "Morte:2:Velocidade Mortal": {
        "efeito": "Alvo ganha uma ação de movimento a mais por turno "
                  "enquanto você sustentar. Não serve para conjurar ritual.",
    },

    "Morte:3:Poeira da Podridão": {
        "efeito": "Nuvem de 6m sustentada: na conjuração e no início de "
                  "cada turno seu, 4d8 de Morte em seres e objetos na área "
                  "(Fortitude reduz à metade). Quem falha não recupera PV "
                  "por 1 rodada.",
        "ampliacoes": [("Verdadeiro", "Dano vira 4d8+16.")],
    },
    "Morte:3:Tentáculos de Lodo": {
        "efeito": "Círculo de 6m pela cena: na conjuração e no início de "
                  "cada turno seu, teste de agarrar (Ocultismo no lugar de "
                  "Luta) contra cada alvo na área. Vencendo, agarra; quem "
                  "já estava agarrado é esmagado (4d6).",
        "ampliacoes": [("Verdadeiro", "Raio sobe para 9m.")],
    },
    "Morte:3:Zerar Entropia": {
        "efeito": "Alvo fica paralisado (passou na Vontade: só lento). No "
                  "início de cada turno dele, ação completa + novo teste de "
                  "Vontade encerra.",
        "ampliacoes": [
            ("Discente", "Passa a valer para qualquer ser, não só pessoa. "
                         "Requer 4º círculo."),
            ("Verdadeiro", "Vários alvos escolhidos. Requer 4º círculo e "
                           "afinidade."),
        ],
    },
    "Morte:3:Âncora Temporal": {
        "efeito": "Aura sobre o alvo: no início de cada turno dele, Vontade "
                  "ou não consegue se deslocar naquele turno (agir, pode). "
                  "Dois sucessos seguidos encerram.",
        "ampliacoes": [
            ("Verdadeiro", "Vários alvos escolhidos. Requer 4º círculo."),
        ],
    },

    "Morte:4:Convocar o Algoz": {
        "efeito": "Cria o que o alvo mais teme — só ele vê com nitidez; o "
                  "resto vê um vulto. O algoz surge do seu lado, flutua 12m "
                  "por turno atrás da vítima e a persegue enquanto você "
                  "sustentar (Vontade e Fortitude parciais).",
    },
    "Morte:4:Distorção Temporal": {
        "efeito": "Bolsão de tempo de 3 rodadas: você age, mas não sai do "
                  "lugar nem interage com nada; em troca, nada de fora te "
                  "afeta e nada que você fizer afeta a área.",
    },
    "Morte:4:Fim Inevitável": {
        "efeito": "Buraco negro de 1,5m em alcance extremo, por 4 rodadas: "
                  "no início de cada um dos seus turnos, todo mundo a até "
                  "90m (você incluído) faz Fortitude ou cai e é puxado 30m "
                  "na direção dele.",
    },

    "Sangue:1:Arma Atroz": {
        "efeito": "Arma corpo a corpo tocada: +2 em ataque e +1 na margem "
                  "de ameaça enquanto sustentar.",
        "ampliacoes": [
            ("Discente", "Bônus vira +5 em ataque. Requer 2º círculo."),
            ("Verdadeiro", "+5 em ataque, +2 na margem e no multiplicador "
                           "de crítico. Requer 3º círculo e afinidade."),
        ],
    },
    "Sangue:1:Armadura de Sangue": {
        "efeito": "Carapaça de sangue: +5 de Defesa pela cena. Soma com "
                  "outros rituais, mas não com bônus de equipamento.",
        "ampliacoes": [
            ("Discente", "+10 de Defesa e resistência 5 a balístico, corte, "
                         "impacto e perfuração. Requer 3º círculo."),
            ("Verdadeiro", "+15 de Defesa e resistência maior. Requer 4º "
                           "círculo."),
        ],
    },
    "Sangue:1:Corpo Adaptado": {
        "efeito": "Alvo fica imune a calor e frio extremos, respira na água "
                  "(ou no ar, se for aquático) e não sufoca em fumaça.",
        "ampliacoes": [
            ("Discente", "Duração vira 1 dia."),
            ("Verdadeiro", "Alcance curto e vários alvos escolhidos."),
        ],
    },
    "Sangue:1:Distorcer Aparência": {
        "efeito": "Muda a sua aparência — altura, peso, pele, cabelo, voz, "
                  "digital, íris: +10 em Enganação para se passar por "
                  "outra pessoa (Vontade desacredita).",
    },
    "Sangue:1:Fortalecimento Sensorial": {
        "efeito": "+1 dado em Investigação, Luta, Percepção e Pontaria pela "
                  "cena.",
        "ampliacoes": [
            ("Discente", "Inimigos também sofrem −1 dado para te acertar. "
                         "Requer 2º círculo."),
            ("Verdadeiro", "Imune a surpreendido e desprevenido, +10 de "
                           "Defesa e Reflexos. Requer 4º círculo e "
                           "afinidade."),
        ],
    },
    "Sangue:1:Ódio Incontrolável": {
        "efeito": "Frenesi no alvo: +2 em ataque e dano corpo a corpo e "
                  "resistência 5 a balístico, corte, impacto e perfuração. "
                  "Em troca, nada que exija calma — sem Furtividade, sem "
                  "conjurar ritual.",
        "ampliacoes": [
            ("Discente", "Além do normal, o alvo se cura um pouco cada vez "
                         "que derruba alguém."),
            ("Verdadeiro", "Bônus de ataque e dano sobem bastante."),
        ],
    },

    "Sangue:2:Aprimorar Físico": {
        "efeito": "+1 em Agilidade ou Força (escolha do alvo) pela cena.",
        "ampliacoes": [
            ("Discente", "Bônus vira +2. Requer 3º círculo."),
            ("Verdadeiro", "Bônus vira +3. Requer 4º círculo e afinidade."),
        ],
    },
    "Sangue:2:Descarnar": {
        "efeito": "6d8 de dano (metade corte, metade Sangue) e hemorragia: "
                  "no início de cada turno do alvo, Fortitude ou +2d8 de "
                  "Sangue. Dois sucessos seguidos encerram.",
        "ampliacoes": [
            ("Discente", "Dano direto vira 10d8 e a hemorragia sangra "
                         "mais."),
        ],
    },
    "Sangue:2:Flagelo de Sangue": {
        "efeito": "Marca uma ordem na pele do alvo (\"não me ataque\", "
                  "\"me siga\", \"não saia daqui\"). Cada rodada em que ele "
                  "desobedecer: 10d6 de Sangue e enjoado na rodada "
                  "(Fortitude parcial).",
        "ampliacoes": [
            ("Discente", "Vale para qualquer ser, não só pessoa."),
            ("Verdadeiro", "Como discente, e a marca dura muito mais."),
        ],
    },
    "Sangue:2:Hemofagia": {
        "efeito": "Arranca o sangue do alvo: 6d6 de Sangue (Fortitude reduz "
                  "à metade) e você recupera PV igual à metade do dano "
                  "causado.",
        "ampliacoes": [
            ("Discente", "Sem resistência, e dá para somar a um ataque "
                         "corpo a corpo na mesma ação."),
            ("Verdadeiro", "Vira pessoal e atinge todos ao seu redor."),
        ],
    },
    "Sangue:2:Transfusão Vital": {
        "efeito": "Transfere até 30 PV seus para o alvo tocado. Você não "
                  "pode cair abaixo de 1 PV com isso.",
        "ampliacoes": [
            ("Discente", "Até 50 PV. Requer 3º círculo."),
            ("Verdadeiro", "Até 100 PV. Requer 4º círculo."),
        ],
    },

    "Sangue:3:Ferver Sangue": {
        "efeito": "Sustentado: na conjuração e no início de cada turno do "
                  "alvo, Fortitude — falhou, 4d8 de Sangue e fica fraco; "
                  "passou, metade e sem a condição. Dois sucessos seguidos "
                  "encerram.",
        "ampliacoes": [("Verdadeiro", "Vários alvos escolhidos.")],
    },
    "Sangue:3:Forma Monstruosa": {
        "efeito": "Vira meio criatura de Sangue: roupa e proteção viram "
                  "couraça, o que estiver nas mãos vira garra. Equipamento "
                  "fica inacessível, mas os bônus de ataque, dano e Defesa "
                  "sobem.",
        "ampliacoes": [
            ("Discente", "Além do normal, ganha um deslocamento melhor e "
                         "regeneração."),
            ("Verdadeiro", "Os bônus de ataque e dano sobem de novo."),
        ],
    },
    "Sangue:3:Purgatório": {
        "efeito": "Poça de sangue de 6m sustentada: inimigos dentro ficam "
                  "vulneráveis a balístico, corte, impacto e perfuração. "
                  "Sair custa 6d6 de Sangue + Fortitude — falhou, não sai.",
    },
    "Sangue:3:Vomitar Pestes": {
        "efeito": "Enxame Grande (3m) sustentado, que atravessa o espaço "
                  "dos outros: no fim de cada turno seu causa dano em quem "
                  "estiver no espaço dele (Reflexos reduz à metade).",
        "ampliacoes": [
            ("Discente", "Quem falha também fica com uma condição ruim."),
            ("Verdadeiro", "O enxame vira Enorme."),
        ],
    },

    "Sangue:4:Capturar o Coração": {
        "efeito": "Paixão obsessiva por você: no início de cada turno, "
                  "Vontade — falhou, o alvo age para te agradar naquele "
                  "turno, mesmo contra os próprios aliados. Dois sucessos "
                  "seguidos encerram.",
    },
    "Sangue:4:Invólucro de Carne": {
        "efeito": "Clone seu com as mesmas estatísticas e cópia do "
                  "equipamento mundano. Não tem consciência (INT e PRE "
                  "nulos) e só faz o que você mandar.",
    },
    "Sangue:4:Vínculo de Sangue": {
        "efeito": "Símbolo em você e no alvo: sempre que você sofrer dano, "
                  "ele faz Fortitude — falhou, cada um leva metade. Dá para "
                  "conjurar invertido, você levando a metade do dano dele.",
    },
}
