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

- `game/defs/` — Def scripts + sibling JSON (stat, team, region, flow, ...)
- `game/model/` — domain Things and generators (`Actor`, `ActorGenerator`).
  Kept out of `defs/` because these are runtime entities, not catalogs.
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

- **Unit tests** — run the suite as a SCENE, never with `--script`:

  ```bash
  godot --headless --path . res://tests/run.tscn
  ```

  A `--script` run replaces the main loop with a custom SceneTree and the
  autoloads do not exist while `_init()` executes, so `Drive`/`God`/`The` are
  unreachable and any suite touching them aborts the runner mid-flight. Register
  new suites in the `_SUITES` array of `tests/run.gd`. Exit code is 0 / 1.

  ⚠️ **GDScript has no exceptions.** A runtime error inside a test aborts that
  function and returns to the runner, which used to see no recorded failures
  and print `ok` — a green run hiding broken tests. The runner now fails any
  test that asserted **nothing**, on the grounds that "asserted nothing" and
  "died on line one" are indistinguishable. A test whose only statement is a
  conditional `fail()` must therefore assert something positive too.

  Also grep the run for `SCRIPT ERROR`: the runner cannot see those, but the
  shell can, and a clean suite should print none.

  The runner waits one frame before running anything, so a suite MAY mount a
  screen with `(Engine.get_main_loop() as SceneTree).root.add_child(...)`.
  Inside `_ready` that call is refused ("parent node is busy setting up
  children") and the screen silently never builds.

- **Boot smoke test** is the second check — it exercises Drive → engine.json
  → PathManager → managers → parser/loader/validator discovery → module scan
  → def scan → Flow → first screen:

  ```bash
  godot --headless --path . --quit-after 300
  ```

  Exit 0 with no `SCRIPT ERROR` means the chain is intact.

- **Quit check** — the one thing neither of the above can see, because it ends
  the process:

  ```bash
  godot --headless --path . res://tests/quit_check.tscn
  ```

  It boots, waits for the start screen, presses Sair and expects the tree to go
  down. Exit 1 means it is still standing. This shipped broken twice: `"$exit"`
  was handled by a listener on `Game`, and **`Game` is freed by the first
  `change_scene_to_packed`** — which is exactly why `Flow` is parented to the
  tree root instead. Anything that must outlive a scene swap belongs on the
  Flow, not on the boot scene, and a unit test asserting "the handler exists"
  proves nothing about whether it is still connected.

- **Fit check** — the fourth, and the one the unit runner structurally cannot
  do:

  ```bash
  godot --headless --path . res://tests/fit_check.tscn
  ```

  Every screen must fit `1920x1080` without scrolling, and must not fit by
  using a third of it either. A screen's real size only settles after a LAYOUT
  PASS, and `get_combined_minimum_size()` read in the same frame a Control was
  added reports nonsense — an autowrapping Label does not know its own width
  yet, so it reports the height it would need at its minimum width. The
  creation form measured 7562px that way and 1051px one frame later, which is
  why this is a scene with its own `_ready` that can await.

  Each screen tags the node that has to fit with `set_meta("fit_root", true)`.
  Guessing was wrong twice — the background ColorRect, then the club-colour
  badge — and there is no generic answer, because a ScrollContainer reports a
  tiny minimum by design and would hide the exact problem being looked for. A
  new screen opts in; one that forgot fails loudly.

  It exists because the creation form shipped at 1743px against a 1080 viewport,
  in a 940px column, with two thirds of the monitor empty beside it — and
  nothing about that looks wrong in a screenshot or in a passing test.

- **Screen smoke tests** are the third check. UI is otherwise invisible to the
  loop: GDScript has no exceptions, so a screen that dies halfway through
  building its own form leaves a half-drawn panel and a green run — which is
  how the 1-career-point deadlock reached the player.
  `tests/test_screen_create_manager.gd` mounts the scene and presses the
  buttons. Add one per screen that has state worth breaking.

- The match simulation must be **deterministic given a seed** — test with
  known seeds.
- UI is tested manually through gameplay.
- Each task must be independently testable before merge.

⚠️ **GDScript warnings are editor-only.** A headless run, `--editor --quit` and
`--check-only` all stay silent about them, so the automated loop cannot see a
shadowed variable or an unused signal. `tests/test_lint.gd` covers the two
traps that have actually bitten this project — a variable named after a Godot
built-in, and one named after anything the file's base class inherits. The
second asks **ClassDB** for every signal, property and method up the engine
chain rather than keeping a list: a hand-kept list is what let `var draw`
through, since it shadows a `CanvasItem` signal three levels above `Menu`.
Map any new game base class to its engine ancestor in `ENGINE_BASE`. It is
still not the compiler. Warnings reported from the editor are still worth
passing along.

⚠️ After renaming a `class_name` or moving files, Godot keeps the stale names
in `.godot/global_script_class_cache.cfg` and the boot fails with
"Could not find type X". It is a cache, not a real break. Run
`godot --headless --path . --import` before validating.

## Dependencies

- Godot 4.7, Forward Plus
- `addons/d5star` (git submodule) — the only addon
