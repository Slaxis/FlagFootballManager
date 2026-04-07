# Changelog

## [Unreleased]

### Added
- Module select screen: choose campaign module before character creation
- Module manifest now supports i18n fields (name, description) and version
- Player age set to 15 (was 16)

### Changed
- Main menu START → module select → character creation (was: START → creation)
- Character creation BACK → module select (was: BACK → main menu)

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
