# Changelog

## [Unreleased]

### Added
- Module select screen: choose campaign module before character creation
- Module manifest now supports i18n fields (name, description) and version
- Player age set to 15 (was 16)
- Gender toggle (M/F) on character creation header
- Language toggle (PT/EN) button on home screen top bar
- All UI strings converted to i18n dicts: activities, stats, skills, vitals, day names, room items, all menu buttons, cutscene pages bilingual PT/EN
- Cutscene pages now loaded from injectable Thing JSON (`group: "cutscene"`) with i18n text + image field
- Weekly planner: 7x4 grid (Mon-Sun x Morning/Afternoon/Night/Late Night) replaces daily slots
- Late Night time slot added to activities, "Stay Up Late" activity added
- NEXT WEEK button resolves all 28 slots, CLEAR resets grid
- Per-day play buttons: [>] resolves one day, changes to [ok] when done
- Days must be resolved in order (Mon->Tue->Wed...)
- Color-coded outcomes: blue (running), green (good), yellow (neutral), red (bad)
- Log text colored to match outcomes via BBCode
- Progressive resolution with 500ms delay per slot, vitals update live
- TV renamed to Computer
- Slot synergy/penalty matrix: activities have slot_modifiers, effects scaled by modifier
- Vital collapse: when vital hits 0, planned activity replaced by binge (APAGAO, COMILANCA, CARENCIA, MARATONA DE CELULAR)
- Per-day play buttons: > (single slot), >> (full day), >> WEEK (all remaining)
- Color-coded calendar and log: green=synergy, yellow=normal, red=collapse
- Progressive resolution with 500ms delay, vitals update live
- Column header dropdowns: set all 7 days in a slot at once
- Week summary popup: vitals before/after, money delta, activities by color
- Cutscene: BACK/NEXT/SKIP buttons
- Weekly quests sidebar: injectable per week via Things, live tracking, summary results
- 9 attribute training activities with 3 events each (pos/neu/neg), stat bonuses
- HP vital, Room (quarto) vital
- Activity categories: BRUTALITY/FINESSE/COGNITION/SCHOOL/FAMILY/FRIENDS with grouped dropdowns
- All activities available in all 4 time slots (soft margins via modifiers, no hard locks)
- Late night global energy penalty (-15 for non-sleep activities)
- Fridge meal system: cooking stocks meals, hunger=0 eats from fridge before collapse
- Floating draggable fridge window with live meal count
- Week schedule carryover (copies previous week's choices)
- Beach Football and Video Games activities
- Quest type: activity_category_count (tracks any activity from a category)

### Changed
- Removed gym/academia, train_solo, socialize, stay_up_late activities
- Renamed activities for 15yo context: Hill Sprints, Calisthenics, Parkour, etc.
- Cooking now stocks fridge (+3 meals) instead of direct hunger restore

### Changed
- Home screen layout: grid takes ~75% width (left), room + vitals + log on right
- "Plan your day" → "Plan your week", "Next day" ��� "Next week"
- Day advances by 7 per week instead of 1

### Changed
- Main menu START → module select → character creation (was: START → creation)
- Character creation BACK → module select (was: BACK → main menu)
- activity.json, stat.json, skill.json now use `{"pt": ..., "en": ...}` format
- Home screen fully i18n-aware: labels, dropdowns, log messages update on language switch

## [0.0.1] — 2026-04-07

### Added
- Engine ported from SugarLoaf: Thing system, modules, Defs, command bus, i18n, logging
- Main menu: Continue / Start / Options / Quit
- Character creation: Player/Coach toggle, RPG stat sheet (Brutality/Finesse/Cognition), star/dummy mark system, read-only skills panel
- Stat Def (`game/defs/stat.gd`): injectable attribute groups via JSON
- Skill Def (`game/defs/skill.gd`): injectable skills (Offense/Defense/General) via JSON
- Creation Def (`game/defs/creation.gd`): injectable balancing rules via JSON
- Activity Def (`game/defs/activity.gd`): 12 daily activities with time slots and vital effects
- Cutscene: 7-page narrative intro
- Home screen: top bar (money/calendar), weekly planner (3 slots), room objects, vitals panel, effects bar
- Day progression: resolve activities, apply effects, vital collapse warnings
- 8 Brazilian flag football teams as Things with full rosters: Flag Kings (RJ), Cronos (SP), Spartans (SP), Predadores (MS), Coritiba Crocodiles (PR), Fortaleza Tritões (CE), Floripa Ghosts (SC), Cavalaria 2 de Julho (BA)
- Base player Thing with 9 attributes + 12 skills
- `project.godot` configured with autoloads and Forward Plus rendering
- `roadmap.md` with full development roadmap (Cycles B-I)
- `CLAUDE.md` with project conventions and architecture docs
