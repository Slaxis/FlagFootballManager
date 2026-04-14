# FFM v0.1.0 — Execution Plan

Player is 15, has 4 weeks to prepare for a flag football tryout while keeping up with school and household chores. Core mechanic: card selection under time pressure (play recognition).

---

## Phase 1 — Module System & i18n ✅

### 1.1 — Module select screen ✅
### 1.2 — Language toggle ✅
### 1.3 — Cutscene as injectable Things ✅

---

## Phase 2 — Weekly Planner ✅

### 2.1 — Week grid UI ✅
### 2.2 — Slot synergy/penalty matrix ✅
### 2.3 — Vital collapse system ✅
### 2.4 — Next Week resolution ✅ (merged into 2.1)
### 2.5 — Weekly quests sidebar ✅

---

## Phase 3 — Activities & Events

### 3.1 — Attribute training activities ✅
- 9 attribute activities with 3 events each (pos/neu/neg)
- HP vital, activity categories (BRUTALITY/FINESSE/COGNITION/SCHOOL/FAMILY/FRIENDS)
- Grouped dropdowns with category separators
- All slots open with soft margin modifiers (no hard locks)
- Fridge meal system (cooking stocks fridge, hunger uses fridge before collapse)
- Floating fridge window, week schedule carryover
- Late night global energy penalty

### 3.2 — Life activities ✅ (merged into 3.1)
- Study, Chores, Cook, Clean Room, Rest, Sleep, Beach Football, Games, etc.

### 3.3 — Effect system ✅
- Events produce timed Effects that persist across slots
- Effect has: name, duration_slots, modifiers (activity bonuses/penalties)
- E.g., "Runner's High" lasts 4 slots, +15% to brutality
- E.g., "Scraped Knee" lasts 6 slots, -30% brutality, -20% finesse
- Effects shown as cards in the bottom effects bar
- Effects applied during slot resolution as multiplier on top of slot_modifiers

### 3.4 — Activity unlock/lock ✅
- `requires` field per activity: `min_age`, `has_item`, `has_team`, `no_team`, `week_range`
- Locked activities hidden from dropdown (not shown, not greyed)
- Unlocks happen through gameplay progression (join team, buy item, reach age)

### 3.5 — Hunger cascade ✅
- Auto-meals: breakfast (morning) and dinner (night) when hunger < 80
- Source cascade: fridge (free, +35) → delivery (R$15, +30) → lanche (up to R$30, scaled) → nothing
- Emergency cascade at hunger=0: same sources but fridge restores +25 (smaller emergency portion)
- Cooking stocks the fridge — strategic resource for sustaining the week without spending money
- Log shows source: [=] fridge, [$] money spent

### 3.6 — Social from phone
- "Sair com amigos" becomes phone-initiated: pick friend, pick activity, schedule in calendar
- Social activities unlock through contacts made via Rolê na praça / phone

### 3.7 — Fridge inventory
- Full item-based fridge (not just meal counter)
- Buy food via phone shop, stored as items
- Meals consume specific items, different nutritional value

---

## Phase 4 — Card Minigame (Core Mechanic)

### 4.1 — Play card data ✅
- Def: `game/defs/play.gd` + `play.json`
- Routes: Post, Go, Slant, Out, In, Corner, Curl, Flat, Screen
- Cards show route drawings (Line2D) instead of text names

### 4.2 — Minigame scene ✅
- Route recognition minigame: call label + 3 card buttons with route drawings + timer
- Generalized card_minigame.gd supports 3 card types: path, label, play_ref
- Field panel with route animation after answer

### 4.3 — Tryout system ✅
- New "TEAM" activity category, tryout moved from brutality
- Position selection: QB, WR, Center, DB, Rusher
- 3 physical drills (40-yard dash, three-cone, pro agility) + 1 position drill
- Tryout orchestrator: position select → drills → results screen
- Physical drills: reaction (sprint/hold), path matching, direction calls
- Position drills: QB reads defense, WR/Center route recognition, DB coverage, Rusher rush read
- Pass threshold: 60% combined score (9/14)
- WIN screen on pass (team_id set, position stored)
- GAME OVER screen if week 4 ends without team → main menu
- Tryout results shown in week summary
- Tryout hidden from dropdown after joining team (no_team requires check)

### 4.4 — Training integration ✅
- Team practice uses play_minigame (5 rounds, 12s timer, difficulty 2)
- Moved team_practice to "team" category
- Minigame + events coexist: minigame runs first, then effects/events process normally
- Events: Foco Tático (buff), Coach's Scolding (debuff), play_reading skill gains

### 4.5 — Field visualization
- Node2D with yard lines, player token runs route path via tween

