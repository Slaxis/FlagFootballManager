# FFM v0.1.0 — Execution Plan

Player is 15, has 4 weeks to prepare for a flag football tryout while keeping up with school and household chores. Core mechanic: card selection under time pressure (play recognition).

---

## Phase 1 — Module System & i18n

Everything before character creation.

### 1.1 — Module select screen ✅
- New screen between main menu and character creation
- Lists available modules from `Drive.list_modules()`
- Each module shows: name, description, version (i18n-ready)
- Player selects a module → `Drive.set_module()` → proceeds to creation
- Module manifest updated with `description`, `version` fields (i18n dicts)

### 1.2 — Language toggle ✅
- PT/EN button on home screen top bar
- All runtime UI text uses `I18n.text()` with i18n dicts
- activity.json, stat.json, skill.json converted to `{"pt": ..., "en": ...}` format
- Home screen labels, slot names, day names, vital names, room items all i18n
- Character creation resolves stat/skill names and descs via I18n

### 1.3 — Cutscene as injectable Things ✅
- Cutscene pages loaded from Thing JSON with `group: "cutscene"`
- Pages sorted by `order`, text resolved via I18n, image field ready for PNGs
- Modules can inject/override cutscene content via JSON

---

## Phase 2 — Weekly Planner

Replace day-by-day with week-at-a-glance.

### 2.1 — Week grid UI ✅
- 7 columns (Mon-Sun) x 4 rows (Morning, Afternoon, Night, Late Night)
- 28 OptionButton cells, each filtered by slot availability
- Late Night defaults to Sleep
- CLEAR button resets all to first option
- NEXT WEEK resolves all 28 slots sequentially
- Layout: grid left (3/4 width), room + vitals + log right (1/4)

### 2.2 — Activity slot synergy/penalty matrix
- New field in activity.json: `"slot_modifiers": {"morning": 1.2, "late_night": 0.5}`
- Multiplier on effects: morning jog = 1.2x energy cost but 1.2x stat gain
- Late night study = 0.5x efficiency
- Sleeping in late_night slot = 1.5x energy recovery (natural)
- Training at night = 0.8x (poor lighting, tired)
- Socializing at night = 1.3x social gain (going out)
- Default modifier = 1.0 if not specified
- All injectable via JSON

### 2.3 — Vital collapse system
- Each vital has a collapse threshold (default: 0)
- When a vital hits 0 during week resolution, the system:
  1. Cancels the current planned activity
  2. Injects a recovery action (sleep if energy=0, eat if hunger=0, etc.)
  3. Logs a warning: "You were too exhausted to train. Slept instead."
- Recovery actions defined in activity.json with `"recovery_for": "energy"` field

### 2.4 — "Next Week" resolution
- Button resolves all 28 slots sequentially (Mon morning → Sun late night)
- Each slot: pick activity → roll event (positive/neutral/negative) → apply effects with slot modifier
- Events that require decisions pause resolution and prompt player
- After full resolution: advance week counter, show summary

### 2.5 — Week tasks (quests) sidebar
- Left panel shows weekly objectives with checkboxes
- Fixed quests first 4 weeks: "Do homework 3x", "Pass tryout", "Keep all vitals above 20"
- Quest completion gives bonus rewards (money, stat boost)
- Quests defined as Things with `group: "quest"`, injectable per module

---

## Phase 3 — Activities & Events per Attribute

### 3.1 — Activity per attribute
One dedicated training activity per attribute, each with 3 possible events.

| Attribute    | Activity           | Positive Event            | Neutral Event          | Negative Event            |
|--------------|--------------------|---------------------------|------------------------|---------------------------|
| Speed        | Sprint Training    | Runner's high (+extra)    | Normal session         | Pulled muscle (-HP)       |
| Strength     | Weight Training    | New PR (+extra)           | Normal session         | Dropped weight (-HP)      |
| Stamina      | Endurance Run      | Second wind (+extra)      | Normal session         | Side stitch, cut short    |
| Agility      | Agility Drills     | In the zone (+extra)      | Normal session         | Rolled ankle (-HP)        |
| Dexterity    | Ball Handling      | Hands of glue (+extra)    | Normal session         | Jammed finger (-HP)       |
| Balance      | Yoga / Core Work   | Deep focus (+extra)       | Normal session         | Fell, embarrassed (-social)|
| Perception   | Film Study         | Eureka moment (+extra)    | Normal session         | Information overload (-energy)|
| Intelligence | Book Study         | Aced a concept (+extra)   | Normal session         | Burnout (-leisure)        |
| Charisma     | Social Networking  | Made a connection (+extra)| Normal session         | Awkward encounter (-social)|

