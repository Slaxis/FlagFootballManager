# Flag Football Manager — Roadmap

## Completed

### Cycle A — Skeleton (Life Sim Core)
- [x] Main menu: Continue / Start / Options / Quit
- [x] Character creation: Player/Coach toggle, RPG stat sheet, star/dummy marks
- [x] Cutscene: narrative intro after creation
- [x] Home screen: top bar (money, calendar), left panel (3 activity slots), center (room objects + log), right panel (vitals), bottom (effects bar)
- [x] Activity Def system: data-driven activities with time slots and stat effects
- [x] Day progression: resolve 3 slots, apply effects, advance calendar, debuff on low vitals
- [x] Stat/Skill/Creation Defs: all game data injectable via JSON
- [x] Engine ported from SugarLoaf: Thing system, modules, Defs, command bus
- [x] 8 real Brazilian flag teams with rosters (Things)

---

## Cycle B — Phone & Team Integration

The phone is the player's gateway to the flag football world.

- [ ] **Phone UI** — modal/overlay accessed from room
  - [ ] Teams tab: browse teams by state, see rosters, training schedules
  - [ ] Tryouts tab: sign up for open tryouts (adds event to calendar)
  - [ ] Shop tab: buy gear, food, supplements
  - [ ] Contacts tab: chat with friends, teammates
- [ ] **Team training schedules** — each team has a weekly schedule (JSON per team)
  - [ ] Training events appear in calendar when player joins a team
  - [ ] Missing training hurts standing with the team
- [ ] **Tryout event** — show up at the right day/time
  - [ ] Minigame or stat check to determine if you make the team
  - [ ] Success → join team, fail → try again next week
- [ ] **Team roster view** — Elifoot-style roster screen accessible via phone/computer

---

## Cycle C — Equipment & Clothing

- [ ] **Equipment Def** — slots: shirt, shorts, shoes, hat, gloves, accessories
- [ ] **Clothing items as Things** — each with stat modifiers, durability
- [ ] **Wardrobe UI** — drag/equip from room wardrobe
- [ ] **Context penalties** — wrong outfit for activity = bad event (work in gym clothes, etc.)
- [ ] **Shop** — phone shop sells clothing and gear
- [ ] **Durability** — training destroys gear over time, need replacements

---

## Cycle D — Buff/Debuff & Event System

- [ ] **Buff/Debuff cards** — visual cards on bottom bar with icons and timers
- [ ] **Vital thresholds** → automatic debuffs (Hungry, Exhausted, Lonely, Bored)
- [ ] **Activity events** — random events during activities
  - [ ] Work: boss angry, got a raise, coworker conflict
  - [ ] Training: injury risk, breakthrough, bad weather
  - [ ] Social: made a new friend, argument, party invite
- [ ] **Event resolution** — stat checks against player attributes
- [ ] **Notification system** — events pop up as the day resolves

---

## Cycle E — Season & Competition

- [ ] **Season calendar** — shared league schedule (round robin or bracket)
- [ ] **Match simulation** — play-by-play engine using player/team stats
- [ ] **Match day** — attend the game, performance depends on stats + vitals + gear
- [ ] **Tabelão** — Elifoot-style simultaneous match view
- [ ] **2D grid match view** — pixel art field, player tokens, play-by-play visualization
- [ ] **Standings** — league table, stats leaders
- [ ] **End of season** — awards, stats summary, next season transition

---

## Cycle F — Career Progression

- [ ] **XP system** — gain XP from training, matches, study
  - [ ] Intelligence stat affects XP gain rate
  - [ ] Skills level up through use (train throwing → throwing goes up)
- [ ] **Perk system** — unlock perks at milestones (level 5, 10, etc.)
  - [ ] Perks are passive bonuses: "Early Riser" (+energy from sleep), "Clutch" (+stats in 4th quarter)
- [ ] **Aging** — stats peak around 22-26, slow decline after
- [ ] **Injuries** — happen during training/matches, require rest to heal
- [ ] **Retirement** — forced if no team picks you for a full season, or voluntary
- [ ] **Career stats** — lifetime record, achievements, hall of fame

---

## Cycle G — Financial Depth

- [ ] **Allowance vs Work** — student gets mesada, worker gets salary
- [ ] **Job types** — part-time, full-time, gig work, each with different schedules and pay
- [ ] **Expenses** — team monthly fee (mensalidade), gear replacement, food
- [ ] **Money events** — bonus from good match performance, sponsor deals (later career)
- [ ] **Financial stress** — can't afford team fee = risk of being cut

---

## Cycle H — Coach Mode

- [ ] **Coach creation** — different stat sheet (tactical, motivational, organizational)
- [ ] **Team management** — recruit players, set lineups, design plays
- [ ] **Budget management** — mensalidades, field rental, equipment, sponsors
- [ ] **Playbook system** — design offensive/defensive plays
- [ ] **Staff** — hire assistant coaches, coordinators
- [ ] **Dual perspective** — player mode characters appear as NPCs in coach mode

---

## Cycle I — Polish & Content

- [ ] **3D room** — replace menu room with 3D scene with clickable sprites
- [ ] **Mirror/avatar** — visual player representation with equipped gear
- [ ] **Sound & Music** — ambient home sounds, match day crowd
- [ ] **More teams** — expand to 20+ teams across more states
- [ ] **Custom modules** — user guide for creating leagues, teams, players from scratch
- [ ] **Multiple campaigns** — different starting scenarios (college player, veteran comeback, etc.)
- [ ] **Localization** — Portuguese (pt-BR) as first content language, i18n for UI
