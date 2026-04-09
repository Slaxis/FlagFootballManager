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

### 3.3 — Effect system
- Events produce timed Effects that persist across slots
- Effect has: name, duration_slots, modifiers (activity bonuses/penalties)
- E.g., "Runner's High" lasts 4 slots, +10% to physical training
- E.g., "Pulled Muscle" lasts 8 slots, -20% to physical, +negative event chance
- Effects shown as cards in the bottom effects bar
- Effects applied during slot resolution as multiplier on top of slot_modifiers

### 3.4 — Activity unlock/lock
- `requires` field per activity: `age`, `school`, `team`, `day`, `one_time`, `requires_item`
- Locked activities greyed out in dropdown with lock icon and tooltip explaining why
- Unlocks happen through gameplay progression (join team, buy item, reach age)

### 3.5 — Hunger cascade
- hunger=0: eat from fridge (free, no slot) → pedir comida (costs $, no slot) → comer fora (costs $$, no slot) → collapse if broke
- Fridge depletes first, then money, then collapse

### 3.6 — Social from phone
- "Sair com amigos" becomes phone-initiated: pick friend, pick activity, schedule in calendar
- Social activities unlock through contacts made via Rolê na praça / phone

### 3.7 — Fridge inventory
- Full item-based fridge (not just meal counter)
- Buy food via phone shop, stored as items
- Meals consume specific items, different nutritional value

---

## Phase 4 — Card Minigame (Core Mechanic)

### 4.1 — Play card data
- Def: `game/defs/play.gd` + `play.json`
- Routes: Post, Go, Slant, Out, In, Corner, Curl, Flat, Screen
- Each play has card image (placeholder or generated)

### 4.2 — Minigame scene
- Top: 2D top-down field
- Center: play call text ("Run a POST route!")
- Bottom: 3 cards, one correct + 2 distractors
- Timer bar (10s for tryout, decreases with difficulty)

### 4.3 — Tryout event
- Sunday morning, weeks 1-4
- 5 rounds of play recognition, need 3/5 to pass
- Fail week 4 → game over

### 4.4 — Training integration
- Team training uses same minigame, more rounds, XP scaling

### 4.5 — Field visualization
- Node2D with yard lines, player token runs route path via tween

---

## Phase 5 — Calendar Year & Origins

### 5.1 — Calendar year from module
- `start_date` in module manifest, real dates in top bar

### 5.2 — Origin system (Arcanum-style)
- Backgrounds chosen at creation with stat modifiers, school assignment, schedule
- Origins: Estudante Municipal Noturno, Classe Média Manhã, Técnico Tarde, Bully, Atleta Escolar, Nerd Quieto

### 5.3 — School as locked schedule
- Origin injects locked slots, attendance tracked as quest

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
3.4 Activity unlock/lock ⚙ requires system
3.5 Hunger cascade       · fridge → money → collapse
3.6 Social from phone    · phone-initiated social events
3.7 Fridge inventory     · full item-based fridge

4.1 Play card data       · card definitions
4.2 Minigame scene       · play the card game
4.3 Tryout event         · tryout minigame
4.4 Training             · team training minigame
4.5 Field viz            · route animation

5.1 Calendar year        · real dates
5.2 Origin system        · character backgrounds
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