### 3.2 — Existing activities become "life" activities
- Study (school homework — required for quest completion)
- Work Part-time
- Cook & Eat (hunger recovery)
- Sleep / Rest (energy recovery)
- Hang Out, Watch TV, Browse Phone (leisure/social)
- Household Chores (required for quest, small money from parents)

### 3.3 — Event data structure
```json
{
  "id": "sprint_training",
  "name": {"pt": "Treino de Velocidade", "en": "Sprint Training"},
  "attribute": "speed",
  "slots": ["morning", "afternoon"],
  "slot_modifiers": {"morning": 1.2, "late_night": 0.3},
  "vitals_cost": {"energy": -20, "hunger": -10},
  "events": [
    {
      "type": "positive",
      "chance": 0.2,
      "text": {"pt": "Runner's high! Sessão incrível.", "en": "Runner's high! Incredible session."},
      "effects": {"speed": 2, "stamina": 1},
      "vitals": {"energy": -5}
    },
    {
      "type": "neutral",
      "chance": 0.6,
      "text": {"pt": "Treino normal, bom progresso.", "en": "Normal session, good progress."},
      "effects": {"speed": 1}
    },
    {
      "type": "negative",
      "chance": 0.2,
      "text": {"pt": "Puxou o músculo! Precisa descansar.", "en": "Pulled a muscle! Need to rest."},
      "effects": {"speed": 0},
      "vitals": {"energy": -15, "hp": -10}
    }
  ]
}
```

---

## Phase 4 — Card Minigame (Core Mechanic)

### 4.1 — Play card data
- Def: `game/defs/play.gd` + `play.json`
- Each play: `id`, `name`, `category` (route/coverage/rush), `image`, `description`
- Routes: Post, Go (Fly/Fade), Slant, Out, In (Dig), Corner, Curl, Flat, Screen
- Each play has a card image (placeholder PNG or generated)

### 4.2 — Minigame scene
- Top: 2D top-down field (simplified, ~400x200px)
- Center: play call text ("Run a POST route!")
- Bottom: 3 cards face up, one correct + 2 distractors
- Timer bar (T seconds, starts at 10s for tryout, decreases with difficulty)
- Player clicks a card:
  - Correct: animation of player token running the route on field, +points, +skill XP
  - Wrong: animation shows wrong route, 0 points, log shows what was correct

### 4.3 — Tryout event
- Available: Sunday morning, weeks 1-4
- Player must have "Tryout" in their Sunday morning slot
- Minigame: 5 rounds of play recognition
- Need X/5 correct to pass (X = 3 for easy, scales with team quality)
- Pass → join team, unlock team training, team roster
- Fail week 4 → game over screen ("No team accepted you. You retired from flag football.")

### 4.4 — Training integration
- Team training activities use the same minigame
- More rounds, more complex play calls
- XP gained scales with correct answers

### 4.5 — Field visualization
- Node2D scene with yard lines, end zones
- Player token (colored circle/sprite) runs the route path
- Route paths defined as arrays of Vector2 waypoints per play
- Simple tween animation along the path

---

## Phase 5 — Calendar Year & Origins

### 5.1 — Calendar year from module
- Module manifest gets `start_year` field (e.g., 2026)
- Top bar shows real date: "Seg 06/Jan/2026" instead of "Day 1"
- Week/day counters map to actual calendar dates starting from module's start date
- Start date injectable via module JSON: `"start_date": "2026-01-05"` (first Monday)

### 5.2 — Origin system (Arcanum-style)
- New Def: `game/defs/origin.gd` + `origin.json`
- Origins are character backgrounds chosen at creation (after stats, before cutscene)
- Each origin defines:
  - `name`, `desc` (i18n)
  - `stat_modifiers`: bonuses/penalties to attributes (e.g., +2 speed, -1 intelligence)
  - `skill_modifiers`: bonuses/penalties to skills
  - `school`: which school the player attends (reference to school Thing)
  - `schedule`: locked time slots (e.g., school occupies night slots Mon-Fri)
  - `allowance`: weekly mesada amount
  - `traits`: flavor tags for event resolution
