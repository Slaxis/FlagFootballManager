# Flag Football Manager — Roadmap

> **O jogo:** o Elifoot 2000 do flag football brasileiro. Gestão de clube,
> 100% em painéis, single player. Você é o manager de um time amador e sobe
> — ou é demitido — pela estrutura real da CBFA.

Este documento é a fonte de verdade do plano. Cada branch abaixo segue o
ciclo: **planejar → apresentar → aprovar → implementar → testar → fechar.**

---

## 1. A realidade que o jogo adapta

Estrutura real do flag brasileiro (CBFA, 2025/26), levantada em 2026-09-05:

- **139 times em 2025** — 99 masculinos, 40 femininos, 60 cidades, 23 UFs + DF
- **5 regiões**: Norte, Nordeste, Centro-Oeste, Sudeste, Sul
- **Fase regional classificatória** → **Super Final** com 16 times por categoria
- **Três divisões nacionais**: Série A, B e C (a C criada em 2026)
- **Acesso**: campeão e vice de cada regional vão pra Série A; demais
  classificados caem em B ou C
- O Rio tem 5 títulos nacionais de flag, empatado com SP e atrás só do MS (6)
- Flag é olímpico em LA 2028

⚠️ A listagem de origem erra a região de alguns clubes: RR e TO aparecem como
Sul (são Norte), PB como Sul (é Nordeste), SC como Sudeste (é Sul). Por isso a
região **nunca é armazenada no clube** — é derivada da UF via `RegionDef`.

⚠️ A mesma página, puxada duas vezes, devolveu listas diferentes (9 vs 8 times
no RJ) e **omitiu o Flag Kings** — o clube mais importante do Rio e atual
campeão brasileiro. A lista é melhor esforço, não verdade absoluta: o
conhecimento do autor sobre a cena carioca supera o scrape.

Somos o *International Superstar Soccer* do flag: adaptação, não simulação.

---

## 2. Decisões fechadas

