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
| 17 | **Modalidade, não gênero.** O jogo não pergunta se você é homem ou mulher; pergunta **em que modalidade você joga** e **qual você gerencia**. O `Actor` carrega `plays` e `manages` como arrays de `masc`/`fem`/`misto` — "joguei no masculino, treinei o feminino" é a norma no flag brasileiro, não exceção. Regra dura: `plays` não pode conter `masc` e `fem` juntos. |
| 18 | **`The` é o Blackboard, `Record` é o item.** O quadro compartilhado por onde o estado flui entre cenas é `The.board`; cada entrada tipada nele é um `Record`, que sabe se serializar. O Flow gateia as próprias transições no conteúdo do quadro — controle dirigido por blackboard, e a lib já fazia isso sem nomear. |
| 19 | **A régua é ancorada e o d5\* a define.** 1 passo é criança pequena, **5 é adulto mediano**, 10 é atleta olímpico candidato a medalha. Armazenado 0..100 (o caminho do treino), lido em passos de dez (o que rola). Um teste de habilidade é `atributo + habilidade + 2d5*` — e é essa soma que obriga a escala a ser 1..10: com 0..100 o dado viraria ruído. |
| 20 | **O líder empresta seus passos ao elenco.** O modificador é `passo − 5`, com a âncora do adulto mediano como zero: 6 dá +1, 7 dá +2, e um líder de 3 passos **atrapalha** em −2. Vale para atributos e para as habilidades de comissão, e é por isso que a ficha do manager não é enfeite. |
| 21 | **A criação é paga em anos de vida.** A tela **sorteia um moleque de 12 anos** — corpo, os 8 atributos entre 2 e 7, e às vezes um perk — e **os 6 anos que fazem dele um adulto são os que você gasta** (~130 career points). O sorteio não encosta nas habilidades de propósito: como um teste é atributo + habilidade, decidir isso pelo jogador esvaziaria a única pergunta da tela. O perk sai desses mesmos 12 anos — quem veio com Craque pagou em atributo, quem veio com Vidraça está mais forte por causa disso — e serve pra dar um tom antes do jogador decidir qualquer coisa. O 🎲 sorteia **outro moleque**, idêntico — os dados escolhem quem você nasceu, nunca quem você virou. A origem de todo custo continua sendo o zero, então vender um atributo devolve os 45 pontos inteiros e você pode se refazer do nada. A idade sobe enquanto você distribui e volta quando você desfaz. Tudo pode ser devolvido até zero. Atributos e habilidades saem do mesmo bolso, porque treinar destreza e treinar lançamento melhoram a mesma jogada. **E você sai da tela aos 18 ou não sai**: o botão de começar fica fechado enquanto sobrar ponto. A moeda é o **career point**: entrar no passo N custa N pontos do próprio tipo, e um ponto de atributo vale 3 career points contra 2 de habilidade — crescer é mais caro que aprender. Um ano de vida dá 23, então a vida inteira vale 414. A semente **é o nome**: `hash(nome + sobrenome + apelido)`. Ela não *rola* a ficha — o jogador continua distribuindo cada ponto à mão, que era o motivo de tirar o sorteio inicial do caminho — mas define o mundo em que ele nasce: quais clubes de várzea existem e qual deles te chama. Escrever os três campos num papel é o suficiente para voltar ao mesmo mundo. |
| 22 | **O apelido tem que ser sobre a pessoa.** No amador brasileiro o apelido *é* o nome — ninguém no campo sabe o sobrenome do cara — então um apelido sorteado de um saco genérico se denuncia na hora. São quatro fontes e três delas são coerentes com o actor: morfologia sobre o **nome** (Pedro → Pedrinho, Lucas → Luquinho), sobre o **sobrenome** (Vasconcelos → Vasco), sobre o que ele é **notável** por (9 de agilidade → Foguete, 2 de vontade → Chorão) e, por último, o saco aberto. Atributo conta para os dois lados; **habilidade só conta para cima**, porque um amador tem uma dúzia de habilidades zeradas por nunca ter treinado, não por ser ruim nelas. |
| 23 | **Um perk, opcional, e o defeito paga.** No máximo **1** por actor, e não pegar nenhum é uma resposta legítima — tudo vai para a ficha. Qualidade custa career points; **defeito devolve**. Sem isso ninguém escolheria "mãos de pedra", e é justamente o defeito pago que faz o teto de 1 ser uma regra necessária em vez de arbitrária. O `effect` de cada perk fica **declarado** no catálogo e é consumido por quem é dono da regra — `C.1` lê `roll_bonus`, o treino lê `training_penalty`, a temporada lê `injury_risk`. |
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
do loop semanal, e por isso vêm cedo (Fase C).

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
  Continue (cinza até E.1) · Novo Jogo · Ajustes · Sair
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
                                            ├── Local de Treino    (D.2)
                                            └── Financeiro         (D.3)
                       └─ [ Próxima Semana ]  → C.4
