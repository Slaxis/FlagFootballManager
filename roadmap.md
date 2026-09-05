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
- Flag é olímpico em LA 2028

Os 9 times que já estavam no repo são reais (Cronos, Coritiba Crocodiles,
Goiânia Rednecks, Campo Grande Predadores, Spartans, Batatais Ghosts,
Tritões, Cavalaria 2 de Julho).

⚠️ A fonte tem erros de região que precisam ser corrigidos **por UF**:
RR e TO aparecem como Sul (são Norte), PB como Sul (é Nordeste), SC e ES
como Sudeste (SC é Sul).

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

### Tiers — como o "tier 4" encaixa na realidade

| Tier | Realidade | Como se vive lá |
|---|---|---|
| **4** | Não federado | Estadual e amistoso. Jogador **paga** pra jogar. Campo de várzea. |
| **3** | Série C | Entra no Brasileirão. Primeiro patrocínio local. |
| **2** | Série B | Estrutura real, viagem começa a doer. |
| **1** | Série A | Elite. Patrocínio de verdade, disputa o título nacional. |

Subir não é promoção de tabela — é **classificação no regional**.

### Calendário — toda semana tem uma decisão

12 estaduais + 4 regionais + 2 nacionais = 18 semanas com jogo em 52. As
outras 34 **são o jogo**: treino, campo, mercado, dinheiro.

```
toda semana        treino roda + 1 evento/escolha
                   (campo caiu, jogador sumiu, patrocinador ligou,
                    talento apareceu no mercado)
fim de mês         etapa estadual
fim de trimestre   etapa regional
fim de semestre    etapa nacional  (a 2a decide o campeão do ano)
```

Etapa de flag amador é um **fim de semana inteiro com vários jogos**, não uma
partida — o que entrega naturalmente a tela do Elifoot.

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
   └─ sorteio: você é manager de um time tier 4
        └─ HOME DO CLUBE  ── abas ──┬── Elenco
             │                      ├── Comissão Técnica
             │                      ├── Local de Treino
             │                      └── Financeiro
             └─ [ Próxima Semana ]
                   ├─ semana comum  → treino + evento → resumo → HOME
                   ├─ entre semanas → mercado ("leilão") → HOME
                   └─ semana de etapa → TELA DE JOGOS AO VIVO → HOME
```

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
  pra jogo de carreira. Endereçado em `D.1`.
- `game/defs/flow.gd` é cópia literal do ScrapWarriorsOne. O próprio autor
  anotou no código que deveria viver na d5star. Exigiria o DefManager varrer
  também um diretório de defs da engine.
- FFM não tem suíte de testes — validação é só o boot headless.

---

## 7. Feature branches

### Fase A — Dados reais
| Branch | Entrega |
|---|---|
| `A.1-team-database` | Os ~139 times reais em Thing JSON, região corrigida por UF, categorias masc/fem |
| `A.2-fictional-fill` | Gerador de times fictícios pra completar estaduais rasos |
| `A.3-player-generation` | Roster procedural: nome, camisa, posição, força, perk |
| `A.4-perks` | Catálogo de perks com efeito mecânico |

### Fase B — A casca
| Branch | Entrega |
|---|---|
| `B.1-new-game-draft` | Novo Jogo sorteia você como manager de um time tier 4 |
| `B.2-club-home` | Home com barra de abas + botão Próxima Semana (abas vazias) |

### Fase C — As quatro abas
| Branch | Entrega |
|---|---|
| `C.1-elenco` | Lista com ASCII de qualidade, CRUD (expulsar, elogiar) |
| `C.2-comissao-tecnica` | CRUD de técnicos, buffs/debuffs, chamam jogadas |
| `C.3-local-treino` | Campos, custo, buff/debuff no elenco |
| `C.4-financeiro` | Caixa, mensalidades, patrocínios |

### Fase D — O tempo passa
| Branch | Entrega |
|---|---|
| `D.1-save-load` | Conserta `The.snapshot()` e persiste a carreira |
| `D.2-calendar` | Semana / mês / trimestre / semestre e o que dispara em cada |
| `D.3-week-tick` | Próxima Semana processa treino + resumo de evolução |
| `D.4-mercado` | O "leilão": técnicos atraem talento entre as semanas |

### Fase E — A partida
| Branch | Entrega |
|---|---|
| `E.1-match-engine` | Simulação headless, determinística, emitindo eventos |
| `E.2-match-view` | **A tela Elifoot**: um jogo por linha, cronômetro, eventos ao vivo |
| `E.3-match-controls` | Substituição e mudança de padrão tático durante o jogo |

### Fase F — A temporada
| Branch | Entrega |
|---|---|
| `F.1-estadual` | Etapa estadual mensal + tabela |
| `F.2-regional` | Etapa regional trimestral + classificação |
| `F.3-nacional` | Etapa nacional semestral + campeão do ano |
| `F.4-manager-career` | Reputação do manager, demissão e convite de outros clubes |
| `F.5-season-rollover` | Virada de ano, acesso entre séries, envelhecimento |

---

## 8. Histórico

O FFM nasceu como club manager, virou simulação da vida do atleta, e em
2026-09-03 voltou à essência. O life sim inteiro está preservado na tag
`pre-d5star-migration` e na branch `legacy/life-sim` — incluindo 12 telas de
UI, minigames, cutscenes, quests e o sistema de tryout.