| # | Decisão |
|---|---|
| 1 | **MVP é só masculino.** Mas o clube modela **dois elencos** (`squads`), porque gerir masculino + feminino é o diferencial em relação ao Elifoot. O feminino entra depois sem refatoração. |
| 2 | **Assimetria estadual é abraçada.** SP tem ~60 times, RR tem 6. Começar em SP é hard mode; em RR é fácil subir e caro viajar. Variedade de carreira de graça. |
| 3 | **Todos os jogos ao vivo.** A rodada inteira roda junto na tela, um jogo por linha, tabela mudando em tempo real. |
| 4 | **Duas rotas de carreira**, como no Elifoot: subir de tier **com o time**, ou **trocar de time** (ser demitido, ser convidado). O manager é uma entidade própria, com reputação. |
| 5 | ~~Força é um número único.~~ **REVISADA (2026-09-06):** 7 stats base (`strength`, `stamina`, `agility`, `dexterity`, `perception`, `intelligence`, `charisma`) e as stats de jogo **derivadas por fórmula** em JSON. São 7 dos 9 atributos do life sim — `speed` e `balance` saíram porque viraram derivadas. |
| 6 | **Perks aprovados** (tabela na §4). |
| 7 | **Posições e padrões táticos aprovados** (§4). |
| 8 | **Calendário orientado a semana**, não a tempo real: `S/YYYY`, 52 turnos por ano. |
| 9 | **O evento padrão de toda semana é o coletivo.** Por isso o motor e a tela de partida vêm cedo, não no fim. |
| 10 | **Não existe "Player" — existe `Actor`.** Jogador, técnico, scout e o seu Manager são a mesma entidade. Função é **escalação, não tipo**: no tier 4 o Manager pode ser head coach *e* quarterback ao mesmo tempo; no tier 1 são actors diferentes. Acumular funções **penaliza o desempenho** — e subir de tier é, literalmente, poder parar de fazer tudo sozinho. |
| 11 | **A carreira do Manager é um roguelike de vida inteira.** Começa aos **18** como manager tier 4, envelhece, e morre aos 90 (número arbitrário, a evoluir). Dinastia não é sistema: é simplesmente criar um novo manager no ano em que o anterior morreu. |
| 12 | **A força do Manager persiste e cresce com resultados.** É a correção da falha do Elifoot, onde o técnico não tem memória: perdeu por azar, foi punido igual. Aqui azar é ruído, não sentença. |
| 13 | **Clubes nascem, se fundem e morrem.** Nada de JSON autorado para clubes novos — `TeamGenerator` inventa. Fusão e extinção (que redistribui os actors) são simulados. |
| 14 | **"Praça", não "Leilão".** Leilão pressupõe dinheiro que o esporte amador não tem. Na Praça ficam os actors sem clube — jogadores *e* comissão técnica — esperando convite. |
| 15 | **Toda branch termina com algo que você abre o jogo e vê.** Quando a branch é lógica pura, ela entrega a visualização mais feia possível de si mesma — uma tela de debug conta. Vale retroativamente: `A.2` e `A.3` somaram ~700 linhas e zero pixels, e essa dívida é paga em `B.3`. |
| 17 | **Modalidade, não gênero.** O jogo não pergunta se você é homem ou mulher; pergunta **em que modalidade você joga** e **qual você gerencia**. O `Actor` carrega `plays` e `manages` como arrays de `masc`/`fem`/`misto` — "joguei no masculino, treinei o feminino" é a norma no flag brasileiro, não exceção. Duas regras duras: `plays` não pode conter `masc` e `fem` juntos, e **`misto` não fica sozinho** — o time misto tem cota de mulheres, então o elenco precisa saber se você ocupa vaga de homem ou de mulher. As cinco respostas legais: nenhuma, `[masc]`, `[fem]`, `[masc, misto]`, `[fem, misto]`. |
| 18 | **`The` é o Blackboard, `Record` é o item.** O quadro compartilhado por onde o estado flui entre cenas é `The.board`; cada entrada tipada nele é um `Record`, que sabe se serializar. O Flow gateia as próprias transições no conteúdo do quadro — controle dirigido por blackboard, e a lib já fazia isso sem nomear. |
| 19 | ~~**A régua é ancorada no adulto mediano.**~~ **SUBSTITUÍDA pela 43.** |
| 20 | **O líder empresta seus passos ao elenco.** O modificador é `passo − 5`, com a âncora do adulto mediano como zero: 6 dá +1, 7 dá +2, e um líder de 3 passos **atrapalha** em −2. Vale para atributos e para as habilidades de comissão, e é por isso que a ficha do manager não é enfeite. |
| 21 | **A criação é paga em anos de vida.** A tela **sorteia um moleque de 12 anos** — corpo, os 8 atributos entre 2 e 7, e às vezes um perk — e **os 6 anos que fazem dele um adulto são os que você gasta** (~130 career points). O sorteio não encosta nas habilidades de propósito: como um teste é atributo + habilidade, decidir isso pelo jogador esvaziaria a única pergunta da tela. O perk sai desses mesmos 12 anos — quem veio com Craque pagou em atributo, quem veio com Vidraça está mais forte por causa disso — e serve pra dar um tom antes do jogador decidir qualquer coisa. O 🎲 sorteia **outro moleque**, idêntico — os dados escolhem quem você nasceu, nunca quem você virou. A origem de todo custo continua sendo o zero, então vender um atributo devolve os 45 pontos inteiros e você pode se refazer do nada. A idade sobe enquanto você distribui e volta quando você desfaz. Tudo pode ser devolvido até zero. Atributos e habilidades saem do mesmo bolso, porque treinar destreza e treinar lançamento melhoram a mesma jogada. **E você sai da tela aos 18 ou não sai**: o botão de começar fica fechado enquanto sobrar ponto. A moeda é o **career point**: entrar no passo N custa N pontos do próprio tipo, e um ponto de atributo vale 3 career points contra 2 de habilidade — crescer é mais caro que aprender. Um ano de vida dá 23, então a vida inteira vale 414. A semente **é o nome**: `hash(nome + sobrenome + apelido)`. Ela não *rola* a ficha — o jogador continua distribuindo cada ponto à mão, que era o motivo de tirar o sorteio inicial do caminho — mas define o mundo em que ele nasce: quais clubes de várzea existem e qual deles te chama. Escrever os três campos num papel é o suficiente para voltar ao mesmo mundo. |
| 22 | **O apelido tem que ser sobre a pessoa.** No amador brasileiro o apelido *é* o nome — ninguém no campo sabe o sobrenome do cara — então um apelido sorteado de um saco genérico se denuncia na hora. São quatro fontes e três delas são coerentes com o actor: morfologia sobre o **nome** (Pedro → Pedrinho, Lucas → Luquinho), sobre o **sobrenome** (Vasconcelos → Vasco), sobre o que ele é **notável** por (9 de agilidade → Foguete, 2 de vontade → Chorão) e, por último, o saco aberto. Atributo conta para os dois lados; **habilidade só conta para cima**, porque um amador tem uma dúzia de habilidades zeradas por nunca ter treinado, não por ser ruim nelas. |
| 23 | **Um perk, opcional, e o defeito paga.** No máximo **1** por actor, e não pegar nenhum é uma resposta legítima — tudo vai para a ficha. Qualidade custa career points; **defeito devolve**. Sem isso ninguém escolheria "mãos de pedra", e é justamente o defeito pago que faz o teto de 1 ser uma regra necessária em vez de arbitrária. O `effect` de cada perk fica **declarado** no catálogo e é consumido por quem é dono da regra — `D.1` lê `roll_bonus`, o treino (`C.2`) lê `training_penalty`, a temporada lê `injury_risk`. |
| 24 | **Elenco é curadoria mais geração, e a curadoria é esparsa.** Atleta real entra como Thing de módulo (`ActorDef`); o que o curador não escrever, o gerador preenche a partir da reputação do clube. Ficha cheia são 23 números, e doze pessoas em dezesseis clubes são 4.400 campos que ninguém preenche direito — seis linhas têm que virar uma pessoa completa. O preenchimento é semeado pelo **id do atleta**, não pela semente da carreira: o mesmo atleta sai igual em toda partida, e só os gerados ao redor dele mudam. Fonte que chega depois **mescla** por id em vez de substituir, então um mod que só quer dizer "esse cara tem 100 de força" escreve só isso. A organização de pastas é **convenção**: a engine varre tudo e mescla (d5star v0.5.0). |
| 25 | **Nome de atleta real vem de fonte, nota não.** Nome e elenco de lista oficial (CBFA/IFAF, site do clube) é referência e pode entrar. As 23 notas não têm fonte pública — atribuí-las a uma pessoa real seria uma avaliação inventada publicada num jogo. A saída é a decisão 24: o atleta real entra só com nome, clube e modalidade, e os números saem explicitamente do gerador. Onde a curadoria tiver julgamento real, ela fixa o número — decisão editorial de quem cura. |
| 26 | **A semana é um `d5*−2` de career points, e essa é a régua de balanceamento.** Cada actor rola por semana: miolo de −1 a +2 em 71% das semanas, e caudas raras de 9% pra cada lado — a semana perdida e a semana de virada. Média crua 0,5/semana (26 cp/ano); vontade, clube e juventude somam ao dado. A âncora é **16-18 anos + 3-5 anos de boa dedicação = seleção brasileira** (passo 8), o que dá ~1 cp/semana pro comprometido. Comparação: a infância custa 23 cp/ano, então um ano de atleta dedicado vale ~2× um ano de criança crescendo. |
| 27 | **Potencial por actor, sorteado no nascimento.** Teto mole em passos: 6 é comum, 7-8 incomum, 9-10 raro. Ganho acima do teto é amortecido, não zerado — trabalho conta, só rende pouco. Sem isso "jogar em clube bom" vira sinônimo de virar lenda, e clube não devia fabricar talento. |
| 28 | **A carreira é o dado, curada ou simulada.** Um actor é ficha de nascimento + lista de anos. Cada ano diz `position` (o que treinou) e, opcionalmente, `gains` (quando o curador sabe). Ano sem `gains` é simulado. Um actor inventado é literalmente isso com a lista inventada — não existem dois caminhos de código. De quebra, `team` por ano vira histórico real: "jogou em 5 times" deixa de ser anedota. |
| 29 | **Leader Action Points, à la Old World — 1 a 6 POR MOEDA por semana, com estoque de duas.** Três moedas, de Aristóteles: **Logos** convence pelo intelecto, **Ethos** pela autoridade (vontade + carreira + títulos), **Pathos** pelo carisma. Era "1-3 ações por semana" no total; virou renda por moeda, que é mais rico pelo mesmo preço e é o que faz a ficha do manager importar depois da tela de criação. ⚠️ A renda é `1 + passo/2` e **uma medição escolheu o 2**: em `/3` os três cenários davam 1·1·1, porque todos abrem por volta do passo 2 e o passo 2 é o começo inteiro do jogo — dial que não se mexe na única faixa que o player vai ver não é dial. E **Logos e Pathos pendem pra HABILIDADE e não pro atributo**, pelo mesmo motivo: o atributo é a capacidade que todo mundo tem um pouco, a habilidade é o que aquela pessoa fez, e três cenários que diferem por habilidade têm que ser separados por habilidade. O estoque de duas semanas é o que transforma a renda em plano em vez de mesada. |
| 30 | **Cinco pools por actor, e um pool é um PAR — `agora` e `máximo`.** É isso que faz uma barra ser barra, e é por isso que o formato vem antes de qualquer coisa gastar: tela que mostra um número só precisa ser reescrita no dia em que algo drena, e tela que mostra fração nunca precisa. **Health** é o corpo — aguenta a pancada, e no fundo você se lesiona e vai pro banco, então é escudo contra evento e não número que desce sozinho; **Stamina** é quantas jogadas seguidas antes de sair; **Sanity** é força mental, quebra sob pressão; **Emotional** é força emocional — chamar o companheiro, entrar na cabeça do adversário, puxar a torcida; e **Loyalty** é o quanto ele está comprometido com ESTE clube, e no fundo da barra ele pode ir embora. Eram "quatro pools gastos e um estado" — são cinco barras, e o que muda entre elas é quem drena e o que acontece quando esvazia. Os quatro primeiros têm teto de atributo porque o que teu corpo e tua cabeça aguentam é quem você é; **o da Loyalty não**, porque nada num jogador diz o quanto ele pode se importar com um clube em que ainda não entrou. E todos têm **piso 4** (decisão 43: o passo 0 é o percentil 20 das pessoas, não o fundo delas — o fraco não é feito de papel). |
| 31 | **Afinidade é polaridade, não peso.** Cada posição carrega um vetor de +1 / 0 / −1 sobre atributos **e** habilidades, e o fit é o produto interno com os números do actor. O QB quer destreza, inteligência e regra; ele **não** quer provocação, então essa entrada é −1 e um boca-suja pontua pior na posição por mais que arremesse bem. Peso diria "arremesso vale 3× regra", que é uma afirmação sobre **treino** e mora em `trains`. Polaridade responde outra pergunta — essa pessoa serve pra essa vaga — e responder com sinal em vez de magnitude é o que deixa o vetor fácil de escrever: sim / não / errado, quinze vezes, e acabou. Um vetor serve as duas eras da carreira: no nascimento as habilidades são zero e só os atributos falam; no ano dez as habilidades dominam. `B.6` pergunta pra mesma função. |
| 32 | **O dia é a unidade e xp é a moeda.** `xp/dia = dedicação + D5.successes()`, `10 xp = 1 cp`, semana de 5 dias. E são **duas correntes**: quem fez o trabalho ganha 1 cp de atributo **e** 1 cp de habilidade — academia e campo são sessões diferentes, e um bolso só dividido entre as duas deixava metade da ficha parada. 1 cp/semana = semana boa (academia quase todo dia, treino a 75%); 2 = excelente; 3 = treinou todo dia e ainda teve o dia da epifania. `D5.successes()` é a leitura de **contagem** do mesmo dado (à la White Wolf): 5 é um sucesso, 0 é uma falha, 1-4 é nada, e as duas pontas explodem. Medido: 70,6% de nada, 12,2% pra cada ±1, caudas raras. |
| 33 | **A régua é absoluta, então ela precisa de quantis — e de uma escala internacional.** 10 é o melhor que existe **na Terra**, então "bom pra várzea" e "bom" são frases diferentes. Cinco bandas com razão de chance **4:1** (80/20) entre vizinhas: **Q1** nível cidade (30-55) · **Q2** estadual (55-68) · **Q3** nacional (68-80, *a seleção brasileira é isto*) · **Q4** mundial menor (80-90) · **Q5** mundial maior (90-100). O nível de um clube é `país + divisão` (`nation.json`), então um clube **de cidade** no México bate um clube **estadual** no Brasil — e o Brasil inteiro tem 0 a 2 Q5, que é o que a realidade diz. Isto nasceu de um furo visível: um garoto de 26 anos do Piedade Pelicanos com Treinamento 8, nível internacional em treino num clube de bairro. |
| 34 | **Potencial é TETO, não pedágio.** Cobrar 4× acima dele não era parede nenhuma: uma carreira de 15 anos a ~50 cp/ano atravessava e saía 19 pontos além. Agora o teto é duro, com uma folga de 2 pontos caríssima pra quem trabalhou mais do que qualquer um esperava. Sem isso as bandas não descrevem nada — se dá pra treinar além da sua banda, a banda é enfeite. |
| 35 | **Marcar dois no mesmo lugar não é erro, é o método.** A competição pede **7 inscritos** e o usual é **12**, sem máximo. Cada posição declara `slots` (QB 1 · C 1 · WR 3 · R 1 · CB 2 · S 2 · e um por cargo), e quem for marcado além disso é **reserva ali**, listado embaixo com a posição que cobriria. Dois QBs é como o técnico descobre qual é o melhor — e na maioria das semanas o evento **é o coletivo**, onde os dois pegam snap. Aviso de "excedeu" seria o jogo discordando do próprio loop. |
| 36 | **Cada atributo mora num ponto do corpo, e a cor é a ligação.** Os oito são declarados **da cabeça ao pé** — Inteligência (coroa) · Percepção (terceiro olho) · Carisma (garganta) · Vontade (coração) · Vitalidade (plexo solar) · Destreza (**mãos**) · Agilidade (sacral) · Força (raiz) — então toda tela que percorre `base_ids()` lê de cima pra baixo como uma pessoa em pé. Uma liberdade assumida: a tradição tem sete rodas e a ficha tem oito atributos, então **Destreza** ganha um ponto próprio nas mãos. Um corpo tem mãos; a tradição só nunca precisou rolar recepção. **A habilidade herda a cor do atributo que a rege**, então "Lançamento" e "Destreza" são o mesmo âmbar e a ligação entre aptidão e prática é visível em vez de decorada. |
| 37 | **A tela veste o clube.** Fundo e letra saem das duas cores do clube, como no Elifoot — assim, com dois managers dividindo tela, de quem é a vez é um olhar e não um rótulo. `TeamColors` já garante o contraste WCAG do par, e painel, régua e texto apagado são derivados dele, então a paleta não tem como escapar da identidade do clube. Ver um adversário te põe **nas cores dele** — o "fora de casa" mais barato que existe. |
| 38 | **O clube monta o elenco de propósito, e tem fundadores.** Deixar cada actor escolher a própria posição entre as onze punha cinco delas na comissão, então um elenco saía com cinco preparadores físicos, dois olheiros e um center — um clube que não escala cinco não é um clube. Agora `Rosters` planeja antes: comissão por tier (1 no tier 4, 4 no tier 1), depois as posições de jogo cicladas pelos `slots` até cobrir a formação. De 1 a 5 são **fundadores** — alguém teve que botar cinco numa quadra antes de existir clube, e esses são os mais velhos da sala. |
| 39 | **A comparação é interna: a barra de afinidade é normalizada pela coluna.** Você nunca escolhe um QB contra o mundo, escolhe contra as outras onze pessoas da sala — então a caixa mais cheia da coluna é a melhor opção do clube ali e o resto lê como fração dela. O número absoluto fica no tooltip. |
| 40 | **Você escolhe de onde veio, e isso é a dificuldade.** A tela entregava um moleque zerado e o largava num clube cheio de gente com dez anos de carreira, sem resposta pra pergunta óbvia: por que o mais novo da sala é o gestor? Três cenários, à la Zomboid — **Fundador** (não existia clube, elenco quase todo novato, o mais difícil e o único em que o clube é seu), **Ex-jogador** (ficha de atleta, carrega o time em campo no início a troco de fadiga e de piorar como técnico) e **Estudado** (nunca teve o físico, estudou o jogo; acontece de um clube pronto preferir isso a promover alguém de dentro). A origem gasta parte dos career points na direção dela, diz que TIPO de clube te espera e condiciona o elenco que existia antes de você. |
| 41 | **A ficha abre num ADULTO PRONTO, habilidades incluídas e todo cp gasto.** Preencher quinze barras do zero é tarefa, não escolha — e piorou com as origens, porque um ex-jogador sem habilidade não é um ex-jogador. Você recebe uma pessoa pronta e **editar ela é o jogo** — vender um passo pra comprar outro, e vender dois pra bancar um talento mais caro. Parar aos 12 com 130 pontos no bolso era o que produzia o gênio de 12 anos: o cabeçalho dizia "12 anos" enquanto você bombava Liderança pra 8. **E o manager usa a MESMA régua do elenco**: potencial sorteado do nível que o cenário te dá, piso em 45 pra os 18 anos caberem debaixo do teto, e o teto vale também pro que o jogador compra na mão — senão o super-herói estava a um clique. |
| 42 | **Todo clube tem administração, até o menor.** Presidente, tesoureiro e comunicação são três cadeiras que existem mesmo na várzea — alguém responde, alguém paga o rateio e alguém fala com patrocinador. São posições de `side: admin`, então usam a mesma afinidade, o mesmo botão e a mesma tela. A tela do elenco passa a ler na ordem em que um clube é montado: **Administração · Comissão · Escalação**. |
| 43 | **O zero da régua é o percentil 20 das pessoas, não o fundo delas.** Abaixo dele ninguém entra em quadra — criança e adulto que nunca praticou. Então a régua mede desenvolvimento atlético ACIMA desse piso, e **a âncora passa a SER o quantil**: 0 adulto comum · **2 várzea (Q1)** · **4 estadual (Q2)** · **6 seleção brasileira (Q3)** · **8 encara México e EUA (Q4)** · **10 estrela da IFAF (Q5)**. Eram dois sistemas empilhados que discordavam sobre o que um número significa; virou um. Um actor com tudo 0 é a criança de 12 anos. A decisão 20 sobrevive intacta e fica mais forte: com 5 = seleção, um gestor de várzea lidera em −2 e **atrapalha de verdade** — que é o America Red Lions perdendo um Carioca Bowl porque o banco esqueceu de parar o relógio, com os melhores atletas em campo. |
| 44 | **O manager é VIVIDO, e o orçamento é o que ele custou.** Ele era o único da tela com gerador próprio, e dois geradores divergem — foi assim que saiu heroico ao lado do elenco que gerencia. Agora sai do `ActorLife` como todo mundo: ficha de nascimento, a posição que o cenário dá, os anos que o cenário dá. E some o orçamento fixo: **414 estava calibrado pra régua velha** e uma pessoa de nível cidade não absorve nada perto disso. Você recebe uma pessoa e os pontos que pode mover são **os dele**. A idade deixa de subir conforme você gasta — ela é a idade que a vida produziu. |
| 45 | **Talento tem moeda própria, e você pega quantos quiser.** Career point é **treino** — semana de academia, temporada em quadra. Talento não é coisa que se treina: é o que a carreira **fez com você**, então sai de **perk points**, ganhos nos grandes momentos e não acumulados por semana. Os dois no mesmo bolso faziam Craque custar o mesmo que duas temporadas de trabalho, que são coisas de naturezas diferentes. E isso libera a lógica Zomboid: **defeito PAGA talento**, e o cara pode ser Mãos de pedra E Capitão E Vidraça ao mesmo tempo. O teto de 1 existia só porque defeito reembolsava career point e a build ótima era a lista inteira de defeitos — com régua separada, o saldo faz esse trabalho sozinho. Saldo inicial: **1** pro fundador e pro estudado, **2** pro ex-jogador. Os talentos ficam por **último** na ficha: você termina a pessoa e depois diz o que aconteceu com ela. |
| 46 | **Ninguém é inventado por um clube. Todo mundo nasce na Praça e é DRAFTADO.** O elenco era montado dentro do clube que precisava dele: cada time inventava exatamente as pessoas que lhe faltavam, na primeira leitura, isolado. Saíam elencos individualmente plausíveis e coletivamente impossíveis — ninguém disputava ninguém, todo clube recebia a formação ideal, e não existia a categoria "pessoa sem clube". Agora o mundo inteiro é **um laço só**: `ActorGenerator.spawn` põe gente na Praça, `draft(actor, teams)` decide quem leva, e isso roda até todo clube estar cheio — e continua um pouco depois, pra a Praça sobrar mercado. Três coisas saem de graça: a **estratificação** (ninguém atribui qualidade a clube; o draft casa nível com nível e a tabela de tier cai sozinha), o **mercado** (tem gente na praça na semana 1) e o **player** (você é um spawn como outro qualquer, e o cenário é uma regra de como você é draftado — é por isso que o clube que te pega é crível). ⚠️ `draft`, não `match`: `match` é palavra reservada do GDScript. |
| 47 | **O cenário é uma TRAJETÓRIA, não um cargo.** A origem nomeava a posição exata da carreira — o ex-jogador era `receiver`, ponto — e os três sintomas vinham todos dessa linha: todo ex-jogador saía QB, o fundador só tinha skill de gestão, e o estudado tinha as mesmas duas skills toda rolagem. O que varia de verdade entre as três vidas é de que **lado da linha** ela aconteceu: `track: player` ou `track: staff`. Onde exatamente na quadra é pergunta pro corpo, e o matcher responde. **Ninguém nasce preparador físico** — cadeira de comissão é transição de fim de carreira, então o spawn nunca oferece uma. |
| 48 | **O Fundador é o único start que assina o próprio clube.** Nome, bairro, cidade e cores. Os outros dois entram num clube que já existia e não têm voto — é isso que faz escolher cenário ser escolher **quanto do mundo é seu**. Os campos abrem PREENCHIDOS pela semente: caixa em branco é parede, caixa sorteada é sugestão que você aceita num clique ou escreve por cima. E o fundador **não é draftado** — não há onde ser draftado, essa é a premissa. |
| 49 | **A oferta de jogador de flag são PENEIRAS, não um pool mundial.** Duas portas, e nenhuma delas é um mercado que os clubes compram: (1) jogador de futebol americano que também joga flag — ele já existe, acha o esporte sozinho e ninguém o recrutou; (2) gente que o clube foi lá e CHAMOU, uma peneira, que é o jeito ordinário de um time amador brasileiro tapar um buraco. A peneira gera **2d5* + alcance** candidatos no **nível do próprio clube** — então o Bangu Castores, não federado, 4ª divisão, peneira um pool Q1, e o Flag Kings peneira outro. Quem não passa vai pra praça normalmente, e é assim que alguém bom fica disponível pro time pior. |
| 50 | **A rodada é: peneiras → indies → draft da praça, sempre do melhor clube pro pior.** Os melhores são preenchidos primeiro e quem sobra fica com os piores, que é como funciona e é também por que a tabela de tier não precisa que ninguém a declare. E o `pick(clube, pool)` aponta pro lado contrário do `draft(actor, times)` de propósito: **clube que faz compras sempre tem o que fazer**, enquanto pessoa oferecida de clube em clube pode ser recusada por todos e voltar na rodada seguinte pra ser recusada de novo. Era esse o "ninguém quis" — o gerador rolava recebedor num campeonato que precisava de center e ia recusando, esperando o dado. **A oferta agora é criada PELO clube PARA o buraco dele.** |
| 51 | **A peneira orienta o CORPO, nunca a posição.** Um clube chamando center rola alguns corpos e guarda o que puxa pra lá; o matcher continua fazendo o que sempre fez, então a decisão 47 sobrevive inteira — ninguém recebe cargo, e uma peneira de center pode perfeitamente revelar um safety. Ele só apareceu porque viu o cartaz. E a peneira **te testa na posição que anunciou** (um empurrão do tamanho do ruído, não uma designação): sem isso a orientação vazava — o clube pedia recebedor, o corpo era escolhido pra recebedor, e o matcher lia o mesmo corpo e dizia "quarterback", porque as duas posições querem coisas parecidas e QB é o vetor mais fácil de pontuar. Todo clube da liga encostava no teto de excedente de QB ainda faltando recebedor. |
| 52 | **Comissão é orçamento SEPARADO do elenco, e uma pessoa por cadeira.** Você não carrega head coach reserva, e um técnico não pode ocupar a vaga de um recebedor — contar junto é o que já produziu um clube com cinco preparadores físicos e um center. E o clube também faz peneira de comissão, pelo mesmo motivo de sempre: a cadeira está vazia e alguém tem que chamar a jogada. **Quem é contratado como técnico já senta na cadeira** (atleta não: escolher os cinco titulares é trabalho seu), e não usa camisa. |
| 53 | **A fonte é o clima.** Um simulador 100% painel não tem sprite pra carregar atmosfera, então a fonte carrega. Duas, as duas de terminal de propósito — **o Elifoot era um jogo de DOS**: **VT323** (matriz do DEC VT320) no display, e **Pixel Code** (pixel monoespaçada) no corpo. Monoespaçada não é gosto: metade do jogo é coluna de número, e monoespaçada alinha de graça. Filtro de textura do projeto em **Nearest**, e antialiasing / hinting / subpixel desligados no import — fonte pixel com antialiasing vira mingau. Os tamanhos são uma **escada**, não uma faixa: fonte pixel só fica nítida em passo inteiro da grade em que foi desenhada. |
| 54 | **Toda tela cabe em 1920x1080, e não cabe usando um terço.** O formulário de criação nasceu com 1743px numa tela de 1080, dentro de uma coluna de 940, com dois terços do monitor vazios do lado — e isso não parece errado em screenshot nem em teste que passa, parece "a tela é meio comprida". Virou o quarto harness (`tests/fit_check.tscn`), porque o runner não consegue ver: o tamanho real só assenta depois de um **passo de layout**, e rótulo com autowrap medido no mesmo quadro reporta a altura que precisaria na largura mínima — 7562px contra 1051px um quadro depois. Cada tela marca com `set_meta("fit_root", true)` o nó que tem que caber, porque não existe resposta genérica: ScrollContainer reporta mínimo minúsculo **por design** e esconderia exatamente o que se procura. |
| 55 | **Pixel perfect são duas coisas, e nenhuma é escolhida a gosto.** (a) **O corpo cai na grade da fonte.** O mdc das caixas de todos os glifos *é* o tamanho de um pixel de design; num corpo em que isso não dá pixel inteiro de tela, a haste alterna entre 1 e 2 px — o borrão. Medido: Pixel Code tem 112 unidades por pixel num em de 1008, então os corpos nítidos são **9 · 18 · 27 · 36**, e a primeira escada usava 12/14/16 (o 16 punha um pixel de design em 1,78). Daí **o corpo tem um tamanho só**: não há degrau entre 9 (ilegível a 1x) e 18, e inventar um é reinventar o borrão — hierarquia sai da **cor**. A VT323 não é fonte de pixel (mdc 4 num em de 1000), é outline imitando CRT; o que ela tem é métrica que só fecha em **múltiplo de 5**. (b) **A escala da janela é inteira.** `scale_mode="integer"`: o padrão `fractional` escala o canvas por 1,333x num 1440p e rasteriza tudo em fração de pixel. Custo assumido: 1080p → 1x, 2160p → 2x, **1440p → 1x com borda**, porque 2x não cabe e não existe terceira opção sem um viewport base que não segura a tela. |
| 56 | **O quadro não se mexe quando o cenário muda.** O Fundador carrega um bloco de clube que os outros dois não têm, então o painel crescia e encolhia conforme você clicava — e isso é pior justo quando você está comparando os três. Painel pinado nos dois eixos (como **mínimo**, então conteúdo que estoura ainda é visto pelo fit_check), e toda largura de dentro capada: o nome do clube é digitado pelo player, e um nome longo bastava pra mover o painel dois pixels. |
| 57 | **O canvas de projeto é 1280x720, e isso é decisão de design.** Escolhido pra que todo monitor comum pegue um degrau inteiro em vez de ficar preso em 1x: 1080p 1x, 1440p 2x, 4K 3x — o tamanho aparente passa a acompanhar o monitor, que é a única forma de um jogo de pixel ler igual nos três. O preço é o espaço: 1280x720 é o que **toda** tela tem que caber dentro, e o formulário de criação queria 1850x1040. Pago em **abas** (FICHA · HABILIDADES · TALENTOS) e em disciplina — dica de uma linha com o resto no tooltip, rótulo de campo virando placeholder, e os dezoito códigos de posição da tabela do elenco rodando no degrau menor (`Look.MICRO`, 9px) porque são duas ou três letras num botão, não prosa. E a escala é calculada em `Look.fit_window()`, não no project.godot: `scale_mode="integer"` arredonda pra baixo e põe tarja na sobra, e `aspect="expand"` não devolve essa sobra — daí o quadrado no meio da tela num 1440p. |
| 58 | **Ícone de talento é identidade, não enfeite.** É a coluna Talento inteira do elenco — uma caixa de 26px com um glifo dentro — então dois talentos com o mesmo glifo fazem a coluna mentir, e qualquer coisa que procure um talento pelo ícone acha o errado. Aconteceu: dois dos treze talentos adicionados de uma vez reusaram glifos já no catálogo, e o teste de tela que devolve um talento começou a devolver o de outro. Invariante virou teste. |
| 59 | **`content_scale_size` e `content_scale_factor` se multiplicam.** O `size` é o canvas lógico e a engine já o estica até a janela; o `factor` é um multiplicador **em cima** disso. Setar os dois pôs o jogo em 4x num monitor que devia dar 2x — viewport lógico em 640x360 e tela vazando pela borda. Só o `size` é setado; a escala sai de `canvas = janela / escala`, e o esticão da engine é esse inteiro nos dois eixos por construção. E o readout não pode ler a escala do `factor`: leria "2x" com a imagem em 4x. Aritmética virou função pura com suíte (`tests/test_look.gd`) porque dois bugs seguidos aqui foram descritos por screenshot e nenhum teste os viu. |
| 60 | **A janela É o canvas: um para um, sem escala nenhuma.** Escalar por inteiro a partir de um canvas pequeno é genuinamente pixel-perfect e é **outra estética** — grossa, próxima, SNES — e ainda por cima apertada, porque 2x num 1440p deixa só 1280x720 de espaço e essa tela é quase toda tabela. **Pixel art de alta resolução** é a outra: glifo pequeno de aresta dura com espaço em volta, e ela vem da **fonte** e do filtro Nearest, não de ampliar. `Look.DESIGN_MIN` vira 2560x1440 e passa a ser **alvo** e não divisor — a resolução pra qual as telas são desenhadas. Resolução menor é problema pro dia em que alguém tiver uma. |
| 61 | **Todo atributo e habilidade tem um código de três letras, e é ele que aparece.** "Chamada de jogada" tem dezessete caracteres ao lado de uma barra de dez casas, e vinte e três linhas assim leem como classificado de jornal em vez de ficha. Três letras em coluna fixa leem como **tabela**, que é o que é. Por idioma, porque a mnemônica é o ponto: VIT é Vitalidade, STA é Stamina. Únicos dentro de cada idioma, com teste. |
| 62 | **Texto explicativo não fica na tela: fica no tooltip.** Cada seção carregava duas linhas de prosa dizendo pra que ela servia, e seis dessas viram a tela numa página de letra miúda que você lê uma vez e depois precisa aprender a ignorar. A explicação não foi deletada — mudou pra onde explicação pertence, que é **a um hover de distância e permanentemente disponível** em vez de permanentemente no caminho. E o critério inverte: o que estava na tela tinha que justificar o espaço explicando a si mesmo; o que está no hover só precisa responder a pergunta com que você passou o mouse ali. |
| 63 | **A cromia sai do fundo e vai pra onde tem significado.** O verde do Elifoot é uma bela referência e também uma tela inteira de cor saturada carregando informação nenhuma — fundo que você olha por uma hora é fundo que você para de ver e passa a cansar, e que compete com toda coisa colorida desenhada por cima. Então a moldura fica **azul-marinho muito escuro e branco** até a tela do time, e a cor fica reservada pra: **verde/vermelho** (talento ou defeito — a comparação que o player mais faz), **âmbar** (atenção), **os chakras** (um tom por atributo, herdado pelas habilidades) e **as cores do clube**, que a partir da tela do time modulam tudo. Contra uma aproximação neutra, a chegada no clube lê como chegada em vez de como mais um verde. |
| 64 | **Emoji não é ícone: é um bitmap colorido da fonte de outra pessoa.** Ignora a face, ignora a paleta, e aterrissa numa tela de pixel com cara de adesivo. Todo glifo vira **ASCII** — `[*]` pro dado, `[-]` pro cadeado, prefixos de uma letra no log do draft — e os talentos ganham **código de três letras** como o resto da ficha. E isso virou teste: **todo caractere de todo JSON de conteúdo tem que existir na fonte do jogo**, com o instrumento provado antes (o `has_char` precisa RECUSAR um emoji). Quatro símbolos do log (⌂ ⚐ ⚑ ⚠) não existiam em nenhuma das duas fontes e estavam sendo desenhados por fallback — num log monoespaçado, glifo de outra largura quebra a coluna que faz o log ser legível. |
| 65 | **A presidência é sua e não se troca.** O player é o **PRESIDENTE**, em qualquer cenário — era `head_coach` em dois dos três, e isso silenciosamente te punha como membro da tua própria comissão técnica, disputando cadeira num clube que você deveria mandar. Presidente é a pessoa a quem o clube responde, que é o que ser o player significa. Todo outro cargo é **trabalho que se distribui**, inclusive de volta pra si mesmo, e a tabela do elenco é onde isso acontece — só o botão de presidente é travado. |
| 66 | **O corpo é identidade.** Altura e peso são o mesmo tipo de fato que o nome — como você é no papel — e estavam embaixo dos atributos só porque é lá que mora o passo que eles deslocam. Duas caixas cabem exatamente onde três campos de nome já estavam, e com isso os **talentos ganham a largura inteira debaixo dos atributos e das habilidades**: talento é uma frase, e frase precisa de linha. E o **clube vai por último** na coluna, porque só existe pro Fundador — bloco que aparece e some no MEIO de uma coluna empurra tudo abaixo dele a cada troca de cenário; no fim ele cresce pra baixo, em espaço que já estava vazio. |
| 67 | **A tabela do elenco é UM GridContainer, cabeçalho incluído.** Cabeçalho e linhas eram HBoxContainers separados que concordavam sobre larguras por serem escritos a partir das mesmas constantes — e sobre mais nada: o cabeçalho separava por `COL_GAP` e as linhas por `8`, então cada coluna derivava dois pixels e na vigésima quarta o cabeçalho estava 48px fora das caixas que ele nomeia. Já tinha sido "consertado" uma vez, clipando um título que crescia além do mínimo; a largura nunca foi o problema, o **arranjo** era. Num grid a coluna é dimensionada pela célula mais larga *daquela coluna*, cabeçalho e linhas juntos, porque são o mesmo container — alinhamento deixa de ser coisa pra acertar e passa a ser coisa que não tem como dar errado. Custa a linha-como-botão: grid tem célula, não linha. Então seleção e zebra são pintadas por célula, e **a célula do nome é a que se clica**, que é o idioma de tabela em todo lugar. |
| 68 | **A célula mostra o VALOR, não o nome da própria coluna.** Toda célula da coluna de presidente lia "PRE", doze vezes, embaixo de um cabeçalho que já dizia PRE — 216 repetições de dezoito palavras que a coluna já tinha nomeado. Não era informação, era textura, e deixava a tabela ilegível por ser barulhenta sobre nada. O que uma célula de (pessoa, posição) sabe é **quanto essa pessoa serve pra essa vaga**, e isso só existia como a largura do preenchimento atrás. Agora é número também: o preenchimento é **relativo** (como ele se compara ao resto do elenco naquela posição) e o número é **absoluto** — perguntas diferentes em vez de repetição. E o número é tingido pelo próprio valor, então coluna de afinidade baixa some e o olho cai em quem realmente serve. |
| 69 | **A cor do clube é a que tem MATIZ, e a rampa corre sobre a faixa que os dados usam.** Duas causas separadas, e nenhuma era a óbvia. (a) O accent era "a mais clara das duas" (`ink` se for brilhante, senão a `plate` clareada) — pergunta errada: clube de vinho e branco tem tinta branca, então o accent saía **branco** e o vinho que é a identidade inteira do lugar não aparecia em lugar nenhum além do escudo. A pergunta certa é qual das duas carrega o matiz, e **saturação** responde; clube que de fato não tem matiz (preto e branco) continua branco, porque não há outra coisa pra ele ser. (b) `StatBar.tint` interpola de cinza até a cor num intervalo 0..100, mas **Geral nesse tier vive entre 14 e 30** — 14 a 30% do caminho, ou seja, cinza. A cor do clube estava lá o tempo todo e nenhum valor chegava longe o bastante na rampa pra mostrá-la. Normaliza-se contra a faixa do próprio elenco (Geral) e contra o teto da coluna (afinidade). |
| 70 | **A escolha do player não é sugestão: alto contraste literal.** `colors[0]` é o **fundo** e `colors[1]` é a **letra**, e nenhuma das duas é trocada nem substituída. O código fazia as duas coisas — lia ao contrário (primária = tinta) e ainda **trocava** o par quando falhava o teste de contraste — então quem escolhia amarelo de fundo e verde de letra recebia uma tela mostarda sem verde nenhum: o amarelo virava letra, era trocado, e o verde era substituído inteiro. Agora o fundo é o fundo; se a letra não lê, só o **brilho** dela se mexe. Da tela do time em diante a paleta é exatamente: fundo escolhido, letra escolhida, e misturas com preto e branco pra profundidade — nenhum terceiro matiz é inventado. |
| 71 | **Antes do clube, cinza — nem verde nem azul-marinho.** O azul ainda tem temperatura: lê como frio, como noite, como *alguma coisa*, e toda coisa colorida desenhada em cima tem que discutir com essa leitura antes de dizer o que veio dizer. Moldura que não diz nada é o que faz a chegada no clube ler como chegada. |
| 72 | **Contratar alguém não é dar a cadeira a ele.** A comissão era sentada no instante em que era assinada, e como `head_coach` é a primeira cadeira que uma peneira anuncia, **todo clube da liga abria com um head coach já em posto** — decisão tomada pelo manager, em silêncio, antes de ele ter visto o elenco. Atleta chega sem marcação porque escalar os cinco é trabalho dele; comissão técnica é o mesmo trabalho. As pessoas estão lá, no elenco, com as afinidades de comissão pra provar; qual delas senta onde é escolha sua. A presidência é a única exceção, e não é exceção à regra — é outra regra: você não se nomeia, você já é. |
| 73 | **Travado não é desabilitado.** `disabled` acinzenta o controle, e cinza quer dizer *indisponível* — o oposto do que a célula do presidente diz. A presidência é **ocupada**: a caixa fica preenchida, na letra do clube, igualzinha a toda cadeira que alguém ocupa. Ela só não responde ao mouse, e o tooltip diz por quê. |
| 74 | **A estreia é lognormal a partir dos 16, com 95% dentro aos 21.** Era uniforme 15–21, que é a afirmação de que *não existe* idade típica pra começar: estrear aos 21 era exatamente tão provável quanto aos 15. Uma cena onde a molecada entra aos 16 não é uma faixa plana, é uma pilha no chão com uma cauda — 36% aos 16, 30% aos 17, e o resto escorrendo. Os parâmetros são **derivados, não escolhidos**: com `offset = exp(N(μ,σ))` e a idade tirada pelo piso, `P(estreia ≤ 21) = P(offset < 6) = 0.95` dá `μ = ln(6) − 1.645σ = 0.3113` pra σ = 0.9. σ é a única escolha livre, e é ela que decide a gordura da cauda tardia. E o corte é **rerroll, não clamp**: `clampi` dobra a cauda inteira no último degrau — meio por cento de todo mundo estreava exatamente aos 30, mais do que aos 29, e aquele calombo era feito de gente que rolou 40. |
| 75 | **A ponta de entrada da carreira tem que ser alcançável — e ela lia a régua errada.** A decisão 26 calibra o clube mais fraco do mundo em ~1,6 temporadas por atleta; quem alimentava a mistura era `reputação = nível × 20`, e o nível nunca desce de 1, então a maturidade nunca descia de 0.2 e a várzea recebia centro **3,1**. As duas réguas vão de 0 a 100 e são indistinguíveis num call site — foi por isso que passou. Medido depois do conserto: nível 1.0 → mediana **2** anos, p95 5; nível 5.0 → mediana 9, p95 25. A liga montada saiu de mediana 22 pra **19 na várzea** e 25 no nível 4. E **`AGE_MAX` passou a prender alguma coisa**: era constante que dois testes liam e ninguém aplicava, então estreia tardia + carreira longa somavam sozinhas e os clubes de nível 4 despachavam recebedor de 55 anos. |
| 76 | **Só o ex-jogador tem carreira.** Havia um segundo intervalo de anos, compartilhado — três a seis que todo mundo ganhava por "ter estado por perto" — e ele era estrutural pelo motivo errado: sem ele a ficha saía em nada, três pontos de carreira e uma tela que não dá pra editar. Só que ele também fazia os três cenários serem a mesma pessoa por baixo, e isso é falso pra dois deles. O **fundador é novato** — é a premissa, não existia clube onde ter carreira. O **estudado nunca jogou**. Quem carrega a ficha agora é a alocação do próprio cenário, que é o lugar honesto: o estudado tem o regulamento porque **leu**, não porque passou quatro anos sem nome em algum lugar. Medido: fundador 18–23 anos e budget 33–78, estudado 18–22 e 32–44, ex-jogador 21–28 e 25–275. |
| 77 | **Um clube fundado semana passada não contrata um veterano de dez anos.** O cenário do fundador escreve os números (`squad.max_career_years`, `squad.veterans`) e o clube os carrega, então o draft lê a regra sem saber o que é uma origem. As peneiras do próprio clube já trariam novatos, mas **a praça não** — o mercado é feito da carreira dos outros — então o teto mora em `wants()`, onde as duas portas leem ele. Os poucos "veteranos" são exatamente o que a descrição do cenário sempre prometeu: gente que largou outro time pra apostar neste, e quando essas vagas enchem a porta fecha. |
| 78 | **A página é preta; o clube veste as janelas.** As duas telas punham o fundo do clube na TELA e derivavam painel, poço e régua dele — não existia um quadrado que não fosse o clube, e a ficha que você abre num atleta desenha oito atributos em oito cores de chakra sem ter contra o que contrastar. Um clube amarelo tornava a própria ficha ilegível, e não era bug de ninguém: cada cor individual era exatamente a que o player escolheu. Agora `CANVAS` (quase preto, sempre, pra todo clube) é coisa diferente de `PANEL`. A decisão 70 continua de pé — nenhum matiz novo é inventado — o que mudou é o que "fundo" quer dizer: a janela, não a tela. E o clube aparece MAIS, não menos, porque agora dá pra ver onde ele está: o escudo com o fundo de verdade, a moldura de toda janela, e o preenchimento do que está selecionado. |
| 79 | **`signal`: a cor do clube que sobrevive a uma página preta.** `TeamColors` promete que fundo e letra contrastam **entre si** e não promete nada sobre nenhum dos dois contra o preto. O Vasco é preto no branco e o América é branco no vermelho — então "usa o fundo pra borda" dá borda invisível pra um e "usa a letra" dá pro outro. `signal` é aquele dos dois que lê melhor no canvas, e é ele que pinta borda, título, barra e seleção. É uma escolha entre as duas cores do player, nunca uma terceira. |
| 80 | **Talento é sigla, igual atributo.** Vinte e sete nomes por extenso num chip era a última seção da criação que ainda lia como classificado — e "Quebra de cintura  2 pp" pedia 276px num chip de 252, então o que cortava era também o que definia a largura da coluna. Três letras e um número cabem cinco por linha, com nome e descrição no tooltip: o mesmo movimento do `B.6i` em INT/PER/CAR. Os textos em si ficaram — são voz, não verborragia, e tooltip não cobra comprimento. O que mudou foram dois **códigos**: `FER`/`FRR` diferiam por uma letra e os dois soavam defensivos (um é tackle, outro é durabilidade), então Ferro ficou com `FER` e Ferrolho virou `FLH`; e `SEM` lia como preposição, virou `SCD`. |
| 81 | **O vocabulário de `effect` é fechado e nomeia quem consome.** Todo talento declara `{kind, scope, target, amount}` e nada lê isso ainda — os consumidores estão meses à frente. Um `"kind": "roll_bonuz"` carrega, valida, é lançado, e então não faz nada dentro do motor de partida, quando o bug vai parecer desbalanceamento no `D.1` em vez de erro de digitação num JSON que ninguém abre desde então. A lista fechada mora no teste e cada entrada diz **quem lê** — acrescentar um `kind` passa a ser o momento de responder "e quem age nisso?", que é a pergunta que um campo de texto livre nunca faz. |
| 82 | **A várzea começa aos 14, e a janela do manager é uma truncagem da mesma curva.** Catorze é quando a galera pega o esporte nessa cena, e quem chega no topo da escada quase certamente começou lá e não aos vinte (doze seria mais verdade ainda e precisaria de um juvenil pra ser honesto). O manager precisa de uma faixa mais estreita que a de um moleque qualquer da praça, e o caminho barato é um segundo par de constantes — que é como se acaba com duas formas que discordam e ninguém capaz de dizer qual é a real. Pergunta pra mesma curva e fica só com o que cai dentro da janela, **por rejeição e não por clamp**: clamp dobra tudo que fica de fora nas bordas e empilha metade da população no primeiro e no último ano. Medido: fundador 100% entre 16 e 19, estudado 16–18, ex-jogador 19–24, todos saindo da mesma janela mais a própria carreira. |
| 83 | **Sigla de três letras é pra quem você decora; talento leva palavra.** Os códigos estão certos pros oito atributos e as quinze habilidades — você aprende uma vez e lê pelo resto do jogo. Um catálogo de **27** é outro problema: ninguém decora, então `CRQ FOG CER COL` é uma tela que se lê com o mouse, um tooltip por vez. O chip passa a dizer `FOGUETE >`. E `tag` é **apelido, não abreviação**: "Só no ataque" não tem forma curta e TURISTA diz a mesma coisa numa palavra. Apelido de defeito tem que ler como defeito sozinho — ATAQUE e FÔLEGO soariam elogio. O código de três letras fica onde ganhou o lugar: a coluna de 34px do elenco, onde não cabe mais nada. |
| 84 | **Nada dentro de uma célula pode ser mais largo que a célula, e isso é uma MEDIÇÃO e não um comentário.** Todo Control que DECLARA um mínimo faz uma promessa sobre quanto espaço precisa; quando o mínimo combinado dele passa da própria declaração, alguma coisa dentro quebrou a promessa e o container acima cresceu pra cobrir — que é por que isso é invisível de fora e óbvio de dentro. O `fit_check` passou a varrer isso em toda tela, e na primeira execução achou cinco coisas que ninguém tinha visto. O mesmo erro já tinha causado dois bugs no mesmo arquivo: a criação 2x2 saiu **500px mais larga** que a fila indiana que substituiu, e a passada seguinte ficou presa por **uma linha de três chips**. Nos dois casos a tela ainda cabia e os totais ainda passavam. A outra metade da regra é a coluna se medir contra o próprio cabeçalho: a face é monoespaçada em 12px por caractere, "Talento" tem 84px contra uma coluna de 34 — e o mais LARGO daquelas colunas é o cabeçalho e não o dado, então elas pareciam folgadas de toda linha menos a que as nomeia. |
| 85 | **Toda reserva é a MÉDIA dos dois atributos que a sustentam, e chega a 10 só quando os dois chegam.** Corpo que não cansa é corpo máximo nas duas coisas que o fazem. Eram `4 + a + b` indo até 24, que é uma **segunda régua** num jogo cuja calibração inteira é o 0..10 da decisão 43 — e toda tela que mostrasse uma reserva ao lado de um atributo teria que ensinar qual escala era qual. O piso de 4 saiu junto e está certo: o degrau 0 já significa o percentil 20 das pessoas e não o fundo delas, então reserva 0 diz exatamente o que atributo 0 diz. A Lealdade tem teto 6, ou 9 pra quem fundou o clube — ninguém nasce capaz de amar um clube em 10. |
| 86 | **Apelido é sorteio uniforme entre dez categorias, e a décima compõe duas das outras.** Eram quatro fontes com peso, e os pesos mentiam: `stat` declarava 45% e entregava 16%, enquanto a morfologia declarava 45% e entregava **62%**. A causa é a queda em cascata — fonte que não produz nada passa a vez, e `stat` não produz nada pra quem não tem traço notável, o que com o limiar em sete degraus é 63% de um elenco de várzea. A metade saborosa do sistema foi calibrada pra um mundo onde a galera chega no degrau sete, e esse mundo é a seleção. As dez: tamanho · nome · físico · corpo · bicho · traço · origem · ofício · comida · composto. E o sorteio é uma **ordem embaralhada** e não um sorteio único, pra que o uniforme seja entre as categorias que sabem responder. |
| 87 | **Notabilidade é relativa ao próprio sujeito quando nada cruza o limiar absoluto.** O lateral com agilidade 3 e o resto em 1 é o Foguete daquele time — que é exatamente como apelido se ganha, por comparação com quem está em volta e não com a seleção brasileira. Precisa de folga real (dois degraus acima da mediana dele), senão uma ficha plana batiza todo mundo no cara-ou-coroa. |
| 16 | **Dois arquivos de persistência, não um.** O *save* morre com o manager (decisão 11). O *perfil* sobrevive: guarda o que foi desbloqueado entre carreiras — a começar pelo modo **Pick Team**, que só abre depois de vencer uma rodada nacional. |