- Example origins:
  - **Estudante Municipal (Noturno)**: school at night Mon-Fri, low allowance, +1 strength, +1 charisma, -1 intelligence. "You go to public school at night. Tough neighborhood, tougher kids."
  - **Estudante Classe Media (Manha)**: school mornings Mon-Fri, medium allowance, +1 intelligence, +1 perception, -1 strength. "Private school kid. Good grades expected."
  - **Tecnico (Tarde)**: school afternoons Mon-Fri, medium allowance, +1 dexterity, +1 intelligence, -1 charisma. "Technical school. You're learning a trade."
  - **Bully do Noturno**: school at night Mon-Fri, low allowance, +2 charisma, +1 strength, -2 intelligence, +1 trash_talk. "Everyone knows your name. Not for good reasons."
  - **Atleta Escolar**: school mornings Mon-Fri, medium allowance, +1 speed, +1 stamina, +1 agility, -1 intelligence, -1 charisma. "You're already on the school track team."
  - **Nerd Quieto**: school mornings Mon-Fri, high allowance, +2 intelligence, +2 perception, -2 charisma, -1 strength. "Top of your class. Bottom of the social ladder."
- School occupies slots → those slots are locked in the weekly planner (greyed out, can't change)
- Missing school → penalty event (parents angry, grades drop, allowance cut)

### 5.3 — School as locked schedule
- Origin's `schedule` injects locked activities into the week grid
- Locked cells are greyed out and show "School" (or the specific school name)
- Player can't override locked slots
- School attendance tracked as quest: "Attend school 5/5 days"

---

## Phase 6 — Name Generator

### 6.1 — Brazilian name generator
- Port weighted name generator from ScrapWarriors (`the-scrap-warriors/game/content/system/naming.json`)
- Adapted for Brazilian names: first names, surnames, and nicknames (apelidos)
- Def: `game/defs/naming.gd` + `naming.json`
- JSON structure per gender:
  - `"first_names"`: weighted list of Brazilian first names (male/female)
  - `"surnames"`: weighted list of common Brazilian surnames (Silva, Santos, Oliveira, etc.)
  - `"nicknames"`: weighted list of common apelidos + generators (diminutives, abbreviations)
  - `"generators"`: patterns like `["first_name", "surname"]`, `["nickname"]`, `["first_name", "surname", "surname"]`
- Character creation: player can type name manually OR click randomize button
- Randomize generates: Nome, Sobrenome, Apelido separately
- NPC names generated automatically using same system
- Injectable via JSON — modules can add regional name pools (e.g., gaúcho names, nordestino names)

---

## Phase 7 — Room Interactive Menus

### 6.1 — Floating draggable menus for room objects
- Phone, Computer, Fridge, Wardrobe become floating panels (draggable, closable)
- Click object button → opens a floating Window/PanelContainer with content
- Multiple can be open at once, player arranges them freely
- **Phone**: browse teams, sign up for tryouts (adds event to calendar), chat contacts, shop for small items
- **Computer**: view team roster (Elifoot-style), watch game film, check league standings, browse jobs
- **Fridge**: inventory of food items, eat to recover hunger, items bought via phone shop
- **Wardrobe**: equipment slots, change outfit, see outfit bonuses/penalties, items bought via phone shop
- Each menu is its own scene, injectable per module
- Items purchased appear in the relevant menu (buy food → fridge, buy gear → wardrobe)

---

## Phase 7 — Color Revamp & Polish

### 5.1 — Theme
- Dark background, accent colors for each section
- Vitals bars colored: green > yellow > red based on value
- Stat groups keep their identity colors
- Cards in minigame have distinct visual style

### 5.2 — Top bar improvements
- Time-of-day indicator changes as week resolves (sun/moon icons or color shift)
- Week progress bar (28 slots, fills as days pass)

---

## Execution Order (Incremental & Testable)

Legend: ✅ merged | ⚙ in progress | · pending

```
1.1 Module select       ✅
1.2 Language toggle      ✅
1.3 Injectable cutscene  ✅

2.1 Week grid UI         ✅ (7x4 grid, per-day play, color coding)
2.2 Slot synergy         ✅
2.3 Vital collapse       · plan bad week, see overrides
2.4 Next Week            ✅ (merged into 2.1)
2.5 Weekly quests        · see objectives, complete them

3.1 Attribute activities · new activities in palette
3.2 Life activities      · homework, chores in grid
3.3 Event resolution     · random events fire during week

4.1 Play card data       · see card definitions
4.2 Minigame scene       · play the card game standalone
4.3 Tryout event         · go to tryout, play minigame
4.4 Training             · team training uses minigame
4.5 Field viz            · see routes animate on field

5.1 Calendar year        · real dates in top bar
5.2 Origin system        · pick origin at creation, see locked school slots
5.3 School schedule      · locked cells in grid, attendance quest

6.1 Name generator       · Brazilian names (port from ScrapWarriors)

7.1 Room floating menus  · phone, computer, fridge, wardrobe as draggable panels

8.1 Theme                · color revamp
8.2 Top bar              · time of day, week progress
```

Each step produces a testable increment. Feedback after each step can redirect the next.