### 4.6 — Technique card system ✅
- Collectible technique cards with 3 personalities: Intenso (red), Técnico (blue), Estratégico (green)
- Yomi layer: Intenso > Estratégico > Técnico > Intenso
- d5* dice system (exploding 0/5), vital penalty on low vitals
- Drill minigame: situation sequences with technique card hand, multi-card play
- Hand permanent on home screen, filtered by context
- Starter: personality choice + origin bonus card
- Hotkeys: 1-5 cards, S skip, Q/W/E slot/day/week
- Physical drills migrated from play.json to drill.json
- Mechanics reference: game/docs/mechanics.md

---

## Phase 5 — Calendar Year & Origins

### 5.1 — Calendar year from module
- `start_date` in module manifest, real dates in top bar

### 5.2 — Origin system ✅
- **Origem**: quebrada (R$200, garra), condomínio (R$500, estável), mansão (R$1200, rico)
  - Each origin sets starting money, fridge meals, vitals, and stat modifiers
- **Colégio**: público (turnos 1-3), de bairro (turnos 1-2), de elite (turno 1 só)
  - School adds stat modifiers, turno stored in session for 5.3 slot locking
- **Corpo**: sliders de altura (150-200cm) e peso (45-110kg)
  - Thresholds: tall/short, heavy/light → stat bonuses/penalties
- All modifiers stack (origin + school + body) and show live in creation screen
- New Def: `origin.gd` + `origin.json`, session stores origin/school/turno/height/weight

### 5.3 — School as locked schedule
- Turno do colégio injeta slots trancados (turno 1 = manhã, turno 2 = tarde, turno 3 = noite)
- Attendance tracked as quest, skipping has consequences

---

## Phase 6 — Quest Providers (Questers)

### 6.1 — Quest provider system
- Quests come from NPCs (providers/questers), not just per-week static lists
- Each provider has: id, name, relationship_level, quest_pool
- Provider unlocks through gameplay (meet someone, join team, get job)

### 6.2 — Initial provider: Mãe (Mom)
- Available from week 1
- Quests: estudar, arrumar o quarto, preparar refeições, ajudar em casa
- Weekly allowance (mesada) tied to quest completion
- Relationship affects allowance amount and quest difficulty

### 6.3 — Future providers
- **Emprego (Boss)**: work shifts, performance targets, salary
- **Coach de posição**: skill-specific training quests
- **Coach do time**: team training attendance, tactical study
- **Presidente do time**: fundraising, team events, community
- **Namorada/o**: social quests, dates, relationship maintenance
- **Amigos**: hangout quests, loyalty missions, group activities
- Each provider can give 1-3 quests per week from their pool

---

## Phase 7 — Name Generator

### 7.1 — Brazilian name generator
- Port weighted generator from ScrapWarriors
- First names, surnames, nicknames (apelidos) by gender
- Regional pools injectable per module

---

## Phase 8 — Room Interactive Menus

### 8.1 — Floating draggable menus
- Phone, Computer, Fridge, Wardrobe as draggable Window panels
- Phone: teams, tryouts, shop, contacts
- Computer: roster, film, standings, jobs
- Fridge: food inventory
- Wardrobe: equipment slots, outfit bonuses

---

## Phase 9 — Color Revamp & Polish

### 9.1 — Theme
- Dark background, accent colors, vitals colored by value

### 9.2 — Top bar
- Time-of-day indicator, week progress bar

---

## Execution Order (Incremental & Testable)

Legend: ✅ merged | ⚙ in progress | · pending

```
1.1 Module select       ✅
1.2 Language toggle      ✅
1.3 Injectable cutscene  ✅

2.1 Week grid UI         ✅
2.2 Slot synergy         ✅
2.3 Vital collapse       ✅
2.4 Next Week            ✅
2.5 Weekly quests        ✅

3.1 Attribute activities ✅ (includes 3.1b, 3.2)
3.3 Effect system        ✅
3.4 Activity unlock/lock ✅
3.5 Hunger cascade       ✅ fridge → delivery → lanche → collapse
3.6 Social from phone    · phone-initiated social events
3.7 Fridge inventory     · full item-based fridge

4.1 Play card data       ✅ card definitions + route drawings
4.2 Minigame scene       ✅ play the card game + generalized card types
4.3 Tryout event         ✅ tryout system (data, integration, win/lose)
4.4 Training             ✅ team training minigame
4.5 Field viz            · route animation
4.6 Technique cards      ✅ collectible cards, d5*, yomi, drill minigame

5.1 Calendar year        · real dates
5.2 Origin system        ✅ quebrada/condomínio/mansão + escola + corpo
5.3 School schedule      · locked slots

6.1 Quest providers      · quester system
6.2 Mom as provider      · initial quests + allowance
6.3 Future providers     · boss, coach, girlfriend, friends

7.1 Name generator       · Brazilian names

8.1 Room floating menus  · phone, computer, fridge, wardrobe

9.1 Theme                · color revamp
9.2 Top bar              · time indicators
```

Each step produces a testable increment. Feedback after each step can redirect the next.