### Tiers — como o "tier 4" encaixa na realidade

| Tier | Realidade | Como se vive lá |
|---|---|---|
| **4** | Não federado | Estadual e amistoso. Jogador **paga** pra jogar. Campo de várzea. |
| **3** | Série C | Entra no Brasileirão. Primeiro patrocínio local. |
| **2** | Série B | Estrutura real, viagem começa a doer. |
| **1** | Série A | Elite. Patrocínio de verdade, disputa o título nacional. |

Subir não é promoção de tabela — é **classificação no regional**.

### Calendário — semana `S/YYYY`, 52 turnos por ano

O jogo **não é orientado a tempo real, é orientado a turno** — como o Elifoot.
Cada turno é uma semana identificada por `S/YYYY`: `1/2026`, `2/2026`, …
`52/2026`. São **52 turnos por ano**, sempre.

Toda semana tem um evento. O evento padrão é o **coletivo** — o racha interno
do próprio elenco, dividido em dois times. É assistindo ao coletivo que você
descobre quem joga bem em cada posição, sem precisar de tela de scout.

```
1º semestre  (semanas 1–26)    estaduais
2º semestre  (semanas 27–52)   regionais + nacional
```

| Tipo de semana | Evento |
|---|---|
| comum (a maioria) | **coletivo** — assiste, observa o elenco, ajusta |
| semana de etapa | rodada competitiva (estadual, regional ou nacional) |
| futuro | amistoso agendado por você (mecânica adiada) |

