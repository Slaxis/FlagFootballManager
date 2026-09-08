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

**Perks**

| ASCII | Perk | Efeito |
|---|---|---|
| `★` | Craque | Força alta, puxa o time |
| `⚡` | Foguete | Velocidade fora da curva |
| `🧠` | Cérebro | Lê jogada, ótimo QB/safety |
| `✋` | Mãos de cola | Não derruba passe |
| `🪨` | Mãos de pedra | Derruba o que não devia |
| `🎯` | Ferrolho | Especialista em puxar flag |
| `📣` | Capitão | Buff de moral no elenco |
| `💸` | Padrinho | Traz patrocínio / paga em dia |
| `👻` | Sumido | Falta treino sem avisar |
| `🩹` | Vidraça | Lesiona fácil |

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

- **O save tem dois furos independentes**, não um. Bloqueante pra jogo de
  carreira, e `E.1` é reescrita do caminho de persistência, não um remendo:
  1. `The.snapshot()` varre `get_nodes_in_group("things")`, mas Things são
     RefCounted e nunca entram na árvore — a varredura sempre volta vazia.
  2. `The.snapshot()` faz `board.duplicate(true)` e **nunca chama
     `to_snapshot()`** nos Records. `duplicate` num Dictionary com RefCounted
     copia a referência, não o estado — e referência não vira JSON. Os ganchos
     de memento estão declarados, o `Hand` até os sobrescreve, e ninguém os
     invoca.
- `game/defs/flow.gd` é cópia literal do ScrapWarriorsOne. O próprio autor
  anotou no código que deveria viver na d5star. Exigiria o DefManager varrer
  também um diretório de defs da engine.
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
| `A.4-role-assignment` | Escalação em funções + penalidade de acumular | |
| `A.5-team-generator` | `TeamGenerator` inventa clubes; preenche o Carioca com não federados | |
| `A.6-perks` | Catálogo de perks com efeito mecânico | |

### Fase B — O clube na tela
| # | Branch | O que você vê no jogo | |
|---|---|---|---|
| **B.1** | `start-screen` | A Start Screen: Continue (cinza), Novo Jogo, Ajustes, Sair | ✅ |
| **B.2** | `module-select` | A lista de módulos: o nativo e qualquer universo em `user://modules` | ✅ |
| **B.3** | `team-generator` | A lista salta de 10 pra 16 clubes; os 6 do fundo são várzea carioca | ✅ |
| **B.4** | `create-manager` | Cria seu manager (nome sorteado, 18 anos) e escolhe Career Type — Random ativo, **Pick Team cadeado** | |
| **B.5** | `team-screen` | Seu clube com abas **Elenco** e **Adversários**. **Paga a dívida de A.2 e A.3** | |
| **B.6** | `role-assignment` | Coluna **Função** no Elenco: escala alguém em duas e vê o Geral cair | |
| **B.7** | `perks` | Os ícones `★ ⚡ 🧠 🪨` ao lado dos nomes | |

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
