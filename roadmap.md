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
no RJ). A lista é melhor esforço, não verdade absoluta.

Somos o *International Superstar Soccer* do flag: adaptação, não simulação.

---

## 2. Decisões fechadas

| # | Decisão |
|---|---|
| 1 | **MVP é só masculino.** Mas o clube modela **dois elencos** (`squads`), porque gerir masculino + feminino é o diferencial em relação ao Elifoot. O feminino entra depois sem refatoração. |
| 2 | **Assimetria estadual é abraçada.** SP tem ~60 times, RR tem 6. Começar em SP é hard mode; em RR é fácil subir e caro viajar. Variedade de carreira de graça. |
| 3 | **Todos os jogos ao vivo.** A rodada inteira roda junto na tela, um jogo por linha, tabela mudando em tempo real. |
| 4 | **Duas rotas de carreira**, como no Elifoot: subir de tier **com o time**, ou **trocar de time** (ser demitido, ser convidado). O manager é uma entidade própria, com reputação. |
| 5 | **Força é um número único.** Os 9 atributos do modo carreira antigo foram descartados. O framework de Def de stats continua igual, então expandir depois é só editar JSON. |
| 6 | **Perks aprovados** (tabela na §4). |
| 7 | **Posições e padrões táticos aprovados** (§4). |
| 8 | **Calendário orientado a semana**, não a tempo real: `S/YYYY`, 52 turnos por ano. |
| 9 | **O evento padrão de toda semana é o coletivo.** Por isso o motor e a tela de partida vêm cedo, não no fim. |

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

## 6. Dívidas conhecidas

- `The.snapshot()` varre `get_nodes_in_group("things")`, mas Things são
  RefCounted e nunca entram na árvore — **o save não acha nada**. Bloqueante
  pra jogo de carreira. Endereçado em `E.1`.
- `game/defs/flow.gd` é cópia literal do ScrapWarriorsOne. O próprio autor
  anotou no código que deveria viver na d5star. Exigiria o DefManager varrer
  também um diretório de defs da engine.
- FFM não tem suíte de testes — validação é só o boot headless.

---

## 7. Feature branches

### Fase A — Dados reais
| Branch | Entrega | |
|---|---|---|
| `A.1-team-database` | Os 9 clubes cariocas como Things, região derivada da UF, tier e reputação | ✅ |
| `A.2-fictional-fill` | Clubes fictícios não federados (tier 4) completando o Carioca | |
| `A.3-player-generation` | Elencos: nome, camisa, posição, força, perk | |
| `A.4-perks` | Catálogo de perks com efeito mecânico | |

### Fase B — A casca
| Branch | Entrega |
|---|---|
| `B.1-new-game-draft` | Novo Jogo sorteia você como manager de um clube tier 4 |
| `B.2-club-home` | Home com barra de abas + botão Próxima Semana |
| `B.3-elenco` | A aba Elenco: lista de jogadores com ASCII de qualidade |

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
| `D.4-mercado` | O "leilão": técnicos atraem talento entre as semanas |
| `D.5-elenco-crud` | Expulsar, elogiar — a gestão de verdade do elenco |

### Fase E — A temporada
| Branch | Entrega |
|---|---|
| `E.1-save-load` | Conserta `The.snapshot()` e persiste a carreira |
| `E.2-calendar-season` | 1º semestre estaduais, 2º regionais + nacional |
| `E.3-carioca` | Campeonato Carioca: tabela, rodadas, decide o tier |
| `E.4-match-controls` | Substituição e mudança de padrão tático durante o jogo |
| `E.5-season-rollover` | Virada de ano, envelhecimento |

### Fora do MVP
Regional e nacional · categoria feminina · carreira do manager (demissão e
convite) · amistosos agendados · expansão pros 139 times do Brasil.

---

## 8. Histórico

O FFM nasceu como club manager, virou simulação da vida do atleta, e em
2026-09-03 voltou à essência. O life sim inteiro está preservado na tag
`pre-d5star-migration` e na branch `legacy/life-sim` — incluindo 12 telas de
UI, minigames, cutscenes, quests e o sistema de tryout.