Semana de etapa segue a **mesma lógica de "próximo evento"**, só mais densa —
etapa de flag amador é um fim de semana inteiro com vários jogos, o que
entrega naturalmente a tela do Elifoot com um jogo por linha.

**Consequência de projeto:** como toda semana tem um jogo pra assistir, o
motor de partida e a tela de jogo não são "o fim do projeto" — são o coração
do loop semanal — mas não são pré-requisito de existir uma semana, então
vêm na Fase D, depois que o loop já gira (Fase C).

### Financeiro — a tensão é viagem

Sem salário, dinheiro precisa de destino. Ele compra **horas de campo, horas
de técnico, equipamento e viagem**. A decisão que parte o coração:

> Seu time de Boa Vista se classificou pra uma etapa nacional em São Paulo.
> A passagem de 12 atletas custa mais que o caixa do ano inteiro.

Receita por tier: **mensalidade de atleta** (tier baixo) → **patrocínio**
(tier alto).

---

## 3. O loop

### Fluxo de telas

```
START SCREEN
  Continue (cinza até E.3) · Novo Jogo · Ajustes · Sair
        │
        └─ MODULE SELECT
             "Brasileirão de Flag 2026"   ← módulo nativo
             + qualquer coisa em user://modules  ← universos do jogador
             │
             └─ CREATE MANAGER
             nome (sorteado, rerolável) · 18 anos
             Career Type:
               ( ) Pick Team  🔒  "vença uma rodada nacional pra liberar"
               (•) Random         sorteia um clube tier 4  ← Elifoot
                  │
                  └─ TEAM SCREEN  ── abas ──┬── Elenco        (o seu)
                                            ├── Adversários   (os outros clubes)
                                            ├── Comissão Técnica   (D.1)
                                            ├── Local de Treino    (C.2)
                                            └── Financeiro         (C.3)
                       └─ [ Próxima Semana ]  → C.5
```

