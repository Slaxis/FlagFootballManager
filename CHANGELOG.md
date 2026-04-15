# Changelog

## [Unreleased]

### Added (release 0.1.0 prep)
- SaveManager autoload (single-slot save + Hall of Fame + settings) at `engine/globals/save_manager.gd`
- Main menu Continue button + new-game overwrite confirmation
- Auto-save at end of each week in `player_home`
- Game Over screen + Hall of Fame entry on 4 failed tryouts
- Win screen (Ato 0) saved to Hall of Fame with act0_complete result
- Hall of Fame screen listing past careers from main menu
- Options menu: Master / Music / SFX volume sliders, language toggle (PT/EN), reset defaults, persisted to `user://settings.json`
- 3-bus audio layout (Master / Music / SFX) in `default_bus_layout.tres`
- Save & Quit button in player_home tool row (blocked while a week is resolving)
- Unified action bar in player_home: `[SPACE] PAUSE | [Q] ATIVIDADE | [W] DIA | [E] SEMANA | X | [ESC] MENU` — replaces per-day `>`/`>>` columns for a cleaner grid
- ESC hotkey opens Save & Quit; pause button toggles PAUSE/RESUME label inline

### Fixed
- Continue after clearing Ato 0 now returns to the win screen instead of dropping back into the weekly grid (Act 1 unavailable); session flag `ato0_complete` drives the routing
- Save & Quit mid-week now persists per-day resolution progress (`day_resolved`, `day_slot_index`, `slot_colors`); previously resolved slots would reset to unplayed on reload, double-applying their vital/money effects when replayed
- Starting a new career now wipes `The.session` before module select; prior-run grid selections, `ato0_complete`, and tryout counters no longer bleed into the fresh playthrough (both main-menu NEW GAME and game-over NEW GAME paths)
- Replaced cryptic `X` clear-plan button with labeled `LIMPAR PLANO` / `CLEAR PLAN`

### Added (4.x cycle)
- Technique card system (`technique.gd`/`technique.json`): rarities, tiers, personalities (intenso/tecnico/estrategico), coins, vital_cost, situation_tags
- Drill system (`drill.gd`/`drill.json`): 8 drills (3 physical + 5 position: qb/wr/center/db/rusher)
- Drill minigame in NEO Scavenger format: player | other sprites, narrative prompt, card hand (commons always available via tag match + memory cards from deck), d5* dice, yomi rock-paper-scissors between personalities
- Tryout manager: position select → 3 physical drills → 1 position drill → results
- Common cards auto-appear in hand when their tags match the situation's tags; memory cards (uncommon/rare) drawn from deck
- Added `respirar_fundo` (recovery common) and `tentativa_honesta` (universal fallback)
- Origin system, cutscene, fridge meals with delivery cascade, hunger auto-resolution, tryout failure counter

### Changed (4.x cycle)
- Tryout uses drill_minigame for all drills (removed old card_minigame path for position drill)
- Position drills converted to NEO Scavenger format with situations + tags + check_stats
- Replaced green field + animated dot viewport with player/other sprite panels


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

- Technique card system: collectible cards with personality types (Intenso/Tecnico/Estrategico), yomi layer, d5* dice, vital costs
- Drill minigame: situation sequences with technique card hand, multi-card play, synergy, viewport animation
- New Defs: TechniqueDef (technique.gd/json), DrillDef (drill.gd/json) — 9 basic + 6 advanced + 4 casa + 6 meta + 6 origin cards
- Personality selection in character creation with starter deck (1 base + 1 origin bonus)
- Tryout physical drills now use drill_minigame with technique cards (40-yard, three-cone, shuttle)
- Hand panel permanent on home screen, hotkeys changed: Q/W/E for slot/day/week, 1-5 for cards, S for skip
- Mechanics reference document: game/docs/mechanics.md
- Home screen redesign: sidebar (casa/vitals/quests/diary/effects) + main panel (grid + embedded viewport)
- Minigames now embedded in SubViewport instead of Window popups (play_minigame, tryout)
- Room placeholder shown in viewport when no minigame is active
- Log replaced with Diary (narrative text in sidebar, scrollable)
- Origin system: 3 origins (quebrada/condomínio/mansão) with distinct starting money, fridge, vitals, stat modifiers
- School system: 3 schools (público/bairro/elite) with stat modifiers, turno selection (1=manhã, 2=tarde, 3=noite)
- Body system: height (150-200cm) and weight (45-110kg) sliders with threshold-based stat bonuses
- All origin/school/body modifiers stack and display live during character creation
- New Def: OriginDef (origin.gd + origin.json) with compute_modifiers, turnos_for_school
- Session stores origin, school, turno, height, weight for downstream use
- Hunger system: auto-meals at breakfast (morning) and dinner (night) when hunger < 80
- Meal source cascade: fridge (free, +35) → delivery (R$15, +30) → lanche (up to R$30, scaled)
- Emergency cascade at hunger=0: same sources, fridge gives +25 (smaller emergency portion)
- Collapse only triggers when broke and no fridge — cooking is now strategic
- Route card drawings now use fixed scale (100-unit reference), preserving relative route sizes
- Hotkey labels on play buttons: [1]> slot, [2]>> day, [3]>> week
- Fridge and mirror windows now unfocusable — keyboard shortcuts toggle them properly
- Team practice uses play_minigame (5 rounds, diff 2, 12s timer) with events (Foco Tático buff, Coach's Scolding debuff)
- Minigame activities now continue to effects/events after minigame (no early return)
- Play card minigame: route drawings on cards (Line2D) instead of text names
- Generalized card minigame (card_minigame.gd): supports path, label, and play_ref card types
- Tryout system overhaul: position selection (QB/WR/Center/DB/Rusher) → 3 physical drills (40-yard dash, three-cone, pro agility) → 1 position-specific drill → results
- New "TEAM" activity category with tryout moved from brutality
- Physical drill minigames: sprint reaction (GO/HOLD), cone path matching, shuttle direction calls
- Position drill minigames: QB defensive reads, WR/Center route recognition, DB coverage calls, Rusher rush reads
- Tryout pass/fail: 60% combined threshold (9/14 points)
- WIN screen on tryout pass with position display
- GAME OVER screen when week 4 ends without team (returns to main menu)
- Tryout results breakdown in weekly summary popup
- Activity requires: no_team check (hides tryout after joining team)
- Fixed activity dropdown index mapping: _grid_activities now uses grouped order matching dropdown display

### Changed
- Removed gym/academia, train_solo, socialize, stay_up_late activities
- Renamed activities for 15yo context: Hill Sprints, Calisthenics, Parkour, etc.
- Cooking now stocks fridge (+3 meals) instead of direct hunger restore
- Timed effect system: events produce buffs/debuffs lasting N slots (Runner's High, Zen, Contusão, etc.)
- Effect cards in bottom bar with styled panels (green/red border)
- Mirror/character sheet window (M key): stats with effect modifiers, skills, active effects
- Keyboard shortcuts: SPACE pause, 1/2/3 slot/day/week, F fridge, M mirror
- Realistic default week schedule for 15yo student
- Removed Sleep In (merged into Sleep with morning 0.8x soft margin)
- Activity lock/unlock system: requires field (min_age, has_item, has_team, week_range). Locked activities hidden from dropdowns, appear when unlocked.
- Locked activities added: Part-time Job (age 16+), Gym (membership), Team Practice (has team)

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
