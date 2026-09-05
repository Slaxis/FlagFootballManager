# Flag Football Manager

## Project Overview

A club management sim set in the Brazilian amateur flag football scene — "the
Elifoot 2000 of flag football". You manage an amateur club through the real
CBFA structure: state rounds, regional qualifiers, national finals, and the
Série A/B/C divisions. Single player, 100% panel-based UI.

There is no salary in amateur flag: low-tier clubs survive on athlete dues,
high-tier clubs on sponsorship, and travel to a national round can cost more
than a season's cash. That tension is the game.

**`roadmap.md` is the source of truth** for the plan, the design decisions,
and the feature branch sequence. Read it before starting work.

## Architecture

### Engine — `addons/d5star/` (git submodule)

The engine is the **d5star** library, consumed as a submodule from
`https://github.com/Slaxis/d5star` and pinned per commit. It is shared with
other games (ScrapWarriorsOne), so:

**Never put game-specific logic in `addons/d5star/`.**

To fix something in the engine:

```bash
cd addons/d5star && git commit -am "fix: ..." && git push
cd ../.. && git add addons/d5star && git commit -m "chore: bump d5star"
```

The library registers its eight autoloads through its own EditorPlugin —
`Air` (bus), `Log`, `Drive` (service locator), `God` (hubs), `The` (session),
`I18n`, `SaveManager`, `Audio`. Do not hand-write them into `project.godot`.

Key primitives: **Thing/ThingData/ThingPart** (pure RefCounted, never in the
scene tree), **Def** (typed data catalogs), **Slate** (typed snapshot of
choices), **Flow** (declarative screen graph in JSON), **Card/Deck/Hand**,
**Menu/World/Overlay** scene adapters.

⚠️ GDScript has no namespaces. The library owns **54 global `class_name`s** —
see the reserved list in `addons/d5star/README.md` before naming a class.
`Manager`, `Selection` and `Rules` were deliberately freed for the game
(they became `D5Manager`, `Slate` and `Codex`).

### Game — `game/`

- `game/defs/` — Def scripts + sibling JSON (stat, skill, team, flow, ...)
- `game/modules/brasil/` — the campaign module
- `res://d5star.json` — project layout config, lives outside the submodule

### Module structure

```
game/modules/<id>/
  module.json                      manifest: {id, name, description, order, requires}
  content/
    system/game.json               {id, name, version, flow, directories}
    things/<def_id>/<id>/<id>.json per-Thing hosting, one folder per Thing
  scene/<screen>/<screen>.tscn     screens, resolved by Flow's scene_file
```

Navigation is **declarative**: `content/things/flow/main_flow/main_flow.json`
declares steps, `scene_file`, `consumes`/`produces` and `transitions`. A
screen calls `go("<transition>")` — it never names another screen.

## Tracking

- **`roadmap.md`** — plan, decisions, feature branch list. Source of truth.
- **`CHANGELOG.md`** — updated after each task completion.

Always update CHANGELOG.md when completing a task.

## Workflow

Per feature branch: **plan → present → approve → implement → test → close.**
Do not start implementing before the plan is approved.

## Git

- **`master`** is the stable branch (note: the d5star repo uses `main`).
- Feature branches: `feature/<task-id>` — e.g. `feature/A.1-team-database`,
  matching the ids in `roadmap.md`.
- One branch per task. Merge to `master` after testing.
- The life sim the game used to be is preserved in the tag
  `pre-d5star-migration` and the branch `legacy/life-sim`.

## Code Conventions

- **Language**: all code, variable names, class names and technical docs in English
- **Content**: module JSON uses i18n dicts (`{"pt": "...", "en": "..."}`) resolved by I18n
- **GDScript style**: Godot's official style guide
  - snake_case for variables, functions, signals
  - PascalCase for classes and `class_name`
  - UPPER_SNAKE_CASE for constants
  - Type hints on all function signatures and variable declarations
- **Comments**: only where the logic is non-obvious. No boilerplate docstrings.
- **File naming**: snake_case (e.g. `match_engine.gd`, `player_row.tscn`)

## Thing JSON rules

- Reserved keys: `id`, `ancestor`, `parts`, `group`, `kind`, `abstract`
- Every other key becomes a `data` entry
- `ancestor` gives type inheritance; data merges with operator semantics
  (`+`, `-`, `*`, `/` prefixes). Literal escape with `=` — `"=+10"` is the
  string `"+10"`.
- `group` enables querying by category (e.g. `group: "team"`)

## Testing

- **Boot smoke test** is the primary check — it exercises Drive → engine.json
  → PathManager → managers → parser/loader/validator discovery → module scan
  → def scan → Flow → first screen:

  ```bash
  godot --headless --path . --quit-after 300
  ```

  Exit 0 with no `SCRIPT ERROR` means the chain is intact.

- The match simulation must be **deterministic given a seed** — test with
  known seeds.
- UI is tested manually through gameplay.
- Each task must be independently testable before merge.

⚠️ After renaming a `class_name` or moving files, Godot keeps the stale names
in `.godot/global_script_class_cache.cfg` and the boot fails with
"Could not find type X". It is a cache, not a real break. Run
`godot --headless --path . --import` before validating.

## Dependencies

- Godot 4.7, Forward Plus
- `addons/d5star` (git submodule) — the only addon