A barra de abas nasce com **duas** abas em `B.4` e cresce conforme a Fase C
entrega as outras. `club_select` de hoje vira a aba **Adversários**.

A seleção de módulo não é enfeite: é onde o jogador pluga o **próprio
universo**, como as ligas caseiras do Elifoot. A d5star já varre
`user://modules`, então isso funciona sem código novo.


```
Novo Jogo
   └─ sorteio: você é manager de um clube tier 4
        └─ HOME DO CLUBE  ── abas ──┬── Elenco
             │                      ├── Comissão Técnica
             │                      ├── Local de Treino
             │                      └── Financeiro
             └─ [ Próxima Semana ]  → avança S/YYYY
                   ├─ semana comum   → COLETIVO (assiste) → HOME
                   ├─ entre semanas  → mercado ("leilão") → HOME
                   └─ semana de etapa → JOGOS AO VIVO → HOME
```

### Escopo do MVP

- **Rio de Janeiro apenas.** Os 9 clubes cariocas reais + clubes fictícios não
  federados pra completar.
- **Campeonato Carioca misto**: todos os tiers na mesma tabela. É o resultado
  do Carioca que **decide o tier no Brasileirão**.
- **O MVP não chega ao Brasileirão.** Regional e nacional ficam declarados no
  calendário mas fora do escopo.