```

A barra de abas nasce com **duas** abas em `B.4` e cresce conforme a Fase D
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

**Posições** (flag é 5×5): QB · Center · Recebedor · Rusher · Safety

**Padrões táticos**
- *Ataque*: Passe curto · Bomba · Balanceado · Segurar relógio
- *Defesa*: Homem-a-homem · Zona · Blitz · Prevent

**Perks** — catálogo em `game/defs/perk.json`, no máximo **1** por actor e
opcional. O preço é em career points e o defeito **devolve**.

| ASCII | Perk | cp | Efeito declarado |
|---|---|---|---|
| `★` | Craque | 40 | `roll_bonus` +1 em tudo |
| `⚡` | Foguete | 25 | `roll_bonus` +2 em rota |
| `🧠` | Cérebro | 25 | `roll_bonus` +2 em cobertura |
| `✋` | Mãos de cola | 25 | `roll_bonus` +2 em recepção |
| `🎯` | Ferrolho | 25 | `roll_bonus` +2 em tackle |
| `📣` | Capitão | 30 | `team_bonus` +1 de moral |
| `💸` | Padrinho | 20 | `finance_bonus` em patrocínio |
| `🪨` | Mãos de pedra | **−25** | `roll_bonus` −2 em recepção |
| `👻` | Sumido | **−30** | `training_penalty` na presença |
| `🩹` | Vidraça | **−30** | `injury_risk` +2 |

O `effect` é um **contrato**, não uma regra: quem o executa é o sistema dono
dela — `C.1` lê `roll_bonus`, o treino lê `training_penalty`, a temporada lê
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
| **B.5** | `team-screen` | Seu clube com abas **Elenco** e **Adversários**. **Paga a dívida de A.2 e A.3** | |
| **B.6** | `role-assignment` | Coluna **Função** no Elenco: escala alguém em duas e vê o Geral cair | |
| **B.7** | `perks` | Os ícones `★ ⚡ 🧠 🪨` na lista do elenco — o catálogo e a escolha já saíram em `B.4c`, falta o roster mostrar | |

> `team-generator` subiu na frente de `create-manager`: o sorteio coloca você
> num clube **tier 4**, e nenhum dos 10 clubes reais é tier 4. Sortear num
> tier 3 agora significaria refazer depois, perdendo a premissa de começar na
> várzea.

### Fase C — O coletivo  🔥 *fim desta fase = jogo rodando em loop*
| Branch | Entrega |
|---|---|
| `C.1-match-engine` | Simulação headless, determinística, emitindo eventos |
| `C.2-match-view` | **A tela Elifoot**: um jogo por linha, cronômetro, eventos ao vivo |
| `C.3-coletivo` | Coletivo semanal: elenco dividido em dois, você observa |
| `C.4-week-tick` | Próxima Semana avança `S/YYYY` e dispara o evento da semana |

### Fase D — As outras abas
| Branch | Entrega |
|---|---|
| `D.1-comissao-tecnica` | CRUD de técnicos, buffs/debuffs, chamam jogadas |
| `D.2-local-treino` | Campos, custo, buff/debuff no elenco |
| `D.3-financeiro` | Caixa, mensalidades, patrocínios |
| `D.4-praca` | Actors sem clube — jogadores e comissão — esperando convite |
| `D.5-elenco-crud` | Expulsar, elogiar, convidar da Praça |

### Fase E — A temporada e a carreira
| Branch | Entrega |
|---|---|
| `E.1-save-load` | Conserta `The.snapshot()` e persiste a carreira |
| `E.2-calendar-season` | 1º semestre estaduais, 2º regionais + nacional |
| `E.3-carioca` | Campeonato Carioca: tabela, rodadas, decide o tier |
| `E.4-match-controls` | Substituição e mudança de padrão tático durante o jogo |
| `E.5-manager-career` | Envelhece, morre aos 90, força por resultados, expulsão e convite |
| `E.6-season-rollover` | Virada de ano, envelhecimento do elenco |
| `E.7-team-lifecycle` | Fusão e extinção de clubes, redistribuindo os actors |

### Fora do MVP
Regional e nacional · categoria feminina · amistosos agendados · expansão
pros 139 times do Brasil.

---

## 8. Histórico

O FFM nasceu como club manager, virou simulação da vida do atleta, e em
2026-09-03 voltou à essência. O life sim inteiro está preservado na tag
`pre-d5star-migration` e na branch `legacy/life-sim` — incluindo 12 telas de
UI, minigames, cutscenes, quests e o sistema de tryout.
