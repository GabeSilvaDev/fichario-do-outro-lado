# -*- coding: utf-8 -*-
"""
O que cada ameaça FAZ, escrito aqui — em notação de mesa, não em prosa de
livro.

Os números (PV, Defesa, testes, dano) saem do extrator, que lê o PDF do dono
do livro. O texto das habilidades é escrito neste arquivo, à mão, no formato
`gatilho → efeito (resistência) · limite`. É o que mantém o bestiário do app
dentro da Licença da Comunidade: nomes e mecânica são liberados, os textos
dos livros não podem ser reproduzidos.

Chave: "FONTE:página:PV" — o mesmo trio que identifica o bloco no extrator.
Campos: nome (como aparece na ficha), grupo, habilidades [(execução, nome,
efeito)], e opcionalmente tatica.
"""

NOTACAO = {
    "OPRPG:182:70": {
        "nome": "Aberração de Carne",
        "grupo": "Sangue",
        "habilidades": [
            ("Reação", "Agarrão",
             "Acertou pancada → agarra (3d20+12). Segura 2 alvos por vez."),
            ("Movimento", "Abocanhar",
             "Engole até 2 agarrados: 3d6 perfuração ao entrar e no início "
             "de cada turno dela enquanto continuarem lá dentro."),
        ],
        "tatica": "Agarra dois, engole, e continua batendo em quem sobrou.",
    },
    "OPRPG:186:1200": {
        "nome": "Aniquilação",
        "grupo": "Sangue",
        "habilidades": [
            ("Reação", "Agarrão",
             "Acertou tentáculos → agarra (5d20+50). Até 4 alvos."),
            ("Reação", "Instinto aniquilador",
             "Alguém em alcance curto andou mais de 3m → ataque de "
             "tentáculos de graça nessa pessoa."),
            ("Livre", "Apertar e destruir",
             "Início do turno dela: 40 de dano de Sangue em cada agarrado."),
            ("Movimento", "Bater as asas",
             "Alcance longo: 8d6 mental, empurra 6m e atordoa 1 rodada "
             "(Fortitude DT 40 = metade e sem os efeitos)."),
            ("Movimento", "Estrangulamento final",
             "Desloca 15m; quem ficar adjacente no caminho fica agarrado e "
             "asfixiado (Reflexos DT 30 evita)."),
            ("Completa", "Tempestade de espinhos",
             "1×/cena: 20d6+20 Sangue em alcance médio (Reflexos DT 40 = "
             "metade). Depois disso perde o disparo de espinhos na cena."),
        ],
        "tatica": "Agarra o grupo todo, aperta a cada turno e guarda a "
                  "tempestade para quando estiverem juntos.",
    },
    "OPRPG:188:700": {
        "nome": "Carente",
        "grupo": "Sangue",
        "habilidades": [
            ("Movimento", "Forma infantil",
             "Assume forma de criança: quem a vê assim precisa de Vontade "
             "para atacá-la na rodada seguinte."),
            ("Reação", "Rasteira de tentáculo",
             "Alguém se afasta dela → derruba com o tentáculo."),
            ("Livre", "Sugada mortal",
             "Alvo agarrado perde sangue: dano contínuo enquanto ela "
             "segurar."),
        ],
        "tatica": "Usa a forma de criança para o grupo hesitar, depois agarra "
                  "quem chegou perto.",
    },
    "OPRPG:190:105": {
        "nome": "Dama de Sangue",
        "grupo": "Sangue",
        "habilidades": [
            ("Livre", "Consumir",
             "Começa SEM as habilidades da ficha. Ação padrão adjacente a um "
             "cadáver = consome e ganha a próxima habilidade da lista. Antes "
             "de 7 corpos, gasta o turno indo atrás de corpo."),
        ],
        "tatica": "Enquanto houver cadáver na cena, ela come em vez de "
                  "lutar — e fica pior a cada corpo. Tirar os corpos do "
                  "alcance dela É a luta.",
    },
    "OPRPG:193:360": {
        "nome": "Enpap-X",
        "grupo": "Sangue",
        "habilidades": [
            ("Livre", "Acorrentar",
             "Corrente acerta alvo Médio ou menor → agarra à distância "
             "(2d20+17); início do turno dela, 4d6 impacto em cada agarrado."),
            ("Reação", "Forma desencadeada",
             "Crítico com socão ou corrente → derruba ou empurra 3m."),
            ("Reação", "Crescer",
             "Cada socão que acerta dá +1d6 cumulativo no dano dela até o "
             "fim do turno."),
            ("Movimento", "Marcas do terror",
             "Alcance curto: 4d6 mental (Vontade DT 25 = metade)."),
        ],
        "tatica": "Puxa dois com correntes, soca o mesmo alvo em sequência "
                  "para o dano crescer.",
    },
    "OPRPG:194:1150": {
        "nome": "Kerberos",
        "grupo": "Sangue",
        "habilidades": [
            ("Livre", "Devorar",
             "1×/cena: alvo a 0 PV pela mordida é devorado e morre; ela cura "
             "metade dos PV totais dele (Fortitude DT 40 evita)."),
            ("Completa", "Derrubar e devorar",
             "Derruba um alvo a até 3m (5d20+45) e faz 3 mordidas nele, com "
             "dano 4d12+40."),
        ],
        "tatica": "Derruba o mais frágil e concentra tudo nele para abrir o "
                  "Devorar.",
    },
    "OPRPG:197:750": {
        "nome": "Minotauro",
        "grupo": "Sangue",
        "habilidades": [
            ("Livre", "Cravar chifres",
             "Investida com chifres que acerta → alvo fica agarrado. "
             "Enquanto segura, não ataca com chifres; no fim de cada turno "
             "da vítima ela sofre o dano de novo."),
        ],
        "tatica": "Investe de longe, crava, e usa o machado enquanto o "
                  "espetado sangra.",
    },
    "OPRPG:199:240": {
        "nome": "Mulher Afogada",
        "grupo": "Sangue",
        "habilidades": [
            ("Movimento", "Sugar sangue",
             "Devora corpo adjacente morto nesta cena → recupera 40 PV."),
            ("Padrão", "Afogar em Sangue",
             "Invade boca e nariz de alvo em alcance curto: asfixiado. "
             "Fortitude DT 24 no início de cada turno dele encerra e a "
             "expulsa."),
            ("Reação", "Arrancar sangue",
             "Ao ser arrancada de quem estava afogando: 6d6 Sangue e a "
             "vítima fica fraca."),
            ("Movimento", "Invadir órgãos",
             "Em quem já está afogado: 6d6 Sangue e fica enjoado."),
        ],
        "tatica": "Escolhe um alvo, afoga, e usa os corpos da cena para se "
                  "curar.",
    },
    "OPRPG:201:550": {
        "nome": "Titã de Sangue",
        "grupo": "Sangue",
        "habilidades": [
            ("Livre", "Estraçalhar",
             "Mordida que acerta → +4d12+10 perfuração e sangrando até o fim "
             "da cena (Reflexos DT 30 = metade e sem sangramento)."),
        ],
        "tatica": "Morde sempre o mesmo alvo: o sangramento é que mata.",
    },
    "OPRPG:202:45": {
        "nome": "Zumbi de Sangue",
        "grupo": "Sangue",
        "habilidades": [],
        "tatica": "Cego: acha o grupo pelo ar que se mexe. Vem em bando e "
                  "não recua.",
    },
    "OPRPG:203:200": {
        "nome": "Zumbi de Sangue Bestial",
        "grupo": "Sangue",
        "habilidades": [],
        "tatica": "Versão grande e rápida do zumbi: fica escondido "
                  "(Furtividade 2d20+13) e ataca quem se separou.",
    },
    "OPRPG:206:1666": {
        "nome": "O Diabo",
        "grupo": "Sangue",
        "habilidades": [
            ("Livre", "Explodir em sangue",
             "Causou dano com a arma sangrenta ou tocou ferida aberta → "
             "10d6 de Sangue."),
            ("Livre", "Sangrar",
             "Crítico de chifre → deixa o chifre cravado: vítima fica "
             "vulnerável a Sangue; arrancar é ação padrão e causa 8d8."),
            ("Movimento", "Transportar pelo sangue",
             "Move-se para qualquer poça de sangue à vista, inclusive a de "
             "um personagem machucado ou morrendo."),
        ],
        "tatica": "Fere um, some, reaparece do sangue dele. Não fica no "
                  "mesmo lugar duas rodadas.",
    },

    "OPRPG:209:140": {
        "nome": "Aracnasita",
        "grupo": "Morte",
        "habilidades": [
            ("Livre", "Estacar",
             "Mordida que acerta → +1d10 Morte e alvo agarrado; sair = ação "
             "padrão + Atletismo DT 20 (um aliado adjacente também pode)."),
            ("Reação", "Desovar aranhas",
             "1×/cena ao ficar machucada: enche a volta de aranhas, que "
             "produzem um efeito novo a cada turno dela."),
            ("Movimento", "Disparar teia",
             "Teia de 3×3m em alcance curto: entrar = agarrado (Reflexos DT "
             "20 evita); começar o turno preso = 2d8+10 Morte."),
        ],
        "tatica": "Prende o grupo na teia e come quem ficou sozinho.",
    },
    "OPRPG:211:400": {
        "nome": "Carniçal",
        "grupo": "Morte",
        "rituaisDoLivro": {"nomes": ["Perturbação"], "dt": 29,
                           "nota": "Referência da habilidade Comando — o "
                                   "carniçal não conjura, só produz estes "
                                   "efeitos."},
        "habilidades": [
            ("Reação", "Pancada poderosa",
             "Crítico de garra → empurra 6m; bateu em parede/carro, +4d6 "
             "impacto (se for outra pessoa, os dois levam)."),
            ("Movimento", "Comando",
             "Ordem a um alvo em alcance curto (Vontade DT 29 evita) — "
             "mesmos efeitos básicos do ritual Perturbação."),
            ("Padrão", "Hipnose",
             "Domina a mente de um alvo em alcance curto (Vontade DT 29). "
             "Faz tudo, menos se matar; repete o teste no fim de cada turno."),
            ("Completa", "Reanimar corpos",
             "1×/cena: 2d4+2 corpos em alcance médio levantam como "
             "esqueletos de Lodo e atacam o mais próximo."),
        ],
        "tatica": "Hipnotiza o mais forte do grupo e deixa os aliados "
                  "resolverem o problema por ele.",
    },
    "OPRPG:213:999": {
        "nome": "Ceifador Espiral",
        "grupo": "Morte",
        "habilidades": [
            ("Movimento", "Transporte pelo pó",
             "Dentro da própria área de cinzas: teleporta para outro ponto "
             "dela e ataca de foice como ação livre."),
            ("Completa", "Contemplar a espiral",
             "Quem o vê em alcance médio: 10d10+30 mental (Vontade DT 43 = "
             "metade). Quem sofreu fica imune até o fim da cena."),
            ("Completa", "Cinzas das terras desoladas",
             "Cria área em alcance longo: 10d10+20 Morte e enjoado "
             "(Fortitude DT 43 = metade)."),
        ],
        "tatica": "Cria as cinzas primeiro; depois usa a área para aparecer "
                  "ao lado de quem estiver curando.",
    },
    "OPRPG:214:140": {
        "nome": "Enraizado",
        "grupo": "Morte",
        "habilidades": [],
        "tatica": "Anda devagar e bate forte: 2d8+8 impacto MAIS 2d12 de "
                  "Morte por golpe.",
    },
    "OPRPG:216:290": {
        "nome": "Escutado",
        "grupo": "Morte",
        "habilidades": [
            ("Movimento", "Vomitar Lodo",
             "1×/cena, na primeira rodada de cada cópia: 4d10+10 Morte em "
             "alcance curto e lento até o fim da cena (Reflexos DT 25 = "
             "metade e sem a condição)."),
        ],
        "tatica": "Aparece em cópias; cada uma vomita uma vez e depois "
                  "morde. Arremessa a própria cabeça em quem estiver longe.",
    },
    "OPRPG:217:40": {
        "nome": "Esqueleto de Lodo",
        "grupo": "Morte",
        "habilidades": [
            ("Completa", "Espiral de Lodo",
             "Vira poça e avança 9m em linha reta: 2d10 Morte em quem estiver "
             "no caminho (Reflexos DT 14 = metade). Reforma-se no fim."),
        ],
        "tatica": "É o coringa de horda: use vários, e use a espiral para "
                  "atravessar a formação do grupo.",
    },
    "OPRPG:219:700": {
        "nome": "Marionete",
        "grupo": "Morte",
        "habilidades": [
            ("Reação", "Reflexos guiados por corda",
             "1×/rodada: quem ficar adjacente leva um ataque de foice."),
            ("Completa", "Ironia do destino",
             "Dois ataques de foice no mesmo alvo; acertando o segundo, "
             "agarra com a arma e carrega a vítima 6m. Enquanto segura, "
             "repassa parte do próprio dano para ela."),
        ],
        "tatica": "Deixa o grupo vir até ela — cada aproximação custa uma "
                  "foice de 10d8+10.",
    },
    "OPRPG:221:400": {
        "nome": "Múmia Xipófaga",
        "grupo": "Morte",
        "habilidades": [
            ("Livre", "Agarrada mumificadora",
             "Garra que acerta → agarra (4d20+30); no início de cada turno "
             "da vítima, 4d8+30 Morte e a múmia cura o mesmo tanto. Vítima "
             "morta assim vira esqueleto de Lodo."),
            ("Padrão", "Amalgamar",
             "Com 0 PV, funde-se a um morto ou criatura de Morte adjacente: "
             "volta com 200 PV, três garras por turno e +5 de dano."),
        ],
        "tatica": "Não morre de primeira: se houver corpo por perto, ela se "
                  "levanta mais forte. Limpe o chão antes de derrubá-la.",
    },
    "OPRPG:224:800": {
        "nome": "Nidere",
        "grupo": "Morte",
        "habilidades": [
            ("Livre", "Reverter",
             "Quem sofre dano das garras invertidas fica enjoado até o fim "
             "do próximo turno dele."),
            ("Livre", "Rastrear e abater",
             "+6d6 de dano contra alvo desprevenido."),
        ],
        "tatica": "Caça: 24m de deslocamento e furtividade alta. Ataca quem "
                  "não a viu chegar e sai antes do troco.",
    },
    "OPRPG:226:990": {
        "nome": "Sempiternal",
        "grupo": "Morte",
        "habilidades": [
            ("Livre", "Toque acelerador",
             "Cada golpe envelhece o alvo além do dano."),
            ("Movimento", "Correntes de Lodo",
             "Alcance médio: 20d6 Morte (Fortitude DT 40 = metade). Quem "
             "ficar machucado por isso pega vulnerabilidade a Morte."),
        ],
        "tatica": "Ataca quatro vezes por rodada com os dedos alongados e "
                  "envelhece o grupo enquanto isso.",
    },
    "OPRPG:227:65": {
        "nome": "Succ",
        "grupo": "Morte",
        "habilidades": [
            ("Livre", "Sucção",
             "Mordida que acerta → prende no rosto e suga o ar: Fortitude DT "
             "17 solta; falhou, fica inconsciente e cai para 0 PV morrendo "
             "no início do próximo turno dele."),
        ],
        "tatica": "Some no escuro, pula no isolado e mata rápido. Aliado "
                  "tem que arrancá-la.",
    },
    "OPRPG:230:2000": {
        "nome": "O Deus da Morte",
        "grupo": "Morte",
        "categoria": "Entidade", "tamanho": "Médio", "elemento": "Morte",
        "habilidades": [
            ("Livre", "Agarrão",
             "Soco espiral em alvo Médio ou menor → agarra (6d20+47)."),
            ("Livre", "Controlar relógio interno",
             "Início de cada turno: encerra até 2 condições nele."),
            ("Movimento", "Controlar mortos",
             "Qualquer criatura de Morte em alcance longo se desloca e ataca "
             "por ordem dele."),
            ("Movimento", "Espiral descendente",
             "Alvo agarrado envelhece 3d20 anos; 1 de dano mental por ano."),
            ("Padrão", "Espiral destrutiva",
             "Espiral de 12m de raio em alcance longo: 10d10+50 Morte "
             "(Fortitude DT 45 = metade)."),
        ],
        "tatica": "Agarra, envelhece, e usa os mortos da cena como exército.",
    },

    "OPRPG:234:1111": {
        "nome": "Anjo",
        "grupo": "Conhecimento",
        "habilidades": [
            ("Livre", "Faixas detentoras",
             "Asas que acertam alvo Médio ou menor → agarra (5d20+45) e "
             "fascina. Um por vez, e continua atacando normalmente."),
            ("Padrão", "Chamas reveladoras",
             "Círculo até alcance médio: 10d8 Conhecimento (Vontade DT 43 = "
             "metade). Quem sofre ganha auréola e o anjo passa a saber onde "
             "essa pessoa está."),
            ("Completa", "Raio dourado",
             "1×/cena: linha de 3m em alcance longo, 15d8+50 Conhecimento "
             "(Reflexos DT 43 = metade)."),
        ],
        "tatica": "Marca todo mundo com as chamas e guarda o raio para "
                  "quando estiverem alinhados.",
    },
    "OPRPG:237:750": {
        "nome": "Bicho-Papão",
        "grupo": "Conhecimento",
        "habilidades": [
            ("Movimento", "Atormentar",
             "Alvo em alcance curto: 3d8 mental (Vontade DT 30 = metade). "
             "Escondido dele, +3d8."),
            ("Completa", "Saltar e assustar",
             "Sai do esconderijo perto de quem não o via: 10d8 mental "
             "(Vontade DT 35 = metade)."),
        ],
        "tatica": "Some, sussurra, some de novo. Só aparece de corpo inteiro "
                  "quando o alvo já está sem Sanidade.",
    },
    "OPRPG:238:500": {
        "nome": "Espreitador",
        "grupo": "Conhecimento",
        "habilidades": [
            ("Movimento", "Correr pelas frestas",
             "Teleporta para qualquer ponto em alcance longo, desde que "
             "haja uma fresta no caminho."),
            ("Completa", "Espreitar",
             "1×/cena, adjacente a alguém dormindo: 10d6 mental (Vontade DT "
             "30 = metade). Se enlouquecer, ele pode copiar a vítima."),
            ("Padrão", "Cópia observada",
             "Manifesta cópia de quem enlouqueceu: mesma ficha, dano vira "
             "Conhecimento, sem rituais nem poderes, dura a cena."),
        ],
        "tatica": "Ataca o acampamento, não o combate. Quem dorme é o alvo.",
    },
    "OPRPG:241:750": {
        "nome": "Estrangeiro",
        "grupo": "Conhecimento",
        "habilidades": [
            ("Livre", "Comandar",
             "Rajada psíquica que causa dano → Vontade DT 35 ou cumpre uma "
             "ordem dele."),
            ("Livre", "Apagar memória",
             "Quem enlouquece por causa dele fica sob controle dele — ou "
             "tem a memória apagada e recupera 1d4 de Sanidade."),
            ("Livre", "Oblívio",
             "Quem sofre o toque sutil esquece que ele existe (Vontade DT "
             "30 evita); repete no fim de cada turno."),
            ("Completa", "Incubar",
             "Toca alguém que o esqueceu e implanta uma larva: lê a mente "
             "dela à distância e consome 1d6 de Sanidade por período."),
        ],
        "tatica": "Não luta: apaga, incuba e usa o grupo contra ele mesmo.",
    },
    "OPRPG:242:36": {
        "nome": "Existido",
        "grupo": "Conhecimento",
        "habilidades": [
            ("Livre", "Brilho enlouquecedor",
             "1×/rodada: quem o vê em alcance médio sofre 1d6 mental "
             "(Vontade DT 14 = metade)."),
            ("Movimento", "Fortalecimento paranormal",
             "Se já causou dano mental com o brilho nesta cena: +1 dado em "
             "testes de AGI/FOR/VIG e +2d4 de Conhecimento nas pancadas, "
             "até o fim da cena."),
        ],
        "tatica": "Fraco sozinho, perigoso em grupo: o brilho soma entre "
                  "vários.",
    },
    "OPRPG:243:180": {
        "nome": "Lembrado",
        "grupo": "Conhecimento",
        "habilidades": [
            ("Padrão", "Expandir aura",
             "Alcance curto: 6d6 mental (Vontade DT 20 = metade)."),
        ],
        "tatica": "Anda para o meio do grupo e explode a aura — quanto mais "
                  "juntos, pior.",
    },
    "OPRPG:244:390": {
        "nome": "Ocioso",
        "grupo": "Conhecimento",
        "habilidades": [
            ("Reação", "Retaliação",
             "Foi atacado ou alvo de habilidade → teleporta para o lado do "
             "agressor e bate (5d20+30, 4d10+20 impacto não letal)."),
            ("Livre", "Permanecer próximo",
             "1×/rodada: teleporta para qualquer ponto do campo de visão do "
             "alvo."),
            ("Completa", "Aterrorizar",
             "Fica parado olhando: quem estiver adjacente sofre 4d10+10 "
             "mental."),
        ],
        "tatica": "Não persegue e não some: só continua ali. Atacar é o que "
                  "faz ele agir.",
    },
    "OPRPG:246:90": {
        "nome": "Parasita de Culpa",
        "grupo": "Conhecimento",
        "habilidades": [
            ("Completa", "Fixar",
             "Aproxima-se de quem dorme: Percepção (com penalidade por "
             "dormir) contra Furtividade 2d20+15. Falhou, vira hospedeiro."),
            ("Completa", "Atormentar",
             "Fixado: no início de cada cena do sonho, 2d6 mental em todos "
             "os que estiverem dentro dele (Vontade DT 20 = metade)."),
            ("Completa", "Cópias do hospedeiro",
             "Fixado: cria até 4 cópias do hospedeiro, com 20 PV e dano de "
             "Conhecimento."),
        ],
        "tatica": "A cena dele é o sonho. Acordar é o objetivo, não vencer.",
    },
    "OPRPG:248:330": {
        "nome": "Rastejador Sombrio",
        "grupo": "Conhecimento",
        "habilidades": [
            ("Livre", "Desespero",
             "Dano do toque da dor vem acompanhado do mesmo tanto de dano "
             "mental (Vontade DT 25 = metade do mental)."),
            ("Livre", "Rastejar",
             "Sob cobertura ou camuflagem: +10 em Furtividade e sem perder "
             "deslocamento ao se mover escondido."),
            ("Movimento", "Tentáculos das sombras",
             "Até 3 alvos em alcance médio ficam agarrados pelas sombras "
             "(Reflexos DT 28 evita) e podem ser arrastados pela área."),
        ],
        "tatica": "Puxa três para o escuro e machuca corpo e mente ao mesmo "
                  "tempo.",
    },
    "OPRPG:250:500": {
        "nome": "Silhueta",
        "grupo": "Conhecimento",
        "habilidades": [
            ("Livre", "Reescrever a realidade",
             "Enquanto se move: transforma objetos em alcance curto em "
             "outros do mesmo tamanho. Não afeta seres nem o que estiverem "
             "vestindo ou segurando."),
            ("Padrão", "Toque devastador",
             "Toca até 2 alvos/objetos e aplica o dano da aura dela."),
        ],
        "tatica": "Quase nunca ataca. Muda o cenário até a cena virar outra.",
    },
    "OPRPG:251:60": {
        "nome": "Vulto",
        "grupo": "Conhecimento",
        "habilidades": [
            ("Completa", "Plantar paranoia",
             "Alcance médio: abalado (Vontade DT 15 evita); quem já estava "
             "abalado fica apavorado."),
        ],
        "tatica": "Aparece de canto de olho. Bom para gastar Sanidade antes "
                  "do combate de verdade.",
    },
    "OPRPG:254:1200": {
        "nome": "Máscara do Desespero",
        "grupo": "Conhecimento",
        "categoria": "Entidade", "tamanho": "Médio",
        "elemento": "Conhecimento",
        "rituaisDoLivro": {"elementos": ["Conhecimento"], "circuloMax": 4,
                           "dt": 45,
                           "nota": "1×/turno, qualquer um destes, sem custo "
                                   "(execução até ação completa, teto de "
                                   "20 PE)."},
        "habilidades": [
            ("Livre", "Conjuração verdadeira",
             "1×/turno: conjura qualquer ritual de Conhecimento de qualquer "
             "círculo (até ação completa, até 20 PE). DT 45."),
            ("Movimento", "Onipresença",
             "Move-se para qualquer sombra da Realidade e sabe o que "
             "acontece nela — ninguém se esconde dela."),
            ("Padrão", "Reescrever realidade",
             "Altera composição, posição e estado de objetos de até 1 "
             "tonelada em alcance médio."),
        ],
        "tatica": "Não precisa estar presente para agir. Quando aparece, a "
                  "cena já está perdida — jogue como consequência, não como "
                  "combate.",
    },

    "OPRPG:257:30": {
        "nome": "Anárquico",
        "grupo": "Energia",
        "habilidades": [],
        "tatica": "Bate errático: 2d12 sem bônus. Vem em número.",
    },
    "OPRPG:259:120": {
        "nome": "Anárquico Descontrolado",
        "grupo": "Energia",
        "habilidades": [
            ("Livre", "Aceleração",
             "Quem sofre a pancada energética fica acelerado: se no turno "
             "seguinte usar movimento+padrão (ou completa), leva 4d12 de "
             "Energia."),
            ("Movimento", "Autodestruição",
             "Explode: 8d12 Energia em alcance curto (Reflexos DT 25 = "
             "metade; adjacentes rolam com 2 dados pelo pior)."),
        ],
        "tatica": "Bate, obriga o grupo a se mexer devagar, e explode no "
                  "meio deles.",
    },
    "OPRPG:261:1000": {
        "nome": "Anomalia",
        "grupo": "Energia",
        "habilidades": [
            ("Livre", "Romper consciência",
             "Quem tenta entender o que está vendo perde Sanidade."),
            ("Livre", "Manipular ondas da existência",
             "Altera o que é possível na cena: distância, gravidade, tempo."),
            ("Completa", "Manifestar o impossível",
             "Cria um efeito que não deveria existir, escolhido pelo mestre."),
        ],
        "tatica": "Não tem corpo para atacar: é cenário hostil com ficha. "
                  "Use para o grupo fugir, não para vencer.",
    },
    "OPRPG:263:600": {
        "nome": "Anomiático",
        "grupo": "Energia",
        "habilidades": [
            ("Livre", "Comportamento errático",
             "Início do turno: role 1d6 três vezes e execute os três "
             "comportamentos na ordem sorteada."),
        ],
        "tatica": "Imprevisível de propósito: role na mesa, à vista, para a "
                  "mesa sentir que ninguém controla aquilo.",
    },
    "OPRPG:265:160": {
        "nome": "Ciborgue",
        "grupo": "Energia",
        "habilidades": [
            ("Completa", "Investida energética",
             "Avança até 24m e soca com +1 dado no ataque: +2d8 de dano "
             "(4d8+10) e derruba (Fortitude DT 20 evita)."),
            ("Movimento", "Criar barreira",
             "+5 de Defesa até o início do próximo turno dele."),
            ("Movimento", "Reiniciar",
             "Encerra uma condição que o esteja afetando."),
        ],
        "tatica": "Atravessa a sala na investida, levanta barreira quando "
                  "focam nele, e reinicia toda vez que prendem ele.",
    },

    "OPRPG:267:600": {
        "nome": "Infecticídio", "grupo": "Energia",
        "habilidades": [
            ("Livre", "Infecção",
             "Quem sofre as pancadas pega o vírus (Fortitude DT 30 evita e "
             "dá imunidade até o fim da cena)."),
            ("Reação", "Consumação insidiosa",
             "Levou alguém a 0 PV com as pancadas → consome a vítima e "
             "recupera 50 PV."),
            ("Completa", "Atropelar",
             "Corre o dobro do deslocamento atravessando espaços ocupados e "
             "ataca cada um que estiver no caminho."),
        ],
        "tatica": "Atravessa a formação inteira e come quem cair.",
    },
    "OPRPG:268:60": {
        "nome": "Perturbado de Energia", "grupo": "Energia",
        "habilidades": [
            ("Livre", "Implantar confusão",
             "1×/rodada: agarra quem acabou de levar o toque plasmático "
             "(4d20+10) e força a reviver traumas: 2d8 mental (Vontade DT "
             "15 = metade)."),
        ],
        "tatica": "Toca, agarra e mexe na cabeça — o dano físico é o menor "
                  "problema.",
    },
    "OPRPG:269:220": {
        "nome": "Sukkalgir", "grupo": "Conhecimento",
        "habilidades": [
            ("Livre", "Agarrão",
             "Mordida em alvo Médio ou menor → agarra (3d20+15)."),
            ("Completa", "Grito de desespero",
             "Alcance médio: 3d12 mental (Vontade DT 20 = metade; cobertura "
             "dá +5 no teste)."),
        ],
        "tatica": "Agarra um e grita para o resto perder Sanidade junto.",
    },
    "OPRPG:271:560": {
        "nome": "Telopsia", "grupo": "Energia",
        "habilidades": [
            ("Movimento", "Viajar pela tela",
             "Some de uma tela e aparece em outra em alcance longo; depois "
             "anda 9m."),
            ("Padrão", "Tela zumbificadora",
             "Alcance médio: 6d6 mental e confuso até o fim da cena "
             "(Vontade DT 30 = metade e sem a condição). Já confuso que "
             "falhar fica também fascinado."),
            ("Completa", "Prender na tela",
             "Desintegra alguém em alcance curto e o materializa dentro da "
             "tela (Fortitude DT 30 evita): paralisado, 2d12 mental por "
             "turno. A cada 50 de dano que a criatura leva, o preso tenta "
             "sair."),
        ],
        "tatica": "Luta pela tela: nunca está no mesmo aparelho duas "
                  "rodadas.",
    },
    "OPRPG:273:950": {
        "nome": "Tempestuoso", "grupo": "Energia",
        "habilidades": [
            ("Livre", "Raio de energia radioativa",
             "Acertou as duas garras no mesmo alvo → o raio salta dele para "
             "outro em alcance médio: 4d20+20 Energia (Reflexos DT 40 = "
             "metade)."),
            ("Completa", "Expandir em radiação",
             "Alcance longo: 10d20+20 Energia (Reflexos DT 40 = metade). "
             "Custa 100 PV a ele."),
        ],
        "tatica": "Usa o grupo como condutor: quanto mais juntos, mais o "
                  "raio salta.",
    },
    "OPRPG:274:360": {
        "nome": "Viajante", "grupo": "Conhecimento",
        "habilidades": [
            ("Livre", "Agarrão",
             "Pancada em alvo Médio ou menor → agarra (2d20+15)."),
            ("Completa", "Devorar memória",
             "Em quem está agarrado: 4d12 mental e esquece completamente "
             "uma pessoa (Vontade DT 29 = metade e sem o esquecimento). "
             "Cada vítima perturbada assim dá +1d12 no dano da pancada."),
        ],
        "tatica": "Come lembrança, não corpo. Cada memória perdida deixa "
                  "ele mais forte.",
    },
    "OPRPG:278:1413": {
        "nome": "Anfitrião", "grupo": "Energia",
        "habilidades": [
            ("Livre", "Potência de Energia",
             "Testes de perícia de AGI e INT com +35; os outros atributos, "
             "+25."),
            ("Livre", "Imunidades",
             "Imune a dano e a efeitos de Energia e a condições de "
             "paralisia. Vulnerável a Conhecimento."),
            ("Completa", "Ato 1 — cinco facetas",
             "Ao começar o combate, divide-se em 5 facetas com a mesma "
             "ficha, 250 PV cada e resistência a dano 20; cada faceta só "
             "usa as habilidades com o nome dela. O ato acaba quando todas "
             "caem."),
            ("Livre", "Enigma de Medo",
             "A imunidade a dano só cai quando o grupo resolve o Enigma de "
             "Medo dele — sem isso, atacar não resolve."),
        ],
        "tatica": "Cinco alvos ao mesmo tempo, cada um com um truque. O "
                  "combate é sobre o enigma, não sobre PV.",
    },
    "OPRPG:282:850": {
        "nome": "Degolificada", "grupo": "Sangue",
        "habilidades": [
            ("Livre", "Agarrar e estrangular",
             "Pancada em alvo Médio ou menor → agarra (5d20+35) e o alvo "
             "fica asfixiado. Até 2 por vez."),
            ("Livre", "Grito rasgado",
             "1×/cena, alcance médio: 4d10+10 mental + efeito aleatório "
             "(1d4) (Vontade DT 35 = metade e sem o efeito)."),
            ("Movimento", "Desfiguramento capilar",
             "Em cada agarrado: 10d6+20 perfuração (Fortitude DT 35 = "
             "metade) e 6d10 mental (Vontade DT 35 = metade)."),
        ],
        "tatica": "Agarra dois, grita uma vez, e usa os cabelos enquanto "
                  "eles não conseguem se soltar.",
    },

    "OPRPG:284:8": {
        "nome": "Bandido", "grupo": "Gente e tropa",
        "habilidades": [
            ("Livre", "Ataque furtivo",
             "1×/rodada: +1d6 de dano contra alvo desprevenido ou flanqueado."),
        ],
        "tatica": "Ameaça, rouba, foge. Só encara em grupo.",
    },
    "OPRPG:284:17": {
        "nome": "Capanga", "grupo": "Gente e tropa",
        "habilidades": [
            ("Livre", "Ataque furtivo",
             "1×/rodada: +1d6 de dano contra alvo desprevenido ou flanqueado."),
        ],
        "tatica": "Segura o alvo até o patrão chegar.",
    },
    "OPRPG:284:25": {
        "nome": "Soldado de Aluguel", "grupo": "Gente e tropa",
        "habilidades": [
            ("Completa", "Ataque em movimento",
             "Percorre o deslocamento e ataca em qualquer ponto do trajeto."),
        ],
        "tatica": "Sai da cobertura, atira em movimento, volta.",
    },
    "OPRPG:285:90": {
        "nome": "Assassino", "grupo": "Gente e tropa",
        "habilidades": [
            ("Livre", "Ataque furtivo",
             "1×/rodada: +4d6 contra desprevenido ou flanqueado."),
            ("Livre", "Mão na boca",
             "Ataque furtivo corpo a corpo cala a vítima: ela não grita nem "
             "alerta ninguém."),
            ("Movimento", "Assassinar",
             "Marca um alvo em alcance curto: até o fim do próximo turno, o "
             "primeiro furtivo que acertar nele tem os dados extras "
             "dobrados."),
        ],
        "tatica": "Marca, espera o flanqueio, e mata em um golpe só.",
    },
    "OPRPG:285:145": {
        "nome": "Comandante Mercenário", "grupo": "Gente e tropa",
        "habilidades": [
            ("Completa", "Ataque em movimento",
             "Percorre o deslocamento e faz os dois ataques em qualquer "
             "ponto do trajeto."),
            ("Movimento", "Ordens",
             "Aliados em alcance médio ganham +1 dado em perícia e +1 dado "
             "de dano até o fim da cena."),
        ],
        "tatica": "Fica atrás, grita ordens (a tropa fica bem mais "
                  "perigosa) e só avança quando o grupo já está gasto.",
    },
    "OPRPG:286:15": {
        "nome": "Cultista", "grupo": "Gente e tropa",
        "rituaisDoLivro": {"circuloMax": 1, "dt": 15,
                           "nota": "CONJURADOR: escolha 2 destes, de um "
                                   "elemento só. Conjura sem pagar PE, até "
                                   "3 PE por conjuração."},
        "habilidades": [],
        "ataques": [("Faca", "Corpo a corpo", 2, 5, "1d4+1 perfuração", "19")],
        "tatica": "Vem em número, morre fácil, e o que importa é o ritual "
                  "que eles estão terminando.",
    },
    "OPRPG:286:35": {
        "nome": "Investido", "grupo": "Gente e tropa",
        "rituaisDoLivro": {"circuloMax": 2, "dt": 17,
                           "nota": "CONJURADOR: escolha 2 de 1º e 2 de 2º "
                                   "círculo, de até dois elementos. Sem "
                                   "pagar PE, até 5 PE por conjuração."},
        "habilidades": [],
        "tatica": "Cultista que já provou do Outro Lado: aguenta mais e não "
                  "recua.",
    },
    "OPRPG:286:150": {
        "nome": "Líder de Culto", "grupo": "Gente e tropa",
        "rituaisDoLivro": {"circuloMax": 3, "dt": 25,
                           "nota": "CONJURADOR: escolha 2 de cada círculo "
                                   "(1º, 2º e 3º), de até dois elementos. "
                                   "Sem pagar PE, até 10 PE por "
                                   "conjuração."},
        "habilidades": [],
        "tatica": "Conjura de trás dos fiéis; se a linha cair, foge para "
                  "reaparecer na próxima missão.",
    },
    "OPRPG:287:15": {
        "nome": "Policial", "grupo": "Gente e tropa",
        "habilidades": [],
        "tatica": "Manda parar, atira em quem correr, chama reforço.",
    },
    "OPRPG:287:40": {
        "nome": "Policial de Elite", "grupo": "Gente e tropa",
        "habilidades": [
            ("Padrão", "Lança-granadas",
             "1×/cena: granada em alcance médio, 8d6 em quem estiver a 6m "
             "do impacto."),
        ],
        "tatica": "Tropa de choque: granada primeiro, avanço depois.",
    },
    "OPRPG:287:105": {
        "nome": "Chefe de Polícia", "grupo": "Gente e tropa",
        "habilidades": [
            ("Completa", "Empurrar e atirar",
             "Empurra um adjacente 3m (Fortitude DT 19 evita) e atira; se "
             "empurrou, +1 dado no ataque e +2d8 de dano."),
            ("Reação", "Teimoso",
             "1×/cena: ignora um efeito com teste de resistência ou reduz "
             "um dano recém-sofrido à metade."),
        ],
        "tatica": "Abre distância e descarrega a espingarda.",
    },
    "OPRPG:288:12": {
        "nome": "Cão de Guarda", "grupo": "Animais",
        "habilidades": [
            ("Livre", "Derrubar",
             "Mordida que acerta → tenta derrubar (2d20+5)."),
        ],
        "tatica": "Late antes. É alarme com dentes.",
    },
    "OPRPG:288:10": {
        "nome": "Enxame de Abelhas", "grupo": "Animais",
        "categoria": "Animal (enxame)", "tamanho": "Médio",
        "ataques": [("Picadas", "Corpo a corpo", 1, 5, "1d6 perfuração", "")],
        "habilidades": [
            ("Livre", "Zumbido nauseante",
             "Quem sofre dano do enxame fica enjoado por 1 rodada "
             "(Fortitude DT 15 evita)."),
            ("Livre", "Corpo de enxame",
             "Metade do dano de golpe único; 50% a mais de dano de área."),
        ],
    },
    "OPRPG:288:15": {
        "nome": "Enxame de Ratos", "grupo": "Animais",
        "categoria": "Animal (enxame)", "tamanho": "Médio",
        "ataques": [("Mordidas", "Corpo a corpo", 1, 5, "1d6 corte", "")],
        "habilidades": [
            ("Livre", "Doença",
             "Quem sofre dano do enxame contrai febre hemorrágica "
             "(Fortitude DT 15 evita)."),
            ("Livre", "Corpo de enxame",
             "Metade do dano de golpe único; 50% a mais de dano de área."),
        ],
    },
    "OPRPG:288:40": {
        "nome": "Jacaré", "grupo": "Animais",
        "habilidades": [
            ("Livre", "Agarrão",
             "Mordida em alvo Médio ou menor → agarra (3d20+7)."),
        ],
        "ataques": [
            ("Mordida", "Corpo a corpo", 3, 5, "1d8+8 corte", ""),
            ("Cauda", "Corpo a corpo", 3, 5, "1d12 impacto", ""),
        ],
        "tatica": "Espera na água. Agarra e rola.",
    },
    "OPRPG:289:35": {
        "nome": "Javaporco", "grupo": "Animais",
        "habilidades": [
            ("Reação", "Mordida final",
             "Ao chegar a 0 PV, morde um oponente aleatório."),
        ],
        "ataques": [("Mordida", "Corpo a corpo", 2, 5, "1d8+4 corte", "")],
        "tatica": "Investe em linha reta e não para até cair.",
    },
    "OPRPG:289:55": {
        "nome": "Onça-Pintada", "grupo": "Animais",
        "habilidades": [
            ("Livre", "Agarrão",
             "Mordida em alvo Médio ou menor → agarra (3d20+7)."),
            ("Completa", "Bote",
             "Investida com mordida e garras; os três ataques ganham o bônus "
             "da investida e vão no mesmo alvo."),
        ],
        "tatica": "Some no mato, bota em quem está atrás do grupo.",
    },
    "OPRPG:289:68": {
        "nome": "Sucuri", "grupo": "Animais",
        "habilidades": [
            ("Livre", "Agarrão",
             "Mordida em alvo Médio ou menor → agarra (3d20+12)."),
            ("Livre", "Constrição",
             "Início de cada turno dela: 2d6+8 impacto em quem estiver "
             "agarrado."),
        ],
        "tatica": "Enrola e aperta. Quem não for solto por um aliado morre "
                  "apertado.",
    },

    "VO1:30:15": {
        "nome": "Lia Schmidt", "grupo": "Vendeta Oculta",
        "habilidades": [],
        "tatica": "Atendente do trem. Não é combatente: se defende com o que "
                  "tiver na mão e corre na primeira chance.",
    },
    "VO1:31:15": {
        "nome": "Matheus Santavilla (antes do ritual)",
        "grupo": "Vendeta Oculta",
        "habilidades": [
            ("Livre", "Dilacerar",
             "Acertou as duas facadas no mesmo alvo na rodada → +2d4 de dano."),
        ],
        "tatica": "Ainda é só um homem com uma faca. Se o grupo agir rápido, "
                  "a missão 00 acaba sem o chefe.",
    },
    "VO1:31:30": {
        "nome": "Matheus, Cultista (CHEFE)", "grupo": "Vendeta Oculta",
        "rituaisDoLivro": {"nomes": ["Eletrocussão", "Perturbação"],
                           "dt": 15,
                           "nota": "Conjura sem pagar PE, até 3 PE por "
                                   "conjuração."},
        "habilidades": [
            ("Livre", "Dilacerar",
             "Acertou as duas facadas no mesmo alvo na rodada → +2d4 de dano."),
            ("Livre", "Faca condutora",
             "Facada que acerta pode ficar cravada: enquanto estiver no "
             "corpo, o alvo tem −5 para resistir a Eletrocussão."),
        ],
        "tatica": "Crava a faca, afasta-se e conjura. Regras de CHEFE para "
                  "6+ jogadores: iniciativa dupla, +5 de Defesa a partir do "
                  "3º ataque na rodada, e 1×/combate encerra uma condição.",
    },
    "VO1:59:50": {
        "nome": "Bernardo — Existido de Morte", "grupo": "Vendeta Oculta",
        "categoria": "Criatura", "tamanho": "Médio", "elemento": "Morte",
        "habilidades": [
            ("Padrão", "Aceleração",
             "Do próximo turno até o fim da cena: uma ação padrão a mais "
             "por turno."),
            ("Padrão", "Distorção temporal",
             "Alvo em alcance curto fica lento até o fim da cena (Fortitude "
             "DT 15 reduz para 1 rodada)."),
        ],
        "tatica": "Acelera na primeira rodada e passa a agir duas vezes "
                  "enquanto o grupo fica lento.",
    },
    "VO1:61:100": {
        "nome": "Sereia Encarnada de Morte (CHEFE)",
        "grupo": "Vendeta Oculta",
        "habilidades": [
            ("Reação", "Eu não existo",
             "1×/cena: deixa de existir por 1 rodada — nenhum ataque ou "
             "efeito a alcança."),
            ("Livre", "Enrolar tentáculos",
             "Tentáculos que acertam → agarra (2d20+15); usa para afogar ou "
             "puxar até a mordida."),
            ("Movimento", "Canção do mar",
             "Maldição em raio de 90m, mantida enquanto ela gastar ação: "
             "desconforto (−2 em testes), distração (desprevenido), "
             "distorção (2d6 mental) ou desordem (por último na "
             "iniciativa)."),
            ("Padrão", "Aceleração",
             "Do próximo turno até o fim da cena: uma ação padrão a mais "
             "por turno."),
            ("Padrão", "Consumir presa",
             "Vítima inconsciente ou morta nos tentáculos vira espuma; ela "
             "recupera 2d8+2 PV."),
        ],
        "tatica": "Canta de longe, puxa quem entrar na água e some quando "
                  "levar foco. Some do mar leva a canção junto.",
    },
    "VO1:110:20": {
        "nome": "Capivara Sangrenta", "grupo": "Vendeta Oculta",
        "habilidades": [
            ("Reação", "Pulgas sangrentas",
             "1×/rodada: quem a ataca corpo a corpo é atingido pelas pulgas "
             "dela."),
            ("Livre", "Investida sangrenta",
             "Investida que acerta: +2d6 de dano e a vítima fica sangrando."),
        ],
        "tatica": "Vem em bando e atropela. Bater nela de perto custa caro.",
    },
    "VO1:110:20b": {
        "nome": "Guarda-Costas", "grupo": "Vendeta Oculta",
        "manual": {
            "vd": 20, "pv": 20, "defesa": 17, "tipo": "Pessoa",
            "tamanho": "Médio", "elemento": "",
            "atributos": {"AGI": 2, "FOR": 2, "INT": 1, "PRE": 1, "VIG": 2},
            "deslocamento": 9,
            "testes": {"percepção": {"dados": 1, "bonus": 5},
                       "iniciativa": {"dados": 2, "bonus": 10},
                       "fortitude": {"dados": 2, "bonus": 5},
                       "reflexos": {"dados": 2, "bonus": 5}},
            "ataques": [
                {"nome": "Soco", "alcance": "Corpo a corpo", "extra": "",
                 "critico": "", "dados": 2, "bonus": 5,
                 "dano": "1d6+5 impacto"},
                {"nome": "Submetralhadora", "alcance": "À distância",
                 "extra": "curto", "critico": "19/x3", "dados": 2,
                 "bonus": 5, "dano": "2d6+5 balístico"},
            ],
        },
        "habilidades": [],
        "tatica": "Fica entre o alvo dele e o grupo. Atira para afastar, "
                  "não para matar.",
    },
    "VO1:111:35": {
        "nome": "Onça Sangrenta", "grupo": "Vendeta Oculta",
        "habilidades": [
            ("Livre", "Agarrão",
             "Mordida em alvo Médio ou menor → agarra."),
            ("Completa", "Bote",
             "Investida com mordida e as duas garras, todos no mesmo alvo, "
             "com o bônus da investida."),
        ],
        "tatica": "Aparece do mato junto com Ramiro e vai atrás de quem "
                  "estiver ferido.",
    },
    "VO1:111:60": {
        "nome": "Ramiro Miranda", "grupo": "Vendeta Oculta",
        "habilidades": [
            ("Reação", "Comandar onça",
             "1×/rodada: manda a onça sangrenta (em alcance curto) receber "
             "no lugar dele um ataque ou efeito."),
        ],
        "ataques": [("Facão", "Corpo a corpo", 1, 10, "1d10+5 corte", "")],
        "tatica": "Luta ao lado da onça e usa o bicho como escudo. Aliado "
                  "difícil, mas aliado.",
    },
    "VO1:113:110": {
        "nome": "Quimera de Sangue (CHEFE)", "grupo": "Vendeta Oculta",
        "habilidades": [
            ("Livre", "Agarrão",
             "Mordida de onça em alvo Médio ou menor → agarra (2d20+15)."),
            ("Livre", "Arrancar olho",
             "Crítico da bicada → arranca um olho: ofuscado e vulnerável "
             "até o fim da missão; sem olhos, cego."),
            ("Padrão", "Cabeças múltiplas",
             "Ataca com duas das três bocas (tuiuiú, jacaré, onça)."),
            ("Livre", "Giro de sangue",
             "Mordida de jacaré em alvo agarrado → vítima fica sangrando."),
            ("Reação", "Comandar onça",
             "1×/rodada: a onça sangrenta em alcance curto recebe no lugar "
             "dela um ataque ou efeito."),
        ],
        "tatica": "Agarra com a onça, morde com o jacaré, e usa a bicada "
                  "para cegar quem atira.",
    },
    "VO1:139:30": {
        "nome": "Sussurro Enraizado", "grupo": "Vendeta Oculta",
        "habilidades": [
            ("Livre", "Doença embaralhada",
             "Mordida que acerta contamina com mente embaralhada (Vontade "
             "DT 20 evita)."),
            ("Livre", "Sussurros da Morte",
             "1×/rodada: quem o ouve em alcance curto sofre 1d6 mental "
             "(Vontade DT 14 = metade)."),
        ],
        "tatica": "Fala baixo o tempo todo: o dano mental soma enquanto o "
                  "grupo procura de onde vem a voz.",
    },
    "VO1:139:200": {
        "nome": "Joaquim (CHEFE)", "grupo": "Vendeta Oculta",
        "habilidades": [
            ("Livre", "Agarrão",
             "Pancada que acerta → agarra (3d20+20)."),
            ("Livre", "Mastigar existência",
             "Mordida em alvo agarrado → +2d10 de Conhecimento."),
        ],
        "ataques": [
            ("Pancada", "Corpo a corpo", 3, 15, "2d8+10 impacto", ""),
            ("Mordida", "Corpo a corpo", 3, 15, "2d10+10 perfuração", ""),
        ],
        "tatica": "Agarra e come. Enquanto segura alguém, o resto do grupo "
                  "tem que escolher entre atacar e resgatar.",
    },
    "VO1:139:200b": {
        "nome": "Nívea (CHEFE)", "grupo": "Vendeta Oculta",
        "manual": {
            "vd": 120, "pv": 200, "defesa": 28, "tipo": "Criatura",
            "tamanho": "Grande", "elemento": "Conhecimento",
            "atributos": {"AGI": 3, "FOR": 3, "INT": 2, "PRE": 3, "VIG": 3},
            "deslocamento": 9,
            "testes": {"percepção": {"dados": 3, "bonus": 15},
                       "iniciativa": {"dados": 3, "bonus": 15},
                       "fortitude": {"dados": 3, "bonus": 15},
                       "reflexos": {"dados": 3, "bonus": 15},
                       "vontade": {"dados": 3, "bonus": 15}},
            "ataques": [
                {"nome": "Serra enxertada", "alcance": "Corpo a corpo",
                 "extra": "x2", "critico": "", "dados": 3, "bonus": 15,
                 "dano": "2d12+10 corte"},
                {"nome": "Seringas venenosas", "alcance": "Corpo a corpo",
                 "extra": "", "critico": "", "dados": 3, "bonus": 15,
                 "dano": "1d4+10 perfuração + veneno"},
            ],
        },
        "habilidades": [
            ("Reação", "Torcer ossos",
             "1×/rodada: evita um ataque que a acertou ou outro efeito "
             "negativo (rituais não)."),
            ("Livre", "Injetar Conhecimento",
             "Seringa que acerta → Vontade DT 23 ou fascinado com visões, "
             "até sofrer ação hostil, ser sacudido ou fim da cena."),
        ],
        "tatica": "Enfermeira que virou outra coisa: fascina um, corta o "
                  "resto, e torce o corpo para não morrer.",
    },
    "VO1:140:150": {
        "nome": "Giordano Argento (Vendeta Oculta)",
        "grupo": "Vendeta Oculta",
        "rituaisDoLivro": {
            "nomes": ["Armadura de Sangue", "Descarnar", "Dissipar Ritual",
                      "Eletrocussão", "Salto Fantasma", "Velocidade Mortal"],
            "dt": 25,
            "nota": "Os rituais que ele usa para garantir a fuga. Sem pagar "
                    "PE, até 10 PE por conjuração."},
        "habilidades": [
            ("Livre", "Ataque furtivo",
             "1×/rodada: +4d6 contra desprevenido ou flanqueado."),
            ("Livre", "Especialista em manobras",
             "1×/rodada, ao acertar desarmado: agarrar, derrubar ou "
             "desarmar como ação livre."),
        ],
        "tatica": "Não é o confronto final: é o aviso de que ele sabe "
                  "lutar. Some assim que o combate deixar de convir.",
    },

    "VO2:110:6": {
        "nome": "Bêbado Local", "grupo": "Vendeta Oculta 2",
        "categoria": "Pessoa", "tamanho": "Médio",
        "habilidades": [],
        "ataques": [("Garrafa", "Corpo a corpo", 1, 0, "1d4 corte", "")],
        "tatica": "Atrapalha, fala demais e sabe de um detalhe verdadeiro.",
    },
    "VO2:111:400": {
        "nome": "Criatura do Lago (CHEFE)", "grupo": "Vendeta Oculta 2",
        "habilidades": [
            ("Livre", "Agarrão",
             "Mordida que acerta → agarra com o corpo comprido (4d20+30)."),
            ("Padrão", "Sopro de Energia",
             "Linha de 18m: 12d12 Energia e cego por 1d4 rodadas (Reflexos "
             "DT 30 = metade e sem a cegueira). Uma cegueira por alvo por "
             "cena; recarrega com uma ação de movimento."),
            ("Completa", "Engolir",
             "Começou o turno agarrando → novo teste de agarrar (4d20+30): "
             "engole o alvo, que fica preso, cego e com cobertura total."),
        ],
        "tatica": "Sopra a linha para cegar, agarra o cego e engole.",
    },
    "VO2:112:140": {
        "nome": "Derretido", "grupo": "Vendeta Oculta 2",
        "habilidades": [
            ("Padrão", "Arrastar repulsivo",
             "Até o próximo turno dele, tudo que ele arrasta no movimento "
             "sofre 4d6 de Sangue e cai (Atletismo DT 20 evita)."),
            ("Padrão", "Rastro corrosivo",
             "Deixa ácido por onde passa: terreno difícil, 1d6 de dano a "
             "quem entrar ou começar o turno na área."),
            ("Padrão", "Simular corpo",
             "Imita silhueta de pessoa, animal ou objeto: na penumbra, +10 "
             "em Furtividade e Enganação."),
            ("Completa", "Consumir",
             "Devora quem estiver inconsciente com 0 PV na área dele e "
             "recupera 20 PV."),
            ("Completa", "Deslizar nojento",
             "Percorre o triplo do deslocamento em espaço aberto."),
        ],
        "tatica": "Finge ser móvel, pessoa ou poça. Ataca quando o grupo "
                  "passa por cima dele.",
    },
    "VO2:113:16": {
        "nome": "Fazendeiro Isolado", "grupo": "Vendeta Oculta 2",
        "habilidades": [],
        "ataques": [
            ("Peixeira", "Corpo a corpo", 2, 5, "1d8+5 corte", "19"),
            ("Espingarda", "À distância", 1, 5, "4d6 balístico", "x3"),
        ],
        "tatica": "Sozinho é figurante; em turba (a Moleira chama 3d4) "
                  "cada um deles fica mais perigoso pelo número.",
    },
    "VO2:113:300": {
        "nome": "Giacomo Argento, o Coveiro (CHEFE regional)",
        "grupo": "Vendeta Oculta 2",
        "habilidades": [
            ("Reação", "Racionalização absoluta",
             "1×/cena: declara uma ação inválida antes dela acontecer — "
             "aquela ação falha, sem explicação."),
            ("Livre", "Rituais acelerados",
             "1×/rodada: ritual de execução completa ou menor vira ação "
             "livre."),
            ("Completa", "Análise preliminar",
             "No 1º turno: até o fim da cena causa +2 dados de dano em "
             "combatentes, +1d20 em ataques contra especialistas e RD 10 "
             "contra ocultistas."),
        ],
        "rituaisDoLivro": {"elementos": ["Conhecimento"], "circuloMax": 3,
                           "dt": 29,
                           "nota": "conjura sem pagar PE, até 10 PE por "
                                   "conjuração"},
        "ataques": [("Pá", "Corpo a corpo", 4, 20, "4d10+20 impacto", "")],
        "tatica": "Lê o grupo na primeira rodada e passa a jogar contra a "
                  "classe de cada um.",
    },
    "VO2:114:200": {
        "nome": "Giuseppina Argento, a Moleira (CHEFE regional)",
        "grupo": "Vendeta Oculta 2",
        "habilidades": [
            ("Padrão", "Sementes constritoras venenosas",
             "1×/rodada, cone de 9m: envenenados — enredados e −1d12 PV por "
             "rodada, 1d4+1 rodadas (Fortitude DT 29 vira lento por 1 "
             "rodada)."),
            ("Completa", "Damas sanguinolentas",
             "1×/cena: invoca 1d4 damas de Sangue."),
            ("Completa", "Turba de fazendeiros",
             "1×/cena: chama 3d4 fazendeiros isolados; cada um ganha +2 em "
             "ataque, Defesa e dano por fazendeiro na cena."),
        ],
        "rituaisDoLivro": {"elementos": ["Sangue"], "circuloMax": 3,
                           "dt": 29,
                           "nota": "conjura sem pagar PE, até 10 PE por "
                                   "conjuração"},
        "tatica": "Enche a cena de gente e de damas, e deixa o grupo gastar "
                  "recurso com a turba.",
    },
    "VO2:115:200": {
        "nome": "Melancolia", "grupo": "Vendeta Oculta 2",
        "manual": {"atributos": {"AGI": 1, "FOR": 0, "INT": 2, "PRE": 4,
                                 "VIG": 1}},
        "categoria": "Criatura", "tamanho": "Grande", "elemento": "Sangue",
        "habilidades": [
            ("Livre", "Infecção em quatro estágios",
             "Parasita que se instala na vítima e piora por estágio, cada "
             "um com um teste de Vontade para se livrar: I (Sangue) DT 25, "
             "II (Energia) DT 30 — alquebrado e frustrado, III (Morte) DT "
             "35 — esmorecido, IV (Conhecimento) DT 40 — a vítima passa a "
             "agir só para tirar a própria vida. As condições valem mesmo "
             "para quem é imune a efeito mental."),
            ("Livre", "Cresce ao ser vista",
             "A cada estágio o parasita fica maior e mais visível para a "
             "vítima (Minúsculo → Grande), e o teste fica mais difícil."),
            ("Livre", "Recuperação lenta",
             "Vencido o teste, o parasita troca de vítima; a antiga leva um "
             "dia por estágio para voltar ao normal."),
        ],
        "tatica": "Não é combate: é uma doença com ficha. Marque o estágio "
                  "de cada PJ e cobre o teste no começo de cada cena.",
    },
    "VO2:116:310": {
        "nome": "Pietro Argento, o Engenheiro (CHEFE regional)",
        "grupo": "Vendeta Oculta 2",
        "habilidades": [
            ("Padrão", "Espiral de lentidão",
             "1×/rodada, raio de 9m: alvos à escolha dele ficam lentos até "
             "o fim da cena (Fortitude DT 29 reduz para 1 rodada)."),
            ("Padrão", "Lodo da paralisia",
             "1×/rodada, raio de 9m: alvos à escolha dele ficam paralisados "
             "1 rodada (Fortitude DT 29 evita). Um alvo por cena."),
        ],
        "rituaisDoLivro": {"elementos": ["Morte"], "circuloMax": 3,
                           "dt": 29,
                           "nota": "conjura sem pagar PE, até 10 PE por "
                                   "conjuração"},
        "tatica": "Trava o grupo e corta com a motosserra quem ficou parado.",
    },
    "VO2:161:500": {
        "nome": "Giordano Argento — o Herdeiro (CHEFE FINAL)",
        "grupo": "Vendeta Oculta 2",
        "habilidades": [
            ("Livre", "Ataque furtivo",
             "1×/rodada: +4d6 contra desprevenido ou flanqueado."),
            ("Livre", "Especialista em finta",
             "1×/rodada: finta como ação livre (4d20+25)."),
            ("Livre", "Especialista em manobras",
             "1×/rodada, ao acertar desarmado: agarrar, derrubar ou "
             "desarmar como ação livre (6d20+25)."),
        ],
        "rituaisDoLivro": {"elementos": ["Sangue", "Morte", "Conhecimento",
                                         "Energia"],
                           "circuloMax": 3, "dt": 29,
                           "nota": "conjura sem pagar PE, até 10 PE por "
                                   "conjuração"},
        "tatica": "Finta, agarra e bate três vezes por rodada. A contagem "
                  "regressiva de cenas define com quantos PV ele entra.",
    },

    "CASOS:23:35": {
        "nome": "Bicho-Papão (versão de caso)",
        "grupo": "Casos Paranormais",
        "categoria": "Criatura", "tamanho": "Médio",
        "elemento": "Conhecimento",
        "habilidades": [
            ("Movimento", "Atormentar",
             "Alvo em alcance curto: 1d8+1 mental (Vontade DT 15 = metade); "
             "escondido dele, 2d8+2."),
            ("Completa", "Saltar e assustar",
             "Sai do esconderijo perto de quem não o via: 3d8+3 mental "
             "(Vontade DT 15 = metade)."),
        ],
        "tatica": "Versão fraca do bicho-papão: serve para NEX baixo.",
    },
    "CASOS:43:100": {
        "nome": "Amálgama Decadente", "grupo": "Casos Paranormais",
        "habilidades": [
            ("Livre", "Agarrão",
             "Garras que acertam alvo Médio ou menor → agarra (3d20+12) e "
             "manifesta outro braço, mantendo os dois ataques."),
            ("Movimento", "Incorporar",
             "Novo teste de agarrar contra quem já está preso: puxa para "
             "dentro do corpo de lodo — sufocando e 3d8+3 de Morte por "
             "turno lá dentro."),
        ],
        "tatica": "Agarra, engole e continua atacando com braços novos.",
    },
    "CASOS:43:30": {
        "nome": "Turba de Seguidores da Noite",
        "grupo": "Casos Paranormais",
        "categoria": "Pessoa (enxame)", "tamanho": "Médio",
        "habilidades": [
            ("Livre", "Enxame de gente",
             "É multidão, não indivíduo: ocupa a área toda, atravessa "
             "espaço ocupado e não pode ser agarrada."),
            ("Padrão", "Sufocar pelo número",
             "Quem estiver dentro da área da turba é empurrado, imobilizado "
             "ou pisoteado — o mestre escolhe conforme a cena."),
        ],
        "ataques": [("Mãos e paus", "Corpo a corpo", 1, 5,
                     "1d6+2 impacto", "")],
        "tatica": "Não negocia e não se dispersa por dano: dispersa por "
                  "medo, luz ou pela quebra do ritual que a juntou.",
    },
    "CASOS:71:10": {
        "nome": "Civil armado (Casos Paranormais)",
        "grupo": "Casos Paranormais",
        "habilidades": [
            ("Livre", "Não sabe o que está fazendo",
             "Ataca com medo: erra o alvo com facilidade e desiste assim "
             "que alguém do grupo mostrar autoridade (Diplomacia ou "
             "Intimidação DT 15)."),
        ],
        "tatica": "Existe para ser salvo, não para lutar. Se o grupo "
                  "matá-lo, a missão cobra depois.",
    },
    "VOO:28:10": {
        "nome": "Dissociado", "grupo": "Missões extras",
        "habilidades": [],
        "ataques": [("Pancada", "Corpo a corpo", 1, 5, "1d4+1 impacto", "")],
        "tatica": "Passageiro que perdeu o fio da própria existência. Ataca "
                  "sem reconhecer ninguém.",
    },
    "VOO:29:8": {
        "nome": "Cão Dissociado", "grupo": "Missões extras",
        "habilidades": [],
        "tatica": "O bicho também virou. Rápido e barulhento.",
    },
    "VOO:30:70": {
        "nome": "Traumático (Enfraquecido)", "grupo": "Missões extras",
        "habilidades": [
            ("Completa", "Invocar desastre",
             "Cria um efeito destrutivo ligado ao desastre que o gerou — "
             "incêndio, despressurização, colisão. O mestre escolhe ou "
             "improvisa; role 1d4 por personagem em alcance médio para ver "
             "quem é atingido."),
        ],
        "tatica": "Repete o acidente que o criou. A cena é sobre o desastre, "
                  "não sobre ele.",
    },
    "BRUMAS:15:80": {
        "nome": "Enraizado das Brumas", "grupo": "Missões extras",
        "habilidades": [
            ("Padrão", "Revelar destino",
             "Alvo em alcance curto: 2d6 mental e confuso (Vontade DT 20 = "
             "metade e sem a condição). Um alvo por cena."),
        ],
        "tatica": "Conta para a pessoa como ela vai morrer. Depois bate.",
    },
    "BRUMAS:16:400": {
        "nome": "Xilosapien (CHEFE)", "grupo": "Missões extras",
        "habilidades": [
            ("Reação", "Revelar face verdadeira",
             "1×/cena ao ficar machucada: alcance médio, 5d6 mental "
             "(Vontade DT 25 = metade)."),
            ("Movimento", "Tentáculos",
             "Até 3 alvos em alcance médio ficam agarrados por raízes "
             "(Reflexos DT 25 evita) e podem ser arrastados pela área."),
            ("Completa", "Terror verdadeiro",
             "Usa um agarrado para mostrar a morte dele na cabeça de todos "
             "em alcance médio: 6d6 mental (Vontade DT 25 = metade)."),
        ],
        "tatica": "Prende três, tira a máscara, e transforma a cena em "
                  "perda de Sanidade coletiva.",
    },
}