- **Só masculino.**

---

## 4. Referência rápida

**Ficha do jogador (MVP):** nome · número da camisa · posição · **força** · perk

**Posições** (5×5 oficial): ataque **QB · C · WR**, defesa **R · CB · S**. Linebacker é 7v7 e NÃO entra no 5×5 — a defesa de flag 5×5 é rusher, cornerbacks e safeties. Mais 5 **cargos de comissão** com `side: staff`: **HC · OC · DC · PF · OL**. Cargo e posição são a mesma estrutura de propósito — declaram `code` (o botão), `side`, `affinity` (polaridade, decisão 31) e `trains` (peso, decisão 26) — então a mesma função de fit, o mesmo botão e a mesma tela servem para escalar o time e montar a comissão.

**Padrões táticos**
- *Ataque*: Passe curto · Bomba · Balanceado · Segurar relógio
- *Defesa*: Homem-a-homem · Zona · Blitz · Prevent

**Perks** — catálogo em `game/defs/perk.json`, no máximo **1** por actor e
opcional. O preço é em career points e o defeito **devolve**.

| ASCII | Perk | cp | Efeito declarado |
|---|---|---|---|
| `★` | Craque | 20 | `roll_bonus` +1 em tudo |
| `⚡` | Foguete | 10 | `roll_bonus` +2 em rota |
| `🧠` | Cérebro | 10 | `roll_bonus` +2 em cobertura |
| `✋` | Mãos de cola | 10 | `roll_bonus` +2 em recepção |
| `🎯` | Ferrolho | 10 | `roll_bonus` +2 em tackle |
| `📣` | Capitão | 12 | `team_bonus` +1 de moral |
| `💸` | Padrinho | 8 | `finance_bonus` em patrocínio |
| `🪨` | Mãos de pedra | **−10** | `roll_bonus` −2 em recepção |
| `👻` | Sumido | **−12** | `training_penalty` na presença |
| `🩹` | Vidraça | **−12** | `injury_risk` +2 |

