# Flag Football Manager Brasil

## Project Overview

A life sim / survival game set in the Brazilian amateur flag football scene. You're a 15-year-old student trying to build a flag football career — balancing school, work, training, social life, and vital stats. Core mechanic: card-based play recognition under time pressure. Built on Godot 4.6 with a data-driven engine ported from SugarLoaf.

Two play modes: **Player Mode** (life sim + career survival) and **Coach Mode** (team management, future).

## Architecture

### Engine (`engine/`)
Reusable data-driven engine — portable to other Godot projects. Do NOT add game-specific logic here.

- **Thing system**: all game entities (players, teams, fields, leagues) are Things defined in JSON
- **Autoloads**: Air (command bus), Log, Drive (service locator), God (coordinator), The (session), I18n
- **Modules**: each league/campaign is a self-contained module with its own JSON content
- **Defs**: game definitions (stats, skills, activities, creation rules) loaded from `game/defs/`

### Game (`game/`)
Flag Football Manager specific code, content, and UI.

- `game/defs/` — game definition scripts and base JSON (stats, skills, activities, creation, plays)
- `game/modules/` — campaign modules (e.g., `brasil_2026/`)
- `game/ui/` — shared UI components
- `game/simulation/` — match simulation, play resolution, minigames

### Content authoring
All game entities are JSON-based Things. Users can create custom modules under `user://modules/` to inject their own teams, players, leagues, and fields. User content overrides native content by priority.

## Tracking

- **TODO.md**: dynamic task list and priorities for the current version. Tasks are organized in phases, each step is independently testable. We work one branch per task.
- **CHANGELOG.md**: updated after each task completion. Records what was added, changed, or fixed.
- **roadmap.md**: long-term vision (Cycles B-I). Not actionable — just direction.

Always update CHANGELOG.md when completing a task. Keep TODO.md current with priorities.

## Code Conventions

- **Language**: all code, variable names, class names, and technical docs in English
- **Content**: module JSON data uses i18n dictionaries (`{"pt": "...", "en": "..."}`) resolved by I18n
- **GDScript style**: follow Godot's official GDScript style guide
  - snake_case for variables, functions, signals
  - PascalCase for classes and class_name
  - UPPER_SNAKE_CASE for constants
  - Type hints on all function signatures and variable declarations
- **Comments**: only where logic is non-obvious. No boilerplate docstrings
- **File naming**: snake_case for all files (e.g., `match_engine.gd`, `player_card.tscn`)

## Git Workflow

- `main` branch: stable, tested
- Feature branches: `feature/<task-id>` (e.g., `feature/1.1-module-select`)
- One branch per TODO.md task
- Merge to main after testing

## Engine Rules

- Thing JSON reserved keys: `id`, `ancestor`, `parts`, `texture`, `group`
- All other keys in a Thing JSON become `data` entries
- Use `ancestor` for type inheritance; data merges with operator semantics (`+`, `-`, `*`, `/` prefixes)
- Literal escape: prefix with `=` (e.g., `"=+10"` becomes the string `"+10"`)
- `group` field enables querying Things by category (e.g., `group: "player"`)

## Module Structure

```
game/modules/<module_id>/
  module.json                    # manifest: {id, name, description, order, requires}
  content/
    system/
      game.json                  # rules + entry point
    things/
      <entity>.json              # Thing definitions
  ui/
    <screen_id>/
      <screen_id>.tscn           # UI scenes
```

## Key Design Decisions

- **Life sim first**: daily routine planning (4 slots x 7 days), vital stats, events
- **Card mechanic**: play recognition under timer = core of tryout, training, and match
- **Survival**: no team picks you = game over (forced retirement)
- **Sandbox-first**: modules are user-injectable, all game data is JSON
- **No premature abstraction**: keep it simple, expand through data not code

## Testing

- Test Thing loading and variant merging with unit tests where possible
- Simulation engine should be deterministic given a seed — test with known seeds
- UI is tested manually through gameplay
- Each TODO task must be independently testable before merge

## Dependencies

- Godot 4.6, Forward Plus rendering
- No external plugins or addons for MVP