O `effect` é um **contrato**, não uma regra: quem o executa é o sistema dono
dela — `D.1` lê `roll_bonus`, o treino lê `training_penalty`, a temporada lê
`injury_risk`. Enquanto esses sistemas não existirem, o perk custa, aparece na
ficha e não faz nada — do mesmo jeito que `min_women` esperou a partida.

---

## 5. Alavancas que já existem

- **Card/Deck/Hand da d5star** — pronto e testado no ScrapWarriors, com
  raridade, afinidade e Hand como Slate. Jogadas e táticas são literalmente
  cartas: o técnico tem um baralho, na partida você recebe uma mão de opções.
- **Flow declarativo** — navegação entre telas é JSON, não código.
- **Def + per-Thing hosting** — todo dado do jogo é injetável.

## 5b. Limite técnico registrado

**GDScript não suporta sobrecarga de operadores.** `var c: Team = a + b` não
compila e não tem workaround — é limitação da linguagem.

A fusão de clubes usa o `ThingVariant` da d5star, que já implementa merge com
semântica de operadores **no dado** (`+`, `-`, `*`, `/` como prefixo nos
valores JSON, `=` escapando literal). O `+` existe, só que na camada de dados:

```gdscript
var novo: Dictionary = TeamFusion.merge(vasco_patriotas, botafogo_reptiles)
```

## 6. Dívidas conhecidas

- ~~FFM não tem suíte de testes~~ — resolvida em `A.2`: `tests/run.tscn`,
  rodando por cena para os autoloads existirem.

---

## 7. Feature branches

### Fase A — O modelo
| Branch | Entrega | |
|---|---|---|
| `A.1-team-database` | Os 9 clubes cariocas como Things, região derivada da UF, tier e reputação | ✅ |
| `A.2-stat-model` | 7 stats base + 9 derivadas (média de 3, piso) + Geral, e a suíte de testes | ✅ |
| `A.3-actor-model` | **Actor único**: jogador, técnico, scout e manager são o mesmo tipo | ✅ |
| ~~`A.4-role-assignment`~~ | movida para `B.6` — precisa da aba Elenco para ser visível | → |
| ~~`A.5-team-generator`~~ | movida para `B.3`, e entregue lá | ✅ |
| ~~`A.6-perks`~~ | movida para `B.7` — os ícones só fazem sentido ao lado dos nomes | → |

### Fase B — O clube na tela
| # | Branch | O que você vê no jogo | |
|---|---|---|---|
| **B.1** | `start-screen` | A Start Screen: Continue (cinza), Novo Jogo, Ajustes, Sair | ✅ |
| **B.2** | `module-select` | A lista de módulos: o nativo e qualquer universo em `user://modules` | ✅ |
| **B.3** | `team-generator` | A lista salta de 10 pra 16 clubes; os 6 do fundo são várzea carioca | ✅ |
| **B.4** | `create-manager` | Ficha estilo Zomboid: 8 atributos, 15 habilidades, corpo com régua cobrada, idade como preço, Career Type com Pick Team cadeado | ✅ |
| **B.4c** | `names-and-perks` | Nome/sobrenome/apelido em campos separados, gerador de apelidos coerente, 10 perks com preço em career point (defeito devolve), 🎲 que sorteia a vida inteira, semente derivada do nome | ✅ |
| **B.5** | `team-screen` | Seu clube com abas **Elenco** e **Adversários**, e a ficha completa de qualquer um ao clicar. **Paga a dívida de A.2 e A.3**. Elenco = curadoria (`ActorDef`) + geração por cima | ✅ |
| **B.5b** | `actor-lifecycle` | Elencos que leem certo: clube iniciante cheio de moleque, clube grande com veterano especializado. O actor deixa de ser sorteado e passa a ser **vivido** — ficha de nascimento, posição, ano a ano de carreira, curva de idade | ✅ |
| **B.5c** | `praca-e-draft` | A arquitetura: `ActorGenerator.spawn` → `Praca` → `draft(actor, teams)` → `LeagueGenerator`. `Rosters` para de gerar e passa a receber. Origens viram regra de draft, e o Fundador batiza o próprio clube | ✅ |
| **B.5d** | `draft-screen` | A montagem do mundo ganha tela: barra de progresso e o **log do draft** — quem foi pra onde e por quê — com [OK] pra você conferir antes de passar | ✅ |
| **B.6l** | `tabela-de-verdade` | A tabela do elenco vira um GridContainer único (alinhamento estrutural), a célula passa a mostrar a afinidade no lugar do código repetido, e o texto explicativo do painel vira tooltip | ✅ |
| **B.6k** | `presidente-e-corpo` | O player vira PRESIDENTE e a cadeira é travada; o corpo sobe pra identidade e os talentos ganham a largura inteira; fontes do elenco vão pra escada; o nome do clube passa a mudar o clube | ✅ |
| **B.6j** | `neutro-e-ascii` | Azul-marinho e branco até a tela do time; cor reservada pra talento, atenção, chakra e clube. Glifos ASCII no lugar de emoji, talentos com código de três letras, seletor de cor do clube, e o dado do clube que não sorteava | ✅ |
| **B.6i** | `codigos-e-tooltips` | Atributos e habilidades viram código de três letras; todo texto explicativo sai da tela e vira tooltip, e todo controle sem tooltip ganha um. Criação de 2256x810 para 1740x790 | ✅ |
| **B.6h** | `high-res` | Um para um: a janela é o canvas, sem escala. Criação volta a três colunas numa página, elenco e draft recuperam suas larguras. Três avisos do compilador limpos | ✅ |
| **B.6e** | `canvas-720` | O canvas de projeto vira **1280x720**, pra 1440p pegar 2x e 4K pegar 3x. Criação em três abas, elenco com os códigos no degrau menor, draft mais curto. Escala calculada no runtime | ✅ |
| **B.6b** | `pixel-e-layout` | Duas fontes pixel de terminal (VT323 + Pixel Code), render em Nearest, e as telas remontadas pra usar a tela: criação em três colunas com rodapé fixo (1743px → 1050px), escalação à esquerda e tabela à direita. Catálogo de talentos de 10 para **27** | ✅ |
| **B.5e** | `tryouts` | A oferta deixa de ser um pool mundial e passa a ser **peneira por clube** (2d5* + alcance, no nível do clube) + quem aparece sozinho. Rodada: peneiras → indies → draft da praça, do melhor pro pior. Comissão técnica entra como orçamento próprio | ✅ |
| **B.6** | `role-assignment` | Colunas ordenáveis e três blocos: **Perfil · Escalação · Comissão**. Cada vaga é um botão onde a CAIXA É UMA BARRA preenchida pela afinidade — o elenco lê como mapa de calor, e a mesma tela resolve escalação e comissão técnica | ✅ |
| **B.7** | `talentos-e-preto` | Talento vira **palavra + marca ascii** (`FOGUETE >`) na criação e mantém a sigla na coluna de 34px do elenco; saldo de tp no cabeçalho. A página fica **preta**: `CANVAS` separado de `PANEL`, o clube veste as janelas e a seleção em vez do monitor, e o azul-marinho que a decisão 71 tinha mandado embora sai de verdade. Criação em **2x2**, estreia recalibrada dos **14**, gradiente na idade e três cabeçalhos que estavam cortados | ✅ |
| **B.8** | `pools-e-moedas` | As cinco barras na ficha e as três moedas no cabeçalho do elenco. **Só exibição.** Um pool é um par `agora`/`máximo`, e a cor da barra é **o quanto ela está cheia** e não qual pool é — o código ao lado diz qual. A Loyalty abre pela distância entre o nível do clube e o do atleta, que é a relação no dia um. `D.1` drena os quatro do corpo, `C.1` e `C.3` escrevem a Loyalty, `C.5` recarrega | ✅ |
| **B.9** | `vaga-e-dropdown` | **A vaga vazia vira ponto de entrada.** Clicar numa vaga da escalação (ou numa cadeira da comissão) abre a lista de quem pode ocupá-la, ordenada pela afinidade NAQUELA posição — o caminho inverso de ordenar a tabela e clicar na célula, e os dois passam a valer. ⚠️ Uma fonte, dois leitores: a ordem da lista e a cor da célula saem da MESMA função de afinidade, senão a lista diz que ele é o melhor center enquanto a barra dele está fria. A vaga já sabe a posição, então a lista é o elenco inteiro ordenado e não uma lista "de centers" — decisão 47 de pé. Quem já está sentado aparece com onde está, não sumido | |

> `team-generator` subiu na frente de `create-manager`: o sorteio coloca você
> num clube **tier 4**, e nenhum dos 10 clubes reais é tier 4. Sortear num
> tier 3 agora significaria refazer depois, perdendo a premissa de começar na
> várzea.

### Fase C — A semana  🔥 *fim desta fase = jogo rodando em loop*

⚠️ **O motor de partida saiu do caminho crítico.** A semana 1 que o loop precisa
— escalar, treinar, cobrar mensalidade, ver o que aconteceu — **não tem jogo**:
o evento dela é o coletivo. `match-engine` era o item mais caro dessa fase e
virou Fase D, onde ele é "a semana que tem jogo" em vez de o pré-requisito de
existir uma semana.

| Branch | Entrega |
|---|---|
| `C.1-people-management` | O modelo de ação: o ponto compra a TENTATIVA, o D5 resolve o desfecho em três faixas (2+ agrada todos e ele · 1 agrada todos menos ele · 0 não agrada ninguém). Oito ações nas três moedas, escrevendo **Loyalty** e **relações**. Montar comissão e escalação pela primeira vez é de graça — desfazer o que você mesmo fez é que custa |
| `C.2-ct-e-treino` | Quatro níveis de CT valendo 1–3 slots, e a semana como **roteiro**: discurso inicial → slots → discurso final. Catálogo de seis exercícios mais o coletivo. O discurso é a ação de People Management que mora na tela de treino |
| `C.3-financeiro` | Caixa e extrato de cinco linhas. **A mensalidade é um slider e é a tensão inteira do jogo**: alto enche o caixa e derruba a Loyalty, baixo é amado e quebrado. Aluguel do CT, equipamento, churrasco |
| `C.4-coletivo` | Coletivo semanal: elenco dividido em dois, você observa. **É o evento da semana no MVP** |
| `C.5-week-tick` | A resolução e o relatório da semana — o log do draft serve de molde. `S/YYYY` avança. **O loop fecha aqui** |

> Recomendação registrada: **`E.3-save-load` deveria vir logo depois do `C.5`**.
> A partir dele existe uma carreira que dura semanas, e perder oito semanas de
> teste a cada sessão é o que mata o playtest.

### Fase D — A partida
| Branch | Entrega |
|---|---|
| `D.1-match-engine` | Simulação headless, determinística, emitindo eventos *(era `C.1`)* |
| `D.2-match-view` | **A tela Elifoot**: um jogo por linha, cronômetro, eventos ao vivo *(era `C.2`)* |
| `D.3-comissao-tecnica` | Buffs/debuffs dos cargos e chamada de jogada. **A ESCOLHA dos cargos já saiu em `B.6`** — os 5 cargos (HC · OC · DC · PF · OL) são posições de `side: staff` e usam a mesma afinidade, o mesmo botão e a mesma tela *(era `D.1`)* |
| `D.4-match-controls` | Substituição e mudança de padrão tático durante o jogo *(era `E.4`)* |

### Fase E — O mundo vivo
| Branch | Entrega |
|---|---|
| `E.1-praca-viva` | A praça com fluxo semanal, aba própria e KPIs — actors sem clube, jogadores e comissão, esperando convite. **Quente `^^` / fria `vv`** *(era `D.4`)* |
| `E.2-fog-of-war` | Stats, habilidades e talentos invisíveis; revelados por olheiro, coletivo, tempo de convívio e jogo oficial |
| `E.3-save-load` | Conserta `The.snapshot()` e persiste a carreira *(era `E.1`)* |

### Fase F — A temporada e a carreira
| Branch | Entrega |
|---|---|
| `F.1-calendar-season` | 1º semestre estaduais, 2º regionais + nacional *(era `E.2`)* |
| `F.2-carioca` | Campeonato Carioca: tabela, rodadas, decide o tier *(era `E.3`)* |
| `F.3-manager-career` | Envelhece, morre aos 90, força por resultados, expulsão e convite *(era `E.5`)* |
| `F.4-season-rollover` | Virada de ano, envelhecimento do elenco *(era `E.6`)* |
| `F.5-team-lifecycle` | Fusão e extinção de clubes, redistribuindo os actors *(era `E.7`)* |

### Fase G — O corte  🚀 *fim desta fase = v0.1.0 nas mãos de gente*
| Branch | Entrega |
|---|---|
| `G.1-tudo-em-json` | O que ainda mora em GDScript e é **conteúdo** sai: as fórmulas das três moedas, as paletas de clube, o tamanho de elenco por divisão, a curva de envelhecimento. ⚠️ **Vem antes do `C.1`, não depois** — cada consumidor novo encarece a mudança, e o People Management vai ler as moedas o tempo todo |
| `G.2-curadoria` | **A passada manual em TODO o conteúdo**, feita pelo autor e não pelo gerador: nomes, apelidos, talentos, cenários, clubes, eventos, textos de rolo. É a última coisa antes do corte, e é o que separa "o sistema funciona" de "o jogo tem voz" |
| `G.3-v0.1.0` | Export **HTML pro itch.io** e um **.exe** pra mandar por link. Dois meses de treino jogáveis pros alpha players |

> **A regra que a Fase G existe pra garantir, e que vale pra tudo que for
> escrito daqui em diante:** todo evento e todo rolo é **injetável por JSON**,
> com script opcional ligado pelo nome (`things/event/<id>/<id>.json` +
> `<id>.gd extends ThingPart`, que a lib auto-liga e o `ScriptBindingValidator`
> confere no boot). O JSON declara o comum — texto, quais stats e skills entram,
> dificuldade, buffs, debuffs, desfechos — e o script é a válvula de escape.
>
> O vocabulário desses campos é **fechado e coberto por teste**, igual ao
> `effect` dos talentos: um `"kind"` escrito errado tem que quebrar no boot, não
> virar desbalanceamento inexplicável três branches depois.
>
> Fazer um desenvolvimento desse tamanho sem essa garantia é perder tempo: o
> conteúdo que não se alcança pelo JSON é conteúdo que não dá pra curar.

### Movidas e absorvidas
| Branch | |
|---|---|
| ~~`C.1-match-engine`~~ · ~~`C.2-match-view`~~ | viraram `D.1` e `D.2` — a partida deixou de ser pré-requisito do loop | → |
| ~~`D.5-elenco-crud`~~ | **absorvida pelo `C.1`**. Expulsar, elogiar e convidar da praça eram um CRUD; viraram ações com custo em moeda e roll de desfecho. A feature sumiu porque o People Management já a contém — menos código, não mais | ✂ |
| ~~`D.2-local-treino`~~ · ~~`D.3-financeiro`~~ | subiram pra `C.2` e `C.3`: sem elas não existe o que resolver numa semana | ↑ |

### Fora do MVP
Regional e nacional · categoria feminina · amistosos agendados · expansão
pros 139 times do Brasil.

---

## 8. Histórico

O FFM nasceu como club manager, virou simulação da vida do atleta, e em
2026-09-03 voltou à essência. O life sim inteiro está preservado na tag
`pre-d5star-migration` e na branch `legacy/life-sim` — incluindo 12 telas de
UI, minigames, cutscenes, quests e o sistema de tryout.
